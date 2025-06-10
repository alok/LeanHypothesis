#!/usr/bin/env python3
"""
Advanced demonstration of LeanHypothesis capabilities
"""

from leanhypothesis.generator import StrategyGenerator
from leanhypothesis.bridge import LeanBridge
from hypothesis import strategies as st
import json


def demo_advanced_strategies():
    """Demonstrate advanced Hypothesis strategies"""
    print("🔬 Advanced Strategy Demonstration")
    print("=" * 50)
    
    generator = StrategyGenerator()
    
    # 1. Recursive JSON-like structures
    print("\n1. Recursive JSON-like structures:")
    json_strategy = st.recursive(
        st.one_of(st.booleans(), st.integers(), st.text(max_size=10)),
        lambda children: st.one_of(
            st.lists(children, max_size=3),
            st.dictionaries(st.text(max_size=5), children, max_size=2)
        ),
        max_leaves=5
    )
    generator.register_strategy("json_tree", json_strategy)
    
    data = generator.generate_data("json_tree", 3)
    for i, example in enumerate(data):
        print(f"  Example {i+1}: {example['value'][:100]}...")
    
    # 2. Complex composite types
    print("\n2. Complex user profiles with constraints:")
    user_strategy = st.fixed_dictionaries({
        "username": st.text(min_size=3, max_size=20).filter(lambda s: s.isalnum()),
        "age": st.integers(min_value=13, max_value=100),
        "email": st.emails(),
        "preferences": st.dictionaries(
            st.sampled_from(["theme", "lang", "notifications"]),
            st.one_of(st.booleans(), st.text(max_size=10)),
            min_size=1, max_size=3
        ),
        "scores": st.lists(st.floats(min_value=0.0, max_value=1.0), min_size=1, max_size=5)
    })
    generator.register_strategy("user_profile", user_strategy)
    
    data = generator.generate_data("user_profile", 2)
    for i, example in enumerate(data):
        parsed = json.loads(example['value'])
        print(f"  User {i+1}:")
        print(f"    Username: {parsed['username']}")
        print(f"    Age: {parsed['age']}")
        print(f"    Email: {parsed['email']}")
        print(f"    Preferences: {parsed['preferences']}")
        print(f"    Scores: {parsed['scores'][:3]}...")
    
    # 3. Mathematical structures
    print("\n3. Mathematical structures (matrices):")
    matrix_strategy = st.lists(
        st.lists(st.floats(min_value=-100, max_value=100), min_size=2, max_size=4),
        min_size=2, max_size=4
    ).filter(lambda matrix: len(set(len(row) for row in matrix)) == 1)  # All rows same length
    
    generator.register_strategy("matrix", matrix_strategy)
    data = generator.generate_data("matrix", 2)
    for i, example in enumerate(data):
        matrix = json.loads(example['value'])
        print(f"  Matrix {i+1}: {len(matrix)}x{len(matrix[0])} matrix")
        print(f"    First row: {matrix[0]}")
    
    # 4. Show shrinking quality
    print("\n4. Shrinking demonstration:")
    large_list_strategy = st.lists(st.integers(), min_size=5, max_size=20)
    generator.register_strategy("large_list", large_list_strategy)
    data = generator.generate_data("large_list", 1)
    
    if data:
        example = data[0]
        original = json.loads(example['value'])
        shrinks = [json.loads(s) for s in example['shrinks'][:3]]
        print(f"  Original list (length {len(original)}): {original[:5]}...")
        for i, shrink in enumerate(shrinks):
            print(f"  Shrink {i+1} (length {len(shrink)}): {shrink[:5]}...")


def demo_lean_integration():
    """Demonstrate Lean integration capabilities"""
    print("\n\n🔗 Lean Integration Demonstration")
    print("=" * 50)
    
    bridge = LeanBridge()
    
    # Test various data types
    types_to_test = ["int", "nat", "text", "bool"]
    
    for type_name in types_to_test:
        print(f"\n{type_name.capitalize()} generation:")
        result = bridge.generate_test_data(type_name, 3)
        data = json.loads(result)
        
        if data["status"] == "success":
            print(f"  ✓ Generated {data['count']} examples")
            for i, example in enumerate(data["data"][:2]):
                print(f"  Example {i+1}: {example['value']}")
                if example['shrinks']:
                    print(f"    Shrinks: {example['shrinks'][:3]}...")
        else:
            print(f"  ✗ Failed: {data.get('error', 'Unknown error')}")


def demo_performance():
    """Demonstrate performance characteristics"""
    print("\n\n⚡ Performance Demonstration")
    print("=" * 50)
    
    import time
    generator = StrategyGenerator()
    
    # Large dataset generation
    start_time = time.time()
    data = generator.generate_data("int", 100)
    end_time = time.time()
    
    print(f"Generated {len(data)} integer examples in {end_time - start_time:.3f} seconds")
    
    # Complex type generation
    start_time = time.time()
    complex_strategy = st.lists(
        st.tuples(st.text(max_size=10), st.integers(), st.booleans()),
        max_size=10
    )
    generator.register_strategy("complex_tuples", complex_strategy)
    data = generator.generate_data("complex_tuples", 50)
    end_time = time.time()
    
    print(f"Generated {len(data)} complex tuple examples in {end_time - start_time:.3f} seconds")


if __name__ == "__main__":
    print("🚀 LeanHypothesis Advanced Demonstration")
    print("=" * 60)
    
    demo_advanced_strategies()
    demo_lean_integration()
    demo_performance()
    
    print("\n\n✅ Demonstration Complete!")
    print("\nKey Features Demonstrated:")
    print("• Recursive data structures")
    print("• Complex composite types with constraints")
    print("• Mathematical structures")
    print("• Sophisticated shrinking")
    print("• Lean integration via subprocess")
    print("• Performance characteristics")
    print("• JSON marshaling/unmarshaling")
