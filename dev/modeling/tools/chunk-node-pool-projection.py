"""Pool typed-IR projection delegates to the existing restricted, fail-closed emitter."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'chunk_node_pool', 'namespace': 'NodePoolAst', 'proof': 'NodePool', 'fields': {'phase': 'int', 'capacity': 'int', 'budget': 'int', 'issued': 'int', 'privateNodes': 'int', 'sealedNodes': 'int', 'queued': 'int', 'owned': 'int', 'done': 'int', 'debt': 'int', 'receipts': 'int', 'borrowers': 'int', 'kind': 'int', 'rootsClosed': 'bool', 'usersClosed': 'bool', 'headAttached': 'bool', 'admitted': 'bool', 'alive': 'bool'}, 'actions': ['admit', 'reject', 'reserve', 'derive', 'seal', 'publish', 'claim', 'finish', 'observe', 'borrow', 'returnBorrow', 'closeRoots', 'complete', 'closeUsers', 'detachHead', 'certify', 'reclaim']}
def generate(ir):
 p=Path(__file__).with_name('chunk-transport-ledger-projection.py')
 s=importlib.util.spec_from_file_location('restricted_pool_projection',p)
 m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
