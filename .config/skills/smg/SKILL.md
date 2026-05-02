---
description: "Understanding codebase structure, measuring coupling, enforcing architecture, building LLM context"
---

# smg — Semantic Graph for Architecture

`smg` turns a codebase into a queryable graph of modules, classes, functions,
and relationships, backed by a SQLite+FTS5 fuzzy cache.

## Why smg instead of reading files

Reading source costs hundreds of lines of context. `smg` answers the same
structural questions in a fraction of the tokens:

| Task                        | Without smg                          | With smg                                  |
| --------------------------- | ------------------------------------ | ----------------------------------------- |
| What is this class?         | `Read src/engine.py` (hundreds)      | `smg about <name>` (a card)               |
| Where is X used?            | `Grep` (unbounded)                   | `smg usages <name>` (a capped table)      |
| What breaks if I change X?  | Manual import trace                  | `smg impact <name>` (a capped table)      |
| Find a function by keyword  | `Grep` + guess paths                 | `smg search truncate` (ranked)            |
| Architectural overview      | Read dozens of files                 | `smg analyze` (a one-screen summary)      |
| Pack context for a question | Manually pick and read files         | `smg context X --tokens 8000` (auto)      |

**Use smg first.** Start with `smg about`, `smg search`, or `smg analyze`
before reaching for `Read` or `Grep`. Fewer tokens, better-structured answers.

## Output

Compact ASCII by default — lowercase headers, dash separators, no box-drawing,
no ANSI. Identical in a terminal and in a pipe.

Flag availability varies by command — `<cmd> --help` to confirm. Patterns:

- `--json` — canonical envelope. On `search`, `list`, `status`.
- `--format json` — structured. On `about`, `analyze`, `usages`, `impact`,
  `context`, `diff`, `overview`, `between`, `blame`, `query` subcommands.
- `--limit N` — cap rows (`0` = unlimited). On `search`, `list`, `usages`,
  `impact`, `blame`, `query`.
- `--full` — expand or untruncate. On `search`, `list`, `status`, `about`,
  `analyze`, `query subgraph`.

Default limit: 20 for listings, 10 for search.

## Setup

```bash
smg init               # create .smg/ in project root (once)
smg scan               # extract structure (Python/JS/TS/C/Zig)
smg scan --changed     # incremental: only files changed since last commit
smg watch              # auto-rescan on changes
```

Scanning also builds the fuzzy-search cache at `.smg/search.sqlite3`.

## Search

```bash
smg search truncate                   # partial identifier
smg search "drop path"                # docstring fragment
smg search helpers                    # matches smg.cli.helpers._truncate
smg search --kind function truncate
```

Dotted identifiers are decomposed: `smg.cli.helpers._truncate` indexes as
`smg cli helpers truncate`. CamelCase splits too.

Output columns: `rank kind name location snippet`.

## Orient

```bash
smg overview                         # graph stats, most connected
smg status                           # node/edge counts by type
smg about auth.service               # progressive card (--depth 0|1|2)
smg between api.routes db.models     # shortest path + direct edges
```

`about` is the single best command for "what is X?". Depth 0 = identity,
1 = edges, 2 = 2-hop neighborhood. All fit on one screen.

## Investigate

```bash
smg usages Engine              # every direct reference, with location
smg impact Engine --depth 3    # what breaks if Engine changes
smg diff                       # structural changes since HEAD
smg blame auth.service         # entity-level git blame
```

Name resolution is fuzzy: `smg about Engine` → `app.core.Engine` if unambiguous.

## Analyze

```bash
smg analyze                          # cycles, metrics, smells, hotspots
smg analyze --module auth            # scope to one package
smg analyze --full                   # full detail (16 KB cap)
```

Computes: cycles (Tarjan), PageRank, betweenness, k-core, bridges, layering
violations, dead code, CK class metrics, Martin's package metrics, SDP
violations, complexity, smells, hotspots, git churn.

## Context — pack source for LLMs

```bash
smg context auth.service --tokens 8000
```

Walks the dependency graph outward and packs into a token budget. Degrades
gracefully: full source → signatures → summaries. Most token-efficient way
to build a context window for a question about a node.

## Query — graph traversal

```bash
smg query deps auth.service --depth 2
smg query callers auth.service --depth 2
smg query path api.routes db.models
smg query subgraph auth --depth 2
```

## Enforce

```bash
smg rule add layering --deny "infra.* -> app.*"
smg rule add acyclic --invariant no-cycles
smg check              # exit 0 = pass, 1 = violations
```

## Principles

- **Search before reading.** `smg search X` finds the node; `smg about X`
  gives you the card. Only `Read` if you need the full implementation.
- **Scan first, query second.** Always `smg scan` (or `--changed`) if code
  has changed since the last scan.
- **Analyze before refactoring.** `smg analyze --summary` shows what's
  fragile. `smg impact X` shows what will break.
- **Enforce in CI.** `smg check` exits non-zero on violations.
