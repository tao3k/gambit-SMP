"""Restricted typed AST projection; no native C23 or slot-value proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'dispatch_joint_admission', 'namespace': 'DispatchJointAst', 'fields': {'nativeOpen': 'int', 'storage': 'int', 'control': 'int', 'root': 'int', 'scope': 'int', 'others': 'int', 'selected': 'int', 'phase': 'int', 'pending': 'int', 'committed': 'int', 'known': 'int', 'refused': 'int', 'unknown': 'int', 'borrow': 'int', 'created': 'int', 'released': 'int', 'lease': 'int', 'rootAuth': 'int', 'nativeAuth': 'int', 'finished': 'int', 'delivered': 'int', 'dataReads': 'int', 'gcOpen': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'gcEpoch': 'int', 'viewRoot': 'int'}, 'actions': ['enterNative', 'enterOther', 'leaveOther', 'selectHandle', 'deleteCommand', 'reserveRoot', 'rejectBeforeReserve', 'commitJoint', 'rejectReservedDelete', 'abortPreparation', 'loseReply', 'resolveReservedAbort', 'ackCommit', 'readSelected', 'finishUse', 'retireBorrow', 'deliverOutcome', 'leaveScope', 'leaveEmptyScope', 'removeRoot', 'freeStorage', 'freeControl', 'closeGc', 'freezeRoots', 'beginScan', 'endScan', 'resumeGc']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
