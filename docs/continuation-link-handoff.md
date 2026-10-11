# Continuation Link Handoff Audit

## New Source Obligation

This extends the publication-granularity model without modifying its owner or
the candidate runtime. Candidate026 `lib/mem.c` has two distinct writers:

- `mark_captured_continuation:3937-3943` installs `cf` into the new frame link,
  retains `ptr` to that field, and later writes `*ptr = forw` on the next frame
  iteration. Completed frame copying does not mean its link has its final value.
- `scan`, case `___sFRAME:4286-4294`, reads the link, temporarily masks a non-end
  FIXNUM link with `___FAL`, calls `mark_frame`, then restores the saved pointer
  with a SUBTYPED tag. This case does not acquire `MISC_MEM_LOCK`.
- The producer holds `MISC_MEM_LOCK`, but that lock alone cannot exclude a
  consumer which does not take it. `end_heap_chunk:3416-3417` still excludes the
  locally scanned chunk; whether the affected frame is in a different eligible
  chunk is a premise to establish in a source-bound native regression.

The model considers an exported frame whose link still refers to a stack frame:
consumer reads the old link, producer installs the forwarding pointer, consumer
restores its saved old pointer. The new forwarding pointer is lost. The model
allows masking between these events; this is separate from queue double-claim.

## Model Boundary

`continuation_link_handoff.qnt` contains one producer, one consumer and one link
under sequential consistency. The consumer's mark work is abstracted. Two
negative controls check consumption before link readiness and lost final
updates. The fixed contract forbids publication until the producer's final link
write is complete and checks safety plus explicit progress.

This is an abstract sufficient condition, not a patch prescribing indefinite
buffering of whole continuations. An implementation might establish equivalent
consumer exclusion or a different stable-link representation. Its resource,
deadlock and nested-call properties would need separate verification.

The model assumes queue eligibility and the interleaving; it does not prove
native reachability, an actual C data race, or the historical compiler crash's
cause. The current source can publish at msection transitions too, so this is
not evidence that the proposed local-frontier guard introduced the issue.
The stale-frontier observation remains a publication-granularity result.

## Working Session Handoff

Before changing the frontier guard, establish that a thief cannot consume the
unfinished link, or implement and verify the missing producer/consumer handoff.
Bind the first native diagnostic to GC cycle, phase, chunk generation and link
address, with the actual two write sites. Do not hide a stale pointer by accepting
arbitrary to-space inputs, add an unproved global lock, or rerun the unchanged
denied compiler suite to search for this interleaving.

Reuse the local GHC parallel-GC paper section 3.4's private-versus-exported work
distinction; do not transplant its forwarding/copy assumptions to Gambit's frame
representation. Native GC, bootstrap and full Gerbil tests remain open gates.

Manifest: `evidence/continuation-link-model.json`. Run through the existing
`src/gambit_smp/verify_protocols.py` and portable `protocol_evidence.py` publisher.

TLC verification completed: both negative controls produced counterexamples;
the fixed contract exhausted 6 distinct / 7 generated states, queue zero, with
safety and explicit temporal progress checked. Source/model inputs remained
stable. Portable logs, typed traces and receipt are in
`evidence/model-results/continuation-link-model/`. These results are registered
as protocol evidence, not native acceptance.
