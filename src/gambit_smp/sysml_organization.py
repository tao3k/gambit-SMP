"""Model-owned delivery boundaries and source locations, never runtime verdicts.

Literal anchors locate every occurrence in actual bytes. They are a navigation
and invalidation aid, not a C/Scheme parser, a complete caller inventory or a
semantic refinement proof. No process or SDK lifecycle is introduced here.
"""
import hashlib
from pathlib import Path


def _path(name):
    if not isinstance(name, str) or not name:
        raise ValueError('repository-owned organization subject required')
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or '.cache' in path.parts or str(path) != name:
        raise ValueError('canonical organization subject required')
    return path


def validate_organization(flow):
    streams = {row['id']: row for row in flow.get('workstreams', [])}
    if len(streams) != len(flow.get('workstreams', [])):
        raise ValueError('unique workstream identity required')
    questions = {row['id']: row for row in flow['questions']}
    assignments = flow.get('assignments', [])
    if not streams:
        if any(flow.get(name) for name in ('assignments','workDependencies','progressAxes','sourceSites')):
            raise ValueError('organization needs model-owned workstreams')
        return
    for row in streams.values():
        for field in ('id','label','authority','unit','entry','exit','excluded','netBenefit'):
            if not isinstance(row.get(field), str) or not row[field]:
                raise ValueError('complete workstream boundary required')
    mapped = set()
    for row in assignments:
        identity = row.get('question')
        if identity not in questions or identity in mapped or row.get('workstream') not in streams:
            raise ValueError('each question needs one primary workstream')
        mapped.add(identity)
    if mapped != set(questions):
        raise ValueError('every question needs its primary workstream')
    graph = {key: set() for key in streams}
    for row in flow.get('workDependencies', []):
        a, b = row.get('dependent'), row.get('prerequisite')
        if a not in streams or b not in streams or b in graph[a]:
            raise ValueError('dangling or duplicate workstream dependency')
        graph[a].add(b)
    pending, done = set(), set()
    def visit(key):
        if key in pending:
            raise ValueError('cyclic workstream dependency')
        if key in done:
            return
        pending.add(key)
        for dependency in graph[key]:
            visit(dependency)
        pending.remove(key); done.add(key)
    for key in streams:
        visit(key)
    identities = set()
    for row in flow.get('progressAxes', []):
        for field in ('id','authority','reported','meaning','credit'):
            if not isinstance(row.get(field), str) or not row[field]:
                raise ValueError('explicit progress provenance and no-transfer boundary required')
        if row['id'] in identities:
            raise ValueError('duplicate progress axis')
        identities.add(row['id'])
    sites, located_questions = set(), set()
    for row in flow.get('sourceSites', []):
        if row.get('question') not in questions or row.get('id') in sites:
            raise ValueError('unique source site and actual question required')
        for field in ('id','anchor','role','observed','required','gap'):
            if not isinstance(row.get(field), str) or not row[field]:
                raise ValueError('source location must retain its required adapter and gap')
        _path(row.get('artifact'))
        sites.add(row['id']); located_questions.add(row['question'])
    required = {key for key, row in questions.items() if row['owner'] in {'source','native'}}
    if not required <= located_questions:
        raise ValueError('every source/native question needs actual source locations')


def source_bindings(root, flow):
    """Locate sites and hash dirty working bytes without editing or executing them."""
    root = Path(root).resolve()
    result = []
    # Read each subject once so duplicate locations share the same observed bytes.
    subjects = {}
    for row in flow.get('sourceSites', []):
        name = row['artifact']; path = root/_path(name)
        if path.resolve() != path:
            raise ValueError('source subject must not escape through symlinks')
        if name not in subjects:
            subjects[name] = path.read_bytes() if path.is_file() else None
        data = subjects[name]; anchor = row['anchor'].encode()
        offsets, cursor = [], 0
        if data is not None:
            while (offset := data.find(anchor, cursor)) >= 0:
                offsets.append(offset); cursor = offset + len(anchor)
        result.append(dict(row, sha256=hashlib.sha256(data).hexdigest() if data is not None else '',
                           lines=[data[:offset].count(b'\n')+1 for offset in offsets],
                           status='located' if offsets else 'missing',
                           semanticVerified=False))
    return result


def organization_facts(root, flow):
    sites = source_bindings(root, flow)
    return dict(
        shWorkstream=[[row['id']] for row in flow.get('workstreams', [])],
        shAssignment=[[row['question'], row['workstream']] for row in flow.get('assignments', [])],
        shWorkDependency=[[row['dependent'], row['prerequisite']] for row in flow.get('workDependencies', [])],
        shSourceSite=[[row['id'],row['question'],row['artifact'],row['sha256'],row['status']] for row in sites],
        shSourceRequirement=[[row['id'],row['gap']] for row in sites])
