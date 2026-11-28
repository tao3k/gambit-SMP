"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'frame_seal_root_scope', 'namespace': 'FrameSealRootAst', 'fields': {'live': 'int', 'snap': 'int', 'rootEpoch': 'int', 'seen': 'int', 'request': 'int', 'Q': 'int', 'A': 'int', 'T': 'int', 'B': 'int', 'denied': 'int', 'owner': 'bool', 'aliases': 'bool', 'sealedView': 'bool', 'frozen': 'bool', 'covered': 'bool', 'modulePinned': 'bool', 'moduleClosed': 'bool', 'ledger': 'bool', 'receipt': 'bool', 'started': 'bool', 'alternative': 'bool', 'retained': 'bool'}, 'actions': ['own', 'mutateLive', 'seal', 'beginRequest', 'publishRequest', 'selectRequest', 'unknownRequest', 'completeRequest', 'ackSource', 'freeze', 'coverSource', 'issue', 'start', 'relocate', 'deferRootWriter', 'revokeBeforeCopy', 'finishRound', 'closeLedger', 'retireModule', 'rejectOpaque']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_frame_seal_root_scope_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
