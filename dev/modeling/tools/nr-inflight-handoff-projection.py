"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'nr_inflight_handoff', 'namespace': 'NrInflightHandoffAst', 'fields': {'stage': 'int', 'tokenApplied': 'int', 'nodeApplied': 'int', 'tokenReceipt': 'int', 'nodeReceipt': 'int', 'escrow': 'int', 'queue': 'int', 'lock': 'int', 'gate': 'int', 'pin': 'int', 'anchor': 'int', 'validated': 'int', 'live': 'int', 'generation': 'int', 'senders': 'int', 'rawClosed': 'int'}, 'actions': ['prepareEscrow', 'popNode', 'beginToken', 'applyTokenEffect', 'loseTokenReturn', 'receiveTokenReceipt', 'confirmToken', 'beginNodeRelease', 'applyNodeEffect', 'loseNodeReturn', 'receiveNodeReceipt', 'confirmNode', 'publishDone', 'releaseEscrow', 'beginLookup', 'validateFirst', 'validateSecond', 'installPin', 'unlockLookup', 'releasePin', 'rejectClosedLookup', 'rejectOldFirst', 'acquireClose', 'closeGate', 'closeSenders', 'closeRawRoutes', 'retireRecord', 'unlockClose', 'acquireReuse', 'commitReuse', 'unlockReuse']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
