# Cross-VM Resize Progress Audit

## Evidence Boundary

This audit does not identify the cause of the native long-run stalls and does
not qualify a source repair. The shared Python framework is frozen for the
complete graph task. No source lock, recipe budget, or model admission changed.

The selected source is the resize-grace fixture, reconstructed through
`evidence/fixtures/vm-registry-reader-lease/resize-grace-source.lock.json`
and `patches/fixtures/vm-registry-resize-grace.patch`, not an arbitrary cached
checkout. Audited bytes:

| Input | SHA-256 |
| --- | --- |
| `lib/setup.c` | `9d028d74abdf9efa98e9f8616ffeb6a6b66aeedd63ccbee91ed5731b1c41c2a2` |
| `lib/os_io.c` | `e17daf7fb752e9eb85b8b6e6e4672d81ae05435332392cff273ceaf6f5f223fa` |
| `models/gambit/vm_registry_resize_grace.qnt` | `b25e5c4fa1728f9e4d24c34b55b8094b51fdf3d6511cb13ef9c5778edc19eaca` |

## Source Findings

1. In `lib/setup.c`, processor zero handles `OP_SET_PROCESSOR_COUNT` after
   the old processors arrive. Shrink takes `vm_list_mut`, closes global
   reader admission, drains outstanding reader leases, publishes the new
   count, reopens admission, unlocks, and replays deferred interrupts.
2. The interrupt reader path does not acquire `vm_list_mut`. Delivery calls
   `___raise_interrupt_vmstate`, then `___raise_interrupt_pstate`, then
   `___device_select_abort`. A claimed reader/writer mutex inversion would
   need another source edge; these calls alone do not establish one.
3. Under the POSIX asynchronous-select configuration, `lib/os_io.c` sets
   both pipe endpoints nonblocking during setup. Abort writes one byte and
   ignores its error. Pipe fullness therefore is not evidence of a blocking
   write in a successfully initialized processor. Initialization failure and
   endpoint lifetime still require their own proof.

## Model Requirements Still Open

Existing model coverage was checked before proposing a new model:

- `vm_registry_repeated_retirement.qnt` covers two registry generations,
  two signal requests, atomic reader admission and replay ownership. It has
  one writer, not two independently resizing VMs. Reuse its admission and
  replay obligations rather than treating repeated mutation as unexplored.
- `vm_retirement_join_composition.qnt` composes retained sender/receiver
  resources with joining two incarnations of one slot. Its temporal property
  assumes weak fairness and a transient failed join; it does not arbitrate
  two VM owners on the global writer mutex.

The missing composition is therefore independent VM resize ownership over
the shared registry gate, not a new implementation of either existing model.

The resize-grace model explicitly represents two processors in one VM, one
interrupt reader and one shrinking barrier. Its `noStall` predicate is
`terminal or enabled(step)`: this excludes a state with no enabled transition,
but does not exclude infinite executions that postpone an owner's completion.
It is not a fairness or bounded-latency theorem.

The complete chain therefore still requires:

| Requirement | Condition needed before claiming completion |
| --- | --- |
| Multiple writers | At least two independently resizing VMs sharing the registry gate and writer mutex; preserve each VM's barrier membership. |
| Repeated cycles | Grow, shrink, replay and join must return ownership to the next cycle without borrowing another VM's completion. |
| Signal interleavings | Admission failure, pending-bit publication, reopen and replay must compose across writers and readers. |
| Progress | State scheduler and OS-join assumptions explicitly; check temporal progress or a justified finite progress bound, not only `enabled(step)`. |
| Source refinement | Bind atomic operations, barrier ordering, endpoint lifetime and join outcomes to the exact source fixture. |
| Native coverage | Complete all planned 2-5 VM populations under the unchanged budget; retain censored runs and unknown percentiles. |

For an initial finite composition, two writers and two completed resize
cycles per writer are topology witnesses, not hardcoded host CPU limits.
Native population and processor counts must continue to come from available
CPU capacity. Finite progress can use a strictly advancing phase measure
only if every nonterminal transition advances it and reader requests, OS
joins and barrier arrivals have explicit bounds. Such a measure must not
silently turn an unbounded interrupt stream or failed join into a finite
successful operation. A subsequent temporal composition needs the relevant
fairness assumptions and failure outcomes instead of suppressing them.

## Diagnostic Receipt

The `smp-bazel-profile-topology-stack-observation` run ended DENY because
`resize-safe-progress` verification exceeded its original 15-second step
budget (15.038536667 seconds, exit -9). `independent-vms` was BLOCKED by that
dependency. No native executable or stack sampler ran. This is a checker
budget failure, not a newly observed native deadlock or a successful stack
diagnosis. Do not rerun identical input merely to seek a passing schedule.

The earlier baseline and successor native latency timeouts remain separate
observations. Neither establishes full-population P55/P99, and their partial
sample counts do not establish a speedup.
