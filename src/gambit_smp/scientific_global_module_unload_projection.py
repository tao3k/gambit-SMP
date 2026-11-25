"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'global_module_unload', 'namespace': 'GlobalUnloadAst', 'fields': {'epoch': 'int', 'phase': 'int', 'users0': 'int', 'users1': 'int', 'nativeUsers': 'int', 'tasks': 'int', 'observers': 'int', 'stamp0': 'int', 'stamp1': 'int', 'denied': 'int', 'closed0': 'bool', 'closed1': 'bool', 'ready0': 'bool', 'ready1': 'bool', 'receipt0': 'bool', 'receipt1': 'bool', 'pendingChild': 'bool', 'unknownResult': 'bool', 'scopeComplete': 'bool', 'teardownQualified': 'bool', 'loaderPin': 'bool'}, 'actions': ['borrow0', 'borrow1', 'observe', 'closeGlobal', 'closeLocal0', 'closeLocal1', 'return0', 'return1', 'issueLocal0', 'issueLocal1', 'deliver0', 'deliver1', 'rejectStale', 'rejectLate', 'nativeBorrow', 'nativeReturn', 'unknownNative', 'observerRetire', 'beginChild', 'commitChild', 'rejectChild', 'unknownChild', 'taskDone', 'permit', 'beginUnload', 'closeKnown', 'closeUnknown', 'rejectIncomplete']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_global_module_unload_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
