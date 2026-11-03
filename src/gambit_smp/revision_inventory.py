"""Read-only, model-owned HEAD/index/working inventory for a pending REV queue.

Native SysML supplies exact primary ownership and dependencies. This module
checks coverage and observes Git bytes; it grants no semantic/test admission.
"""
from collections import Counter
import hashlib
import os
from pathlib import Path
import re

from gambit_smp.task_processes import run


def ownership(paths, packages):
    """Require one primary owner per pending path, with a closed acyclic graph."""
    paths = set(paths)
    owners, graph = {}, {}
    for package in packages:
        name = package['id']
        if not isinstance(name, str) or not name or name in graph:
            raise ValueError('unique named model packages required')
        members, dependencies = package['paths'], package['depends']
        if len(members) != len(set(members)) or len(dependencies) != len(set(dependencies)):
            raise ValueError('duplicate model path or dependency')
        graph[name] = set(dependencies)
        for path in members:
            p = Path(path)
            if p.is_absolute() or '..' in p.parts or path in owners:
                raise ValueError('ambiguous or escaping primary ownership: ' + path)
            owners[path] = name
    if set(owners) != paths:
        raise ValueError('model/pending coverage differs: missing=' +
                         repr(sorted(paths - set(owners))) + '; stale=' +
                         repr(sorted(set(owners) - paths)))
    active, closed = set(), set()

    def visit(name):
        if name not in graph or name in active:
            raise ValueError('unknown or cyclic model dependency: ' + name)
        if name in closed:
            return
        active.add(name)
        for parent in sorted(graph[name]):
            visit(parent)
        active.remove(name)
        closed.add(name)
    for name in graph:
        visit(name)
    return owners


def inventory(root, repository, packages):
    """Capture all three versions; reject concurrent source/index/HEAD drift."""
    root, repository = Path(root).resolve(), Path(repository).resolve()
    if not repository.is_relative_to(root):
        raise ValueError('repository must belong to the declared root')
    env = dict(os.environ, GIT_OPTIONAL_LOCKS='0')

    def git(*args):
        result = run(['git', '--no-optional-locks', '-C', str(repository), *args],
                     cwd=root, env=env, capture_output=True, timeout=30)
        if result.returncode:
            raise ValueError(result.stderr[:1500].decode(errors='replace'))
        return result.stdout

    def pending():
        raw = git('status', '--porcelain=v1', '-z', '--untracked-files=all', '--no-renames')
        return raw, {os.fsdecode(row[3:]): row[:2].decode()
                     for row in raw.split(b'\0') if row}

    def working(name):
        path = repository / name
        if any(p.is_symlink() for p in (path, *path.parents) if p != repository.parent):
            raise ValueError('source aliases require separate admission: ' + name)
        if not path.exists():
            return None
        if not path.is_file():
            raise ValueError('regular source required: ' + name)
        return path.read_bytes()

    sha = lambda data: hashlib.sha256(data).hexdigest() if data is not None else None
    head = git('rev-parse', 'HEAD').decode().strip()
    initial_index = git('ls-files', '--stage', '-z')
    initial_status, statuses = pending()
    owners = ownership(statuses, packages)
    entries = {}
    for row in initial_index.split(b'\0'):
        if row:
            fields, name = row.split(b'\t', 1)
            mode, blob, stage = fields.split()
            if stage != b'0':
                raise ValueError('unmerged index requires an explicit resolution')
            entries[os.fsdecode(name)] = (mode.decode(), blob.decode())
    rows, observed_working = [], {}
    for name in sorted(statuses):
        tree = git('ls-tree', '-z', head, '--', name)
        blob = tree.split(b'\t', 1)[0].split()[-1].decode() if tree else None
        old = git('cat-file', 'blob', blob) if blob else None
        indexed_blob = entries.get(name, (None, None))[1]
        indexed = git('cat-file', 'blob', indexed_blob) if indexed_blob else None
        current = working(name)
        observed_working[name] = sha(current)
        coordinates = bool(old is not None and current is not None and old != current and
            re.sub(rb'(?m)^#line[^\n]*\n', b'', old) ==
            re.sub(rb'(?m)^#line[^\n]*\n', b'', current))
        rows.append(dict(path=name, status=statuses[name], owner=owners[name],
            headBlob=blob, indexBlob=indexed_blob, headSha256=sha(old),
            indexSha256=sha(indexed), workingSha256=sha(current),
            workingEqualsHead=current == old, indexEqualsHead=indexed == old,
            coordinateDirectivesOnly=coordinates))
    if (head != git('rev-parse', 'HEAD').decode().strip() or
            initial_index != git('ls-files', '--stage', '-z') or
            initial_status != pending()[0] or
            observed_working != {name: sha(working(name)) for name in statuses}):
        raise ValueError('concurrent pending source/index/HEAD change')
    return dict(baseRevision=head, repository=str(repository.relative_to(root)),
        pathCount=len(rows), rows=rows, owners=dict(sorted(Counter(owners.values()).items())),
        indexSha256=sha(initial_index), statusSha256=sha(initial_status),
        sourceCopies=0, sourceMutated=False, runtimeAdmitted=False,
        boundary='Read-only double-read observation, not an atomic filesystem snapshot or ABA-proof writer-freeze credential. Primary ownership and observed bytes only; shared hunks, semantic correctness, producer lineage and test admission require explicit source reviews.')
