# Darwin L1 Calibration and L2 Native Observation

Date: 2026-10-20. **Design/platform research only.** No recorder, ES client,
tracer, fixture or native/performance workload was built or run; no entitlement,
TCC, SIP, tracing or system configuration was changed. Refines the
[independent E01-E32 evidence plan](independent-equivalence-evidence-plan.md).
D1-D12 refer to the [platform/source ledger](darwin-observation-platform-evidence.md).

## 1. Feasibility Conclusion and Meaning of Unchanged Context

Darwin offers a credible **candidate** for original-tool exec-time observation:
Endpoint Security NOTIFY_EXEC supplies counted arguments/environment tokens,
versioned exec cwd and process identities; NOTIFY_EXIT supplies wait-format
termination status (D1-D4). It can observe a tool without replacing its binary,
inserting a wrapper, passing recorder options, changing its parent to a debugger,
or injecting DYLD variables. Select an out-of-process **native ES notification
client** as the future L2 candidate, not eslogger text or a launch wrapper.
No such client has been authorized, created or calibrated here.

“Unchanged” must be scoped:

- **Launch payload:** no observer-added argv/env entries, no tool/path substitution,
  no changes to cwd, inherited descriptors, credentials, signal disposition or
  source/configuration bytes. Exact preservation requires future evidence.
- **Control topology:** observer is not parent/reaper/debugger and never authorizes,
  denies, signals or suspends the target. The original shell/Gambit owns children.
- **Scheduling/system state:** no zero-interference claim. Collection consumes
  resources; even native ES client creation has documented cache side effects
  (D4). Notification capture is not a performance control or proof that races
  and all externally visible behavior are identical to an unobserved run.

If “unchanged context” means literally no perturbation of the host or scheduling,
this study cannot establish it. L2 can target unchanged **explicit launch state**
and original tool identity, conditional on verified coverage. L3 uninstrumented
acceptance stays separate. L1 necessarily changes the tool slot and stays a
**derived construction profile**, even if its logging is perfectly calibrated.

## 2. L1 Recorder Design and Calibration

### 2.1 Record Exactly What the Leaf Received

A proposed small native leaf records at its defined **main-entry boundary**:
argc, argv[0..argc-1] as byte strings, the ordered environment vector without
map conversion, and physical cwd acquisition result plus directory identity.
It records before parsing options, calling setenv/chdir or opening its sink.
The recorder must not use the new typed decoder or shared renderer as its oracle.

Capture uses explicit counts and per-string lengths, then a versioned binary
frame with byte-order definition, total-length bound and checksum. No shell
quoting, UTF-8 repair, line splitting or JSON stringification stands in for raw
bytes. Native argv/env cannot contain embedded NUL inside a string; distinguish
empty strings from absent vector members. Calibrate zero-length, space, tab,
newline, quote, backslash, equals sign, dollar/star and non-UTF-8 bytes as data.
Those calibration bytes do not broaden managed-profile input admission.
Preserve duplicate env names and order; never reconstruct the vector with getenv.
Initial argument fixtures require argc >= 1; unusual argc-zero kernel behavior
is outside initial support until separately tested.

The boundary is **not** the kernel's exec input. Darwin loader/security/runtime
startup may treat recorder and GCC images differently. A main-entry record
cannot prove pre-dyld bytes or absence of startup environment changes. Compare
an explicit calibration launch manifest with the leaf result, and, if eventually
available, an independent ES exec event for that calibration binary. A mismatch
is a boundary/qualification issue, not permission to normalize differences away.

Cwd is not PWD. Record getcwd success/error and the current directory's device/
inode identity. Logical symlink spelling may differ from kernel-resolved cwd;
renamed/unlinked/inaccessible directories can make pathname acquisition fail.
Never substitute PWD on failure. Exact path-byte parity stays unresolved when
the two observation boundaries expose different representations. A later-opened
`.` descriptor changes recorder-local fd state; it must not be described as an
unchanged inherited descriptor. Initial calibration should use stable accessible
directories, then negative rename/unlink/permission cases separately.

