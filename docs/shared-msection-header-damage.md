# Shared Msection Header Damage

## Native Discriminator

`darwin-shared-successor-snapshot` completes both bootstrap passes and final
ASCENT review. Its unchanged compiled stress inventory remains DENY: two pass,
TFIB aborts and interrupt2 times out. No runtime or release repair is admitted.

The TFIB record binds PID 23806 and captures before the cursor update:

| Field | Observed value |
| --- | --- |
| Selected successor | `0x6a5e72d09` |
| Predecessor | `0x5fd504008` |
| Address-order catalog member | 1053 |
| Independently loaded stored next | `0x6a5e72d09` |
| Assigned sections | 3588 |
| Catalog section count | 4643 |
| Header index | -44 |
| Header position | -1 |

The independent atomic load agrees with the bad selected successor, and the
predecessor is still present in the current arena catalog. Both header integer
fields are invalid as well. This is stronger than the old post-return cursor
observation: investigating only a corrupted return register or a private pool
link is insufficient. Catalog membership does not prove a live allocation
generation; a stale catalog reference remains a separate possible failure.

Do not infer a Scheme tag class, a particular overwrite instruction, or a
specific thread from these values alone. The source layout puts index/pos,
prev and next immediately before section payload. Growth initializes valid
indices/positions and raw links; contraction updates surviving raw links and
frees tail sections. Payload bounds, first writing access, and retirement while
references remain must now be audited together.

## Model Binding

`shared_msection_header_integrity.qnt` composes the existing stack-ownership
model with distinct allocation-order and address-order metadata. Its native
control imports exactly the observed negative index/position and non-section
successor; it does not manufacture a legal writing action. The positive case
keeps valid header metadata. Both checks pass through Quint and ASCENT.
This observation binding is not a complete GC or source-lifetime proof.

The source-derived copy/retirement contract now checks these premises together:
60 legal states are exhausted without a violation; escaped-range and live-borrower
retirement controls each produce the expected counterexample. Neither unsafe
control is established as a source-reachable native cause. Source audit and
reproduction are in `shared-msection-copy-retirement.md`; the portable model
receipt is `copy-retirement-model-observation.json` in the current evidence
directory. First writer and live generation remain open, not historical gaps.

## Open Chain

The next source-derived candidate is shared-section undo bound restoration;
see `shared-section-undo-bounds.md`. It targets a concrete missing partition
after restoring an old section still used by the current heap. Its model is
prepared but not checked, the runtime is unchanged, and attribution to this
captured header damage remains unproved. This is a pending candidate, not a
closed first-writer requirement or native acceptance.

- First header write or reclamation/reuse event remains unbound.
- Identify whether the section was assigned as stack or heap when damaged.
- Check frame/object copy and saved-pointer ranges before administrative words.
- Bind growth/contraction barriers and borrower lifetime, not membership alone.
- Retain interrupt2 as a separate timeout; no shared cause has been proved.

The exact source, native record and model bindings are versioned under
`evidence/fixtures/darwin-shared-successor-snapshot`; cached build trees are not
the evidence identity. No unchanged pressure-test retry is admitted. Milestone
remains 5/12.
