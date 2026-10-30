from pathlib import Path
import json,importlib.util
r=Path.cwd();b=r/'dev/refactoring/modern-c';cache=r/'.cache/tasks/future-frame-commit/putobjs-custody'
fields=dict(phase=15,mode=2,empty=1,walk=401,last=401,localCount=1201,uncredited=800,exposed=800,delta=800,split=1,lock=2,sharedTail=1,lastFixed=1,receipt=1,escaped=1,held=1,gate=1,readers=1,generation=2,stamp=1,accepted=1,finalized=1)
init={k:0 for k in fields};init.update(localCount=1201,held=1,gate=1,readers=1,generation=1,stamp=1)
a=[]
def act(n,g,updates,source):a.append((n,g,updates,source))
alive='s.escaped==0'
act('admitOwner','s.phase==0 and s.mode==0',{'mode':1},'prior')
act('chooseEmpty','s.phase==8 and s.mode==1 and '+alive,{'mode':2,'empty':1},'tail-condition')
act('chooseNonempty','s.phase==8 and s.mode==1 and '+alive,{'mode':2,'empty':0},'tail-condition')
act('trimLocal','s.phase==0 and s.mode==1 and '+alive,{'phase':1,'localCount':401,'uncredited':800},'trim')
act('loadLocalHead','s.phase==1 and '+alive,{'phase':2},'head-load')
act('assignLast','s.phase==2 and s.walk<401 and '+alive,{'phase':3,'last':'s.walk+1'},'walk-last')
act('advanceCursor','s.phase==3 and '+alive,{'phase':4,'walk':'s.walk+1'},'walk-next')
act('loopAgain','s.phase==4 and s.walk<401 and '+alive,{'phase':2},'walk-condition')
act('cutLocal','s.phase==4 and s.walk==401 and '+alive,{'phase':5,'split':1},'split')
act('lockKnown','s.phase==5 and '+alive,{'phase':6,'lock':1},'lock')
act('lockUnknown','s.phase==5 and '+alive,{'phase':6,'lock':2,'escaped':1},'lock')
act('linkOldTail','s.phase==6 and s.lock==1 and '+alive,{'phase':7},'suffix-link')
act('publishSharedHead','s.phase==7 and s.lock==1 and '+alive,{'phase':8,'exposed':800},'shared-head')
act('updateEmptySharedTail','s.phase==8 and s.mode==2 and s.empty==1 and '+alive,{'phase':9,'sharedTail':1},'shared-tail')
act('keepSharedTail','s.phase==8 and s.mode==2 and s.empty==0 and '+alive,{'phase':9,'sharedTail':1},'tail-condition')
act('addSharedCount','s.phase==9 and '+alive,{'phase':10,'delta':800,'uncredited':0},'shared-count')
act('unlockKnown','s.phase==10 and s.lock==1 and '+alive,{'phase':11,'lock':0},'unlock')
act('unlockUnknown','s.phase==10 and s.lock==1 and '+alive,{'phase':11,'lock':2,'escaped':1},'unlock')
act('fixLocalLast','s.phase==11 and s.lock==0 and '+alive,{'phase':12,'lastFixed':1},'localCount-last')
act('publishReceipt','s.phase==12 and s.lock==0 and s.lastFixed==1 and '+alive,{'phase':13,'receipt':1},'localCount-last')
act('escape','s.phase<=12 and s.mode==1 and '+alive,{'escaped':1},'prior')
act('loseReceiptAck','s.phase==13 and s.receipt==1 and '+alive,{'escaped':1},'prior')
act('acceptReceipt','s.receipt==1 and s.stamp==s.generation and s.held==1 and s.gate==1 and s.accepted==0',{'accepted':1},'prior')
act('closeAdmission','s.phase==13 and s.receipt==1',{'phase':14,'gate':0},'cache-free')
act('readersDetached','s.phase==14 and s.readers==1',{'readers':0},'cache-free')
act('attestFinalization','s.phase==14 and s.readers==0 and s.finalized==0',{'finalized':1},'thread-finalize')
act('reuseAddress','s.phase==14 and s.readers==0 and s.finalized==1 and s.lock==0 and s.held==1',{'phase':15,'generation':2,'held':0,'accepted':0},'cache-free')
inv=[]
for k,v in fields.items():inv.extend([f's.{k}>=0',f's.{k}<={v}'])
inv+=['s.generation>=1','s.stamp==1','s.localCount+s.uncredited+s.delta==1201',
's.phase==0 implies all{s.localCount==1201,s.uncredited==0,s.walk==0,s.last==0}',
's.phase>=1 implies all{s.localCount==401,s.mode>=1}',
's.phase<=1 implies all{s.walk==0,s.last==0}',
's.phase==2 implies all{s.last==s.walk,s.walk<401}',
's.phase==3 implies all{s.last==s.walk+1,s.walk<401}',
's.phase==4 implies all{s.last==s.walk,s.walk>=1}',
's.phase>=5 implies all{s.walk==401,s.last==401}',
's.phase<=4 implies s.split==0','s.phase>=5 implies s.split==1',
's.phase<=5 implies s.lock==0',
's.phase>=6 and s.phase<=10 implies s.lock>=1',
's.phase>=12 implies s.lock==0',
's.lock==2 implies all{s.escaped==1,(s.phase==6 or s.phase==11)}',
's.phase<=7 implies s.exposed==0','s.phase>=8 implies s.exposed==800',
's.phase<=8 implies s.sharedTail==0','s.phase>=9 implies s.sharedTail==1',
's.phase<=9 implies s.delta==0','s.phase>=10 implies s.delta==800',
's.phase<=11 implies s.lastFixed==0','s.phase>=12 implies s.lastFixed==1',
's.phase<=12 implies s.receipt==0','s.phase>=13 implies s.receipt==1',
's.phase<=13 implies all{s.gate==1,s.readers==1}',
's.phase>=14 implies s.gate==0',
's.phase<=14 implies all{s.generation==1,s.held==1}',
's.phase==15 implies all{s.generation==2,s.held==0,s.readers==0,s.accepted==0,s.finalized==1}',
's.accepted==1 implies all{s.receipt==1,s.generation==s.stamp}',
's.finalized==1 implies all{s.phase>=14,s.readers==0}']
state='{'+','.join(k+':int' for k in fields)+'}'
q="module putobjs_custody {\n// Selected n=1200 high-water return, valid 1201-node chain and original native owner.\ntype State="+state+"\npure val initial:State={"+','.join(k+':'+str(v) for k,v in init.items())+"}\nvar s:State\naction init=s'=initial\nval safe=all{"+','.join(inv)+'}\n'
for n,g,u,_ in a:q+='action '+n+'=all{'+g+",s'={...s,"+','.join(k+':'+str(v) for k,v in u.items())+'}}\n'
q+="action step=any{"+','.join(x[0] for x in a)+",all{s'=s}}\n"
walk='400.reps(i => assignLast.then(advanceCursor).then(loopAgain)).then(assignLast).then(advanceCursor)'
prefix='init.then(admitOwner).then(trimLocal).then(loadLocalHead).then('+walk+').then(cutLocal)'
body=prefix+'.then(lockKnown).then(linkOldTail).then(publishSharedHead).then(chooseEmpty).then(updateEmptySharedTail).then(addSharedCount)'
known=body+'.then(unlockKnown).then(fixLocalLast).then(publishReceipt)'
end=".then(all{assert(safe),s'=s})\n"
q+='run normalEmptyTest='+known+'.then(acceptReceipt)'+end
q+='run normalNonemptyTest='+known.replace('chooseEmpty','chooseNonempty').replace('updateEmptySharedTail','keepSharedTail')+end
q+='run lockUnknownTest='+prefix+'.then(lockUnknown)'+end
q+='run unlockUnknownTest='+body+'.then(unlockUnknown)'+end
q+='run staleReceiptTest='+known+'.then(closeAdmission).then(readersDetached).then(attestFinalization).then(reuseAddress)'+end
q+='run lostAckTest='+known+'.then(loseReceiptAck).then(acceptReceipt)'+end
q+='run partialWalkTest=init.then(admitOwner).then(trimLocal).then(loadLocalHead).then(assignLast).then(advanceCursor).then(escape)'+end
q+='}\n';(b/'models/quint/putobjs_custody.qnt').write_text(q)
pr=(r/'dev/modeling/tools/thread-cache-tail-projection.py').read_text();start=pr.index('SPEC = ');stop=pr.index('\ndef generate',start)
pr=pr[:start]+'SPEC = '+repr(dict(module='putobjs_custody',namespace='PutObjsCustodyAst',fields={k:'int' for k in fields},actions=[x[0] for x in a]))+pr[stop:];pr=pr.replace('Thread-cache tail','PutObjs custody');(r/'dev/modeling/tools/putobjs-custody-projection.py').write_text(pr)
(cache/'author-data.json').write_text(json.dumps(dict(actions=a,invariants=len(inv),prefix=prefix,body=body,known=known)))
print('fields',len(fields),'actions',len(a),'invariants',len(inv))