### 2.2 Sink and Control Channels Are Fixture State

Do not export phase/output labels or add logging arguments: historical invalid
controls did that (D11). Do not rely on an inherited logging FD: Gambit's fallback
child path closes descriptors, and the materialized Darwin spawn path has its own file-action
policy (D9/D10). Keep stdout/stderr/tty and child stdin behavior unchanged for
the integration case rather than redirecting tool output into the record stream.

Select a compiled-in, fixture-owned absolute sink root outside source/cwd/package
search directories. The same recorder binary/sink binding serves both paired
arms. Per-process records use collision-resistant exclusive publication; the
outside controller associates them with launch events, without passing IDs in
the tested environment. All added filesystem actions and sink configuration are
part of L1's identity. Capture first, open/write after; record any local resource
changes and their limitations. Do not claim extra I/O is invisible to the system.

A truncated/partial frame, allocation failure, write failure, collision or missing
terminal commit yields OBSERVATION_INVALID. A recorder logging failure must not
masquerade as successful compiler output. The construction leaf creates no fake
object or bundle. Predetermined exit-zero, exit-nonzero and signal variants are
separately bound fixture tool identities, identical between arms for each case.
Package-query variants may emit deterministic cflags/libs bytes and statuses;
they prove a derived query contract, not real pkg-config or native artifacts.

### 2.3 Independent Calibration Matrix

All C rows are proposed and **unexecuted**. Ground truth comes from an independent
controlled launcher with explicit vectors and designated child ownership, not
from the new decoder/renderer or a shell-pretty-printed command. A launcher is
only calibration scaffolding; it must not become the L2 production tool parent.

| Case | Independent control / observation | Pass requirement / failure classification |
| --- | --- | --- |
| C01 vector framing | Explicit argv including distinct argv[0], empty word and adjacent whitespace-bearing words | Same count/order/length/bytes, no string join; any loss is mismatch |
| C02 raw bytes | Non-UTF-8 and delimiter-like data; frame decoder separate from typed parser | Byte-exact recovery or unsupported boundary reported; repair/truncation invalidates calibration |
| C03 environment | Ordered duplicate names, NAME=, absent NAME, values containing = and newline | Exact received vector, not getenv map; differences retained; startup-boundary mismatch unresolved until explained |
| C04 cwd | Stable real directory, symlink/logical PWD difference, negative rename/unlink cases | Physical identity plus path acquisition/error; PWD never oracle; path failure not an empty successful cwd |
| C05 size bounds | Small/large vectors near admitted launch/recorder bounds | Complete framing/counts or explicit launch/record failure; no accepted clipped output |
| C06 completion | Bound zero/nonzero/signal tool variants; independent designated parent's wait result | Store raw status and decoded kind/signal/code; no comparison of exit code alone |
| C07 spawn failure | Missing executable, invalid cwd and denied execution in controlled fixtures | Distinguish no image exec from recorder failure and child exit; no synthetic exec event or fake record |
| C08 concurrency | Simultaneous distinct leaves, repeated argv, PID reuse/exec-generation scenarios | Unique records and complete process association; no overwrite or PID-only join |
| C09 sink failures | Partial write/truncation/collision/denied sink and deliberately missing commit | Observer invalidity detected; successful leaf exit alone cannot pass |
| C10 route fidelity | Copied old script with final leaf slot changed, same managed fixture profile | Diff permits only declared tool substitution; no BUILD_*_CC override that clears FLAGS; main-entry argv compared after real old eval |
| C11 comparator sensitivity | Mutated copies of immutable records: drop word, reorder env, alter cwd, swap exit association | Comparator rejects each change; does not prove live observer completeness |
| C12 contamination review | Before/after source/tool/config digests, env/args/fd/cwd policies and sink binding | No undeclared mutation or injected labels; invalid control retained, never reclassified as a pass |

C01-C12 success would admit only L1's stated boundary/profile. Native/GCC
forwarding remains interposed, even if argv/env forwarding is byte-exact.
It must not replace L2 original-tool observations or L3 native acceptance.

