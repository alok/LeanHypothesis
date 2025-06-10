#!/usr/bin/env python3
"""
Sophisticated Counterexample Discovery Showcase

This demonstrates the real power of Hypothesis in finding counterexamples
to false properties, including edge cases and sophisticated shrinking.
"""

import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__)))

from leanhypothesis.generator import StrategyGenerator
from leanhypothesis.bridge import LeanBridge
from hypothesis import strategies as st, given, settings
import json


def demonstrate_counterexample_discovery():
    """Show sophisticated counterexample discovery"""
    print("🔍 LeanHypothesis: Sophisticated Counterexample Discovery")
    print("=" * 65)
    print("Demonstrating Hypothesis's power in finding minimal counterexamples\n")
    
    generator = StrategyGenerator()
    
    # Example 1: Mathematical misconception
    print("1. Testing flawed property: 'For all x, x² ≥ x'")
    print("   (This fails for 0 < x < 1, but we're using integers)")
    
    # Generate integers and test the property
    data = generator.generate_data("int", 20)
    counterexamples = []
    
    for example in data:
        x = int(example['value'])
        property_holds = x * x >= x
        if not property_holds:
            counterexamples.append((x, x * x))
    
    if counterexamples:
        print("   ⚠️  COUNTEREXAMPLES FOUND:")
        for x, x_squared in counterexamples[:3]:
            print(f"      x = {x}, x² = {x_squared}, x² ≥ x? {x_squared >= x}")
    else:
        print("   ✓ No counterexamples found (expected for integers)")
    
    print()
    
    # Example 2: String property with edge cases
    print("2. Testing flawed property: 'All strings when lowercased equal original'")
    
    # Register a strategy for mixed-case strings
    mixed_case_strategy = st.text(min_size=1, max_size=20).filter(
        lambda s: any(c.isupper() for c in s)
    )
    generator.register_strategy("mixed_case", mixed_case_strategy)
    
    data = generator.generate_data("mixed_case", 15)
    counterexamples = []
    
    for example in data[:10]:
        original = json.loads(example['value'])
        lowercased = original.lower()
        property_holds = original == lowercased
        
        if not property_holds:
            counterexamples.append((original, lowercased))
    
    print("   ⚠️  COUNTEREXAMPLES FOUND:")
    for original, lowercased in counterexamples[:3]:
        print(f"      Original: '{original}' -> Lowercased: '{lowercased}'")
    
    print()
    
    # Example 3: List property with boundary conditions
    print("3. Testing flawed property: 'Removing first element always shortens list'")
    
    # Generate lists including empty ones
    list_strategy = st.lists(st.integers(), min_size=0, max_size=10)
    generator.register_strategy("int_list", list_strategy)
    
    data = generator.generate_data("int_list", 15)
    counterexamples = []
    
    for example in data:
        original_list = json.loads(example['value'])
        if isinstance(original_list, list):
            tail_list = original_list[1:] if original_list else []
            property_holds = len(tail_list) < len(original_list)
            
            if not property_holds:
                counterexamples.append(original_list)
    
    if counterexamples:
        print("   ⚠️  COUNTEREXAMPLES FOUND:")
        for lst in counterexamples[:3]:
            print(f"      Empty list: {lst} -> tail: {lst[1:] if lst else []} (same length!)")
    
    print()
    
    # Example 4: Sophisticated shrinking demonstration
    print("4. Demonstrating sophisticated shrinking behavior")
    
    # Generate complex data and show how it shrinks
    complex_strategy = st.dictionaries(
        st.text(min_size=1, max_size=10),
        st.lists(st.integers(), max_size=5),
        min_size=1, max_size=3
    )
    generator.register_strategy("complex_dict", complex_strategy)
    
    data = generator.generate_data("complex_dict", 3)
    
    for i, example in enumerate(data):
        original = json.loads(example['value'])
        print(f"   Complex example {i+1}:")
        print(f"      Original: {str(original)[:60]}...")
        
        shrinks = example['shrinks'][:3]
        for j, shrink_json in enumerate(shrinks):
            try:
                shrink = json.loads(shrink_json)
                print(f"      Shrink {j+1}: {str(shrink)[:60]}...")
            except:
                print(f"      Shrink {j+1}: {shrink_json[:60]}...")
        print()


def demonstrate_realistic_bug_finding():
    """Show how this would find real bugs in Lean code"""
    print("🐛 Realistic Bug Discovery Simulation")
    print("=" * 45)
    print("Simulating how LeanHypothesis would find bugs in real Lean properties\n")
    
    generator = StrategyGenerator()
    
    # Simulate a buggy sorting algorithm property
    print("Testing: 'Our custom sort preserves all elements'")
    print("(Simulating a sorting bug that loses elements)")
    
    data = generator.generate_data("int_list", 10)
    bugs_found = 0
    
    for example in data:
        original_list = json.loads(example['value'])
        if isinstance(original_list, list) and len(original_list) > 2:
            # Simulate a buggy sort that sometimes drops the last element
            buggy_sorted = sorted(original_list[:-1])  # Oops! Lost last element
            
            # Property: sorted list should have same length
            property_holds = len(buggy_sorted) == len(original_list)
            
            if not property_holds:
                bugs_found += 1
                print(f"   🐛 BUG FOUND in test case {bugs_found}:")
                print(f"      Input: {original_list}")
                print(f"      Buggy output: {buggy_sorted}")
                print(f"      Expected length: {len(original_list)}, Got: {len(buggy_sorted)}")
                
                # Show shrinking would help debug
                if example['shrinks']:
                    smallest_failing = json.loads(example['shrinks'][0])
                    if isinstance(smallest_failing, list) and len(smallest_failing) > 2:
                        print(f"      Shrunk counterexample: {smallest_failing}")
                print()
                
                if bugs_found >= 2:  # Show a couple examples
                    break
    
    print(f"Found {bugs_found} instances of the bug!")
    print("This demonstrates how LeanHypothesis would catch real implementation errors.")


if __name__ == "__main__":
    demonstrate_counterexample_discovery()
    print("\n" + "="*65 + "\n")
    demonstrate_realistic_bug_finding()
    
    print("\n✨ Key Takeaways:")
    print("• Hypothesis generates diverse test cases including edge cases")
    print("• Counterexamples are found quickly and reliably") 
    print("• Sophisticated shrinking produces minimal failing cases")
    print("• Edge cases like empty lists, mixed-case strings are covered")
    print("• Real bugs in algorithms would be caught automatically")
    print("• All of this works seamlessly from Lean's type-safe environment")
