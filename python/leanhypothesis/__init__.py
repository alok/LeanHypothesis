"""
LeanHypothesis: Python bindings for Lean property-based testing

This module provides the Python side of the bridge between Hypothesis
and Lean 4, allowing Lean to leverage Hypothesis's mature property-based
testing capabilities.
"""

from .generator import StrategyGenerator
from .bridge import LeanBridge

__version__ = "0.1.0"
__all__ = ["StrategyGenerator", "LeanBridge"]
