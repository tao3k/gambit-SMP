# Evidence-driven tool choices

This is a caller-owned policy for Agentic AI, not a command registry or an
execution capability. Questions, build identity, supported target formats and
declared prerequisites enter ordinary Evidence relations. The Library derives
options, missing premises, compiler context and reusable observations. No tool
order, retry count, unique best choice or closed investigation universe exists.

`ready` means only that all declared premises have source bindings. It does not
mean installed, permitted, runnable, source-correct, complete or repaired. Source
hashes bind bytes, not the truth of a host assessment. Tool availability, exact
binary/debug identity, model closure, permissions and execution budgets require
independent checked observations. None are inferred from a filename or compiler
family. The tool policy never grants execution, retry or acceptance authority.

## Capability basis

* GCC `-fdump-tree-*`/`-fdump-rtl-*` and `-fopt-info-*` inspect compilation
  transformations. They require reproducing the exact source/options; a
  diagnostic rebuild is not automatically the original runtime image.
  https://gcc.gnu.org/onlinedocs/gcc/Developer-Options.html
* GNU objdump disassembles supported targets; addr2line maps addresses and nm
  lists symbols. readelf is ELF-only, not a Mach-O reader. Installed target
  support must be checked, not inferred from the GNU name.
  https://sourceware.org/binutils/docs/binutils.html
* LLVM objdump inspects instructions, symbolizer resolves source/inlined
  locations, readobj inspects object structure, and dwarfdump verifies debug
  information. GCC-built objects are not excluded. No instruction listing
  establishes whole-program synchronization or a crash cause.
  https://llvm.org/docs/CommandGuide/llvm-objdump.html
  https://llvm.org/docs/CommandGuide/llvm-symbolizer.html
  https://llvm.org/docs/CommandGuide/llvm-readobj.html
  https://llvm.org/docs/CommandGuide/llvm-dwarfdump.html
* GDB/LLDB inspect threads, registers, watchpoints and memory. Attach may need
  permission and perturb schedules; an observed stopped state is not a liveness
  proof. Symbols, load slide and exact image identity remain separate premises.
  https://sourceware.org/gdb/current/onlinedocs/gdb/
  https://lldb.llvm.org/use/tutorial.html
* herd7 enumerates executions of a litmus under an explicit memory model. A
  forbidden bad outcome checks that litmus/model, not source refinement, object
  lifetime, fairness, native crash causality or performance. It does not repair
  code. C-level and AArch64-level experiments must keep their semantics distinct;
  a racy legacy volatile program cannot be silently recast as race-free atomics.
  Model includes/options/version, bounded loops and source/instruction mapping
  must be bound. litmus7 hardware execution is a separate capability.
  https://github.com/herd/herdtools7
* CBMC checks real C machine arithmetic, pointers, bounds and caller assertions
  under explicit environment and unwinding premises. The execution route is
  the existing `c.cbmc` Recipe capability. Contract/branch identity, source
  projections, ABI, complete property inventory, traces and process custody
  remain attached to each result. A timeout or internal checker failure is an
  unresolved verification question, not a counterexample to the C program.
  https://diffblue.github.io/cbmc/contracts-functions.html
* GenMC explores concurrent C at LLVM IR level under an explicit SC, TSO,
  RA, RC11, IMM or ARMv8 model. It can expose assertion failures and weak-memory
  executions in finite data-deterministic programs. The optional `c.genmc`
  Recipe capability retains real source cuts, atomic lowering, compiled LLVM,
  model, exploration bounds, raw output and error graphs. A randomized or
  bounded exploration is not complete verification. Its model pthread/libc
  environment is not a native Gambit process or a linked-image correspondence.
  https://github.com/MPI-SWS/genmc/blob/master/doc/manual/usage.md
* Frama-C/WP checks ACSL preconditions, postconditions, frame conditions and
  loop invariants using an explicit C/memory model and selected provers. RTE
  obligations and inconsistent-premise checks belong to the selected campaign.
  Declaring `assigns`, `requires` or an invariant is not proving it. A parsed
  file, tool exit 0 or a subset of proved goals is not complete verification.
  Eva is an alternative abstract interpretation for sequential C alarms; it
  does not establish the SMP memory model or scheduling properties.
  https://www.frama-c.com/html/acsl.html
  https://www.frama-c.com/fc-plugins/wp.html
  https://www.frama-c.com/fc-plugins/eva.html

## C contract questions and use

`evidence/scenarios/tool-reasoning/c-contracts.view.json` reuses this same
ASCENT component. It offers tools against memory geometry, machine arithmetic,
linked-list transactions, function/loop contracts and verifier cost questions.
There is no mandatory CBMC-to-WP fallback or ranking. The model chooses the
experiment and its discriminating observation. New tools remain possible.

For concrete C counterexamples, select a branch Recipe under
`tests/contracts/INTERFACE/CONTRACT/BRANCH/`, inspect its source cuts and caller
premises, then use `research --run ... --engine ... --out ...`. Read the retained
result through `research --read`. A required geometry proof is a source-bound
callee premise; it is not a requirement to complete unrelated models first.

