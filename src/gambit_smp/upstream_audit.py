#!/usr/bin/env python3
"""Validate a downloaded PR's complete diff inventory without applying it."""
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import subprocess


def role(name):
    if name in ("configure", "configure.ac"):
        return "build-configuration"
    if name.endswith(".scm"):
        return "scheme-source"
    if name.endswith(".c") and Path(name).name.startswith("_"):
        return "generated-c"
    if name.endswith(".c"):
        return "runtime-c"
    return "report-or-other"


def inventory(directory):
    files = json.loads((directory / "files.json").read_text())
    output = subprocess.check_output(["git", "apply", "--numstat", str((directory / "full.diff").resolve())], text=True)
    rows = list(csv.reader(io.StringIO(output), delimiter="\t"))
    actual = {name: (int(added), int(deleted)) for added, deleted, name in rows}
    if len(actual) != len(rows) or len(files) != len(actual):
        raise ValueError("missing or duplicate diff files")
    result = []
    for file in files:
        name = file["filename"]
        if actual.get(name) != (file["additions"], file["deletions"]):
            raise ValueError("diff/API coverage mismatch: " + name)
        result.append({"file": name, "role": role(name), "additions": file["additions"],
                       "deletions": file["deletions"], "blobSha": file["sha"]})
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--input", type=runtime_argument, required=True)
    parser.add_argument("--head", required=True)
    parser.add_argument("--base", required=True)
    args = parser.parse_args()
    metadata = json.loads((args.input / "pr.json").read_text())
    if metadata["head"]["sha"] != args.head or metadata["base"]["sha"] != args.base:
        raise ValueError("downloaded PR identity does not match declared head/base")
    rows = inventory(args.input)
    if metadata["changed_files"] != len(rows):
        raise ValueError("PR metadata/file inventory coverage mismatch")
    receipt = {"schema": "upstream-pr-diff-audit.v1", "head": args.head, "base": args.base,
               "coverage": "all-api-files-match-full-diff-numstat", "applied": False,
               "diffSha256": hashlib.sha256((args.input / "full.diff").read_bytes()).hexdigest(),
               "files": rows}
    (args.input / "inventory.json").write_text(json.dumps(receipt, indent=2) + "\n")
    counts = {kind: sum(row["role"] == kind for row in rows) for kind in {row["role"] for row in rows}}
    print("UPSTREAM-INVENTORY-OK", len(rows), json.dumps(counts, sort_keys=True))


if __name__ == "__main__":
    main()
