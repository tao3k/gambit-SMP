"""Restricted typed scalar projection for the actual paired-model product."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'future_frame_activation', 'namespace': 'FrameActivationAst', 'fields': {'n_decision': 'int', 'n_claims': 'int', 'n_done': 'int', 'n_resultRoot': 'int', 'n_sourceRoot': 'int', 'n_destRoot': 'int', 'n_childRoot': 'int', 'n_copyReady': 'int', 'n_copyRev': 'int', 'n_viewRev': 'int', 'n_viewGen': 'int', 'n_viewLease': 'int', 'n_patchReady': 'int', 'n_patchRev': 'int', 'n_patchGen': 'int', 'n_patchLease': 'int', 'n_gate': 'int', 'n_admitted': 'int', 'n_generation': 'int', 'n_grantGen': 'int', 'n_lease': 'int', 'n_revision': 'int', 'n_sourceHeap': 'int', 'n_localGrants': 'int', 'n_remoteGrants': 'int', 'n_copyOps': 'int', 'n_validations': 'int', 'n_probes': 'int', 'p_phase': 'int', 'p_eligible': 'int', 'p_claims': 'int', 'p_probes': 'int', 'p_childRuns': 'int', 'p_childDone': 'int', 'p_sourceRoot': 'int', 'p_copyRoot': 'int', 'p_ready': 'int', 'p_queueRoot': 'int', 'p_restoreRoot': 'int', 'p_contextRoot': 'int', 'p_resultRoot': 'int', 'p_placeholder': 'int', 'p_materialized': 'int', 'p_split': 'int', 'p_parentOwner': 'int', 'p_prefixRuns': 'int', 'p_parentRuns': 'int', 'p_captured': 'int', 'p_captureRoot': 'int', 'p_exited': 'int', 'p_descriptor': 'int', 'p_gcOpen': 'int', 'p_frozen': 'int', 'p_scanning': 'int', 'p_scanned': 'int', 'p_epoch': 'int', 'p_vSource': 'int', 'p_vCopy': 'int', 'p_vQueue': 'int', 'p_vRestore': 'int', 'p_vContext': 'int', 'p_vResult': 'int', 'p_vCapture': 'int', 'p_resultPublished': 'int', 'publication': 'int', 'active': 'int', 'attempts': 'int'}, 'actions': ['reserve', 'allocate', 'enter', 'resolve', 'initialize', 'validate', 'prepare', 'sendPublication', 'publicationUnknown', 'acceptPublication', 'rejectPublication', 'commit', 'activationFailed', 'activate', 'wakeFailed', 'dequeue', 'restore', 'doneLocal', 'doneSplit', 'closeLocal', 'abort', 'finishAborted', 'publishResult', 'runPrefix', 'grantLocal', 'grantRemote', 'leave', 'gcEnter', 'gcFreeze', 'gcBegin', 'forwardNoCopy', 'forwardWithCopy', 'gcEnd', 'gcLeave', 'closeDomain', 'resetDomain']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_future_frame_activation_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
