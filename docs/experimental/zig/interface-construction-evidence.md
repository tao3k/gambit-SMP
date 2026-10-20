# Interface Construction Evidence Ledger

Date: 2026-10-19. Companion to the
[architecture](interface-construction-aot-design.md). All timings below are
retained historical observations, not measurements of the proposed design.
The current research checkout and parent patch repository do not make those
historical binaries equivalent to the current SMP runtime.

## Repository Evidence

| ID | Source | Observation | Architecture consequence / limit |
| --- | --- | --- | --- |
| E1 | [D1510 interface architecture transfer](../../../../../patches/gerbil-v19-darwin/receipts/d1510-interface-architecture-transfer.md), especially Exact Gerbil Boundary, Source Audit, Construction Program | Metadata generation consumes expanded code; imports create retained mutable records; normal expansion has two stages with deferred exports; sealed syntax is not an effect validator | Compile a construction program; retain live effects, record identity and compiler-facing fields. No raw quote or initialized-context sharing |
| E2 | [D1510 interface reader budget](../../../../../patches/gerbil-v19-darwin/receipts/d1510-interface-reader-budget.md) | make/test/json/list reader-own wall observations 0.024055 / 0.022395 / 0.059050 / 0.040119 seconds; JSON allocation delta crosses GC and is unqualified | Parser replacement alone has no evidence for a major startup gain; observed times are not an uninstrumented whole-prefix budget |
| E3 | [D1510 real phase import boundary](../../../../../patches/gerbil-v19-darwin/receipts/d1510-real-phase-import-boundary.md) | Existing native phase init: first 0.007957s, later 0.001339 / 0.000774s, 78,944 bytes; wrapper restoration 0.001655 / 0.001597s, 1,902,800 bytes, dependencies already loaded | No stable advantage over native reuse; approximately 24x wrapper allocation in this control. Do not extrapolate source-eval comparison to the real prefix |
| E4 | [D1510 joint import/eval](../../../../../patches/gerbil-v19-darwin/receipts/d1510-stdlib-joint-import-eval.md) | Own accounting subtracts observed children; first-import residuals still include internal work and observer overhead; raw submodule-key miss is not an interface-cache miss | Do not call residuals pure reconstruction, sum overlapping intervals, or reopen the same census |
| E7 | [D1510 head resolution live boundary](../../../../../patches/gerbil-v19-darwin/receipts/d1510-head-resolution-live-boundary.md) | Failed public-resolver wrapper did not intercept internal direct calls. Corrected reached-predicate control mutates a binding between resolution and caller dispatch; 408 ordered diagnostic cases pass | Unguarded terminal result transfer is wrong; preserve live dispatch observations. Diagnostic cases establish neither complete conformance nor a speedup |

E1 retains source anchors at `compiler/driver.ss:844,904`,
`compiler/compile.ss:1258,1438-1496`, `expander/module.ss:15-22,139,633-645,783-789,840-872`,
`expander/top.ss:273,327`, `expander/stx.ss:35-40`, and
`expander/core.ss:281,430-438`. These are **report-bound historical source
audits**, not a claim that this update reread the exact historical Gerbil source
checkout. The reports themselves were read. Generated setters and SSI exports
recorded in E1 establish that a final record type is not an immutable record.
No absence of mutation in a local caller proves safe global sharing.

E1's runtime-declaration handler observations are make 5,369 / 0.008585s,
test 3,604 / 0.002566s, json 8,979 / 0.038180s and list 3,151 / 0.046725s.
The timer begins at the selected expander `e` handler, after head expansion,
identifier resolution and method selection. It neither establishes a large
unmeasured budget nor bounds that budget by the measured handler interval.
An export wrapper has no hits because the body directly calls export logic;
that does not imply zero export work.

Its import-binding census records 61,428 / 31,956 / 110,753 / 30,767 phase-zero
symbol-key attempts, with zero prior object retained in this narrow observation.
Repeated-key fractions are approximately 8.75 / 2.36 / 8.50 / 2.45 percent.
These are not CPU fractions, universally redundant effects or safe deletion
counts. Non-symbol and phase-shifted imports are outside that census.

