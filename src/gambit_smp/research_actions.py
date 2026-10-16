"""Agentic AI actions over the existing sealed research kernel, without a TUI."""
import argparse
from contextlib import closing
import hashlib
import json
from pathlib import Path
import sqlite3
import sys
import time
import uuid

from gambit_smp.framework import ROOT, digest


def identity(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                                     allow_nan=False).encode()).hexdigest()


def _inputs(root, paths):
    result = {}
    for path in paths:
        path = Path(path).resolve(strict=True)
        path.relative_to(root)
        if not path.is_file():
            raise ValueError("regular source file required")
        result[str(path)] = digest(path)
    return result


def _outcomes(root):
    from gambit_smp.artifact_storage import database_path
    path = database_path(root, "research-actions/requests.sqlite", ".data/research-actions/requests.sqlite")
    if not path.exists():
        return []
    with closing(sqlite3.connect("file:" + str(path) + "?mode=ro", uri=True)) as db:
        return list(db.execute("SELECT body, result FROM requests WHERE result IS NOT NULL ORDER BY id"))


def _study(root, name):
    """Bind exact documents/pointers. Predictions remain proposals, not facts."""
    from gambit_smp.recipes import source_path, read_json
    from gambit_smp.native_review import pointer
    path = source_path(root, name)
    study = read_json(path)
    if set(study) != {"schema", "id", "references", "equalities", "hypotheses", "sourceTrace", "failureReferences"} or study["schema"] != "research-study.v2":
        raise ValueError("typed research study required")
    paths, values, provenance = [path], {}, []
    for ref in study["references"]:
        if set(ref) != {"id", "path", "sha256", "pointer"} or ref["id"] in values:
            raise ValueError("unique exact evidence reference required")
        document = source_path(root, ref["path"])
        if digest(document) != ref["sha256"]:
            raise ValueError("study evidence digest mismatch")
        values[ref["id"]] = pointer(read_json(document), ref["pointer"])
        paths.append(document)
        provenance.append(dict(ref, value=values[ref["id"]]))
    for pair in study["equalities"]:
        if len(pair) != 2 or values[pair[0]] != values[pair[1]]:
            raise ValueError("study evidence identity correspondence mismatch")
    if (not isinstance(study["failureReferences"], list)
            or len(set(study["failureReferences"])) != len(study["failureReferences"])
            or any(name not in values or type(values[name]) is not int
                   for name in study["failureReferences"])):
        raise ValueError("declared integer process-exit references required")
    ids = set()
    for hypothesis in study["hypotheses"]:
        if set(hypothesis) != {"id", "claim", "predictions", "limitations", "recipe"} or hypothesis["id"] in ids:
            raise ValueError("unique typed hypothesis required")
        ids.add(hypothesis["id"])
        for prediction in hypothesis["predictions"]:
            if set(prediction) != {"observation", "expected", "falsifier", "coverageRequired"}:
                raise ValueError("explicit prediction, falsifier and coverage required")
    trace = study["sourceTrace"]
    if set(trace) != {"path", "shaReference", "anchors", "missingReason"}:
        raise ValueError("exact source trace declaration required")
    trace_ready = False
    if trace["path"] is not None:
        source = source_path(root, trace["path"])
        if digest(source) != values[trace["shaReference"]]:
            raise ValueError("trace source differs from selected failure source")
        paths.append(source)
        trace_ready = True
    return study, paths, provenance, trace_ready


