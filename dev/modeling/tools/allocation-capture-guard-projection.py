"""Restricted typed-IR projection; not a C23 compiler proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'allocation_capture_guard', 'namespace': 'AllocationCaptureAst', 'fields': {'phase': 'int', 'captured': 'int', 'guard': 'int', 'disabled': 'int', 'owner': 'int', 'root': 'int', 'child': 'int', 'calls': 'int'}, 'actions': ['issue', 'metadataReject', 'maskReject', 'cancelBeforeMask', 'maskConfirmed', 'invoke', 'nativeReturn', 'capture', 'armExitOwner', 'restoreReturns', 'restoreAbandons', 'restoreUnknown', 'nativeNull', 'finishNull', 'restoreNullAbandons', 'startLogger', 'skipLogger', 'loggerReturns', 'loggerError', 'nestedEnter', 'nestedKnownExit', 'nestedUnknownExit', 'capturedThrow', 'handoff', 'unrecordedEscape', 'inflightEscape']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
