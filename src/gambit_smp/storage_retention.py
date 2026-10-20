"""Explicit, revalidated legacy cleanup; never infer source disposal from age."""
import argparse
from datetime import datetime, timedelta
import hashlib
import json
import os
from pathlib import Path
import shutil
import stat

from gambit_smp.workspace import ZONE, active_paths, bounded, lease, now, referenced, write

# Shared inputs, live coordination and restoration state need explicit migration,
# not expiry. New per-task output is reclaimed by workspace.gc instead.
SHARED = {"fixtures", "fixture-archives", "fixture-evidence", "research", "history",
          "reasoning", "research-actions", "workspace-leases", "tools", "venv",
          "source-cache", "source-overlays", "source-slices", "bench", "tasks", "worktrees",
          ".gerbil-bench.lock"}


def inspect(path, cutoff, *, deleting=False, disposable_databases=(), disposable_git=()):
    """Fingerprint metadata without following aliases or reading private logs."""
    digest = hashlib.sha256()
    logical = allocated = count = 0
    latest = 0
    blocked = None
    pending = [path]
    while pending:
        item = pending.pop()
        st = item.lstat()
        count += 1
        latest = max(latest, st.st_mtime)
        logical += st.st_size
        allocated += st.st_blocks * 512
        digest.update(json.dumps([str(item.relative_to(path)), st.st_mode, st.st_dev,
                                  st.st_ino, st.st_size, st.st_mtime_ns], separators=(",", ":")).encode())
        if item.name == ".git" and str(item.relative_to(path)) not in disposable_git:
            blocked = "nested Git checkout"
        if item.name.endswith((".sqlite", ".sqlite3", ".db", ".sqlite-wal", ".sqlite-shm",
                               ".sqlite3-wal", ".sqlite3-shm", ".db-wal", ".db-shm", ".quarantine.json")):
            if str(item.relative_to(path)) not in disposable_databases:
                blocked = "operational state or quarantine"
        if (not deleting or not stat.S_ISDIR(st.st_mode)) and datetime.fromtimestamp(st.st_mtime, ZONE).date() >= cutoff:
            blocked = "recent descendant"
        if blocked:
            break
        if stat.S_ISDIR(st.st_mode):
            pending.extend(sorted(item.iterdir(), reverse=True))
    return dict(fingerprint=digest.hexdigest(), entries=count, logicalBytes=logical,
                allocatedBytes=allocated, latestMtime=latest, blocked=blocked)


def plan(root, *, today=None, opened=None):
    root = Path(root).resolve(strict=True)
    from gambit_smp.task_dependencies import protected
    cutoff = (today or now().date()) - timedelta(days=1)
    opened = active_paths() if opened is None else opened
    opened = [p for p in opened if str(p).casefold().startswith(str(root).casefold() + os.sep)]
    result = dict(schema=1, root=str(root), cutoff=cutoff.isoformat(), timezone=str(ZONE),
                  targets=[], retained=[])
    for store in (".cache", ".data"):
        base = bounded(root, store)
        if not base.exists():
            continue
        for path in sorted(base.iterdir()):
            write(bounded(root, ".state/storage/legacy-cleanup-progress.json"),
                  dict(at=now().isoformat(), inspecting=str(path.relative_to(root)),
                       targets=len(result["targets"]), retained=len(result["retained"])))
            reason = None
            if path.is_symlink():
                reason = "root alias"
            elif protected(root, path):
                reason = "registered task dependency"
            elif path.name in SHARED:
                reason = "shared store or coordination"
            elif path.is_dir() and (path / ".git").exists():
                reason = "Git checkout; use Git-flow reclamation"
            elif referenced(path, opened):
                reason = "process reference"
            elif datetime.fromtimestamp(path.stat().st_mtime, ZONE).date() >= cutoff:
                reason = "recent root"
            if reason:
                result["retained"].append(dict(path=str(path.relative_to(root)), reason=reason))
                continue
            inventory = inspect(path, cutoff)
            if inventory["blocked"]:
                result["retained"].append(dict(path=str(path.relative_to(root)), reason=inventory["blocked"]))
            else:
                result["targets"].append(dict(path=str(path.relative_to(root)), **inventory))
    return result