For a WP investigation, supply ACSL clauses, actual C, target machine and
memory model, called-function contracts, loop invariants/variants where needed,
and the exact prover/runtime environment. Typical native arguments are
`frama-c -wp -wp-rte -wp-fct FUNCTION -wp-prover PROVER SOURCE.c`.
`-wp-help` describes the installed version's options. Retain every scheduled
goal and its status, unresolved goals, assumptions and source/tool identities.
The optional `c.frama-c` Recipe capability now executes this source-bound
observation. Its arguments declare `machdep`, `model`, `provers`, per-goal
`proverSeconds`, and named ACSL `obligations`, alongside the same contract,
branch, source cuts and caller assumptions used by the C lane. RTE and smoke
goals, disabled proof-cache reuse and a complete scheduled-goal/report match
are part of the adapter. This does not establish that arbitrary C is supported
by the chosen memory model.

Seal a caller-owned `frama-c-wp-runtime.v1` declaration with
`research --seal ENGINE --wp-runtime RUNTIME.json` and the existing compiler
and ASCENT arguments. The declaration has explicit `binaries` (Frama-C,
Why3, prover and required helpers), `directories` (Frama-C/Why3 package data
and declared native stubs), and `why3Config`. A configured prover command
and driver must belong to that closure. Execution checks bytes and package
membership before and after use, disables ambient Why3 detection, and uses
an owned provider-only PATH. It does not run opam or install a missing tool.
WP runtime inputs are not added to a CBMC-only Recipe's support inventory.

The report retains all top-level goals, their native statuses and source
locations. WP `failed`, `unknown`, `stepout` and `timeout` are unproved goals,
not validated C counterexamples. Smoke tests reverse ordinary proof logic:
proving their false goal exposes an unreachable context. Root-precondition
smoke warnings are distinguished from dead-code warnings, which can be
legitimate under a constrained caller. Unproved smoke goals are best-effort
checks, not a proof of consistent premises. No such result qualifies a
native producer. The actual-predicate controls are in
`evidence/fixtures/dev-cbmc-copy-plan/wp-check.recipe.json`.

The source-bound opam discovery route is
`evidence/tool-environments/frama-c-opam.json`, consumed by the existing
`gambit-smp --task TASK tool-environment --request FILE --out OUTPUT` entry.
Discovery probes versions and package paths without evaluating shell output.
It is separate from executing WP and from a sealed proof-runtime closure.

For outcome reachability, `c.cbmc` accepts named `witnesses` from its declared
assertion inventory. A harness deliberately asserts the negation of its
target state; a failure trace witnesses that state. Every other checked
property must succeed for `REACHED`. A trace accompanied by failed/unknown
safety checks remains `UNQUALIFIED_TRACE`. These observations have verdict
`REACHABILITY`, separate ASCENT rows, and never become `repair_needed` or
`VERIFIED` safety contracts. They keep all existing memory and unwinding
checks enabled, unlike a separate native `--cover` campaign. See
`evidence/fixtures/dev-cbmc-copy-plan/reachability.recipe.json`.

For a verifier timeout, inspect the actual phase, stack and resource footprint.
The `c.cbmc` capability accepts bounded `sampleAfterSeconds` and `verbosity`
observations. Compare equivalent storage representations at identical extents
and properties. Neither increasing a timeout, shrinking the native section nor
silently replacing the C body establishes the original contract.

CBMC's optional `paths` argument selects `fifo` or `lifo` single-path symbolic
exploration. It changes the verifier's state representation, not the program's
repair/retry order. All feasible bounded paths and unwinding obligations remain
part of verification. It is an option when merged conditional whole-object
values dominate formula construction; a completed per-path sample cannot stand
in for the complete checker verdict.

The normal Clue entry can discover these choices, for example:

```scheme
((bindings (("kind" "tool-choice")
            ("focus" "c-section-contracts")
            ("tool" "frama-c-wp"))))
```

Pass this data to `gambit-smp --task TASK trajectory clues`. Continue with its
checkpoint and expand a returned claim to inspect the policy, question and
environment references. These are tool-choice hypotheses, not installation,
execution-authority or verification claims.

## GenMC source concurrency lane

The local command remains `genmc --version` and `genmc PROGRAM.c`; an
explicit installation such as `.bin/genmc` can be used directly. In the
framework use `c.genmc` through the same `research --run` / `research --read`
entry. Nothing installs or resolves a fallback tool during verification.

Seal `research --seal ENGINE --genmc-runtime RUNTIME.json` together with the
existing compiler and ASCENT arguments. The caller-owned declaration is:

```json
{
  "schema": "genmc-runtime.v1",
  "binaries": {"genmc": "EXPLICIT_GENMC", "clang": "EXPLICIT_CLANG"},
  "directories": {"genmc-headers": "MODEL_HEADER_DIRECTORY", "clang-headers": "CLANG_RESOURCE_INCLUDE_DIRECTORY"},
  "libraries": ["DECLARED_LLVM_AND_COMPILER_LIBRARIES"]
}
```

