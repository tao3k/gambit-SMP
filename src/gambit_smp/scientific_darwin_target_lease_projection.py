"""Target-lease NativeScope typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'darwin_target_lease', 'namespace': 'TargetLeaseAst', 'fields': {'published': 'int', 'gate': 'int', 'current': 'int', 'oldLive': 'int', 'certificate': 'int', 'mayAbandon': 'int', 'outer': 'int', 'nested': 'int', 'maintenance': 'int', 'origin': 'int', 'allocFamily': 'int', 'freeFamily': 'int', 'operation': 'int', 'pointer': 'int', 'recorded': 'int', 'unknown': 'int', 'custodian': 'int', 'freeApplied': 'int', 'freeReceipt': 'int', 'retired': 'int'}, 'actions': ['publishPlain', 'publishAdmittedHooks', 'acquireOuter', 'closeOrdinary', 'publishReplacement', 'beginMalloc', 'obtainPointer', 'recordSuccess', 'recordNull', 'enterNested', 'leaveNested', 'loseBeforeCapture', 'loseRecordedAck', 'recoverRecorded', 'releaseOuter', 'beginOriginFree', 'applyFree', 'recordFreeBackend', 'loseFreeReturn', 'settleFree', 'reconcileFree', 'releaseMaintenance', 'retireOldBundle']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_darwin_target_lease_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
