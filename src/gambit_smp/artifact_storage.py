"""Isolated workspace transfers and separately sealed generation custody."""
import ctypes
from contextlib import contextmanager
import errno
import fcntl
import hashlib
import json
import os
import shutil
import sys
import tarfile
from pathlib import Path


@contextmanager
def workspace_lease(root, source, expected_identity, *, broken_links=None, identity_reader=None):
    """Exclusive in-place access; never authorize a different source state."""
    from gambit_smp.recipes import tree_identity
    root, source = Path(root).resolve(strict=True), Path(source)
    if source.is_symlink():
        raise ValueError("workspace root cannot be a symlink")
    source = source.resolve(strict=True)
    if not source.is_relative_to(root / ".data/fixtures"):
        raise ValueError("mutable workspace must belong to the fixture store")
    identity = (source.stat().st_dev, source.stat().st_ino)
    key = hashlib.sha256(str(source).encode()).hexdigest()
    store = root / ".data/workspace-leases"
    store.mkdir(parents=True, exist_ok=True)
    lock_path = store / (key + ".lock")
    flags = os.O_CREAT | os.O_RDWR | getattr(os, "O_NOFOLLOW", 0)
    fd = os.open(lock_path, flags, 0o600)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            raise ValueError("workspace already leased") from error
        if (store / (key + ".quarantine.json")).exists():
            raise ValueError("workspace has an unquiesced process observation")
        if (source.stat().st_dev, source.stat().st_ino) != identity:
            raise ValueError("workspace identity changed during lease acquisition")
        if identity_reader is not None and broken_links is not None:
            raise ValueError("custom identity reader cannot relax unresolved links")
        actual = identity_reader(source) if identity_reader is not None else tree_identity(source, broken_links=broken_links)
        if actual != expected_identity:
            raise ValueError("workspace state differs from admitted input")
        yield source
        if source.is_symlink() or (source.stat().st_dev, source.stat().st_ino) != identity:
            raise ValueError("workspace replaced while leased")
    finally:
        os.close(fd)


