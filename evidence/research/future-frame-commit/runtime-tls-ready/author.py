from pathlib import Path
import json
r=Path.cwd();b=r/'dev/refactoring/modern-c';c=r/'.cache/tasks/future-frame-commit/runtime-tls-ready'
F=dict(g=4,locks=1,tables=1,genericKey=1,allocKey=2,initOwner=1,bootPin=1,cache=4,tls=2,fast=1,owner=1,usePin=1,finalizer=1,late=1,roster=1,observed=1,epoch=2,reentrySeen=1,rawSeen=1)
I={k:0 for k in F};I['epoch']=1
A=[]
def a(n,g,u,s):A.append((n,g,u,s))
a('reserveRuntime','s.g==0',dict(g=1,initOwner=1),'global-init')
a('initializeLocks','s.g==1 and s.locks==0',dict(locks=1),'static-bootstrap')
a('initializeTables','s.g==1 and s.locks==1 and s.tables==0',dict(tables=1),'bucket-init')
a('createGenericKey','s.g==1 and s.genericKey==0',dict(genericKey=1),'generic-key')
a('createAllocKeyKnown','s.g==1 and s.allocKey==0',dict(allocKey=1),'unix-key')
a('createAllocKeyUnknown','s.g==1 and s.allocKey==0',dict(allocKey=2),'unix-key')
a('bootstrapBorrow','s.g==1 and s.locks==1 and s.bootPin==0',dict(bootPin=1),'init-reentry')
a('bootstrapReturn','s.bootPin==1',dict(bootPin=0),'init-reentry')
a('initializationReentry','s.g==1 and s.reentrySeen==0',dict(reentrySeen=1),'init-reentry')
a('publishRuntime','s.g==1 and s.locks==1 and s.tables==1 and s.genericKey==1 and s.allocKey==1 and s.bootPin==0',dict(g=2,initOwner=0),'global-init')
a('observeRuntime','s.g==2 and s.observed==0',dict(observed=1),'plain-flags')
a('beginCacheInstall','s.g==2 and s.observed==1 and s.cache==0',dict(cache=1,owner=1),'unix-set')
a('rawSetterReturned','s.cache==1 and s.tls==0 and s.rawSeen==0',dict(rawSeen=1),'unix-set')
a('recordKnownInstall','s.cache==1 and s.tls==0',dict(tls=1),'checked-set')
a('installUnknown','s.cache==1 and s.tls==0',dict(tls=2),'unix-set')
a('publishCache','s.g==2 and s.cache==1 and s.tls==1',dict(cache=2),'fast-slot')
a('publishFast','s.g==2 and s.cache==2 and s.fast==0',dict(fast=1),'fast-slot')
a('acquireNormal','s.g==2 and s.cache==2 and s.observed==1 and s.usePin==0',dict(usePin=1),'fast-slot')
a('releaseNormal','s.usePin==1',dict(usePin=0),'thread-exit')
a('admitFinalizer','s.g==2 and s.cache==2 and s.finalizer==0',dict(finalizer=1),'exit-callback')
a('beginGlobalClose','s.g==2',dict(g=3),'process-finalize')
a('deriveLateTsdWork','s.g==3 and s.cache==2 and s.finalizer==1 and s.late==0',dict(late=1),'tsd-recreate')
a('drainLateTsdWork','s.g==3 and s.finalizer==1 and s.late==1',dict(late=0),'tsd-recreate')
a('finishFinalizer','s.g==3 and s.finalizer==1 and s.late==0',dict(finalizer=0),'exit-callback')
a('closeCache','s.g==3 and s.cache==2 and s.finalizer==0 and s.late==0',dict(cache=3),'thread-exit')
a('clearFastKnown','s.cache==3 and s.usePin==0 and s.fast==1',dict(fast=0),'fast-slot')
a('clearTlsKnown','s.cache==3 and s.usePin==0 and s.tls==1',dict(tls=0),'unix-clear')
a('clearTlsUnknown','s.cache==3 and s.usePin==0 and s.tls==1',dict(tls=2),'unix-clear')
a('freeCacheKnown','s.cache==3 and s.tls==0 and s.fast==0 and s.usePin==0 and s.owner==1',dict(cache=4,owner=0),'free-before-clear')
a('attestRosterClosed','s.g==3 and s.cache==4 and s.owner==0 and s.usePin==0 and s.finalizer==0 and s.late==0 and s.roster==0',dict(roster=1),'all-threads')
a('deleteGenericKey','s.g==3 and s.roster==1 and s.genericKey==1',dict(genericKey=0),'generic-key-delete')
a('deleteAllocKeyKnown','s.g==3 and s.roster==1 and s.allocKey==1',dict(allocKey=0),'unix-key-delete')
a('deleteAllocKeyUnknown','s.g==3 and s.roster==1 and s.allocKey==1',dict(allocKey=2),'unix-key-delete')
a('freeGlobalLocks','s.g==3 and s.roster==1 and s.genericKey==0 and s.allocKey==0 and s.cache==4 and s.bootPin==0',dict(locks=0,tables=0),'allocator-finalize')
a('retireRuntime','s.g==3 and s.roster==1 and s.genericKey==0 and s.allocKey==0 and s.cache==4 and s.locks==0 and s.tables==0',dict(g=4,epoch=2),'allocator-finalize')
V=[f'all{{s.{k}>=0,s.{k}<={v}}}' for k,v in F.items()]
V+=['s.epoch>=1','s.g==0 implies all{s.locks==0,s.tables==0,s.genericKey==0,s.allocKey==0,s.initOwner==0,s.cache==0,s.observed==0}',
's.g==1 implies all{s.initOwner==1,s.cache==0,s.observed==0,s.roster==0}',
's.g==2 implies all{s.locks==1,s.tables==1,s.genericKey==1,s.allocKey==1,s.initOwner==0,s.roster==0}',
's.g>=2 implies s.initOwner==0','s.g==4 implies all{s.cache==4,s.locks==0,s.tables==0,s.allocKey==0,s.genericKey==0,s.roster==1,s.epoch==2}',
's.g!=4 implies s.epoch==1','s.tables==1 implies s.locks==1','s.bootPin==1 implies all{s.g==1,s.locks==1}',
's.cache==0 implies all{s.tls==0,s.fast==0,s.owner==0,s.usePin==0,s.finalizer==0,s.late==0,s.rawSeen==0}',
's.cache>=1 implies all{s.g>=2,s.observed==1}',
's.cache>=1 and s.cache<=3 implies s.owner==1',
's.cache==1 implies all{s.g==2,s.fast==0,s.usePin==0,s.finalizer==0,s.late==0}',
's.cache==2 implies all{(s.g==2 or s.g==3),s.tls==1}',
's.cache==3 implies all{s.g==3,s.finalizer==0,s.late==0}',
's.cache==4 implies all{s.g>=3,s.tls==0,s.fast==0,s.owner==0,s.usePin==0,s.finalizer==0,s.late==0}',
's.tls==2 implies all{(s.cache==1 or s.cache==3),s.owner==1}',
's.usePin==1 implies all{(s.cache==2 or s.cache==3),s.owner==1,s.tls==1}',
's.finalizer==1 implies all{s.cache==2,s.owner==1}',
's.late==1 implies all{s.g==3,s.cache==2,s.finalizer==1}',
's.roster==1 implies all{s.g>=3,s.cache==4,s.owner==0,s.usePin==0,s.finalizer==0,s.late==0}',
's.allocKey==2 implies (s.g==1 or s.g==3)',
's.g<=1 implies all{s.roster==0,s.finalizer==0,s.late==0}',
's.observed==1 implies s.g>=2']
q='module runtime_tls_ready {\n// Single admitted owner/epoch; native outcome receipts and all-owner roster are premises.\ntype State={'+','.join(k+':int' for k in F)+'}\n'
q+="pure val initial:State={"+','.join(k+':'+str(v) for k,v in I.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(V)+"}\n"
for n,g,u,src in A:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(n for n,g,u,src in A)+",all{s'=s}}\n"
pre='init.then(reserveRuntime).then(initializeLocks).then(initializeTables).then(createGenericKey).then(createAllocKeyKnown)'
run=pre+'.then(publishRuntime).then(observeRuntime)';bind=run+'.then(beginCacheInstall).then(recordKnownInstall).then(publishCache)'
closed=bind+'.then(publishFast).then(beginGlobalClose).then(closeCache).then(clearFastKnown).then(clearTlsKnown).then(freeCacheKnown).then(attestRosterClosed)'
end=".then(all{assert(safe),s'=s})\n"
H=[('normal',closed+'.then(deleteGenericKey).then(deleteAllocKeyKnown).then(freeGlobalLocks).then(retireRuntime)'),('bootstrapReentry',pre+'.then(bootstrapBorrow).then(initializationReentry).then(bootstrapReturn).then(publishRuntime)'),('unknownKey','init.then(reserveRuntime).then(initializeLocks).then(createAllocKeyUnknown)'),('rawReturn',run+'.then(beginCacheInstall).then(rawSetterReturned)'),('unknownInstall',run+'.then(beginCacheInstall).then(installUnknown)'),('lateCleanup',bind+'.then(admitFinalizer).then(beginGlobalClose).then(deriveLateTsdWork).then(drainLateTsdWork).then(finishFinalizer).then(closeCache)'),('unknownClear',bind+'.then(beginGlobalClose).then(closeCache).then(clearTlsUnknown)'),('unknownDelete',closed+'.then(deleteGenericKey).then(deleteAllocKeyUnknown)'),('pinDrains',bind+'.then(acquireNormal).then(beginGlobalClose).then(closeCache).then(releaseNormal).then(clearTlsKnown).then(freeCacheKnown)')]
for n,p in H:q+='run '+n+'Test='+p+end
G={n:g for n,g,u,src in A};N=[('partialNotReady','init.then(reserveRuntime).then(initializeLocks)','publishRuntime'),('borrowNotFullReady',pre+'.then(bootstrapBorrow)','publishRuntime'),('rawNotInstalled',run+'.then(beginCacheInstall).then(rawSetterReturned)','publishCache'),('unknownInstallNoReady',run+'.then(beginCacheInstall).then(installUnknown)','publishCache'),('lateWorkBlocksClose',bind+'.then(admitFinalizer).then(beginGlobalClose).then(deriveLateTsdWork)','closeCache'),('fastBlocksFree',bind+'.then(publishFast).then(beginGlobalClose).then(closeCache).then(clearTlsKnown)','freeCacheKnown'),('closedNoNormal',bind+'.then(publishFast).then(beginGlobalClose)','acquireNormal'),('unknownClearNoFree',bind+'.then(beginGlobalClose).then(closeCache).then(clearTlsUnknown)','freeCacheKnown'),('unknownKeyNoLocks',closed+'.then(deleteGenericKey).then(deleteAllocKeyUnknown)','freeGlobalLocks')]
for n,p,a0 in N:q+='run '+n+'Test='+p+".then(all{assert(not("+G[a0]+")),assert(safe),s'=s})\n"
q+='}\n';(b/'models/quint/runtime_tls_ready.qnt').write_text(q)
pr=(r/'dev/modeling/tools/cache-ready-publication-projection.py').read_text();i=pr.index('SPEC = ');j=pr.index('\ndef generate',i);pr=pr[:i]+'SPEC = '+repr(dict(module='runtime_tls_ready',namespace='RuntimeTlsReadyAst',fields={k:'int' for k in F},actions=[n for n,g,u,src in A]))+pr[j:];(r/'dev/modeling/tools/runtime-tls-ready-projection.py').write_text(pr)
(c/'author-data.json').write_text(json.dumps(dict(actions=A,bounds=len(F),invariants=len(V),pre=pre,run=run,bind=bind,closed=closed)))
print('fields/actions/invariants',len(F),len(A),len(V))
