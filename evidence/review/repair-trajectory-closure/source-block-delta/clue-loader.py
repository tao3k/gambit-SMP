"""SMP projection into the upstream, non-authorizing Trajectory exploration API."""
import argparse
from collections.abc import Sequence
import json
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import (append_trajectory_attempt, canonical,
                                          fingerprint, read_trajectory_attempts,
                                          append_trajectory_clues, read_trajectory_clues)


def _current(snapshot):
    if snapshot.get("executionAuthorized") is not False:
        raise ValueError("recorded-only action snapshot required")
    for path, sha in snapshot["inputs"].items():
        if digest(Path(path)) != sha:
            raise ValueError("trajectory action source changed: " + path)


def candidate(snapshot, action_id, *, check_current=True):
    """Map a discovered SMP action to opaque, source-bound upstream identities."""
    if check_current:
        _current(snapshot)
    actions = [action for action in snapshot["actions"] if action["id"] == action_id]
    if len(actions) != 1:
        raise ValueError("unique discovered action required")
    action = actions[0]
    scope = action.get("study") or action.get("view") or action.get("scope")
    operation = action.get("operation") or ("recipe:" + action["recipe"]
                                            if action.get("recipe") else None)
    if not isinstance(scope, str) or not scope or not isinstance(operation, str):
        raise ValueError("discovered action lacks a stable scope or operation")
    result = dict(questionIdentity=action["id"], scopeIdentity=scope,
                  operationIdentity=operation,
                  inputIdentity=snapshot["sourceIdentity"],
                  toolIdentity=fingerprint(snapshot["backend"]))
    if snapshot.get("engine") is not None:
        result["modelIdentity"] = fingerprint(snapshot["engine"])
    elif snapshot.get("context") is not None and snapshot.get("evidenceViews") is not None:
        result["modelIdentity"] = fingerprint({"context": snapshot["context"],
                                               "evidenceViews": snapshot["evidenceViews"]})
    if action.get("hypothesis", "none") != "none":
        result["proposalIdentity"] = action["hypothesis"]
    return result


def record(root, scope, snapshot, action_id, handle, *, purpose=None):
    """Retain an existing action request and outcome; never launch an action."""
    from gambit_smp.research_actions import observe

    observed = observe(root, handle)
    request = observed["request"]
    if (request["action"] != action_id or request["sourceIdentity"] != snapshot["sourceIdentity"]
            or request["revision"] != snapshot["revision"] or request["authorization"] is not True):
        raise ValueError("observed action differs from selected source and request")
    proposed = candidate(snapshot, action_id, check_current=False)
    result = observed["result"]
    retained_result = {key: value for key, value in result.items() if key != "inspection"}
    proof = dict(handle=handle, status=result["status"],
                 outcome=result.get("outcome", result["status"]),
                 resultIdentity=fingerprint(retained_result))
    return append_trajectory_attempt(root, scope, snapshot["sourceIdentity"],
                                     proposed, observation=proof,
                                     snapshot_identity=fingerprint(snapshot), purpose=purpose)


def _replay(root, scope, snapshot, engine, *, through=None, proposed=None):
    """Read one retained prefix into a short-lived upstream ledger."""
    from ascent.trajectory import Trajectory

    retained = read_trajectory_attempts(root, scope)
    if through is not None:
        matches = [index for index, event in enumerate(retained) if event["id"] == through]
        if len(matches) != 1:
            raise ValueError("trajectory prefix endpoint must name one retained attempt")
        retained = retained[:matches[0] + 1]
        if retained[-1].get("snapshotIdentity") != fingerprint(snapshot):
            raise ValueError("trajectory prefix snapshot identity mismatch")
    source = retained[0]["sourceIdentity"] if retained else snapshot["sourceIdentity"]
    with Trajectory(engine, scope, source) as trajectory:
        for event in retained:
            if event["sourceIdentity"] != trajectory.source_identity:
                trajectory.invalidate(event["sourceIdentity"])
            fields = dict(event["candidate"])
            if event["purpose"] is not None:
                fields["purpose"] = event["purpose"]
            trajectory.append("attempt", event_id=event["id"], **fields)
        if snapshot["sourceIdentity"] != trajectory.source_identity:
            trajectory.invalidate(snapshot["sourceIdentity"])
        packet = trajectory.context() if proposed is None else trajectory.explore(proposed)
    return packet, retained


