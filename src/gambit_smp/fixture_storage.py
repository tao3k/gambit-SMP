"""Bound disposable Gambit source trees; preserve evidence when pruning them."""
from gambit_smp.task_processes import run as _task_run
import argparse
from contextlib import contextmanager
import fcntl
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess


def source_trees(root):
    found = []
    for directory, children, files in os.walk(root, followlinks=False):
        path = Path(directory)
        children[:] = [name for name in children if not (path / name).is_symlink()]
        if (path / "lib/setup.c").is_file() and (path / "include").is_dir():
            found.append(path)
            children[:] = []
    return sorted(found)


@contextmanager
def source_capacity(destination, *, staging=False):
    destination = Path(destination).resolve()
    task = next((parent for parent in destination.parents
                 if parent.parent.name == 'tasks' and parent.parent.parent.name == '.cache'), None)
    if task is not None:
        from gambit_smp.artifact_storage import fixture_root
        root = task.parent.parent.parent
        active_root = os.environ.get('GAMBIT_SMP_TASK_ROOT')
        if active_root:
            if root != Path(active_root).resolve():
                raise ValueError('nested task stores cannot allocate another source tree')
            from gambit_smp.workspace import task_output
            if task_output(root, destination) != destination:
                raise ValueError('source allocation requires current task ownership')
        if staging:
            # Only the incremental materializer opts into a disposable delta.
            yield
            return
        try:
            fixture_root(root, destination)
        except ValueError as error:
            raise ValueError('task source trees require a maintained build product; reuse the producer, not an attempt copy') from error
        if active_root:
            from gambit_smp.work_items import admit
            products = admit(root, task.name, os.environ.get('GAMBIT_SMP_TASK_PROCESS')).get('buildProducts')
            if products is not None and destination.parent.parent.name not in products:
                raise ValueError('source allocation requires a registered build product')
        yield
        return
    managed = next((parent for parent in destination.parents
                    if parent.name == "fixtures" and parent.parent.name in {".cache", ".data"}), None)
    if managed is None:
        yield
        return
    managed.mkdir(parents=True, exist_ok=True)
    with (managed / ".source-capacity.lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        trees = source_trees(managed)
        fixtures = {tree.relative_to(managed).parts[0] for tree in trees}
        fixture = destination.relative_to(managed).parts[0]
        if len(fixtures) >= 2 and fixture not in fixtures:
            raise ValueError("fixture source limit is 2: reuse or prune an inactive fixture first")
        yield


def prune(root, keep, archive, *, apply=False, targets=None, discard=None):
    root = Path(root).resolve(strict=True)
    if not (root.name == "fixtures" and root.parent.name in {".cache", ".data"}
            or root.name == 'fixtures' and root.parent.parent.name == 'tasks'
               and root.parent.parent.parent.name == '.cache'
            or root.name in {".cache", ".data"}):
        raise ValueError("cleanup is restricted to project data stores")
    if root.name in {".cache", ".data"} and targets is None:
        raise ValueError("explicit cleanup targets required")
    lock_path = root / '.source-capacity.lock'
    if root.name == 'fixtures' and root.parent.parent.name == 'tasks':
        locks = root.parent.parent.parent / 'workspace-leases'
        locks.mkdir(exist_ok=True)
        lock_path = locks / ('prune-' + hashlib.sha256(str(root).encode()).hexdigest() + '.lock')
    with lock_path.open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        return _prune(root, keep, archive, apply=apply, targets=targets, discard=discard)


def _prune(root, keep, archive, *, apply=False, targets=None, discard=None):
    root, archive = Path(root).resolve(strict=True), Path(archive).resolve()
    if archive.is_relative_to(root):
        raise ValueError("evidence archive must be outside the cleanup root")
    keep = {Path(path).resolve(strict=True) for path in keep}
    if targets is None:
        trees = source_trees(root)
    else:
        requested = [Path(p) for p in targets]
        if any(p.is_symlink() for p in requested):
            raise ValueError("cleanup target cannot be a symlink")
        trees = sorted({p.resolve(strict=True) for p in requested} | keep)
        if any(not p.is_relative_to(root) or p == root or source_trees(p) != [p] for p in trees):
            raise ValueError("cleanup targets must be inventoried source trees")
    if not keep.issubset(set(trees)):
        raise ValueError("retain inventoried source trees")
    selected = set(trees) if targets is None else {Path(p).resolve(strict=True) for p in targets}
    if not selected.issubset(set(trees)):
        raise ValueError("cleanup targets must be inventoried source trees")
    if targets is not None and any(a == b or a.is_relative_to(b) or b.is_relative_to(a) for a in selected for b in keep):
        raise ValueError("cleanup target is protected")
    targets = sorted(selected - keep)
    discard = {} if discard is None else dict(discard)
    for name, sha in discard.items():
        path = Path(name)
        if (path.is_absolute() or ".." in path.parts or not any((root / path).is_relative_to(p) for p in targets)
                or not isinstance(sha, str) or len(sha) != 64
                or path.suffix in {".json", ".log", ".md", ".out", ".err", ".stdout", ".stderr"}):
            raise ValueError("exact non-evidence discard binding required")
    identities = {path: (path.stat().st_dev, path.stat().st_ino) for path in targets}
    record = {"schema": "fixture-source-prune.v1", "retained": [str(p.relative_to(root)) for p in sorted(keep)],
              "removed": [], "planned": [str(p.relative_to(root)) for p in targets],
              "evidencePreserved": False, "runtimeAdmission": False,
              "discardBindings": discard, "inventories": {}}
    if not apply:
        return record
    # lsof includes cwd and executable mappings, not just explicitly open files.
    observed = _task_run(["lsof", "-n", "-P", "-F", "n"], capture_output=True, text=True, timeout=60)
    if observed.returncode not in (0, 1) or not observed.stdout:
        raise ValueError("cannot inspect active files; refusing cleanup")
    active = [line[1:] for line in observed.stdout.splitlines() if line.startswith("n/")]
    protected = []
    git_protected = []
    for target in targets:
        if target.is_symlink() or (target.stat().st_dev, target.stat().st_ino) != identities[target]:
            raise ValueError("source tree identity changed during cleanup")
        if any(name == str(target) or name.startswith(str(target) + "/") for name in active):
            protected.append(target)
            continue
        if any(Path(directory, ".git").exists() for directory, _, _ in os.walk(target)):
            git_protected.append(target)
    targets = [target for target in targets if target not in protected and target not in git_protected]
    record["activeProtected"] = [str(path.relative_to(root)) for path in protected]
    record["gitProtected"] = [str(path.relative_to(root)) for path in git_protected]
    archive.mkdir(parents=True, exist_ok=True)
    receipt = archive / "receipt.json"
    if receipt.exists():
        raise ValueError("cleanup receipt already exists")
    receipt.write_text(json.dumps(record, indent=2) + "\n")
    store = root.parent if root.name == 'fixtures' else root
    if root.name == 'fixtures' and root.parent.parent.name == 'tasks':
        store = root.parent.parent.parent
    lease_root = store / 'workspace-leases'
    lease_root.mkdir(exist_ok=True)
    for target in targets:
        key = hashlib.sha256(str(target).encode()).hexdigest()
        if (lease_root / (key + ".quarantine.json")).exists():
            raise ValueError("quarantined workspace cannot be retired")
        with (lease_root / (key + ".lock")).open("a") as lease:
            try:
                fcntl.flock(lease, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError as error:
                raise ValueError("leased workspace cannot be retired") from error
            _retire_tree(root, target, archive, discard, record, identities[target])
        receipt.write_text(json.dumps(record, indent=2) + "\n")
    record["evidencePreserved"] = True
    receipt.write_text(json.dumps(record, indent=2) + "\n")
    return record


def discard_bindings(root, declaration, targets):
    """Resolve reproducible duplicates from one retained artifact, not guessed suffixes."""
    if declaration.get('schema') != 'artifact-backed-source-discard.v1':
        return declaration
    from gambit_smp.framework import digest
    from gambit_smp.runtime_artifact import archive_manifest
    from gambit_smp.recipes import tree_identity
    import tarfile
    root = Path(root).resolve(strict=True)
    archive = Path(declaration['archive']).resolve(strict=True)
    if digest(archive) != declaration['sha256']:
        raise ValueError('discard generation archive changed')
    with tarfile.open(archive) as stream:
        value = archive_manifest(stream, verify_runtime=True)
    selected = {str(Path(path).resolve().relative_to(root)) for path in targets or ()}
    if selected != set(declaration['trees']):
        raise ValueError('discard generation must bind the exact selected trees')
    bindings = {}
    for name, kind in declaration['trees'].items():
        if kind not in {'runtime', 'source'}:
            raise ValueError('discard tree requires its runtime or materialized-source inventory')
        target = root / name
        if archive.is_relative_to(target):
            raise ValueError('reproduction archive cannot be removed with its duplicate')
        expected = value['files'] if kind == 'runtime' else value['sourceIdentity']
        for path, row in tree_identity(target).items():
            relative = Path(name) / path
            if (row == expected.get(path) == value['files'].get(path) and 'sha256' in row
                    and relative.suffix not in {'.json', '.log', '.md', '.out', '.err', '.stdout', '.stderr'}):
                bindings[relative.as_posix()] = row['sha256']
    if digest(archive) != declaration['sha256']:
        raise ValueError('discard generation changed during planning')
    return bindings


def _retire_tree(root, target, archive, discard, record, expected_inode):
    inventory = {}
    for directory, children, files in os.walk(target, followlinks=False):
        for name in [*children, *files]:
            source = Path(directory, name)
            relative = source.relative_to(root).as_posix()
            if source.is_symlink():
                inventory[relative] = {"link": os.readlink(source)}
            elif source.is_dir():
                inventory[relative] = {"directory": True, "mode": source.stat().st_mode & 0o777}
            elif source.is_file():
                sha = hashlib.sha256(source.read_bytes()).hexdigest()
                row = {"sha256": sha, "bytes": source.stat().st_size,
                       "mode": source.stat().st_mode & 0o777}
                if relative in discard:
                    if discard[relative] != sha:
                        raise ValueError("discard source identity changed")
                    row["retention"] = "caller-declared-reproducible-source"
                else:
                    saved = archive / "evidence" / relative
                    saved.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(source, saved)
                    if hashlib.sha256(saved.read_bytes()).hexdigest() != sha:
                        raise ValueError("archive identity mismatch")
                    row["retention"] = "bytes-archived"
                inventory[relative] = row
            else:
                raise ValueError("special filesystem object cannot be retired")
    # Recheck the complete source immediately before removal under the same lease.
    if target.is_symlink() or (target.stat().st_dev, target.stat().st_ino) != expected_inode:
        raise ValueError("source tree replaced during archival")
    actual = set()
    for directory, children, files in os.walk(target, followlinks=False):
        for name in [*children, *files]:
            source = Path(directory, name)
            relative = source.relative_to(root).as_posix()
            if source.is_symlink():
                actual.add(relative)
                if inventory.get(relative) != {"link": os.readlink(source)}:
                    raise ValueError("source link changed during archival")
            elif source.is_dir():
                actual.add(relative)
                if inventory.get(relative) != {"directory": True, "mode": source.stat().st_mode & 0o777}:
                    raise ValueError("source directory changed during archival")
            elif source.is_file():
                actual.add(relative)
                row = inventory.get(relative, {})
                if (hashlib.sha256(source.read_bytes()).hexdigest() != row.get("sha256")
                        or source.stat().st_mode & 0o777 != row.get("mode")):
                    raise ValueError("source changed during archival")
            else:
                raise ValueError("special filesystem object cannot be retired")
    if actual != set(inventory):
        raise ValueError("source inventory changed during archival")
    record["inventories"][target.relative_to(root).as_posix()] = inventory
    (archive / "receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    from gambit_smp.storage_policy import retiring_fixture
    with retiring_fixture(target):
        shutil.rmtree(target)
    record["removed"].append(str(target.relative_to(root)))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, required=True)
    parser.add_argument("--keep", type=Path, action="append", default=[])
    parser.add_argument("--target", type=Path, action="append")
    parser.add_argument("--discard-bindings", type=Path,
                        help="exact reproducible source path/SHA map or artifact-backed discard declaration")
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--archive", type=runtime_argument, required=True)
    parser.add_argument("--apply", action="store_true")
    args = parser.parse_args()
    discard = None if args.discard_bindings is None else discard_bindings(
        args.root, json.loads(args.discard_bindings.read_text()), args.target)
    record = prune(args.root, args.keep, args.archive, apply=args.apply, targets=args.target, discard=discard)
    print(json.dumps({"planned": len(record["planned"]), "removed": len(record["removed"]),
                      "retained": record["retained"], "activeProtected": record.get("activeProtected", []),
                      "gitProtected": record.get("gitProtected", [])}))


from gambit_smp.task_entry import managed_tool as _managed_tool
main = _managed_tool('fixture-storage')(main)

if __name__ == '__main__':
    from gambit_smp.task_entry import tool_main
    raise SystemExit(tool_main('fixture-storage',main))
