# Darwin Consumer Link, Load and Callback Support Design

Date: 2026-10-20. Design only. Refines the
[native adapter architecture](darwin-dtrace-adapter-architecture.md) and A01-A06.
[Evidence ledger and source anchors](darwin-consumer-support-evidence.md).
No compiler/linker invocation, consumer build/load, live probe enumeration,
trace, calibration or performance validation was performed.

The later [local stack inspection](darwin-local-stack-correspondence.md) records
TAPI 2100.0.2.6, dyld 1387 and an on-disk cache libdtrace label 413. Historical
TAPI/dyld branches below must not be relabeled as those installed implementations.
The version-label match narrows correspondence without qualifying callbacks.

The decision is to retain **two conditional ARM consumer profiles**, ordinary
arm64 with the OS interoperability path and native arm64e with matching callback
ABI. Neither is currently qualified. A third, homogeneous arm64 library profile
is conditional on a different, verified SDK/runtime pair. Merely selecting
`-arch arm64e` is not an adoption plan. The collector remains a separate process
with a project-owned byte-stream boundary; the product does not link libdtrace.

## 1. TAPI Is a Versioned Selection Mechanism

The inspected SDK stub has only x86_64-macos and arm64e-macos export targets
[B1]. Published ld64 passes CPU/subtype and its subtype-enforcement option to
TAPI [B2]. Thus the first question is the **actual linker/TAPI pair and flags**,
not whether a string named arm64 occurs in the stub.

