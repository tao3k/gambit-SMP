# Configured Darwin Inputs, Decoding and Retirement Gates

Date: 2026-10-20. Design only: static source/artifact/receipt inspection; no
configuration, compiler, package query, implementation or performance run.
This refines the [effective model](effective-configuration-darwin-gcc.md).
C1-C8 below refer to the [evidence ledger](darwin-configured-input-evidence.md).

## 1. Concrete Baseline and Its Limits

A generated **`bin/gambuild-C.unix`** survives in the materialized Gerbil
Gambit tree (C1). Earlier searches for `gambuild-C` missed this filename.
Its configuration is useful evidence, but it is neither the research vendor
revision nor the historical frozen D1510 driver. C2 binds the accompanying
config.status/log/header bytes. The ledger reproduces all initial bindings,
including full ordered flag strings, rather than reconstructing a toolchain
from historical timings.

| Field | Retained value / consequence |
| --- | --- |
| Compiler / preprocessor | `/opt/homebrew/bin/gcc-16`; preprocessor command adds `-E`; separate tool roles |
| Recorded compiler | config.log reports Homebrew GCC 16.2.0, `aarch64-apple-darwin25`; recorded compiler build sysroot `/Library/Developer/CommandLineTools/SDKs/MacOSX26.sdk` |
| Configured build/host/target | `aarch64-apple-darwin25.6.0`; native configuration, not cross/universal support |
| Captured C override default | `-foptimize-sibling-calls `; unset selects this, explicit empty suppresses only this contribution |
| Captured LD default | Three ordered `-L` words for Homebrew openssl@3, sqlite and zlib; preserve order |
| Object/dynamic optimization | `FLAGS_OPT=" -O1"`; `FLAGS_OPT_RTS=" -O3"` is a distinct runtime recipe input |
| Macro tracking | `-ftrack-macro-expansion=0` already present; introducing Zig cannot claim this existing gain again |
| Dynamic / library | `-bundle` in FLAGS_DYN; FLAGS_LIB has make placeholders and `-dynamiclib`; BUILD_LIB is unimplemented and remains rejected |
| Generic executable | FLAGS_EXE repeats the common flag block; runtime is `GAMBITDIR_LIB/libgambit.a`; no independent FLAGS_OPT segment |
| Package tool | `PKG_CONFIG=""`; a package request follows the unavailable-tool warning/failure route, not an inferred PATH lookup |
| Features | Known labels unix/windows/gcc/clang/visualc/cc; true labels unix and gcc only; Darwin is not a recognized metadata feature |
| Header | Version 409008; default multiple independent VMs, default single-threaded VMs, default MAX_PROCESSORS=1; conditional overrides still matter |

The recorded sysroot is the **compiler's configuration report**, not a hash of
SDK content or proof of the SDK used by every later request. Deployment target,
compiler/linker bytes, specs, include search paths, runtime archive and installed
activation identity remain unbound here. No new managed profile is qualified.
`--enable-smp` in config.status does not override the generated header evidence
or establish scheduler/native behavior. Header and request macros must be
resolved together. Likewise `--enable-single-host=0` and `___SINGLE_HOST` are
not contradictory by themselves: the header sets SINGLE_HOST_LIMIT=0 and its
conditional host-selection rules govern the generated unit (C2).

C3 records historical macro-tracking and packed-string improvements. C4 records
a denied extra coordinator. Neither makes this generated configuration the
identity of those runs. Referenced private D935/D1510 directories were absent
at the bounded paths checked this turn; durable reports remain usable as
historical claims, not as recovered raw argv logs. No missing path was rebuilt.

## 2. String Decoding Is a Composition, Not One Tokenizer

C1 and C5 distinguish six encodings. The proposed importer must record
`sourceKind`, raw bytes/digest, decoder ID/version, field, origin/presence,
ordered output words and rejection reason. A decoder's output is only a
candidate; mode/profile and native argument admission still follow.

