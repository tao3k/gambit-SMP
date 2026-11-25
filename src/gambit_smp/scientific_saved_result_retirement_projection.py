"""RC-reader-grace typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'saved_result_retirement', 'namespace': 'SavedResultRetirementAst', 'fields': {'a': 'int', 'b': 'int', 'c': 'int', 'complete': 'int', 'observerGate': 'int', 'observer': 'int', 'issuer': 'int', 'recordLive': 'int', 'generation': 'int'}, 'actions': ['saveA', 'installB', 'beginRestore', 'reenterPublishC', 'loseB', 'ackB', 'beginCRelease', 'loseC', 'ackC', 'commitRestore', 'beginDiscard', 'beginRestoredRelease', 'loseA', 'ackA', 'completeFirst', 'completeSecond', 'lookupRecord', 'returnRecord', 'closeObserverGate', 'closeIssuer', 'retireRecord', 'reuseSlot']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_saved_result_retirement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
