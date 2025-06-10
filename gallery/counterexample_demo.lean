import LeanHypothesis

/-!
# Counterexample Discovery Demo

This demonstrates LeanHypothesis finding counterexamples to false properties,
showcasing the power of Hypothesis's sophisticated test data generation.
-/

open LeanHypothesis

-- Example 1: Flawed arithmetic property (should fail)
def testFlawedSubtraction : IO Bool := do
  IO.println "Testing flawed property: a - b = b - a..."
  -- This should fail! Subtraction is NOT commutative
  runProperty (fun (pair : Nat × Nat) => 
    let a := pair.1
    let b := pair.2
    a - b = b - a)

-- Example 2: Flawed list property (should fail)  
def testFlawedListReverse : IO Bool := do
  IO.println "Testing flawed property: reverse of singleton is empty..."
  -- This should fail! reverse [x] = [x], not []
  runProperty (fun (xs : List Nat) => 
    xs.length = 1 → xs.reverse = [])

-- Example 3: Flawed string property (should fail)
def testFlawedStringLength : IO Bool := do
  IO.println "Testing flawed property: all strings have even length..."
  -- This should fail! Many strings have odd length
  runProperty (fun (s : String) => s.length % 2 = 0)

-- Example 4: Boundary condition failure (should fail)
def testFlawedDivision : IO Bool := do
  IO.println "Testing flawed property: division is always smaller..."
  -- This should fail! What about division by numbers < 1?
  runProperty (fun (pair : Nat × Nat) => 
    let a := pair.1
    let b := pair.2
    b > 0 → a / b ≤ a)

-- Example 5: Mathematical misconception (should fail)
def testFlawedSquare : IO Bool := do
  IO.println "Testing flawed property: square root is always smaller..."
  -- This should fail! sqrt(x) > x for 0 < x < 1 (but we're using Nat, so different failure)
  runProperty (fun (n : Nat) => 
    n > 0 → n * n ≤ n)

-- Example 6: A property that should pass (control)
def testCorrectProperty : IO Bool := do
  IO.println "Testing correct property: list length non-negative..."
  runProperty (fun (xs : List Nat) => xs.length ≥ 0)

-- Demonstrate counterexample discovery
def demonstrateCounterexamples : IO Unit := do
  IO.println "🔍 LeanHypothesis Counterexample Discovery Demo"
  IO.println "================================================"
  IO.println "Testing intentionally flawed properties to show counterexample finding\n"
  
  -- Test flawed properties (should fail and show counterexamples)
  IO.print "❌ Flawed subtraction commutativity... "
  let result1 ← testFlawedSubtraction
  IO.println (if result1 then "UNEXPECTED PASS" else "✓ CORRECTLY FAILED")
  
  IO.print "❌ Flawed list reverse property... "
  let result2 ← testFlawedListReverse
  IO.println (if result2 then "UNEXPECTED PASS" else "✓ CORRECTLY FAILED")
  
  IO.print "❌ Flawed string length property... "
  let result3 ← testFlawedStringLength
  IO.println (if result3 then "UNEXPECTED PASS" else "✓ CORRECTLY FAILED")
  
  IO.print "❌ Flawed division property... "
  let result4 ← testFlawedDivision
  IO.println (if result4 then "UNEXPECTED PASS" else "✓ CORRECTLY FAILED")
  
  IO.print "❌ Flawed square property... "
  let result5 ← testFlawedSquare
  IO.println (if result5 then "UNEXPECTED PASS" else "✓ CORRECTLY FAILED")
  
  -- Test correct property (should pass)
  IO.print "✅ Correct list length property... "
  let result6 ← testCorrectProperty
  IO.println (if result6 then "✓ CORRECTLY PASSED" else "UNEXPECTED FAIL")
  
  IO.println "\n🎯 What This Demonstrates:"
  IO.println "• LeanHypothesis finds counterexamples to false properties"
  IO.println "• Hypothesis generates diverse test cases under the hood"
  IO.println "• Failed properties get minimal counterexamples via shrinking"
  IO.println "• Correct properties pass with confidence"
  IO.println "• Everything runs in pure Lean with type safety"

#eval! demonstrateCounterexamples
