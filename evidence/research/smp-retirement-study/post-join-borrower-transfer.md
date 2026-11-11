# Post-join borrowers and partial transfer

2026-10-23. repair-9-12. Evidence only for the contract boundary. The c86
producer change that follows this note is not a 9/12 receipt.

## Observation

A `___thread_join` result of 0 means the donor OS thread has exited. It does
not mean every scanner or other borrower has left, and it does not mean memory
transfer and destruction both finished.

Before this note, the shrink loop dropped `native_tails` and called
`___transfer_mem_pstate` then `___cleanup_mem_pstate` as soon as join returned
0. `___transfer_mem_pstate` splices still objects and the RC list under
`MISC_MEM_LOCK`. `___cleanup_mem_pstate` then frees those structures and, when
`heap_chunks_to_scan_lock_ready_` is set, destroys the scan lock. The join
loop did not read marker count, `still_objs_to_scan_`, the scan-chunk head and
tail, `native_entry_users`, or the request-slot producer count.

## Separate claims

- Join failure keeps the tail and the real `pthread_join` result. That result
  is not printed as `LIFECYCLE-JOIN:OS-JOIN-ERROR`.
- Join success with a live marker, a nonzero `scan_workers_count_`, a
  nonempty scan queue, a remaining still-object scan, an entry borrow, or a
  request producer refuses the transfer and sets `transfer_retained`. The
  tail stays. `scan_workers_count_` is the existing GC worker count, so a
  scanner still inside `mark_reachable_from_marked` keeps the transfer refused.
- After a clear observation, still objects and RC blocks move, then
  `___release_transferred_mem_pstate` frees the donor remnants and does not
  destroy the scan lock. Destroying that lock remains a later step.
- `lifecycle-join-recovery-1` and `lifecycle-join-recovery-2` stay as they
  are. The qualifier is unchanged. Count stays 8/12.
- The earlier c86 p1, p11, and 2-to-1 prints are external until a path and
  hash bind them. `runtimeAdmitted` stays false.

Clue continuation used for this read:
`clue-read:b46487a05d678f4995047475e555a23e40c6f11803667ce874c67de5036dc20f`.
The registered processor-interrupt collective view stayed unclosed, with
`executionAuthorized` false and `runtimeAdmitted` false.
