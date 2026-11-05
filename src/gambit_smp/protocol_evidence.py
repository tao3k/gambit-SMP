"""Publish portable model evidence and recover its source-bound Datalog facts."""
import argparse
import json
from pathlib import Path
import re

from gambit_smp.check_gambit import admitted_model, model_checks, reuse_model_receipt
from gambit_smp.framework import ROOT, digest
from gambit_smp.output_observations import recorded, check_model, binding, observe, TRANSCRIPT_SUFFIXES

MANIFEST = "evidence/protocol-extensions.json"
RECEIPT = "evidence/model-results/protocol-extensions/receipt.json"
BUNDLE_REGISTRY = "evidence/protocol-bundles.json"


def load_bundles(root):
    saved = json.loads((root / BUNDLE_REGISTRY).read_text())
    if saved.get("schema") != "gambit-protocol-bundles.v1":
        raise ValueError("unknown protocol bundle registry")
    rows = saved.get("bundles")
    if not isinstance(rows, list) or not rows:
        raise ValueError("nonempty protocol bundle registry required")
    for row in rows:
        if not isinstance(row, list) or len(row) != 2:
            raise ValueError("manifest/receipt pair required")
        for name in row:
            if (not isinstance(name, str) or not name or Path(name).is_absolute()
                    or any(part in ("..", ".data") for part in Path(name).parts)):
                raise ValueError("durable relative bundle path required")
    if len({row[0] for row in rows}) != len(rows):
        raise ValueError("unique bundle manifests required")
    return tuple(tuple(row) for row in rows)


BUNDLES = load_bundles(ROOT)


def relative(root, name):
    if not isinstance(name, str) or Path(name).is_absolute():
        raise ValueError("relative evidence path required")
    from gambit_smp.framework import resolved_root
    root = resolved_root(root)
    path = (root / name).resolve()
    path.relative_to(root)
    return path


def portable(text):
    text = text.replace(str(ROOT), "<REPO>").replace(str(Path.home()), "<HOME>")
    return re.sub(r"/(?:private/)?var/folders/[^\s:()]+", "<TMP>", text)


def model_snapshot_files(source, inputs):
    files = {}
    for name, expected in inputs.items():
        if not name.startswith("models/gambit/") or not name.endswith(".qnt"):
            continue
        if any(part in ("..", ".data") for part in Path(name).parts):
            raise ValueError("durable model input required")
        artifact = "source/" + Path(name).name
        if artifact in files:
            raise ValueError("model snapshot basename collision")
        snapshot = relative(source, Path(name).name)
        if digest(snapshot) != expected:
            raise ValueError("model snapshot differs from checked input")
        files[artifact] = snapshot
    return files


def checked_rows(root, manifest, receipt_path):
    if any(case.get("registrationOnly") is True for case in manifest["cases"]):
        raise ValueError("registration-only metadata cannot admit a protocol receipt")
    saved = json.loads(receipt_path.read_text())
    if (saved.get("accepted") is not True or saved.get("contextStable") is not True
            or saved.get("runtimeAdmitted") is not False
            or saved.get("native", {}).get("status") != "not-run"
            or saved.get("quintVersion") != manifest["quintVersion"]):
        raise ValueError("protocol receipt is not admitted model-only evidence")
    for name, expected in manifest["contextInputs"].items():
        if saved.get("inputs", {}).get(name) != expected or digest(relative(root, name)) != expected:
            raise ValueError("protocol source or paper context differs")
    if "modelSources" in saved:
        expected = {"source/" + Path(name).name: sha for name, sha in saved["inputs"].items()
                    if name.startswith("models/gambit/") and name.endswith(".qnt")}
        if saved["modelSources"] != expected or any(
                digest(relative(receipt_path.parent, name)) != sha for name, sha in expected.items()):
            raise ValueError("portable model source inventory differs")
    result = []
    for case in manifest["cases"]:
        rows = reuse_model_receipt(receipt_path, case, root / "models/gambit")
        for row in rows:
            if row.get("sourceStable") is not True:
                raise ValueError("model changed during checking")
            log = relative(receipt_path.parent, row["log"])
            old = row["variant"] == "old"
            output = recorded(root, log, row.get('logSha256'), outputs=saved.get('outputs') or
                ({row['log']: row['outputObservation']} if 'outputObservation' in row else None))
            check_model(output, row, temporal=None if old else case['temporal'])
            checked_artifacts(receipt_path.parent, row)
            if old:
                trace = relative(receipt_path.parent, row["trace"])
                if row.get("traceSha256") != digest(trace):
                    raise ValueError("counterexample digest mismatch")
        result.append((case["id"], rows))
    if len(saved["results"]) != sum(len(model_checks(case)) for case in manifest["cases"]):
        raise ValueError("unexpected or missing protocol checks")
    return result


