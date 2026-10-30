"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'nr_anchor_retirement', 'namespace': 'NrAnchorRetirementAst', 'fields': {'token': 'int', 'queue': 'int', 'node': 'int', 'done': 'int', 'eeLive': 'int', 'senders': 'int', 'anchorPin': 'int', 'recordPin': 'int', 'recordGate': 'int', 'recordLive': 'int', 'generation': 'int', 'rawClosed': 'int'}, 'actions': ['produceErrorToken', 'completeNoToken', 'enqueueToken', 'claimPrivateToken', 'popCallback', 'knownTokenConsumption', 'unknownCallbackExit', 'reconcileKnownConsumption', 'finishLanding', 'exitOwnerEnv', 'acquireAnchor', 'lookupFirstRecord', 'lookupSecondRecord', 'releaseRecord', 'releaseAnchor', 'closeRecordGate', 'closeSenders', 'closeRawRoutes', 'retireRecord', 'reuseSlot', 'acceptFirstAck', 'rejectFirstAfterReuse']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
