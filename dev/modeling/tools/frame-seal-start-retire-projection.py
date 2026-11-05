"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path
import importlib.util
SPEC={'module': 'frame_seal_start_retire', 'namespace': 'SealStartAst', 'fields': {'generation': 'int', 'saved': 'int', 'ticket': 'int', 'phase': 'int', 'nativePins': 'int', 'frames': 'int', 'roots': 'int', 'maintenance': 'int', 'observers': 'int', 'denied': 'int', 'writer': 'bool', 'guard': 'bool', 'suspended': 'bool', 'sealed': 'bool', 'opaqueExport': 'bool', 'admit': 'bool', 'copyPin': 'bool', 'revocationWins': 'bool', 'unknown': 'bool', 'reclaimed': 'bool'}, 'actions': ['capture', 'resumeLive', 'resumeDenied', 'closeWriters', 'opaqueEscape', 'seal', 'abortCandidate', 'issue', 'observe', 'revoke', 'casStart', 'casFailed', 'revokeTooLate', 'finishCopy', 'nativeBorrow', 'nativeReturn', 'nativeUnknown', 'closeAdmission', 'dropFrame', 'dropRoot', 'beginMaintenance', 'endMaintenance', 'reclaim', 'denyLateBorrow']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('frame_root_scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
