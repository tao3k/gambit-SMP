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
from functools import lru_cache

from gambit_smp.ascent_program import engine_api, load_component_catalog, query
from gambit_smp.framework import ROOT, digest, relative

RULES = ROOT / "evidence/dsl/history.ss"
STORAGE_RULES = RULES.with_name("storage.ss")
QUERIES = {"added": "added", "removed": "removed", "retained": "retained",
           "changedInputs": "changed_input", "addedInputs": "added_input",
           "removedInputs": "removed_input"}
POLICY_QUERIES = {"eligible": "publishable", "gaps": "publication_gap"}


class CheckpointConflict(ValueError):
    pass


class CheckpointClosed(CheckpointConflict):
    """A terminal prefix is immutable, not a transient CAS conflict."""


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


@lru_cache(maxsize=32)
def _storage_location(source_bytes, registry_bytes):
    """Cache only identity-bound routing metadata, never evidence or eligibility."""
    # Construction and routing are one owned API boundary. Nested native
    # loaders reuse its identity; entry and exceptional exit still hash bytes.
    with engine_api(retain=True) as (engine, _):
        catalog = load_component_catalog(RULES.parent / "components.json", entry="state-storage",
                                         constructor="make-history-storage", trusted=True)
        locations = query({}, catalog, {"location": "location"}, engine=engine)["location"]
    if len(locations) != 1 or len(locations[0]) != 1:
        raise ValueError("one registered durable history location required")
    if STORAGE_RULES.read_bytes() != source_bytes or (RULES.parent / "components.json").read_bytes() != registry_bytes:
        raise ValueError("storage declaration changed during routing")
    return locations[0][0]


@contextmanager
def _database(root):
    from gambit_smp.artifact_storage import durable_database_path
    location = _storage_location(STORAGE_RULES.read_bytes(), (RULES.parent / "components.json").read_bytes())
    path = durable_database_path(root, location, "reasoning/history.sqlite3")
    path.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(path, isolation_level=None)) as db:
        db.execute("PRAGMA synchronous=FULL")
        version = db.execute("PRAGMA user_version").fetchone()[0]
        if version not in (0, 1, 2, 3, 4, 5, 6):
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
                version = 1
            except BaseException:
                db.rollback()
                raise
        if version == 1:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("CREATE TABLE IF NOT EXISTS trajectory_attempts "
                           "(id TEXT PRIMARY KEY, scope TEXT NOT NULL, body TEXT NOT NULL)")
                db.execute("CREATE INDEX IF NOT EXISTS trajectory_attempts_scope "
                           "ON trajectory_attempts(scope)")
                db.execute("PRAGMA user_version=2")
                db.commit()
                version = 2
            except BaseException:
                db.rollback()
                raise
        if version == 2:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("ALTER TABLE trajectory_attempts ADD COLUMN request_handle TEXT")
                db.execute("UPDATE trajectory_attempts SET request_handle="
                           "json_extract(body,'$.observation.handle')")
                db.execute("CREATE UNIQUE INDEX trajectory_attempts_request "
                           "ON trajectory_attempts(scope,request_handle)")
                db.execute("PRAGMA user_version=3")
                db.commit()
                version = 3
            except BaseException:
                db.rollback()
                raise
        if version == 3:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("CREATE TABLE IF NOT EXISTS trajectory_clues "
                           "(scope TEXT NOT NULL, id TEXT NOT NULL, body TEXT NOT NULL, "
                           "PRIMARY KEY(scope,id))")
                db.execute("PRAGMA user_version=4")
                db.commit()
                version = 4
            except BaseException:
                db.rollback()
                raise
        if version == 4:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("CREATE TABLE IF NOT EXISTS clue_read_checkpoints "
                           "(id TEXT PRIMARY KEY, body TEXT NOT NULL)")
                db.execute("PRAGMA user_version=5")
                db.commit()
                version = 5
            except BaseException:
                db.rollback()
                raise
        if version == 5:
            db.execute("BEGIN IMMEDIATE")
            try:
                db.execute("CREATE TABLE IF NOT EXISTS execution_checkpoints "
                           "(run TEXT NOT NULL, sequence INTEGER NOT NULL, identity TEXT NOT NULL, body TEXT NOT NULL, "
                           "PRIMARY KEY(run,sequence))")
                db.execute("PRAGMA user_version=6")
                db.commit()
            except BaseException:
                db.rollback()
                raise
        yield db


