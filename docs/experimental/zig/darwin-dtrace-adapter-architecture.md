# Darwin Native DTrace Consumer and Evidence Adapter

Date: 2026-10-20. Design only. This refines K15/V9 in the
[external observer study](darwin-external-observer-design.md), without qualifying
any original-tool observation. [Source ledger](darwin-dtrace-adapter-evidence.md).
No consumer implementation, compilation, linking, live probe enumeration,
tracing, calibration or performance validation was performed.

The architectural decision is an optional, separately qualified Darwin evidence
collector. It may supply bounded observations to the equivalence evaluator; it
must not become a requirement of Zig construction, Gambit execution or MLIR
services. A native consumer can remove CLI text parsing from the evidence path.
It cannot remove platform protection, kernel observability or semantic gaps.

Continue with the [link/load/callback support matrices](darwin-consumer-support-matrix.md)
for version-specific TAPI and dyld paths, C0/C1 candidates, P01-P10 probe
admission and U01-U06 unresolved obligations. Source-level compatibility paths
do not qualify the installed stack.

## Six Independent Architecture Boundaries

| Boundary | Required identity / decision | Current evidence and remaining gate |
| --- | --- | --- |
| Hardware and OS | Hardware capabilities, boot/kernel identity, protection policy | CPU capability alone says nothing about a selected consumer executable or target visibility |
| Consumer executable | Mach-O CPU/subtype, deployment target, compiler ABI, signing/loading requirements | SDK distinguishes ARM64_ALL, ARM64_V8 and ARM64E; no consumer was produced or loaded [N1,N2] |
| Library interface | SDK/header/stub hashes, actual loaded library identity, symbols and callback ABI | Local stub lists x86_64-macos and arm64e-macos, with no literal arm64-macos target; link/load compatibility remains unresolved [N1] |
| D compiler and records | D data model, type definitions, action schema, descriptor sizes/offsets and argument ABI | DTRACE_O_LP64/ILP32 select the D compiler model; neither selects the observed process architecture nor proves callback layout [N3,N4] |
| Observed image | Exact original tool image, ABI, image generation, protection status | A consumer's architecture must not be substituted for the target's architecture; translation/other target ABIs are separate deferred profiles |
| Probe/emitter | Provider/module/function/name, attributes, argument types, firing context, installed-kernel correspondence | Published source and declared probes are candidates; availability, enablement and actual firing remain unqualified [N5,N7] |

