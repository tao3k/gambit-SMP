"""RC-reader-grace typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'escrow_critical_tail', 'namespace': 'EscrowCriticalTailAst', 'fields': {'stage': 'int', 'free': 'int', 'slot': 'int', 'external': 'int', 'registered': 'int', 'queued': 'int', 'cancel': 'int', 'supervisor': 'int', 'lock': 'int', 'pin': 'int', 'tailQualified': 'int', 'nodeReceipt': 'int'}, 'actions': ['disableCancel', 'exhaustPool', 'returnExternalSlot', 'claimSlot', 'releaseUnpublishedSlot', 'registerKnown', 'registerUnknown', 'reconcileRegistration', 'popKnownEscrow', 'escapeToken', 'knownTokenEndpoint', 'qualifyNodeTail', 'completeQualifiedNodeTail', 'unknownNodeCompletion', 'knownNodeBackendReceipt', 'publishDone', 'acquireMap', 'issuePin', 'unlockMap', 'escapeHoldingMap', 'knownOwnerLanding', 'returnPinKnown', 'returnPinUnknown', 'knownPinReturnLanding', 'handoffSupervisor', 'beginRestoreCancel', 'knownRestoreReturn', 'retireSlot']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_escrow_critical_tail_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
