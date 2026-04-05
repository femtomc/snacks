---
description: "Every piece of prose: commits, comments, doc strings, TODO notes"
---

# Writing

## The reader model

The reader is intelligent, motivated, and has general technical background — but
has zero prior context on the specific thing you are explaining. They have not
read the other files. They have not been in the conversation. They are arriving
cold.

Every concept must be introduced before it is used. If you write "the membrane
translates Oids to Caps," you have used three terms. Each must already be
defined, or be defined in the same sentence.

No forward references without explicit markers. "We define X in Section 3" is
acceptable. Using X without comment before Section 3 is not.

No implicit context. "As discussed above" means nothing if the reader skimmed.
Restate the relevant fact.

## Linearity

Technical prose must be linear: each sentence depends only on what came before
it. The reader builds a mental model one sentence at a time. If sentence N
requires understanding from sentence N+5, you have failed.

The structure is always: what the reader already knows, what new thing we are
introducing, how it connects, what follows from it.

Non-linear exposition forces the reader to hold unresolved references in working
memory. That is the primary cause of "I read it but didn't understand it."

## Self-containment

A section, docstring, or document should make sense on its own. The reader
should not need to have read three other files to understand this one.

If you depend on a definition from elsewhere, restate it briefly: "a dataspace
(a shared assertion store with bag semantics) ..." If a comment references a
function, name it and say what it does: "see `retract_facet()`, which closes the
facet and retracts all its assertions." Not just "see `retract_facet()`."

## Precision

Use the right word, not the approximate word. "Connects" is almost always wrong.
What is the actual relation? Refines? Projects? Simulates? Implements? Extends?
"Handles" is vague. Dispatches? Routes? Validates? Transforms? "Manages" means
nothing. Allocates? Tracks? Schedules? Owns?

If you cannot name the specific relation or action, you do not understand what
you are describing. Stop and figure it out before writing.

## Earning each sentence

Every sentence must advance the reader's understanding. Test each one: does it
tell the reader something they did not know after the previous sentence? If
removed, would the reader lose anything?

Cut: "It is important to note that X" — just state X. "As we can see" — state
the conclusion. "This is a powerful feature that enables" — say what it enables.
"In this section we will discuss X" — discuss X. "Let's take a closer look" —
look at it. These pad word count without advancing understanding.

Advancing understanding includes orienting the reader. A sentence that tells the
reader what question the next paragraph answers earns its place even if it
doesn't state a new technical fact. The cut test catches filler, not framing.

## Framing

Before presenting technical content, ground the reader in the question it
answers. Not with hollow phrases ("It's worth noting") — with the actual problem
or tension that makes the content matter.

Bad: "The skeleton optimizer compiles observer patterns into shape and constant
prefilters for fast dispatch."

Good: "Observer dispatch in a live dataspace can be expensive: every assertion
change must check every observer's pattern. The skeleton optimizer compiles
patterns into prefilters that reject non-matches cheaply, but does it ever
reject a genuine match?"

The bad version states a fact. The good version tells the reader what problem
exists, what the approach does about it, and what question remains open. After
reading it, they know why the next paragraph proves soundness.

Framing is not preamble. One to three sentences that answer "why am I reading
this?" A section that opens with a bare technical claim assumes motivation the
reader doesn't have. A section that opens with three paragraphs of context
buries the point. Both fail.

The test: after your opening sentence, does the reader know what question this
section answers? If not, you've started with the answer before stating the
question.

The danger in a defensive writing style — one trained primarily on what to cut —
is prose that's precise and concise but reads like a reference card. Every
sentence earned, no sentence wasted, but the reader doesn't know why they're
being told any of it. Framing is what prevents that. It's the difference between
a person reading facts off a list and a person explaining something at a
whiteboard.

### The acid test

Read your text aloud. If it sounds like a LinkedIn post, a corporate memo, or a
chatbot, rewrite it. Good technical writing sounds like a thoughtful person
explaining something at a whiteboard — direct, specific, no filler.

## Definitions

When introducing a term, give it a one-sentence operational definition at the
point of first use. An operational definition says what the thing does or how it
behaves, not what it "is" in the abstract.

Bad: "A facet is an ownership concept in the actor model." Good: "A facet is a
scope within an actor; when a facet closes, all assertions it owns are retracted
and all its child facets are closed."

The good version tells you what happens when you interact with it. The bad
version could describe a hundred things.

## Structure by context

Code comments: say why, not what. The code says what. If the code doesn't make
the "what" clear, fix the code.

Docstrings: lead with what the function does in one sentence. Then parameters.
Then edge cases. Do not explain the implementation strategy unless it affects
the caller.

Commit messages: say what changed and why. The diff shows what changed. "Fix
off-by-one in retract" is useless. "Fix double-retract when facet closes during
turn commit — the handle was removed from the bag before the observer callback
fired" is useful.

Technical documents: follow the linearity rule strictly. Open with the one thing
the reader needs to know. Build from there. End when there is nothing left to
say.

Papers: every claim needs a proof, a citation, or an explicit "we conjecture."
Ungrounded claims erode trust in the grounded ones.

## References

- Kernighan & Pike, _The Practice of Programming_ — clarity, simplicity,
  linearity in technical prose
- Kernighan & Plauger, _The Elements of Programming Style_ — "say what you mean,
  simply and directly"
- Strunk & White, _The Elements of Style_ — "omit needless words"
- Leslie Lamport, _How to Write a 21st Century Proof_ — structured proof
  exposition, linearity as a formal property
- Simon Peyton Jones, _How to Write a Great Research Paper_ — the
  one-sentence-contribution discipline
