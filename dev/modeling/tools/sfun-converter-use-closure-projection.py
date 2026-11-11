"""Restricted typed IR projection, not a native C23 equivalence proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'sfun_converter_use_closure', 'namespace': 'ConverterUseAst', 'fields': {'phase': 'int', 'privateCopy': 'int', 'payload': 'int', 'inputRef': 'int', 'active': 'int', 'result': 'int', 'gate': 'int', 'valid': 'int', 'receipt': 'int', 'marker': 'int', 'effects': 'int', 'settled': 'int', 'critical': 'int', 'captured': 'int', 'dtor': 'int', 'code': 'int', 'roots': 'int', 'gc': 'int', 'exitAck': 'int', 'reply': 'int'}, 'actions': ['reservePrivate', 'beginWrap', 'wrapSuccess', 'wrapFailureReturned', 'wrapFailureUnknown', 'auditPrivateDisposed', 'bodyBadResult', 'bodyGoodResult', 'captureArgument', 'dropInputReference', 'handlerCall', 'handlerBadResult', 'handlerGoodResult', 'finishResult', 'signFinalUse', 'escapeOwner', 'drainInputFromGuard', 'ackExitedOwner', 'signEscapedUse', 'beginMarkerRelease', 'markerDrop', 'commitMarkerRelease', 'loseReply', 'queryReply', 'dropCaptured', 'beginDestructor', 'destructorReturned', 'destructorUnknown', 'beginGc', 'finishGc', 'retireRoots', 'retireCode']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 ast,receipt=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
 receipt.pop("c11Refinement",None)
 return ast,receipt
