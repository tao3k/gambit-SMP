"""RC-reader-grace typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'callback_producer', 'namespace': 'CallbackProducerAst', 'fields': {'gate': 'int', 'producer': 'int', 'ticket': 'int', 'phase': 'int', 'done': 'int', 'receipt': 'int', 'resultPhase': 'int', 'resultReceipt': 'int', 'origin': 'int', 'retired': 'int'}, 'actions': ['closeRoots', 'dispatchChild', 'landingFirst', 'landingSecond', 'beginCleanup', 'loseCleanup', 'cleanupReceiptFirst', 'cleanupReceiptSecond', 'settleFirst', 'settleSecond', 'sealProducer', 'publishResult', 'beginResultRelease', 'loseResultRelease', 'resultReleaseReceipt', 'settleResultRelease', 'retireDomain']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_callback_producer_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
