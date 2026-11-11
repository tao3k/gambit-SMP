from pathlib import Path
import json,re,hashlib
from gambit_smp import workspace,work_process
from gambit_smp.framework import execute,available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def run():
 old=json.loads((E/'drain-cap-admission-protocol.json').read_text())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/drain-closure-audit');out.mkdir(parents=True)
  source=json.loads((R/old['sourceReceipt']).read_text());c=R/source['candidate']
  assert sha(R/old['lock'])==old['lockSha256'] and sha(R/old['patch'])==old['patchSha256']
  assert all(sha(c/p)==h for p,h in source['files'].items())
  assert all(sha(R/p)==h for p,h in old['protectedInputs'].items())
  rows=[]
  for f in sorted((c/'lib').glob('*.scm')):
   fn='';a=f.read_text().splitlines()
   for i,z in enumerate(a):
    m=re.match(r'\(define-prim \(([^\s)]+)',z)
    if m:fn=m[1]
    if not z.startswith('(define-prim') and re.search(r'\(##(?:lock-(?:scheduler-object|processor|2-threads|3-threads)-with-sync-participation!|sync-op-interrupt!)',z):
     rows.append(dict(file=str(f.relative_to(c)),line=i+1,function=fn,text=z.strip()))
  (out/'callers.json').write_text(json.dumps(rows,indent=2)+'\n')
  # Standalone compiler controls only: no runtime source, object, link or execution.
  probe=out/'atomic-control.c';probe.write_text('''typedef unsigned long W;
_Static_assert(sizeof(W)==8,"64-bit control");
_Static_assert(__atomic_always_lock_free(sizeof(W),0),"native word must be lock-free");
struct G { W gate; };
_Static_assert(__alignof__(struct G)>=__alignof__(W),"alignment");
int enter(struct G *g,W *expected,W next) {
 return __atomic_compare_exchange_n(&g->gate,expected,next,0,__ATOMIC_ACQ_REL,__ATOMIC_ACQUIRE);
}
W put(struct G *g) { return __atomic_fetch_sub(&g->gate,1,__ATOMIC_ACQ_REL); }
''')
  controls=[]
  for name,cc in [('gcc16','/opt/homebrew/bin/gcc-16'),('apple-clang','/usr/bin/clang')]:
   if not Path(cc).exists():continue
   logs=[];asm=out/(name+'.s');meta={}
   for args in [[cc,'--version'],[cc,'-dumpmachine'],[cc,'-O2','-std=c11','-S',str(probe),'-o',str(asm)]]:
    code,log,to,secs=execute(args,out,30,metadata=meta);logs.append(dict(argv=args,exit=code,timeout=to,seconds=secs,metadata=dict(meta),output=log));assert code==0 and not to,(args,log)
   text=asm.read_text();calls=re.findall(r'^\s*(?:bl|call\w*)\s+([^\n]+)',text,re.M)
   controls.append(dict(name=name,compiler=cc,commands=logs,assembly=str(asm.relative_to(R)),assemblySha256=sha(asm),calls=calls,exclusiveInstructions=bool(re.search(r'\b(?:ldaxr|stlxr|casal|ldaddal)\b',text)),actualProducer=False))
   (out/(name+'.log')).write_text(json.dumps(logs,indent=2)+'\n')
  base=(R/'models/gambit/drain_cap_admission.qnt').read_text()
  base=re.sub(r'^  action init[A-Z]\w*=.*\n','',base,flags=re.M)
  base=base.replace('module drain_cap_admission','module drain_sync_closure')
  base=base.replace('Set(1,3,4,6,7,8,9,10).contains(m)', 'Set(1,3,4,6,7,8,9,10,11,12).contains(m)')
  base=base.replace('capStep:int,spent:bool}', 'capStep:int,spent:bool,locks:int,rootSaved:bool,rootVersion:int,rawVersion:int,usedVersion:int,relocated:bool,nestedActive:bool,nestedDone:bool,activeClaim:int,executions:int,hadError:bool,errorPending:bool,handled:bool,finished:bool,unwound:bool,afterPut:bool,carrier:bool}')
  base=base.replace('spent:m==10}', 'spent:m==10,locks:if(m==11) 2 else 1,rootSaved:false,rootVersion:1,rawVersion:1,usedVersion:0,relocated:false,nestedActive:false,nestedDone:false,activeClaim:1,executions:0,hadError:m==12,errorPending:m==12,handled:false,finished:false,unwound:false,afterPut:false,carrier:true}')
  names={'Normal':(1,0),'TwoLocks':(11,0),'Error':(12,0),'EmulatedCas':(1,12),'Unrooted':(1,13),'StaleLocal':(1,14),'ThrowHeld':(12,15),'LostError':(12,16),'ParentClaimLost':(1,17),'PostPutAccess':(1,18),'EarlyCarrierDrop':(1,19),'DuplicateExecution':(1,20)}
  pos=['Normal','TwoLocks','Error']
  base=base.replace('  action snapshotGate', '\n'.join(f'  action init{k}=s\'=initial({m},{b})' for k,(m,b) in names.items())+'\n  action snapshotGate')
  base=base.replace('s.pc==3,s.ctl==1,','s.pc==3,s.ctl==1,s.rootSaved,s.relocated,s.nestedDone,not(s.nestedActive),s.activeClaim==1,(s.rawVersion==s.rootVersion or s.bug==14),')
  base=base.replace('n:s.n-1,served:true}', 'n:s.n-1,served:true,executions:s.executions+1,usedVersion:s.rawVersion}')
  extra='''  action saveRoots=all {s.pc==3,not(s.rootSaved),s'={...s,rootSaved:true}}
  action moveRoots=all {s.pc==3,s.rootSaved,not(s.relocated),s'={...s,rootVersion:2,relocated:true}}
  action reloadRoots=all {s.pc==3,s.relocated,s.rawVersion!=s.rootVersion,s.bug!=14,s'={...s,rawVersion:s.rootVersion}}
  action nestedEnter=all {s.pc==3,s.rootSaved,not(s.nestedActive),not(s.nestedDone),s'={...s,nestedActive:true,activeClaim:2,n:s.n+1,extra:true}}
  action nestedLeave=all {s.nestedActive,s'={...s,nestedActive:false,nestedDone:true,activeClaim:if(s.bug==17) 2 else 1,n:s.n-1,extra:false}}
  action releaseLocks=all {s.pc==12,s.locks>0,s'={...s,locks:s.locks-1}}
  action finishNative=all {s.pc==12,s.locks==0,not(s.finished),s'={...s,errorPending:false,handled:s.hadError,finished:true}}
  action closureMutant=any {
    all {s.bug==12,s.pc==2,s'={...s,mutexHeld:true}},
    all {s.bug==13,s.pc==3,s'={...s,carrier:false}},
    all {s.bug==15,s.pc==3,s.locks>0,s'={...s,unwound:true}},
    all {s.bug==16,s.errorPending,s'={...s,errorPending:false}},
    all {s.bug==17,s.nestedDone,s.activeClaim!=1,s'={...s,granted:false}},
    all {s.bug==18,s.pc==4,s.n==0,s'={...s,afterPut:true}},
    all {s.bug==19,s.pc==6,s'={...s,carrier:false}},
    all {s.bug==20,s.served,s'={...s,executions:2}}
  }
'''
  base=base.replace('  action idle=',extra+'  action idle=')
  base=base.replace('pollMiss,mutant,idle}', 'pollMiss,mutant,saveRoots,moveRoots,reloadRoots,nestedEnter,nestedLeave,releaseLocks,finishNative,closureMutant,idle}')
  base=base.replace('  val safe=all {','  val priorSafe=all {')
  base=base.replace('  val goal=', '''  val safe=all {priorSafe,s.carrier,not(s.mutexHeld),not(s.unwound),not(s.afterPut),s.executions<=1,
    not(s.served) or (s.rootSaved and s.usedVersion==s.rootVersion),
    not(s.nestedDone) or s.activeClaim==1,
    not(s.hadError) or s.errorPending or s.handled,
    not(s.handled) or s.locks==0}
  val priorGoal=''')
  base=base.replace('  temporal fairness=', '  val goal=s.finished\n  temporal fairness=')
  base=base.replace('weakFair(pollMiss,Set(s))}', 'weakFair(pollMiss,Set(s)),weakFair(saveRoots,Set(s)),weakFair(moveRoots,Set(s)),weakFair(reloadRoots,Set(s)),weakFair(nestedEnter,Set(s)),weakFair(nestedLeave,Set(s)),weakFair(releaseLocks,Set(s)),weakFair(finishNative,Set(s))}')
  model=R/'models/gambit/drain_sync_closure.qnt';model.write_text(base)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  results=[]
  for name in names:
   d=out/name;d.mkdir();p=d/model.name
   p.write_text(re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]=='init'+name else '',base,flags=re.M))
   row,log,trace=check(p,initializer='init'+name,invariant='safe',negative=name not in pos,temporal='progress' if name in pos else None,timeout=30,cwd=d,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (d/'check.log').write_text(log)
   if trace:(d/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(case=name,kind='positive' if name in pos else 'negative',path=str(d.relative_to(R)));results.append(row)
   print(name,row['accepted'],row['seconds'],flush=True)
  receipt=dict(schema='drain-sync-closure.v1',sourceReceipt=old['sourceReceipt'],sourceFiles=source['files'],candidate=str(c.relative_to(R)),lock=old['lock'],lockSha256=old['lockSha256'],patch=old['patch'],patchSha256=old['patchSha256'],callers=rows,compilerControls=controls,model=str(model.relative_to(R)),modelSha256=sha(model),rows=results,allAccepted=all(x['accepted'] for x in results),protectedInputs=old['protectedInputs'],runtimeChanged=False,nativeExecutions=0,compilerAssemblyOnly=True)
  assert all(sha(R/p)==h for p,h in old['protectedInputs'].items())
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
  print('OUTPUT',out,'ALL',receipt['allAccepted'],flush=True)
if __name__=='__main__':run()
