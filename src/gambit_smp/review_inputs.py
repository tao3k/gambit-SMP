"""Bind review claims to the actual files named by their receipts."""
import json
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.protocol_evidence import BUNDLES
from gambit_smp.research_audit import local
from gambit_smp.quint_backend import admitted_model, counterexample, summarize


RAW_LOG_MANIFEST = "evidence/model-raw-log-attestations.json"
PROOF_OBSERVATIONS = "evidence/induction-observations.json"


def proof_observations(root):
    """Bind archived partial observations, never create admitted model facts."""
    root = Path(root).resolve()
    if not (root / PROOF_OBSERVATIONS).is_file():
        return None, {}
    catalog_path = local(root, PROOF_OBSERVATIONS)
    catalog = json.loads(catalog_path.read_text())
    if (catalog.get("schema") != "gambit-induction-observations.v1" or
            catalog.get("overallAccepted") is not False):
        raise ValueError("partial proof catalog must remain non-admitted")
    inputs = {PROOF_OBSERVATIONS: digest(catalog_path)}
    for notes in [catalog.get("notes"), *(row.get("notes") for row in catalog["observations"])]:
        if notes is None:
            continue
        if not isinstance(notes, str) or not Path(notes).parts or Path(notes).parts[0] != "docs":
            raise ValueError("partial proof notes must be repository documentation")
        notes_file = local(root, notes)
        if notes_file.relative_to(root).parts[0] != "docs" or ".data" in notes_file.relative_to(root).parts:
            raise ValueError("partial proof notes must not resolve into a cache")
        inputs[notes] = digest(notes_file)
    if catalog.get("proofLayer"):
        inputs[catalog["proofLayer"]] = digest(local(root, catalog["proofLayer"]))
    observations, identifiers = [], set()
    for index, row in enumerate(catalog["observations"]):
        if row["id"] in identifiers:
            raise ValueError("duplicate partial proof observation")
        identifiers.add(row["id"])
        proof_layer = row.get("proofLayer", catalog.get("proofLayer"))
        if proof_layer:
            inputs[proof_layer] = digest(local(root, proof_layer))
        receipt_path = row["receipt"]
        if not receipt_path.startswith("evidence/") or ".data" in Path(receipt_path).parts:
            raise ValueError("partial proof receipt must be persistent evidence")
        receipt_file = local(root, receipt_path)
        if ".data" in receipt_file.relative_to(root).parts:
            raise ValueError("partial proof receipt resolves into a cache")
        if digest(receipt_file) != row["receiptSha256"]:
            raise ValueError("partial proof receipt identity mismatch")
        saved = json.loads(receipt_file.read_text())
        if any(saved.get(field) is not False for field in (
                "accepted", "runtimeAdmitted", "releaseAdmitted", "temporalProved")):
            raise ValueError("partial proof receipt must remain non-admitted")
        archive_path = local(receipt_file.parent, "archive.json")
        archive = json.loads(archive_path.read_text())
        if (archive.get("schema") != "gambit-model-attempt-archive.v1" or
                archive.get("archiveOnly") is not True or
                any(archive.get(field) is not False for field in (
                    "accepted", "runtimeAdmitted", "releaseAdmitted"))):
            raise ValueError("partial proof archive must remain non-admitted")
        inputs[str(archive_path.relative_to(root))] = digest(archive_path)
        artifacts = {}
        for name, hashes in archive["files"].items():
            artifact = local(receipt_file.parent, name)
            path = str(artifact.relative_to(root))
            if ".data" in artifact.relative_to(root).parts:
                raise ValueError("partial proof artifact resolves into a cache")
            if digest(artifact) != hashes["portableSha256"]:
                raise ValueError("partial proof archived artifact drift: " + path)
            inputs[path] = hashes["portableSha256"]
            artifacts[name] = {"path": path, **hashes}
        if artifacts.get("receipt.json", {}).get("portableSha256") != row["receiptSha256"]:
            raise ValueError("partial proof archive does not bind its receipt")
        checks = saved.get("results", [])
        if not checks and "log" in saved:
            checks = [{"log": saved["log"], "logSha256": saved.get("logSha256"),
                       "step": saved.get("targetStep"), "exit": saved.get("exit"),
                       "timeout": saved.get("timeout"), "obligationProved": saved.get("obligationProved")}]
        for check in checks:
            for field in ("log", "trace"):
                if field in check:
                    recorded = artifacts.get(check[field])
                    expected = check.get(field + "Sha256")
                    if recorded is None or (expected is not None and recorded["rawSha256"] != expected):
                        raise ValueError("partial proof check artifact identity mismatch")
        for name, expected in saved.get("modelInputs", {}).items():
            if artifacts.get(name, {}).get("rawSha256") != expected:
                raise ValueError("partial proof model snapshot identity mismatch")
        gaps = []
        recorded_irs = {name: saved[field] for name, field in (
            ("protocol-ir.json", "protocolIrSha256"), ("generator-ir.json", "generatorIrSha256")) if field in saved}
        if (saved.get("generatorContract") or {}).get("proofIrSha256"):
            recorded_irs["proof-ir.json"] = saved["generatorContract"]["proofIrSha256"]
        for name, expected in recorded_irs.items():
            if name not in artifacts:
                gaps.append({"path": str((receipt_file.parent / name).relative_to(root)),
                             "expectedSha256": expected})
            elif artifacts[name]["rawSha256"] != expected:
                raise ValueError("partial proof IR identity mismatch")
        observations.append({"row": row, "index": index, "receipt": saved,
                             "proofLayer": proof_layer,
                             "notes": row.get("notes", catalog.get("notes")),
                             "archivePath": str(archive_path.relative_to(root)),
                             "artifacts": artifacts, "checks": checks, "artifactGaps": gaps})
    return {**catalog, "boundObservations": observations}, inputs


