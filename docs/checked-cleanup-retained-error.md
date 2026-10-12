# Checked Cleanup Retained Error Candidate

## Review Before Repair

The source caller and real Darwin primitive diagnostics establish that ignoring
the resize result can invoke destructive helpers without a join witness. The
cleanup-error, lifecycle and error/GC-drain models distinguish reduced population
from successful exit and drain. This candidate implements that caller boundary;
it is not another execution of an unchanged denied route. Expected performance
gain is zero: this repair targets failure correctness.

## Source Authority And Interface

Source authority is pinned `vendor/gambit` plus
`evidence/fixtures/checked-cleanup-retained-error/source.lock.json` and its
cumulative eighteen-file patch. The inherited sixteen other files are unchanged;
only `lib/setup.c` and `include/gambit.h.in` differ from the scheduler-retry parent.

The candidate adds direct embedding entry `___cleanup_checked`, preserving the
void legacy entry and existing global function-table layout. It does not add a
function-table slot or change the return type of an existing public symbol.
The new prototype and export still require complete build/link and embedding
qualification; source compatibility is not a complete ABI proof.

The checked entry returns the original shrink error before destructive cleanup.
Separate private phase and error state distinguish retained failure from cleaned
state. Repeated checked calls return that same error without resizing or freeing
again. The setup entry checks the admission helper before overwriting parameters
or VM population. Clean completion currently permits the existing fresh-setup
path, but actual second-generation embedding now fails; this permission is not
a safe-reentry guarantee.

The legacy wrapper invokes Gambit's existing fatal-error mechanism on failure;
it cannot silently return as if cleanup succeeded. A custom fatal callback that
escapes nonlocally remains an embedding contract concern. Normal legacy cleanup
returns unchanged. This failure policy is a candidate, not a released change.

## Explicit Concurrency And Ownership Limits

Host setup/cleanup calls are required to be serialized, as this candidate's
model and source comments state. The private phase is not an atomic lease for
arbitrary concurrent host API calls. This premise must not be confused with
disabling SMP processors or multiple threaded VMs.

The candidate does not implement new tracking for other live VMs, GC borrowers,
foreign callbacks, or publication tails. It relies on the existing caller
quiescence contract on successful cleanup. The error/GC-drain composition exposes
those unclosed source-refinement obligations; this patch alone does not discharge
them. Retained failure is not recovery, leak freedom or permission to unload.

## Source And Model Verification

The fixture `checked_cleanup_retained_error.c` reuses the prior real Darwin
thread controls and includes exact newly locked checked/admission/legacy bodies.
Destruction helpers and fatal process exit remain explicit stubs; collective
resize coordination is mocked and Scheme tagging abstracted.

Twelve parallel observations, three per mode, passed:

- Checked success: one resize, one global release, repeated call succeeds.
- Checked EINVAL: zero destruction calls, repeated call and admission helper
  return the original error.
- Legacy success: normal return, one resize, no unsafe release.
- Legacy EINVAL: fatal stub exits 73 before destructive calls; returning would
  fail the assertion. Exit 73 is an expected fixture observation, not an ordinary
  successful runtime exit.

GNU strict compilation took 0.176 seconds. Processes completed within their
unchanged five-second caps, with quiescent groups. Actual full `___setup` was not
called by this source-unit: the helper is observed and its entry callsite audited.
The earlier format-warning denial and original fixture snapshot are retained.

`checked_cleanup_failure_disposition.qnt` imports the conditional cleanup model
and binds this source lock and source-unit receipt. Twenty-two distinct states /
twenty-six generated states pass safety and fair explicit-outcome completion.
Silent legacy return and setup overwrite each produce expected counterexamples.

The declared sealed source-core Recipe regenerates the complete runtime with GNU
GCC and all three SMP/multiple-VM flags under the unchanged 420-second total and
180-second seed/core budgets. Build status and subsequent native results must be
read from its actual receipt, not inferred from source-unit success.

The actual sealed source-core run passed all five steps in 152.649 seconds.
Its inspection reports PASS/CURRENT, and only the two intended files differ
from the locked parent. The portable summary binds the original receipts:
`evidence/source-results/fixtures/checked-cleanup-retained-error/sealed-source-core-summary.json`.
This is complete source-core regeneration, not a two-pass bootstrap or a Gerbil
package cold-build timing.

The same fresh producer compiled the unchanged `gc_root_cohort_composition` and
`resize_gc_lifecycle` controls. Three runs per fixture passed without timeout,
with unchanged source/binary identity before and after. CPU capacity was divided
among two simultaneous processes, each receiving six processors on this host;
the scheduler derived those values from available capacity and the cohort's
six-role requirement. Source and native budgets stayed at 60 and 30 seconds.
These are diagnostic native controls, not a sealed complete suite. Their receipt
is under `evidence/source-results/fixtures/checked-cleanup-retained-error/fresh-runtime-native/`.

## Remaining Gates

The real C embedding fixture completed generation zero, including checked and
repeated cleanup, then received SIGBUS during the next `___setup` (0.804 seconds,
no timeout). The crash stack enters `___linkfile_descr` from
`linker_to_mod_or_lnk`. That function overwrites static linker function entries
with resolved descriptors, then interprets them as functions on another setup.
The receipt is `embedding-worker-report/receipt.json` under this candidate's
source-results directory. This is a native DENY, not a passing reentry control.

Earlier generation-zero callbacks independently returned encoded error 71;
their cause remains open. The later phase-observer run passing generation zero
does not repair or explain those observations.

`global_linker_generation.qnt` separates callable linker entries from resolved
descriptors and generation-bound fixup metadata. Restoring only linker entries
leaves module-fixup generation as an explicit counterexample obligation, not an
observed second native crash. Abstract complete reconstruction and explicit
unsupported-reentry refusal are alternatives to audit against the upstream
embedding contract, not implemented repairs. Do not reset one flag and claim
full lifecycle correctness.

Whole-runtime fault injection and API reentry; valid joinable-processor failure
reachability; physical root/borrower and other-VM drain; custom fatal callback and
unload contracts; arbitrary host concurrency; full native suites; two-pass
bootstrap; Gerbil build/test correctness and performance. No runtime or release
admission until these are qualified at the exact candidate identity.
