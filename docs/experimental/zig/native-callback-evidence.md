# Native Callback Custody: Source and Primary Evidence

Reviewed 2026-10-21. Research HEAD
`1a2d8612f2065387c62858e10baf63ce369cc48c`; Gambit HEAD
`7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Working bytes, not just commit
names, are bound in the [trace](native-callback-traceability.json). Existing
patches, recorded Darwin configuration and vendor baseline are separate
identities. No new compiler expansion, native experiment or proof-engine run.
The inventory is selected manual caller tracing, not a whole-program census.

## Gambit and Recorded Configuration

| ID | Source anchors | Observation and limit |
| --- | --- | --- |
| NE01 | [public map](../../../vendor/gambit/lib/gambit/list/list.scm#L850), 850–929; [capture macro](../../../vendor/gambit/include/gambit.h.in#L6589), 6589–6618; [capture materialization](../../../vendor/gambit/lib/mem.c#L3667), 3667–3966; [dynamic state](../../../vendor/gambit/lib/_thread.scm#L340), 340–477, 4623–4706, 4908–5078 | Map calls arbitrary proc and retains pending work; capture can leave stack-backed frames until materialization. Denv/cache/binding aliases require their own writer coverage. Scheme continuation lifetime is not C activation lifetime. Prior map point/layout and writer studies supply detailed frame correspondence; no regenerated C. |
| NE02 | [Tcl bridge](../../../vendor/gambit/examples/tcltk/tcltk.scm#L124), 124–195, 217–228, 260–345 | Actual ClientData → RC data → still vector → proc → apply path; creation, delete callback and result string release are distinct. Source failure path and deletion during invocation do not establish the external Tcl ownership/thread/escape contract. |
| NE03 | [FFI generator](../../../vendor/gambit/gsc/_ptree2.scm#L2902), 2902–3012, 3200–3254, 3295–3336; [SFUN macros](../../../vendor/gambit/include/gambit.h.in#L10040), 10040–10066; [CFUN macros](../../../vendor/gambit/include/gambit.h.in#L10325), 10325–10405 | scheme-object parameters converted before other types; cleanup requirement chooses a CFUN body catcher. SFUN error handler reenters Scheme through temp1–4. Generated conversion cleanup and normal END are not proof of per-scope cleanup on unmatched outer unwind. |
| NE04 | [RC operations](../../../vendor/gambit/lib/mem.c#L674), 674–829; [RC scanning](../../../vendor/gambit/lib/mem.c#L3969), 3969–3996; [baseline strong phase](../../../vendor/gambit/lib/mem.c#L6840), 6840–6873; [existing cumulative patch](../../../patches/fixtures/processor-interrupt-collective-wait-cumulative.patch#L3160), 3160–3234, 3433–3452, 4362–4385 | Plain list/refcount/data operations; collector updates data location. Baseline P0 call versus patched per-processor call and donor transfer are different source layers. cleanup_rc frees its list independent of native refcount. Existing repair is credited, not newly implemented or requalified. |
| NE05 | [call/run](../../../vendor/gambit/lib/setup.c#L3275), 3275–3422; [throw/propagate](../../../vendor/gambit/lib/setup.c#L839), 839–867; [return to C](../../../vendor/gambit/lib/_kernel.scm#L1019), 1019–1071 | call creates RA/marker frame, sets GVM state, enters configured host/trampoline TRY, matches destination or rethrows. Kernel checks marker/processor. run has an outer TRY; its normal marker kill is not an independently established unmatched-unwind cleanup. |
| NE06 | [manual C-return case](../../../vendor/gambit/doc/gambit.txi#L12208), 12208–12267; [identity conversion](../../../vendor/gambit/doc/gambit.txi#L19137), 19137–19145; [still-root conversion example](../../../vendor/gambit/doc/gambit.txi#L19835), 19835–19895 | Existing documented capture/resume example reaches multiple-c-return exception after original return. Wrong-processor return is separate. scheme-object exposes raw representation; manual converter explicitly retains still objects across allocating constructors. Manual sample was read, not executed. |
| NE07 | [dynamic closure](../../../vendor/gambit/lib/os_dyn.c#L637), 637–675, 744–789, 1045–1058; [procedure conversion](../../../vendor/gambit/lib/c_intf.c#L2887), 2887–2968; [PSTATE binding](../../../vendor/gambit/include/gambit.h.in#L8622), 8622–8635, 8690–8720; [thread setup](../../../vendor/gambit/lib/os_thread.c#L697), 697–709 | Dynamic code is guarded by target provider; c_closure_self is global with TLS TODO. Native thread setup/binding is distinct from callback admission; fixed binding macros do not prove nested nonlocal restoration. Tcl static entry does not require this trampoline. |
| NE08 | [pointer ownership](../../../vendor/gambit/lib/c_intf.c#L1682), 1682–1776, 2825–2883; [string copies](../../../vendor/gambit/lib/c_intf.c#L3199), 3199–3310, 3625–3658; [Scheme wait](../../../vendor/gambit/lib/_thread.scm#L2530), 2530–2566; [wait wrapper](../../../vendor/gambit/lib/_kernel.scm#L4505), 4505–4522; [C wait](../../../vendor/gambit/lib/os_io.c#L11493), 11493–11607 | FOREIGN pointer conversion unwraps external storage; release_foreign clears wrapper then calls release_fn; release_pointer is no-op. String conversion allocates independent RC bytes. Wait wrapper saves/restores GVM state; C adapter caches Scheme condvars/device pointers across queue unlock/wait/relock. These copies are not covered by merely saving GVM registers. |
| NE09 | [marker](../../../vendor/gambit/lib/c_intf.c#L6511), 6511–6562; [saved roots](../../../vendor/gambit/include/gambit.h.in#L8059), 8059–8086; [saved scanning](../../../vendor/gambit/lib/mem.c#L6526), 6526–6538 | Explicit TODO about proc_or_false before allocating marker. Marker slot zero roots proc/validity and threaded slot one records processor. saved[0..2] are fixed published scratch locations; SAVE1/RESTORE1 does not create nested reservation semantics. |
| NE10 | [TRY and cleanup](../../../vendor/gambit/include/gambit.h.in#L9959), 9959–10012; [recorded build script](../../../../ci-source-patch-check/src/gambit/bin/gambuild-C.unix#L15), 15–38; [recorded header](../../../../ci-source-patch-check/src/gambit/include/gambit.h#L1580), 1580–1600, 1670–1695, 6818–6840 | Recorded GCC path / flags and conditional setjmp, C++ and tail/trampoline branches. Raw header token occurrence is not active preprocessed configuration. No binary/configuration equivalence or mixed Zig nonlocal ABI qualified by reading it. |
| NE11 | [OCaml root lists](../../../vendor/ocaml/runtime/globroots.c#L28), 28–100, 116–178, 235–254; [named callback registration](../../../vendor/ocaml/runtime/callback.c#L387), 387–431; [blocking hooks](../../../vendor/ocaml/runtime/signals.c#L147), 147–217, 300–310; [local-root exits](../../../vendor/ocaml/runtime/caml/memory.h#L439), 439–456 | Concrete root-classification support, registry synchronization, rooted lock acquisition/reload, blocking hook and pending action handling, and root-head restoration. Surrounding OCaml collector/domain rules are part of their correctness; membership mutex alone is not a portable proof that plain root update races are safe. |

Local OCaml HEAD `46e1c324fb9e9f21f52c9cc3399020f7ef8b9b91`,
[VERSION](../../../vendor/ocaml/VERSION) reports 5.5.1. It is a separate source
identity from the published 5.3 manual/header. Neither is equated to a tested
Gambit/OCaml binary. Remote `runtime/callback.c` and `globroots.c` fetches
failed with cache miss in this study; local inspected sources above supply
the source claims instead. These failures are not positive retrieval evidence.

## Primary Literature and Platform/Language Rules

| ID | Primary evidence | Bounded use |
| --- | --- | --- |
| NP01 | [OCaml C interface](https://ocaml.org/manual/5.3/intfc.html), §§5.1, 7.3, 12.1–12.2 | Rooted locations and cooperative updates differ from heap access permission. Native threads require registration. Named root values can change during GC. Blocking transitions may run pending callbacks/raise and forbid managed access while released. Gambit's analogous participation protocol must be derived, not copied. |
| NP02 | [Retrofitting Parallelism onto OCaml](https://anil.recoil.org/papers/2020-icfp-retropar.pdf), §§1.2–1.4, 5.4 | Existing C access assumptions constrain collector design; activation/scanning of fibers needs explicit synchronization. Infer a Gambit access protocol; do not import benchmark percentages or assume current library internals match the paper. |
| NP03 | [WG14 N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf), §5.1.2.4 ¶25; §7.13.2.1 ¶2–3; §7.17.3 | Conflicting unsynchronized non-atomic actions are undefined; longjmp needs a live same-thread environment; certain modified nonvolatile automatic locals become indeterminate. Proposed gate, cut and off-stack ledger are deductions from these constraints, not supplied algorithms. |
| NP04 | [Retrofitting Effect Handlers onto OCaml](https://kcsrk.info/papers/retro-concurrency_pldi_21.pdf), §§2.3, 3.1–3.2, 5 | Deliberate one-shot and no-C-frame capture choices, mixed-stack exception handling and cleanup tradeoffs. Gambit retains different Scheme and native-marker semantics. The paper does not validate jumping across Zig frames. |
| NP05 | [OCaml callback header](https://raw.githubusercontent.com/ocaml/ocaml/5.3/runtime/caml/callback.h), lines 26–52 | Explicit propagating versus typed result callbacks offer distinct boundaries. This is inspiration for an intentionally specified service result, not equivalence of a returned error and a Scheme continuation transfer. |
| NP06 | [A Parallel Virtual Machine for Efficient Scheme Compilation](https://www.iro.umontreal.ca/~feeley/papers/FeeleyMillerLFP90.pdf), §§1–2 | Historical Gambit motivation for a target-parameterized semantic machine and frontend/backend information exchange. Supports the architectural direction; does not describe today's FFI, prove a modern GC or require Zig. |
| NP07 | [Zig language reference](https://ziglang.org/documentation/0.15.1/), tagged unions, error unions, defer and atomics | Private state/ordinary cleanup can be expressed with typed mechanisms. No lifetime, moving-root, complete GC or foreign-longjmp guarantee follows from those facilities. Compare against generated/opaque modern C, not today's raw C macros alone. |

NP references are primary reading identities, not downloaded byte-pinned
inputs. No quotation or numerical performance result is reused. The
architectural conclusions and formulas are our conditional deductions.

## Existing Design Dependencies

ND01. [Writer/caller closure](continuation-writer-closure-design.md),
[minor edge-cut proof](continuation-minor-scan-proof.md) and
[writer matrix](continuation-writer-benefit-matrix.md): complete aliased
frame/denv/root writers are required for mature graph elision.

ND02. [Owned callback / participating wait](owned-callback-participating-wait-contract.md),
[RC caller evidence](rc-marker-caller-evidence.md),
[root custody](shared-runtime-root-custody-design.md): existing fixes,
participation cuts, donor transfer and lifetime requirements are credited.

ND03. [Generated native contract](generated-c-native-contract.md),
[map generated C](map-generated-c-design.md),
[GC architecture](gc-native-runtime-design.md): Scheme remains semantic owner;
generated C is the mainline, other providers share the same native contract.
