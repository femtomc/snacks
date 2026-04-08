---
description: "Understanding codebase structure, measuring coupling, enforcing architecture, building LLM context"
---

# smg — Semantic Graph for Architecture

`smg` turns a codebase into a queryable graph of modules, classes, functions,
and their relationships. It is backed by a SQLite+FTS5 fuzzy cache that lets
you search by partial identifier or docstring fragment.

## Why smg instead of reading files

Reading a source file costs hundreds of lines of context. `smg` gives you the
same structural understanding in a fraction of the tokens:

| Task                        | Without smg                          | With smg                                  |
| --------------------------- | ------------------------------------ | ----------------------------------------- |
| What is this class?         | `Read src/engine.py` (hundreds of lines) | `smg about <name>` (a compact card)           |
| Where is X used?            | `Grep` across repo (unbounded)           | `smg usages <name>` (a capped table)          |
| What breaks if I change X?  | Manual trace through imports             | `smg impact <name>` (a capped table)          |
| Find a function by keyword  | `Grep` + guess file paths                | `smg search truncate` (ranked hits)           |
| Architectural overview      | Read dozens of files                     | `smg analyze` (a one-screen summary)          |
| Pack context for a question | Manually pick and read files             | `smg context X --tokens 8000` (auto-pack)     |

**Use smg first.** When you need to understand a codebase, start with
`smg about`, `smg search`, or `smg analyze` before reaching for `Read`
or `Grep`. You will use fewer tokens and get better-structured answers.

## Output format

All commands emit compact ASCII by default — lowercase headers, dash
separators, no box-drawing, no ANSI escapes. Output is identical in a
terminal and in a pipe.

Flag availability varies by command — run `<cmd> --help` to confirm.
General patterns:

- `--json` — canonical JSON envelope. Available on `search`, `list`,
  `status`.
- `--format json` — structured JSON. Available on `about`, `analyze`,
  `usages`, `impact`, `context`, `diff`, `overview`, `between`, `blame`,
  and `query` subcommands.
- `--limit N` — cap rows (`--limit 0` unlimited). Available on `search`,
  `list`, `usages`, `impact`, `blame`, and `query` subcommands.
- `--full` — expand detail or remove truncation. Available on `search`,
  `list`, `status`, `about`, `analyze`, `query subgraph`.

Default limit is 20 for listings, 10 for search.

## Setup

```bash
smg init          # create .smg/ in the project root (once)
smg scan          # extract structure via tree-sitter (Python/JS/TS/C/Zig)
smg scan --changed   # incremental: only files changed since last commit
smg watch         # auto-rescan on file changes
```

Scanning also builds the fuzzy-search cache at `.smg/search.sqlite3`.

## Search — find things by keyword

```bash
smg search truncate              # partial identifier match
smg search "drop path"           # docstring fragment
smg search helpers               # matches smg.cli.helpers._truncate
smg search --kind function truncate   # filter to functions only
```

Search decomposes dotted identifiers: `smg.cli.helpers._truncate` is indexed
as `smg cli helpers truncate`, so any sub-token matches. CamelCase is also
split: `AnalysisResult` matches `analysis` or `result`.

Output uses the canonical search columns: `rank kind name location snippet`.

## Orient — high-level understanding

```bash
smg overview                         # graph stats, most connected nodes
smg status                           # node/edge counts by type
smg about auth.service               # progressive context card (--depth 0|1|2)
smg between api.routes db.models     # shortest path + direct edges
```

`about` is the single best command for "what is X?". Depth 0 gives identity,
depth 1 adds edges, depth 2 adds the 2-hop neighborhood. All fit on one screen.

## Investigate — ask specific questions

```bash
smg usages Engine              # every direct reference, with source location
smg impact Engine --depth 3    # what breaks if Engine changes (reverse transitive)
smg diff                       # structural changes since HEAD
smg blame auth.service         # entity-level git blame
```

Name resolution is fuzzy: `smg about Engine` resolves to `app.core.Engine` if
unambiguous.

## Analyze — find architectural problems

```bash
smg analyze                          # cycles, metrics, smells, hotspots
smg analyze --module bellman         # scope to one package
smg analyze --full                   # full detail (respects 16 KB cap)
```

Computes: cycles (Tarjan), PageRank, betweenness, k-core, bridges, layering
violations, dead code, CK class metrics, Martin's package metrics, SDP
violations, complexity, smells, hotspots, git churn.

## Context — pack source for LLMs

```bash
smg context auth.service --tokens 8000
```

Walks the dependency graph outward from the target and packs source into a
token budget. Degrades gracefully: full source -> signatures -> summaries.
This is the most token-efficient way to build a context window for a
question about a specific node.

## Query — graph traversal

```bash
smg query deps auth.service --depth 2       # transitive dependencies
smg query callers auth.service --depth 2    # what calls this
smg query path api.routes db.models         # shortest path
smg query subgraph auth --depth 2           # N-hop neighborhood
```

## Enforce — architectural constraints

```bash
smg rule add layering --deny "infra.* -> app.*"
smg rule add acyclic --invariant no-cycles
smg check              # exit 0 = pass, 1 = violations
```

## Key principles

- **Search before reading.** `smg search X` finds the node; `smg about X`
  gives you the context card. Only `Read` the file if you need the full
  implementation body.
- **Scan first, query second.** Always `smg scan` (or `--changed`) if the
  code has changed since the last scan.
- **Analyze before refactoring.** `smg analyze --summary` shows what's
  fragile. `smg impact X` shows what will break.
- **Enforce in CI.** `smg check` exits non-zero on violations.
