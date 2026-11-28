"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'guard_thread_admission', 'namespace': 'GuardAdmissionAst', 'fields': {'phase': 'int', 'mask': 'int', 'guard': 'int', 'sourceRoot': 'int', 'targetRoot': 'int', 'ack': 'int', 'tls': 'int', 'supervisor': 'int', 'childGuard': 'int', 'childRoot': 'int', 'childSource': 'int', 'childAck': 'int', 'application': 'int', 'closed': 'int'}, 'actions': ['arrive', 'cancelBeforeRegistration', 'maskConfirmed', 'maskOutcomeUnknown', 'reserveGuard', 'capacityReject', 'publishRegistry', 'publicationUnknown', 'queryCommitted', 'queryAbsent', 'roundAcknowledged', 'releaseSourceRoot', 'bindContext', 'bindingUnknown', 'enterApplication', 'beginNested', 'nestedPublish', 'nestedRoundAcknowledged', 'nestedPublicationUnknown', 'queryNestedCommitted', 'returnNested', 'nestedExitUnknown', 'armOuterExit', 'armAfterNested', 'restoreReturns', 'restoreDoesNotReturn', 'restoreUnknown', 'closeAdmission', 'tlsDetachKnown', 'scanGraceKnown', 'retireActiveGuard']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_guard_thread_admission_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
