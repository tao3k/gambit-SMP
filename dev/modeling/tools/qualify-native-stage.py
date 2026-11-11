"""Bounded transport orchestration; all native work stays in declared Recipes.

Run under the existing workspace supervisor so nested dispatcher calls inherit
one live task lease rather than repeatedly reconciling all historical children.
"""
import argparse
import json
import os
import hashlib
import re
from pathlib import Path
import sys
from gambit_smp.task_processes import run

parser = argparse.ArgumentParser()
parser.add_argument('demand', choices=('reuse-explicit-artifact',))
parser.add_argument('--prior')
parser.add_argument('--out', required=True)
args = parser.parse_args()
root = Path.cwd()
base = root / 'evidence/research/darwin-native-stage'
cohort = root / '.cache/tasks/modern-c-frame-contract/cohort'
engine = cohort / 'native-stage-configure-sampling-engine'
dispatcher = str(root / '.venv/bin/gambit-smp')
from gambit_smp.artifact_storage import runtime_output
transport = runtime_output(root, cohort / 'native-stage-transport' / os.environ['GAMBIT_SMP_TASK_RUN'])
transport.mkdir(parents=True, exist_ok=False)


def command(name, argv, budget):
    result = run(argv, cwd=root, text=True, capture_output=True, timeout=budget)
    (transport / (name + '.stdout')).write_text(result.stdout)
    (transport / (name + '.stderr')).write_text(result.stderr)
    print(json.dumps(dict(step=name, exit=result.returncode)), flush=True)
    if result.returncode:
        receipt=Path(args.out)/'run/receipt.json'
        if name == args.demand and receipt.is_file():
            data=json.loads(receipt.read_text())
            print(json.dumps(dict(failures=[{k:s.get(k) for k in ('id','outcome','reason')}
                for s in data['steps'] if s['outcome'] not in {'PASS','BLOCKED'}])),flush=True)
        else:
            print(result.stdout[-3000:] + result.stderr[-3000:], flush=True)
        sys.exit(result.returncode)


if not (base / 'native-delta.lock.json').exists():
    command('source-export', [dispatcher, 'materialize-source', '--export-candidate',
        'vendor/gambit', '--lock', str(base/'native-delta.lock.json'),
        '--patch', str(base/'native-delta.patch'), '--file', 'lib/_mem/configuration.inc'], 60)
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
control_sources = ['src/gambit_smp/'+name+'.py' for name in
                   ('native_development','generation_artifacts','native_capabilities','research_kernel',
                    'reasoning_history','build_profile','completed_producer','historical_inputs')]
control_sources += ['src/gambit_smp/'+name+'.py' for name in
                    ('bootstrap_artifacts','artifact_storage','workspace','cli','validation_domains')]
control_sources += ['tests/test_'+name+'.py' for name in
                    ('native_development','build_profile','completed_producer','historical_inputs')]
control_sources += ['tests/test_'+name+'.py' for name in ('bootstrap_artifacts','workspace','cli')]
source_hashes = {p:sha(root/p) for p in control_sources}
certificate = base/'transport-controls.json'
previous = json.loads(certificate.read_text()) if certificate.exists() else None
if previous is None or previous['sourceHashes'] != source_hashes:
    command('stage-controls', [str(root/'.venv/bin/python'), '-c',
        'from gambit_smp.validation_domains import isolated_test_context; import unittest\n'
        'with isolated_test_context(): unittest.main(module=None)',
        'tests.test_native_development', 'tests.test_build_profile', 'tests.test_completed_producer',
        'tests.test_historical_inputs', 'tests.test_bootstrap_artifacts',
        'tests.test_workspace.WorkspaceTests.test_build_entry_reconciles_its_owner_without_global_retention',
        'tests.test_cli.CommandTests.test_native_run_returns_receipt_without_evaluating_the_evidence_catalog',
        'tests.test_cli.CommandTests.test_read_presentation_is_dispatcher_owned_and_does_not_leak_to_workers',
        '-v'], 90)
    if previous is not None:
        records=base/'controls';records.mkdir(exist_ok=True)
        (records/(sha(certificate)+'.json')).write_bytes(certificate.read_bytes())
    log=transport/'stage-controls.stderr'
    count=re.search(r'Ran (\d+) tests',log.read_text())
    if not count: raise ValueError('test completion marker missing')
    certificate.write_text(json.dumps(dict(sourceHashes=source_hashes,exit=0,tests=int(count[1]),
        stderr=dict(path=str(log.relative_to(root)),sha256=sha(log)),nativeAccepted=False),indent=2)+'\n')
elif sha(root/previous['stderr']['path']) != previous['stderr']['sha256']:
    raise ValueError('retained test certificate drifted; cannot silently reissue unchanged evidence')
if not (base/'completed-configure-make-producer.json').exists():
    command('producer-export', [dispatcher, 'research', '--export-producer',
        '.cache/tasks/modern-c-frame-contract/runs/darwin-producer-bootstrap', '--step', 'bootstrap',
        '--input-archive', 'evidence/research/darwin-native-stage/configure-make-historical-inputs.json',
        '--out', str(base/'completed-configure-make-producer.json')], 90)
if not engine.exists():
    command('engine-seal', [dispatcher, 'research', '--seal', str(engine), '--gcc',
        '/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16', '--ascent-api',
        str(root/'.venv/lib/python3.14/site-packages/ascent')], 90)
native = [dispatcher, 'research', '--run', str((base/'existing-make.recipe.json').relative_to(root)),
          '--engine', str(engine), '--out', args.out]
if args.prior:
    native += ['--prior', args.prior]
command(args.demand, native, 600)