def remove_tree(path):
    """Only an approved disposable tree: copied package dirs may be read-only."""
    if not path.is_dir():
        path.unlink()
        return
    mode = path.lstat().st_mode
    if not stat.S_ISDIR(mode):
        raise ValueError("cleanup directory became an alias")
    os.chmod(path, mode | 0o700, follow_symlinks=False)
    for directory, dirs, files in os.walk(path, followlinks=False):
        for name in dirs:
            child = Path(directory) / name
            mode = child.lstat().st_mode
            if stat.S_ISDIR(mode) and mode & 0o700 != 0o700:
                os.chmod(child, mode | 0o700, follow_symlinks=False)
    shutil.rmtree(path)


def apply(root, manifest, expected_sha, *, resume=False):
    root = Path(root).resolve(strict=True)
    if hashlib.sha256(manifest.read_bytes()).hexdigest() != expected_sha:
        raise ValueError("cleanup manifest changed")
    value = json.loads(manifest.read_text())
    if value["root"] != str(root):
        raise ValueError("cleanup repository mismatch")
    cutoff = datetime.fromisoformat(value["cutoff"]).date()
    receipt_path = bounded(root, ".state/storage/legacy-cleanup-applied.json")
    # Exact input fingerprints are checked immediately before each removal. No
    # path is inferred from directory names, no branch is reset or unregistered.
    with lease(root, "storage-retention"):
        # Read progress after acquiring custody; another cleaner may have
        # completed between command dispatch and lock acquisition.
        if receipt_path.exists():
            receipt = json.loads(receipt_path.read_text())
            if not resume or receipt["planSha256"] != expected_sha or receipt.get("complete"):
                raise ValueError("cleanup receipt exists; use --resume for this incomplete plan")
        else:
            receipt = dict(schema=1, planSha256=expected_sha, removed=[], state="running")
        for index, row in enumerate(receipt["removed"]):
            if any(row.get(key) != item for key, item in value["targets"][index].items()):
                raise ValueError("cleanup journal does not match plan prefix")
        receipt.update(state="running", complete=False)
        opened = active_paths()
        write(receipt_path, receipt)
        try:
            for row in value["targets"][len(receipt["removed"]):]:
                relative = Path(row["path"])
                if len(relative.parts) != 2 or relative.parts[0] not in (".cache", ".data"):
                    raise ValueError("direct legacy artifact required")
                path = bounded(root, relative)
                from gambit_smp.task_dependencies import protected
                if protected(root, path) or path.name in SHARED or path.is_symlink():
                    raise ValueError("protected legacy artifact")
                if referenced(path, opened):
                    raise ValueError("process acquired legacy artifact")
                interrupted = receipt.get("current")
                if interrupted:
                    if interrupted["path"] != row["path"]:
                        raise ValueError("interrupted cleanup target differs")
                    if not path.exists() and not path.is_symlink():
                        receipt["removed"].append(dict(row, archivedRecords=interrupted["archivedRecords"],
                                                       absentOnResume=True))
                        receipt.pop("current")
                        write(receipt_path, receipt)
                        continue
                    st = path.lstat()
                    if (interrupted["path"] != row["path"] or path.is_symlink() or
                            [st.st_dev, st.st_ino] != interrupted["identity"] or
                            inspect(path, cutoff, deleting=True)["blocked"]):
                        raise ValueError("interrupted cleanup tree changed; manual reconciliation required")
                    archived = interrupted["archivedRecords"]
                else:
                    current = inspect(path, cutoff)
                    if current != {k: v for k, v in row.items() if k != "path"} or current["blocked"]:
                        raise ValueError("legacy artifact changed; regenerate plan")
                    archived = archive_records(root, path)
                    st = path.lstat()
                    receipt["current"] = dict(path=row["path"], identity=[st.st_dev, st.st_ino],
                                              archivedRecords=archived, stage="deleting")
                    write(receipt_path, receipt)
                remove_tree(path)
                receipt["removed"].append(dict(row, archivedRecords=archived))
                receipt.pop("current", None)
                write(receipt_path, receipt)
        finally:
            receipt.update(state="terminal", complete=len(receipt["removed"]) == len(value["targets"]))
            write(receipt_path, receipt)
    return receipt


