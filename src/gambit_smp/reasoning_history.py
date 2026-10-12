"""Immutable observations and independently published ASCENT analyses.

SQLite transports journal entries and performs compare-and-swap; the Evidence
DSL derives deltas and publication eligibility. Neither grants execution rights.
"""
import hashlib
from contextlib import closing, contextmanager
import json
from pathlib import Path
import sqlite3
import uuid

from gambit_smp.ascent_program import engine_api, load_component_catalog, query
from gambit_smp.framework import ROOT, digest, relative

RULES = ROOT / "evidence/dsl/history.ss"
QUERIES = {"added": "added", "removed": "removed", "retained": "retained",
           "changedInputs": "changed_input", "addedInputs": "added_input",
           "removedInputs": "removed_input"}
POLICY_QUERIES = {"eligible": "publishable", "gaps": "publication_gap"}


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True,
                      allow_nan=False)


def fingerprint(value):
    return hashlib.sha256(canonical(value).encode()).hexdigest()


def normalized(results):
    return {name: sorted({canonical(row) for row in rows}) for name, rows in results.items()}


def lineage(workflow, *, task=None, branch="workspace", selection="all", policy="default"):
    """Caller-owned lineage, independent of inventory and source revisions.

    The database root isolates workspaces. Callers name branches explicitly when
    sharing that database; 'workspace' does not claim Git branch detection.
    """
    return workflow + ":" + fingerprint(dict(task=task, branch=branch,
                                              selection=selection, policy=policy))


@contextmanager
def _database(root):
    path = Path(root) / ".data/reasoning/history.sqlite3"
    path.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(path, isolation_level=None)) as db:
        version = db.execute("PRAGMA user_version").fetchone()[0]
        if version not in (0, 1):
            raise ValueError("unknown history database schema version")
        if version == 0:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("CREATE TABLE IF NOT EXISTS observations (id TEXT PRIMARY KEY, body TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS heads (scope TEXT PRIMARY KEY, id TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS observation_events (id TEXT PRIMARY KEY, body TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS lineages (scope TEXT PRIMARY KEY, body TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS analysis_requests (id TEXT PRIMARY KEY, body TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS analysis_results (attempt TEXT PRIMARY KEY, id TEXT NOT NULL, body TEXT NOT NULL)")
                db.execute("CREATE TABLE IF NOT EXISTS head_analyses (scope TEXT PRIMARY KEY, attempt TEXT NOT NULL)")
                db.execute("PRAGMA user_version=1")
                db.commit()
            except BaseException:
                db.rollback()
                raise
        yield db


def _head(db, scope):
    row = db.execute("SELECT id FROM heads WHERE scope=?", (scope,)).fetchone()
    return row[0] if row else None


def _head_analysis(db, scope):
    row = db.execute("SELECT attempt FROM head_analyses WHERE scope=?", (scope,)).fetchone()
    return row[0] if row else None


def _observation(db, identity):
    row = db.execute("SELECT body FROM observations WHERE id=?", (identity,)).fetchone()
    if row is None:
        raise ValueError("missing historical observation")
    body = json.loads(row[0])
    if fingerprint(body) != identity or body.get("schema") not in (
            "gambit-reasoning-observation.v1", "gambit-reasoning-observation.v2"):
        raise ValueError("historical observation identity mismatch")
    return body


def _published_analysis(db, observation, attempt=None):
    if attempt is None:
        row = db.execute("SELECT attempt,id,body FROM analysis_results WHERE "
                         "json_extract(body,'$.observation')=? AND json_extract(body,'$.status')='published' "
                         "ORDER BY rowid DESC LIMIT 1", (observation,)).fetchone()
    else:
        row = db.execute("SELECT attempt,id,body FROM analysis_results WHERE attempt=?", (attempt,)).fetchone()
    if row is None:
        raise ValueError("historical observation has no published analysis binding")
    body = json.loads(row[2])
    if (fingerprint(body) != row[1] or body.get("attempt") != row[0]
            or body.get("observation") != observation or body.get("status") != "published"):
        raise ValueError("historical analysis identity mismatch")
    return row[0], body