def _view_inventory(snapshot):
    return [dict(id=view["id"], path=view["path"], queries=view["queries"],
                 rows={name: len(rows) for name, rows in view["answers"].items()})
            for view in snapshot.get("evidenceViews", ())]


def context(root, scope, snapshot, engine, *, through=None):
    """Expose retained observations before selecting any action or hypothesis."""
    _current(snapshot)
    packet, retained = _replay(root, scope, snapshot, engine, through=through)
    _current(snapshot)
    return dict(packet, historyThrough=through, replayedAttempts=len(retained),
                clueJournal=clue_journal(root, scope),
                scope=scope, repositoryEvidence=_view_inventory(snapshot),
                openPredictions=snapshot["research"]["openPredictions"],
                discriminators=snapshot["research"]["discriminators"],
                executionAuthorized=False, runtimeAdmitted=False)


def inspect(root, scope, snapshot, action_id, engine, *, through=None):
    """Compare a chosen candidate with durable attempts; never choose it."""
    from gambit_smp.ascent_program import load_component_catalog, query
    from gambit_smp.framework import ROOT

    proposed = candidate(snapshot, action_id)
    packet, retained = _replay(root, scope, snapshot, engine,
                               through=through, proposed=proposed)
    catalog = load_component_catalog(
        ROOT / "evidence/dsl/trajectory-review.components.json",
        entry="trajectory-review", constructor="make-trajectory-review", trusted=True)
    facts = {
        "comparison": [(row["earlierEvent"], row["relation"])
                       for row in packet["comparisons"]],
        "attempt": [(event["id"], ordinal, event["observation"]["status"],
                     event["observation"]["outcome"], event["purpose"] or "")
                    for ordinal, event in enumerate(retained)],
    }
    review = query(facts, catalog, {
        "repeatedObservation": "repeated_observation",
        "repeatCandidates": "repeat_candidate",
        "intentionalReplication": "intentional_replication",
        "comparisonUnknown": "comparison_unknown",
        "changedPremise": "changed_premise",
        "historical": "historical",
    }, engine=engine)
    _current(snapshot)
    action = next(action for action in snapshot["actions"] if action["id"] == action_id)
    return dict(packet, action=action_id, historyThrough=through,
                replayedAttempts=len(retained),
                openPredictions=snapshot["research"]["openPredictions"],
                discriminators=snapshot["research"]["discriminators"],
                sameInputFailures=action["explanation"]["sameInputFailures"],
                review=review,
                executionAuthorized=False, runtimeAdmitted=False)


def _declaration(root, snapshot, view_path):
    """Bind bytes and host references; all projection and query logic is upstream."""
    from gambit_smp.evidence_views import load

    retained = [view for view in snapshot.get("evidenceViews", ()) if view["path"] == view_path]
    document, facts, catalog, inputs = load(root, view_path)
    if len(retained) != 1 or inputs != retained[0]["inputs"]:
        raise ValueError("Evidence view differs from discovery")
    spec = catalog["nativeComponents"]
    return document, facts, list(spec["sources"].values()), inputs


def _native_exchange(root, snapshot, engine):
    from ascent.trajectory import ClueExchange

    _current(snapshot)
    owner = None
    for retained in snapshot.get("evidenceViews", ()):
        if not {"clue", "factor", "link"}.issubset(retained["queries"]):
            continue
        document, facts, sources, inputs = _declaration(root, snapshot, retained["path"])
        attestations = {str(Path(path).relative_to(Path(root).resolve())): sha
                        for path, sha in inputs.items()}
        if owner is None:
            owner = ClueExchange(engine, sources, document["constructor"], facts, attestations)
        else:
            owner.include(engine, sources, document["constructor"], facts, attestations)
    if owner is None:
        raise ValueError("context has no declarative Clue projection; use its declared View queries")
    _current(snapshot)
    return owner


