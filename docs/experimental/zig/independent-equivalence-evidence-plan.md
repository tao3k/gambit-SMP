# Independent Evidence for E01-E32

Date: 2026-10-20. **Design only.** No observer, recorder, fixture, compiler test
or performance experiment is implemented or run. Refines the
[E01-E32 obligations](native-argv-equivalence-matrix.md) and
[single-source model](single-source-native-profile.md). Source IDs O1-O10 and
content identities are in the [observation/caller ledger](equivalence-observation-evidence.md).
The [caller and replacement plan](native-caller-retirement-plan.md) binds M2-M8
to actual call sites rather than function names alone.

## 1. Independent Oracle and Evidence Lanes

Pin a **legacy baseline** with exact generated script, header, compiler/runtime,
source patches and installed paths. Pin a managed candidate independently.
The old arm must retain the old producer/decoder/shell behavior. Do not generate
its expected argv with the new shared model, new decoder or typed renderer.
Manual source invariants are reviewed separately; native observation determines
what the old route actually passed. A new renderer agreeing with itself is not
an oracle. The materialized Gerbil source and research vendor Gambit are distinct
checkouts; their composition must be explicitly bound before a future native run.

Use four separate lanes, never promote their evidence silently:

| Lane | Purpose / proposed method | Can establish | Cannot establish |
| --- | --- | --- | --- |
| L0 source/configuration | Read pinned sources, generated assignments and template composition; independently record expected invariants | Recipe/ownership and candidate expected vectors | Executed argv, shell behavior, native correctness |
| L1 construction fixture | Isolated legacy copy with only final compiler/package tool slots redirected to a byte-recording leaf; compare managed fixture using the same leaf/tool profile | Actual shell-produced argument boundaries, ordering, environment/cwd at recorder entry; query order/status in controlled fixture | Original compiler identity, unmediated old execution, successful native artifacts |
| L2 original native witness | Unmodified legacy script and actual configured tools, with a separately qualified process-boundary acquisition facility; compare fully bound managed execution | Real program/argv/environment/cwd/process/status observations within acquisition coverage | Omitted/unreadable fields, completeness merely inferred from command text |
| L3 uninstrumented native acceptance | Existing source-bound native/platform acceptance with real tools, no recorder or diagnostic env injection | Actual artifact/module/FFI/GC/control behavior under that profile | Every exact argv element or explanation of its construction |

L1 is an intentionally **derived fixture profile**: replacing C_COMPILER or
PKG_CONFIG changes a tool/configuration identity. Bind the exact old-file diff
and original values. Do not use `BUILD_*_CC_PARAM` to install the recorder: that
clears mode FLAGS (O3), changing the case under test. The recorder must receive
native argument bytes after shell eval, not a pre-eval command string. It must
not decode its input with the new decoder or construct the expected argv.
A native leaf would write an independent framed record using a bound private
sink, without exporting labels, adding diagnostic argv, or invoking a shell.
This is a proposed recorder requirement, not existing tooling.

Even a forwarding recorder adds a process and changes tool context; it remains
L1/interposed evidence. L2 requires an acquisition capability that demonstrably
captures the requested fields on the actual Darwin version, including shell
exec/spawn and cwd. This study does **not** assume DTrace, debugger output or a
particular tracing API supplies full argv/env/cwd without omissions. If that
capability is unavailable or cannot be calibrated, mark L2 **UNRESOLVED** and
keep exact original-native parity open. L1 plus L3 is useful triangulation,
not a substitute for missing L2 fields or a completed original-native claim.
No privileged observer is requested or installed by this research.

The subsequent [Darwin feasibility study](darwin-recorder-observation-design.md)
selects native ES notifications as a conditional successful-exec L2 candidate,
not an available/qualified observer. It defines C01-C12 and Q01-Q08 calibration
and U1-U10 gaps, including failed launches and Scheme status propagation.

