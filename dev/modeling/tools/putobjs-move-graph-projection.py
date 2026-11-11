"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'putobjs_move_graph', 'namespace': 'PutObjsMoveGraphAst', 'fields': {'p': 'int', 'c': 'int', 'knowledge': 'int', 'mutex': 'int', 'walk': 'int', 'cursor': 'int', 'sharedHead': 'int', 'sharedCount': 'int', 'destHead': 'int', 'destTail': 'int', 'destCount': 'int', 'tailNext': 'int', 'localTail': 'int', 'pops': 'int', 'popPtr': 'int', 'nMove': 'int', 'tailReturned': 'int', 'tailReused': 'int', 'receipt': 'int', 'held': 'int', 'gate': 'int', 'readers': 'int', 'ready': 'int', 'generation': 'int', 'stamp': 'int', 'opaqueOnly': 'int', 'oldRead': 'int'}, 'actions': ['knownProducerUnlock', 'unknownReleased', 'unknownStillHeld', 'fixProducerLast', 'publishReceipt', 'closeSourceAdmission', 'sourceReadersDetached', 'attestSourceFinalized', 'reuseSourceCache', 'borrowOldTail', 'acquireConsumer', 'selectMove800', 'loadMoveHead', 'creditDestination', 'debitShared', 'walkMovedNext', 'detachSharedHead', 'assignDestinationTail', 'cutMovedTail', 'publishDestinationHead', 'releaseConsumer', 'loadPopHead', 'advanceInteriorHead', 'advanceLastHead', 'decrementDestination', 'returnInterior', 'returnTail', 'initializeTailPayload']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
