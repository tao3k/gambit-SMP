# Darwin External Syscall/I/O Observer: Feasibility and Calibration

Date: 2026-10-20. **Design only.** No probe enumeration, tracing/client setup,
recorder, source hook, calibration or performance workload was implemented/run.
No privilege, SIP, audit, descriptor or terminal setting changed. Refines the
[supplemental evidence paths](darwin-supplemental-evidence-design.md) and
[L1/L2 study](darwin-recorder-observation-design.md). X1-X12 resolve in the
[source/platform ledger](darwin-external-observer-evidence.md).

The [native consumer and adapter refinement](darwin-dtrace-adapter-architecture.md)
expands K15/V9 into explicit arm64/arm64e, callback/record, probe visibility and
scope admission boundaries. It qualifies no runtime capability.

## 1. Decision: Four Independently Qualified Capabilities

Select a **conditional native DTrace-consumer research design**, using framed
records and independently qualified syscall/proc providers, alongside a separate
ES notification stream. Do not select shipped dtruss's text output as an oracle.
This is not a claim that these probes, permissions or data are available on the
current host. Exact provider/ABI/stability/coverage qualification precedes any
native claim; protected-process gaps cannot be fixed by assuming root is enough.

| Capability | What could supplement original evidence | Current verdict |
| --- | --- | --- |
| A failure returns | Covered syscall entry/return pairs and qualified proc failure events | Plausible for selected kernel failures; no live availability, return ABI or complete attempt attribution established |
| B binary payload | Explicit-length byte snapshots with accepted/read counts and copy-boundary proof | Bounded snapshots are a candidate; general kernel-consumed byte identity is unresolved, especially concurrent mutation/oversized traffic |
| C fd lifecycle | Successful fd operations, inherited descriptors and spawn/exec transformations, joined to open descriptions/endpoints | Userspace syscall records alone are insufficient for spawn transformations; no full original fd graph established |
| D ES correlation | Proven process-generation/thread/attempt/channel crosswalk plus independent stream completeness | Conditional; clean ES counters do not qualify the other stream, and timestamps/PID alone do not establish joins |

Qualify capability bits per observation scope, not one “observer works” boolean.
A trustworthy failed-open return can stand even when unrelated output bytes are
unresolved. Conversely a plausible stdout string cannot qualify unknown return,
channel or process identity. No capability has been qualified by this study.
Original Scheme continuation/exception commits remain outside the selected
external syscall/I/O contract.

### 1.1 Consumer Feasibility and Isolation

The installed SDK supplies `dtrace.h` raw-probe/record callbacks and explicit
drop/error handlers, plus a libdtrace link stub (X12). This is a concrete native
consumer candidate, not just a wish for structured CLI output. However the header
warns that these implementation interfaces can change; its ABI constant is not
a cross-release stability guarantee. The inspected stub lists x86_64 and arm64e,
not ordinary arm64. Header/stub presence proves neither linkability for the
project target nor successful runtime initialization. No build/link/load probe
was performed. Keep consumer architecture/ABI/toolchain compatibility unresolved.

Isolate any future consumer as a Darwin/version-bound **evidence adapter** with
its own raw-record and receipt protocol. It is not part of the normal Gambit/Zig
native compilation path and must not make product builds depend on tracing
privileges or libdtrace. Do not call the library's process-create/grab/continue
interfaces to control the original target merely because they are available.
A version/ABI change requires observer requalification and new evidence receipts;
it is not an automatic change to compiler argv or an epoch added to every native
artifact key. Observation provenance and semantic artifact identity remain separate.

## 2. Source-Grounded Feasibility

X1's shipped dtruss stores syscall arguments in thread-local state and formats
return/errno observations. Its read/write path converts copied memory into a
string. This supports a starting point for return observation, **not** binary
fidelity or full child/fd coverage. X2/X3 document distinct syscall versus
pid/fbt return arguments, raw trace-memory display and multiple buffer/drop/error
classes. A consumer must interpret those explicitly, not parse a human command
line or treat every arg0 as the same ABI.

