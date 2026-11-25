"""Joint-entry NativeScope typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'native_entry_admission', 'namespace': 'NativeEntryAst', 'fields': {'phase': 'int', 'host': 'int', 'sourcePin': 'int', 'sourceRoot': 'int', 'carrierRoot': 'int', 'registry': 'int', 'guard': 'int', 'inflight': 'int', 'nested': 'int', 'unknown': 'int', 'outcome': 'int', 'epoch': 'int', 'sourceEpoch': 'int', 'carrierEpoch': 'int', 'frozen': 'int', 'scanned': 'int', 'entryOpen': 'int', 'writeOpen': 'int', 'written': 'int', 'marker': 'int', 'receipt': 'int', 'registrationUnknown': 'int', 'scanAdmission': 'int', 'grace': 'int', 'rejected': 'int', 'holder': 'int'}, 'actions': ['pinSource', 'reserveCarrier', 'qualifyHost', 'publishCarrier', 'loseRegistrationAck', 'confirmSameRegistration', 'jointIssue', 'writeEntryState', 'allocateMarker', 'certifyTransfer', 'releaseSource', 'closeIngress', 'exhaustCarrier', 'rejectClosed', 'freezeWriters', 'scanSource', 'scanBoth', 'scanCarrier', 'thawWriters', 'enterNested', 'leaveNested', 'recordOutcome', 'loseCompletion', 'landNested', 'settleKnown', 'recoverRecorded', 'closeScanAdmission', 'confirmGrace', 'retireCarrier']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_native_entry_admission_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
