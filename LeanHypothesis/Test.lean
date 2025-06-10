import LeanHypothesis.Strategy
import LeanHypothesis.FFI

/-!
# Integration Tests for LeanHypothesis

This module contains integration tests that demonstrate the full
Python → Lean binding functionality.
-/

namespace LeanHypothesis.Test

open LeanHypothesis.FFI

/-- Test Python data generation integration -/
def testPythonIntegration : IO Unit := do
  IO.println "=== Testing Python Integration ==="
  
  -- Test basic data generation
  IO.println "Testing integer generation..."
  match ← generateData "int" 5 with
  | some data => 
    IO.println s!"✓ Generated integer data: {data.take 100}..."
  | none => 
    IO.println "✗ Failed to generate integer data"
  
  IO.println "Testing natural number generation..."
  match ← generateData "nat" 3 with
  | some data => 
    IO.println s!"✓ Generated nat data: {data.take 100}..."
  | none => 
    IO.println "✗ Failed to generate nat data"
  
  IO.println "Testing text generation..."
  match ← generateData "text" 2 with
  | some data => 
    IO.println s!"✓ Generated text data: {data.take 150}..."
  | none => 
    IO.println "✗ Failed to generate text data"

/-- Test property testing integration -/
def testPropertyTesting : IO Unit := do
  IO.println "\n=== Testing Property Testing ==="
  
  -- Test simple property
  IO.println "Testing simple property (always true)..."
  let result ← runPropertyTest "nat" "lambda x: x >= 0" 10
  if result then
    IO.println "✓ Property test passed"
  else
    IO.println "✗ Property test failed"

/-- Test strategy generation with Lean types -/
def testLeanStrategies : IO Unit := do
  IO.println "\n=== Testing Lean Strategy Integration ==="
  
  -- Test Nat property
  IO.println "Testing Nat property: addition commutativity..."
  let result1 ← runProperty (fun (n : Nat) => n + 0 = 0 + n)
  IO.println s!"Result: {result1}"
  
  -- Test String property
  IO.println "Testing String property: length invariant..."
  let result2 ← runProperty (fun (s : String) => (s ++ "").length = s.length)
  IO.println s!"Result: {result2}"
  
  -- Test List property
  IO.println "Testing List property: length is non-negative..."
  let result3 ← runProperty (fun (xs : List Nat) => xs.length >= 0)
  IO.println s!"Result: {result3}"

/-- Comprehensive integration test -/
def runIntegrationTests : IO Unit := do
  IO.println "🚀 Starting LeanHypothesis Integration Tests\n"
  
  testPythonIntegration
  testPropertyTesting
  testLeanStrategies
  
  IO.println "\n✅ Integration tests completed!"

#eval runIntegrationTests

end LeanHypothesis.Test