def discover(root, context):
    """Native DSL derives prerequisite closure; eligibility is not admission."""
    from gambit_smp.ascent_program import engine_api, load_evidence_catalog, evaluate
    from gambit_smp.recipes import load, source_path
    from gambit_smp.research_kernel import manifest_paths, implementation_paths
    root = Path(root).resolve()
    if set(context) - {"recipes", "engine", "studies", "graph", "observations", "views"} or not isinstance(context.get("recipes", []), list):
        raise ValueError("context requires an explicit recipe inventory and optional engine")
    names = context.get("recipes", [])
    if len(set(names)) != len(names) or not (names or context.get("studies") or context.get("graph") or context.get("views")):
        raise ValueError("nonempty explicit unique action inventory required")
    source = root / "evidence/dsl/actions.ss"
    paths = [source, root / "evidence/native-failures.json"]
    # Transport and execution policy are part of the action revision.
    implementation = [Path(__file__), Path(__file__).with_name("evidence_views.py"),
                      *implementation_paths(Path(__file__).parent)]
    facts = {name: [] for name in ("DeclaredAction", "DeclaredRequires", "PremiseDepends", "DeclaredSatisfied", "DeclaredCurrent", "RecordedOutcome", "Hypothesis", "Prediction", "Observation",
                                  "ObservationEvidence", "PremiseEvidence", "ActionEvidence", "EvidenceReference", "ProcessExit",
                                  "DeclaredKind", "DeclaredStudyMember", "DeclaredSourcePremise", "StudySourceBinding", "StudySourceGap", "Capability",
                                  "StudyDeclaration", "StudyHypothesis", "StudyEvidence", "StudyExit", "SnapshotIdentity")}
    actions = []
    references = {}
    views = []
    from gambit_smp.evidence_views import load as load_view
    if not isinstance(context.get("views", []), list):
        raise ValueError("explicit Evidence view inventory required")
    for name in context.get("views", []):
        view, _, _, bound_view = load_view(root, name)
        if any(row["id"] == view["id"] for row in views):
            raise ValueError("duplicate Evidence view identity")
        views.append(view)
        paths.extend(Path(p) for p in bound_view)

    def evidence(path, pointer="", *, premise=None, action=None):
        path = Path(path).resolve(strict=True)
        ref = {"path": str(path), "sha256": digest(path), "pointer": pointer}
        key = "evidence:" + identity(ref)
        if key not in references:
            references[key] = ref
            facts["EvidenceReference"].append([key, ref["path"], ref["sha256"], pointer])
        if premise is not None:
            facts["PremiseEvidence"].append([premise, key])
        if action is not None:
            facts["ActionEvidence"].append([action, key])
        return key
    engine = None
    if context.get("engine"):
        engine_path = Path(context["engine"]).resolve()
        engine = manifest_paths(engine_path)
    for name in names:
        path = source_path(root, name)
        recipe, steps = load(root, path)
        if recipe["schema"] != "evidence-recipe.v2":
            raise ValueError("new actions require sealed v2 recipes")
        action = "recipe:" + recipe["id"]
        if any(item["id"] == action for item in actions):
            raise ValueError("duplicate action identity")
        facts["DeclaredAction"].append([action])
        evidence(path, action=action)
        facts["DeclaredRequires"].append([action, "sealed-engine"])
        facts["DeclaredRequires"].extend([action, "capability:" + step["capability"]] for step in steps)
        paths.extend([path, *(source_path(root, item) for item in recipe["inputs"])])
        actions.append({"id": action, "recipe": name, "scope": recipe["scope"],
                        "capabilities": [step["capability"] for step in steps],
                        "budgetSeconds": recipe["budgetSeconds"],
                        "risk": "execution", "authorizationRequired": True,
                        "admission": "kernel-check-required",
                        "expectedEvidence": ["sealed run receipt", "actual step observations"],
                        "inputSchema": {"type": "object", "properties": {},
                                        "additionalProperties": False}})
    studies = []
    study_ids = set()
    recorded_observations = []
    gaps = []
    def add_action(action, operation, **fields):
        if any(row["id"] == action for row in actions):
            raise ValueError("duplicate action identity")
        facts["DeclaredAction"].append([action])
        facts["DeclaredKind"].append([action, operation])
        actions.append({"id": action, "operation": operation, "risk": "read-only" if operation in ("inspect-study", "evidence-view") else "local-artifact",
                        "authorizationRequired": True, "admission": "recorded-only",
                        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False}, **fields})
    for name in context.get("studies", []):
        study, study_paths, provenance, trace_ready = _study(root, name)
        if study["id"] in study_ids:
            raise ValueError("duplicate study identity")
        study_ids.add(study["id"])
        paths.extend(study_paths)
        studies.append({"study": study, "provenance": provenance})
        prefix = "study:" + study["id"]
        facts["StudyDeclaration"].append([study["id"], name])
        if trace_ready:
            facts["StudySourceBinding"].extend([
                [study["id"], evidence(root / study["sourceTrace"]["path"])],
                [study["id"], evidence(root / name, "/sourceTrace")]])
        else:
            facts["StudySourceGap"].append([study["id"], study["sourceTrace"]["missingReason"]])
        for hypothesis in study["hypotheses"]:
            hid = prefix + ":" + hypothesis["id"]
            facts["StudyHypothesis"].append([study["id"], hypothesis["id"]])
            facts["Hypothesis"].append([hid])
            facts["Prediction"].extend([hid, prefix + ":" + p["observation"], p["expected"]] for p in hypothesis["predictions"])
        facts["StudyEvidence"].append([study["id"], evidence(root / name)])
        for ref in provenance:
            rid = evidence(root / ref["path"], ref["pointer"])
            facts["StudyEvidence"].append([study["id"], rid])
            if ref["id"] in study["failureReferences"]:
                facts["StudyExit"].append([study["id"], rid, ref["value"]])
    # Explicit, source-bound observation records only. Presence is not a
    # falsifier, coverage certificate or causal conclusion.
    from gambit_smp.native_review import pointer
    if not isinstance(context.get("observations", []), list):
        raise ValueError("explicit observation reference inventory required")
    for ref in context.get("observations", []):
        if not isinstance(ref, dict) or set(ref) != {"path", "sha256", "pointer"}:
            raise ValueError("exact observation SHA and pointer required")
        path = source_path(root, ref["path"])
        if digest(path) != ref["sha256"]:
            raise ValueError("observation record changed")
        record = pointer(json.loads(path.read_text()), ref["pointer"])
        if (not isinstance(record, dict) or set(record) != {
                "schema", "study", "observation", "sourceSha256", "receipt", "value"}
                or record["schema"] != "research-observation.v1"):
            raise ValueError("typed source-bound observation required")
        selected = next((row for row in studies if row["study"]["id"] == record["study"]), None)
        if selected is None:
            raise ValueError("observation belongs to an undeclared study")
        study = selected["study"]
        observed = {p["observation"] for h in study["hypotheses"] for p in h["predictions"]}
        source_sha = next(row["value"] for row in selected["provenance"]
                          if row["id"] == study["sourceTrace"]["shaReference"])
        if record["observation"] not in observed or record["sourceSha256"] != source_sha:
            raise ValueError("observation predicate or source identity mismatch")
        receipt = record["receipt"]
        if not isinstance(receipt, dict) or set(receipt) != {"path", "sha256", "pointer"}:
            raise ValueError("exact observation receipt reference required")
        original = source_path(root, receipt["path"])
        if (digest(original) != receipt["sha256"]
                or pointer(json.loads(original.read_text()), receipt["pointer"]) != record["value"]):
            raise ValueError("observation value does not match its original receipt")
        paths.extend([path, original])
        oid = "study:" + study["id"] + ":" + record["observation"]
        facts["Observation"].append([oid])
        facts["ObservationEvidence"].extend([[oid, evidence(path, ref["pointer"])],
                                              [oid, evidence(original, receipt["pointer"])]])
        recorded_observations.append({"observation": oid, "record": ref, "receipt": receipt,
                                      "scope": "recorded correspondence only; measurement validity and coverage not admitted"})
    if context.get("graph"):
        graph = context["graph"]
        if set(graph) != {"model"} or not isinstance(graph["model"], str):
            raise ValueError("graph requires an exact registered model")
        from gambit_smp.ascent_review import collect
        from gambit_smp.review_validation import python_files, asset_files
        facts["DeclaredRequires"].append(["graph:" + graph["model"], "current-catalog"])
        try:
            catalog_inputs = collect(root, task_model=graph["model"])[1]
            paths.extend(root / path for path in catalog_inputs)
            facts["DeclaredSatisfied"].append(["current-catalog"])
            for path in catalog_inputs:
                evidence(root / path, premise="current-catalog")
        except ValueError as error:
            # A failed catalog cannot license graph validation, but must not
            # suppress unrelated read-only investigation of bound receipts.
            gaps.append({"action": "graph:" + graph["model"], "premise": "current-catalog", "reason": str(error)})
            paths.extend(path for directory in ("evidence", "models", "docs")
                         for path in (root / directory).rglob("*") if path.is_file())
        paths.extend(root / path for path in python_files(root))
        paths.extend(root / path for path in asset_files(root))
        add_action("graph:" + graph["model"], "current-graph", model=graph["model"], budgetSeconds=300,
                   expectedEvidence=["full validation inventory", "CURRENT graph and source/backend recheck"])
        facts["DeclaredRequires"].append(["graph:" + graph["model"], "sealed-engine"])
    if engine is not None:
        facts["DeclaredSatisfied"].append(["sealed-engine"])
        evidence(engine_path / "engine.json", premise="sealed-engine")
        facts["Capability"].extend([name, "capability:" + name] for name in engine["capabilities"])
        for name in engine["capabilities"]:
            evidence(engine_path / "engine.json", "/capabilities", premise="capability:" + name)
    bound = _inputs(root, paths)
    bound.update({str(path.resolve()): digest(path) for path in implementation})
    history = _outcomes(root)
    with engine_api(retain=True) as (api, backend):
        from gambit_smp.evidence_views import evaluate as evaluate_view
        view_results = [evaluate_view(root, name, api) for name in context.get("views", [])]
        for view in view_results:
            for row in view["answers"].get("actions", []):
                if len(row) != 3 or any(type(value) is not str for value in row):
                    raise ValueError("view actions require id, query and reason strings")
                identifier, query, reason = row
                if query not in view["queries"]:
                    raise ValueError("view action names an undeclared query")
                action = "view:" + view["id"] + ":" + identifier
                add_action(action, "evidence-view", view=view["path"], query=query,
                           expectedEvidence=[reason], budgetSeconds=15)
                # The view document declares every individually hashed input.
                # Keep that full map once in the snapshot, not once per action.
                evidence(root / view["path"], action=action)
        source_identity = identity({"inputs": bound, "backend": backend, "engine": engine})
        facts["SnapshotIdentity"] = [[source_identity]]
        for body, result in history:
            body, result = json.loads(body), json.loads(result)
            if "sourceIdentity" in body:
                facts["RecordedOutcome"].append([body["action"], body["sourceIdentity"],
                                                 result.get("outcome", result["status"])])
        answers, explanation = evaluate(api, facts, load_evidence_catalog(source,
            constructor="make-actions", trusted=True), {"eligible": "Eligible", "blocked": "Blocked", "openPredictions": "OpenPrediction", "discriminators": "Discriminator",
                "needs": "Need", "missing": "Missing", "supported": "Supported", "reused": "ReusedEvidence",
                "failures": "ExistingFailure", "failedEvidence": "FailedEvidence", "explanationGaps": "ExplanationGap", "actionGaps": "ActionGap",
                "studyActions": "StudyActionSpec", "studyExpected": "StudyExpected"})
    for action, operation, subject, path, hypothesis, risk, admission in answers["studyActions"]:
        if any(row["id"] == action for row in actions):
            raise ValueError("duplicate action identity")
        row = {"id": action, "operation": operation, "study": path, "hypothesis": hypothesis,
               "risk": risk, "admission": admission, "authorizationRequired": True,
               "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
               "expectedEvidence": [text for identifier, text in answers["studyExpected"] if identifier == action]}
        actions.append(row)
    gaps.extend({"action": row[0], "premise": row[1], "reason": row[2]} for row in answers["actionGaps"])
    checked = _inputs(root, paths)
    checked.update({str(path.resolve()): digest(path) for path in implementation})
    if checked != bound:
        raise ValueError("action inputs changed during discovery")
    if engine is not None and manifest_paths(engine_path) != engine:
        raise ValueError("sealed engine changed during discovery")
    if _outcomes(root) != history:
        raise ValueError("action outcomes changed during discovery")
    eligible = {row[0] for row in answers["eligible"]}
    for action in actions:
        action["eligibility"] = "PREFLIGHT_READY" if action["id"] in eligible else "BLOCKED"
        action["blockers"] = [row[1] for row in answers["blocked"] if row[0] == action["id"]]
        action["whyNotScope"] = "explicit bound prerequisite inventory; not an open-world absence proof"
        action["blockingEvidence"] = [gap for gap in gaps if gap["action"] == action["id"]]
        action["explanation"] = {
            "requiredPremises": [row[1] for row in answers["needs"] if row[0] == action["id"]],
            "missingPremises": [row[1] for row in answers["missing"] if row[0] == action["id"]],
            "supportedPremises": [{"premise": row[1], "reference": references[row[2]]}
                                  for row in answers["supported"] if row[0] == action["id"]],
            "reusedEvidence": [references[row[1]] for row in answers["reused"] if row[0] == action["id"]],
            "sameInputFailures": [{"sourceIdentity": row[1], "outcome": row[2]}
                                  for row in answers["failures"] if row[0] == action["id"]],
            "existingFailedEvidence": [{"reference": references[row[1]], "exit": row[2]}
                                       for row in answers["failedEvidence"] if row[0] == action["id"]],
            "unboundPremises": [row[1] for row in answers["explanationGaps"] if row[0] == action["id"]],
            "executionAuthorized": False, "causalEstablished": False,
            "scope": "declared prerequisite closure and exact references; not an open-world proof"}
    state = {"schema": "research-actions.v1", "context": context, "inputs": bound,
             "backend": backend, "engine": engine, "actions": actions,
             "sourceIdentity": source_identity, "recordedOutcomes": history,
             "studies": studies, "evidenceViews": [{k: v for k, v in view.items() if k != "explanation"} for view in view_results], "research": {"gaps": gaps, "openPredictions": answers["openPredictions"], "discriminators": answers["discriminators"],
                                                "recordedObservations": recorded_observations,
                                                "causalEstablished": False, "coverageEstablished": False},
             "executionAuthorized": False, "runtimeAdmitted": False}
    # Process-local handles/generations are observations, not revision inputs.
    return dict(state, revision=identity(state), nativeExplanation=explanation,
                viewExplanations={view["id"]: view["explanation"] for view in view_results})