TAPI 1300.0.6.5 first tries exact architecture, rejects a miss under
ExactCpuSubType, otherwise searches the same CPU type. This explains a possible
arm64-to-arm64e stub selection, not a callback ABI guarantee.
[TAPI 1300 source](https://github.com/apple-oss-distributions/tapi/blob/tapi-1300.0.6.5/tools/libtapi/LinkerInterfaceFile.cpp).

TAPI 1600.0.11.8 instead returns the requested architecture after a non-exact
miss; subsequent platform/export filtering uses that architecture. For this
stub, returning arm64 does not select its arm64e exports. Successful parsing is
therefore insufficient evidence of usable symbol imports.
[TAPI 1600 source](https://github.com/apple-oss-distributions/tapi/blob/tapi-1600.0.11.8/tools/libtapi/LinkerInterfaceFile.cpp).

| Request against the inspected stub | TAPI 1300 selection path | TAPI 1600 selection/filter path | Design disposition |
| --- | --- | --- | --- |
| arm64e, exact or non-exact | Exact hit | Exact hit | Source-level stub candidate; still needs platform/import and runtime gates |
| arm64, ExactCpuSubType | Missing architecture | Missing architecture | Reject for this specific request/stub combination |
| arm64, non-exact | Same-CPU fallback can select arm64e | Returns arm64 without selecting arm64e exports | Version-dependent unresolved; no generic fallback promise |
| x86_64 | Exact hit | Exact hit | Separate Intel/translation profile, outside initial ARM support |

This table describes inspected public implementations, not this machine's
installed linker. New Apple linkers, LLVM/lld, Zig-bundled linkers and their TAPI
readers must not inherit the old branch's verdict. Do not select an obsolete
linker, rewrite a stub, suppress missing imports or weaken subtype enforcement
to manufacture eligibility. A receipt must identify the selected architecture,
required symbol set, actual provider and platform/deployment decision, as well
as the executable's resulting Mach-O subtype.

The initial required import set is `dtrace_open`, `dtrace_close`, `dtrace_errno`,
`dtrace_errmsg`, `dtrace_probe_iter`, `dtrace_probe_info`,
`dtrace_program_strcompile`, `dtrace_program_info`, `dtrace_program_exec`,
`dtrace_setopt`, `dtrace_go`, `dtrace_stop`, `dtrace_work`,
`dtrace_handle_err` and `dtrace_handle_drop`. All 15 names occur in the inspected
stub's shared x86_64/arm64e export group [B1]. This is a static export-name check,
not a link or symbol-binding result for C0. Provider/control APIs excluded by the
profile are not added merely because they are exported.

## 2. dyld Loading Is a Separate Conditional Path

Published dyld ProcessConfig marks ordinary arm64 main images keys-off and
passes that state through its syscall delegate. In a ptrauth-enabled dyld build,
the graded loader's keys-off set includes arm64e and arm64; its keys-on set is
arm64e-only. Launch grading and dependency grading are separate. These are OS
selection paths, not instructions to disable authentication.
[ProcessConfig](https://github.com/apple-oss-distributions/dyld/blob/dyld-1378/dyld/DyldProcessConfig.cpp),
[delegate](https://github.com/apple-oss-distributions/dyld/blob/dyld-1378/dyld/DyldDelegates.cpp),
[graded architectures](https://github.com/apple-oss-distributions/dyld/blob/main/mach_o/GradedArchitectures.cpp).

The file-backed loader additionally checks architecture/platform and code
signature/library validation. Shared-cache lookup is another path: an SDK stub
is not a physical dylib slice or the loaded shared-cache image.
[MachOFile](https://github.com/apple-oss-distributions/dyld/blob/main/common/MachOFile.cpp),
[Loader](https://github.com/apple-oss-distributions/dyld/blob/main/dyld/Loader.cpp).

Design consequence: record consumer main-image subtype, actual dyld/cache image
identities, selected libdtrace provider, platform/deployment requirements and
effective OS-established interoperability mode separately. The text name
arm64e is insufficient to identify PAC ABI version [B7]. An ad-hoc signature or
successful library lookup does not certify executable launch eligibility.
Private arm64e distribution/signing policy and installed-kernel correspondence
remain unresolved. No boot arguments, protection changes, DYLD overrides or
target relaunches are part of qualification.

| Profile | Consumer / selected library | Link requirement | Load and callback requirement | Current status |
| --- | --- | --- | --- | --- |
| C0 | arm64 / OS arm64e libdtrace | Actual reader must expose required imports with a documented compatible selection path | OS-established keys-off interoperability, exact loaded library and typed C callback behavior must agree | Conditional candidate; historical source explains possibility, no installed support receipt |
| C1 | arm64e / matching arm64e libdtrace | Exact subtype/platform exports and all required imports | Main-image launch policy, PAC ABI version, dependency validation and standard callback ABI | Conditional candidate; no launch or ABI receipt |
| C2 | arm64 / arm64 libdtrace | Verified SDK exports arm64; inspected stub does not | Matching runtime image and ordinary arm64 ABI | Deferred to another SDK/runtime profile; not available by editing this stub |
| C3 | arm64e with keys on / arm64-only dependency | Even an accepted link is insufficient | Inspected keys-on dependency grade excludes plain arm64 | Excluded from the selected source-derived load model |
| C4 | x86_64 / x86_64 libdtrace on Apple Silicon | Independent reader and imports | Translation availability and observed-target/probe ABI independently qualified | Deferred; not a rescue path for C0/C1 |
| C5 | arm64e with nonstandard function-pointer type discrimination / standard system library | Symbol names may still match | Function-pointer schema mismatch at callbacks | Reject direct callback interchange |

C0 and C1 are alternative collector deployment profiles, not an automatic runtime
fallback chain. No public source reading in this study establishes a supported
combination on the current host. Failed eligibility leaves evidence unavailable;
native builds continue without a collector. C2 is a future configuration, not a
claim that a separately linkable ordinary-arm64 system libdtrace exists here.

![Link/load decision boundaries](darwin-consumer-link-load.svg)

## 3. libdtrace Initialization and Callback ABI

Published libdtrace requires matching DTRACE_VERSION, rejects conflicting
D-model flags, skips device access for NODEV, and otherwise opens dtrace and
fasttrap devices. It retains fasttrap failure separately. Initialization also
adjusts the consumer's fd limit. A successful open is not every-provider support.
[dt_open.c](https://github.com/apple-oss-distributions/dtrace/blob/dtrace-413/lib/libdtrace/common/dt_open.c).

This further supports process isolation: never initialize it inside Gambit,
the native executor or a parent that later launches the measured workload.
Collector-owned fd/resource changes must not be inherited by original tools.
NODEV belongs to an offline capability only; it cannot emit a probe-ready token.
Use separate readiness states for library, device, each provider and each recipe.

Clang's standard arm64e C function-pointer schema is IA, no address diversity,
discriminator zero; optional type discrimination changes the ABI. dlsym returns
code pointers using the standard function schema. Dynamic lookup does not bypass
callback compatibility.
[Clang ABI documentation](https://clang.llvm.org/docs/PointerAuthentication.html).

The proposed collector boundary keeps these obligations explicit:

| Callback / data path | ABI contract | Adapter admission condition |
| --- | --- | --- |
| Probe callback | SDK `int(const dtrace_probedata_t *, void *)` | Exact C prototype, opaque context with qualified lifetime; capture event base under the chosen decoder |
| Record callback | SDK `int(const dtrace_probedata_t *, const dtrace_recdesc_t *, void *)` | Record pointer may be NULL; data address convention separately qualified; no double offset |
| Error/drop handlers | SDK typed `int(const ... *, void *)` | Copy fields and borrowed messages immediately; handler return values use HANDLE constants, not CONSUME constants |
| API status returns | C int / SDK enum / pointer and separate error output | Preserve each API's error convention; no blanket bool conversion |
| Callback code pointers | Selected process ABI, pointer-auth scheme and compiler flags | No manual PAC stripping/signing or cast-based repair; no C++ exception, Zig panic/unwind or Scheme nonlocal exit across callback |
| Callback structures | Exact headers, field layout, alignment, signedness and library revision | C boundary owns access; no packed mirror structs or host-width guessing in the evaluator |

The published consumer invokes a NULL-record callback at event completion and
does not use its return as the normal per-record abort decision. Probe/record
consume results and handler results have different enums. Error messages may
refer to stack storage. Those are decoder/lifetime obligations in addition to
pointer authentication.
[dt_consume.c](https://github.com/apple-oss-distributions/dtrace/blob/dtrace-413/lib/libdtrace/common/dt_consume.c),
[dt_handle.c](https://github.com/apple-oss-distributions/dtrace/blob/main/lib/libdtrace/common/dt_handle.c),
[SDK declarations](/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk/usr/include/dtrace.h).

The C-facing collector owns all callbacks and error state. Callback failure
records a fatal scope condition; return values alone, especially a NULL-record
completion return, cannot certify abort/drain. A single owner drives library
operations; cross-thread use, reentrancy and handler lifetime need independent
qualification rather than a presumed thread-safety contract. Only copied,
versioned project records enter the offline evaluator. A separate process may
be written partly in Zig, but its language choice is not ABI evidence.

## 4. Probe Admission Matrix

Every C0/C1 deployment requires its own probe verdicts. Below, **candidate**
means eligible for a future bounded qualification plan, never qualified now.
Target ABI means the observed image, independently of consumer ABI.

| ID | Probe / target scope | Required condition beyond C0/C1 eligibility | Allowed evidence ceiling | Decision now |
| --- | --- | --- | --- | --- |
| P01 | dtrace BEGIN/END/ERROR control probes | Exact control semantics, handler installation, lifecycle and loss controls | Collector lifecycle/health only; not workload coverage | Candidate, unresolved |
| P02 | syscall scalar entry/return; original unprotected arm64 target | Exact operation variants, emitter identity, provider return convention and firing controls | Local call/result; attribution additionally requires process-generation join | Candidate, unresolved |
| P03 | syscall scalar entry/return; original unprotected arm64e target | P02 plus exact target ABI/subtype and visibility qualification | Same bounded facts as P02; no privilege inferred from target architecture | Candidate, separate unresolved scope |
| P04 | read/write bounded copy; either selected target ABI | P02/P03 plus pointer/length ABI, copy bounds, mutation, partial IO, fd and loss controls | Attempted or completion-count-associated snapshots | Candidate, unresolved; no kernel-consumed-byte promotion |
| P05 | proc spawn/exec failure | Installed provider/source correspondence, argument/emitter context and attempt witness | Local failure event only until independent join | Candidate, unresolved |
| P06 | spawn fd-action internal events | Complete successful action witnesses, order, fd generations and affected process | No complete graph supplied by selected source hooks | Unresolved; source recipe cannot substitute |
| P07 | pid/objc/oneshot user function probes | fasttrap availability and compiler call-path side effects, plus exact target ABI | Separate derived/control profile only | Excluded from initial strict L2 profile |
| P08 | fbt/internal kernel functions | Kernel build, probe stability, argument ABI and context-preservation proof | No initial portable evidence contract | Deferred; unresolved |
| P09 | Any provider on protected/system tools | Positive visibility under unchanged installed policy for each exact image | At most individually qualified operations | Unresolved; unprotected controls cannot qualify this row |
| P10 | Scheme continuation/exception/barrier delivery | Stable original semantic witness and independent association | No selected OS-probe substitute | Unresolved; not enabled by C0/C1 success |

Published pid probe creation checks fasttrap and can call dt_proc_grab internally.
Avoiding explicit dtrace_proc_grab in collector code therefore does not alone
preserve context. [dt_pid.c](https://github.com/apple-oss-distributions/dtrace/blob/main/lib/libdtrace/common/dt_pid.c).
Admission must inspect recipe expansion and the library path it invokes. Deny
wildcards/macros that introduce excluded providers; no hidden pid attachment
during a supposed syscall-only profile.

P01 health support is necessary but cannot prove that P02-P09 are visible.
Exact tuple/argument/attribute manifests, match counts, positive and negative
controls, actual firing, error/drop coverage and ES association remain separate
gates. Provider or target-ABI changes invalidate the relevant rows. Neither
successful scalar tracing nor an ES EXEC fd subset qualifies P06 or P04's
kernel-consumed bytes. The previous Q0-Q3 and Scheme-delivery gaps remain.

![Callback and probe admission](darwin-consumer-probe-admission.svg)

## 5. Required Receipts and Unresolved Register

The support predicate is conjunctive:

`support(profile, probe, target, scope) = linkImports AND launchPolicy AND
loadedProvider AND callbackABI AND deviceProvider AND probeRecipe AND
targetVisibility AND decoderFidelity AND healthDrain AND requiredAssociation`.

Each term is pass, fail or unresolved. An absent term is unresolved, not pass.
Record the evidence source for every term; static-source eligibility is a
different field from an observed pass. Do not multiply unqualified assumptions
into a platform-wide support claim.

| ID | Remaining question | Required closure evidence; not performed here |
| --- | --- | --- |
| U01 | Installed linker/reader correspondence and selected imports | Exact executable/library identities, flags, SDK digest and independent import-selection result; historical TAPI source alone cannot close it |
| U02 | C0 OS interoperability / C1 arm64e launch eligibility | Installed kernel/dyld/cache and selected main-image/library identities, unchanged policy, effective process ABI and loading evidence |
| U03 | Callback compatibility in selected toolchains | Independent typed callback call/return, struct layout, NULL-record, error/drop and lifetime controls; Zig/C keyword compatibility is insufficient |
| U04 | Device/provider/recipe visibility for each target | Per-P-row original image/ABI controls, no implicit process attachment, no missing-match suppression |
| U05 | Lossless bounded decoding and process association | A02/A05/A06 controls including ambiguity, faults, persistence loss and drain; no timestamp-only join |
| U06 | Full fd effects, consumed bytes and Scheme delivery | New independent original witnesses; C0/C1 selection does not supply them |

Changes to SDK/stub or actual linker invalidate U01; kernel/dyld/cache/signing
policy changes invalidate U02 and affected probe visibility; compiler/ABI flags,
headers, libdtrace or adapter changes invalidate U03 and decoding. Recipe/target
changes invalidate their P rows; ES identity/sequence policy changes invalidate
joins. Retain earlier receipts and requalify dependent scopes. These are evidence
admission keys, not new native artifact keys unless actual compiler inputs change.
No A01-A06, E01-E32 or M2-M8 retirement gate is closed by this design.