VERIFIER_MODULES = (
    "src/gambit_smp/protocol_evidence.py",
    "src/gambit_smp/check_gambit.py",
    "src/gambit_smp/verify_protocols.py",
    "src/gambit_smp/framework.py",
    "src/gambit_smp/tlc_values.py",
    "src/gambit_smp/quint_backend.py",
)
HISTORICAL_VERIFIER_NAMES = {Path(name).name for name in VERIFIER_MODULES}


def _verifier_input(name):
    path = Path(name)
    return (str(path.parent) in ("src/gambit_smp", "tools/model") and
            path.name in HISTORICAL_VERIFIER_NAMES)


def _record(root, path, expected, model=None, rechecked=False):
    source = local(root, path)
    if digest(source) != expected:
        raise ValueError("review receipt changed: " + path)
    saved = json.loads(source.read_text())
    recorded = saved.get("inputs")
    if recorded is not None and (not isinstance(recorded, dict) or
                                 any(not isinstance(k, str) or not isinstance(v, str)
                                     for k, v in recorded.items())):
        raise ValueError("invalid receipt input map: " + path)
    bound = dict(recorded or {})
    superseded = []
    if rechecked and recorded:
        # protocol_checked is emitted only after the current verifier has
        # rechecked the saved logs, model hash, source context and result set.
        # Its old implementation paths are provenance, not current premises.
        superseded = sorted(name for name in bound if _verifier_input(name))
        for name in superseded:
            del bound[name]
        for name in VERIFIER_MODULES:
            bound[name] = digest(local(root, name))
    if rechecked and model is not None:
        rows = [row for row in saved.get("results", []) if row.get("case") == model]
        if not rows:
            raise ValueError("rechecked receipt has no model results: " + model)
        for row in rows:
            for field, hash_field in (("log", "logSha256"), ("trace", "traceSha256")):
                if field not in row:
                    if field == "log":
                        raise ValueError("rechecked result has no archived log")
                    continue
                artifact = (source.parent / row[field]).resolve()
                artifact.relative_to(source.parent.resolve())
                name = str(artifact.relative_to(root))
                expected_hash = row.get(hash_field)
                if digest(artifact) != expected_hash:
                    raise ValueError("rechecked artifact identity mismatch: " + name)
                if name in bound and bound[name] != expected_hash:
                    raise ValueError("conflicting rechecked artifact identity: " + name)
                bound[name] = expected_hash
    bound[path] = expected
    if model is not None:
        name = "models/gambit/" + model + ".qnt"
        bound[name] = digest(local(root, name))
    level = "revalidated-output" if superseded else (
        "recorded" if recorded else "catalog-fallback")
    return bound, level, superseded


