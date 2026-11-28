"""Restricted actual Quint IR extraction; native emitter fidelity is not claimed."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'primitive_header_binding', 'namespace': 'PrimitiveHeaderAst', 'fields': {'phase': 'int', 'demand': 'int', 'headerDemand': 'int', 'member': 'bool', 'prm': 'bool', 'glo': 'bool', 'spec': 'bool', 'coverage': 'bool', 'closed': 'bool', 'receipt': 'bool'}, 'actions': ['seedSupply', 'seedDemand', 'seedOtherDemand', 'writeHeader', 'emitPrm', 'emitGlo', 'sealSpec', 'checkCoverage', 'closePair', 'issue', 'unknownOutput', 'rejectLateUse']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_primitive_header_binding_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
