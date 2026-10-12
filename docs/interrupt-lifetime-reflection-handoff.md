# Interrupt Lifetime Reflection Handoff

`evidence/fixtures/thread-completion-contract/interrupt-lifetime-reflection.json`
stages the newer moving-root, callback-GC and requester-cancellation evidence.
It retains the earlier `root-and-suite-reflection.json` unchanged rather than
rewriting its historical absence-of-relocation boundary.

The current Reflection validator accepted nine hash-bound artifacts, three
non-closed requirements and six conditions. Rejection controls confirmed that
a stale digest, disposable cache path and attempted closed status are denied.
The cancellation evidence now records two compiled diagnostic executions with
GC before and after requester termination, not full source refinement.
The model receipt is a bounded protocol result, not a
physical GC or native-runtime proof.

The staged requirements distinguish physical roots/callback lifetime, actual
cancellation/source refinement, and complete same-artifact acceptance. Selected
native observations match the new source-core identity, not the parent bootstrap.
No newer receipt grants credit to a different candidate or resets a deadline.

After the owner's qualification window released, this input was registered as
the new `interrupt-lifetime-current-source` audit issue. Old snapshots remain
unchanged. The first new-input full graph was DENY on a historical-registry
test assumption; see `interrupt-lifetime-registration.md`. A changed test must
qualify with a fresh full graph before CURRENT/PASS can be claimed. Validation checks
references and expected digests, not whole graph admission or runtime truth.
