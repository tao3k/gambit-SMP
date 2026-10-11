"""Check portable research inputs without installing ASCENT or using caches."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

from gambit_smp.framework import ROOT
from gambit_smp.paper_cache import paper_pins
from gambit_smp.source_provision import validate as validate_capsule


def portable(root, name):
    path = Path(name)
    target = (root / path).resolve()
    if (path.is_absolute() or ".." in path.parts or ".data" in path.parts or
            not target.is_relative_to(root.resolve()) or
            ".data" in target.relative_to(root.resolve()).parts or not target.is_file()):
        raise ValueError(f"non-portable or missing research input: {name}")
    return target


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   text=True, timeout=10).strip()


def manifest_inputs(root, manifest):
    record = json.loads(portable(root, manifest).read_text())
    context = record["contextInputs"]
    inputs = {manifest}
    for name, expected in context.items():
        if hashlib.sha256(portable(root, name).read_bytes()).hexdigest() != expected:
            raise ValueError(f"model context digest drift: {name}")
        inputs.add(name)
    for case in record.get("cases", []):
        name = "models/gambit/" + case["id"] + ".qnt"
        portable(root, name)
        inputs.add(name)
    return inputs


def inventory(root, require_committed=False):
    """Audit current manifests, without rewriting historical receipt identities."""
    rows = []
    for path in sorted((root / "evidence").glob("*.json")):
        record = json.loads(path.read_text())
        if not isinstance(record, dict) or "contextInputs" not in record:
            continue
        name = path.relative_to(root).as_posix()
        issues = []
        for item in record["contextInputs"]:
            try:
                portable(root, item)
            except ValueError as error:
                issues.append(str(error))
        if not issues:
            try:
                if require_committed:
                    check(root, name, require_committed=True)
                else:
                    manifest_inputs(root, name)
            except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
                issues.append(str(error))
        rows.append({"manifest": name, "portableInputs": not issues,
                     "committedInputsVerified": require_committed and not issues,
                     "issues": issues})
    return {"schema": "gambit-research-portability-inventory.v1", "manifests": rows,
            "portable": sum(row["portableInputs"] for row in rows),
            "blocked": sum(not row["portableInputs"] for row in rows),
            "committedInputsChecked": require_committed, "networkReproductionChecked": False,
            "runtimeAdmitted": False}


def check(root, manifest, require_committed=False):
    root = root.resolve()
    inputs = {"evidence/papers.lock.json", "evidence/runtime-source.lock.json",
              ".gitmodules", manifest}
    inputs.update("src/gambit_smp/" + name + ".py" for name in
                  ("reproduction_check", "paper_cache", "source_materialize",
                   "source_provision", "framework", "__init__"))
    inputs.add("models/gambit/cases.json")
    capsule, _ = validate_capsule(root)
    inputs.update(("evidence/runtime-source-provisioning.json", capsule["bundle"]))
    papers = []
    for name in ("evidence/papers.json", "evidence/papers-audit-expansion.json"):
        papers.extend(json.loads(portable(root, name).read_text())["papers"])
        inputs.add(name)
    pins = paper_pins(portable(root, "evidence/papers.lock.json"), papers, root=root)
    inputs.update(pin["notes"] for pin in pins.values())
    lock = json.loads(portable(root, "evidence/runtime-source.lock.json").read_text())
    if lock.get("schema") != "gambit-runtime-source-lock.v1":
        raise ValueError("unsupported source lock")
    submodule = lock["submodule"]
    portable(root, submodule + "/lib/mem.c")
    if git(root / submodule, "rev-parse", "HEAD") != lock["revision"]:
        raise ValueError("submodule HEAD differs from source lock")
    url = git(root, "config", "-f", ".gitmodules", "--get",
              f"submodule.{submodule}.url")
    if url != lock["repository"]:
        raise ValueError("submodule URL differs from source lock")
    for name, row in lock["files"].items():
        source = submodule + "/" + name
        if hashlib.sha256(portable(root, source).read_bytes()).hexdigest() != row["baseSha256"]:
            raise ValueError(f"submodule source differs from locked base: {name}")
        inputs.add(source)
    inputs.add(lock["patch"])
    if hashlib.sha256(portable(root, lock["patch"]).read_bytes()).hexdigest() != lock["patchSha256"]:
        raise ValueError("source overlay differs from source lock")
    inputs.update(manifest_inputs(root, manifest))
    # Gitlinks own nested source files; the parent repository owns other inputs.
    if require_committed:
        entry = git(root, "ls-tree", "HEAD", "--", submodule).split()
        if entry[:3] != ["160000", "commit", lock["revision"]]:
            raise ValueError("source gitlink is not committed at the locked revision")
        for name in sorted(inputs):
            if name.startswith(submodule + "/"):
                relative = name[len(submodule) + 1:]
                committed = subprocess.check_output(
                    ["git", "-C", str(root / submodule), "show", lock["revision"] + ":" + relative],
                    timeout=10)
            else:
                try:
                    committed = subprocess.check_output(
                        ["git", "-C", str(root), "show", "HEAD:" + name],
                        stderr=subprocess.PIPE, timeout=10)
                except subprocess.CalledProcessError as error:
                    raise ValueError(f"research input is not committed: {name}") from error
            if committed != portable(root, name).read_bytes():
                raise ValueError(f"working input differs from committed bytes: {name}")
    return {"schema": "gambit-research-input-check.v1", "papers": len(pins),
            "sourceRevision": lock["revision"], "inputs": sorted(inputs),
            "committedInputsChecked": require_committed,
            "networkReproductionChecked": False, "runtimeAdmitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default="evidence/gc-recursive-queue-wait.json")
    parser.add_argument("--require-committed", action="store_true")
    parser.add_argument("--inventory", action="store_true",
                        help="audit all current context manifests; exit nonzero if any are blocked")
    args = parser.parse_args()
    try:
        result = (inventory(ROOT, args.require_committed) if args.inventory else
                  check(ROOT, args.manifest, args.require_committed))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"REPRODUCTION-INPUT-DENY: {error}\n")
    print(json.dumps(result, sort_keys=True))
    if args.inventory and result["blocked"]:
        parser.exit(1)


if __name__ == "__main__":
    main()
