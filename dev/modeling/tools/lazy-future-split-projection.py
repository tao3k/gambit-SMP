"""Restricted typed AST projection; no native C23 or slot-value proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'lazy_future_split', 'namespace': 'LazySplitAst', 'fields': {'phase': 'int', 'eligible': 'int', 'claims': 'int', 'probes': 'int', 'childRuns': 'int', 'childDone': 'int', 'sourceRoot': 'int', 'copyRoot': 'int', 'ready': 'int', 'queueRoot': 'int', 'restoreRoot': 'int', 'contextRoot': 'int', 'resultRoot': 'int', 'placeholder': 'int', 'materialized': 'int', 'split': 'int', 'parentOwner': 'int', 'prefixRuns': 'int', 'parentRuns': 'int', 'captured': 'int', 'captureRoot': 'int', 'exited': 'int', 'descriptor': 'int', 'gcOpen': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'epoch': 'int', 'vSource': 'int', 'vCopy': 'int', 'vQueue': 'int', 'vRestore': 'int', 'vContext': 'int', 'vResult': 'int', 'vCapture': 'int', 'resultPublished': 'int'}, 'actions': ['denyParallelProfile', 'claimSplit', 'failedProbe', 'allocateCopy', 'initializeCopy', 'publishReady', 'commitSplit', 'abortPrivate', 'localChildDone', 'localAfterAbortDone', 'childDoneInSplit', 'dequeueParent', 'restoreParent', 'publishResult', 'runParentPrefix', 'consumeSplitResult', 'runLocalParent', 'captureAfterValue', 'restoreAfterValue', 'dropCaptured', 'exitParent', 'retireTaskRoots', 'retireDescriptor', 'closeGc', 'freezeRoots', 'beginScan', 'endScan', 'resumeGc']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