| Source kind | Actual old path | Managed interpretation / limit |
| --- | --- | --- |
| Configure SH binding | Shell assignment quoting first establishes strings; FLAGS reference the captured C/LD bindings; escaped BUILD placeholders survive until substitution and final eval | Read authoritative configured data. A transitional inert importer accepts only known assignments and whitelisted field references in this exact template family; never source the script |
| Scheme string/list native option | `##multiple-args-join` returns strings unchanged, joins lists with LF; accumulation splits LF and appends spaces; final eval parses the resulting option fragment | A list element was not necessarily one native argument. `"-D___DYNAMIC -fPIC"` still denotes two words. Decode the admitted literal-word fragment subset in its actual composition |
| Input/output filenames | LF transport, then `shell_quote` iterates unquoted `$1` and invokes unquoted `${arg}`, then single-quote encoding, then eval | Quoting happens after possible field splitting/globbing. Initial legacy import accepts only nonempty simple paths without whitespace, glob patterns or control bytes; new typed paths may support more but cannot claim legacy parity |
| Metadata payload | grep marker extraction, eval_sexpr string placeholders/boolean reductions, limited Scheme escape decode, accumulation with spaces, final eval | Condition parser and payload word decoder are separate. Preserve source/field/order; reject malformed/unsupported serialization rather than use a general Scheme reader as proof of legacy equivalence |
| Package request/result | Request loop uses outer LF IFS; invocation temporarily uses space IFS for `$arg`; result accumulation uses LF; eventual eval interprets result option fragments | No universal pkg-config/shlex convention assumed. Version constraints may be multiple request words; result quoting needs the admitted literal-word decoder. PKG_CONFIG itself is not passed through shell eval at query invocation |
| Gerbil direct-link LD string | `gcc-ld-options` splits literal U+0020 and drops empty parts; quotes and backslashes stay ordinary characters; repeated option occurrences append in order | Preserve that exact split for admitted simple historical input; do not apply a shell decoder. New typed LD vectors require producer changes |

Unquoted expansions in loops also permit pathname expansion before final eval.
Quotes inside the expanded data do not retroactively quote those earlier
expansions. Command substitution strips trailing newlines; LF transport cannot
preserve embedded LF/empty list-element boundaries. Consequently a successful
parse by a modern shell-word library alone is **not** a losslessness argument.
C1's Darwin literal-substitution patch reduces substitution machinery but
still calls shell_quote and final eval. It is not an argv implementation.
Its LF/control-byte fallback must remain mapped until M7 replacement is admitted.

### 2.1 Selected Admission Rules

These are proposed restrictions, not an implemented decoder or executed fixtures.
First validate the source-specific preconditions above; only then apply the
literal-word grammar. One fragment consists of whitespace-separated words
formed from ordinary unquoted characters, single-quoted literal spans,
double-quoted spans without expansion, and supported literal backslash escapes.
Adjacent spans concatenate; balanced quoted empty spans may form an empty word.
Interpret this grammar only where the old route eventually parses shell words.
All quoting/escaping must be complete; no locale-dependent interpretation.
Reject expansions, commands and filesystem-dependent token construction before
resolution. The old pre-eval stages further restrict that grammar's admitted use.

| Input class / example | Decision and reason |
| --- | --- |
| Known captured flag blocks, including duplicate flags | Statically representable as ordered words; preserve duplicates and configured suppression; executable identity still separately required |
| Legacy option fragment `-D___DYNAMIC -fPIC` | Two arguments; lossless within the simple-word subset used in C4/C7 |
| Quoted space in legacy option value | Conditional only: preserve literal quoting at final eval, but reject if early unquoted stages can split/reconstruct/glob it differently; not blanket support |
| New producer vector `["-I", "a b"]` | Literal typed words supported by the new contract; this is not evidence old filename transport preserved spaces |
| Empty string/list in legacy option transport | Both can collapse to no words; do not infer `[""]`. Typed empty argument needs explicit new emission and a declared behavioral extension |
| `$VAR`, `${VAR}`, `$()`, backticks, arithmetic, tilde expansion | Reject raw legacy ingress; values would depend on shell evaluation. Whitelisted configured field references are typed references, not general expansion |
| Glob syntax, command separators, redirection, pipelines, comments, LF/CR or control sentinels | Reject initial legacy fragment admission; do not execute to discover meaning. A literal typed argument can have a different declared capability |
| Response-file arguments such as `@flags` | Reject initial profile until response-file content, nesting, cwd and dependency invalidation are modeled |
| Raw CC override / executable wrapper string | Rejected initial profile even if lexically simple; old override clears mode FLAGS and is not ordinary compiler reselection |
| Direct Gerbil LD `-L"a b"` | Old route splits into `-L"a` and `b"`; reject initial managed migration rather than silently repair it into `-La b` |
| Non-UTF-8 / NUL / ambiguous transport boundaries | Reject initial profile; UTF-8 exact bytes without normalization remains the selected contract |

