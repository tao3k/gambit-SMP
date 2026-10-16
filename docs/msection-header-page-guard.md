# Msection Header Page Guard

## Decision

The scalar GC write observer did not fire, but TFIB still consumed a bad
successor with intact index/position. It does not cover raw copying, mutator
fields, arbitrary compiler stores or reclamation. Repeating that observer cannot
identify the missing writer.

A Darwin/GNU-only page guard is the next diagnostic: align section payload to
the actual host page size, leaving the unchanged C header immediately before it.
Protect the preceding owned page read-only outside administrative resize/free.
An actual prohibited store can then fault at its own PC, including stores not
covered by C wrappers. Use public `sysconf`/`mprotect`; no loader interposition,
private runtime call, signal injection or custom signal handler is needed.

The `___msection` field layout, `offsetof(base)`, payload size and pointer
arithmetic remain unchanged. Only allocation alignment/padding changes. The
aligned allocation helper's existing backpointer lies in the protected owned
prefix and is read normally; free unprotects it before the allocator runs.
Protection must never cover another allocation or a payload byte.

The existing address-sorted directory is opened around `adjust_msections` and
reprotected on every return through a wrapper. Marking has completed before
resize; registered mutators must be parked during the open interval. VM cleanup
must already own quiescent storage before free. These protocol premises are not
proved by page geometry. A no-op resize need not open pages.

## Review Before Code

- Relevant: directly covers the remaining administrative-header writer gap,
  instead of another read snapshot or general barrier change.
- Explored: the prior observer only wrapped selected scalar GC stores; no
  page-isolated header guard has been executed in this workstream.
- Worth: preserve the ABI and let the real protection fault identify an access
  instruction, subject to exact PID/image/fault-address binding.
- Expected benefit: causal evidence only. Padding, permission calls and changed
  addresses affect timing and may prevent recurrence. No speedup, universal
  first-cause proof or native repair is claimed.

The QNT checks prefix ownership/alignment, unchanged header adjacency, payload
transparency, and reprotection before mutator resume. A trap remains a failed
native observation; bootstrap and stress must run through the existing sealed
framework with original flags, source reuse and inactivity windows.
