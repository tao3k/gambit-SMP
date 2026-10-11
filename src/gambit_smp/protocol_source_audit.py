"""Source-review facts, kept distinct from finite-model and native admission."""
import json

from gambit_smp.framework import digest
from gambit_smp.protocol_evidence import relative
from gambit_smp.sync_retirement_source import expected

MANIFEST = "evidence/protocol-source-correspondence.json"
ARITIES = {"source_review": 3, "source_review_anchor": 2,
           "source_avoid_route": 2, "source_native_pending": 1}


def check_schedule(saved):
    policies = ("existing-no-destroy", "naive-child-destroy",
                "deferred-drain-contract", "initialization-failure")
    if (saved.get("schema") != "gambit-sync-retirement-schedule.v1"
            or saved.get("compile", {}).get("exit") != 0
            or saved.get("compile", {}).get("timeout") is not False):
        raise ValueError("source-unit compile evidence missing")
    seen = set()
    for row in saved["results"]:
        key = (row.get("policy"), row.get("point"))
        if key in seen or key[0] not in policies or key[1] not in (1, 2):
            raise ValueError("duplicate or unknown source schedule")
        seen.add(key)
        outcome = expected(policies.index(key[0]), key[1])
        if (row.get("actual") != outcome or row.get("expected") != outcome
                or row.get("exit") != 0 or row.get("timeout") is not False):
            raise ValueError("source schedule observation does not support verdict")
    if len(seen) != 8:
        raise ValueError("incomplete source schedules")


def facts(root):
    root = root.resolve()
    document = relative(root, MANIFEST)
    data = json.loads(document.read_text())
    if (data.get("schema") != "gambit-protocol-source-correspondence.v1"
            or data.get("runtimeAdmitted") is not False
            or data.get("releaseAdmitted") is not False):
        raise ValueError("source review cannot admit runtime")
    inputs = {MANIFEST: digest(document)}
    source = relative(root, data["sourceRoot"])
    for name, sha in data["contextInputs"].items():
        path = relative(source, name)
        if digest(path) != sha:
            raise ValueError("source correspondence stale: " + name)
        inputs[str(path.relative_to(root))] = sha
    receipt_path = relative(root, data["sourceUnitReceipt"])
    if digest(receipt_path) != data["sourceUnitReceiptSha256"]:
        raise ValueError("source-unit receipt differs")
    saved = json.loads(receipt_path.read_text())
    if (saved.get("status") != "source-schedule-observed" or saved.get("sourceStable") is not True
            or saved.get("runtimeAdmitted") is not False or len(saved.get("results", [])) != 8
            or not all(row.get("matched") is True for row in saved["results"])):
        raise ValueError("incomplete source-unit evidence")
    check_schedule(saved)
    inputs[data["sourceUnitReceipt"]] = digest(receipt_path)
    for name, sha in saved["inputs"].items():
        if digest(relative(root, name)) != sha:
            raise ValueError("source-unit input changed: " + name)
        inputs[name] = sha
    result = {name: [] for name in ARITIES}
    models, ids = set(), set()
    allowed = {"gc_epoch_work_bridge", "gc_scan_claim_transfer", "sync_retirement_drain", "vm_configuration_contract"}
    for row in data["observations"]:
        model, name, status = row["model"], row["id"], row["status"]
        if (model not in allowed or name in ids or not row["finding"] or not row["next"]
                or status not in ("implemented-local", "repair-required", "unresolved-origin")):
            raise ValueError("invalid source correspondence row")
        models.add(model)
        ids.add(name)
        result["source_review"].append((model, name, status))
        for anchor in row["anchors"]:
            path, number = anchor.rsplit(":", 1)
            if path not in data["contextInputs"] or not 0 < int(number) <= len(relative(source, path).read_text().splitlines()):
                raise ValueError("source anchor outside reviewed input")
            result["source_review_anchor"].append((name, anchor))
        result["source_avoid_route"].extend((name, route) for route in row["avoid"])
    if models != allowed:
        raise ValueError("all four model/source correspondences required")
    result["source_native_pending"] = [(gate,) for gate in data["nativeGates"]]
    return result, inputs
