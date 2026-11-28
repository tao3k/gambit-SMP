# Darwin Supplemental Evidence: Failures, Output and Scheme Delivery

Date: 2026-10-20. **Design only.** No tracing, audit initialization, recorder,
source hook, native command or performance validation was implemented/run.
No permissions, SIP, audit policy, descriptors or terminals were changed.
Refines [L1/L2 feasibility](darwin-recorder-observation-design.md) and
[independent E01-E32 evidence](independent-equivalence-evidence-plan.md).
F1-F12 in the [source/platform ledger](darwin-supplemental-evidence.md) identify
actual sources; all acquisition mechanisms below remain unqualified.

## 1. Decision: Supplement by Boundary, Not by Guessing from ES

The ES lifecycle stream is the process-identity spine for successful exec/exit.
It is not a stream of failed API calls, output bytes or Scheme continuations.
Select three evidence paths with distinct claims:

1. **Original retained channels:** read already-produced, complete, source-bound
   logs/receipts from the unchanged baseline where they exist. Do not add a new
   sink and call it retained. A final compile-error log proves a visible message,
   not the exact underlying errno or the Scheme value that caused it.
2. **Conditional external observation:** a separately qualified syscall/error/
   I/O observer may supplement ES without changing target argv/env/binary/parent.
   Its visibility, byte capture, loss accounting, API-versus-syscall meaning,
   fd/process identity and protected-process restrictions must be established.
   Neither shipped dtruss nor ES alone supplies this whole capability today.
3. **Source-instrumented controlled evidence:** bound copies of Gambit/Gerbil or
   query leaves can expose precise return/string/delivery points and independently
   compare native wait outcomes. This is derived L1 evidence, never original L2.
   Pair it with source invariants and L3 native acceptance without relabeling it
   as an unchanged original binary observation.

Where no qualified original boundary exists, the strict original-run claim
stays **unresolved**. This study does not relax E29 or any M2-M8 retirement gate
just to substitute source reasoning or an instrumented success for missing data.
A scoped successful-exec claim can progress independently of unresolved internal
Scheme/error/output claims. Zero scheduling perturbation remains unclaimed.

## 2. Failed Launches: Separate API, Kernel, Child and Scheme Errors

### 2.1 What the Existing Code Actually Delivers

| Boundary / source | Observed source behavior | Evidence implication |
| --- | --- | --- |
| Darwin preparation and spawn, F1 | File-action/attribute helpers store the first nonzero result; posix_spawnp is called only while spawn_errno == 0; its returned error is copied to errno before err_code_from_errno | A setup failure can prevent any spawn syscall. Capture stage + function return, not just an unrelated thread-local errno or absence of EXEC |
| Darwin route selection, F1 | Pseudo-terminal request or bare executable name with explicit child env can select fallback instead of spawn | Bind branch, PATH policy and child env; a controlled pseudo-terminal case cannot represent original non-PTY launch |
| Fallback child, F2 | chdir then execvp; on exec failure, child writes errno to private error pipe and exits 1; chdir failure uses sentinel 0 | Target tool may never start although a fork child exists. EXIT(1) of the fallback child does not reveal failed exec errno |
| Fallback parent, F2 | Reads error pipe: full integer gives OS error or cwd sentinel; partial nonzero read gives unknown error; EOF selects process-device setup | Observer must not read, duplicate-and-read or redirect that pipe. It is an active protocol with one intended consumer |
| Scheme run-subprocess, F3 | A fixnum error can be delivered to cont when requested, or raised; sentinel 1 is mapped to ENOENT for directory failure | Scheme delivery may intentionally discard original chdir errno. Cannot invert final ENOENT to the actual kernel error |
| Shell/direct native failure, F4/F5 | Shell may transform a failed command into a shell status; Gerbil invoke raises on delivered nonzero status | Compiler failure, shell failure and Gambit launch failure are distinct. One outer exit code is not their common oracle |

Current SDK spawn manual and Apple's archived manual specify nonzero function
error with no child created for that spawn failure (F7). This does not rule out
other children or earlier preparation errors. execve returns only on failure;
execvp may try multiple PATH candidates. Do not import another OS's spawn error
model into this Darwin baseline. Bind actual native route and pinned platform.

