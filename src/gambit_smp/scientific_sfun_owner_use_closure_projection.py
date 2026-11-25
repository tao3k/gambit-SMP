"""Restricted typed QNT projection; trusted parser/emitter, no C23 implementation proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'sfun_owner_use_closure', 'namespace': 'SfunOwnerAst', 'fields': {'stage': 'int', 'owner': 'int', 'epoch': 'int', 'terminal': 'int', 'active': 'int', 'gate': 'int', 'valid': 'int', 'ref': 'int', 'effects': 'int', 'done': 'int', 'closeOwner': 'int', 'closeEpoch': 'int', 'completed': 'int', 'origin': 'int', 'captured': 'int', 'shots': 'int', 'borrowers': 'int', 'escrow': 'int', 'exitAck': 'int', 'root': 'int', 'code': 'int', 'gc': 'int', 'critical': 'int', 'reply': 'int', 'oldOwner': 'int', 'oldEpoch': 'int'}, 'actions': ['bodyCall', 'inputConversionFails', 'captureCurrent', 'callReturns', 'resultConversionFails', 'retryHandler', 'resultConversionSucceeds', 'closeAdmission', 'signLocalClosure', 'enterNested', 'leaveNested', 'outwardUnknown', 'drainDescendant', 'ackNativeExit', 'signEscapedClosure', 'beginRelease', 'physicalDrop', 'commitDrop', 'loseClosureReply', 'queryClosure', 'observeOldInvocation', 'observeOldOwner', 'resumeOldReturn', 'resumeExpiredPrefix', 'rejectExpiredReturn', 'dropCaptured', 'beginGc', 'endGc', 'retireRoots', 'retireCode', 'newOwner']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_sfun_owner_use_closure_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        ast, receipt = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        receipt.pop('c11Refinement', None)
        return (ast, receipt)
