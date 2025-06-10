import LeanHypothesis

/-!
# LeanHypothesis Demo

Demonstrates the sophisticated property-based testing capabilities of LeanHypothesis.
-/

def main : IO Unit := do
  IO.println "🚀 LeanHypothesis: Property-Based Testing for Lean 4"
  IO.println "================================================\n"

  -- Check system health
  IO.println "\n=== System Health Check ==="
  let healthy ← LeanHypothesis.Core.healthCheck
  if not healthy then
    IO.println "❌ System check failed - please ensure Python bridge is available"
    return

  -- Run performance benchmark
  IO.println "\n=== Performance Benchmark ==="
  LeanHypothesis.Core.benchmark

  -- Test dependent shrinking (experimental)
  IO.println "\n=== Dependent Shrinking Demo ==="
  let depResult ← LeanHypothesis.DependentShrink.runDependentProperty
    (fun (n : Nat) => n >= 0) 10
  IO.println s!"Dependent property test result: {depResult}"

  -- Run example test suite
  IO.println "\n=== Example Test Suite ==="
  let suiteResult ← LeanHypothesis.Core.exampleArithmetic
  IO.println s!"Test suite passed: {suiteResult}"

  -- Run integration tests
  LeanHypothesis.Test.runIntegrationTests

  IO.println "\n✨ LeanHypothesis is ready for property-based testing!"

  -- Demonstrate counterexample functionality
  IO.println "\n=== Counterexample Demo ==="
  IO.println "Testing property: all lists have even length"
  let result ← LeanHypothesis.FFI.runPropertyTest "list(nat)" "lambda xs: len(xs) % 2 == 0" 50
  if result then
    IO.println "✓ Property passed!"
  else
    IO.println "✗ Property failed (see counterexamples above)"
    IO.println "Note how Hypothesis found minimal counterexamples like single-element lists!"

  IO.println "\n✅ Demo completed successfully!"
