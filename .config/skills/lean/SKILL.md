---
description: "Writing or modifying Lean proofs"
---

# Lean

Principles for proving theorems in Lean 4 without Mathlib, distilled from TPIL4,
the Lean reference manual, the community simp guide, and Terry Tao's
formalization notes.

## Forward vs backward reasoning

At every step you choose: work from the goal upward (backward) or from
hypotheses downward (forward). This determines efficiency.

Backward reasoning (`apply`, `exact`, `constructor`) is the default. Start from
the goal and ask "what would prove this?" If the goal is `A /\ B`, split it. If
`P -> Q`, introduce `P` and prove `Q`. Backward reasoning is goal-directed — it
focuses effort on what matters.

Forward reasoning (`have`, `obtain`, `calc`) is for intermediate facts. Switch
when you need to derive something not directly visible in the goal. `have`
mirrors mathematical "it suffices to show" reasoning. `calc` is inherently
forward but reads like mathematics — use it for chains of equalities or
inequalities.

The trap: blind backward reasoning without specifying intermediate values.
Applying `le_trans` to `x <= z` without naming the witness creates an
underconstrained subgoal. Use `calc` or explicit `have` instead.

## The definitional equality principle

`rfl` is the gold standard because it means the definitions are doing the work.
When a proof is `rfl`, the kernel verifies equality through pure computation —
no lemmas, no search, no fragility. The intellectual content lives in the
definitions, not the proof.

Design definitions so `rfl` works. This is the single most important Lean design
principle. If you find yourself writing long simp chains to prove something
"obvious," the problem is usually the definition, not the proof.

The hierarchy of proof difficulty: `rfl` (definitional, zero effort) >
`decide`/`native_decide` (kernel computes a decision procedure) >
`simp`/`omega`/`grind` (tactic generates a proof term) > manual proof.

Strive to keep proofs as high on this hierarchy as possible.

## Simplification philosophy

Simp is a directed rewriter, not a solver. It applies `@[simp]`-tagged lemmas
left-to-right until no more apply. It does not search for proofs.

What makes a good simp lemma: the RHS must be strictly simpler than the LHS, it
must be unconditional or have easily-dischargeable side conditions, it must
converge (no cycles, no infinite growth), and it should push toward a canonical
normal form for your domain.

When multiple equivalent formulations exist (`n != 0` vs `0 < n`), pick one as
canonical and write simp lemmas that normalize everything to it.

A bare `simp` in the middle of a proof is fragile — it breaks when the simp set
changes. Prefer `simp only [...]` for non-terminal uses. When `simp` closes a
goal completely, bare `simp` is acceptable because the intent is clear.

Use `simp?` to discover what `simp` did. Even when you keep bare `simp`, running
`simp?` documents what happened.

## Term-mode vs tactic-mode

They are the same thing. Every tactic proof produces a term. The choice is
cognitive ergonomics.

Use term mode when the proof is a direct construction (`fun h => h.left`), when
it is short enough that tactic overhead adds noise, or when composing proof
terms into larger terms. Term-mode proofs are faster to typecheck because the
kernel processes them directly.

Use tactic mode when you need to see intermediate goal states, when you need
automation, when the proof involves case analysis with multiple subgoals, or
when exploring with `sorry` placeholders.

Mix freely. Inside `by`, `exact <term>` drops to term mode. Inside a term,
`by <tactics>` enters tactic mode.

## Structuring proofs

Outline with `sorry`, fill one at a time. Write the proof skeleton using `have`
statements and `sorry` placeholders. Verify Lean accepts the structure. Then
fill each `sorry` individually, compiling after each.

Name hypotheses deliberately. Use `h`-prefixed names (`hle`, `hmem`, `hne`).
Never rely on auto-generated names — they are intentionally inaccessible in
Lean 4. Use `case` tags over positional goals for robustness against reordering.

Extract lemmas when a `have` block exceeds ~30 lines, the same argument appears
in multiple proofs, or a subproof has a clear mathematical identity. Name
theorems `A_of_B_of_C` following the convention so autocomplete helps.

