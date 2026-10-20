# Source-block evidence through the existing Trajectory

Status: byte-reference transport and native Clue integration implemented;
real Repair/Agent qualification remains separate. This document does not admit
a native repair or certify a complete C dependency extractor.

## Reuse the existing engine

The locked ASCENT revision is `e119827e588ea7b6d8a3195ac8e0ee8f61de6c11`.
Additional proof-only source-summary and carrier laws are maintained in ASCENT
PR #1; this does not relabel the installed runtime dependency or its native
qualification as a newer proof-source revision.
Its `packages/proofs/lean/SourceCertificates.lean` already defines the required
conditional dependency argument: `resultObligation` requires semantic locality;
`reuse_after_batch` preserves a certificate after disjoint updates;
`pending_after_batch` identifies affected obligations; `close_after_batch`
requires their discharge. This does not prove a C dependency extractor complete.

Clue `slices.rs` already retains prior items across a source change when its
read contract still agrees, then derives a refresh rather than clearing every
read hint. Reuse this, the Scheme set-difference rules, Session and the existing
registration system. Do not introduce another reader, checkpoint, workflow or
Python C/Scheme parser.

The downstream `trajectory-review.ss` already distinguishes observed repetition,
intentional replication, changed premises and unknown comparisons. Repeated
reading is not automatically an invalid investigation. Inspect public tools,
results and source changes, not private model reasoning.

## The atomic object is a conditional claim

Neither an entire header nor an arbitrary fixed-size chunk is a knowledge unit.
A useful unit connects these independently verifiable facets:

| Facet | Contract |
| --- | --- |
| Origin | Pinned source revision plus overlay; generated headers additionally name their configuration/producer inputs |
| Location | Macro, function or declaration and checked byte span; line numbers are navigation, not identity |
| Content | Actual source bytes and content digest, not an Agent-written claim that a file was read |
| Conditions | Relevant configuration, representation, target and ABI premises; missing premises remain unknown |
| Footprint | All source/configuration facts needed by this particular conclusion, with an explicit scoped completeness witness |
| Knowledge | Claim, support, counterevidence, derivation and unresolved references, separate from raw source bytes |

For example, an object's representation macro, a processor-access macro, and a
root-liveness assertion are different units even when they share `gambit.h`.
Two equal macro bodies in different generated images are not automatically the
same observation. Equal bytes do not establish equal configuration or ownership.

A source byte projection attests only byte origin. It cannot promote a comment,
source interpretation or model assumption into a runtime fact. In particular,
reading a block, verifying its byte identity, reviewing its meaning and admitting
a native repair remain distinct events.

## Registration and query path

1. A source observation uses the existing generic host byte/provenance facilities.
   `source.project` already verifies declared disjoint byte ranges. A proposed
   range is not a complete semantic footprint or a verified macro expansion.
2. The downstream Scheme declaration links the unit to symbols, representation
   premises, supported conclusions, counterevidence and neighboring units through
   the existing `clue`, `factor` and `link` relations. These are domain data, not
   Python branches or an upstream hardcoded Gambit navigator.
3. A normal factor/scope query returns applicable knowledge first, with compact
   source references, missing conditions and explicit expansions. Source text
   remains available through caller-selected expansion; no fixed investigation
   order, preferred hypothesis or source-read prohibition is added.
4. Session/checkpoint acknowledges displayed evidence identities, not that an
   Agent understood a conclusion. Unchanged acknowledged units need not be
   displayed again; additions, withdrawals and changed conditions remain visible.
5. A subsequent Agent interpretation can add a reviewed hypothesis or new source
   relation through the same DSL. It cannot issue its own host byte attestation.

The existing view reference accepts optional `ranges`, each containing zero-based
`start`, exclusive `end` and the SHA-256 of those exact bytes. The reference's
ordinary `sha256` still binds the entire current input file. Both Recipe
`source.project` and references call the same byte checker. Overlap, wrong hashes,
out-of-file spans and mixing a byte projection with a JSON pointer are rejected.

Optional `context` names other checked references (for example a configuration
or a source lock). Cycles and unknown references are rejected. The block witness
binds the source path, origin, exact ranges and context identities. It deliberately
does not incorporate unrelated enclosing file bytes: changing those bytes still
requires a reviewed whole-file reference update, but need not re-display an
unchanged acknowledged block. Moving a span changes this conservative identity;
there is no heuristic locator or implicit equivalence decision.

`{"references": true}` supplies the host-checked label and digest to the existing
Scheme reference relation. `{"reference": "ID", "field": "text"}` supplies the
checked UTF-8 excerpt, without parsing C. The same host observation supplies the
native Clue exchange's attestation map. An Agent-written digest/factor does not.
No new CLI, Session, checkpoint or navigation policy is involved.