def append_observation(root, scope, inputs, results, backend, *, bound_inputs=None):
    """Retain supplied facts before loading or executing analysis.

    Unbound observations can be recorded, never published. Reported hashes stay
    reports rather than becoming verified current sources.
    """
    if not isinstance(scope, str) or not scope:
        raise ValueError("history scope must be a nonempty caller-owned lineage")
    body = dict(schema="gambit-reasoning-observation.v2", scope=scope,
                inputs=inputs, backend={"name": backend.get("name")}, backendInputs=backend.get("inputs", {}),
                boundInputs={} if bound_inputs is None else bound_inputs,
                queries=normalized(results))
    if any(body["inputs"].get(path) != sha for path, sha in body["boundInputs"].items()):
        raise ValueError("bound source identity differs from observation")
    identity = fingerprint(body)
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        try:
            db.execute("INSERT OR IGNORE INTO observations VALUES (?,?)", (identity, canonical(body)))
            if _observation(db, identity) != body:
                raise ValueError("historical observation identity mismatch")
            # Content identity is stable; every received metrics/receipt event
            # remains distinct, including a repeat of the same facts.
            event = dict(event=uuid.uuid4().hex, observation=identity, backend=backend)
            db.execute("INSERT INTO observation_events VALUES (?,?)", (fingerprint(event), canonical(event)))
            db.commit()
        except BaseException:
            db.rollback()
            raise
    return identity


def fork_lineage(root, scope, *, parent_scope, parent_observation):
    """Explicit immutable fork; never rename or overwrite its parent's history."""
    if not isinstance(scope, str) or not scope or scope == parent_scope:
        raise ValueError("fork requires a distinct nonempty lineage")
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        parent = _observation(db, parent_observation)
        if parent["scope"] != parent_scope:
            raise ValueError("lineage parent identity mismatch")
        body = dict(schema="gambit-reasoning-lineage.v1", scope=scope,
                    parentScope=parent_scope, parentObservation=parent_observation,
                    parentAnalysis=_published_analysis(db, parent_observation)[0]
                    if parent["schema"] == "gambit-reasoning-observation.v2" else None)
        db.execute("INSERT OR IGNORE INTO lineages VALUES (?,?)", (scope, canonical(body)))
        saved = db.execute("SELECT body FROM lineages WHERE scope=?", (scope,)).fetchone()[0]
        if saved != canonical(body):
            raise ValueError("lineage already exists with a different parent")
        db.commit()


def _prepare(root, observation, limits, legacy_scope):
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        try:
            current = _observation(db, observation)
            scope = current["scope"]
            row = db.execute("SELECT body FROM lineages WHERE scope=?", (scope,)).fetchone()
            if row is None:
                seed = _head(db, legacy_scope) if legacy_scope else None
                definition = dict(schema="gambit-reasoning-lineage.v1", scope=scope,
                                  parentScope=legacy_scope if seed else None, parentObservation=seed)
                db.execute("INSERT INTO lineages VALUES (?,?)", (scope, canonical(definition)))
            else:
                definition = json.loads(row[0])
            expected = _head(db, scope)
            previous = expected or definition["parentObservation"]
            previous_analysis = (_head_analysis(db, scope) if expected else definition.get("parentAnalysis"))
            if previous and _observation(db, previous)["schema"] == "gambit-reasoning-observation.v2":
                previous_analysis = _published_analysis(db, previous, previous_analysis)[0]
            request = dict(schema="gambit-reasoning-analysis-request.v1", scope=scope,
                           observation=observation, expectedHead=expected,
                           expectedAnalysis=_head_analysis(db, scope),
                           previousObservation=previous, previousAnalysis=previous_analysis,
                           lineage=definition, factLimits=None if limits is None else dict(
                               input=limits.input, derived=limits.derived, output=limits.output))
            attempt = uuid.uuid4().hex
            request["attempt"] = attempt
            request["bindingSHA"] = fingerprint(request)
            db.execute("INSERT INTO analysis_requests VALUES (?,?)", (attempt, canonical(request)))
            db.commit()
            return attempt, request
        except BaseException:
            db.rollback()
            raise


def _snapshot(db, identity, policy_inputs=None, *, analysis_attempt=None):
    if identity is None:
        return dict(inputs={}, backendInputs={}, queries={})
    body = _observation(db, identity)
    body = {**body, "inputs": dict(body["inputs"])}
    if body["schema"] == "gambit-reasoning-observation.v2":
        if policy_inputs is None:
            _, analysis = _published_analysis(db, identity, analysis_attempt)
            policy_inputs = analysis["sourceInputs"]
        body["inputs"].update(policy_inputs)
    return body