X4's public XNU `kern_exec.c` applies spawn file actions internally, including
fd changes and delayed close-on-exec. It also contains error-bearing spawn/exec
failure probes under CONFIG_DTRACE. These are useful candidate boundaries, but
rolling published source is not this host's kernel or a runtime probe inventory.
Failure probes do not cover all earlier libc preparation failures or supply a
complete action/payload trace. No live probe name/argument contract is admitted.

X5's actual materialized Gambit uses POSIX_SPAWN_CLOEXEC_DEFAULT, standard-fd
inheritance checks, dup/close actions and a cwd action. The fallback closes and
rearranges descriptors before exec. This makes spawn fd transforms a real
project requirement, not a hypothetical edge case. Source-derived expected
transforms are an independent invariant; they are not observed original actions.

## 3. Failure Return Contract

### 3.1 Capture Boundaries and Pairing

A proposed original observer records probe ID/provider/version, caller execution
crosswalk, TID, per-thread attempt ordinal, syscall/API kind, entered argument
scalars/path snapshot refs, and complete return convention. Store unsigned raw
probe slots plus a separately interpreted signed result. Capture errno only at
a boundary whose definition makes it the current operation's error. A successful
call must not inherit an old errno and be classified failed.

- **syscall entry/return:** selected Darwin ABI/version must be independently
  calibrated; include actual variants such as nocancel, relative-path and vector
  I/O calls where used. Omitted variants are a capability hole.
- **exec success:** may not produce an ordinary return to the old image. Close
  its pending attempt only through a qualified success/image-transition edge,
  not a fabricated return. Failed exec remains in the caller's current image.
- **proc spawn/exec failure probe:** use only after proving actual provider,
  argument meaning, emitter identity and coverage. Do not duplicate-count a
  failure also seen at syscall return; associate records to one attempt.
- **libc or Gambit preparation:** syscall observation cannot prove an API result
  that occurred before any syscall, or every final execvp result after PATH
  searches. Those fields retain the supplemental design's unresolved status.

X2 says syscall return slots differ from pid/fbt function return slots. X5 also
converts posix_spawnp's **function return code** to an OS error. A kernel-probe
return, a libc return, errno, child EXIT and Scheme fixnum are separate values.
Never silently translate one into another. The failure's child PID output is
undefined where the API failed; do not correlate it with an unrelated ES child.

The observer needs reentrancy-safe pairing, including interrupted calls,
restarts and nested provider observations. A single saved “last call” slot is
not sufficient when stacking different providers or losing an entry/return.
A missing half invalidates that attempt; no later return is attached by proximity.

### 3.2 Candidate Failure Claims

| Covered fact | Could close, if calibrated | Cannot close by itself |
| --- | --- | --- |
| Failed exec syscall return in known caller generation | That attempted syscall's failure/result | Complete execvp PATH search or final library error, Scheme delivery |
| Qualified spawn-failure proc probe | Kernel failure at that probe's stage | Every file-action/attribute setup failure, exact original fd transformation |
| Failed open/read/write on known fd/endpoint | That operation's return and defined errno | All diagnostic bytes, terminal display or branch that chose the operation |
| Native wait-related observation in original parent | Covered wait outcome and ownership evidence | Correct Scheme device association/continuation or barrier commit |

Existing retained audit records are optional corroboration, not assumed present;
legacy audit selection and permissions remain outside this design's changes.
No syscall/observer is launched with a wrapper that changes target credentials,
PATH, argv, env, parent, descriptors or controlling terminal.

## 4. Binary Payload Contract: A Snapshot Is Not Yet Written Data

### 4.1 Record Format and Declared Bounds

Use a native consumer of fixed, versioned raw records rather than `%s`,
copyinstr, JSON string conversion or dtruss text. A proposed payload frame has
operation key, direction, byte boundary, source address category, explicit byte
count, total transfer length, chunk offset/length, captured bytes, copy outcome
and end-of-frame checksum/commit. NUL/non-UTF-8/delimiter bytes are ordinary data.
Do not log target memory outside the specified I/O region to fill gaps.

