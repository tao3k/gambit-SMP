"""Restricted typed-IR extraction; no source/native qualification."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'dedicated_copy_capacity', 'namespace': 'DedicatedCopyAst', 'fields': {'sourceN': 'int', 'actual': 'int', 'target': 'int', 'extra': 'int', 'strategy': 'int', 'outcome': 'int', 'retired': 'int', 'charged': 'int', 'frozen': 'bool', 'attempted': 'bool', 'unknown': 'bool', 'retained': 'bool', 'sealed': 'bool', 'collecting': 'bool', 'cleaned': 'bool'}, 'actions': ['freeze', 'sharedUnsuitable', 'growFull', 'growPartial', 'growFailed', 'growUnknown', 'resolveFull', 'resolvePartial', 'chooseDedicated', 'planUnavailable', 'retryPlan', 'beginCopy', 'retireCharged', 'consumeOne', 'retainUnknown', 'cleanupKnownBatch']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_dedicated_copy_capacity_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
