# Shared Stack Reservation Native Result

The frozen design/input is `shared-section-undo-bounds.md`. Results are kept in
this separate output document so updating a milestone does not mutate the
producer's input closure or invalidate source-bound historical receipts.

The first producer attempt passes configure and seed but fails causal review
because claim change IDs did not match the updated intent. It never executes
bootstrap. That DENY and its original input files remain unchanged. A new
checked seed checkpoint reuses the exact successful prefix in 3.582 seconds;
corrected review data is in separate files, not rewritten history.

Both full bootstrap passes and final ASCENT review then pass: 130.873 native
make / 138.396 bootstrap-stage / 150.220 child whole seconds. Make concurrency
is selected from host capacity, here 12 jobs.

The unchanged compiled stress completes all four files: three pass, TFIB
SIGABRT, zero timeout. Native stage 55.765 seconds, child whole 67.913 seconds.
Interrupt2 passes in 25.842 seconds, but a single pass does not establish a
stable repair or a causal relation to the earlier timeout. This is DENY, not
complete native acceptance. Topology is three shards with three VM processors
and a driver each, selected from 12 available CPUs.

The same pre-store boundary again reads a damaged catalog-member header:
member 1495, index -1368899887, position 9, invalid stored successor equal to
the selected result. Position 9 is in range but disagrees with the observed
catalog position. Membership and integer range alone are not enough. The
first writer/generation remains open. No unchanged retry or release admission
is authorized by these results; milestone remains 5/12.

Portable source, producer, native observations and the exact selection line are
under `evidence/fixtures/darwin-shared-stack-reservation`. The next source audit
must bind a writing or reclamation operation before the damaged header use;
another generic pool/layout change or repeated unchanged stress is not justified.
