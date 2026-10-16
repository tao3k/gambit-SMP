# Pipe Descriptor Rollback

## Review Before Source Changes

The public cleanup ownership audit explicitly leaves the descriptor-move error
path open. Existing pipe models cover wait/read/close protocols, not descriptor
ownership while opening the select-abort pipe. This is not an unchanged native
failure rerun and is not a Darwin-only performance hypothesis.

Pinned lib/os_setup.c:move_fds_to_non_std queues an intermediate standard fd
before attempting its next dup. On failure, close_on_error also closes the
original fd separately and then every current fds entry. These sets can overlap.
When close_on_error is false, a queued current fd can be closed despite being
returned in fds, while its original descriptor is not queued and remains live.
Another thread can reuse a closed number before a later duplicate close.

open_half_duplex_pipe publishes hdp fields only on success. Its error branch
nevertheless calls close_half_duplex_pipe(hdp,2), even though the move helper
already owns rollback and hdp need not contain initialized output fields.

The proposed ownership rule is to queue each previous descriptor only after a
successful dup transfers the current fds entry to the new descriptor. On error,
current entries and queued superseded entries are disjoint. The helper alone
owns closing its temporary descriptors, and the opener never reads unpublished
hdp fields. Preserve the original errno across cleanup. Successful moves require
the same dup and close count, no global mutex and no additional syscall.

Expected benefit is correct setup failure rollback, not quantified speedup.
These are POSIX descriptor lifetime defects; they are not attributed to macOS
alone and do not explain the historical GC/stress timeouts.

## Model Boundary

pipe_descriptor_rollback enumerates successful duplication and failure after
zero, one or two intermediate standard descriptors, for both close_on_error
settings. Current output and temporary descriptor ownership are explicit.
A bounded outside-thread reuse transition checks that later cleanup cannot
close a newly reused descriptor. Independent controls cover old helper cleanup,
old retain-on-error behavior, reading unpublished output and omitted temp cleanup.

This abstracts a valid prefix of the low-level helper, not the entire OS fd
allocator or a proof of C. Descriptor inputs are distinct and exclusively owned;
close outcomes, EINTR/platform semantics, invalid input aliases, socketpair and
arbitrary prefix lengths remain outside this finite check. No Gambit runtime
fault injection, private cleanup export or RTLD_NEXT hook is executed.
