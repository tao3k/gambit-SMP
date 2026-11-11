"""RC-reader-grace typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'escrow_critical_tail', 'namespace': 'EscrowCriticalTailAst', 'fields': {'stage': 'int', 'free': 'int', 'slot': 'int', 'external': 'int', 'registered': 'int', 'queued': 'int', 'cancel': 'int', 'supervisor': 'int', 'lock': 'int', 'pin': 'int', 'tailQualified': 'int', 'nodeReceipt': 'int'}, 'actions': ['disableCancel', 'exhaustPool', 'returnExternalSlot', 'claimSlot', 'releaseUnpublishedSlot', 'registerKnown', 'registerUnknown', 'reconcileRegistration', 'popKnownEscrow', 'escapeToken', 'knownTokenEndpoint', 'qualifyNodeTail', 'completeQualifiedNodeTail', 'unknownNodeCompletion', 'knownNodeBackendReceipt', 'publishDone', 'acquireMap', 'issuePin', 'unlockMap', 'escapeHoldingMap', 'knownOwnerLanding', 'returnPinKnown', 'returnPinUnknown', 'knownPinReturnLanding', 'handoffSupervisor', 'beginRestoreCancel', 'knownRestoreReturn', 'retireSlot']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
