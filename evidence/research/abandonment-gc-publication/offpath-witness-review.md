# Off-path proposal review

## Source-bound failed check

`quint typecheck models/gambit/ticket_offpath_witness.qnt` exited 1 for
SHA-256 `88b1b5d056806a6c86ad04a87838fa37ce3c9e0eaddde589879568825a15bf05`.
The first diagnostic was `QNT404: Name 's' not found` at the `initOffPath`
assignment. The draft declares `State` but not its state variable. This is a
model compilation failure, not an invariant counterexample or a native failure.

## Observation is not an ownership oracle

The proposal note is bound to
`ba3b67943e80e69e065f86ce37ac187fd8c4190cea92b3422e14e50f7b88428e`.
The draft's `unique` predicate reads `s.holder` and `readWitness` assigns that
same latent holder. The described implementation has no such oracle. Removing
this hidden premise does not preserve the stated ownership conclusion.

A valid abstract alternative is: processor 1 holds ticket 1 in a register;
processor 2's live stack contains an unrelated integer 1; the serving word and
generation stay unchanged. There is one residual stack match, but it belongs
to processor 2, not the owner. Even a closed interval and no wrap cannot turn
integer equality into acquisition provenance.

`models/gambit/ticket_offpath_owner_counterexample.qnt` separates observable
word matching from ownership ground truth. It is a challenge to the acceptance
claim, not a model of the full runtime or evidence that this stack configuration
occurred in the recorded native failure.

The existing `quint_backend.check` ran `init / step / ownerSound` with the TLC
backend and required a reachable invariant-violation trace, not a generic nonzero
exit. It accepted the expected counterexample in 4.984 seconds: 2 generated,
2 distinct states, 0 queued. The initial state is `observed=false, accepted=0`;
the next `observe` state is `observed=true, accepted=2`, while `realOwner=1`.
This establishes the abstract counterexample, not occurrence in the native run.

## Other unclosed premises

- Negative initializers pre-populate invalid acceptance; they do not establish
  reachable failures of a faulty observer starting from a valid initial state.
- `barrierStage` and the published operation are assigned, not derived from
  election and a release/acquire handshake.
- `failureShape` holds ticket state constant by construction; it cannot prove
  preservation of native scheduling or of the retained hang.

No model scope review, C change or native admission follows from this draft.
The proposal remains available for revision; this review does not prescribe an
alternative design or prohibit revisiting it under stronger evidence.
