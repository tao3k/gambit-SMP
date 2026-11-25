"""Restricted typed-IR extraction; shared emitter is pinned by the study input receipt."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'continuation_restore_plan', 'namespace': 'ContinuationRestoreAst', 'fields': {'r0': 'int', 'r1': 'int', 'mode0': 'int', 'mode1': 'int', 'cap0': 'int', 'cap1': 'int', 'outcome': 'int', 'denied': 'int', 'frozen': 'bool', 'retained': 'bool'}, 'actions': ['freezeSmall', 'freezeLarge', 'freezeOversize', 'share0', 'share1', 'dedicate0', 'dedicate1', 'reject0', 'reject1', 'sealAccept', 'sealReject', 'allocationFailure', 'denyMutation', 'retainUnknown']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_continuation_restore_admission_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
