# Interrupt Requester Cancellation Composition

`lib/_thread.scm:##thread-intr!` assigns the result mutex to the receiving
target, then waits as the requesting thread. These roles are distinct.
`##thread-end-locked!` abandons queues owned by the terminated thread; the
target's result ownership cannot be discarded merely because its waiter exits.
Waiter removal and later result unlock/wakeup must also exclude a dead requester.

The QNT composition executes the existing queue/result actions. Callback
begin/return/throw use the split source projection of `interrupt_callback_gc_exit`,
extended with separate cancellation request, waiter unlink and termination
commit transitions. Result observation can race with a cancellation request
before unlink; a historical wake is distinct from a wake after termination.
The wake exclusion starts at waiter unlink, not only at termination commit:
the detached waiter is no longer eligible for the original result-queue wake.
An explicit control observes that intermediate window before termination.
Terminal requires an initiated cancellation to finish rather than being
silently dropped when the callback returns. Trylock/retry and physical memory
ordering remain abstraction premises. Controls
drop result lifetime, wake a canceled requester or mistake waiter cancellation
for target-owned mutex abandonment. Physical tracing, waiter unlink atomicity
and ownership publication remain assumptions requiring native/source evidence.
Processor retirement, generations, weak/strong phases and full acceptance are OPEN.

The initial nested import accessed private `C::I` bindings and was rejected
before model checking. No checked parent was changed to expose internals.
The corrected model imports the queue/result module directly and explicitly
defines callback lifetime beside cancellation. The callback model is a context
reference, not falsely claimed as an executed module dependency.