E7 supersedes the source-only suggestion in E1's Single-Step Head Resolution
Transfer section. Its failed observer remains preserved, rather than being
treated as evidence that internal resolution has no effects. E1's later CPU
follow-up includes bootstrap and imports; host/hash samples cannot identify an
exclusive removable interface-dispatch wall-time fraction. Its later context
table audit also preserves pair-identity keys and rebinding callbacks, rejecting
a symbol-only substitution for the public table contract.

The historical first-log observations remain 4.850866 / 4.573628 / 4.592897s;
complete cold builds 47.771713 / 47.824226 / 47.927094s. Referenced original
whole-task gates are 5 / 50 / 112s. Current stable complete-test admission is
open. No diagnostic pass changes that status.

## Primary Literature and Transfer Limits

| ID | Primary source | Supported transfer | Not established |
| --- | --- | --- | --- |
| E5 | [Racket Linklets reference](https://docs.racket-lang.org/reference/linklets.html); [Flatt et al., Rebuilding Racket on Chez Scheme, ICFP 2019](https://www-old.cs.utah.edu/plt/publications/icfp19-rddkmstz.pdf), section 3 and Figure 2 | Separate compiled code from instantiation against imported variables. Module elaboration can produce runtime/compile-time linklets and syntax-construction components | Gerbil lexical metadata, phases and mutable records are not automatically Racket-compatible; no transplant speedup |
| E6 | [MLIR Side Effects and Speculation rationale](https://mlir.llvm.org/docs/Rationale/SideEffectsAndSpeculation/) | Distinguish memory effects from speculation/divergence and other behavior; custom effectful operations need explicit legality | No automatic treatment of Scheme continuations, current bindings or alias identity; no purity inferred from a structural region |

Racket's linklet input sits below macros, and correlated representations omit
lexical context. Instantiation provides current imported variable instances and
evaluates code. This is a staging precedent, not permission to persist Gerbil
syntax objects. Cross-module compilation assumptions must match later imports.

The ICFP paper also reports startup/loading and compilation tradeoffs; native
compilation is not a universal startup improvement. Its evaluation and
[supplement](https://www2.cs.utah.edu/plt/rkt-on-chez/appendix.pdf) do not qualify
this Darwin/GNU/Gambit configuration. The proposed constructor still needs its
own semantic coverage and cost attribution.

## Evidence Discipline

Source shape establishes a possible mechanism, diagnostic controls constrain
observable behavior, and matched complete workloads would establish product
benefit. None substitutes for the others. This update adds only a design and
documentation checks. Rejected restoration, sharing and resolver routes are
not rerun. Report files can acquire later addenda; any future admission must
bind the exact report/source/runtime bytes used, not just a filename.

The following SHA-256 snapshot identifies the report files at this review's
documentation checkpoint. It binds reports, not unavailable historical source
trees or new native acceptance:

| Report | SHA-256 |
| --- | --- |
| `d1510-interface-architecture-transfer.md` | `88fa4275c0c6f2fa41309b61f5d3f5b9e51c23faf61c115160f689e18c16120e` |
| `d1510-interface-reader-budget.md` | `b65ab19e4f0aa7d6a6c8f313be4d8e0b80907ff52980d316a881c28ed4e2075b` |
| `d1510-real-phase-import-boundary.md` | `7e14d019b850e23d4df547c6b70e706dbeaf1bc41f750fd0d09c155b4364e5b4` |
| `d1510-stdlib-joint-import-eval.md` | `e2be0c3379241b8d4d7f4e58c3a323979f3a7c4799f3492557a3292be441d43d` |
| `d1510-head-resolution-live-boundary.md` | `0c5d3b69af12840a9eeb281ca95ca3d9e103d136b0825a54397c2e46f9f375e0` |

Documentation checks: 171 local file references across this collection resolve;
Markdown table widths are consistent. `interface-code-instance.d2` renders with
D2 0.9.0 (`dagre`, theme 0) and its SVG was visually inspected. These checks do
not execute an interface, constructor, compiler or performance workload.
