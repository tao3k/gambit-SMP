"""Prefix-permission NativeScope typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'native_prefix_permission', 'namespace': 'NativePrefixAst', 'fields': {'phase': 'int', 'profile': 'int', 'identity': 'int', 'bindingEpoch': 'int', 'sealEpoch': 'int', 'fast': 'int', 'durable': 'int', 'sourceRoot': 'int', 'carrierRoot': 'int', 'intent': 'int', 'allocation': 'int', 'recorded': 'int', 'hook': 'int', 'unknown': 'int', 'custodian': 'int', 'epoch': 'int', 'rootEpoch': 'int', 'localEpoch': 'int', 'gate': 'int'}, 'actions': ['selectPlain', 'selectCollecting', 'selectReentrant', 'selectAbandoning', 'selectOpaque', 'selectWrongSelf', 'selectDebugIO', 'replaceBeforeGrant', 'grantFast', 'grantDurable', 'denyProfile', 'closeAdmission', 'beginAllocation', 'obtainNativeMemory', 'enterHook', 'returnHook', 'gcRound', 'reloadRoot', 'captureOutcome', 'publishInputs', 'abandonBeforeRecord', 'loseRecordedResponse', 'recoverPrivateRecord', 'recoverPublishedRecord', 'releaseSource', 'handoffBank', 'rollbackPlain']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_native_prefix_permission_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
