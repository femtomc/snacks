---
description: "Modifying or creating .zig files"
---

# Zig

Design patterns extracted from the Zig 0.15.2 standard library. These are the
principles the stdlib authors follow, distilled from reading the actual source.

## Ownership: the managed/unmanaged split

Every collection exists in two forms. The unmanaged form stores only data — no
allocator. Every mutating operation takes an `Allocator` as an explicit
parameter. The managed form wraps unmanaged plus a stored allocator and
delegates every method.

The reason is not convenience vs performance. It is struct size in aggregate. An
extra 16-byte allocator field multiplied by thousands of embedded collections
adds up. The unmanaged form keeps per-instance cost minimal.

The default in 0.15 is unmanaged. Managed is deprecated for ArrayList. Use
unmanaged and thread the allocator through.

## The allocator interface: fat pointer without generics

`Allocator` is a fat pointer — a struct carrying a data pointer and a vtable
pointer. This is the only runtime polymorphism in the stdlib. The reason:
allocators must be swappable at runtime (testing, debug, arena, production) and
passable as values without infecting every type with a comptime parameter.

The vtable pointer is always to a comptime-known `const` in the binary's
read-only section. Each concrete allocator's `.allocator()` captures `self` as
`*anyopaque`. If the struct moves after calling `.allocator()`, the fat pointer
dangles. Never store the `Allocator` value inside the same struct that produced
it.

The four vtable operations are tiered: `resize` (in-place, returns bool),
`remap` (can relocate within the allocator's domain, returns optional pointer),
and the high-level `realloc` (never fails to resize, falls back to
alloc+copy+free). This layering lets callers make optimal decisions — try remap
first, fall back to manual alloc+targeted-copy only when the allocator cannot
help.

## Two-tier allocation in activation loops

Long-lived systems use two allocators per operation: a per-operation arena
(freed when the operation completes) and a persistent allocator (for things that
outlive the operation). Mixing these is the most common memory bug: allocating a
long-lived object with the arena causes use-after-free when the operation ends.

## Growth strategy

Arrays grow at 1.5x with a cache-line additive constant:
`new +|= new / 2 + cache_line / @sizeOf(T)`. The 1.5x (not 2x) means freed
blocks can be reused by subsequent allocations. The additive constant ensures
the first allocation is at least one cache line, avoiding tiny allocation
thrash. Hash maps grow by powers of two because index computation uses
bitmasking.

## Context types: comptime duck-typing for strategy injection

Hash map takes a `Context` type parameter with `.hash` and `.eql` methods,
resolved at comptime. Most contexts are zero-sized types — their methods are
comptime-known functions, so the context adds zero bytes and zero runtime
overhead. When the context IS stateful (carrying a pointer to a string table for
interned lookups), it stores actual data. The design handles both cases without
branching: init checks `@sizeOf(Context) != 0` at comptime.

Adapted lookups let you search with a different key type by providing an adapter
context with asymmetric `eql`. This enables looking up a string in a map keyed
by string indices without materializing a key.

## Zero-cost empty states

Collections default to requiring no allocation. Empty state is
`items = &[_]T{}`, `capacity = 0`. You can declare
`my_list: ArrayListUnmanaged(Thing) = .{}` in a struct initializer with no
allocator. The first append does the first allocation.

## Single-allocation packing

Hash map stores metadata, keys, and values in one allocation. The metadata
pointer points into the middle of the buffer; the header is at a negative
offset. One allocation means one cache miss to reach the allocator, one pointer
to track, one free to clean up.

## Intrusive vs extrinsic data structures

DoublyLinkedList is purely intrusive: Node has only prev/next, zero data. Users
embed Node in their struct and recover the container via `@fieldParentPtr`. No
allocation per node. O(1) removal without search. The list is a concrete type,
not generic.

The heuristic: intrusive when elements have stable addresses and may live in
multiple collections simultaneously (scheduler queues, timer wheels, LRU
caches). Extrinsic (ArrayList, HashMap) when you want cache-friendly sequential
access.

## Struct-of-arrays vs array-of-structs

An array-of-structs stores each element contiguously: `[{x,y,z}, {x,y,z}, ...]`.
A struct-of-arrays stores each field contiguously:
`{[x,x,...], [y,y,...], [z,z,...]}`. The stdlib provides both — the
struct-of-arrays variant packs all field arrays into a single allocation, sorted
by alignment descending to minimize padding.

Use struct-of-arrays when you access fields selectively (iterating positions
without touching colors), when structs have padding (eliminates waste), or when
decomposing tagged unions (iterate tags separately from payloads). Use
array-of-structs when you always access all fields together or need per-element
pointers.

## The I/O model: buffering is intrinsic

Reader and Writer carry vtable + inline buffer. The buffer length determines
behavior: zero-length means unbuffered, non-empty means buffered. There is no
separate "BufferedWriter" wrapper. Composition is via stream pumping (Reader
streams to Writer) rather than nested wrapping, enabling zero-copy transfer.

## Comptime eliminates categories, not instances

When the choice is per-program, make it comptime. DebugAllocator takes a Config
struct as a comptime parameter — thread safety, stack trace depth, memory limits
are all resolved at compile time. Disabled features are dead-code-eliminated.
The format system unrolls the format string at comptime into specialized write
calls. No parser runs at runtime.

When the choice is per-call-site or per-object, make it runtime. The Allocator
vtable exists because Reader/Writer instances cross function boundaries where
the concrete type is unknown.

## Error context: capture cheaply, resolve lazily

`@returnAddress()` captures a single integer (one register read). Stack traces
record N addresses. Translation to file/line/column is deferred until the error
is printed. The debug allocator records stack traces per allocation but only
prints them on leak/double-free. The hot path stays fast; errors are maximally
informative.

## The `@fieldParentPtr` pattern

Zig's alternative to inheritance. A base type is embedded as a field in a
container type. `@fieldParentPtr("field_name", base_ptr)` recovers the
container. The build system uses this for Step downcasting: every concrete step
embeds a `step: Step` field and the cast function checks an id tag then uses
`@fieldParentPtr` to recover the concrete type. No vtable, no heap allocation,
no type erasure.

## File-is-struct

Every `.zig` file IS a struct. Fields are declared at the top level; methods are
pub functions. `const Self = @This()` names the type. The file system structure
IS the type hierarchy. One type per file, no nesting.

## Buffers are values, not abstractions

The I/O system, the format system, and the debug system all work with
caller-owned `[]u8` buffers passed explicitly. No hidden allocation, no implicit
buffering. The caller decides the buffer size and provides it. Memory usage is
visible and controllable.

## References

- Zig 0.15.2 standard library source (`lib/std/`): `heap.zig`, `array_list.zig`,
  `hash_map.zig`, `mem.zig`, `Build.zig`, `Io.zig`, `fmt.zig`, `meta.zig`,
  `testing.zig`, `debug.zig`, `Thread.zig`, `multi_array_list.zig`,
  `DoublyLinkedList.zig`, `bit_set.zig`, `enums.zig`, `priority_queue.zig`,
  `segmented_list.zig`
- [Zig 0.15.0 Language Reference](https://ziglang.org/documentation/0.15.0/)
- [Zig 0.15.0 Standard Library Reference](https://ziglang.org/documentation/0.15.0/std/)
- [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
- [Be Careful When Assigning ArenaAllocators](https://www.openmymind.net/Be-Careful-When-Assigning-ArenaAllocators/)
  — Karl Seguin
- [Migrating to Zig 0.15: The Roadblocks Nobody Warned You About](https://sngeth.com/zig/systems-programming/breaking-changes/2025/10/24/zig-0-15-migration-roadblocks/)