def cache_clue_checkpoint(root, checkpoint, *, wire_bytes=None, frame_bytes=None, scope=None):
    """Content-addressed read hint, separate from observations and admission."""
    if scope is not None:
        if not isinstance(scope, str) or not scope:
            raise ValueError('nonempty investigation scope required')
        checkpoint = dict(schema='gambit-smp.clue-investigation.v1', scope=scope, checkpoint=checkpoint)
    if wire_bytes is not None or frame_bytes is not None:
        if (type(wire_bytes) is not int or type(frame_bytes) is not int
                or not 0 < frame_bytes <= wire_bytes):
            raise ValueError('complete bounded clue frame required')
        checkpoint = dict(schema='gambit-smp.clue-wire-frame.v1', checkpoint=checkpoint,
                          wireBytes=wire_bytes, frameBytes=frame_bytes, encoding='utf-8')
    encoded, identity = canonical(checkpoint), fingerprint(checkpoint)
    with _database(root) as db:
        db.execute("INSERT OR IGNORE INTO clue_read_checkpoints VALUES (?,?)", (identity, encoded))
        saved = db.execute("SELECT body FROM clue_read_checkpoints WHERE id=?", (identity,)).fetchone()
        if saved != (encoded,):
            raise ValueError("clue read checkpoint cache differs from its identity")
    return "clue-read:" + identity


def load_clue_checkpoint(root, token, *, require_framed=False, include_scope=False):
    """Missing disposable cache safely replays; altered bytes never suppress reads."""
    identity = token.removeprefix("clue-read:")
    if (not token.startswith("clue-read:") or len(identity) != 64
            or any(c not in "0123456789abcdef" for c in identity)):
        raise ValueError("opaque clue-read checkpoint token required")
    with _database(root) as db:
        row = db.execute("SELECT body FROM clue_read_checkpoints WHERE id=?", (identity,)).fetchone()
    if row is None:
        return (None, None) if include_scope else None
    checkpoint = json.loads(row[0])
    if fingerprint(checkpoint) != identity:
        raise ValueError("clue read checkpoint cache identity mismatch")
    if isinstance(checkpoint, dict) and checkpoint.get('schema') == 'gambit-smp.clue-wire-frame.v1':
        window, size = checkpoint.get('wireBytes'), checkpoint.get('frameBytes')
        if (type(window) is not int or type(size) is not int or not 0 < size <= window
                or checkpoint.get('encoding') != 'utf-8' or 'checkpoint' not in checkpoint):
            raise ValueError('clue wire-frame cache contract differs')
        checkpoint = checkpoint['checkpoint']
    elif require_framed:
        return (None, None) if include_scope else None
    scope = None
    if isinstance(checkpoint, dict) and checkpoint.get('schema') == 'gambit-smp.clue-investigation.v1':
        if (set(checkpoint) != {'schema', 'scope', 'checkpoint'}
                or not isinstance(checkpoint['scope'], str) or not checkpoint['scope']):
            raise ValueError('clue investigation scope contract differs')
        scope, checkpoint = checkpoint['scope'], checkpoint['checkpoint']
    return (checkpoint, scope) if include_scope else checkpoint


def _clue_rows(db, scope):
    result = []
    for identity, encoded in db.execute(
            "SELECT id,body FROM trajectory_clues WHERE scope=? ORDER BY rowid", (scope,)):
        body = json.loads(encoded)
        if (fingerprint(body) != identity or body.get("scope") != scope
                or body.get("schema") != "gambit-trajectory-clues.v1"):
            raise ValueError("trajectory clue journal identity mismatch")
        result.append(body)
    return result


def read_trajectory_clues(root, scope):
    """Read immutable submissions; the caller supplies their epistemic role."""
    if not isinstance(scope, str) or not scope:
        raise ValueError("trajectory scope required")
    with _database(root) as db:
        rows = _clue_rows(db, scope)
    return rows, fingerprint(rows)


