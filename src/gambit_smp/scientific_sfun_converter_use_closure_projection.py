"""Restricted typed IR projection, not a native C23 equivalence proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'sfun_converter_use_closure', 'namespace': 'ConverterUseAst', 'fields': {'phase': 'int', 'privateCopy': 'int', 'payload': 'int', 'inputRef': 'int', 'active': 'int', 'result': 'int', 'gate': 'int', 'valid': 'int', 'receipt': 'int', 'marker': 'int', 'effects': 'int', 'settled': 'int', 'critical': 'int', 'captured': 'int', 'dtor': 'int', 'code': 'int', 'roots': 'int', 'gc': 'int', 'exitAck': 'int', 'reply': 'int'}, 'actions': ['reservePrivate', 'beginWrap', 'wrapSuccess', 'wrapFailureReturned', 'wrapFailureUnknown', 'auditPrivateDisposed', 'bodyBadResult', 'bodyGoodResult', 'captureArgument', 'dropInputReference', 'handlerCall', 'handlerBadResult', 'handlerGoodResult', 'finishResult', 'signFinalUse', 'escapeOwner', 'drainInputFromGuard', 'ackExitedOwner', 'signEscapedUse', 'beginMarkerRelease', 'markerDrop', 'commitMarkerRelease', 'loseReply', 'queryReply', 'dropCaptured', 'beginDestructor', 'destructorReturned', 'destructorUnknown', 'beginGc', 'finishGc', 'retireRoots', 'retireCode']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_sfun_converter_use_closure_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        ast, receipt = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        receipt.pop('c11Refinement', None)
        return (ast, receipt)
