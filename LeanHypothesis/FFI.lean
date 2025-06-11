import Lean.Data.Json

/-!
# FFI Bridge for Python Hypothesis

This module provides a robust Foreign Function Interface (FFI) layer for communicating
with the Python Hypothesis library. It handles JSON serialization, error recovery,
and provides a clean interface for property-based testing.

## Features

- **Robust JSON Parsing**: Uses Lean's built-in JSON parser with comprehensive error handling
- **Process Management**: Reliable subprocess communication with timeout and error recovery
- **Type-Safe Results**: Structured result types with explicit error handling
- **Logging**: Detailed logging for debugging and monitoring
- **Performance**: Optimized for minimal overhead in test execution

## Architecture

The FFI bridge operates through subprocess calls to a Python CLI that wraps Hypothesis.
This approach provides:
- Process isolation and fault tolerance
- Easy integration with existing Python tooling
- Clear separation between Lean and Python concerns
- Straightforward debugging and monitoring

Future versions may include direct C FFI for improved performance.
-/

namespace LeanHypothesis.FFI

/-! ## Result Types and Parsing -/

/-- Result from Python bridge with comprehensive error information -/
structure PythonResult where
  /-- Success/error status -/
  status : String
  /-- Raw JSON data from Python -/
  data : String
  /-- Error message if status is "error" -/
  error : Option String
  /-- Additional metadata for debugging -/
  metadata : Option (String × String) -- (command, timing)
  deriving Repr

/-- Detailed error information for better debugging -/
inductive FFIError where
  | jsonParseError (raw : String) (context : String)
  | processError (exitCode : Int) (stderr : String) (command : String)
  | timeoutError (command : String) (duration : Float)
  | validationError (message : String) (data : String)
  deriving Repr

/-- Enhanced result type with detailed error reporting -/
def FFIResult (α : Type) := Except FFIError α

/-- Parse JSON result from Python bridge with enhanced error handling -/
def parsePythonResult (jsonStr : String) (context : String := "") : FFIResult PythonResult := do
  match Lean.Json.parse jsonStr with
  | .ok json =>
    match json.getObjVal? "status" with
    | .ok statusJson =>
      match statusJson.getStr? with
      | .ok status =>
        let data := json.getObjVal? "data" |>.toOption |>.bind (·.getStr?.toOption) |>.getD jsonStr
        let error := json.getObjVal? "error" |>.toOption |>.bind (·.getStr?.toOption)
        let timing := json.getObjVal? "timing" |>.toOption |>.bind (·.getStr?.toOption)
        let metadata := timing.map (fun t => (context, t))
        .ok ⟨status, data, error, metadata⟩
      | .error _ => .error (FFIError.jsonParseError jsonStr s!"Missing status string in {context}")
    | .error _ => .error (FFIError.jsonParseError jsonStr s!"Missing status field in {context}")
  | .error e => .error (FFIError.jsonParseError jsonStr s!"JSON parse failed in {context}: {e}")

/-! ## Helper utilities -/

/-/ Four-digit lowercase hexadecimal representation of `n` (< 65536). -/
private def hex4 (n : Nat) : String :=
  let digits := Nat.toDigits 16 n  -- Lean returns list Char
  let pad := List.replicate (4 - digits.length) '0'
  String.mk (pad ++ digits)

/-/ Render a string safely for terminal output:
    • Printable 7-bit ASCII stays as-is.
    • TAB / NEWLINE become visible glyphs (⇥, ⏎).
    • Every other code-point is escaped as \uXXXX.
    • If the resulting string exceeds `maxLen`, truncate and annotate. -/
private def sanitizeAscii (s : String) (maxLen : Nat := 80) : String :=
  let rendered :=
    s.foldl (init := "") fun acc c =>
      let n := c.toNat
      if 32 ≤ n ∧ n < 127 then
        acc.push c
      else if c = '\n' then
        acc ++ "⏎"
      else if c = '\t' then
        acc ++ "⇥"
      else
        acc ++ "\\u" ++ hex4 n
  if rendered.length > maxLen then
    rendered.take maxLen ++ "…(" ++ toString s.length ++ " chars)"
  else
    rendered

/-/ Recursively convert a `Lean.Json` value (possibly *repeatedly* encoded as a
    JSON string) into a human-readable string. This tries to unwrap the common
    pattern produced by the Python bridge where values are encoded *twice*:

    • the outer layer represents the counterexample value (e.g. a JSON array),
    • string elements inside that array are themselves JSON-encoded strings
      (because the Python side uses `json.dumps` on the example values).

  The algorithm keeps peeling layers as long as parsing succeeds. For compound
  structures like arrays we recursively pretty-print the children so we end up
  with far fewer `\uXXXX` escapes in the final output.
-/
private partial def jsonPretty (j : Lean.Json) : String :=
  let rec aux (j : Lean.Json) : String :=
    match j with
    | .str s =>
      -- Attempt to parse the *contents* of the string again. If that succeeds
      -- we recurse, otherwise we just return the decoded Lean string `s`.
      match Lean.Json.parse s with
      | .ok inner => aux inner
      | .error _  => sanitizeAscii s
    | .arr arr =>
      let elems := arr.map aux
      s!"#[{String.intercalate ", " elems.toList}]"
    | .obj o => (Lean.Json.obj o).compress  -- Fall back to compressed JSON representation
    | other   => other.compress
  aux j

/-! ## Process Management and Data Generation -/