def append_trajectory_clues(root, scope, source_identity, clues, expected_prefix):
    """CAS of host-validated clue payloads, without admission or inference."""
    if (not isinstance(scope, str) or not scope or not isinstance(source_identity, str)
            or not source_identity or not isinstance(clues, list) or not clues):
        raise ValueError("nonempty source-bound clue submission required")
    body = dict(schema="gambit-trajectory-clues.v1", scope=scope,
                sourceIdentity=source_identity, clues=clues)
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        try:
            rows = _clue_rows(db, scope)
            if fingerprint(rows) != expected_prefix:
                raise ValueError("stale trajectory clue prefix; reread current context")
            ids = [clue["id"] for row in rows for clue in row["clues"]]
            supplied = [clue["id"] for clue in clues]
            if len(set(ids + supplied)) != len(ids) + len(supplied):
                raise ValueError("trajectory clue id is already retained")
            identity = fingerprint(body)
            db.execute("INSERT INTO trajectory_clues VALUES (?,?,?)",
                       (scope, identity, canonical(body)))
            rows.append(body)
            db.commit()
        except BaseException:
            db.rollback()
            raise
    return dict(prefix=fingerprint(rows), submissions=len(rows),
                retainedClues=len(ids) + len(supplied), accepted=supplied)


def append_trajectory_attempt(root, scope, source_identity, candidate, *, observation,
                              snapshot_identity, purpose=None):
    """Persist an observed attempt without admitting its action or result."""
    if not isinstance(scope, str) or not scope or not isinstance(source_identity, str) or not source_identity:
        raise ValueError("trajectory scope and source identity required")
    required = {"questionIdentity", "operationIdentity", "inputIdentity"}
    optional = {"scopeIdentity", "toolIdentity", "modelIdentity", "proposalIdentity"}
    if (not isinstance(candidate, dict) or set(candidate) - required - optional
            or any(not isinstance(candidate.get(key), str) or not candidate[key]
                   for key in required)
            or any(not isinstance(value, str) or not value for value in candidate.values())
            or (purpose is not None and (not isinstance(purpose, str) or not purpose))
            or not isinstance(observation, dict)
            or set(observation) != {"handle", "status", "outcome", "resultIdentity"}
            or any(not isinstance(value, str) or not value for value in observation.values())):
        raise ValueError("typed trajectory candidate required")
    if (not isinstance(snapshot_identity, str) or len(snapshot_identity) != 64
            or any(char not in "0123456789abcdef" for char in snapshot_identity)):
        raise ValueError("trajectory snapshot identity required")
    body = dict(schema="gambit-trajectory-attempt.v1", id=uuid.uuid4().hex,
                scope=scope, sourceIdentity=source_identity, candidate=candidate,
                observation=observation, snapshotIdentity=snapshot_identity,
                purpose=purpose, executionAuthorized=False)
    with _database(root) as db:
        db.execute("BEGIN IMMEDIATE")
        try:
            row = db.execute("SELECT id,body FROM trajectory_attempts "
                             "WHERE scope=? AND request_handle=?",
                             (scope, observation["handle"])).fetchone()
            if row is not None:
                previous = json.loads(row[1])
                if (fingerprint(previous) != row[0] or
                        {key: value for key, value in previous.items() if key != "id"}
                        != {key: value for key, value in body.items() if key != "id"}):
                    raise ValueError("trajectory request handle changed identity")
                db.commit()
                return previous
            db.execute("INSERT INTO trajectory_attempts(id,scope,request_handle,body) "
                       "VALUES (?,?,?,?)",
                       (fingerprint(body), scope, observation["handle"], canonical(body)))
            db.commit()
        except BaseException:
            db.rollback()
            raise
    return body