Observers must keep event transport out of tested child env/options. O9's
historical failed controls show that exported phase/output labels can invalidate
the comparison. A supposedly harmless instrument is part of the experiment's
identity. Hash originals before/after; retain observer code/diff/version and
coverage/calibration records. Source-only purity claims do not prove calibration.

## 2. Where to Observe the Old Route

| Boundary | Exact old location | Required evidence and why |
| --- | --- | --- |
| B0 configured inputs | O6 configure.ac composition/ESC_SH/AC_CONFIG_FILES, actual generated .unix/header, O7 make/install consumers | Record defaults, present/unset inputs, recipe fields and generation identity before testing; do not execute config scripts just to inspect them |
| B1 producer intent before transport | O1 Gerbil filters/invoke and O2 ##gambuild-params | For a source-instrumented fixture only, record original Scheme strings/lists, phi/debug/static/name/path roles before LF flattening; altered source identity is explicit |
| B2 Scheme process launch | O1 driver invoke:1190-1206 and O4 ##run-subprocess | Real argv to GSC, env or gambuild child; inherited env and directory; Gambit status delivered back. This is not the final GCC argv |
| B3 resolution children and diagnostics | O3 process_pkg_config/get_meta_info/extract_cc_ld_options | Ordered cflags/libs calls, query env/cwd/status/output, feature-selected payloads; `/dev/tty` separately from stdout/stderr |
| B4 final native tool entry | O3 obj/dyn/exe eval; O1 direct gerbil-gcc invoke | Actual program/arguments/env/cwd after all splitting, globbing and eval. VERBOSE output, set -x or BUILD_* text is insufficient |
| B5 completion and semantic barrier | O1 invoke, compile-obj unwind-protect, schedule-darwin-objects-and-link; O2 status branches; O5 executor publication | Native exit/signal versus delivered Scheme error, cleanup/output presence, failed-object barrier preventing link; no success inferred from filename alone |
| B6 native/runtime admission | Retained O10 semantic/native gates | Real output format/symbol/relocation/module/GC/control/FFI evidence; independent of construction evidence |

Events form a causal graph: parent spawn before child result, cflags before
libs for a request, all required successful object results before final link.
Do not impose a total order on independent parallel object jobs or use wall-time
timestamps as a dependency proof. Preserve per-request/action ordinals and
parent/child/job associations. L2 must distinguish program resolution from
argv[0], and raw native status from Scheme's encoded/delivered status; do not
assume a portable integer mapping without source/platform evidence.

Do not require literal child env equality between the *gambuild shell* and the
*executor*: those are different implementation processes. Compare the eventual
compiler/query child context, preserving observable env keys/values and absence.
Old transport variables may reach a tool via inheritance (O4). Their removal is
not automatically transparent. A tool can read arbitrary environment entries;
for strict parity the managed executor must construct the required leaf child
context, or explicitly restrict/reject the tool/profile and qualify that scope.
This does not authorize reintroducing the env protocol as the internal request
transport. Never mask differing keys just because they begin GAMBUILD or BUILD.

## 3. Receipt and Failure Model

Proposed inert evidence structure:

```text
CaseReceipt = {caseId, ERow, lane, baselineSourceIds, candidateSourceIds,
  profileIds, toolAndRuntimeIds, fixtureDigest, snapshotId, observerId,
  observationCoverage, originalFileDigestsBeforeAfter, calibrationRef,
  events, expectedInvariantsRef, comparisonPolicyId, outcome, limitations}
Event = {requestId, eventId, parentId, jobId?, boundary, ordinal,
  programBytes?, argvByteVectors?, rawEnvironmentEntries?, cwdBytes?,
  sourceAndArtifactRefs, diagnosticChannel?, payloadDigest?,
  nativeCompletion?, deliveredSchemeResult?}
```