def read_view(root, snapshot, view_id, query_name, engine):
    """Read a declared relation directly, without fabricating an observed Clue."""
    from gambit_smp.evidence_views import evaluate

    _current(snapshot)
    matches = [view for view in snapshot.get("evidenceViews", ())
               if view["id"] == view_id and query_name in view["queries"]]
    if len(matches) != 1:
        raise ValueError("declared Evidence view query required")
    retained = matches[0]
    current = evaluate(root, retained["path"], engine)
    if current["inputs"] != retained["inputs"] or current["answers"] != retained["answers"]:
        raise ValueError("Evidence view changed since discovery")
    _current(snapshot)
    return dict(view=view_id, query=query_name, answers=current["answers"][query_name],
                contextIdentity=snapshot["sourceIdentity"],
                sourceInputs={str(Path(path).relative_to(Path(root).resolve())): sha
                              for path, sha in current["inputs"].items()},
                executionAuthorized=False, runtimeAdmitted=False)


def clue_journal(root, scope):
    retained, prefix = read_trajectory_clues(root, scope)
    return dict(prefix=prefix, submissions=len(retained),
                retainedClues=sum(len(row["clues"]) for row in retained))


def submit(root, scope, snapshot, rows, expected_prefix):
    """Retain Agent hypotheses; a source reference alone supplies no attestation."""
    _current(snapshot)
    from gambit_smp.ascent_program import engine_api

    with engine_api() as (engine, _):
        _native_exchange(root, snapshot, engine).submit(rows)
    result = append_trajectory_clues(root, scope, snapshot["sourceIdentity"],
                                    list(rows), expected_prefix)
    _current(snapshot)
    return dict(result, contextIdentity=snapshot["sourceIdentity"],
                executionAuthorized=False, runtimeAdmitted=False)


def clues(root, scope, snapshot, question, engine, *, proposed=(), bindings=(),
          compact=False, expansions=(), checkpoint=None, display_bytes=8192,
          selector=None, constructor="query"):
    """Transport declarations, retained hypotheses and requests to the native Library."""
    owner = _native_exchange(root, snapshot, engine)
    submissions, prefix = read_trajectory_clues(root, scope) if scope is not None else ([], None)
    retained, historical = [], []
    for batch in submissions:
        if batch["sourceIdentity"] == snapshot["sourceIdentity"]:
            retained.extend(batch["clues"])
        else:
            historical.extend(row["id"] for row in batch["clues"])
    owner.submit([*retained, *proposed])
    if bindings or selector is not None:
        if selector is not None:
            sources = [selector]
        else:
            navigator = snapshot.get("context", {}).get("navigator")
            if navigator is None:
                raise ValueError("factor reads require a caller-declared navigator")
            document, _, sources, _ = _declaration(root, snapshot, navigator)
            constructor = document["constructor"]
        if compact:
            request = dict(bindings=list(bindings), expand=list(expansions), displayBytes=display_bytes)
            if checkpoint is not None:
                request["checkpoint"] = checkpoint
            result = owner.slice_selected(sources, constructor, request)
        else:
            result = owner.read_selected(sources, constructor, list(bindings))
    else:
        if compact:
            request = dict(questions=[question] if question else [], expand=list(expansions),
                           displayBytes=display_bytes)
            if checkpoint is not None:
                request["checkpoint"] = checkpoint
            result = owner.slice(request)
        else:
            result = owner.read([question])
    _current(snapshot)
    if compact:
        result["brief"].update(contextIdentity=snapshot["sourceIdentity"],
                               historyIncluded=scope is not None,
                               historicalClues=historical)
        return result
    return dict(result, contextIdentity=snapshot["sourceIdentity"],
                scope=scope, historyIncluded=scope is not None,
                clueJournal=dict(prefix=prefix, submissions=len(submissions),
                                 retainedClues=sum(len(row["clues"]) for row in submissions)),
                historicalClues=historical)


