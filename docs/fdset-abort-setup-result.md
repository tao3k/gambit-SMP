# FD-Set Setup And Cleanup Result

## Model-First Check

The existing source-bound framework completed all 8 steps with PASS in
26.202354916 seconds, within the 45-second model ceiling. Correct ownership
exhausted 119 distinct / 139 generated states, queue empty. Three controls
produce decoded counterexamples: old cleanup omits the bank (10 states),
ready-only rollback misses failed setup (7), and freeing without clearing
ownership fields violates accounting (10). No test was skipped.

The model covers two/three allocated buffers, async disabled/enabled, each
allocation failure, pipe creation failure, both fcntl failures, success and
repeated cleanup. It is not a concrete allocator/OS or C refinement proof.
The source step binds the pipe-descriptor predecessor; the model checks a
proposed bank ownership rule before the C successor is applied.

Engine ID:
`fc943732ddf04239f2dd9426f57ad71f00af2b384ff04ecd77337fadffa7ff2b`.
Outer receipt SHA-256:
`f042b8af3e987ce53ae66d63295b9bb7208bff9cabb581bd6f12752c7d35e338`.
Child receipt SHA-256:
`c160c9b5d1fa649973a3031e3407d75d06ebc9df00b095c2a37629fab719ba5b`.

## Source Successor

Source lock: `evidence/fixtures/fdset-abort-owned-rollback/source.lock.json`,
SHA-256 `c81d31ec44b016e2d5a3ab92ea27b99d4595571f266d39b7c114d2f224c59754`.
Overlay: `patches/fixtures/fdset-abort-owned-rollback.patch`,
SHA-256 `98e3d38ca5ab78e843b79aed3669758cf8616fd4932e35496bef3016a9489662`.

The lock retains all 23 files. Only lib/os_io.c differs from the preceding
pipe-descriptor candidate; that previous descriptor fix and SFUN context fix
are retained. Current os_io.c SHA-256 is
`c032d4b4381ec3fab84ad4e5e46b1fbee8fb7ead74ca6ca109b952432cc242f2`.
The exporter reapplied and verified the overlay from pinned submodule bytes;
all 23 current candidate digests were checked. The one retained source tree
was reused, not copied to another long-lived fixture.

On late POSIX setup failure, fdset_realloc(ps,0) releases the successfully
committed bank. Normal cleanup calls the same operation independently of
abort-ready. This allocates nothing, releases non-NULL buffers, nulls every
pointer and resets size. Atomic abort ownership still guards pipe/event close.
No structure layout, exported signature, concurrency flag or lock is added.
The POSIX bank repair is platform-general, not a macOS-only speed patch.

Source inspection of cleanup_mem_pstate confirms it does not free the PSTATE
storage before this OS cleanup. Allocation-helper partial failure already frees
its scratch buffers; caller cleanup is not added on that branch. Exclusive
setup/cleanup and drained users remain premises.

## Checks And Remaining Acceptance

GNU GCC 16 syntax-only compilation of os_io.c passed before and after the
repair with retained HAVE_CONFIG_H, PRIMAL/LIBRARY and O3 defines. Preprocessed
output includes the two new zero-capacity release calls in setup and cleanup,
so the repaired branch was not excluded. This is not a fresh configure or
linked/runtime test. Alternate platform/configuration compilation and permitted
public-path fault/resource tests are still needed.

The three counterexamples are copied byte-for-byte under the source fixture:

- old-cleanup: `434fafd3eaf4eaeb5b33b59fddf7589fdcdfe0386662976c2d665be4962a38dc`
- ready-only: `177ef7b336ce40b101a65009e79d2bca5d87cf68d2abc21b6e4714430ab305a4`
- forgot-reset: `53a6670c75f066b3f65dc2cdd2cbdf3eb2fa38bb1397bf97b3d2f32c88284743`

No runtime fault hook, private cleanup export, new bootstrap budget or release
admission is used. Cumulative native milestone remains 3/12. The last full
bootstrap/GSI qualification belongs to queue-endpoint, not this successor.
Original qualification consumption remains 468.695876834 / 600 seconds.
