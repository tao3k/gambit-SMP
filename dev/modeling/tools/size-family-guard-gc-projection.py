"""Restricted typed AST projection; trusted emitter, not native C23 equivalence."""
import importlib.util
from pathlib import Path
SPEC={'module': 'size_family_guard_gc', 'namespace': 'SizeGuardAst', 'fields': {'phase': 'int', 'direction': 'int', 'created': 'int', 'hold': 'int', 'effects': 'int', 'carrier': 'int', 'lang': 'int', 'captured': 'int', 'guard': 'int', 'lease': 'int', 'closed': 'int', 'frozen': 'int', 'gc': 'int', 'scanners': 'int', 'scanned': 'int', 'exited': 'int', 'outcome': 'int', 'receiptId': 'int', 'reply': 'int', 'attempt': 'int', 'epoch': 'int', 'leaseEpoch': 'int', 'viewGuard': 'int', 'viewCarrier': 'int', 'viewAttempt': 'int', 'viewLang': 'int'}, 'actions': ['reserveSfun', 'reserveCfun', 'beginConversion', 'completeBoxed', 'completeImmediate', 'abortBeforeConversion', 'acquireRootUpdate', 'publishLanguage', 'releaseRootUpdate', 'captureArgument', 'finishNative', 'escapeNative', 'claimDrop', 'fuseCfunHandoff', 'physicalDrop', 'recordDrop', 'releaseDrop', 'loseReply', 'queryReceipt', 'dropCapture', 'clearLanguage', 'retireGuard', 'reissueSfun', 'reissueCfun', 'closeGate', 'freezeOwner', 'beginScan', 'endScan', 'resumeOwner']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
