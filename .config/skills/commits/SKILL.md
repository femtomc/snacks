---
description: "Every git commit"
---

# Commits

How to write commit messages that make changes locatable in `git log` and
`git blame`. Format and principles drawn from the Linux kernel, Go, Git, and
Jujutsu VCS conventions.

## The reader

A developer six months from now, running `git log --grep` or `git blame`. They
don't have your TODO list or task tracker. The commit message is all they have.

A commit message answers where a change happened and why. The diff answers what
changed.

## Format

```
area: imperative description

Explain what was wrong and why this change is correct. Wrap at 72
columns. Plain text, no Markdown.

Trailer-Key: value
```

A filled-in example:

```
formal: prove observer monotonicity for bag transitions

The existing proof covered single-assertion transitions but not
batched retractions during facet close. The induction now handles
multi-retract steps by showing bag difference preserves the subset
ordering.

Fixes: a1b2c3d ("formal: prove single-step monotonicity")
```

The subject line has an area prefix, a colon, and a description in imperative
mood.

The area prefix is a lowercase noun naming the part of the codebase that
changed. It is not a type classification. Whether a commit is a fix or a feature
is apparent from the verb. The prefix tells the reader where to look, which is
the first thing they search for. When a commit touches two areas, separate them
with a comma. When a commit is cross-cutting, omit the prefix.

The description completes the sentence "if applied, this commit will \_\_\_."
Write "add," "fix," "remove," "prove" not "added," "fixes," "removing." Keep the
full subject under 65 characters. No trailing period. Lowercase after the colon.

The body is mandatory for any commit that changes behavior. It explains what was
broken, what was missing, or what design constraint drove the change. If the fix
is non-obvious, explain why it's correct. A subject-only commit for a behavioral
change leaves `git blame` readers with no answer to "why."

Trailers are key-value metadata at the end of the body, after a blank line. They
keep structured data out of the subject line.

```
Fixes: abc123def ("original commit subject")
Closes: #42
```

Use `Fixes:` with the abbreviated hash and quoted subject of the commit that
introduced the bug.

## One change

A commit does one logical thing. The test: can you describe it in one sentence
without "and"?

Tests and documentation go in the same commit as the code they cover.

Never mix formatting with behavioral changes. A commit changes what the code
does or how it looks, not both. The formatting commit comes first.

## What goes wrong

`Clean up.` says nothing. Which files, what was wrong with them, why now. Every
commit in `git log --oneline` should be grep-able by area and scannable by a
reader who wasn't there.

Task-tracker references are not descriptions. `(P5.23)` and `JIRA-1234` point to
systems that get archived. The commit is the permanent record. If an issue
reference helps, put it in a `Closes:` trailer.

Type prefixes (`feat:`, `fix:`, `chore:`) displace the area prefix without
adding information the verb doesn't already carry.
`fix(parser): handle precedence` is `parser: fix precedence handling` with a
redundant label.

## Search

Structured area prefixes make `git log --grep` precise:

```
git log --grep="^formal:" --oneline
git log --grep="^server:" --oneline
```

For symbol-level archaeology:

```
git log -S "function_name"
git log -L :function_name:path/file
```

For bulk-formatting commits that pollute `git blame`, maintain a
`.git-blame-ignore-revs` file and configure it:

```
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

## References

- Linux kernel, _Submitting Patches_ — subsystem prefixes, trailer tags, body
  discipline
- Go project, _Commit Messages_ (go.dev/doc/contribute) — package-path prefix,
  imperative completion test
- Git project, _SubmittingPatches_ — area prefix, three-part body (what is wrong
  / why this fix / alternatives), 50-char subject
- Jujutsu VCS, _Contributing Guidelines_ — topic prefix over Conventional
  Commits, one change per commit, tests with code
- Chris Beams, _How to Write a Git Commit Message_ — the seven rules
- ICSE 2025, Zeng et al., _A First Look at Conventional Commits Classification_
  — 52 categorization challenges with type prefixes
