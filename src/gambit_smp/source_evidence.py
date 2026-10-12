"""Publish/check source-component receipts without deriving native admission."""
import argparse
from copy import deepcopy
import json
from pathlib import Path
import re

from gambit_smp.framework import ROOT, digest
from gambit_smp.gc_wait_source import matched
from gambit_smp.protocol_evidence import portable, relative


def validate(root, record):
    if (record.get("schema") != "gambit-gc-wait-source-schedule.v1"
            or record.get("status") != "source-schedule-observed"
            or record.get("diagnosticOnly") is not True
            or record.get("runtimeAdmitted") is not False
            or record.get("releaseAdmitted") is not False
            or record.get("sourceStable") is not True
            or record.get("configuredCompilerVerified") is not True):
        raise ValueError("not checked diagnostic component evidence")
    compile_result = record.get("compile", {})
    if type(compile_result.get("exit")) is not int or compile_result["exit"] != 0 or compile_result.get("timeout") is not False:
        raise ValueError("component did not compile")
    if "gcc" not in record.get("compiler", "").lower() or "clang" in record["compiler"].lower():
        raise ValueError("GNU compiler evidence required")
    for key in ("binarySha256", "compilerSha256"):
        if not re.fullmatch(r"[0-9a-f]{64}", record.get(key, "")):
            raise ValueError("component/compiler digest required")
    inputs = record.get("inputs", {})
    required = {"models/gambit/native/gc_wait_notification_schedule.c",
                "src/gambit_smp/gc_wait_source.py", "evidence/gc-wait-notification.json",
                "evidence/model-results/gc-wait-notification/receipt.json"}
    if not required.issubset(inputs):
        raise ValueError("component model/fixture/adapter bindings missing")
    for name, sha in inputs.items():
        if digest(relative(root, name)) != sha:
            raise ValueError("component input is stale: " + name)
    rows = record.get("results", [])
    if len(rows) != 3 or {row.get("point") for row in rows} != {1, 2, 3}:
        raise ValueError("complete unique schedule matrix required")
    for row in rows:
        if (type(row.get("exit")) is not int or row["exit"] != 0
                or row.get("timeout") is not False or row.get("matched") is not True
                or not matched(row["point"], row.get("actual"))):
            raise ValueError("component output contradicts its verdict")


def checked(root, path):
    record = json.loads(path.read_text())
    validate(root, record)
    for row in [record["compile"], *record["results"]]:
        log = relative(path.parent, row["log"])
        if digest(log) != row["logSha256"]:
            raise ValueError("component log digest differs")
        if "actual" in row and json.loads(log.read_text()) != row["actual"]:
            raise ValueError("component log differs from recorded output")
    return record


def facts(root, checked_models):
    manifest_path = root / "evidence/source-observations.json"
    if not manifest_path.is_file():
        return [], {}
    manifest = json.loads(manifest_path.read_text())
    if manifest.get("schema") != "gambit-source-observations.v1":
        raise ValueError("unknown source observation manifest")
    inputs = {manifest_path.relative_to(root).as_posix(): digest(manifest_path)}
    result, seen = [], set()
    for entry in manifest["observations"]:
        pair = (entry["model"], entry["receipt"])
        if pair in seen or entry["model"] != "gc_wait_notification":
            raise ValueError("duplicate/unsupported source observation")
        seen.add(pair)
        path = relative(root, entry["receipt"])
        if entry["model"] not in checked_models or not path.is_file():
            continue
        inputs[entry["receipt"]] = digest(path)
        try:
            record = checked(root, path)
        except (ValueError, KeyError, OSError, TypeError):
            continue
        inputs.update(record["inputs"])
        for row in record["results"]:
            log = relative(path.parent, row["log"])
            inputs[log.relative_to(root).as_posix()] = digest(log)
            result.append((entry["model"], "POSIX-source-schedule-" + str(row["point"]),
                           digest(path), digest(log)))
        compile_log = relative(path.parent, record["compile"]["log"])
        inputs[compile_log.relative_to(root).as_posix()] = digest(compile_log)
    return result, inputs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--from-dir", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    record = json.loads((args.from_dir / "receipt.json").read_text())
    validate(ROOT, record)
    if digest(args.from_dir / "schedule") != record["binarySha256"]:
        raise ValueError("compiled component binary differs")
    saved = deepcopy(record)
    saved["rawReceiptSha256"] = digest(args.from_dir / "receipt.json")
    logs = [(saved["compile"], "compile.log")]
    logs.extend((row, "point-" + str(row["point"]) + ".log") for row in saved["results"])
    contents = {}
    for row, name in logs:
        raw = (args.from_dir / name).read_text()
        if "actual" in row and json.loads(raw) != row["actual"]:
            raise ValueError("raw log contradicts result")
        contents[name] = portable(raw)
        row.update(log=name, rawLogSha256=digest(args.from_dir / name))
    args.out.mkdir(parents=True, exist_ok=False)
    for name, content in contents.items():
        (args.out / name).write_text(content)
    for row, name in logs:
        row["logSha256"] = digest(args.out / name)
    (args.out / "receipt.json").write_text(json.dumps(saved, indent=2) + "\n")
    checked(ROOT, args.out / "receipt.json")
    print("SOURCE-COMPONENT-EVIDENCE-OK; runtimeAdmitted=false")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
