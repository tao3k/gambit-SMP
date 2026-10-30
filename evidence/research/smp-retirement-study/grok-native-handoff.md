# Grok handoff: owned requests, permanent wake faults and checked teardown

Evidence-only handoff, 2026-10-23. Integration belongs to Grok. This checklist
records an already tested experiment; it does not authorize operating on another
thread, modifying runtime code, launching a full inventory, committing or pushing.

## 1. Identity and starting point

- [ ] Start in the existing `repair-9-12` checkout and incremental producer.
  Resolve the real task lock descriptor, kernel PID/birth and last consumers;
  wait for an occupied production lease to release naturally. Use normal
  `workspace.execution_scope` and the source workspace lease for integration or
  native execution. Metadata checks use the registered `audit` role.
- [ ] Compare bytes with `grok-native-handoff.json` and
  `final-device-owner-verification.json` before interpreting any receipt.
  A mutable directory name alone is not producer identity.
- [ ] Preserve the diagnostic producer's `building` state and false admission.
  Grok must publish its completed source-bound producer through the existing
  framework; old completion seals cannot certify changed source.

Producer: `.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6`.

Experimental 7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808 SHA256: `7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808`.

The index binds ten runtime source files, generated `_thread.c`, `_gambit.c`,
`gambit.h`, eight native receipt groups (39 control rows), and the model receipt.
Strict coordinator-owner controls are from run `5f62b1bf99b443e9b092f0766b300109`;
the other 37 rows are from `0435aab786604b139a320715f8535ec4`, on the same 7263fe0376e89ddf1d4527a7a9701c5943136346f82477c14d2de05e51104808.
The handoff manifest rechecks those bytes; it does not rerun native tests.

Existing `device-callback-full-closure.patch` followed by
`fault-owner-guard.patch` was replayed on its recorded before-source copy and
matched all six changed files. These are deltas on the earlier owned-request
experiment, not standalone replacements for upstream Gambit. Do not apply every
incremental patch together or run old `execute-*` scripts on an arbitrary base.
Use their before/after identities to review and integrate through managed source
updates; do not blindly patch a shared producer.

## 2. Function-level integration checklist

Paths below refer to the exact producer source, not the checkout's unrelated
runtime tree. Review the generated C as well as Scheme.

