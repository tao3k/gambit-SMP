# Verified Generational GC For CakeML (ITP 2017)

Source: [Sandberg Ericsson, Myreen and Aman Pohjola](https://www.cl.cam.ac.uk/~mom22/itp17.pdf).
Reviewed PDF identity: `evidence/papers.lock.json`, `cakeml-verified-gc-2017`.
These are repository-owned analysis notes, not the paper's full text.

## Applicable Evidence Boundary

Separate the collector algorithm from its implementation correspondence.
An abstract invariant is insufficient without the actual object representation,
roots, allocation and generated-code contracts. This lesson guides our evidence
layers; importing CakeML's collector policy is not proposed.

## QNT And Native Acceptance

QNT/TLC supplies explicitly bounded protocol evidence, not an unbounded theorem
or a C implementation proof. Lexical source guards and extracted components are
additional narrow observations. Preserve native regressions, linked artifact
identity, full bootstrap and Gerbil correctness as separate gates. A mock pass
or exhausted finite search must not overwrite a native DENY.

Detailed comparison: [source obligations](../paper-source-obligations.md).
