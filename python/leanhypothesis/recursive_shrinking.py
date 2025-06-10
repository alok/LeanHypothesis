"""
Recursive Shrinking Module for LeanHypothesis

This module implements sophisticated recursive shrinking based on insights from:
1. Hypothesis's choice sequence approach
2. Hedgehog's integrated shrinking
3. Dependent type property testing research

Key features:
- Preserves invariants during shrinking
- Handles nested data structures recursively
- Uses type information to guide shrinking
- Implements minimal counterexample generation
"""

import json
from typing import Any, List, Dict, Tuple, Optional, Callable, Set
from dataclasses import dataclass
from abc import ABC, abstractmethod
from enum import Enum


class ChoiceType(Enum):
    """Types of choices made during generation"""

    BOOLEAN = "boolean"
    INTEGER = "integer"
    FLOAT = "float"
    STRING = "string"
    BYTES = "bytes"
    COLLECTION_SIZE = "collection_size"
    COLLECTION_ELEMENT = "collection_element"


@dataclass
class Choice:
    """Represents a single choice made during value generation"""

    choice_type: ChoiceType
    value: Any
    metadata: Dict[str, Any]  # e.g., min/max bounds, constraints
    path: Tuple[int, ...]  # Path in the choice tree

    def __hash__(self):
        return hash((self.choice_type, str(self.value), str(self.path)))


