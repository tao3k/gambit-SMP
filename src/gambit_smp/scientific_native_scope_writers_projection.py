"""Closed-writer NativeScope typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'native_scope_writers', 'namespace': 'NativeScopeAst', 'fields': {'phase': 'int', 'generation': 'int', 'thread': 'int', 'cap': 'int', 'nested': 'int', 'gate': 'int', 'pending': 'int', 'unknown': 'int', 'pins': 'int', 'roots': 'int', 'descriptors': 'int', 'custodian': 'int', 'closedWorld': 'int', 'pub': 'int', 'view': 'int', 'rf': 'int', 'observed': 'int', 'floor0': 'int', 'floor1': 'int', 'handoffRelease': 'int', 'targetAcquired': 'int', 'returnRight': 'int', 'recorded': 'int', 'callGen': 'int', 'responseGen': 'int', 'rejected': 'int'}, 'actions': ['issue', 'beginWrite', 'publishRelease', 'recordOutcome', 'deliverOutcome', 'loseResponse', 'recoverRecorded', 'enterNested', 'leaveNested', 'catcherSubtree', 'acquire0', 'acquire1', 'closeAdmission', 'renewSameThread', 'prepareMigration', 'targetAcquire', 'issueTarget', 'rejectStaleDelivery', 'rawInterference', 'retire']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_native_scope_writers_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
