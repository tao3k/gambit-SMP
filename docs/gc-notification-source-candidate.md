# GC Notification Source Candidate

## Route Review

The combined notification/recheck route is distinct from known rejected
signal-only, recheck-only and inverted Q-to-M lock order variants. Existing
Quint evidence supports investigating the combined protocol; it does not prove
C source refinement or runtime correctness. Expected benefit is preventing a
lost notification and premature idle registration, not a measured speedup.

## Reproducible Source

Candidate 029 uses `evidence/runtime-source-029.lock.json`, the fixed Gambit
submodule and a versioned snapshot overlay. It never requires the old runtime
cache. Relative to the original 026 slice, only these changes are made:

- After releasing its FIFO lock, the publisher locks M, signals and unlocks M.
- Before decrementing the active count, the waiter holds M and checks each
  actual processor queue under that queue's lock. On pending work it releases
  M and returns to the original scan/steal path without changing the count.
- `lib/mem.h` declares the existing candidate `___glo_list_add` return type
  as `___SCMOBJ`, matching its implementation and checked callers.

No payload scan, allocation, publication or callback occurs while the waiter
holds M. The original count decrement, termination broadcast, condition wait
and count restoration remain unchanged. A structural delta test checks this
scope; it does not prove memory visibility, scheduling fairness or GC progress.

The earlier five-file 028 snapshot is deliberately retained. Its full mem.c
compilation failed because the inherited header still declared `void`. The
026 five-file correspondence remains a valid audited slice, not a configured
toolchain claim. Supporting the sixth header input changed the provisioner's
hash: all eight original 026 synchronization controls were actually replayed
into `sync-retirement-submodule-005.json`; the older receipts were not rewritten.

## Compilation Evidence

Reproduce the object check with:

```sh
uv run --locked python -m gambit_smp.locked_object \
  --source-lock evidence/runtime-source-029.lock.json \
  --gcc "$GNU_CC" --out "$LOCAL_BUILD_DIR/notification-object"
```

The runner regenerates configure from the locked configure.ac, enables SMP,
multiple VMs and multiple-threaded VMs, then obtains the actual makefile mem.o
recipe. Although configure requested O1, the effective mem.o recipe uses O3
and `-ftrack-macro-expansion=0`. Report the effective recipe, not the requested
option, as the compilation flags. This is not performance acceptance.
Configure has a 90-second cap and compilation a
90-second cap; neither was expanded.

Observed GNU GCC 16.2.0: configure 38.277 seconds, full mem.c object 0.997
seconds, both exit zero. Receipt:
`evidence/model-results/gc-notification-object-029.json`.
The negative 028 header result remains in
`evidence/model-results/gc-notification-object-028-header-deny.json`.

Two initial configure attempts failed before reaching mem.c. The new runner
had restored the ambient PATH, selecting Nix assembler/linker tools and causing
undefined stdio symbols. Keeping the established GCC runner's controlled PATH
fixed the link probe without changing SDK, headers or configure outcomes.
`gnu_stdio_probe.c` independently compiles and runs with that controlled PATH;
the ambient-PATH and alternative-SDK attempts both failed. These are harness
environment diagnostics, not Gambit GC failures.

The historical object receipt does not bind raw log hashes or the effective
argv/tool search order. Those logs remain local diagnostic artifacts, not
portable public evidence. The recorded object result must not be promoted to
an admitted native receipt; subsequent runners need that richer binding.

The later `uv run --locked` synchronization replay invocation was rejected
because concurrent dependency edits made uv.lock inconsistent. The eight
controls were run using the already prepared `.venv/bin/python`, without
altering those edits. This does not establish current locked dependency setup.

## Remaining Acceptance

### Preserving The Earlier Candidate Composition

Candidate 029 is intentionally only a six-file source slice. Auditing the
earlier candidate 026 inventory against the pinned submodule identified missing
authoritative inputs; transplanting its old binary would hide those differences.
Candidate 031 instead publishes an eleven-file overlay in
`patches/snapshots/candidate031-composed-source.patch`, locked by
`evidence/runtime-source-031.lock.json`. The exporter proves the overlay restores
every declared file's exact bytes from the committed base before publishing.

| Additional preserved input | Corresponding contract |
| --- | --- |
| `lib/_system.scm` | Decoder pre-publication rehash, rooted iteration and serialization snapshots; `table_decode`, `gc_table_iteration`, `gc_table_serialization` |
| `lib/_io.scm` | Shared endpoint predicate mutex; `pipe_wait` and `pipe_close_wait` |
| `gsc/_prims.scm` | Explicit increment delta type guard; `vector_increment_guard` |
| `include/gambit.h.in` | Checked-negation return repair moved from generated header into the template; `checked_negate_return` |
| `lib/c_intf.c` | Root save before allocating a stack marker and restore afterward; `root_marker` |
| `lib/os_io.c` | Existing Darwin-only posix_spawn route, preserved rather than dropped |

The audit compared 133 earlier source inventory entries. One unrelated
diagnostic header, `include/gambit-not409008.h`, has no committed base and is not
transplanted. Generated C/configuration/installed headers are not restoration
inputs. The one-time extraction verified earlier source hashes; future
reproduction requires only the pinned submodule and the new overlay, not that
earlier cache checkout. These contracts describe the retained deltas, not proof
that their whole GC/VM/lifecycle composition has passed.

Candidate 030's nine-file intermediate omitted the last two C inputs. Its
native audit also rejected exporter implementation drift during the build.
That parent failure remains a DENY, not a GC failure or reusable build pass.
The common adapter now preserves such context-exit failures in a DENY receipt
instead of exiting with only a traceback. Candidate 031 requires its own
stable-context source build and native checks; earlier positive results do not
automatically transfer.

