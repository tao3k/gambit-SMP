from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'restore_entry_guard', 'namespace': 'RestoreEntryAst', 'fields': {'t0phase': 'int', 't0witness': 'int', 't0issued': 'int', 't0settles': 'int', 't0carrier': 'int', 't0guard': 'bool', 't0roots': 'bool', 't0restored': 'bool', 't0ack': 'bool', 't1phase': 'int', 't1witness': 'int', 't1issued': 'int', 't1settles': 'int', 't1carrier': 'int', 't1guard': 'bool', 't1roots': 'bool', 't1restored': 'bool', 't1ack': 'bool', 'current': 'int', 'parent1': 'int', 'kind1': 'int', 'presented': 'int', 'nonce': 'int', 'hops': 'int', 'duplicates': 'int', 'rejected': 'int', 'markerCreated1': 'bool', 'markerLive1': 'bool'}, 'actions': ['reserveInitial0', 'publishRoot0', 'enterInitial0', 'internalGraft0', 'suspend0', 'schedulerResume0', 'bodyReturn0', 'restoreOuter0', 'observeExit0', 'settle0', 'reserveSemantic1', 'reserveCrossRestore1', 'reserveForeignChild1', 'publishRoot1', 'allocateMarker1', 'enter1', 'internalGraft1', 'bodyReturn1', 'restoreOuter1', 'invalidateMarker1', 'observeExit1', 'settle1', 'abortMarkerAllocation1', 'unknownForeignExit1', 'confirmOuterCatch1', 'presentOld', 'presentNew', 'presentOldAsNew', 'rejectMismatchedGuard', 'repeatOldReceipt', 'rejectUnobservedOldExit', 'loseReply0', 'query0', 'loseReply1', 'query1']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_restore_entry_guard_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