## 3. L2 Candidate: Native Endpoint Security Notifications

Apple's API exposes argument/environment accessors and exec/exit event types;
these are API capabilities, not a measured guarantee for this host. Use a client
outside the target process group and original parent chain. Subscribe to
NOTIFY_EXEC, NOTIFY_FORK and NOTIFY_EXIT before the target scope begins; include
relevant cwd-change notifications only if later cwd evolution is in scope.
Do not subscribe to AUTH events just to obtain launch data: auth responses can
block/change execution. Never wrap the compiler launch with sudo to grant the
observer privileges. The separately launched observer's own privilege/TCC context
must not leak into the original workload's credentials/environment.

| Required field | Candidate acquisition | Required checks and limit |
| --- | --- | --- |
| Program / argv | EXEC target executable identity plus all es_exec_arg entries by count/index | Keep argv[0] separate from executable path; length-based copying; exact count/order/bytes calibrated; no claimed original PATH spelling from resolved executable |
| Environment | All es_exec_env entries by count/index, copied in event lifetime | Preserve ordered raw entries/empty values/duplicates; no dictionary/string renderer; runtime coverage and full-vector fidelity remain to be calibrated |
| Cwd at exec | EXEC cwd es_file_t when message version >= 3 | Require nontruncated path and stat identity; it is kernel-reported absolute cwd, not logical PWD or necessarily getcwd spelling |
| Completion | NOTIFY_EXIT stat plus process audit token | SDK specifies wait format; decode exit/signal using matching platform rules, retain raw value; this is not proof of what Scheme caller received |
| Process association | EXEC message.process before image replacement, exec.target after replacement; FORK and parent audit identities | Use host/boot scope plus audit token pid/pidversion, never PID alone; same PID can execute shell then GCC |
| Completeness | Runtime message version, subscription/mute/filter record, per-type seq_num and global_seq_num where available, local writer/queue commits | Counter continuity detects some kernel drops, not pre-subscription/muted/filtered/unflushed events; unknown coverage is unresolved |

Token data cannot outlive its message. Copy counts/tokens/metadata during the
callback or use the matching retain/release API before asynchronous processing.
Preserve raw token bytes and length; ES APIs do not require a JSON/Unicode
conversion. An fd-count limitation documented for exec **fds** is not evidence
that argv/env have the same cap; equally, absence of a documented argv truncation
flag is not a completed fidelity test. Calibrate boundary sizes and byte cases.

Select runtime message.version >= 4 for this initial full-field/loss-counter
candidate: cwd requires >= 3 and global_seq_num >= 4 in the inspected SDK.
Check each versioned access at runtime; SDK presence does not make the running
event version sufficient. Earlier versions remain unresolved for this profile. Inspect subscription state and relevant default/path/process muting;
record any visibility gap without unmuting protected system paths as a workaround.
Evaluate counter continuity before client-side target filtering. Persist both
kernel counters and local transport sequence/checksum/commit coverage. The first
observed counter is not proof of events before subscription, nor does a last
clean counter prove a tail was flushed. Bound readiness, start/end scope and
collector-drain completion independently of observed target absence.

No account of missing events can be repaired by ps polling. A collector that
starts late, misses exec or exit, has unexplained drops, restarts, or receives a
truncated required path cannot certify a complete case. Capture unrelated
system events only as necessary for sequence/scope accounting; they are not
new authority over the observed workload.

### 3.1 L2 Qualification Procedure (Not Executed)