### Seed And Source Regeneration Boundary

The shared `locked_object` adapter now has an explicit diagnostic seed target.
Generated Scheme C optimization and handwritten RTS optimization are separate
configure options; changing the former alone leaves RTS at its default highest
level. The diagnostic control requests both explicitly, without altering any
GC/VM configuration or raising a previously failed bootstrap budget:

```sh
.venv/bin/python -m gambit_smp.locked_object \
  --source-lock evidence/runtime-source-029.lock.json --gcc "$GNU_CC" \
  --target seed-core --c-opt 0 --rts-opt 0 --build-budget 120 \
  --out "$LOCAL_BUILD_DIR/source029-seed"
```

An actual local GNU GCC 16.2.0 run configured in 35.700 seconds and compiled and
linked the initial core in 14.573 seconds. Twelve jobs were selected by the host
capacity query, not a fixture constant. The effective makefile attested `-O0`
for both categories. This is a low-optimization correctness control, not a
production performance result. Its seed binaries may contain the committed
pre-generated Scheme C, so `scmRegenerationEstablished` is explicitly false.

The actual new seed compiler then regenerated `lib/_thread.scm` with host-auto
processors in 6.052 seconds, within its unchanged 30-second cap. The command
was derived from the configured makefile but replaced dummy `gsc-boot` with
the SHA-bound seed `gsc/gsc`; it wrote a fresh separate `_thread.c` output.
This establishes one SCM-to-C invocation, not linked SCM parity or full GC.
The shared adapter also offers `rebuild_source_core`: it copies the exact seed
to `gsc-boot`, runs `bootclean`, requires every selected generated C file to be
absent, and checks their restoration plus source stability, linked artifacts
and recursive make errors after `core`. A zero make exit or leftover generated
C cannot qualify. One regenerated core is not the complete two-pass bootstrap.

Add `--regenerate-source` to the seed command to execute both stages through the
same public adapter. The configured build budget applies separately to the seed
core and the source-regeneration campaign; the latter shares its budget between
cleanup and rebuilding. An actual local campaign deleted and regenerated 46
selected Scheme C files, restored and relinked all three artifacts, and reported
stable Scheme inputs. Cleanup took 1.675 seconds and core regeneration/rebuild
took 104.482 seconds, within the campaign's 120-second budget. No recursive make
errors or missing generated files were accepted. A late one-second process
sampling attempt found the compiler had already exited, so no stack observation
is claimed.

The resulting runtime passed the existing real-payload `table_gc.scm` diagnostic
in interpreted and compiled modes. Both selected and checked all 12 host-auto
processors. Interpreted execution took 0.057 seconds; native compilation took
3.151 seconds and compiled execution 0.554 seconds. Each mode exercised ten
forced GC cycles for each of `eq?`, `eqv?`, and `equal?`, checking seven live
keys after every cycle. These are 30 forced cycles and 210 lookup assertions per
mode, not arbitrary recursive graphs or the whole native suite. The initial
diagnostic harness rejected `CHILD-PROCESSORS:12` because it used the separate
inline-suite `PROCESSORS:` checker. That DENY is retained; the corrected exact
fixture protocol was checked with unchanged runtime, fixture and budgets.

All these observations keep runtime/release admission false. The source lock
still represents the six audited deltas; it does not silently adopt other
earlier `_system.scm` or compiler repairs from an old cache checkout. Those
repairs need their own reproducible composition before whole-candidate claims.

Real multiple-publisher/waiter schedules, repeated condition returns, phase
composition, full linked GC, VM resize/shutdown, bootstrap and Gerbil full tests
remain open. The unbounded wake counterexamples still require an explicit
scheduler assumption; this C candidate does not implement copier fairness.
Runtime and release admission remain false. Do not retry unchanged 028 or the
already timed-out native pipelines solely because this object compiles.

## Source031 Regenerated Core Identity

The eleven-file composed candidate completed a local GNU GCC source-core
campaign with both Scheme C and runtime optimization explicitly set to `-O0`.
Configuration took 35.498 seconds, seed core 14.496 seconds, cleanup 2.180
seconds and source regeneration/rebuild 100.185 seconds. The regeneration
campaign retained its shared 120-second budget. This is a correctness control,
not a production-performance result or a completed two-pass bootstrap.

The generic `runtime_identity --source-build` adapter now verifies the producer
input hashes, source lock and overlay, selected source files, Scheme and
generated-C inventories, generated header, configured makefile and final
linked artifacts. It uses `sourceRegeneration.artifacts`, not the historical
top-level seed artifact hashes. It requires all successful build stages and
all three concurrency configure flags. It transfers no model admission.

The final linked hashes are:

| Artifact | SHA-256 |
| --- | --- |
| `gsi/gsi` | `7d6623d4ba70da0163ae119943188f21ac15cc4c4187156b835b0b95f63b8811` |
| `gsc/gsc` | `ecba3de5f8d9f54e541df9622371ad56bf901dde34990e78b89b4382876fad74` |
| `lib/libgambit.a` | `10b5deed48fa6afb247b69edd34ae589aaee5d572568084525f34e794cf1bc3f` |

Native suite execution has not been admitted for this candidate. The retry
preflight found overlapping historical aggregate failure scopes and returned
`REVIEW_REQUIRED` before executing the selected GC/pipe/interrupt fixtures.
A preceding combined-selection preflight also exposed a missing historical
object-cache helper. The audit now records that helper as an unbound identity
instead of crashing or ignoring the missing dependency. Neither observation
is a native test pass or a new runtime failure.

The focused runtime identity, native Datalog audit, retry gate and Reflection
regression suite passed 40 tests in 10.369 seconds. This validates the adapters
and rejection behavior, not full GC, native SMP or Gerbil correctness.
