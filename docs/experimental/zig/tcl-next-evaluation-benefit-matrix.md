# Next Evaluation: Modern C and Zig Benefit/Cost Matrix

Use equal caller/entry domains and equal raw/mixed semantics. Distinguish preserved
source behavior from deliberately normalized future behavior. No implementation,
benchmark, person-day estimate or invented cycle count is used.
[Design](tcl-next-evaluation-design.md), [arguments](tcl-next-evaluation-arguments.md)
and [evidence](tcl-next-evaluation-evidence.md) supply the conditions.

NV01. Ten necessary support families:

| Support family | Modern generated C | Optional Zig | Retirement / retained work |
| --- | --- | --- | --- |
| Target-specific semantic entry and native scope identities | Scheme-derived schema plus core entry hooks | Same schema and native hooks | Host-job/object-pointer counters can retire after all callers migrate |
| Forward/command/child role propagation | Explicit internal context and call-site role metadata | Same role distinctions or additional FFI representation | Avoid duplicate identities; source call-site coverage remains |
| Raw acceptance versus entry ordering | Shared C-serialized target history, L/C/A hierarchy | Same core ordering | Unsynchronized numLevels guesses can retire; actual locking remains |
| Check provenance and control routing | Native check/phase/cause outcomes | Same outcomes and Tcl/Scheme route evidence | Text/return-code guessing can retire; nested causal records remain |
| First-attempt consumption | Source-issued identity plus observation and preemption/return proof | Same receipt and proof requirements | Convenient later-script substitution forbidden in either provider |
| NRE/coroutine completion | Logical activation and native-return ledger | Same ledger, suspension roots and grace | Schedule-return shortcuts can retire; suspended custody remains |
| Raw neutrality and final admission | Compose existing discharge/pending/reset/publication plan | Same common issuer/facade | No U reset or new raw request may be hidden |
| Optional normalized gates/guards/check API | New Tcl semantic policy and complete failure proof | Same policy/proof/core integration | Added capability possible; no literal-source savings assumed |
| Roots/results/image and failure | Existing Gambit support, owned records and sealed refusal | Same Gambit support and provider leases | No GC or C activation validity obligation disappears |
| Private source/ABI upgrade and loaded-domain qualification | One isolated facade plus actual caller/native qualification | Same facade plus any added Zig mapping/toolchain | Centralized policies can share review; extra language support is retained cost |

NV02. Design-level quantities and limits:

| Quantity | Result | Boundary |
| --- | --- | --- |
| Receipt predicates separated | Identity, observation, consumption, raw neutrality | Different facts; no native issuer implemented |
| Necessary support families compared | 10 | Policies/representations, not source-line counts |
| Conditional arguments / inert cases | 10 / 31 | Handwritten, unexecuted |
| New source-normalization candidates | Entry gate, completion guard, non-destructive check API | New semantics requiring proof, not already qualified |
| Qualified installed/native profiles / paths retired | 0 / 0 | Design only |
| Support families eliminated solely by Zig | 0 established | Exclusive positive increment unresolved |
| Runtime speedup / memory reduction | Unknown | No native workload or measurement |

NV03. Event work must include logical as well as native activity. Let E be new
semantic attempts, F forwarding/command-role transitions, Cq actual cancellation
checks, A coroutine/NRE activation or suspension/completion events, B native scope
entry/return events, H history/discharge attempts and P owned bytes. The additional
work is:

```text
W_identity = identity_records(E) + role_propagation(F) + scope_records(B)
W_causality = check/control_records(Cq) + logical_activation_records(A)
W_admission = raw_entry_ordering + sum_over_H(cut/frontier/receipt_validation)
             + failure/invalidation/retirement + owned_bytes(P)
W_added = W_identity + W_causality + W_admission
```

Identity count does not multiply by wrapper count, but forwarding still costs
metadata propagation/verification. Scheduling and yield events do not disappear
because the native call returned. The retained space includes live identities,
callback roots, activation records, raw coverage and payload/image leases. Shared
allocation or compression can reduce representation costs only with a sufficient-
summary invariant; it cannot replace actual causal/source coverage. [ND02–ND17]

NV04. Break-even criteria are symbolic and falsifiable:

```text
preserved-source_runtime_gain_positive iff
  sum_over_R(equivalent creation/init/state reconstruction actually avoided)
    > W_added + extra retained-state/refusal/recovery cost

normalized_contract_value requires
  an explicitly required capability + complete changed-semantics qualification
  + total runtime/support balance against an equal-capability alternative
```

R counts histories meeting every entry/consumption/neutrality premise, not ERROR
returns or job reservations. If callbacks frequently win first, empty paths remain
unsupported, coroutine closure is unavailable or U persists, R can be zero. No
positive native number is inferred from the source-known conditional classes.
[NP09, NV03]

NV05. Preserve/modify/refuse matrix:

| Path | Source-preserving value | New cost / refutation |
| --- | --- | --- |
| Naturally first event script | Correct attribution avoids falsely targeting the later host job | Broader entry/context coverage; raw API cannot promise a particular job |
| Empty direct attempt | Honest identity and refusal prevent cancellation loss | No clean reuse gain for that unsupported consumption history |
| Early ERROR with U | Valid observation while retaining state | Still no clean reuse until qualified neutrality or an explicitly changed guard policy |
| Filtered OK | Preserve legacy destructive behavior and reject false acknowledgement | Stronger next-script contract remains unsatisfied; re-arm changes semantics |
| Nested callback/NRE/coroutine | Explicit native/control/logical custody may enable qualified histories | Extra role/activation/causal support and possible progress refusal |
| Uniform entry/return normalization | Could supply a coherent future cancellation capability | Changes poll/reset/check ordering and requires Tcl-core and compatibility proof |

NV06. Reusing the common generation issuer, ledger storage, root/outcome custody
and C facade shares policy owners across RootRegistry, release coordination and
Tcl integration. E/F/Cq/A/B/H/P remain necessary distinct work. The previous
zero-unrelated-callback targeted barrier and O(handler-count) readiness repair are
not additional savings of identity tracking. An entry gate that instead services
all handlers changes cost/effect placement; a target-only gate changes ordering.
Neither option is free and neither is selected as already equivalent here.

NV07. Zig must demonstrate its own increment over the same generated C plan:

```text
necessary maintained C support actually retired
 + independently admitted additional required capability
 - retained Tcl/C islands - duplicate context/receipt/ABI representations
 - added toolchain/language/invalidation/qualification obligations
```

No role, observation, NRE activation, root or private-core support family is shown
to vanish because the emitter is Zig. LLVM/MLIR remains a decoupled consumer of
native plans; it cannot issue cancellation-consumption or GC lifetime authority.

NV08. Present decision: keep modern Scheme-generated C as the mainline. First
qualify target-specific semantic identity and receipt composition; compare any
future normalized Tcl behavior as an explicit architecture change. A coherent
modernized native contract can be valuable independently of language replacement.
The source evidence does not yet establish positive total runtime gain, fully
general raw/managed equivalence, installed native correctness or a Zig-only benefit.