There is no approved `arm64 -> arm64e` fallback rule. Do not patch the stub,
force a subtype, strip pointer signatures, use an untyped dlsym cast, or switch
to a translated consumer to turn an unknown into support. Apple ld64 delegates
stub matching to TAPI with CPU/subtype and optional exact-subtype enforcement;
that published path does not settle this host's linker/dyld compatibility.
[Apple ld64 source](https://github.com/apple-oss-distributions/ld64/blob/main/src/ld/parsers/textstub_dylib_file.cpp).

Clang describes arm64e function-pointer signing and authentication. Matching
pointer width is therefore insufficient evidence for callback interoperability.
[Clang pointer-authentication documentation](https://clang.llvm.org/docs/PointerAuthentication.html).
The preferred containment design is a small Apple-ABI-facing C boundary inside
the collector, with typed callbacks compiled against the exact selected headers.
This is a design choice to reduce the qualification surface, not proof that a C
shim makes an arm64e consumer runnable. Direct Zig imports remain an alternative
only after that toolchain's exact callback/struct/PAC behavior is qualified.
Neither choice requires changing the workload compiler or forcing Zig's product
code to adopt the collector's ABI.

The collector owns libdtrace handles and callbacks. Its external boundary is a
versioned, length-delimited record stream; no libdtrace structure, function
pointer, handle or borrowed data pointer crosses into the Zig native request
model or the evidence evaluator. Collector failure becomes unavailable evidence,
never an alternative native compilation route.

![ABI containment](darwin-dtrace-abi-boundary.svg)

## Consumer Pipeline and Record Contract

The proposed lifecycle specializes the previous readiness/drain state machine:

1. **Describe:** record platform, collector ABI, SDK/library identities and
   supported decoder schemas. A header parse or DTRACE_O_NODEV open is not a
   device/permission check [N3].
2. **Discover:** inspect exact candidate probes, argument types and stability
   attributes. Iteration also reports declared definitions; enumeration alone
   is insufficient. Record compile flags and match counts; ZDEFS/EMPTY must not
   silently admit a required zero-match capability [N5].
3. **Prepare:** register error/drop handlers before capture, fix approved options
   and non-destructive actions, enable required probes, then establish readiness
   with independent controls. This step is future work, not an instruction to
   run probes in this research phase.
4. **Capture:** copy bounded event data and metadata synchronously into
   collector-owned storage; persist through a bounded queue with explicit local
   loss. Keep callback execution independent of target control and evaluator IO.
5. **Drain/seal:** prove the scoped end boundary, drain both DTrace and ES lanes,
   retain faults/counters and issue capability-specific verdicts. Library close
   or a successful consumer exit is not a completeness certificate.

Apple's published consumer moves `dtpda_data` from event base in the probe
callback to record address in the record callback. Adding `dtrd_offset` again
there would double-offset. Internal actions, including dynamic tracemem size,
can be consumed before record callbacks. Returning NEXT skips normal formatting
for ordinary records; THIS permits it. These details require a revision-bound
decoder, not a presumed one-callback-per-record ABI.
[Apple dt_consume.c](https://github.com/apple-oss-distributions/dtrace/blob/main/lib/libdtrace/common/dt_consume.c).

Design consequence: initially admit only explicit scalar fields and fixed-bound
payload actions whose complete layout has an independently checked recipe.
Defer dynamic/compound actions, printf/system/freopen, speculation, aggregation,
stacks and symbolization from the raw evidence profile. A callback is not an
escape hatch for arbitrary D programs. Disallow destructive actions and any
program option/action that changes output routing or target execution.

The decoder must check action allowlists, record count, total event size,
overflow-safe offset-plus-size, alignment and field signedness/byte order against
the selected descriptor/schema. Unknown combinations fail the capability rather
than guessing. At probe entry, copy the bounded event and metadata before any
borrowed pointer can outlive its callback; at record entry use the qualified
pointer convention. Do not mix those two acquisition modes. The schema records
which mode was used. Header comments about bitness-neutral kernel record
descriptions do not extend to every user-library callback structure [N3,N4].

The proposed envelope contains:

| Record group | Required information | Prohibited inference |
| --- | --- | --- |
| Session | Collector/schema versions; source, SDK, loaded-library and kernel identities; consumer and target ABI declarations; options and D recipe digest | SDK identity equals installed implementation |
| Probe manifest | Exact probe tuple/ID mapping for this session; argument and attribute evidence; matching/enabling/firing verdicts | Probe IDs are stable across boots/sessions |
| Raw event | CPU, original timestamp/domain, local receive ordinal, exact emitter fields, bounded raw bytes and descriptor/schema reference | Receive order is global execution order |
| Payload | Requested/returned/captured lengths, direction, iovec/chunk order, sample phase, copy outcome and fidelity class | Memory snapshot equals bytes consumed by kernel |
| Health | DTrace drop/fault classes, consumer queue/persistence loss, readiness/drain boundaries and missing controls | Zero principal-buffer drops proves complete capture |
| Association | Original ES reference, process/image generation witness, candidate joins and ambiguity verdict | pid/tid plus nearby time authenticates an ES join |

This is a wire-contract design, not a new on-disk artifact format implementation.
Kernel/libdtrace diagnostics and adapter parse failures remain separate records.
Unrecognized versions cannot silently decode with the previous schema.

## Probe Visibility and Admissible Scope

The qualification ladder is: **source mapped -> ABI eligible -> library
loadable -> device accessible -> probe visible -> required matches enabled ->
controlled firing/return ABI calibrated -> scoped fidelity/loss/association
admitted**. This turn establishes source mappings only. Later successful stages
must not retroactively fill earlier missing identity evidence.

| Candidate scope | What future qualification could admit | Boundary retained now |
| --- | --- | --- |
| syscall entry/return on selected unprotected processes | Event-local arguments and exact provider-specific result convention for calibrated syscall variants | No live inventory or firing proof; errno/return slots cannot be copied from pid/fbt conventions [N6] |
| proc spawn/exec failure candidates | A source-matched failure event and its actual emitter/argument meaning | CONFIG_DTRACE source does not establish an installed probe or complete launch-attempt history [N7] |
| User pid probes / function return | At most a separately qualified derived profile | Not selected for strict original observation; no proc_create/grab/continue/waitfor, injection, stopping or relaunch under debugger [N3] |
| Internal kernel fbt | Research hypothesis for a particular kernel build | No portable contract for spawn action identity, locked fd state or consumed bytes; excluded from initial supported scope |
| Protected/system executables | Only visibility positively established under unchanged policy | An unprotected fixture cannot qualify protected tools; archived SIP guidance identifies restrictions, not live availability [N8] |
| Scheme state delivery | No selected DTrace capability | OS events do not establish Scheme return/raise, continuation or barrier delivery; previous unresolved remains |

Qualify visibility per executable/process class, provider and operation variant,
including a negative control that must fire but is hidden/denied. An empty stream
is then visibility failure, not evidence that the workload performed no calls.
Do not turn on permissive unresolved-symbol or zero-probe flags to suppress that
failure. Root privilege alone cannot be treated as visibility proof. Observer
side effects on scheduling remain possible even when argv/env/cwd/fds are kept
unchanged; performance claims require a separate experiment.

## Spawn FD Actions: Recipe, Kernel Effects and Witnesses

Project source builds file actions for stdio inheritance, dup2, close and cwd,
with CLOEXEC_DEFAULT and a fallback path [N9]. These are expected recipes. They
are not a trace of which actions actually executed in a particular attempt.

Published XNU executes spawn actions internally, with close-on-exec cleanup
later. Its failure hooks carry an open path or fd, while final spawn/exec hooks
carry an error. They do not report a complete successful action sequence.
The source also distinguishes the constructing thread from the new image's
success context. [Apple kern_exec.c](https://github.com/apple-oss-distributions/xnu/blob/main/bsd/kern/kern_exec.c).

| Operation / state | Evidence required for an actual fd transition | Current disposition |
| --- | --- | --- |
| dup2 / close / inherit / chdir inside spawn | Action ordering, source/destination and actual outcome tied to the attempt and affected process | No separate userspace syscall event is guaranteed; full graph unresolved |
| CLOEXEC_DEFAULT / FD_CLOEXEC | Pre-state plus actual exec-time transforms and slot generations | Recipe flags and a successful EXEC cannot certify every closure |
| spawn-open/fd failure | Exact live probe ABI/emitter, failure stage and independent attempt join | Can become a local failure witness; does not prove earlier/later action effects or original libc errno |
| ES exec fd descriptions | Independently qualified ES image identity and documented subset | Partial anchors only; cannot establish the missing pre-exec graph |
| libc action initialization / add-action failure | Original userspace return witness | May occur before any kernel spawn; syscall/proc absence cannot supply its result |

Never decode the opaque posix_spawn_file_actions_t by assuming Apple's private
layout. Never infer fd ownership from an integer carried by a failure hook alone.
Keep observed edges, source-predicted edges and unknown edges as distinct types.
A complete attribution such as “these bytes were the query's stdout” additionally
needs endpoint identity and the fd lifetime proof across shell, tool and spawn.
For joins, retain constructing emitter and affected child separately; failed
spawn need not have any successful ES EXEC to join. No fabricated child image.

## Byte Capture and Qualified Claims

Use four explicit fidelity classes: **attempted user-memory snapshot**,
**completed-count-associated snapshot**, **kernel-consumed bytes**, and
**recipient-observed bytes**. Moving between classes requires new independent
evidence. Bounded tracemem/copyin plus a syscall return can at most support the
first two without a matching memory-stability/kernel-copy witness.

A write entry snapshot may precede concurrent mutation; a read return snapshot
may follow another thread's mutation. Iovec metadata can race separately.
Partial IO, EINTR/error and multiple writes require exact completion semantics,
not slicing a formatted string. NUL, non-UTF8, trailing newline and empty payloads
must survive as bytes. Reaching max_transfer_bytes/max_iov, missing chunks,
copy faults or unsupported variants produces an explicit incomplete verdict,
not a shortened “complete” record [N4,N6,N10].

Even a faithful channel sample does not automatically recover shell command
substitution after trailing-LF removal, tty rendering, a stdio user-space buffer
that never flushed, or Scheme delivery. A tty write is not proof of what a user
saw. Existing Q0-Q3 layers stay separate. There is no selected portable witness
for arbitrary kernel-consumed bytes or a complete spawn fd graph; neither is
made supported merely by choosing a native consumer.

![Scope qualification](darwin-dtrace-scope.svg)

## Adapter Qualification and Upgrade Gates

The following are proposed admission obligations, all **unresolved / not run**.
They specialize K01-K15 rather than promoting any E01-E32 or M2-M8 gate.

| ID | Independent qualification obligation | Failure verdict |
| --- | --- | --- |
| A01 | Each selected arm64/arm64e consumer profile: exact link/load eligibility, callback call/return behavior, ABI/layout and deployment rules | Unsupported/unknown profile, not a fallback to another ABI |
| A02 | Raw event base versus record address, descriptor layouts, callback lifetime and skip/format semantics against independent known binary records | Decoder unqualified, including double-offset or hidden-action mismatch |
| A03 | Per-target/probe inventory, attributes, positive/negative firing and compile match counts under unchanged protection | Invisible or unknown scope; empty trace cannot pass |
| A04 | Spawn failure variants, action failure and pre-syscall libc failure distinguished; emitter/affected-process identities independently established | Local witness only; full attempt and fd graph remain unresolved |
| A05 | Byte boundaries B-1/B/B+1, iovecs, NUL/non-UTF8, partial/error IO, mutation races, copy faults and drop/queue loss injection in separate controls | Snapshot class only or incomplete; no consumed-byte claim |
| A06 | ES cross-stream identity/clock relation, pid reuse/same-pid exec, missing/ambiguous joins and drain/health proof | Unattributed record or scope failure, never best-effort pass |

No control changes the original measured workload. Source-copy controls can
calibrate a mechanism but cannot stand in for original visibility/identity.
Record the exact qualifying controls and scope; a pass for write cannot qualify
writev, spawn or tty. Unknown protection/ABI changes invalidate eligibility;
kernel/provider, recipe, library/header or decoder changes invalidate affected
adapter receipts. ES version/muting/association changes invalidate the relevant
joins. Requalify the dependent scope rather than rewriting old receipts.

Observer identity belongs to evidence admission keys. It does not alter managed
profile argv or native artifact keys unless it actually changes a compiler input.
Zig's value here is ownership of a typed evidence boundary and failure isolation;
MLIR consumes neither private libdtrace ABI nor unqualified trace facts. Its
optimization legality continues to depend on Gambit's semantic contracts and
independent acceptance. This prevents a platform-specific research dependency
from becoming another permanent product build layer.
