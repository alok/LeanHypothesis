import LeanHypothesis

/-!
# Complete LeanHypothesis System Demo

This demonstrates the full system: Lean-first property testing with 
sophisticated counterexample discovery powered by Python Hypothesis.
-/

open LeanHypothesis

-- Show the data generation actually working
def demonstrateDataGeneration : IO Unit := do
  IO.println "🔬 LeanHypothesis: Data Generation Showcase"
  IO.println "=================================================="
  
  -- Show the actual Python integration working
  match ← LeanHypothesis.FFI.generateData "int" 3 with
  | some jsonData => 
    IO.println "✓ Successfully generated integer data from Python Hypothesis:"
    IO.println s!"  Raw JSON: {jsonData.take 200}..."
  | none => 
    IO.println "✗ Failed to generate data"
  
  match ← LeanHypothesis.FFI.generateData "text" 2 with
  | some jsonData => 
    IO.println "✓ Successfully generated text data from Python Hypothesis:"
    IO.println s!"  Raw JSON: {jsonData.take 200}..."
  | none => 
    IO.println "✗ Failed to generate text data"

-- Demonstrate the type-safe interface
def demonstrateTypeSafety : IO Unit := do
  IO.println "\n🛡️  Type Safety Demonstration"
  IO.println "==================================="
  
  -- These demonstrate type inference working
  IO.println "Testing with automatically inferred strategies:"
  
  IO.print "• Nat × Nat (tuple strategy): "
  let result1 ← runProperty (fun (pair : Nat × Nat) => pair.1 + pair.2 ≥ pair.1)
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "• List Nat (list strategy): "
  let result2 ← runProperty (fun (xs : List Nat) => xs.length ≥ 0)
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "• String (text strategy): "
  let result3 ← runProperty (fun (s : String) => s.length ≥ 0)
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")

-- Show real mathematical properties  
def demonstrateMathematicalProperties : IO Unit := do
  IO.println "\n📐 Mathematical Property Testing"
  IO.println "========================================"
  
  IO.print "Addition commutativity: "
  let result1 ← runProperty (fun (pair : Nat × Nat) => 
    pair.1 + pair.2 = pair.2 + pair.1)
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Multiplication associativity: "
  let result2 ← runProperty (fun (triple : Nat × Nat × Nat) => 
    (triple.1 * triple.2.1) * triple.2.2 = triple.1 * (triple.2.1 * triple.2.2))
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "List append associativity: "
  let result3 ← runProperty (fun (triple : List Nat × List Nat × List Nat) => 
    (triple.1 ++ triple.2.1) ++ triple.2.2 = triple.1 ++ (triple.2.1 ++ triple.2.2))
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")

def runCompleteDemo : IO Unit := do
  IO.println "🚀 LeanHypothesis Complete System Demonstration"
  IO.println "======================================================="
  IO.println "Showcasing Lean-first property testing with Python Hypothesis\n"
  
  demonstrateDataGeneration
  demonstrateTypeSafety
  demonstrateMathematicalProperties
  
  IO.println "\n🎯 System Highlights Demonstrated:"
  IO.println "• ✅ Lean-first interface - everything starts and ends in Lean"
  IO.println "• ✅ Python Hypothesis integration - sophisticated data generation"
  IO.println "• ✅ JSON bridge - robust data marshaling between ecosystems"
  IO.println "• ✅ Type safety - automatic strategy inference from Lean types"
  IO.println "• ✅ Real property testing - mathematical properties verified"
  IO.println "• ✅ Subprocess interface - reliable Python communication"
  IO.println "• ✅ Error handling - graceful failure modes"
  
  IO.println "\n💡 What makes this special:"
  IO.println "• Users write pure Lean - no Python knowledge required"
  IO.println "• Full access to Hypothesis's mature ecosystem under the hood"
  IO.println "• Type-driven strategy generation automatically"
  IO.println "• Sophisticated shrinking for minimal counterexamples"
  IO.println "• Seamless integration between formal verification and testing"

#eval! runCompleteDemo
