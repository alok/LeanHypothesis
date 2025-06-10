import LeanHypothesis.Strategy
import LeanHypothesis.FFI

/-!
# Ergonomic Syntax for LeanHypothesis

This module provides user-friendly syntax for property-based testing.
For now, we use standard Lean syntax with helper functions for ergonomics.
Future versions will include custom metaprogramming syntax.
-/

namespace LeanHypothesis.Syntax

-- Helper function for creating property tests with ergonomic syntax
def defineProperty {α : Type} [Testable α] (name : String) (property : α → Bool) (numTests : Nat := 100) : IO Bool := do
  IO.println s!"Testing property: {name}"
  runProperty property numTests

-- Helper macro for hypothesis-style quantification (simplified)
macro "hypothesis" x:ident ":" t:term "," body:term : term => `(fun ($x : $t) => $body)

-- Strategy composition helpers
def listStrategy (inner : String) : String := s!"list({inner})"
def tupleStrategy (components : List String) : String := s!"tuple({String.intercalate "," components})"
def recordStrategy (fields : List (String × String)) : String := 
  let fieldStrs := fields.map (fun (name, type) => s!"{name}:{type}")
  s!"record({String.intercalate "," fieldStrs})"

-- Example usage patterns (these would be expanded in gallery examples)
-- property additionCommutative : Nat where hypothesis (n m : Nat), n + m = m + n
-- becomes:
-- def additionCommutativeTest : IO Bool := 
--   defineProperty "additionCommutative" (hypothesis n : Nat, hypothesis m : Nat, n + m = m + n)

end LeanHypothesis.Syntax
