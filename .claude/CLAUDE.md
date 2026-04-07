# Global Instructions

## Skills

Read the relevant skills before starting work. Apply them — they are not
reference material, they are how we work.

### Process

Apply regardless of task type.

| Skill                               | When                                                             | Related          |
| ----------------------------------- | ---------------------------------------------------------------- | ---------------- |
| [writing](skills/writing/SKILL.md)        | Every piece of prose: commits, comments, doc strings | commits          |
| [commits](skills/commits/SKILL.md)        | Every git commit                                     | writing          |

### Language

Read before modifying files in this language.

| Skill                             | When                                    | Related                   |
| --------------------------------- | --------------------------------------- | ------------------------- |
| [zig](skills/zig/SKILL.md)              | Modifying or creating .zig files        | testing, flexibility      |
| [lean](skills/lean/SKILL.md)            | Writing or modifying Lean proofs        | testing                   |
| [python](skills/python/SKILL.md)        | Modifying or creating .py files         | testing, flexibility      |
| [latex](skills/latex/SKILL.md)          | Modifying .tex files (non-TikZ content) | writing, references, tikz |
| [tikz](skills/tikz/SKILL.md)           | Writing TikZ diagrams in .tex files     | latex, diagrams           |

### Design

Read when the task involves this concern, regardless of language.

| Skill                                 | When                                                             | Related            |
| ------------------------------------- | ---------------------------------------------------------------- | ------------------ |
| [testing](skills/testing/SKILL.md)          | Writing, reviewing, or planning tests                            | zig, python, lean  |
| [flexibility](skills/flexibility/SKILL.md)  | Designing extension points, combinators, or polymorphic dispatch | zig, python        |
| [diagrams](skills/diagrams/SKILL.md)        | Generating diagrams or thinking about visual communication       | tikz               |

### Tools

Read when using these tools.

| Skill                         | When                                                              | Related  |
| ----------------------------- | ----------------------------------------------------------------- | -------- |
| [bellman](skills/bellman/SKILL.md)  | Coordinating multi-turn agent work across files and modules       |          |
| [smg](skills/smg/SKILL.md)          | Understanding codebase structure, measuring coupling, enforcing architecture, building LLM context | testing  |

## Bellman for Multi-Step Work

**REQUIREMENT**: When a task requires more than one turn of work — multiple
files, multiple deliverables, subtask dependencies, or work that benefits
from structured decomposition — you MUST use `bellman` to organize it. Do
not spawn ad-hoc subagents for multi-step work. Use bellman.

Bellman is an execution engine. You describe a DAG of issues with
dependency edges, then `bellman run` dispatches agents to execute each
issue in dependency order, retrying failures with structured memory of
what was already tried. You decompose. Bellman executes.

**When you MUST use bellman:**

- The task spans multiple files or modules that cannot be completed
  atomically in one turn.
- The task has natural subtask dependencies (A must finish before B).
- You want parallel execution across independent workstreams.
- You need retry/repair semantics — the work might fail and need
  structured recovery.
- You are orchestrating other agents (via ACP) to do the work.

**When bellman is NOT required:**

- Simple single-turn tasks: one file edit, a quick bug fix, a formatting
  change.
- Exploratory questions or research that doesn't produce durable output.

**The orchestrator workflow:**

    bellman init <prompt-file>       # create a run with a root issue
    # decompose root into children with bellman mutate create
    # each child: --body, --require (order), --agent/--model (who executes)
    bellman mutate close root expanded   # yield — you are done decomposing
    bellman run --agent claude-acp --repair  # bellman dispatches agents

After decomposing, hand off to `bellman run`. Do not execute leaf issues
yourself — that abandons the durable state, retry semantics, and parallel
dispatch that bellman exists to provide.

**Profile-based routing:** Before decomposing, run `bellman profile list`
to discover available agent profiles. Each profile bundles an agent, model,
and mode tuned for a class of work — read the annotations to decide which
profile fits each child issue. Assign via `--profile <name>` on
`bellman mutate create`. Issues without a profile use the runner's defaults.

The CLI is self-documenting — every command supports `--help`, and
`bellman skill <topic>` teaches cross-cutting workflows (orchestration,
decomposition, execution, concurrency, routing, repair, observation).

## Tooling

- Use `uv` for all Python tooling (`uv run`, `uv tool install`). Never
  `pip install` directly.
