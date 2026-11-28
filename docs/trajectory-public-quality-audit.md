# Public Investigation Quality Audit

## Scope

This reviews public reports from Grok session
`4e39e7e0-d707-411b-941e-6b6cd7074507`, not hidden reasoning. Raw session
exports remain disposable cache. This note is a reviewed source-semantics
counterexample, not an accepted Gambit runtime diagnosis.

## Evidence And Error

The initial public report proposed H-residue and reconstructed a to-space
address `0x70004` from stack address `0x80004` by subtracting 65,536 bytes.

Pinned vendor revision: `7c490c3ab5b5a4238b26f4a59d8cd9fd4b085882`.

- `lib/mem.h:20` explicitly gives msection size in words; line 66 defines
  `___MSECTION_SIZE` as 131,072.
- `include/gambit.h.in:11354` and `:11360` declare stack start/limit as
  `___WORD *`.
- `lib/mem.c:3141` computes
  `alloc_stack_start = alloc_stack_limit + (___MSECTION_SIZE >> 1)`.

Under the report's assumed eight-byte word and source formula, the address
increment is `65,536 * 8 = 524,288 = 0x80000` bytes, not `0x10000`.
The corresponding integer subtraction is `0x80004 - 0x80000 = 4`, not
`0x70004`. This refutes that reconstruction under those assumptions.

It does not establish that 4 was an actual selected pointer. Candidate image
layout, generated instruction semantics, register provenance and same-run
binding remain separate requirements. C source arithmetic over an invalid
pointer is not a proof of native execution or its cause.

The report also distinguished the 503-root progress timeout from selected-section
corruption and did not claim either a GC cause or native acceptance. Those
bounded conclusions survive this arithmetic correction. A source-bound
hypothesis must still add a discriminant beyond existing selection-origin and
internal-work/root-progress requirements before being counted as new progress.

## Acceptance Boundary

An independent public self-review, requested without identifying the error,
withdrew the unsupported image/formula reconstruction and several overstrong
causal claims, and corrected a decimal-to-hex conversion. It did not identify
the word-versus-byte scaling error. Preserve both the original report and
that partial correction; public self-review alone did not close this gap.

The ASCENT protocol can preserve this counterexample, its conditions and source
references. It cannot mathematically guarantee a probabilistic Agent will draw
a correct conclusion. Clarification and public review provide a reasonable
calibration window, without a fixed tool sequence, hypothesis ranking or forced
checkpoint reuse. The erroneous report is retained, not rewritten as success.