### 2.2 Proposed Independent Failure Witnesses

| Path | Required record | Scope and remaining limit |
| --- | --- | --- |
| Qualified external syscall observer | Per-thread entry/return for relevant fork/exec/spawn/chdir calls; return convention, errno where defined, attempted path/vector refs and caller identity | Candidate for original kernel failures only. A C library preparation error or final execvp/posix_spawnp API return is not automatically a corresponding kernel-return event |
| Already-existing audit trail | Exact event selection/policy, raw record/header/subject/return tokens and lifecycle coverage | Existing records may corroborate selected failures. SDK event constants do not prove events were enabled, emitted or complete; no trail inspected here |
| Source-instrumented Gambit copy | Before/after each checked preparation function; actual spawnp return; fallback error-pipe write/read results; converted OS error and delivered Scheme outcome | Precise source-bound L1 route evidence; source/tool identity changed. No extra reader of the real original error pipe |
| Explicit calibration launcher | Own failed exec/spawn/cwd fixtures and designated wait result, compared to the observer | Qualifies observer conventions/coverage for those fixtures, not original call-path delivery |

Local audit manuals say the legacy BSM subsystem is deprecated since macOS 11
and disabled since macOS 14 (F9). No live state was checked. Do not enable it or
alter argv/arge/failure selection globally for this design. Policy changes can
alter overhead and even failure behavior; existing retained records are an
optional corroboration path, not the selected universal collector.

For syscall observation, require entry/return pairing and platform-specific
return decoding, including nocancel/ABI variants as relevant. Failed libc spawn
returns an error number; failed exec syscall returns failure with errno. Those
encodings are not interchangeable. Failure at attribute/file-action setup may
need a user-level boundary absent from an original syscall stream. Neither an
ES AUTH decision nor a missing NOTIFY_EXEC is evidence of that return value.

## 3. Query stdout/stderr and /dev/tty

### 3.1 Define Four Output Boundaries

- **Q0 producer write:** query/tool or shell builtin bytes attempted on a specific
  fd; attempted length differs from accepted length on error/short write.
- **Q1 channel delivery:** bytes accepted/read through the actual pipe/file/tty;
  establish descriptors, endpoints and their generations, not merely fd 1 or 2.
- **Q2 shell value:** command-substitution result after shell transformations,
  then the old accumulation/word-decoding stages. In particular trailing-newline
  removal means Q0 cannot be reconstructed from the final option string.
- **Q3 visible diagnostic:** outer stderr/stdout/controlling-terminal presentation,
  potentially with terminal processing and unrelated writers. Q3 is not Q0/Q2.

F4 queries cflags then libs under set -e using command substitution. stdout is
consumed inside the shell; stderr follows its inherited destination unless the
route changes it. Unsupported metadata and unavailable package-tool warnings
write to `/dev/tty`. No package executable starts for the unavailable-tool
warning. The writer is the shell execution performing the builtin/redirection,
possibly a subshell; it cannot be found by filtering only pkg-config processes.

The ES WRITE event has a target file field, not a payload buffer/byte-count/result
record (F6). OPEN may identify an opened file but is not a successful returned-fd
record. These cannot recover Q0-Q3. Do not equate a file notification with a
successful full write or assume all pipe/tty traffic has matching file events.

### 3.2 Acquisition Choices and Their Costs

| Path | What it could establish | Why scope must be limited |
| --- | --- | --- |
| Existing complete file/terminal transcript | Bytes actually saved at that pre-existing sink, with source/run/sink identity | Not internal query stdout or post-substitution value; concurrent writer attribution/termios/rendering may be missing |
| Qualified external I/O observer | Entry-buffer snapshot plus actual read/write/writev results, fd lifecycle and accepted/read byte counts | Pointer/string logs are insufficient; copy faults, caps, concurrent buffer mutation, partial writes, retries, missed fd operations or event loss invalidate byte-complete claims |
| Controlled query leaf / instrumented shell fixture | Explicit query stdout/stderr bytes/status; source-bound shell values and selected options | L1 only, under its declared descriptor and source changes; empty actual PKG_CONFIG profile cannot prove a successful real query |
| New tee/pipe/capture redirection | A new captured stream | Changes fd types, buffering, backpressure, SIGPIPE and sometimes isatty behavior; derived context, not transparent original L2 |
| New script/PTY wrapper | A new terminal transcript | Changes parent/session/controlling-terminal topology and terminal behavior; cannot represent a no-tty original or original /dev/tty failure |
| Duplicating and reading an existing pipe/tty | Consumed bytes from the shared channel | Not passive observation: can steal data; no selection as a supplement |