def _publish(root, attempt, request, analysis):
    """CAS and publication share a short transaction, never an inference lock."""
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        try:
            _observation(db, request["observation"])
            saved = db.execute("SELECT body FROM analysis_requests WHERE id=?", (attempt,)).fetchone()
            if saved is None or saved[0] != canonical(request):
                raise ValueError("historical analysis request identity mismatch")
            definition = db.execute("SELECT body FROM lineages WHERE scope=?", (request["scope"],)).fetchone()
            if definition is None or definition[0] != canonical(request["lineage"]):
                raise ValueError("historical lineage changed before publication")
            if request["previousObservation"]:
                _observation(db, request["previousObservation"])
            if (_head(db, request["scope"]) != request["expectedHead"] or
                    _head_analysis(db, request["scope"]) != request["expectedAnalysis"]):
                raise ValueError("concurrent reasoning observation; preserve newer head")
            db.execute("INSERT INTO analysis_results VALUES (?,?,?)",
                       (attempt, fingerprint(analysis), canonical(analysis)))
            db.execute("INSERT INTO heads VALUES (?,?) ON CONFLICT(scope) DO UPDATE SET id=excluded.id",
                       (request["scope"], request["observation"]))
            db.execute("INSERT INTO head_analyses VALUES (?,?) ON CONFLICT(scope) DO UPDATE SET attempt=excluded.attempt",
                       (request["scope"], attempt))
            db.commit()
        except BaseException:
            db.rollback()
            raise


def analyze_observation(root, observation, *, limits=None, legacy_scope=None):
    """Current analysis of retained facts; interrupted attempts remain pending.

    Each call is a distinct attempt, not an automatic retry or budget reset.
    Unknown process exits/timeouts are never fabricated from Python exceptions.
    """
    attempt, request = _prepare(root, observation, limits, legacy_scope)
    sources, metrics, policy_metrics, delta, policy = {}, {}, {}, None, None
    try:
        catalog = load_component_catalog(RULES.parent / "components.json", entry="history",
                                         constructor="make-history", trusted=True, limits=limits)
        sources = {str(Path(path).relative_to(ROOT.resolve())): sha
                   for path, sha in catalog["sourceInputs"].items()}
        with _database(root) as db:
            current = _snapshot(db, observation, sources)
            previous = _snapshot(db, request["previousObservation"], analysis_attempt=request["previousAnalysis"])
            if current.get("backend", {}).get("name") != "ascent-cffi-api" or not current["backendInputs"]:
                raise ValueError("history requires identity-bound native inference")
            if previous.get("scope") not in (None, request["scope"], request["lineage"]["parentScope"]):
                raise ValueError("historical observation lineage mismatch")
        bindings = current.get("boundInputs", {})
        def check_bindings():
            if any(digest(relative(Path(root).resolve(), path)) != sha for path, sha in bindings.items()):
                raise ValueError("history observation source inputs changed during analysis")
        check_bindings()
        facts = {}
        for label, snapshot in (("previous", previous), ("current", current)):
            facts[label + "_row"] = [(name, row) for name, rows in snapshot["queries"].items() for row in rows]
            facts[label + "_input"] = list(snapshot["inputs"].items()) + [
                ("backend:" + name, sha) for name, sha in snapshot["backendInputs"].items()]
        facts.update(proposal=[(attempt, observation)],
                     expected_parent=[(attempt, fingerprint((request["expectedHead"], request["expectedAnalysis"])))],
                     observed_parent=[], completed=[], source_checked=[], backend_checked=[])
        with engine_api(retain=True) as (engine, identities):
            if identities != current["backendInputs"]:
                raise ValueError("history backend changed after current inference")
            delta = query(facts, catalog, QUERIES, engine=engine, metrics=metrics)
            check_bindings()
            if any(digest(ROOT / path) != sha for path, sha in sources.items()):
                raise ValueError("history rules changed during inference")
            with _database(root) as db:
                now = fingerprint((_head(db, request["scope"]), _head_analysis(db, request["scope"])))
            facts.update(observed_parent=[(now,)], completed=[(attempt,)],
                         source_checked=[(attempt,)], backend_checked=[(attempt,)])
            # The completed full comparison is retained above. Publication
            # checks its premises without recomputing every historical delta.
            policy_facts = {**facts, "current_row": [], "previous_row": [],
                            "current_input": [], "previous_input": []}
            policy = query(policy_facts, catalog, POLICY_QUERIES, engine=engine, metrics=policy_metrics)
            if policy["eligible"] != [(attempt, observation)] or policy["gaps"]:
                raise ValueError("ASCENT history publication rejected: " + canonical(policy))
        if any(digest(ROOT / path) != sha for path, sha in sources.items()):
            raise ValueError("history rules changed before publication")
        check_bindings()
        metrics.update(name="ascent-cffi-api", inputs=identities)
        policy_metrics.update(name="ascent-cffi-api", inputs=identities)
        for name in ("added", "removed", "retained"):
            delta[name] = [(relation, json.loads(row)) for relation, row in delta[name]]
        analysis = dict(schema="gambit-reasoning-analysis.v1", attempt=attempt,
                        observation=observation, previousObservation=request["previousObservation"],
                        previousAnalysis=request["previousAnalysis"],
                        expectedHead=request["expectedHead"], status="published", sourceInputs=sources,
                        expectedAnalysis=request["expectedAnalysis"],
                        verifiedObservationInputs=bindings,
                        reportedOnlyInputs=sorted(set(current["inputs"]) - set(bindings) - set(sources)),
                        delta=delta, backend=metrics, publication=policy, publicationBackend=policy_metrics,
                        runtimeAdmitted=False, persistedResultReuse=False)
        _publish(root, attempt, request, analysis)
        return {**analysis, "analysis": fingerprint(analysis), "lineage": request["scope"],
                "scope": "Recorded observations and current ASCENT analysis; no execution authority"}
    except BaseException as error:
        failure = dict(schema="gambit-reasoning-analysis.v1", attempt=attempt,
                       observation=observation, previousObservation=request["previousObservation"],
                       status="failed", errorType=type(error).__name__, error=str(error),
                       sourceInputs=sources, comparison=delta, backend=metrics,
                       publication=policy, publicationBackend=policy_metrics,
                       runtimeAdmitted=False, persistedResultReuse=False)
        with _database(root) as db:
            db.execute("INSERT INTO analysis_results VALUES (?,?,?)",
                       (attempt, fingerprint(failure), canonical(failure)))
        error.add_note("history observation=" + observation + "; analysis attempt=" + attempt)
        raise


