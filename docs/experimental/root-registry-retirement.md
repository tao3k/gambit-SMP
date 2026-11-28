# Root Registry Retirement And Scanner Ownership

## Concrete Reference Mechanisms

Pinned OCaml `runtime/globroots.c`:29-82 and :237-288 uses a dedicated
`roots_mutex` for root-list topology and scanning. The blocking lock form is
intentional: registration/removal can run where releasing the domain lock is
unsafe. Thus "wait for this metadata lock" does not itself grant permission to
detach runtime participation or execute a pending Scheme callback.

While scanning, the current OS thread has `iterating_roots > 0`. Deletion in that
thread marks `ROOT_DELETED` without acquiring its own nonrecursive lock again;
the current or a later iteration physically removes the entry. Other threads
still take the mutex. Insertion does not have the same bypass. This is a narrow
owner/operation contract, not a global recursion flag or arbitrary re-entry API.
The scanner invokes a trusted `scanning_action`, not an arbitrary application
callback.

The POSIX path in `caml/platform.h`:219,672-675 uses the static pthread mutex
initializer and `pthread_mutex_lock`; it supplies no recursive-lock contract.
The model's re-lock control assumes a blocking nonrecursive guard. It does not
claim every platform's unsupported self-lock has that identical native outcome.

The manual `intf-c.etex`:2160-2179 gives the missing effect boundary. Custom
finalizers cannot allocate, call into OCaml, raise, or access/mutate its heap,
but root removal is explicitly permitted. These restrictions explain why a
root-deletion path must work without granting the whole runtime API. They must
not be imposed wholesale on Gambit's supported FFI/continuation behavior.
This permission alone does not prove which finalizer runs during a particular
global-root scan; the special deletion branch and the finalizer effect contract
are separate source observations.

`globroots.c`:151-178 also does not hold the topology mutex across the final
`*r = newval`. The public contract in `caml/memory.h`:566-593 requires modifying
generational roots through the designated API, and the manual :1132-1145 ties
that discipline to scanning roots less often. Registry exclusion alone is not a
proof of arbitrary concurrent payload updates, complete roots, or a C memory
ordering bridge. A generational-root/update-barrier design for Gambit would be
an independent collector milestone, not a low-cost mutex change or measured gain.

### Entry Ownership And Collector Phase Are Separate

The same OCaml manual, `intf-c.etex`:2643-2689, requires the domain lock for
runtime access, including callbacks. After releasing it, C must not access OCaml
data or call its runtime until reacquisition. That is an entry/participation
contract, not a process-global mutation lock. `tutorials/parallelism.etex`:
602-610 explicitly states that C in different domains can run concurrently even
when both retain their domain locks. Copying a per-context entry lock would not
by itself serialize Gambit's runtime-shared tables or one escaped root slot.

The collector supplies another essential premise. `minor_gc.c`:533-561 scans
global young roots on the first participant, inside the STW callback at
:885-945. `major_gc.c`:1671-1756 elects one global-root scanner and publishes
`MARKED` with release semantics. Other participants use acquire loads and do
not resume mutators until global roots are marked. The source explicitly allows
other domains to leave after their own local roots are done only once that
global condition holds. Thus the ordinary payload store in `globroots.c` is
not explained solely by `roots_mutex` or the domain lock: the collective's
mutator exclusion matters. These observations do not prove same-slot concurrent
C writers safe, nor make C bindings that access runtime values while detached
legal. The model below assumes eligible participants and SC phase events; the
actual release/acquire bridge remains a source-refinement obligation.

For Gambit the useful low-cost question is whether its existing collective
already supplies that exclusion for each actual RC caller. It is not whether
to import OCaml's generational barrier, make all FFI calls take one global lock,
or add an unconditional extra GC barrier. Inspect legal entry, root publication,
participation and post-service reload together before proposing synchronization.

There is already positive Gambit counterevidence to "the root-completion barrier
is missing": pinned `mem.c`:6938-7038 places `BARRIER()` calls between setup,
strong marking, weak marking, cleanup and resizing inside the VM collection
path. This is not a proof that every legal external user is in that cohort or
that the candidate's barrier implementation is correct. It means the current
Recipe must first bind the affected RC user to those existing phases, not copy
OCaml's `MARKED` variable or add another barrier on the basis of this projection.