Rejection applies to **this managed profile**. Preserve an explicitly selected
legacy profile for existing workloads; never retry through it after managed
resolution/tool effects. A rejection must identify field, source decoder,
location and unsupported construct, not report a compiler failure.

## 3. Metadata Conditions and Effects

C1's reducer is textual and whitespace-sensitive; it is not a complete Scheme
evaluator. A structured producer emits the following typed subset; importing
legacy C requires canonical producer-shaped forms and supported escapes.
Arbitrary handwritten equivalent Scheme syntax is not automatically admitted.

Descriptive grammar: `Feature = unix | windows | gcc | clang | visualc | cc`;
`Predicate = boolean | Feature | (and Predicate*) | (or Predicate*) |
(not Predicate)`; `Entry = String | (when Predicate String)`.
Only configured selected labels become true. The proposed parser validates
whole trees and arities, including suppressed branches; it does not execute
Scheme or evaluate user procedures.

| Expression / key | Mapping / compatibility boundary |
| --- | --- |
| unix / gcc | True for C1; tied to configured feature data, not runtime host probing |
| windows / clang / visualc / cc | False for C1; `cc` is a label, not all C compilers |
| `(and)` / `(or)` | True / false under the inspected reductions |
| nested and/or/not | Boolean composition; preserve exact supported canonical representation on legacy import |
| `(when #t "...")` / `(when #f "...")` | Decode selected payload / emit none; record both selection outcomes |
| `(when darwin "...")` | Unknown feature; old reducer cannot normalize it, warns/ignores; managed profile rejects, not silently false |
| Unsupported form, bad arity, malformed string/escape | Old unsupported-expression warning/ignore where reducer reaches that outcome; managed admission rejects explicitly. No claim all malformed input had safe uniform legacy behavior |
| cc-options | Ordered compile fragments, after package cflags and before explicit CC options |
| ld-options-prelude / ld-options | Distinct pre-input and tail positions, even though object mode does not consume link slots |
| pkg-config-path | Metadata additions then explicit additions, each prepended; last addition wins; preserve ambient baseline |
| pkg-config | Metadata requests then explicit requests; each issues cflags then libs, including in obj mode; retain failure/diagnostic order |

C1's scheme_string_decode supports its specific quote/backslash and t/v/f
substitutions; it is not a full Scheme Unicode/hex/newline escape codec.
Reserved internal control sentinels, embedded newlines and noncanonical escaping
are outside initial legacy import. A newly typed metadata string does not
inherit those serialization losses, but its word payload semantics still need
an explicit decoder or producer-owned argv emission.

`MetadataRecord` needs source unit/digest, key, ordinal, typed expression,
feature-set identity, payload encoding and origin. Resolution adds selected or
suppressed status, decoded words, diagnostic and action dependencies.
A source-bound record cannot be transplanted to another C unit with matching
filenames alone. The patched Darwin route's runtime-C metadata source remains
distinct from the static object bundle input.

The old initial package/path scan passes quoted `$1` as a **single grep filename**,
whereas later CC/LD collection loops over files. Do not silently generalize it
to multi-file package collection. Initial legacy-compatible ingress accepts
one metadata source (or none); multi-source typed metadata needs a separately
declared producer contract. Semantic linker composition is different: C6
combines LD and package metadata in module order but does not collect CC options
in that function. Gambit must retain that semantic composition; Zig must not
rescan every original module and accidentally reintroduce CC/link options.

