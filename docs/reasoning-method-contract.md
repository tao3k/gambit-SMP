# Optional reasoning methods

This is caller-reviewed policy, not checker output or a claim that a particular
method is necessary. All four choices can coexist with source reading, empirical
investigation or an unlisted method. No attempt threshold, ranking, fixed steps,
model-before-code gate or new execution capability is introduced.

## Suitability and limits

- Quint/QNT: investigate protocol transitions, ownership, generations, schedules
  and counterexamples. Declare state/actions, environment and fairness assumptions,
  checked bounds, properties and positive/negative controls. A bounded check or
  simulation is not an unbounded theorem, weak-memory validation or source proof.
- Lean: investigate a precisely stated inductive or refinement theorem when the
  question needs more than finite exploration. Bind definitions, invariants,
  induction/refinement obligations, assumptions and source correspondence. Kernel
  checking establishes the formalized theorem, not that actual Gambit implements
  the abstraction or that its assumptions are true. Lean is not a required next
  stage after QNT; counterexamples or source observations may be more informative.
- Modify existing Evidence DSL: a coherent existing component owns the question
  but lacks a relation, rule, source/result binding or invalidation condition.
  Review its contract, callers, provenance and withdrawal controls. An edit may
  improve explanation without establishing the truth of its input claims.
- Add Evidence DSL component: a separately reusable inference responsibility needs
  a declared input/output contract and composition/source boundaries. This is not
  a reason to duplicate existing rules, create a Python inference engine, or add a
  Library execution capability. Existing and new designs may both be investigated.

Official method references, not runtime dependencies:
https://quint.sh/docs/quint
https://quint.sh/docs/what-does-quint-do
https://lean-lang.org/doc/reference/latest/Elaboration-and-Compilation/

## Real Working questions

The Working chunk review already declares missing allocation generations,
cross-arena aliases, root closure and weak-memory coverage. Its QNT coverage gap
supports considering protocol-model extension, not a source correctness claim.
The existing Working method declaration explicitly raises an optional Lean
root/copy invariant investigation; it is not evidence of an existing theorem.

This change also records a framework design review: modeling-guidance already
owns coverage/refutation/revision windows, so extending its explanation contract
is an option. Method suitability with premise and conclusion-boundary queries is
a separately reusable responsibility (it also applies outside GC), so extracting
a composed Evidence component is another option. Both are reviewed alternatives,
not a claim that either design is uniquely correct. The implemented component is
reasoning-methods; no second Python reasoning implementation is added.

The real view binds the candidate and actual review/model bytes through the
Working view's exact reference pointers. Missing formal premises remain missing;
no fictional proof, runtime receipt, tool installation or authorized run is added.
The source itself records that these are host-reviewed questions and assessments.
Every answer includes the question and policy path/SHA. Reused review references
are recorded-only, not an inherited model PASS. Supported means only that the
declared premise list has bound sources, never that the list is complete or true.

The view is registered for the full graph and included in Working's actual Action
context. Discover/select/observe inspect answers through the existing kernel;
selection still requires host authorization and checks stale snapshot identities.
