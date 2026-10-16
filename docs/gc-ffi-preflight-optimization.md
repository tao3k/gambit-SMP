# Leased Preflight And Actual Scheme/C FFI

## Changes And Safety Boundary

The generic validation transport now acquires an explicitly selected completed
runtime's lease before full producer inspection. Its initial complete hash
seeds the checked inventory while the lock is held, avoiding another first read.
A single Recipe holds the same lease across capabilities; every capability
still performs a fresh full SHA verification, and receipt/archive/tool checks
are not replaced by the tree cache. The Recipe releases all locks on normal or
exceptional completion. Closed scopes reject reuse and discard cached entries.

Metadata checkpoints include every path, device/inode, mode, link count, size,
mtime and ctime. The scandir traversal preserves the former Path inventory,
including hidden entries, internal links and component-wise ordering. Changed
metadata forces a fresh hash. External links and replaced roots remain denied.
This is cooperative exclusive-workspace custody, not filesystem hermeticity
against arbitrary privileged writers.

Managed suite checks use SHA values from that complete leased inventory;
unleased checks still read bytes. Missing files do not silently fall back. Final
full SHA reads are never memoized. Mutable source-generation changes must match
the capability's actual input/output identity, not merely a cache hit.

The existing serial ABI EvaluationOwner is now used by the sealed worker for
retry review and terminal Evidence. It is not Actor concurrency. Every request
retains full child source checks; normal process exit, unforced teardown,
request completion and terminal seal identity are mandatory. The owner receipt
is SHA-bound into the child receipt and checked by readback. Teardown is charged
to the existing deadline. The freshly reaped owner's full terminal seal check
replaces only the immediately redundant worker check; the parent independently
rehashes the seal after worker exit.

## Frozen Final Execution

Engine: `3839170633ac53bbed5afbce891db89fd912941dc5fd94b3e279b219e0426631`
(`.data/research-engine-gc-ffi-023`). Library bytes are unchanged.
Recipe: `evidence/research/experimental-scheme-ffi/managed-workspace.recipe.json`.
Actual run: `.data/experimental-scheme-ffi-014`.

- Parent: PASS, exit 0, timeout false, 16.259082/20 seconds including final
  checks; performanceBudgetExceeded false; reaped and process group quiescent.
- Child including owner finalization: 14.739533 seconds; inputsStable true.
- Source 4.046356, producer 3.192014, compiled FFI 5.473594, terminal Evidence
  0.972464 seconds, all PASS.
- One actual upstream gsc fixture compiled and ran; 32 explicit Scheme GC
  iterations checked a stable malloc payload through C FFI and then freed it.
- One serial ABI process completed both requests and exited 0 without forced
  termination or terminal identity error. Final owner receipt is SHA-bound.
- Actual `research --read` reported CURRENT, binding CURRENT, artifacts AVAILABLE.

The producer revalidates the exact completed Darwin binary/identity and its
original configure argv containing all three concurrency flags. The FFI
processor probe reported 11, not a hard-coded benchmark topology. This is
evidence of flags plus a compiled GC/FFI component, not independent multi-VM
construction/rollback/retirement or full runtime acceptance.

## Matching Measurement And Regression

The three paired identity-transport trials use identical 137 file bytes and
answers (`7a33c1e04899ed27edf12fe3947167eee05bbdc1f2c3d083907d4d1feac6cc4c`),
five lookups and fresh final SHA in both modes, with AB/BA ordering. Baseline
median was 0.050892 seconds; candidate 0.024719 seconds. This is about 51.4%
less time for this small hashing workload, not a collector/whole-framework
speedup. Raw logs: `.data/early-lease-matched-performance-023`.

175 transport/custody/kernel tests passed, no skips, in 4.815/15 seconds;
`.data/early-lease-regression-023`. Controls cover stale receipts, mutation,
mtime restoration, path/inode changes, lock retention/release, closed scope and
owner receipt tampering/forced termination. These unit controls do not replace
the actual FFI execution. The separate 131-test invocation had 40 skips and is
not claimed as sealed-review qualification.

## Retained Failures And Open Gates

007 and 009 retain their whole-run timeouts despite individual fixture PASS.
008 retains performanceBudgetExceeded true at 20.392 seconds. 010's earlier
18.806-second PASS is not imported as the final candidate. 011 failed terminal
budget; 012 failed owner deadline; 013 rejected non-normal owner teardown. All
original receipts/logs remain unchanged. Initial unit failures for updated cache
accounting and the incomplete mock producer reference were corrected as test
contract changes; their observed failures were not relabeled PASS.

The new Evidence view `stable-ffi-023.view.json` closes only stable-payload-ffi.
It requires both bound configuration and execution sources for the flag facts;
withdrawal restores missing flags. Full independent-VM lifecycle, movable
foreign borrowing/callbacks and matched collector performance stay unknown.
Historical reasons/negative views remain intact. No full current graph, full
consumer suite, source refinement, GC redesign speedup or complete Gambit
acceptance is established here. Working's separate SIGBUS/SMP repair is not
overridden by this component result.
