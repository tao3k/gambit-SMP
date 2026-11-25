"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'node_storage_authority', 'namespace': 'NodeStorageAuthorityAst', 'fields': {'stage': 'int', 'ownerReady': 'int', 'listVisible': 'int', 'layout': 'int', 'mapReady': 'int', 'coverage': 'int', 'aliasSeen': 'int', 'gate': 'int', 'metaLease': 'int', 'payloadLease': 'int', 'tailAuth': 'int', 'nodeRole': 'int', 'unknown': 'int', 'receipt': 'int', 'cacheLive': 'int', 'cacheGen': 'int', 'nodeAllocGen': 'int', 'queryGen': 'int', 'cleanupReady': 'int', 'opaqueSeen': 'int', 'currentSeen': 'int'}, 'actions': ['publishRawList', 'initializeOwner', 'attestDisjoint', 'bindNodeMap', 'sealReaderClosure', 'exposeAlias', 'revokeSeal', 'rejectAlias', 'acquireMetadata', 'returnMetadata', 'acquirePayload', 'returnPayload', 'knownHandoff', 'unknownHandoff', 'consumerAllocate', 'fixSourceLast', 'publishCompletion', 'closeAdmission', 'attestCleanup', 'retireCache', 'lookupOpaque', 'probeCurrentCache']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_node_storage_authority_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