Select read-only acquisition of **already-existing sinks** where available.
For original Q0/Q1 still hidden in pipes, a new syscall-byte observer is only a
research candidate. Shipped dtruss's read/write formatting uses string conversion
of copied data (F10); even if some bytes appear, it is not a lossless framed stream
oracle. Write acceptance count and failure errno must be paired with a bounded
snapshot; return-time memory is not necessarily the memory consumed by the kernel.
Concurrent mutation or incomplete kernel-copy semantics keeps exact bytes open.
A read witness must capture the data actually returned before later mutation,
with its own capability proof. Do not silently concatenate attempted writes
whose returned counts were smaller or negative.

For channel identity, require a complete lifecycle graph for pipe creation,
open, dup/dup2/fcntl duplication, close, fork inheritance, spawn file actions,
exec close-on-exec and fd reuse. An fd is scoped by process execution and an
open-generation. The ES exec fd list can be partial; it cannot complete this
graph by assumption. Missing Q0/Q1/Q2 evidence stays missing, even if final argv
matches. `/dev/tty` uses controlling-terminal semantics rather than “whatever
stderr points at”; creating a tty to make a warning succeed changes the case.

Terminal output further separates writer-requested bytes, line-discipline bytes,
PTY-master stream and rendered screen text. A screenshot or transcript without
raw/channel/termios provenance does not prove exact warning bytes or writer.
If no controlling tty exists, retain the redirection failure as its own outcome;
never synthesize the missing warning or assume warning write succeeded.

## 4. Scheme State Delivery: Follow the Actual Value, Not the Exit Label

Source chain for the pinned POSIX vendor path (F2/F3/F5):

```text
SIGCHLD handler waitpid(-1, WNOHANG)
  -> process-device status_set(raw wait status), got_status
  -> os_device_process_status returns #f or raw fixnum/error
  -> ##process-status waits/loops, returns value or raises I/O/timeout exception
  -> ##run-subprocess continuation or Gerbil invoke receives status/error
  -> ##compile-file / ##build-executable / invoke raises or returns product
  -> Gerbil job completion/publication and executable link barrier
```

F3/F5 return the stored raw status on the inspected POSIX path; do not substitute
an 8-bit decoded exit code when comparing the Scheme value. Spawn errors before
a process port exists use the other fixnum-error/exception branch. Zero/nonzero
classification is used by callers, but that does not prove internal value equality
or distinguish signal termination from a normal nonzero exit.

The process wrapper also reads/drains its process port before delivering status
in the inspected branches (F3). A native exit event can therefore precede stream
completion or user-level delivery. A descendant retaining a pipe endpoint is a
possible source of delayed EOF; do not reinterpret a missing delivery as a
known Scheme error without stream/continuation evidence. No new timeout is added
to force that ambiguity into a result.

An ES EXIT with wait-format stat corroborates the native child's termination.
It does not prove which device accepted it, whether a continuation ran, which
exception reached the user, whether cleanup succeeded, or which object-job
completion allowed/prevented a later link. A later link absence is not alone a
proof the correct barrier executed; observation coverage must also be complete.

Proposed independent source-copy instrumentation records at four locations:
status_set commit, ##process-status return/raise, immediate caller branch, and
job publication/barrier decision. The record must bind port/device association,
child process identity, source location and native status, with a monotone
per-request ordinal. It must retain error and timeout paths, reentry/retry count,
cleanup outcomes and whether the continuation/consumer actually ran. No semantic
change, extra wait or suppressed exception is allowed **within that derived
fixture**. Observer recording failure invalidates evidence, not application success.
No such source hooks were written here.

A bounded search of the relevant C/Scheme/process/driver files found no known
DTRACE_PROBE/STAP_PROBE/USDT/TRACEPOINT sites for these delivery boundaries.
This does not prove no probe exists anywhere in Gambit. There is no identified
stable original-binary probe for these Scheme values. Debugger/memory/source
hooks can help L1 diagnosis but need binding to optimized code, GC representation
and signals; they are not selected as unchanged-context original observations.

