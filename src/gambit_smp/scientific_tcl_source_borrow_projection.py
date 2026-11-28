"""Restricted typed AST projection; no native C23 or slot-value proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'tcl_source_borrow', 'namespace': 'TclBorrowAst', 'fields': {'generation': 'int', 'tokenGeneration': 'int', 'storage': 'int', 'closed': 'int', 'scope': 'int', 'borrower': 'int', 'borrowCreated': 'int', 'borrowReleased': 'int', 'selected': 'int', 'current': 'int', 'oldRoot': 'int', 'newRoot': 'int', 'dest': 'int', 'destVersion': 'int', 'pending': 'int', 'acknowledged': 'int', 'replyLost': 'int', 'writer': 'int', 'gcClosed': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'epoch': 'int', 'viewOld': 'int', 'viewNew': 'int', 'viewDest': 'int', 'prepared': 'int', 'refused': 'int', 'otherOld': 'int', 'otherNew': 'int'}, 'actions': ['selectDispatch', 'acquireBorrow', 'refuseLateDispatch', 'refuseGcClosed', 'otherBorrowOld', 'otherBorrowNew', 'releaseOtherOld', 'releaseOtherNew', 'acquireWriter', 'prepareSetter', 'commitSetter', 'abortSetter', 'releaseWriter', 'revoke', 'publishDestination', 'loseReply', 'acknowledgeTransfer', 'dropOldVersion', 'dropRevokedRoots', 'leaveDispatch', 'freeSource', 'dropDestination', 'reuseStorage', 'selectNewToken', 'closeGcGate', 'freezeRoots', 'beginScan', 'endScan', 'resumeRoots']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_tcl_source_borrow_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
