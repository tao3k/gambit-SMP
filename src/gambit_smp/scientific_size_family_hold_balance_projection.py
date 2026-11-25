"""Restricted QNT typed AST projection; not native C23 equivalence."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'size_family_hold_balance', 'namespace': 'SizeHoldAst', 'fields': {'phase': 'int', 'direction': 'int', 'x': 'int', 'created': 'int', 'hold': 'int', 'effects': 'int', 'root': 'int', 'captured': 'int', 'gc': 'int', 'reply': 'int', 'settled': 'int', 'critical': 'int', 'exited': 'int'}, 'actions': ['selectSizeMax', 'selectSignedMin', 'selectSignedMax', 'selectAboveFix', 'selectAtFix', 'selectMinFix', 'selectBelowFix', 'convertBoxed', 'convertImmediate', 'conversionFailure', 'publishRoot', 'captureArgument', 'finishNative', 'enterDrop', 'physicalDrop', 'commitDrop', 'loseReply', 'recoverReply', 'dropCapture', 'dropRoot', 'beginGc', 'finishGc']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_size_family_hold_balance_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
