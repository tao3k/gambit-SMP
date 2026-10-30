"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path
import importlib.util
SPEC={'module': 'image_membership_enrollment', 'namespace': 'ImageEnrollmentAst', 'fields': {'phase': 'int', 'epoch': 'int', 'vm1': 'int', 'incarnation': 'int', 'ticketEpoch': 'int', 'receiptEpoch0': 'int', 'receiptEpoch1': 'int', 'receiptInc1': 'int', 'users0': 'int', 'users1': 'int', 'observers': 'int', 'denied': 'int', 'helperKnown': 'bool', 'membersSealed': 'bool', 'mappingQualified': 'bool', 'ownedFacade': 'bool', 'rawEscape': 'bool', 'expected1': 'bool', 'closed0': 'bool', 'closed1': 'bool', 'receipt0': 'bool', 'receipt1': 'bool', 'externalDrained': 'bool'}, 'actions': ['enumerateHelper', 'sealMembers', 'prepareOwned', 'exposeRaw', 'reserveOwner', 'commitOpen', 'closeGlobal', 'commitClosing', 'abortReserved', 'unknownOwner', 'close0', 'close1', 'return0', 'return1', 'exitKnown', 'reuseBeforeClose', 'issue0', 'issue1', 'observe', 'retireObserver', 'borrow0', 'borrow1', 'rejectLate', 'rejectStale', 'unknownExternal', 'permit', 'invalidateMembership']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('frame_root_scalar_projection',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 return m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