def _repository_snapshot(root):
    """Bind the current registry for both discovery and evidence reads."""
    from gambit_smp.evidence_views import registry, load
    from gambit_smp.recipes import source_path

    names, inputs = registry(root)
    views = []
    for name in names:
        path = source_path(root, name)
        identity = digest(path)
        document = json.loads(path.read_text())
        if not {"clue", "factor", "link"}.issubset(document["queries"]):
            continue
        _, _, _, bound = load(root, name)
        if bound[str(path)] != identity:
            raise ValueError("Evidence declaration changed during query binding")
        inputs.update(bound)
        views.append(dict(id=document["id"], path=name, queries=document["queries"], inputs=bound))
    return dict(evidenceViews=views, inputs=inputs, sourceIdentity=fingerprint(inputs),
                executionAuthorized=False)


def repository_clues(root: str | Path = ".", question: str | Sequence[str] | None = None,
                     engine: object = None, *,
                     bindings: Sequence[tuple[str, str]] | None = None, expansions: Sequence[str] | None = None,
                     checkpoint: object = None, display_bytes: int = 8192,
                     selector: str | None = None, constructor: str = "query") -> dict:
    """Return a source-bound incremental Evidence slice using ASCENT inference.

    The CLI renders this same result directly as inert Scheme data.
    Separate calls start fresh unless checkpoint carries the previous token,
    including when changing selectors or expanding scope. Omission requests replay;
    it is not automatic continuation. This affects display history, not inference.
    Result shape: {"brief": dict, "checkpoint": str}. brief["families"] is a
    LIST of family dictionaries, not a claim-keyed map. Each family has claim
    (str), observations (list[dict]), hypotheses (list[dict]), links (list[dict]),
    reference (dict), conflict (bool), unknown (bool). An observation has id,
    digest, polarity, source, receipt (str) and factors (dict[str, list[str]]).
    brief["deferred"] is a LIST of collapsed family dictionaries with claim,
    counts and reference. brief["counts"] and brief["delta"] are dictionaries
    of integer counts; scopeReference is {"sourceIdentity": str, "claims": list[str]}.
    association, when present, contains caller-named relation row lists and a
    selectorIdentity string. Wide results may instead appear in deferredRelations
    (list[dict] with relation, role, rowCount, reference). retainedRelations has
    the same shape for exact derived results already shown under this checkpoint;
    their bodies are not repeated. A missing inline relation is not an empty result.
    Relation references bind sourceIdentity, selectorIdentity and contentIdentity.
    Repeating the same selector with checkpoint and suitable display_bytes can
    expose deferred details; caller-authored alternative predicates remain allowed.
    Evaluation/presentation/exploration flags are bool. counts describes current
    scope; delta counts library items added/removed/retained relative to the read
    hint, not test cases. presentationComplete means no requested unit remains
    deferred, including derived results; previously shown units need not repeat.
    checkpoint is a short persistent clue-read token, directly reusable across
    Python processes; neither file writes nor native row serialization are needed.

    Registered Evidence relations are already loaded by this operation. A selector
    queries their actual rows: variables can discover claims, factor names and
    values without knowing their identifiers, opening files or selecting a Context.
    The exact-identifier requirement applies to the direct question argument,
    not to variables in selector rules. No natural-language matching is performed.

    root is the checkout path (str or pathlib.Path; '.' in its working directory).
    With engine=None the framework opens, verifies and closes its own engine;
    no backend inventory is part of the response. An explicit engine may be
    yielded by the engine_api() context manager for grouped reads. question is an exact
    claim string, or None with selector. selector is a Scheme source string;
    constructor names its declared constructor (any declared name, default query).
    Sources: clue(id,digest,claim,
    polarity,role,source), factor(id,digest,name,value), link(from,to,label,id,
    digest), attested(id,digest,receipt), binding(name,value). bindings are facts
    supplied as (name, value) string pairs to that declaration, not Python keyword
    matching. With bindings and no selector, the repository's optional registered
    Scheme selection is used; an explicit selector replaces that default.
    expansions is a sequence of arbitrary additional claim strings.

    The Library's (include clue-selection-schema) declares those input schemas
    without adding rules. With it, relation clauses declare only additional
    relations, including question; the caller still declares sources and outputs.
    Explicit input declarations remain supported without this include.

    A complete domain-neutral declaration (caller may change its predicates):
      (define-evidence (query)
        (sources clue attested) (outputs question)
        (include clue-selection-schema)
        (relation question (claim))
        ((question C) <-- (clue I D C _ _ _) (attested I D _)))
    This selects all attested claims, not a recommended investigation scope.
    Restrict, join or expand relations as the investigation requires. Factor
    names and values are queryable cells of factor, not an external vocabulary
    that must be found by file search. Additional outputs can expose association
    witnesses; do not output unrelated source tables merely to copy them.

    Declaration grammar (SOURCE/EXTRA/COLUMN/TERM/NAME are metavariables):
      (define-evidence (NAME) (sources SOURCE ...) (outputs question EXTRA ...)
        (include clue-selection-schema)
        (relation question (claim)) (relation EXTRA (COLUMN ...)) ...
        ((R TERM ...) <-- (R TERM ...) ... ) ...)
    Bare term symbols are variables: repeated symbols join equal cells across
    a rule's body and head. _ is an anonymous wildcard; (lit "text") is a
    string constant. (not (R TERM ...)) is stratified negation with variables
    bound by positive body atoms. Recursive rules use the same relation in a
    head and a body; they must yield a finite fixed point. bindings supplies
    rows of the declared (sources binding) relation, with columns name,value.
    expansions adds exact claims to the resulting read scope, independently of
    selector outputs; it does not add factor bindings or rewrite the selector.
    question(claim) is the
    required output; arbitrary additional trace relations are preserved.
    Its claim is an Evidence identifier, not a natural-language search prompt.
    Unsupported claims remain unknown; literal text does not establish a link
    to existing evidence without a caller-declared relational association.
    Sources are read-only: a rule head cannot name a source relation, including
    an identity rule. A source may be named in outputs without a copying rule.

    Returns a dict with brief (dict) and checkpoint (a small opaque string token).
    The framework stores native read hints in its existing ignored history cache;
    the token works across Python processes. No caller-written checkpoint file
    or raw row serialization is necessary. It is not evidence or execution authority.
    brief contains sourceIdentity, mode, counts, families, deferred, scopeReference
    and expandable source/content-bound references. Passing the prior checkpoint
    unchanged enables incremental reads; None explicitly starts a fresh read.
    Only fully displayed families are acknowledged, even on a folded page.
    A new selector or scope re-evaluates relevance but reuses same-source shown
    families. New sources reset read hints. A missing cached read hint safely replays
    evidence with checkpointStatus=cache-miss, never reporting it absent.
    The default presentation is 8192 bytes. A deferred family already has an
    expansion reference. A wide pending set may instead have deferredScope,
    bound by source/content identity and claimCount, without acknowledging any
    hidden body. A compact scopeReference omits claims only when its header
    otherwise cannot fit. The same selector and checkpoint resume unseen units.
    Deferred summaries retain polarity counts; increasing display_bytes does not
    discover additional evidence. Python string slicing of printed families
    loses traceability, unlike the Library's honest folding. Repeating a read
    with checkpoint=None is an initial read again, not an incremental read.
    display_bytes is presentation capacity, never a search or inference limit.
    No Context, catalog lookup, action choice or execution authority is implied.
    """
    if engine is None:
        from gambit_smp.ascent_program import engine_api

        with engine_api() as (bound_engine, _):
            return repository_clues(root, question, bound_engine, bindings=bindings,
                expansions=expansions, checkpoint=checkpoint, display_bytes=display_bytes,
                selector=selector, constructor=constructor)
    from gambit_smp.recipes import source_path

    root = Path(root).resolve()
    snapshot = _repository_snapshot(root)
    if bindings and selector is None:
        if question:
            raise ValueError("use an exact question or relational bindings, not both")
        document = json.loads((root / "evidence/views.json").read_text())
        selection = document.get("selection")
        if selection is None:
            raise ValueError("bindings require a Scheme selector or registered selection")
        path = source_path(root, selection["source"])
        selector = path.read_text()
        constructor = selection["constructor"]
    owner = _native_exchange(root, snapshot, engine)
    request = dict(displayBytes=display_bytes)
    if expansions is not None:
        request["expand"] = list(expansions)
    cache_miss = False
    if isinstance(checkpoint, str):
        from gambit_smp.reasoning_history import load_clue_checkpoint
        checkpoint = load_clue_checkpoint(root, checkpoint)
        cache_miss = checkpoint is None
    if checkpoint is not None:
        request["checkpoint"] = checkpoint
    elif cache_miss:
        request["checkpoint"] = []
    if selector is not None:
        request["bindings"] = list(bindings or ())
        result = owner.slice_selected([selector], constructor, request)
    else:
        if question is not None:
            request["questions"] = [question] if isinstance(question, str) else list(question)
        result = owner.slice(request)
    _current(snapshot)
    result["brief"]["inputIdentity"] = snapshot["sourceIdentity"]
    if cache_miss:
        result["brief"]["checkpointStatus"] = "cache-miss"
    from gambit_smp.reasoning_history import cache_clue_checkpoint
    result["checkpoint"] = cache_clue_checkpoint(root, result["checkpoint"])
    return result


