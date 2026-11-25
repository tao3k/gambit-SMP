"""Restricted scalar projection; shared projector remains trusted."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'storage_index_transactions', 'namespace': 'StorageIndexAst', 'fields': {'opened': 'int', 'generation': 'int', 'revision': 'int', 'adjacent': 'int', 'payload': 'int', 'rejections': 'int', 'a': 'int', 'aSnapshot': 'int', 'aSnapshotGeneration': 'int', 'aGeneration': 'int', 'aLease': 'int', 'aBound': 'int', 'aRoot': 'int', 'aKnown': 'int', 'aReaders': 'int', 'aScan': 'int', 'b': 'int', 'bSnapshot': 'int', 'bSnapshotGeneration': 'int', 'bGeneration': 'int', 'bLease': 'int', 'bBound': 'int', 'bRoot': 'int', 'bKnown': 'int', 'bReaders': 'int', 'bScan': 'int'}, 'actions': ['chooseAdjacent', 'observeA', 'reserveA', 'prepareA', 'publishA', 'queryA', 'borrowA', 'returnA', 'scanA', 'finishScanA', 'revokeA', 'drainA', 'abortA', 'settleA', 'rejectOldA', 'observeB', 'reserveB', 'prepareB', 'publishB', 'queryB', 'borrowB', 'returnB', 'scanB', 'finishScanB', 'revokeB', 'drainB', 'abortB', 'settleB', 'rejectOldB', 'sourceWrite', 'closeIndex', 'reuse']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_storage_index_transactions_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
