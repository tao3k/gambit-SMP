"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'cleanup_ingress', 'namespace': 'CleanupIngressAst', 'fields': {'gate': 'int', 'outer': 'int', 'child': 'int', 'permit': 'int', 'closed': 'int', 'guard': 'int', 'roots': 'int', 'settled': 'int', 'resultDebt': 'int', 'unknown': 'int', 'collective': 'int', 'joined': 'int', 'retired': 'int'}, 'actions': ['reserveChild', 'enterChild', 'returnChild', 'cancelPermit', 'requestClose', 'loseBoundary', 'recoverLanding', 'exportResult', 'releaseResult', 'finishOuter', 'drainCollective', 'joinUnknown', 'joinKnown', 'retireDomain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
