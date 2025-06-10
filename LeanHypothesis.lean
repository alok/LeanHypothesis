import LeanHypothesis.Core
import LeanHypothesis.Strategy  
import LeanHypothesis.FFI
import LeanHypothesis.DependentShrink
import LeanHypothesis.Test

/-!
# LeanHypothesis Library

A sophisticated property-based testing library for Lean 4 that bridges Python's 
mature Hypothesis library while building toward a pure Lean implementation with
dependent type-driven shrinking algorithms.

## Quick Start

```lean
import LeanHypothesis

-- Test a simple property
#eval runProperty (fun (n : Nat) => n + 0 = 0 + n)

-- Test with custom constraints
#eval runDependentProperty (fun (n : Int) (h : n > 0) => n * n > 0) 

-- Run system health check
#eval LeanHypothesis.Core.healthCheck
```

## Modules

- **Core**: Main unified interface with examples and diagnostics
- **Strategy**: Type-safe strategy definitions and property testing
- **FFI**: Robust Python bridge with comprehensive error handling
- **DependentShrink**: Future-oriented dependent type shrinking algorithms
- **Test**: Integration tests and advanced examples

## Research Integration

This library incorporates insights from recent research on dependent types,
property-based testing, and verification. It provides a foundation for
advancing the state of the art in type-driven test generation.

For detailed documentation, see individual module files.
-/