def read_trajectory_attempts(root, scope):
    """Replay distinct observed attempts in insertion order across restarts."""
    if not isinstance(scope, str) or not scope:
        raise ValueError("trajectory scope required")
    with _database(root) as db:
        rows = db.execute("SELECT id,request_handle,body FROM trajectory_attempts "
                          "WHERE scope=? ORDER BY rowid", (scope,))
        result = []
        for identity, handle, encoded in rows:
            body = json.loads(encoded)
            if (fingerprint(body) != identity or body.get("schema") != "gambit-trajectory-attempt.v1"
                    or body.get("scope") != scope or body.get("executionAuthorized") is not False
                    or set(body.get("observation", {})) != {"handle", "status", "outcome", "resultIdentity"}
                    or body["observation"]["handle"] != handle):
                raise ValueError("historical trajectory attempt identity mismatch")
            snapshot_identity = body.get("snapshotIdentity")
            if (snapshot_identity is not None and
                    (not isinstance(snapshot_identity, str) or len(snapshot_identity) != 64
                     or any(char not in "0123456789abcdef" for char in snapshot_identity))):
                raise ValueError("historical trajectory snapshot identity mismatch")
            result.append(body)
        return result


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


def append_observation(root, scope, inputs, results, backend, *, bound_inputs=None, checkpoint=None):
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
            if checkpoint is not None:
                _append_execution_checkpoint(db, checkpoint, identity)
            db.commit()
        except BaseException:
            db.rollback()
            raise
    return identity


def _native_build_keys(header):
    """Build dependency identities exclude attempt names, display IDs and budgets."""
    steps = {step["id"]: step for step in header.get("declaration", {}).get("steps", [])}
    inputs = header.get("inputs", {})
    memo = {}

    def value(item):
        if isinstance(item, dict):
            if set(item) == {"step", "output"} and item["step"] in steps:
                return {"producer": identity(item["step"]), "output": item["output"]}
            return {key: value(data) for key, data in item.items()}
        if isinstance(item, list):
            return [value(data) for data in item]
        if isinstance(item, str) and item in inputs:
            return {"inputSha256": inputs[item]}
        return item

    def identity(name):
        if name not in memo:
            step = steps[name]
            arguments = step.get('arguments', {})
            if step['capability'] == 'gambit.materialize':
                arguments = {key:data for key,data in arguments.items()
                             if key not in {'buildWorkspace', 'workspace', 'workspaceState', 'cacheReceipt'}}
            memo[name] = fingerprint({"capability": step["capability"],
                                      "arguments": value(arguments),
                                      "dependencies": sorted(identity(dep) for dep in step.get("dependsOn", []))})
        return memo[name]

    costly = {"gambit.configure", "gambit.seed-core", "gambit.source-core", "gambit.bootstrap", 'gerbil.build',
              'gambit.native-development'}
    return {identity(name) for name, step in steps.items() if step.get("capability") in costly}


def _guard_native_build_start(db, checkpoint, observation):
    """Serialize fresh starts against existing durable headers, including old runs.

    This is an execution guard, never cache admission. Actual prior validation,
    tool/source checks, quiescence and stage reuse remain the runner's job.
    """
    record = _observation(db, observation)
    payloads = record["queries"].get("run_record", [])
    if len(payloads) != 1:
        return
    header = json.loads(payloads[0])
    if header.get("schema") != "research-run-header.v1":
        return
    root = header.get("request", {}).get("root")
    if not root:
        return
    cache = Path(root).resolve() / ".cache/tasks"
    run = Path(checkpoint["run"])
    if not run.is_relative_to(cache):
        return
    task = run.relative_to(cache).parts[0]
    owner = cache / task
    keys = _native_build_keys(header)
    if not keys:
        return
    previous = None
    # The existing BEGIN IMMEDIATE covers both this read and the header insert.
    # No disposable directory scan or new scheduler/state database is involved.
    for path, identity, encoded in db.execute(
            "SELECT run,identity,body FROM execution_checkpoints "
            "WHERE run>=? AND run<? AND sequence=0 ORDER BY rowid", (str(owner) + "/", str(owner) + "0")):
        if path == checkpoint["run"]:
            continue
        body = json.loads(encoded)
        if fingerprint(body) != identity or body.get("run") != path:
            raise ValueError("build start checkpoint identity mismatch")
        old = _observation(db, body["observation"])
        rows = old["queries"].get("run_record", [])
        if len(rows) != 1:
            raise ValueError("build start checkpoint lacks its immutable header")
        old_header = json.loads(rows[0])
        if (old_header.get("schema") == "research-run-header.v1"
                and (old_header.get("recipe") == header.get("recipe")
                     or keys & _native_build_keys(old_header))):
            previous = path
    if previous is None:
        return
    requested = header.get("requestedPrior")
    if requested is None:
        prior = header.get("request", {}).get("prior")
        requested = str(Path(prior).parent) if prior else None
    if requested is not None and str(Path(requested).resolve()) == previous:
        return
    raise CheckpointConflict("native build already has a durable attempt; inspect/reuse its checkpoint "
                             "with --prior or an explicit completed-runtime/seed-checkpoint producer: " + previous)


