"""Bounded source-correspondence and conditional QNT checks; no native execution."""
from pathlib import Path
import json,hashlib,importlib.util,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['TwoOwners','SetupRetry','PartialClaim','SetupReentry','Cut5','RefusedCut','CloseInflight','RepeatSetup','Exhaustion','StaleToken','PrepareFailure','PreparingReentry','OwnerSetupFailure','BeforePrepareFailure','LocalRetry']
NEG=['ResetSession','ReclaimSlot','ReenterPrepare','MixedCut5','UncommittedCut','OldToken','TokenBeforeFooter','OldAttachment','NestedWriter','ClaimBeforeReady','LocalStaleCapability']
GOALS={
 'TwoOwners':'s.fired and s.ready==Set(0,1) and s.rejected and s.tokenStage==2',
 'SetupRetry':'s.finished and s.epoch==2 and s.mapping and not(s.opened)',
 'PartialClaim':'s.finished and s.epoch==2 and s.used.contains(0) and not(s.ready.contains(0))',
 'SetupReentry':'s.finished and s.reentered and s.rejected and s.prepares==1',
 'Cut5':'s.read and not(s.accepted) and s.prevOk and s.footer==0',
 'RefusedCut':'s.finished and s.rejected and not(s.fired) and s.token==0',
 'CloseInflight':'s.fired and s.certified and s.closedDuring and not(s.opened)',
 'RepeatSetup':'s.finished and s.epoch==2 and s.counts.get(0)==1 and not(s.attached)',
 'Exhaustion':'s.finished and s.seq==2 and s.token==0 and not(s.fired)',
 'StaleToken':'s.finished and s.rejected and s.seq==1 and s.token==0 and not(s.fired)',
 'PrepareFailure':'s.finished and s.epoch==2 and not(s.mapping) and s.prepares==1',
 'PreparingReentry':'s.finished and s.reentered and s.rejected and s.prepares==1',
 'OwnerSetupFailure':'s.finished and s.epoch==2 and s.ready.contains(0) and s.counts.get(0)==1 and not(s.attached)',
 'BeforePrepareFailure':'s.finished and s.epoch==2 and not(s.mapping) and s.prepares==0',
 'LocalRetry':'s.finished and s.epoch==1 and s.opened and s.ready==Set(0,1) and s.counts.get(0)==1 and not(s.cap)'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 protected=json.loads((E/'diagnostic-order-id-generated-c.json').read_text())['protectedInputs'];before={p:sha(R/p) for p in protected}
 spec=importlib.util.spec_from_file_location('carrier',E/'verify-scan-carrier-source.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
 files,_,prior=m.materialize();lockpath=R/'evidence/research/processor-interrupt-collective-wait/scan-diag-prepare.lock.json';lock=json.loads(lockpath.read_text());patch=(R/lock['patch']).read_text();assert sha(R/lock['patch'])==lock['patchSha256']
 current={}
 for name,v in lock['files'].items():
  base=m.apply_file(files[name],(R/prior['patch']).read_text(),name,True);assert hashlib.sha256(base.encode()).hexdigest()==v['baseSha256']
  current[name]=m.apply_file(base,patch,name);assert hashlib.sha256(current[name].encode()).hexdigest()==v['candidateSha256']
 symbols=['___setup','___setup_vmstate','___setup_pstate','___cleanup_checked','___gc_diag_prepare_process','gc_diag_bind_owner','gc_diag_publish','___gc_diag_arm','gc_diag_cut','gc_diag_attached']
 calls={symbol:[dict(file=p,line=i+1,text=t.strip()) for p,c in current.items() for i,t in enumerate(c.splitlines()) if re.search(r'\b'+re.escape(symbol)+r'\b',t)] for symbol in symbols}
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/scan-session-commit-model');out.mkdir(parents=True,exist_ok=True)
  model=R/'models/gambit/scan_session_commit.qnt';code=model.read_text()
  (out/'source-call-index.json').write_text(json.dumps(calls,indent=2)+'\n')
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='scan-session-commit-model.v1',model=str(model.relative_to(R)),modelSha256=sha(model),lock=str(lockpath.relative_to(R)),lockSha256=sha(lockpath),lockedFiles=len(current),sourceCallIndex=str((out/'source-call-index.json').relative_to(R)),sourceCallIndexSha256=sha(out/'source-call-index.json'),perCaseTimeoutSeconds=30,nativeRuns=0,nativeAdmitted=False,rows=[],allAccepted=False)
  cases=[(n,None) for n in POS+NEG]+[(n,g) for n,g in GOALS.items()]
  for name,goal in cases:
   case=out/(name+('-reachable' if goal else ''));case.mkdir()
   projected=re.sub(r'^  action init(\w+)=.*\n',lambda x:x[0] if x[1]==name else '',code,flags=re.M)
   if goal:projected=projected.rsplit('}',1)[0]+'  val targetNotReached=not('+goal+')\n}\n'
   snapshot=case/model.name;snapshot.write_text(projected)
   negative=bool(goal or name in NEG)
   row,log,trace=check(snapshot,initializer='init'+name,invariant='targetNotReached' if goal else 'safe',negative=negative,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   row.update(initializer='init'+name,kind='reachability' if goal else 'mutant' if negative else 'safety',goal=goal,evidenceDirectory=str(case.relative_to(R)))
   if negative:
    row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
    row['witness']=(trace or {}).get('states',[{}])[-1].get('s')
   result['rows'].append(row);(out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n')
   print(name,row['kind'],row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected model outcome; retained logs at '+str(case))
  result['allAccepted']=all(x['accepted'] for x in result['rows']);result['protectedInputsUnchanged']=before=={p:sha(R/p) for p in protected};assert result['protectedInputsUnchanged']
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
