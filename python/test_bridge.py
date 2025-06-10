#!/usr/bin/env python3
"""
Test script for the LeanHypothesis Python bridge
"""

import json
from leanhypothesis.bridge import LeanBridge
from leanhypothesis.generator import StrategyGenerator


def test_generator():
    """Test the strategy generator"""
    print("Testing StrategyGenerator...")
    gen = StrategyGenerator()
    
    # Test basic strategies
    for strategy_name in ["nat", "int", "text", "bool"]:
        print(f"  Testing {strategy_name}...")
        data = gen.generate_data(strategy_name, 5)
        assert len(data) <= 5
        print(f"    Generated {len(data)} examples")
        for example in data[:2]:  # Show first 2 examples
            print(f"    Example: {example}")
    
    print("StrategyGenerator tests passed!")


def test_bridge():
    """Test the Lean bridge"""
    print("\nTesting LeanBridge...")
    bridge = LeanBridge()
    
    # Test data generation
    result = bridge.generate_test_data("int", 10)
    data = json.loads(result)
    assert data["status"] == "success"
    assert data["count"] <= 10
    print(f"  Generated {data['count']} integers")
    
    # Test custom strategy registration
    result = bridge.register_custom_strategy("small_int", "int")
    data = json.loads(result)
    assert data["status"] == "success"
    print("  Custom strategy registration successful")
    
    print("LeanBridge tests passed!")


def test_cli():
    """Test the CLI interface"""
    print("\nTesting CLI interface...")
    import subprocess
    import sys
    
    # Test data generation via CLI
    result = subprocess.run([
        sys.executable, "-m", "leanhypothesis.bridge", 
        "generate", "nat", "5"
    ], capture_output=True, text=True)
    
    if result.returncode == 0:
        data = json.loads(result.stdout)
        print(f"  CLI generated {data.get('count', 0)} examples")
    else:
        print(f"  CLI test failed: {result.stderr}")
    
    print("CLI tests completed!")


if __name__ == "__main__":
    test_generator()
    test_bridge() 
    test_cli()
    print("\nAll tests completed!")
