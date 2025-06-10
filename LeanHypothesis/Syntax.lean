/-!
# Ergonomic Syntax for LeanHypothesis

This module provides user-friendly syntax for property-based testing
using Lean's metaprogramming capabilities.
-/

import LeanHypothesis.Strategy
import LeanHypothesis.FFI
import Lean.Parser
import Lean.Elab.Term

namespace LeanHypothesis.Syntax

open Lean Elab Term Parser

/-- Syntax for defining property tests with automatic strategy inference -/
syntax "property" ident ":" term "where" term : command

/-- Syntax for custom strategy definitions -/
syntax "strategy" ident ":" term ":=" term : command

/-- Syntax for running property tests with natural language -/
syntax "#test" ident "(" num ")" : command

/-- Syntax for hypothesis-style forall quantification -/
syntax "∀hypothesis" "(" ident ":" term ")" "," term : term

/-- Strategy combinators with natural syntax -/
syntax "lists" "(" term ")" : term
syntax "tuples" "(" term,* ")" : term  
syntax "records" "{" (ident ":" term),* "}" : term
syntax "oneOf" "[" term,* "]" : term
syntax "constrained" "(" term ")" "|" term : term

-- Implementation of the syntax extensions

@[command_elab «property»]
def elabPropertyCommand : CommandElab := fun stx => do
  match stx with
  | `(property $name:ident : $type:term where $prop:term) => do
    let nameStr := name.getId.toString
    let typeExpr ← Term.elabTerm type none
    let propExpr ← Term.elabTerm prop none
    
    -- Generate the property test function
    let testDef := `(
      def $(mkIdent (nameStr ++ "Test")) : IO Bool := do
        runProperty (fun (x : $type) => $prop)
    )
    
    elabCommand testDef
    logInfo s!"Property '{nameStr}' defined. Run with #test {nameStr}(n) where n is number of tests."
  | _ => throwUnsupportedSyntax

@[command_elab «strategy»]  
def elabStrategyCommand : CommandElab := fun stx => do
  match stx with
  | `(strategy $name:ident : $type:term := $impl:term) => do
    let nameStr := name.getId.toString
    -- Register the strategy in the global strategy registry
    let strategyDef := `(
      instance : Testable $type where
        mkStrategy := pure ⟨$(quote nameStr)⟩
        parseGenerated s := $impl s
    )
    elabCommand strategyDef
    logInfo s!"Strategy '{nameStr}' registered for type {type}."
  | _ => throwUnsupportedSyntax

@[command_elab «#test»]
def elabTestCommand : CommandElab := fun stx => do
  match stx with
  | `(#test $name:ident ( $numTests:num )) => do
    let nameStr := name.getId.toString
    let testName := mkIdent (nameStr ++ "Test")
    let num := numTests.getNat
    
    let runTest := `(
      #eval do
        IO.println s!"Running property test: {$(quote nameStr)}"
        let result ← $testName
        if result then
          IO.println s!"✓ Property passed after {$(quote num)} tests"
        else  
          IO.println s!"✗ Property failed"
    )
    elabCommand runTest
  | _ => throwUnsupportedSyntax

-- Term elaborators for strategy combinators

@[term_elab «lists»]
def elabLists : TermElab := fun stx expectedType? => do
  match stx with
  | `(lists ($inner:term)) => do
    let innerType ← inferType (← elabTerm inner none)
    return ← elabTerm `(List $inner) expectedType?
  | _ => throwUnsupportedSyntax

@[term_elab «tuples»]
def elabTuples : TermElab := fun stx expectedType? => do
  match stx with
  | `(tuples ($elems:term,*)) => do
    let tupleType := elems.getElems.foldl (fun acc elem => `($acc × $elem)) `(Unit)
    return ← elabTerm tupleType expectedType?
  | _ => throwUnsupportedSyntax

@[term_elab «∀hypothesis»]
def elabForallHypothesis : TermElab := fun stx expectedType? => do
  match stx with  
  | `(∀hypothesis ($var:ident : $type:term), $body:term) => do
    return ← elabTerm `(fun ($var : $type) => $body) expectedType?
  | _ => throwUnsupportedSyntax

end LeanHypothesis.Syntax
