# Interrupt Callback GC And Exit Composition

## Source Window

In `lib/_thread.scm:##other-interrupt!` and
`##thread-resume-execution!`, the result mutex's thunk runs before the
`specific` field is updated and the mutex unlocked. The thunk can allocate,
collect or raise. Thread termination abandons its owned mutexes. The previous
queue/result model represents successful dispatch as a single transition;
it cannot observe a collection or failed callback between dequeue and result
publication. This is a stated abstraction gap, not a new runtime bug report.

## Direct Model Composition

`interrupt_callback_gc_exit.qnt` imports the existing queue/result state and
actually executes its extraction, propagation, peer delivery and result
observation actions. It replaces the atomic successful A dispatch with callback
begin, return and throw actions. During callback execution, the result remains
target-owned and the payload requires a callback-stack root even though A is
no longer linked in a queue. An early success cannot resolve a still-running
callback; a failed/terminated callback must abandon the result.

Three controls omit the callback root, publish success early or treat a thrown
callback as successful delivery. They are hypothetical sensitivity controls,
not actual C fault injections or previously reproduced source failures.
Primitive termination/abandonment, tracing, lock release and exception routing
remain source-refinement assumptions. Collection is one abstract event, not
physical address forwarding or a full strong/weak epoch.

Progress retains explicit weak-fair scheduling and terminating primitive
assumptions. Cancellation, multiple requesters, nested/foreign callbacks,
processor retirement and complete native acceptance remain OPEN. A passing
model cannot discharge these conditions or replace actual callback/GC tests.
