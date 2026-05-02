---
description: "Designing extension points, combinators, or polymorphic dispatch"
---

# Flexibility

Principles from Hanson & Sussman, _Software Design for Flexibility_ (MIT
Press, 2021). Apply when designing systems, choosing implementation
strategies, or reviewing for extensibility.

## The additive principle

A working program should not be modified to add new functionality. New behavior
is introduced by adding new code. When extending requires editing internals,
every extension risks breaking what already works, and the cost of change
grows with the system. Designs that accept incremental additions make
long-term costs additive rather than multiplicative.

This is the organizing principle behind every technique below — each is a
specific mechanism for additive extension in a different dimension.

## Combinators

A combinator takes procedures as input and returns a new procedure with the
same interface. The critical property is closure: any combination is usable
wherever a primitive is expected, and feedable into further combinators
without adaptation.

The vocabulary grows linearly; the expressible behaviors grow combinatorially.

- **compose** — sequential pipeline.
- **parallel-combine** — apply two procedures to the same input, merge.
- **spread-combine** — split arguments between two procedures, merge.
- **restrict** — wrap with a predicate guard. Foundation of predicate
  dispatch.
- **discard-argument**, **curry-argument**, **permute-arguments** — adapt
  interfaces without rewriting.

The combinator vocabulary is itself extensible: new combinators do not affect
existing programs.

When not to combinate: depth makes stack traces unreadable; performance
requires fused loops; the composition is used exactly once and a plain function
is clearer.

## Wrappers

A wrapper specializes an existing procedure by transforming inputs, transforming
outputs, or surrounding execution — without modifying the wrapped procedure.
Three forms:

- **Before-wrapper** — validate or transform arguments.
- **After-wrapper** — transform or validate the return value.
- **Around-wrapper** — receives the wrapped procedure and controls whether,
  when, and how many times it executes. Most general: subsumes memoization,
  retry, access control, transactions.

Prefer wrapping to rewriting. A simple base wrapped for a particular purpose is
easier to test, extend, and replace than a specialized program tangling
domain logic with adaptation logic.

When not to wrap: depth obscures the actual computation; indirection cost
dominates an inner loop.

## Generic dispatch

A generic procedure dispatches to handlers based on properties of its
arguments at call time. Handlers are registered independently, guarded by
predicates.

Predicate dispatch subsumes type dispatch. Type dispatch is the special case
where the predicate is a type test. Predicates can express any computable
condition: value ranges, structural properties, relationships between
arguments. You are not forced to commit to a type taxonomy to get
polymorphism.

Generic dispatch resolves the expression problem: new data variants are added
by registering new handlers, new operations are added as new generic
procedures with their own handlers — both axes additive.

When multiple handlers match, resolve by specificity: a predicate matching a
strict subset is more specific. If two match and neither subsumes the other,
signal an error rather than choosing arbitrarily.

When not to use it: the set of cases is genuinely closed (protocol verbs, AST
nodes in a fixed grammar) — direct match is simpler. Generic dispatch adds
indirection and makes "which handler runs?" harder to answer.

## Pattern matching and unification

Pattern matching decomposes structured data by declaring expected shape and
binding variables. Code becomes data-shape-driven; new shapes mean new
clauses.

Unification generalizes: two patterns, both containing variables, are compared
to find the most general substitution that makes them identical. Enables
bidirectional constraint propagation, type inference, symbolic computation.

Use pattern matching for structured data with multiple cases. Use unification
when relationships are bidirectional or partial information must combine.

## Layering

A layered datum is a base value annotated with independent metadata layers
(units, provenance, constraints). A layered procedure processes each
independently — the base operates on base values while annotation handlers
process their layers in parallel.

The critical property: the base layer computes without reference to annotation
layers. Annotation layers may read the base but not each other. Layers compose
additively — attaching a new one does not require modifying the base or
existing layers.

Use when metadata must flow through a computation without contaminating core
logic.

## Propagation

A propagator network has cells (containers for partial information) and
propagators (autonomous agents that watch cells and contribute to others).
Computation proceeds by accumulation until fixed point.