def checked_artifacts(directory, row):
    checker = row.get("checker")
    if checker is None:
        return {}
    if (checker.get("backend") != "quint-compile-tlc" or
            checker.get("livenessSchedule") != "final" or checker.get("inputsStable") is not True or
            checker.get("phase") != "tlc" or checker.get("modelSha256") != row["modelSha256"]):
        raise ValueError("compiled checker identity is not stable")
    artifacts = {name: relative(directory, name) for name in checker.get("artifacts", {})}
    if len(artifacts) != 2 or sorted(path.suffix for path in artifacts.values()) != [".cfg", ".tla"]:
        raise ValueError("compiled TLA+ and CFG evidence required")
    for name, path in artifacts.items():
        if digest(path) != checker["artifacts"][name]:
            raise ValueError("compiled checker artifact digest mismatch")
        if path.suffix == ".cfg":
            expected = "INIT q_init\nNEXT q_step\nINVARIANT q_inv\n" + (
                "PROPERTY q_temporalProps\n" if row.get("temporal") else "")
            if path.read_text() != expected:
                raise ValueError("compiled checker configuration omitted or changed properties")
    return artifacts


def bundle_facts(root, manifest_name, receipt_name):
    manifest = json.loads((root / manifest_name).read_text())
    result = {"protocol_model": [], "protocol_composes": [], "protocol_source": [], "protocol_paper": [],
              "protocol_control": [], "protocol_checked": [], "protocol_obligation": []}
    inputs = {manifest_name: digest(root / manifest_name)}
    for case in manifest["cases"]:
        path = root / "models/gambit" / (case["id"] + ".qnt")
        sha = digest(path)
        inputs[str(path.relative_to(root))] = sha
        result["protocol_model"].append((case["id"], sha))
        result["protocol_composes"].extend((case["id"], name) for name in case["composes"])
        result["protocol_obligation"].extend((case["id"], name) for name in case.get("openObligations", []))
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
                        if key == 'log':
                            if saved_outputs := json.loads(path.read_text()).get('outputs'):
                                recorded(root, evidence, row.get('logSha256'), outputs=saved_outputs)
                            else:
                                inputs.update(binding(root, evidence, row['logSha256']))
                        else:
                            inputs[str(evidence.relative_to(root))] = digest(evidence)
                for artifact in checked_artifacts(path.parent, row).values():
                    inputs[str(artifact.relative_to(root))] = digest(artifact)
        inputs.update(manifest["contextInputs"])
        saved = json.loads(path.read_text())
        for name, sha in saved.get("modelSources", {}).items():
            artifact = relative(path.parent, name)
            inputs[str(artifact.relative_to(root))] = sha
    return result, inputs


def facts(root):
    if load_bundles(root) != BUNDLES:
        raise ValueError("protocol bundle registry changed after loading")
    result, inputs = {}, {BUNDLE_REGISTRY: digest(root / BUNDLE_REGISTRY)}
    for manifest, receipt in BUNDLES:
        rows, bound = bundle_facts(root, manifest, receipt)
        inputs.update(bound)
        for name, values in rows.items():
            result.setdefault(name, []).extend(values)
    rows, bound = report_links(root, dict(result.get("protocol_model", [])))
    result["protocol_report"] = rows
    inputs.update(bound)
    return result, inputs


