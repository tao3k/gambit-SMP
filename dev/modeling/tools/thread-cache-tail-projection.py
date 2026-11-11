"""Thread-cache tail typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'thread_cache_tail', 'namespace': 'ThreadCacheTailAst', 'fields': {'phase': 'int', 'count': 'int', 'initialCount': 'int', 'shared': 'int', 'counted': 'int', 'headPublished': 'int', 'qualified': 'int', 'receipt': 'int', 'owner': 'int', 'mask': 'int', 'supervisor': 'int', 'free': 'int', 'parentSlot': 'int', 'childSlot': 'int', 'extra': 'int', 'childPhase': 'int'}, 'actions': ['enterChild', 'childCleanupKnown', 'beginChildRestore', 'knownChildRestore', 'claimExtra', 'returnExtra', 'denyOwner', 'sampleEmpty', 'sampleLow', 'sampleNear', 'sampleHigh', 'selectFast', 'selectHelper', 'attestFastTail', 'writeFastLink', 'publishFastHead', 'incrementFastCount', 'publishFastReceipt', 'helperPush', 'helperFlush800', 'helperKnownReturn', 'unknownHelper', 'handoffParent', 'beginParentRestore', 'knownParentRestore']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
