"""RC-reader-grace typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'rc_reader_grace', 'namespace': 'RcReaderGraceAst', 'fields': {'admission': 'int', 'lookup': 'int', 'claimed': 'int', 'done': 'int', 'domainLive': 'int', 'registered': 'int', 'scan': 'int', 'saved': 'int', 'diagLease': 'int', 'diagGate': 'int', 'fault': 'int', 'escrow': 'int', 'retired': 'int', 'denied': 'int', 'descendant': 'int', 'cohortDrained': 'int'}, 'actions': ['spawnDescendant', 'finishDescendant', 'confirmCohortDrain', 'enterLookup', 'claimLookup', 'failClaim', 'completeClaim', 'closeAdmission', 'rejectLate', 'beginScan', 'endScan', 'saveDiagnostic', 'borrowDiagnostic', 'returnDiagnostic', 'closeDiagnostic', 'unlinkNode', 'retireDomain']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_rc_reader_grace_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
