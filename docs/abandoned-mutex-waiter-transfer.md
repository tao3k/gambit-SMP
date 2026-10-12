# Abandoned Mutex Waiter Transfer

## Source-Shaped Question

The nonqueued SMP mutex slow-path repair preserves prior abandonment.
Queued acquisition returns through `##mutex-signal-no-reschedule!` instead.
This function reads the caller's saved new owner, locks that target, and marks
the mutex abandoned when the target has terminated. However, its final resume
thunk currently depends only on incoming `abandoned?`, which describes the
previous owner's release. A normal previous-owner unlock can therefore select
the success thunk despite the new owner's termination. This is a separate
source branch, not established by the earlier nonqueued native result.

## Model And Assumptions

`abandoned_mutex_waiter_transfer.qnt` represents one queued caller, a distinct
requested new owner and a previous mutex owner. It checks target death before
transfer, previous-owner abandonment and normal unlock. Target-state inspection
and transfer are atomic under the assumed primitive-lock contract. Caller
resume must preserve both sources of abandonment. Old `transferSafe` and
`outcomeSafe` controls must fail independently; positive completion requires the
explicit finite-model fairness assumption.

No native result or source repair is claimed by model creation. The actual
fixture must establish that the caller is queued on this mutex before target
termination; relative sleeps are not a synchronization proof. Runtime GC roots,
multiple queued callers, cancellation, priority inheritance and primitive-lock
progress remain separate obligations. Existing bootstrap source stays frozen.
