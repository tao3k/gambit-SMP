"""Thin use of existing workspace custody; no alternate reuse implementation."""
import json
import sys
from pathlib import Path
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
from gambit_smp.task_processes import run
root = Path.cwd()
step = json.loads((root / '.cache/tasks/modern-c-frame-contract/runs/bazel-request-custody/run/bootstrap/step-receipt.json').read_text())
assert step['outcome'] == 'PASS' and step['fullTwoPassBootstrapEstablished']
assert all(n == 2 for n in step['phaseCounts'].values())
runtime = step['outputs']['runtime']
with workspace_lease(root, root / runtime['workspace'], runtime['identity']) as source:
    run(['ruby', '.cache/tasks/modern-c-frame-contract/cohort/check-reused-wide.rb'], check=True)
    assert tree_identity(source) == runtime['identity'], 'runtime mutated during tests'