Three escapes from the expression-oriented paradigm:

1. **Multidirectional.** A constraint relating three values can compute any one
   from the other two.
2. **Partial information.** Cells hold intervals, possibility sets, or
   incomplete structures, refined incrementally.
3. **Multiple sources.** Independent propagators contribute to the same cell;
   merge combines them.

Merge must be commutative, associative, idempotent, and monotonic
(information only increases). When merge produces a contradiction, the
dependency system identifies the minimal responsible assumption set.

Use when relationships are bidirectional, information arrives incrementally
from multiple sources, or you need dependency-directed backtracking.

## Dependencies and backtracking

Every computed value carries the set of premises it was derived from. When
operations combine tracked values, support sets union. This enables:

1. **Explanation.** For any result, identify which inputs contributed.
2. **Dependency-directed backtracking.** On contradiction, compute the nogood
   set (minimal assumptions that cause it), record it to prevent retrying the
   same combination, and retract the least-committed assumption. Far more
   efficient than chronological backtracking, which retracts the most recent
   choice regardless of relevance.

Use in search, constraint satisfaction, configuration, or any system where
"why did this happen?" must be answerable.

## Interpreters

When a pattern recurs three or more times, build a small interpreter.
Instances become data descriptions, not imperative code.

Languages built for flexibility should have very few mechanisms — primitives,
means of combination, means of abstraction — and must be extensible. When
multiple languages suit parts of a problem, there must be good ways to
interoperate.

The cost: every language must be documented and taught. "Don't participate in
the creation of a Tower of Babel."

## Degeneracy

Degeneracy is multiple structurally different mechanisms achieving the same
function. Distinct from redundancy (identical components duplicated). If one
mechanism fails, a structurally different one still produces the result —
because they differ, they don't share failure modes.

Biology is pervasively degenerate: energy from carbohydrates, fats, and
proteins via distinct pathways; 64 codons mapping to 20 amino acids so most
point mutations are silent.

Only systems with significant degeneracy tolerate environmental change.
Mechanisms that become inoperative are free to mutate without affecting
viability — this is how neutral variation accumulates as raw material for
future adaptation.

Propagator networks naturally support degeneracy: multiple independent
propagators can contribute to the same cell, each self-contained.

When not to build it in: consistency is paramount and multiple paths risk
subtly different answers (transactional systems); the system is genuinely
closed to future change.

## The cost of flexibility

1. **Comprehension.** Every extension point, generic dispatch, and combinator
   layer must be understood. Unexercised flexibility is pure overhead.
2. **Performance.** Generic dispatch, predicate testing, propagation are
   slower than direct calls.
3. **Testing.** Larger state spaces — each extension point multiplies the
   configurations to cover.

Build flexibility where you have evidence the system will need to change.
Build concretely where you do not. The mistake is making everything slippery
(AbstractFactoryFactory) or nothing (a monolithic script).

The principal cost of software is programmer time over the product's lifetime,
including maintenance and adaptation. Designs that minimize rewriting reduce
overall cost even when the initial implementation is more elaborate.

## Decision guide

| Extension needed                          | Technique        |
| ----------------------------------------- | ---------------- |
| New behavior from existing parts          | Combinators      |
| Adapt interface without rewriting         | Wrappers         |
| New data variants + new operations        | Generic dispatch |
| Structured data with variable shape       | Pattern matching |
| Metadata without contaminating core logic | Layering         |
| Bidirectional or incremental computation  | Propagation      |
| Auditable provenance, intelligent search  | Dependencies     |
| Recurring structural pattern              | Interpreter      |
| Resilience to unanticipated failure       | Degeneracy       |

## References

- Hanson & Sussman, _Software Design for Flexibility_ (MIT Press, 2021)
- Sussman, "Building Robust Systems" (2007) — biological motivation
- Radul & Sussman, "The Art of the Propagator" (2009) — propagation model
- Abelson & Sussman, _SICP_ (1985) — metalinguistic abstraction, eval/apply
- Sussman & Wisdom, _Structure and Interpretation of Classical Mechanics_
  (2001) — generic arithmetic in physics
