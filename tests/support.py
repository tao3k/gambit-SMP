"""Isolated validator fixtures, never published as research evidence."""
from contextlib import contextmanager
import json
import hashlib
from pathlib import Path
import shutil
import tempfile

from gambit_smp.framework import digest


def borrow_git_sources(repository, root, identities):
    """Give an isolated fixture real read-only Git object provenance.

    Object alternates borrow an existing repository; no checkout, branch or
    source file is copied. This never proves the fixture HEAD/index is a build.
    """
    from gambit_smp import workspace
    from gambit_smp.source_identity import read_source
    repository, root = Path(repository).resolve(), Path(root).resolve()
    if root == repository:
        raise ValueError('isolated fixture source owner required')
    for identity in identities:
        if identity.get('kind') != 'git':
            raise ValueError('fixture needs an explicit Git source identity')
        read_source(repository, identity)
        source = (repository / identity['repository']).resolve()
        target = (root / identity['repository']).resolve()
        target.relative_to(root)
        target.mkdir(parents=True, exist_ok=True)
        if not (target / '.git').exists():
            workspace.git(target, 'init', '-q')
        if Path(workspace.git(target, 'rev-parse', '--show-toplevel')).resolve() != target:
            raise ValueError('fixture Git source owner is not exact')
        objects = Path(workspace.git(source, 'rev-parse', '--git-path', 'objects'))
        if not objects.is_absolute():
            objects = source / objects
        destination = Path(workspace.git(target, 'rev-parse', '--git-path', 'objects'))
        if not destination.is_absolute():
            destination = target / destination
        destination.resolve().relative_to(root)
        path = destination / 'info/alternates'
        path.parent.mkdir(parents=True, exist_ok=True)
        names = path.read_text().splitlines() if path.exists() else []
        if str(objects.resolve()) not in names:
            path.write_text('\n'.join([*names, str(objects.resolve())]) + '\n')


def copy_output_observations(repository, root, prefix):
    """Transport the selected durable observations, never the raw cache."""
    source = json.loads((repository/'evidence/published-inputs.json').read_text())
    path = root/'evidence/published-inputs.json'
    path.parent.mkdir(parents=True, exist_ok=True)
    selected = {identity: dict(item, origins=[name for name in item['origins']
                if name.startswith(str(prefix).rstrip('/')+'/')])
                for identity, item in source.get('observations', {}).items()
                if any(name.startswith(str(prefix).rstrip('/')+'/') for name in item['origins'])}
    for item in selected.values():
        if 'sources' in item:
            item['sources'] = {name: value for name, value in item['sources'].items()
                               if name in item['origins']}
    borrow_git_sources(repository, root, [identity for item in selected.values()
                                         for identity in item.get('sources', {}).values()])
    path.write_text(json.dumps(dict(schema=source['schema'], records={}, observations=selected)))


def copy_live_view(repository, root, name):
    """Initialize a mutable test view from exact declared source bytes.

    The copied files belong to the isolated fixture, not the original Git
    repository. Retain their byte/range identities; remove immutable locators
    only in this explicitly live fixture. Never use this as research evidence.
    """
    from gambit_smp.source_identity import reference_bytes
    document = json.loads((repository / name).read_text())
    original = json.loads(json.dumps(document))
    plan = {}
    for ref in document['references']:
        raw = reference_bytes(repository, ref)
        if hashlib.sha256(raw).hexdigest() != ref['sha256']:
            raise ValueError('live fixture original byte identity differs')
        if ref['path'] in plan and plan[ref['path']] != raw:
            raise ValueError('live fixture needs one source epoch per path')
        plan[ref['path']] = raw
        ref.pop('identity', None)
    manifest = document['manifest']
    catalog = json.loads((repository / manifest).read_text())
    plan[manifest] = (repository / manifest).read_bytes()
    for component in catalog['components']:
        source = component['source']
        if source.startswith('package:'):
            continue
        path = (Path(manifest).parent / source).as_posix()
        plan[path] = (repository / path).read_bytes()
    for path, raw in plan.items():
        target = root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(raw)
    target = root / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps(document))
    receipt = root / 'tests/fixture-sources.json'
    receipt.parent.mkdir(parents=True, exist_ok=True)
    receipt.write_text(json.dumps(dict(view=name, originalView=original,
                                      role='isolated mutable test bytes, never research admission')))
    return document


@contextmanager
def task_fixture(name):
    """A real isolated task for CLI controls, not a relaxed storage policy."""
    from unittest.mock import patch
    from gambit_smp import workspace
    from gambit_smp.validation_domains import isolated_test_context
    with isolated_test_context(), tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary).resolve()
        workspace.git(root, 'init', '-q')
        workspace.git(root, '-c', 'user.name=Test', '-c', 'user.email=test@example.invalid',
                      'commit', '--allow-empty', '-qm', 'test')
        workspace.start(root, name, adopt=True)
        with patch('gambit_smp.framework.ROOT', root), \
                patch('gambit_smp.framework.project_root', return_value=root), \
                patch('gambit_smp.task_dependencies.default_task', return_value=name):
            yield root, root / '.cache/tasks' / name