With C1's empty package tool, a nonempty package request cannot yield a successful
plan under this exact profile. Do not discover a host pkg-config instead. Adding
a resolver requires a new profile identity and bound tool/search/dependency
record. No query was executed to inspect results here.

## 4. M1-M12 Retirement Recheck

All entries remain **open**: this study designs gates, not a migration. Retire
only the managed caller path, not shared public/runtime ownership.

The [dual-output model and concrete requests](single-source-native-profile.md)
and [E01-E30 matrix](native-argv-equivalence-matrix.md) refine M2-M8 with
independent process-boundary observations and per-caller retirement conditions.

| Item | Additional concrete exit condition | Evidence / present limit |
| --- | --- | --- |
| M1 | Snapshot native tool/environment ingress; bind configured compiler versus Gerbil direct linker separately | C1/C2/C5; actual binary/specs/linker identity incomplete |
| M2 | Tag each producer field by encoding; direct-space-split and shell-fragment routes must not share a decoder | C5; empty/quoted/ordered option parity not executed |
| M3 | Emit closed native intents for each native call, without nesting gsc -obj; preserve semantic-link barrier | C5/C7; no replacement implemented |
| M4 | Preserve PIC/dynamic defines, runtime metadata source, static input, alias tail and bundle error boundary | C5; bundle role is not dylib support |
| M5 | Stop LF environment round-trip for migrated calls; declare lossy input refusal or explicit typed extension | C5; old transport cannot recover all original vectors |
| M6 | Typed canonical conditions, field order, warning/rejection policy, package query effects and source-bound metadata | C1/C6; empty package resolver and multi-source scan restriction prevent blanket compatibility |
| M7 | Direct argv execution, known template slots only; remove both portable and Darwin literal substitution from managed path | C1/C7; 0015 still evals, so its presence does not close M7 |
| M8 | One authoritative config producer emits shell and typed data; compare actual header/defaults/recipes, preserve duplicate FE flags | C1/C2; configure CLI and generated header are not interchangeable; no emitter exists |
| M9 | Retain path/cwd/copies pending macro/debug/metadata/output-name parity | C5; static/dynamic source identity is not path interchangeability |
| M10 | Preserve Gambit status/error delivery and exclusive child ownership; keep ordered query failures | Prior migration R8 plus C1; no lifecycle acceptance |
| M11 | Retain semantic linker metadata composition, GC/control/FFI/module setup and runtime admission | C6 and prior R7/R9; decoded argv is not native correctness |
| M12 | Preserve outer source/native/platform gates; no new scheduler or global LLVM cache epoch | C4/C8 and prior design; historical success/denial is not this profile's acceptance |

Required future parity evidence is per source kind, mode and profile: admitted
input boundaries, exact ordered argv/env/cwd, resolution actions and diagnostics,
header/runtime/tool identities, mutation rejection and native acceptance.
A design review cannot mark these gates passed. LLVM service upgrades invalidate
only referenced service stages unless a shared runtime/configuration contract
changes; raw decoding changes invalidate plans that actually used that decoder,
not every unrelated C artifact. See the [stage invalidation matrix](effective-configuration-darwin-gcc.md).

The structural benefit remains replacing multiple native encodings/resolvers
with one typed authority, while leaving language semantics in Gambit/Gerbil.
C4's 0.88s versus 1.59s component result is a warning against adding another
preparation layer; it is not a savings estimate for this design.

## 5. Diagrams and Evidence Boundary

[String decoding and admission D2](legacy-string-decoding.d2) /
[SVG](legacy-string-decoding.svg), and
[metadata resolution D2](metadata-admission.d2) /
[SVG](metadata-admission.svg) show the proposed boundaries.
The evidence ledger binds inspected bytes and historical report scope.
All examples are static architectural cases. No decoder, compiler, package
query, runtime test or timing experiment was implemented or run.
