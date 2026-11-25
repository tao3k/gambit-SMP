"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'allocation_capture_guard', 'namespace': 'AllocationCaptureAst', 'fields': {'phase': 'int', 'captured': 'int', 'guard': 'int', 'disabled': 'int', 'owner': 'int', 'root': 'int', 'child': 'int', 'calls': 'int'}, 'actions': ['issue', 'metadataReject', 'maskReject', 'cancelBeforeMask', 'maskConfirmed', 'invoke', 'nativeReturn', 'capture', 'armExitOwner', 'restoreReturns', 'restoreAbandons', 'restoreUnknown', 'nativeNull', 'finishNull', 'restoreNullAbandons', 'startLogger', 'skipLogger', 'loggerReturns', 'loggerError', 'nestedEnter', 'nestedKnownExit', 'nestedUnknownExit', 'capturedThrow', 'handoff', 'unrecordedEscape', 'inflightEscape']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_allocation_capture_guard_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
