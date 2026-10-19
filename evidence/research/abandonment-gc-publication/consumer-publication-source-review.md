# Consumer publication: implementation correspondence

## Preserved result

The checked `consumer_publication.qnt` digest is
`e53be0b9b02cbed707c644370614a3c45b5d4c5e5881fae7e53fef75abdde6bd`.
The stable campaign accepted three positive checks and six reachable negative
controls in 33.096 seconds. Each positive check exhausted 66,668 distinct
states. This review preserves that result; it does not label a conditional
model as a failed check or establish the cause of the native timeout.

## Atomic representation is an implementation premise

`publish1/publish2` replace `pubH` and `pubT` in one transition. `publishDone`
replaces `doneSeq` and `doneOp` in one transition, and `atomicRead` consumes
both in one transition. The model explicitly rejects split reads. Therefore a
C implementation must supply a corresponding indivisible representation or
a checked publication/reader protocol; two separate release stores are not
the modeled atomic pair. The current ticket lock has two ticket words, not a
shared owner certificate. The actual sync operation contains an operation byte
and two word arguments, not the model's scalar payload.

An encoding must state its represented fields, supported widths, identity and
reuse bounds. A model with two actors and two tickets does not prove that
arbitrary native identities and ticket generations fit one atomic word, or
that a wider atomic operation is lock-free under the GNU build profile. This
review does not select an encoding or require a general operation-payload
snapshot when only the operation kind is being claimed.

## Phase and source identity are observable conditions

The actual barrier captures the processor cohort, gathers child proposals,
combines/elects an operation, and only then distributes the result. Message
flags contain processor identifiers that can recur; they do not carry the
model's `seenRound`. A new round identifier needs a defined source and lifetime.
A completed-operation record can describe a completed past round, but may be
absent while a participant is blocked before election. That absence cannot be
reported as no barrier, and an entry proposal cannot be relabeled as the
selected operation. Correspondence must expose which phase and identity a
record actually describes.

The reader source lock is
`651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`;
the cumulative patch is
`e0f2b46d591ecbab9156d3d0adf9c83531e9d0c64f4c617b6ceb9b286c63ba12`.
Relevant definitions are `___ticketlock_struct`, `___sync_op_struct`,
`___TICKETLOCK_LOCK2`, and `barrier_sync_op` in that candidate. The retained
materialized workspace additionally contains the processor-only observer;
it is not an unmodified instance of this source lock.

## Historical certificates are not simultaneous ownership

`ownerConsumer` deliberately permits a certified actor to have unlocked by the
time a later report is read (`p1/p2 >= 2`). `jointCertificates` preserves two
independent historical certificates; it does not establish that the lock
holder was in that operation, that both records refer to one VM incarnation,
or that they were simultaneously current. A source report must preserve these
conditions rather than infer a causal lock/collective cycle from two valid but
independent records. Missing, stale and conflicting records remain distinct.

The model still makes unlock available whenever an actor holds the lock.
Its completion property is not yet a functional repair proof for a holder
waiting for a collective whose other participant is blocked on that lock.
Added publication stores may change scheduling; finite-state safety does not
prove preservation of the original fault schedule. Actual source repair and
the original uninstrumented stress acceptance remain outstanding.
