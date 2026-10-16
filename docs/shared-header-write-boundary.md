# Shared Header Write Boundary

## Prechange Review

- Relevant: TFIB still reads a damaged catalog-member header after the stack
  partition candidate. The new position 9 is in range but differs from member
  1495. A range-only model is insufficient.
- Prior work: old-space/scan-origin diagnostics observe inputs or repeated
  bodies; the shared-successor diagnostic observes a later use. None binds an
  actual GC administrative-header write attempt. Their failures are not retried.
- Worth: check central GC cell stores and forwarding-header targets before
  writing. This can bind a concrete invalid operation without replacing the
  allocator, masking a pointer or dropping a scan.
- Expected benefit: causal evidence, not a speedup or accepted source repair.
  Catalog lookup adds diagnostic cost and changes scheduling. No hit cannot
  exclude uninstrumented GC, bulk-copy, mutator or reclamation paths.

## Model And Native Scope

The QNT imports the latest native header values and separately rejects an
otherwise-valid header whose position is merely in range. The write-boundary
controls enumerate logical header/payload/external-root addresses: guarded
administrative writes deny, other writes remain allowed; unguarded writes
violate integrity. The unsafe writer control is not claimed native-reachable.

The proposed C observer uses the existing address-order lookup and
`offsetof(___msection, base)`, never the damaged index/position to identify a
header. The arena directory is stable through GC marking; resize occurs after
the marking phase barriers. The observer does not establish allocation
generation or private ownership. It must not be called on arbitrary mutator
stores while another processor could resize the directory.

Scope is Darwin/GNU only: `mark_array` cell updates and movable forwarding
headers, plus captured/active frame GC slot writes. A report identifies a
guarded write boundary or attempted forwarding header, not necessarily the
first corrupting instruction in the whole runtime. No suppression, successful
exit, release admission or milestone increment follows from a denial.
