"""Isolated validator fixtures, never published as research evidence."""
from contextlib import contextmanager
import json
from pathlib import Path
import shutil
import tempfile

from gambit_smp.framework import digest


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
