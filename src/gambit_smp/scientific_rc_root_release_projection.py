"""RC-root-release typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'rc_root_release', 'namespace': 'RcRootReleaseAst', 'fields': {'admission': 'int', 'owner': 'int', 'borrow': 'int', 'scanner': 'int', 'alias': 'int', 'registered': 'int', 'permit': 'int', 'phase': 'int', 'origin': 'int', 'receipt': 'int', 'domainLive': 'int', 'reader': 'int'}, 'actions': ['acquireBorrow', 'exportAlias', 'closeSource', 'dropOwner', 'returnBorrow', 'returnAlias', 'beginScan', 'endScan', 'enterReader', 'exitReader', 'unlinkAndPermit', 'beginFree', 'loseFreeResult', 'backendReceipt', 'settleFree', 'retireDomain']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_rc_root_release_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
