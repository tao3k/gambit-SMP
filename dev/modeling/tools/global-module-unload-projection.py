"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path
import importlib.util
SPEC={'module': 'global_module_unload', 'namespace': 'GlobalUnloadAst', 'fields': {'epoch': 'int', 'phase': 'int', 'users0': 'int', 'users1': 'int', 'nativeUsers': 'int', 'tasks': 'int', 'observers': 'int', 'stamp0': 'int', 'stamp1': 'int', 'denied': 'int', 'closed0': 'bool', 'closed1': 'bool', 'ready0': 'bool', 'ready1': 'bool', 'receipt0': 'bool', 'receipt1': 'bool', 'pendingChild': 'bool', 'unknownResult': 'bool', 'scopeComplete': 'bool', 'teardownQualified': 'bool', 'loaderPin': 'bool'}, 'actions': ['borrow0', 'borrow1', 'observe', 'closeGlobal', 'closeLocal0', 'closeLocal1', 'return0', 'return1', 'issueLocal0', 'issueLocal1', 'deliver0', 'deliver1', 'rejectStale', 'rejectLate', 'nativeBorrow', 'nativeReturn', 'unknownNative', 'observerRetire', 'beginChild', 'commitChild', 'rejectChild', 'unknownChild', 'taskDone', 'permit', 'beginUnload', 'closeKnown', 'closeUnknown', 'rejectIncomplete']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('frame_root_scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
