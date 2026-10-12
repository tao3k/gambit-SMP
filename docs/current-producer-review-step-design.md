# Current Producer Review Step Design

## Source-Audited Requirement

The current `native_review.campaign` requires exact generated identity and
runtime tree hashes. `project_review` also requires those hashes in the causal
claim rows. The source-core producer cannot know them before it builds.
`Context.artifact` correctly accepts only current-graph PASS outputs, and
`run_sealed` retains one absolute deadline. `prior` is not continuation.

Thus merely adding a suite to the existing source recipe, or interpolating a
campaign hash while leaving causal rows unchanged, does not solve the formal
handoff. Neither importing an old binary nor relabeling the known failure
inventory is permitted. The existing sealed_runtime_review_handoff model
checks the desired finite safety boundary; it is not this implementation.

## Proposed Generic Boundary

Prefer a current-producer review binding step inside one sealed recipe over
cross-run resume. Build, binding, preflight and suite execution must consume
the same existing whole deadline. No pause, fresh timeout, previous PASS-step
injection or archived-runtime import is added.

The step receives declared, hash-bound host review intent plus typed runtime
and identity references to a current PASS producer. The intent must explicitly
authorize binding to that producer's source lock/configuration and selected
suite; it cannot silently mutate a previously literal v1 review. Its unresolved
artifact references are a new explicit input contract, not a template string
substitution or cached inference result.

Before producing a bound review, validate all of the following:

1. Producer and identity descriptors are admitted, of the correct types and
   unchanged. Verify actual runtime/source contents against that identity.
2. The host intent names the exact source lock, selected fixtures, source/tool
   changes, canonical historical failures, policy and causal premises. Preserve
   original failure receipt/log/baseline identity/budget bytes.
3. Bind both campaign and every causal claim to the observed current artifact.
   The whole runtime tree, host-derived allocation and resolved suite inventory
   are bound together, not just the compiler executable hash.
   `native_review.campaign` currently reads the calling step's budget. A new
   binding step must explicitly bind the target suite step's immutable ID and
   budget, not substitute its own shorter review budget or fabricate Context.
   The actual suite must recompute and match that target campaign.
4. Retain all overlapping historical failures and all existing native policy
   obligations. A finite-model result is not a reviewed causal premise.
5. Run the same native ASCENT policy, without a weaker rule set or Python
   substitute decision. Only a policy-qualified review artifact may reach the
   suite; the review itself grants no execution or runtime admission.
6. Immediately before execution, recheck producer/artifact/review identities,
   campaign scope and remaining absolute deadline. Retain non-expanded suite
   and step budgets, with shared host-adaptive CPU allocation.

This contract still treats completeness and truth of host causal reasoning as
trusted inputs, just as literal typed reviews do. It does not authenticate the
review author or prove a source fix from a matching digest.

## Required Rejection Tests

Reject unqualified or mistyped producer, changed source/configuration/tool,
stale artifact, wrong selected files or mode, changed failure inventory/policy,
missing historical receipt/log/budget, unreviewed overlapping failure, causal
claim referring to another producer, topology drift, deadline reset, unknown
review reference, a review-step budget confused with the suite budget and a
model-only claim masquerading as causal review.
The positive test must actually reach a suite with a bound fresh producer;
an always-deny implementation is not sufficient.

## Ownership And Status

The human subsequently assigned the shared interface implementation to this
task. `gambit.review` now binds typed current runtime/identity outputs to the
downstream suite's campaign and budget, evaluates the existing native ASCENT
policy, and publishes `bound-native-review.v1`. `gambit.suite` consumes that
artifact and rechecks producer, intent and campaign identities. This is
implemented code, not yet a qualified end-to-end admission path.

The fresh `current-producer-native-chain` qualification retains its original
420-second whole budget. Its first attempt failed at GNU stdio linking because
the Node prefix preempted Darwin system linker tools. The host tool search was
corrected without changing the GNU compiler or any SMP/VM flag. The second
attempt reached source regeneration but did not generate `lib/_std.c`;
`source-core.stderr` records `_std.c` Error 70 and terminated make processes.
No final outer/child receipt exists and no live process remains. Preserve the
raw directory as incomplete; neither the exact interruption cause nor a native
compiler defect is established by that log alone. Review and suite completion
are unproven. Do not relabel this as bootstrap or native PASS.

The current sealed `research --run` CLI no longer requires a redundant
`--allow-native` switch. The explicit run invokes declared capabilities;
source, tool, causal-policy and deadline checks remain in force. Historical
receipts retain their original execution configuration.

### Native Policy Qualification

Running `tests.test_native_retry_review` with the editable implementation and
a selected engine failed: 36 tests, 12 errors, 59.223 seconds. The first error
was `new research must execute the sealed implementation, not the editable
checkout`. The identity guard was retained, not mocked or relaxed.

Loading the implementation from engine
`b0afede290654f40f6bb7cc5140df726c2784e3aa8a656eae901c376fde0ecee`
then passed the same 36 tests without skips in 84.264 seconds. Three additional
focused tests passed in 6.417 seconds: a typed current-producer binding reached
the actual native causal policy, changed intent was rejected, and changed bound
artifact bytes were rejected. These tests use synthetic runtime/causal fixtures
to qualify transport and native policy; they execute no Gambit native suite and
do not establish the truth of a production causal review. Individual context
deadlines were unchanged. The aggregate test duration is not the 420-second
producer campaign or a full-suite performance measurement.

The framework task released this task's model/document input freeze explicitly.
Any earlier graph or timing receipts remain historical for their original
inputs; a current graph must be freshly sealed after model inputs stabilize.

The source-core whole budget remains 420 seconds, not a new larger deadline.
Suite additions must fit remaining time and the historical native limits; a
binding capability cannot turn budget exhaustion into PASS. Even after this
interface is implemented, actual full native/GC/lifecycle/bootstrap/Gerbil
and production performance acceptance remain required.
