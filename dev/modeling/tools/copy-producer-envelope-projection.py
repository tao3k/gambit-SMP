"""Restricted typed-IR projection; native producer closure is separate."""
from pathlib import Path
import importlib.util
SPEC={'module': 'copy_producer_envelope', 'namespace': 'ProducerEnvelopeAst', 'fields': {'epoch': 'int', 'seenEpoch': 'int', 'objectMax': 'int', 'frameFs': 'int', 'cap': 'int', 'q': 'int', 'u': 'int', 'align': 'int', 'threshold': 'int', 'budget': 'int', 'spent': 'int', 'phase': 'int', 'denied': 'int', 'objects': 'bool', 'frames': 'bool', 'abi': 'bool', 'oldPinned': 'bool', 'sourceWitness': 'bool', 'source': 'bool', 'frozen': 'bool', 'sealed': 'bool', 'started': 'bool', 'alternative': 'bool', 'retained': 'bool'}, 'actions': ['coverObjects', 'coverFrames', 'chooseCap', 'abiMismatch', 'opaqueProducer', 'missingOldModule', 'missingSourceWitness', 'freeze64', 'freeze32', 'issue', 'start', 'consume', 'weakCut', 'deferLateModule', 'replaceBeforeStart']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("producer_scalar_projection",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
