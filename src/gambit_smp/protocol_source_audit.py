"""Source-review facts, kept distinct from finite-model and native admission."""
import json
from pathlib import Path

from gambit_smp.framework import digest, relative
from gambit_smp.source_materialize import locked_source

MANIFEST = "evidence/protocol-source-correspondence.json"
ARITIES = {"source_review": 3, "source_review_anchor": 2,
           "source_avoid_route": 2, "source_native_pending": 1}


def check_schedule(saved, root):
    from gambit_smp.observation_contract import evaluate
    if (saved.get("schema") != "gambit-sync-retirement-schedule.v1"
            or saved.get("compile", {}).get("exit") != 0
            or saved.get("compile", {}).get("timeout") is not False):
        raise ValueError("source-unit compile evidence missing")
    answers, inputs, _ = evaluate(root,
        "evidence/research/source-schedule-revalidation/observations.json", saved["results"])
    if any(answers.values()):
        raise ValueError("source schedule observation contract rejected: " +
                         ",".join(name for name, rows in answers.items() if rows))
    return inputs


def facts(root):
    root = root.resolve()
    document = relative(root, MANIFEST)
    data = json.loads(document.read_text())
    if (data.get("schema") != "gambit-protocol-source-correspondence.v1"
            or data.get("runtimeAdmitted") is not False
            or data.get("releaseAdmitted") is not False):
        raise ValueError("source review cannot admit runtime")
    inputs = {MANIFEST: digest(document)}
    if data.get("sourceLock"):
        with locked_source(root, data["sourceLock"]) as (source, source_inputs):
            return source_facts(root, data, source, {**inputs, **source_inputs}, locked=True)
    source = relative(root, data["sourceRoot"])
    if ".data" in source.relative_to(root).parts:
        raise ValueError("source correspondence requires versioned source inputs")
    return source_facts(root, data, source, inputs)


def source_facts(root, data, source, inputs, locked=False):
    root = root.resolve()
    for name, sha in data["contextInputs"].items():
        path = relative(source, name)
        if digest(path) != sha:
            raise ValueError("source correspondence stale: " + name)
        if not locked:
            inputs[str(path.relative_to(root))] = sha
    receipt_path = relative(root, data["sourceUnitReceipt"])
    if digest(receipt_path) != data["sourceUnitReceiptSha256"]:
        raise ValueError("source-unit receipt differs")
    saved = json.loads(receipt_path.read_text())
    historical = {}
    reconstruction_inputs = dict(inputs)
    if data.get("sourceUnitInputArchive"):
        from gambit_smp.historical_inputs import bindings
        historical, paths = bindings(root, receipt_path, data["sourceUnitInputArchive"])
        for path in paths:
            inputs[path.relative_to(root).as_posix()] = digest(path)
    if (saved.get("status") != "source-schedule-observed" or saved.get("sourceStable") is not True
            or saved.get("runtimeAdmitted") is not False):
        raise ValueError("incomplete source-unit evidence")
    inputs.update({Path(name).relative_to(root).as_posix(): sha
                   for name, sha in check_schedule(saved, root).items()})
    if locked and (saved.get("sourceLock") != data["sourceLock"] or
                   saved.get("sourceFileIdentities", {}).get("lib/setup.c") !=
                   data["contextInputs"].get("lib/setup.c")):
        raise ValueError("source-unit receipt does not bind locked source")
    if locked:
        lock_name = data["sourceLock"]
        patch_name = json.loads(relative(root, lock_name).read_text())["patch"]
        for name, sha in reconstruction_inputs.items():
            if name == MANIFEST:
                continue
            recorded = saved.get("inputs", {}).get(name)
            if recorded != sha:
                archived = historical.get(str(root / name))
                if (name in {lock_name, patch_name} or archived is None
                        or digest(archived) != recorded):
                    raise ValueError("source-unit receipt omits locked source inputs")
    inputs[data["sourceUnitReceipt"]] = digest(receipt_path)
    for name, sha in saved["inputs"].items():
        path = historical.get(str(root / name), relative(root, name))
        if digest(path) != sha:
            raise ValueError("source-unit input changed: " + name)
        inputs[path.relative_to(root).as_posix()] = sha
    result = {name: [] for name in ARITIES}
    ids = set()
    for row in data["observations"]:
        model, name, status = row["model"], row["id"], row["status"]
        if (not all(type(value) is str for value in (model, name, status))
                or name in ids or not row["finding"] or not row["next"]):
            raise ValueError("invalid source correspondence row")
        ids.add(name)
        result["source_review"].append((model, name, status))
        for anchor in row["anchors"]:
            path, number = anchor.rsplit(":", 1)
            if path not in data["contextInputs"] or not 0 < int(number) <= len(relative(source, path).read_text().splitlines()):
                raise ValueError("source anchor outside reviewed input")
            result["source_review_anchor"].append((name, anchor))
        result["source_avoid_route"].extend((name, route) for route in row["avoid"])
    from gambit_smp.ascent_program import load_evidence_catalog, query
    requirements_path = relative(root, "evidence/protocol-source-requirements.json")
    requirements_sha = digest(requirements_path)
    requirements = json.loads(requirements_path.read_text())
    if (set(requirements) != {"schema", "models", "statuses"}
            or requirements["schema"] != "ascent.source-review-contract.v1"
            or any(not isinstance(requirements[key], list) or not requirements[key]
                   or any(type(value) is not str for value in requirements[key])
                   or len(set(requirements[key])) != len(requirements[key])
                   for key in ("models", "statuses"))):
        raise ValueError("complete typed source review contract required")
    catalog = load_evidence_catalog(relative(root, "evidence/dsl/source-review-contract.ss"),
        constructor="make-source-review-contract", trusted=True)
    answers = query({"RequiredModel": [[value] for value in requirements["models"]],
                     "AllowedStatus": [[value] for value in requirements["statuses"]],
                     "SourceReview": result["source_review"]}, catalog,
                    {name: name for name in ("MissingModel", "UnknownModel", "UnknownStatus")},
                    reuse_program=True)
    inputs[requirements_path.relative_to(root).as_posix()] = requirements_sha
    inputs.update({Path(path).relative_to(root).as_posix(): sha for path, sha in catalog["sourceInputs"].items()})
    if any(digest(relative(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("source review inputs changed during inference")
    if any(answers.values()):
        raise ValueError("source review contract rejected: " +
                         ",".join(name for name, rows in answers.items() if rows))
    result["source_native_pending"] = [(gate,) for gate in data["nativeGates"]]
    return result, inputs
