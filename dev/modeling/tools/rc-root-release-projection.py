"""RC-root-release typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'rc_root_release', 'namespace': 'RcRootReleaseAst', 'fields': {'admission': 'int', 'owner': 'int', 'borrow': 'int', 'scanner': 'int', 'alias': 'int', 'registered': 'int', 'permit': 'int', 'phase': 'int', 'origin': 'int', 'receipt': 'int', 'domainLive': 'int', 'reader': 'int'}, 'actions': ['acquireBorrow', 'exportAlias', 'closeSource', 'dropOwner', 'returnBorrow', 'returnAlias', 'beginScan', 'endScan', 'enterReader', 'exitReader', 'unlinkAndPermit', 'beginFree', 'loseFreeResult', 'backendReceipt', 'settleFree', 'retireDomain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
