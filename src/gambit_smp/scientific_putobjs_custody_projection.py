"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'putobjs_custody', 'namespace': 'PutObjsCustodyAst', 'fields': {'phase': 'int', 'mode': 'int', 'empty': 'int', 'walk': 'int', 'last': 'int', 'localCount': 'int', 'uncredited': 'int', 'exposed': 'int', 'delta': 'int', 'split': 'int', 'lock': 'int', 'sharedTail': 'int', 'lastFixed': 'int', 'receipt': 'int', 'escaped': 'int', 'held': 'int', 'gate': 'int', 'readers': 'int', 'generation': 'int', 'stamp': 'int', 'accepted': 'int', 'finalized': 'int', 'batchTaken': 'int'}, 'actions': ['takePublishedBatch', 'admitOwner', 'chooseEmpty', 'chooseNonempty', 'trimLocal', 'loadLocalHead', 'assignLast', 'advanceCursor', 'loopAgain', 'cutLocal', 'lockKnown', 'lockUnknown', 'linkOldTail', 'publishSharedHead', 'updateEmptySharedTail', 'keepSharedTail', 'addSharedCount', 'unlockKnown', 'unlockUnknown', 'fixLocalLast', 'publishReceipt', 'escape', 'loseReceiptAck', 'acceptReceipt', 'closeAdmission', 'readersDetached', 'attestFinalization', 'reuseAddress']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_putobjs_custody_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
