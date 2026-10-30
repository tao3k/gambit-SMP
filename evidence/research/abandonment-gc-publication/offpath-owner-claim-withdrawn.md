# Owner claim is not current

Source lock `651f18daae1befaa0f25d2218277fed62de631f3790838285e409833ed20ca67`.
The current owner conclusion is that a unique residual stack word equal to
the serving ticket is not acquisition provenance. The value
`unique-residual-slot-equals-stable-serving-word` is a rejected assumption of
`ticket_offpath_witness`, not the current proposal.

The failed module, without `var s`, is retained at
`evidence/research/abandonment-gc-publication/ticket_offpath_witness.failed-typecheck.qnt`
with SHA-256 `88b1b5d056806a6c86ad04a87838fa37ce3c9e0eaddde589879568825a15bf05`.
Its typecheck exited 1 with `QNT404: Name 's' not found`. The review is
`evidence/research/abandonment-gc-publication/offpath-witness-review.md`
(`64adb9edc9b535ff3dc0f7d84e160fb4d1fc3a3cc01b685cd7ccaff48f1b0b45`).
The original proposal note remains
`ba3b67943e80e69e065f86ce37ac187fd8c4190cea92b3422e14e50f7b88428e`.

`models/gambit/ticket_offpath_owner_counterexample.qnt`
(`4c58e8fdeb25d2b67e72fb4b60108956bf2176ebe70805044cd84728d70c941c`)
is the checked separating trace: processor 1 holds ticket 1 in a register,
processor 2's stack contains an unrelated 1, and `observe` accepts 2 while
`realOwner` is 1. A closed interval does not repair that.

The live `models/gambit/ticket_offpath_witness.qnt` only adds `var s: State`.
That syntax correction does not qualify the protocol, does not remove the
holder oracle, and is not a scope review or a native admission. The rejected
assumptions stay on the model: residual-spill ownership, an assigned barrier
stage, and no representation of fault preservation.
