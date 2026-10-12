# Eager Tail Marking And Disjoint Scan Ownership

## Pre-Implementation Review

1. Source correspondence supports refining ownership by field, not adding a
   global lock. Candidate027 publishes a fully copied object before completing
   eager marking of its first field; its scanner explicitly skips that field.
2. `gc_forward_publication` and `gc_scan_claim_transfer` already cover early
   payload publication and duplicate claims. They do not represent this exact
   producer/scanner field partition. Do not rerun their native failures.
3. This refinement prevents a false diagnosis that any retained producer work
   after chunk export is unsafe. It provides no measured speedup or accepted
   runtime patch.
4. It does not identify the cause of diagnostic014's repeated vector-body scan,
   nor explain diagnostic012/013's relocated fields. Those observations remain
   denied routes with unresolved producer/claim origins.

## Source And Paper

HotSpot section 4 reserves a speculative local destination, wins a forwarding
CAS, then copies; losing threads redirect and retract their local reservation.
Thus CAS-before-copy alone is not a defect. The consuming operation and its
readiness requirement matter. Gambit's `mark_array:3720-3778` has this shape.

For nonempty movable objects with subtype at or below `sBOXVALUES`,
`mark_array:3753-3756` retains the destination's first field in `cell` for eager
marking. Copying finishes before `end_heap_chunk:3770`, but `goto again:3775`
can occur after that chunk publication. A consumer may therefore scan the
exported object's remaining fields while the producer still owns field zero.
This is not the continuation-link protocol: continuations have separate subtype
handling and are outside this partition.

The consumer enforces the partition in two paths:

- `scan:4324-4327` skips the first field for the matching movable subtype;
  still objects instead scan every field.
- `scan_and_advance:4351-4356` gives pairs a fast path that also skips the first
  payload field. The ordinary path remains necessary when fast scanning is off.

The source's worker stays inside `mark_array` while eager work is unfinished.
Its later idle accounting in `mark_reachable_from_marked:6955` must not be moved
to export time. Recursive eager chains may allocate and publish more chunks;
that closure is an explicit remaining composition obligation.

Forwarded-reference consumers must also be distinguished. CAS losers and the
`FORW` branch (`mem.c:3744,3803`) redirect references without reading the target
payload. `determine_will_executability:5180-5185` does dereference a forwarded
will's payload, but is reached from `process_wills` in the weak phase after
strong closure and the inter-phase barrier (`7239-7247`). That is a different
readiness premise. Neither observation proves all consumers are covered.

## Model Contract

`eager_tail_scan_partition.qnt` explores one copied object with 1..4 reference
fields, source-owned field zero, a singly claimed remaining scan interval, and
producer/scanner completion. It permits legal overlap rather than banning
producer ownership whenever work is queued. Counts are finite verification
bounds, not runtime tuning or package-specific values.

Two independent controls check scanning field zero again and deactivating the
producer at export. The former must reject duplicate relocated input; the latter
must reject resuming with field zero unfinished. A positive result is bounded
SC evidence with coherent queue publication assumed, not a C memory-model proof.

Initial payloads are valid old-space references. Aliased logical objects,
recursive chains, zero-length/still/weak/continuation objects, repeated epochs,
multiple chunks and exclusive queue-claim correctness are not proved here.
The existing claim-transfer model remains relevant to the exported interval,
but its whole-object ownership interpretation must not be imposed on this
source-specific split.

Campaign001 was rejected during parsing because a local identifier shadowed
Quint's builtin `size`; it provides no protocol evidence. The corrected run
renames that local identifier without changing the protocol. Receipts retain
the failed attempt separately from accepted model evidence.

Campaign002 has stable bound inputs. Both controls produce actual invariant
violations: six states for duplicate first-field marking (22.799 seconds),
seven for early producer idling (16.663 seconds). The positive model passes
safety and weak-fair progress over 74 distinct states, 114 generated, zero
queued in 28.396 seconds. The source-bound portable bundle is
`evidence/model-results/eager-tail-scan-partition/`. The control search may stop
at its first counterexample; it is not an exhaustive correctness claim.

## Engineering Gate

Do not delay every chunk export until eager chains finish, add a to-space skip,
or serialize all scanning based on this refinement. For any proposed GC repair,
bind the exact first/second scanner origin, object allocation generation, field
interval and producer activity. Native acceptance still requires the identified
GNU GCC candidate with all three switches, GC/lifecycle regressions, complete
bootstrap and Gerbil full tests. No unchanged native retry was performed here.
