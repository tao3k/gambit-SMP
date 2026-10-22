"""Gambit SMP research and verification framework.

Public Evidence API: repository_clues evaluates caller-owned Scheme/Datalog
over registered Evidence, managing its checked engine by default. Its brief
and persistent checkpoint token support source-bound progressive reads.
engine_api is an optional context manager for grouped reads.

help(repository_clues) is the shared CLI/API contract for sources, term syntax,
scope, presentation and checkpoints. Queries inform reasoning, not action choice
or execution authority; hypotheses and exploration remain caller-owned.

CLI: gambit-smp trajectory clues --help (also python -m gambit_smp).
"""

from importlib import import_module

__all__ = ["engine_api", "repository_clues"]


def __getattr__(name):
    # Preserve CLI --root selection before importing checkout-bound modules.
    modules = {"engine_api": "ascent_program", "repository_clues": "trajectory_exploration"}
    if name not in modules:
        raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
    value = getattr(import_module(f"{__name__}.{modules[name]}"), name)
    globals()[name] = value
    return value


def __dir__():
    return sorted(set(globals()) | set(__all__))

# A framework import must not create an alternative top-level organization.
from pathlib import Path as _Path
from gambit_smp.storage_policy import install as _install_storage_policy
_install_storage_policy(_Path(__file__).resolve().parents[2])
import os as _os
for _root_name in ('GAMBIT_SMP_TASK_ROOT','GAMBIT_SMP_ROOT'):
    if _os.environ.get(_root_name):
        _install_storage_policy(_Path(_os.environ[_root_name]))


# New supervised children validate custody before any adapter or worker body.
# Existing in-flight receipts are observed in place, never restarted or rewritten.
if all(_os.environ.get(key) for key in ('GAMBIT_SMP_TASK_ROOT','GAMBIT_SMP_TASK_ID','GAMBIT_SMP_TASK_RUN')):
    import json as _json
    from gambit_smp.workspace import paths as _task_paths, bounded as _bounded, identifier as _identifier, inherited_lease as _inherited_lease, context_run as _context_run, context_owner as _context_owner
    _control=_Path(_os.environ['GAMBIT_SMP_TASK_ROOT']).resolve(strict=True)
    _task=_identifier(_os.environ['GAMBIT_SMP_TASK_ID']);_run=_identifier(_os.environ['GAMBIT_SMP_TASK_RUN'])
    _run_record=_json.loads(_context_run(_control,_task,_run).read_text())
    if _run_record.get('custodyProtocol',0)>=3:
        if _os.environ.get('GAMBIT_SMP_TASK_PROCESS') and _json.loads(_task_paths(_control,_task)[0].read_text())['state']!='open':
            raise ValueError('process child requires an open parent work item')
        _task_record=_json.loads(_context_owner(_control,_task).read_text())
        if (_task_record['state']!='open' or _task_record.get('run')!=_run or _run_record['state']!='running' or
                _inherited_lease(_control,_task) is None):
            raise ValueError('framework child requires current real task custody')
        from gambit_smp.storage_policy import activate as _activate_storage_policy
        _activate_storage_policy(_control,_task)
