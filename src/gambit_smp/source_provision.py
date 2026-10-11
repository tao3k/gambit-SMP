"""Initialize the fixed submodule offline from a versioned shallow source capsule."""
import argparse
import json
from pathlib import Path
import re
import subprocess

from gambit_smp.framework import ROOT, digest, relative

MANIFEST = "evidence/runtime-source-provisioning.json"


def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args],
                                   stderr=subprocess.STDOUT, text=True, timeout=30).strip()


def input_path(root, name):
    path = relative(root, name)
    if ".data" in path.relative_to(root.resolve()).parts or not path.is_file():
        raise ValueError("source capsule must be a repository input, not a cache")
    return path


def validate(root, manifest=MANIFEST):
    record = json.loads(input_path(root, manifest).read_text())
    lock_path = input_path(root, record["sourceLock"])
    lock = json.loads(lock_path.read_text())
    if (record.get("schema") != "gambit-source-provisioning.v1" or
            digest(lock_path) != record["sourceLockSha256"] or
            lock.get("schema") != "gambit-runtime-source-lock.v1" or
            not re.fullmatch(r"[0-9a-f]{40}", record["revision"]) or
            any(record[key] != lock[key] for key in ("revision", "submodule", "repository")) or
            record["shallowBoundary"] != record["revision"] or
            not record["omittedParents"] or
            any(not re.fullmatch(r"[0-9a-f]{40}", p) for p in record["omittedParents"]) or
            any(record.get(key) is not False for key in ("networkReproductionChecked",
                "configuredToolchainReproduced", "runtimeAdmitted", "releaseAdmitted"))):
        raise ValueError("invalid source capsule binding")
    relative(root, record["submodule"])
    bundle = input_path(root, record["bundle"])
    if digest(bundle) != record["bundleSha256"]:
        raise ValueError("source bundle digest drift")
    if git(root, "bundle", "list-heads", str(bundle)).split() != [record["revision"], "HEAD"]:
        raise ValueError("source bundle must expose only the locked HEAD")
    if git(root, "config", "-f", ".gitmodules", "--get",
           f"submodule.{record['submodule']}.url") != record["repository"]:
        raise ValueError("canonical submodule URL drift")
    entry = git(root, "ls-files", "--stage", "--", record["submodule"]).split()
    if entry[:3] != ["160000", record["revision"], "0"]:
        raise ValueError("submodule index does not bind the locked revision")
    return record, lock


def initialize(root, manifest=MANIFEST):
    root = root.resolve()
    record, lock = validate(root, manifest)
    checkout = relative(root, record["submodule"])
    if checkout.exists() and (not checkout.is_dir() or any(checkout.iterdir())):
        raise ValueError("fresh unpopulated submodule required; existing checkout is never modified")
    bundle = input_path(root, record["bundle"])
    # Override transport for this invocation only; keep the canonical URL in .gitmodules.
    git(root, "-c", "protocol.file.allow=always", "-c",
        f"submodule.{record['submodule']}.url={bundle}", "submodule", "update", "--init",
        "--", record["submodule"])
    if git(checkout, "rev-parse", "HEAD") != record["revision"]:
        raise ValueError("initialized source revision drift")
    parents = [line.split()[1] for line in git(checkout, "cat-file", "-p",
               record["revision"]).splitlines() if line.startswith("parent ")]
    if parents != record["omittedParents"]:
        raise ValueError("source capsule shallow boundary does not match commit parents")
    gitdir = Path(git(checkout, "rev-parse", "--absolute-git-dir"))
    if not gitdir.is_relative_to(root):
        raise ValueError("initialized submodule metadata escapes checkout")
    shallow = gitdir / "shallow"
    if shallow.exists():
        raise ValueError("unexpected pre-existing shallow metadata")
    # Git bundle omits the sender's shallow file; restore the explicitly locked boundary.
    shallow.write_text(record["shallowBoundary"] + "\n")
    git(checkout, "fsck", "--full", "--no-reflogs")
    for name, row in lock["files"].items():
        if digest(input_path(root, record["submodule"] + "/" + name)) != row["baseSha256"]:
            raise ValueError("initialized base source digest drift")
    validate(root, manifest)
    return {"schema": "gambit-source-provisioning-receipt.v1",
            "revision": record["revision"], "bundleSha256": record["bundleSha256"],
            "status": "offline-source-tree-reproduced", "fsckPassed": True,
            "shallowHistory": True, "networkReproductionChecked": False,
            "configuredToolchainReproduced": False, "runtimeAdmitted": False,
            "releaseAdmitted": False}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", default=MANIFEST)
    args = parser.parse_args()
    try:
        print(json.dumps(initialize(ROOT, args.manifest), sort_keys=True))
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        parser.exit(1, f"SOURCE-PROVISION-DENY: {error}\n")


if __name__ == "__main__":
    main()
