"""
Advanced tests for sophisticated Hypothesis features
"""

import json
import pytest
from hypothesis import given, strategies as st, settings, Phase, Verbosity
from hypothesis.database import InMemoryExampleDatabase
from hypothesis.stateful import RuleBasedStateMachine, rule, initialize, precondition
from leanhypothesis.generator import StrategyGenerator
from leanhypothesis.bridge import LeanBridge


class TestAdvancedFeatures:
    """Test sophisticated Hypothesis features integration"""

    def test_composite_strategies(self):
        """Test complex composite strategies"""
        generator = StrategyGenerator()
        
        # Register advanced composite strategies
        generator.register_strategy(
            "user_record",
            st.fixed_dictionaries({
                "id": st.integers(min_value=1, max_value=1000000),
                "name": st.text(min_size=1, max_size=50),
                "age": st.integers(min_value=0, max_value=120),
                "active": st.booleans(),
                "scores": st.lists(st.floats(min_value=0.0, max_value=100.0), min_size=0, max_size=10)
            })
        )
        
        data = generator.generate_data("user_record", 10)
        assert len(data) <= 10
        
        # Verify structure
        for example in data:
            parsed = json.loads(example["value"])
            assert "id" in parsed
            assert "name" in parsed
            assert "age" in parsed
            assert "active" in parsed
            assert "scores" in parsed
            print(f"Generated user: {parsed}")

    def test_filtered_strategies(self):
        """Test strategies with filters and assumptions"""
        generator = StrategyGenerator()
        
        # Even integers only
        even_ints = st.integers().filter(lambda x: x % 2 == 0)
        generator.register_strategy("even_int", even_ints)
        
        data = generator.generate_data("even_int", 20)
        
        for example in data:
            value = int(example["value"])
            assert value % 2 == 0, f"Expected even number, got {value}"
            print(f"Even integer: {value}")

    def test_recursive_strategies(self):
        """Test recursive data structures"""
        generator = StrategyGenerator()
        
        # JSON-like tree structure
        json_strategy = st.recursive(
            st.one_of(
                st.booleans(),
                st.integers(),
                st.text()
            ),
            lambda children: st.one_of(
                st.lists(children, max_size=3),
                st.dictionaries(st.text(max_size=10), children, max_size=3)
            ),
            max_leaves=10
        )
        
        generator.register_strategy("json_tree", json_strategy)
        data = generator.generate_data("json_tree", 5)
        
        for example in data:
            parsed = json.loads(example["value"])
            print(f"JSON tree: {parsed}")

    def test_database_persistence(self):
        """Test that examples are stored and reused"""
        database = InMemoryExampleDatabase()
        generator = StrategyGenerator()
        generator._database = database
        
        # Generate data twice - should show some reuse
        data1 = generator.generate_data("int", 10)
        data2 = generator.generate_data("int", 10)
        
        print(f"First run: {len(data1)} examples")
        print(f"Second run: {len(data2)} examples")
        assert len(data1) > 0
        assert len(data2) > 0

    @given(st.integers(min_value=1, max_value=1000))
    @settings(max_examples=50, phases=[Phase.explicit, Phase.reuse, Phase.generate])
    def test_hypothesis_integration(self, n):
        """Test direct Hypothesis integration"""
        generator = StrategyGenerator()
        
        # Test that our generator can work with Hypothesis-generated data
        data = generator.generate_data("nat", n % 20 + 1)
        assert len(data) <= n % 20 + 1
        
        for example in data:
            value = int(example["value"])
            assert value >= 0, f"Expected non-negative, got {value}"


class LeanPropertyStateMachine(RuleBasedStateMachine):
    """Stateful testing for Lean property validation"""
    
    def __init__(self):
        super().__init__()
        self.bridge = LeanBridge()
        self.generated_values = []
    
    @initialize()
    def setup(self):
        """Initialize the state machine"""
        self.generated_values = []
    
    @rule(strategy_name=st.sampled_from(["int", "nat", "text", "bool"]))
    def generate_values(self, strategy_name):
        """Generate values using a strategy"""
        result = self.bridge.generate_test_data(strategy_name, 5)
        data = json.loads(result)
        
        assert data["status"] == "success"
        self.generated_values.extend(data["data"])
    
    @rule()
    @precondition(lambda self: len(self.generated_values) > 0)
    def validate_generated_values(self):
        """Validate that generated values are well-formed"""
        for value_data in self.generated_values:
            assert "value" in value_data
            assert "type" in value_data
            assert "shrinks" in value_data
            
            # Type-specific validation
            if value_data["type"] == "nat":
                val = int(value_data["value"])
                assert val >= 0
            elif value_data["type"] == "bool":
                assert value_data["value"] in ["True", "False"]


class TestStatefulTesting:
    """Test stateful property testing"""
    
    def test_stateful_machine(self):
        """Run the stateful test machine"""
        # This would normally be run with @given and a state machine runner
        # For now, we'll test it manually
        machine = LeanPropertyStateMachine()
        machine.setup()
        
        # Run some operations
        machine.generate_values("int")
        machine.generate_values("nat")
        machine.validate_generated_values()
        
        print(f"Generated {len(machine.generated_values)} values in stateful test")


def test_shrinking_quality():
    """Test the quality of shrinking behavior"""
    generator = StrategyGenerator()
    
    # Generate a large integer and check its shrinks
    large_int_strategy = st.integers(min_value=1000, max_value=1000000)
    generator.register_strategy("large_int", large_int_strategy)
    
    data = generator.generate_data("large_int", 5)
    
    for example in data:
        original = int(example["value"])
        shrinks = [int(s) for s in example["shrinks"]]
        
        print(f"Original: {original}")
        print(f"Shrinks: {shrinks}")
        
        # Verify shrinks are actually smaller
        for shrink in shrinks:
            assert abs(shrink) <= abs(original), f"Shrink {shrink} not smaller than {original}"


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