def catalog(root, context_path=None, *, factor=None):
    """Discover declarations, not investigation directions or admitted evidence."""
    from gambit_smp.recipes import source_path

    root = Path(root).resolve()
    if context_path is None:
        from gambit_smp.ascent_program import engine_api

        snapshot = _repository_snapshot(root)
        pairs = []
        if snapshot["evidenceViews"]:
            with engine_api() as (engine, _):
                pairs = _native_exchange(root, snapshot, engine).inventory()["factors"]
        result = dict(catalogIdentity=snapshot["sourceIdentity"],
                      factorNames=sorted({name for name, _ in pairs}),
                      inventoryComplete=False,
                      clueExchangeAvailable=bool(snapshot["evidenceViews"]),
                      executionAuthorized=False, runtimeAdmitted=False)
        if factor is not None:
            result.update(factor=factor,
                          values=sorted({value for name, value in pairs if name == factor}))
        _current(snapshot)
        return result

    from gambit_smp.ascent_program import engine_api
    from gambit_smp.evidence_views import load

    path = source_path(root, str(context_path))
    identity = digest(path)
    declaration = json.loads(path.read_text())
    inputs = {str(path): identity}
    views, projected = [], []
    for name in declaration["views"]:
        view_path = source_path(root, name)
        view_identity = digest(view_path)
        view = json.loads(view_path.read_text())
        inputs[str(view_path)] = view_identity
        views.append(dict(id=view["id"], path=name, queries=sorted(view["queries"])))
        if {"clue", "factor", "link"}.issubset(view["queries"]):
            _, _, _, source_inputs = load(root, name)
            inputs.update(source_inputs)
            projected.append(dict(path=name, queries=view["queries"], inputs=source_inputs))
    snapshot = dict(context=declaration, evidenceViews=projected, inputs=inputs,
                    executionAuthorized=False)
    inventory = {"factors": []}
    if projected:
        with engine_api() as (engine, _):
            inventory = _native_exchange(root, snapshot, engine).inventory()
    pairs = inventory["factors"]
    result = dict(context=str(path.relative_to(root)), contextSha256=identity,
                  catalogIdentity=fingerprint(inputs), views=views,
                  factorNames=sorted({name for name, _ in pairs}),
                  factors=pairs, inventoryComplete=False,
                  clueExchangeAvailable=bool(projected),
                  executionAuthorized=False, runtimeAdmitted=False)
    if factor is not None:
        result.update(factor=factor, values=sorted({value for name, value in pairs if name == factor}))
    _current(snapshot)
    return result


