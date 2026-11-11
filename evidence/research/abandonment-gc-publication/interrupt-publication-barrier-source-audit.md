# Interrupt Publication Versus Barrier Participation

## Bound Observation

Source lock:
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
The original compiled `thread_interrupt2_stress.scm` did not complete.
Its parent driver and busy child were stopped; no passing completion marker
or original-budget qualification was produced. The retained run is DENY.

The one-second OS sample recorded 809/814 main-thread samples in
`___raise_high_level_interrupt_pstate`, with two peer threads in
`barrier_sync_op` / `_pthread_cond_wait`. The sample does not reveal the
barrier operation kind or the ticket owner.

## Source And Static Instruction Mapping

In this candidate's `lib/setup.c`, `___raise_high_level_interrupt_pstate`
begins at line 364. Its first critical operation is:

```c
___PRIMLOCK(ps,___FIX(___OBJ_LOCK1),___FIX(___OBJ_LOCK2))
```

The generated `include/gambit.h` maps that SMP macro to
`___TICKETLOCK_LOCK2` on the processor Scheme object's two lock fields.
Static `nm` and `otool` inspection of the sampled build maps the sampled
function offsets +32/+36 to this acquisition loop, before queue publication:

```asm
ldapr x2, [x3]
cmp   x4, x2
b.ne  <same load>
```

This locates a ticket-service wait, not the later queue splice or interrupt
notification. It does not identify who reserved or owns the preceding ticket,
whether a lock owner parked, or whether the barrier is a GC, startup, resize
or another collective operation. No debugger, injected loader, interposition
or memory mutation was used for this observation.

## Source And Model Obligations Still Open

- Establish the ticket owner's identity, initialization and lifetime conditions.
- Establish the actual collective operation and each participant's role.
- Audit all callers and both acquire/release sides of this processor-object lock.
- Model interrupt publication together with those observed lifecycle/barrier
  conditions. The existing abandonment model excludes this C primitive-lock path.
- Use a source-bound native regression to distinguish hypotheses; neither the
  sampled loop nor the finite abandonment PASS proves mutex or tgroup causality.

The completed bootstrap and three completed compiled tests remain observations,
not full native acceptance. The widened draft budgets disqualify that run from
original-budget acceptance; the current Recipe restores the original windows.
No unchanged full-suite repeat is justified by this source-location result alone.