An empty context is legal byte provenance, not a semantic completeness witness.
The registered `source-byte-clues.view.json` exposes baseline msection definitions,
their actual setup/resize callers, allocation and representation macros, and the
configure pointer-width probe, with explicit unknown active configuration/VM scope;
it cannot establish an observed native address or current candidate equivalence.

## Applicability and invalidation

A reusable conclusion requires current origin/content, satisfied conditions and
agreement on a complete dependency footprint. Absence of a registered dependency
is not a witness of independence. A justified empty footprint is legal; an empty
list without a scoped witness is unknown.

An unrelated edit may preserve a conclusion only when its locality/footprint
premise holds. An unchanged block whose macro definitions, caller ownership or
build condition changed must be reconsidered. A whole-file digest remains a safe
conservative fallback until finer correspondence is verified; it is not a reason
to claim selective invalidation already works.

Moved line numbers do not establish a changed conclusion. Conversely, matching
text at two anchors does not authorize choosing either occurrence. An ambiguous
locator needs an explicit source resolution. Concurrent edits reject an unstable
observation window rather than mixing source generations.

Cache removal changes artifact availability, not historical completion or native
milestones. Runtime logs, generated source products, tool transcripts and their
derived statistics stay in Cache. Git maintains source declarations, replay
Recipes and validation contracts. Redaction alone does not make a run reproducible.

## Context compaction and retained understanding

A displayed byte block is not an Agent understanding. `understanding` records in
the existing Scheme view retain a concise interpretation, the raw block reference
and the exact digest reviewed when that interpretation was written. That reviewed
digest is a literal historical basis, not a reference that silently follows edits.
The summary may state assumptions, limitations and open references. It remains a
`hypothesis`, never a host-attested semantic or native claim.

The Scheme projection compares the recorded basis with the current checked block
identity. It exposes `reviewed-bytes-current` or `changed-or-unavailable-review`;
the old interpretation is retained in either case. A block or declared context
change reopens the summary in the existing Clue delta rather than silently
reissuing it as current understanding. This comparison establishes source
correspondence only: undeclared semantic dependencies remain an open obligation.

After context compaction a caller can query the summary claim or explicitly expand
its reference to the raw block. Omitting a read checkpoint requests a fresh recap;
supplying it requests continuation. Neither a retained read hint nor a current
summary proves the model remembers or agrees with the interpretation. Intentional
rereading remains available; no frequency quota or investigation blacklist is used.

## Impact radius is a dependency closure, not a line window

`impact_node` binds a reviewed source/configuration node to its checked reference.
`impact_dependency(consumer, dependency, kind)` records caller, definition,
representation, configuration or validation relationships chosen by the domain
author. The same Scheme projection derives `impact_path` transitively and
`impact_affected(consumer, origin)` from actually changed node identities. There
is no hardcoded hop radius, preferred direction or limit on new hypotheses.

The known radius must not be mistaken for a complete radius. A node needs an
`impact_declaration` with its scoped edge count and an `impact_witness` bound to
the reviewed scope document's bytes. The engine checks the registered count,
the current witness and the presence of each dependency node. A justified
zero-edge leaf is legal. A missing declaration, changed witness, count mismatch
or unregistered dependency produces `impact_boundary`; `impact_unresolved`
propagates that boundary to dependent summaries. These are explicit author
claims of scope, not a proof that all C callers/macros have been discovered.

`summary_reusable` therefore means only: its reviewed bytes agree, no declared
dependency change reaches it, and no unresolved declared boundary reaches it.
It is a conditional source-scope result, not semantic correctness or native
acceptance. The three output classes remain distinct: known affected, current
under the declared footprint, and unknown radius. The maintained msection
allocation summary exposes unknown impact scope at the active-configuration
boundary; the word-unit and literal-definition scopes remain distinct. None is
promoted to native support merely because its byte checks pass.

The executable integration control changes a two-edge configuration dependency
while leaving the summarized block's own bytes unchanged. It verifies that the
summary reappears with its impact origin, and that removing an intermediate
scope witness prevents reuse even with no observed byte changes. Existing
ASCENT `SourceCertificates.lean` supplies the conditional locality/dependency
argument. Existing `SourceUpdateFrame.lean` additionally covers transitive
summary invalidation, unknown scopes and disjoint-change preservation;
`ClueQueryResume.qnt` covers their composition with interruption and retained
understanding. Native extraction completeness is not claimed by these controls.

## Implementation and acceptance obligations

