# Payload And VM Transfer Source Experiment

This extends the ZGC-inspired design research. It is not an implemented
concurrent Gambit collector, a complete C memory-model proof, FFI acceptance,
cross-VM continuation support or measured GC performance.

## Protocol Models

`ForeignPayloadPublication.qnt` separates borrowed-writer lifetime, payload
version, copied value, publication and delayed reader visibility. It exercises
stale-copy, live-lease and missing-acquire faults. A single write, abstract
atomic actions and an assumed release/acquire edge bound the experiment.
It does not cover arbitrary callbacks, interior pointers, multiple writers,
pin acquisition racing retirement or a full weak-memory event graph.

`ContinuationVMTransfer.qnt` separates source/destination roots, publication,
generation-bound acknowledgement and source-VM retirement. Two requests permit
stale-generation acknowledgements. The three faults omit destination-root
publication, accept stale acknowledgements or retire with a foreign lease.
Compatible VM heaps/representations are assumed. No arbitrary cross-VM
continuation API is inferred from same-VM processor migration.

The positive profiles in campaign 002 exhaust 12 and 19 distinct states with
zero queued states. Six negative profiles decode actual counterexamples.
These are finite observations, not source or native admission.

## Exact Source Correspondence

The current declared candidate is `darwin-dynamic-modulo-scope`, as recorded in
`evidence/scenarios/concurrent-gc/darwin-source-032.view.json`. Its source lock
does not establish a matching runtime producer. Four source files independently
match the candidate lock's per-file SHA against captured fdset bytes. Reusing
identical source bytes is not reusing the fdset binary as a new candidate.

The new `payload-transfer.view.json` preserves captured histories and gives
six exact source anchors through declarative `source_anchor`/`source_gap`
relations. Withdrawal of `_thread.scm` removes its two source correspondences
but never closes an obligation.

| Source | Observation | Remaining Correspondence |
| --- | --- | --- |
| `include/gambit.h.in:11034-11102` | Selected sync backend may use GCC `__sync`, Windows, emulation or sequential primitives | Establish the actual publisher/reader pair and selected backend, not a blanket assertion that ordering is absent |
| `lib/mem.c:708-835` | RC allocation, registration, reference count and payload association | Establish writer ownership, snapshot version validation, lease acquisition and reclamation ordering |
| `lib/c_intf.c:1683-1727` | Foreign release clears callback/pointer; ordinary pointer lifetime belongs to C world | Establish callback draining and payload consistency independently of reference counting |
| `lib/_thread.scm:3190-3207` | Migration retains donor root while publishing a processor target under ownership | Define compatible cross-VM transfer and both root inventories before source retirement |
| `lib/mem.c:4013-4298` | Frame/continuation scanning has representation-specific roots | Connect every moving frame/continuation root and FFI root to relocation epochs |
| `lib/_thread.scm:2750-2762` | Resume consumes a migration target before interrupt handling | Keep stale acknowledgement/interrupt activity from clearing a newer handoff |

GCC documents most `__sync` operations as full barriers, with specified
exceptions. Its `__atomic` operations require a data-race-free program and
particular reads-from relationships. A relaxed-visibility model counterexample
does not establish that the existing Gambit GCC path exhibits it:
https://gcc.gnu.org/onlinedocs/gcc/_005f_005fsync-Builtins.html
https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html

## Executable Assets And Actual Failures

`foreign_payload_control.c` is a deterministic C11 protocol experiment. The
first implementation merely projected a source file without compiling it;
the sealed builder correctly rejected the missing source consumption. The
corrected asset actually includes and calls a numerically projected RC function
slice, independently byte-matched to the current candidate. A minimal
single-thread header/context surrounds that exact slice. This is a component
control, not the full Gambit ABI, a Scheme/C FFI crossing or concurrent GC.
All payload accesses use atomics; intentionally stale copy/live lease controls
avoid turning undefined C data races into manufactured counterexamples.

`tests/experimental/foreign_payload_gc.scm` is a pending real compiled fixture:
it creates and mutates a stable C payload through `c-lambda`, retains the
foreign handle through explicit Scheme GC, checks its value and releases it.
It has not been compiled/run or admitted. It tests neither borrowed movable
Scheme pointers nor cross-VM callbacks. Those need separate real fixtures.

The sealed Recipe is
`evidence/research/experimental-payload-vm-transfer/control.recipe.json`.
Attempt 001 failed schema validation before execution; the existing
`expectedExit`/`negativeControl` fields corrected that error. Attempt 002
completed all eight model controls but denied C build admission because the
compiler did not consume the locked-source projection. Its parent whole time
was 43.105868 seconds. Attempt 003 followed the real RC source-consumption
change with only 44 seconds remaining. It timed out during a subsequent model
check; the C build/test and terminal evaluation did not complete. Its parent
whole time was 44.427160 seconds, exit -9, timeout true, reaped and quiescent.
Both executed attempts total 87.533028 seconds under the original 90-second
cap. The remaining budget is not reset; neither native execution nor complete
campaign PASS is claimed. Earlier model observations have matching QNT bytes,
but changing the C asset does not relabel the old whole campaign as CURRENT.

## Actual Agentic AI Consumer

