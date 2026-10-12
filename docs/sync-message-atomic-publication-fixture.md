# Sync Message Atomic Publication Fixture

## Review Before Repair

The retained-sync, acquire/publication, retirement-round and result/startup models
already identify publication and drain requirements. The source has sender mutex
protection and fences, but its spinning receiver reads a volatile integer without
holding that mutex. The prior native result/startup harness used atomic field
substitutes. That establishes control flow under a stronger field contract, not
the original flag access protocol. This fixture removes that substitute.

This is a GNU compiler memory-access correctness change, not a Darwin-only speed
optimization. Expected end-to-end performance benefit is unmeasured. The existing
locks, signals and fences remain; no performance claim or full SMP admission is
made. Caches and numbered source directories are not authoritative inputs.

## Source Protocol

The original `___VOLATILE int` field declarations and ABI are unchanged. All sync
flag accesses in the setup protocol now use GNU atomics: acquire loads in both
polling paths, relaxed stores for reset/initialization, release stores to publish
the message. `SYNC_GET_MSG` takes explicit destination and flag arguments so that
the atomic load operates on the real flag address, not on an assignment result.

The matching release/acquire handoff orders payload publication before the
receiver consumes the payload. Clearing a flag does not grant the next payload
writer permission to overwrite it: the reverse-direction next tree round must
still establish consumption. Sender unlock/signal tails and VM admission/drain
remain separate resource-lifetime obligations.

The [GNU atomic builtins documentation](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html)
describes the load/store orders and their release/acquire relationship. It also
requires a data-race-free program; making these flags atomic does not qualify
every other shared Gambit field. This fixture targets the GNU toolchain already
required by the selected source. Other compiler configurations are not admitted.

## Model and Native Binding

`sync_atomic_round_publication.qnt` explores two payload rounds with explicit
acknowledgement, safe reuse and temporal progress. Four controls cover non-atomic
flag access, missing release, missing acquire and reset-only payload reuse.
The memory-order behavior is an abstract primitive contract, not an executable
formal proof of the compiler or the complete C memory model.

The native harness projects the original header's exact flag/payload declarations,
complete sync tree, dispatcher, outer loop and startup function. Actual pthreads
run the candidate without replacing sync flags with `_Atomic` declarations.
GNU load/store instrumentation still executes the real builtin. Its variable
memory-order argument may compile as the stronger sequentially consistent order;
the configured full source object uses the production constant orders directly.
This distinction prevents stress observations from becoming a weak-memory proof.

Checks cover stable membership, setup failure, growth/startup, successful shrink,
1,000 stable rounds and 1,000 alternating success/error rounds. Every non-P0
request result is checked, not just the final value. A single-thread atomic-access
probe expects one load and two stores; the unchanged parent fails that contract
with zero atomic accesses. The parent is not run concurrently with volatile flags.
That negative control verifies source access selection, not a hardware race.

The full GNU GCC object recipe includes memory, mutex-backed memory, setup and
thread objects with SMP, multiple VMs and multiple threaded VMs enabled. Object
compilation is not a linked runtime, bootstrap or Gerbil performance test.

The linked seed campaign passed in 91.850 seconds overall; its `make -j12 core`
stage took 29.007 seconds. The worker count was selected from the host CPU
capacity, not a fixed recipe constant. Portable evidence binds the linked gsi,
gsc and library hashes. This seed retains pre-generated Scheme C, so source
Scheme regeneration and complete bootstrap remain unestablished.

A separate same-campaign module check subsequently regenerated the actual
locked `_system.scm` in 17.029 seconds (85.020 seconds overall), with stable
source/compiler inputs and a bound generated-C hash. This closes the one-module
regeneration check, not complete source regeneration: the output is not linked
and no full GC, bootstrap or Gerbil result is inferred.

The later source-core campaign regenerated all 46 inventoried Scheme C modules
and relinked gsi, gsc and the library. It passed in 182.110 seconds overall;
the source-core make stage took 117.701 seconds. Scheme inputs stayed unchanged,
all generated outputs were present, and recursive build errors were absent.
This establishes full inventoried source regeneration and one core relink, not
the two-pass bootstrap, complete native suite or Gerbil acceptance.

## Evidence and Remaining Requirements

Source authority is the pinned submodule and
`evidence/fixtures/sync-message-atomic-publication/source.lock.json` plus its
cumulative overlay. Only setup changes relative to the parent Fixture. The
generic recipes and portable observation bind source/model/native identities.

Initial model publication lacked the comparison model snapshots because their
dependencies were declared at the wrong manifest level. The corrected campaign
uses verified same-model result reuse, snapshots both dependencies and publishes
the final portable receipt; no unchanged TLC jobs were repeated. The original
check and publication failure are not reclassified as algorithm failures.

This does not repair ignored join errors, permanent join failure, complete VM
quarantine/cleanup, payload GC, strong/weak phase composition, foreign callback
reentry, complete source-regenerated runtime, bootstrap or Gerbil acceptance.
Those Reflection requirements remain open. No timeout or assertion was relaxed.
