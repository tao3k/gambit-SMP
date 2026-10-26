"""PutObjs custody typed-IR projection; no native refinement claim."""
import importlib.util
from pathlib import Path
SPEC = {'module': 'runtime_tls_ready', 'namespace': 'RuntimeTlsReadyAst', 'fields': {'g': 'int', 'locks': 'int', 'tables': 'int', 'genericKey': 'int', 'allocKey': 'int', 'initOwner': 'int', 'bootPin': 'int', 'cache': 'int', 'tls': 'int', 'fast': 'int', 'owner': 'int', 'usePin': 'int', 'finalizer': 'int', 'late': 'int', 'roster': 'int', 'observed': 'int', 'epoch': 'int', 'reentrySeen': 'int', 'rawSeen': 'int', 'cacheEpoch': 'int', 'fastEpoch': 'int', 'requestEpoch': 'int'}, 'actions': ['beginThreadClose', 'rebindCache', 'refreshHandle', 'closeEmptyOwner', 'reserveRuntime', 'initializeLocks', 'initializeTables', 'createGenericKey', 'createAllocKeyKnown', 'createAllocKeyUnknown', 'bootstrapBorrow', 'bootstrapReturn', 'initializationReentry', 'publishRuntime', 'observeRuntime', 'beginCacheInstall', 'rawSetterReturned', 'recordKnownInstall', 'installUnknown', 'publishCache', 'publishFast', 'acquireNormal', 'releaseNormal', 'admitFinalizer', 'beginGlobalClose', 'deriveLateTsdWork', 'drainLateTsdWork', 'finishFinalizer', 'closeCache', 'clearFastKnown', 'clearTlsKnown', 'clearTlsUnknown', 'freeCacheKnown', 'attestRosterClosed', 'deleteGenericKey', 'deleteAllocKeyKnown', 'deleteAllocKeyUnknown', 'freeGlobalLocks', 'retireRuntime']}
def generate(ir):
 p=Path(__file__).with_name('chunk-capacity-charge-projection.py')
 s=importlib.util.spec_from_file_location('scalar',p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m)
 a,r=m.generate(ir,SPEC['module'],SPEC['fields'],SPEC['actions'],SPEC['namespace'])
 r.pop('c11Refinement',None);r['c23Refinement']=False
 return a,r
