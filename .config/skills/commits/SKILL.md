---
description: "Every git commit"
---

# Commits

Commit messages that make changes locatable in `git log` and `git blame`.
Format from Linux kernel, Go, Git, and Jujutsu conventions.

## The reader

A developer six months from now, running `git log --grep` or `git blame`.
They don't have your TODO list. The commit message is all they have.

A commit answers *where* a change happened and *why*. The diff answers *what*.

## Format

```
area: imperative description

Explain what was wrong and why this change is correct. Wrap at 72
columns. Plain text, no Markdown.

Trailer-Key: value
```

Example:

```
formal: prove observer monotonicity for bag transitions

The existing proof covered single-assertion transitions but not
batched retractions during facet close. The induction now handles
multi-retract steps by showing bag difference preserves the subset
ordering.

Fixes: a1b2c3d ("formal: prove single-step monotonicity")
```

The subject is `area: imperative description`.

The **area prefix** is a lowercase noun naming the part of the codebase that
changed. Not a type classification — the verb already says fix or feature.
The prefix is the first thing readers search for. Two areas: comma-separate.
Cross-cutting: omit.

The **description** completes "if applied, this commit will ___." Write
"add," "fix," "remove," "prove" — not "added," "fixes," "removing." Subject
under 65 characters. No trailing period. Lowercase after the colon.

The **body** is mandatory for any commit that changes behavior. Explain what
was broken, what was missing, or what design constraint drove the change. If
the fix is non-obvious, explain why it's correct. A subject-only commit for
a behavioral change leaves `git blame` readers no answer to "why."

**Trailers** are key-value metadata after the body, separated by a blank line:

```
Fixes: abc123def ("original commit subject")
Closes: #42
```

`Fixes:` uses the abbreviated hash and quoted subject of the bug-introducing
commit.

## One change

A commit does one logical thing. Test: describe it in one sentence without
"and."

Tests and documentation go in the same commit as the code they cover.

Never mix formatting with behavioral changes. The formatting commit comes
first.

## What goes wrong

`Clean up.` says nothing. Which files, what was wrong, why now. Every commit
in `git log --oneline` should be grep-able by area and scannable by a reader
who wasn't there.

Task-tracker references are not descriptions. `(P5.23)` and `JIRA-1234`
point to systems that get archived. The commit is the permanent record. Put
issue references in a `Closes:` trailer.

Type prefixes (`feat:`, `fix:`, `chore:`) displace the area prefix without
adding information. `fix(parser): handle precedence` is
`parser: fix precedence handling` with a redundant label.

## Search

```bash
git log --grep="^formal:" --oneline
git log --grep="^server:" --oneline

git log -S "function_name"             # symbol added/removed
git log -L :function_name:path/file    # function history
```

For bulk-formatting commits that pollute `git blame`:

```bash
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

## References

- Linux kernel, _Submitting Patches_ — subsystem prefixes, trailer tags,
  body discipline
- Go project, _Commit Messages_ — package-path prefix, imperative test
- Git project, _SubmittingPatches_ — area prefix, three-part body
- Jujutsu VCS, _Contributing Guidelines_ — topic prefix over Conventional
  Commits, one change per commit
- Chris Beams, _How to Write a Git Commit Message_ — the seven rules
- ICSE 2025, Zeng et al., _A First Look at Conventional Commits
  Classification_ — 52 categorization challenges with type prefixes
