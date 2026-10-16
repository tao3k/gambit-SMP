# Compiled Scheduling Path Review

## Existing Failure, Not Another O1 Retry

The original numeric probe retained a 90-second whole native budget. Scheme-to-C
completed in 30.818 seconds; C-to-dynamic-module was killed after 59.250 seconds.
That is a cumulative probe failure, not proof of the complete C phase duration
or an independent 59-second performance requirement. No unchanged compilation
is rerun here and no old timeout is reclassified.

The exact historical invocation already used O1, disabled macro tracking and
explicit `-fschedule-insns2`, `-fmodulo-sched` and
`-freschedule-modulo-scheduled-loops`. Current configuration also enables them.
GNU GCC 16.2.0 `-Q --help=optimizers` confirms those three flags are enabled
when explicitly requested at O1. `configure.ac` attaches them to the shared
object/dynamic flag family; blindly removing them there would also change RTS
compilation, which is not an acceptable unreviewed runtime tradeoff.

GCC describes modulo scheduling and post-register-allocation scheduling in its
[optimization reference](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html).
Their presence identifies actual compiler work, not evidence of its measured
dominance or a guaranteed speedup.

## Four Questions

1. Is the path relevant? Yes, it changes the actual failed C phase rather than
   crediting an unrelated GC repair with C compiler cost reduction.
2. Has it already been exhausted? Existing records establish O1-to-O1 and
   already-disabled macro tracking; the scoped documentation search did not
   locate a measured dynamic-only scheduling comparison. This is not a claim
   that all unindexed historical experiments have been ruled out.
3. Is it worth checking? A strictly scoped diagnostic is reasonable because
   the profile forces extra scheduling work at O1. Keep RTS O3, concurrency,
   arithmetic/aliasing requirements, PIC, ABI and tail-call configuration.
4. Expected benefit? Unknown until phase measurement. No percentage, multiple
   or performance PASS is justified by flag names alone. Runtime code quality
   must be tested alongside compile cost before any release profile change.

## Next Evidence Boundary

Use the existing sealed framework for a current-producer phase observation,
not the historical unsealed compiler-cost adapter or an ad hoc script. Bind the
original fixture, generated C, actual GCC command, each phase exit/quiescence,
original cumulative budget and a real module-initialization/assertion witness.
Compiler-option candidates must be explicitly typed and limited; do not allow
arbitrary command injection, disabling SMP or replacing the default toolchain.
Check unchanged source-emission cost separately from a scheduling candidate.

The existing lower-optimization correspondence must not be waived. A same-O1
scheduling candidate requires its own command-bound eligibility model and actual
causal evidence. A changed binary, shorter earlier phase or model PASS alone
does not establish that C compilation now completes or that full GSC is green.

## Current Frozen-Producer Observations

All observations below use the fdset 23-file frozen producer. The default
complete GSC campaign now uses genuine completed-work inactivity clocks and
observed all twelve groups: 378/379 files accepted. Only `_num.scm` reached
its unchanged 90-second file inactivity limit. The outer supervisor did not
time out; the 125-file group legitimately passed after 392.172 seconds.
See `fdset-frozen-source-qualification.md` for inventory and receipt bindings.

The existing typed compiler-observation capability separately compiled the
original numerical fixture and executed its original assertions:

| Explicit dynamic-module diagnostic | Scheme to C | GCC to module | Execution | Whole attempt |
| --- | ---: | ---: | ---: | ---: |
| Disable modulo, loop rescheduling and second instruction scheduling | 4.925 s | 76.623 s | 0.804 s | 110.897 s |
| Disable modulo and loop rescheduling only | 4.914 s | 80.512 s | 0.629 s | 114.797 s |

The generated C bytes match (SHA-256
`64fcf0f160f6781098920a1028515e0d617f4cecd792cc8d75554f014776518c`).
Both retain O1, RTS O3, GNU GCC, SMP, multiple threaded VMs and original
assertions, with independent 90-second phase windows. The second observation
is not a speedup over the first. These isolated, sequential diagnostics are
not a matched comparison with the concurrent default-profile file timeout;
neither demonstrates that scheduling dominates compile time. In particular,
do not infer a percentage gain from a censored default run, or adopt compiler
flags solely to fit a diagnostic cutoff. No source/release profile changed.

The modulo-only recipe is
`evidence/research/current-source-full-bootstrap/fdset-numeric-modulo-diagnostic.recipe.json`.
Its completed run is `.data/fixtures/fdset-numeric-modulo-phase-observation-run`:
outer receipt SHA-256
`9e495c0f87d849bb037c620606daa4540f0c88f2a971bea4a27c5e0238692ef1`,
child receipt SHA-256
`bf6a7d69c7d51d9992942deea162966874ce05b9a330ee624ed5c836ae9e79eb`.
The retained preceding attempts `fdset-numeric-modulo-only-diagnostic-run`
and `fdset-numeric-modulo-only-loopback-diagnostic-run` both rejected before
execution: first for unavailable TLC loopback access, then because prior-run
handling incorrectly required quiescence proof for a process never launched.
Neither is a compiler failure or silently rewritten PASS. The subsequent run
used loopback-capable execution and all normal source/model checks; the
prelaunch-prior contract defect remains open, not patched around in shared
framework code during another task's validation freeze.

## Independent Default-Command Control

The existing typed interface now also accepts `default-control`. It supplies
empty extra C options and preserves the generated driver's defaults. Arbitrary
flags, nonfinite/widened phase limits and escaped fixture paths still reject.
Its claim explicitly excludes full-suite, runtime and performance admission.
The QNT initializer `initDefaultControl` distinguishes an explicitly bound
control from an undeclared unchanged retry; neither a control nor a candidate
can promote itself to release acceptance. Focused interface/Recipe regressions
passed 65/65 before execution.

Recipe: `evidence/research/current-source-full-bootstrap/fdset-numeric-default-control.recipe.json`.
Sealed executor: `b1c6a1de37b83733842e74b9db9d67fc4fde9fa21da10924555e2f8b78ec6c02`.
The default-control QNT check passed before the native phases. Generated C
again matched SHA-256
`64fcf0f160f6781098920a1028515e0d617f4cecd792cc8d75554f014776518c`.
Scheme-to-C completed in 4.741556 seconds. The independent default C-to-module
phase reached its 90-second inactivity window (observed 90.007705 seconds,
exit -9). Module execution was not reached. Whole attempt: 123.730609 seconds,
DENY; no outer timeout, parent reaped, process group quiescent.

Outer receipt SHA-256:
`2693528990801b6598c1d651c76bc2232fc2ac8d5f977b6a82d36a1054a06907`;
child receipt SHA-256:
`f57a9e5daa7dff3b7f5597a87d035300e974d1e7d78ad8bdfaa8df1c0942f0f8`.
Raw run: `.data/fixtures/fdset-numeric-default-phase-control-run`.

This establishes that the current file-level failure is not solely a shared
Scheme-plus-C timer: the default C phase independently exceeded its window.
It does not establish deadlock, the uncensored default duration or a stable
speedup ratio. The unchanged generated C and successful changed-option probes
make a narrowly scoped GNU dynamic-code scheduling investigation relevant;
they do not justify changing RTS code generation, Linux defaults, concurrency
or release performance gates. No Gambit source/profile was changed.

Next evidence required: a source-bound Darwin/GNU/dynamic-only candidate must
prove its scope excludes RTS/static/executable and other platforms, retain the
default timeout, and qualify a complete current inventory plus runtime and
performance obligations before adoption. A single-file diagnostic cannot be
spliced into the default campaign to claim 379/379, and framework/model success
does not close any of the remaining nine native gates.
