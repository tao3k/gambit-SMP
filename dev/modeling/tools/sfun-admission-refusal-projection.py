"""Typed AST projection; source pin, C23 and native exception refinements stay open."""
import importlib.util
from pathlib import Path
SPEC={'module': 'sfun_admission_refusal', 'namespace': 'SfunAdmissionAst', 'fields': {'phase': 'int', 'managed': 'int', 'domainOpen': 'int', 'pool': 'int', 'sourcePin': 'int', 'sourceDrops': 'int', 'root': 'int', 'guard': 'int', 'guardCreates': 'int', 'guardDrops': 'int', 'marker': 'int', 'markerCreates': 'int', 'markerDrops': 'int', 'allocs': 'int', 'bodyEntries': 'int', 'handlerEntries': 'int', 'legacyRetries': 'int', 'origin': 'int', 'code': 'int', 'refused': 'int', 'preRefused': 'int', 'refusalStamp': 'int', 'final': 'int', 'landing': 'int'}, 'actions': ['refuseBeforeEntry', 'exhaustPool', 'refuseNoRecord', 'reserveGuard', 'ackHandoff', 'cancelBeforeAck', 'allocateMarker', 'markerFailure', 'beginBody', 'conversionFailure', 'opaqueConversionFailure', 'finishSuccess', 'callRefused', 'handlerRefused', 'recoverGood', 'recoverBad', 'outerThrow', 'releaseMarker', 'closeGuard', 'dropRefusedSource', 'deliver', 'closeDomain', 'resumeDomain', 'legacyMarkerSuccess', 'legacyRejectCall', 'legacyErrorRetry', 'legacyMarkerFailure']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
