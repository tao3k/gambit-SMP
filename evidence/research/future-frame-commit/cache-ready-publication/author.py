from pathlib import Path
import json
r=Path.cwd();b=r/'dev/refactoring/modern-c';c=r/'.cache/tasks/future-frame-commit/cache-ready-publication'
F=dict(stage=10,owned=1,busy=1,owner=1,tls=2,fast=1,listed=1,ready=1,ack=3,builder=1,readerPin=1,diagPin=1,diagState=5,snapshot=1,statsOK=1,formatted=1,rollbackUnknown=1,pendingSeen=1,cleanupOK=1,generation=2,snapshotGen=1,allocations=1)
I={k:0 for k in F};I.update(builder=1,generation=1)
A=[]
def a(n,g,u,s):A.append((n,g,u,s))
a('reserveConstruction','s.stage==0',dict(stage=1,busy=1),'tls-read')
a('allocateCandidate','s.stage==1 and s.allocations==0',dict(stage=2,owned=1,allocations=1),'cache-allocate')
a('allocationRejected','s.stage==1 and s.allocations==0',dict(stage=9,ack=3),'cache-panic')
a('initializeOwner','s.stage==2',dict(stage=3,owner=1),'cache-owner')
a('installTlsKnown','s.stage==3 and s.tls==0',dict(stage=4,tls=1),'tls-write')
a('installTlsUnknown','s.stage==3 and s.tls==0',dict(tls=2),'tls-write')
a('stageRegistryEntry','s.stage==4',dict(stage=5,listed=1),'list-publish')
a('publishKnown','s.stage==5 and s.ack==0',dict(stage=6,ready=1,ack=1),'list-publish')
a('publishUnknownCommitted','s.stage==5 and s.ack==0',dict(stage=6,ready=1,ack=2),'list-publish')
a('publishUnknownAbsent','s.stage==5 and s.ack==0',dict(ack=2),'list-publish')
a('rejectPublication','s.stage==5 and s.ack==0',dict(stage=9,ack=3),'list-publish')
a('reconcileCommitted','(s.stage==6 or s.stage==7) and s.ack==2',dict(ack=1),'prior')
a('reconcileAbsent','s.stage==5 and s.ack==2',dict(stage=9,ack=3),'prior')
a('finishBuilder','(s.stage==6 or s.stage==7) and s.ack==1 and s.builder==1',dict(builder=0),'prior')
a('publishFastHandle','s.stage==6 and s.ready==1 and s.fast==0',dict(fast=1),'fast-slot')
a('constructionReentry','s.stage>=1 and s.stage<=5 and s.busy==1 and s.ready==0 and s.pendingSeen==0',dict(pendingSeen=1),'tls-read')
a('closingReentry','s.stage==7 and s.ready==0 and s.pendingSeen==0',dict(pendingSeen=1),'tls-cleanup')
a('acquireReader','s.stage==6 and s.ready==1 and s.readerPin==0',dict(readerPin=1),'fast-slot')
a('releaseReader','s.readerPin==1',dict(readerPin=0),'prior')
a('qualifyStats','s.stage==6 and s.statsOK==0',dict(statsOK=1),'stats-read')
a('beginDiagnostic','s.stage==6 and s.ready==1 and s.statsOK==1 and s.diagState==0',dict(diagState=1,diagPin=1),'diagnostic-lock')
a('requestOwnerSnapshot','s.diagState==1',dict(diagState=2),'stats-read')
a('ownerSnapshotAck','s.diagState==2 and s.statsOK==1',dict(diagState=3,snapshot=1,snapshotGen=1),'stats-read')
a('releaseDiagnosticPin','s.diagState==3 and s.snapshot==1',dict(diagState=4,diagPin=0),'diagnostic-callout')
a('formatSnapshot','s.diagState==4 and s.snapshot==1 and s.formatted==0',dict(diagState=5,formatted=1),'diagnostic-callout')
a('closeReady','s.stage==6',dict(stage=7,ready=0),'tls-cleanup')
a('unlinkEntry','(s.stage==7 or s.stage==9) and s.listed==1',dict(listed=0),'list-unlink')
a('clearTlsKnown','(s.stage==7 or s.stage==9) and s.tls==1 and s.readerPin==0 and s.diagPin==0',dict(tls=0),'tls-cleanup')
a('clearFastKnown','s.stage==7 and s.fast==1 and s.readerPin==0 and s.diagPin==0',dict(fast=0),'fast-slot')
clean='s.stage==7 and s.builder==0 and s.ack==1 and s.readerPin==0 and s.diagPin==0 and s.tls==0 and s.fast==0 and s.listed==0 and s.rollbackUnknown==0'
a('attestNativeCleanup',clean+' and s.cleanupOK==0',dict(cleanupOK=1),'cache-free')
a('retireKnown',clean+' and s.cleanupOK==1',dict(stage=8,owned=0,busy=0,generation=2),'cache-free')
rb='s.stage==9 and s.ack==3 and s.listed==0 and s.tls==0 and s.fast==0 and s.readerPin==0 and s.diagPin==0 and s.rollbackUnknown==0'
a('rollbackUnknown',rb,dict(rollbackUnknown=1),'cache-free')
a('rollbackKnown',rb,dict(stage=10,owned=0,busy=0,builder=0),'cache-free')
V=[f'all{{s.{k}>=0,s.{k}<={v}}}' for k,v in F.items()]
V+=['s.generation>=1','s.stage==0 implies all{s.owned==0,s.busy==0,s.owner==0,s.tls==0,s.listed==0,s.ready==0,s.ack==0,s.allocations==0}',
's.stage>=1 and s.stage<=7 implies s.busy==1','s.stage==9 implies s.busy==1',
's.stage==1 implies all{s.owned==0,s.owner==0,s.tls==0,s.listed==0,s.ready==0,s.ack==0,s.allocations==0}',
's.stage>=2 and s.stage<=7 implies all{s.owned==1,s.allocations==1}',
's.stage==2 implies all{s.owner==0,s.tls==0,s.listed==0,s.ready==0,s.ack==0}',
's.stage>=3 and s.stage<=7 implies s.owner==1',
's.stage==3 implies all{s.tls!=1,s.listed==0,s.ready==0,s.ack==0}',
's.stage==4 implies all{s.tls==1,s.listed==0,s.ready==0,s.ack==0}',
's.stage==5 implies all{s.tls==1,s.listed==1,s.ready==0,(s.ack==0 or s.ack==2)}',
's.stage==6 implies all{s.ready==1,s.owned==1,s.owner==1,s.tls==1,s.listed==1,(s.ack==1 or s.ack==2)}',
's.ready==1 implies s.stage==6','s.stage==7 implies all{s.ready==0,(s.ack==1 or s.ack==2)}',
's.stage==8 implies all{s.owned==0,s.busy==0,s.ready==0,s.ack==1,s.builder==0,s.readerPin==0,s.diagPin==0,s.tls==0,s.fast==0,s.listed==0,s.cleanupOK==1,s.generation==2}',
's.stage==9 implies all{s.ready==0,s.ack==3,s.builder==1,s.readerPin==0,s.diagPin==0,s.diagState==0,s.fast==0}',
's.stage==10 implies all{s.owned==0,s.busy==0,s.ready==0,s.builder==0,s.readerPin==0,s.diagPin==0,s.tls==0,s.fast==0,s.listed==0,s.ack==3}',
's.stage!=8 implies s.generation==1',
's.stage<=5 implies all{s.builder==1,s.readerPin==0,s.diagPin==0,s.diagState==0,s.fast==0,s.cleanupOK==0}',
's.ack==2 implies all{s.builder==1,(s.stage==5 or s.stage==6 or s.stage==7)}',
's.tls==2 implies all{s.stage==3,s.owned==1,s.builder==1,s.ready==0}',
's.readerPin==1 implies all{(s.stage==6 or s.stage==7),s.owned==1,s.tls==1}',
's.diagPin==1 implies all{(s.stage==6 or s.stage==7),s.owned==1,s.tls==1,s.diagState>=1,s.diagState<=3}',
's.diagState>=1 and s.diagState<=3 implies s.diagPin==1',
's.diagState==0 implies all{s.diagPin==0,s.snapshot==0,s.snapshotGen==0,s.formatted==0}',
'(s.diagState==1 or s.diagState==2) implies all{s.snapshot==0,s.snapshotGen==0,s.formatted==0}',
's.diagState>=3 implies all{s.snapshot==1,s.snapshotGen==1}',
's.diagState>=4 implies s.diagPin==0',
's.diagState==5 implies s.formatted==1','s.formatted==1 implies all{s.diagState==5,s.diagPin==0}',
's.snapshot==1 implies s.diagState>=3',
's.cleanupOK==1 implies all{(s.stage==7 or s.stage==8),s.builder==0,s.ack==1,s.readerPin==0,s.diagPin==0,s.tls==0,s.fast==0,s.listed==0}',
's.rollbackUnknown==1 implies all{s.stage==9,s.ready==0,s.builder==1,s.listed==0,s.tls==0,s.fast==0}',
's.stage<=5 implies s.statsOK==0','s.stage==9 or s.stage==10 implies s.statsOK==0']
q='module cache_ready_publication {\n// RuntimeServiceReady and pre-reserved NativeThreadDomain guard are external premises.\ntype State={'+','.join(k+':int' for k in F)+'}\n'
q+="pure val initial:State={"+','.join(k+':'+str(v) for k,v in I.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(V)+"}\n"
for n,g,u,src in A:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(n for n,g,u,src in A)+",all{s'=s}}\n"
pre='init.then(reserveConstruction).then(allocateCandidate).then(initializeOwner).then(installTlsKnown).then(stageRegistryEntry)'
pub=pre+'.then(publishKnown).then(finishBuilder)';close=pub+'.then(closeReady).then(unlinkEntry).then(clearTlsKnown).then(attestNativeCleanup).then(retireKnown)'
snap='qualifyStats.then(beginDiagnostic).then(requestOwnerSnapshot).then(ownerSnapshotAck).then(releaseDiagnosticPin)'
end=".then(all{assert(safe),s'=s})\n"
H=[('known',pub),('earlyReentry','init.then(reserveConstruction).then(constructionReentry).then(allocateCandidate)'),('unknownTls','init.then(reserveConstruction).then(allocateCandidate).then(initializeOwner).then(installTlsUnknown).then(constructionReentry)'),('unknownCommitted',pre+'.then(publishUnknownCommitted).then(acquireReader).then(releaseReader).then(reconcileCommitted).then(finishBuilder)'),('unknownAbsent',pre+'.then(publishUnknownAbsent).then(constructionReentry).then(reconcileAbsent).then(unlinkEntry).then(clearTlsKnown).then(rollbackKnown)'),('rejected',pre+'.then(rejectPublication).then(unlinkEntry).then(clearTlsKnown).then(rollbackKnown)'),('unknownRollback',pre+'.then(rejectPublication).then(unlinkEntry).then(clearTlsKnown).then(rollbackUnknown)'),('lateFormat',pub+'.then('+snap+').then(closeReady).then(unlinkEntry).then(clearTlsKnown).then(attestNativeCleanup).then(retireKnown).then(formatSnapshot)'),('snapshotDuringClose',pub+'.then(qualifyStats).then(beginDiagnostic).then(requestOwnerSnapshot).then(closeReady).then(unlinkEntry).then(ownerSnapshotAck).then(releaseDiagnosticPin).then(clearTlsKnown).then(attestNativeCleanup).then(retireKnown).then(formatSnapshot)'),('fastClose',pub+'.then(publishFastHandle).then(acquireReader).then(closeReady).then(closingReentry).then(releaseReader).then(unlinkEntry).then(clearFastKnown).then(clearTlsKnown).then(attestNativeCleanup).then(retireKnown)')]
for n,p in H:q+='run '+n+'Test='+p+end
G={n:g for n,g,u,src in A}
N=[('noReadyDuringTlsUnknown','init.then(reserveConstruction).then(allocateCandidate).then(initializeOwner).then(installTlsUnknown)','stageRegistryEntry'),('pendingNoSecondAllocation','init.then(reserveConstruction).then(allocateCandidate).then(constructionReentry)','allocateCandidate'),('noStatsFromReady',pub,'beginDiagnostic'),('unknownNoRollback',pre+'.then(publishUnknownAbsent)','rollbackKnown'),('readerPinsBlockTlsClear',pub+'.then(acquireReader).then(closeReady)','clearTlsKnown'),('copyPendingNoUnpin',pub+'.then(qualifyStats).then(beginDiagnostic).then(requestOwnerSnapshot)','releaseDiagnosticPin'),('noRollbackRetry',pre+'.then(rejectPublication).then(unlinkEntry).then(clearTlsKnown).then(rollbackUnknown)','rollbackKnown'),('closedFastNoReader',pub+'.then(publishFastHandle).then(closeReady)','acquireReader')]
for n,p,a0 in N:q+='run '+n+'Test='+p+".then(all{assert(not("+G[a0]+")),assert(safe),s'=s})\n"
q+='}\n';(b/'models/quint/cache_ready_publication.qnt').write_text(q)
pr=(r/'dev/modeling/tools/node-storage-authority-projection.py').read_text();i=pr.index('SPEC = ');j=pr.index('\ndef generate',i);pr=pr[:i]+'SPEC = '+repr(dict(module='cache_ready_publication',namespace='CacheReadyPublicationAst',fields={k:'int' for k in F},actions=[n for n,g,u,src in A]))+pr[j:];(r/'dev/modeling/tools/cache-ready-publication-projection.py').write_text(pr)
(c/'author-data.json').write_text(json.dumps(dict(actions=A,bounds=len(F),invariants=len(V),pre=pre,pub=pub,close=close,snap=snap)))
print('fields/actions/invariants',len(F),len(A),len(V))
