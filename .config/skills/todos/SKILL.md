---
description: "Executing work from a TODO.md or *_TODO.md file"
---

# TODOs

How to plan, execute, and track work through TODO files when operating as an
iterative agent. Principles drawn from hierarchical task network planning,
dependency-directed backtracking, and observed failure modes of looping agents.

## The operating model

You execute in a loop. Each iteration starts fresh, with no memory of prior
runs. The TODO file is the only persistent state between iterations. What you
write in it determines whether the next iteration makes progress or wastes time.

The TODO file is three things at once: a task list, a decision log, and a
handoff document. A bare checklist fails at the second and third. Every entry
must carry enough context for a cold reader to understand what was done, what
was tried, and what remains.

## One item per iteration

Pick the first unchecked item. Complete it. Mark it done. Stop.

Don't start a second item. Don't fix adjacent issues you notice along the way.
Don't clean up files outside the current item. Scope creep is how agents run out
of context mid-task and produce incomplete changes across too many files.

If completing an item reveals a new problem, add it as a new unchecked item.
Don't fix it in the same iteration.

## Mark done with evidence

`[x]` by itself tells the next iteration nothing. When you check off an item,
include what you did and what changed:

```
- [x] P3.2: Fix bag transition for multi-retract — replaced loop with batch
      diff in retract_facet. Tests pass (zig build test, 47/47).
```

The note prevents two pathologies. The next iteration won't redo the work,
because the note explains what changed and how to verify it. A later iteration
won't revert the change without understanding why it was made. Both pathologies
come from bare check-marks that carry no information.

## Verification before check-off

Every item needs a mechanical verification criterion. If the item doesn't have
one, establish one before starting. Run the check after completing the work.
Don't mark an item done without seeing the check pass.

Good criteria are commands that return zero or nonzero: a test suite, a build, a
type checker, a linter. "Looks right" isn't verification.

If verification fails, leave the item unchecked and record what went wrong. The
next iteration should see the failure, not rediscover it independently.

## Decomposition

If you can't describe the exact edits an item requires, the item is compound.
Don't attempt a compound item directly. Your job for that iteration is to
replace it with concrete sub-items.

Decomposition is a valid iteration output. Replace the compound item with its
sub-items and mark the parent as decomposed:

```
- [x] P4: Add text-based mask generation (decomposed into P4.1–P4.4)
  - [ ] P4.1: Add --select flag to fill command
  - [ ] P4.2: Integrate CLIPSeg for text-to-mask
  - [ ] P4.3: Geometry-based masking fallback (--rect, --circle)
  - [ ] P4.4: Standalone mask command
```

Each sub-item should be scoped to one to three files, verifiable by a mechanical
check, and completable in a single iteration. If a sub-item fails any of these,
it's still compound.

Only decompose the next item you intend to work on. A TODO with twelve sub-items
decomposed three levels deep will be stale by item four. Break down one compound
item, execute its first sub-item, then assess whether the remaining sub-items
still make sense given the updated state. The correct decomposition of
"implement feature X" depends on what the codebase looks like now, not what it
looked like when the TODO was written. Two levels deep is the limit. Deeper
decomposition is speculative and will be invalidated by earlier work.

An item is compound when it has no specific files, no mechanical verification
criterion, or can't be completed in one iteration. "Improve performance," "clean
up the codebase," and "fix all bugs" are compound. When you encounter items like
these, decompose them or flag them as needing human specification.

## Recording failures

Before trying an approach, scan the TODO for prior failure notes on the same
item. If an approach was already tried and failed, don't try it again unless the
conditions that caused the failure have changed.

Write failed approaches inline with the item:

```
- [ ] P2.3: LLM-based prompt expansion
      Tried: direct API — rate-limited at free tier, unusable for batch
      Tried: local model — too large for CI runner memory
      Current approach: lightweight proxy with small model
```

In planning, these are called nogoods (records of which decision combinations
lead to dead ends). Without them, agents circle: try approach A, fail, try
approach B, fail, try approach A again without remembering it already failed.

When an agent can't make progress after two distinct attempts, leave the item
unchecked and record what's blocking it:

```
- [ ] P6.3: Wire loader poll into server run loop
      BLOCKED: async event loop not yet available. Tried manual poll with
      timer callback, but the timer API isn't exposed in the current server
      interface. Needs: async event loop or timer registration in server.
```

A clear block reason is more useful than a bad implementation. The next
iteration or a human can read the reason and either resolve the dependency or
restructure the plan. After recording the block, move to the next unchecked,
non-blocked item.

## Backtracking

When a step fails, trace the failure to its cause before attempting a fix.

If the failure is local (a typo, a wrong function name, an off-by-one), fix it
in place. The decomposition is sound; a leaf step went wrong.

If the failure reveals a bad assumption (the interface you're building against
doesn't exist, the approach requires a capability the system lacks), the problem
isn't the step but the decomposition that produced it. Record the invalid
assumption on the parent item and redecompose:

```
- [ ] P5: SVG round-trip (replanned — vtracer drops text labels)
  - [x] P5.1: Vectorize with vtracer — works for shapes, drops text
  - [ ] P5.2: Use potrace + manual text overlay instead
  - [ ] P5.3: Document round-trip with text preservation caveat
```

The scope of replanning matches the scope of the invalid assumption. A bad local
assumption means replan the sub-item. A bad structural assumption means replan
the parent. Don't replan everything. Trace the dependency chain to find the
actual cause and backtrack to that decision. Replanning steps that weren't
affected by the failure is wasted work.

## State checkpoints

At the boundary between phases or major items, write a brief checkpoint
summarizing the current state:

```
## P3 complete

DSL-to-diffusion pipeline working for Mermaid and D2 input. Style presets
functional. Structural preservation (P3.4) deferred — edit distorts layout
at high strength. Manifest records all from-dsl operations.
```

The checkpoint tells the next iteration what exists, what works, what's known to
be broken, and what assumptions are in play. Without it, the next iteration
reconstructs state from scratch by reading all the code, wasting context and
risking misunderstanding.

## Dependencies and ordering

Items are ordered by priority. The first unchecked item is highest priority.
Respect this ordering. Don't skip ahead to an easier item.

If you discover that a later item depends on an earlier one, or that an item
depends on something outside the TODO, record the dependency explicitly:

```
- [ ] P4.2: Integrate CLIPSeg
      Depends on: P4.1 (--select flag must exist first)
```

This prevents a future iteration from attempting the item out of order and
wasting a cycle discovering the dependency independently.

## Deleting the TODO

Delete the TODO file only when every item is verified complete and no blocked
items remain. If blocked items remain, leave the file for human review.

Before deleting, read the entire file one final time. If any completed item
lacks verification evidence, re-verify it.

## References

- Ghallab, Nau & Traverso, _Automated Planning and Acting_ (Cambridge, 2016) —
  HTN planning, task decomposition, plan repair vs. replanning, plan monitoring
- Stallman & Sussman, "Forward Reasoning and Dependency-Directed Backtracking in
  a System for Computer-Aided Circuit Analysis" (1977) — dependency-directed
  backtracking, nogood sets, tracing failures to causal decisions
- De Kleer, "An Assumption-based TMS" (1986) — assumption-based truth
  maintenance, nogood recording, support-set tracking
- Hanson & Sussman, _Software Design for Flexibility_ (MIT Press, 2021) —
  dependency tracking and backtracking in propagator networks
- Yang et al., "SWE-agent: Agent-Computer Interfaces Enable Automated Software
  Engineering" (2024) — localization-first execution, iterative agent patterns