## Chez: Stable Carrier Is Not Execution TLS

Pinned Chez `s/7.ss`:812-830 enters collection under `with-tc-mutex` and requires
one active Scheme thread. `s/cmacros.ss`:2210-2218 uses paired interrupt and
mutex operations. Creation/destruction in `c/thread.c`:58-183,261-341 uses that
context mutex. This is the relevant exclusion context for carrier reuse, not
the assertion that an unchanging creator address proves old thread identity.

`c/gc.c`:120-180 explicitly forbids acquiring `tc_mutex` while sweeping and
forbids `get_thread_context()` there: sweeper OS threads differ from Scheme
threads and can temporarily process another context. :2980-3028 assigns
contexts to sweepers, while :1042,1159,2216-2217 supplies absent-creator routing.
The collector's explicit ownership descriptor, execution entry ownership and
OS-thread-local iteration state therefore have different meanings. Neither
"replace everything by TLS" nor "TLS must never be used" follows.

## Current 9/12 Repair: Avoid Redoing Existing Work

Pinned Gambit `mem.c`:684-700 force-cleans the RC list; `___release_rc`:760-780
decrements a record's reference count and unlinks/frees at zero; :816-825 stores
the Scheme payload; :3969-3989 scans the RC data. Strong-root assignment at
:6845-6864 is a separate collector question. A C reference count is not a lease
on the containing processor/VM and does not stop forced container cleanup.

The inspected existing cumulative mutex-return patch, SHA-256
`49514f1819da3ca6008b07690e732a13625a54811a3e44a7da3615e25fdf0d55`,
already splices RC and still-object lists in `___transfer_mem_pstate` under
`MISC_MEM_LOCK`, empties the donor, transfers before cleanup after a successful
join, and moves `mark_rc` outside the P0-only branch. These are positive source
observations, not new changes or qualification of that repair package. The patch
is another owner's active source product, not a new research-model input here.

The existing native `retired_rc_root_survival.scm`, observed SHA-256
`faf3f9ac6cd2814b7e08adc27f6f847f077ad90226c43c5f3d3cfcbf0e8da945`,
already retains movable values on nonzero processors, retires to P0, collects,
checks relocation and payload contents, then releases the handles. Do not add
another copy or report this source inspection as executing it. It covers that
successful-retirement scenario, not all failure/cancellation/host access paths.

The remaining bounded Recipe is to bind the actual legal host users and their
last RC access, exact donor/recipient incarnation, scan phase and transfer
completion before destructive cleanup. Reuse `gc_rc_roots` for per-processor
coverage and `vm_list_reader_retirement` for admission/borrower lifetime. Neither
model alone proves moving-GC visibility, external frame ownership, complete RC
handoff or the actual candidate's current native gates.

One concrete writer-side condition remains: the transfer's `MISC_MEM_LOCK` does
not by itself cover the baseline `___release_rc` list unlink or `___set_data_rc`
payload store, which do not acquire that lock in the inspected helper bodies.
If supported entries already serialize those operations against retirement, bind
that source guarantee rather than adding a lock. If concurrent handle operations
are supported, their actual writer/scan contract must be established. The helper
shape alone is not a reachable race or evidence that broader concurrent RC APIs
are supported; inventing such APIs belongs to Experimental.

### Actual RC Callers And Counterevidence