def _append_execution_checkpoint(db, checkpoint, observation):
    run = checkpoint["run"]
    previous = db.execute("SELECT sequence,identity,body FROM execution_checkpoints WHERE run=? "
                          "ORDER BY sequence DESC LIMIT 1", (run,)).fetchone()
    # Self-contained observations append under BEGIN IMMEDIATE. Callers whose
    # result depends on a particular prefix still supply the strict CAS token.
    expected = checkpoint.get("expectedPrefix", previous[1] if previous else None)
    if (previous[1] if previous else None) != expected:
        raise CheckpointConflict("concurrent checkpoint publication; refresh the committed prefix")
    if previous and json.loads(previous[2])["runId"] != checkpoint["runId"]:
        raise ValueError("checkpoint path belongs to another execution")
    if previous is None:
        _guard_native_build_start(db, checkpoint, observation)
    if previous:
        retained = _observation(db, json.loads(previous[2])["observation"])
        payloads = retained["queries"].get("run_record", [])
        if len(payloads) != 1:
            raise ValueError("checkpoint head lacks its immutable record")
        if json.loads(payloads[0]).get("schema") == "research-terminal-observation.v1":
            raise CheckpointClosed("terminal execution is immutable; a new execution needs a new run identity")
    body = {key: checkpoint[key] for key in ("run", "runId", "path", "scope")}
    body.update(sequence=previous[0] + 1 if previous else 0, previous=expected, observation=observation)
    db.execute("INSERT INTO execution_checkpoints VALUES (?,?,?,?)",
               (run, body["sequence"], fingerprint(body), canonical(body)))


def read_execution_checkpoint(root, run):
    """Read an authenticated committed prefix without requiring disposable run files."""
    run = str(Path(run).resolve())
    records, previous, run_id = [], None, None
    with _database(root) as db:
        for sequence, identity, encoded in db.execute(
                "SELECT sequence,identity,body FROM execution_checkpoints WHERE run=? ORDER BY sequence", (run,)):
            body = json.loads(encoded)
            if (fingerprint(body) != identity or body["run"] != run or body["previous"] != previous
                    or body["sequence"] != sequence or sequence != len(records)
                    or (run_id is not None and body["runId"] != run_id)):
                raise ValueError("checkpoint prefix identity mismatch")
            observation = _observation(db, body["observation"])
            payloads = observation["queries"].get("run_record", [])
            if observation["scope"] != body["scope"] or len(payloads) != 1:
                raise ValueError("checkpoint lacks its immutable record observation")
            records.append(dict(body, identity=identity, payload=json.loads(payloads[0]),
                                inputs=observation["inputs"]))
            previous, run_id = identity, body["runId"]
    return {"prefixIdentity": previous, "records": records, "runId": run_id}


def execution_checkpoint_head(root, run):
    """Indexed append metadata; full prefix verification belongs to read/consumption."""
    with _database(root) as db:
        row = db.execute("SELECT identity,body FROM execution_checkpoints WHERE run=? "
                         "ORDER BY sequence DESC LIMIT 1", (str(Path(run).resolve()),)).fetchone()
        if row is None:
            return None
        if fingerprint(json.loads(row[1])) != row[0]:
            raise ValueError("checkpoint head identity mismatch")
        return row[0]


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
            if current.get("backend", {}).get("name") != "ascent-rust" or not current["backendInputs"]:
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
        metrics.update(name="ascent-rust", inputs=identities)
        policy_metrics.update(name="ascent-rust", inputs=identities)
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