Use length-framed bytes or an explicitly lossless binary-to-text representation;
never pretty-printed command text as argv evidence. Preserve raw environment
entries alongside name/presence/value interpretation. Duplicate env names cannot
be represented by a map alone: pin actual ordering/selection behavior or reject
ambiguous cases before claiming parity. The event receipt's identity is separate
from the request/artifact key; PIDs and event labels must not become compiler
inputs. Missing stdout/stderr/tty coverage is recorded, not silently empty.
Immutable fixture snapshots give both arms matching **visible path spellings**;
if separate directories change cwd/__FILE__/metadata identity, bind and qualify
that difference rather than normalizing it away. Inability to present matching
paths is UNRESOLVED for strict parity.

| Outcome | Meaning |
| --- | --- |
| CONSTRUCTION_MATCH | Required fields/actions match in a qualified L1 derived fixture; not original-native parity |
| ORIGINAL_NATIVE_MATCH | Required L2 observations plus independent L3 acceptance match for the exact admitted source/profile/input subset |
| EXPECTED_REJECTION | Managed rejection matches declared restriction with no prohibited effects; never counted as equivalence |
| MISMATCH | Valid observations disagree on required args/env/cwd/actions/status/artifact behavior, or managed work violates a must-not-start condition |
| OBSERVATION_INVALID | Instrumentation changed inputs unexpectedly; missing/truncated events, calibration failure, identity drift or contaminated controls |
| UNRESOLVED | Required tool/profile/runtime/observer/field evidence unavailable, mapped-only mode or skipped gate; no pass inferred |

Failure is not only nonzero exit: an unexpected successful compilation after a
failed libs query, wrong alias, hidden legacy retry or extra native child can
be a MISMATCH. Expected negative cases must capture zero prohibited children
under complete observation coverage. Absence of a log line is not proof of no
execution. Timeouts/incomplete captures remain unresolved/invalid and retained;
no wider timeout or fallback retry converts them to success.

## 4. Controlled Fixture Families

These are specifications to construct later, not files created this turn.

- **F1 defaults/options:** same pinned generated C; captures absent / present-empty /
  nonempty `-DCASE_C=11`; LD sentinels `-L/example/first` then `-L/example/second`.
  Duplicate -fPIC and sibling-call flags retained. Use simple paths initially.
- **F2 mode roles:** ordinary object, Darwin bundle from C and from object,
  generic Gambit exe, Gerbil dependency exe, Gerbil full-program-optimization
  stub exe. Runtime-object recipe stays mapped-only with its actual make caller.
- **F3 transport:** legacy string `-D___DYNAMIC -fPIC`, list of two fragments,
  empty string/list/element, space/LF paths, quote/backslash/glob/response-file
  variants. Compare admitted simple cases; rejected variants need no dangerous
  shell execution. Use inert marker syntax, no executable substitution payload.
- **F4 metadata:** producer-shaped canonical literal/when/boolean records;
  known true gcc/unix, known false clang/windows, nested predicates, unknown
  darwin, malformed arity/escape; source digest and key/ordinal always bound.
- **F5 package actions:** actual retained profile with unavailable package tool
  plus empty/nonempty request. A separate derived L1 profile has a deterministic
  query leaf returning distinct cflags/libs payloads, failing each phase in turn.
  It does not prove a real installed pkg-config's behavior or SDK correctness.
- **F6 source/path/symbol:** runtime-C metadata differs from static-C/object
  identity, static runtime copy retained, alias pair from pinned encoder,
  output-dir relative paths and __FILE__/debug observations where meaningful.
- **F7 lifecycle/publication:** compiler failure, spawn failure, missing cwd,
  failed object among multiple jobs, incomplete output/manifest, changed header
  or compiler between snapshot and publication. Retain negative artifacts.
- **F8 language policy:** phi × debug × static combinations, repeated CC/LD
  options including exact -Bstatic/-static and unrelated flags; semantic GSC
  debug/phase options remain distinguishable from native CC/LD options.

