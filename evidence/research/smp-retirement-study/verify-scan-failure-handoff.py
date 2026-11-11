"""Check only the split failure-window model in registered audit custody."""
from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Interrupt','OsMemory','Sync','VmPublish','DirectGlobal','CleanupAccepted','CleanupRefused','BeforePrepare','LiveCleanupRefusal']
NEG={'RetryOnly':'safe','MissingOsRevoke':'safe','MissingSyncRevoke':'safe','VmLateRevoke':'safe','DirectGlobalOpen':'safe','RefusedCleanupOpen':'closedOnRefusal','LateArm':'noLateAdmission','GlobalCloseLocal':'safe','CloseLiveRefusal':'safe'}
GOALS={
 'Interrupt': 's.finished and s.checked and s.retryRefused and not(s.admitted) and s.claims==1 and s.otherCap',
 'OsMemory': 's.finished and s.cleanup and s.retryRefused and s.otherCap',
 'Sync': 's.finished and s.cleanup and s.retryRefused and s.otherCap',
 'VmPublish': 's.finished and s.cleanup and s.revoked and s.retryRefused',
 'DirectGlobal': 's.finished and s.returned and not(s.opened) and s.mapping',
 'CleanupAccepted': 's.finished and s.returned and s.cleanup and not(s.opened)',
 'CleanupRefused': 's.finished and s.fatal and s.escaped and s.repeated and not(s.opened) and s.mapping',
 'BeforePrepare': 's.finished and not(s.mapping) and not(s.opened)',
 'LiveCleanupRefusal': 's.finished and s.refused and s.opened and s.otherCap'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 prior=json.loads((E/'scan-session-cut-implementation.json').read_text());lock=R/prior['lock'];assert sha(lock)==prior['lockSha256'];assert sha(R/prior['patch'])==prior['patchSha256']
 returns=R/prior['returnIndex'];assert returns.is_file()
 protected=json.loads((E/'diagnostic-order-id-generated-c.json').read_text())['protectedInputs'];before={p:sha(R/p) for p in protected}
 model=R/'models/gambit/scan_failure_handoff.qnt';code=model.read_text()
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/scan-failure-handoff');out.mkdir(parents=True,exist_ok=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='scan-failure-handoff-model.v1',model=str(model.relative_to(R)),modelSha256=sha(model),lock=prior['lock'],lockSha256=sha(lock),returnIndex=prior['returnIndex'],returnIndexSha256=sha(returns),nativeRuns=0,sourceRefinementAdmitted=False,perCaseTimeoutSeconds=30,rows=[],allAccepted=False)
  cases=[(n,'safe',False,None,'safety') for n in POS]+[(n,inv,True,None,'mutant') for n,inv in NEG.items()]+[(n,'targetNotReached',True,g,'reachability') for n,g in GOALS.items()]
  cases+=[('CleanupRefused','targetNotReached',True,'s.terminated and s.fatal and not(s.opened) and s.mapping','termination-witness')]
  for name,invariant,negative,goal,kind in cases:
   case=out/(name+'-'+kind);case.mkdir()
   projected=re.sub(r'^  action init(\w+)=.*\n',lambda x:x[0] if x[1]==name else '',code,flags=re.M)
   if goal:projected=projected.rsplit('}',1)[0]+'  val targetNotReached=not('+goal+')\n}\n'
   snapshot=case/model.name;snapshot.write_text(projected)
   row,log,trace=check(snapshot,initializer='init'+name,invariant=invariant,negative=negative,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+name,kind=kind,invariant=invariant,goal=goal,evidenceDirectory=str(case.relative_to(R)))
   if negative:
    row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
    row['witness']=(trace or {}).get('states',[{}])[-1].get('s')
   result['rows'].append(row);(out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected model result retained at '+str(case))
  result['allAccepted']=all(x['accepted'] for x in result['rows']);result['protectedInputsUnchanged']=before=={p:sha(R/p) for p in protected};result['lockUnchanged']=sha(lock)==prior['lockSha256'];assert result['protectedInputsUnchanged'] and result['lockUnchanged']
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
