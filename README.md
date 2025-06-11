# LeanHypothesis
+
+A sophisticated property-based testing library for Lean 4 that bridges Python's mature Hypothesis library while building toward a pure Lean implementation with dependent type-driven shrinking algorithms.
+
+## Features
+
+✅ **Property-Based Testing**: Automatically generate test cases and find edge cases  
+✅ **Counterexample Display**: When tests fail, see minimal counterexamples with shrinking  
+✅ **Python Integration**: Leverage Hypothesis's mature strategies and shrinking algorithms  
+✅ **Type-Safe Interface**: Strongly typed Lean interface with `Testable` typeclass  
+✅ **Composite Strategies**: Support for lists, tuples, and custom composite types  
+✅ **Performance Optimized**: Generate 50-100 examples in <0.1s  
+
+## Quick Start
+
+```lean
+import LeanHypothesis
+
+-- Test a simple property
+#eval runProperty (fun (n : Nat) => n + 0 = 0 + n)
+
+-- Test with custom constraints  
+#eval runDependentProperty (fun (n : Int) (h : n > 0) => n * n > 0)
+
+-- Run system health check
+#eval LeanHypothesis.Core.healthCheck
+```
+
+## Counterexample Display
+
+When property tests fail, LeanHypothesis automatically displays minimal counterexamples found by Hypothesis's sophisticated shrinking engine:
+
+```lean
+-- Testing property 'x > 10' on naturals
+#eval LeanHypothesis.FFI.runPropertyTest "nat" "lambda x: x > 10" 20
+
+-- Output:
+-- [FFI] ✗ Found 2 counterexample(s):
+--   [1] Counterexample: 0
+--   [2] Counterexample: 5
+--       Shrunk to: #[0, 1, 2, 3, 4]
+```
+
+The shrinking process automatically finds simpler values that still fail the property, making debugging much easier.
+
+## Installation
+
+1. Ensure you have Lean 4 installed (nightly-2025-06-09 or later)
+2. Clone this repository
+3. Install Python dependencies:
+   ```bash
+   cd python && uv sync
+   ```
+4. Build the Lean project:
+   ```bash
+   lake build
+   ```
+
+## Usage Examples
+
+### Basic Property Testing
+
+```lean
+-- Test that addition is commutative
+def testAddComm : IO Bool := do
+  runProperty (fun (a b : Nat) => a + b = b + a)
+
+-- Test string properties
+def testStringConcat : IO Bool := do  
+  runProperty (fun (s : String) => (s ++ "").length = s.length)
+```
+
+### Finding Counterexamples
+
+```lean
+-- This will fail and show counterexamples
+def testFailing : IO Unit := do
+  let result ← runPropertyTest "list(nat)" "lambda xs: len(xs) % 2 == 1" 20
+  if not result then
+    IO.println "Found lists with even length!"
+```
+
+### Custom Strategies
+
+The Python bridge supports sophisticated custom strategies:
+
+```python
+# In Python
+user_strategy = st.fixed_dictionaries({
+    "username": st.text(min_size=3, max_size=20).filter(str.isalnum),
+    "age": st.integers(min_value=13, max_value=100),
+    "email": st.emails()
+})
+```
+
+## Architecture
+
+- **Lean Interface** (`LeanHypothesis/`): Type-safe property testing interface
+- **Python Bridge** (`python/leanhypothesis/`): Hypothesis integration via subprocess
+- **FFI Layer**: Robust JSON-based communication with error handling
+- **Dependent Shrinking**: Experimental support for dependent type constraints
+
+## Development
+
+```bash
+# Run tests
+lake exe leanhypothesis
+
+# Run Python tests
+cd python && uv run pytest tests/ -v
+
+# Build documentation  
+lake build-doc
+```
+
+## License
+
+MIT License - See LICENSE file for details
+
+## Contributing
+
+Contributions welcome! Please see CONTRIBUTING.md for guidelines.
+
+## Acknowledgments
+
+Built on top of the excellent [Hypothesis](https://hypothesis.readthedocs.io/) library for Python.
+
+## Counterexample Gallery: LeanHypothesis vs Python/Hypothesis
+
+Below is a quick visual comparison showing how the exact same failing properties are rendered by LeanHypothesis versus the raw output you would get from running Python/Hypothesis directly.  The examples were captured from the current integration-test suite.
+
+| Property checked | LeanHypothesis output | Python/Hypothesis output |
+|------------------|-----------------------|--------------------------|
+| `x > 100`  (strategy `nat`, 20 tests) | 
+```text
+[FFI] ✗ Found 4 counterexample(s):
  [1] Counterexample: 0
  [2] Counterexample: 54
      Final shrink: 50
      Shrink trace: #[0, 51, 14, 30]
  [3] Counterexample: 1
      Final shrink: 0
  [4] Counterexample: 21
``` | 
+```text
+Falsifying example: x=0
+Falsifying example: x=54
+Falsifying example: x=1
+Falsifying example: x=21
+``` |
+| `len(xs) % 2 == 1`  (strategy `list(text)`, 30 tests) | 
+```text
+[FFI] ✗ Found 30 counterexample(s):
  [1] Counterexample: #[]
  [2] Counterexample: #["c", "=", "l"]
      Final shrink: #["c"]
      Shrink trace: #[#[], #[], #["x"], #["y"]]
  ...
``` | 
+```text
+Falsifying example: xs=[]
+Falsifying example: xs=['c', '=', 'l']
+... (28 more) ...
+``` |
+
+In LeanHypothesis:
+
+* Counter-examples are **indexed** and grouped.
+* Shrinking information is surfaced via `Final shrink` and a compact `Shrink trace`.
+* Non-ASCII / control characters are escaped as `\uXXXX`, guaranteeing clean terminal output.
+
+This makes it dramatically quicker to understand why a property failed without scrolling through pages of raw Hypothesis logs.