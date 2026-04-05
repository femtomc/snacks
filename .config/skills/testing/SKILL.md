---
description: "Writing, reviewing, or planning tests"
---

# Testing

How to test systems that have both a formal specification and multiple runtime
implementations. Principles drawn from Hypothesis (MacIver), QuickCheck (Hughes
& Claessen), PropEr Testing (Hebert), the Syndicate protocol verification
literature, and the patterns that emerged from testing this codebase across
Lean, Python, and Zig.

## The verification stack

Testing is not one activity. It is four activities with different guarantees,
different costs, and different failure modes. Each layer catches bugs the others
miss.

**Formal proof** establishes that a property holds for all inputs, forever, by
construction. A Lean theorem that bag transitions are monotone does not need
re-checking when the code changes — but it says nothing about whether the Python
implementation actually implements bags correctly.

**Property-based testing** generates many random inputs and checks that a stated
invariant holds for each one. It bridges the gap between the formal model and
the runtime: the theorem tells you what must be true; the property test checks
that it is. A single property test that "DISCARD matches any value" is worth
more than a hundred hand-picked examples, because Hypothesis will find the edge
cases you did not think of.

**Differential testing** treats one implementation as an oracle for another.
Generate random well-formed programs, run them through both interpreters, and
compare observable output. This catches semantic divergence that neither
property tests nor proofs will find, because it tests the full composition of
parsing, evaluation, and world-state management — not isolated properties of
components.

**Unit and integration tests** pin specific behaviors that the other layers are
too coarse to catch: error messages, CLI output formats, async lifecycle timing,
network reconnection. They are the fastest to write and the most brittle to
maintain.

The layers compose upward. A proven theorem motivates a property test. A
property test motivates a differential test layer. Unit tests fill the gaps.
When a differential test finds a bug, the fix should be accompanied by a
property test that would have caught it, and ideally a theorem that proves the
fix is general.

## Property selection

The hardest part of property-based testing is choosing what property to test.
"It doesn't crash" is a property, but a weak one. The goal is to state
invariants that are strong enough to catch real bugs and precise enough to not
produce false positives.

**Algebraic properties** are the strongest and most reusable. Roundtrip:
`parse(to_text(v)) == v`. Idempotence: `preserve(preserve(v)) == preserve(v)`.
Reflexivity: `preserve_equal(v, v)`. Symmetry:
`preserve_equal(a, b) == preserve_equal(b, a)`. These properties are universal —
they hold for every value in the domain and require no setup beyond a value
generator.

**State machine properties** describe how a system evolves under sequences of
operations. "After n asserts followed by n retracts, the key is absent" is a
state machine property. "Disjoint keys never interfere" is an independence
property. These are the natural language for testing reactive systems where
observable behavior depends on operation history.

**Monotonicity and conservation** properties constrain what operations can and
cannot do. "Adding a caveat can only narrow acceptance, never widen it."
"Allocation counters never decrease." "Assertion lifetime equals connection
lifetime." These catch the most insidious bugs — the ones where something works
almost always but violates a structural invariant under rare interleavings.

**Separation properties** assert independence. "Retracting key k1 does not
affect key k2." "An observer on pattern P does not fire for non-matching
values." "A define produces no SAM operations." These prevent action at a
distance.

**Compositional properties** verify that combining components preserves the
guarantees of the parts. "A matching assert on an empty bag yields
ABSENT_TO_PRESENT and the skeleton index returns the matching observer." This
tests the bag and the index together, which is where integration bugs live.

To find good properties, read the formal specification. Every theorem is a
property test waiting to be written. If there is no formal specification, write
the property first — it forces you to articulate what the code should do, which
is half the design work.

## Strategy composition

A strategy is a recipe for generating random values of a specific type.
Strategies compose: you build complex generators from simple ones.

**Atoms first.** Start with the irreducible values of your domain — integers,
booleans, strings, symbols. Constrain ranges to avoid degenerate cases: integers
within `[-2^31, 2^31]`, strings of bounded length, symbols from a regex that
avoids reserved words. The goal is values that are diverse enough to find bugs
but small enough to read in failure reports.

**Recursive structure.** Use `st.recursive` (Python) or nested `drawInteger`
choices (Zig) to build trees of values. The base case is atoms; the extension
adds records, tuples, sequences. Bound the recursion with `max_leaves` — deep
trees slow generation and produce unreadable counterexamples. Six to eight
leaves is usually enough.

**Domain-specific generators.** When testing a language, generate programs, not
strings. A composite strategy that produces `(assert <label field>)` will find
bugs that a random string generator never reaches, because every generated
program is syntactically valid. Layer generators by complexity: start with
single-instruction programs (layer 0), then add variable binding, then reactive
handlers, then composition patterns. Each layer exercises a different part of
the system.

