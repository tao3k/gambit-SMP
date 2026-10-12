# Interrupt Delivery GC Root Composition Result

The existing verifier completed the source-bound contract in 19.470 seconds
with unchanged 90-second check budgets and host-adaptive concurrency.
The corrected imported queue/result plus abstract root-scanning composition
exhausted 56 distinct states, 121 generated and zero queued, and passed safety
and its explicit weak-fair progress check in 5.610 seconds.
The processor/local/thread root omission controls produced required
counterexamples in 7.058, 7.069 and 6.780 seconds respectively.

Portable checker artifacts, imported-model snapshots, logs and traces were
published and revalidated by the existing publisher under
`evidence/model-results/research/interrupt-delivery-gc-roots`.
This is bounded projection evidence, not runtime or release admission.

Source inspection gives an important negative finding: pinned
`vendor/gambit/lib/mem.c:mark_processor_scmobj` calls `mark_array` over
`___PROCESSOR_SIZE` fields. In `vendor/gambit/include/gambit.h.in`, that size is
22, with the interrupt head and tail at indices 20 and 21. Thus the proposed
"omit processor root" control is a sensitivity check, not evidence of an
actual omission in that source. Concurrent cohort/ownership and correct field
publication remain separate requirements.

The existing native fixture independently retains its payload, so its GC
assertions cannot isolate this root chain. A queue-only-root native fixture,
actual moving-address forwarding and source-bound local-root/retirement/phase
checks remain OPEN. No runtime patch was made on the basis of a hypothetical
model control. The whole GC composition, complete native suites, new candidate
bootstrap and Gerbil acceptance remain unqualified.

An initial model diagnostic used a heterogeneous `Set(I::s, roots)` as the
fairness variable and was correctly rejected by the Quint type checker. It
was corrected to a singleton set containing the combined state tuple; all
three local diagnostic window tests then passed before exhaustive checking.
The original model/result protocol was imported without weakening its actions
or invariants. These model results do not resolve the separate formal suite
continuation gap.
