"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'exit_domain_drain', 'namespace': 'ExitDomainDrainAst', 'fields': {'phase': 'int', 'a': 'int', 'b': 'int', 'ack': 'int', 'parent': 'int', 'samePair': 'int', 'tailLive': 'int', 'tailDone': 'int', 'admission': 'int', 'keyGate': 'int', 'lookupPin': 'int', 'data': 'int', 'slot': 'int', 'cache': 'int', 'joined': 'int', 'miss': 'int', 'deps': 'int', 'cacheDone': 'int', 'allOwners': 'int', 'key': 'int'}, 'actions': ['seedRegistrationA', 'chooseDuplicatePair', 'reserveExternalB', 'beginDrain', 'reserveChildB', 'reserveTailB', 'publishBKnown', 'publishBUnknown', 'publicationAbsentUnknown', 'reconcileAcceptedB', 'reconcileAbsentAndRolledBackB', 'popA', 'popB', 'returnA', 'returnB', 'callbackUnknownA', 'freeNodeAKnown', 'freeNodeBKnown', 'freeNodeAUnknown', 'freeNodeBUnknown', 'cancelNewestDuplicateB', 'cancelQueuedA', 'reentrantFinalizeJoin', 'beginSubsystemTail', 'finishSubsystemTail', 'closeProducers', 'attestNoTsdDependencies', 'acquireLookup', 'lookupAbsent', 'releaseLookup', 'detachTableSlot', 'freeTsdData', 'issueDataDrainReceipt', 'cancelAbsentFromReceipt', 'attestCacheAndOwnerRoster', 'deleteGenericKey']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_exit_domain_drain_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
