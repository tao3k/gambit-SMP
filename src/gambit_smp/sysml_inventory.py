"""Model-scoped lexical candidate inventory; no inferred caller completeness.

Every eligible byte file and directory membership is bound, including files
with no matches. All conditional branches, comments and emitted strings remain
visible. This is not preprocessing, name resolution or a C/Scheme call graph.
"""
import fnmatch
from bisect import bisect_right
import hashlib
import os
from pathlib import Path
import re

from gambit_smp.sysml_organization import _path


def validate_inventory(flow):
    adapters = {row['id']:row for row in flow.get('adapters',[])}
    sites = {row['id']:row for row in flow.get('sourceSites',[])}
    scopes = flow.get('inventoryScopes',[]); families = flow.get('accessFamilies',[])
    seen, roots = set(), {}
    for row in scopes:
        if row.get('id') in seen or row.get('adapter') not in adapters:
            raise ValueError('unique inventory scope and actual adapter required')
        seen.add(row['id']); path = _path(row.get('path'))
        if not isinstance(row.get('suffixes'),str) or not row['suffixes'] or any(
                not suffix.startswith('.') or '/' in suffix for suffix in row['suffixes'].split(';')):
            raise ValueError('explicit source suffixes required')
        if not isinstance(row.get('exclude'),str) or not isinstance(row.get('boundary'),str) or not row['boundary']:
            raise ValueError('explicit inventory exclusion and semantic boundary required')
        for old in roots.setdefault(row['adapter'],[]):
            if path==old or path in old.parents or old in path.parents:
                raise ValueError('overlapping inventory scopes refused')
        roots[row['adapter']].append(path)
    seen = set()
    for row in families:
        adapter, site = adapters.get(row.get('adapter')), sites.get(row.get('site'))
        if not adapter or not site or site['question']!=adapter['question'] or row.get('id') in seen:
            raise ValueError('unique access family and owned source site required')
        for field in ('id','pattern','role','guard','publication','release','knownCallers','gap','acceptance'):
            if not isinstance(row.get(field),str) or not row[field]:
                raise ValueError('complete access-family lifecycle required')
        seen.add(row['id'])
        compiled = re.compile(row['pattern'].encode('ascii'),re.MULTILINE)
        if compiled.search(b''):
            raise ValueError('empty-match inventory rules refused')
        if row['adapter'] not in roots:
            raise ValueError('access family needs declared inventory scopes')
    if set(roots)!={row['adapter'] for row in families}:
        raise ValueError('inventory scopes and families must share actual owners')


def inspect_inventory(root, flow, adapter):
    """Return all lexical matches and a conservative multi-file review identity."""
    from gambit_smp.sysml_flow import _identity
    root = Path(root).resolve()
    scopes = [row for row in flow.get('inventoryScopes',[]) if row['adapter']==adapter]
    families = [dict(row,matches=[]) for row in flow.get('accessFamilies',[]) if row['adapter']==adapter]
    compiled = [(row,re.compile(row['pattern'].encode('ascii'),re.MULTILINE)) for row in families]
    files, excluded = {}, []
    for scope in scopes:
        directory = root/_path(scope['path'])
        if directory.resolve()!=directory or not directory.is_dir():
            raise ValueError('actual inventory source directory required')
        suffixes = tuple(scope['suffixes'].split(';'))
        exclusions = scope['exclude'].split(';') if scope['exclude'] else []
        def unreadable(error):
            raise error
        for parent, dirs, names in os.walk(directory,followlinks=False,onerror=unreadable):
            dirs.sort()
            if any((Path(parent)/name).is_symlink() for name in dirs):
                raise ValueError('inventory must not silently skip source symlink directories')
            for name in sorted(names):
                if not name.endswith(suffixes):
                    continue
                path = Path(parent)/name
                if path.resolve()!=path:
                    raise ValueError('inventory source symlinks refused')
                relative = path.relative_to(root).as_posix()
                if any(fnmatch.fnmatchcase(name,pattern) for pattern in exclusions):
                    excluded.append(relative); continue
                data = path.read_bytes(); files[relative] = hashlib.sha256(data).hexdigest()
                lines = [0] + [match.end() for match in re.finditer(b'\n',data)]
                for family, pattern in compiled:
                    for match in pattern.finditer(data):
                        family['matches'].append(dict(artifact=relative,offset=match.start(),
                            line=bisect_right(lines,match.start()),
                            token=match.group().decode('ascii')))
    for family in families:
        family['matches'].sort(key=lambda row:(row['artifact'],row['offset']))
        family['matchCount'] = len(family['matches'])
        family['artifactCount'] = len({row['artifact'] for row in family['matches']})
        family['semanticVerified'] = False
    subject = dict(scopes=scopes,families=families,files=files,excluded=sorted(excluded))
    return dict(subject,subjectSha256=_identity(subject),classification='lexical-candidates-only',
                semanticVerified=False,atomicSnapshot=False)
