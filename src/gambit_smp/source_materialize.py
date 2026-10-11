"""Reproduce a pinned runtime source slice; never qualify built artifacts."""
import argparse
import difflib
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

from gambit_smp.framework import ROOT, apply_untracked_patch, digest, relative

LOCK = ROOT / "evidence/runtime-source.lock.json"
FILES = ("lib/mem.c", "lib/setup.c", "include/gambit.h.in")


def revision(checkout):
    return subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"],
                                   text=True, timeout=10).strip()


def export(checkout, candidate, lock_path, patch_path):
    if lock_path.exists() or patch_path.exists():
        raise ValueError("refusing to overwrite source lock or snapshot overlay")
    commit = revision(checkout)
    patches, files = [], {}
    for name in FILES:
        base = subprocess.check_output(["git", "-C", str(checkout), "show", commit + ":" + name],
                                       timeout=10)
        current = (candidate / name).read_bytes()
        patches.extend(difflib.unified_diff(base.decode().splitlines(True),
            current.decode().splitlines(True), "a/" + name, "b/" + name))
        files[name] = {"baseSha256": hashlib.sha256(base).hexdigest(),
                       "candidateSha256": hashlib.sha256(current).hexdigest()}
    overlay = "".join(patches)
    if not overlay:
        raise ValueError("empty source snapshot delta")
    # Prove the generated overlay restores exactly these bytes before publishing.
    with tempfile.TemporaryDirectory(dir=ROOT / ".data") as temporary:
        target = Path(temporary)
        for name in FILES:
            data = subprocess.check_output(["git", "-C", str(checkout), "show", commit + ":" + name],
                                           timeout=10)
            path = target / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        apply_untracked_patch(target, overlay.encode(), set(FILES))
        if any(digest(target / name) != row["candidateSha256"] for name, row in files.items()):
            raise ValueError("snapshot overlay does not reproduce candidate bytes")
    patch_path.parent.mkdir(parents=True, exist_ok=True)
    patch_path.write_text(overlay)
    record = {"schema": "gambit-runtime-source-lock.v1",
              "repository": "https://git.cons.io/mighty-gerbils/gambit.git",
              "revision": commit, "submodule": "vendor/gambit",
              "patch": str(patch_path.resolve().relative_to(ROOT)),
              "patchSha256": digest(patch_path), "files": files,
              "scope": "candidate027 audited source slice; other source files remain upstream",
              "configuredToolchainReproduced": False,
              "runtimeAdmitted": False, "releaseAdmitted": False}
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(json.dumps(record, indent=2) + "\n")
    return record


def materialize(lock_path, out):
    lock_hash = digest(lock_path)
    lock = json.loads(lock_path.read_text())
    if (lock.get("schema") != "gambit-runtime-source-lock.v1" or
            not re.fullmatch(r"[0-9a-f]{40}", lock["revision"]) or
            set(lock["files"]) != set(FILES) or
            lock.get("runtimeAdmitted") is not False or
            lock.get("releaseAdmitted") is not False):
        raise ValueError("invalid source-slice lock")
    checkout = relative(ROOT, lock["submodule"])
    patch = relative(ROOT, lock["patch"])
    if revision(checkout) != lock["revision"] or digest(patch) != lock["patchSha256"]:
        raise ValueError("source revision or snapshot overlay drift")
    if out.exists():
        raise ValueError("fresh output directory required")
    patch_bytes = patch.read_bytes()
    # Archive the commit, not a potentially dirty checkout or build cache.
    archive = subprocess.check_output(["git", "-C", str(checkout), "archive", lock["revision"]],
                                      timeout=30)
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="source-", dir=out.parent) as temporary:
        source = Path(temporary) / "source"
        source.mkdir()
        with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
            tree.extractall(source, filter="data")
        if any(digest(source / name) != row["baseSha256"] for name, row in lock["files"].items()):
            raise ValueError("archived base source differs from lock")
        apply_untracked_patch(source, patch_bytes, set(FILES))
        observed = {name: digest(source / name) for name in FILES}
        if any(observed[name] != row["candidateSha256"] for name, row in lock["files"].items()):
            raise ValueError("materialized source differs from candidate slice")
        if (digest(patch) != lock["patchSha256"] or revision(checkout) != lock["revision"] or
                digest(lock_path) != lock_hash):
            raise ValueError("source inputs changed during materialization")
        record = {"schema": "gambit-source-materialization.v1",
                  "sourceLockSha256": lock_hash, "revision": lock["revision"],
                  "files": observed, "status": "source-slice-reproduced",
                  "configuredToolchainReproduced": False,
                  "runtimeAdmitted": False, "releaseAdmitted": False}
        (source / "materialization.json").write_text(json.dumps(record, indent=2) + "\n")
        source.rename(out)
    return record


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lock", type=Path, default=LOCK)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--export-candidate", type=Path,
                        help="explicit one-time source snapshot export, not a repair admission")
    parser.add_argument("--patch", type=Path)
    args = parser.parse_args()
    if args.export_candidate:
        if not args.patch or args.out:
            parser.error("export requires --patch and no --out")
        export(ROOT / "vendor/gambit", args.export_candidate, args.lock, args.patch)
        print("SOURCE-SNAPSHOT-EXPORTED")
    else:
        if not args.out or args.patch:
            parser.error("materialization requires --out and no --patch")
        record = materialize(args.lock, args.out)
        print(json.dumps(record, sort_keys=True))


if __name__ == "__main__":
    main()
