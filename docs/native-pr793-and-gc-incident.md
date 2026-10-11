# PR793 Candidate And GC Incident

## Diagnostic 010 Feedback

The exact observer delta from candidate 009 adds fail-stop raw-header checks at
scan entry, worklist enqueue/dequeue and in-situ rehash entry. It changes no
Scheme source, does not skip any failing operation and is not a repair. The
current core rebuild exits 0 with GNU GCC 16.2.0, recompiling `mem.o` and
relinking the library, interpreter and compiler. No full bootstrap was run.

| Attempt | Interpreter | Compiler | Compiled fixture | Admission |
| --- | --- | --- | --- | --- |
| 010 first | 1.398 s, exit 0 | 5.466 s, exit 0 | 0.859 s, exit 0 | Scoped diagnostic pass |
| 010 repeat 1 | 0.256 s, exit 0 | 3.631 s, SIGBUS (-10) | Not run | DENY |

No observer denial message preceded the compiler SIGBUS. Do not claim the
probes exclude a size/layout mismatch, invalid payload or corruption elsewhere.
The observed failure is different from 009: `mark_array +96`, called from
`scan +204`. Current binary disassembly places the fault at the object-header
load after extracting an allocated Scheme reference from a scanned cell.
The reference register is `0x6500000075`; masking its tag produces the reported
fault address `0x6500000070`. The scan return location is shared by closure and
the movable vector-like default paths; it does not establish the original
header subtype or where the malformed reference originated.

This incident is bound to both the selected image UUID and compiler child PID
68621 through the actual failed native receipt. The normalizer now requires
that receipt, exact toolchain identity and a non-timeout signaled compiler exit
for child attribution; a manually supplied PID alone is insufficient. Portable
evidence is `evidence/model-results/native-gc-incident-010-child-bound.json`.
Current source/artifact inventory remains unchanged after both runs. No more
unchanged diagnostic retries followed this failure.

QNT now separates allocation-extent and payload-layout correspondence from
header representation and lifetime. Both new controls are injected obligations,
not conclusions about either incident's root cause. A normal-looking header
check is insufficient implementation evidence. Next source work must trace
copy/scan cursor conservation, variable object extents, scan ownership and
generated-source/object correspondence before trying a repair.

Current model attempt 004 freezes all four independent controls. Positive TLC
exhausts 9 distinct / 13 generated / 0 queued states in 15.703 seconds. Attempt
003 failed because the sandbox denied Apalache's local checker socket; its
receipt remains DENY. The repeated infrastructure failure motivated the shared
runner's fail-fast admission rule, covered by a test that proves no second model
or native child launches. Current framework suite passes 62 tests.

The source audit also checks the ordinary stale-header explanation: Makefiles
declare `include/gambit.h` dependencies for runtime/compiler objects, and the
inspected `_system`, `_kernel`, `_thread`, `_front`, `_back` and `_gsc` objects
postdate the current header. This timestamp evidence does not establish full
ABI/generated-source parity, but provides no basis for an unchanged rebuild
on that explanation alone.

## Source Unit And Incremental Build

The shared `source_unit.py --case shutdown_error_handoff` extracts the actual
`execute_sync_op_loop` body. Three variants (unchanged, exact PR793 condition,
catcher-only injected condition) each execute eight deterministic scenarios.
All 24 outcomes match expectations using GNU GCC 16.2.0: normal delivery,
cleanup, conditional pre-cleanup gap, no error, processor 1, existing first-pass
state, another operation and two errors retaining the first. Barriers and
nonlocal throws are mocked; the baseline NULL-catcher attempt is recorded,
not deliberately crashed. This is not a native shutdown reproduction.

The first extractor attempt rejected a forward declaration and definition with
the same name; it is DENY, with no compile/test. The second uses the exact
definition signature and passes. Current runtime `setup.c` receives only the
PR793 condition. The candidate patch remains under `patches/candidates/`.