**Roundtrip safety.** Not all values survive all roundtrips. Bytes need hex
encoding. Frozensets lose ordering. Floats have NaN. Build separate strategies
for each roundtrip boundary: `text_safe_atoms` for the text parser,
`preserves_values` for the binary format, `bag_keys` for hashable values. Filter
the strategy, not the test — `assume()` discards examples and wastes the budget.

**The composite pattern.** When a single `draw` call cannot express the
constraints between generated values (e.g., a during handler's pattern label
must differ from its body label), use `@st.composite` (Python) or a function
that takes `ConjectureData` (Zig) and draws multiple correlated values. This
keeps the generator legible and the constraints explicit.

## The theorem-to-test bridge

A formal theorem proves a property about an abstract model. A property test
checks that a concrete implementation satisfies the same property. The bridge
between them has three parts.

**Naming.** Each test class names the Lean module it covers. Each test method
names the theorem. `TestBagConversationalSoundness` covers
`Tiny.ConversationalSoundness`. `test_fresh_assert_is_absent_to_present` covers
`bagAdded_assert_fresh`. This traceability is not documentation — it is a
maintenance tool. When a theorem changes, you can find and update every test
that depends on it.

**Structural correspondence.** The test should mirror the theorem's structure.
If the theorem has preconditions, the test's `given` should generate values
satisfying them. If the theorem quantifies over a type, the test's strategy
should cover that type. If the theorem uses induction on sequence length, the
test should generate sequences of varying length and check the inductive
invariant at each step.

**Coverage completeness.** Every proven theorem should have at least one
property test in each runtime implementation. This is not redundancy — the proof
guarantees the abstract model, but a bug in the implementation can violate the
proven property. The test is the bridge that connects the two. When a new
theorem is added in Lean, add corresponding property tests in Python and Zig.
When a property test is added without a theorem, consider whether the property
is provable — if it is, the proof strengthens the guarantee from "holds for the
examples we tried" to "holds forever."

## Differential testing

Differential testing exploits the existence of multiple implementations to find
bugs without writing any assertions. The property is implicit: both
implementations should produce the same observable output for the same input.

**The oracle problem.** Most programs have no oracle — you cannot check the
output without reimplementing the logic. Differential testing solves this by
making one implementation the oracle for the other. When both agree, you have
evidence (not proof) of correctness. When they disagree, at least one has a bug.

**Observable comparison.** Compare at the level of observable world state, not
internal representation. For a dataspace system, the observable state is the set
of assertions visible to an external observer. Sort the set, serialize each
element to text, and compare the sorted lists. Internal details like handle
allocation order, facet tree shape, or evaluation strategy are irrelevant.

**Program generation layers.** Generate programs in layers of increasing
complexity. Layer 0: bare assertions. Layer 1: variable binding plus assertions.
Layer 2: reactive handlers (during, on-message). Layer 3: spawned actors. Layer
4+: builtins, closures, nested handlers, multi-capture patterns. Each layer
exercises a different composition of language features. When a layer has known
divergences (one implementation has a known bug), separate those programs and
track them explicitly rather than suppressing the entire layer.

**Error agreement.** Both implementations should agree on what constitutes an
error. If one errors and the other succeeds, that is a bug — even if the
successful output looks correct. If both error, that is acceptable regardless of
error message content.

## Shrinking

When a property test fails, the counterexample is usually too large to debug
directly. Shrinking reduces it to a minimal failing example by systematically
simplifying the input while preserving the failure.

**Typed choice sequences.** Hypothesis and its ports do not shrink values
directly. They shrink the sequence of choices made during generation. Each
choice is typed (integer, boolean, bytes) and bounded (min, max,
shrink_towards). Shrinking replaces choices with smaller ones — closer to
`shrink_towards`, which is usually zero or the minimum. This means shrinking is
automatic for any strategy built from the primitives. You do not need to write a
custom shrinker.

**Span-aware passes.** The shrinker groups consecutive choices into spans that
correspond to one strategy invocation. It tries deleting entire spans, replacing
spans with trivial (all-zeros) versions, minimizing individual choices,
redistributing value between numeric pairs, and reordering spans. Seven passes,
looped until no progress. The span structure is what makes shrinking
compositional — deleting a span removes an entire record field or list element,
not an arbitrary byte.

**Shrinking-friendly strategies.** Design strategies so that smaller choice
values produce simpler outputs. If you draw an integer to select between
alternatives, put the simplest alternative at index 0 — the shrinker will try it
first. If you draw a length followed by that many elements, the shrinker can
reduce the length by deleting the trailing elements' span. Avoid strategies
where small choice values produce complex outputs, because the shrinker will
pull toward complex cases.

