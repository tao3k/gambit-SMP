"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'putobjs_custody', 'namespace': 'PutObjsCustodyAst', 'fields': {'phase': 'int', 'mode': 'int', 'empty': 'int', 'walk': 'int', 'last': 'int', 'localCount': 'int', 'uncredited': 'int', 'exposed': 'int', 'delta': 'int', 'split': 'int', 'lock': 'int', 'sharedTail': 'int', 'lastFixed': 'int', 'receipt': 'int', 'escaped': 'int', 'held': 'int', 'gate': 'int', 'readers': 'int', 'generation': 'int', 'stamp': 'int', 'accepted': 'int', 'finalized': 'int', 'batchTaken': 'int'}, 'actions': ['takePublishedBatch', 'admitOwner', 'chooseEmpty', 'chooseNonempty', 'trimLocal', 'loadLocalHead', 'assignLast', 'advanceCursor', 'loopAgain', 'cutLocal', 'lockKnown', 'lockUnknown', 'linkOldTail', 'publishSharedHead', 'updateEmptySharedTail', 'keepSharedTail', 'addSharedCount', 'unlockKnown', 'unlockUnknown', 'fixLocalLast', 'publishReceipt', 'escape', 'loseReceiptAck', 'acceptReceipt', 'closeAdmission', 'readersDetached', 'attestFinalization', 'reuseAddress']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
