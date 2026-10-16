# Foreign Wait, Relock And Physical Frame

## Review Before Changes

| Question | Decision |
| --- | --- |
| Relevant? | The current image-bound incident faults at JUMPRET after os-condvar-select. The source restores a physical frame slot, not an independent saved scalar. |
| Already explored? | The imported FFI model checks caller publication/reload but not actual slot copying, break-frame selection, C lock waiting or borrowed local roots. Do not rerun its unchanged controls or reapply the existing wrapper. |
| Worth checking? | Yes. A C spin-to-GC change could resolve a conditional wait cycle while invalidating C locals. Check both obligations together before implementation. |
| Expected benefit? | Reject incomplete repairs and focus source correspondence. No quantified runtime speedup, reduced investigation cost or current crash cause is established. |

## Source And Scope

The source authority is the pinned submodule plus the complete
`darwin-ticket-ownership-acquire` source lock and overlay. Baseline source
anchors in the Evidence view are explicitly baseline anchors, not substitutes
for the changed candidate or generated C. Native mapping is independently
bound through `kernel-return-symbolization.json`.

The caller has the existing FRAME_STORE_RA / W_ALL / C call / R_ALL /
FRAME_FETCH_RA sequence. `move_continuation` copies the interval from published
FP through the break frame backwards into a new stack area, then
`prepare_mem_pstate` publishes the new FP. The model executes this bounded
copy over physical slots, including ordinary and break-frame branches.
The special invalid placeholder -44 is a sensitivity value from the incident,
not evidence that the real collector omitted a copy.

`os_condvar_select` keeps Scheme values in a local condvars array, releases its
queue around device_select, reacquires it and uses those local values. The
model contains one representative borrowed root. It deliberately assumes a
second queue owner can request GC while the caller needs that queue. Whether
the actual queue ownership and sync path permit this cycle is **unproved**.
The `devices == #f` wait has no such queue reacquisition and must not be
explained by this cycle. No GC invocation was found in the inspected direct
device-select body; device callbacks and platform paths remain separate.

The closed protocol assumes root preservation/rebinding for the local C root
when joining GC. This is a design requirement, not a source implementation or
permission to inject a private hook. It does not identify a public root API,
prove native pointer/device lifetime, or cover all C array entries/layouts.

## Checked Result

The existing sealed framework exhausts **40 distinct / 50 generated states,
zero queued**, with safety and weak-fair completion PASS. The three controls
produce invariant violations: C wait without participation, participation
without C-root protection, and missing ordinary return-slot copy. The whole
source/producer-bound run took **29.253 seconds**. Its first parse failure
(reserved local binder `length`) is retained separately.

This does not prove that any of the three controls occurs in current Gambit.
The full native stress DENY remains open. Source fixes must establish the
missing reachability/root/slot correspondence first; no unchanged native
stress retry or bootstrap is authorized by this model result alone.
