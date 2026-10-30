# Ticket ownership observation, not a functional repair

## Identity and boundary

The retained candidate is source lock
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
Two diagnostic overlays were incrementally compiled in its existing workspace:

| Overlay | SHA-256 | Status |
| --- | --- | --- |
| `processor-ticket-observer-all-locks.patch` | `bcd4b8c7b6b899aecd1972cb045357c77a85bc0430a6ed5f94ae1454ba18b9f4` | Historical, broad acquisition recording |
| `processor-ticket-observer.patch` | `852f43813b0f400d4b6321cbe499bbf026616bf9d34b8a28768eb28ee4875868` | Current research overlay, only same-VM processor locks recorded |

These change observation, not the ticket reservation, acquire load, unlock,
queue splice, notification, or collective protocol. They are NOT a repair.
The current workspace includes the second overlay; it must not be presented
as an unmodified instance of source lock `651f18d...`. Each run binds the
actual source and executable bytes. No bootstrap was repeated, no third full
source tree was retained, and no external debugger or interposition was used.

The observer uses exclusive slot claims, unique commit tags, atomic metadata,
processor-construction epochs, and explicit barrier entry/exit lifetime.
Recorded barrier values are **entry proposals**, not an elected operation or
proof that GC is executing. A missing record is not proof that a lock is free.
The eligibility filter assumes the original stress program's fixed membership
and same-VM access; it does not qualify cross-VM access, resize, or teardown.

## Executed observations

The existing framework selected 12 available CPUs, 3 concurrent suite drivers,
and 3 child processors per driver: `capacity(cpu, four_files, True)`.
Original upstream sources, runner, GNU GCC profile, and flags were unchanged.
Each group used `SuiteCompletionProgress` with a 300-second completed-file
inactivity watchdog. Output volume, diagnostic lines, and samples did not
renew it. All completed groups exited zero and were process-group quiescent.

| Original files | Broad observer | Processor-only observer |
| --- | --- | --- |
| TFIB then terminate | PASS 2/2, 100.330 s | PASS 2/2, 60.810 s |
| interrupt | PASS 1/1, 137.264 s | PASS 1/1, 106.308 s |
| interrupt2 | PASS 1/1, 289.471 s | PASS 1/1, 120.798 s |
| Whole campaign | 289.502 s | 120.843 s |

Both diagnostic campaigns completed all four files with stable bound source
and artifact inputs. Neither emitted `TICKET-HOLDER-DISCRIMINATOR`. The
original fixed ticket wait was therefore not identified in these runs.
These timings describe observation overhead and scheduling, not a product
speedup, native repair qualification, or closure of the retained failure.

An earlier single-file observer run used 11 child processors plus one driver
under `capacity(cpu, one_file, True)`. It timed out at 300.012 seconds, exited
by watchdog, and was reaped with its group quiescent. Two bounded public OS
samples contained changing scheduler/GC execution rather than the previous
stable raise-ticket PC. The original program increases independent flood
threads with processor count, so this is not a matched workload or proof of
deadlock. Its failure is retained rather than replaced by the later passes.

## Source counterevidence and repair obligations

`lib/os_io.c:___os_condvar_select` releases the `devices`/processor ticket
before `___device_select`, then reacquires it before updating condvar fields.
The Scheme `##thread-check-devices!` caller's lock precondition alone does
NOT prove that I/O blocks while retaining that ticket. The C reacquire is a
separate raw-wait path; it is not evidence of an actual holder or operation.
This corrects the incomplete cross-layer attribution in the earlier audit;
the earlier document and its identity remain historical evidence.

Grok proposed a rooted Scheme failed-trylock wait followed by the short queue
operation. The proposal remains unimplemented and requires these conditions:

- Preserve the exported C enqueue/dequeue functions' ownership contracts.
  Removing their acquire while retaining their public names would be an ABI
  semantic change, even if only Scheme callers were updated.
