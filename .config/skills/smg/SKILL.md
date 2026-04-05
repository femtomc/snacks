---
description: "Understanding codebase structure, measuring coupling, enforcing architecture, building LLM context"
---

# smg — Semantic Graph for Architecture

`smg` turns a codebase into a queryable graph of modules, classes, functions,
and their relationships. Use it to understand structure, measure coupling, find
hotspots, enforce constraints, and pack LLM context by dependency proximity.

Output is JSON when piped, rich text in a terminal. No flags needed.

## When to use smg

- **Before refactoring**: understand impact, find hotspots, check constraints.
- **Understanding unfamiliar code**: context cards, dependency traces, blame.
- **During code review**: trace usages, measure coupling, detect smells.
- **Enforcing architecture**: deny unwanted paths, require invariants, CI gates.
- **Building LLM context**: `smg context` packs source by graph proximity.

## Setup

```bash
smg init          # create .smg/ in the project root (once)
smg scan          # extract structure from source via tree-sitter
smg scan --changed   # incremental: only rescan files changed since last commit
smg scan --since HEAD~3  # only files changed in last 3 commits
smg scan src/ --clean    # remove stale scan nodes, then full rescan
smg watch         # auto-rescan on file changes
```

Supports Python, JavaScript/TypeScript, C/C++, Zig. All languages extract
containment, imports, call graph, inheritance, and per-function metrics
(cyclomatic/cognitive complexity, nesting, fan-in/fan-out).

## Orient — high-level understanding

```bash
smg overview                   # graph stats, most connected nodes, module sizes
smg status                     # node/edge counts by type
smg about auth.service         # progressive context card (--depth 0|1|2)
smg between api.routes db.models   # shortest path + direct edges
```

`about` is the single best command for "what is X?". Depth 0 gives identity,
depth 1 adds edges, depth 2 adds the 2-hop neighborhood.

## Investigate — ask specific questions

```bash
smg usages Engine              # every direct reference to Engine, with source location
smg impact Engine --depth 3    # what breaks if Engine changes (reverse transitive)
smg diff                       # structural changes since HEAD (with rename detection)
smg diff HEAD~5                # compare against any git ref
smg blame auth.service         # entity-level git blame (not line-level)
```

Name resolution is fuzzy: `smg about Engine` resolves to `app.core.Engine` if
unambiguous. If ambiguous, it lists candidates.

## Analyze — find architectural problems

```bash
smg analyze                          # full analysis: cycles, metrics, smells, hotspots
smg analyze --module bellman         # scope to one package
smg analyze --summary --top 5        # just hotspots and key findings
```

What `analyze` computes:

- **Graph**: cycles (Tarjan), PageRank, betweenness centrality, k-core, bridges,
  layering violations, dead code
- **Classes**: CK metrics (WMC, CBO, RFC, LCOM4, DIT, NOC), Martin's package
  metrics (instability, abstractness, distance), SDP violations
- **Functions**: cyclomatic/cognitive complexity, nesting, fan-in/fan-out
- **Smells**: God Class, Feature Envy, Shotgun Surgery
- **Hotspots**: composite ranking by complexity + coupling + cohesion +
  centrality + git churn

Use `--churn-days N` to control the git history window (default 90 days).

## Query — graph traversal

```bash
smg query deps auth.service --depth 2       # transitive dependencies
smg query callers auth.service --depth 2    # what calls this (transitively)
smg query path api.routes db.models         # shortest path between two nodes
smg query subgraph auth --depth 2           # N-hop neighborhood
smg query incoming auth.service --rel calls # filter by relationship type
```

Output formats: `--format json|text|mermaid|dot`. Mermaid pastes into markdown;
dot pipes to `dot -Tpng -o graph.png`.

## Context — pack source for LLMs

```bash
smg context auth.service --tokens 8000
```

Walks the dependency graph outward from the target node and packs source code
into a token budget. Degrades gracefully: full source -> signatures -> summaries
as the budget fills. Use this when you need to understand a node and its
surroundings without reading every file manually.

## Enforce — architectural constraints

Declare rules, then check them. Exit code 0 = pass, 1 = violations.

```bash
# Deny coupling paths (fnmatch patterns, optional [rel] filter)
smg rule add layering --deny "infra.* -> app.*"
smg rule add no-direct-db --deny "*.controller -[calls]-> *.repository"

# Require structural invariants
smg rule add acyclic --invariant no-cycles
smg rule add reachable --invariant no-dead-code --entry-points "main,cli.*"
smg rule add layered --invariant no-layering-violations

# Scope to a module prefix
smg rule add acyclic-server --invariant no-cycles --scope server

# Check
smg check              # all rules
smg check layering     # one rule
smg rule list          # show all rules
```

## Mutate — annotate beyond what scanning finds

Scanned nodes have `source: "scan"`. Manual annotations have `source: "manual"`
and survive rescans (even `--clean`).

```bash
smg add endpoint /api/login --meta method=POST
smg link api.routes tests test.integration.auth_tests
smg update Engine --doc "Core execution engine"
smg rm deprecated.OldClass
smg batch < bulk_updates.jsonl    # bulk operations from stdin
```

## Key principles

- **Scan first, query second.** Always `smg scan` (or `--changed`) before
  analyzing if the code has changed.
- **Analyze before refactoring.** `smg analyze --summary` shows you what's
  fragile before you touch it. `smg impact X` shows what will break.
- **Enforce in CI.** `smg check` exits non-zero on violations — add it to your
  CI pipeline alongside tests.
- **Layer manual knowledge.** Scanning gives you structure; `add`/`link` let you
  record domain knowledge (endpoints, deployment boundaries, ownership) that
  source code doesn't express.