def _database(root):
    from gambit_smp.artifact_storage import database_path
    path = database_path(root, "research-actions/requests.sqlite", ".data/research-actions/requests.sqlite")
    path.parent.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(path, timeout=1)
    db.execute("CREATE TABLE IF NOT EXISTS requests (id TEXT PRIMARY KEY, body TEXT NOT NULL, result TEXT)")
    db.commit()
    return db


def select(root, snapshot, action, inputs, request_id, *, authorize_execution=False):
    """Reserve before side effects. A pending request never silently relaunches."""
    from gambit_smp.research_kernel import run_sealed
    from gambit_smp.ascent_program import artifact_paths
    started = time.monotonic()
    if type(authorize_execution) is not bool or inputs != {}:
        raise ValueError("explicit host authorization and exact action inputs required")
    if not isinstance(request_id, str) or str(uuid.UUID(request_id)) != request_id:
        raise ValueError("canonical UUID request identity required")
    body = {"revision": snapshot["revision"], "action": action, "inputs": inputs,
            "authorization": authorize_execution, "context": snapshot["context"],
            "sourceIdentity": snapshot["sourceIdentity"]}
    encoded = json.dumps(body, sort_keys=True)
    db = _database(root)
    try:
        previous = db.execute("SELECT body FROM requests WHERE id=?", (request_id,)).fetchone()
        if previous:
            if previous[0] != encoded:
                raise ValueError("request identity reused for different content")
            return observe(root, request_id)
        current = discover(root, snapshot["context"])
        if current["revision"] != snapshot["revision"]:
            raise ValueError("STALE action revision; rediscover before selecting")
        selected = next((item for item in current["actions"] if item["id"] == action), None)
        if selected is None or selected["eligibility"] != "PREFLIGHT_READY":
            raise ValueError("action absent or prerequisites blocked")
        if not authorize_execution:
            raise ValueError("host execution authorization required")
        db.execute("BEGIN IMMEDIATE")
        # Discovery and native inference stay outside the short reservation lock.
        previous = db.execute("SELECT body FROM requests WHERE id=?", (request_id,)).fetchone()
        if previous:
            if previous[0] != encoded:
                raise ValueError("request identity reused for different content")
            db.rollback()
            return observe(root, request_id)
        if any(digest(Path(path)) != sha for path, sha in current["inputs"].items()):
            raise ValueError("STALE action inputs before reservation")
        backend_changed = bool(current["backend"]) and {
            name: digest(path) for name, path in artifact_paths().items()} != current["backend"]
        if backend_changed or _outcomes(root) != current["recordedOutcomes"]:
            raise ValueError("STALE backend or action outcomes before reservation")
        db.execute("INSERT INTO requests VALUES (?, ?, NULL)", (request_id, encoded))
        db.commit()
        from gambit_smp.artifact_storage import cache_path
        out = cache_path(root, "research-actions/" + request_id)
        try:
            if selected.get("operation"):
                result = _execute_action(Path(root).resolve(), selected, current, out, started=started)
            else:
                receipt = run_sealed(Path(root).resolve(), Path(root).resolve() / selected["recipe"],
                                 out, Path(current["context"]["engine"]).resolve(), allow_native=True)
                result = {"status": "COMPLETED", "outcome": receipt["outcome"],
                      "receipt": str(out / "receipt.json"), "receiptSHA": digest(out / "receipt.json"),
                      "runtimeAdmitted": False}
        except BaseException as error:
            result = {"status": "FAILED", "errorType": type(error).__name__, "error": str(error),
                      "out": str(out), "runtimeAdmitted": False}
            db.execute("UPDATE requests SET result=? WHERE id=?", (json.dumps(result), request_id))
            db.commit()
            raise
        db.execute("UPDATE requests SET result=? WHERE id=?", (json.dumps(result), request_id))
        db.commit()
    finally:
        db.close()
    return observe(root, request_id)


