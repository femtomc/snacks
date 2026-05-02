---
description: "Searching agent session history, tool-call patterns, and memory across ~/.claude and ~/.codex"
---

# glom — Agent Context Index

`glom` indexes and searches session transcripts, tool calls, memory files, and
settings across `~/.claude` and `~/.codex`. SQLite FTS5 backed.

## Why glom

Agents accumulate thousands of session files. Without `glom`, finding a prior
session means guessing paths and grepping JSONL.

| Task                           | Without glom                     | With glom                             |
| ------------------------------ | -------------------------------- | ------------------------------------- |
| Find a prior session by topic  | Glob + Grep through ~/.claude    | `glom search 'topic'` (ranked)        |
| Which tools do agents use most | Parse JSONL manually             | `glom tools --names` (compact table)  |
| Find sessions that used a tool | Grep for tool name in JSONL      | `glom tools 'Read'` (ranked)          |
| Inspect a specific session     | `Read` a 100 KB+ JSONL           | `glom show <path>` (truncated panel)  |
| Index statistics               | Count files manually             | `glom stats`                          |

## Output

Compact ASCII tables — lowercase headers, dashes, no box-drawing, no ANSI.
Patterns:

- `--json` — structured JSON (all commands).
- `--limit N` — cap rows (`0` = unlimited). On `search`, `tools`.
- `--full` — multi-line detail or untruncated content. On `search`, `tools`,
  `show`.

Default limit: 10 search, 20 tools.

## Setup

```bash
glom index    # walk ~/.claude and ~/.codex, build FTS5 (once)
```

Re-run periodically. Incremental — only new files indexed.

## Search

```bash
glom search 'parser refactor'        # ranked by BM25
glom search 'refactor parser'        # keyword fragments work
glom search --limit 20 'deployment'
glom search --full 'deployment'      # multi-line snippets
```

Output columns: `rank kind name location snippet`.

## Tools

```bash
glom tools --names              # top 20 tools by call count
glom tools --names --full       # all tools
glom tools 'Read'               # search tool-call records
glom tools 'Bash' --full        # expanded view
```

`tools --names` reveals which tools agents rely on most across sessions.

## Show

```bash
glom show <path>                # truncated to 4000 chars
glom show <path> --full
glom show <path> --json
glom show <path> --json --full
```

Accepts full paths or path suffixes ending in `.jsonl`. Bare UUIDs without
extension do not match.

## Stats

```bash
glom stats    # document counts by kind and source, total content size
```

## Principles

- **Search before browsing.** `glom search X` is faster than navigating
  `~/.claude/projects/`.
- **Use tool patterns for insight.** `glom tools --names` reveals which
  tools dominate workflows.
- **Re-index after long sessions.** New sessions are only searchable after
  `glom index`.
