"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'putobjs_move_graph', 'namespace': 'PutObjsMoveGraphAst', 'fields': {'p': 'int', 'c': 'int', 'knowledge': 'int', 'mutex': 'int', 'walk': 'int', 'cursor': 'int', 'sharedHead': 'int', 'sharedCount': 'int', 'destHead': 'int', 'destTail': 'int', 'destCount': 'int', 'tailNext': 'int', 'localTail': 'int', 'pops': 'int', 'popPtr': 'int', 'nMove': 'int', 'tailReturned': 'int', 'tailReused': 'int', 'receipt': 'int', 'held': 'int', 'gate': 'int', 'readers': 'int', 'ready': 'int', 'generation': 'int', 'stamp': 'int', 'opaqueOnly': 'int', 'oldRead': 'int'}, 'actions': ['knownProducerUnlock', 'unknownReleased', 'unknownStillHeld', 'fixProducerLast', 'publishReceipt', 'closeSourceAdmission', 'sourceReadersDetached', 'attestSourceFinalized', 'reuseSourceCache', 'borrowOldTail', 'acquireConsumer', 'selectMove800', 'loadMoveHead', 'creditDestination', 'debitShared', 'walkMovedNext', 'detachSharedHead', 'assignDestinationTail', 'cutMovedTail', 'publishDestinationHead', 'releaseConsumer', 'loadPopHead', 'advanceInteriorHead', 'advanceLastHead', 'decrementDestination', 'returnInterior', 'returnTail', 'initializeTailPayload']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_putobjs_move_graph_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