def report_links(root, models):
    """Exact-head contract slices; existence of a link is not a proof verdict."""
    name = "evidence/protocol-report-links.json"
    path = root / name
    if not path.is_file():
        return [], {}
    saved = json.loads(path.read_text())
    if saved.get("schema") != "gambit-protocol-report-links.v1":
        raise ValueError("unknown protocol report-link schema")
    contexts = {}
    for manifest_name, _ in BUNDLES:
        manifest = json.loads((root / manifest_name).read_text())
        for case in manifest["cases"]:
            contexts[case["id"]] = manifest["contextInputs"]
    rows, seen, inputs = [], set(), {name: digest(path)}
    for link in saved["links"]:
        model, report = link["model"], link["report"]
        pair = (model, report)
        if model not in models or type(report) is not int or report <= 0 or pair in seen:
            raise ValueError("unknown, duplicate or invalid protocol report link")
        seen.add(pair)
        if link["modelSha256"] != models[model]:
            raise ValueError("protocol report link refers to changed model")
        snapshot = relative(root, link["snapshot"])
        sha = digest(snapshot)
        if sha != link["snapshotSha256"]:
            raise ValueError("protocol report snapshot changed")
        observed = json.loads(snapshot.read_text())
        if (observed.get("number") != report or observed.get("head") != link["head"]
                or not re.fullmatch(r"[0-9a-f]{40}", link["head"])):
            raise ValueError("protocol report head differs from snapshot")
        relative(root, link["contextInput"])
        if contexts[model].get(link["contextInput"]) != sha:
            raise ValueError("protocol model does not bind the linked report snapshot")
        inputs[link["snapshot"]] = sha
        rows.append((model, report, link["head"], sha))
    return rows, inputs


def publish(source, destination, manifest_path=ROOT / MANIFEST):
    manifest = json.loads(manifest_path.read_text())
    saved = json.loads((source / "receipt.json").read_text())
    if not saved.get("accepted") or not saved.get("contextStable"):
        raise ValueError("cannot publish a failed model campaign as accepted")
    # Source-bound observations must still match before publishing.
    if any(digest(relative(ROOT, name)) != expected for name, expected in saved["inputs"].items()):
        raise ValueError("campaign inputs changed before publication")
    snapshots = model_snapshot_files(source, saved["inputs"])
    destination.mkdir(parents=True, exist_ok=False)
    saved["modelSources"] = {}
    saved['outputs'] = {}
    for name, snapshot in snapshots.items():
        target = destination / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(snapshot.read_bytes())
        saved["modelSources"][name] = digest(target)
    for row in saved["results"]:
        for name, artifact in checked_artifacts(source, row).items():
            content = artifact.read_text()
            if portable(content) != content:
                raise ValueError("compiled artifact contains nonportable paths")
            target = destination / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(artifact.read_bytes())
        log = relative(source, row["log"])
        output = row.get('outputObservation') or observe(log.read_bytes())
        row["rawLogSha256"] = output['sha256']
        row["logSha256"] = output['sha256']
        saved['outputs'][row['log']] = output
        if row["variant"] == "old":
            name = log.stem + ".trace.json"
            trace = relative(source, name)
            target = destination / name
            target.write_bytes(trace.read_bytes())
            row.update(trace=name, traceSha256=digest(target))
    saved["redaction"] = "raw logs remain in Cache; only typed output observations are published"
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