Retained external exception logs may establish the visible outcome, when exact
run/sink provenance and contents survive. A new Scheme wrapper catching/logging
exceptions changes call/dynamic context and is a derived test. Source invariants
plus instrumented evidence plus original L3 acceptance can support a bounded
architectural argument, but strict original internal-delivery observation remains
unresolved until its own trusted boundary is available. No second waitpid caller
is introduced into Gambit; only designated calibration parents reap their children.

## 5. Correlation with ES: Explicit Edges, No Timestamp Guessing

Use the following **proposed inert records**, not log formats already implemented:

```text
ExecKey = {hostId, bootScope, auditToken(pid,pidversion)}
AttemptKey = {callerExecKey, threadIdentity, localAttemptOrdinal, observerEpoch}
LaunchAttempt = {AttemptKey, stage, apiOrSyscall, inputsRef,
  returnConvention, returnValue, errnoIfDefined, childPidIfValid,
  parentAttemptRef?, observationCoverage}
ChannelKey = {ownerExecKey, fdNumber, openGeneration, endpointIdentity?}
ChannelTransfer = {AttemptKey?, writerOrReaderExecKey, threadIdentity,
  ChannelKey, syscallOrdinal, requestedCount, actualCount, rawBytesRef?,
  byteBoundary, errnoIfDefined, provenance, observationCoverage}
Delivery = {sourceRevision, requestOrdinal, devicePortAssociation,
  childExecKey?, rawNativeStatus?, SchemeValueOrExceptionRef,
  callerBranch, outputOrBarrierDecision, provenance}
Join = {leftRecord, rightRecord, relation, proofFields,
  confidence: exact | ambiguous | unavailable}
```

| Association | Required evidence | Refuse to infer |
| --- | --- | --- |
| Successful spawn/exec to ES image | Valid child PID on success, audit birth/exec identity and parent/fork lineage, unbroken coverage | Spawn failure's undefined pid value is never a child identity; basename/time proximity is not a join |
| Failed exec attempt | Pair entry/return by caller execution + thread + local ordinal; fork lineage when fallback child exists | No post-exec image is invented. Failed exec leaves the current image; unrelated same-PID history does not identify the requested program |
| Libc preparation to syscall | Source/ABI-qualified function boundary and causal invocation relationship | Do not synthesize a syscall for an early file-action/attribute helper failure or map kernel errno directly to final library API result |
| Query output to cflags/libs action | Exact successful query exec or failed attempt, argv role, channel lifecycle and child/shell associations | Identical query argv can repeat/concur; time-order matching or package text alone is ambiguous |
| tty warning to source condition | Shell execution identity + descriptor/redirection/channel record + covered branch/value evidence | Source warning text or ES OPEN is not proof bytes were written successfully, or which request emitted them |
| Native termination to Scheme delivery | Correct exec generation and device/port/request association, observed return/raise/branch commit | ES EXIT alone cannot create Delivery; no PID-only matching after reuse or shell image replacement |

No request labels are exported into argv/env solely for correlation. L1 source-copy
records may carry source-owned request ordinals, but that newly observable mapping
does not exist in the unchanged original. External syscall observers often expose
PID/TID without an audit pidversion: a lifecycle crosswalk must be independently
proved; if birth/exec boundaries are missing, the join is ambiguous. ES message
process and target describe different image executions; do not mistake either
for the spawning parent's API-call identity without lineage evidence.

Use existing ES event times only as consistency checks, not unique keys. A global
clock offset estimate cannot repair ambiguous repeated calls. Fork, exec, syscall
and I/O streams have separate loss models. Require an unbroken scope/coverage
argument on **each** stream; clean ES sequence counters cannot certify a DTrace,
audit, file or source-record stream. If a required join is ambiguous, the joint
claim is unresolved even when every individual record is well-formed.

## 6. Calibration and Negative Controls (Not Executed)

