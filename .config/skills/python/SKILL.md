---
description: "Modifying or creating .py files"
---

# Python

Design principles distilled from Hettinger, Ramalho, Rhodes, and the standard
library.

## Protocols over inheritance

Objects are defined by what they do, not what they are. Python does not check
that an iterable inherits from `Iterable` — it asks "does it have
`__iter__`?", and if not, "does it have `__getitem__`?" Capability matters,
lineage does not.

Protocols compose orthogonally: `Collection` = `Sized` + `Iterable` +
`Container`. `Sequence` adds `Reversible`. Implement 2 abstract methods,
receive 5 mixin behaviors. Define a minimal core, derive the rest.

ABCs enforce contracts and share implementation. `typing.Protocol` enables
structural conformance — the type checker verifies methods without requiring
inheritance. Protocols are static duck typing.

## The data model

Every interaction invokes at least one dunder. The data model is a coherent
system: a small surface area gives deep language integration.

The hash/equality contract: if `x == y` then `hash(x) == hash(y)`. Python 3
enforces this by setting `__hash__ = None` when you define `__eq__` without
`__hash__`. Mutable objects should not be hashable — if a key's hash changes
after insertion, the table cannot find it.

Descriptors unify properties, methods, classmethods, staticmethods, and
`__slots__`. Data descriptors (`__set__` or `__delete__`) take precedence
over instance dicts because they represent managed attributes that must
guard all access. Non-data descriptors yield to instance dicts because they
represent defaults instances can override. This single rule explains why
properties intercept writes but methods can be shadowed.

## Composition over inheritance

Inheritance models "is-a"; composition models "has-a." Test: if both "B is an
A" and "A is a B" feel equally plausible, inheritance is wrong.

Mixins provide cross-cutting capabilities without "is-a" claims — narrow,
single cohesive capability, work through multiple inheritance with no
hierarchy obligations.

Metaclasses are almost always overkill. Progression: class decorator →
descriptor → `__init_subclass__` → metaclass. Use the simplest mechanism that
works.

Most Gang of Four patterns work around static-language limitations. Python's
first-class functions, dynamic dispatch, and duck typing make many
unnecessary. The survivors (Iterator, Decorator, Strategy) align with
Python's native capabilities.

## Generators and laziness

Laziness is a design choice, not an optimization. Generators produce values
on demand with O(1) memory. The deeper principle is composability — lazy
producers and consumers form pipelines without materializing intermediates.

`yield` transforms a function into a resumable coroutine. Calling it returns
a generator without executing the body. Each `next()` runs to the next
`yield`, then suspends. The caller controls execution pacing — foundation of
cooperative concurrency.

The pipeline pattern replaces intermediate data structures. Each element
flows through the entire pipeline before the next enters. Transformations
become a sequence of named stages.

## Context managers

`with` is scope-as-resource. Cleanup is guaranteed regardless of how the
block exits. Replaces `try/finally` with declarative intent. Acquisition and
release should be paired and automatic, never manually balanced.

`contextlib.contextmanager` bridges generators and resource management. Code
before `yield` is `__enter__`; code after is `__exit__`. Eliminates the
boilerplate of writing a class with two methods.

## EAFP

"Easier to Ask Forgiveness than Permission" is structural. Checking
preconditions before acting (Look Before You Leap) couples the caller to the
callee's implementation. Trying the operation and handling failure decouples
them. The exception path only runs when things go wrong, so the common case
is also faster.

## Flat is better than nested

Guard clauses replace nested conditionals. Handle exceptional cases first;
let the happy path flow at the base indentation. Each level adds an implicit
item the reader holds in working memory.

Extract functions when flattening is insufficient. The function name
communicates intent; the call site stays flat. More than 2-3 levels of
indentation → something can be extracted.

Module structure is also flat. Prefer clear names in a flat package over
deeply nested subpackages.

## Testing

Mocks are a code smell. Extensive patching means the class is too tightly
coupled. Pass collaborators as arguments rather than constructing them
internally; tests supply test doubles directly.

Property-based testing finds bugs example tests miss. Instead of "what output
for this input?", ask "what invariants must hold for any valid input?" This
forces precise specification, which itself reveals bugs.

Fixtures compose in pytest. Parameter names determine which fixtures a test
receives. Fixtures depend on other fixtures, forming a DAG. Test
infrastructure should be as well-structured as production code.

## Type hints

Gradual typing is a feature. Hints are ignored at runtime. Short scripts
need none; library APIs and team codebases benefit greatly.

`TYPE_CHECKING` breaks import cycles — type-only imports run only during
static analysis. Type hints should never change runtime behavior.

Annotate boundaries, not internals. Hints are most valuable at signatures,
return types, and public APIs. Trust the type checker to propagate through
implementation details.

## References

- Raymond Hettinger,
  [Pythonic Code Principles](https://gist.github.com/0x4D31/f0b633548d8e0cfb66ee3bea6a0deff9)
  and
  [The Mental Game of Python](https://paulvanderlaken.com/2019/11/20/the-mental-game-of-python-by-raymond-hettinger/)
- Brandon Rhodes, [Python Design Patterns](https://python-patterns.guide/)
- Luciano Ramalho, _Fluent Python_ 2nd ed (O'Reilly, 2022)
- [PEP 20 — The Zen of Python](https://peps.python.org/pep-0020/)
- [PEP 544 — Protocols: Structural Subtyping](https://peps.python.org/pep-0544/)
- [Python Data Model Reference](https://docs.python.org/3/reference/datamodel.html)
- [Descriptor HowTo Guide](https://docs.python.org/3/howto/descriptor.html)
- [collections.abc Documentation](https://docs.python.org/3/library/collections.abc.html)
- Harry Percival & Bob Gregory,
  [Architecture Patterns with Python](https://www.cosmicpython.com/book/preface.html)
- Hynek Schlawack,
  [The Hashable Contract](https://hynek.me/articles/hashes-and-equality/)
