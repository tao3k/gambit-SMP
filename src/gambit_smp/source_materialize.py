"""Reproduce a pinned runtime source slice; never qualify built artifacts."""
import argparse
from contextlib import contextmanager
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
AUDIT_FILES = (*FILES, "configure.ac", "lib/_thread.scm")


def revision(checkout):
    return subprocess.check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"],
                                   text=True, timeout=10).strip()


def export(checkout, candidate, lock_path, patch_path, files=FILES):
    if lock_path.exists() or patch_path.exists():
        raise ValueError("refusing to overwrite source lock or snapshot overlay")
    commit = revision(checkout)
    selected = set(files)
    if not set(FILES) <= selected <= set(AUDIT_FILES):
        raise ValueError("unsupported source snapshot files")
    patches, files = [], {}
    for name in sorted(selected):
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
        for name in sorted(selected):
            data = subprocess.check_output(["git", "-C", str(checkout), "show", commit + ":" + name],
                                           timeout=10)
            path = target / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(data)
        apply_untracked_patch(target, overlay.encode(), selected)
        if any(digest(target / name) != row["candidateSha256"] for name, row in files.items()):
            raise ValueError("snapshot overlay does not reproduce candidate bytes")
    patch_path.parent.mkdir(parents=True, exist_ok=True)
    patch_path.write_text(overlay)
    record = {"schema": "gambit-runtime-source-lock.v1",
              "repository": "https://git.cons.io/mighty-gerbils/gambit.git",
              "revision": commit, "submodule": "vendor/gambit",
              "patch": str(patch_path.resolve().relative_to(ROOT)),
              "patchSha256": digest(patch_path), "files": files,
              "scope": "audited source slice; other source files remain upstream",
              "configuredToolchainReproduced": False,
              "runtimeAdmitted": False, "releaseAdmitted": False}
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.write_text(json.dumps(record, indent=2) + "\n")
    return record


def materialize(lock_path, out, *, root=None):
    root = ROOT if root is None else Path(root).resolve()
    lock_hash = digest(lock_path)
    lock = json.loads(lock_path.read_text())
    if (lock.get("schema") != "gambit-runtime-source-lock.v1" or
            not re.fullmatch(r"[0-9a-f]{40}", lock["revision"]) or
            not set(FILES) <= set(lock["files"]) <= set(AUDIT_FILES) or
            lock.get("runtimeAdmitted") is not False or
            lock.get("releaseAdmitted") is not False):
        raise ValueError("invalid source-slice lock")
    checkout = relative(root, lock["submodule"])
    patch = relative(root, lock["patch"])
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
        apply_untracked_patch(source, patch_bytes, set(lock["files"]))
        observed = {name: digest(source / name) for name in lock["files"]}
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


@contextmanager
def locked_source(root, name):
    """Resolve versioned inputs into disposable source, never cache authority."""
    root = Path(root).resolve()
    lock_path = relative(root, name)
    lock = json.loads(lock_path.read_text())
    patch_path = relative(root, lock["patch"])
    paths = (lock_path, patch_path, root / "src/gambit_smp/source_materialize.py",
             root / "src/gambit_smp/framework.py")
    if any(".data" in path.relative_to(root).parts for path in paths):
        raise ValueError("source inputs must be versioned, not cache paths")
    inputs = {str(path.relative_to(root)): digest(path) for path in paths}
    with tempfile.TemporaryDirectory(prefix="gambit-source-") as temporary:
        source = Path(temporary) / "source"
        materialize(lock_path, source, root=root)
        yield source, inputs
        if (any(digest(root / path) != sha for path, sha in inputs.items()) or
                revision(relative(root, lock["submodule"])) != lock["revision"]):
            raise ValueError("locked source inputs changed during audit")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lock", type=Path, default=LOCK)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--export-candidate", type=Path,
                        help="explicit one-time source snapshot export, not a repair admission")
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--file", action="append", choices=AUDIT_FILES,
                        help="explicit audited snapshot files; core three remain mandatory")
    args = parser.parse_args()
    if args.export_candidate:
        if not args.patch or args.out:
            parser.error("export requires --patch and no --out")
        export(ROOT / "vendor/gambit", args.export_candidate, args.lock, args.patch,
               args.file or FILES)
        print("SOURCE-SNAPSHOT-EXPORTED")
    else:
        if not args.out or args.patch or args.file:
            parser.error("materialization requires --out and no --patch")
        record = materialize(args.lock, args.out)
        print(json.dumps(record, sort_keys=True))


if __name__ == "__main__":
    main()
