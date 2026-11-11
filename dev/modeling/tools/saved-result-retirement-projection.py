"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'saved_result_retirement', 'namespace': 'SavedResultRetirementAst', 'fields': {'a': 'int', 'b': 'int', 'c': 'int', 'complete': 'int', 'observerGate': 'int', 'observer': 'int', 'issuer': 'int', 'recordLive': 'int', 'generation': 'int'}, 'actions': ['saveA', 'installB', 'beginRestore', 'reenterPublishC', 'loseB', 'ackB', 'beginCRelease', 'loseC', 'ackC', 'commitRestore', 'beginDiscard', 'beginRestoredRelease', 'loseA', 'ackA', 'completeFirst', 'completeSecond', 'lookupRecord', 'returnRecord', 'closeObserverGate', 'closeIssuer', 'retireRecord', 'reuseSlot']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
