"""Restricted typed AST projection; no native C23 or slot-value proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'tcl_checked_refusal', 'namespace': 'TclRefusalAst', 'fields': {'scope': 'int', 'vmOpen': 'int', 'outerSticky': 'int', 'childSticky': 'int', 'childMerged': 'int', 'eventSeen': 'int', 'tclCode': 'int', 'diagnostic': 'int', 'done': 'int', 'delivered': 'int', 'origin': 'int', 'translated': 'int'}, 'actions': ['beginEval', 'beginNested', 'recordOuterRefusal', 'recordChildRefusal', 'publishOuterDiagnostic', 'publishChildDiagnostic', 'catchOrResetResult', 'ordinaryTclError', 'mergeChildRefusal', 'popNested', 'finishEval', 'deliverRefusal', 'deliverOrdinaryNativeError', 'translateOrdinaryError', 'deliverSuccess', 'closeVm', 'resumeVm']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
