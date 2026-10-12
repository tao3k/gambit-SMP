# Source-Bound GC Notification Schedules

The prior QNT model distinguishes a lost work-wake opportunity from collection
deadlock. This adapter binds that distinction to unchanged `end_heap_chunk` and
the actual idle-count/wait fragment in candidate027 `mem.c`, with its generated
header and configured GNU GCC. It does not build or execute a Gambit VM.

## Actual Component Execution

`gc-wait-schedule` first validates the accepted model receipt and exact source
and header hashes. Extraction rejects ambiguous function/macro boundaries.
The source makefile must select the same GNU compiler and have no unaudited
language override. Real pthread create/join, mutexes and condition operations
execute; test gates force notification before actual wait registration at two
points: after final empty probing and after count decrement with mutex held.

The source publisher and count/wait statements are not rewritten. Wrappers
observe condition calls and insert test gates; they still invoke real pthread
operations. Queue consumption is metadata-only, not object tracing. Activity
logging is disabled in the fixture. Two roles are the finite model witness,
not a machine-wide worker setting. An optional spurious wake does not get silently
turned into a work notification: the observed ordering is recorded separately
from successful eventual termination.

Campaign002 compiled in 1.378 seconds with GNU GCC 16.2.0, using its verified
default C23. The two schedules completed in 0.527 and 0.026 seconds, both with
work signal before wait, final count zero, empty queue, joined helper and zero
wait errors. Inputs remained stable. These times are component-test durations,
not Gerbil performance results. Runtime/release admission remain false.

Campaign001 compiled no program and ran no schedules: the new adapter had
incorrectly forced GNU11 while the configured header selects C23 `thread_local`.
The source was not missing TLS configuration. The denied receipt is retained;
no runtime source or configure flags were changed to mask the error.

The portable diagnostic is `evidence/model-results/gc-wait-source-schedules.json`.
Its source/binary/input hashes preserve historical identity; later changes must
not rewrite it or treat it as current whole-runtime acceptance.

## Lock-Order Audit And Remaining Gates

Publication (`mem.c:3428-3456`) releases the queue lock before work notification.
Own-queue and stolen-queue consumers (`4496-4526`, `6926-6948`) also unlock before
calling scanning. The idle count/wait path takes only the termination mutex.
This supports reviewing a termination-mutex-to-queue-lock predicate check, but
does not yet prove a proposed repair's entire dynamic lock graph. Preserve the
release-before-signal ordering; adding the termination mutex while still holding
the queue lock would introduce the inverse edge.

The combined proposal remains unimplemented. Multiple queues/publishers, exact
predicate coverage, condition errors, initialization and retirement need further
composition. This diagnostic does not explain historical duplicate body scans,
compiler crashes or bootstrap budget denials, and admits no unchanged retry.
Complete native GC/lifecycle, bootstrap and Gerbil correctness/performance gates
remain pending.

The source-extraction/context guards, wait-model manifest and CLI test modules
passed 13 framework tests in 2.281 seconds. The first framework attempt had one
test-fixture failure from macOS temporary-directory path aliasing; resolving the
test root corrected it without changing the component program or its receipt.