def argument_parser():
    parser = argparse.ArgumentParser(
        prog="gambit-smp trajectory", description=__doc__,
        epilog="clues reads a Scheme request over registered Evidence. "
               "No flag inventory, catalog or Context selection is required. "
               "context reads retained scoped history only. Reads neither choose nor authorize actions.")
    operations = parser.add_subparsers(dest="operation", required=True)
    parser.set_defaults(execution_policy="task")
    inventory = operations.add_parser("catalog", help="discover current DSL-projected factor names and values",
        description="Read factor names from the current registered Evidence; --factor reads its known values. "
                    "An optional --context restricts discovery to that caller-owned declaration. Inventories are not exhaustive "
                    "and do not restrict new questions or factors.")
    inventory.add_argument("--context", type=Path, help="optional caller-owned Evidence context")
    inventory.add_argument("--factor", help="read known values of this factor, not all evidence")
    inventory.set_defaults(execution_policy="read")
    descriptions = {
        "context": "read scoped retained history (--scope required with --context), not repository Evidence",
        "clues": "query Evidence relations with Scheme/Datalog; return traceable incremental slices",
        "submit": "retain new Agent hypotheses without treating them as observations",
        "record": "retain an already observed action and its outcome; never execute it",
        "inspect": "compare an Agent-selected action with retained attempts; never select it",
    }
    for name, description in descriptions.items():
        operation = operations.add_parser(name, help=description, description=description)
        if name != "clues":
            source = operation.add_mutually_exclusive_group(required=True)
            source.add_argument("--request", type=Path, help="JSON request containing scope, snapshot and operation fields")
            if name in ("context", "submit"):
                source.add_argument("--context", type=Path, help="caller-owned retained-history context")
                operation.add_argument("--scope", help="required with --context; caller-chosen persistent investigation name")
        if name == "clues":
            operation.set_defaults(execution_policy="read")
            operation.formatter_class = argparse.RawDescriptionHelpFormatter
            operation.epilog = """Registered Evidence is already loaded. Supply one inert Scheme association list,
or read it from standard input. Bindings are relational anchors, not keywords:

  ((bindings (("NAME" "VALUE"))))

The registered downstream Scheme association derives the evidence scope.
Include (checkpoint "TOKEN") to reuse displayed evidence across processes and
scope changes. Omission requests a fresh read; it is not automatic continuation.
Include (expand ("CLAIM-OR-REFERENCE")) for arbitrary evidence expansion.
Result: inert Scheme data containing brief evidence and its checkpoint token.

The same request accepts questions, selector, constructor and displayBytes.
questions contains exact claim identifiers, NOT natural-language search terms.
An unknown claim is unresolved, not evidence that the repository lacks facts.
expand opens returned claim/reference identities; an unknown claim's digest is
not a discovered evidence identifier. checkpoint preserves reads, not query fit.

selector is caller-written Scheme/Datalog, replacing the registered association.
Its request value is a Scheme source STRING containing define-evidence, not a
list of rules. Put (include clue-selection-schema) inside that source, not at
request top level. Rules use ((head ...) <-- (body ...) ...), not Prolog :-.
Its variables can discover factor names, values and claims without identifiers:
clue(id,digest,claim,polarity,role,source), factor(id,digest,name,value),
attested(id,digest,receipt), binding(name,value). Join by both id AND digest;
declare sources and outputs, including the question(claim) selection relation.
Use (include clue-selection-schema) for these input relation declarations.
Additional output relations may expose discovery witnesses without selecting
every claim. No keyword or semantic matching is performed. The complete DSL
contract is available with: from gambit_smp import repository_clues; help(repository_clues).
repository_clues is a callable export, not an importable submodule.
Presentation capacity never limits inference or exploration. Only complete shown
units are acknowledged; hidden evidence keeps expandable references. Reads do
not choose actions, close the hypothesis space or grant execution authority.
"""
            operation.add_argument("declaration", nargs="?", default="-",
                                   help="Scheme request; omission or '-' reads standard input")
        if name == "submit":
            operation.epilog = ("Each clue has id, claim, polarity (support/counter), source, and optional "
                "factors as [name,value] pairs. Use clueJournal.prefix from a current context or clues read. "
                "Submissions remain hypotheses; arbitrary new claims and factors are allowed.")
            clues_input = operation.add_mutually_exclusive_group()
            clues_input.add_argument("--clues-file", type=Path, help="JSON list of Agent hypotheses")
            clues_input.add_argument("--clues-json", help="inline JSON hypothesis list")
            operation.add_argument("--expected-prefix", help="clueJournal.prefix from the latest read")
    return parser


