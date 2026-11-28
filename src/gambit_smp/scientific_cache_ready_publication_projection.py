"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'cache_ready_publication', 'namespace': 'CacheReadyPublicationAst', 'fields': {'stage': 'int', 'owned': 'int', 'busy': 'int', 'owner': 'int', 'tls': 'int', 'fast': 'int', 'listed': 'int', 'ready': 'int', 'ack': 'int', 'builder': 'int', 'readerPin': 'int', 'diagPin': 'int', 'diagState': 'int', 'snapshot': 'int', 'statsOK': 'int', 'formatted': 'int', 'rollbackUnknown': 'int', 'pendingSeen': 'int', 'cleanupOK': 'int', 'generation': 'int', 'snapshotGen': 'int', 'allocations': 'int'}, 'actions': ['reserveConstruction', 'allocateCandidate', 'allocationRejected', 'initializeOwner', 'installTlsKnown', 'installTlsUnknown', 'stageRegistryEntry', 'publishKnown', 'publishUnknownCommitted', 'publishUnknownAbsent', 'rejectPublication', 'reconcileCommitted', 'reconcileAbsent', 'finishBuilder', 'publishFastHandle', 'constructionReentry', 'closingReentry', 'acquireReader', 'releaseReader', 'qualifyStats', 'beginDiagnostic', 'requestOwnerSnapshot', 'ownerSnapshotAck', 'releaseDiagnosticPin', 'formatSnapshot', 'closeReady', 'unlinkEntry', 'clearTlsKnown', 'clearFastKnown', 'attestNativeCleanup', 'retireKnown', 'rollbackUnknown', 'rollbackKnown']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_cache_ready_publication_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