def _checks(root, path, model, inputs):
    saved = json.loads(local(root, path).read_text())
    checks = []
    for row in saved.get("results", []):
        if row.get("case") != model:
            continue
        artifacts = {}
        for field in ("log", "trace"):
            if field not in row:
                continue
            declared = str((local(root, path).parent / row[field]).resolve().relative_to(root))
            candidates = [declared] if declared in inputs else [
                name for name in inputs if Path(name).parts[:1] == ("evidence",) and Path(name).name == row[field]]
            if len(candidates) > 1:
                raise ValueError("ambiguous archived check artifact: " + row[field])
            if candidates:
                artifacts[field] = candidates[0]
        checks.append({key: row[key] for key in (
            "variant", "invariant", "initializer", "temporal", "states", "seconds",
            "exit", "timeout", "modelSha256") if key in row} | {"artifacts": artifacts})
    return checks


def _raw_log_attestations(root):
    path = local(root, RAW_LOG_MANIFEST)
    if not path.is_file():
        return {}
    saved = json.loads(path.read_text())
    if saved.get("schema") != "gambit-model-raw-log-attestations.v1":
        raise ValueError("unknown raw log attestation schema")
    result = {}
    for entry in saved["receipts"]:
        key = (entry["model"], entry["receipt"], entry["receiptSha256"])
        if key in result:
            raise ValueError("duplicate raw log attestation")
        result[key] = entry
    return result


def _archived(root, name):
    if Path(name).parts[:1] != ("evidence",):
        raise ValueError("raw model evidence must be archived under evidence/")
    cursor = root
    for part in Path(name).parts:
        cursor = cursor / part
        if cursor.is_symlink():
            raise ValueError("raw model evidence may not be a symlink")
    path = local(root, name)
    return path


def _checked_raw_logs(root, model, receipt_path, receipt_sha, entry):
    """Reinterpret saved TLC logs; never accept a summary bit alone."""
    receipt = json.loads(local(root, receipt_path).read_text())
    if receipt.get("quintVersion") != json.loads((root / "models/gambit/cases.json").read_text())["quintVersion"]:
        raise ValueError("raw log receipt has a different Quint version")
    rows = [row for row in receipt["results"] if row["case"] == model]
    model_sha = digest(local(root, "models/gambit/" + model + ".qnt"))
    snapshot = entry["modelSnapshot"]
    snapshot_path = snapshot["path"]
    if (digest(_archived(root, snapshot_path)) != snapshot["sha256"] or
            snapshot["sha256"] != model_sha or
            any(row["modelSha256"] != model_sha for row in rows)):
        raise ValueError("raw log model snapshot identity mismatch")
    logs = entry["logs"]
    if len(logs) != len(rows) or {row["name"] for row in logs} != {row["log"] for row in rows}:
        raise ValueError("raw log attestation does not cover every check")
    expected = {row["name"]: row for row in logs}
    bound = {RAW_LOG_MANIFEST: digest(local(root, RAW_LOG_MANIFEST)),
             receipt_path: receipt_sha, snapshot_path: model_sha}
    bound.update(checked_model_input_closure(root, receipt))
    for row in rows:
        item = expected[row["log"]]
        path = item["path"]
        if Path(path).name != row["log"]:
            raise ValueError("raw log name differs from receipt")
        source = _archived(root, path)
        if digest(source) != item["sha256"]:
            raise ValueError("raw log identity mismatch: " + path)
        output = source.read_text()
        old = row["variant"] == "old"
        if not admitted_model(row["exit"], output, row["timeout"], old):
            raise ValueError("raw log does not support receipt: " + path)
        if old:
            counterexample(output)
        if row.get("states") and summarize(output) != row["states"]:
            raise ValueError("raw log state count differs from receipt: " + path)
        if row.get("temporal") and "Finished checking temporal properties" not in output:
            raise ValueError("raw log lacks temporal completion: " + path)
        bound[path] = item["sha256"]
    for name in VERIFIER_MODULES:
        bound[name] = digest(local(root, name))
    return bound


