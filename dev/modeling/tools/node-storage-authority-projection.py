"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'node_storage_authority', 'namespace': 'NodeStorageAuthorityAst', 'fields': {'stage': 'int', 'ownerReady': 'int', 'listVisible': 'int', 'layout': 'int', 'mapReady': 'int', 'coverage': 'int', 'aliasSeen': 'int', 'gate': 'int', 'metaLease': 'int', 'payloadLease': 'int', 'tailAuth': 'int', 'nodeRole': 'int', 'unknown': 'int', 'receipt': 'int', 'cacheLive': 'int', 'cacheGen': 'int', 'nodeAllocGen': 'int', 'queryGen': 'int', 'cleanupReady': 'int', 'opaqueSeen': 'int', 'currentSeen': 'int'}, 'actions': ['publishRawList', 'initializeOwner', 'attestDisjoint', 'bindNodeMap', 'sealReaderClosure', 'exposeAlias', 'revokeSeal', 'rejectAlias', 'acquireMetadata', 'returnMetadata', 'acquirePayload', 'returnPayload', 'knownHandoff', 'unknownHandoff', 'consumerAllocate', 'fixSourceLast', 'publishCompletion', 'closeAdmission', 'attestCleanup', 'retireCache', 'lookupOpaque', 'probeCurrentCache']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