| Area / actual functions | Required change / ordering | Invariant and last consumer |
|---|---|---|
| `_thread.scm`: `##thread-intr!`, `##thread-intr-propagate!`, `##thread-intr-notify!`, `##thread-intr-wake!` | Result request is `[next, result_mutex, immutable_target, phase]`; link only in target thread queue under T lock. Publish a separate processor procedure hint after unlock; recheck running/parked routing under T then P with collective participation. On migration forward a new hint. | One request has one queue owner; its next slot never joins two chains. A hint is not ownership. Stale routing must not remove another thread's BTQ/TOQ entry. |
| `##thread-lock-remove-btq-toq!`, `##thread-intr-drain!`, `##thread-intr-execute!`, `##thread-resume-execution!`, `##other-interrupt!` | Check routing predicate before scheduler removal. Claim/dequeue once; queued→active→replied/failed. Retain request, mutex and outcome in mapped Scheme frames through result store and final unlock. Catch/reply/reraise ordinary errors; abandon mutex on winding escape; reject stale continuation reentry. | Sender's second mutex lock remains. Neither polling nor a synthetic success replaces actual thunk execution/reply. An active sender may end by VM terminal failure, which is not a reply. |
| `gambit.h.in`: `___TICKETLOCK_LOCK2`; `setup.c`: `service_procedural_interrupts_pstate` | Acquire barrier after ticket grant; callback non-NO_ERR returns with lock already released and suffix still queued. | Ticket authorization alone is not memory acquire; no second unlock, no dropped suffix. |
| `os_io.c`: `device_select_impl`, `device_select_with_cap`; scheduler wait caller | Independent scheduler recheck cap (50ms), with typed recheck outcome; retain the actual user deadline. Release P lock before observing/posting fault; reacquire/recheck normal scheduler predicates. Public cleanup select remains uncapped. | Cap expiration is not device readiness or user timeout. No CHECK callback on cap-only expiration. No Scheme callback/error handling under P/ticket locks. |
| `___device_select_abort`, `___vmstate_os` | SC writer admission increment→SC closed-phase read→write→release decrement; four EINTR attempts; EAGAIN nonfatal; first hard errno sticky. Cleanup SC closed store then SC count read, and track real selectors too. | No counter/phase store-buffer hole. Successful later write cannot erase hard fault. After closed phase, no new fd writer; existing writers/selectors are last fd consumers. |
| `_thread.scm`: `##wait-fault-observe-unlocked!`, `##fault-control-run!`; `_kernel.scm` hook setters | Register/root pinned P0 coordinator before fault. Post once outside P lock; CAS posted→running. Detach jobs/wills into VM record, advance cursor before invocation, record error/current item, allow private GC collectives, prepare before native exit. Setter hooks live in defining module so generated C retains them. | Root carrier: `[thread, phase, errno, job_suffix, will_suffix, error, recursive_exit_intent, current_callback]`. VM tracing covers every suffix/error/current item. Public admission closes before ownership transfer; private GC work remains serviceable. |
| `##fault-control-callback!`, `##fault-control-cursor!` | Recovery continuation outside per-call winding guard but inside mapped coordinator frame; consume prefix before call; capture escape and retain current/suffix until recovery; reject retired reentry. | Public call/cc/graft cannot consume the coordinator or replay an already executed callback. Recursive exit records intent rather than another native unwind. |
| `##fault-control-protect-owner!`, `##thread-terminate!`, `##thread-suspend!` | Reject the active fault coordinator at private lifecycle entries, before lock acquisition/lifecycle consumption. Keep ordinary thread behavior and healthy path intact. | Termination's non-winding scheduler exit bypasses dynamic-wind; guard alone is insufficient. P0 coordinator is the unique suffix owner until prepared exit. |
| `c_intf.c`: marker make/kill, `___retire_sfun_stack_markers`, `___run` | Track per-P native marker ownership; finalize on every normal/throw `___run` return and nonreturning worker exit. Refuse checked cleanup with a live returnable P0 marker or wrong OS owner before mutations. | C/Scheme frames remain rooted until their actual final consumer; worker OS exit can bypass `___run` finalizer. |
| `os_io.h/c`: `cleanup_error`, `___device_close`, `___device_cleanup`, `___device_release` | Sticky first hard error, single POSIX close attempt, never retry ambiguous close EINTR. EAGAIN readiness-wait EINTR can recheck separately. On hard close/release error retain allocation/ref/group link; do not replay partial release. | Reused fd number belongs to a new owner. CLOSED stage is not evidence of successful disposal. Failed storage remains owned, not falsely freed. |
| `___device_group_cleanup_checked`, checked IO module cleanup | Stop on failed node, preserve untouched suffix and module/group state. Void wrapper must preserve failure retention too. | Group remains last owner after wrapper handoff; no free-on-error. |
| `mem.c/h`: `___prepare_device_foreigns_vmstate`; `___release_foreign`; `setup.c`: `___cleanup_checked` | After worker/wake/marker grace, while all VM roots still live, visit registered VMs' canonical device foreign wrappers; disarm pointer/release function before one-shot callback. Check foreign preparation and IO group cleanup before processor/VM/GC destruction. | Foreign finalizer is a real last pointer consumer. Group-first free would leave a dangling wrapper/double release. Failure retains VM/root/module/device state; success disarms later finalizers. |

## 3. Required invariants and supported boundary

- [ ] At every GC, ownership is covered by a traced thread queue, a mapped active
  frame, or the traced VM coordinator record; no handoff has an unrooted interval.
- [ ] Request IDs/immutable target survive migration and nested requests; phase
  claim prevents duplicate execution/reply. Nested GC does not steal public
  request or callback ownership.
- [ ] Native wake phase is monotone: healthy→faulted→posted→running→prepared→closed,
  with retained failure as a separate terminal disposition. No success clears errno.
- [ ] Native cleanup requires a valid live instance borrow before dereferencing
  any VM pointer and external publishers quiesced before teardown. Counters do
  not make stale raw host pointers valid.
- [ ] Callback errors, public continuation escapes and refused terminate/suspend
  preserve current/suffix/error roots and lead to checked terminal disposition.
  Exit70 in hard-failure tests is intentional failure reporting, not release success.
- [ ] Raw private C/no-winding escapes retain the cleanup-refusal boundary;
  unbounded callbacks are not proven terminating. Darwin tests do not certify
  every platform ABI or arbitrary device release implementation.

