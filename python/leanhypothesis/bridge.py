"""
Lean Bridge: Interface between Lean and Python Hypothesis
"""

import json
import sys
from typing import Dict, List, Any
from .generator import StrategyGenerator


class LeanBridge:
    """Main bridge class for Lean-Python communication"""
    
    def __init__(self):
        self.generator = StrategyGenerator()
        self.test_results = []
    
    def generate_test_data(self, strategy_name: str, num_examples: int = 100) -> str:
        """Generate test data and return as JSON string for Lean to parse"""
        try:
            data = self.generator.generate_data(strategy_name, num_examples)
            return json.dumps({
                "status": "success",
                "data": data,
                "count": len(data)
            })
        except Exception as e:
            return json.dumps({
                "status": "error",
                "error": str(e),
                "data": [],
                "count": 0
            })
    
    def run_property_test(self, strategy_name: str, property_function: str, num_tests: int = 100) -> str:
        """Run a property test and return results"""
        try:
            # Generate test data
            examples = self.generator.generate_data(strategy_name, num_tests)
            
            results = {
                "passed": 0,
                "failed": 0,
                "failures": [],
                "total": len(examples)
            }
            
            # Note: In a full implementation, we would execute the Lean property function
            # For now, we just return the structure that Lean expects
            
            return json.dumps({
                "status": "success",
                "results": results
            })
            
        except Exception as e:
            return json.dumps({
                "status": "error",
                "error": str(e)
            })
    
    def register_custom_strategy(self, name: str, strategy_spec: str) -> str:
        """Register a custom strategy from a specification"""
        try:
            strategy = self.generator.parse_composite_strategy(strategy_spec)
            self.generator.register_strategy(name, strategy)
            return json.dumps({"status": "success"})
        except Exception as e:
            return json.dumps({"status": "error", "error": str(e)})


# Command line interface for testing
def main():
    """CLI interface for testing the bridge"""
    if len(sys.argv) < 2:
        print("Usage: python -m leanhypothesis.bridge <command> [args...]")
        return
    
    bridge = LeanBridge()
    command = sys.argv[1]
    
    if command == "generate":
        if len(sys.argv) >= 3:
            strategy_name = sys.argv[2]
            num_examples = int(sys.argv[3]) if len(sys.argv) > 3 else 10
            result = bridge.generate_test_data(strategy_name, num_examples)
            print(result)
        else:
            print("Usage: generate <strategy_name> [num_examples]")
    
    elif command == "test":
        if len(sys.argv) >= 4:
            strategy_name = sys.argv[2]
            property_func = sys.argv[3]
            num_tests = int(sys.argv[4]) if len(sys.argv) > 4 else 100
            result = bridge.run_property_test(strategy_name, property_func, num_tests)
            print(result)
        else:
            print("Usage: test <strategy_name> <property_function> [num_tests]")
    
    else:
        print(f"Unknown command: {command}")


if __name__ == "__main__":
    main()
