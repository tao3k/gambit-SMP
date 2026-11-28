# NJS Executor and Modernization Evidence

Reviewed: 2026-10-20. Research HEAD `b67da6262a973a0ae898002d5c7f5be2d8b5a90d`;
Gambit HEAD `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`. Local bindings identify
working-copy sources. Design/source research only; no implementation, native,
compiler/performance test, configuration probe or ASCENT evaluation.

## 1. Direct Source / Retained Design Premises

| ID | Read anchor | Finding / limit |
| --- | --- | --- |
| X01 | [gambuild-C.unix.in](../../../vendor/gambit/bin/gambuild-C.unix.in):177-205,239-283 | Query stdout is assigned by command substitution, stderr/stdin are not redirected there; ordered cflags/libs and LF-based accumulation are required meanings. No mandatory two-stream collector follows. |
| X02 | [_gsclib.scm](../../../vendor/gambit/gsc/_gsclib.scm):365-393,544-593; [process.scm](../../../vendor/gambit/lib/gambit/process/process.scm):76-146 | Ordinary native build inherits stdio, resets TTY and supplies cwd; generic capture helper instead reads strings and redirects both outputs. One helper cannot be substituted without its policy audit. |
| X03 | [_io.scm](../../../vendor/gambit/lib/_io.scm):6184-6271,7098-7197 | Byte-vector reads already exist, require empty character-buffer state and distinguish buffered/partial/error paths. Process settings independently select redirection. Native binary byte support is not absent from Scheme; primitive availability is not full adapter admission. |
| X04 | [os_io.c](../../../vendor/gambit/lib/os_io.c):3519-3561,8501-8562,9127-9345,9547-9562 | Existing cleanup/status/reaper support, shared redirected fd for stdout/stderr when selected and launch-error pipe. Wait-any-child hazard is conditional; captured generic streams need not have separate observable ordering. |
| X05 | [_thread.scm](../../../vendor/gambit/lib/_thread.scm):4794-4819,8302-8327 | Both inspected dynamic-wind definitions capture continuation, bind dynamic-wind state and invoke before/after. This is a control mechanism, not an affine job/resource ownership guarantee. Selected configured branch remains an admission question. |
| X06 | [_kernel.scm](../../../vendor/gambit/lib/_kernel.scm):4505-4524; [c_intf.c](../../../vendor/gambit/lib/c_intf.c):1683-1710 | I/O select writes back/reloads registers/RA; foreign release clears fields before invoking the release callback and can return error. Existing runtime boundary/irreversible effects remain, not replaced by no-GC syntax. |
| X07 | [mem.c](../../../vendor/gambit/lib/mem.c):6667-6755 | Configured non-single-threaded VM collector path uses processor count, local scanning and work stealing. Do not describe Gambit as having no parallel collector machinery, or infer qualified installed multicore behavior from this branch. |
| X08 | [_back.scm](../../../vendor/gambit/gsc/_back.scm):17-145; [RFD contract](return-frame-planner-case.md):sections 2-4 | Parameterized target architecture and concrete root/layout extraction are current assets/design duties. Modernization preserves logical negotiation; source snapshot is not implemented G3 export. |
| X09 | [NJS parent](native-job-service-design.md):sections 2-7; [shared runtime evidence](gvm-shared-runtime-evidence.md) | SA/NJR/caller boundaries and runtime compatibility are prior research premises. They are not a new whole-source census, native qualification or measured cost. |

RS/CA/MG/FT rows are project deductions linked to these sources and primary
mechanisms. The bounded reads do not establish all process users, configured
flags, legacy input domains, copied-byte counts or deletion denominators.

## 2. Primary Reuse Mechanisms

Upstream notes are reading identities, not downloaded/pinned bytes or installed
compatible cohorts. Published examples/tests were not executed.

