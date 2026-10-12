# Interrupt Lifetime Registration

Four checked independent models extend the bundle registry from 92 to 96:
sealed producer/review handoff, interrupt GC roots, callback GC/exit and
requester cancellation. Original manifests and receipts remain unchanged.
Each new `registry-contract.json` binds its original contract hash, retains
the same checked cases and adds the Datalog composition metadata. The three
interrupt models execute the imported queue/result model. The handoff model
has no imported model and declares an empty composition list.

The first registry projection exposed a missing `composes` key. This was an
integration failure, not a TLC or native defect. After using explicit bound
registration contracts, all four `bundle_facts` projections report exactly
one checked model each. No Python schema or checker was changed.

The previous 92-bundle bytes are preserved at
`evidence/source-results/fixtures/thread-completion-contract/registry-before-interrupt-lifetime.json`
with the original digest
`4582a11c426cd420e982e13df285cfa2ab1c202541c122e88e3904bd3f7d3254`.
The original 89-bundle parent and original registered Reflection are also
unchanged. The prior interrupt audit issue now binds a versioned historical
projection at
`evidence/fixtures/thread-completion-contract/historical-registry-reflection.json`;
its secondary evidence retains the original Reflection. The embedded projection
must exactly match its new primary artifact, not silently rewrite old evidence.

## Actual New-Input Qualification

The matching previously qualified ASCENT implementation sealed successfully in
1.661 seconds under the original 15-second cap. A fresh full graph on the new
registration ran 770 tests with zero errors, one failure and zero skips.
The parent exited two after 139.588 seconds under the original 300-second cap,
without timeout and with a quiescent process group. Its output is retained at
`.data/fixtures/interrupt-lifetime/registered-graph`; this execution location
is not source authority or a portable proof artifact.

The failure is the historical registry regression's `current[:-3]` assumption:
four legitimate new bundles invalidate a fixed tail length. Later assertions
also require the old Reflection to bind a mutable current registry. The test
owner is coordinating a strict version-chain check, retaining original hashes,
exact historical prefix contents and both Reflection versions. No assertions
may simply be removed, and a changed test requires focused and fresh full
qualification. This denied attempt is not green or an admitted runtime.

The earlier 770-test PASS belongs to the earlier inputs. This newer graph
cannot inherit its CURRENT status. Full native, bootstrap, Gerbil and production
performance obligations remain separate from this framework qualification.