Select binaries from the current environment or an explicit installation;
there are no Homebrew paths in the adapter. `clang -print-resource-dir` locates
its builtin header package. Supply its `include` directory and GenMC's model
header directory. Shared LLVM/compiler libraries are declared native inputs;
the OS remains an external premise. Header membership and every supplied file
are checked before and after use. Clang and GenMC must use the same LLVM major.
The currently qualified report profile is GenMC 0.20; other output versions
remain unsupported until their status parser is qualified.

Recipe arguments bind canonical `contract`/`branch`, `harness`, `function`,
`sources`, verbatim `projections` (or a complete maintained C file), named
`assertions`, `target`, `memoryModel`, `scope`, `assumptions` and `exploration`.
An empty assertion list explicitly requests GenMC's builtin race/memory safety
checks; it does not disable them.
Exploration declares `mode` (`verify`, `random` or `estimate`), optional paired
`bound`/`boundType`, optional `unroll`, and an explicit `randomBudget` for random
mode. These are model-owned experiment choices, not retry rules.

The adapter snapshots unchanged source, preprocesses only declared model and
builtin headers, and invokes the sealed Clang with default configuration files
and ambient system includes disabled. It retains `translation.i` and
`translation.ll`, then feeds the `.ll` directly to GenMC. This avoids GenMC's
embedded C frontend path or a shell selecting another compiler behind the
receipt. The checker input, transformed LLVM, tool/library/header identities,
source locations and failed-execution graph remain attached to the result.
Automatic memory-model detection is disabled so that the recorded model is
the caller's explicit selection.

`VERIFIED` requires a nonempty completed error-free verification exploration
without declared exploration bounds/unrolling. `BOUNDED` and `SAMPLED` retain
their limitations and do not populate the ordinary verified relation. Empty,
unsupported, timed-out or incomplete runs are `INCONCLUSIVE`. A matching first
assertion failure with exit 42 and an error graph is a `COUNTEREXAMPLE`; other
assertions remain unestablished, and the graph is not a native crash trace.
Recognized first race/memory errors also retain their graph as counterexamples.
A non-atomic race is reported at that first invalid contract, rather than
using a later assertion after undefined behavior as the repair witness.
Safety results do not establish scheduler fairness or unbounded liveness.

The qualified source entry is
`tests/contracts/concurrency/copy-gate/two-carriers/check.recipe.json`. It uses
Gambit's actual copy-gate functions and selected GNU sync macro definitions.
The relaxed-publication companion is explicitly a tool qualification litmus,
not a second implementation of the runtime. Raw diagnostics and counterexamples
are inputs to Grok's investigation, without a mandated next tool or repair.

Normal ASCENT discovery uses the existing Tool Reasoning component:

```scheme
((bindings (("kind" "tool-choice")
            ("focus" "c-concurrency-contracts")
            ("tool" "genmc"))))
```

This tool-choice record describes applicability and missing premises; it does
not assert local installation, verification success, source/image refinement
or native execution authority. QNT protocol histories and C/LLVM ordering checks
remain complementary. Original Family A, 295/300 and the 5/12 ledger are unchanged.

The retained 2026-11-12 qualification is
`.cache/tasks/modern-c-frame-contract/processes/audit/runs/9c1b1c8bfd1148bcae7704ca66625b27/outputs/genmc/verification`.
Normal `research --read` reports PASS, CURRENT identity and CURRENT evidence
binding. The actual projected Gambit copy gate verifies under RC11. The
relaxed-publication control yields `ready=1` with `payload=0`; the plain-access
control reports its first non-atomic race. Both retain DOT error graphs and raw
source traces. These controls qualify the adapter, not production runtime bugs.
The GenMC/CBMC/WP regression suite passed 32 tests. Native/source refinement
admission remains false. The earlier incomplete aggregate is retained separately.

```sh
.venv/bin/gambit-smp --task modern-c-frame-contract research --read \
  .cache/tasks/modern-c-frame-contract/processes/audit/runs/9c1b1c8bfd1148bcae7704ca66625b27/outputs/genmc/verification
```

## Real scope

`evidence/scenarios/tool-reasoning/ticket.view.json` investigates the archived
GNU GCC16.2 code-generation fixture and its still-open weak-memory obligation.
It is deliberately not a claim about the latest Working candidate. The actual
compiler version is read by exact JSON pointer from the original receipt.
Recorded assembly can be reused; it does not satisfy binary/debug/runtime or
herd model premises. The full ticket stress DENY remains bound as a competing
boundary; no positive finite or code-generation result closes it.

The Action entry is `evidence/scenarios/tool-reasoning/action-context.json`.
Selection observes the inferred view through the existing revision/permission
kernel. Tool execution is not added by this change. Python contains no tool
selection or research inference branches.
