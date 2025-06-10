import Lean.Data.Json

/-!
# FFI Bridge for Python Hypothesis

This module provides the Foreign Function Interface (FFI) layer
to communicate with the Python Hypothesis bridge.
-/

namespace LeanHypothesis.FFI

/-- Parse JSON result from Python bridge -/
structure PythonResult where
  status : String
  data : String
  error : Option String

def parsePythonResult (jsonStr : String) : Option PythonResult := do
  -- Parse JSON using Lean's built-in JSON parser
  match Lean.Json.parse jsonStr with
  | .ok json =>
    match json.getObjVal? "status" with
    | .ok statusJson =>
      match statusJson.getStr? with
      | .ok "success" => some ⟨"success", jsonStr, none⟩
      | .ok "error" =>
        let errorMsg := json.getObjVal? "error" |>.toOption |>.bind (·.getStr?.toOption) |>.getD "Unknown error"
        some ⟨"error", "", some errorMsg⟩
      | _ => none
    | _ => none
  | _ => none

/-- Generate test data using Python subprocess call -/
def generateData (strategyName : String) (numExamples : Nat := 100) : IO (Option String) := do
  try
    let currentDir ← IO.currentDir
    let cmd := s!"cd {currentDir}/python && uv run leanhypothesis generate {strategyName} {numExamples}"
    let result ← IO.Process.output {
      cmd := "sh"
      args := #["-c", cmd]
    }
    if result.exitCode = 0 then
      -- Extract JSON from output (filter out warnings)
      let lines := result.stdout.splitOn "\n"
      let jsonLine := lines.find? (·.startsWith "{")
      match jsonLine with
      | some json => 
        let parsed := parsePythonResult json
        match parsed with
        | some p => 
          IO.eprintln s!"✓ Successfully parsed: {p.status}"
          return some p.data
        | none => 
          IO.eprintln s!"✗ Failed to parse JSON: {json.take 100}..."
          return none
      | none => 
        IO.eprintln s!"✗ No JSON found in output: {result.stdout.take 200}..."
        return none
    else
      IO.eprintln s!"Python Error (exit {result.exitCode}): {result.stderr}"
      IO.eprintln s!"Command was: {cmd}"
      IO.eprintln s!"Stdout: {result.stdout}"
      return none
  catch e =>
    IO.eprintln s!"Process Error: {e}"
    return none

/-- Run a property test via Python bridge -/
def runPropertyTest (strategyName : String) (propertyFn : String) (numTests : Nat := 100) : IO Bool := do
  try
    let currentDir ← IO.currentDir
    let cmd := s!"cd {currentDir}/python && uv run leanhypothesis test {strategyName} '{propertyFn}' {numTests}"
    let result ← IO.Process.output {
      cmd := "sh"
      args := #["-c", cmd]
    }
    if result.exitCode = 0 then
      let parsed := parsePythonResult result.stdout
      return parsed.map (·.status == "success") |>.getD false
    else
      IO.eprintln s!"Python Error: {result.stderr}"
      return false
  catch e =>
    IO.eprintln s!"Process Error: {e}"
    return false

end LeanHypothesis.FFI
