from pathlib import Path
import json
r=Path.cwd();b=r/'dev/refactoring/modern-c';cache=r/'.cache/tasks/future-frame-commit/putobjs-move-graph'
F=dict(p=5,c=13,knowledge=2,mutex=2,walk=799,cursor=1201,sharedHead=1202,sharedCount=801,destHead=1201,destTail=1201,destCount=800,tailNext=1202,localTail=1201,pops=800,popPtr=1201,nMove=800,tailReturned=1,tailReused=1,receipt=1,held=1,gate=1,readers=1,ready=1,generation=2,stamp=1,opaque=1,oldRead=1)
I={f:0 for f in F};I.update(mutex=1,cursor=402,sharedHead=402,sharedCount=801,tailNext=1202,localTail=1201,held=1,gate=1,readers=1,generation=1,stamp=1)
A=[]
def a(n,g,u,src):A.append((n,g,u,src))
a('knownProducerUnlock','s.p==0',dict(p=1,knowledge=1,mutex=0,opaque=1),'put-unlock')
a('unknownReleased','s.p==0',dict(p=1,knowledge=2,mutex=0,opaque=1),'put-unlock')
a('unknownStillHeld','s.p==0',dict(p=1,knowledge=2,mutex=1,opaque=1),'put-unlock')
a('fixProducerLast','s.p==1 and s.knowledge==1',dict(p=2,localTail=401),'put-last')
a('publishReceipt','s.p==2 and s.knowledge==1',dict(p=3,receipt=1),'prior')
a('closeSourceAdmission','s.p==3',dict(p=4,gate=0),'cache-free')
a('sourceReadersDetached','s.p==4 and s.readers==1',dict(readers=0),'cache-free')
a('attestSourceFinalized','s.p==4 and s.readers==0 and s.c>=10 and s.ready==0',dict(ready=1),'cache-free')
a('reuseSourceCache','s.p==4 and s.readers==0 and s.ready==1 and s.held==1',dict(p=5,held=0,generation=2),'cache-free')
a('borrowOldTail','s.p==0 and s.knowledge==0 and s.mutex==1 and s.oldRead==0',dict(oldRead=1),'put-tail-read')
a('acquireConsumer','s.c==0 and s.mutex==0',dict(c=1,mutex=2),'consumer-lock')
a('selectMove800','s.c==1',dict(c=2,nMove=800),'move-cap')
a('loadMoveHead','s.c==2',dict(c=3,cursor=402),'move-head')
a('creditDestination','s.c==3',dict(c=4,destCount=800),'move-dest-count')
a('debitShared','s.c==4',dict(c=5,sharedCount=1),'move-src-count')
a('walkMovedNext','s.c==5 and s.walk<799',dict(walk='s.walk+1',cursor='s.cursor+1'),'move-next')
a('detachSharedHead','s.c==5 and s.walk==799',dict(c=6,sharedHead='s.tailNext'),'move-detach')
a('assignDestinationTail','s.c==6',dict(c=7,destTail='s.cursor'),'move-tail')
a('cutMovedTail','s.c==7',dict(c=8,tailNext='s.destHead'),'move-cut')
a('publishDestinationHead','s.c==8',dict(c=9,destHead=402),'move-publish')
a('releaseConsumer','s.c==9',dict(c=10,mutex=0),'consumer-unlock')
a('loadPopHead','s.c==10 and s.destCount>0',dict(c=11,popPtr='s.destHead'),'pop-load')
a('advanceInteriorHead','s.c==11 and s.popPtr<1201',dict(c=12,destHead='s.popPtr+1'),'pop-next')
a('advanceLastHead','s.c==11 and s.popPtr==1201',dict(c=12,destHead=0),'pop-next')
a('decrementDestination','s.c==12',dict(c=13,destCount='s.destCount-1'),'pop-count')
a('returnInterior','s.c==13 and s.popPtr<1201',dict(c=10,pops='s.pops+1'),'pop-return')
a('returnTail','s.c==13 and s.popPtr==1201',dict(c=10,pops='s.pops+1',tailReturned=1),'pop-return')
a('initializeTailPayload','s.tailReturned==1 and s.tailReused==0',dict(tailReused=1),'new-object')
V=[f'all{{s.{k}>=0,s.{k}<={v}}}' for k,v in F.items()]
V += ['s.generation>=1','s.stamp==1','s.cursor==402+s.walk',
's.c<=4 implies s.walk==0','s.c>=6 implies s.walk==799',
's.c<=4 implies s.sharedCount==801','s.c>=5 implies s.sharedCount==1',
's.c<=5 implies s.sharedHead==402','s.c>=6 implies s.sharedHead==1202',
's.c<=6 implies s.destTail==0','s.c>=7 implies s.destTail==1201',
's.c<=7 implies s.tailNext==1202','s.c>=8 implies s.tailNext==0',
's.c<=3 implies s.destCount==0','s.c>=4 and s.c<=9 implies s.destCount==800',
's.c>=10 and s.c<=12 implies s.destCount+s.pops==800','s.c==13 implies s.destCount+s.pops==799',
's.c<=9 implies s.pops==0','s.c>=11 implies s.pops<800',
's.c>=11 implies s.popPtr==402+s.pops',
's.c<=8 implies s.destHead==0','s.c==9 implies s.destHead==402',
's.c==10 and s.pops<800 implies s.destHead==402+s.pops',
's.c==10 and s.pops==800 implies s.destHead==0',
's.c==11 implies s.destHead==402+s.pops',
'(s.c==12 or s.c==13) and s.pops==799 implies s.destHead==0',
'(s.c==12 or s.c==13) and s.pops<799 implies s.destHead==403+s.pops',
's.c>=1 and s.c<=9 implies s.mutex==2','s.c>=10 implies s.mutex==0',
's.c==0 and s.knowledge==0 implies s.mutex==1',
's.c==0 and s.knowledge==1 implies s.mutex==0',
's.p==0 implies all{s.knowledge==0,s.opaque==0,s.localTail==1201,s.receipt==0,s.c==0}',
's.p>=1 implies all{s.knowledge>=1,s.opaque==1}',
's.knowledge==2 implies all{s.p==1,s.localTail==1201,s.held==1,s.receipt==0,s.gate==1,s.readers==1,s.ready==0,s.generation==1}',
's.p==1 implies s.localTail==1201','s.p>=2 implies all{s.localTail==401,s.knowledge==1}',
's.p<=2 implies s.receipt==0','s.p>=3 implies s.receipt==1',
's.p<=3 implies all{s.gate==1,s.readers==1}','s.p>=4 implies s.gate==0',
's.p<=4 implies all{s.held==1,s.generation==1}',
's.p==5 implies all{s.held==0,s.generation==2,s.readers==0,s.ready==1}',
's.ready==1 implies all{s.p>=4,s.c>=10,s.readers==0}',
's.tailReturned==1 implies s.pops==800','s.pops==800 implies s.tailReturned==1',
's.tailReused==1 implies s.tailReturned==1']
q='module putobjs_move_graph {\n// Selected post-PutObjs publication: retained401, batch800, previous shared suffix1.\n'
q+='type State={'+','.join(f+':int' for f in F)+'}\n'
q+="pure val initial:State={"+','.join(k+':'+str(v) for k,v in I.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(V)+"}\n"
for n,g,u,src in A:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(x[0] for x in A)+",all{s'=s}}\n"
move='acquireConsumer.then(selectMove800).then(loadMoveHead).then(creditDestination).then(debitShared).then(799.reps(i=>walkMovedNext)).then(detachSharedHead).then(assignDestinationTail).then(cutMovedTail).then(publishDestinationHead).then(releaseConsumer)'
pops='799.reps(i=>loadPopHead.then(advanceInteriorHead).then(decrementDestination).then(returnInterior)).then(loadPopHead).then(advanceLastHead).then(decrementDestination).then(returnTail).then(initializeTailPayload)'
end=".then(all{assert(safe),s'=s})\n"
q+='run consumeBeforeFixTest=init.then(knownProducerUnlock).then('+move+').then('+pops+').then(fixProducerLast).then(publishReceipt)'+end
q+='run fixBeforeMoveTest=init.then(knownProducerUnlock).then(fixProducerLast).then('+move+').then('+pops+').then(publishReceipt)'+end
q+='run fixWhileConsumerLockedTest=init.then(knownProducerUnlock).then(acquireConsumer).then(fixProducerLast).then(selectMove800).then(loadMoveHead).then(creditDestination).then(debitShared).then(799.reps(i=>walkMovedNext)).then(detachSharedHead).then(assignDestinationTail).then(cutMovedTail).then(publishDestinationHead).then(releaseConsumer)'+end
q+='run unknownReleasedConsumesTest=init.then(unknownReleased).then('+move+').then('+pops+')'+end
q+='run unknownHeldBlocksTest=init.then(unknownStillHeld)'+end
q+='run retireAfterConsumerTest=init.then(knownProducerUnlock).then('+move+').then(fixProducerLast).then(publishReceipt).then(closeSourceAdmission).then(sourceReadersDetached).then(attestSourceFinalized).then(reuseSourceCache)'+end
G={n:g for n,g,u,src in A}
late=[('oldTailReuseNoBorrow','init.then(knownProducerUnlock).then('+move+').then('+pops+')','borrowOldTail'),('unknownNoFix','init.then(unknownReleased).then('+move+').then('+pops+')','fixProducerLast'),('unknownNoRetire','init.then(unknownReleased).then('+move+').then('+pops+')','reuseSourceCache'),('unknownHeldNoConsumer','init.then(unknownStillHeld)','acquireConsumer'),('beforeConsumerNoFinalize','init.then(knownProducerUnlock).then(fixProducerLast).then(publishReceipt).then(closeSourceAdmission).then(sourceReadersDetached)','attestSourceFinalized')]
for n,p,a0 in late:q+='run '+n+'Test='+p+".then(all{assert(not("+G[a0]+")),assert(safe),s'=s})\n"
q+='}\n';(b/'models/quint/putobjs_move_graph.qnt').write_text(q)
pr=(r/'dev/modeling/tools/putobjs-custody-projection.py').read_text();start=pr.index('SPEC = ');stop=pr.index('\ndef generate',start);pr=pr[:start]+'SPEC = '+repr(dict(module='putobjs_move_graph',namespace='PutObjsMoveGraphAst',fields={k:'int' for k in F},actions=[x[0] for x in A]))+pr[stop:];(r/'dev/modeling/tools/putobjs-move-graph-projection.py').write_text(pr)
(cache/'author-data.json').write_text(json.dumps(dict(actions=A,invariants=len(V),bounds=len(F),move=move,pops=pops,fields=len(F))))
print('fields',len(F),'actions',len(A),'invariants',len(V))
