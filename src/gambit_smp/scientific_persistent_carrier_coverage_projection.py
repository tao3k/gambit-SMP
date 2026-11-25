from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'persistent_carrier_coverage', 'namespace': 'CarrierCoverageAst', 'fields': {'d0': 'int', 'd1': 'int', 'mem0': 'int', 'mem1': 'int', 'initialized1': 'int', 'known1': 'int', 'sourcePin': 'int', 'use1': 'int', 'observe1': 'int', 'managed': 'int', 'rawUnknown': 'int', 'backing1': 'int', 'payload0': 'int', 'payload1': 'int', 'round': 'int', 'gc': 'int', 'snap0': 'int', 'snap1': 'int', 'read0': 'int', 'read1': 'int', 'done0': 'int', 'done1': 'int', 'updated0': 'int', 'updated1': 'int', 'processors': 'int', 'queries': 'int'}, 'actions': ['admitManagedWriters', 'reserveCarrier', 'initializeCarrier', 'publishCarrier', 'queryPublication', 'returnSourcePin', 'borrowPayload', 'returnPayload', 'observeReceipt', 'releaseObserver', 'revokeCarrier', 'closeSource', 'managedSetter', 'recordRawInterference', 'storageHandoff', 'cleanupSource', 'retireCarrier', 'shrinkProcessors', 'freezeBoth', 'freezeSource', 'freezeCarrier', 'freezeNeither', 'claim0', 'scanDone0', 'scanUnknown0', 'resolveScan0', 'claim1', 'scanDone1', 'scanUnknown1', 'resolveScan1', 'finishRound']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_persistent_carrier_coverage_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
