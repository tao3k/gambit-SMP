"""Thread-cache tail typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'thread_cache_tail', 'namespace': 'ThreadCacheTailAst', 'fields': {'phase': 'int', 'count': 'int', 'initialCount': 'int', 'shared': 'int', 'counted': 'int', 'headPublished': 'int', 'qualified': 'int', 'receipt': 'int', 'owner': 'int', 'mask': 'int', 'supervisor': 'int', 'free': 'int', 'parentSlot': 'int', 'childSlot': 'int', 'extra': 'int', 'childPhase': 'int'}, 'actions': ['enterChild', 'childCleanupKnown', 'beginChildRestore', 'knownChildRestore', 'claimExtra', 'returnExtra', 'denyOwner', 'sampleEmpty', 'sampleLow', 'sampleNear', 'sampleHigh', 'selectFast', 'selectHelper', 'attestFastTail', 'writeFastLink', 'publishFastHead', 'incrementFastCount', 'publishFastReceipt', 'helperPush', 'helperFlush800', 'helperKnownReturn', 'unknownHelper', 'handoffParent', 'beginParentRestore', 'knownParentRestore']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_thread_cache_tail_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
