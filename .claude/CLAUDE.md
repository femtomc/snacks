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
| [references](skills/references/SKILL.md)  | Citing papers, linking prior work, looking up external sources | writing |

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
| [bellman](skills/bellman/SKILL.md)  | Coordinating multi-turn agent work across files and modules       | todos    |
| [smg](skills/smg/SKILL.md)          | Understanding codebase structure, measuring coupling, enforcing architecture, building LLM context | testing  |

## Bellman for Multi-Step Work

**REQUIREMENT**: When a task requires more than one turn of work — multiple
files, multiple deliverables, subtask dependencies, or work that benefits
from structured decomposition — you MUST use `bellman` to organize it. Do
not spawn ad-hoc subagents for multi-step work. Use bellman.

Bellman gives you a durable work graph, an append-only event log, and
structured failure records (nogoods) that persist across agent turns.
Failed approaches are never repeated. Successful approaches (goods) are
available to every subsequent agent. It supports hierarchical
decomposition, parallel execution with conflict detection, causal repair,
and reactive supervision — none of which ad-hoc subagents provide.

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

**How to get started:**

    bellman skill                    # learn the model
    bellman skill orchestration      # learn the orchestrator loop
    bellman init <prompt-file>       # bootstrap a run
    bellman run --repair             # drive to completion

The CLI is self-documenting — every command supports `--help`, and
`bellman skill <topic>` teaches cross-cutting workflows (execution,
decomposition, concurrency, routing, repair, observation, orchestration).

## Tooling

- Use `uv` for all Python tooling (`uv run`, `uv tool install`). Never
  `pip install` directly.
