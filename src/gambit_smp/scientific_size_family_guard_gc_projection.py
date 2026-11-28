"""Restricted typed AST projection; trusted emitter, not native C23 equivalence."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'size_family_guard_gc', 'namespace': 'SizeGuardAst', 'fields': {'phase': 'int', 'direction': 'int', 'created': 'int', 'hold': 'int', 'effects': 'int', 'carrier': 'int', 'lang': 'int', 'captured': 'int', 'guard': 'int', 'lease': 'int', 'closed': 'int', 'frozen': 'int', 'gc': 'int', 'scanners': 'int', 'scanned': 'int', 'exited': 'int', 'outcome': 'int', 'receiptId': 'int', 'reply': 'int', 'attempt': 'int', 'epoch': 'int', 'leaseEpoch': 'int', 'viewGuard': 'int', 'viewCarrier': 'int', 'viewAttempt': 'int', 'viewLang': 'int'}, 'actions': ['reserveSfun', 'reserveCfun', 'beginConversion', 'completeBoxed', 'completeImmediate', 'abortBeforeConversion', 'acquireRootUpdate', 'publishLanguage', 'releaseRootUpdate', 'captureArgument', 'finishNative', 'escapeNative', 'claimDrop', 'fuseCfunHandoff', 'physicalDrop', 'recordDrop', 'releaseDrop', 'loseReply', 'queryReceipt', 'dropCapture', 'clearLanguage', 'retireGuard', 'reissueSfun', 'reissueCfun', 'closeGate', 'freezeOwner', 'beginScan', 'endScan', 'resumeOwner']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_size_family_guard_gc_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
