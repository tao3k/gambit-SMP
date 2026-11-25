"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'native_return_domains', 'namespace': 'NativeReturnAst', 'fields': {'phase': 'int', 'threadLive': 'int', 'stackLive': 'int', 'returnRight': 'int', 'guard': 'int', 'root': 'int', 'shot': 'int', 'ticket': 'int', 'retained': 'int', 'closed': 'int', 'grace': 'int'}, 'actions': ['enterGuard', 'captureScheme', 'leaveActivation', 'resumeFirst', 'settleFirst', 'physicalReturn', 'resumeSecond', 'rejectStaleReturn', 'settleSecond', 'closeCapture', 'scanGrace', 'retireRoots', 'detachThread', 'unknownExit', 'rejectWrongOwner', 'settleRejectedOwner', 'earlyPhysicalReturn', 'resumeAfterReturn', 'settleAfterReturn', 'resumeAgainLive', 'settleAgainLive', 'returnAfterTwo']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_native_return_domains_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
