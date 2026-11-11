# Debug Metadata Projection Candidate

Grok produced this source delta and finite model during the supervised SMP
investigation. They are retained research, not an integrated runtime fix.
The parent source lock is `darwin-stack-entry-contract` (f0507df3).

The delta projects debug descriptor ids through the final allocated value-label
cells while retaining descriptor definition order. Review replaced repeated
`list-ref` traversal with one vector construction and constant-time lookups;
the callback no longer introduces quadratic compiler metadata work.

The QNT characterization covers all 24 permutations of two visible and two
internal labels, a separate rank specification, metadata lookup ownership and
the old identity-map counterexample. It is not source refinement or proof of
the first header writer. Bootstrap and original native tests remain required.

The public Grok query attempt was rejected before execution; it supplies no
evidence-hit or checkpoint-reuse claim. This candidate must not be counted as
another completed milestone gate.

The existing framework verified the unchanged model with host-derived workers:
the old identity-map control produced the expected invariant violation (exit 1,
2 distinct states); the projected association and temporal check passed (exit 0,
25 distinct states, zero queued). Inputs remained stable. A prior attempt was
rejected while opening the local backend endpoint, before model execution; it
remains retained in cache. These outcomes do not qualify the source candidate.
