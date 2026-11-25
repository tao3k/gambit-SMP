"""Restricted typed-IR extraction; no native-source refinement is inferred."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'image_membership_enrollment', 'namespace': 'ImageEnrollmentAst', 'fields': {'phase': 'int', 'epoch': 'int', 'vm1': 'int', 'incarnation': 'int', 'ticketEpoch': 'int', 'receiptEpoch0': 'int', 'receiptEpoch1': 'int', 'receiptInc1': 'int', 'users0': 'int', 'users1': 'int', 'observers': 'int', 'denied': 'int', 'helperKnown': 'bool', 'membersSealed': 'bool', 'mappingQualified': 'bool', 'ownedFacade': 'bool', 'rawEscape': 'bool', 'expected1': 'bool', 'closed0': 'bool', 'closed1': 'bool', 'receipt0': 'bool', 'receipt1': 'bool', 'externalDrained': 'bool'}, 'actions': ['enumerateHelper', 'sealMembers', 'prepareOwned', 'exposeRaw', 'reserveOwner', 'commitOpen', 'closeGlobal', 'commitClosing', 'abortReserved', 'unknownOwner', 'close0', 'close1', 'return0', 'return1', 'exitKnown', 'reuseBeforeClose', 'issue0', 'issue1', 'observe', 'retireObserver', 'borrow0', 'borrow1', 'rejectLate', 'rejectStale', 'unknownExternal', 'permit', 'invalidateMembership']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_image_membership_enrollment_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
