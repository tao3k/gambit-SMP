from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['BeforeClose','Registered','Stale','Forged','OrdinaryClosed','ModeAba','WrongStep','Spent']
NEG=['CachedKey','SkipRegistration','UnpinnedRead','WeakAck','EarlyPut','ResetCount','SealedEntry','ReopenEarly','StaleAck','SkipStep','ReuseSpent']
TEMP=['BlockingMutex','WaitCount','FlagOnly']
TARGETS={'ServicedWithThreadLock':('Registered','s.pc==4 and s.served and s.heldT and s.threadRoot and s.n==0'),
 'AckReadyWriterHeld':('Registered','s.pc==6 and s.writer and s.ackState==2 and s.n==1'),
 'ReopenKeepsResultRef':('Registered','s.pc==12 and s.ctl==0 and s.gen==2 and s.waitRef and s.n==0'),
 'ModeAbaRejected':('ModeAba','s.pc==11 and s.rotated and s.gen==2 and s.rejected and s.n==0')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(s):
 n=sum(int(s[k]) for k in ['lookup','comm','writer','extra','waitCounted'])
 return s['n']==n and s['heldT'] and s['threadRoot'] and not s['rawRead'] and (not s['granted'] or (s['registered'] and s['capStep']==1 and not s['spent'] and (s['pc']==12 or s['expected']==s['gen']))) and (s['ackState']!=2 or (s['payloadInit'] and s['payloadGen']==s['expected'])) and (not s['go'] or (s['zeroSeen'] and s['n']==0)) and (s['pc']!=12 or (s['newKeyInit'] and s['gen']==2 and s['seen']))
def goal(s):
 return (s['pc']==11 and s['rejected'] and s['n']==0) if s['mode'] in [2,3,4,5,9,10] else (s['pc']==12 and s['served'] and s['ctl']==0)
def target(s,g):
 if g=='ServicedWithThreadLock':return s['pc']==4 and s['served'] and s['heldT'] and s['threadRoot'] and s['n']==0
 if g=='AckReadyWriterHeld':return s['pc']==6 and s['writer'] and s['ackState']==2 and s['n']==1
 if g=='ReopenKeepsResultRef':return s['pc']==12 and s['ctl']==0 and s['gen']==2 and s['waitRef'] and s['n']==0
 if g=='ModeAbaRejected':return s['pc']==11 and s['rotated'] and s['gen']==2 and s['rejected'] and s['n']==0
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 protected=json.loads((E/'checked-park-source-protocol.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in protected.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/drain-cap-admission');out.mkdir(parents=True)
  model=R/'models/gambit/drain_cap_admission.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='drain-cap-admission.v1',model=str(model.relative_to(R)),modelSha256=sha(model),nativeExecutions=0,nativeAdmitted=False,perCaseTimeoutSeconds=30,protectedInputs=protected,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'negative',None) for n in NEG]+[(n,'temporal-negative',None) for n in TEMP]+[(n,'reachability',g) for g,(n,_) in TARGETS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,TARGETS[g][1] if g else None))
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind in {'negative','reachability'},temporal='progress' if kind in {'positive','temporal-negative'} else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if kind=='temporal-negative':
    from gambit_smp.quint_backend import counterexample
    loop=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
    try:trace=counterexample(re.split(r'^State \d+: Stuttering',log,flags=re.M)[0])
    except ValueError:trace=None
    states=[x['s'] for x in (trace or {}).get('states',[])]
    row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and states and all(safe(z) and not goal(z) for z in states) and row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
    if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   elif kind!='positive':
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g)),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected epoch/reclaim control')
  res['allAccepted']=len(res['rows'])==26 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in protected.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
