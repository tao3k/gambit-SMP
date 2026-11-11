# Debug Metadata Projection Review

The identity map in `targ-scan-procedure` is inconsistent with stable
continuation numbering on the stack-entry candidate. The construction
source now publishes each debug descriptor under the label cell assigned
after that partition. This is a source repair of that mapping. It does not
prove the interpreter SIGSEGV, and it does not close a native gate.

## Evidence consulted

`trajectory clues` with `make-stack-entry-navigation` and binding
`mechanism=debug-control-point-id-remapping` returned one counter
observation and no support. Claim
`entry-contract-debug-label-mapping-consistent`, witness
`entry-debug-id-gap`, digest
`be78d5fd99bd8a55fcdfe69a3c818e1a129b8bcffa7fafefd1e1597e4e7d4822`, source
`evidence/research/stack-entry-contract/interpreter-crash.json`. Factors:
candidate `stack-entry-contract`, outcome `INCONSISTENT`, stage
`source-audit`, source lock
`f0507df35d87eea34634047edc98e0cb9130bad77f24a63ca7bd131135c81dc4`,
unresolved premise `native-qualification-after-metadata-repair`. It links
to `stable-continuation-partition-candidate` by
`missing-debug-descriptor-projection-contract`. Checkpoint
`clue-read:6086743d42e1ad54b9bbefd93d8423ca97bb01f2360ed19cf690d8b838113b24`.
`executionAuthorized` and `runtimeAdmitted` are false.

The same premise binding returns that same counterevidence. Binding
`candidate=c-continuation-debug-projection` is an unknown factor value, so
the retained Quint characterization is not a registered clue. Its manifest
and `review.md` stay research notes: finite association only, patch not
applied to a source lock, no native qualification.

Exact reads, each a fresh query:

- `stable-continuation-partition-candidate` is support for the source lock,
  outcome `UNQUALIFIED`, mechanisms
  `stable-visible-before-private-continuation-numbering` and
  `full-poll-dominates-stack-only`.
- `entry-contract-interpreter-local-environment-valid` is counter.
  Witness `entry-interpreter-crash`: outcome `SIGSEGV`, procedure
  `##local->value`, scope `uuid-matched-fault-site-not-first-header-writer`.
  Link to the mapping claim:
  `source-audit-hypothesis-not-proved-causality`.
- `entry-contract-manual-ordinals-aligned` is support for generated-source
  ordinal PASS, linked by `entry-ordinals-do-not-imply-debug-id-correctness`.

`evidence/scenarios/stack-header/clues.ss` already joins those factors.
No declarative correction was required.

## Source check

The construction procedure already partitions `ord-lbls` into non-internal
labels and then internal returns, and assigns cell numbers on that
`value-order`. `debug-info-generate` still received `(lambda (i) i)`.

For Scheme procedures, `debug-info-add!` runs once immediately before each
entry or return label is recorded. Simple labels are not value labels and
are not queued. The queue index is therefore the index of
`(keep targ-lbl-val? ord-lbls)`, which is definition order, not
`value-order`. `##subprocedure-info` takes `##subprocedure-id` and selects
the descriptor whose slot 0 equals that id, scanning from the end. After
partition, the id is the cell, so an emission index can name a different
label. The dynamic-env shape in the retained model (cells 0, 2, 1) is an
instance of that mismatch, not a measured fault PC.

C procedures emit an entry and a return through `targ-emit-label-*` without
`debug-info-add!`. `debug-info?` stays false, so `get-id` is not applied.
That path was not given a new debug queue.

Cells are `(cons 'cell n)` and `targ-cell-set!` writes `n` in the cdr.
The callback runs only after value-label cells are assigned.

## Integrated change

In `.cache/trajectory-publication/.cache/fixtures/smp-native/source/gsc/_t-c-2.scm`,
`debug-info-generate` now receives the cdr of the cell for the i-th
definition-order value label. The value-label vector is built once;
lookup is constant time. Label allocation, `val-lbls`, and poll-kind
selection are unchanged.

The parent audit text requires “original value-label order to allocated
label-cell numbers.” This callback is that map. It does not rewrite
`debug-info-generate` or `##subprocedure-info`.

## Left unproved

The SIGSEGV at `##local->value` (`___CDR` of the empty list, UUID-matched
reports) is the same receipt as the mapping gap, and the registered link
says the audit is not proved causality. Nothing here shows that this
projection is the first bad write, the cause of every GSI/GSC failure, or
sufficient for interpreted stress. Native qualification after the metadata
repair remains the open premise. No bootstrap, stress, or model run was
executed for this edit. Milestone progress stays 6/12 until the supervisor’s
existing qualification says otherwise.
