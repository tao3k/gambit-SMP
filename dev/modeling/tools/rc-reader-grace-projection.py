"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'rc_reader_grace', 'namespace': 'RcReaderGraceAst', 'fields': {'admission': 'int', 'lookup': 'int', 'claimed': 'int', 'done': 'int', 'domainLive': 'int', 'registered': 'int', 'scan': 'int', 'saved': 'int', 'diagLease': 'int', 'diagGate': 'int', 'fault': 'int', 'escrow': 'int', 'retired': 'int', 'denied': 'int', 'descendant': 'int', 'cohortDrained': 'int'}, 'actions': ['spawnDescendant', 'finishDescendant', 'confirmCohortDrain', 'enterLookup', 'claimLookup', 'failClaim', 'completeClaim', 'closeAdmission', 'rejectLate', 'beginScan', 'endScan', 'saveDiagnostic', 'borrowDiagnostic', 'returnDiagnostic', 'closeDiagnostic', 'unlinkNode', 'retireDomain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
