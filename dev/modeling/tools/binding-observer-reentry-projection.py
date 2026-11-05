from pathlib import Path
import importlib.util
SPEC={'module': 'binding_observer_reentry', 'namespace': 'BindingObserverAst', 'fields': {'stage': 'int', 'mode': 'int', 'writers': 'int', 'demand': 'int', 'epoch': 'int', 'planEpoch': 'int', 'depth': 'int', 'observerSafe': 'bool', 'first': 'bool', 'second': 'bool', 'custody': 'bool', 'errorSeen': 'bool', 'stable': 'bool', 'closed': 'bool', 'receipt': 'bool', 'captured': 'bool'}, 'actions': ['plainProfile', 'useOnlyProfile', 'rawProfile', 'seal', 'firstElide', 'firstRetain', 'enterFormatter', 'enterIOHandler', 'enterTimeout', 'enterGC', 'readObserver', 'namedDemand', 'namedSupply', 'rawWrite', 'leaveHook', 'secondReadonly', 'secondUnobserved', 'secondNormalize', 'ioFailure', 'compilerAbort', 'nestedCompilation', 'rejectStale', 'capture', 'resumeCaptured', 'certifyNoResume', 'closeOutput', 'issue', 'unknownExit', 'debugScalarPass']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py');s=importlib.util.spec_from_file_location('observer_scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