def archive_attempt(source, destination):
    """Preserve a DENY or diagnostic campaign without creating model admission."""
    receipt = relative(source, "receipt.json")
    saved = json.loads(receipt.read_text())
    symbolic_diagnostic = (saved.get("schema") == "gc-induction-obligation.v1" and
        saved.get("scope") == "safety-candidate-one-step-closure-only-not-complete-proof" and
        saved.get("runtimeAdmitted") is False and saved.get("releaseAdmitted") is False and
        saved.get("temporalProved") is False)
    if (saved.get("accepted") is not False or
            (saved.get("native", {}).get("status") != "not-run" and not symbolic_diagnostic)):
        raise ValueError("archive requires non-admitted model-only attempt")
    relative(ROOT, str(destination.resolve().relative_to(ROOT)))
    files = {receipt.name: receipt}
    outputs = {}
    files.update(model_snapshot_files(source, saved.get("inputs", {})))
    if saved.get("schema") in ("gambit-induction-matrix-result.v1", "gc-necessary-guard-audit.v1",
                               "gc-definedness-controls-audit.v1"):
        ir_inputs = {"protocol-ir.json": saved["protocolIrSha256"]}
        contract = saved.get("generatorContract")
        if saved.get("proofIrSha256"):
            ir_inputs["proof-ir.json"] = saved["proofIrSha256"]
        if contract is not None:
            ir_inputs["proof-ir.json"] = contract["proofIrSha256"]
        for name, expected in ir_inputs.items():
            artifact = relative(source, name)
            if digest(artifact) != expected:
                raise ValueError("archived public IR differs from receipt")
            parsed = json.loads(artifact.read_text())
            if parsed.get("stage") != "parsing" or parsed.get("errors"):
                raise ValueError("archived public IR is not a successful parse")
            files[name] = artifact
    for name, expected in saved.get("modelInputs", {}).items():
        if not name.endswith(".qnt"):
            raise ValueError("additional model snapshot must be Quint source")
        snapshot = relative(source, name)
        if digest(snapshot) != expected:
            raise ValueError("additional model snapshot differs from receipt")
        files[name] = snapshot
    rows = saved.get("results")
    if rows is None and symbolic_diagnostic:
        # Retain older diagnostic receipts byte-for-byte; this only supplies the
        # archive file list and does not manufacture a native or proof verdict.
        log = relative(source, saved["log"])
        if digest(log) != saved["logSha256"]:
            raise ValueError("symbolic diagnostic log differs from receipt")
        name = "gc_recursive_queue_induction.qnt"
        rows = [{"case": "gc_recursive_queue_induction",
                 "modelSha256": saved["modelInputs"][name], "log": saved["log"]}]
    if not isinstance(rows, list):
        raise ValueError("archive requires diagnostic check rows")
    for row in rows:
        case = row["case"]
        if not re.fullmatch(r"[a-z][a-z0-9_]*", case):
            raise ValueError("invalid archived model case")
        snapshot = relative(source, case + ".qnt")
        if digest(snapshot) != row["modelSha256"]:
            raise ValueError("archived model snapshot differs from receipt")
        files[snapshot.name] = snapshot
        # A denied compilation may not have produced both artifacts yet; retain
        # every recorded artifact without treating its presence as acceptance.
        for name, expected in row.get("checker", {}).get("artifacts", {}).items():
            artifact = relative(source, name)
            if digest(artifact) != expected or portable(artifact.read_text()) != artifact.read_text():
                raise ValueError("archived checker artifact drift or nonportable path")
            files[name] = artifact
        log = relative(source, row["log"])
        if row.get("logSha256") and digest(log) != row["logSha256"]:
            raise ValueError("archived diagnostic log differs from receipt")
        outputs[log.name] = observe(log.read_bytes())
        trace = log.with_suffix(".trace.json")
        if trace.exists():
            files[trace.name] = trace
    destination.mkdir(parents=True, exist_ok=False)
    record = {"schema": "gambit-model-attempt-archive.v1", "archiveOnly": True,
              "accepted": False, "runtimeAdmitted": False, "releaseAdmitted": False,
              "originalReceiptSha256": digest(receipt), "files": {}, 'outputs': outputs}
    for name, path in files.items():
        content = path.read_text()
        (destination / name).parent.mkdir(parents=True, exist_ok=True)
        (destination / name).write_text(portable(content))
        record["files"][name] = {"rawSha256": digest(path),
                                  "portableSha256": digest(destination / name)}
    (destination / "archive.json").write_text(json.dumps(record, indent=2) + "\n")
    print("MODEL-ATTEMPT-ARCHIVED-NOT-ADMITTED")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-dir", required=True, type=Path)
    parser.add_argument("--manifest", type=Path, default=ROOT / MANIFEST)
    parser.add_argument("--out", type=Path, default=ROOT / Path(RECEIPT).parent)
    parser.add_argument("--archive-attempt", action="store_true",
                        help="retain denied/diagnostic logs and model snapshots; no protocol admission")
    args = parser.parse_args()
    if args.archive_attempt:
        archive_attempt(args.from_dir.resolve(), args.out.resolve())
    else:
        publish(args.from_dir.resolve(), args.out.resolve(), args.manifest.resolve())


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('publish-protocol')(main)

if __name__ == "__main__":
    main()
