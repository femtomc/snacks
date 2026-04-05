---
description: "Coordinating multi-turn agent work across files and modules"
---

# Bellman

Durable coordination kernel for multi-turn agent work. Use Bellman when a task
spans multiple files, modules, or deliverables that cannot be completed
atomically in one turn.

## The model

Bellman has three parts:

- The **graph** — issues connected by dependency edges. Issues have status,
  outcome, body (task packet), nogoods (failed approaches), and comments.
- The **event log** — append-only record of everything that happened.
- The **state machine** — claims ready issues and invokes agents.

Bellman discovers the workspace from the current directory and resolves the
run automatically from the issue ID.

## Issue lifecycle

Edges: `requires` (B waits for A), `parent` (B is child of A), `blocks`
(reverse of requires).

Terminal success outcomes: `success`, `skipped`, `simulated` — unblock
dependents. `expanded` — yielded after delegating into children; not terminal.
Retryable outcomes: `failure`, `blocked`, `needs_work`.

Readiness: an open issue is ready when all requires/blocks deps closed
successfully, all children settled, and no execution conflict exists.

## Execution (leaf work)

**Step 1 — read your issue. Always.**

    bellman context <issue-id> --json

Check body for acceptance criteria. Check nogoods for approaches that already
failed. Check comments for context from prior agents. Do not start working
until you have read everything.

**Step 2 — do the work.**

**Step 3 — close. This is mandatory.**

    bellman mutate close <issue-id> success

If you do not close, the turn has no effect and the work will be retried from
scratch. Always close before stopping.

**Recording what you did:**

    bellman comment add <issue-id> "what was verified" --kind goods --author-kind agent

Comment kinds: `note`, `goods` (what worked), `progress`, `blocker`,
`decision`, `evidence`, `handoff`, `review`.

**If blocked:**

    bellman mutate close <issue-id> blocked --detail "what you need"

**If the work fails:**

    bellman mutate close <issue-id> failure --nogood "approach tried|why it failed"

## Decomposition (splitting work)

When the issue is too large for one turn, decompose into children and yield.

**When to decompose:** spans multiple files, modules, or deliverables.
Prefer 2-5 chunky children over many tiny ones — each child costs a full
agent turn.

    bellman mutate create "child A" --body "..." --parent <issue-id>
    bellman mutate create "child B" --body "..." --parent <issue-id> \
      --require <child-A-id>
    bellman mutate close <issue-id> expanded

Stop after closing expanded. Other workers will claim your children. Bellman
reclaims the parent when a child fails or when all direct children settle.

On continuation: verify the combined output, then close success. If gaps
remain, create more children and close expanded again.

## Concurrency

By default, issues execute serially. For parallel execution, declare scopes:

    bellman mutate create "task A" --body "..." --parent <id> \
      --execution-mode parallel --edit-path src/parser.py
    bellman mutate create "task B" --body "..." --parent <id> \
      --execution-mode parallel --edit-path src/evaluator.py

Scope semantics: `--edit-path` (exclusive write), `--read-path` (shared read),
`--lock` (named semantic lock). Two parallel issues with overlapping edit
paths serialize. No scope declared = conflicts with everything.

Audit before execution: `bellman inspect concurrency --root <id>`.

## Routing

Route children to different agents/models:

    bellman mutate create "Design" --body "..." --parent <id> \
      --agent claude-acp --model claude-opus-4-6
    bellman mutate create "Implement" --body "..." --parent <id> \
      --agent codex-acp --model o3 --require <design-id>

Named profiles: `bellman profile save fast --agent codex-acp --model o3`.
Use with `--profile fast` on create or step.

## Repair

Nogoods persist across retries. Always check before starting work.

    bellman repair <id>               # reopen minimal causal slice
    bellman retry <id>                # repair + re-execute
    bellman inspect repair-preview <id>  # preview before repairing

Record what worked: `bellman comment add <id> "approach=X" --kind goods`.

## Observation

    bellman status                         # DAG tree view
    bellman next --json --brief            # ready frontier
    bellman inspect validate --root <id>   # terminality check
    bellman wait --for-change              # block until something happens
    bellman events --follow                # stream live events

The `kind` field from `inspect validate` tells you what to do next:
`complete`, `ready`, `running`, `retryable_failure`, etc.

## Orchestration

End-to-end flow:

    bellman init task.md                   # bootstrap
    bellman context root --json            # read prompt
    # create children, close root expanded
    bellman run --workers 4 --repair       # drive to completion
    bellman status                         # verify
    bellman mutate close root success      # finish

With supervisor: run `bellman supervise --checker ./validate.sh` in parallel
for post-close validation.

## Advanced

- `bellman re-expand <id>` — discard children, try new decomposition
- `bellman at-risk <id>` — check blast radius before repair
- `--tag` on create for partitioned views and scoped stepping
- `bellman control interrupt/resume` — durable pause/resume
- Inner runs via nested `bellman init` for isolated subproblems
- `bellman inspect metrics` for performance analysis
- `bellman search "query"` for full-text search across all runs