- Publish queue links, release the target ticket, and notify the target
  processor. Caller `___ps` is not interchangeable with that target.
- Keep movable payloads in traced Scheme locations across synchronization;
  reload them after a possible GC. The processor object itself is `___PERM`.
- Establish target membership and lifecycle validity across a collective,
  and exclude double acquisition, abandoned reservations, reentrant callbacks,
  and a second unlock. The finite two-role model does not prove these.

No functional source repair or release patch is admitted by this observation.
The actual owner, its acquisition instruction, and the pending/elected
operation still require a captured witness on the original wait shape.

## Model and receipt binding

`ticket_observer_snapshot.qnt` passed the positive finite-state invariant and
completion check (38,536 distinct states, zero queued) and four reachable
negative controls: concurrent slot writers, reused tags, omitted generation
checks, and stale barrier lifetime. The processor-only context campaign took
16.316 seconds. This is not C/ARM memory-model refinement or a native-owner
identification. `processor_interrupt_ticket.qnt` separately retains its
conditional raw-wait cycle, payload-rooting, reservation, and publication
controls; its holder-in-collective premise has not become a native fact.

Local reproducible commands use the existing interfaces:

```sh
.venv/bin/gambit-smp verify \
  --manifest evidence/research/abandonment-gc-publication/observer.manifest.json \
  --case ticket_observer_snapshot --out .cache/ticket-observer-verification
```

Materialize the retained source lock with the existing registered source
Recipe before applying the chosen diagnostic overlay. Reuse the existing
build profile and GNU toolchain environment. Incremental C targets use
`CoreBuildProgress`, 130-second completed-target inactivity, and host-selected
make jobs; `_thread.o` requires explicitly remaking `_thread.c` when its
header macros change. Do not silently reuse it solely because Make omitted
the header dependency. Test transport is `runtime_view`, `transfer_tree`, and
`process_observation.capture` with `SuiteCompletionProgress`; no Python
relationship inference or new maintained experiment runner was added.

| Ignored local receipt | SHA-256 |
| --- | --- |
| `.cache/ticket-observer-original-stress/receipt.json` | `36c67055a7918a149ac0cc933517da69bcacc65903c2649798a284a95592eec9` |
| `.cache/ticket-observer-original-campaign/receipt.json` | `911e01cd378a6a6cde1efef744286f688b2e568128ddc35dee7d6a2b0ee549e1` |
| `.cache/ticket-observer-processor-only-campaign/receipt.json` | `a11f6bcc85860a3bfa74897b2ade9c3ba0447b17f1f5f7b575ee702c72bf6903` |
| `.cache/ticket-observer-processor-only-loopback/receipt.json` | `00f964ed4eb6450490a3c38979c61338e0352b8003f23ca0cc8d81f1fc2c8e56` |

The first incremental link failure is retained at
`.cache/ticket-observer-incremental-build/receipt.json`
(`194cac5779ae9e3f1526a102f9c7a284802ade81d8288a3b63bde5087300faed`).
An ambient Nix linker was selected through the unsanitized host PATH, leaving
system symbols unresolved. Reusing the framework's existing `gnu_compiler`
environment, rather than changing flags or sources, completed both links.

## Milestones

Cumulative history remains **6/12**, with original source identities intact.
These observed passes do not replace the failed uninstrumented qualification.

| Remaining obligation | Actual status |
| --- | --- |
| Interpreted stress | Prior interrupt files passed; TFIB timeout; terminate not executed; no new acceptance |
| Registry lifetime | No complete current-source acceptance |
| Lifecycle failure/rollback | No complete current-source acceptance; no prohibited failure interposition used |
| GC/FFI | No complete current-source acceptance |
| Gerbil correctness | No complete current-source build/test acceptance |
| Release performance | Correctness prerequisite remains open; observer timings are not admission |

For the current source, uninstrumented compiled interrupt2, owner/operation
attribution, and a compatible functional repair remain explicit open work.