An observer profile declares `max_transfer_bytes`, `max_iov_count`, per-record
chunk capacity and total in-flight budget. These are **admission bounds**, not
values measured or selected here. Test B-1/B/B+1 at each bound. Unknown/unbounded
original traffic does not become supported because a larger buffer was chosen.
An over-limit operation is marked incomplete/unresolved, not clipped and passed.
This study implements no chunking/probe loop and assumes no unlimited dynamic
copy support from DTrace. Provider/compiler constraints themselves need proof.

Capture failures, bad user addresses, scratch exhaustion, dynamic-state loss,
principal-buffer loss, writer/decoder loss and partial final frames all need
explicit status. X3 distinguishes several of these; “no warning on stdout”
is not a loss counter. Exact evidence requires all relevant counters/records,
bounded start/end and completed persistence. Buffers using ring overwrite/fill
stop/switch each need a separate completeness argument; none guarantees no loss.

### 4.2 Byte Semantics by Operation

| Operation | Minimum observations | Remaining proof requirement |
| --- | --- | --- |
| write/pwrite | Entry buffer snapshot and request length; paired successful/failed return | `n > 0` accepts n bytes, not the requested whole length. Entry snapshot equals kernel-used bytes only under a qualified stable-buffer/copy-boundary contract |
| read/pread | Destination pointer/length at entry; returned n and binary snapshot of returned range | Snapshot must precede any user mutation/reuse; original programs may have another thread sharing memory. EOF is n=0, not a missing record |
| writev/readv | Bounded iovec descriptor snapshot, ordered segment refs/lengths, total returned count and relevant bytes | Account for partial completion across vectors, overflow and descriptor/buffer mutation. Never emit every requested vector as successful data |
| retry/interruption | Complete paired outcomes and new attempt ordinal | Negative return contributes no presumed bytes; short positive completion and retry cannot be counted twice or assumed contiguous without ordering proof |
| pipe/tty | Above plus actual endpoint/lifecycle/terminal context | Accepted writer bytes, reader bytes, tty line discipline and rendered text are distinct claims |

A syscall entry memory copy occurs at a different instant from the kernel's own
copy. A return-time copy of a write buffer may be even later. Hash-equal captured
snapshots do not prove memory was immutable between snapshots. Likewise read
return data can be changed by another thread before observer copying. Calibration
can expose these hazards but cannot prove every original program race-free.
General binary fidelity therefore remains unresolved until a safe observation
boundary or defensible input-domain restriction is established. Internal FBT or
kernel-copy hooks are not selected as a stable supported remedy merely because
published source has internal functions; exact kernel/ABI/permission/stability
and noninterference would need separate qualification.

For a bounded, source-justified stable-buffer domain, entry/return data might
supplement original query bytes. That domain is a prerequisite, **not inferred
from successful sample runs**. Without it label records `observedSnapshot`, not
`provenWrittenBytes`. Even perfect Q0/Q1 acquisition does not expose Q2 shell
values or Scheme commits directly. Existing sink receipts remain scoped to the
layer they actually captured.

## 5. Descriptor State: Three Identities and a Partial State Machine

Separate process instance, execution image, fd slot, open description and
endpoint. The fd number 1 is not a pipe identity; a pathname is not an open
description; duplicate fds may share one underlying object. Suggested records:

```text
ProcessInstance = {host, boot, birthEvidence, pid}
ExecGeneration = {ProcessInstance, ES audit token / qualified crosswalk}
Slot = {ProcessInstance, fdNumber, slotGeneration, imageEpoch}
Description = {observerObjectToken, creationEvidence, lifetimeEvidence}
Endpoint = {kind, pipeReadOrWrite?, objectEvidence, terminalOrFileEvidence?}
FDState = Unknown | Open(Slot,Description,Endpoint,flags) | Closed | Ambiguous
Transition = {operationKey, beforeRefs, actualOutcome, afterRefs,
              sourceBoundary, provenance, coverage}
```

