"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'frame_seal_start_retire', 'namespace': 'SealStartAst', 'fields': {'generation': 'int', 'saved': 'int', 'ticket': 'int', 'phase': 'int', 'nativePins': 'int', 'frames': 'int', 'roots': 'int', 'maintenance': 'int', 'observers': 'int', 'denied': 'int', 'writer': 'bool', 'guard': 'bool', 'suspended': 'bool', 'sealed': 'bool', 'opaqueExport': 'bool', 'admit': 'bool', 'copyPin': 'bool', 'revocationWins': 'bool', 'unknown': 'bool', 'reclaimed': 'bool'}, 'actions': ['capture', 'resumeLive', 'resumeDenied', 'closeWriters', 'opaqueEscape', 'seal', 'abortCandidate', 'issue', 'observe', 'revoke', 'casStart', 'casFailed', 'revokeTooLate', 'finishCopy', 'nativeBorrow', 'nativeReturn', 'nativeUnknown', 'closeAdmission', 'dropFrame', 'dropRoot', 'beginMaintenance', 'endMaintenance', 'reclaim', 'denyLateBorrow']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_frame_seal_start_retire_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
