# Scope of the loop-exit and participant models

## Checked components

The stable five-check campaign reports `contextStable=true`. Both positive
checks finished with zero queued states; the three negative controls produced
reachable invariant counterexamples. The earlier unstable campaign is not
qualification and remains retained separately.

- `loop_exit_owner_evidence.qnt`:
  `de661393e375046acacf8246ac8102ce475a2aae308ffb98761b4849f18712a3`.
- `barrier_round_publication.qnt`:
  `b661abf0aa7bf5a5ef0bf1bfebc0f37e1e09cc696dde02555a9e96a444659c80`.

These are useful conditional component results. This review does not turn them
into a failed model or erase their historical checks.

## Ownership evidence has a consumer

`localEvidence` checks the acquiring actor's own loop-exit comparison and mutual
exclusion in a two-ticket system. Its `e1/e2` are abstract local witnesses, not
existing shared C fields or evidence delivered to another observer. There is
no publication, reader, lifetime validation or association with a sampled
thread/VM in that positive protocol. The external-word control correctly fails,
but does not implement a replacement consumer-visible ownership certificate.

The retained native investigation needs an accountable observation of the actual
holder, not just the already-known fact that the successful acquiring actor
passed its own comparison. That gap may be addressed in different ways; no
particular reporting or ownership representation is selected here.

## Progress is conditional on enabled source actions

The local model enables `unlock1/unlock2` whenever `p1/p2 == 2`. It has no state
where a holder must finish a collective before reaching unlock, or where a
waiter cannot participate in that collective. Its fair completion result is
therefore not progress evidence for the lock-wait/barrier interaction observed
in the native sample. This does not establish that the native sample is a GC
cycle; the actual owner and operation still have to be determined.

## Participant ordering is not a diagnostic snapshot

The barrier model represents a fixed mailbox round trip with a scalar payload.
It orders store, release, acquire, reset, copy and the next upward send. Its
`store2` guard encodes the premise that no subsequent publication overtakes
the receiver's copy. The cohort control deliberately removes that premise;
it is not a proof that a real source cohort change follows the modeled bad path.

There is no consumer protocol for reporting the selected operation together
with the ownership witness. `thirdPartySound` compares a retained historical
sample with later live state; its failure demonstrates that those meanings
must be distinguished, not that every historical sample is invalid. Memory
ordering correspondence relies on the candidate's actual release/acquire
operations, not the names of sequential model actions alone.

## Admission boundary

The component checks support their stated premises. They do not yet qualify a
new C owner/operation reporting protocol, a GC progress repair, or the native
cause of TFIB/interrupt timeouts. Missing source-to-consumer correspondence must
remain visible without inventing a workflow, forbidding alternative hypotheses,
or promoting a baseline characterization into a new runtime fix.
