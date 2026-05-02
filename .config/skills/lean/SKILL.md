---
description: "Writing or modifying Lean proofs"
---

# Lean

Proving theorems in Lean 4 without Mathlib, distilled from TPIL4, the Lean
reference manual, the community simp guide, and Terry Tao's formalization
notes.

## Forward vs backward reasoning

Backward (`apply`, `exact`, `constructor`) is the default — start from the
goal, ask "what would prove this?" Goal-directed: focuses effort on what
matters. If `A /\ B`, split. If `P -> Q`, introduce `P`.

Forward (`have`, `obtain`, `calc`) for intermediate facts. Use when you need
something not directly visible in the goal. `have` mirrors "it suffices to
show." `calc` reads like mathematics — use it for chains of (in)equalities.

The trap: blind backward reasoning without naming intermediate witnesses.
Applying `le_trans` to `x <= z` without naming the witness creates an
underconstrained subgoal. Use `calc` or explicit `have`.

## The definitional equality principle

`rfl` is the gold standard — equality through pure kernel computation, no
lemmas, no search, no fragility. Intellectual content lives in the
definitions, not the proof.

Design definitions so `rfl` works. This is the single most important Lean
design principle. If you find yourself writing long simp chains for something
"obvious," the problem is the definition, not the proof.

Hierarchy of proof difficulty: `rfl` > `decide`/`native_decide` >
`simp`/`omega`/`grind` > manual. Stay as high as possible.

## Simplification

Simp is a directed rewriter, not a solver. It applies `@[simp]` lemmas
left-to-right until none apply.

A good simp lemma: RHS strictly simpler than LHS, unconditional or with
trivial side conditions, converges (no cycles, no growth), pushes toward a
canonical normal form. When equivalent formulations exist (`n != 0` vs
`0 < n`), pick one and normalize toward it.

Bare `simp` mid-proof is fragile — it breaks when the simp set changes. Prefer
`simp only [...]` for non-terminal uses. Bare `simp` is acceptable when it
closes the goal.

Use `simp?` to discover what `simp` did. Even when keeping bare `simp`,
`simp?` documents what happened.

## Term-mode vs tactic-mode

Same thing — every tactic proof produces a term. Choice is cognitive
ergonomics.

Term mode: direct construction (`fun h => h.left`), short proofs, composing
into larger terms. Faster typecheck.

Tactic mode: intermediate states, automation, multi-subgoal case analysis,
exploration with `sorry`.

Mix freely. Inside `by`, `exact <term>` drops to term mode. Inside a term,
`by <tactics>` enters tactic mode.

## Structuring proofs

Outline with `sorry`, fill one at a time. Write the skeleton as `have` +
`sorry`, verify Lean accepts it, then fill each `sorry` and recompile.

Name hypotheses deliberately — `h`-prefixed (`hle`, `hmem`, `hne`). Never
rely on auto-generated names; they are intentionally inaccessible. Use
`case` tags over positional goals for robustness against reordering.

Extract lemmas when a `have` block exceeds ~30 lines, the same argument
appears in multiple proofs, or a subproof has a clear mathematical identity.
Name `A_of_B_of_C` so autocomplete helps.

Fragility comes from: bare `simp` non-terminal, auto-generated hypothesis
names, implicit goal ordering, powerful automation used without understanding.

## Computation in proofs

- `decide` — for any `Decidable` proposition, evaluates the decision
  procedure in the kernel. Works for concrete closed propositions and finite
  enumerations. Not for free variables.
- `native_decide` — same, compiled to native. Trusts the compiler (axiom).
- `omega` — linear arithmetic over `Int`/`Nat`. Handles `+`, `-`, `* (const)`,
  `min`, `max`, `mod`, `div`. Workhorse for numeric goals.
- `grind` — SMT-style: equality reasoning across theories, linear arithmetic,
  polynomial algebra. More powerful than `simp` but slower. Use when `simp`
  normalizes but cannot close, and the problem mixes equalities with
  arithmetic.

## Dependent type thinking

Types can mention values. If `v : Vector n` and you rewrite `n` to `m`, the
type of `v` must change too — which is why `rw` can fail in dependent
contexts.

- `subst h` (where `h : x = e` and `x` is free) eliminates `x` entirely.
  Cleanest when available.
- `rw [h]` does directed substitution.
- `▸` has better heuristics than `rw` for dependent contexts.
- `simp_rw [h]` rewrites under binders where `rw` cannot.

Pattern matching is elimination. Under Curry-Howard, `match` on an inductive
type applies the type's eliminator. Proof structure mirrors data structure: 3
constructors → 3 cases; recursive types demand inductive proofs.

The `generalizing` pattern: `induction xs generalizing A` re-quantifies `A` in
the IH. Without it the IH is too specific. Dependent-type equivalent of
strengthening the induction hypothesis.

## Debugging stuck proofs

Stuck means your mental model diverges from Lean's. Inspect and reconcile.

Move the cursor through the proof; watch the Infoview. Use `#check`, `#print`,
`#reduce` to see what expressions actually compute to. `simp?`/`exact?`/`apply?`
search — even when they fail, the errors are informative.

Common patterns:

- "Type mismatch" usually means implicit arguments inferred differently than
  expected.
- Goals with opaque definitions need `simp only [defName]` or `@[simp]`
  projection lemmas.
- `omega` cannot see through opaque struct projections — `simp` first.

The generalization escape hatch: when stuck because a variable appears in
both goal and hypothesis type, prove a more general statement where the
dependency is a parameter. Proving more is sometimes easier.

## Without Mathlib

You are building your own lemma library. `exact?`/`apply?` only search what
you have plus core. Prove small reusable lemmas; tag `@[simp]` when
appropriate. Every `@[simp]` is an investment in future automation.

Use inductive predicates over computable functions for relations like
operational semantics. They do not require termination proofs and naturally
support inversion and case analysis.

Self-sufficiency is an advantage — you understand exactly what you depend on,
proofs are self-contained, builds stay fast.

## References

- [Theorem Proving in Lean 4](https://lean-lang.org/theorem_proving_in_lean4/)
- [Lean 4 Reference Manual](https://lean-lang.org/doc/reference/latest/)
- [Lean Community Simp Guide](https://leanprover-community.github.io/extras/simp.html)
- [Mathematics in Lean](https://leanprover-community.github.io/mathematics_in_lean/)
- Terry Tao,
  [A Slightly Longer Lean 4 Proof Tour](https://terrytao.wordpress.com/2023/12/05/a-slightly-longer-lean-4-proof-tour/)
- Leslie Lamport, _How to Write a 21st Century Proof_
- [Lean 4.7.0 — omega tactic](https://lean-lang.org/blog/2024-4-4-lean-470/)
- [The grind tactic](https://lean-lang.org/doc/reference/latest/The--grind--tactic/)
