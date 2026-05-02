---
description: "Writing, reviewing, or planning tests"
---

# Testing

How to test systems with both a formal specification and multiple runtime
implementations.

## The verification stack

Four activities, different guarantees, different costs:

- **Formal proof** — for-all-inputs guarantee by construction. A Lean theorem
  that bag transitions are monotone holds forever, but says nothing about
  whether the Python implementation actually implements bags correctly.
- **Property-based testing** — random inputs, stated invariants. Bridges the
  formal model to the runtime. One property test that "DISCARD matches any
  value" is worth a hundred hand-picked examples; Hypothesis finds edge cases
  you didn't think of.
- **Differential testing** — one implementation as oracle for another. Catches
  semantic divergence neither proofs nor properties find, because it tests the
  full composition end to end.
- **Unit/integration** — pin specific behaviors the others are too coarse for:
  error messages, CLI output, async timing, reconnection.

The layers compose upward. A theorem motivates a property test; a property test
motivates a differential test layer; unit tests fill gaps. When a differential
test finds a bug, the fix should add a property test that would have caught
it, ideally a theorem that proves the fix general.

## Property selection

The hardest part is choosing a property strong enough to catch real bugs but
precise enough to avoid false positives.

- **Algebraic** — strongest and most reusable. Roundtrip
  `parse(to_text(v)) == v`, idempotence `f(f(v)) == f(v)`, reflexivity
  `equal(v, v)`, symmetry `equal(a, b) == equal(b, a)`. Universal: hold for
  every value, no setup beyond a generator.
- **State machine** — how a system evolves under operation sequences. "After n
  asserts followed by n retracts, the key is absent." "Disjoint keys never
  interfere."
- **Monotonicity / conservation** — what operations cannot do. "Adding a caveat
  can only narrow acceptance." "Allocation counters never decrease." Catches
  the worst bugs — almost always works, violates structure under rare
  interleavings.
- **Separation** — independence. "Retracting k1 does not affect k2." "An
  observer on P does not fire for non-matching values." Prevents action at a
  distance.
- **Compositional** — combining components preserves the parts' guarantees. "A
  matching assert on an empty bag yields ABSENT_TO_PRESENT *and* the index
  returns the matching observer."

To find good properties, read the formal specification — every theorem is a
property test waiting to be written. If there is no specification, write the
property first; it forces you to articulate what the code should do.

## Strategy composition

A strategy is a recipe for generating values. Strategies compose.

**Atoms first.** Constrain ranges to avoid degenerate cases: integers in
`[-2^31, 2^31]`, bounded-length strings, regex-restricted symbols. Diverse
enough to find bugs, small enough to read in failure reports.

**Recursive structure.** `st.recursive` (Python) or nested `drawInteger` (Zig)
to build trees. Bound with `max_leaves` (6–8 is usually enough) — deep trees
slow generation and produce unreadable counterexamples.

**Domain-specific generators.** When testing a language, generate programs, not
strings. A composite that produces `(assert <label field>)` finds bugs random
strings never reach. Layer by complexity: bare assertions, then variable
binding, then reactive handlers, then composition.

**Roundtrip safety.** Not all values survive all roundtrips (bytes need hex,
frozensets lose order, floats have NaN). Build separate strategies per
boundary: `text_safe_atoms`, `preserves_values`, `bag_keys`. Filter the
strategy, not the test — `assume()` discards examples and wastes budget.

**Composite pattern.** When constraints between values cannot be expressed in a
single `draw` (e.g., a handler's pattern label must differ from its body
label), use `@st.composite` (Python) or a function over `ConjectureData` (Zig)
that draws multiple correlated values.

## The theorem-to-test bridge

- **Naming.** Each test class names the Lean module it covers; each test method
  names the theorem. `TestBagConversationalSoundness` covers
  `Tiny.ConversationalSoundness`. `test_fresh_assert_is_absent_to_present`
  covers `bagAdded_assert_fresh`. When a theorem changes, you can find every
  dependent test.
- **Structural correspondence.** Mirror the theorem's structure: preconditions
  → strategy filters; quantifier → strategy; induction on length → varying
  sequence lengths checking the inductive invariant.
- **Coverage completeness.** Every proven theorem gets at least one property
  test in each runtime. The proof guarantees the abstract model; the test
  checks the implementation. New theorem in Lean → add tests in Python and
  Zig. New property test without a theorem → consider whether it is provable.

## Differential testing

Both implementations should produce the same observable output for the same
input. The property is implicit; both agree → evidence of correctness; both
disagree → at least one has a bug.

**Observable comparison.** Compare at the level of observable world state, not
internal representation. For a dataspace, compare the set of assertions
visible externally (sorted, serialized). Internal details — handle order, facet
shape, evaluation strategy — are irrelevant.

