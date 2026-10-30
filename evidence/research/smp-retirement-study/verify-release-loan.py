from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd()
NAMES=['Concurrent','Export','PrefixFailure','SupportedUnwind','UnknownCallback','RawSnapshot','ClaimWithLoan','EarlyLoanEnd','EarlyVmDrop','PrefixLeak','AliasWithoutLoan','DoubleClaim','RetryUnknown','RawUseAfterRelease','CheckThenBorrow','WrongUnwindFrame','StaleLoanToken','LastLoanCallback']
TARGETS={'Export':'s.aliasDone and s.vmFree and s.busy','UnknownCallback':'s.op==4 and s.closed and s.scopes.size()==0 and s.started.contains(1) and s.tails.contains(1)','PrefixFailure':'s.ended.contains(1) and not(s.started.contains(1)) and s.tails.contains(1) and s.vmFree','SupportedUnwind':'s.started.contains(1) and not(s.results.contains(1)) and s.tails.contains(1) and s.vmFree'}
def normalize(x):
 if isinstance(x,dict):
  if set(x)=={"$integerSet"}:return x["$integerSet"]
  return {k:normalize(v) for k,v in x.items()}
 if isinstance(x,list):return [normalize(v) for v in x]
 return x
def safe(s):
 loans=set(s['loans']);scopes=set(s['scopes']);using=set(s['using'])
 return not s['bad'] and s['calls']<=1 and s['refs']==len(scopes)+int(s['pin'])+int(s['alias'] and not s['aliasDone']) and using<=loans and loans-{3}<=scopes and (s['op']<2 or not loans) and (not s['freed'] or not loans) and (not s['vmFree'] or (s['closed'] and s['refs']==0)) and not(set(s['ended'])&loans) and (not s['callback'] or (s['op']==2 and s['pin'])) and (s['op']!=4 or s['pin'])
def main():
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/release-loan-composition');out.mkdir(parents=True)
  model=R/'models/gambit/release_loan_composition.qnt';code=model.read_text();cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='release-loan-composition.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30)
  cases=[(n,None) for n in NAMES]+[(n,n) for n in TARGETS]
  for i,(suffix,goal) in enumerate(cases):
   name='init'+suffix;case=out/(name+('-goal' if goal else ''));case.mkdir();compiled=case/model.name
   projected=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M)
   if goal:projected=projected[:-2]+'  val targetNotReached=not('+TARGETS[goal]+')\n}\n'
   compiled.write_text(projected)
   row,log,trace=check(compiled,initializer=name,invariant='targetNotReached' if goal else 'safe',negative=bool(goal or i>=6),timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=6:
    states=[normalize(x['s']) for x in (trace or {}).get('states',[])]
    if goal:
     def target(s):
      if goal=='Export':return s['aliasDone'] and s['vmFree'] and s['busy']
      if goal=='UnknownCallback':return s['op']==4 and s['closed'] and not s['scopes'] and 1 in s['started'] and 1 in s['tails']
      return 1 in s['tails'] and s['vmFree'] and (1 not in s['started'] if goal=='PrefixFailure' else 1 in s['started'] and 1 not in s['results'])
     witness=next((s for s in states if target(s)),None)
    else:witness=next((s for s in states if not safe(s)),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   row.update(initializer=name,caseName=case.name,goal=goal);res['rows'].append(row);res['allAccepted']=len(res['rows'])==len(cases) and all(x['accepted'] for x in res['rows'])
   (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(case.name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected result: '+str(case))
  print(out,flush=True)
if __name__=='__main__':main()
