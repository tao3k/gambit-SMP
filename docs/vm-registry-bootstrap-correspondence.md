# Registry Candidate Bootstrap Correspondence

This review permits one source-bound bootstrap investigation, not runtime or
source-refinement admission. Historical failures, logs and budgets remain
unchanged. The previous intent was correctly denied because its `setup.c`
after-hash described the prior thread-completion candidate, not this candidate.
That denied run built a linked seed but never executed from-scratch bootstrap.

## Preserved Synchronization Core

The prior candidate is reproduced by the thread-completion source lock and the
new candidate by the registry release/replay source lock, both on the same
pinned submodule revision. The inclusive `setup.c` block from
`___EXP_FUNC(void,___init_procedural_interrupt)` through the declaration
`___HIDDEN void cleanup_os_and_mem_vmstate` has identical SHA-256
`41a72bf0530976d692f60ab7985b0deae95b7ce481a9aa868efa1bd289a3c5f3`.
This includes the synchronization/start/resize implementation already used by
the retained bootstrap review. It does not include the changed registry and
cleanup code and is not a whole-file equivalence or behavioral proof.

Reproduce both locked source trees with the existing `materialize-source` CLI,
then hash the named inclusive block using the same line selection:

```sh
sed -n '/___EXP_FUNC(void,___init_procedural_interrupt)/,/___HIDDEN void cleanup_os_and_mem_vmstate/p' "$SOURCE/lib/setup.c" | shasum -a 256
```

No cached tree, previous binary or numbered diagnostic directory is authority.
The complete new `setup.c` SHA is
`b3019f9cd4aa26c1a0a1532439daecf2ba8303c98b1b81c1dcefcd62b78cc9cc`.
The overlay additionally changes `mem.c` and `mem.h` for the same registry
protocol; all 20 file identities remain locked.

## New Behavior And Assumptions

The added unsigned atomic gate couples reader registration with closing and
terminal shutdown. Writers drain admitted global-interrupt readers before
registry mutation/cleanup. Deferred interrupt replay obtains a fresh reader
lease, has record-side and release-side rechecks, and runs outside the writer
mutex. Shutdown cannot be undone by an ordinary writer reopen. Public cleanup
locks once; the internal global loop calls a locked helper and unlocks before
destroying the registry mutex. The device-select abort descriptors are created
nonblocking; the callback does not acquire the registry mutex.

These changes affect construction, interrupt delivery and shutdown of the
compiler runtime; they are a materially changed investigation of that runtime,
not an unchanged replay of a censored command. Root-cause resolution of the old
timeouts remains a hypothesis. Existing sync-core byte preservation, finite
QNT controls, linked seed construction and object compilation do not prove it.

GNU native-word atomics are required for this prototype. The selected Mach-O
object used inline `casal`/`ldaddal`/`ldar`, with no external atomic helper.
Physical memory order, arbitrary epochs/signal storms, embedding cleanup-lock
ownership, direct processor-resource lifetime and constructor/global teardown
overlap remain open source/native obligations. Global setup/teardown requires
exclusive lifecycle ownership. None is waived by retry eligibility.

The bootstrap investigation retains GNU GCC, all three flags, host-derived
shared concurrency, C/RTS `-O0`, the original 600-second whole budget and exact
two-pass phase/source-closure checks. All native children must exit successfully
and be reaped/quiescent. No full gsi/gsc, GC/FFI, Gerbil, release or performance
claim follows from bootstrap eligibility or success.
