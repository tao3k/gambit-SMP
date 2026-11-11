"""Bounded conditional QNT controls; no native workloads or runtime edits."""
from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['PendingPub','Queued','Active','PostTransfer','Empty','Handoff','UnsafeHandoff','Blocked','Partial']
NEG=['Unregistered','OpenCheck','LocalReject','LateMutation','DropRoot','RawCarrier','BlindAbandon','StaleOwner','EarlyDrop','LateAccess','OwnerOnly','ReleaseBeforeSender']
GOALS={'PendingPub':'s.refused and s.returned and s.n==2 and s.hint==1 and s.callerLive',
 'Queued':'s.refused and s.returned and s.n==2 and s.hint==2',
 'Empty':'s.committed and s.n==1 and s.count==0',
 'Handoff':'s.committed and s.n==1 and s.hint==3 and s.hroot and s.count==2',
 'UnsafeHandoff':'s.refused and s.returned and s.n==2 and s.qdom==1',
 'Blocked':'s.refused and s.returned and s.req==2 and s.owner==1',
 'Active':'s.cleanup and s.abandoned and s.owner==0 and s.released and not(s.senderLive)',
 'Partial':'s.cleanup and s.partial and not(s.linked) and not(s.abandoned) and s.count==1 and s.n==2',
 'PostTransfer':'s.cleanup and not(s.abandoned) and s.owner==0 and s.req==5 and s.released'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def main():
 binding=json.loads((E/'delivery-function-alignment.json').read_text());lock=R/binding['sourceLock'];assert sha(lock)==binding['sourceLockSha256']
 protected=json.loads((E/'diagnostic-order-id-generated-c.json').read_text())['protectedInputs'];before={p:sha(R/p) for p in protected}
 model=R/'models/gambit/delivery_shrink_release.qnt';code=model.read_text()
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/delivery-shrink-release');out.mkdir(parents=True,exist_ok=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=1,maxHeap='-Xmx1G',stackSize='-Xss8m')))
  report=dict(schema='delivery-shrink-release-model.v1',model=str(model.relative_to(R)),modelSha256=sha(model),sourceLock=binding['sourceLock'],sourceLockSha256=sha(lock),sourceRefinementAdmitted=False,nativeRuns=0,perCaseTimeoutSeconds=30,rows=[],allAccepted=False)
  cases=[(n,False,None,'safety') for n in POS]+[(n,True,None,'mutant') for n in NEG]+[(n,True,g,'reachability') for n,g in GOALS.items()]
  for name,negative,goal,kind in cases:
   case=out/(name+'-'+kind);case.mkdir()
   code2=re.sub(r'^  action init(\w+)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
   if goal:code2=code2.rsplit('}',1)[0]+'  val targetNotReached=not('+goal+')\n}\n'
   snap=case/model.name;snap.write_text(code2)
   row,log,trace=check(snap,initializer='init'+name,invariant='targetNotReached' if goal else 'safe',negative=negative,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if negative:row['accepted']=bool(row['accepted'] and trace and len(trace.get('states',[]))>1)
   row.update(initializer='init'+name,kind=kind,goal=goal,evidenceDirectory=str(case.relative_to(R)))
   if negative:row['witness']=(trace or {}).get('states',[{}])[-1].get('s')
   report['rows'].append(row);(out/'receipt.json').write_text(json.dumps(report,indent=2)+'\n');print(name,kind,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected result retained at '+str(case))
  report['allAccepted']=all(r['accepted'] for r in report['rows']);report['protectedInputsUnchanged']=before=={p:sha(R/p) for p in protected};assert report['protectedInputsUnchanged'];assert sha(lock)==binding['sourceLockSha256']
  (out/'receipt.json').write_text(json.dumps(report,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
