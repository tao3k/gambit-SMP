"""Restricted typed AST projection; no native C23 or slot-value proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'future_frame_commit', 'namespace': 'FrameCommitAst', 'fields': {'decision': 'int', 'claims': 'int', 'done': 'int', 'resultRoot': 'int', 'sourceRoot': 'int', 'destRoot': 'int', 'childRoot': 'int', 'copyReady': 'int', 'copyRev': 'int', 'viewRev': 'int', 'viewGen': 'int', 'viewLease': 'int', 'patchReady': 'int', 'patchRev': 'int', 'patchGen': 'int', 'patchLease': 'int', 'gate': 'int', 'admitted': 'int', 'generation': 'int', 'grantGen': 'int', 'lease': 'int', 'revision': 'int', 'sourceHeap': 'int', 'localGrants': 'int', 'remoteGrants': 'int', 'copyOps': 'int', 'validations': 'int', 'probes': 'int'}, 'actions': ['reserveSplit', 'childDone', 'closeLocal', 'allocateRootedCopy', 'enterRuntime', 'resolveCanonical', 'initializeCopy', 'validateCopy', 'prepareReturn', 'commitSplit', 'abortSplit', 'grantLocal', 'grantRemote', 'leaveRuntime', 'enterGc', 'forwardNoCopy', 'forwardWithCopy', 'leaveGc', 'closeDomain', 'resetDomain', 'failedProbe']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"]);r.pop("c11Refinement",None);r["c23Refinement"]=False
 return a,r
