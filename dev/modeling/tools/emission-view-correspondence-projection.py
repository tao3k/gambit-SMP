"""Restricted typed IR extraction; actual C encoding and alias closure remain obligations."""
from pathlib import Path
import importlib.util
SPEC={'module': 'emission_view_correspondence', 'namespace': 'EmissionViewAst', 'fields': {'phase': 'int', 'generation': 'int', 'snapshot': 'int', 'pending': 'int', 'writers': 'int', 'cGen': 'int', 'mGen': 'int', 'frontCaptured': 'bool', 'lateCaptured': 'bool', 'aliasesClosed': 'bool', 'inputFrozen': 'bool', 'fragmentsOwned': 'bool', 'layoutDone': 'bool', 'escaped': 'bool', 'opaqueSeen': 'bool', 'nativeQualified': 'bool', 'verifierQualified': 'bool', 'cDone': 'bool', 'mDone': 'bool', 'coverage': 'bool', 'ioComplete': 'bool', 'receipt': 'bool', 'nativeReady': 'bool'}, 'actions': ['captureFront', 'captureLate', 'discoverChild', 'drainOne', 'reserveWriter', 'writerPublish', 'writerDone', 'unknownWriter', 'escapeAlias', 'beginClose', 'closeAliases', 'freezeInputs', 'declareOpaque', 'copyFragments', 'qualifyNative', 'qualifyVerifier', 'resolveLayout', 'lateLayoutWrite', 'freeze', 'emitC', 'emitSpec', 'verifyCoverage', 'closeOutputs', 'issue', 'nativePermit', 'rejectSnapshot', 'unknownOutput', 'rejectLateWriter']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('emission_scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
