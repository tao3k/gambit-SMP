from pathlib import Path
import json
r=Path.cwd();b=r/'dev/refactoring/modern-c';c=r/'.cache/tasks/future-frame-commit/node-storage-authority'
F=dict(stage=10,ownerReady=1,listVisible=1,layout=1,mapReady=1,coverage=1,aliasSeen=1,gate=1,metaLease=1,payloadLease=1,tailAuth=1,nodeRole=2,unknown=1,receipt=1,cacheLive=1,cacheGen=2,nodeAllocGen=1,queryGen=1,cleanupReady=1,opaqueSeen=1,currentSeen=1)
I={k:0 for k in F};I.update(tailAuth=1,cacheLive=1,cacheGen=1,nodeAllocGen=1,queryGen=1)
A=[]
def a(n,g,u,src):A.append((n,g,u,src))
a('publishRawList','s.stage==0',dict(stage=1,listVisible=1),'cache-list')
a('initializeOwner','s.stage==1',dict(stage=2,ownerReady=1),'cache-owner')
a('attestDisjoint','s.stage==2 and s.layout==0',dict(layout=1),'alloc-distinct')
a('bindNodeMap','s.stage==2 and s.ownerReady==1 and s.layout==1',dict(stage=3,mapReady=1,gate=1),'node-chunk')
a('sealReaderClosure','s.stage==3 and s.aliasSeen==0',dict(stage=4,coverage=1),'prior')
a('exposeAlias','s.stage==3 and s.aliasSeen==0',dict(aliasSeen=1),'callback-overlay')
a('revokeSeal','s.stage==4 and s.payloadLease==0',dict(stage=3,coverage=0,aliasSeen=1),'trace-hook')
a('rejectAlias','s.stage==3 and s.aliasSeen==1 and s.payloadLease==0',dict(stage=10,gate=0),'prior')
a('acquireMetadata','s.mapReady==1 and s.gate==1 and s.metaLease==0',dict(metaLease=1),'diagnostic')
a('returnMetadata','s.metaLease==1',dict(metaLease=0),'diagnostic')
a('acquirePayload','s.stage==4 and s.coverage==1 and s.tailAuth==1 and s.payloadLease==0',dict(payloadLease=1),'put-tail')
a('returnPayload','s.payloadLease==1',dict(payloadLease=0),'put-tail')
a('knownHandoff','s.stage==4 and s.coverage==1 and s.payloadLease==0',dict(stage=5,tailAuth=0,nodeRole=1),'put-unlock')
a('unknownHandoff','s.stage==4 and s.coverage==1 and s.payloadLease==0',dict(stage=5,tailAuth=0,nodeRole=1,unknown=1),'put-unlock')
a('consumerAllocate','s.stage>=5 and s.stage<=9 and s.nodeRole==1',dict(nodeRole=2),'new-object')
a('fixSourceLast','s.stage==5 and s.unknown==0',dict(stage=6),'put-last')
a('publishCompletion','s.stage==6',dict(stage=7,receipt=1),'prior')
a('closeAdmission','s.stage==7',dict(stage=8,gate=0),'cache-free')
a('attestCleanup','s.stage==8 and s.metaLease==0 and s.payloadLease==0 and s.cleanupReady==0',dict(cleanupReady=1),'tls-cleanup')
a('retireCache','s.stage==8 and s.cleanupReady==1 and s.metaLease==0 and s.payloadLease==0',dict(stage=9,cacheLive=0,cacheGen=2),'cache-free')
a('lookupOpaque','s.mapReady==1 and s.opaqueSeen==0',dict(opaqueSeen=1),'prior')
a('probeCurrentCache','s.mapReady==1 and s.metaLease==1 and s.gate==1 and s.cacheLive==1 and s.cacheGen==s.queryGen and s.currentSeen==0',dict(currentSeen=1),'diagnostic')
V=[f'all{{s.{k}>=0,s.{k}<={v}}}' for k,v in F.items()]
V+=['s.nodeAllocGen==1','s.queryGen==1','s.cacheGen>=1',
's.stage==0 implies s.listVisible==0','s.stage>=1 implies s.listVisible==1',
's.stage<=1 implies s.ownerReady==0','s.stage>=2 implies s.ownerReady==1',
's.stage<=2 implies all{s.mapReady==0,s.gate==0,s.metaLease==0,s.payloadLease==0,s.coverage==0,s.aliasSeen==0}',
's.stage>=3 implies all{s.mapReady==1,s.layout==1,s.ownerReady==1}',
's.stage==3 implies s.coverage==0','s.stage==4 implies all{s.coverage==1,s.aliasSeen==0}',
's.stage>=5 and s.stage<=9 implies all{s.coverage==1,s.aliasSeen==0}',
's.stage<=4 implies all{s.tailAuth==1,s.nodeRole==0,s.unknown==0,s.receipt==0}',
's.stage>=5 and s.stage<=9 implies all{s.tailAuth==0,s.nodeRole>=1}',
's.stage==10 implies all{s.aliasSeen==1,s.coverage==0,s.gate==0,s.cacheLive==1,s.receipt==0,s.tailAuth==1,s.nodeRole==0,s.unknown==0,s.payloadLease==0}',
's.unknown==1 implies all{s.stage==5,s.receipt==0,s.cacheLive==1,s.cleanupReady==0,s.cacheGen==1,s.gate==1}',
'(s.stage==5 or s.stage==6) implies s.receipt==0','s.stage>=7 and s.stage<=9 implies s.receipt==1',
's.stage>=3 and s.stage<=7 implies s.gate==1','s.stage>=8 implies s.gate==0',
's.stage==9 implies all{s.cacheLive==0,s.cacheGen==2,s.metaLease==0,s.payloadLease==0,s.cleanupReady==1}',
's.stage!=9 implies all{s.cacheLive==1,s.cacheGen==1}',
's.cleanupReady==1 implies all{(s.stage==8 or s.stage==9),s.metaLease==0,s.payloadLease==0}',
's.payloadLease==1 implies all{s.stage==4,s.tailAuth==1}']
q='module node_storage_authority {\n// Proposed stable registration/admission; current raw list publication is not a binding receipt.\ntype State={'+','.join(k+':int' for k in F)+'}\n'
q+="pure val initial:State={"+','.join(k+':'+str(v) for k,v in I.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(V)+"}\n"
for n,g,u,src in A:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(n for n,g,u,src in A)+",all{s'=s}}\n"
pre='init.then(publishRawList).then(initializeOwner).then(attestDisjoint).then(bindNodeMap)'
sealed=pre+'.then(sealReaderClosure)';known=sealed+'.then(knownHandoff)';finished=known+'.then(fixSourceLast).then(publishCompletion)'
end=".then(all{assert(safe),s'=s})\n"
for n,p in [('rawListOnly','init.then(publishRawList)'),('normal',finished),('metadataOnlyAfterTransfer',known+'.then(acquireMetadata).then(probeCurrentCache).then(lookupOpaque)'),('unknownConsumer',sealed+'.then(unknownHandoff).then(consumerAllocate)'),('revoked',sealed+'.then(revokeSeal).then(rejectAlias)'),('lateOpaque',finished+'.then(closeAdmission).then(attestCleanup).then(retireCache).then(lookupOpaque)'),('payloadLease',sealed+'.then(acquirePayload).then(returnPayload).then(knownHandoff)')]:q+='run '+n+'Test='+p+end
G={n:g for n,g,u,src in A}
for n,p,guard in [('rawNotReady','init.then(publishRawList)','acquireMetadata'),('oldTailNoRead',known,'acquirePayload'),('leaseBlocksHandoff',sealed+'.then(acquirePayload)','knownHandoff'),('revokedNoSeal',sealed+'.then(revokeSeal)','sealReaderClosure'),('unknownNoRetire',sealed+'.then(unknownHandoff).then(consumerAllocate)','retireCache'),('metadataBlocksFree',finished+'.then(acquireMetadata).then(closeAdmission)','attestCleanup'),('reusedNoCacheRead',finished+'.then(closeAdmission).then(attestCleanup).then(retireCache)','probeCurrentCache')]:q+='run '+n+'Test='+p+".then(all{assert(not("+G[guard]+")),assert(safe),s'=s})\n"
q+='}\n';(b/'models/quint/node_storage_authority.qnt').write_text(q)
pr=(r/'dev/modeling/tools/putobjs-move-graph-projection.py').read_text();i=pr.index('SPEC = ');j=pr.index('\ndef generate',i);pr=pr[:i]+'SPEC = '+repr(dict(module='node_storage_authority',namespace='NodeStorageAuthorityAst',fields={k:'int' for k in F},actions=[n for n,g,u,src in A]))+pr[j:];(r/'dev/modeling/tools/node-storage-authority-projection.py').write_text(pr)
(c/'author-data.json').write_text(json.dumps(dict(actions=A,bounds=len(F),invariants=len(V),pre=pre,sealed=sealed,finished=finished)))
print('model',len(F),len(A),len(V))