| Case | Required independent control | Qualification boundary |
| --- | --- | --- |
| Q01 readiness | Authorized native client reports actual subscriptions/message versions before the original workload starts; record all relevant mute/filter state | Missing permission/readiness/visibility keeps U2/U5 open; no target credential escalation |
| Q02 bytes | Independent explicit calibration launcher plus C01-C05 leaf data versus every ES argv/env token | Compare kernel-event and main-entry boundaries without conflating them; byte differences cannot be repaired with Unicode conversion |
| Q03 identity | Fork then exec, shell-to-tool exec in same PID, unrelated same-name tools and process reuse controls | Every exec/exit joined by boot scope and audit identity; basename/PID-only correlation rejected |
| Q04 cwd | Stable physical cwd, differing PWD/symlink spelling and negative unavailable/truncated-path cases | Match defined physical identity/path contract; missing paths remain unresolved, not inferred from PWD |
| Q05 exit | Normal and signal termination, compared with designated calibration parent's raw wait result | EXIT stat interpretation qualified; original Scheme delivery is a separate U7 obligation |
| Q06 losses | Known event counts in controlled calibration; deliberate local writer loss, seq discontinuities and scope/fence omissions | Every injected loss invalidates completeness. No fixed event volume or clean short run proves loss-free future captures |
| Q07 unchanged launch state | Unmodified original source/tool/config hashes and independently checked target launch bytes/context; notification-only collector outside parent/process group | No wrapper/DYLD/debugger/sudo-target launch. Collector-only host effects remain disclosed; zero timing perturbation not claimed |
| Q08 exclusions | Failed spawn/exec/cwd, query-output/tty and Scheme-propagation cases | Receipt labels fields/events not covered by notifications; no successful-exec calibration promoted into full E29 coverage |

For a future capture, select before/after **control fences** generated by an
independent controller outside the tested process tree and environment. They
help delimit event/transport persistence and detect counter/tail loss; record
their identities separately. They do not prove that muted events existed, all
cross-thread events arrived in a desired order, or pre-subscription activity was
covered. If a supported drain/scope argument cannot be established, U5 stays open.
A fixed delay after the last tool is not a completeness proof.

### 3.2 Permission and Platform Preconditions

The native client requires the Endpoint Security entitlement, suitable signing/
provisioning, privilege and TCC Full Disk Access. Apple's es_new_client result
must establish actual readiness; local SDK presence or permission-file inspection
does not establish a working client (D4/D5). No client initialization/permission
probe was performed, and this design does not request system changes.

This host's read-only version file reports macOS 26.6.1 build 25G76; the installed
MacOSX26.sdk path resolves to MacOSX26.5.sdk (D6). That identifies the headers read,
not an ES runtime capability result, exact kernel source build, or the historical
D1510 execution platform. Archive header/man/version digests with future receipts.
Apple rolling docs and archived SIP guidance are contextual, not proof that all
behaviors match this exact host.

### 3.3 Successful Exec Is Not the Whole Launch Contract

A successful exec event is a snapshot at image transition. It does not expose
all failed exec/spawn/chdir attempts or their errno, the shell's intended command
before evaluation, query stdout/stderr, `/dev/tty` writes, or Gambit's delivered
process-status/error. EXIT describes termination, not the parent's wait result
or ownership. It cannot prove the right Scheme callback consumed that result.
These gaps remain unresolved for original, unmodified execution unless a second,
independently qualified boundary captures them without altering the tested
context. A source-instrumented Gambit fixture is useful L1 evidence only.

D9 shows raw wait status stored by Gambit's SIGCHLD reaper, while the Scheme
process wrapper later delivers status/errors. The observer must never call
waitpid(-1,...) in the target runtime or compete with it. A separate ES subscriber
does not reap target children. In calibration, only the explicitly designated
launcher parent waits for its own fixture child. Process identity must also
handle the shell exec optimization (same PID, different pidversion).

## 4. Alternatives and Their Limits