Clean-environment `make -j12 core` exits 0, compiling `setup.o` and relinking
`libgambit.a`, `gsi` and `gsc` with GNU GCC 16.2.0. This is incremental core,
not full threaded bootstrap. `runtime_identity.py` verifies that reversing the
one condition yields both the admitted source-unit input and the prior recorded
setup source, unchanged prior listed sources, and the tested candidate function.
It inventories current C/SCM/headers/Makefiles plus selected binary hashes. This
does not prove complete generated-source or compiled-object parity. The PR793
guard is not the QNT positive seal/drain design.

## Actual p4 Native Results

Existing exact-model receipts were checked and reused, not rerun. The decoder
fixture uses mixed key types, text/binary round trips and forced GC. Its existing
source guards and candidate identity remain required.

| Attempt | Interpreter | Compiler | Compiled fixture | Admission |
| --- | --- | --- | --- | --- |
| 009 first | 1.400 s, exit 0 | 6.141 s, exit 0 | 0.777 s, exit 0 | This scoped run passed |
| 009 repeat 1 | 0.483 s, exit 0 | 3.649 s, SIGBUS (-10) | Not run | DENY |

No p1/p2 or additional p4 retry followed the failure. The current input and
artifact inventory remains unchanged after both runs. A single successful
compile does not establish stability, causal repair or performance improvement.
The selected candidate remains denied for complete compiler/runtime acceptance.
The correctness guard is retained as a candidate, not an official patch-chain
promotion. These runs do not replace full bootstrap or package suites.

## Uninstrumented macOS Incident

The newly observed incident is `EXC_BAD_ACCESS / SIGBUS`, with faulting frame
`gc_hash_table_rehash_in_situ +48`, then `___garbage_collect_pstate` and
`service_sync_op`. Another thread is in the same rehash function, but its table
base register differs; this is not evidence of two workers rehashing one table.
The image UUID matches current candidate gsc:
`c0dc0df5-e380-3ce5-ac48-686e3c8b73b6`.

At +48, current-binary disassembly is `ldr x1, [x0, w2, sxtw #3]`.
The reported base plus eight times the signed index equals the fault address.
The preceding code derives the word count from `body[-1]` and starts the
uniform-key scan from the last key. The fault is therefore an indexed key-slot
read, not an observed NULL-catcher throw. The recorded word count is 14,686,624.
The actual allocation extent and original header's low type bits are absent:
do not assert a forwarding header, early free, duplicate worklist or upstream
bug cause solely from those registers.

The original runner did not record its child PID. The incident is bound to the
candidate binary image, not uniquely to this run's child PID. New native receipts
now record child PID and UTC start/end for interpreter, compiler and compiled
fixture; the incident normalizer rejects an explicitly mismatched PID. It uses
a strict multi-JSON parser and a whitelist that excludes paths, machine/user
identifiers and unrelated metadata. No raw private incident is committed.

## Model Feedback And Next Gate

The original `gc_table_header_lifetime` version adds special-reader/worklist representation and
retirement obligation omitted by the prior key/layout-only rehash model. It
independently injects a stale forwarding header and retirement during reading.
These are hypothetical controls, not established causes of the native crash.
Its positive canonical worklist/lifetime contract is not a source patch or a
proposal to mask corruption with a bounds check.

The first model check's negatives were DENY because the strict decoder did not
support zero-based finite-function rendering, although TLC produced invariant
violations. The second uses one-based symbolic object IDs, preserving the same
protocol, with all outcomes checked anew. Source work must now inspect scan
ownership, worklist registration, header representation across GC phases,
reclamation, and compiled/source ABI correspondence before another failed
compiler route is attempted. No claim of whole-runtime green is made.

The historical second model run exhausts 9 distinct states, 13 generated, zero queue in
17.686 seconds. Two actual fault-control traces are frozen and digest-bound.
This small lifetime contract is not a model of the real 14,686,624-word allocation
or proof of an in-situ rehash implementation; those native/source obligations
remain open.