def archive_records(root, path):
    """Keep small custody receipts byte-for-byte, not private event/debug streams."""
    result = []
    candidates = [path] if path.is_file() else path.rglob("*.json")
    for candidate in candidates:
        if candidate.is_symlink() or candidate.stat().st_size > 2 * 1024 * 1024:
            continue
        if (candidate.name not in {"receipt.json", "record.json", "run.json", "summary.json"}
                and not candidate.name.endswith(("-applied.json", "-plan.json"))):
            continue
        raw = candidate.read_bytes()
        sha = hashlib.sha256(raw).hexdigest()
        target = bounded(root, ".state/storage/retired-records/" + sha + ".json")
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists():
            if target.read_bytes() != raw:
                raise ValueError("retired receipt archive changed")
        else:
            fd = os.open(target, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW, 0o600)
            with os.fdopen(fd, "wb") as stream:
                stream.write(raw)
                stream.flush()
                os.fsync(stream.fileno())
        result.append(dict(source=str(candidate.relative_to(root)), sha256=sha,
                           archive=str(target.relative_to(root))))
    if result:
        directory = os.open(target.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    if result:
        with lease(root,'receipt-archive'):
            index_path=bounded(root,'.state/storage/retired-records/index.json')
            index=json.loads(index_path.read_text()) if index_path.exists() else dict(schema='retired-custody-records.v1',records={})
            if index.get('schema')!='retired-custody-records.v1':raise ValueError('unknown retired record index')
            for row in result:index['records'].setdefault(row['source'],{})[row['sha256']]=row['archive']
            write(index_path,index)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(os.environ.get("GAMBIT_SMP_ROOT", Path.cwd())))
    parser.add_argument("--apply", type=Path)
    parser.add_argument("--sha256")
    parser.add_argument("--resume", action="store_true", help="continue a journaled incomplete deletion")
    parser.add_argument('--audit-task',help='classify nested validation/Git custody without taking over the owner')
    parser.add_argument('--integration-checkout',type=Path,help='read-only canonical Git-flow comparison target')
    parser.add_argument('--path',action='append',help='explicit registered custody path, including recent Git inputs')
    parser.add_argument('--archive-queues',action='store_true',help='preserve verified historical test queues; never complete or replay jobs')
    args = parser.parse_args()
    if args.audit_task:
        if args.apply or args.resume or args.sha256:parser.error('custody audit cannot apply a legacy deletion manifest')
        from gambit_smp.storage_custody import audit
        value=audit(args.root,args.audit_task,archive_queues=args.archive_queues,paths=args.path,integration=args.integration_checkout)
        print(json.dumps(dict(task=args.audit_task,decisions=len(value['decisions']),taskCustody=value['taskCustody'])))
        return 0
    if args.archive_queues or args.path or args.integration_checkout:parser.error('--archive-queues/--path require --audit-task')
    if args.apply:
        if not args.sha256:
            parser.error("--apply requires --sha256")
        value = apply(args.root, args.apply, args.sha256, resume=args.resume)
        print(json.dumps(dict(removed=len(value["removed"]), complete=value["complete"])))
    else:
        value = plan(args.root)
        destination = bounded(args.root, ".state/storage/legacy-cleanup-plan.json")
        write(destination, value)
        print(json.dumps(dict(plan=str(destination), sha256=hashlib.sha256(destination.read_bytes()).hexdigest(),
                              targets=len(value["targets"]), retained=len(value["retained"]),
                              allocatedBytes=sum(row["allocatedBytes"] for row in value["targets"]))))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
