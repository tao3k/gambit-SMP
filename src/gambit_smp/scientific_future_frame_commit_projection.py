"""Restricted typed AST projection; no native C23 or slot-value proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'future_frame_commit', 'namespace': 'FrameCommitAst', 'fields': {'decision': 'int', 'claims': 'int', 'done': 'int', 'resultRoot': 'int', 'sourceRoot': 'int', 'destRoot': 'int', 'childRoot': 'int', 'copyReady': 'int', 'copyRev': 'int', 'viewRev': 'int', 'viewGen': 'int', 'viewLease': 'int', 'patchReady': 'int', 'patchRev': 'int', 'patchGen': 'int', 'patchLease': 'int', 'gate': 'int', 'admitted': 'int', 'generation': 'int', 'grantGen': 'int', 'lease': 'int', 'revision': 'int', 'sourceHeap': 'int', 'localGrants': 'int', 'remoteGrants': 'int', 'copyOps': 'int', 'validations': 'int', 'probes': 'int'}, 'actions': ['reserveSplit', 'childDone', 'closeLocal', 'allocateRootedCopy', 'enterRuntime', 'resolveCanonical', 'initializeCopy', 'validateCopy', 'prepareReturn', 'commitSplit', 'abortSplit', 'grantLocal', 'grantRemote', 'leaveRuntime', 'enterGc', 'forwardNoCopy', 'forwardWithCopy', 'leaveGc', 'closeDomain', 'resetDomain', 'failedProbe']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_future_frame_commit_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
