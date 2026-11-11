"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path
import importlib.util
SPEC={'module': 'frame_seal_root_scope', 'namespace': 'FrameSealRootAst', 'fields': {'live': 'int', 'snap': 'int', 'rootEpoch': 'int', 'seen': 'int', 'request': 'int', 'Q': 'int', 'A': 'int', 'T': 'int', 'B': 'int', 'denied': 'int', 'owner': 'bool', 'aliases': 'bool', 'sealedView': 'bool', 'frozen': 'bool', 'covered': 'bool', 'modulePinned': 'bool', 'moduleClosed': 'bool', 'ledger': 'bool', 'receipt': 'bool', 'started': 'bool', 'alternative': 'bool', 'retained': 'bool'}, 'actions': ['own', 'mutateLive', 'seal', 'beginRequest', 'publishRequest', 'selectRequest', 'unknownRequest', 'completeRequest', 'ackSource', 'freeze', 'coverSource', 'issue', 'start', 'relocate', 'deferRootWriter', 'revokeBeforeCopy', 'finishRound', 'closeLedger', 'retireModule', 'rejectOpaque']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('frame_root_scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
