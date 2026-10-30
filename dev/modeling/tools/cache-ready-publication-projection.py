"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'cache_ready_publication', 'namespace': 'CacheReadyPublicationAst', 'fields': {'stage': 'int', 'owned': 'int', 'busy': 'int', 'owner': 'int', 'tls': 'int', 'fast': 'int', 'listed': 'int', 'ready': 'int', 'ack': 'int', 'builder': 'int', 'readerPin': 'int', 'diagPin': 'int', 'diagState': 'int', 'snapshot': 'int', 'statsOK': 'int', 'formatted': 'int', 'rollbackUnknown': 'int', 'pendingSeen': 'int', 'cleanupOK': 'int', 'generation': 'int', 'snapshotGen': 'int', 'allocations': 'int'}, 'actions': ['reserveConstruction', 'allocateCandidate', 'allocationRejected', 'initializeOwner', 'installTlsKnown', 'installTlsUnknown', 'stageRegistryEntry', 'publishKnown', 'publishUnknownCommitted', 'publishUnknownAbsent', 'rejectPublication', 'reconcileCommitted', 'reconcileAbsent', 'finishBuilder', 'publishFastHandle', 'constructionReentry', 'closingReentry', 'acquireReader', 'releaseReader', 'qualifyStats', 'beginDiagnostic', 'requestOwnerSnapshot', 'ownerSnapshotAck', 'releaseDiagnosticPin', 'formatSnapshot', 'closeReady', 'unlinkEntry', 'clearTlsKnown', 'clearFastKnown', 'attestNativeCleanup', 'retireKnown', 'rollbackUnknown', 'rollbackKnown']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
