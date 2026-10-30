from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Return','PrefixError','ResultError','Callback','CallbackError','ReparkRetained','InlineRefusal','HookRefusal','NativeUnknown','PrepareError']
NEG=['UnwindHost','LegacyErrorUnwind','DoubleBody','PrefixLeak','DoubleArgFree','MissingRoot','KillRunMarker','ResultWhileParked','ReturnBeforeRepark','ChildOwnsLoan','DropCallbackTail','AtEndEarly','PrefixBeforeJournal','ReplayUnknownBody','MissingResultRoot','ReturnedCatcher','MissingNativeCatcher']
TARGETS={'CallbackTail':('Callback','s.phase==8 and s.hostAlive and s.cbLive and not(s.cbMarker) and s.cbTail and s.active'),
 'ParkedCallbackReturn':('Callback','s.phase==9 and not(s.active) and s.hostAlive and s.cbLive and s.cbLoanOwner==1'),
 'ResultFailureAfterHook':('ResultError','s.phase==15 and s.error and s.hookCount==1 and s.argFrees==1'),
 'PrefixFailureCleanup':('PrefixError','s.phase==15 and s.error and s.calls==0 and s.argFrees==1'),
 'RetainedRepark':('ReparkRetained','s.phase==12 and s.active and s.hostAlive and s.cbTail and s.root and s.journal')}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(s):
 return s['parentMarker'] and s['catcherOwner'] in (1,2) and (s['catcherOwner']!=2 or (s['cbLive'] and s['cbMarker'])) and (not s['schemeResult'] or s['resultBit']==s['gcBit']) and s['calls']<=1 and s['argFrees']<=1 and s['cbLoanFrees']<=1 and s['hookCount']<=1 and (not s['root'] or (s['jobPin'] and s['journal'] and s['rootBit']==s['gcBit'])) and (not s['cbRoot'] or s['cbBit']==s['gcBit']) and (not s['argHeld'] or (s['jobPin'] and s['journal'])) and (not s['cbLoan'] or (s['cbLoanOwner']==1 and s['jobPin'] and s['journal'])) and (not s['bodyEntered'] or s['bodyDone'] or s['hostAlive']) and (not(s['hostAlive'] and not s['cbLive']) or not s['active']) and (not s['cbLive'] or (s['hostAlive'] and s['cbTail'] and s['jobPin'])) and (not s['resultConverted'] or (s['bodyDone'] and s['active'])) and (s['hookCount']==0 or (s['bodyDone'] and s['resultConverted'])) and (not s['retained'] or (s['root'] and s['journal'] and s['jobPin'])) and (s['phase']!=15 or (not s['argHeld'] and not s['cbLoan'])) and (not s['refused'] or (s['calls']==0 and not s['bodyEntered']))
def target(s,g):
 if g=='CallbackTail':return s['phase']==8 and s['hostAlive'] and s['cbLive'] and not s['cbMarker'] and s['cbTail'] and s['active']
 if g=='ParkedCallbackReturn':return s['phase']==9 and not s['active'] and s['hostAlive'] and s['cbLive'] and s['cbLoanOwner']==1
 if g=='ResultFailureAfterHook':return s['phase']==15 and s['error'] and s['hookCount']==1 and s['argFrees']==1
 if g=='PrefixFailureCleanup':return s['phase']==15 and s['error'] and s['calls']==0 and s['argFrees']==1
 if g=='RetainedRepark':return s['phase']==12 and s['active'] and s['hostAlive'] and s['cbTail'] and s['root'] and s['journal']
 raise ValueError(g)
def project(code,name,observer=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return s[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else s
def main():
 protected=json.loads((E/'checked-park-source-protocol.json').read_text())['protectedInputs'];assert all(sha(R/n)==h for n,h in protected.items())
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/staged-ffi-stack');out.mkdir(parents=True)
  model=R/'models/gambit/staged_ffi_stack.qnt'
  code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='staged-ffi-stack.v1',model=str(model.relative_to(R)),modelSha256=sha(model),nativeExecutions=0,nativeAdmitted=False,perCaseTimeoutSeconds=30,protectedInputs=protected,rows=[],allAccepted=False)
  cases=[(n,'positive',None) for n in POS]+[(n,'negative',None) for n in NEG]+[(n,'reachability',g) for g,(n,_) in TARGETS.items()]
  for n,kind,g in cases:
   case=out/(n+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+n,TARGETS[g][1] if g else None))
   row,log,trace=check(p,initializer='init'+n,invariant='targetNotReached' if g else 'safe',negative=kind!='positive',temporal='progress' if kind=='positive' else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if kind!='positive':
    w=next((x['s'] for x in (trace or {}).get('states',[]) if target(x['s'],g)),None) if g else next((x['s'] for x in (trace or {}).get('states',[]) if not safe(x['s'])),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   row.update(initializer='init'+n,kind=kind,goal=g,evidenceDirectory=str(case.relative_to(R)));res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(n,kind,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected staged FFI control')
  res['allAccepted']=len(res['rows'])==32 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in protected.items());res['protectedInputsUnchanged']=True
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
