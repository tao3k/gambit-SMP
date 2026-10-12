# Sealed Runtime Review Handoff

## Source-Grounded Gap

`src/gambit_smp/recipes.py`, `Context.artifact`, admits only a PASS producer
in the current execution graph and rechecks the descriptor's content identity.
`src/gambit_smp/research_kernel.py`, `run_sealed`, binds previous observations
and disallows budget expansion or unchanged failed retries. It does not resume
previous PASS steps. These are existing safeguards, not bugs to bypass.

The thread-completion source-core build has a real PASS producer, but a later
typed suite requires review of its generated runtime identity. Importing an
archived binary, predicting its hash or fabricating a PASS step is not a valid
handoff. A generic checked continuation remains an OPEN framework obligation.

## QNT Projection

`models/gambit/sealed_runtime_review_handoff.qnt` models admission, not GC.
Six equality tokens represent source, engine, tool, test fixture, failure
inventory and runtime identity. Review freezes their exact tuple; changes in
any component must invalidate the old review. Producer qualification is a
separate precondition and cannot be inferred from review success.

The ghost `actualSpent` records cumulative work. Resetting the visible budget
at a handoff must not make an otherwise exhausted campaign executable. Three
abstract cost units are a finite exploration domain, not seconds, CPU counts
or proposed production budgets. Production continuation must retain its
original absolute deadline and step budgets, including build and review time.

Negative initializations permit unqualified producers, stale identity reuse
or accounting reset. These controls must produce violations before this model
can be registered as checked evidence. Parsing or simulation alone is not
exhaustive verification. The progress obligation is conditional: a continuously
eligible launch eventually executes under weak fairness. Identity drift or
budget exhaustion may remove eligibility. Reaching eligibility, availability
of review, real elapsed-time progress and source refinement are not proved.

Local diagnostic `quint test` passed all four runs: a real permitted handoff
(preventing a vacuous always-deny model), unqualified producer rejection,
stale identity violation and exhausted-budget reset violation. The stale
identity run used 10,000 samples; this is not exhaustive exploration of all
six identity components. An initial test expression mistakenly used `s.safe`
instead of the module-level `safe`; typechecking rejected it before execution.
The corrected tests exited zero. These observations are not sealed receipts
and are not registered in the shared admission graph. Exhaustive verification
must use the existing driver after the owner's current CPU window closes.

## Required Implementation Contract

A continuation must preserve the sealed engine, immutable recipe/input and
tool identities, actual producer receipt and typed artifacts. It must recheck
artifact contents, scope the review to the observed current campaign and
retain concrete historical failures. A source or tool change creates a new
candidate requiring review; it cannot silently reuse the old admission.

No framework implementation or native suite admission follows from this
design asset. The complete 25-file thread suite, stress tests, GC composition,
bootstrap, Gerbil correctness/performance and Lean qualification remain OPEN.
