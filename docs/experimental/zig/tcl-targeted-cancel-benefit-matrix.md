# Targeted Settlement: Work, Support and Net Benefit

Compare equal request semantics, allowed native/handler domain, old-job isolation,
raw idle cancellation, roots and delivery custody. This is a theoretical work and
maintenance ledger, not a benchmark. No person-days, invented cycles or percentages.
[Design](tcl-targeted-cancel-design.md), [arguments](tcl-targeted-cancel-arguments.md)
and [evidence](tcl-targeted-cancel-evidence.md) define the conditions.

TV01. The useful modernization is one native contract and one Tcl-owned commitment
boundary. It is available to modern Scheme-generated C and optional Zig alike.
The following twelve support families cannot be omitted merely by changing emitter:

| Necessary support family | Modern generated C | Optional Zig | Actual retirement / retained cost |
| --- | --- | --- | --- |
| Provider image/private ABI capability | One isolated C facade; capture stable entries and image lease | Use same facade or maintain extra private ABI import | Duplicate binding recipes can retire; provider qualification stays |
| Interpreter/token/owner identity | Shared registry with non-reused generations | Same registry/identity rules | Address-only checks can retire; lifecycle hooks and raw pointer users stay |
| Explicit managed submission | Generated typed contract, request coverage and outcomes | Same contract and records | Per-adapter cancellation recipes can retire after caller migration |
| Raw API provenance and compatibility | Core rawSerial/interference hook; original raw payload/return behavior | Same core hook and raw implementation | Raw API does not retire; a restricted domain is not free gain |
| Native/control/async scope closure | One entry/actual-return ledger | Same source scope ledger | Per-adapter guesswork can retire; E-dependent bookkeeping stays |
| Attributed vs generic token marks | New A-locked internal primitive plus unknown-debt handling | Same Tcl primitive | Generic mark and signal-sensitive contract remain; duplicate host attribution can retire |
| Pending request coalescing/custody | One selected-payload/coverage policy | Same selected-payload/coverage policy | No FIFO queue or per-request observation fiction; bytes and terminal records stay |
| Target settlement and readiness | One Tcl helper plus list scan | Same helper or C bridge | Managed thread-wide barrier drain can retire; async executor and normal callbacks stay |
| Non-forced reset/postcondition | Core callback-free commit with private reset | Same reset/source qualification | Reset-on-OK shortcuts can retire; flags/provenance checks stay |
| Epoch authority/publication | Common Scheme plan and one L,C,A commit | Same plan and lock protocol | Independent reset/publish paths can retire; leases and synchronization stay |
| Root/marker/outcome/image reclamation | Existing Gambit support plus explicit detached-byte custody | Same Gambit support and retirement | No GC, native-root or C-return validity obligation disappears |
| Source upgrades/failure qualification | Maintain hook/layout/lock/invalidation and exceptional-exit rules | Same rules plus Zig toolchain/FFI mapping if added | Centralization shares review; new private Tcl coupling remains a cost |

TV02. Quantities with an explicit evidence boundary:

| Measure | Count or bound | Meaning |
| --- | --- | --- |
| Existing pinned token kinds per interpreter | 1 cancellation token | Reused in place; not a new token per request |
| New managed clean receipt path implemented/admitted | 0 / 0 | Proposed Tcl core integration |
| Unrelated callbacks executed by the proposed targeted barrier | 0 | By contract, unlike servicing arbitrary ready handlers; their later work remains |
| Mandatory readiness repair | One H-handler pass per settled batch | Selected design avoids uncharged ready-count hot-path changes |
| Necessary support families compared | 12 | Policies/ownership boundaries, not lines of code |
| Families proved unnecessary solely because of Zig | 0 | Incremental positive value remains unresolved |
| Conditional arguments / inert counterexamples | 9 / 24 | Handwritten and unexecuted |
| Paths retired / native profiles qualified | 0 / 0 | Documentation only |
| Full mixed raw/managed reuse refinement | Unresolved | Strict clean predicate explicitly excludes raw interference |
| Runtime speedup / tail latency percentage | Unknown | No native workload or performance validation |

TV03. Work accounting distinguishes barrier latency from whole-history work.
Let H be the maximum registered owner handler count, I the affected same-owner
interpreters, R the old accepted managed request records (or explicit retained
coalescing intervals), E the counted native/control entries, X raw submissions, G generic token marks,
P total owned payload
bytes, Q unrelated callbacks a thread-wide barrier would actually execute, and U
number of batches/reuses. Let V_i include real registry/frontier validation rather
than an assumed constant-time lookup.

