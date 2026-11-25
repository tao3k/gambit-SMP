from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'binding_observer_reentry', 'namespace': 'BindingObserverAst', 'fields': {'stage': 'int', 'mode': 'int', 'writers': 'int', 'demand': 'int', 'epoch': 'int', 'planEpoch': 'int', 'depth': 'int', 'observerSafe': 'bool', 'first': 'bool', 'second': 'bool', 'custody': 'bool', 'errorSeen': 'bool', 'stable': 'bool', 'closed': 'bool', 'receipt': 'bool', 'captured': 'bool'}, 'actions': ['plainProfile', 'useOnlyProfile', 'rawProfile', 'seal', 'firstElide', 'firstRetain', 'enterFormatter', 'enterIOHandler', 'enterTimeout', 'enterGC', 'readObserver', 'namedDemand', 'namedSupply', 'rawWrite', 'leaveHook', 'secondReadonly', 'secondUnobserved', 'secondNormalize', 'ioFailure', 'compilerAbort', 'nestedCompilation', 'rejectStale', 'capture', 'resumeCaptured', 'certifyNoResume', 'closeOutput', 'issue', 'unknownExit', 'debugScalarPass']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_binding_observer_reentry_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
