"""Resume inference after an externally stale snapshot; do not rerun formal tools."""
import hashlib
import importlib.util
import json
from pathlib import Path
import traceback

root = Path.cwd()
spec = importlib.util.spec_from_file_location('span_study', root / 'dev/modeling/tools/reader-span-study.py')
study = importlib.util.module_from_spec(spec)
spec.loader.exec_module(study)
cache = study.CACHE
old_input = json.loads((cache / 'input.json').read_text())
old_checks = json.loads((cache / 'checks.json').read_text())
assert old_checks['status'] == 'conditional-model-checks-pass'
for name in [study.QNT, study.LEAN, study.PARAM, study.MODEL, study.RULES]:
    assert study.sha(root / name) == old_input['sourceBindings'][name], name
retained = json.loads((study.EVIDENCE / 'artifacts.json').read_text())
for name in ['quint-tests.stdout', 'quint-init.stdout', 'quint-initHeader.stdout', 'lean.stdout']:
    origin = study.EVIDENCE / name
    assert study.sha(origin) == retained[str(origin.relative_to(root))], name
    # Later successful runs have different timing/seed diagnostics. Keep them,
    # while using the immutable originally qualified formal receipt as origin.
    (cache / ('post-layout-' + name)).write_bytes((cache / name).read_bytes())
    (cache / name).write_bytes(origin.read_bytes())
(cache / 'formal-origin-input.json').write_text(json.dumps(old_input, indent=2))
(cache / 'stale-inference-history.json').write_text(json.dumps({
    'provenance': 'Recovered from tool response of final projection run',
    'failure': 'trajectory action source changed: docs/smp-retirement-research-index.md',
    'meaning': 'External evidence-index change invalidated inference snapshot; not a model counterexample'
}, indent=2))
p = json.loads((cache / 'projection.json').read_text())
for attempt in range(3):
    try:
        summary = study.inference(p)
        break
    except ValueError as error:
        (cache / f'inference-snapshot-failure-{attempt}.txt').write_text(traceback.format_exc())
        if 'trajectory action source changed:' not in str(error) or attempt == 2:
            raise
else:
    raise RuntimeError('No stable inference snapshot')
old_checks.update(summary)
old_checks.update(inferenceResumedAfterStaleSnapshot=True, formalToolsRerunOnResume=False,
                  formalSubjectsVerifiedUnchanged=True)
study.save(cache / 'checks.json', old_checks)
new_input = json.loads((cache / 'input.json').read_text())
assert all(study.sha(root / name) == digest for name, digest in new_input['sourceBindings'].items())
for path in cache.iterdir():
    if path.is_file() and path.suffix != '.png':
        (study.EVIDENCE / path.name).write_bytes(path.read_bytes())
study.save(study.EVIDENCE / 'artifacts.json', {
    str(path.relative_to(root)): study.sha(path) for path in study.EVIDENCE.iterdir()
    if path.is_file() and path.name != 'artifacts.json'
})
print(json.dumps({k: v for k, v in old_checks.items() if k != 'retainedSysmlWarnings'}))
