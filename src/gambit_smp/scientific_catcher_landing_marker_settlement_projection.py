"""Restricted typed-IR projection; not a C23 compiler proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'catcher_landing_marker_settlement', 'namespace': 'CatcherSettlementAst', 'fields': {'phase': 'int', 'prepared': 'int', 'escrow': 'int', 'issued': 'int', 'targetActive': 'int', 'errorClass': 'int', 'caught': 'int', 'current': 'int', 'validated': 'int', 'receipt': 'int', 'reply': 'int', 'refI': 'int', 'refO': 'int', 'doneI': 'int', 'doneO': 'int', 'effectsI': 'int', 'effectsO': 'int', 'critical': 'int', 'root': 'int', 'descriptor': 'int', 'captured': 'int', 'reader': 'int', 'copyReady': 'int', 'scanStage': 'int', 'slot': 'int', 'cache': 'int', 'borrow': 'int', 'version': 'int', 'shotActive': 'int', 'shotTicket': 'int', 'contextSlot': 'int', 'closed': 'int', 'rootRetired': 'int', 'grace': 'int', 'guard': 'int', 'unknown': 'int', 'leafPermit': 'int', 'validI': 'int', 'validO': 'int'}, 'actions': ['prepareFirst', 'prepareSecond', 'rollbackPartial', 'rollbackReady', 'preparationUnknown', 'auditPreparation', 'publishEscrow', 'escrowReplyLost', 'queryEscrow', 'issueTransfer', 'issueOtherError', 'catchInner', 'restoreInnerCatcher', 'catchOuter', 'restoreOuterCatcher', 'borrowFresh', 'releaseBorrow', 'validateLanding', 'publishLanding', 'landingReplyLost', 'queryLanding', 'beginInnerRelease', 'decrementInner', 'commitInnerRelease', 'innerReplyLost', 'queryInnerRelease', 'nativeTargetReturned', 'beginOuterRelease', 'decrementOuter', 'commitOuterRelease', 'outerReplyLost', 'queryOuterRelease', 'settleGuards', 'resumeCaptured', 'finishResumption', 'dropCaptured', 'startGc', 'rewriteRootOnly', 'rewriteRegistryFirst', 'rewriteContextSlot', 'initializeCopiedObject', 'finishGc', 'closeRootAdmission', 'retireRoots', 'ackDescriptorGrace', 'retireDescriptor']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_catcher_landing_marker_settlement_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
