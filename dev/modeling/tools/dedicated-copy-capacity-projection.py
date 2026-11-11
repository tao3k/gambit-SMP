"""Restricted typed-IR extraction; no source/native qualification."""
from pathlib import Path
import importlib.util
SPEC={'module': 'dedicated_copy_capacity', 'namespace': 'DedicatedCopyAst', 'fields': {'sourceN': 'int', 'actual': 'int', 'target': 'int', 'extra': 'int', 'strategy': 'int', 'outcome': 'int', 'retired': 'int', 'charged': 'int', 'frozen': 'bool', 'attempted': 'bool', 'unknown': 'bool', 'retained': 'bool', 'sealed': 'bool', 'collecting': 'bool', 'cleaned': 'bool'}, 'actions': ['freeze', 'sharedUnsuitable', 'growFull', 'growPartial', 'growFailed', 'growUnknown', 'resolveFull', 'resolvePartial', 'chooseDedicated', 'planUnavailable', 'retryPlan', 'beginCopy', 'retireCharged', 'consumeOne', 'retainUnknown', 'cleanupKnownBatch']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("copy_capacity_scalar_projection",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