@contextmanager
def clue_fixture(repository, claims=32, body="fixture source"):
    """A finite, byte-attested corpus; size is test data, not a query limit."""
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary).resolve()
        folder = root / 'evidence'
        folder.mkdir()
        source = folder / 'clues.ss'
        shutil.copyfile(repository / 'evidence/scenarios/stack-header/clues.ss', source)
        (folder / 'basis.md').write_text(body)
        (folder / 'components.json').write_text(json.dumps({
            'schema': 'ascent.evidence-components.v1', 'components': [{
                'id': 'fixture', 'source': 'clues.ss',
                'exports': ['make-stack-entry-clues'], 'dependencies': []}]}))
        (folder / 'views.json').write_text(json.dumps({
            'schema': 'ascent.evidence-views.v1', 'views': ['evidence/clues.view.json']}))
        (folder / 'clues.view.json').write_text(json.dumps({
            'schema': 'ascent.evidence-view.v1', 'id': 'pagination-fixture',
            'manifest': 'evidence/components.json', 'entry': 'fixture',
            'constructor': 'make-stack-entry-clues',
            'facts': {
                'observation': [[f'observation-{i}', f'claim-{i}',
                                 'support' if i % 2 else 'counter', 'basis'] for i in range(claims)],
                'attribute': [[f'observation-{i}', 'source-text',
                               {'reference': 'basis', 'field': 'text'}] for i in range(claims)],
                'edge': [[f'observation-{i}', f'claim-{i + 1}', 'related']
                         for i in range(claims - 1)],
                'reference': {'references': True}},
            'queries': {'clue': 'clue', 'factor': 'factor', 'link': 'link'},
            'references': [{'id': 'basis', 'path': 'evidence/basis.md',
                            'sha256': digest(folder / 'basis.md'), 'pointer': None,
                            'ranges': [{'start': 0, 'end': (folder / 'basis.md').stat().st_size,
                                        'sha256': digest(folder / 'basis.md')}]}]}))
        yield root


@contextmanager
def protocol_fixture(repository, manifest_name, receipt_name):
    """Retain checker logs/models but substitute explicitly synthetic context."""
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary).resolve()
        manifest = json.loads((repository / manifest_name).read_text())
        receipt = json.loads((repository / receipt_name).read_text())
        shutil.copytree((repository / receipt_name).parent, (root / receipt_name).parent)
        copy_output_observations(repository, root, Path(receipt_name).parent)
        for case in manifest["cases"]:
            name = "models/gambit/" + case["id"] + ".qnt"
            (root / name).parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(repository / name, root / name)
        for name in manifest["contextInputs"]:
            target = root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text("Synthetic context for validator unit tests; not native source.\n")
            manifest["contextInputs"][name] = digest(target)
            receipt["inputs"][name] = digest(target)
        (root / manifest_name).parent.mkdir(parents=True, exist_ok=True)
        (root / manifest_name).write_text(json.dumps(manifest))
        (root / receipt_name).write_text(json.dumps(receipt))
        yield root, manifest, root / receipt_name


_source_checkpoint_rows = {}


def source_checkpoint_fixture_rows(root):
    """Copy authenticated immutable prerequisites before isolating test history.

    These are exact existing SQLite rows, not a simulated recovery result.
    """
    from gambit_smp.reasoning_history import _database, read_execution_checkpoint
    from gambit_smp.source_identity import read_source
    registry = json.loads((root/'evidence/views.json').read_text())
    files = [root/name for name in registry['views']]
    key = tuple((str(file),digest(file)) for file in files)
    if key in _source_checkpoint_rows:
        return _source_checkpoint_rows[key]
    runs=set()
    for file in files:
        for ref in json.loads(file.read_text())['references']:
            identity=ref.get('identity',{})
            if identity.get('kind')=='task-checkpoint':
                read_source(root,identity)
                runs.add(str((root/identity['run']).resolve()))
    checkpoints=[];observations={}
    with _database(root) as db:
        for run in runs:
            for row in db.execute('SELECT * FROM execution_checkpoints WHERE run=? ORDER BY sequence',(run,)):
                checkpoints.append(row)
                identity=json.loads(row[-1])['observation']
                observations[identity]=db.execute('SELECT * FROM observations WHERE id=?',(identity,)).fetchone()
    rows=(tuple(observations.values()),tuple(checkpoints))
    _source_checkpoint_rows[key]=rows
    return rows


def seed_source_checkpoint_fixture(root, rows):
    """Install exact prerequisite rows; ordinary readers still verify the chain."""
    from gambit_smp.reasoning_history import _database
    with _database(root) as db:
        db.execute('BEGIN IMMEDIATE')
        db.executemany('INSERT OR IGNORE INTO observations VALUES (?,?)',rows[0])
        db.executemany('INSERT OR IGNORE INTO execution_checkpoints VALUES (?,?,?,?)',rows[1])
        db.commit()


def published_digest(root, path):
    """Historical output identity is durable even when its raw cache is gone."""
    from gambit_smp.output_observations import TRANSCRIPT_SUFFIXES, recorded
    from gambit_smp.framework import digest
    return recorded(root, path)['sha256'] if path.suffix in TRANSCRIPT_SUFFIXES else digest(path)
