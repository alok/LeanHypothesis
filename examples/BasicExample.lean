/-!
# Basic LeanHypothesis Example

This example demonstrates how to use LeanHypothesis to run
property-based tests using Python's Hypothesis library.
-/

import LeanHypothesis

open LeanHypothesis

-- Example 1: Testing addition commutativity
def testAdditionCommutativity : IO Bool := do
  let property := fun (n : Nat) => n + 0 = 0 + n
  runProperty property

-- Example 2: Testing list length property  
def testListLength : IO Bool := do
  let property := fun (xs : List Nat) => xs.length >= 0
  runProperty property

-- Example 3: Testing string properties
def testStringConcat : IO Bool := do
  let property := fun (s : String) => (s ++ "").length = s.length
  runProperty property

-- Main test runner
def main : IO Unit := do
  IO.println "Running LeanHypothesis examples..."
  
  IO.println "Testing addition commutativity..."
  let result1 ← testAdditionCommutativity
  IO.println s!"Result: {result1}"
  
  IO.println "Testing list length property..."
  let result2 ← testListLength  
  IO.println s!"Result: {result2}"
  
  IO.println "Testing string concatenation..."
  let result3 ← testStringConcat
  IO.println s!"Result: {result3}"
  
  IO.println "Done!"

#eval main