FD state **survives exec except where transformed**; a new image ID does not
reset the fd table or automatically allocate a new underlying open description.
Pointer-like observer object tokens cannot be assumed lifetime-unique; reuse and
kernel structure ABI must be qualified. Unknown inherited slots remain Unknown.

| Transition | Required actual evidence | Conservative update / ambiguity rule |
| --- | --- | --- |
| open/openat/other creator | Successful return and actual fd; object identity where available; directory-relative context | New slot generation; same path does not merge descriptions. Failed open does not invent a slot |
| pipe/socketpair | Success plus complete returned fd pair and endpoint roles | Pair endpoints from output arguments only after success; scalar return 0 alone is insufficient |
| dup/dup2/fcntl duplication | Result, source slot, replaced target where applicable, descriptor flags | Share description; preserve atomic target replacement semantics; same-fd dup2 must not be miscounted as arbitrary close/new object |
| fcntl F_SETFD/F_SETFL etc. | Command/argument and success outcome | Descriptor flag versus shared status flag distinctions preserved; observed command name alone is not a change |
| close/closefrom/guarded or bulk close | Applicable variant, outcome and all affected slots | Do not apply Linux retry assumptions. Interrupted/uncertain close semantics need platform qualification or mark slot Ambiguous |
| fork/vfork/related creation | Child identity and complete parent table snapshot at semantic inheritance boundary | Copy slot references, not new descriptions. Shared-table cases require distinct handling; unsupported variants reject graph completeness |
| posix_spawn file actions | Qualified successful child table/transform witness; flags/actions in order and actual outcome | Outer syscall list alone cannot synthesize all kernel fd mutations; immutable source recipes provide expected invariants only |
| exec close-on-exec | Exact successful image edge plus established flags/action effects | Preserve surviving description refs; drop only proven-closed slots; ES subset fd list cannot fill unknown entries |
| exit | Correct process instance and complete lifetime edge | Retire its slots; other processes may retain descriptions/endpoints, so EOF is not inferred from one writer's exit |

Process-table acquisition beginning after launch may miss original stdin/stdout/
stderr or preexisting package pipes. Polling proc fd APIs can corroborate a
snapshot but races with operations; it cannot recover omitted history or impose
an atomic cut on multithreaded changes. Any root unknown can taint downstream
channel attribution even while an individual write return remains usable.

### 5.1 Spawn Is a Hard Boundary, Not Just Another Fork

The materialized Gambit uses spawn file actions and CLOEXEC_DEFAULT (X5).
The installed action manual describes transformations performed before child
execution (X6). Inferring “all open/dup/close syscalls captured, therefore fd
history complete” is invalid for this route. A direct child-table snapshot with
qualified coverage, or a qualified transform observation at an appropriate
boundary, is required. Neither is available in this study. Copying a user-level
opaque posix_spawn_file_actions_t memory layout is not a portable/public ABI
solution; the installed spawn header types it as an opaque pointer.

ES exec may return only a subset of descriptors (X8). Its last_fd is not a full
fd count or complete table. A post-exec poll cannot establish the table at exec
without a race argument. Stopping the child to make a snapshot stable changes
the control context and belongs to an instrumented lane, not strict L2.

### 5.2 Concurrency and Ordering

Syscall entry order is not a universal fd-state linearization order. Two threads
can close/reuse/dup/write while their syscall intervals overlap. Per-CPU records
and sorted timestamps cannot resolve a descriptor-table race automatically.
Apply a transition only with sufficient actual ordering/outcome evidence; keep
alternative possible graph states or mark the affected association Ambiguous.
No global ordering is invented to make the graph deterministic. Initial
calibration includes controlled sequential cases **and** overlapping operations;
passing sequential examples does not admit concurrent original workloads.

## 6. ES Cross-Stream Association and Collector Protocol