def _execute_action(root, action, snapshot, out, *, started):
    """Fixed generic operations, never data-supplied argv or runner handlers."""
    from gambit_smp.framework import execute
    from gambit_smp.agent_context import recheck
    out.mkdir(parents=True, exist_ok=False)
    operation = action["operation"]
    receipt = {"schema": "research-action-observation.v1", "operation": operation,
               "sourceIdentity": snapshot["sourceIdentity"], "inputs": snapshot["inputs"],
               "backend": snapshot["backend"], "nativeExplanation": snapshot["nativeExplanation"],
               "runtimeAdmitted": False, "causalEstablished": False, "executionAuthorized": False}
    if operation == "current-graph":
        import os
        env = dict(os.environ, GAMBIT_SMP_TEST_ENGINE=str(Path(snapshot["context"]["engine"]).resolve()))
        metadata = {}
        remaining = 300 - (time.monotonic() - started)
        if remaining <= 0:
            raise ValueError("graph selection exhausted its whole 300-second budget")
        code, output, timeout, elapsed = execute([sys.executable, "-m", "gambit_smp.agent_context",
            "--model", action["model"], "--profile", "full", "--timeout", "300", "--out", str(out / "graph")],
            cwd=root, timeout=remaining, env=env, metadata=metadata)
        log = out / "process.log"
        log.write_text(output)
        receipt.update(exit=code, timeout=timeout, executionSeconds=elapsed, budgetSeconds=300,
                       process=metadata, logSHA=digest(log), outcome="DENY")
        if (out / "graph/context.json").exists():
            receipt["graph"] = recheck(root, out / "graph")
            if code == 0 and not timeout and receipt["graph"]["status"] == "CURRENT" and receipt["graph"]["frameworkValidated"]:
                receipt["outcome"] = "PASS"
    elif operation == "evidence-view":
        from gambit_smp.ascent_program import engine_api
        from gambit_smp.evidence_views import evaluate as evaluate_view
        with engine_api(retain=True) as (api, _):
            view = evaluate_view(root, action["view"], api)
        receipt.update(view=view, selectedQuery=action["query"],
                       answers=view["answers"][action["query"]], outcome="RECORDED", budgetSeconds=15)
    else:
        study, _, provenance, _ = _study(root, action["study"])
        receipt.update(provenance=provenance, research=snapshot["research"], outcome="RECORDED")
        if operation == "inspect-study":
            receipt["study"] = study
        elif operation == "design-experiment":
            hypothesis = next(row for row in study["hypotheses"] if row["id"] == action["hypothesis"])
            receipt["proposal"] = hypothesis
            receipt["executionReadiness"] = "SEPARATE_KERNEL_REVIEW_REQUIRED" if hypothesis["recipe"] else "CAPABILITY_NOT_IMPLEMENTED"
        elif operation == "trace-source":
            trace = study["sourceTrace"]
            lines = (root / trace["path"]).read_text().splitlines()
            anchors = []
            for anchor in trace["anchors"]:
                if (set(anchor) != {"role", "line", "text"} or type(anchor["line"]) is not int
                        or not 1 <= anchor["line"] <= len(lines) or lines[anchor["line"] - 1] != anchor["text"]):
                    raise ValueError("exact source anchor mismatch")
                anchors.append(anchor)
            receipt["anchors"] = anchors
            receipt["dynamicProvenanceEstablished"] = False
        else:
            raise ValueError("unsupported action operation")
    if any(digest(Path(path)) != sha for path, sha in snapshot["inputs"].items()):
        receipt["outcome"] = "STALE"
    from gambit_smp.ascent_program import artifact_paths
    if {name: digest(path) for name, path in artifact_paths().items()} != snapshot["backend"]:
        receipt["outcome"] = "STALE"
    receipt["seconds"] = time.monotonic() - started
    if operation == "current-graph" and receipt["seconds"] > 300:
        receipt["outcome"] = "DENY"
        receipt["budgetExceeded"] = True
    if operation == "evidence-view" and receipt["seconds"] > 15:
        receipt["outcome"] = "DENY"
        receipt["budgetExceeded"] = True
    path = out / "receipt.json"
    path.write_text(json.dumps(receipt, indent=2, allow_nan=False) + "\n")
    return {"status": "COMPLETED", "outcome": receipt["outcome"], "receipt": str(path),
            "receiptSHA": digest(path), "runtimeAdmitted": False}


