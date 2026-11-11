# Lifecycle join recovery: missing formal 9/12 evidence

2026-10-23 source/design review. The audit recorded qualification 8/12; that is an observed result, not a policy that fixes the count. Statements about no runtime/native/qualifier/recipe edits describe the original author's evidence-only execution scope, not a prohibition on another implementation owner.

Implementation sequences below are conditional design dependencies, not an approved executable work order or permission grant. They must first be resolved against one current, coherent source/generator/header/generated-C/producer identity. Per-file historical line numbers are evidence coordinates, never cross-generation patch offsets. This scope clarification does not alter the original observations, model logs, native receipts or qualification predicate.

See [recursive-ffi-journal.md](recursive-ffi-journal.md) for the corrected status: the cumulative one-winner foreign release patch is recorded as landed, while journals/control-reference lifetime, internal wills, checked bridges and new generated C remain unimplemented proposals in these reports. Plain-release-function observations below describe their saved snapshots and must not be read as instructions to redo the landed claim. The lock is the source authority here; the separate vendor engineering checkout is not required to match it and is not a drift test. Patch/lock agreement is not a configured build or current gsi certificate.

The unchanged lifecycle campaign has an unresolved reachable-trigger precondition on the reviewed Darwin shrink graph. Its historical checklist is retained as a dependency record, not a runnable next step. A pending-to-real-join0 contract requires a separate explicit review; this document neither makes pending an errno nor changes an observer.

## Finding

**The exact final fault/device experiment does not implement deferred join
recovery. Neither historical PASS closes that gap. A legitimate OS-error
trigger for the unchanged formal same-owner contract is also not established.**
These are separate implementation and acceptance-feasibility gaps. The retained
Darwin observations do not prove that every possible OS error is irrecoverable;
they do rule out treating a live joinable worker, a mutex wait, or an immediate
EDEADLK retry as the required recovery witness.

The audited experiment is the original c86dff86 producer bound by
`final-device-owner-verification.json`; GSI SHA256
`7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808`.
Its `setup.c` SHA256 is
`b2391053e699fe47af531af164880573d510768164186000bc2ab17903eef218`.
It remains diagnostic/building and not formally admitted. The fault/device
checks established retained failure, not lifecycle recovery.

## 1. Actual source operation and state transitions

Line numbers below identify the pinned producer, not an arbitrary current tree.

| Source / transition | Already guaranteed | Missing / consequence |
|---|---|---|
| `os_thread.c:548–560`, `___thread_join` | One actual POSIX `pthread_join`; nonzero errno encoded, zero mapped to NO_ERR. | No try-join or live-worker EAGAIN interface. Calling earlier can block; an alive target does not imply an errno. |
| `setup.c:1473`, `___current_vm_resize` → `on_all_processors(OP_VM_RESIZE)` → `___vm_resize_pstate` | Resize is a collective operation and returns its result. | Recovery must be entered through an agreed collective branch; a P0-only return cannot strand survivors in a different barrier. |
| `___vm_resize_pstate:1044`, P0 `OP_SET_PROCESSOR_COUNT:1173` | Publishes reduced active population before join. | Active population is not a retired-resource registry. Join failure leaves off-cohort state without a pending generation/owner ledger. |
| Retiring worker `setup.c:1117–1143` | Removes itself from idle deque; cleans local interrupts; retires native sfun markers; cleans OS state; exits OS thread. | Local cleanup is not proof of all old handler/remote GC borrowers drained or all Scheme/C roots handed off. Do not infer global quiet from these calls alone. |
| P0 `setup.c:1189–1200` | Only successful join calls `___transfer_mem_pstate` and `___cleanup_mem_pstate`; failure preserves those allocations and returns first error. | No pending-slot registration, stored per-target errno, same-owner identity, one-time finalization state, later recovery dispatch or slot-reuse guard. The next grow can setup the old slot again. |
| `mem.c:5257`, `___transfer_mem_pstate` | Splices still-object/RC lists and clears donor lists under misc-memory lock. | Its comment requires successful join AND GC/queue borrower drain; it does not establish those premises. It does not transfer arbitrary live donor C frames or all processor-private work. |
| `mem.c:5307`, `___cleanup_mem_pstate` | Frees remaining still/RC state and destroys scan queue lock. | Must not run before last scan/queue/handler consumer; join success alone is not complete borrower evidence. |
| GC `mem.c:3574`, `setup_stack_heap_vmstate`; strong mark at `:7302` onward | Active processors perform per-P still/RC/continuation/register/saved/type-cache/processor marking; P0 marks VM object. | No dedicated pending-retirement tracing path was found in this producer. Keeping native storage allocated is not proof of GC scanning. Before allowing Scheme/GC after error, prove pending donor roots/work are covered. |
| `setup.c:5385`, `cleanup_admission_error`; `___cleanup_checked:5454–5461` | Failed shutdown resize returns before VM/device/root destruction; cleanup_phase becomes retained(2). | Next cleanup returns the sticky error before retry. setup_state already changed to2 and registry/interrupt admission sealed. This is safe retained-failure disposition within its contract, not resumable shutdown. Never reset the flag to pretend rollback. |

