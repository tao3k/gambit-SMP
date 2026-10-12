# Allocator Ticket Handoff Audit

## Review Before Runtime Changes

1. Supported path: the same ticket handoff obligation already repaired at GC
   queue consumers also applies to readers of VM-shared allocation state.
2. Previously explored: `ticket_queue_handoff` separates reservation from
   ownership acquisition. Reuse that counterexample; do not rerun candidate017
   or build a duplicate model just to relabel its protected pointer.
3. Worth auditing: candidate027's `ALLOC_MEM_LOCK` still lacks a post-wait
   acquire, while `next_msection_without_locking` reads and updates shared
   allocation state. This is a source/code-generation gap, not proof of the
   historical repeated-body scan's cause.
4. Expected benefit: correct shared-state handoff. No speedup estimate; a
   barrier has a cost, and runtime/whole-toolchain acceptance remains required.

## Source Chain

- `mem.c:327-328` maps `alloc_msection` and `nb_msections_assigned` to VM state,
  not private processor fields.
- `mem.c:383` maps ALLOC directly to `___SPINLOCK_LOCK` without the barriers
  now present in the queue consumers at `4498,4519,6927`.
- `next_heap_msection:3533-3535` takes ALLOC around
  `next_msection_without_locking`. The latter reads `alloc_msection->next` and
  advances both the shared cursor and assigned-section count (`3255-3274`).
- `gambit.h.in:6222-6227` reserves a ticket using an atomic builtin, then
  observes ownership through volatile loads, with no post-wait acquire.
  The source's debug-history variant has an extra barrier; do not use that
  variant's behavior to qualify the non-debug path.
- `MISC_MEM_LOCK` shares this macro, but its consumers and reentrancy obligations
  are separate. The custom msection callback bypasses the default cursor body
  and remains an explicit separate contract.

Reservation may occur while the preceding holder still owns the lock. Its
earlier barrier therefore does not by itself acquire later writes from that
holder. Replacing the protected queue-head value in the existing QNT handoff
trace with the shared allocation cursor shows the same abstract stale-read
obligation. It does **not** prove that a native allocation was duplicated.

## Actual GNU GCC Observation

The committed fixture includes candidate027's generated `gambit.h` directly.
It rejects incorrect threading/lock/builtin configurations at preprocessing.
GNU GCC 16.2, `-O2 -S`, emits:

```text
ticket reservation:       ldaddal
wait for current ticket:  ldr / cmp / bne
read protected cursor:    ldr
```

The second wrapper adds the existing `___SHARED_MEMORY_BARRIER()` immediately
after lock acquisition. Its output has `dmb ish` between the wait and protected
load. Full generated assembly, hashes and command arguments are retained in
`evidence/codegen/ticket-acquire/`. This is a local Darwin/AArch64 code-generation
inspection, not an executed concurrency test or production LTO disassembly.

GCC documents that volatile accesses do not order non-volatile accesses, and
that the legacy sync builtins provide barriers at their invocation. Neither
statement supplies a missing ownership-acquire operation after the wait.
See [GCC volatile semantics](https://gcc.gnu.org/onlinedocs/gcc/Volatiles.html)
and [GCC sync builtins](https://gcc.gnu.org/onlinedocs/gcc-9.1.0/gcc/_005f_005fsync-Builtins.html).
This does not establish portable ISO C race freedom for the entire legacy
ticket implementation; a comprehensive atomic migration has a larger scope.

## Repair And Evidence Boundaries

Working should choose between a scoped ALLOC/MISC call-site acquire and a
reviewed shared-ticket primitive repair. The latter changes Scheme primitive
locks too, so it is not interchangeable with the small queue repair. Retain
the proven initialization and lifetime requirements for either choice. This
correctness obligation is not known to be macOS-only merely because this
assembly was inspected on Darwin.

For native admission, bind the selected repair, generated header and new
binary; verify allocation ownership and failed initialization/lifetime behavior
before GC, full bootstrap and Gerbil suites with all three switches. Existing
models supply ordering obligations, not execution permission or causal evidence
that this explains diagnostic014/015. Do not erase the later candidate018
post-copy-headroom passes or repeat already-present queue fences.
