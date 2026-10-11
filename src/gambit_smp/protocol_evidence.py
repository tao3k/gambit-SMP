"""Publish portable model evidence and recover its source-bound Datalog facts."""
import argparse
import json
from pathlib import Path
import re

from gambit_smp.check_gambit import admitted_model, model_checks, reuse_model_receipt
from gambit_smp.framework import ROOT, digest

MANIFEST = "evidence/protocol-extensions.json"
RECEIPT = "evidence/model-results/protocol-extensions/receipt.json"
BUNDLES = ((MANIFEST, RECEIPT),
           ("evidence/configuration-model.json", "evidence/model-results/configuration-model/receipt.json"),
           ("evidence/continuation-link-model.json", "evidence/model-results/continuation-link-model/receipt.json"),
           ("evidence/continuation-origin-model.json", "evidence/model-results/continuation-origin-model/receipt.json"),
           ("evidence/sync-tree-retirement-model.json", "evidence/model-results/sync-tree-retirement-model/receipt.json"))


def relative(root, name):
    if not isinstance(name, str) or Path(name).is_absolute():
        raise ValueError("relative evidence path required")
    path = (root / name).resolve()
    path.relative_to(root.resolve())
    return path


def portable(text):
    text = text.replace(str(ROOT), "<REPO>").replace(str(Path.home()), "<HOME>")
    return re.sub(r"/(?:private/)?var/folders/[^\s:()]+", "<TMP>", text)


def checked_rows(root, manifest, receipt_path):
    saved = json.loads(receipt_path.read_text())
    if (saved.get("accepted") is not True or saved.get("contextStable") is not True
            or saved.get("runtimeAdmitted") is not False
            or saved.get("native", {}).get("status") != "not-run"
            or saved.get("quintVersion") != manifest["quintVersion"]):
        raise ValueError("protocol receipt is not admitted model-only evidence")
    for name, expected in manifest["contextInputs"].items():
        if saved.get("inputs", {}).get(name) != expected or digest(relative(root, name)) != expected:
            raise ValueError("protocol source or paper context differs")
    result = []
    for case in manifest["cases"]:
        rows = reuse_model_receipt(receipt_path, case, root / "models/gambit")
        for row in rows:
            if row.get("sourceStable") is not True:
                raise ValueError("model changed during checking")
            log = relative(receipt_path.parent, row["log"])
            if row.get("logSha256") != digest(log):
                raise ValueError("protocol log digest mismatch")
            text = log.read_text()
            old = row["variant"] == "old"
            if not admitted_model(row["exit"], text, row["timeout"], old):
                raise ValueError("protocol log does not support verdict")
            if not old and (row.get("temporal") != case["temporal"] or
                    "Finished checking temporal properties" not in text or
                    row.get("states", {}).get("queued") != 0):
                raise ValueError("complete temporal evidence required")
            if old:
                trace = relative(receipt_path.parent, row["trace"])
                if row.get("traceSha256") != digest(trace):
                    raise ValueError("counterexample digest mismatch")
        result.append((case["id"], rows))
    if len(saved["results"]) != sum(len(model_checks(case)) for case in manifest["cases"]):
        raise ValueError("unexpected or missing protocol checks")
    return result


def bundle_facts(root, manifest_name, receipt_name):
    manifest = json.loads((root / manifest_name).read_text())
    result = {"protocol_model": [], "protocol_composes": [], "protocol_source": [], "protocol_paper": [],
              "protocol_control": [], "protocol_checked": []}
    inputs = {manifest_name: digest(root / manifest_name)}
    for case in manifest["cases"]:
        path = root / "models/gambit" / (case["id"] + ".qnt")
        sha = digest(path)
        inputs[str(path.relative_to(root))] = sha
        result["protocol_model"].append((case["id"], sha))
        result["protocol_composes"].extend((case["id"], name) for name in case["composes"])
        result["protocol_source"].extend((case["id"], name) for name in case["source"])
        result["protocol_paper"].extend((case["id"], name) for name in case["papers"])
        result["protocol_control"].extend((case["id"], inv, init)
            for variant, inv, init in model_checks(case) if variant == "old")
    path = root / receipt_name
    if path.is_file():
        # Invalid/stale receipts leave obligations open, never silently green.
        inputs[receipt_name] = digest(path)
        try:
            rows = checked_rows(root, manifest, path)
        except (ValueError, KeyError, OSError):
            return result, inputs
        for name, checks in rows:
            result["protocol_checked"].append((name, digest(path)))
            for row in checks:
                for key in ("log", "trace"):
                    if key in row:
                        evidence = relative(path.parent, row[key])
                        inputs[str(evidence.relative_to(root))] = digest(evidence)
        inputs.update(manifest["contextInputs"])
    return result, inputs


def facts(root):
    result, inputs = {}, {}
    for manifest, receipt in BUNDLES:
        rows, bound = bundle_facts(root, manifest, receipt)
        inputs.update(bound)
        for name, values in rows.items():
            result.setdefault(name, []).extend(values)
    return result, inputs


def publish(source, destination, manifest_path=ROOT / MANIFEST):
    manifest = json.loads(manifest_path.read_text())
    saved = json.loads((source / "receipt.json").read_text())
    if not saved.get("accepted") or not saved.get("contextStable"):
        raise ValueError("cannot publish a failed model campaign as accepted")
    # Source-bound observations must still match before publishing.
    if any(digest(relative(ROOT, name)) != expected for name, expected in saved["inputs"].items()):
        raise ValueError("campaign inputs changed before publication")
    destination.mkdir(parents=True, exist_ok=False)
    for row in saved["results"]:
        log = relative(source, row["log"])
        target = destination / log.name
        target.write_text(portable(log.read_text()))
        row["rawLogSha256"] = digest(log)
        row["logSha256"] = digest(target)
        if row["variant"] == "old":
            name = log.stem + ".trace.json"
            trace = relative(source, name)
            target = destination / name
            target.write_bytes(trace.read_bytes())
            row.update(trace=name, traceSha256=digest(target))
    saved["redaction"] = "repository/home/temp paths replaced in logs; raw log hashes retained"
    saved["publisherSha256"] = digest(Path(__file__))
    receipt = destination / "receipt.json"
    receipt.write_text(json.dumps(saved, indent=2) + "\n")
    try:
        checked_rows(ROOT, manifest, receipt)
    except (ValueError, KeyError, OSError):
        saved["accepted"] = False
        receipt.write_text(json.dumps(saved, indent=2) + "\n")
        raise
    print("PROTOCOL-EVIDENCE-OK")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-dir", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=ROOT / MANIFEST)
    parser.add_argument("--out", type=Path, default=ROOT / Path(RECEIPT).parent)
    args = parser.parse_args()
    publish(args.from_dir.resolve(), args.out.resolve(), args.manifest.resolve())


if __name__ == "__main__":
    main()