| Case | Controlled supplement comparison | Required failure detection |
| --- | --- | --- |
| S01 launch stage | Absent executable, bad cwd, missing PATH candidate, preparation helper failure, fork failure | No accidental promotion of child EXIT(1) into exec errno; setup failure can have no spawn/EXEC |
| S02 return conventions | Spawn-return error, exec -1/errno, normal exit N and signal termination | Encodings/stages retained; unrelated errno and undefined child PID rejected |
| S03 fallback handoff | Source-copy private pipe success/error/partial-read/cwd-sentinel variants | Original consumer remains sole reader; swallowed/changed mapping or instrumentation read invalidates fixture |
| S04 query bytes | Distinct cflags/libs stdout, stderr, trailing LF, embedded NUL in a construction leaf, short write and failure | Q0/Q1/Q2/Q3 not conflated; invalid shell-byte case does not expand managed admission |
| S05 tty states | Existing controlling tty, redirected stderr, no tty and warning-write failure | No new PTY in original case; stderr transcript cannot falsely certify /dev/tty bytes |
| S06 descriptor reuse | Concurrent repeated queries; dup/close/fork/exec and reused fd numbers | Wrong channel generation or missing lifecycle edge makes association ambiguous |
| S07 Scheme delivery | Source-copy raw status/exception, conversion, cleanup and caller/barrier records; native wait independent | Missing/duplicate continuation, wrong device, timeout/I/O error and failed-object link detected; no competing reaper |
| S08 independent stream losses | Mutated immutable record copies, missing syscall return, missing output chunk or Scheme commit | Comparator detects each loss; ES continuity alone cannot pass another stream |
| S09 context | Same source/tool/profile where original claim is made; explicit source/sink/fd/parent changes in derived cases | Added tee/PTY/DYLD/logger env or catch wrapper cannot be labeled unchanged-context |
| S10 claim scope | Original retained visible outcome contrasted with L1 internal state and ES native exit | Evidence lanes remain distinct; unobserved required field blocks strict equivalence |

Calibration evaluates acquisition/comparison semantics only, not performance.
No dangerous system-resource exhaustion or privileged audit/tracing operation is
performed in this work. Failure injection is a future bounded-fixture design;
no unchanged original workload is deliberately modified to manufacture an event.

## 7. Unresolved and Retirement Consequences

| Gap | Current status / what would be needed | E/M consequence |
| --- | --- | --- |
| R1 original failed API result | No qualified external user-level return witness; syscall trace cannot cover every setup/library result | Original E29 launch-error parity open; source-copy knowledge is L1 |
| R2 failed syscall / optional audit stream | No calibrated syscall observer or retained selected audit trail; runtime protection/selection unknown | No failed-attempt errno or no-child proof from missing ES EXEC |
| R3 internal query bytes/value | No qualified original byte/channel/shell-value acquisition | E20/E22 cannot claim all query and transform behavior from argv/exit alone |
| R4 tty diagnostics | No original byte/writer/terminal-state witness | E19/E22/E29 diagnostic parity open; no tty means distinct error case |
| R5 original Scheme delivery | No stable original-binary delivery hook, port/request crosswalk or exception/barrier commit witness | E24/E29/E30 delivery/barrier scope remains open |
| R6 cross-stream identity/completeness | No actual streams/calibration/drain or lifecycle crosswalk | Ambiguous joins remain unresolved, not rounded into matches |
| R7 context preservation | Candidate external observers unqualified; source wrappers and new channel taps change context | Only explicitly derived claims admitted in design; zero perturbation unclaimed |

U6/U7/U8 from the preceding Darwin study are **decomposed, not closed**, by R1-R7.
M6/M7 need declared query/error/diagnostic behavior; M3/M4 need actual failure and
barrier evidence; M5 needs correct Scheme handoff. No gate retires on these source
reads.
The [external observer feasibility design](darwin-external-observer-design.md)
now specifies separate capability admission, raw-consumer limitations,
spawn/exec fd transformations, concurrency and ES crosswalk calibration. It
refines these gaps without asserting an available original-context observer.
 A future policy could deliberately qualify narrower external behavior,
but this design does not silently redefine strict E-row requirements to do so.

[Supplement paths D2](darwin-supplement-paths.d2) / [SVG](darwin-supplement-paths.svg),
[correlation and delivery D2](darwin-evidence-correlation.d2) / [SVG](darwin-evidence-correlation.svg).