**Program generation layers.** Layer 0: bare assertions. Layer 1: + variable
binding. Layer 2: + reactive handlers. Layer 3: + spawned actors. Layer 4+:
builtins, closures, nested handlers, multi-capture patterns. Each exercises a
different composition. Track known divergences explicitly rather than
suppressing whole layers.

**Error agreement.** Both should agree on what is an error. One errors and the
other succeeds → bug. Both error → acceptable regardless of message content.

## Shrinking

When a property fails, the counterexample is usually too large. Shrinking
reduces it to a minimum.

**Typed choice sequences.** Hypothesis and its ports shrink the *sequence of
choices* made during generation, not the values. Each choice is typed
(integer, boolean, bytes) and bounded. Shrinking replaces choices with smaller
ones (closer to `shrink_towards`, usually 0). Shrinking is automatic for any
strategy built from primitives — no custom shrinker needed.

**Span-aware passes.** The shrinker groups consecutive choices into spans
corresponding to one strategy invocation. It deletes spans, replaces them with
zeros, minimizes individual choices, redistributes between numeric pairs, and
reorders. Seven passes, looped to fixed point. Spans make shrinking
compositional — deleting a span removes a record field or list element, not an
arbitrary byte.

**Shrinking-friendly strategies.** Smaller choice values should produce simpler
outputs. Put the simplest alternative at index 0; the shrinker tries it first.
Draw a length followed by elements so the shrinker can drop trailing elements'
span. Avoid strategies where small choices produce complex outputs — the
shrinker pulls toward complexity.

## Stateful testing

Generates operation sequences against a model and the real system, checking
postconditions after each step. Finds bugs from specific orderings.

**The model.** Two sides — a model (simplified, trusted, often a dict or list)
and the system. The model's `nextState` is verifiable by inspection. The
system's response is compared after each command.

**Command generation.** Commands depend on current model state — you can only
retract a previously-asserted handle. Preconditions filter invalid commands.
This state-dependent generation explores reachable states, not arbitrary ones.

**Postcondition checking.** Cheap, runs after every step. For a dataspace:
assertion counts, observer notifications, handle validity.

**Shrinking sequences.** A failing 50-op sequence shrinks to maybe 3 — the
minimal interleaving that triggers the bug. This is stateful testing's most
valuable output: a minimal reproducer for an ordering bug.

## Stress testing

Not property tests — they check survival under sustained load.

**What to stress.** Rapid assert/retract cycles. Connect/disconnect with held
assertions. Sequential client sessions against a persistent server. Concurrent
observers on overlapping patterns. The goal is to trigger leaks, double-frees,
corrupted indices, and count drift.

**What to measure.** Wall-clock time (regression). Counts before/after
(conservation). State after disconnect (cleanup completeness). The most
valuable stress test asserts the server returns to baseline after a client
disconnects.

## Test architecture

- **One file per concern.** Kernel semantics, preserves roundtrip, differential
  fuzz — each in its own file. Different performance, failure modes, and
  maintenance.
- **Strategies are shared infrastructure.** Define domain strategies (atoms,
  values, programs, patterns) once and import. When the value model changes,
  the strategy changes in one place.
- **Settings are explicit.** Differential tests need long deadlines and
  `suppress_health_check=[too_slow]`. Pure property tests can use defaults.
  `@settings(max_examples=200)` says "we need coverage"; `max_examples=50`
  says "this is expensive."
- **Cross-implementation parity.** Every property in Python should have one in
  Zig. The Lean theorem is the shared spec; tests are independent conformance
  checks. A test in one language but not the other is a gap.

## References

- MacIver, [Hypothesis docs](https://hypothesis.readthedocs.io/) — typed choice
  sequences, shrinking, stateful testing, health checks
- Hughes & Claessen,
  [QuickCheck](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)
  (ICFP 2000) — `Arbitrary`, shrinking, properties as first-class values
- Hughes,
  [Testing the Hard Stuff and Staying Sane](https://www.youtube.com/watch?v=zi0rHwfiX1Q)
  — model-based testing, Erlang QuickCheck on distributed databases
- Hebert, [PropEr Testing](https://propertesting.com/) — stateful testing for
  Erlang/OTP, targeted PBT
- Garnock-Jones,
  [Conversational Concurrency](https://eighty-twenty.org/2018/01/24/conversational-concurrency)
  — Theorem 4.35, the formal foundation for dataspace assertion semantics
- Lamport, _Specifying Systems_ — TLA+, refinement mapping spec ↔
  implementation
- Barr et al.,
  [The Oracle Problem in Software Testing](https://ieeexplore.ieee.org/document/6963470)
  — differential testing as a solution
