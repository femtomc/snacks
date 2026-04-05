---
description: "Modifying or creating .py files"
---

# Python

Design principles that make excellent Python code, distilled from Hettinger,
Ramalho, Rhodes, and the standard library itself.

## Protocols over inheritance

Objects are defined by what they do, not what they are. When you write a `for`
loop, Python does not check whether the object inherits from `Iterable` — it
asks "does this have `__iter__`?" and if not, "does it have `__getitem__`?"
Capability matters, lineage does not.

Protocols compose orthogonally. `Collection` = `Sized` + `Iterable` +
`Container`. `Sequence` builds on those plus `Reversible`. You implement 2
abstract methods and receive 5 mixin behaviors for free. The principle: define a
minimal core, derive the rest.

ABCs enforce contracts and share implementation. `typing.Protocol` enables
structural conformance — the type checker verifies that an object has the right
methods without requiring any inheritance relationship. Protocols are static
duck typing.

## The data model

Every interaction with a Python object invokes at least one dunder method. The
data model is not a bag of special methods — it is a coherent system where
implementing a small surface area gives deep integration with the language.

The hash/equality contract is inviolable: if `x == y` then `hash(x) == hash(y)`.
Python 3 enforces this by setting `__hash__ = None` when you define `__eq__`
without `__hash__`. Mutable objects should not be hashable — if a key's hash
changes after insertion, the hash table cannot find it.

Descriptors are the unifying mechanism behind properties, methods, classmethods,
staticmethods, and `__slots__`. Data descriptors (defining `__set__` or
`__delete__`) take precedence over instance dicts because they represent managed
attributes that must guard all access. Non-data descriptors yield to instance
dicts because they represent defaults that instances can override. This single
precedence rule explains why properties intercept writes but methods can be
shadowed.

## Composition over inheritance

Inheritance models "is-a"; composition models "has-a." The test: if you can
argue both "B is an A" and "A is a B" with equal plausibility, inheritance is
wrong. Deep hierarchies create the class explosion problem. Composition with
interchangeable policy objects avoids it.

Mixins provide cross-cutting capabilities without "is-a" claims. They should be
narrow, providing a single cohesive capability. They work through multiple
inheritance but carry no hierarchy obligations.

Metaclasses are almost always overkill. The progression is: class decorator >
descriptor > `__init_subclass__` > metaclass. Use the simplest mechanism that
works.

Most classic OOP design patterns (the "Gang of Four" catalog) exist to work
around limitations of static, class-based languages. Python's first-class
functions, dynamic dispatch, and duck typing make many of them unnecessary. The
patterns that survive (Iterator, Decorator, Strategy) do so because they align
with Python's native capabilities.

## Generators and laziness

Laziness is a design choice, not an optimization. Generators produce values on
demand with O(1) memory. But the deeper principle is composability: lazy
producers and consumers form pipelines where each stage transforms data without
materializing intermediate collections.

`yield` transforms a function into a resumable coroutine. Calling it returns a
generator object without executing the body. Each `next()` runs until the next
`yield`, then suspends. This inversion — the caller controls execution pacing —
is the foundation of cooperative concurrency.

The pipeline pattern replaces intermediate data structures. Each element flows
through the entire pipeline before the next enters. This clarifies intent by
expressing transformations as a sequence of named stages.

## Context managers

`with` is scope-as-resource, not scope-as-variable. Context managers guarantee
cleanup regardless of how the block exits. This replaces `try/finally` with
declarative intent. Resource acquisition and release should be paired and
automatic, never manually balanced.

`contextlib.contextmanager` bridges generators and resource management. Code
before `yield` is `__enter__`; code after is `__exit__`. This eliminates the
boilerplate of writing a class with two methods for simple resource patterns.

## Try the operation, handle failure

"Easier to Ask Forgiveness than Permission" (EAFP) is a structural decision.
Checking preconditions with `if` before acting (Look Before You Leap) couples
the caller to implementation details of the callee. Trying the operation and
handling failure decouples them. The exception path only executes when things go
wrong, so the common case is faster too.

## Flat is better than nested

Guard clauses replace nested conditionals. Handle exceptional cases first, then
let the happy path flow at the base indentation level. Each indentation level
adds cognitive load — an implicit item the reader must hold in working memory.

Extract functions when flattening is insufficient. The function name
communicates intent; the call site stays flat. If you need more than 2-3 levels
of indentation, something can be extracted.

Module structure should also be flat. Prefer clear module names in a flat
package over deeply nested subpackages.

## Testing

Mocks are a code smell. If testing requires extensive patching, the class is too
tightly coupled. Pass collaborators as arguments rather than constructing them
internally. When dependencies are injected, tests supply test doubles directly.

Property-based testing finds bugs example tests miss. Instead of "what output do
I expect for this input?", ask "what invariants must hold for any valid input?"
This forces you to articulate your specification precisely, which itself reveals
bugs.

Fixtures compose in pytest. A test function's parameter names determine which
fixtures it receives. Fixtures can depend on other fixtures, forming a DAG. Test
infrastructure should be as well-structured as production code.

## Type hints

Gradual typing is a feature, not a compromise. Type hints are ignored at
runtime. Short scripts need none; library APIs and team codebases benefit
greatly.

`TYPE_CHECKING` exists to break import cycles. Type annotations sometimes
require imports that would create circular imports at runtime.
`if TYPE_CHECKING:` blocks run only during static analysis. Type hints should
never change runtime behavior.

Annotate boundaries, not internals. Type hints provide the most value at
function signatures, return types, and public APIs. Trust the type checker to
propagate types through implementation details.

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
