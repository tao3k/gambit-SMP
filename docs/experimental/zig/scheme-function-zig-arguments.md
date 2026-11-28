# Conditional Arguments for the Real Function Path

Reviewed: 2026-10-20. Handwritten implications and logical counterexamples,
not machine-checked proofs, simulated schedules or native witnesses. Read the
[design](scheme-function-zig-design.md),
[evidence](scheme-function-zig-evidence.md) and
[economic matrix](scheme-function-zig-cost-matrix.md).

## Conditional Proof Obligations

| ID | Assumptions | Argument / exact conclusion | Still required |
| --- | --- | --- | --- |
| SP01 | Stable finite proper input, checks enabled, forcing disabled, admitted primitives, successful allocations and no input mutation during services | After k iterations x is the kth input tail; acc contains fresh copies of the first k elements in reverse order. Pair construction and cdr advance preserve the invariant; null at k=n returns the reversal. | Actual normalization/emission refinement, identity, service/error/control domain; induction is not a complete compiler proof. |
| SP02 | Semantic completion records actual selected order and features; runtime services preserve the required control/effect trace | Replace each completed operation by an admitted provider realization with matching normal/exceptional edges. Composition preserves that chosen trace, including the two diagnostic paths and polls. | Macro/declaration domain and operation refinements. A proof for no forcing does not extend to enabled forcing. |
| SP03 | No-handles pair, h≤L, L+3≤b, valid minima/provenance/alignment and actual storage rights; no hidden allocation/safepoint; metadata needs no allocation inside construction | Header and body writes occupy offsets 0,1,2, cursor advance forms h+3. W=P=delta=3, so isolated B=3 stays within b; post-cons predicate may now take the slow edge without having exceeded b. | Actual binding at every entry/return and target layout, full span containing any additional events; no inference from CHECK_HEAP's 4096. |
| SP04 | Before every collecting/control edge all live references/control state are materialized in admitted scanner locations; complete acc_new is rooted; no subsequent old derived pointer is used | Collector traversal reaches the new result and live input; relocation writes current roots, resumed execution reloads roots and allocation binding. Therefore that edge neither loses the live result nor uses its pre-move address. | Independent root oracle versus map and actual root publication/scanner synchronization. Current scanner arrays may require valid values in semantically dead slots. |
| SP05 | DispatchHostProfile fully governs all entries/exits; local tail iteration is a loop; each external transfer returns through bounded native activations before next dispatch | Induction over tail transfers keeps bounded native call depth for this body. Non-tail force retains a Scheme frame; capture/throw restores explicit Scheme state rather than native stack frames. | All arity/error/helper/FFI/continuation edges, dynamic-wind/multiple-value semantics and no cross-Zig nonlocal C escape. No throughput bound follows. |
| SP06 | Every required point/frame/constant/import has a valid product record; runtime binds correct VM identities and retains code/maps before callable publication; initialization effects follow their declared dependency policy | Any published reverse procedure resolves entries/resumes/constants through its live matching binding. Unload waits for every continuation/callback/global/init user, so published users cannot target freed code under these assumptions. | Independent decoder and caller/domain closure, concurrent VM initialization, cyclic/reentrant initialization, actual failure ownership. Not proven by sizeof checks alone. |
| SP07 | Completed semantic graph supplies all former C scanner decisions; selected Zig route never invokes old dumper, metadata query or generated Scheme-host C | The route can delete those generation/preprocessing obligations without changing their semantic authority. Retained C runtime/FFI is explicitly outside this retirement. Global deletion requires no remaining callers in the whole declared cohort. | Dependency census, complete replacement behavior and future independent native qualification. A single function cannot retire all of _std or a global header. |
| SP08 | Same admitted capabilities and lifetime workload for modern C and Zig; common savings credited once; bounded residual savings exceed all incremental costs and risks | The lower bound of Zig's incremental net is positive. If either bound is missing, this implication has no accepted economic conclusion; modernization's common benefits remain a separate decision. | Residual support/caller census, bounded maintenance events and horizon, target/ABI/tool/control costs, real retirements. No positive bound is issued here. |

## Logical Counterexamples

Each row is a falsifier to investigate, not a report of a reproduced failure.

| ID | Counterexample | Broken obligation / consequence |
| --- | --- | --- |
| SX01 | Compile the unchecked primitive's body as public reverse. | Omits proper-list diagnostic distinction; returning the copied prefix on dotted input is not public semantics [SP01/02]. |
| SX02 | Treat macro-force-vars as a no-op for every configuration. | Enabled force can run arbitrary Scheme, allocate/capture/fail; graph and roots are incomplete [SP02/04/05]. |
| SX03 | Invent left-to-right ordering from the source sibling arguments, or reread car after a newly inserted GC/poll. | Can change input observations, failure and finalizer traces. Source order and artifact schedule require separate justified choices [SP02]. |
| SX04 | Native recursive Zig loop calls are expected to optimize at -O. | Proper tail semantics now depend on optimizer choice; long loops can grow stack. Required tail calls reject or use the separately selected dispatch profile [SP05]. |
| SX05 | A tail-host module returns a dispatch disposition to an old nonreturning bridge. | Different host protocols compose incorrectly even if each body's local loop looks correct [SP05/06]. |
| SX06 | Use only hp≤L, with no actual three-word headroom. | Post-cons writes may exceed the admitted native extent before the predicate runs [SP03]. |
| SX07 | Attach an allocating metadata helper inside cons, but retain B=3. | Hidden allocation invalidates the isolated bound and may expose a partial pair [SP03/04]. |
| SX08 | Spill roots after the helper that allocates the spill buffer. | That helper can collect before x/acc is protected; the later map cannot repair a lost reference [SP04]. |
| SX09 | Keep orig only in an unregistered Zig local because x already traverses the list. | Original diagnostic identity is missing at an error/GC boundary; completed prefix does not retain the original input spine [SP02/04]. |
| SX10 | Resume heap slow path by replaying cons or restoring old hp. | Duplicates an already completed object or writes into an obsolete section/moved layout [SP03/04]. |
| SX11 | Omit polling because reverse's local tail loop is now native. | Changes preemption/interrupt opportunities; tail correctness alone is insufficient [SP02/05]. |
| SX12 | Map Scheme exceptions to Zig error return and let a C helper longjmp over Zig defer. | Loses Scheme handlers/dynamic state or bypasses native cleanup; no valid cross-language control protocol [SP02/05]. |
| SX13 | Link old numerical labels into new PointId tables and publish before maps/constants are held. | A continuation or GC observes stale/unresolved identities, even when code linked successfully [SP06]. |
| SX14 | Abort init by freeing image storage after a callback/global has escaped; or hold a nonreentrant lock across Scheme init. | Respectively use-after-free or reentrant deadlock. A failed initialization flag is not exclusive custody [SP06]. |
| SX15 | Region-free the output when the Zig host returns; or infer higher-order optimization from LLVM's presence. | Escaping reverse output remains live; code-generation services do not prove escape/effect facts [SP01/04, SF21]. |
| SX16 | Count removed macro generation as Zig-specific while C-G uses the same descriptors/typed generator; omit long-lived C islands and Zig upgrades. | Double-counted common benefit and missing incremental cost can turn an actually negative comparison positive [SP07/08]. |

The graph, conditional reasoning and byte counts make the design reviewable.
They do not close Q-full-runtime-contract, Q-full-semantic-provider-domain,
Q-full-retirement-closure, Q-full-total-cost or Q-full-zig-increment. AG05/AG06
remain economically unaccepted and AG07 native qualification remains unrun.