```text
S_batch = sum_i V_i + O(H) readiness repair + coverage_disposition(R)
          + I reset/postcondition operations + receipt/publication work
M_history = scope_accounting(E) + request/mark_provenance(R + X + G)
            + byte_ownership(P) + retirement/dependency work
W_target_history = sum_batches S_batch + M_history + required_later_handler_work
```

Coverage disposition is O(R) if every request outcome is materialized; interval
compression can reduce bookkeeping only when independently delivered outcomes
are not promised. Memory includes live coverage, bytes, identity and lease records;
these cannot be counted as zero because the token itself is reused. A new scan may
extend mutex hold time; I/R/tree validation can also contend with raw cancellation.
Moving allocation/callbacks out of the commit interval improves reasoning, not a
proof of bounded scheduling latency. [TD07–TD16]

TV04. Existing AsyncInvoke rescans from the head after each callback. For finite H
and Q_total invoked callbacks its scan upper bound is O(H*(Q_total+1)), plus actual
callback and derived work. The new targeted barrier uses O(H) repair and I-target
work, avoiding execution of Q unrelated callbacks at that barrier. This gives a
structural reduction in barrier callback exposure, but not an unconditional
asymptotic improvement: Q may be zero, H small, validation costly, and unrelated
work may simply run later. Handler starvation/termination is not proved in either
path. If the equivalent old profile already needs no global drain, its avoided
D can be zero and the new machinery can lose. [TX03, TD10, TP04, TP07]

TV05. Break-even conditions use actual quantities, not assumed savings:

```text
runtime_work_positive iff
  sum(actual old barrier work eliminated across equivalent histories)
    > sum(S_batch + new provenance/scope/retirement overhead not already shared)

reuse_positive iff
  equivalent create + Tcl/Tk init + state reconstruction actually avoided
    > added reuse protocol + retained-state + failure/quarantine cost

incremental_Zig_positive iff
  necessary maintained C support actually retired
  + independently admitted additional required capability
    > retained Tcl/C support + duplicated representations/bridges
      + added toolchain/ABI/invalidation/qualification obligations
```

For barrier latency the left side can include callback time moved out of that
barrier, but the report must label it latency relocation and account for required
later execution in whole-history work. No sum is assigned invented numeric values.
All equal-domain correctness and failure obligations are prerequisites, not
negative costs to trade away. [TP09, TV01–TV04]

TV06. Sharing reduces duplicate policy owners, not per-target safety work. Binding
metadata may be shared per provider image; one Scheme plan and C facade can serve
RootRegistry, release services and this Tcl component without separate epoch/root
implementations. Target identity, E scopes, R outcomes, I resets, P bytes and image
grace remain distinct necessary instances. An optional ready-count facility adds
another invariant to every create/mark/claim/delete path; amortization is favorable
only if saved scans exceed added hot-path and upgrade cost under equal semantics.
This study neither selects it nor treats it as a Zig-exclusive service.

TV07. Refutations that keep the design honest:

| Claimed gain | Refuting condition | Decision |
| --- | --- | --- |
| Targeted settlement makes reuse universally cheap | Raw/interp cancel or unknown marks are frequent; frontier cannot qualify | No clean reuse from this path; preserve raw support and sealed custody |
| O(1) target clear solves all overhead | Readiness repair scans H, coverage needs R records, frontier validates I | Charge full work and lock hold time |
| Zero unrelated callbacks proves less total work | Required callbacks run after the barrier | Report reduced exposure/latency only; total saving unproved |
| Zig removes manual cleanup/root code | Same native exit, marker, receipt and private-core hooks still needed | No support-family retirement established |
| C cannot express the architecture | Generated typed contracts, lock hierarchy and opaque facade implement the same protocol | Keep modern generated C as mainline unless a separate Zig increment is proved |
| Successful source reasoning admits native reuse | Installed Tcl/Tk, every producer and exceptional owner exit are open | Full/runtime/native gates remain unresolved |

TV08. Present decision: study the common native contract and Tcl core cooperation
on the modern generated C mainline. Do not add Zig merely to host this protocol.
A genuine incremental result would identify a necessary support representation or
service that disappears under Zig, with equal raw/managed/GC semantics and complete
failure coverage; none is established here. This component's potential win is
avoiding unrelated barrier callbacks and consolidating native lifecycle policy.
It does not claim to deliver all of Gambit's modernization or a measured speedup.