| Obligation | Existing owner / missing integration |
| --- | --- |
| Current byte observation | Host source capabilities; connect verified spans/configuration to the registered projection |
| Semantic dependency scope | Downstream Scheme; provide the completeness/locality premises, including callers and macro/configuration dependencies |
| Scoped selection and continuation | ASCENT Clue exchange and Session; retain current read-contract semantics |
| Repetition classification | Existing downstream trajectory review; distinguish unknown purpose from intentional replication |
| Mathematical conditions | Extend existing source-certificate, source-update-frame and Clue-resume controls only for a genuinely uncovered composition |
| Real usefulness | A resumed Repair investigation must consume the relevant reusable unit, expose missing premises and add discriminating evidence or a justified source repair |

The same controls must cover unchanged continuation, a disjoint source update,
an affected transitive dependency, a changed preprocessor configuration, equal
bytes from a foreign origin, an incomplete footprint, a new counterexample,
ambiguous/moved source anchors, process restart and cache deletion. An unknown
symbol must remain queryable and expandable. Deliberate rereading and competing
hypotheses remain permitted.

Use the maintained public arithmetic counterexample in
`trajectory-public-quality-audit.md` as one replayable integration example:
combine the msection's word unit, pointer element type and allocation expression
under an explicit word-width premise. The formula can rebut an address
reconstruction without proving that either address was observed natively. Keep
the real ownership/join and GC obligations separate from that illustration.

A lower read count is not sufficient acceptance. Measure duplicate returned
observations separately from overlapping source windows, missing-condition
discovery, corrections, useful new evidence and native gate closure. No fixed
number of calls or elapsed minutes defines an invalid reasoning path.

Pagination completion is conditional on finite unchanged inputs and adequate
capacity for each indivisible evidence unit and its references. Repeating an
undersized page can legitimately retain the same checkpoint: no body was shown,
so no read may be acknowledged. The caller may expand a reference, change its
query or increase presentation capacity; none restricts inference or exploration.
The framework regression corpus tests both eventual complete, non-repeating
delivery under the fitting premise and honest deferral without it. It does not
assume an ever-growing repository can be fully paged at one fixed capacity.
An inactivity termination retains a partial failure; it is not a deadlock proof.
Observed test exceptions must be flushed before suite finalization so a later
interruption cannot erase their causes. Runtime qualification remains separate.

## Unbound discovery is not an evidence hit

An explicit `((bindings ()))` request reaches the registered Scheme association.
The SMP declaration returns `unbound_scope` and observed factor names through
the existing association results, without selecting claims or raw source bodies.
An absent request remains an input error. Python distinguishes field presence
from truthiness and transports the declaration; it does not choose factors,
expand the scope or implement the relation rules. Other applications can supply
their own association policy.

The existing ASCENT `AnchoredEvidenceSlice` QNT/Lean models distinguish this
discovery branch from a conjunctive evidence match. Empty anchors do not select
every witness, discovered names have a source witness, and discovery grants no
action or closed exploration space. Real-source controls continue from unbound
metadata to the same-witness `entity=msection` relation and test CLI restart,
macro-change invalidation and disjoint-edit preservation separately. These are
not guarantees that a probabilistic Agent will choose the best query.

## The receiving carrier is part of presentation

Library rendering and terminal delivery are distinct observations. A complete
Library packet can still be clipped by a provider while its checkpoint survives
in the visible tail. Provider completion therefore does not qualify delivery.
The existing launch receipt records public terminal byte counts and truncation
flags separately, without inspecting private reasoning or assigning query intent.
Provider-owned attempt logs and receipts are not writable Agent scratch.

`Launch.read_window_bytes` configures the complete UTF-8 stdout window. Its
default reuses the Library's existing display capacity. The task passes this
capacity through `GAMBIT_SMP_CLUE_WIRE_BYTES`; this is a transport observation,
not another query endpoint or a scope/iteration limit. The CLI uses the existing
native folding operation until the entire serialized carrier, including host
metadata and checkpoint, fits. A tighter retry starts from the original hint,
strictly decreases its rendering budget and rejects a changed source generation.
It never slices serialized Scheme or reports hidden content as absent. An
insufficient header window fails explicitly. Unpublished trial hints are Cache,
not evidence, delivery confirmation or execution progress.

The existing content-addressed hint cache binds a bounded-frame observation to
the native hint, including the UTF-8 byte count and configured window. It does
not grant evidence or execution authority. In a bounded carrier, an old hint
without that observation is `delivery-unverified`: replay read confirmations
from the existing native fallback, without deleting source evidence, history or
execution milestones. Confirmed hints continue through the same Session path.
This conservative recovery is necessary when an older terminal displayed only
the beginning and end of a larger response.

The bound assumes a calibrated receiving capacity. Each real provider run must
still inspect its actual truncation observations; a successful end-turn is not
proof of that assumption. Source selection, inference and arbitrary reference
expansion remain in ASCENT. The existing `AnchoredEvidenceSlice` QNT/Lean model
adds this carrier composition and the acknowledgement-before-delivery failure;
it does not prove that an LLM understands a displayed fact.