## Stateful testing

Stateful testing generates sequences of operations against a model and a real
system, checking postconditions after each step. It finds bugs that arise from
specific operation orderings — the kind of bug that property tests on isolated
functions never see.

**The model.** A state machine test has two sides: a model (simplified, trusted,
often a dict or list) and the system under test (the real implementation). The
model's `nextState` function is simple enough to verify by inspection. The
system's response is compared against the model's prediction after each command.

**Command generation.** Commands are generated from the current model state —
you can only retract a handle that was previously asserted, only observe a
pattern that makes sense given current assertions. Preconditions filter invalid
commands. This state-dependent generation is what distinguishes stateful testing
from simply generating random operation sequences: it explores reachable states,
not arbitrary ones.

**Postcondition checking.** After each command, check that the real system's
observable state matches the model's predicted state. For a dataspace, this
means checking assertion counts, observer notifications, and handle validity.
Postconditions should be cheap — they run after every step, so expensive
assertions multiply the test cost by the sequence length.

**Shrinking sequences.** The shrinker reduces failing command sequences by
deleting commands, simplifying command arguments, and reordering independent
commands. A failing sequence of 50 operations might shrink to 3 — the minimal
interleaving that triggers the bug. This is where stateful testing produces its
most valuable output: a minimal reproducer for a concurrency or ordering bug.

## Stress testing

Stress tests are not property tests. They do not check invariants against random
inputs. They check that the system survives sustained load without corruption.

**What to stress.** Rapid assert/retract cycles (hundreds per turn). Client
connect/disconnect while assertions are held. Sequential client sessions against
a persistent server. Concurrent observers on overlapping patterns. The goal is
to trigger resource leaks, double-frees, corrupted indices, and assertion count
drift.

**What to measure.** Wall-clock time (regression detection). Assertion counts
before and after (conservation). State after client disconnect (cleanup
completeness). The most valuable stress test asserts that server state returns
to baseline after a client disconnects — this tests the full cleanup path that
is hardest to get right in a reactive system.

## Test architecture

**One file per concern.** Kernel semantics properties in one file. Preserves
roundtrip properties in another. Differential fuzz tests in a third. Do not mix
property tests with integration tests — they have different performance
characteristics, different failure modes, and different maintenance needs.

**Strategies are shared infrastructure.** Define domain strategies (atoms,
values, programs, patterns) once and import them. A strategy is as much a part
of the test infrastructure as a fixture. When the value model changes, the
strategy changes in one place.

**Settings are explicit.** Differential tests need long deadlines and
`suppress_health_check=[too_slow]`. Property tests on pure functions can use
defaults. Make the tradeoff visible: `@settings(max_examples=200)` says "we need
thorough coverage here" and `max_examples=50` says "this is expensive, we accept
less coverage."

**Cross-implementation parity.** Every property tested in Python should have a
corresponding property test in Zig (and vice versa). The Lean theorem is the
shared specification; the property tests are independent checks that each
implementation conforms. When a test exists in one language but not the other,
that is a gap to fill, not an acceptable state.

## References

- David MacIver, [Hypothesis documentation](https://hypothesis.readthedocs.io/)
  — typed choice sequences, shrinking, stateful testing, health checks
- David MacIver, "In Praise of Property-Based Testing" and "Hypothesis: A new
  approach to property-based testing" — the internal data representation is a
  choice sequence, not a value; this unifies generation and shrinking
- John Hughes & Koen Claessen,
  [QuickCheck: A Lightweight Tool for Random Testing of Haskell Programs](https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf)
  — the foundational work on property-based testing: shrinking, arbitrary
  typeclass, properties as first-class values
- John Hughes,
  [Testing the Hard Stuff and Staying Sane](https://www.youtube.com/watch?v=zi0rHwfiX1Q)
  — model-based testing for stateful systems, Erlang QuickCheck, testing
  distributed databases
- Fred Hebert, [PropEr Testing](https://propertesting.com/) — thinking in
  properties, stateful testing for Erlang/OTP, targeted property-based testing
- Tony Garnock-Jones,
  [Conversational Concurrency](https://eighty-twenty.org/2018/01/24/conversational-concurrency)
  — Theorem 4.35 (bag transition soundness), the formal foundation for dataspace
  assertion semantics
- Lamport, _Specifying Systems_ — TLA+ as a source of testable state machine
  specifications, the concept of refinement mapping between specification and
  implementation
- Barr et al.,
  [The Oracle Problem in Software Testing: A Survey](https://ieeexplore.ieee.org/document/6963470)
  — differential testing as a solution to the oracle problem
