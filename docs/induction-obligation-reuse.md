# Induction Obligation Reuse

`induction_reuse.py` is a shared archive validator/composer, not a GC executor
or a feature-specific test script. It does not rerun completed obligations.

The source-wait composition verifies:

- Stable archived receipts, model snapshots and successful original logs.
- Exact source identity of all baseline model dependencies.
- Identity of complete shared parse-IR modules, ignoring only parser IDs.
- Preservation of their imported declaration scopes, with no shadowing.
- Matching induction initializer, invariant, action and obligation length.
- Initial inclusion for the target relation and an identical safety predicate.
- Cartesian generator conformance through the existing fail-closed IR audit.
- A unique obligation for every branch of the actual full transition relation.

The new receipt records 20 reused branch obligations, two new branch checks,
the target initial-state check and the reused safety implication. The old
receipts remain unchanged; the complete-state reachability timeout remains
incomplete. Changing current source bytes, shared declarations or archived
logs prevents reuse. The certificate binds its interpreter and all checked
archive inputs; later changes require revalidation.

## Proof Boundary

[`gc-source-wait-composed-obligations/receipt.json`](../evidence/model-results/gc-source-wait-composed-obligations/receipt.json)
reports `symbolicObligationsComplete=true`. It deliberately retains
`accepted=false`, `inductiveSafetyAdmitted=false`, `solverCoverageProved=false`
and no temporal/runtime/release admission. This is structural composition of
bounded symbolic evidence under the existing Cartesian generator trusted
rule, not a solver proof of the evidence interpreter or C refinement.

Successful native primitives, coherent memory, the finite four-role/four-object
graph and single phase remain assumptions. None of them follows from reusing
the symbolic checks. Full native GC, lifecycle, bootstrap and Gerbil acceptance
are separate Requirements in Reflection.

The composer is deliberately narrow: wrapped/ghost actions need a separate
refinement contract; altered helper predicates, domains or safety goals cannot
inherit the old result merely because an action name matches.

## Reproduce

```sh
python -m gambit_smp.induction_reuse \
  --baseline evidence/model-results/gc-induction-cartesian-contract-ir/receipt.json \
  --delta evidence/model-results/gc-source-wait-new-action-induction/receipt.json \
  --manifest evidence/gc-source-wait-induction.json \
  --out .data/gc-source-wait-composition-reproduction
```

This only reads versioned source/archives and writes a fresh output directory;
no disposable build source or external compiler runtime is required.
