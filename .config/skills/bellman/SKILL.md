---
description: "Coordinating multi-turn agent work across files and modules"
---

# Bellman

You have a complex task — multiple files, subtask dependencies, work that
cannot be done atomically in one turn. Bellman turns it into a DAG of
issues, dispatches agents to execute each one, and retries failures with
structured memory of what was already tried.

You decompose. Bellman executes.

## Which role are you?

**If bellman dispatched you** — your preamble says "You are a Bellman
agent assigned to issue ..." and hands you an issue ID — skip to
[Execution (leaf work)](#execution-leaf-work). Everything between here
and that section is for orchestrators. Your preamble and issue body
already tell you what to do; the Execution section fills in the details.

**If you are reaching for bellman yourself** — you have a task and want
bellman to coordinate it — you are the orchestrator. Read on.

## Your role: orchestrator

When you reach for bellman, you are the orchestrator. You do three things:

1. Describe the work as a DAG of issues with dependency edges.
2. Hand the DAG to `bellman run`, which dispatches agents to execute each
   issue in dependency order.
3. Review the result when bellman finishes.

You do NOT execute leaf issues yourself. After decomposing, you yield.
Bellman claims ready issues and dispatches separate agents to do the work.
Each agent reads its assigned issue, executes it, closes it, and bellman
cascades to dependents.

**The anti-pattern:** decompose the DAG correctly, then start doing the
leaf work yourself instead of running `bellman run`. This abandons durable
state, retry semantics, parallelism, and nogood tracking — everything
bellman exists to provide.

## Bootstrap

    bellman init task.md

Write a prompt file describing the full task with acceptance criteria.
`init` creates a root issue and prints the run ID.

## Characterize the task

Before you decompose, characterize the task. The shape of the work
determines which decomposition strategy you need. Most real tasks trigger
at least one of these — a task that triggers none is the simple case,
not the common one.

**Can you write every child's spec right now, without seeing another
child's output?**
If not, you have phased work — child B's body depends on what child A
produces. You need [phased execution](#phased-execution).

**Do children produce artifacts that must integrate correctly?**
Shared interfaces, combined configs, code that calls code another child
wrote — any of these mean a silent integration failure can slip past
individual child success. You need a [review gate](#review-gates).

**Could a child fail repeatedly in ways that clutter the main DAG?**
Exploratory work, uncertain approaches, tasks that might need several
decomposition attempts — these pollute the parent run's nogoods and
state. You need an [inner run](#inner-runs).

**Is there a cross-cutting constraint every child must satisfy?**
A test suite, a type checker, a style policy — something that can't be
checked per-child because it applies to the integrated result. You need
a [supervisor sidecar](#supervisor-sidecars).

**Are children independent and touching disjoint files?**
They can run concurrently. You need
[parallel execution](#parallel-execution).

**Does the decomposition itself require domain knowledge you lack?**
If you can't write good child specs without surveying the codebase or
understanding the problem deeply, you need
[delegated decomposition](#delegated-decomposition).

**Will this run take more than one dispatch cycle, or are you running
parallel workers or multiple workstreams?**
Any run with phased execution, review gates, parallel workers, or
multiple `bellman run` processes needs live observation. Without it you
discover stalls, conflicts, and failures minutes after they happen
instead of as they happen. You need
[live observation](#live-observation).

## Decompose

Three decisions per child: what work (`--body`), what order (`--require`),
and who executes it (`--agent`, `--model`).

    bellman context root --json
    bellman mutate create "child A" --body "..." --parent root \
      --agent claude-acp --model claude-sonnet-4-6
    bellman mutate create "child B" --body "..." --parent root \
      --require <child-A-id> --agent claude-acp --model claude-opus-4-6
    bellman mutate close root expanded

Prefer 2–5 chunky children over many small ones — each child costs a
full agent turn. Use `bellman acp list` for available agents and
`bellman profile list` for saved agent/model combinations. Match
capability to complexity: a stronger model for design-heavy work, a
faster one for mechanical changes.

After closing expanded, stop. Bellman claims your children.

## Patterns

These are not optional extras. They are how you handle real tasks. A
task with no integration risk, no phased dependencies, no cross-cutting
constraints, and no exploratory subtasks is rare.

### Review gates

**When:** children produce artifacts that must work together — shared
interfaces, combined configurations, code that crosses child boundaries.

**The problem:** each child succeeds individually, but the integrated
result is broken. Without a review gate, you close the parent on child
completion and ship the breakage.

**How:** when bellman reclaims a parent after all children settle, the
orchestrator gets another turn. Use it to verify the integrated result:

    bellman status
    # if gaps remain:
    bellman mutate create "fix integration" --body "..." --parent <id>
    bellman mutate close <id> expanded      # yield again
    # if correct:
    bellman mutate close <id> success

The parent is not done when its children are done. The parent is done
when the integrated result is correct.

### Phased execution

**When:** child B's spec cannot be written until child A produces output.
The decomposition itself is staged — you know phase 1's tasks but phase 2
depends on phase 1's results.

**The problem:** you either write vague child specs ("handle whatever A
produced") that agents can't execute well, or you over-specify and get
brittle specs that break when A's output differs from your prediction.

**How:** tag children by phase and drive phases sequentially:

    bellman mutate create "design API" --body "..." --parent <id> --tag phase1
    bellman mutate create "write spec" --body "..." --parent <id> --tag phase1
    bellman run --tag phase1 --agent claude-acp --repair
    # read phase 1 output, then decompose phase 2
    bellman mutate create "implement API" --body "..." --parent <id> --tag phase2 \
      --require <design-id>
    bellman run --tag phase2 --agent claude-acp --repair

You decompose incrementally, not all at once. Each phase's output informs
the next phase's decomposition.

### Inner runs

**When:** a subtask is exploratory, might fail messily, or needs its own
decomposition that you want isolated from the main DAG.

**The problem:** a flailing child generates nogoods and retries that
clutter the main run's state. Its failures block unrelated siblings
during repair. Its decomposition (if it expands) adds noise to the
parent DAG.

**How:** create a separate bellman run for the subproblem:

    sub=$(bellman init --run-id-only <(echo "explore approach X"))
    bellman run --run-id "$sub" --agent claude-acp --repair
    # on success, feed results back to the main run

Inner retries don't pollute outer state. If the inner run fails entirely,
the outer run sees one failure, not a trail of nogoods from a dozen
attempts.

### Supervisor sidecars

**When:** a cross-cutting constraint spans children — a test suite, type
checker, linter, or business rule that must hold over the integrated
result, not just individual children.

**The problem:** each child passes its own checks, but the combined
output violates the constraint. You discover this at the review gate,
after all work is done.

**How:** attach a checker that runs on every close:

    bellman supervise --checker ./validate.sh

The supervisor rejects closes that violate the constraint, catching
problems as they happen rather than after all children settle.

### Parallel execution

**When:** children are independent and touch disjoint files.

**How:** declare scopes so bellman can run them concurrently:

    bellman mutate create "parser" --body "..." --parent <id> \
      --execution-mode parallel --edit-path src/parser.py
    bellman mutate create "evaluator" --body "..." --parent <id> \
      --execution-mode parallel --edit-path src/evaluator.py

Scope types: `--edit-path` (exclusive write), `--read-path` (shared
read), `--lock` (named semantic lock). Overlapping edit paths serialize
automatically. No scope declared = conflicts with everything.

Audit before execution: `bellman inspect concurrency --root <id>`.

For fully independent workstreams with no shared state, use separate
runs entirely:

    r1=$(bellman init --run-id-only audio.md)
    r2=$(bellman init --run-id-only graphics.md)
    bellman run --run-id "$r1" --agent claude-acp --repair   # bg 1
    bellman run --run-id "$r2" --agent claude-acp --repair   # bg 2

### Delegated decomposition

**When:** you can't write good child specs because you don't know the
codebase or domain deeply enough. The decomposition itself requires
judgment you lack.

**How:** let `bellman run` dispatch an agent to decompose:

    bellman run --agent claude-acp --repair

The dispatched agent reads the prompt, surveys the codebase, creates
children, and closes root as expanded. Bellman cascades into the
children.

The tradeoff: you give up direct control over decomposition structure
and per-child routing. Use this when a domain-aware agent will decompose
better than you can from the outside.

Delegated decomposition composes recursively — a dispatched agent can
itself decompose, creating grandchildren.

## Drive to completion

    bellman run --agent claude-acp --repair

Claims ready issues, dispatches agents, waits when blocked, retries on
failure, exits when the scope is final. The `--agent` flag sets the
default; per-issue routing (from decomposition) overrides it.

Use `--workers N` with parallel-scoped issues for concurrent execution.

## Live observation

**When:** the run has more than one dispatch cycle — phased execution,
review gates, parallel workers, or multiple concurrent `bellman run`
processes. In practice, most non-trivial runs qualify.

**The problem:** you fire `bellman run` and context-switch. A child
stalls on turn 2, a parallel worker hits a scope conflict, a phase
completes and needs your decomposition for the next phase — but you
don't find out until you check manually, minutes later. The run's
wall-clock time inflates with your reaction latency.

**How — pick the level that matches the run:**

**One-shot check** — sufficient between phases or after `bellman run`
exits:

    bellman status
    bellman next --json --brief

**Event-driven dashboard** — refreshes on every durable event, not on a
timer. Use this for any run you are actively orchestrating:

    while :; do clear; bellman status; \
      bellman wait --for-change >/dev/null 2>&1 || sleep 2; done

**Event tail** — stream structured events for scripting or watching
alongside the dashboard:

    bellman events --follow | jq -c '{type, issue_id, at}'

**tmux operator dashboard** — status pane, event tail, and N worker
panes in one session. Use this for parallel runs or when you want
workers visible:

    bell-session() {
      local prompt=$1 n=${2:-4} agent=${3:-codex-acp}
      local r
      r=$(bellman init --run-id-only "$prompt") || return 1

      tmux new-session -d -s "bell-$r" -x 200 -y 50
      tmux send-keys "while :; do clear; bellman status --run-id $r; \
        bellman wait --run-id $r --for-change >/dev/null 2>&1 \
        || sleep 2; done" Enter
      tmux split-window -h
      tmux send-keys "bellman events --run-id $r --follow \
        | jq -c '{type, issue_id, at}'" Enter
      for i in \$(seq "\$n"); do
        tmux split-window -v
        tmux send-keys "bellman run --run-id $r \
          --agent $agent --repair" Enter
      done
      tmux select-layout tiled
      tmux attach-session -t "bell-$r"
    }

**Multiple independent workstreams** — launch each `bellman run` as a
separate background process with its own dashboard. Do not cram multiple
runs into one shell with `&` — you lose per-run event tracking.

**Compact JSON for scripting:**

    # Count issues by status
    bellman status --json \
      | jq '[.issues[].status] | group_by(.) | map({(.[0]): length}) | add'

    # One-line progress summary
    bellman status --json \
      | jq '"done: \([.issues[] | select(.status == "closed")] | length) / \(.issues | length)"'

See `bellman skill monitor` for the full reference.

## Verify and close

    bellman status
    bellman inspect validate --root <id>
    bellman mutate close root success

The `kind` field from `inspect validate` tells you what to do next:
`complete`, `ready`, `running`, `retryable_failure`, etc.

## Issue lifecycle

Issues have status (open, in_progress, closed) and outcome:

- Terminal success: `success`, `skipped`, `simulated` — unblock dependents.
- Yielded: `expanded` — delegated into children; bellman reclaims the
  parent when children settle or a child fails.
- Retryable: `failure`, `blocked`, `needs_work` — can be repaired.

Edges: `requires` (B waits for A), `parent` (B is child of A), `blocks`
(reverse of requires).

Readiness: an open issue is ready when all requires/blocks deps closed
successfully, all children settled, and no execution conflict exists.

## Routing

Route children to different agents and models:

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

## Execution (leaf work)

This section is for agents dispatched by bellman to execute a single issue.
If you are the orchestrator, skip this — `bellman run` handles dispatch.

Think of your issue as a function call: the body is your arguments, the
close outcome and comments are your return value. A function that ignores
its arguments produces garbage. A function that returns void wastes the
caller's turn.

**Step 1 — read everything before you touch anything.**

    bellman context <issue-id> --json

This returns five things — read all of them:

- **body**: task spec and acceptance criteria.
- **nogoods**: approaches that already failed. Do not repeat them.
- **comments**: durable messages from prior agents (handoffs, decisions).
- **parent**: the broader goal. Disambiguates when the body is unclear.
- **siblings**: parallel work alongside you. Avoid duplication.

**Step 1b — check your surroundings.** Optional but valuable when the
body is ambiguous or you are one of several parallel workers:

    bellman status                         # where does your issue sit in the DAG?
    bellman next --json --brief            # who else is running alongside you?

Siblings tell you what not to duplicate. Parent context tells you the
broader goal. If your issue touches files another in-progress sibling
also touches, coordinate via comments or close `blocked`.

**Step 2 — do the work.**

Check acceptance criteria before considering yourself done.

**Step 3 — record what you did.**

Comments are how knowledge survives your turn. Be specific:

    bellman comment add <issue-id> "verified: tests pass, API matches spec" --kind goods --author-kind agent
    bellman comment add <issue-id> "chose X over Y because Z" --kind decision --author-kind agent

Comment kinds: `goods` (what worked — survives retries), `handoff`
(context for next agent), `decision` (why A over B), `evidence`
(data/output), `progress`, `blocker`, `review` (acceptance check),
`note` (general).

**Step 4 — close. This is mandatory.**

    bellman mutate close <issue-id> success          # criteria met
    bellman mutate close <issue-id> failure --nogood "approach|reason"
    bellman mutate close <issue-id> blocked --detail "what you need"

If you do not close, the turn has no effect and the work will be retried
from scratch.

When the work fails, the nogood is the most valuable thing you produce —
it prevents future agents from wasting a turn on the same dead end.

Run `bellman skill worker` for the complete guide.

## Advanced

- `bellman re-expand <id>` — discard children, try new decomposition
- `bellman at-risk <id>` — check blast radius before repair
- `--tag` on create for partitioned views and scoped stepping
- `bellman control interrupt/resume` — durable pause/resume
- `bellman inspect metrics` for performance analysis
- `bellman search "query"` for full-text search across all runs
