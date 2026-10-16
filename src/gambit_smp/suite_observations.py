"""Transport fresh declared suite outputs; never infer semantic admission."""
import json
import os
from pathlib import Path
import re
import stat

from gambit_smp.framework import digest


MAX_BYTES = 65536


def validate(value, files):
    if (not isinstance(value, dict) or not value or len(value) > 32
            or not set(value) <= set(files)
            or any(not isinstance(name, str) or not re.fullmatch(
                r"observations/[A-Za-z0-9_-]+\.json", name) for name in value.values())
            or len(set(value.values())) != len(value)):
        raise ValueError("unique bounded observation outputs belonging to selected fixtures required")


def path_inside(work, name):
    path = work / name
    if path.parent.is_symlink() or path.is_symlink():
        raise ValueError("suite observation symlinks are forbidden")
    if not path.resolve().is_relative_to(work.resolve()):
        raise ValueError("suite observation escaped its shard")
    return path


def prepare(work, declared, files):
    selected = {file: name for file, name in declared.items() if file in set(map(str, files))}
    for name in selected.values():
        path = path_inside(work, name)
        if path.exists():
            raise ValueError("suite observation must be absent before execution")
        path.parent.mkdir(exist_ok=True)
    return selected


def capture(work, selected, destination):
    """Freeze exact regular-file bytes after successful, quiescent execution."""
    from gambit_smp.recipes import read_json
    if not selected:
        return []
    destination.mkdir(parents=True, exist_ok=False)
    observations = []
    for fixture, name in sorted(selected.items()):
        source = path_inside(work, name)
        fd = os.open(source, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK)
        with os.fdopen(fd, "rb") as stream:
            before = os.fstat(stream.fileno())
            if not stat.S_ISREG(before.st_mode) or before.st_size > MAX_BYTES:
                raise ValueError("bounded regular suite observation required")
            raw = stream.read(MAX_BYTES + 1)
            after = os.fstat(stream.fileno())
        current = source.lstat()
        def identity(item):
            return (item.st_dev, item.st_ino, item.st_mode, item.st_size,
                    item.st_mtime_ns, item.st_ctime_ns)
        if (identity(before) != identity(after) or identity(current) != identity(before)
                or len(raw) != before.st_size or len(raw) > MAX_BYTES):
            raise ValueError("suite observation changed during capture")
        target = destination / Path(name).name
        with target.open("xb") as stream:
            stream.write(raw)
        payload = read_json(target)
        if not isinstance(payload, dict):
            raise ValueError("suite observation must be a structured JSON object")
        observations.append({"fixture": fixture, "declaredPath": name,
            "file": target.name, "sha256": digest(target), "bytes": len(raw),
            "semanticAdmitted": False})
    return observations
