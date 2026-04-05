---
description: "Designing extension points, combinators, or polymorphic dispatch"
---

# Flexibility

Design principles from Hanson and Sussman's _Software Design for Flexibility_
(MIT Press, 2021). Apply these when designing systems, choosing between
implementation strategies, or reviewing code for extensibility.

## The additive principle

A working program should not be modified to add new functionality. New behavior
should be introduced by adding new code. When extending a system requires
editing its internals, every extension risks breaking existing behavior and the
cost of change grows with the system. Designs that accept incremental additions
make long-term costs additive rather than multiplicative.

This is the organizing principle behind every technique in this document. Each
technique is a specific mechanism for achieving additive extension in a
different dimension.

## Combinators

A combinator takes procedures as input and returns a new procedure with the same
interface. The critical property is closure: any combination can be used
wherever a primitive is expected, and can be fed into further combinators
without adaptation.

Build complex behavior by composing small, independently testable functions
rather than writing monolithic procedures. The vocabulary of combinators grows
linearly but the expressible behaviors grow combinatorially.

The standard combinators and when to reach for each:

- **compose** — feed the output of one procedure into another. Use when
  computation flows sequentially through stages.
- **parallel-combine** — apply two procedures to the same input and merge their
  outputs. Use when you need independent analyses of the same data.
- **spread-combine** — split arguments between two procedures and merge their
  outputs. Use when you need to unbundle a structure, operate on parts
  separately, and rebundle.
- **restrict** — wrap a procedure so it only applies when a predicate holds.
  This is the foundation of predicate dispatch.
- **discard-argument**, **curry-argument**, **permute-arguments** — adapt a
  procedure's interface without rewriting it. Use when two components agree on
  semantics but disagree on argument shape.

The combinator vocabulary is itself extensible: introducing new combinators does
not affect the behavior of existing programs.

When not to use combinators: when combinator depth makes stack traces
unreadable, when performance requires fused loops, or when the composition is
used exactly once and a plain function is clearer.

## Wrappers

A wrapper specializes an existing procedure by converting its inputs, converting
its outputs, or adding behavior before and after execution — without modifying
the wrapped procedure. The wrapped procedure does not know about the wrapper.
The wrapper makes few assumptions about the wrapped procedure.

Three forms:

- **Before-wrapper** — validates or transforms arguments before the call.
- **After-wrapper** — transforms or validates the return value after the call.
- **Around-wrapper** — receives the wrapped procedure as an argument and
  controls whether, when, and how many times it executes. This is the most
  general form: it subsumes memoization, retry logic, access control, and
  transactional boundaries.

Prefer wrapping to rewriting. A simple, general base program wrapped for a
particular purpose is easier to test, extend, and replace than a specialized
program that tangles domain logic with adaptation logic.

When not to wrap: when wrapper depth obscures the actual computation, or when
the performance cost of indirection dominates an inner loop.

## Generic dispatch

A generic procedure dispatches to different handler implementations based on
properties of its arguments at call time. Handlers are registered independently,
guarded by predicates on the arguments. When the generic procedure is called, it
evaluates predicates against the actual arguments and delegates to the matching
handler.

Predicate dispatch subsumes type dispatch. Type dispatch is predicate dispatch
where the predicate is a type test. But predicates can express arbitrary
conditions: value ranges, structural properties, relationships between
arguments, or any computable test. You are not forced to commit to a type
taxonomy to get polymorphism.

Generic dispatch resolves the expression problem: new data variants are
accommodated by registering new handlers (no existing code changes), and new
operations are defined as new generic procedures with their own handlers (no
existing code changes). Both axes of extension are additive.

When multiple handlers match, resolve by specificity: a handler whose predicate
matches a strict subset of another's is more specific. If two handlers match and
neither subsumes the other, signal an error rather than choosing arbitrarily.

When not to use generic dispatch: when the set of cases is genuinely closed and
known at design time (protocol verbs, AST node kinds in a fixed grammar), a
direct match is simpler. Generic dispatch adds indirection and makes "which
handler actually runs?" harder to answer.

## Pattern matching and unification

Pattern matching decomposes structured data by declaring the expected shape and
binding variables to matching parts. It makes code data-shape-driven: the
structure of the data determines the behavior, and adding new shapes means
adding new clauses.

Unification generalizes pattern matching to be bidirectional: two patterns, both
containing variables, are compared, and the algorithm finds the most general
substitution that makes them identical. Unification enables bidirectional
constraint propagation, type inference, and symbolic computation.

Use pattern matching when processing structured data with multiple cases. Use
unification when relationships between structures are bidirectional or when
combining partial information.

## Layering

A layered datum is a base value annotated with independent metadata layers
(units, provenance, constraints). A layered procedure processes each layer
independently: the base procedure operates on base values while annotation
handlers process their corresponding layers in parallel.

The critical property: the base layer computes without reference to annotation
layers. Annotation layers may read the base layer's values but not each other's.
This means layers compose additively — attaching a new layer to data does not
require modifying the base computation or any existing layer.

