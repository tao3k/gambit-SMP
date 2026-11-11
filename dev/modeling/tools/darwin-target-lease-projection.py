"""Target-lease NativeScope typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'darwin_target_lease', 'namespace': 'TargetLeaseAst', 'fields': {'published': 'int', 'gate': 'int', 'current': 'int', 'oldLive': 'int', 'certificate': 'int', 'mayAbandon': 'int', 'outer': 'int', 'nested': 'int', 'maintenance': 'int', 'origin': 'int', 'allocFamily': 'int', 'freeFamily': 'int', 'operation': 'int', 'pointer': 'int', 'recorded': 'int', 'unknown': 'int', 'custodian': 'int', 'freeApplied': 'int', 'freeReceipt': 'int', 'retired': 'int'}, 'actions': ['publishPlain', 'publishAdmittedHooks', 'acquireOuter', 'closeOrdinary', 'publishReplacement', 'beginMalloc', 'obtainPointer', 'recordSuccess', 'recordNull', 'enterNested', 'leaveNested', 'loseBeforeCapture', 'loseRecordedAck', 'recoverRecorded', 'releaseOuter', 'beginOriginFree', 'applyFree', 'recordFreeBackend', 'loseFreeReturn', 'settleFree', 'reconcileFree', 'releaseMaintenance', 'retireOldBundle']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