Attach records to the existing `ExecKey`, `AttemptKey`, `ChannelKey` and `Join`
contracts from the [supplemental design](darwin-supplemental-evidence-design.md).
Use a qualified process-birth/image crosswalk, not PID/PPID/name matching alone.
The DTrace manual exposes pid/tid/timestamps; it does not establish an ES audit
pidversion field in every syscall record. A kernel-derived generation token
would require a verified source/ABI/availability contract; no private offset is
assumed. Fork/exec continuity must disambiguate inherited processes and same-PID
image changes before any ES join is accepted.

Thread IDs additionally need an exec/lifetime scope. Pair local ordinals within
that scope; resolve successful exec without an ordinary return using actual
image transition evidence. Timestamps from two streams require epoch/clock
semantics and uncertainty metadata, but remain consistency checks, not unique
keys or cross-CPU linearization. ES process/target identity must not be mistaken
for the spawning parent's userspace API frame.

Proposed native consumer phases:

```text
Unqualified -> Ready -> ScopeAnchored -> Capturing -> Draining -> Sealed
                    \-> Unresolved/Invalid on coverage or identity failure
```

Ready requires actual provider/ABI/privilege/stability evidence and ES readiness.
ScopeAnchored requires subscription/probe coverage before the original parent
starts, independent fences and known initial process/fd state for relevant claims.
The observer is a separate process; no target launcher replacement, credential
change, DYLD injection, extra fd, logger env/argv or signal/reaper is introduced.
It may consume resources, so zero scheduling/performance perturbation is unclaimed.

Persist raw probe/event metadata and immutable binary records in observer-owned
storage outside target cwd/source/search roots. Record per-CPU buffer epochs,
probe IDs, dynamic-state errors/drops, consumer/write errors and complete commit
boundaries. Preserve ES versions/subscriptions/mutes/counters separately. Sequence
numbers added by the consumer detect consumer loss only, not ungenerated/missed
probes. Readiness/fence/drain cannot cure invisible or unsupported variants.
A case with an unexplained loss is not repaired by timestamps or a larger retry.

Sealed means the claimed capability's fields, joins, counters and tail coverage
are complete. It does not mean all other capabilities passed. If syscall data
are sound but the process-generation crosswalk is ambiguous, retain the local
fact but withhold the ES/request attribution. If channel history is partial,
withhold query/tty attribution even if that tool's successful EXEC is known.

## 7. Calibration Conditions (All Proposed, None Executed)

Controlled launchers/leaves have independent expected vectors, byte payloads,
fd operations and designated completion witnesses. They are fixture contexts,
not the unchanged original pipeline. Ground truth must not come from the new
profile renderer, observer's own reconstruction or identical parser code.

| ID | Control | Required acceptance / deliberate failure sensitivity |
| --- | --- | --- |
| K01 | Provider/ABI census for selected host/architecture and target classes | Exact names/arguments/stability/protection coverage bound before claims; declarations or published source are not a live census |
| K02 | Success, ordinary errno failures, nocancel/relative-path variants | Per-boundary signed return/errno/API distinctions; stale errno and swapped slots rejected |
| K03 | Failed exec versus successful image replacement, spawn setup versus kernel failure | Missing return on success not fabricated; proc/syscall duplicates merged only by proved attempt relationship; no-child claim not inferred from missing EXEC |
| K04 | NUL/non-UTF-8/newline/all byte values and zero-length transfer | Counted bytes round-trip exactly through probes/consumer/storage; no C-string conversion or pretty-print parser |
| K05 | B-1/B/B+1, vector limits, scratch/dynamic/principal/consumer loss | Over-limit/copy fault/loss explicitly invalidates affected claims; no accepted clipped or silently overwritten payload |
| K06 | Short I/O, error, EINTR/retry, EOF, vector partial completion | Returned count governs accepted/read range; negative returns and requested unused suffixes never added as delivered bytes |
| K07 | Shared-buffer mutation and iovec mutation during blocked/overlapping I/O | Detect or explicitly refuse unsupported fidelity; equal endpoint snapshots are not proof of kernel-used data |
| K08 | pipe pair, openat, dup2 replacement/same-fd, fcntl flags, close/reuse | Actual output arguments and shared-description/slot generations correct; mutated/missing transition rejected |
| K09 | fork/exec inheritance, CLOEXEC and Gambit-like spawn action ordering | Kernel actions not guessed from absent syscalls; partial ES fd list or post-exec polling alone cannot pass |
| K10 | Concurrent fd-table operations and reused kernel object/PID/TID values | Proven ordering/identity or Ambiguous result; timestamp sorting and pointer equality must fail negative controls |
| K11 | ES plus syscall streams with lost birth/exec/fork or duplicated names/argv | Audit-generation crosswalk exact; PID/name/time-only false joins rejected; one stream's counters cannot certify another |
| K12 | Start/stop/drain, observer restart, missing final chunk, dropped return | All affected records retain incomplete status; quiescence timeout/empty log never becomes no-effects proof |
| K13 | Existing tty versus absent tty, command-substitution query output | Writer bytes/channel/shell value/visible transcript kept distinct; no new PTY or pipe claimed transparent |
| K14 | Source/tool/launch-context identities and independent record mutations | No target perturbing controls; comparator rejects changed return/byte/slot/join, but these checks do not themselves prove live capture coverage |
| K15 | Native consumer target/ABI/library lifecycle | Independently qualify the selected architecture, library/header version and raw/error/drop callbacks; no arm64 support inferred from an arm64e stub; observer upgrades require new receipts, not modified compiler inputs |

