# Header Consumer Dependencies

## Confirmed Build Gap

Both upstream `gsi/makefile.in` and `gsc/makefile.in` attach the configured
`gambit.h` prerequisite to `MODULES_O`, which is not defined there. Their real
object inventories are `LIBRARY_OBJECTS` and `EXECUTABLE_OBJECTS`.

This matters for the startup acknowledgement repair because its processor/VM
fields and global API change C layouts. Reusing old Scheme-generated C objects
without recompiling against the new header does not qualify an ABI-coherent
runtime. It is not yet proven that this gap is the sole cause of exit 71.

## Actual Controls and Repair

GNU make dry-run controls use `-W ../include/gambit.h` without touching the
header or rebuilding the control runtime. For `_gsi.o`, `_gsilib.o`, `_gsc.o`
and `_front.o`, old rules schedule no C compilation; repaired rules schedule
compilation for every object. All eight commands exit zero.

The fix attaches the header to both complete object lists, including linker
objects and normal C objects. It is platform-independent build correctness,
not a Darwin-only performance intervention. No Python framework files change.

The semantic fixture `header-consumer-dependencies` inherits the startup-return
outcome repair. Its 16-file cumulative overlay and source lock bind to the
pinned submodule and pass apply-check. The executable dependency controls are
in `evidence/source-results/fixtures/header-consumer-dependencies/dependency-controls.json`.
Reflection references these hashes as source evidence, not protocol acceptance.

## Admission Boundary

Dry-run scheduling is not a completed compilation, and dependency repair is
not a GC repair. A successful complete consumer build and actual processor
startup are required before reuse/GC results can qualify this candidate.
The earlier all-consumer build exceeded the unchanged 180-second budget and
remains DENY. Full bootstrap, native suites and Gerbil correctness remain open.