Use layering when metadata (units, dependency provenance, uncertainty intervals)
must flow through a computation without contaminating the core logic.

## Propagation

A propagator network consists of cells (containers for partial information) and
propagators (autonomous agents that watch cells and add information to other
cells). Computation proceeds by cells accumulating information until a fixed
point is reached.

Propagation escapes the expression-oriented paradigm in three ways:

1. **Multidirectional.** A constraint relating three values can compute any one
   from the other two. No prescribed direction of computation.
2. **Partial information.** Cells hold intervals, possibility sets, or
   incomplete structures, refined incrementally as information arrives.
   Expressions demand complete inputs.
3. **Multiple sources.** Independent propagators contribute to the same cell.
   The merge operation combines their contributions. Expressions assign each
   variable exactly one definition.

Merge must be commutative, associative, idempotent, and monotonic (information
only increases). When merge produces a contradiction, the dependency system
identifies the minimal set of assumptions responsible.

Use propagation when relationships are naturally bidirectional, when information
arrives incrementally from multiple sources, or when you need
dependency-directed backtracking.

## Dependencies and backtracking

Every computed value should carry the set of premises it was derived from. When
operations combine tracked values, support sets are unioned. This makes
provenance explicit and enables two capabilities:

1. **Explanation.** For any result, you can identify exactly which inputs
   contributed.
2. **Dependency-directed backtracking.** When a contradiction is detected, the
   system computes the nogood set (the minimal set of assumptions that together
   cause the contradiction), records it to prevent the same combination from
   being tried again, and retracts the least-committed assumption. This is
   dramatically more efficient than chronological backtracking, which retracts
   the most recent choice regardless of whether it is relevant to the failure.

Use dependency tracking in search, constraint satisfaction, configuration
management, or any system where "why did this happen?" must be answerable.

## Interpreters

When a pattern recurs three or more times, build a small interpreter that
expresses the pattern declaratively. Each instance becomes a data description
rather than imperative code.

The power of interpretation is available in any Turing-universal language. If
the language does not fit the problem, build a language that does. But with this
power comes responsibility: every language must be documented and taught. "Don't
participate in the creation of a Tower of Babel."

Languages built for flexibility should have very few mechanisms: primitives,
means of combination, and means of abstraction. They must be extensible — it
must be possible to add new primitives and new means of combination as needed.
When multiple languages are appropriate for parts of a problem, there must be
good ways for those languages to interoperate.

## Degeneracy

Degeneracy is having multiple structurally different mechanisms that achieve the
same function. It is distinct from redundancy, where identical components are
duplicated. In a degenerate system, if one mechanism fails, a structurally
different mechanism can still produce the result — and because the mechanisms
differ, they do not share failure modes.

Biological systems are pervasively degenerate: energy from carbohydrates, fats,
and proteins via distinct metabolic pathways; 64 codons mapping to 20 amino
acids so that many point mutations are silent; exploratory behavior where
generators and testers evolve independently.

Degeneracy is a product of evolution that enables evolution. Only systems with
significant degeneracy tolerate environmental change. A mechanism that becomes
inoperative is free to mutate without affecting viability — this is how neutral
variation accumulates, which is the raw material for future adaptation.

Propagator networks provide a natural mechanism for degeneracy: multiple
independent propagators can contribute partial information to the same cell, and
the merge operation combines them. Each contributing propagator is
self-contained and can produce a result by itself.

When not to build in degeneracy: when consistency is paramount and multiple
paths risk producing subtly different answers (transactional systems), or when
the system is genuinely closed to future change.

## The cost of flexibility

Flexibility has three costs:

1. **Comprehension.** Every extension point, generic dispatch, and combinator
   layer must be understood by readers. Unexercised flexibility is pure
   overhead.
2. **Performance.** Generic dispatch, predicate testing, and propagation are
   slower than direct calls.
3. **Testing.** Flexible systems have larger state spaces. Each extension point
   multiplies the number of configurations that should be tested.

Build flexibility where you have evidence the system will need to change. Build
concretely where you do not. A system should be slippery in the directions it is
likely to be extended and firm in the directions it is not. The mistake is
making everything slippery (AbstractFactoryFactory) or nothing slippery (a
monolithic script).

The principal cost of software is programmer time over the product's lifetime,
including maintenance and adaptation. Designs that minimize rewriting and
refactoring reduce overall cost even when the initial implementation is more
elaborate.

## Decision guide

When choosing a technique, match the kind of extension you need:

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
- Sussman, "Building Robust Systems" (2007) — the biological motivation
- Radul & Sussman, "The Art of the Propagator" (2009) — propagation model
- Abelson & Sussman, _Structure and Interpretation of Computer Programs_ (1985)
  — metalinguistic abstraction, eval/apply
- Sussman & Wisdom, _Structure and Interpretation of Classical Mechanics_ (2001)
  — generic arithmetic applied to physics