def execution_policy(arguments):
    """Parser-owned effects; read hints do not require an execution lease."""
    return argument_parser().parse_args(arguments).execution_policy


def main():
    from gambit_smp.framework import ROOT

    parser = argument_parser()
    args = parser.parse_args()
    if args.operation == "catalog":
        from ascent.trajectory import ClueExchange
        print(ClueExchange.render(catalog(ROOT, args.context, factor=args.factor)))
        return
    if args.operation == "clues":
        from gambit_smp.ascent_program import engine_api
        from ascent.trajectory import ClueExchange
        import sys
        source = sys.stdin.read() if args.declaration == "-" else args.declaration
        request = ClueExchange.parse_request(source)
        if not any(request.get(key) for key in ("bindings", "questions", "selector", "expand", "checkpoint")):
            parser.error("a relational query or resumable checkpoint is required")
        with engine_api() as (engine, _):
            packet = repository_clues(ROOT, request.get("questions"), engine,
                bindings=request.get("bindings"), expansions=request.get("expand"),
                checkpoint=request.get("checkpoint"), display_bytes=request.get("displayBytes", 8192),
                selector=request.get("selector"), constructor=request.get("constructor", "query"))
        print(ClueExchange.render(packet))
        return
    if args.request:
        if any(getattr(args, field, None) for field in (
                "scope", "clues_file", "clues_json", "expected_prefix")):
            parser.error("--request owns all request fields")
        request = json.loads(args.request.read_text())
    else:
        if args.operation not in ("context", "submit") or not args.scope:
            parser.error("context and submit require --scope")
        from gambit_smp.research_actions import discover
        snapshot = discover(ROOT, json.loads(args.context.read_text()))
        request = dict(scope=args.scope, snapshot=snapshot)
        if args.operation == "submit":
            if bool(args.clues_file) == bool(args.clues_json) or args.expected_prefix is None:
                parser.error("submit requires one of --clues-file/--clues-json and --expected-prefix")
            request.update(clues=json.loads(args.clues_file.read_text() if args.clues_file
                                            else args.clues_json),
                           expectedPrefix=args.expected_prefix)
    common = {"scope", "snapshot", "action"}
    if args.operation == "submit":
        if set(request) != {"scope", "snapshot", "clues", "expectedPrefix"}:
            raise ValueError("submit requires scope, snapshot, clues and expectedPrefix")
        result = submit(ROOT, request["scope"], request["snapshot"], request["clues"],
                        request["expectedPrefix"])
    elif args.operation == "record":
        if set(request) not in (common | {"handle"}, common | {"handle", "purpose"}):
            raise ValueError("record requires scope, snapshot, action and observed handle")
        result = record(ROOT, request["scope"], request["snapshot"], request["action"],
                        request["handle"], purpose=request.get("purpose"))
    else:
        required = common if args.operation == "inspect" else {"scope", "snapshot"}
        if set(request) not in (required, required | {"through"}):
            raise ValueError(args.operation + " requires " + ", ".join(sorted(required))
                             + " and optional through")
        from gambit_smp.ascent_program import engine_api

        with engine_api() as (engine, _):
            if args.operation == "context":
                result = context(ROOT, request["scope"], request["snapshot"], engine,
                                 through=request.get("through"))
            elif args.operation == "inspect":
                result = inspect(ROOT, request["scope"], request["snapshot"],
                                 request["action"], engine, through=request.get("through"))
    from ascent.trajectory import ClueExchange
    print(ClueExchange.render(result))



from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('trajectory')(main)

if __name__ == "__main__":
    main()