What makes a proof fragile: bare `simp` in non-terminal position, relying on
auto-generated hypothesis names, relying on implicit goal ordering, using
powerful automation without understanding why it worked.

## Computation in proofs

`decide`: for any proposition with a `Decidable` instance, evaluates the
decision procedure in the kernel. Proof by computation — the algorithm IS the
proof. Works for concrete closed propositions and finite enumerations. Does not
work for universally quantified propositions with free variables.

`native_decide`: same as `decide` but compiled to native code for speed. Use for
expensive computations. Introduces an axiom trusting the compiler.

`omega`: linear arithmetic over integers and naturals. Handles `+`, `-`,
`* (by constants)`, `min`, `max`, `mod`, `div`. The workhorse for numeric goals.

`grind`: SMT-style reasoning — it combines equality reasoning across theories,
linear arithmetic, and polynomial algebra into a single search. More powerful
than `simp` but slower and less predictable. Use when `simp` normalizes but
cannot close the goal and the problem mixes equalities with arithmetic.

## Dependent type thinking

Types can mention values. If `v : Vector n` and you rewrite `n` to `m`, the type
of `v` must also change. This is why `rw` can fail in dependent contexts.

`subst h` (where `h : x = e` and `x` is a free variable) eliminates `x` entirely
— the cleanest option when available. `rw [h]` does directed substitution in the
goal. The `▸` operator has better heuristics than `rw` for dependent contexts.
`simp_rw [h]` rewrites under binders where `rw` cannot reach.

Pattern matching is elimination. Under Curry-Howard, `match` on an inductive
type applies the type's eliminator. Proof structure should mirror data
structure: 3 constructors means 3 proof cases, recursive types demand inductive
proofs.

The `generalizing` pattern: `induction xs generalizing A` re-quantifies `A` in
the induction hypothesis. Without it, the IH is too specific for the recursive
case. This is the dependent-type equivalent of strengthening the induction
hypothesis.

## Debugging stuck proofs

A stuck proof means your mental model of the goal state diverges from Lean's.
The fix is always to inspect and reconcile.

Move the cursor through the proof and watch the Infoview. Use `#check` to verify
types, `#print` to see full definitions, `#reduce` to see what expressions
compute to. Use `simp?` / `exact?` / `apply?` to search — even when they fail,
the errors are informative.

Common patterns: "type mismatch" means implicit arguments were inferred
differently than you expected. Goals with opaque definitions need
`simp only [defName]` or `@[simp]` projection lemmas. `omega` cannot see through
opaque struct projections — normalize with `simp` first.

The generalization escape hatch: when a proof gets stuck because a variable
appears in both the goal and a hypothesis type, prove a more general statement
where the dependency is a parameter. Proving more is sometimes easier.

## Without Mathlib

You are building your own lemma library. `exact?` and `apply?` only search what
you have defined plus the core library. Prove small reusable lemmas and tag them
`@[simp]` when appropriate. Build your simp set deliberately — every `@[simp]`
lemma is an investment in future automation.

Use inductive predicates over computable functions for relations like
operational semantics. They do not require termination proofs and naturally
support inversion and case analysis.

The self-sufficiency mindset: every proof must be justified from first
principles. This is an advantage — you understand exactly what you depend on,
proofs are self-contained, and build times stay fast.

## References

- [Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/) —
  the canonical teaching resource
- [Lean 4 Reference Manual](https://lean-lang.org/doc/reference/latest/) —
  tactic reference, simp sets, propositional equality
- [Lean Community Simp Guide](https://leanprover-community.github.io/extras/simp.html)
- [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/)
- Terry Tao,
  [A Slightly Longer Lean 4 Proof Tour](https://terrytao.wordpress.com/2023/12/05/a-slightly-longer-lean-4-proof-tour/)
- Leslie Lamport, _How to Write a 21st Century Proof_
- [Lean 4.7.0 — omega tactic](https://lean-lang.org/blog/2024-4-4-lean-470/)
- [The grind tactic](https://lean-lang.org/doc/reference/latest/The--grind--tactic/)
