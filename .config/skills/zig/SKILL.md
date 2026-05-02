---
description: "Modifying or creating .zig files"
---

# Zig

Patterns extracted from the Zig 0.15.2 standard library — what the stdlib
authors actually do.

## Ownership: managed/unmanaged split

Every collection exists in two forms. Unmanaged stores only data; every
mutating operation takes an `Allocator` parameter. Managed wraps unmanaged
plus a stored allocator and delegates.

Why: struct size in aggregate. An extra 16-byte allocator field × thousands
of embedded collections adds up. Unmanaged keeps per-instance cost minimal.

The default in 0.15 is unmanaged. Managed is deprecated for ArrayList. Thread
the allocator through.

## The allocator interface

`Allocator` is a fat pointer: data pointer + vtable pointer. The only runtime
polymorphism in the stdlib. Allocators must be swappable at runtime (testing,
debug, arena, production) and passable as values without a comptime
parameter.

The vtable is always to a comptime-known `const` in `.rodata`. Each
allocator's `.allocator()` captures `self` as `*anyopaque`. **If the struct
moves after `.allocator()` is called, the fat pointer dangles.** Never store
the `Allocator` value inside the struct that produced it.

Four tiered vtable operations: `resize` (in-place, returns bool), `remap`
(can relocate within the allocator's domain), high-level `realloc` (never
fails — falls back to alloc+copy+free). Try cheaper tiers first.

## Two-tier allocation in activation loops

Long-lived systems use two allocators per operation: a per-operation arena
(freed when operation completes) and a persistent allocator. Mixing them is
the most common memory bug — long-lived object on the arena → use-after-free.

## Growth strategy

Arrays grow at 1.5x with a cache-line additive:
`new +|= new / 2 + cache_line / @sizeOf(T)`. The 1.5x (not 2x) means freed
blocks can be reused by subsequent allocations. The additive ensures the
first allocation is at least one cache line. Hash maps grow by powers of two
because index computation uses bitmasking.

## Context types: comptime duck typing

Hash map takes a `Context` type with `.hash` and `.eql`, resolved at
comptime. Most contexts are zero-sized — methods are comptime-known
functions, zero bytes and zero runtime overhead. When the context IS
stateful (a pointer to a string table for interned lookups), it stores
data. Init checks `@sizeOf(Context) != 0` at comptime to handle both.

Adapted lookups let you search with a different key type via an asymmetric
`eql` — look up a string in a map keyed by string indices without
materializing a key.

## Zero-cost empty states

Collections default to needing no allocation. Empty is `items = &[_]T{}`,
`capacity = 0`. Declare `my_list: ArrayListUnmanaged(Thing) = .{}` in a
struct initializer with no allocator. The first append does the first
allocation.

## Single-allocation packing

Hash map stores metadata + keys + values in one allocation. Metadata pointer
points into the middle of the buffer; the header is at a negative offset. One
allocation = one cache miss to the allocator, one pointer to track, one free.

## Intrusive vs extrinsic

DoublyLinkedList is purely intrusive: `Node` has only prev/next, zero data.
Users embed Node in their struct and recover the container via
`@fieldParentPtr`. No allocation per node, O(1) removal without search. The
list is a concrete type, not generic.

Heuristic: intrusive when elements have stable addresses and may live in
multiple collections (scheduler queues, timer wheels, LRU caches). Extrinsic
(ArrayList, HashMap) when you want cache-friendly sequential access.

## Struct-of-arrays vs array-of-structs

AoS stores each element contiguously: `[{x,y,z}, {x,y,z}, ...]`. SoA stores
each field contiguously: `{[x,x,...], [y,y,...], [z,z,...]}`. Stdlib
provides both; the SoA variant packs all field arrays into one allocation,
sorted by alignment descending to minimize padding.

Use SoA when accessing fields selectively (positions without colors), when
structs have padding, or when decomposing tagged unions. Use AoS when you
always access all fields together or need per-element pointers.

## I/O: buffering is intrinsic

Reader and Writer carry vtable + inline buffer. Buffer length determines
behavior: zero = unbuffered, non-empty = buffered. No separate
`BufferedWriter`. Composition is via stream pumping (Reader → Writer), not
nested wrapping — enabling zero-copy transfer.

## Comptime eliminates categories, not instances

Per-program choice → comptime. DebugAllocator's Config (thread safety, stack
trace depth, memory limits) is a comptime parameter; disabled features get
DCE'd. The format system unrolls the format string at comptime into
specialized write calls — no runtime parser.

Per-call-site or per-object choice → runtime. The Allocator vtable exists
because Reader/Writer instances cross function boundaries where the concrete
type is unknown.

## Error context: cheap capture, lazy resolution

`@returnAddress()` captures one integer (one register read). Stack traces
record N addresses. Translation to file/line/column is deferred until print.
The debug allocator records traces per allocation but only prints on
leak/double-free. Hot path stays fast; errors are maximally informative.

## The `@fieldParentPtr` pattern

Zig's alternative to inheritance. A base type is embedded as a field in a
container; `@fieldParentPtr("field_name", base_ptr)` recovers the container.
The build system uses this for Step downcasting: every step embeds
`step: Step`, the cast checks an id tag, then `@fieldParentPtr` recovers the
concrete type. No vtable, no heap, no type erasure.

## File-is-struct

Every `.zig` file IS a struct. Top-level fields, pub function methods.
`const Self = @This()` names the type. The file system structure IS the type
hierarchy — one type per file, no nesting.

## Buffers are values

The I/O system, format system, and debug system all work with caller-owned
`[]u8` buffers passed explicitly. No hidden allocation, no implicit
buffering. The caller decides the size. Memory usage is visible and
controllable.

## References

- Zig 0.15.2 stdlib (`lib/std/`): `heap.zig`, `array_list.zig`, `hash_map.zig`,
  `mem.zig`, `Build.zig`, `Io.zig`, `fmt.zig`, `meta.zig`, `testing.zig`,
  `debug.zig`, `Thread.zig`, `multi_array_list.zig`, `DoublyLinkedList.zig`,
  `bit_set.zig`, `enums.zig`, `priority_queue.zig`, `segmented_list.zig`
- [Zig 0.15.0 Language Reference](https://ziglang.org/documentation/0.15.0/)
- [Zig 0.15.0 Standard Library Reference](https://ziglang.org/documentation/0.15.0/std/)
- [Zig 0.15.1 Release Notes](https://ziglang.org/download/0.15.1/release-notes.html)
- Karl Seguin,
  [Be Careful When Assigning ArenaAllocators](https://www.openmymind.net/Be-Careful-When-Assigning-ArenaAllocators/)
- [Migrating to Zig 0.15](https://sngeth.com/zig/systems-programming/breaking-changes/2025/10/24/zig-0-15-migration-roadblocks/)
