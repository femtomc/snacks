# Global Instructions

## Skills

Read the relevant skills before starting work. Apply them — they are not
reference material, they are how we work.

Codex will auto-load skills when your prompt matches their description. The
table below lists all available global skills for reference.

### Process

Apply regardless of task type.

| Skill       | When                                                             | Related          |
| ----------- | ---------------------------------------------------------------- | ---------------- |
| writing     | Every piece of prose: commits, comments, doc strings | commits          |
| commits     | Every git commit                                     | writing          |
| references  | Citing papers, linking prior work, looking up external sources | writing |

### Language

Read before modifying files in this language.

| Skill   | When                                    | Related                   |
| ------- | --------------------------------------- | ------------------------- |
| zig     | Modifying or creating .zig files        | testing, flexibility      |
| lean    | Writing or modifying Lean proofs        | testing                   |
| python  | Modifying or creating .py files         | testing, flexibility      |
| latex   | Modifying .tex files (non-TikZ content) | writing, references, tikz |
| tikz    | Writing TikZ diagrams in .tex files     | latex, diagrams           |

### Design

Read when the task involves this concern, regardless of language.

| Skill       | When                                                             | Related            |
| ----------- | ---------------------------------------------------------------- | ------------------ |
| testing     | Writing, reviewing, or planning tests                            | zig, python, lean  |
| flexibility | Designing extension points, combinators, or polymorphic dispatch | zig, python        |
| diagrams    | Generating diagrams or thinking about visual communication       | tikz               |

### Tools

Read when using these tools.

| Skill   | When                                                              | Related  |
| ------- | ----------------------------------------------------------------- | -------- |
| bellman | Coordinating multi-turn agent work across files and modules       | todos    |
| smg     | Understanding codebase structure, measuring coupling, enforcing architecture | testing  |

## Bellman for Long-Horizon Work

When a task is too large for a single turn — multiple files, multiple
deliverables, or work that benefits from structured decomposition — use
`bellman` instead of spawning subagents.

**Why bellman over subagents:**

- Subagents are ephemeral. They lose context when they finish, failures
  vanish, and there is no structured memory across retries.
- Bellman gives you a durable work graph, an append-only event log, and
  structured failure records (nogoods) that persist across agent turns.
  Failed approaches are never repeated. Successful approaches (goods) are
  available to every subsequent agent.
- Bellman supports hierarchical decomposition, parallel execution with
  conflict detection, causal repair, and reactive supervision — none of
  which subagents provide.

**When to use bellman:**

- The task spans multiple files or modules that cannot be completed
  atomically in one turn.
- The task has natural subtask dependencies (A must finish before B).
- You want parallel execution across independent workstreams.
- You need retry/repair semantics — the work might fail and need
  structured recovery.
- You are orchestrating other agents (via ACP) to do the work.

**When NOT to use bellman:**

- Simple single-turn tasks: one file edit, a quick bug fix, a formatting
  change.
- Exploratory questions or research that doesn't produce durable output.

**How to get started:**

    bellman skill                    # learn the model
    bellman skill orchestration      # learn the orchestrator loop
    bellman init <prompt-file>       # bootstrap a run
    bellman run --repair             # drive to completion

Run `bellman skill` for the full operational guide. The CLI is
self-documenting — every command supports `--help`, and `bellman skill
<topic>` teaches cross-cutting workflows (execution, decomposition,
concurrency, routing, repair, observation, orchestration).

## Tooling

- Use `uv` for all Python tooling (`uv run`, `uv tool install`). Never
  `pip install` directly.
