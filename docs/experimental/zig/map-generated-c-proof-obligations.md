# Map: Conditional Arguments and Falsifiers

Design arguments only, not machine-checked proofs or executed cases. References
resolve through the [evidence ledger](map-generated-c-evidence.md) and
[design](map-generated-c-design.md). Their purpose is to expose hidden premises
before implementation rather than award native acceptance to document checks.

MA01. **Call/root completeness.** Assume every collecting/control-transfer edge
has a completed point; each semantically live managed value has a traceable
home or an admitted callee/foreign carrier; every relocation rewrites those
homes and resumed code reloads them. Then induction over a call/resume sequence
preserves each value used by map after the transfer: current pair/proc after
callback, pending result after recursive work, and original arguments on checked
failure. Descendant frames and environments are transitively scanned. This
depends on all helpers, runtime roles and foreign entries, not merely the 22
stored descriptors. Counterexample: result exists only in a native temporary
across recursive GC; a valid-looking return label resumes with a stale pointer.
[MC04–MC10, ME04–ME08]

MA02. **Frame-reader agreement.** Assume the constructor, active/captured-frame
scanner and restoration code interpret the same kind, size, link, map, actual
return point and code identity. Normal and internal entries then preserve frame
boundaries and root classification through capture/movement/restore. Current
RETI handling expands caller size and has a separate actual return address.
Counterexample: decoding RETI fs=8 as a RETN-sized frame gives the wrong base,
link and next frame even if the gcmap literal is copied correctly. Same-size
frames with maps 0x7 and 0x9 are not interchangeable. [MC06–MC07, ME05–ME08]

MA03. **Allocation/check completion.** Assume the whole uninterrupted write
interval fits admitted space B/reserve, no uninitialized object is trace-visible,
and slow paths distinguish not-yet-performed from already-completed allocation.
Then movement/retry resumes with the same one completed pair and valid fields.
Stored L5/L7 resume after CONS; L20 after list-of-lists construction. A post-check
cannot jump back before CONS without replay semantics. Counterexamples: charge
only pair payload while forgetting header/alignment/boxing; publish partial
pair; reexecute CONS after GC; reload an old raw field address after movement.
Allocation failure/overflow retains explicit source/destination custody and
does not promise rollback of published state. [MC08, ME02, ME04, ME06–ME07]

MA04. **Higher-order/control equivalence.** Assume unknown callback effects are
conservative, order/value/check behavior is preserved in the selected profile,
captured frames preserve pending values, and dynamic transfers use admitted
wind/exception rules. Then replacing physical host/layout construction does
not change map's observable results and control transitions. Counterexamples:
parallelize arbitrary callbacks; interpret a callback's #f as the map-tail error;
freeze mismatch policy despite its setter; replace multi-shot continuations by
one-shot fibers. The standard's input-mutation error domain cannot be used to
claim an additional implementation-preservation profile passed. [ME01–ME02,
ME08, MP03, MP05]

MA05. **Repeated return and regions.** Assume each invocation can reconstruct
its still-pending output construction without mutating an already returned list,
and retained frames/root/code remain live. Then multiple continuation returns
can coexist with the original result graph. A callback can store its captured
continuation globally and return; a later invocation resumes the pending map
work after the original map returned. That is a falsifier for freeing every map
temporary at the first return, or destructively reusing an output accumulator.
A nonescaping/no-capture specialized region may be lawful only after proving
the callback, aliases, native escape and reentry conditions; general map does
not supply those premises. [MC10, ME07–ME08, MP05]

MA06. **Module/control lifetime.** Assume code/descriptors are registered before
any executable entry becomes visible, and retained until all procedure/frame/
callback/task/reader references are gone. Then the mapping from a reachable
return point to its code and root map remains valid across suspension and
capture. Counterexample: map returns, module unload frees labels, later callback
continuation resumes L2. A source digest or root handle alone does not retain
code. Setup failure after publication cannot free tables while a scanning
reader holds them. [MC11–MC13, ME07, ME09–ME13]

MA07. **Binding and partial failure.** Assume per-instance progress and owned
relocation/registration, explicit import/init order, and a failure protocol for
each externally visible transition. This can separate reusable products from
live instances without conflating prepared with active. Existing flag setting
before fallible checks does not establish this invariant. Counterexamples:
failed setup leaves a shared done flag and a later VM skips validation; a
reentrant initializer sees an instance as active too soon; retry duplicates
native side effects. User initialization can escape or affect external state,
so universal transactional rollback is not a premise. [MC12, ME10–ME11]

MA08. **Modern collector closure.** Assume complete young-edge remembering,
major-root/SATB publication, typed weak processing, capacity/forwarding safety,
worker termination and FFI participation. Then map's long-lived pending results
and captured frames can survive young promotion and major collection under the
new algorithm. Point/map extraction alone proves none of these premises.
Counterexamples: a mature captured frame receives a young object via unlogged
restore; a blocked native caller retains an unregistered movable reference;
a collector worker scans a mutator's live registers without an acknowledgement.
[MC14, ME12–ME13]

MA09. **Quantitative benefit.** Equal semantic work with less repeated mature
copying can reduce GC work, but only if barrier/root/phase/promotion/memory
overheads do not consume the saving. The ratio in MV03 states this condition
without inventing a workload. Map callback cost can dominate; an empty list or
objects surviving just one copy can offer no such saving. A new renderer can
also increase native C frontend work. These are genuine negative cases, not
failures to implement enough code. [MV03–MV04, ME12, MP02]

MA10. **Backend isolation and retirement.** Assume completed graphs are bound
to their semantic/profile inputs, every selected consumer uses the new plan,
and no hidden old scanner computes required roots/checks on its behalf. Then
the old responsibility can retire for that cohort once independent equivalence
and native obligations are satisfied. Counterexamples: MLIR clones a call but
keeps its old point/root plan; the new emitter calls old targ-gen-jump to decide
meaning; map host changes but `_std` still requires the old dump to bind it.
Keeping declared physical C leaf macros does not itself violate isolation;
keeping duplicate semantic inference does. [MC03, MC06, MC15, ME03–ME11, MP06–MP07]

Each premise has an actual producer and reader obligation. A future independent
qualification plan must cover normal return, recursive GC, callback capture and
repeated invocation, poll capture, errors/wind/value delivery, both map arities,
helper failures, foreign block/reentry, module setup failure/reentry and final
code/root withdrawal. No such cases were executed here. RootRegistry,
BarrierLog and ReleaseCoordinator supply parts of these premises but are not
three interchangeable implementations of the same state machine.
