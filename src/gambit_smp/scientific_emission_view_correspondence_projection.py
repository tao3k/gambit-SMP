"""Restricted typed IR extraction; actual C encoding and alias closure remain obligations."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'emission_view_correspondence', 'namespace': 'EmissionViewAst', 'fields': {'phase': 'int', 'generation': 'int', 'snapshot': 'int', 'pending': 'int', 'writers': 'int', 'cGen': 'int', 'mGen': 'int', 'frontCaptured': 'bool', 'lateCaptured': 'bool', 'aliasesClosed': 'bool', 'inputFrozen': 'bool', 'fragmentsOwned': 'bool', 'layoutDone': 'bool', 'escaped': 'bool', 'opaqueSeen': 'bool', 'nativeQualified': 'bool', 'verifierQualified': 'bool', 'cDone': 'bool', 'mDone': 'bool', 'coverage': 'bool', 'ioComplete': 'bool', 'receipt': 'bool', 'nativeReady': 'bool'}, 'actions': ['captureFront', 'captureLate', 'discoverChild', 'drainOne', 'reserveWriter', 'writerPublish', 'writerDone', 'unknownWriter', 'escapeAlias', 'beginClose', 'closeAliases', 'freezeInputs', 'declareOpaque', 'copyFragments', 'qualifyNative', 'qualifyVerifier', 'resolveLayout', 'lateLayoutWrite', 'freeze', 'emitC', 'emitSpec', 'verifyCoverage', 'closeOutputs', 'issue', 'nativePermit', 'rejectSnapshot', 'unknownOutput', 'rejectLateWriter']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_emission_view_correspondence_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
