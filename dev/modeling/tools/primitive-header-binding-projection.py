"""Restricted actual Quint IR extraction; native emitter fidelity is not claimed."""
from pathlib import Path
import importlib.util
SPEC={'module': 'primitive_header_binding', 'namespace': 'PrimitiveHeaderAst', 'fields': {'phase': 'int', 'demand': 'int', 'headerDemand': 'int', 'member': 'bool', 'prm': 'bool', 'glo': 'bool', 'spec': 'bool', 'coverage': 'bool', 'closed': 'bool', 'receipt': 'bool'}, 'actions': ['seedSupply', 'seedDemand', 'seedOtherDemand', 'writeHeader', 'emitPrm', 'emitGlo', 'sealSpec', 'checkCoverage', 'closePair', 'issue', 'unknownOutput', 'rejectLateUse']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('primitive_scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
