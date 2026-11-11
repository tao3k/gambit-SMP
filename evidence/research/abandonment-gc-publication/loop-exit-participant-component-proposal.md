# Loop-exit and participant component limits

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
Correspondence review
`evidence/research/abandonment-gc-publication/loop-exit-barrier-correspondence-review.md`
(`32e7887b001b4f542a3e74768e19246a03c8ee6e85ff8944c883eaf49c1173d2`)
classifies both checked components as
`conditional-component-not-consumer-certificate`. This note is the current
proposal for those limits. It leaves `scope_review` empty. Empty scope review
keeps consumer correspondence unresolved. It is not native admission, a C
reporting protocol, or a GC progress repair.

Live models named by the review:

- `models/gambit/loop_exit_owner_evidence.qnt`
  `de661393e375046acacf8246ac8102ce475a2aae308ffb98761b4849f18712a3`
- `models/gambit/barrier_round_publication.qnt`
  `b661abf0aa7bf5a5ef0bf1bfebc0f37e1e09cc696dde02555a9e96a444659c80`

The model-revision report for those two digests is the stable campaign
`.cache/loop-exit-barrier-publication-stable/receipt.json`
(`fb57d01805d18ee3ae00cf5f23f30e1ee5fef5c2419bb7cc1c1dbcdc61c3c176`):
`contextStable=true`, `accepted=true`, `runtimeAdmitted=false`,
`releaseAdmitted=false`, native status `not-run`, campaign 15.194s.
That receipt preserves the component checks. It does not qualify a consumer
certificate.

The earlier campaign
`.cache/loop-exit-barrier-publication/receipt.json`
(`fd983652688f9db1fd3a727271dd4299cff164b473fe9ebe2c3222ea4745a7e5`)
has `contextStable=false`, `accepted=false`, `runtimeAdmitted=false`, and
native status `not-run`. It stays registered and is not a model-revision report.

## Current proposed values

`loop_exit_owner_evidence` owner-identity:
`acquirer-loop-exit-comparison-not-a-consumer-certificate`.
The candidate macro compares the thread-local reserved ticket with `current`
and then ends. Model fields `e1` and `e2` are that comparison. The model
assumption matches this value. There is no shared owner field, publication,
reader, lifetime check, or sampled-thread association in the positive protocol.

`loop_exit_owner_evidence` observation-effect:
`fair-completion-is-not-native-lock-wait-progress`.
The model assumption remains `unlock-enabled-whenever-holding`: unlock is
enabled whenever the holder phase is 2. Fair completion of that transition
system is not progress evidence for the native lock-wait/barrier sample, and
it does not establish that the sample is a GC cycle.

`loop_exit_owner_evidence` fault-preservation: `not-represented`.
The model assumption matches.

`barrier_round_publication` barrier-operation:
`participant-copy-matches-round-only-under-upward-wait`.
The model assumption matches. Under that wait, the participant copy matches
the acquired round after the flag reset.

`barrier_round_publication` cohort:
`upward-wait-is-not-a-real-cohort-proof`.
The model assumption remains `next-payload-waits-for-post-copy-upward-send`,
which is the `store2` guard. The cohort control removes that premise. The
control is not proof that a real source cohort follows the modeled path.

`barrier_round_publication` publication-handshake:
`flag-equality-is-not-a-third-party-snapshot`.
The model assumption matches. Flag values can recur and are not a round id.
`thirdPartySound` distinguishes a retained sample from later live state. The
stronger mixed-accept trace remains
`models/gambit/barrier_thirdparty_flag_aba.qnt`
(`097e0eb89843c7028ddbed439039b9c057d10989d4acc21aacc92bc24e35142c`).
This scalar model does not replace that trace.

`barrier_round_publication` observation-effect:
`no-joint-owner-and-selected-operation-consumer`.
The model assumption matches. No consumer protocol reports the selected
operation together with the ownership witness.

`barrier_round_publication` fault-preservation: `not-represented`.
The model assumption matches.

The rejected offpath assumption
`unique-residual-slot-equals-stable-serving-word` stays on
`ticket-offpath-witness`. It is not a proposed value of this proposal.
Execution remains unauthorized.
