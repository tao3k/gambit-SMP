"""Restricted scalar projection; shared projector remains trusted."""
import importlib.util
from pathlib import Path
SPEC={'module': 'storage_index_transactions', 'namespace': 'StorageIndexAst', 'fields': {'opened': 'int', 'generation': 'int', 'revision': 'int', 'adjacent': 'int', 'payload': 'int', 'rejections': 'int', 'a': 'int', 'aSnapshot': 'int', 'aSnapshotGeneration': 'int', 'aGeneration': 'int', 'aLease': 'int', 'aBound': 'int', 'aRoot': 'int', 'aKnown': 'int', 'aReaders': 'int', 'aScan': 'int', 'b': 'int', 'bSnapshot': 'int', 'bSnapshotGeneration': 'int', 'bGeneration': 'int', 'bLease': 'int', 'bBound': 'int', 'bRoot': 'int', 'bKnown': 'int', 'bReaders': 'int', 'bScan': 'int'}, 'actions': ['chooseAdjacent', 'observeA', 'reserveA', 'prepareA', 'publishA', 'queryA', 'borrowA', 'returnA', 'scanA', 'finishScanA', 'revokeA', 'drainA', 'abortA', 'settleA', 'rejectOldA', 'observeB', 'reserveB', 'prepareB', 'publishB', 'queryB', 'borrowB', 'returnB', 'scanB', 'finishScanB', 'revokeB', 'drainB', 'abortB', 'settleB', 'rejectOldB', 'sourceWrite', 'closeIndex', 'reuse']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