def observe(root, handle):
    """Read a request without inference, automatic retry or erasing partial runs."""
    from gambit_smp.research_kernel import inspect
    db = _database(root)
    try:
        row = db.execute("SELECT body, result FROM requests WHERE id=?", (handle,)).fetchone()
    finally:
        db.close()
    if row is None:
        raise ValueError("unknown action handle")
    result = json.loads(row[1]) if row[1] else {"status": "PENDING_OR_INTERRUPTED"}
    if result.get("receipt"):
        path = Path(result["receipt"])
        if digest(path) != result["receiptSHA"]:
            raise ValueError("action receipt changed")
        receipt = json.loads(path.read_text())
        if receipt.get("schema") == "research-action-observation.v1":
            from gambit_smp.ascent_program import artifact_paths
            drift = any(digest(Path(p)) != sha for p, sha in receipt["inputs"].items()) or {name: digest(path) for name, path in artifact_paths().items()} != receipt["backend"]
            result["inspection"] = {"status": "STALE" if drift else "CURRENT", "runtimeAdmitted": False}
            if receipt.get("logSHA") and digest(path.parent / "process.log") != receipt["logSHA"]:
                raise ValueError("action process log changed")
            if receipt["operation"] == "current-graph" and (path.parent / "graph/context.json").exists():
                from gambit_smp.agent_context import recheck
                result["inspection"]["graph"] = recheck(Path(root).resolve(), path.parent / "graph")
        else:
            result["inspection"] = inspect(path.parent)
    return {"handle": handle, "request": json.loads(row[0]), "result": result,
            "executionAuthorized": False, "runtimeAdmitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("operation", choices=("discover", "select", "observe"))
    parser.add_argument("--request", type=Path, help="structured JSON request")
    parser.add_argument("--authorize-execution", action="store_true")
    args = parser.parse_args()
    if args.request is None:
        parser.error("--request is required")
    try:
        request = json.loads(args.request.read_text())
        if args.operation == "discover":
            result = discover(ROOT, request)
        elif args.operation == "select":
            if set(request) != {"snapshot", "action", "inputs", "requestId"}:
                raise ValueError("exact selection request fields required")
            result = select(ROOT, request["snapshot"], request["action"], request["inputs"],
                            request["requestId"], authorize_execution=args.authorize_execution)
        else:
            if set(request) != {"handle"}:
                raise ValueError("exact observation request fields required")
            result = observe(ROOT, request["handle"])
        print(json.dumps(result, indent=2))
        if args.operation == "select" and (result["result"].get("status") == "FAILED" or
                result["result"].get("outcome") not in (None, "PASS", "RECORDED")):
            return 2
        return 0
    except (OSError, ValueError, KeyError, TypeError, sqlite3.Error) as error:
        print("ACTION-DENY " + str(error), file=sys.stderr)
        return 2