def repair_interrupted_build_links(root, source, source_lock, failed_receipt, receipt_sha, destination):
    """Remove only known internal dangling launch aliases after verified teardown."""
    from gambit_smp.framework import digest
    from gambit_smp.recipes import tree_identity
    root, source = Path(root).resolve(strict=True), Path(source)
    raw = Path(failed_receipt).read_bytes()
    receipt = json.loads(raw)
    lock = json.loads(Path(source_lock).read_text())
    lock_name = Path(source_lock).resolve().relative_to(root).as_posix()
    if (hashlib.sha256(raw).hexdigest() != receipt_sha or receipt.get("outcome") != "DENY"
            or receipt.get("schema") != "sealed-research-run.v1" or receipt.get("parentReaped") is not True
            or receipt.get("processGroupQuiescent") is not True or Path(receipt["root"]).resolve() != root
            or receipt["inputs"].get(lock_name) != digest(Path(source_lock))):
        raise ValueError("quiescent source-bound failed producer required for repair")
    allowed = {"bin/" + name: "../gsi/gsi" for name in
               ("gsi-script", "scheme-srfi-0", "scheme-r4rs", "six-script", "scheme-r5rs",
                "scheme-ieee-1178-1990", "six")}
    allowed["bin/gsc-script"] = "../gsc/gsc"
    identity = tree_identity(source, broken_links=allowed)
    broken = {name: row["link"] for name, row in identity.items() if row.get("unresolved")}
    destination = Path(destination).resolve()
    if not destination.is_relative_to(root / "evidence") or destination.exists():
        raise ValueError("fresh persistent repair evidence required")
    with workspace_lease(root, source, identity, broken_links=allowed) as leased:
        for name, row in lock["files"].items():
            if digest(leased / name) != row["candidateSha256"]:
                raise ValueError("source lock drift prevents build-link repair")
        if Path(failed_receipt).read_bytes() != raw:
            raise ValueError("failed producer changed before repair")
        destination.parent.mkdir(parents=True, exist_ok=True)
        record = {"schema": "interrupted-build-link-repair.v1", "workspace": leased.relative_to(root).as_posix(),
                  "sourceLock": lock_name, "sourceLockSha256": digest(Path(source_lock)),
                  "failedReceiptSha256": receipt_sha, "plannedLinks": broken,
                  "runtimeAdmitted": False, "historicalProgressReset": False}
        with destination.open("x") as stream:
            json.dump(record, stream, sort_keys=True, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        for name, target in broken.items():
            path = leased / name
            if not path.is_symlink() or os.readlink(path) != target or path.exists():
                raise ValueError("build alias changed during repair")
            path.unlink()
        tree_identity(leased)
    return record


def quarantine_workspace(root, source, process_records):
    """Do not let advisory-lock release erase an unquiesced child process."""
    root, source = Path(root).resolve(strict=True), Path(source).resolve(strict=True)
    key = hashlib.sha256(str(source).encode()).hexdigest()
    target = root / ".data/workspace-leases" / (key + ".quarantine.json")
    record = {"schema": "workspace-process-quarantine.v1",
              "workspace": source.relative_to(root).as_posix(),
              "reason": "process-group-not-quiescent", "runtimeAdmitted": False,
              "processes": [{key: row.get(key) for key in ("pid", "startedAt", "endedAt", "parentReaped", "processGroupQuiescent")}
                            for row in process_records if row.get("processGroupQuiescent") is False]}
    if not record["processes"]:
        raise ValueError("explicit unquiesced process observation required")
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.open("x") as stream:
        json.dump(record, stream, sort_keys=True)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    fd = os.open(target.parent, os.O_RDONLY)
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def seal_workspace_state(root, source, destination, bindings):
    """Retain exact inventory and input custody, not an executable backup."""
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path, tree_identity
    root = Path(root).resolve(strict=True)
    destination = Path(destination).resolve()
    if not destination.is_relative_to(root / "evidence"):
        raise ValueError("workspace state must be retained in Evidence")
    if not bindings:
        raise ValueError("source/configuration input bindings required")
    for name, expected in bindings.items():
        if digest(source_path(root, name)) != expected:
            raise ValueError("workspace state input drift")
    inventory = tree_identity(Path(source))
    record = {"schema": "retained-workspace-state.v1", "identity": inventory,
              "bindings": bindings, "runtimeAdmitted": False,
              "claim": "observed-tree-state-not-current-bytes-or-backup"}
    destination.parent.mkdir(parents=True, exist_ok=True)
    with destination.open("x") as stream:
        json.dump(record, stream, sort_keys=True, indent=2)
        stream.write("\n")
        stream.flush()
        os.fsync(stream.fileno())
    if tree_identity(Path(source)) != inventory:
        raise ValueError("workspace changed while retaining state")
    return {"path": destination.relative_to(root).as_posix(), "sha256": digest(destination)}


def checked_workspace_state(root, reference, expected_identity, *, input_bindings=None):
    """Check retained evidence without upgrading absent bytes into a runtime."""
    from gambit_smp.framework import digest, relative
    from gambit_smp.recipes import read_json, source_path
    root = Path(root).resolve(strict=True)
    path = relative(root, reference["path"])
    if not path.is_relative_to(root / "evidence") or digest(path) != reference["sha256"]:
        raise ValueError("retained workspace state changed")
    record = read_json(path)
    if (record.get("schema") != "retained-workspace-state.v1"
            or record.get("identity") != expected_identity
            or record.get("runtimeAdmitted") is not False or not record.get("bindings")):
        raise ValueError("retained workspace state does not match producer")
    for name, expected in record["bindings"].items():
        original = source_path(root, name)
        bound = (input_bindings or {}).get(str(original), original)
        if digest(bound) != expected:
            raise ValueError("retained workspace input drift")
    return {"recordedStateBound": True, "currentBytesEstablished": False,
            "runtimeAdmitted": False}


def adopt_source_archive(workspace, archive, files, cache_files):
    """Fill a leased source slice from the pinned archive, without a second tree."""
    from gambit_smp.framework import digest
    workspace = Path(workspace)
    for name in (*files, *cache_files):
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or ".git" in path.parts:
            raise ValueError("workspace inventory path outside source boundary")
    if set(files) & set(cache_files):
        raise ValueError("source files cannot be declared disposable cache")
    with tarfile.open(archive) as tree:
        members = {}
        for member in tree.getmembers():
            name = Path(member.name)
            if name.is_absolute() or ".." in name.parts or ".git" in name.parts or not (member.isfile() or member.isdir()):
                raise ValueError("source archive must contain regular bounded paths")
            if member.name in members:
                raise ValueError("duplicate source archive entry")
            members[member.name] = member
        if set(cache_files) & set(members):
            raise ValueError("tracked archive source cannot be disposable cache")
        cache_directories = {parent.as_posix() for name in cache_files
                             for parent in Path(name).parents if parent != Path(".")}
        for name, row in files.items():
            member = members.get(name)
            if member is None or not member.isfile():
                raise ValueError("locked source missing from archive")
            with tree.extractfile(member) as stream:
                if hashlib.sha256(stream.read()).hexdigest() != row["baseSha256"]:
                    raise ValueError("source archive base differs from lock")
            if digest(workspace / name) != row["candidateSha256"]:
                raise ValueError("adopted candidate differs from source lock")
        # Validate the entire existing inventory before writing or removing bytes.
        for path in workspace.rglob("*"):
            name = path.relative_to(workspace).as_posix()
            if path.is_symlink() or not (path.is_file() or path.is_dir()):
                raise ValueError("adopted workspace contains unsupported entry")
            if path.is_dir():
                if (name not in members or not members[name].isdir()) and name not in cache_directories:
                    raise ValueError("untracked workspace directory")
            elif name in files:
                continue
            elif name in cache_files:
                if digest(path) != cache_files[name]:
                    raise ValueError("declared cache artifact changed")
            elif name in members and members[name].isfile():
                with tree.extractfile(members[name]) as stream:
                    if digest(path) != hashlib.sha256(stream.read()).hexdigest():
                        raise ValueError("unlocked tracked source changed")
            else:
                raise ValueError("untracked workspace file")
        for name in cache_files:
            path = workspace / name
            if path.is_file():
                path.unlink()
        for name in sorted(cache_directories, key=lambda value: len(Path(value).parts), reverse=True):
            path = workspace / name
            if name not in members and path.is_dir():
                path.rmdir()
        for name, member in members.items():
            target = workspace / name
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif not target.exists():
                target.parent.mkdir(parents=True, exist_ok=True)
                with tree.extractfile(member) as stream, target.open("xb") as output:
                    shutil.copyfileobj(stream, output)
                target.chmod(member.mode & 0o777)


def transfer_generation(source, destination):
    """Transfer a checked immutable generation; caller seals and hashes bytes.

    This deliberately differs from mutable workspace transfers, which must
    never hardlink. Shared generations remain hash-checked, not write-isolated.
    """
    source, destination = Path(source), Path(destination)
    if source.is_symlink() or not source.is_file():
        raise ValueError("regular nonsymlink generation required")
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(destination)
    try:
        os.link(source, destination, follow_symlinks=False)
        return "linked-generation"
    except OSError as error:
        if error.errno not in {errno.EXDEV, errno.ENOTSUP, errno.ENOSYS}:
            raise
    shutil.copyfile(source, destination)
    return "copied"


def clone_file(source, destination, *, clone=None):
    if clone is None and sys.platform == "darwin":
        clone = ctypes.CDLL(None, use_errno=True).clonefile
        clone.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_int]
        clone.restype = ctypes.c_int
    if clone is not None:
        if clone(os.fsencode(source), os.fsencode(destination), 0) == 0:
            shutil.copystat(source, destination)
            return "copy-on-write"
        error = ctypes.get_errno()
        if error not in {errno.EXDEV, errno.ENOTSUP, errno.ENOSYS}:
            raise OSError(error, os.strerror(error), destination)
    shutil.copy2(source, destination)
    return "byte-copy"


