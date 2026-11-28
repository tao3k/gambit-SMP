"""Restricted typed-IR projection; native producer closure is separate."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'copy_producer_envelope', 'namespace': 'ProducerEnvelopeAst', 'fields': {'epoch': 'int', 'seenEpoch': 'int', 'objectMax': 'int', 'frameFs': 'int', 'cap': 'int', 'q': 'int', 'u': 'int', 'align': 'int', 'threshold': 'int', 'budget': 'int', 'spent': 'int', 'phase': 'int', 'denied': 'int', 'objects': 'bool', 'frames': 'bool', 'abi': 'bool', 'oldPinned': 'bool', 'sourceWitness': 'bool', 'source': 'bool', 'frozen': 'bool', 'sealed': 'bool', 'started': 'bool', 'alternative': 'bool', 'retained': 'bool'}, 'actions': ['coverObjects', 'coverFrames', 'chooseCap', 'abiMismatch', 'opaqueProducer', 'missingOldModule', 'missingSourceWitness', 'freeze64', 'freeze32', 'issue', 'start', 'consume', 'weakCut', 'deferLateModule', 'replaceBeforeStart']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_copy_producer_envelope_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
