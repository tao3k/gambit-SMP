# Retired RC Exit-Tail Boundary

## Refutation Before Runtime Editing

The earlier quiescent-root handoff design requires a real donor quiescence
witness. It must not be implemented as an unconditional flag immediately
before `___thread_exit`. The selected `lib/os_thread.c` calls `pthread_exit`;
POSIX executes cleanup handlers and thread-specific destructors during exit.
See the [primary pthread exit specification](https://pubs.opengroup.org/onlinepubs/009696899/functions/pthread_exit.html).

Gambit's own fallback TLS key is created with a NULL destructor. This audit
does not claim that Gambit itself installs a root-mutating exit callback.
Foreign callbacks retaining or registering RC handles form an explicit FFI
boundary: determine whether they are admitted during retirement, not merely
assume they have stopped. A successful join covers exit completion, while a
failed join or an earlier checkpoint does not supply that witness.

## Executable Composition

`retired_rc_exit_tail.qnt` imports the actual transitions of
`retired_rc_gc_visibility`, not only its conclusions. It adds exit entry,
a callback registering another donor root and acknowledgement timing.
The pre-exit-ack policy has a counterexample after root handoff. The positive
policy acknowledges only after callback completion; this remains an abstract
required condition, not an implemented POSIX observation mechanism.

The native fixture uses standard pthread TLS/destructors and atomic simulated
root values. The actual byte-locked `___thread_exit` function is projected from
the selected source via `source.project`, checked by `source.bind`, and compiled
with `native.workspace-build`. No function copy is hand-maintained, no join
failure is injected, and no private cleanup or `RTLD_NEXT` path is used.

Workers derive their population from `GAMBIT_SMP_AVAILABLE_CPUS`, supplied by
the framework's current available-processor query. They publish a checkpoint,
then actually call the projected exit function. TLS destructors subsequently
change their data. The safe control joins before reading final data. The
unsafe control copies before exit and observes the mismatch after joining.
All memory used for this observation is atomic; the control does not induce
undefined memory races to manufacture a failure.

## Actual Results

Recipe `retired-rc-exit-tail-model-native` passed twelve required steps in
24.940416 seconds under the original 300-second budget. Safety and enabled
progress each explored 19 distinct / 24 generated states, zero queued.
All seven declared main/imported trajectories passed, with the required
pre-exit-ack counterexample.

Native build: 0.172881 seconds. Safe case: 0.634891 seconds, exit zero.
Unsafe case: 0.005850 seconds, expected exit one and exact
`PRE-EXIT-ACK:EXPECTED-VIOLATION` output. Both returned without timeout and with
reaped/quiescent groups. The exit-one result is a declared negative control,
not a runtime pass or an ignored failure.

Outer receipt: `2b856ffc1d35a3d4a6ef93745b7b67a0fe47cc63e5d536f29d16949daa8ec9f1`.
Child receipt: `017eb73fcf7350d59c67a0f4345afb0674fc9a07092ae4f63c33692cce5a1ba4`.
Engine: `3191f03770635de2d1acecd8dee1d19b1305488ab17b3f9c565c6fb1916b6c5a`.
This uses the new v2 seal only for bounded diagnostics. The full consumer/
105-review/current graph for v2 has not qualified; shared generations are
hash/identity checked, not a portable or absolutely immutable sandbox.

The first proposal was rejected before execution because `native.c-build`
is not admitted in the new research lane. It was replaced by the existing
typed source projection/binding interface; no policy was relaxed. The shared
framework freeze was respected, then explicitly released after its parent
terminated. No Gambit bootstrap or completed-runtime copy was created here.

## Next Repair Obligation

Do not insert the rejected pre-exit acknowledgement into the runtime.
Choose and model a source-enforced RC ownership/admission protocol that covers
the complete supported exit tail, or establish a genuine complete-tail witness.
Specify foreign callback eligibility and permanent join-failure behavior.
The actual failed-join/post-GC regression, full source refinement, complete
GC/FFI and lifecycle acceptance remain open. The native POSIX control proves
ordering only, not a reproduced Gambit heap failure or an admitted SMP repair.