def checked_model_input_closure(root, receipt):
    """Check source imports without claiming that retained model logs passed."""
    closure = receipt.get("inputClosure", {})
    if not isinstance(closure, dict):
        raise ValueError("raw model input closure must be a path/hash mapping")
    bound = {}
    for name, expected_sha in closure.items():
        if (not isinstance(name, str) or not name.startswith("models/")
                or Path(name).suffix != ".qnt" or digest(local(root, name)) != expected_sha):
            raise ValueError("raw model input closure identity mismatch")
        bound[name] = expected_sha
    return bound


def bindings(root, base, observations, snapshot_identity):
    """Return per-receipt expected inputs and current file identities.

    A missing recorded file has no CurrentInput row, so ASCENT invalidates the
    receipt. Model composition edges remain claim obligations, not proof edges.
    """
    root = Path(root).resolve()
    specs = {}
    cases = json.loads((root / "models/gambit/cases.json").read_text())["cases"]
    model_paths = {case["id"]: case["modelReceipt"] for case in cases
                   if "modelReceipt" in case}
    raw_logs = _raw_log_attestations(root)
    used_raw_logs = set()
    for model, receipt, *_ in base["facts"].get("model_receipt", []):
        path = model_paths[model]
        inputs, level, superseded = _record(root, path, receipt, model)
        attestation = raw_logs.get((model, path, receipt))
        raw_logs_present = (attestation is not None and all(
            _archived(root, row["path"]).is_file() for row in attestation["logs"]))
        if attestation is not None:
            used_raw_logs.add((model, path, receipt))
        if raw_logs_present:
            for name in list(inputs):
                if _verifier_input(name):
                    del inputs[name]
            inputs.update(_checked_raw_logs(root, model, path, receipt, attestation))
            level = "raw-log-revalidated"
        specs[model + ":" + receipt] = {"path": path, "inputs": inputs,
                                        "binding": level, "supersededVerifierInputs": superseded,
                                        "rawLogEvidencePending": not raw_logs_present,
                                        "checks": _checks(root, path, model, inputs),
                                        "depends": []}
    if set(raw_logs) != used_raw_logs:
        raise ValueError("raw log attestation names an unadmitted model receipt")

    protocol_paths = dict(model_paths)
    for manifest_name, receipt_name in BUNDLES:
        manifest = local(root, manifest_name)
        if manifest.is_file():
            for case in json.loads(manifest.read_text())["cases"]:
                name = case["id"]
                if name in protocol_paths and protocol_paths[name] != receipt_name:
                    raise ValueError("ambiguous protocol receipt: " + name)
                protocol_paths[name] = receipt_name
    for model, receipt in base["facts"].get("protocol_checked", []):
        path = protocol_paths[model]
        inputs, level, superseded = _record(root, path, receipt, model, rechecked=True)
        specs[model + ":" + receipt] = {"path": path, "inputs": inputs,
                                        "binding": level, "supersededVerifierInputs": superseded,
                                        "checks": _checks(root, path, model, inputs),
                                        "rawLogEvidencePending": False, "depends": []}

    path_to_receipts = {}
    for key, spec in specs.items():
        identity = (spec["path"], spec["inputs"][spec["path"]])
        path_to_receipts.setdefault(identity, set()).add(key)
    audit_path = "evidence/research-audit.json"
    audit_sha = digest(local(root, audit_path))
    for observation in observations:
        qualified = "audit:" + observation["id"]
        inputs = {audit_path: audit_sha}
        depends = []
        for item in observation["evidence"]:
            path, expected = item["path"], item["sha256"]
            local(root, path)
            inputs[path] = expected
            depends.extend(path_to_receipts.get((path, expected), ()))
        specs[qualified] = {"path": audit_path, "inputs": inputs,
                            "binding": "recorded", "depends": sorted(set(depends))}

    current = {"validated-catalog": snapshot_identity}
    for spec in specs.values():
        for name in spec["inputs"]:
            if name not in current:
                path = local(root, name)
                if path.is_file():
                    current[name] = digest(path)
    return specs, current
