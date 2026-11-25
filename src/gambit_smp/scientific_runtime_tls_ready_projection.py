"""PutObjs custody typed-IR projection; no native refinement claim."""
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science.Path = Path
        _science.SPEC = {'module': 'runtime_tls_ready', 'namespace': 'RuntimeTlsReadyAst', 'fields': {'g': 'int', 'locks': 'int', 'tables': 'int', 'genericKey': 'int', 'allocKey': 'int', 'initOwner': 'int', 'bootPin': 'int', 'cache': 'int', 'tls': 'int', 'fast': 'int', 'owner': 'int', 'usePin': 'int', 'finalizer': 'int', 'late': 'int', 'roster': 'int', 'observed': 'int', 'epoch': 'int', 'reentrySeen': 'int', 'rawSeen': 'int', 'cacheEpoch': 'int', 'fastEpoch': 'int', 'requestEpoch': 'int'}, 'actions': ['beginThreadClose', 'rebindCache', 'refreshHandle', 'closeEmptyOwner', 'reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'createAllocKeyUnknown', 'bootstrapBorrow', 'bootstrapReturn', 'initializationReentry', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'rawSetterReturned', 'recordKnownInstall', 'installUnknown', 'publishCache', 'publishFast', 'acquireNormal', 'releaseNormal', 'admitFinalizer', 'beginGlobalClose', 'deriveLateTsdWork', 'drainLateTsdWork', 'finishFinalizer', 'closeCache', 'clearFastKnown', 'clearTlsKnown', 'clearTlsUnknown', 'freeCacheKnown', 'attestRosterClosed', 'deleteGenericKey', 'deleteAllocKeyKnown', 'deleteAllocKeyUnknown', 'freeGlobalLocks', 'retireRuntime']}
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def generate(_science, ir):
        p = Path(str(_science.context.root / 'src/gambit_smp/scientific_runtime_tls_ready_projection.py')).with_name('chunk-capacity-charge-projection.py')
        m = _science.context.library('chunk_capacity_charge_projection')
        a, r = m.generate(ir, _science.SPEC['module'], _science.SPEC['fields'], _science.SPEC['actions'], _science.SPEC['namespace'])
        r.pop('c11Refinement', None)
        r['c23Refinement'] = False
        return (a, r)
