from pathlib import Path
import json
r=Path.cwd();b=r/'dev/refactoring/modern-c';c=r/'.cache/tasks/future-frame-commit/exit-domain-drain'
F=dict(phase=6,a=8,b=8,ack=2,parent=2,samePair=1,tailLive=1,tailDone=1,public=1,keyGate=1,lookupPin=1,data=1,slot=1,cache=1,joined=1,miss=1,deps=1,cacheDone=1,allOwners=1,key=1)
I={k:0 for k in F};I.update(public=1,keyGate=1,key=1)
A=[]
def a(n,g,u,s):A.append((n,g,u,s))
a('seedRegistrationA','s.phase==0 and s.a==0',dict(a=2,data=1,slot=1,cache=1),'create-thread')
a('chooseDuplicatePair','s.phase==0 and s.b==0 and s.samePair==0',dict(samePair=1),'create-thread')
a('reserveExternalB','s.phase==0 and s.a==2 and s.b==0',dict(b=1,parent=0),'create-thread')
a('beginDrain','s.phase==0',dict(phase=1,public=0),'invoke')
a('reserveChildB','s.phase==1 and s.a==3 and s.b==0',dict(b=1,parent=1),'create-thread')
a('reserveTailB','s.phase==1 and s.tailLive==1 and s.b==0',dict(b=1,parent=2),'condition-producer')
a('publishBKnown','s.b==1 and s.ack==0',dict(b=2,ack=1),'create-thread')
a('publishBUnknown','s.b==1 and s.ack==0',dict(b=2,ack=2),'create-thread')
a('publicationAbsentUnknown','s.b==1 and s.ack==0',dict(ack=2),'create-thread')
a('reconcileAcceptedB','s.b>=2 and s.ack==2',dict(ack=1),'prior')
a('reconcileAbsentAndRolledBackB','s.b==1 and s.ack==2',dict(b=0,ack=0,parent=0),'prior')
a('popA','s.phase==1 and s.a==2 and s.b!=2',dict(a=3),'pop-thread')
a('popB','s.phase==1 and s.b==2',dict(b=3),'pop-thread')
a('returnA','s.a==3',dict(a=4),'callback-thread')
a('returnB','s.b==3',dict(b=4),'callback-thread')
a('callbackUnknownA','s.a==3',dict(a=8),'callback-thread')
a('freeNodeAKnown','s.a==4 or s.a==6',dict(a=5),'free-thread')
a('freeNodeBKnown','s.b==4 or s.b==6',dict(b=5),'free-thread')
a('freeNodeAUnknown','s.a==4 or s.a==6',dict(a=7),'free-thread')
a('freeNodeBUnknown','s.b==4 or s.b==6',dict(b=7),'free-thread')
a('cancelNewestDuplicateB','s.b==2 and s.samePair==1',dict(b=6),'delete-thread')
a('cancelQueuedA','s.a==2 and not(s.b==2 and s.samePair==1)',dict(a=6),'delete-thread')
a('reentrantFinalizeJoin','s.phase==1 and (s.a==3 or s.b==3) and s.joined==0',dict(joined=1),'finalize-thread')
done='(s.a==0 or s.a==5) and (s.b==0 or s.b==5) and s.ack!=2'
a('beginSubsystemTail','s.phase==1 and '+done+' and s.tailLive==0 and s.tailDone==0',dict(tailLive=1),'tail-finalizers')
a('finishSubsystemTail','s.phase==1 and s.tailLive==1 and s.b!=1 and s.ack!=2',dict(tailLive=0,tailDone=1),'tail-finalizers')
a('closeProducers','s.phase==1 and '+done+' and s.tailLive==0 and s.tailDone==1',dict(phase=2,keyGate=0),'tail-finalizers')
a('attestNoTsdDependencies','s.phase==2 and s.deps==0',dict(deps=1),'condition-close')
a('acquireLookup','s.key==1 and s.keyGate==1 and s.lookupPin==0',dict(lookupPin=1),'pure-get')
a('lookupAbsent','s.lookupPin==1 and s.data==0 and s.miss==0',dict(miss=1),'pure-get')
a('releaseLookup','s.lookupPin==1',dict(lookupPin=0),'pure-get')
a('detachTableSlot','s.phase==2 and s.lookupPin==0 and s.deps==1',dict(phase=3,slot=0),'tsd-detach')
a('freeTsdData','s.phase==3 and s.slot==0 and s.lookupPin==0 and s.deps==1',dict(phase=4,data=0),'tsd-free')
a('issueDataDrainReceipt','s.phase==4',dict(phase=5),'tsd-free')
a('cancelAbsentFromReceipt','s.phase>=3 and s.slot==0 and s.miss==0',dict(miss=1),'delete-thread')
a('attestCacheAndOwnerRoster','s.phase==5 and s.lookupPin==0',dict(cacheDone=1,allOwners=1,cache=0),'all-threads')
a('deleteGenericKey','s.phase==5 and s.cacheDone==1 and s.allOwners==1 and s.lookupPin==0 and s.key==1',dict(phase=6,key=0),'key-delete')
V=[f'all{{s.{k}>=0,s.{k}<={v}}}' for k,v in F.items()]
V+=['s.phase==0 implies all{s.public==1,s.keyGate==1,s.tailLive==0,s.tailDone==0}',
's.phase>=1 implies s.public==0','s.phase<=1 implies all{s.keyGate==1,s.slot==s.data,s.deps==0}',
's.phase>=2 implies all{s.keyGate==0,(s.a==0 or s.a==5),(s.b==0 or s.b==5),s.ack!=2,s.tailLive==0,s.tailDone==1}',
's.phase>=3 implies all{s.slot==0,s.lookupPin==0,s.deps==1}',
's.phase>=4 implies s.data==0','s.phase<=5 implies s.key==1','s.phase==6 implies all{s.key==0,s.cacheDone==1,s.allOwners==1,s.cache==0}',
's.lookupPin==1 implies all{s.phase<=2,s.key==1}',
's.data==1 implies s.cache==1','s.a>=1 and s.a<=8 and s.phase<=1 implies s.data==1',
's.b>=1 and s.b<=8 and s.phase<=1 implies s.data==1',
's.b==0 implies all{s.ack==0,s.parent==0}','s.b==1 implies all{s.ack!=1,s.data==1}',
's.b>=2 implies all{s.a!=0,s.parent>=0,(s.ack==1 or s.ack==2)}',
's.a>=3 and s.a<=4 implies s.phase==1','s.b>=3 and s.b<=4 implies s.phase==1',
'(s.a==6 or s.a==7 or s.a==8) implies s.phase<=1','(s.b==6 or s.b==7 or s.b==8) implies s.phase<=1',
's.tailLive==1 implies all{s.phase==1,s.tailDone==0}',
's.tailDone==1 implies s.tailLive==0',
's.cacheDone==1 implies all{s.phase>=5,s.data==0,s.slot==0,s.lookupPin==0,s.cache==0}',
's.allOwners==1 implies all{s.phase>=5,s.cacheDone==1}',
's.phase<=4 implies all{s.cacheDone==0,s.allOwners==0}',
's.cache==0 implies s.data==0']
q='module exit_domain_drain {\n// Two distinct registrations may share proc/clientData; native receipt authorities are external premises.\ntype State={'+','.join(k+':int' for k in F)+'}\n'
q+="pure val initial:State={"+','.join(k+':'+str(v) for k,v in I.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(V)+"}\n"
for n,g,u,src in A:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(n for n,g,u,src in A)+",all{s'=s}}\n"
pre='init.then(seedRegistrationA).then(beginDrain).then(popA)';finish='returnA.then(freeNodeAKnown)';tail='beginSubsystemTail.then(finishSubsystemTail).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)'
end=".then(all{assert(safe),s'=s})\n"
H=[('normal',pre+'.then('+finish+').then('+tail+')'),('duplicateSelfDelete','init.then(seedRegistrationA).then(chooseDuplicatePair).then(beginDrain).then(popA).then(reserveChildB).then(publishBKnown).then(cancelNewestDuplicateB).then(freeNodeBKnown).then('+finish+').then('+tail+')'),('unknownAckChildRuns',pre+'.then(reserveChildB).then(publishBUnknown).then(returnA).then(freeNodeAKnown).then(popB).then(returnB).then(freeNodeBKnown).then(reconcileAcceptedB).then('+tail+')'),('tailCreatesHandler',pre+'.then('+finish+').then(beginSubsystemTail).then(reserveTailB).then(publishBKnown).then(finishSubsystemTail).then(popB).then(returnB).then(freeNodeBKnown).then(closeProducers).then(attestNoTsdDependencies).then(detachTableSlot).then(freeTsdData).then(issueDataDrainReceipt)'),('reentrantJoin',pre+'.then(reentrantFinalizeJoin).then('+finish+')'),('unknownNodeFree',pre+'.then(returnA).then(freeNodeAUnknown)'),('unknownCallback',pre+'.then(callbackUnknownA)'),('emptyLookup','init.then(acquireLookup).then(lookupAbsent).then(releaseLookup)'),('keyAfterExternalRoster',pre+'.then('+finish+').then('+tail+').then(cancelAbsentFromReceipt).then(attestCacheAndOwnerRoster).then(deleteGenericKey)'),('unknownNoCommit',pre+'.then(reserveChildB).then(publicationAbsentUnknown).then(returnA).then(freeNodeAKnown).then(reconcileAbsentAndRolledBackB).then('+tail+')')]
for n,p in H:q+='run '+n+'Test='+p+end
G={n:g for n,g,u,src in A};N=[('emptyQueueStillInflight',pre,'beginSubsystemTail'),('reentryNotDrain',pre+'.then(reentrantFinalizeJoin)','detachTableSlot'),('unknownRegistrationNotClosed',pre+'.then(reserveChildB).then(publicationAbsentUnknown).then(returnA).then(freeNodeAKnown)','closeProducers'),('tailChildStillQueued',pre+'.then('+finish+').then(beginSubsystemTail).then(reserveTailB).then(publishBKnown).then(finishSubsystemTail)','closeProducers'),('pendingNodeFreeNotClosed',pre+'.then(returnA).then(freeNodeAUnknown)','beginSubsystemTail'),('dataReceiptNotRoster',pre+'.then('+finish+').then('+tail+')','deleteGenericKey'),('lookupPinBlocksDetach',pre+'.then('+finish+').then(beginSubsystemTail).then(finishSubsystemTail).then(acquireLookup).then(closeProducers).then(attestNoTsdDependencies)','detachTableSlot')]
for n,p,a0 in N:q+='run '+n+'Test='+p+".then(all{assert(not("+G[a0]+")),assert(safe),s'=s})\n"
q+='}\n';(b/'models/quint/exit_domain_drain.qnt').write_text(q)
pr=(r/'dev/modeling/tools/runtime-tls-ready-projection.py').read_text();i=pr.index('SPEC = ');j=pr.index('\ndef generate',i);pr=pr[:i]+'SPEC = '+repr(dict(module='exit_domain_drain',namespace='ExitDomainDrainAst',fields={k:'int' for k in F},actions=[n for n,g,u,src in A]))+pr[j:];(r/'dev/modeling/tools/exit-domain-drain-projection.py').write_text(pr)
(c/'author-data.json').write_text(json.dumps(dict(actions=A,bounds=len(F),invariants=len(V),pre=pre,tail=tail,finish=finish)))
print('fields/actions/invariants',len(F),len(A),len(V))
