# Owned Processor Log Rollback Fixture

## Repair Boundary

`candidate-pstate-log-owned-rollback.patch` extends the checked processor failure
helper only when `os_mem_ready` is true. The memory callee has then returned
success, including successful processor-log initialization. Existing OS/memory
cleanup completes before `___cleanup_actlog_pstate` frees the owned log buffers.
If log allocation fails, the callee has already released its temporary buffer;
the outer failure helper does not enter this branch. Borrowed VM0 interrupts
retain their separate outer ownership.

The immutable Fixture overlay includes the preceding reviewed changes, checked
processor rollback, owned log release and isolated VM log abort helper.
It modifies thirteen locked files over the pinned submodule. Git patch
application checking passes. Normal cleanup/dump is not changed by this repair.

The VM constructor still publishes count before P0 readiness, and global cleanup
can revisit an already-unwound processor. VM-memory/list-resource rollback and
normal dump readiness remain unclosed. This candidate is not eligible for a
whole-runtime acceptance claim until those source obligations are repaired.

## Materialization Failures

The legacy materializer rejected the source lock because its explicit file
whitelist excludes activity-log files, before patch application. Its separate
retrospective DENY record preserves the observed parent exit 1 and does not
fabricate a producer receipt.

The typed Recipe attempt also returned DENY, parent exit 2, with stable inputs.
Its revision subprocess actually exited 0 and printed the expected revision.
The preceding Darwin `confstr()` warning was included in the returned command
text and caused a false `source revision drift` rejection. The exact portable
output is retained in the research assets. This is an execution-interface
output-channel defect, not an upstream revision change or native runtime bug.
No archive, patch or compiler stage ran in that attempt. Do not repeat it with
unchanged executor/input; keep the failure and require a changed typed interface
which preserves stderr while parsing stdout independently.

## Model Binding

`processor-log-contract.json` binds this exact source lock and overlay to
the imported processor/log rollback composition. Earlier numbered proof material
is historical, not transferred to this Fixture. A current model check remains only
an abstract ownership contract, not semantic C refinement, object compilation,
GC/lifecycle, bootstrap or Gerbil acceptance.

## Fixture Identity

Canonical source lock:
`evidence/fixtures/pstate-log-owned-rollback/source.lock.json`.
Canonical overlay: `patches/fixtures/pstate-log-owned-rollback.patch`.
Both bind the pinned `vendor/gambit` submodule.

Fixture names describe the protocol or failure condition, never an experiment
sequence number. Future changes retain this semantic identity; revision and
content hashes distinguish inputs. Original numbered receipts remain immutable
historical evidence, not active source identities.

Active Fixture directory names, overlay names and Recipe identifiers contain no
sequence numbers. Tests enforce this across every registered Fixture directory,
its model context inputs and its materialization Recipes. Input revisions use
the submodule revision and SHA-256 bindings, not a renamed `SourceNNN` identity.

The new context was checked independently: processor/log safety and progress
completed with 428 distinct states, VM memory with 861, and the composed
constructor with 282,122. All eleven negative controls reproduced their expected
violations. These are bounded abstract contracts, not native runtime acceptance.