For source stability, the ten indexed runtime source identities and GSI were
rechecked unchanged. `os_thread.c`, model/probe/recipe and historical sources are
additionally bound in the new JSON. This audit does not inspect or operate on a
peer's live producer/thread.

## 2. What the five existing campaigns actually prove

| Campaign | Retained outcome / stdout | Admission consequence |
|---|---|---|
| lifecycle-join-recovery-1 | PASS/exit0, `STILL-JOINABLE-THEN-SUCCESS` banner | Rejected: setup sets LW_REFUSED before actual join. |
| lifecycle-join-recovery-2 | Same PASS/exit0 and banner; separate receipt | Repetition of the same invalid witness, not two OS-error recoveries. |
| lifecycle-join-os-1 | DENY/exit2; `NO-STILL-JOINABLE-ERROR`, `(11 0 1 0 11 0)` | First resize joined successfully; no errno to recover. |
| lifecycle-join-later-1 | Same DENY/exit2 and tuple | Later-entry helper exists in this historical source, but failed branch never exercised. |
| lifecycle-join-wait-2 | Same DENY/exit2 and tuple | Blocking join still returns0. More waiting did not produce the missing error. |

Tuple is `(before first mid reopen after errno)`. The latter two source snapshots
are different from the final fault/device producer; do not transplant their
claims or hashes. The machine-readable observation summary has
`producerIdentity=UNKNOWN`; its platform statements are historical reports, not
newly executed native facts. The three DENY transcripts above were reopened and
hashed in this audit. The prior platform report distinguishes cycle error11
from first-call success; it records retry11 while the worker still joins the
owner, and later0 after pthread cancellation. Cancellation and another-owner
handoff are not this resize contract and are not authorized fixes.

### Historical helper defects that should not be copied

`lifecycle-join-wait-2` setup has later-entry recovery at1177 and dispatch1251.
It is a useful ordering sketch, not an integration-ready patch:

- A VM-global `lifecycle_os_join_errno` followed by any successful donor join can
  set `lifecycle_same_owner_joined`. With multiple donors this can pair A's failure
  with B's success. Track target/epoch/OS owner and attempt per donor instead.
- Successful `pthread_join` followed by handler_quiet==0 leaves join_pending set.
  A later invocation may call join a second time on the already joined thread.
  Separate joined-awaiting-drain from join-pending; never re-join after success.
- The pending recovery dispatch returns NO_ERR after clearing debt, without
  carrying out the requested grow. The probe makes only one reopen call and
  expects the original processor count. A successful recovery-only operation
  must not masquerade as successful requested resize. Resume the agreed request
  or explicitly document/return recovery-only and issue a separate resize.
- The historical shrink error arm duplicates errno recording. More importantly,
  a count guard alone cannot maintain GC coverage of off-cohort donors.

## 3. Implementation steps for Grok

These are requirements for a new reviewed integration, not edits performed here.

1. **First select a realizable failure contract.** Trace a native error from the
   real `___thread_join` return to the same target's later success. The current
   normal shrink has no demonstrated transient-error trigger. Recipe stdout is
   exactly error11 then0; the Python observer accepts any positive non22 errno.
   Both constraints matter: another errno does not satisfy that sealed recipe.
   Do not interpose errno, detach/cancel a worker, create a join cycle, change
   owner, add pre-join flags or widen budgets to manufacture acceptance. If no
   legal trigger exists, stop formal attempts with this gate OPEN and submit a
   separate contract-review decision. Do not silently weaken the recipe/checker.
   Injection may test retention but is not this formal OS-error witness.
2. **Add a retirement ledger**, in processor/VM native structures declared in
   `gambit.h.in` and managed in setup.c: immutable retirement epoch, original
   thread handle, exclusive P0/OS owner identity, per-donor actual errno and join
   state, root/work handoff ownership, borrower-drain acknowledgments, pending
   count and publication state. Suggested state names are design requirements,
   not existing fields: Prepared→Retiring→JoinPending→JoinedAwaitingDrain→
   Transferred→Reclaimed. Error stays pending; success never re-enters JoinPending.
   Count equals unreclaimed ledger entries; no slot/handle/epoch reuse until clear.
3. **Prepare before population commit.** While old cohort still serves nested
   GC, drain/hand off scheduler and GC work and root every surviving Scheme value
   in a mapped/traced owner. Inventory actual donor stack/register/saved/RC/still
   roots, callback suffixes, outstanding hints and scan work; a C pointer or a VM
   record name is not a GC map. Either prove all live data is handed to surviving
   tracing before shrinking, or implement a correct pending-root tracing domain.
   Publish preparation with release/acquire ordering; account for errors before
   commit and collective rollback without exiting only a subset of old cohort.
4. **Commit then join once per attempt**, in `___vm_resize_pstate`. A real join
   failure stores its exact return and the ledger identity, retains roots/queue
   locks/handle and returns an agreed result to survivors. Successful join moves
   to JoinedAwaitingDrain. Validate handler generation/scan/queue grace, then
   transfer exactly once and cleanup exactly once. Mark the final state before
   clearing count with ordered publication. EINVAL or stale handles are retained
   failures, not a recoverable still-joinable success.
