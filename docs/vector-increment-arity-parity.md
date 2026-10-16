# Vector Increment Arity Parity

## Route Review

- Relevant: the unchanged upstream interrupt stress calls the internal
  increment with two arguments. A current-producer atomic projection confirms
  that the interpreter rejects that call.
- Previously explored: the complete interpreted inventory tests internal
  three-argument and public two-argument calls, not internal two-argument
  dispatch. The prior diagnostic remains retained, including its erroneous
  new-value return assertions.
- Worth fixing: compiled/interpreted dispatch must agree for the same accepted
  primitive; fixing only the stress fixture would conceal the discrepancy.
- Expected benefit: remove a confirmed correctness failure. No throughput,
  end-to-end speedup or complete stress success is predicted from this alone.

## Source Correspondence

The pinned `vendor/gambit` revision is
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.
`gsc/_prims.scm` accepts two or three arguments for `##vector-inc!`.
`gsc/_t-c-2.scm` supplies one as the omitted delta before emitting VECTORINC.
`lib/gambit/vector/vector.scm` currently declares exactly three arguments.
`lib/_gambit#.scm` makes an optional-parameter `define-prim` require an explicit
body rather than synthesizing its fixed-arity inline self-call.

The candidate supplies an optional delta of one and explicitly invokes the
existing three-argument compiler primitive. It does not implement a separate
read/modify/write algorithm, change atomic operations or serialize threads.
The corrected successor fixture checks both the old-value return and the
updated vector, explicit negative delta and invalid argument counts.

## Immutable Candidate And Validation

`evidence/fixtures/vector-increment-arity-parity/source.lock.json` preserves
all 21 BTQ candidate file identities and adds only the vector primitive file.
The consolidated patch is `patches/fixtures/vector-increment-arity-parity.patch`.
The older model, diagnostic fixture, recipe and failed receipts are unchanged.
The arity QNT model has old-contract negative and repaired-contract positive
controls; it does not prove atomic arithmetic, root handling or parallel GC.

Nine focused integrity/framework checks pass. These are not native acceptance.
The full bootstrap recipe retains the Bazel profile, adaptive CPU concurrency,
all three concurrency flags, original model/review controls and 600-second
whole budget, then runs the corrected atomic fixture under its 20-second
native budget. The actual sealed run is PASS in 404.745/600 seconds, with
seed 48.583 seconds and full from-scratch 197.708 seconds, both exit zero
without timeout. All two-pass phase counts are established and the corrected
atomic interpreted fixture passes 1/1. The completed producer reference is
`evidence/research/vm-registry-reader-lease/vector-arity-completed-producer.json`.
The subsequent original 379-file interpreted campaign is PASS, 379/379, in
83.548/300 seconds. Its runtime transfer reports 2243 copy-on-write files,
zero byte copies and no hardlinks; no fresh toolchain build was performed.
The successor now closes bootstrap and complete gsi (2/12); the atomic
fixture does not substitute for the complete stress campaign.

The unchanged four-file interpreted stress successor is DENY at its original
300-second whole budget, 300.297 seconds including teardown, exit -9 with
timeout. Parent reaping and process-group quiescence are recorded.
`thread_interrupt_stress.scm` passed in 51.214 seconds; the other three files
are incomplete, not passes. No complete stress correctness or speedup is
admitted. This run reused the same producer through 2243 filesystem clones.

Static workload audit: `tfib_stress.scm` calls `(go 15 5000)` and executes
`busy-sleep 6000` at every recursive node. With C(0)=C(1)=1 and
C(n)=1+C(n-1)+C(n-2), C(15)=1973. The declared workload therefore visits
9,865,000 recursive nodes and requests 59,190,000,000 busy-sleep decrements.
This counts source-level work, not measured CPU instructions or a lower bound
on wall time: compiler optimization, scheduling and VM behavior still matter.
It does not prove that the timeout is free of protocol deadlock. Separating
workload execution from stalled ownership/GC progress remains open; silently
reducing loops, changing mode or widening budgets is not a repair.
Recipe preflight rejection for an incomplete verdict dependency
graph and the loopback-prerequisite rejection remain retained; neither is a
runtime test result. Full native candidate qualification is pending.

The accepted BTQ checkpoint remains 2/12 gates. The new candidate inherits
none of those passes until bound verification completes. Complete gsc, PR
gsi/gsc, stress gsi/gsc, registry lifetime, lifecycle faults, GC/FFI, Gerbil
correctness and release performance remain open.
