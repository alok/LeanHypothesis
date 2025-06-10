"""
Strategy Generator: Converts Hypothesis strategies to Lean-compatible data
"""

import json
from typing import Any, List, Dict, Optional
from hypothesis import strategies as st, given, settings, Phase
from hypothesis.database import InMemoryExampleDatabase
from hypothesis.internal.conjecture.engine import ConjectureRunner
from hypothesis.internal.conjecture.data import ConjectureData


class StrategyGenerator:
    """Generates test data using Hypothesis strategies for Lean consumption"""

    def __init__(self):
        self._strategies = {
            "nat": st.integers(min_value=0),
            "int": st.integers(),
            "text": st.text(),
            "bool": st.booleans(),
            "float": st.floats(allow_nan=False, allow_infinity=False),
        }
        self._database = InMemoryExampleDatabase()

    def register_strategy(self, name: str, strategy: st.SearchStrategy) -> None:
        """Register a custom strategy"""
        self._strategies[name] = strategy

    def generate_data(
        self, strategy_name: str, num_examples: int = 100
    ) -> List[Dict[str, Any]]:
        """Generate test data using Hypothesis's sophisticated engine"""
        # Resolve strategy: built-in first, else attempt composite parsing
        strategy: st.SearchStrategy
        if strategy_name in self._strategies:
            strategy = self._strategies[strategy_name]
        else:
            # Try to parse composite strategy specifications like "list(nat)"
            strategy = self.parse_composite_strategy(strategy_name)
            # Cache this parsed strategy to avoid re-parsing next time
            self._strategies[strategy_name] = strategy

        examples = []

        # Use Hypothesis's internal engine for better data generation
        def test_function(value):
            """Dummy test function that always passes - we just want the data"""
            examples.append({
                "value": self._serialize_value(value),
                "shrinks": [],  # We'll populate this below
                "type": strategy_name,
                "interesting": False,
            })
            return True

        # Configure settings for comprehensive testing
        test_settings = settings(
            max_examples=num_examples,
            database=self._database,
            phases=[Phase.explicit, Phase.reuse, Phase.generate, Phase.target],
            deadline=None,
        )

        # Run the test to collect examples
        try:
            with test_settings:
                test_decorated = given(strategy)(test_function)
                # Actually call the test to generate examples
                test_decorated()
        except Exception as e:
            # If the sophisticated approach fails, fall back to simple generation
            print(f"Falling back to simple generation: {e}")
            examples = []
            for _ in range(min(num_examples, 50)):
                try:
                    value = strategy.example()
                    examples.append({
                        "value": self._serialize_value(value),
                        "shrinks": [],
                        "type": strategy_name,
                        "interesting": False,
                    })
                except Exception:
                    continue

        # Now generate shrinking examples for the first few
        for i, example in enumerate(examples[: min(5, len(examples))]):
            try:
                original_value = self._deserialize_value(
                    example["value"], strategy_name
                )
                shrinks = self._generate_shrinks_sophisticated(strategy, original_value)
                example["shrinks"] = [self._serialize_value(s) for s in shrinks]
            except Exception:
                continue

        return examples

    def _deserialize_value(self, serialized: str, strategy_name: str) -> Any:
        """Deserialize a value back to its original form"""
        if strategy_name in ["nat", "int"]:
            return int(serialized)
        elif strategy_name == "bool":
            return serialized == "True"
        elif strategy_name == "text":
            return json.loads(serialized)
        elif strategy_name == "float":
            return float(serialized)
        else:
            return json.loads(serialized)

    def _generate_shrinks_sophisticated(
        self, strategy: st.SearchStrategy, value: Any, max_shrinks: int = 10
    ) -> List[Any]:
        """Generate shrunk versions using Hypothesis's sophisticated shrinking"""
        shrinks = []

        # Use Hypothesis's internal shrinking capabilities
        try:
            from hypothesis.internal.conjecture.engine import ConjectureRunner
            from hypothesis.internal.conjecture.data import ConjectureData, Status

            def test_function(data):
                try:
                    generated = data.draw(strategy)
                    # We want to find values "smaller" than our original
                    if self._is_smaller(generated, value):
                        shrinks.append(generated)
                        if len(shrinks) >= max_shrinks:
                            data.mark_interesting()
                except Exception:
                    pass

            # Run the conjecture engine to find shrinks
            runner = ConjectureRunner(test_function, settings=settings(max_examples=50))
            runner.run()

        except Exception:
            # Fallback to simple shrinking
            shrinks = self._generate_simple_shrinks(strategy, value, max_shrinks)

        return shrinks[:max_shrinks]

    def _is_smaller(self, candidate: Any, original: Any) -> bool:
        """Determine if candidate is "smaller" than original for shrinking purposes"""
        try:
            if isinstance(original, (int, float)):
                return abs(candidate) < abs(original)
            elif isinstance(original, str):
                return len(candidate) <= len(original) and candidate != original
            elif isinstance(original, list):
                return len(candidate) <= len(original) and candidate != original
            elif isinstance(original, bool):
                return candidate == False and original == True
            else:
                return candidate != original
        except:
            return False

    def _generate_simple_shrinks(
        self, strategy: st.SearchStrategy, value: Any, max_shrinks: int = 5
    ) -> List[Any]:
        """Fallback simple shrinking method"""
        shrinks = []

        # Type-specific shrinking
        if isinstance(value, int):
            # Try smaller integers
            for candidate in [0, 1, -1, value // 2, value - 1, value + 1]:
                if candidate != value and abs(candidate) <= abs(value):
                    shrinks.append(candidate)
                    if len(shrinks) >= max_shrinks:
                        break
        elif isinstance(value, str):
            # Try shorter strings
            if len(value) > 0:
                shrinks.extend(["", value[: len(value) // 2], value[1:], value[:-1]])
        elif isinstance(value, bool):
            if value:
                shrinks.append(False)

        return shrinks[:max_shrinks]

    def _serialize_value(self, value: Any) -> str:
        """Serialize a value to a string that Lean can parse"""
        if isinstance(value, (int, float, bool)):
            return str(value)
        elif isinstance(value, str):
            return json.dumps(value)  # Properly escape strings
        elif isinstance(value, list):
            return json.dumps([self._serialize_value(item) for item in value])
        elif isinstance(value, dict):
            return json.dumps({k: self._serialize_value(v) for k, v in value.items()})
        else:
            return json.dumps(str(value))

    def parse_composite_strategy(self, strategy_spec: str) -> st.SearchStrategy:
        """Parse composite strategy specifications like 'list(int)' or 'dict(text,nat)'"""
        if strategy_spec.startswith("list(") and strategy_spec.endswith(")"):
            inner_spec = strategy_spec[5:-1]
            inner_strategy = self._parse_strategy_spec(inner_spec)
            return st.lists(inner_strategy)
        elif strategy_spec.startswith("dict(") and strategy_spec.endswith(")"):
            # dict(key_type,value_type)
            inner = strategy_spec[5:-1]
            parts = inner.split(",")
            if len(parts) == 2:
                key_strategy = self._parse_strategy_spec(parts[0].strip())
                value_strategy = self._parse_strategy_spec(parts[1].strip())
                return st.dictionaries(key_strategy, value_strategy)

        return self._strategies.get(strategy_spec, st.text())

    def _parse_strategy_spec(self, spec: str) -> st.SearchStrategy:
        """Parse a strategy specification"""
        if spec in self._strategies:
            return self._strategies[spec]
        else:
            return self.parse_composite_strategy(spec)
