"""Restricted typed-IR projection; not a C23 compiler proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'guard_thread_admission', 'namespace': 'GuardAdmissionAst', 'fields': {'phase': 'int', 'mask': 'int', 'guard': 'int', 'sourceRoot': 'int', 'targetRoot': 'int', 'ack': 'int', 'tls': 'int', 'supervisor': 'int', 'childGuard': 'int', 'childRoot': 'int', 'childSource': 'int', 'childAck': 'int', 'application': 'int', 'closed': 'int'}, 'actions': ['arrive', 'cancelBeforeRegistration', 'maskConfirmed', 'maskOutcomeUnknown', 'reserveGuard', 'capacityReject', 'publishRegistry', 'publicationUnknown', 'queryCommitted', 'queryAbsent', 'roundAcknowledged', 'releaseSourceRoot', 'bindContext', 'bindingUnknown', 'enterApplication', 'beginNested', 'nestedPublish', 'nestedRoundAcknowledged', 'nestedPublicationUnknown', 'queryNestedCommitted', 'returnNested', 'nestedExitUnknown', 'armOuterExit', 'armAfterNested', 'restoreReturns', 'restoreDoesNotReturn', 'restoreUnknown', 'closeAdmission', 'tlsDetachKnown', 'scanGraceKnown', 'retireActiveGuard']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
