"""Pool typed-IR projection delegates to the existing restricted, fail-closed emitter."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'chunk_node_pool', 'namespace': 'NodePoolAst', 'proof': 'NodePool', 'fields': {'phase': 'int', 'capacity': 'int', 'budget': 'int', 'issued': 'int', 'privateNodes': 'int', 'sealedNodes': 'int', 'queued': 'int', 'owned': 'int', 'done': 'int', 'debt': 'int', 'receipts': 'int', 'borrowers': 'int', 'kind': 'int', 'rootsClosed': 'bool', 'usersClosed': 'bool', 'headAttached': 'bool', 'admitted': 'bool', 'alive': 'bool'}, 'actions': ['admit', 'reject', 'reserve', 'derive', 'seal', 'publish', 'claim', 'finish', 'observe', 'borrow', 'returnBorrow', 'closeRoots', 'complete', 'closeUsers', 'detachHead', 'certify', 'reclaim']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_chunk_node_pool_projection.py')).with_name('chunk-transport-ledger-projection.py')
        m = _science.context.library('chunk_transport_ledger_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
