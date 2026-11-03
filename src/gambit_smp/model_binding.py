"""Rebuild typed SysML selections from one explicit current or immutable epoch.

The caller owns the SDK connection. No model cache, download, process runner or
runtime admission is introduced by source/selection identity checks.
"""
import hashlib
import json
from pathlib import Path
import re

from gambit_smp.framework import digest


def api_binding(connection, root, binding, *, source_identities=None):
    """Rebuild a bounded binding from SysML; cached values grant no authority.

    The caller supplies the existing qualified SDK connection. Publication keeps
    source/selection identities and a typed-value digest instead of another copy
    of model prose, diagrams and old projections. An explicit immutable source
    set selects a historical epoch; it never falls back to current files.
    """
    root = Path(root).resolve()
    selection = binding['selection']
    if (not isinstance(selection, list) or not selection or
            any(not isinstance(name, str) or
                not re.fullmatch(r'[A-Za-z_]\w*(?:::\w+)*(?:\.\w+)*', name)
                for name in selection) or len(set(selection)) != len(selection)):
        raise ValueError('unique qualified model field selection required')
    if source_identities is not None:
        from gambit_smp.source_identity import read_git_sources
        if set(source_identities) != set(binding['inputs']):
            raise ValueError('complete immutable model source set required')
        identities = [source_identities[name] for name in binding['inputs']]
        for name, identity in zip(binding['inputs'], identities):
            if (identity.get('path') != name or
                    identity.get('sha256') != binding['inputs'][name]):
                raise ValueError('immutable model source identity differs from binding')
        contents = read_git_sources(root, identities)
        if any(content is None for content in contents):
            raise ValueError('immutable model source unavailable')
    documents = []
    for name, expected in binding['inputs'].items():
        path = Path(name)
        source = root / path
        if path.is_absolute() or '..' in path.parts or '.cache' in path.parts:
            raise ValueError('canonical repository model source required')
        if source_identities is not None:
            text = contents[len(documents)].decode('utf-8', 'strict')
        elif (source.resolve() != source or not source.is_file() or digest(source) != expected):
            raise ValueError('current repository model source required')
        else:
            text = source.read_text()
        documents.append((name, text))
    if not documents:
        raise ValueError('model source closure required')
    model = connection.parse_sources(documents, strict=True, strict_conformance=True)
    model.raise_for_errors()
    if model.diagnostics or model.hash != binding['sdkObservation']['modelHash']:
        raise ValueError('diagnostic-free matching native model required')
    values = {name: model.eval(name) for name in selection}
    if any(type(value) not in (str, int, bool) for value in values.values()):
        raise ValueError('set scalar model values required')
    actual = hashlib.sha256(json.dumps(values, sort_keys=True, separators=(',', ':')).encode()).hexdigest()
    if actual != binding['projectionSha256']:
        raise ValueError('typed native projection identity differs')
    return dict(binding, expressions=values)
