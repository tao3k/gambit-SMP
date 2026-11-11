"""Restricted typed-IR projection; not a C23 compiler proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'native_return_domains', 'namespace': 'NativeReturnAst', 'fields': {'phase': 'int', 'threadLive': 'int', 'stackLive': 'int', 'returnRight': 'int', 'guard': 'int', 'root': 'int', 'shot': 'int', 'ticket': 'int', 'retained': 'int', 'closed': 'int', 'grace': 'int'}, 'actions': ['enterGuard', 'captureScheme', 'leaveActivation', 'resumeFirst', 'settleFirst', 'physicalReturn', 'resumeSecond', 'rejectStaleReturn', 'settleSecond', 'closeCapture', 'scanGrace', 'retireRoots', 'detachThread', 'unknownExit', 'rejectWrongOwner', 'settleRejectedOwner', 'earlyPhysicalReturn', 'resumeAfterReturn', 'settleAfterReturn', 'resumeAgainLive', 'settleAgainLive', 'returnAfterTwo']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