/-- Generate test data using Python subprocess call with enhanced error handling -/
def generateData (strategyName : String) (numExamples : Nat := 100) : IO (Option String) := do
  try
    let currentDir ← IO.currentDir
    let result ← IO.Process.output {
      cmd := "uv"
      args := #["run", "leanhypothesis", "generate", strategyName, toString numExamples]
      cwd := some s!"{currentDir}/python"
    }
    if result.exitCode = 0 then
      -- Extract JSON from output (filter out warnings)
      let lines := result.stdout.splitOn "\n"
      let jsonLine := lines.find? (·.startsWith "{")
      match jsonLine with
      | some json =>
        let parsed := parsePythonResult json s!"generateData({strategyName})"
        match parsed with
        | .ok p =>
          IO.eprintln s!"[FFI] ✓ Successfully parsed: {p.status}"
          if p.status == "success" then
            return some p.data
          else
            IO.eprintln s!"[FFI] ✗ Error: {p.error.getD "Unknown error"}"
            return none
        | .error e =>
          IO.eprintln s!"[FFI] ✗ Parse error: {repr e}"
          return none
      | none =>
        IO.eprintln s!"[FFI] ✗ No JSON found in output: {result.stdout.take 200}..."
        return none
    else
      IO.eprintln s!"[FFI] Python Error (exit {result.exitCode}): {result.stderr}"
      IO.eprintln s!"[FFI] Command was: uv run leanhypothesis generate {strategyName} {numExamples}"
      return none
  catch e =>
    IO.eprintln s!"[FFI] Process Error: {e}"
    return none

/-- Run a property test via Python bridge with enhanced error handling -/
def runPropertyTest (strategyName : String) (propertyFn : String) (numTests : Nat := 100) : IO Bool := do
  try
    let currentDir ← IO.currentDir
    let result ← IO.Process.output {
      cmd := "uv"
      args := #["run", "leanhypothesis", "test", strategyName, propertyFn, toString numTests]
      cwd := some s!"{currentDir}/python"
    }
    if result.exitCode = 0 then
      -- Extract first JSON object in stdout in case of warnings/logs
      let lines := result.stdout.splitOn "\n"
      let jsonLine := lines.find? (·.startsWith "{") |>.getD result.stdout.trim
      -- Parse JSON directly
      match Lean.Json.parse jsonLine with
      | .ok json =>
        match json.getObjVal? "status" with
        | .ok statusJson =>
          match statusJson.getStr? with
          | .ok "success" => return true
          | .ok "failure" =>
            -- Extract and display counterexamples
            match json.getObjVal? "results" with
            | .ok resultsJson =>
              match resultsJson.getObjVal? "failures" with
              | .ok failuresJson =>
                match failuresJson.getArr? with
                | .ok failures =>
                  if failures.size > 0 then
                    IO.eprintln s!"[FFI] ✗ Found {failures.size} counterexample(s):"
                    for i in [0:failures.size] do
                      let failure := failures[i]!
                      match failure.getObjVal? "value" with
                      | .ok valueJson =>
                        let pretty := jsonPretty valueJson
                        IO.eprintln s!"  [{i+1}] Counterexample: {pretty}"
                        -- Show shrinks if available, but prefer the *final* shrunk value
                        match failure.getObjVal? "shrinks" with
                        | .ok shrinksJson =>
                          match shrinksJson.getArr? with
                          | .ok shrinks =>
                            if shrinks.size > 0 then
                              let final := shrinks[shrinks.size - 1]! -- Lean's arrays are 0-indexed and size > 0
                              IO.eprintln s!"      Final shrink: {jsonPretty final}"
                              if shrinks.size > 1 then
                                -- Optionally also show a preview of the first few intermediate shrinks
                                let preview := (shrinks.take 4).map jsonPretty
                                IO.eprintln s!"      Shrink trace: {preview}"
                          | _ => pure ()
                        | _ => pure ()
                      | _ => pure ()
                | _ => pure ()
              | _ => pure ()
            | _ => pure ()
            return false
          | .ok "error" =>
            match json.getObjVal? "error" with
            | .ok errorJson =>
              match errorJson.getStr? with
              | .ok error => IO.eprintln s!"[FFI] ✗ Error: {error}"
              | _ => IO.eprintln "[FFI] ✗ Unknown error"
            | _ => IO.eprintln "[FFI] ✗ Unknown error"
            return false
          | _ =>
            IO.eprintln "[FFI] ✗ Unknown status"
            return false
        | _ =>
          IO.eprintln "[FFI] ✗ Missing status field"
          return false
      | .error e =>
        IO.eprintln s!"[FFI] ✗ JSON parse error: {e}"
        return false
    else
      IO.eprintln s!"[FFI] Python Error: {result.stderr}"
      return false
  catch e =>
    IO.eprintln s!"[FFI] Process Error: {e}"
    return false

/-! ## Debug and Monitoring Utilities -/

/-- Check if the Python bridge is available and working -/
def checkBridge : IO Bool := do
  try
    let currentDir ← IO.currentDir
    let result ← IO.Process.output {
      cmd := "uv"
      args := #["run", "leanhypothesis", "--help"]
      cwd := some s!"{currentDir}/python"
    }
    if result.exitCode = 0 then
      IO.eprintln s!"[FFI] ✓ Bridge available: {result.stdout.trim}"
      return true
    else
      IO.eprintln s!"[FFI] ✗ Bridge unavailable: {result.stderr}"
      return false
  catch e =>
    IO.eprintln s!"[FFI] ✗ Bridge check failed: {e}"
    return false

end LeanHypothesis.FFI
