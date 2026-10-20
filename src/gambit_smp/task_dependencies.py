"""In-place task dependency custody and retention policy.

Registration does not execute scripts, move checkpoints or admit native recovery.
"""
import json
import os
from pathlib import Path

from gambit_smp.workspace import bounded, paths, lease, write, now, referenced


def policy(root):
    path = bounded(root, '.state/task-policy.json')
    return json.loads(path.read_text()) if path.exists() else {}


def default_task(root):
    return policy(root).get('defaultTask')


def registry(root, task):
    return bounded(root, '.state/task-dependencies/' + task + '.json')


def dependencies(root, task):
    path = registry(root, task)
    if not path.exists():
        return []
    result = []
    for row in json.loads(path.read_text())['paths']:
        source = bounded(root, row['path'])
        st = source.stat()
        if [st.st_dev, st.st_ino] != row['identity']:
            raise ValueError('registered dependency identity changed: ' + row['path'])
        result.append(source)
    return result


def protected(root, path):
    directory = bounded(root, '.state/task-dependencies')
    if directory.exists():
        for file in directory.glob('*.json'):
            for row in json.loads(file.read_text())['paths']:
                saved = bounded(root, row['path'])
                if saved == path or saved.is_relative_to(path) or path.is_relative_to(saved):
                    return True
    return False


def adopt(root, task, relatives, *, default=False):
    """Register physical identities without touching a byte of the live trees."""
    root = Path(root).resolve(strict=True)
    with lease(root, "storage-retention"), lease(root, task):
        record = json.loads(paths(root, task)[0].read_text())
        if record['state'] != 'open':
            raise ValueError('open task required')
        destination = registry(root, task)
        previous = json.loads(destination.read_text()) if destination.exists() else dict(task=task, paths=[])
        rows = {row['path']: row for row in previous['paths']}
        for relative in relatives:
            path = bounded(root, relative)
            if Path(relative).parts[0] not in {'.cache', '.data'} or len(Path(relative).parts) < 2:
                raise ValueError('explicit legacy artifact path required')
            if path == paths(root, task)[1]:
                raise ValueError('task cache cannot be its own legacy dependency')
            st = path.stat()
            row = dict(path=path.relative_to(root).as_posix(), identity=[st.st_dev, st.st_ino],
                       custody='in-place-pin', registeredAt=now().isoformat())
            if row['path'] in rows and rows[row['path']]['identity'] != row['identity']:
                raise ValueError('cannot replace a registered dependency')
            rows.setdefault(row['path'], row)
        previous.update(paths=list(rows.values()), nativeAdmitted=False)
        write(destination, previous)
        if default:
            current = policy(root)
            if current.get('defaultTask', task) != task:
                raise ValueError('checkout already belongs to another default task')
            write(bounded(root, '.state/task-policy.json'), dict(schema=1, defaultTask=task))
        return previous


def release(root, task, relatives):
    """Explicitly relinquish recovery pins after quiescence, preserving history."""
    from gambit_smp.workspace import active_paths, pending
    with lease(root, 'storage-retention'), lease(root, task):
        if pending(root):
            raise ValueError('pending requests prevent dependency release')
        occupied = active_paths()
        target = registry(root, task)
        value = json.loads(target.read_text())
        names = {bounded(root, name).relative_to(Path(root).resolve()).as_posix() for name in relatives}
        rows = {row['path']: row for row in value['paths']}
        if not names <= rows.keys():
            raise ValueError('unknown dependency pin')
        dependencies(root, task)  # Replacement or missing bytes require reconciliation.
        for name in names:
            if referenced(bounded(root, name), occupied):
                raise ValueError('dependency still occupied')
        released = value.setdefault('released', [])
        for name in sorted(names):
            row = rows.pop(name)
            released.append(dict(row, releasedAt=now().isoformat()))
        value['paths'] = list(rows.values())
        write(target, value)
        return value
