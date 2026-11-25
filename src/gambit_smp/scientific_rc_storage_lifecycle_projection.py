"""Restricted scalar projection; shared projector remains trusted."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'rc_storage_lifecycle', 'namespace': 'RcStorageAst', 'fields': {'phase': 'int', 'generation': 'int', 'operation': 'int', 'bytes': 'int', 'checked': 'int', 'owned': 'int', 'index': 'int', 'root': 'int', 'sourceHold': 'int', 'known': 'int', 'owner': 'int', 'contextClosing': 'int', 'contextGone': 'int', 'base': 'int', 'extra': 'int', 'extraSeen': 'int', 'borrow': 'int', 'scan': 'int', 'native': 'int', 'grace': 'int', 'effects': 'int', 'savedGeneration': 'int', 'keyGeneration': 'int', 'committed': 'int', 'oldResult': 'int', 'oldKnown': 'int', 'frees': 'int', 'rejections': 'int'}, 'actions': ['begin', 'beginZero', 'beginTooLarge', 'ticketFailure', 'checkSize', 'rejectSize', 'allocNull', 'allocSuccess', 'saveKey', 'reserveIndex', 'prepareRoot', 'publish', 'queryCommit', 'releaseSource', 'retainExtra', 'releaseExtra', 'releaseBase', 'borrow', 'returnBorrow', 'nativePin', 'nativeReturn', 'scan', 'finishScan', 'closeEntry', 'requestCleanup', 'handoffVM', 'exitContext', 'settleEffects', 'abortPrivate', 'unpublish', 'scanGrace', 'startFree', 'finishFree', 'loseFreeOutcome', 'reuseAddress', 'queryOld', 'rejectOldRelease']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_rc_storage_lifecycle_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        return m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
