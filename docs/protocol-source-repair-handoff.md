# Four Models To Source Repairs

## Review Decision

This review binds candidate026 over Gambit
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`, not a moving upstream head.
`evidence/protocol-source-correspondence.json` records source hashes, locations,
repair obligations and forbidden shortcuts. `protocol_source_audit.py` joins
these facts to the research Datalog query. Source or evidence drift rejects the
observation. No rule promotes a finite model result to runtime admission.

| Model | Source correspondence | Decision |
| --- | --- | --- |
| `gc_epoch_work_bridge` | `___vm_resize_pstate`, `barrier_sync_op`, heap setup, strong-root and GC phase barriers | Existing local guards must be retained; full C refinement remains unproved. |
| `gc_scan_claim_transfer` | `end_heap_chunk`, local scanner and both queue consumers | Existing exclusion/acquire guards are present; the historical duplicate slot's originating transition remains unresolved. |
| `sync_retirement_drain` | synchronization setup, message macros, shrink cleanup and VM teardown | Repair resource ownership/reuse and partial setup rollback; reject naive child destruction. |
| `vm_configuration_contract` | configure switches, `_thread.scm` scheduler, threaded-VM GC conditional | Three independent contracts, all enabled for target acceptance; SMP-off is not a threaded-GC fix. |

## Path Assessment Before Runtime Changes

- Resource lifetime: already identified by the prior double-init source unit;
  this round adds the missing exact-macro receive/send schedule and two init
  failure positions, not another unchanged native run. Expected benefit is
  correctness under resize/reuse/failure, not a claimed bootstrap speedup or
  proof that it caused the historical compiler crash.
- Scan ownership: important to the historical relocated-slot reports, but a
  specific new source repair is not justified yet. The current source already
  excludes the locally scanned allocation chunk and acquires after ticket
  ownership. Repeating those changes would add no demonstrated value.
- GC population/phase: source contains the intended local guards. Do not alter
  actual participant accounting just because the finite model uses two workers.
- Configuration: qualifies which implementation runs; it does not itself fix
  correctness. All three flags must stay enabled for final acceptance.

## New Executable Source Evidence

`sync_retirement_source.py` reuses `source_unit.sync_resource_functions`, the
shared GNU compiler selector and bounded process executor. It additionally
extracts the unchanged `SYNC_GET_MSG` and `SYNC_SEND_MSG` macros. Resource
operations are mocked so the fixture can report invalid destruction without
performing undefined pthread operations. The fixture has one sender and one
receiver with deterministic scheduling hooks, not native parallel threads.

GNU GCC compiled the unit successfully. All eight observations matched:

| Injected policy | After publication, sender still locked | After unlock, before signal |
| --- | --- | --- |
| Current source, no added destructor | Receive returns without locking; resources remain live | Same |
| Naive child cleanup destruction | Busy destruction plus two later invalid operations | Late signal uses destroyed condition variable |
| Defer destruction until sender returns | No invalid operation, both resources destroyed | Same |

Two further scenarios inject mutex-init or condition-init failure into the
unchanged setup helper. The former still initializes the condition variable;
the latter retains the initialized mutex. Neither reports an error or rolls
back. The portable receipt is
`evidence/model-results/sync-retirement-source-schedule-002.json`.
The first receipt is retained separately: a concurrent, unrelated extension of
the shared `source_unit.py` invalidated its current tool identity. The extraction
helper was reviewed unchanged; the short eight-schedule check was refreshed
against the updated tool, without rerunning a denied native route.

The deferred policy is a sufficient contract **for this single-sender fixture**,
not a runtime patch. It does not establish global quiescence or C memory-model
correctness. The QNT model's direct flag-driven seal represents the fast receive
case; do not reinterpret its lock-taking waiter path as the only source path.

## Concrete Working Session Repairs

1. Separate synchronization-object lifetime from slot reset in
   `setup_sync_op_pstate` (`setup.c:4673`). Pair exactly-once initialization with
   an owned destruction point. A bounded VM-lifetime resource pool can avoid
   resize-time destruction, but requires explicit initialized-slot tracking and
   checked rollback; it must not reinitialize an already live mutex or condition.
2. Do not add destroy directly to `___cleanup_pstate` (`setup.c:4689`) or assume
   `___thread_join` of the victim (`setup.c:979`) drains incoming senders. A parent
   can still be in its publish/unlock/signal interval. Moving signal under the
   lock alone does not stop the receiver's lock-free fast path. If destroying on
   retirement, prove admission sealed and all senders, waiters and admitted
   reservations drained. If retaining until VM shutdown, prove all VM and
   external users quiescent before `___cleanup_vmstate`; that function is not
   automatically a safe destruction point.
3. Make synchronization setup failure observable to `___setup_pstate` before
   resize population publication. POSIX init macros return a boolean, Windows
   initialization macros do not. Use a platform-aware checked abstraction,
   unwind only successfully owned resources, and test both init failure sites.
   Account for earlier OS/memory/interrupt setup when unwinding the caller.
   Procedural-interrupt mutex lifetime is an adjacent separate obligation;
   this fixture does not claim to cover its external sender protocol.
4. For the compiler scan residual, preserve current fences and cursor exclusion.
   Before another expensive run, identify the first violated physical-slot
   ownership transition with cycle, phase, allocation generation, chunk owner
   and scan interval. Address equality alone cannot distinguish reuse. Do not
   accept arbitrary to-space references to hide duplicate scanning. Do not call
   the candidate026 `_num.scm` budget denial a proven GC crash.

## Acceptance Order

The machine-readable handoff deliberately leaves five native gates pending:
exact artifact identity with all three flags, GC regressions, multi-VM
resize/shutdown, compiler/bootstrap, and full Gerbil build/tests. These must
refer to the same repaired source and built artifacts. A model-only or mocked
source-unit pass closes none of them.

Use the existing failed-route preflight before comparable native reruns. A
changed source file alone is not proof the tested compiler changed. Retain
binary/build-driver/fixture identity and a causal hypothesis; do not widen
budgets or replay known failures by changing the output directory. Existing
post-decode forced-GC positive receipts remain evidence, not a reason to rerun
the original reported failure unchanged.

GHC parallel-copying GC sections 3.4-3.5 motivate separation of private scan
work, exported work and active-worker termination; HotSpot supplies related
termination reasoning. Neither proves Gambit's resource lifetime protocol or
Darwin-specific behavior. Cached papers and prior protocol receipts are reused.

Commands for this new atomic refinement (not the full acceptance suite):

```sh
uv run --locked gambit-smp sync-schedule \
  --source .data/vector-increment-runtime-026/source/lib/setup.c \
  --gcc "$GNU_GCC" --out .data/sync-retirement-schedule-NEW
uv run --locked gambit-smp audit --check \
  --out .data/research-audit-NEW
```
