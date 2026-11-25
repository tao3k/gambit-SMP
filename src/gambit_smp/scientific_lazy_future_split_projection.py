"""Restricted typed AST projection; no native C23 or slot-value proof."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'lazy_future_split', 'namespace': 'LazySplitAst', 'fields': {'phase': 'int', 'eligible': 'int', 'claims': 'int', 'probes': 'int', 'childRuns': 'int', 'childDone': 'int', 'sourceRoot': 'int', 'copyRoot': 'int', 'ready': 'int', 'queueRoot': 'int', 'restoreRoot': 'int', 'contextRoot': 'int', 'resultRoot': 'int', 'placeholder': 'int', 'materialized': 'int', 'split': 'int', 'parentOwner': 'int', 'prefixRuns': 'int', 'parentRuns': 'int', 'captured': 'int', 'captureRoot': 'int', 'exited': 'int', 'descriptor': 'int', 'gcOpen': 'int', 'frozen': 'int', 'scanning': 'int', 'scanned': 'int', 'epoch': 'int', 'vSource': 'int', 'vCopy': 'int', 'vQueue': 'int', 'vRestore': 'int', 'vContext': 'int', 'vResult': 'int', 'vCapture': 'int', 'resultPublished': 'int'}, 'actions': ['denyParallelProfile', 'claimSplit', 'failedProbe', 'allocateCopy', 'initializeCopy', 'publishReady', 'commitSplit', 'abortPrivate', 'localChildDone', 'localAfterAbortDone', 'childDoneInSplit', 'dequeueParent', 'restoreParent', 'publishResult', 'runParentPrefix', 'consumeSplitResult', 'runLocalParent', 'captureAfterValue', 'restoreAfterValue', 'dropCaptured', 'exitParent', 'retireTaskRoots', 'retireDescriptor', 'closeGc', 'freezeRoots', 'beginScan', 'endScan', 'resumeGc']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_lazy_future_split_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
