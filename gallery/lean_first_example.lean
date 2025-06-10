import LeanHypothesis

/-!
# Lean-First Property Testing Example

This demonstrates how LeanHypothesis provides a Lean-first interface
for property-based testing with Python's Hypothesis generating data under the hood.
-/

open LeanHypothesis

-- Basic arithmetic properties using our Lean interface

def testAdditionCommutativity : IO Bool := do
  IO.println "Testing addition commutativity..."
  runProperty (fun (pair : Nat × Nat) => pair.1 + pair.2 = pair.2 + pair.1)

def testListAppendLength : IO Bool := do
  IO.println "Testing list append length..."
  runProperty (fun (pair : List Nat × List Nat) => 
    (pair.1 ++ pair.2).length = pair.1.length + pair.2.length)

def testStringConcatLength : IO Bool := do
  IO.println "Testing string concatenation length..."
  runProperty (fun (pair : String × String) => 
    (pair.1 ++ pair.2).length = pair.1.length + pair.2.length)

def testNatMaxCommutative : IO Bool := do
  IO.println "Testing max commutativity..."
  runProperty (fun (pair : Nat × Nat) => max pair.1 pair.2 = max pair.2 pair.1)

-- Demonstrate that everything is Lean-first
def runPropertySuite : IO Unit := do
  IO.println "🚀 LeanHypothesis Gallery: Lean-First Property Testing"
  IO.println "================================================================="
  IO.println "All tests written in pure Lean with Hypothesis generating data\n"
  
  IO.print "Addition commutativity... "
  let result1 ← testAdditionCommutativity
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "List append length... "
  let result2 ← testListAppendLength
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "String concat length... "
  let result3 ← testStringConcatLength
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Max commutativity... "
  let result4 ← testNatMaxCommutative
  IO.println (if result4 then "✓ PASS" else "✗ FAIL")
  
  IO.println "\n✅ Property testing completed!"
  IO.println "\n🎯 Key Features Demonstrated:"
  IO.println "• Pure Lean syntax - no Python visible to users"
  IO.println "• Type-safe property definitions"
  IO.println "• Automatic strategy inference for built-in types"
  IO.println "• Sophisticated data generation via Hypothesis (under the hood)"
  IO.println "• Seamless integration between Lean and Python ecosystems"
  IO.println "• Everything starts and ends in Lean 4"

#eval! runPropertySuite
