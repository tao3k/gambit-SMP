"""Publish retained binary bytes without overwriting a validated executable inode."""
import hashlib
import os
from pathlib import Path
import re
import tempfile

from gambit_smp.artifact_storage import clone_file, runtime_output


def _regular(path):
    if any(part.is_symlink() for part in (path, *path.parents)):
        raise ValueError('product paths cannot traverse aliases')
    if not path.is_file():
        raise ValueError('regular product required')


def materialize_product(root, source, destination, expected_sha256):
    """Replace one task-owned product atomically, under the caller's lease.

    A fresh inode matters on Darwin: in-place writes can invalidate cached
    executable signatures even when a later digest matches. This transfers
    bytes, not qualification authority, and is not a concurrent-writer lock.
    """
    if not re.fullmatch(r'[0-9a-f]{64}', expected_sha256):
        raise ValueError('exact SHA256 required')
    source = Path(os.path.abspath(source))
    declared = Path(os.path.abspath(destination))
    _regular(source)
    if any(part.is_symlink() for part in (declared, *declared.parents)):
        raise ValueError('product destination cannot traverse aliases')
    destination = runtime_output(root, declared)
    if source == destination or (destination.exists() and os.path.samefile(source, destination)):
        raise ValueError('source and destination must be distinct products')
    before = source.stat()
    identity = (before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns)
    if hashlib.sha256(source.read_bytes()).hexdigest() != expected_sha256:
        raise ValueError('source product digest mismatch')
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.product-', dir=destination.parent) as temporary:
        staged = Path(temporary) / 'product'
        method = clone_file(source, staged)
        after = source.stat()
        if (identity != (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
                or hashlib.sha256(staged.read_bytes()).hexdigest() != expected_sha256
                or hashlib.sha256(source.read_bytes()).hexdigest() != expected_sha256):
            raise ValueError('source product changed during materialization')
        os.replace(staged, destination)
    return dict(sha256=expected_sha256, method=method, publication='fresh-inode-replace')
