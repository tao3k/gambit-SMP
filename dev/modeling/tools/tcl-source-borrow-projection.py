"""Restricted typed AST projection; no native C23 or slot-value proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'tcl_source_borrow', 'namespace': 'TclBorrowAst', 'fields': {'generation': 'int', 'tokenGeneration': 'int', 'storage': 'int', 'closed': 'int', 'scope': 'int', 'borrower': 'int', 'borrowCreated': 'int', 'borrowReleased': 'int', 'selected': 'int', 'current': 'int', 'oldRoot': 'int', 'newRoot': 'int', 'dest': 'int', 'destVersion': 'int', 'pending': 'int', 'acknowledged': 'int', 'replyLost': 'int', 'writer': 'int', 'gcClosed': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'epoch': 'int', 'viewOld': 'int', 'viewNew': 'int', 'viewDest': 'int', 'prepared': 'int', 'refused': 'int', 'otherOld': 'int', 'otherNew': 'int'}, 'actions': ['selectDispatch', 'acquireBorrow', 'refuseLateDispatch', 'refuseGcClosed', 'otherBorrowOld', 'otherBorrowNew', 'releaseOtherOld', 'releaseOtherNew', 'acquireWriter', 'prepareSetter', 'commitSetter', 'abortSetter', 'releaseWriter', 'revoke', 'publishDestination', 'loseReply', 'acknowledgeTransfer', 'dropOldVersion', 'dropRevokedRoots', 'leaveDispatch', 'freeSource', 'dropDestination', 'reuseStorage', 'selectNewToken', 'closeGcGate', 'freezeRoots', 'beginScan', 'endScan', 'resumeRoots']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
