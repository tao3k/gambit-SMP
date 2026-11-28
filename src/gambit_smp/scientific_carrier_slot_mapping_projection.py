from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'carrier_slot_mapping', 'namespace': 'SlotMappingAst', 'fields': {'alias': 'int', 'd0': 'int', 'd1': 'int', 'mem0': 'int', 'mem1': 'int', 'store0': 'int', 'store1': 'int', 'lookup0': 'int', 'lookup1': 'int', 'borrow0': 'int', 'borrow1': 'int', 'gc': 'int', 'round': 'int', 'm0': 'int', 'm1': 'int', 'task0': 'int', 'task1': 'int', 'updated0': 'int', 'updated1': 'int', 'word0': 'int', 'word1': 'int', 'processors': 'int', 'rejected': 'int'}, 'actions': ['registerAlias', 'registerCopy', 'beginLookup0', 'acceptBorrow0', 'lookupUnknown0', 'resolveLookup0', 'rejectLookup0', 'returnBorrow0', 'close0', 'retire0', 'lateRequest0', 'claim0', 'scan0', 'scanUnknown0', 'resolveScan0', 'beginLookup1', 'acceptBorrow1', 'lookupUnknown1', 'resolveLookup1', 'rejectLookup1', 'returnBorrow1', 'close1', 'retire1', 'lateRequest1', 'claim1', 'scan1', 'scanUnknown1', 'resolveScan1', 'freeze000', 'freeze001', 'freeze010', 'freeze011', 'freeze100', 'freeze101', 'freeze110', 'freeze111', 'finishRound', 'freeStore0', 'freeStore1', 'exitProcessor']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_carrier_slot_mapping_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
