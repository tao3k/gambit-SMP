"""Restricted scalar projection; shared projector remains trusted."""
import importlib.util
from pathlib import Path
SPEC={'module': 'rc_storage_lifecycle', 'namespace': 'RcStorageAst', 'fields': {'phase': 'int', 'generation': 'int', 'operation': 'int', 'bytes': 'int', 'checked': 'int', 'owned': 'int', 'index': 'int', 'root': 'int', 'sourceHold': 'int', 'known': 'int', 'owner': 'int', 'contextClosing': 'int', 'contextGone': 'int', 'base': 'int', 'extra': 'int', 'extraSeen': 'int', 'borrow': 'int', 'scan': 'int', 'native': 'int', 'grace': 'int', 'effects': 'int', 'savedGeneration': 'int', 'keyGeneration': 'int', 'committed': 'int', 'oldResult': 'int', 'oldKnown': 'int', 'frees': 'int', 'rejections': 'int'}, 'actions': ['begin', 'beginZero', 'beginTooLarge', 'ticketFailure', 'checkSize', 'rejectSize', 'allocNull', 'allocSuccess', 'saveKey', 'reserveIndex', 'prepareRoot', 'publish', 'queryCommit', 'releaseSource', 'retainExtra', 'releaseExtra', 'releaseBase', 'borrow', 'returnBorrow', 'nativePin', 'nativeReturn', 'scan', 'finishScan', 'closeEntry', 'requestCleanup', 'handoffVM', 'exitContext', 'settleEffects', 'abortPrivate', 'unpublish', 'scanGrace', 'startFree', 'finishFree', 'loseFreeOutcome', 'reuseAddress', 'queryOld', 'rejectOldRelease']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