Record-level negative controls validate comparator sensitivity; controlled
kernel/user-memory cases validate acquisition boundaries. Neither finite sample
set alone proves all possible races safe. Domain restrictions require independent
justification and explicit capability metadata. No benchmark or native tool
pipeline is run to discover those restrictions in this document work.

## 8. Original-Evidence Admission and Unresolved Register

| ID | Claim after future qualification | Current status / cannot substitute |
| --- | --- | --- |
| V1 | Selected syscall return/defined error in a known caller generation | Unresolved: no live ABI/provider/visibility/pairing or generation proof; potential supplement to failed-attempt parts of E29 |
| V2 | Bounded observed byte snapshot | Unresolved: no raw recorder/copy/size/loss calibration; would prove only the named snapshot boundary |
| V3 | Kernel-consumed write / delivered read bytes | Unresolved: stable-buffer or safe copy-boundary proof absent; snapshots alone insufficient for E20/E22 byte parity |
| V4 | Complete original fd/channel history | Unresolved: inherited state, spawn kernel actions, exec closures and concurrent linearization not witnessed; ES subset cannot close it |
| V5 | Exact syscall-to-ES-to-request association | Unresolved: crosswalk/loss/epoch/identity unqualified; timestamps not a replacement |
| V6 | Original query or tty writer/destination and full stream | Unresolved unless V3/V4/V5 and terminal/output-layer coverage hold; final argv/log text is not original hidden output |
| V7 | Final libc launch error or Scheme continuation/exception/barrier | Outside a generic syscall-only observer; original user-level witness still missing; L1 source-copy evidence stays separate |
| V8 | No change to explicit launch/control context | Unresolved until capture context audit; stopping/wrapping/injecting remains derived. No zero scheduling perturbation claim selected |
| V9 | Native consumer architecture/library API | Unbuilt/unlinked; SDK private-interface warning and x86_64/arm64e stub require actual target/ABI qualification; no stable product dependency selected |

All V entries remain open at this checkpoint. This refines previous R1-R7 and
U6-U8; it closes none. A calibrated, visible, identity-bound kernel failure
record **can in principle add original evidence** without replacing the target;
a text trace or plausible fd reconstruction cannot. M6/M7 need both action and
channel/error scope; M3/M4/M5 retain Scheme and barrier obligations. No M2-M8
retirement or E-row pass follows from platform/source feasibility alone.

[Capability/collector D2](darwin-external-observer.d2) / [SVG](darwin-external-observer.svg),
[fd/ES association D2](darwin-fd-es-association.d2) / [SVG](darwin-fd-es-association.svg).
