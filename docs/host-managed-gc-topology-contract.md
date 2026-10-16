# Host-Managed GC Topology Contract

## Framework Gap

The standalone executable capability previously started every fixture with p1.
That is intentional for independently constructed VMs, whose fixture divides
available CPU capacity across its cohorts. It is not sufficient for existing
single-VM GC controls requiring five or six simultaneously placed protocol roles.

`processorTopology` now distinguishes `fixture-managed` (unchanged default)
from `host-managed` (the existing available-CPU capacity planner). Both
compilation and execution populations are recorded. No fixed machine core
count or lower-workload replacement is introduced. Optional
`executionBudgetSeconds` is nested within the original step deadline and cannot
extend it. Optional `stderr` requires exact bytes, not substring acceptance or
ignored warnings. Absence still requires zero stderr bytes.

## Retained Actual Denial

`smp-vector-arity-root-cohort-resize` ran with the current completed producer
through engine `7fe0214bb89a4324bf7001181526357cb47f9194aa7fd4689ece99683fc88f6e`.
Whole outcome is DENY, 53.541884 seconds, no timeout. QNT fixed safety and
missing-root/stale-reload negative controls passed. The native controls used
the original unchanged source and 30-second execution caps:

| Control | Compile | Execute | Exit | Framework outcome |
| --- | --- | --- | --- | --- |
| Moving-root cohort | 2.696424 s | 0.498642 s | 0 | DENY: undeclared exact two-line stderr trace |
| Resize/GC lifecycle | 1.204542 s | 0.551686 s | 0 | DENY: stdout also contains resize events |

These are not native acceptance passes. Both original assertion bodies and
their transcripts are retained. A nonzero assertion or unexpected warning
must still fail. The root fixture explicitly emits exactly two
`TRACE:gc-wait-cohort:gc-request` stderr lines. Resize output contains
capacity-derived transitions and nondeterministic valid caller IDs; it cannot
be accepted by copying one observed transcript or ignoring all prefix lines.

## Successor Closed Loop

`smp-vector-arity-root-cohort-reviewed-transcript` now passes and reads CURRENT:
74.702990 seconds whole under the unchanged 300-second budget. Exact source,
completed producer and both original assertion bodies are unchanged. The
successor declares the root fixture's exact stderr bytes and the resize event
contract; no output is silently discarded.

| Control | Compile | Execute | Processors | Outcome |
| --- | --- | --- | --- | --- |
| Moving-root cohort | 2.654993 s | 0.688532 s | 11, host-derived | PASS |
| Resize/GC lifecycle | 1.413537 s | 0.548885 s | 11, host-derived | PASS |

The resize Evidence review consumes 169 decoded tokens, with zero unexpected
tokens and zero missing cells. It took 8.633879 seconds separately from native
execution. The flat-event decoder only transports row/column/value facts;
Scheme DSL owns matching and missing/extra negation. The data contract binds
initial shrink, each population-derived grow/shrink pair, final restoration,
valid processor caller IDs and exactly one final completion record.

`native_transcript_admission.qnt` checks complete positional admission and
retains bypass counterexamples; the composed root model checks fixed safety
plus missing-root and stale-reload counterexamples. Real ASCENT unit controls
reject omission, extra events, order swaps, wrong population, out-of-range
callers and duplicate completion. The decoder cannot evaluate Scheme source.

Engine:
`b8a66c4851343a664b2e720982fd3a35b09655f98d43884377c189fea06eb593`.
Outer receipt SHA-256:
`414632ac47fd4a7738904ec4ecd7baf9b6c5eb8e7ccb180516df57d55cab1221`.
Child receipt SHA-256:
`e2207b7f511b108bbdd5e10df95cdb342b03259769d005843779fff0cb27cfeb`.

## Remaining Qualification

The exact stderr and typed resize transcript interfaces have now been qualified
on the successor sealed native campaign. The original DENY remains retained.
These two controls do not cover every foreign-frame/forwarding/root transfer,
injected join failure, setup reentry or concurrent retirement requirement.
Current milestone remains 3/12; full GC/FFI and lifecycle gates remain open.
