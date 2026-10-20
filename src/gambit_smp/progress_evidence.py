"""Bind explicit progress observations without upgrading old safety receipts."""
import argparse
import hashlib
import json
from pathlib import Path

from gambit_smp.check_gambit import admitted_model
from gambit_smp.framework import ROOT, digest
from gambit_smp.model_progress import generated
from gambit_smp.protocol_evidence import portable, relative


MANIFEST = "evidence/progress-obligations.json"


def checked(root, case, receipt):
    root = root.resolve()
    saved = json.loads(receipt.read_text())
    manifest = json.loads((root / MANIFEST).read_text())
    if (saved.get("schema") != "gambit-model-progress-receipt.v1"
            or saved.get("case") != case["id"] or saved.get("accepted") is not True
            or saved.get("sourceStable") is not True or saved.get("runtimeAdmitted") is not False
            or saved.get("quintVersion") != manifest["quintVersion"]):
        raise ValueError("progress receipt is not admitted model-only evidence")
    required = {MANIFEST, "models/gambit/" + case["id"] + ".qnt",
                "src/gambit_smp/model_progress.py", "src/gambit_smp/framework.py",
                "src/gambit_smp/check_gambit.py", "src/gambit_smp/tlc_values.py"}
    inputs = saved.get("inputs", {})
    if not required.issubset(inputs) or any(digest(relative(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("progress observation source context differs")
    rows = saved.get("results", [])
    if len(rows) != 2 or {row["variant"] for row in rows} != {"blocked", "protocol"}:
        raise ValueError("independent blocked and normal checks required")
    original = (root / "models/gambit" / (case["id"] + ".qnt")).read_text()
    for row in rows:
        blocked = row["variant"] == "blocked"
        snapshot = relative(receipt.parent, row["snapshot"])
        expected = hashlib.sha256(generated(original, case, blocked).encode()).hexdigest()
        log = relative(receipt.parent, row["log"])
        if (row.get("accepted") is not True or row.get("snapshotSha256") != expected
                or digest(snapshot) != expected or row.get("logSha256") != digest(log)):
            raise ValueError("progress snapshot or log identity differs")
        text = log.read_text()
        if not admitted_model(row["exit"], text, row["timeout"], blocked):
            raise ValueError("progress log does not support the verdict")
        if blocked:
            trace = relative(receipt.parent, row["trace"])
            value = json.loads(trace.read_text())
            if (digest(trace) != row.get("traceSha256") or value.get("generatedSha256") != expected
                    or value.get("case") != case["id"]):
                raise ValueError("progress control trace differs")
        elif (row.get("temporal") != "obligationProgress"
              or "Finished checking temporal properties" not in text):
            raise ValueError("explicit completed temporal check required")
    return saved


def facts(root):
    root = root.resolve()
    manifest = json.loads((root / MANIFEST).read_text())
    if manifest.get("schema") != "gambit-progress-obligations.v1":
        raise ValueError("unknown progress manifest")
    names = [case["id"] for case in manifest["cases"]]
    if len(set(names)) != len(names):
        raise ValueError("duplicate progress obligation")
    result = {"model_progress_obligation": [], "model_progress_checked": []}
    inputs = {MANIFEST: digest(root / MANIFEST)}
    for case in manifest["cases"]:
        model = relative(root, "models/gambit/" + case["id"] + ".qnt")
        inputs[str(model.relative_to(root))] = digest(model)
        result["model_progress_obligation"].append((case["id"], digest(model), case["scope"]))
        path = root / "evidence/model-results/model-progress" / case["id"] / "receipt.json"
        if not path.exists():
            continue
        inputs[str(path.relative_to(root))] = digest(path)
        try:
            saved = checked(root, case, path)
        except (ValueError, KeyError, OSError):
            continue
        inputs.update(saved["inputs"])
        for row in saved["results"]:
            for key in ("log", "trace", "snapshot"):
                if key in row:
                    item = relative(path.parent, row[key])
                    inputs[str(item.relative_to(root))] = digest(item)
        result["model_progress_checked"].append((case["id"], digest(path)))
    return result, inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-dir", required=True, type=Path)
    args = parser.parse_args()
    source = args.from_dir.resolve()
    saved = json.loads((source / "receipt.json").read_text())
    manifest = json.loads((ROOT / MANIFEST).read_text())
    case = next(case for case in manifest["cases"] if case["id"] == saved["case"])
    checked(ROOT, case, source / "receipt.json")
    target = ROOT / "evidence/model-results/model-progress" / case["id"]
    target.mkdir(parents=True, exist_ok=False)
    for row in saved["results"]:
        log = relative(source, row["log"])
        row["rawLogSha256"] = digest(log)
        copied = target / log.name
        copied.write_text(portable(log.read_text()))
        row["logSha256"] = digest(copied)
        for key in ("snapshot", "trace"):
            if key in row:
                original = relative(source, row[key])
                (target / original.name).write_bytes(original.read_bytes())
    saved["publisherSha256"] = digest(Path(__file__))
    receipt = target / "receipt.json"
    receipt.write_text(json.dumps(saved, indent=2) + "\n")
    try:
        checked(ROOT, case, receipt)
    except (ValueError, KeyError, OSError):
        saved["accepted"] = False
        receipt.write_text(json.dumps(saved, indent=2) + "\n")
        raise
    print("PROGRESS-EVIDENCE-OK")
    return 0


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('publish-progress')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('publish-progress', main))