| Mechanism | Useful evidence | Why it cannot presently certify complete unchanged-context L2 |
| --- | --- | --- |
| eslogger | Built-in ES diagnostic output, lifecycle illustration | Local man says own-process-group suppression, unstable/non-API JSON, separate JSON/message versions, OS-log truncation; stdout export fidelity uncalibrated. Never infer full schema/bytes from API alone |
| execsnoop / dtruss / custom DTrace | Some exec/syscall/return observations, potential error diagnostics | Shipped execsnoop prints pr_psargs text; not framed argv/env. Custom copying/buffer limits, coverage and SIP restrictions need separate qualification; root alone does not prove complete tracing |
| ps / KERN_PROCARGS2 / proc_pidinfo | Point-in-time argument/environment or cwd-related inspection | Separate reads race with exec/chdir/exit, short-lived processes and permissions; headers do not promise a coherent exec-boundary four-field snapshot |
| kqueue process exit | Exit notification/status capability subject to documented rights | Does not provide argv/env/cwd or preceding failed launches; not a complete launch recorder |
| LLDB / ptrace / task memory | Instrumented state/register/memory diagnosis when allowed | Attach/suspension and privileges alter context; SIP can block protected processes. Not selected as transparent L2 |
| DYLD interposition / wrapper / source hooks | Controlled entry/return values and fixture diagnostics | Changes image/env/parent/control path; protected launches can purge DYLD variables; keep as instrumented/derived evidence |
| AUTH_EXEC-only ES client | Preauthorization data | Changes control/deadline policy and cannot stand for successful exec+exit coverage; NOTIFY candidate selected instead |

The eslogger manual explicitly distinguishes its JSON schema version from the
ES message version. Its own-process-group suppression means a same-group setup
can produce a misleading empty trace. Moving collector groups avoids that one
filter but does not establish byte fidelity or loss completeness. No eslogger,
dtruss, execsnoop, debugger, permission or process-inspection command was run.

## 5. Explicit Unresolved Register and E-Row Consequences

| ID | Gap remaining at this checkpoint | Evidence required before closing / affected claim |
| --- | --- | --- |
| U1 | No L1 recorder/launcher/calibration results | C01-C12 with immutable raw records; all L1 E-row controls remain unexecuted |
| U2 | No usable native ES client or runtime permissions established | Properly authorized readiness/subscriptions on exact host; L2 unavailable until then |
| U3 | Full argv/env byte fidelity and size coverage uncalibrated | Independent controlled launches versus ES tokens and L1 records across declared bounds; empty/duplicate/invalid-UTF-8 cases qualified |
| U4 | Cwd representation/truncation/alias issues | Version >= 3, nontruncated path, directory identity and explicit physical/logical comparison contract; E25 not exact path proof from PWD |
| U5 | Kernel/client/transport completeness unproved | Start/end/readiness/drain evidence, counter accounting, mute/filter provenance and local loss detection; no-effects cases cannot pass on empty logs |
| U6 | Failed exec/spawn/chdir errno not fully observable via selected notifications | Independent error-boundary witness; E29 and failed-launch portions remain unresolved for original tools |
| U7 | Native EXIT versus Scheme delivered status/error/barrier | Independent original-caller evidence plus retained reaper ownership; E24/E29 and failure-barrier parts cannot pass from ES exit alone |
| U8 | Query output and tty diagnostic transport absent from lifecycle stream | Separately qualified channels without altering descriptors/tty/context; E19-E22/E29 diagnostic parity remains unresolved |
| U9 | No guarantee of zero scheduling/system perturbation | No such claim selected; L2 launch-state scope only, L3 uninstrumented acceptance separate, no performance conclusion |
| U10 | Full native profile/tool/header/runtime/SDK identity not qualified | Existing profile and native admission obligations still required; ES path/codesign/stat is not all content/specs/dependency evidence |

Selected **NOTIFY_EXEC + NOTIFY_EXIT** may eventually cover the four requested
fields for **successful image executions**, under a declared physical-cwd and
byte-fidelity contract. It cannot currently close the whole E01-E32 suite or
M2-M8 retirement. L1 calibration, successful-exec L2, failed-launch/status
propagation and L3 native behavior are separate evidence obligations.

The subsequent [supplemental evidence design](darwin-supplemental-evidence-design.md)
decomposes U6/U7/U8 into failed API/kernel calls, Q0-Q3 output boundaries,
Scheme commits and explicit ES joins. R1-R7 remain unresolved; the source/read
work does not close original-context observation or native retirement gates.

[Calibration D2](darwin-l1-calibration.d2) / [SVG](darwin-l1-calibration.svg),
[L2 feasibility D2](darwin-l2-observation.d2) / [SVG](darwin-l2-observation.svg).