Stable disposition is the mechanism: explicit ownership, independent bounded
wait return, unique rooted fault coordinator, then checked last-consumer teardown.
This avoids relying on a transient wake byte or repairing head/tail after a lost
request. Costs include a 50ms scheduler recheck wake while idle, SC admission
operations per abort, a separate hint allocation, one marker allocation/free,
and a one-time still-object traversal at sealed teardown. Retained hard failure
keeps resources until host/process disposition. No performance improvement or
complete safety proof is claimed from these finite tests.

## 4. Regression commands for the integrator (not executed by this handoff)

Run from the SMP root. The current native runners are pinned to the c86dff86
producer path. They test whatever bytes are there; verify hashes first. If Grok
publishes different bytes, generate new receipts with those identities and keep
all historical failures. Do not relabel the old receipts or use old audit
finalizers as regression runners. Do not select a different task/directory to
reset cumulative budgets.

After production custody is naturally available, run the focused chain through
the existing supervisor; the scripts themselves also take execution/source leases:

```sh
.venv/bin/python - <<'PYREG'
from pathlib import Path
import sys
from gambit_smp.workspace import execute
r = Path.cwd()
names = ['verify-fault-owner-native.py', 'verify-device-callback-native.py', 'verify-real-device-close.py', 'verify-owned-request-native.py', 'verify-marker-ffi-native.py', 'verify-owned-request-final.py', 'verify-accepted-fault-native.py', 'verify-final-deadline-native.py']
program = 'import runpy; ' + '; '.join(
    'runpy.run_path(' + repr(str(r / 'evidence/research/smp-retirement-study' / n))
    + ',run_name="__main__")' for n in names)
print(execute(r, 'repair-9-12', [sys.executable, '-c', program], wall_seconds=600))
PYREG
```

The 600s supervisor cap is for this aggregate focused chain, not a replacement
for any formal stage budget. Keep existing native child caps (including 12s per
flood round and 30s fault controls), p11, compiler/configuration and fixtures.
Compiler fixture execution with GAMBOPT=p1 is distinct from native p11 testing.
Inspect every child receipt and parentReaped/processGroupQuiescent; outer exit0
alone is insufficient.

Run the QNT controls separately, with the audit role its runner registers; do
not nest a second audit launcher under production custody:

```sh
.venv/bin/python evidence/research/smp-retirement-study/verify-device-callback-model.py
.venv/bin/python -m unittest tests.test_current_checkpoint_qualification
.venv/bin/python - <<'PYQUAL'
import importlib.util
from pathlib import Path
s = importlib.util.spec_from_file_location('qualification', 'tests/run_current_checkpoint_qualification.py')
m = importlib.util.module_from_spec(s); s.loader.exec_module(m)
print(m.qualify_nine_of_twelve(Path.cwd()))
PYQUAL
```

QNT candidate must pass `safe` and fair `completion`; all ten negative
initializers must yield their decoded distinguishing witness. The model runner
retains the 30s per-case limit. Expected mutants are early unlink, group free on
error, forgotten close error, callback escape/reentry, roots freed before IO,
failed release freeing storage, free before foreign handoff, and coordinator
terminate/suspend. A mutant's counterexample is the expected negative result.

Expected native checks: 8×100000 exact deliveries/replies at p11; nested
migration/GC; ordinary errors and winding escape; C callback non-NO_ERR suffix;
600 actual nested C/Scheme calls; accepted sender at hard fault; finite EINTR
recovery; EBADF/persistent EINTR/held writer dispositions; independent wait
return and real250ms deadline; close/release/group/foreign/P1 wrapper retention;
real close EINTR before/after syscall and fd reuse; individual self-terminate and
self-suspend refusal, rooted suffix/error and prepared P0 exit. All 39 rows
must pass on the same final executable, including expected fatal/refusal rows.

## 5. Formal 9/12 admission: still open

`tests/run_current_checkpoint_qualification.py:qualify_nine_of_twelve` is the
current counter observer. Read-only evaluation during this handoff returned
`{"admitted": false, "closed": null, "count": "8/12", "runsOk": false}`. This is a counter observation, not new native execution.

- [ ] Grok lands/reviews actual code and obtains a completed canonical registered
  same-work-item producer bound to exact source, generated C, compiler/config and
  executable bytes. The diagnostic building producer is insufficient.
