# VM Registry Reader Lease Candidate

## Identity And Boundary

This is an unadmitted source candidate, not an SMP completion or a release
patch. It preserves the existing 20-file overlay on the pinned Gambit submodule
revision `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882` and changes `lib/setup.c`,
`lib/mem.c` and `lib/mem.h` for registry lifetime. Reproduce through
`evidence/fixtures/vm-registry-reader-lease/unsigned-source.lock.json`
(SHA-256 `f403f5f2fc889c6122b8a210a35a7caee0199acd2cab85f404ffa91ddf4cf938`)
and `patches/fixtures/vm-registry-reader-lease-unsigned.patch`
(SHA-256 `0a3f651043fc978e8a58fdde01e1cc3a0af78ed4e66bfa09fff0866d4bcbf1a7`).
Local output directories are not source authority.

## Protocol

The word combines closed admission, a terminal shutdown seal and reader count.
Signal readers register with CAS before capturing registry pointers. Writers
close admission and drain registered readers before mutation/resource cleanup.
Closed signal paths coalesce interrupt bits without waiting for the registry
mutex; replay obtains a fresh reader lease and the post-record recheck prevents
late mailbox publication from being stranded by an earlier writer flush.

Global teardown sets the terminal bit before P0 cleanup, and retains it on
failed joins. An ordinary writer cannot reopen a terminal generation. Public VM
cleanup acquires the writer mutex; the global cleanup loop calls a locked helper
to avoid double locking and unlocks the mutex before destroying it. Constructor
publication rejects a terminal registry. VM execution and GC are not serialized.

This prototype deliberately requires the GNU native-word-atomic backend for
multiple VMs; it does not silently fall back to a potentially locking emulated
signal-path primitive. Unsupported targets are not release-qualified. Global
setup/teardown still requires exclusive lifecycle ownership and quiesced private
constructors; this is not a new concurrent-global-reinitialization API.

## Actual Validation

The existing sealed Framework Only object recipe passed in **63.592 seconds**
under its original **300-second** budget, with stable inputs. Every observed
child exited zero without timeout. `research --read` returned `CURRENT`, with
both runtime and source-refinement admission false. GNU configure retained
`--enable-smp`, `--enable-multiple-vms` and
`--enable-multiple-threaded-vms`, with C/RTS `-O0` for correctness qualification.
Configure took 30.725 seconds; real `setup.c` and `mem.c` compilation took
0.222 and 0.238 seconds. These are object diagnostics, not package timings.

The same recipe retained actual negative controls for split admission, unleased
replay and writer reopening after terminal shutdown. Repeated retirement has
255 distinct / 627 generated states; terminal shutdown has 36 / 68. Queues
exhausted for positive safety checks. The separate terminal `noStall` check
passed; this is finite deadlock evidence, not unbounded fairness. The canonical
case, raw-log attestation, model snapshot and counterexample traces are durable.
Native ASCENT catalog validation passed with 15 finite model admissions.

Actual Mach-O arm64 object inspection showed `casal` for admission and
`ldaddal` for reader release. Undefined-symbol inspection found no external
atomic/sync/outlined-AArch64 helper. This establishes this object's backend,
not general signal safety or nonblocking behavior of every interrupt callback.
The device-select abort path uses a pipe write whose descriptors are configured
nonblocking, but processor-resource lifetime and error paths still need native
composition coverage.

Thirty-one focused recovery, model projection, catalog, native-DSL Grid and
executable-adapter tests passed in 7.943 seconds under 15 seconds, with no skips.
The earlier 975-test frozen graph qualification does not qualify these later
source/model/catalog inputs as current.

## Retained Failures And Open Requirements

The first seal omitted explicit Quint/Node identity and failed before steps.
The attempted prior-tool correspondence was then rejected because that failed
run had no prior tool observation. Both failures remain intact; neither is a
native runtime failure. The corrected seal pins the complete tools and uses
the same recipe budgets. No known failed native suite was retried unchanged.

Source review also rejected a signed-word overflow expression: Gambit's
`___WORD` is signed. The initial snapshot is retained separately as
`source.lock.json` / `vm-registry-reader-lease.patch`, not selected by the object
recipe. The selected candidate uses `___UWORD`; no test pass is attributed to
the rejected expression.

Remaining gates before promotion:

- Model and test saturation/overflow deferral progress: a reader rejected at
  counter capacity currently relies on a future flush, unlike writer closure.
- Prove or repair processor-resource ownership across direct VM interrupts,
  shrink, failed joins and private constructor/global shutdown overlap.
- Audit embedding callers that formerly held the registry mutex around public
  cleanup; changed locking ownership must not introduce recursive deadlock.
- Bind physical C publication/reclamation order and repeated setup epochs to
  the exact source, rather than treating the finite models as C refinement.
- Build a linked, fully source-regenerated candidate and both complete bootstrap
  passes, then run exact full gsi/gsc, PR/stress, real multiple-VM, GC/FFI,
  lifecycle-fault, Gerbil and release-performance gates.

No object or finite-model result discharges these requirements. The current
recipe is an intermediate source validation, not the final milestone verdict.
