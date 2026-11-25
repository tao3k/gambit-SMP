from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'source_pin_handoff', 'namespace': 'SourcePinAst', 'fields': {'gate': 'int', 'alive': 'int', 'sourceRoot': 'int', 'epoch': 'int', 'gc': 'int', 'pin0': 'int', 'pin1': 'int', 'accepted0': 'int', 'accepted1': 'int', 'carrier0': 'int', 'carrier1': 'int', 'value0': 'int', 'value1': 'int', 'guard0': 'int', 'guard1': 'int', 'ack0': 'int', 'ack1': 'int', 'dups': 'int', 'rejected': 'int'}, 'actions': ['pinOuter', 'pinNested', 'closeSource', 'rejectLatePin', 'copy0', 'refresh0', 'enroll0', 'reserveGuard0', 'commitGuard0', 'lostReservation0', 'resolveCommitted0', 'resolveFailed0', 'queryAck0', 'returnPin0', 'repeatReturn0', 'abortBeforeGuard0', 'outerExit0', 'retireCarrier0', 'copy1', 'refresh1', 'enroll1', 'reserveGuard1', 'commitGuard1', 'lostReservation1', 'resolveCommitted1', 'resolveFailed1', 'queryAck1', 'returnPin1', 'repeatReturn1', 'abortBeforeGuard1', 'outerExit1', 'retireCarrier1', 'retireSource', 'freezeGc', 'finishGcNone', 'finishGcOuter', 'finishGcNested', 'finishGcBoth']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_source_pin_handoff_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
