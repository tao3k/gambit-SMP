# C memory correspondence of the certificate reader

The initial implementation contract has digest
`f7aaa62b1909cc977096acc34f7e30d4a98cc33fe3c26c3482a6e3a6d97d9f50`.
It specifies plain holder/ticket stores and loads between atomic sequence
operations. A reader can overlap a writer even when its second sequence
check later rejects the result. Rejection is not mutual exclusion and does
not retroactively remove the overlapping plain accesses.

The [GNU atomic builtins contract](https://gcc.gnu.org/onlinedocs/gcc/_005f_005fatomic-Builtins.html)
assumes data-race-free programs. Acquire/release ordering is conditional on
the relevant reads-from relation. A sequence counter alone does not establish
that relation for every overlapping payload access. The finite interleaving
model treats its field accesses as defined actions; it does not qualify
undefined C accesses. Any eventual implementation must make the accesses
defined and justify the ordering of both validation and payload reads. This
review does not choose a representation or memory-order optimization.

The contract explicitly limits publication to two interrupt acquisition sites.
The retained source also acquires processor-object locks through Scheme
primitives and other C paths. Failure to find a certificate cannot identify
those holders. Coverage may be intentionally bounded for an experiment, but
that bound must survive in the returned evidence; reliable ownership of a
sampled target is not implied merely because its wait site was instrumented.

Likewise, a copied record's status is an observation at its validated read,
not a continuously refreshed assertion after unlock or another barrier round.
Historical identity and live ownership must remain distinguishable. The
initial implementation campaign's positive `ownerImpl` check failed on this
distinction and is retained as a real counterexample, not a passing protocol.
These correspondence issues do not establish the native timeout's cause.

## What the implementation checks must distinguish

The revised ownership invariant preserves acquisition history for a sampled
certificate. That is useful, but weaker than validating a CURRENT classification
at its observation point. A mutation that labels every coherent historical
certificate CURRENT must be distinguishable from the valid reader; requiring
the saved label to remain live forever would instead repeat the rejected
assertion. Read completion and future ownership are different claims.

The first `barrier_phase_record` abstraction fixes the entry proposal to 7
and the elected operation to 3, then requires a returned operation to differ
from the entry proposal. In the source election, the local proposal can win.
Equality with that proposal is not itself an error. Winner provenance must
distinguish a genuine local winner from an unelected entry value; the fixed
different-value example does not cover both cases. This is a coverage issue,
not a failed result of the initial finite instance.
