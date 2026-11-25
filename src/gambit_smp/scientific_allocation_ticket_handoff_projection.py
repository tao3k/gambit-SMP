"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'allocation_ticket_handoff', 'namespace': 'AllocationTicketAst', 'fields': {'phase': 'int', 'ticket': 'int', 'owner': 'int', 'effect': 'int', 'calls': 'int', 'frees': 'int', 'reserved': 'int', 'sourceHold': 'int'}, 'actions': ['issue', 'metadataExhausted', 'invoke', 'cancelBeforeInvoke', 'allocatorNull', 'allocatorReturn', 'captureReturn', 'interruptUnrecordedReturn', 'allocatorOutcomeUnknown', 'commit', 'indexOutcomeUnknown', 'resolveCommitted', 'resolveAbsent', 'observeCommit', 'retryCommitQuery', 'requestPrivateAbort', 'invokePrivateFree', 'privateFreeKnown', 'privateFreeUnknown']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_allocation_ticket_handoff_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