class ChoiceSequence:
    """
    Tracks the sequence of choices made during value generation.
    This allows for more intelligent shrinking by understanding the generation path.
    """

    def __init__(self):
        self.choices: List[Choice] = []
        self.current_path: List[int] = [0]

    def record_choice(
        self, choice_type: ChoiceType, value: Any, metadata: Dict[str, Any] = None
    ):
        """Record a choice made during generation"""
        choice = Choice(
            choice_type=choice_type,
            value=value,
            metadata=metadata or {},
            path=tuple(self.current_path),
        )
        self.choices.append(choice)
        self.current_path[-1] += 1

    def push_scope(self):
        """Enter a new scope (e.g., generating a nested structure)"""
        self.current_path.append(0)

    def pop_scope(self):
        """Exit the current scope"""
        if len(self.current_path) > 1:
            self.current_path.pop()

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary for serialization"""
        return {
            "choices": [
                {
                    "type": c.choice_type.value,
                    "value": c.value,
                    "metadata": c.metadata,
                    "path": c.path,
                }
                for c in self.choices
            ]
        }


class Shrinker(ABC):
    """Abstract base class for type-specific shrinkers"""

    @abstractmethod
    def shrink(
        self, value: Any, choice_sequence: Optional[ChoiceSequence] = None
    ) -> List[Any]:
        """Generate shrunk versions of the value"""
        pass

    @abstractmethod
    def is_valid(self, value: Any) -> bool:
        """Check if a value satisfies type invariants"""
        pass


class IntegerShrinker(Shrinker):
    """Shrinker for integers with dependent type awareness"""

    def __init__(
        self, min_value: Optional[int] = None, max_value: Optional[int] = None
    ):
        self.min_value = min_value
        self.max_value = max_value

    def is_valid(self, value: Any) -> bool:
        if not isinstance(value, int):
            return False
        if self.min_value is not None and value < self.min_value:
            return False
        if self.max_value is not None and value > self.max_value:
            return False
        return True

    def shrink(
        self, value: int, choice_sequence: Optional[ChoiceSequence] = None
    ) -> List[int]:
        """
        Shrink integers using multiple strategies:
        1. Towards zero
        2. Binary search between value and zero
        3. Remove factors
        4. Round to nice numbers
        """
        if not self.is_valid(value):
            return []

        shrinks = set()

        # Always try zero if valid
        if self.is_valid(0) and value != 0:
            shrinks.add(0)

        # Binary search towards zero
        if value > 0:
            targets = [0]
            if self.min_value is not None and self.min_value > 0:
                targets.append(self.min_value)

            for target in targets:
                current = value
                while current > target:
                    mid = (current + target) // 2
                    if mid < current and self.is_valid(mid):
                        shrinks.add(mid)
                    current = mid

        elif value < 0:
            targets = [0]
            if self.max_value is not None and self.max_value < 0:
                targets.append(self.max_value)

            for target in targets:
                current = value
                while current < target:
                    mid = (current + target) // 2
                    if mid > current and self.is_valid(mid):
                        shrinks.add(mid)
                    current = mid

        # Try nice round numbers
        if abs(value) >= 10:
            for divisor in [10, 100, 1000]:
                rounded = (value // divisor) * divisor
                if rounded != value and self.is_valid(rounded):
                    shrinks.add(rounded)

        # Try removing prime factors
        if abs(value) > 1:
            for prime in [2, 3, 5, 7, 11]:
                if value % prime == 0:
                    candidate = value // prime
                    if self.is_valid(candidate):
                        shrinks.add(candidate)

        # Sort by absolute value (prefer smaller numbers)
        return sorted(list(shrinks), key=abs)


class StringShrinker(Shrinker):
    """Shrinker for strings with pattern preservation"""

    def __init__(
        self,
        min_length: int = 0,
        max_length: Optional[int] = None,
        valid_chars: Optional[Set[str]] = None,
    ):
        self.min_length = min_length
        self.max_length = max_length
        self.valid_chars = valid_chars

    def is_valid(self, value: Any) -> bool:
        if not isinstance(value, str):
            return False
        if len(value) < self.min_length:
            return False
        if self.max_length is not None and len(value) > self.max_length:
            return False
        if self.valid_chars is not None:
            return all(c in self.valid_chars for c in value)
        return True

    def shrink(
        self, value: str, choice_sequence: Optional[ChoiceSequence] = None
    ) -> List[str]:
        """
        Shrink strings using multiple strategies:
        1. Remove characters from ends
        2. Remove characters from middle
        3. Simplify characters (e.g., to 'a')
        4. Remove redundant sequences
        """
        if not self.is_valid(value):
            return []

        shrinks = []

        # Empty string if valid
        if self.is_valid(""):
            shrinks.append("")

        # Remove from ends
        for i in range(1, len(value) - self.min_length + 1):
            # Remove from end
            candidate = value[:-i]
            if self.is_valid(candidate) and candidate not in shrinks:
                shrinks.append(candidate)

            # Remove from start
            candidate = value[i:]
            if self.is_valid(candidate) and candidate not in shrinks:
                shrinks.append(candidate)

        # Remove from middle (binary search style)
        if len(value) > self.min_length + 1:
            mid = len(value) // 2
            candidate = value[: mid // 2] + value[mid + mid // 2 :]
            if self.is_valid(candidate) and candidate not in shrinks:
                shrinks.append(candidate)

        # Simplify characters
        if len(value) > self.min_length:
            # Replace with 'a' or valid simple character
            simple_char = (
                "a"
                if self.valid_chars is None or "a" in self.valid_chars
                else next(iter(self.valid_chars))
            )
            simplified = simple_char * len(value)
            if self.is_valid(simplified) and simplified not in shrinks:
                shrinks.append(simplified)

        # Sort by length (prefer shorter strings)
        return sorted(set(shrinks), key=len)


class ListShrinker(Shrinker):
    """Recursive shrinker for lists"""

    def __init__(
        self,
        element_shrinker: Shrinker,
        min_length: int = 0,
        max_length: Optional[int] = None,
    ):
        self.element_shrinker = element_shrinker
        self.min_length = min_length
        self.max_length = max_length

    def is_valid(self, value: Any) -> bool:
        if not isinstance(value, list):
            return False
        if len(value) < self.min_length:
            return False
        if self.max_length is not None and len(value) > self.max_length:
            return False
        return all(self.element_shrinker.is_valid(elem) for elem in value)

    def shrink(
        self, value: List[Any], choice_sequence: Optional[ChoiceSequence] = None
    ) -> List[List[Any]]:
        """
        Recursively shrink lists:
        1. Remove elements
        2. Shrink individual elements
        3. Reorder to put simpler elements first
        """
        if not self.is_valid(value):
            return []

        shrinks = []

        # Empty list if valid
        if self.min_length == 0:
            shrinks.append([])

        # Remove elements
        if len(value) > self.min_length:
            # Binary search removal
            for size in self._binary_search_sizes(len(value), self.min_length):
                # Remove from end
                shrinks.append(value[:size])

                # Remove from middle
                if size < len(value) - 1:
                    mid = len(value) // 2
                    shrinks.append(value[: size // 2] + value[mid + size // 2 :])

        # Shrink individual elements (recursive shrinking)
        for i, elem in enumerate(value):
            elem_shrinks = self.element_shrinker.shrink(elem)
            for shrunk_elem in elem_shrinks[:3]:  # Limit to avoid explosion
                new_list = value.copy()
                new_list[i] = shrunk_elem
                if self.is_valid(new_list):
                    shrinks.append(new_list)

        # Remove duplicates while preserving order
        seen = set()
        unique_shrinks = []
        for shrink in shrinks:
            key = tuple(shrink)
            if key not in seen:
                seen.add(key)
                unique_shrinks.append(shrink)

        return unique_shrinks

    def _binary_search_sizes(self, current: int, minimum: int) -> List[int]:
        """Generate sizes using binary search pattern"""
        sizes = []
        while current > minimum:
            current = (current + minimum) // 2
            if current > minimum:
                sizes.append(current)
        return sizes


class DependentTypeShrinker:
    """
    Main shrinker that uses dependent type information to guide shrinking.
    This incorporates insights from formal methods research.
    """

    def __init__(self):
        self.shrinkers: Dict[str, Shrinker] = {}
        self._register_default_shrinkers()

    def _register_default_shrinkers(self):
        """Register default shrinkers for common types"""
        self.shrinkers["int"] = IntegerShrinker()
        self.shrinkers["nat"] = IntegerShrinker(min_value=0)
        self.shrinkers["string"] = StringShrinker()
        self.shrinkers["text"] = StringShrinker()

    def register_shrinker(self, type_name: str, shrinker: Shrinker):
        """Register a custom shrinker for a type"""
        self.shrinkers[type_name] = shrinker

    def shrink_with_invariants(
        self,
        value: Any,
        type_info: Dict[str, Any],
        choice_sequence: Optional[ChoiceSequence] = None,
    ) -> List[Any]:
        """
        Shrink a value while preserving type invariants.

        Args:
            value: The value to shrink
            type_info: Type information including constraints
            choice_sequence: Optional choice sequence from generation

        Returns:
            List of shrunk values that satisfy type invariants
        """
        type_name = type_info.get("type", "unknown")

        # Handle composite types
        if type_name.startswith("list"):
            element_type = type_info.get("element_type", {"type": "unknown"})
            shrinker = ListShrinker(
                element_shrinker=self._get_shrinker_for_type(element_type),
                min_length=type_info.get("min_length", 0),
                max_length=type_info.get("max_length"),
            )
            return shrinker.shrink(value, choice_sequence)

        # Handle basic types
        shrinker = self.shrinkers.get(type_name)
        if shrinker:
            # Apply type-specific constraints
            if hasattr(shrinker, "min_value") and "min_value" in type_info:
                shrinker.min_value = type_info["min_value"]
            if hasattr(shrinker, "max_value") and "max_value" in type_info:
                shrinker.max_value = type_info["max_value"]

            return shrinker.shrink(value, choice_sequence)

        # Fallback: no shrinking for unknown types
        return []

    def _get_shrinker_for_type(self, type_info: Dict[str, Any]) -> Shrinker:
        """Get appropriate shrinker for a type"""
        type_name = type_info.get("type", "unknown")
        return self.shrinkers.get(
            type_name, self.shrinkers.get("int")
        )  # Default to int shrinker

    def find_minimal_counterexample(
        self,
        value: Any,
        type_info: Dict[str, Any],
        property_fn: Callable[[Any], bool],
        max_iterations: int = 1000,
    ) -> Any:
        """
        Find the minimal counterexample using iterative shrinking.

        This implements the core algorithm from property-based testing:
        repeatedly shrink until no smaller failing example exists.
        """
        current = value
        iterations = 0

        while iterations < max_iterations:
            shrinks = self.shrink_with_invariants(current, type_info)

            # Find the first shrink that still fails the property
            found_smaller = False
            for candidate in shrinks:
                if not property_fn(candidate):
                    current = candidate
                    found_smaller = True
                    break

            if not found_smaller:
                # No smaller counterexample found
                break

            iterations += 1

        return current


# Export main components
__all__ = [
    "ChoiceSequence",
    "DependentTypeShrinker",
    "IntegerShrinker",
    "StringShrinker",
    "ListShrinker",
    "Shrinker",
]
