# Interrupt Registry Reflection Version

Adding three actually checked protocol bundles changed the registry identity.
The first fresh graph attempt then stopped in 0.831 seconds, before validation,
because an older module-fixup Reflection still bound the previous registry.
This was a correct source-identity rejection, not a Library or GC defect.
The original failed graph observation remains retained by the graph owner.

The prior registry was reconstructed by mechanically removing exactly those
three added bundles. Its bytes reproduce the original digest
`eac411bf5c033abd4f4554dc4e6c81eeda6d4082581479e637255526446a35d2`.
It is preserved at
`evidence/source-results/fixtures/abandoned-result-state/registry-parent.json`.
The old Reflection artifact now points to that snapshot with its unchanged
digest. Neither the old observation nor its acceptance claim was rewritten.

A separate current Reflection is stored at
`evidence/fixtures/abandoned-result-state/registered-protocol-reflection.json`
and embedded in the new `interrupt-result-composition-current-source` audit
issue. It binds the current complete registry, all three checked bundles,
actual parent abandonment failure, candidate source lock, bootstrap, selected
native tests and current-artifact Unicode observation. It explicitly retains
the GC, cancellation, retirement, source-refinement, full native, Gerbil and
Lean admission gaps. Historical graph success is not current graph success.

Every Reflection binding and each newly registered bundle passed local current
hash validation. This does not replace fresh full ASCENT graph execution.
The prepared compiled combined native fixture has passed the actual rebuilt
Gambit reader only; macro expansion, compilation and assertions remain unrun.
No runtime patch or timeout expansion was made for this identity repair.