5. **Recover at a later collective entry**, via `___current_vm_resize`/
   `___vm_resize_pstate` and a reviewed `recover_retired_processors`. Verify same
   VM, epoch, target and OS owner before native join. Survivors must agree on
   recovery/return/retry-request boundary. No nested fresh resize, grow slot
   setup, GC domain switch or successful cleanup while debt remains. After
   recovery, execute the original resize or return a distinct supported result;
   callers and the probe must agree. Do not spin retry inside the error arm.
6. **Keep sticky shutdown separate.** Existing `___cleanup_checked` deliberately
   seals admission and retains terminal failure. Do not make it restartable by
   clearing cleanup_phase/setup_state or reopening native resources. If shutdown
   recovery is required, add a separate resumable teardown cursor and verify its
   last consumers before changing that contract. Public resize recovery and
   permanent wake/device failure are different state machines.

## 4. Historical acceptance dependencies for the unchanged gate

- [ ] Prove the native trigger in step1 is reachable under the exact recipe;
  retain owner/target handle+epoch and raw return observations. If not, report
  blocked contract feasibility rather than scheduling two more full rebuilds.
- [ ] Review and publish completed source-bound producer using same repair-9-12
  custody, original compiler/configuration, no unrelated reseal or budget reset.
  Preserve the 39 targeted fault/device control contracts and first-eight gates.
- [ ] Run focused lifecycle controls before formal campaigns: first-call success;
  real error retaining resources; repeat error retaining same generation; later
  actual same-target join0; joined-but-not-drained without a second join; multi-
  donor mixed success; GC between failure/recovery; wrong owner/stale epoch;
  grow/repeated shrink during debt; cleanup retention; recovery+requested reopen.
  Injected errors and QNT mutants are separate labels, never formal OS evidence.
- [ ] Record one event tuple per attempt `(VM, epoch, donor, OS owner, entry,
  actual join return, phase, root/work owner, grace, transfer/cleanup counts)`.
  Result errA→0A must not be synthesized from another donor's success. Bound
  records to the real executable/generated C and retain failure logs too.
- [ ] Fix/review the probe's observability in a separately authorized integration:
  it currently never asserts `first!=0` and its errno getter is aggregate. Demand
  actual first-error/return agreement and same-donor later0; verify pending0,
  one transfer/free, scanned roots and restored processor population. Historical
  `lifecycle_join_os_errno` symbol is absent from the final producer; source-bound
  probe linkage is itself an unmet prerequisite. Do not change expected results
  or claim its current two stdout lines alone prove recovery.
- [ ] Obtain two independent genuine campaign receipts via the existing
  `gambit-smp --task repair-9-12 research` route and unchanged formal recipe,
  engine/producer/prior identity and caps. Historical run1/2 are immutable evidence,
  not output directories to overwrite. The observer has fixed run1/2 bindings;
  registering fresh receipts there without destroying history needs the existing
  evidence publication mechanism or explicit reviewed binding migration. Copying
  stdout or rewriting historical PASS metadata is not publication.
- [ ] In each receipt: native join-probe exit0, timeout=false; parent outcome and
  childOutcome PASS; native process host-managed topology with processor count>1;
  observation stdout equal raw stdout; exact declared recipe output; no pre-join
  flag, EINVAL, immediate retry, raw cancellation or substitute-owner shortcut.
  Keep original source60/configure120/seed180/core600/join-step90,
  join execution30/verdict10 budgets and progress overhead30 as declared.
- [ ] Reopen every child observation and verify provenance/last-consumer grace;
  the current Python observer uses source substring checks and transcript matching,
  not a complete machine-level proof. Only then record lifecycle closed and9/12
  in milestone/review, retaining8/12/6/12 history and other three open gates.

Read-only observer / qualification negatives (commands for Grok; not run here):

```sh
.venv/bin/python -m unittest tests.test_current_checkpoint_qualification
.venv/bin/python - <<'PYQUAL'
import importlib.util
s = importlib.util.spec_from_file_location('q', 'tests/run_current_checkpoint_qualification.py')
m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
print(m.qualify_nine_of_twelve('.'))
PYQUAL
```

Existing QNT `joinable_error_same_owner` permits independent joinFail/joinOk
choices; it does not prove the OS can realize that sequence. The Darwin return
model characterizes the missing premise. Keep both and their negative controls;
new ledger/QNT work must compose same-donor identity, generation, joined/drain
separation, root coverage, collective result and reopen semantics, rather than
assuming a fair scheduler eventually changes errno into success. No new model
run or C-level sufficiency theorem was produced by this evidence audit.


## Follow-up: platform branch feasibility and distinct pending status

`darwin-join-feasibility.md` pins Apple implementation evidence and records10
QNT controls. The restricted valid/exclusive/no-cancellation shrink graph lacks
the required native error→same-owner0 path. Wider target-cancellation reachability
is explicitly retained and does not qualify Gambit. Proposed deferred retirement
is a runtime status before native join, not errno11; replacing the formal gate
requires explicit contract review. No counter/recipe/runtime edit was made.
