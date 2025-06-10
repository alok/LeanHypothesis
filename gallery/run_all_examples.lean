/-!
# Gallery Test Runner

Main entry point for running all LeanHypothesis gallery examples.
Demonstrates the full range of capabilities from basic to domain-specific.
-/

import LeanHypothesis

-- Import all gallery examples
-- Note: These would need to be added to the lakefile once we have proper compilation

def runCompleteGallery : IO Unit := do
  IO.println "🎨 LeanHypothesis Complete Gallery"
  IO.println "=" * 40
  IO.println "Comprehensive demonstration of Lean property-based testing"
  IO.println "with Python Hypothesis integration\n"
  
  IO.println "📋 Available Examples:"
  IO.println "1. Basic Properties (basic_properties.lean)"
  IO.println "2. Advanced Properties (advanced_properties.lean)"  
  IO.println "3. Domain Examples (domain_examples.lean)"
  IO.println ""
  
  -- For now, just show the structure since we need proper compilation
  IO.println "🔧 To run specific examples:"
  IO.println "  lake exe basic_properties"
  IO.println "  lake exe advanced_properties"
  IO.println "  lake exe domain_examples"
  IO.println ""
  
  IO.println "✨ Features Showcased:"
  IO.println "• Ergonomic property syntax using Lean metaprogramming"
  IO.println "• Custom strategy definitions with domain constraints"
  IO.println "• Recursive data structure generation"
  IO.println "• Mathematical structure properties"
  IO.println "• Stateful and protocol testing"
  IO.println "• Real-world domain examples"
  IO.println "• Seamless Python Hypothesis integration under the hood"
  IO.println "• Type-safe property testing with sophisticated shrinking"

#eval runCompleteGallery
