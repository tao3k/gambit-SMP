"""Restricted typed-IR extraction; shared emitter is pinned by the study input receipt."""
from pathlib import Path
import importlib.util
SPEC={'module': 'continuation_restore_plan', 'namespace': 'ContinuationRestoreAst', 'fields': {'r0': 'int', 'r1': 'int', 'mode0': 'int', 'mode1': 'int', 'cap0': 'int', 'cap1': 'int', 'outcome': 'int', 'denied': 'int', 'frozen': 'bool', 'retained': 'bool'}, 'actions': ['freezeSmall', 'freezeLarge', 'freezeOversize', 'share0', 'share1', 'dedicate0', 'dedicate1', 'reject0', 'reject1', 'sealAccept', 'sealReject', 'allocationFailure', 'denyMutation', 'retainUnknown']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("restore_scalar_projection",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
