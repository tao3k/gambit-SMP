"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'exit_domain_drain', 'namespace': 'ExitDomainDrainAst', 'fields': {'phase': 'int', 'a': 'int', 'b': 'int', 'ack': 'int', 'parent': 'int', 'samePair': 'int', 'tailLive': 'int', 'tailDone': 'int', 'admission': 'int', 'keyGate': 'int', 'lookupPin': 'int', 'data': 'int', 'slot': 'int', 'cache': 'int', 'joined': 'int', 'miss': 'int', 'deps': 'int', 'cacheDone': 'int', 'allOwners': 'int', 'key': 'int'}, 'actions': ['seedRegistrationA', 'chooseDuplicatePair', 'reserveExternalB', 'beginDrain', 'reserveChildB', 'reserveTailB', 'publishBKnown', 'publishBUnknown', 'publicationAbsentUnknown', 'reconcileAcceptedB', 'reconcileAbsentAndRolledBackB', 'popA', 'popB', 'returnA', 'returnB', 'callbackUnknownA', 'freeNodeAKnown', 'freeNodeBKnown', 'freeNodeAUnknown', 'freeNodeBUnknown', 'cancelNewestDuplicateB', 'cancelQueuedA', 'reentrantFinalizeJoin', 'beginSubsystemTail', 'finishSubsystemTail', 'closeProducers', 'attestNoTsdDependencies', 'acquireLookup', 'lookupAbsent', 'releaseLookup', 'detachTableSlot', 'freeTsdData', 'issueDataDrainReceipt', 'cancelAbsentFromReceipt', 'attestCacheAndOwnerRoster', 'deleteGenericKey']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