The new view uses ordinary declarative Evidence DSL, not Python research
judgment. It binds model verdicts, counterexamples, raw verifier logs and
source hashes. Real Python/C ABI tests verify inference, source withdrawal,
restoration, retained-session reuse, Action discovery, authorized read-only
selection and CURRENT observation. Two tests passed without skips in
6.245584 seconds under the original 15-second cap, with final exit 0, no timeout
and a quiescent process group. Raw results are local in
`.data/experimental-payload-view-001/receipt.json`, not Git-archived admission.

The new candidate's three flags remain missing execution evidence; the older
configured fdset producer does not fill them. Nine source/native obligations
and six performance metrics stay open. No complete current graph or full
consumer regression is claimed from these two focused tests.

## Matched Runtime Measurement Gate

There is no new collector implementation to compare yet. Model-checker,
compilation and Library query durations must not be reported as GC speedup.
A real run must freeze baseline/candidate source and binaries, GNU GCC and
options, all three concurrency flags, full fixture bytes, heap/live-set,
processors/jobs and original execution budgets. Retain failed trajectories and
measure pauses p99/max, throughput, barrier CPU, peak RSS and FFI latency on
the same inputs. Until that run exists, `missing_metric` remains unpopulated
by measurements and no performance conclusion is supported.

## First C Execution And FFI Admission Attempt

The combined campaign remains DENY; its 87.533028 seconds are not reset.
Read-only phase analysis found 31.838161 seconds in the eight verifier
processes of attempt 002. The source-consumption-denied build spent only
0.117520 seconds in compiler identity/dependency checks. There was no C
compilation taking forty seconds. Attempt 003 exhausted its remainder before
the corrected source-consuming C control reached execution.

The distinct native-only first-execution Recipe is
`evidence/research/experimental-rc-payload/control.recipe.json`. It does not
rerun or reuse the model checks as native admission. Its whole cap is 15
seconds, below the old combined campaign cap and no larger than the old
compiler-step cap. `.data/experimental-rc-payload-001` completed in 7.522264
parent whole seconds, exit 0, no timeout, parent reaped and group quiescent.
Actual C build took 0.141682 seconds. The checked payload/RC control exited 0;
the stale-copy and live-lease controls each exited 1 as declared. Exact source
consumption and terminal Evidence were validated. This is still a
single-thread RC component, not real Scheme/C FFI or moving concurrent GC.

The actual compiled fixture was then submitted, without running a binary
directly, through
`evidence/research/experimental-scheme-ffi/control.recipe.json`. It declares
the latest Darwin source lock/completed producer, fixture SHA, full canonical
failure inventory and review rules, 15-second suite cap and 30-second whole
cap. `.data/experimental-scheme-ffi-001` rejected completed-source reuse before
producer/compilation/FFI execution. Parent whole time was 7.863597 seconds,
exit 2, no timeout, reaped/quiescent. No FFI result exists.

The failure is an actual custody-cut mismatch, not evidence of an FFI hang.
The registered source cut describes 2243 files from before bootstrap in the
same mutable workspace. A read-only comparison found 61 changed expected
files, including configure-generated makefiles/scripts, compiler executables
and libraries. Independently comparing all 956 reported bootstrap source-file
hashes found no differences. That latter fact does not permit ignoring the
61 mismatches, replacing the old source SHA, accepting the runtime tree as the
old source tree, or executing a binary outside the checked kernel.

The source/runtime custody owner has the exact failure and comparison. The
required repair is a genuinely retained immutable pre-build source cut and
separately validated product cut, or an independently qualified general
snapshot capability. No ordinary retry of this unchanged producer is allowed.
Working continues its normal suite; no SubAgent was used and its mutable
directory was not changed by this FFI attempt. Cross-VM continuation/native
retirement and same-input GC performance remain unvalidated.

The existing `workspacePolicy: in-place` contract was separately attempted,
explicitly selecting the checked built-runtime cut, not relabeling the original
pre-bootstrap source cut. Suite code places added fixtures and test compilation
in a separate test directory. The managed lease and product identity checks
were retained. `managed-workspace.recipe.json` had only 20 seconds remaining
after attempt 001 under the original 30-second FFI campaign.

In `.data/experimental-scheme-ffi-002`, source and producer stages actually
passed in 8.734266 and 8.760004 seconds. The outer timeout occurred during suite
preparation, after compiler identity probes and before a native-review receipt,
processor probe or Scheme/C compilation record. The parent exited -9,
timeout true, reaped/quiescent; whole time was 20.347328 seconds. Both FFI
attempts total 28.210925 seconds under the original 30-second cap. No FFI
compilation/load or payload assertion is claimed. No ordinary unchanged retry
is allowed and the budget is not reset.

This isolates the next optimization obligation: avoid repeating equivalent
completed-producer and full-artifact validation within the same exclusively
leased generation, while preserving complete per-path SHA checks, semantic
cut identity and final revalidation. Do not skip source or product checking,
reuse a global unbounded cache, widen timeouts or directly execute the binary.
The immutable source-cut repair remains necessary for portable isolated reuse;
the managed path's two PASS stages do not establish that repair.

The RC component outputs and first FFI setup denial are also bound in
`ffi-execution.view.json`, with raw process/log hashes. A real Library consumer
test passed in 5.125781 seconds under its 15-second cap and explicitly retained
all nine native/source obligations, six missing metrics and the new-candidate
flag evidence gaps. This is a focused Evidence transport check, not full
consumer or runtime acceptance.
