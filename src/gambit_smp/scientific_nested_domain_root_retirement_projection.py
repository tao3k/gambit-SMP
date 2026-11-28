"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'nested_domain_root_retirement', 'namespace': 'NestedDomainAst', 'fields': {'source': 'int', 'target': 'int', 'ack': 'int', 'pubReply': 'int', 'innerSource': 'int', 'innerTarget': 'int', 'innerAck': 'int', 'outerGuard': 'int', 'innerGuard': 'int', 'outerRight': 'int', 'innerRight': 'int', 'unwind': 'int', 'landed': 'int', 'captured': 'int', 'gcReader': 'int', 'descriptor': 'int', 'rootClosed': 'int', 'rootGrace': 'int', 'rootRetired': 'int', 'codeClosed': 'int', 'codeGrace': 'int', 'detached': 'int', 'outcome': 'int', 'shotGuard': 'int', 'shotTicket': 'int'}, 'actions': ['publishRoots', 'publicationReplyLost', 'publicationAbsentUnknown', 'resolvePublication', 'acknowledgeRoots', 'releaseSource', 'enterOuter', 'reserveInnerOffer', 'publishInnerRoots', 'acknowledgeInnerRoots', 'releaseInnerSource', 'enterInner', 'captureInner', 'startGcReader', 'finishGcReader', 'escrowOuterUnwind', 'issueOuterUnwind', 'landingObserved', 'landingReplyLost', 'reconcileLanding', 'settleInnerGuard', 'settleOuterGuard', 'resumeCaptured', 'rejectInnerReturn', 'finishResumption', 'closeCapturedHolders', 'closeRootAdmission', 'closeCodeAdmission', 'ackRootGrace', 'retireRootSlots', 'ackCodeGrace', 'retireDescriptor', 'detachNativeOwner']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_nested_domain_root_retirement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
