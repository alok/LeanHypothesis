/-!
# Basic Properties Gallery - Lean-First Property Testing

This file demonstrates ergonomic property-based testing in Lean,
with Python's Hypothesis called seamlessly under the hood.
-/

import LeanHypothesis.Syntax

open LeanHypothesis.Syntax

-- Example 1: Basic arithmetic properties

def additionCommutativeTest : IO Bool := 
  defineProperty "additionCommutative" (fun (pair : Nat × Nat) => pair.1 + pair.2 = pair.2 + pair.1)

def additionAssociativeTest : IO Bool := 
  defineProperty "additionAssociative" (fun (triple : Nat × Nat × Nat) => 
    (triple.1 + triple.2.1) + triple.2.2 = triple.1 + (triple.2.1 + triple.2.2))

def multiplicationCommutativeTest : IO Bool := 
  defineProperty "multiplicationCommutative" (fun (pair : Nat × Nat) => pair.1 * pair.2 = pair.2 * pair.1)

-- Example 2: List properties

property listLengthNonNegative : List Nat where
  ∀hypothesis (xs : List Nat), xs.length ≥ 0

property listAppendLength : List Nat where
  ∀hypothesis (xs ys : List Nat), (xs ++ ys).length = xs.length + ys.length

property listReverseLength : List Nat where
  ∀hypothesis (xs : List Nat), xs.reverse.length = xs.length

property listReverseReverse : List Nat where
  ∀hypothesis (xs : List Nat), xs.reverse.reverse = xs

-- Example 3: String properties

property stringAppendLength : String where
  ∀hypothesis (s t : String), (s ++ t).length = s.length + t.length

property stringEmptyAppend : String where
  ∀hypothesis (s : String), s ++ "" = s ∧ "" ++ s = s

-- Example 4: Option properties

property optionMapComposition : Option Nat where
  ∀hypothesis (opt : Option Nat), 
    opt.map (fun x => x + 1) |>.map (fun x => x * 2) = 
    opt.map (fun x => (x + 1) * 2)

-- Example 5: Mathematical properties

property absoluteValueNonNegative : Int where
  ∀hypothesis (n : Int), Int.natAbs n ≥ 0

property maxCommutative : Nat where
  ∀hypothesis (n m : Nat), max n m = max m n

property minCommutative : Nat where
  ∀hypothesis (n m : Nat), min n m = min m n

-- Custom strategies for specific domains

strategy SmallNat : Nat := fun s => 
  match s.toNat? with
  | some n => if n ≤ 100 then some n else none
  | none => none

strategy NonEmptyString : String := fun s => 
  match s with
  | "" => none
  | str => some str

-- Properties using custom strategies

property smallNatAddition : SmallNat where
  ∀hypothesis (n m : SmallNat), n + m ≥ n ∧ n + m ≥ m

property nonEmptyStringNotEmpty : NonEmptyString where
  ∀hypothesis (s : NonEmptyString), s.length > 0

-- Composite type properties

property tupleProperties : Nat × String where
  ∀hypothesis (pair : Nat × String), 
    pair.1 ≥ 0 ∧ pair.2.length ≥ 0

-- Run the tests
#check additionCommutativeTest
#check listLengthNonNegativeTest

-- Interactive testing commands
-- #test additionCommutative(100)
-- #test listAppendLength(50) 
-- #test stringAppendLength(25)

-- Property test suites

def runBasicArithmetic : IO Unit := do
  IO.println "🧮 Testing Basic Arithmetic Properties"
  IO.println "=" * 40
  
  IO.print "Addition commutativity... "
  let result1 ← additionCommutativeTest
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Addition associativity... "  
  let result2 ← additionAssociativeTest
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Multiplication commutativity... "
  let result3 ← multiplicationCommutativeTest  
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")

def runListProperties : IO Unit := do
  IO.println "\n📋 Testing List Properties"
  IO.println "=" * 30
  
  IO.print "List length non-negative... "
  let result1 ← listLengthNonNegativeTest
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "List append length... "
  let result2 ← listAppendLengthTest
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "List reverse length... "
  let result3 ← listReverseLengthTest
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")
  
  IO.print "List reverse reverse... "
  let result4 ← listReverseReverseTest
  IO.println (if result4 then "✓ PASS" else "✗ FAIL")

def runStringProperties : IO Unit := do
  IO.println "\n📝 Testing String Properties"
  IO.println "=" * 31
  
  IO.print "String append length... "
  let result1 ← stringAppendLengthTest
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "String empty append... "
  let result2 ← stringEmptyAppendTest
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")

def runMathematicalProperties : IO Unit := do
  IO.println "\n🔢 Testing Mathematical Properties"
  IO.println "=" * 38
  
  IO.print "Absolute value non-negative... "
  let result1 ← absoluteValueNonNegativeTest
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Max commutativity... "
  let result2 ← maxCommutativeTest
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Min commutativity... "
  let result3 ← minCommutativeTest
  IO.println (if result3 then "✓ PASS" else "✗ FAIL")

def runCustomStrategyProperties : IO Unit := do
  IO.println "\n🎯 Testing Custom Strategy Properties"
  IO.println "=" * 42
  
  IO.print "Small nat addition... "
  let result1 ← smallNatAdditionTest
  IO.println (if result1 then "✓ PASS" else "✗ FAIL")
  
  IO.print "Non-empty string... "
  let result2 ← nonEmptyStringNotEmptyTest
  IO.println (if result2 then "✓ PASS" else "✗ FAIL")

-- Main test runner
def runAllTests : IO Unit := do
  IO.println "🚀 LeanHypothesis Basic Properties Gallery"
  IO.println "=" * 50
  IO.println "Testing fundamental properties with Hypothesis-generated data\n"
  
  runBasicArithmetic
  runListProperties  
  runStringProperties
  runMathematicalProperties
  runCustomStrategyProperties
  
  IO.println "\n✅ All basic property tests completed!"
  IO.println "\nFeatures demonstrated:"
  IO.println "• Ergonomic property syntax in pure Lean"
  IO.println "• Automatic strategy inference for built-in types"
  IO.println "• Custom strategies with domain constraints"
  IO.println "• Comprehensive property test suites"
  IO.println "• Seamless Python Hypothesis integration (under the hood)"

#eval runAllTests