| Pinned source path | Observed contract | Unproved condition and Recipe consequence |
| --- | --- | --- |
| `c_intf.c`:2885-2934 to `os_dyn.c`:748-794 | A converted Scheme procedure not already backed by `c-define` may allocate a C closure. Its RC payload is initialized before the trampoline is returned. | This is not evidence of post-publication arbitrary payload mutation. Map the actual allocation/GC/entry contract, including its supported configuration. |
| `os_dyn.c`:639-671,758-762 | The pinned trampoline generator has bodies for 32-bit x86/PPC and SPARC. With no `C_CLOSURE_CODE_SIZE`, creation returns null; conversion reports its existing error. | The global `c_closure_self` TODO is not automatically a reachable failure on a current ARM64 or 64-bit x86 build. Do not propose TLS as a repair for a path not enabled by that candidate. Static `c-define` entry is a distinct path. |
| `c_intf.c`:6510-6546 | The stack-marker helper allocates, then obtains the dynamic closure's procedure through the RC record when `proc_or_false` is false. | RC discovery during a possible collection and the marker's later ownership must compose. Existing per-processor RC marking addresses a component, not the entire foreign-entry/root-map proof. |
| `c_intf.c`:1731-1779 | Function and string release/addref helpers call the RC operations; no retirement join or borrower handshake is added in these helper bodies. | Bind external last use to the legal host owner and containing VM lifetime. A C refcount does not keep a destroyed VM alive; simultaneous calls are not established as supported. |
| `examples/tcltk/tcltk.scm`:125-195,294-342 | The example creates a still vector, installs it in an RC record before publishing Tcl client data, reads it for callbacks and releases it on command deletion. | This is an example, not qualification of the current SMP FFI. Tcl event ownership, command deletion versus active callbacks and VM teardown need actual entry contracts. No new native fixture is implied. |

This bounded caller census distinguishes initialization, callback use and
destruction; it is not a complete inventory of third-party RC clients. The
existing movable-root retirement fixture remains useful and stronger than the
example on relocation, but does not certify every callback or host-lifetime
interleaving. No new supported concurrent RC API is inferred from exported
function pointers.

## Experimental Combination, Not A New Collector

[Root registry QNT](../../models/experimental/root_registry_callback.qnt)
imports `vm_list_reader_retirement` unchanged. Logical deletion closes admission
but retains storage until the modeled scanner's last slot use. A same-owner
trusted callback can request deferred deletion and return without relocking;
an external deleter follows the normal after-scan path.

This is a conservative last-use protocol, not an assertion that OCaml always
retains every slot until callback return. A scanner that no longer needs a slot
may have an earlier legal release point; that requires its own actual last-use
argument. Registry nodes, root-slot storage and the Scheme value are distinct.
Physical moving collection and root-value mutation are not modeled here.

The controls omit one condition at a time: recursive relock deadlocks; another
thread borrowing the scanner's depth acquires false authority; logical deletion
treated as storage lifetime permits a live reader to see freed storage. Positive
witnesses must complete both same-owner and ordinary external deletion. The
[Lean contracts](../../models/experimental/lean/RootRegistryCallback.lean) keep
owner-specific deletion separate from insertion and reuse `WorkAccounting`'s
root/mutation distinction.

This extends the [participant/publication study](participant-exit-publication.md)
at a previously unspecified callback/last-use boundary. It does not turn a
blocking metadata wait into GC service, introduce arbitrary finalizer callbacks,
select a Gambit lock, or change its root ABI. Promotion still needs concrete C
ordering, legal callback effects, root completeness, failure cleanup, native
stability and matched cost evidence.

### Same Model, Global-Scan Resume Projection

`initScanPhaseFixed` adds a separate phase projection to this existing model.
Two abstract domains park before the global scan and may write root payloads
before parking or after the global scan completes. It does not serialize writes
from different domains, claim same-slot writer safety or add a root-value
barrier. `initLocalScanAsGlobalCompletion` drops only the global completion
condition from resume: a local completion can then admit a payload writer while
global scanning is active. `noPostScanMutation` is a reachability control showing
that the corrected protocol permits mutation again, rather than making safety
vacuous by parking every mutator forever.

Local-root readiness at a resume decision is a premise of this projection;
local-root enumeration and its completion events are not represented. The
omission control isolates the case where local work is ready but the global
scan is not. It does not assert that the implementation starts global scanning
only after all local scanning or proves the actual local-root census complete.

The Lean companion separates local completion, global completion and independent
domain entry ownership. This extends the phase/exclusion premise only. Registry
last use, complete roots, physical relocation, reader reload and C ordering
still require their existing models and actual source bridges. The two-domain
finite abstraction is not a configured machine-worker count.
