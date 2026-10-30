"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'callback_producer', 'namespace': 'CallbackProducerAst', 'fields': {'gate': 'int', 'producer': 'int', 'ticket': 'int', 'phase': 'int', 'done': 'int', 'receipt': 'int', 'resultPhase': 'int', 'resultReceipt': 'int', 'origin': 'int', 'retired': 'int'}, 'actions': ['closeRoots', 'dispatchChild', 'landingFirst', 'landingSecond', 'beginCleanup', 'loseCleanup', 'cleanupReceiptFirst', 'cleanupReceiptSecond', 'settleFirst', 'settleSecond', 'sealProducer', 'publishResult', 'beginResultRelease', 'loseResultRelease', 'resultReleaseReceipt', 'settleResultRelease', 'retireDomain']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
