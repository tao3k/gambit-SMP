# Interrupt Delivery GC Root Obligation

## Native Evidence Gap

The existing `models/gambit/native/interrupt_delivery_result_composition.scm`
keeps `payload` in `check-path` and captures it in both thunk closures. Its
post-GC payload assertions therefore do not isolate processor/thread queue
reachability. The receipt remains useful combined delivery/abandonment evidence,
but cannot qualify a root scanner solely because those assertions pass.

## Executable Composition

`interrupt_delivery_gc_roots.qnt` imports and executes the existing interrupt
delivery/result transition relation. It adds a collection interleaving across
processor-queue, extracted-local and target-thread-queue ownership windows.
Three control policies omit each root category separately. No unrelated
permanent external payload root is present in this abstraction.

The collector projection assumes the referenced node's transitive result-mutex
and thunk payload graph is traced whenever its owner is scanned. This premise
is precisely what source/native evidence must establish, not an implemented
collector fix. The two-request domain and one possible collection are bounded.
Moving-address forwarding, generations, weak roots, callback exceptions,
requester cancellation, retained dead-thread reachability and processor
retirement are not modeled by this increment. No entire-GC admission follows.

## Source Correspondence Still Required

The pinned submodule's `lib/setup.c:___get_next_high_level_interrupt_pstate`
removes a processor queue head and returns the Scheme object. Its caller
`lib/_thread.scm:##other-interrupt!` retains it while dispatching or propagating
the result mutex. `##thread-intr-propagate!` links a request into a thread's
queue when its target is not running. The semantic candidate overlay repairs
detachment/result behavior; source authority is the pinned submodule plus
`patches/fixtures/abandoned-result-state.patch`, not a cache checkout.

Required native validation must avoid an independent retained payload root,
force collection in each relevant ownership window, validate actual queue
delivery and payload structure, and bind the result to the same candidate.
That fixture has not yet been implemented or executed. This is an acceptance
gap, not a newly reproduced Gambit bug. Existing failures must not be rerun
unchanged or overridden by model-only success.
