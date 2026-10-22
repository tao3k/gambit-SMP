"""Reproduce a pinned runtime source slice; never qualify built artifacts."""
from gambit_smp.task_processes import check_output as _task_check_output
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
from gambit_smp.source_capabilities import source_name, source_file, validate_source_lock

LOCK = ROOT / "evidence/runtime-source.lock.json"
FILES = ("lib/mem.c", "lib/setup.c", "include/gambit.h.in")
AUDIT_FILES = (*FILES, "configure.ac", "lib/_thread.scm", "lib/mem.h")
COMPOSED_FILES = (*AUDIT_FILES, "lib/_system.scm", "lib/_io.scm", "gsc/_prims.scm",
                  "lib/c_intf.c", "lib/os_io.c")


def revision(checkout):
    return _task_check_output(["git", "-C", str(checkout), "rev-parse", "HEAD"],
                                   text=True, timeout=10).strip()


def export(checkout, candidate, lock_path, patch_path, files=FILES, *, overlay=None):
    if lock_path.exists() or patch_path.exists():
        raise ValueError("refusing to overwrite source lock or snapshot overlay")
    if checkout.resolve() != ROOT.resolve() / "vendor/gambit":
        raise ValueError("canonical Gambit submodule source required")
    commit = revision(checkout)
    if not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("fixed Git revision required")
    selected = set(files)
    if not selected or len(selected) != len(files):
        raise ValueError("nonempty unique source snapshot files required")
    for name in selected:
        source_name(name)
    if overlay is not None:
        from gambit_smp.artifact_storage import cache_path, runtime_output
        scratch = runtime_output(ROOT, cache_path(ROOT, "source-materialize"))
        scratch.mkdir(parents=True, exist_ok=True)
        raw = overlay.read_bytes()
        with tempfile.TemporaryDirectory(dir=scratch) as temporary:
            target = Path(temporary)
            originals = {}
            for name in sorted(selected):
                data = source_file(candidate, name).read_bytes()
                originals[name] = hashlib.sha256(data).hexdigest()
                path = target / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(data)
            try:
                apply_untracked_patch(target, raw, selected)
            except subprocess.CalledProcessError as error:
                detail = error.stderr or error.stdout or b"no patch diagnostic returned"
                if isinstance(detail, bytes):
                    detail = detail.decode("utf-8", errors="replace")
                raise ValueError("source overlay rejected: " + detail.strip()) from error
            if (overlay.read_bytes() != raw or any(
                    digest(source_file(candidate, name)) != sha for name, sha in originals.items())):
                raise ValueError("source or overlay changed during snapshot export")
            # Export the self-contained cumulative delta, never mutate the producer.
            return export(checkout, target, lock_path, patch_path, files)
    patches, files = [], {}
    for name in sorted(selected):
        entry = _task_check_output(["git", "-C", str(checkout), "ls-tree", "-z", commit,
                                         "--", name], timeout=10)
        rows = entry.rstrip(b"\0").split(b"\0")
        if (len(rows) != 1 or b"\t" not in rows[0]
                or rows[0].split(b"\t", 1)[0].split()[:2] not in
                   ([b"100644", b"blob"], [b"100755", b"blob"])
                or rows[0].split(b"\t", 1)[1] != name.encode()):
            raise ValueError("existing regular tracked source file required")
        base = _task_check_output(["git", "-C", str(checkout), "show", commit + ":" + name],
                                       timeout=10)
        current = source_file(candidate, name).read_bytes()
        patches.extend(difflib.unified_diff(base.decode().splitlines(True),
            current.decode().splitlines(True), "a/" + name, "b/" + name))
        files[name] = {"baseSha256": hashlib.sha256(base).hexdigest(),
                       "candidateSha256": hashlib.sha256(current).hexdigest()}
    overlay = "".join(patches)
    if not overlay:
        raise ValueError("empty source snapshot delta")
    # Prove the generated overlay restores exactly these bytes before publishing.
    from gambit_smp.artifact_storage import cache_path, runtime_output
    scratch = runtime_output(ROOT, cache_path(ROOT, "source-materialize"))
    scratch.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=scratch) as temporary:
        target = Path(temporary)
        for name in sorted(selected):
            data = _task_check_output(["git", "-C", str(checkout), "show", commit + ":" + name],
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
    from gambit_smp.fixture_storage import source_capacity
    with source_capacity(out):
        return _materialize(lock_path, out, root=root)


def _materialize(lock_path, out, *, root=None):
    root = ROOT if root is None else Path(root).resolve()
    lock_hash = digest(lock_path)
    from gambit_smp.recipes import read_json, source_path
    lock = read_json(lock_path)
    validate_source_lock(lock)
    if (lock.get("submodule") != "vendor/gambit" or
            lock.get("repository") != "https://git.cons.io/mighty-gerbils/gambit.git"):
        raise ValueError("canonical Gambit submodule source required")
    checkout = relative(root, lock["submodule"])
    patch = source_path(root, lock["patch"])
    if checkout != root / "vendor/gambit":
        raise ValueError("source repository cannot be an alias")
    if revision(checkout) != lock["revision"] or digest(patch) != lock["patchSha256"]:
        raise ValueError("source revision or snapshot overlay drift")
    if out.exists():
        raise ValueError("fresh output directory required")
    patch_bytes = patch.read_bytes()
    # Archive the commit, not a potentially dirty checkout or build cache.
    archive = _task_check_output(["git", "-C", str(checkout), "archive", lock["revision"]],
                                      timeout=30)
    out.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="source-", dir=out.parent) as temporary:
        source = Path(temporary) / "source"
        source.mkdir()
        with tarfile.open(fileobj=io.BytesIO(archive)) as tree:
            tree.extractall(source, filter="data")
        if any(digest(source_file(source, name)) != row["baseSha256"] for name, row in lock["files"].items()):
            raise ValueError("archived base source differs from lock")
        apply_untracked_patch(source, patch_bytes, set(lock["files"]))
        observed = {name: digest(source_file(source, name)) for name in lock["files"]}
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
             root / "src/gambit_smp/framework.py", root / "src/gambit_smp/source_capabilities.py",
             root / "src/gambit_smp/recipes.py")
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
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument)
    parser.add_argument("--export-candidate", type=Path,
                        help="explicit one-time source snapshot export, not a repair admission")
    parser.add_argument("--patch", type=Path)
    parser.add_argument("--overlay", type=Path,
                        help="apply a delta to selected candidate bytes in isolation before export; producer stays unchanged")
    parser.add_argument("--file", action="append",
                        help="explicit existing tracked source files with locked byte identities")
    args = parser.parse_args()
    if args.export_candidate:
        if not args.patch or args.out or (args.overlay and not args.file):
            parser.error("export requires --patch and no --out; --overlay requires explicit --file inventory")
        export(ROOT / "vendor/gambit", args.export_candidate, args.lock, args.patch,
               args.file or FILES, overlay=args.overlay)
        print("SOURCE-SNAPSHOT-EXPORTED")
    else:
        if not args.out or args.patch or args.file or args.overlay:
            parser.error("materialization requires --out and no export options")
        record = materialize(args.lock, args.out)
        print(json.dumps(record, sort_keys=True))


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('materialize-source')(main)

if __name__ == "__main__":
    main()
