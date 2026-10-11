# Compiler Cost Boundaries

The complete compiled runtime020 campaign remains DENY at 300.316 seconds.
Three balanced shards stop with 42, 42 and 31 completed files; the last shard
is compiling the original `03-number/_num.scm`. Do not rerun the same campaign
unchanged or admit a timeout as success.

## Original Fixture Phase Probe

`compiler_cost.py` uses the shared bounded executor and snapshot/identity
helpers. It copies unchanged upstream fixtures and splits Scheme-to-C,
C-to-dynamic-module and compiled execution. This is diagnostic only and never
complete-suite or bootstrap admission. One whole budget covers all phases.

The corrected runtime021 probe records Scheme-to-C completion in 30.818 seconds,
generating 152,462 C lines. C-to-module then consumes the remaining budget and
is killed after 59.250 seconds; whole duration is 90.384 seconds, DENY.
Compiled execution does not start. The actual command uses GNU GCC16, `-O1`
and the existing `-ftrack-macro-expansion=0`. There is substantial frontend
work and unresolved C compilation cost, not evidence of a GC deadlock or TLS
root cause. Receipt: `native-compiler-cost-num-021-deny.json`.

The first adapter attempt is separately retained under
`.data/compiler-cost-num-021`: the CLI ignores direct C input in default dynamic
mode, and misplaced `-f` is warned about. Its apparent frontend time is not
clean-option evidence. The corrected adapter uses public `compile-file` for
generated C, places `-f` first and rejects ignored-option warnings and missing
artifacts, even with exit zero. No runtime or compiler flag repair is admitted.

## Driver Binding

Generated `bin/gambuild-C` was not in the older handwritten source inventory.
New native/probe receipts independently verify its configured compiler against
the selected GNU executable, bind its hash plus present cache-helper hashes,
record whether native object reuse was requested and recheck at completion.
An enabled but missing reuse helper rejects admission.

The driver-bound runtime021 fxmul calibration passes interpreted (0.346 s) and
compiled (8.183 s) modes with reuse disabled. This validates the new framework
guard on a real original fixture; it is not an end-to-end acceleration claim.
The preceding numeric probe ran before this guard was added and is not
retroactively claimed to have pre/post driver hashes.

## TLS Hypothesis Review

Parent evidence `d1361-darwin-platform-branch-admission.md` rejects TLS lookup
for its SINGLE_THREADED_VMS configuration. That exclusion does not cover the
current multiple-threaded-VM candidate. The actual runtime021 binary contains
`___emutls_get_address` and the TLS processor-state cell.

However, current `gambit.h` already propagates processor-state arguments when
getter/setter access may be slow; `___GLOCELL` uses the propagated `___ps`.
Binary symbol presence is not hot-path attribution or evidence of a large
speedup opportunity. Do not add another state cache without measured caller
cost and an ownership/publication/rebinding model. Source and native facts,
not a generic platform analogy, must select the next repair.
