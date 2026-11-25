"""Restricted typed AST projection; no native C23 or slot-value proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'dispatch_joint_admission', 'namespace': 'DispatchJointAst', 'fields': {'nativeOpen': 'int', 'storage': 'int', 'control': 'int', 'root': 'int', 'scope': 'int', 'others': 'int', 'selected': 'int', 'phase': 'int', 'pending': 'int', 'committed': 'int', 'known': 'int', 'refused': 'int', 'unknown': 'int', 'borrow': 'int', 'created': 'int', 'released': 'int', 'lease': 'int', 'rootAuth': 'int', 'nativeAuth': 'int', 'finished': 'int', 'delivered': 'int', 'dataReads': 'int', 'gcOpen': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'gcEpoch': 'int', 'viewRoot': 'int'}, 'actions': ['enterNative', 'enterOther', 'leaveOther', 'selectHandle', 'deleteCommand', 'reserveRoot', 'rejectBeforeReserve', 'commitJoint', 'rejectReservedDelete', 'abortPreparation', 'loseReply', 'resolveReservedAbort', 'ackCommit', 'readSelected', 'finishUse', 'retireBorrow', 'deliverOutcome', 'leaveScope', 'leaveEmptyScope', 'removeRoot', 'freeStorage', 'freeControl', 'closeGc', 'freezeRoots', 'beginScan', 'endScan', 'resumeGc']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_dispatch_joint_admission_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
