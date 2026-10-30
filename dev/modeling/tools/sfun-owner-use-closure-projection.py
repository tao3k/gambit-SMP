"""Restricted typed QNT projection; trusted parser/emitter, no C23 implementation proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'sfun_owner_use_closure', 'namespace': 'SfunOwnerAst', 'fields': {'stage': 'int', 'owner': 'int', 'epoch': 'int', 'terminal': 'int', 'active': 'int', 'gate': 'int', 'valid': 'int', 'ref': 'int', 'effects': 'int', 'done': 'int', 'closeOwner': 'int', 'closeEpoch': 'int', 'completed': 'int', 'origin': 'int', 'captured': 'int', 'shots': 'int', 'borrowers': 'int', 'escrow': 'int', 'exitAck': 'int', 'root': 'int', 'code': 'int', 'gc': 'int', 'critical': 'int', 'reply': 'int', 'oldOwner': 'int', 'oldEpoch': 'int'}, 'actions': ['bodyCall', 'inputConversionFails', 'captureCurrent', 'callReturns', 'resultConversionFails', 'retryHandler', 'resultConversionSucceeds', 'closeAdmission', 'signLocalClosure', 'enterNested', 'leaveNested', 'outwardUnknown', 'drainDescendant', 'ackNativeExit', 'signEscapedClosure', 'beginRelease', 'physicalDrop', 'commitDrop', 'loseClosureReply', 'queryClosure', 'observeOldInvocation', 'observeOldOwner', 'resumeOldReturn', 'resumeExpiredPrefix', 'rejectExpiredReturn', 'dropCaptured', 'beginGc', 'endGc', 'retireRoots', 'retireCode', 'newOwner']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 ast,receipt=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
 receipt.pop("c11Refinement",None)
 return ast,receipt
