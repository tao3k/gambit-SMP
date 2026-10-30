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