Real native fixtures must use source-bound genuine producer output and the
required runtime; a hand-written C marker fixture only qualifies construction
or a narrow C command. A successful stand-in must not impersonate a real native
object or complete module acceptance. Variants change fixture identities, never
reuse a previous content digest for modified inputs.

## 5. Per-Row Independent Controls and Failures

Lane requirements below are for future qualification. L0 is implicit for every
row. C means L1 construction; N means L2 plus L3 native evidence. R is expected
restriction evidence with complete no-prohibited-effect coverage. No row has
been exercised here. The preceding matrix defines the exact segment algebra.

| Row | Old observation / lane | Positive or paired control | Deliberate negative control / failure criterion |
| --- | --- | --- | --- |
| E01 | B0/B4; C then N | GCC and preprocessor roles, prefix -E exactly once | Wrong tool digest, doubled prefix or role swap must fail; native preprocessor use not inferred from an unused configured field |
| E02 | B0/B4; C/N, F1 | Absent C and LD select captured defaults | Delete one default or move its position: mismatch |
| E03 | B0/B4; C/N, F1 | Present-empty C/LD versus absent, one field at a time | Clearing all mode flags or retaining suppressed capture: mismatch |
| E04 | B1/B4; C/N, F1 | Nonempty capture sentinels, repeated flags | Sorting/reversing/deduplicating words must be detected |
| E05 | B2/B4/B5; C/N, F2 | One generated C ordinary obj, exact Out and joined -I | Wrong O, -o location, extra input or missing compiler child: fail |
| E06 | B0/B4; C only until support, F2 | Actual make runtime recipe OR versus ordinary O | Installed obj assumed OR or fabricated native coverage: fail; managed runtime support remains unresolved/deferred |
| E07 | B3/B4/B5; C/N, F2 | Bundle from C versus object, preserve FD/DD/-bundle | Replace with dylib role, omit dynamic define or use archive recipe: mismatch |
| E08 | B4/B6; C/N, F2 | Generic exe, repeated FE and absolute RK | Insert standalone O, remove repeat or reorder RK/Lib: mismatch |
| E09 | B1/B4/B5; C/N, F2 | Separate Gerbil exe: shared/rpath true and false, ordered deps | Generic FE/package scan injected or library moved: mismatch |
| E10 | B1/B4/B6; C/N, F2 | Full-program stub exe: source defaults and ordered stub/link objects | Borrow dependency recipe or alter Darwin source default libraries: mismatch |
| E11 | B1/B4; R, F3 | Absent/empty CC normal path; nonempty raw override rejected | Compiler/query starts after rejection, or override accepted with old FLAGS retained: fail |
| E12 | B0/B4; R, F2 | Obj/bundle supported roles contrasted with lib/archive/dylib unsupported | Treat echo placeholder success or suffix as native support: fail |
| E13 | B4; C/N, F1/F2 | Duplicate CC flags, repeated ordered link libraries | One missing duplicate or reordered library detected even if program still links |
| E14 | B1/B4; C/N, F3 | One string containing two words versus two simple fragments | Record raw fragment as one argv element, collapse changed boundaries: mismatch |
| E15 | B1/B4; R, F3 | Simple paths admitted; empty/LF/ambiguous paths rejected | Reconstruct lost list element or silently accept changed path: fail; no hazardous baseline eval required |
| E16 | B1/B4; R, F3 | Plain literal contrasted with inert expansion/glob/@file syntax | Any query/compiler/response-file traversal after rejection: fail under complete coverage |
| E17 | B1/B4; C/R, F3 | Repeated direct-link strings with multiple spaces, simple words | Apply shell unquoting to direct LD route or accept ambiguous quoted-space form: fail |
| E18 | B3/B4; C/N, F4 | Truth table and nesting over configured labels, empty and/or | Host-derived Darwin truth, swapped and/or or emitted false payload: mismatch |
| E19 | B3/B4; R, F4 | Known canonical entry versus unknown/malformed form | Report rejection as equivalence; ignore unsupported payload silently; start child after rejection: fail |
| E20 | B3/B4; C/N, F4/F5 | Distinct package/meta/explicit sentinels in CC/LP/LT | Swap prelude/tail, file/field order or metadata source digest: mismatch |
| E21 | B3; C and N when actual resolver bound, F5 | Baseline plus two metadata and two explicit search paths | Append instead of prepend or normalize away path distinction: mismatch |
| E22 | B3/B5; C/R and N when bound, F5 | cflags success/libs failure, cflags failure, success pair; obj included | Swallow failed libs, invoke compiler, or query libs after failed cflags contrary to observed route: fail; empty tool profile cannot prove successful queries |
| E23 | B3/B4; R, F4 | One metadata source accepted, multiple rejected | New silent multi-file aggregation or managed child after rejection: fail |
| E24 | B1-B5/B6; C/N, F6 | Actual Darwin patch object then bundle; independent alias/name/source references | Use static object as metadata C, wrong alias, bundle starts after failed object, or missing bundle accepted: fail |
| E25 | B0/B2/B4/B6; C/N, F6 | Same visible cwd/relative paths, runtime/static path copies | Absolute-path rewrite, wrong __FILE__/debug/name or unproved copy deletion: mismatch/unresolved |
| E26 | B0/B4; C/N, F1 | Captured override versus per-request field, escaped placeholder stages | Expand RequestRef too early or CaptureRef too late: mismatch |
| E27 | B0/B4; R, F3 | Legacy opaque fragment retained in legacy output, typed mode unavailable | Drop raw fragment and publish supported typed mode: fail; output spelling alone not original native proof |
| E28 | B0/B5; R/N as applicable, F7 | Complete manifest versus one-file/header/tool mutation | Accept mixed generation, reuse stale request identity or start child on incomplete profile: fail |
| E29 | B2/B3/B5; C/N, F7 | Distinct spawn/nonzero/signal/cwd/query failures with tty available and unavailable | Treat all statuses as zero/nonzero only, lose diagnostic channel, retry legacy or let extra reaper consume child: fail |
| E30 | B5/B6; N, F6/F7 | Required language/runtime native suite and stage-specific header/decoder/provider changes | argv-only pass promoted to semantics; stale acceptance or unrelated provider epoch applied globally: fail |
| E31 | B1/B2/B4; C/N, F8 | phi/debug cross-product, debug -g order, semantic debug options | Native flags leak into phase case or semantic GSC debug options migrate to CC: mismatch |
| E32 | B1/B2/B4; C/N, F8 | Static toggle for exact -Bstatic/-static, direct-LD route, ordered include fragments | Universal static filter, reversed include order or repeated option loss: mismatch |

Negative controls test the **comparator/observer** as well as the candidate.
Inject record-level mutations (drop one argv element, replace empty by absent,
swap one event edge) into a copy of evidence and require rejection; keep original
records immutable. These are comparator sensitivity controls, not native runs or
proof the live observer could not miss an event. L2 calibration separately needs
known child cases, loss accounting and coverage for exec/spawn/cwd/env/status.

No hazardous legacy shell fragments need execution to prove managed refusal.
For unsupported syntax, retained source evidence and a managed no-effects test
are sufficient for EXPECTED_REJECTION, but not for ORIGINAL_NATIVE_MATCH.
E28 manifest validation is a new contract, not old-script observational parity;
E30 is preserved acceptance/invalidation. E06 is mapped-only. Count those
obligations by kind; never claim 32 equal native cases because 32 rows exist.

[Observation architecture D2](independent-observation-boundaries.d2) /
[rendered SVG](independent-observation-boundaries.svg) separates proposed capture
lanes from actual native acceptance.

The [Darwin supplemental paths](darwin-supplemental-evidence-design.md) refine
E19-E22/E24/E29-E30: source-copy/internal delivery evidence is not an original
witness, and output or failure streams need independent identity/loss coverage
before joining ES. No acquisition or E-row execution is implied.
