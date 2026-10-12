# VM Memory Constructor Ownership

This is a source-led prerequisite for `pstate_vm_failure_handoff`, not a native
repair or evidence that PR988/1038's historical compiler failure has this cause.
The prior handoff model assumes VM-memory failure has already unwound local
resources. Pinned candidate027 does not establish that assumption.

## Route Review

| Question | Evidence and decision |
| --- | --- |
| Correct route? | `setup_os_and_mem_vmstate` delegates memory-error cleanup to the memory callee, but the inspected callee has failure returns with live resources. Model that callee before changing its caller. |
| Already explored? | Existing processor setup and outer-prefix models do not track this VM-memory constructor's scan resources, root tables or list membership. No unchanged native failure is rerun. |
| Worth optimizing? | A correctness prerequisite: missing rollback, unchecked initialization, and invalid proposed destruction. It is not a measured performance bottleneck. |
| Expected benefit? | Complete owned-resource rollback without touching unready P0 or unlinking outside the list lock. No numeric speedup is claimed. |

## Source Correspondence

The manifest binds candidate027 `lib/mem.c` and `lib/setup.c` by hash. The pinned
base is `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`; this is not a claim about
the current upstream staging head.

| Source boundary | Fact | Model consequence |
| --- | --- | --- |
| `mem.c:___setup_mem_vmstate`, scan mutex/condition initialization | Both return values are ignored in the threaded path. | Constructor success requires both resources; an init-error control must not pass publication. |
| Root-table acquisition | Failure frees partial root tables and unlocks the global list, then returns without destroying scan resources. | Root failure starts with no owned roots, but still-owned scan resources. |
| VM list insertion | Insertion is protected by `vm_list_mut`, before heap allocation. | Failed heap setup still owns a list membership; unlink must reacquire the global list lock. |
| `adjust_msections` and size check | Failed expansion may retain a consistent partial allocation. Metadata allocation may succeed while zero heap sections exist. | The strengthened model separates descriptor and sections; `vm_heap_partial_allocation` checks this helper/caller lifetime contract. Native correspondence remains open. |
| `___cleanup_mem_vmstate` | Calls `___cleanup_mem_pstate(P0)` and assumes the global list lock is already held. | Full normal cleanup is not a valid unconditional constructor rollback. |
| `setup_os_and_mem_vmstate` | On memory error it cleans only VM OS state. | VM-memory rollback remains a callee obligation; the caller must not blindly destroy the same resource again. |

## Model Scope And Controls

`vm_mem_setup_transaction.qnt` explores single/multiple VM and single/threaded
configuration branches. Integer resource IDs are explicit and stable, not CPU
counts. The finite two-section abstraction checks ownership and release order;
it is not the complete `adjust_msections` implementation.

Six independent controls cover ignored scan-mutex initialization, root failure,
partial heap failure, blanket normal cleanup touching unready P0, unlocked
unlinking, and destruction of an uninitialized condition variable. The first
three characterize the inspected source. The last three reject possible repairs
and are not attributed existing Gambit defects or native failure reports.

The positive contract releases heap allocations, unlinks under the list lock,
frees roots, then destroys initialized condition/mutex resources. It never calls
P0 cleanup. Progress assumes weak fairness and returning primitive calls.

Remaining obligations are native partial allocator correspondence, alternative
mutex-backed spinlocks, activity-log initialization and abort (normal activity-log
cleanup reads P0), and VM-list reader exclusion during early publication. OS VM
setup delegates to the inspected POSIX I/O path, whose cleanup is currently empty;
other platforms still require correspondence checks. The model assumes an
initially valid global list and externally quiescent constructor. It does not
prove concurrent GC/VM visibility, C weak memory, real OS error behavior or native
bootstrap. No runtime repair is admitted by a bounded positive alone.

## Evidence Handling

The first campaign `.data/vm-mem-setup-model-001` found the expected counterexample
but the shared trace parser refused its string-valued resource set. Its DENY is
preserved as a representation/admission failure, not a source or protocol failure.
The integer-ID campaign uses the shared supported resource representation; no
acceptance predicate or timeout was relaxed. Native routes are not run here.

The second campaign checked six controls and positive safety/progress (160
distinct states, 184 generated, zero queued; positive check 29.122 seconds).
However shared parser code changed during execution: `contextStable=false` and
the campaign is DENY, not admitted evidence. Its original receipt remains
unchanged. That campaign cannot supply a portable admitted receipt.

Datalog now includes protocol-composition edges in the existing transitive
contract queries. Checked local protocols can satisfy model-receipt coverage,
but never native coverage. The allocator obligation now points to the separate
bounded model. Spinlock initialization and early-list visibility remain
explicitly unmodeled obligations;
their absence cannot be hidden by a green local constructor model.

The strengthened descriptor-aware campaign `.data/vm-mem-setup-model-003`
rejected all six controls and exhausted 216 distinct / 244 generated positive
states, zero queued, with safety and temporal progress completed in 29.261
seconds. Inputs and model remained stable. Portable evidence is under
`evidence/model-results/vm-mem-setup-transaction-model/`; campaign002 remains a
context-drift DENY and is not rewritten. Activity-log abort now has its own model
dependency; its acceptance is separate from this constructor result.

Campaign004 further composes the spinlock prefix and includes successful
mutex-backed prefix ownership in every later VM failure rollback. It covers
ticket, POSIX mutex and normally returning void mutex backends with threaded
on/off and single/multiple VM branches. The prefix failure contract is proposed,
not implemented in source. All six controls and positive safety/progress passed:
861 distinct / 957 generated states, zero queued, 30.365 seconds for the positive
check, stable inputs. Current portable evidence is under
`evidence/model-results/vm-mem-setup-spin-model/`. Campaign003 remains historical;
its model digest no longer matches the strengthened current model.

Successful-constructor list visibility now has a separate source-characterization
model. Its proof does not supply failure-time reader retirement or C memory-order
refinement. Datalog exposes these downstream obligations instead of treating the
new dependency edges as a whole-runtime proof. The framework regression passed
211 tests in 43.578 seconds, not a Gambit native build/test run.
