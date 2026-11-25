from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'source_owner_registry', 'namespace': 'SourceOwnerAst', 'fields': {'registry': 'int', 'owner': 'int', 'root': 'int', 'writer': 'int', 'writerRoot': 'int', 'payload': 'int', 'writeId': 'int', 'seenWrite': 'int', 'lastDone': 'int', 'round': 'int', 'gc': 'int', 'manifest': 'int', 'storage': 'int', 'pin0': 'int', 'pin1': 'int', 'used0': 'int', 'used1': 'int', 'view0': 'int', 'view1': 'int', 'target0': 'int', 'target1': 'int', 'targetView0': 'int', 'targetView1': 'int', 'guard0': 'int', 'guard1': 'int', 'ack0': 'int', 'ack1': 'int', 'queries': 'int', 'rejects': 'int', 'persistent': 'int'}, 'actions': ['reserveOwner', 'prepareRoot', 'publishOwner', 'abortPrivate', 'closeRegistry', 'closeOwner', 'sealRoster', 'rejectLate', 'beginWrite', 'unknownWrite', 'presentCurrentWrite', 'presentOldWrite', 'commitWrite', 'abortWrite', 'queryWrite', 'pin0', 'enrollTarget0', 'ackRound0', 'reserveGuard0', 'commitGuard0', 'unknownGuard0', 'resolveGuard0', 'returnPin0', 'finishGuard0', 'retireTarget0', 'pin1', 'enrollTarget1', 'ackRound1', 'reserveGuard1', 'commitGuard1', 'unknownGuard1', 'resolveGuard1', 'returnPin1', 'finishGuard1', 'retireTarget1', 'qualifyPersistentCoverage', 'freezeGc', 'finishGc', 'storageReceipt', 'bulkCleanup']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_source_owner_registry_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
