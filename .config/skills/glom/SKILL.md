---
description: "Searching agent session history, tool-call patterns, and memory across ~/.claude and ~/.codex"
---

# glom — Agent Context Index

`glom` indexes and searches the session transcripts, tool calls, memory
files, and settings across `~/.claude` and `~/.codex`. It is backed by
SQLite FTS5 and lets you find prior sessions by keyword, discover
tool-call frequency, and inspect individual documents.

## Why glom

Agents accumulate thousands of session files and tool-call records.
Without `glom`, finding a prior session requires guessing file paths
and grepping through JSONL. With `glom`, a single `glom search X`
returns 10 ranked results in a compact table.

| Task                           | Without glom                     | With glom                             |
| ------------------------------ | -------------------------------- | ------------------------------------- |
| Find a prior session by topic  | Glob + Grep through ~/.claude    | `glom search 'topic'` (ranked hits)   |
| Which tools do agents use most | Parse JSONL manually             | `glom tools --names` (a compact table)|
| Find sessions that used a tool | Grep for tool name in JSONL      | `glom tools 'Read'` (ranked hits)     |
| Inspect a specific session     | `Read` a 100 KB+ JSONL file      | `glom show <path>` (truncated panel)  |
| Index statistics               | Count files manually             | `glom stats` (fixed-size table)       |

## Output format

All commands emit compact ASCII tables — lowercase headers, dash
separators, no box-drawing, no ANSI. Flag availability varies by
command — run `<cmd> --help` to confirm. General patterns:

- `--json` — structured JSON. Available on all commands.
- `--limit N` — cap rows (`--limit 0` unlimited). Available on `search`
  and `tools`.
- `--full` — multi-line detail or untruncated content. Available on
  `search`, `tools`, and `show`.

Default limit is 10 for search, 20 for tool listings.

## Setup

```bash
glom index    # walk ~/.claude and ~/.codex, build the FTS5 index (once)
```

Re-run `glom index` periodically to pick up new sessions. It is
incremental — only new files are indexed.

## Search — find sessions by keyword

```bash
glom search 'bellman context'        # ranked by BM25 relevance
glom search 'refactor parser'        # keyword fragments work
glom search --limit 20 'deployment'  # more results
glom search --full 'bellman'         # multi-line view with snippets
```

Output uses the canonical search columns: `rank kind name location snippet`.
Default limit is 10 results.

## Tools — discover tool-call patterns

```bash
glom tools --names              # top 20 tools by call count
glom tools --names --full       # all tools
glom tools 'Read'               # search tool-call records for 'Read'
glom tools 'Bash' --full        # expanded view of Bash tool calls
```

`tools --names` is useful for understanding which tools agents rely on
most across all indexed sessions.

## Show — inspect one document

```bash
glom show <path>                # truncated to 4000 chars by default
glom show <path> --full         # untruncated
glom show <path> --json         # structured JSON, content truncated
glom show <path> --json --full  # untruncated JSON
```

Accepts full paths or path suffixes ending in `.jsonl`:
`glom show eceef2cc-d2f7-4062-9d3b-d4ca4c3173bc.jsonl` resolves the full
path. Bare UUIDs without the extension do not match.

## Stats — index health

```bash
glom stats    # document counts by kind and source, total content size
```

## Key principles

- **Search before browsing.** `glom search X` finds relevant sessions
  faster than manually navigating `~/.claude/projects/`.
- **Use tool patterns for insight.** `glom tools --names` reveals which
  tools dominate agent workflows. `glom tools 'Bash'` shows what
  agents run most often.
- **Re-index after long sessions.** New sessions are only searchable
  after `glom index`.
