# GC Queue Probe Access Review

## Path Review

The queue/wait models already cover locked publication, recheck and retirement.
They do not establish the C access discipline of the unlocked advisory probe.
The current candidate's `mark_reachable_from_marked` compares remote volatile
head/tail pointers before acquiring the queue lock. Publication and local/remote
pops mutate those pointers under the queue lock; the advisory reader does not
take that lock. The header declares both pointer endpoints volatile, not atomic.

This is a source-level memory-contract gap worth investigating, distinct from
the already-repaired notification, BTQ retry and continuation publication paths.
It is not a unique explanation of the earlier native timeout, which lacks a
terminal stack. No speedup or native failure mechanism is claimed yet.
The expected benefit is explicit access discipline without adding probe locks;
runtime performance must still be measured on a fresh exact-source producer.

GCC documents that volatile accesses do not order unrelated non-volatile data,
and that its memory-model-aware atomic builtins assume a data-race-free program:
[volatile semantics](https://gcc.gnu.org/onlinedocs/gcc/Volatiles.html),
[atomic builtins](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html).
These are compiler contracts, not proof that a particular optimizer transformed
the observed program incorrectly. The issue is not inherently Darwin-only.

## Model Boundary

`models/gambit/gc_queue_probe_access.qnt` characterizes access conflicts while
the writer owns Q, a stale advisory snapshot, and the authoritative locked
recheck. Its controls distinguish a plain unlocked read, changing only the
load while leaving a conflicting plain writer, and retiring from the stale
hint. The proposed protocol makes all potentially conflicting endpoint stores
and advisory loads atomic while keeping lock ownership for dereference/pop.
It does not require the two advisory endpoint loads to be a coherent snapshot.

All four explicit trajectories passed Quint; the initial parse error from
placing a nondeterministic binding inside `all` was corrected before checking.
This is not exhaustive verification, a C11 memory-model proof, source refinement
or native acceptance. The model records an access-discipline abstraction; it
does not simulate undefined behavior as an invented runtime counterexample.

## Required Source Closure

Before a runtime patch, enumerate initialization, publisher tail stores and
local/remote head stores; changing only the advisory load is insufficient.
Keep queue payload/link access under Q, queue recheck under the termination
mutex, and the existing lock-order and phase barriers. Verify that any relaxed
advisory load is never used for payload dereference or termination authority.
Compiler portability and pointer lock-freedom require explicit checks. Then
export a pinned successor, bootstrap it and run the unchanged public topology,
deep saved-stack and complete native inventories. Do not relabel current-source
diagnostics as observations of that unbuilt successor.