def record(root, scope, inputs, results, backend, *, limits=None, legacy_scope=None, bound_inputs=None):
    observation = append_observation(root, scope, inputs, results, backend,
                                     bound_inputs=inputs if bound_inputs is None else bound_inputs)
    return analyze_observation(root, observation, limits=limits, legacy_scope=legacy_scope)


def read_journal(root, scope):
    """Read full retained bodies with identity checks; never replay them as passes."""
    with _database(root) as db:
        observations = {identity: _observation(db, identity) for identity, in db.execute(
            "SELECT id FROM observations WHERE json_extract(body,'$.scope')=?", (scope,))}
        events = {}
        for identity, encoded in db.execute("SELECT id,body FROM observation_events"):
            body = json.loads(encoded)
            if body["observation"] in observations:
                if fingerprint(body) != identity:
                    raise ValueError("historical observation event identity mismatch")
                events[identity] = body
        requests = {}
        for attempt, encoded in db.execute("SELECT id,body FROM analysis_requests WHERE json_extract(body,'$.scope')=?", (scope,)):
            body = json.loads(encoded)
            if (body.get("attempt") != attempt or body.get("bindingSHA") != fingerprint(
                    {key: value for key, value in body.items() if key != "bindingSHA"})):
                raise ValueError("historical analysis request identity mismatch")
            requests[attempt] = body
        results = {}
        for attempt, identity, encoded in db.execute("SELECT attempt,id,body FROM analysis_results"):
            if attempt in requests:
                body = json.loads(encoded)
                if fingerprint(body) != identity or body["attempt"] != attempt:
                    raise ValueError("historical analysis identity mismatch")
                results[attempt] = {"identity": identity, "body": body}
        head, head_analysis = _head(db, scope), _head_analysis(db, scope)
        if head is not None:
            body = _observation(db, head)
            if body["scope"] != scope:
                raise ValueError("historical head lineage mismatch")
            if body["schema"] == "gambit-reasoning-observation.v2" and head_analysis is None:
                raise ValueError("historical head lacks published analysis")
        if head_analysis is not None:
            published = results.get(head_analysis, {}).get("body", {})
            if published.get("status") != "published" or published.get("observation") != head:
                raise ValueError("historical head analysis mismatch")
        return dict(schema="gambit-reasoning-journal.v1", lineage=scope,
                    head=head, headAnalysis=head_analysis,
                    observations=observations, events=events, requests=requests, results=results,
                    pendingAttempts=sorted(set(requests) - set(results)),
                    runtimeAdmitted=False, persistedResultReuse=False)