**P01.** [Zig 0.15.1 Child.zig](https://raw.githubusercontent.com/ziglang/zig/0.15.1/lib/std/process/Child.zig),
spawn/wait/collectOutput/run: reusable stdio/process primitives exist, collection
and termination differ, and convenience run uses piped outputs/ignored stdin.
Its output handoffs occur before final wait. The inference is to audit/guard
partial transfer and choose the proper I/O policy, not infer a reproduced leak,
automatic ownership or an admitted wrapper from this source reading.

**P02.** [libuv streams](https://docs.libuv.org/en/v1.x/stream.html), read callbacks,
distinguishes data, zero read and EOF/error; callers own supplied byte buffers
and stop/close policy. [Handles](https://docs.libuv.org/en/v1.x/handle.html),
allocation/close callbacks, requires user-provided read storage and deferred
handle-memory release through close completion. An allocation callback cannot
close/stop its handle. Our design separates storage and stable owner lifetime
instead of treating libuv as an owned-output container.

**P03.** [libuv process](https://docs.libuv.org/en/v1.x/process.html), options,
spawn/close, supplies stdio/env/cwd and terminal callbacks, with cleanup duties
on failure and premature Unix close. A serious C reuse control is therefore
concrete; dependency/event-loop integration and supported capability costs stay.

**P04.** [Zig 0.15.1 language reference](https://ziglang.org/documentation/0.15.1/),
defer/error handling, supplies local cleanup/propagation constructs. Our
controller/async close/delivery laws are additional project work, not automatic
type/affine ownership. The prior NJS ledger binds concrete library upgrade scope.

**P05.** [Bash command substitution](https://www.gnu.org/s/bash/manual/html_node/Command-Substitution.html)
documents stdout substitution with trailing newlines removed. This supports
separating raw capture from legacy interpretation. It does not identify the
installed Darwin shell/version or qualify NUL/locale/flag behavior. POSIX page
fetches were denied/unavailable and supply no additional platform observation.

## 3. OCaml as a Cross-Layer Modernization Comparison

**O01.** [Retrofitting Parallelism onto OCaml, ICFP 2020](https://kcsrk.info/papers/retro-parallel_icfp_20.pdf),
sections 1.1-1.4 and 4.4: unified-runtime maintenance, sequential semantic/cost
objectives and C API/collector coupling constrain the design. The paper compares
minor-collector alternatives rather than treating maximum concurrency as an
automatic win. Our lesson is to state cross-layer requirements and evaluate
tradeoffs. No historical result, development duration or speed ratio is copied
onto Gambit; the paper is not the entire current OCaml specification.

**O02.** [OCaml 5.3 parallelism manual](https://ocaml.org/manual/5.3/parallelism.html),
sections 3-4, describes domain-local minor allocation, parallel stop-the-world
minor collection, concurrent major collection and DRF-SC memory reasoning.
MG03/MG04 distinguish actual runtime choices from a native service boundary.
These are OCaml guarantees, not inherited Gambit or Zig guarantees.

**O03.** [OCaml 5.3 C interface](https://ocaml.org/manual/5.3/intfc.html),
section 12 runtime access and callbacks, specifies release/acquire obligations
and data/callback restrictions while released; transitions may execute pending
callbacks. The design inference is explicit blocking/root/control gateways.
Do not equate those APIs with Gambit primitives or conclude every rule first
appeared in OCaml 5.

## 4. Evidence and Quantification Limits

BS1's L and sum-of-active-limits are proposed capacity bounds, not observed
query lengths/RSS or proof all legacy inputs fit. Byte quotas do not bound time.
RS rows are residual responsibilities, not independent helper implementations.
CA owners are disjoint work accounts, not hours or an adoption score. MG criteria
define capability/semantic/resource/evolution acceptance, with economic language
choice assessed separately. No criterion receives a native/theory witness.

The retained first-compile, provider, E01-E32 and L1/L2/ES/DTrace evidence gaps
are not closed by these records. No existing path/support is actually retired,
no currently installed collector/worker cohort is qualified, and the positive
same-capability Zig net-cost bound remains unresolved after both C/S reuse.
