"""Isolated workspace transfers and separately sealed generation custody."""
from gambit_smp.task_processes import run as _task_run, check_output as _task_check_output
import ctypes
from contextlib import contextmanager
import errno
import fcntl
import hashlib
from functools import lru_cache
import json
import os
import shutil
import subprocess
import sys
import tarfile
import threading
from pathlib import Path

_workspace_locks = {}
_workspace_locks_mutex = threading.RLock()


def _workspace_scope():
    return [os.environ.get(name) for name in ('GAMBIT_SMP_TASK_ROOT', 'GAMBIT_SMP_TASK_ID',
                                             'GAMBIT_SMP_TASK_PROCESS', 'GAMBIT_SMP_TASK_RUN')]


@contextmanager
def workspace_custody(environment=None):
    """Duplicate real workspace locks into children, including Python helpers.

    The open description, not an environment assertion, survives supervisor
    death. Duplicates protect the spawn/lease-close race and close after exec.
    """
    duplicates, records = [], []
    inherited = json.loads(os.environ.get('GAMBIT_SMP_WORKSPACE_LEASES', '[]'))
    if not isinstance(inherited, list) or len(inherited) > 128:
        raise ValueError('bounded actual workspace descriptor inventory required')
    scope = _workspace_scope()
    try:
        with _workspace_locks_mutex:
            selected = [row for row in _workspace_locks.values() if row['scope'] == scope] + inherited
            seen = set()
            for row in selected:
                if row['scope'] != scope:
                    raise ValueError('workspace custody belongs to another task generation')
                key = (row['fd'], row['source'])
                if key in seen:continue
                seen.add(key)
                fd = row['fd']; actual = os.fstat(fd)
                source = Path(row['source']).stat()
                if ([actual.st_dev, actual.st_ino] != row['lockIdentity'] or
                        [source.st_dev, source.st_ino] != row['sourceIdentity']):
                    raise ValueError('workspace descriptor or source generation changed')
                lock = Path(row['lock'])
                expected = lock.stat()
                if [expected.st_dev, expected.st_ino] != row['lockIdentity']:
                    raise ValueError('workspace lock was replaced')
                probe = os.open(lock, os.O_RDWR | os.O_NOFOLLOW)
                try:
                    try:fcntl.flock(probe, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    except BlockingIOError:pass
                    else:raise ValueError('workspace descriptor is not holding a lease')
                    # A freshly opened descriptor for someone else's occupied
                    # lock is not an inherited open description.
                    try:fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                    except BlockingIOError as error:
                        raise ValueError('workspace descriptor is not the lease owner') from error
                finally:os.close(probe)
                duplicate = os.dup(fd); duplicates.append(duplicate)
                copied = os.fstat(duplicate)
                if [copied.st_dev, copied.st_ino] != row['lockIdentity']:
                    raise ValueError('workspace descriptor changed during delegation')
                records.append(dict(row, fd=duplicate))
        env = dict(os.environ if environment is None else environment)
        if records:env['GAMBIT_SMP_WORKSPACE_LEASES'] = json.dumps(records)
        else:env.pop('GAMBIT_SMP_WORKSPACE_LEASES', None)
        yield tuple(duplicates), env
    finally:
        for fd in duplicates:os.close(fd)


@lru_cache(maxsize=128)
def _repository_root(directory):
    # Cache path routing only, never source verification or evidence admission.
    environment = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    result = _task_run(["git", "-C", str(directory), "rev-parse", "--show-toplevel"],
                            env=environment, capture_output=True, text=True, check=True)
    return Path(result.stdout.rstrip("\n")).resolve(strict=True)


def repository_root(directory):
    """Use Git's worktree root, including nested repositories and worktrees."""
    return _repository_root(Path(directory).resolve(strict=True))


def cache_path(root, name):
    """Local, replaceable storage; never promote a path into Evidence."""
    root = repository_root(root)
    name = Path(name)
    if name.is_absolute() or ".." in name.parts or not name.parts:
        raise ValueError("cache name must be a bounded relative path")
    path = (root / ".cache" / name).resolve()
    if not path.is_relative_to(root / ".cache"):
        raise ValueError("cache alias escapes local cache")
    return path


def runtime_output(root, path):
    """In-repository execution writes only ignored stores, not source assets.

    Explicit external temporary/artifact directories are also supported. Existing
    Existing .data/.ci observations are read in place, not new output locations.
    """
    root, path = repository_root(root), Path(path)
    from gambit_smp.workspace import task_output
    from gambit_smp.task_dependencies import default_task
    if os.environ.get("GAMBIT_SMP_TASK_ID") or default_task(root):
        return task_output(root, path)
    if not path.is_absolute() and path.parts and path.parts[0] == ".cache":
        path = root / path
    declared_cache = path.is_absolute() and path.is_relative_to(root / ".cache")
    path = path.resolve()
    if declared_cache and not path.is_relative_to(root / ".cache"):
        raise ValueError("cache alias escapes local cache")
    if path.is_relative_to(root):
        parts = path.relative_to(root).parts
        if not parts or parts[0] != ".cache":
            raise ValueError("runtime output requires .cache/ (or an external local directory), not Git source")
    return path


def runtime_argument(value):
    """Argparse path type shared by runtime-only adapters."""
    from gambit_smp.framework import ROOT
    return runtime_output(ROOT, value)


def database_path(root, name, previous):
    """Never replace pending operational history with a fresh empty database."""
    target = cache_path(root, name)
    old = repository_root(root) / previous
    if old.exists() and not target.exists():
        raise ValueError("local database requires explicit cache migration: " + str(old))
    return target


def durable_database_path(root, name, previous):
    """Move an existing SQLite store consistently; never start over after pruning Cache."""
    import sqlite3
    import tempfile
    from contextlib import closing
    root = repository_root(root)
    relative = Path(name)
    if (relative.is_absolute() or ".." in relative.parts or not relative.parts
            or relative.parts[0] in {".git", ".cache", ".data", "evidence", "src"}):
        raise ValueError("durable store requires a separate bounded state path")
    target = root / relative
    for part in (target, *target.parents):
        if part == root:
            break
        if part.is_symlink():
            raise ValueError("durable state cannot follow a filesystem alias")
    target.parent.mkdir(parents=True, exist_ok=True)
    with target.with_suffix(".migration.lock").open("a+b") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if target.exists():
            return target
        source = database_path(root, previous, ".data/" + previous)
        if not source.exists():
            return target
        if source.is_symlink() or not source.is_file():
            raise ValueError("regular legacy database required")
        with tempfile.TemporaryDirectory(prefix=".history-migration-", dir=target.parent) as temporary:
            staged = Path(temporary) / "history.sqlite3"
            with closing(sqlite3.connect(source, isolation_level=None)) as owner:
                owner.execute("BEGIN IMMEDIATE")
                try:
                    with closing(sqlite3.connect(source.as_uri() + "?mode=ro", uri=True)) as origin, \
                            closing(sqlite3.connect(staged)) as destination:
                        origin.backup(destination)
                        if destination.execute("PRAGMA integrity_check").fetchone() != ("ok",):
                            raise ValueError("durable history migration failed integrity checking")
                    staged.chmod(0o600)
                    with staged.open("rb") as stream:
                        os.fsync(stream.fileno())
                    os.link(staged, target)
                    directory = os.open(target.parent, os.O_RDONLY)
                    try:
                        os.fsync(directory)
                    finally:
                        os.close(directory)
                finally:
                    owner.rollback()
    return target


def migrate_database(root, name, previous):
    """Explicit consistent SQLite backup; keep the original and refuse overwrite."""
    import sqlite3
    from contextlib import closing
    root = repository_root(root)
    old, target = root / previous, cache_path(root, name)
    if (old.is_symlink() or not old.is_file() or target.exists()
            or not old.is_relative_to(root / ".data")):
        raise ValueError("existing private local database and fresh cache target required")
    target.parent.mkdir(parents=True, exist_ok=True)
    stage = target.with_name(target.name + ".migrating")
    with stage.open("xb"):
        pass
    try:
        with closing(sqlite3.connect(old, timeout=0, isolation_level=None)) as lock:
            lock.execute("BEGIN IMMEDIATE")
            try:
                with closing(sqlite3.connect(old.as_uri() + "?mode=ro", uri=True)) as source, \
                     closing(sqlite3.connect(stage)) as destination:
                    source.backup(destination)
                    schema = "SELECT type,name,tbl_name,sql FROM sqlite_master ORDER BY type,name"
                    if (destination.execute("PRAGMA integrity_check").fetchone() != ("ok",)
                            or source.execute(schema).fetchall() != destination.execute(schema).fetchall()):
                        raise ValueError("local database migration differs from original")
                    for (table,) in source.execute("SELECT name FROM sqlite_master WHERE type='table'"):
                        count = 'SELECT COUNT(*) FROM "' + table.replace('"', '""') + '"'
                        if source.execute(count).fetchone() != destination.execute(count).fetchone():
                            raise ValueError("local database migration lost rows")
                os.link(stage, target)
            finally:
                lock.rollback()
    finally:
        stage.unlink()
    return target


def fixture_root(root, path):
    """New cache custody or the exact historical fixture store, never an alias."""
    root, path = Path(root).resolve(strict=True), Path(path).resolve()
    for name in (".cache/fixtures", ".data/fixtures"):
        store = root / name
        if path != store and path.is_relative_to(store):
            return store
    store = root / '.cache/tasks'
    if path.is_relative_to(store):
        parts = path.relative_to(store).parts
        offset = 3 if len(parts) > 2 and parts[1] == 'processes' else 1
        from gambit_smp.workspace import bounded, identifier
        identifier(parts[0])
        if offset == 3:
            identifier(parts[2])
        tail = parts[offset:]
        if (len(tail) >= 4 and tail[0] == 'build' and tail[3] == 'source'
                and len(tail[2]) == 64 and all(c in '0123456789abcdef' for c in tail[2])):
            identifier(tail[1])
            bounded(root, path.relative_to(root))
            return store / Path(*parts[:offset])
    raise ValueError("runtime must belong to this project's fixture store")


def observation_root(root, path):
    """Receipt storage follows runtime_output; source leases stay fixture-only."""
    root, path = Path(root).resolve(strict=True), Path(path).resolve()
    store = root / ".cache"
    if path != store and path.is_relative_to(store):
        return store
    return fixture_root(root, path)


def fixture_name(root, run):
    root = Path(root).resolve(strict=True)
    store = observation_root(root, run)
    base = store if store == root / ".data/fixtures" else root
    return Path(run).resolve().relative_to(base).as_posix()


def fixture_path(root, name):
    """Cache references are explicit root paths; old receipt names stay unchanged."""
    from gambit_smp.framework import relative
    root = Path(root).resolve(strict=True)
    base = root if Path(name).parts[:1] == (".cache",) else root / ".data/fixtures"
    path = relative(base, name)
    observation_root(root, path)
    return path


def archived_record(root, reference):
    """Read explicitly indexed historical bytes, not a source/cache alias."""
    from gambit_smp.framework import relative
    root = repository_root(root)
    retired=root/'.state/storage/retired-records/index.json'
    if retired.exists():
        from gambit_smp.workspace import bounded
        local=json.loads(retired.read_text())
        if local.get('schema')!='retired-custody-records.v1':raise ValueError('unknown retired custody index')
        versions=local['records'].get(reference['path'])
        if versions is not None:
            name=versions.get(reference['sha256'])
            if name is None:raise ValueError('historical record not bound by retired custody')
            raw=bounded(root,name).read_bytes()
            if hashlib.sha256(raw).hexdigest()!=reference['sha256']:raise ValueError('retired custody record digest mismatch')
            return raw
    index = json.loads((root / "evidence/storage-history.json").read_bytes())
    if index.get("schema") != "git-record-archive.v1":
        raise ValueError("typed historical record archive required")
    name = reference["path"]
    relative(root, name)
    row = index["records"].get(name)
    if row is None or row["sha256"] != reference["sha256"]:
        raise ValueError("historical record not bound by archive")
    revision, blob = index["revision"], row["gitBlob"]
    if any(len(value) != 40 or any(c not in "0123456789abcdef" for c in value)
           for value in (revision, blob)):
        raise ValueError("fixed Git record identity required")
    environment = {key: value for key, value in os.environ.items() if not key.startswith("GIT_")}
    def git(*args):
        return _task_check_output(["git", "-C", str(root), *args], env=environment,
                                       stderr=subprocess.PIPE)
    if git("rev-parse", revision + ":" + name).decode().strip() != blob:
        raise ValueError("historical record does not belong to pinned revision")
    raw = git("cat-file", "blob", blob)
    if hashlib.sha256(raw).hexdigest() != reference["sha256"]:
        raise ValueError("historical record digest mismatch")
    target = cache_path(root, "history/git/" + reference["sha256"] + "/record.json")
    target.parent.mkdir(parents=True, exist_ok=True)
    try:
        with target.open("xb") as stream:
            stream.write(raw)
    except FileExistsError:
        if target.read_bytes() != raw:
            raise ValueError("historical record cache changed")
    return raw


@contextmanager
def workspace_lease(root, source, expected_identity, *, broken_links=None, identity_reader=None):
    """Exclusive in-place access; never authorize a different source state."""
    from gambit_smp.recipes import tree_identity
    root, source = Path(root).resolve(strict=True), Path(source)
    if source.is_symlink():
        raise ValueError("workspace root cannot be a symlink")
    source = source.resolve(strict=True)
    fixture_root(root, source)
    identity = (source.stat().st_dev, source.stat().st_ino)
    key = hashlib.sha256(str(source).encode()).hexdigest()
    store = (cache_path(root, "workspace-leases") if source.is_relative_to(root / '.cache')
             else root / ".data/workspace-leases")
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
        lock_identity = os.fstat(fd)
        with _workspace_locks_mutex:
            _workspace_locks[fd] = dict(fd=fd, source=str(source), lock=str(lock_path), scope=_workspace_scope(),
                lockIdentity=[lock_identity.st_dev, lock_identity.st_ino], sourceIdentity=list(identity))
        yield source
        if source.is_symlink() or (source.stat().st_dev, source.stat().st_ino) != identity:
            raise ValueError("workspace replaced while leased")
    finally:
        with _workspace_locks_mutex:_workspace_locks.pop(fd, None)
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
    store = (cache_path(root, "workspace-leases") if fixture_root(root, source).parent.name == ".cache"
             else root / ".data/workspace-leases")
    target = store / (key + ".quarantine.json")
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
    if not (destination.is_relative_to(root / "evidence") or
            destination.is_relative_to(cache_path(root, "research/workspace-states"))):
        raise ValueError("workspace state requires the local state cache or explicit Evidence destination")
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
    from gambit_smp.recipes import source_path
    root = Path(root).resolve(strict=True)
    path = relative(root, reference["path"])
    if not (path.is_relative_to(root / "evidence") or
            path.is_relative_to(cache_path(root, "research/workspace-states"))):
        raise ValueError("retained workspace state changed")
    raw = path.read_bytes() if path.is_file() else archived_record(root, reference)
    if hashlib.sha256(raw).hexdigest() != reference["sha256"]:
        raise ValueError("retained workspace state changed")
    record = json.loads(raw)
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


def transfer_generation(source, destination, *, portable=False):
    """Transfer a checked immutable generation; caller seals and hashes bytes.

    This deliberately differs from mutable workspace transfers, which must
    never hardlink. Shared generations remain hash-checked, not write-isolated.
    """
    source, destination = Path(source), Path(destination)
    if source.is_symlink() or not source.is_file():
        raise ValueError("regular nonsymlink generation required")
    if destination.exists() or destination.is_symlink():
        raise FileExistsError(destination)
    if portable:
        shutil.copyfile(source, destination)
        return "copied"
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
            # APFS clones usually already retain these values. Avoid hundreds
            # of redundant chmod/utime writes, but repair actual discrepancies.
            def metadata(path):
                state = os.stat(path, follow_symlinks=False)
                return (state.st_mode, state.st_atime_ns, state.st_mtime_ns,
                        getattr(state, "st_flags", None))
            if metadata(source) != metadata(destination):
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


def extract_archive(archive, destination, ctx, *, stage, omit_runtime=False, runtime_only=False, existing_inputs=None,
                    preserve_modes=True):
    """Validate the entire tree before supervised native tar writes anything.

    No member may write through a symlink ancestor, irrespective of entry order.
    Relative internal links are data; hard links, devices and special modes are
    refused. The destination must be empty and owned by the current task.
    """
    import posixpath
    from pathlib import PurePosixPath
    from gambit_smp.workspace import task_output
    archive,destination=Path(archive),Path(destination)
    if task_output(ctx.root,destination) != destination:
        raise ValueError('archive destination requires current task custody')
    if destination.is_symlink():
        raise ValueError('archive extraction requires an empty non-alias destination')
    if destination.exists() and any(destination.iterdir()):
        from gambit_smp.recipes import tree_identity
        if existing_inputs is None:raise ValueError('archive extraction requires an empty destination')
        links={name:row['link'] for name,row in existing_inputs.items() if 'link' in row}
        observed=tree_identity(destination,broken_links=links or None)
        if any({key:value for key,value in row.items() if key != 'unresolved'} != existing_inputs.get(name)
               for name,row in observed.items()):
            raise ValueError('partial archive import contains unrecorded bytes')
    with tarfile.open(archive) as tree:
        names,links=set(),set()
        for member in tree.getmembers():
            path=PurePosixPath(member.name)
            if (path.is_absolute() or '..' in path.parts or str(path) != member.name
                    or member.name in names or member.islnk()
                    or not (member.isdir() or member.isfile() or member.issym())
                    or member.mode & ~0o777):
                raise ValueError('unsafe archive member')
            names.add(member.name)
            if member.issym():
                target=PurePosixPath(member.linkname)
                resolved=posixpath.normpath(str(path.parent/target))
                if target.is_absolute() or resolved == '..' or resolved.startswith('../'):
                    raise ValueError('archive link escapes destination')
                links.add(path)
        if any(parent in links for name in names for parent in PurePosixPath(name).parents):
            raise ValueError('archive entry writes through a symlink ancestor')
    if not omit_runtime and ('lib/setup.c' in names or 'runtime/lib/setup.c' in names):
        from gambit_smp.fixture_storage import source_capacity
        plan = getattr(ctx, 'planned_steps', ())
        staging = any(step['id'] == ctx.directory.name and step['capability'] == 'gambit.materialize'
                      and step['arguments'].get('buildWorkspace')
                      for step in plan) and ctx.receipt.get('workspacePolicy') == 'in-place'
        with source_capacity(destination, staging=bool(staging)):
            pass
    destination.mkdir(parents=True,exist_ok=True)
    if omit_runtime and runtime_only:raise ValueError('one archive selection required')
    options=(['--exclude=runtime','--exclude=runtime/*'] if omit_runtime else
             ['--strip-components=1','runtime'] if runtime_only else [])
    argv=[ctx.tools['tar'],'-xpf' if preserve_modes else '-xf',archive,'-C',destination,'--no-same-owner',*options]
    if not preserve_modes:
        # Match tarfile's data filter for Git source modes (0664/0775), without
        # changing this process's or another worker's umask.
        argv=[ctx.tools['sh'],'-c','umask 022; exec "$@"','source-extract',*argv]
    ctx.require(stage,argv,
                ctx.root,min(30,ctx.remaining()))
    completed=ctx.commands[-1]
    if completed.get('parentReaped') is not True or completed.get('processGroupQuiescent') is not True:
        raise ValueError('archive extraction has no completed quiescent process observation')


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
