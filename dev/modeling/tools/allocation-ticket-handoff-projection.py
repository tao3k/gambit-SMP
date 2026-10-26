"""Restricted typed-IR projection; not a C23 compiler proof."""
import importlib.util
from pathlib import Path
SPEC={'module': 'allocation_ticket_handoff', 'namespace': 'AllocationTicketAst', 'fields': {'phase': 'int', 'ticket': 'int', 'owner': 'int', 'effect': 'int', 'calls': 'int', 'frees': 'int', 'reserved': 'int', 'sourceHold': 'int'}, 'actions': ['issue', 'metadataExhausted', 'invoke', 'cancelBeforeInvoke', 'allocatorNull', 'allocatorReturn', 'captureReturn', 'interruptUnrecordedReturn', 'allocatorOutcomeUnknown', 'commit', 'indexOutcomeUnknown', 'resolveCommitted', 'resolveAbsent', 'observeCommit', 'retryCommitQuery', 'requestPrivateAbort', 'invokePrivateFree', 'privateFreeKnown', 'privateFreeUnknown']}
def generate(ir):
 p=Path(__file__).with_name("chunk-capacity-charge-projection.py")
 s=importlib.util.spec_from_file_location("scalar",p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC["module"],SPEC["fields"],SPEC["actions"],SPEC["namespace"])