def transfer_tree(source, destination, *, dirs_exist_ok=False):
    from gambit_smp.fixture_storage import source_capacity
    is_source = (Path(source) / "lib/setup.c").is_file()
    if is_source:
        with source_capacity(destination):
            return _transfer_tree(source, destination, dirs_exist_ok=dirs_exist_ok)
    return _transfer_tree(source, destination, dirs_exist_ok=dirs_exist_ok)


def _transfer_tree(source, destination, *, dirs_exist_ok=False):
    source, destination = Path(source), Path(destination)
    src, dst = source.resolve(strict=True), destination.resolve()
    if destination.is_symlink() or src == dst or src.is_relative_to(dst) or dst.is_relative_to(src):
        raise ValueError("artifact transfer requires separate, non-overlapping trees")
    # Runtime views create empty test directories; never merge old build outputs.
    if destination.exists() and dirs_exist_ok:
        if not destination.is_dir() or any(destination.iterdir()):
            raise ValueError("artifact transfer cannot overwrite a populated workspace")
    counts = {"copy-on-write": 0, "byte-copy": 0}
    logical_bytes = 0

    def transfer_file(src, dst):
        nonlocal logical_bytes
        counts[clone_file(src, dst)] += 1
        logical_bytes += os.stat(src).st_size
        return dst

    shutil.copytree(source, destination, symlinks=True, copy_function=transfer_file,
                    dirs_exist_ok=dirs_exist_ok)
    return {"schema": "isolated-artifact-transfer.v1", "files": counts,
            "logicalBytes": logical_bytes,
            "hardlinks": False, "claim": "storage-reuse-not-cold-build-or-native-admission"}
