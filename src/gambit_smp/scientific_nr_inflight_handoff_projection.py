"""RC-reader-grace typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'nr_inflight_handoff', 'namespace': 'NrInflightHandoffAst', 'fields': {'stage': 'int', 'tokenApplied': 'int', 'nodeApplied': 'int', 'tokenReceipt': 'int', 'nodeReceipt': 'int', 'escrow': 'int', 'queue': 'int', 'lock': 'int', 'gate': 'int', 'pin': 'int', 'anchor': 'int', 'validated': 'int', 'live': 'int', 'generation': 'int', 'senders': 'int', 'rawClosed': 'int'}, 'actions': ['prepareEscrow', 'popNode', 'beginToken', 'applyTokenEffect', 'loseTokenReturn', 'receiveTokenReceipt', 'confirmToken', 'beginNodeRelease', 'applyNodeEffect', 'loseNodeReturn', 'receiveNodeReceipt', 'confirmNode', 'publishDone', 'releaseEscrow', 'beginLookup', 'validateFirst', 'validateSecond', 'installPin', 'unlockLookup', 'releasePin', 'rejectClosedLookup', 'rejectOldFirst', 'acquireClose', 'closeGate', 'closeSenders', 'closeRawRoutes', 'retireRecord', 'unlockClose', 'acquireReuse', 'commitReuse', 'unlockReuse']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_nr_inflight_handoff_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
