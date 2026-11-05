"""Restricted QNT typed AST projection; not native C23 equivalence."""
import importlib.util
from pathlib import Path
SPEC={'module': 'size_family_hold_balance', 'namespace': 'SizeHoldAst', 'fields': {'phase': 'int', 'direction': 'int', 'x': 'int', 'created': 'int', 'hold': 'int', 'effects': 'int', 'root': 'int', 'captured': 'int', 'gc': 'int', 'reply': 'int', 'settled': 'int', 'critical': 'int', 'exited': 'int'}, 'actions': ['selectSizeMax', 'selectSignedMin', 'selectSignedMax', 'selectAboveFix', 'selectAtFix', 'selectMinFix', 'selectBelowFix', 'convertBoxed', 'convertImmediate', 'conversionFailure', 'publishRoot', 'captureArgument', 'finishNative', 'enterDrop', 'physicalDrop', 'commitDrop', 'loseReply', 'recoverReply', 'dropCapture', 'dropRoot', 'beginGc', 'finishGc']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
