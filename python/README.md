# LeanHypothesis Python Bridge

Python bindings for Lean 4 property-based testing using Hypothesis.

## Installation

```bash
uv sync
```

## Usage

```python
from leanhypothesis import StrategyGenerator, LeanBridge

# Generate test data
generator = StrategyGenerator()
data = generator.generate_data("int", 100)

# Use bridge for Lean integration
bridge = LeanBridge()
result = bridge.generate_test_data("nat", 50)
```

## CLI Usage

```bash
uv run leanhypothesis generate int 10
uv run leanhypothesis test nat "lambda x: x >= 0" 100
```
