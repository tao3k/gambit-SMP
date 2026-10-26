"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'cohort_retirement', 'namespace': 'CohortRetirementAst', 'fields': {'admission': 'int', 'lookup': 'int', 'worker': 'int', 'external': 'int', 'fault': 'int', 'closed': 'int', 'drained': 'int', 'joined': 'int', 'unknown': 'int', 'retired': 'int'}, 'actions': ['enterLookup', 'exitLookup', 'acquireExternal', 'returnExternal', 'closeRoster', 'escapeScanner', 'collectiveDrain', 'exitWorker', 'joinUnknown', 'joinKnown', 'retireDomain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
