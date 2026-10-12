"""Recover portable raw evidence for an existing model without rerunning Quint."""
import argparse
import json
from pathlib import Path

from gambit_smp.check_gambit import reuse_model_receipt
from gambit_smp.framework import ROOT, digest
from gambit_smp.protocol_evidence import portable, relative
from gambit_smp.quint_backend import interpret, summarize


def validated(root, case, directory):
    directory = directory.resolve(strict=True)
    directory.relative_to(root.resolve())
    original = directory / "receipt.json"
    rows = reuse_model_receipt(original, case, root / "models/gambit")
    recorded = reuse_model_receipt(root / case["modelReceipt"], case, root / "models/gambit")
    fields = ("case", "variant", "invariant", "initializer", "modelSha256", "exit", "timeout")
    if [{key: row.get(key) for key in fields} for row in rows] != [
            {key: row.get(key) for key in fields} for row in recorded]:
        raise ValueError("original evidence differs from registered model receipt")
    snapshot = directory / (case["id"] + ".qnt")
    if digest(snapshot) != digest(root / "models/gambit" / snapshot.name):
        raise ValueError("original snapshot differs from current model")
    inputs = {str(path.relative_to(root)): digest(path) for path in (
        original, snapshot, root / case["modelReceipt"], root / "models/gambit" / snapshot.name)}
    recovered = []
    for row in rows:
        if row.get("sourceStable") is not True:
            raise ValueError("original model was not stable")
        log = relative(directory, row["log"])
        text = log.read_text()
        accepted, trace = interpret(row["exit"], text, row["timeout"],
            negative=row["variant"] == "old", temporal=row.get("temporal"))
        if not accepted:
            raise ValueError("raw log does not support model admission")
        inputs[str(log.relative_to(root))] = digest(log)
        recovered.append((row, portable(text), trace))
    return snapshot, inputs, recovered


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--case", required=True)
    parser.add_argument("--from-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    cases_path = ROOT / "models/gambit/cases.json"
    case = next(row for row in json.loads(cases_path.read_text())["cases"] if row["id"] == args.case)
    snapshot, inputs, rows = validated(ROOT, case, args.from_dir)
    inputs["models/gambit/cases.json"] = digest(cases_path)
    inputs[Path(__file__).resolve().relative_to(ROOT).as_posix()] = digest(Path(__file__))
    out = args.out.resolve()
    out.relative_to(ROOT)
    out.mkdir(parents=True, exist_ok=False)
    (out / snapshot.name).write_bytes(snapshot.read_bytes())
    logs, observations = [], []
    for row, text, trace in rows:
        log = out / row["log"]
        log.write_text(text)
        logs.append({"name": row["log"], "path": log.relative_to(ROOT).as_posix(), "sha256": digest(log)})
        observations.append({"variant": row["variant"], "states": summarize(text),
                             "temporalChecked": bool(row.get("temporal"))})
        if trace is not None:
            (out / (Path(row["log"]).stem + ".trace.json")).write_text(json.dumps(trace, indent=2) + "\n")
    if any(digest(ROOT / name) != sha for name, sha in inputs.items()):
        raise ValueError("recovery inputs changed")
    attestation = {"model": case["id"], "receipt": case["modelReceipt"],
                   "receiptSha256": digest(ROOT / case["modelReceipt"]), "logs": logs,
                   "modelSnapshot": {"path": (out / snapshot.name).relative_to(ROOT).as_posix(),
                                     "sha256": digest(out / snapshot.name)}}
    receipt = {"schema": "gambit-model-recovery.v1", "inputs": inputs,
               "attestation": attestation, "observations": observations,
               "diagnosticOnly": True, "runtimeAdmitted": False, "releaseAdmitted": False,
               "modelRerun": False, "sourceRefinementProved": False}
    (out / "recovery.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps(attestation))
    print("RAW-MODEL-RECOVERY-OK; runtimeAdmitted=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