- [ ] Obtain two genuine lifecycle campaign receipts through `gambit-smp --task
  repair-9-12` under the unchanged contract/caps. Observer locations are
  `.cache/tasks/repair-9-12/lifecycle-join-recovery-1` and `...-2`.
  Their historical request selects
  `evidence/research/processor-interrupt-collective-wait/handler-quiet-join-recovery.recipe.json`.
  That historical recipe/engine is a clue, not permission to reuse an obsolete
  seal, overwrite old receipts, or recompile the same failed route. Resolve the
  current valid engine/prior/producer through existing admission before launch;
  no new formal campaign was launched here.
- [ ] Each captured native transcript must be exactly actual nonzero OS join
  errno followed by same-owner later successful join (`OS-JOIN-ERROR n`, then
  `SAME-OWNER-JOIN 0` with the existing LIFECYCLE-JOIN prefix). EINVAL22, pre-join
  LW_REFUSED, banners/pasted text and immediate retry inside the errno arm do not
  qualify. Preserve threads/roots while join is still outstanding.
- [ ] Each receipt outcome/childOutcome PASS, exit0, no timeout; matching native
  process exit0/no timeout; host-managed processorTopology and expected processor
  count >1; observation stdout must equal captured stdout. Check real custody
  and byte provenance beyond the observer's textual source-pattern checks.
- [ ] Current source correspondence must establish actual stored join errno,
  `recover_retired_processors`, pending joins and memory transfer only after the
  correct owner has joined; textual symbol presence alone is not runtime proof.
- [ ] Only after the receipts qualify, update the milestone/review's current9/12
  lifecycle-closed statements while retaining 6/12 and8/12 history. Keep complete
  GC/FFI, Gerbil correctness and release performance explicitly open and keep
  their distinct numerical/crash/full-producer qualifications. Re-run the
  observer and its negative tests; never edit it to admit this experiment.

The latest 39-row native result closes the two tested fault-device/callback
contracts. It does not close the missing lifecycle join recovery, prove that
all first eight gates remain unchanged under integration, or certify TFIB/full
GC/FFI/Gerbil/release behavior. Grok must retain the first-eight contracts and
source-bound prior evidence and run their required qualification before claiming
no regression. Full inventory execution requires its separate authorized gate;
this handoff does not launch it or change any timeout, fixture or expectation.


## Follow-up: lifecycle admission feasibility and source gaps

Read `lifecycle-join-recovery-gap.md` before launching formal campaigns. The final
producer lacks deferred join recovery; historical PASS banners are inadmissible.
Three real-join campaigns instead returned first-call success and DENY. A legal
native error trigger remains unestablished. Historical ledger code also needs
same-donor/epoch attribution, joined-vs-drain separation, continuous GC coverage
and recovery/request-result agreement. Merely rerunning two campaigns or adding
pending fields cannot close9/12. The earlier handoff creation snapshot remains in its audit receipt. The live
companion index now binds this follow-up; historical validation receipts are
unchanged.


## Contract proposal: supported pending retirement and fixed reaper

`lifecycle-pending-reaper-contract.md` maps original safety purposes to a proposed
pending→actual join0 conjunction, function-level interfaces, traced-root/slot/join
permissions, failure disposition and two-campaign native witness requirements.
`lifecycle-pending-join.contract-proposal.json` is evidence only, not an activated
recipe or observer. Combined reaper QNT has16 accepted controls (six positive
safety/fair terminal-disposition cases and ten decoded negatives), including
two donors, two epochs and previous-generation roots. It is conditional protocol
evidence, not C tracing/atomics proof or native9/12. Current count remains8/12.


## Actual C root coverage and publication refinement

See `reaper-c-root-publication.md` and JSON before writing the reaper patch.
Raw saved frames, active-only native RC/still scans, mutable RC writeback,
post-count release callbacks and reader-safe reclamation require actual source
changes. The five ordered patch units and C-shaped keyed publication protocol
are design instructions, not an applied patch.19 new model controls pass;
actual GC maps, generated C, C atomics and native fault tests remain owed.


## Frame materialization, rollback and pending native scan owners

See `retirement-materialization-domain.md` and `.patch-plan.json` for concrete
proposed fields, function signatures/insertion points and common collective
result rules. GC-forwarded roots cannot be rolled back by restoring old fp/bits.
Native owner membership changes atomically with count commit and later transfer;
PREPARING entries do not double-scan active lists. The new model passes16 bounded
controls; source implementation and native receipts remain unperformed.
