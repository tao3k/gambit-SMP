"""Evidence-only stable-cohort private reservation controls; no native execution."""
from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
ROOT=Path(__file__).resolve().parents[3]
NAMES=['initAbortRetry', 'initPrefixAbort', 'initNativeCleanupFault', 'initPostCommitCancel', 'initCapacityRefusal', 'initHeldPublisher', 'initExistingAllocationPrefix', 'initEagerGlobalMutation', 'initBlindRewindAfterCommit', 'initGcDuringClaim', 'initLeaseToStaged', 'initCheckThenPin', 'initStaleGenerationLease', 'initDropAcceptedQueue', 'initFreeWithPublisher', 'initDropFaultCarrier', 'initAbortClearsDebt', 'initClaimLivePage', 'initRawUnleasedPublish', 'initReuseRetainedSlot', 'initDropClaimBeforeViews', 'initWaitNativeCleanupForGc', 'initAssumePublisherReleases']
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/private-reservation-admission-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/private_reservation_admission.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='private-reservation-admission-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();neg=7<=i<21;temporal=('unconditionalQuiescence' if i==22 else 'progress') if not neg else None
   row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=neg,temporal=temporal,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if neg:
    row['expected']='invariant-counterexample';row['witness']=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('violation')==i-6),None)
    row['accepted']=bool(row['accepted'] and row['witness'])
   elif i>=21:
    row['expected']='temporal-counterexample';row['backendAccepted']=row['accepted']
    cleaned=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
    try:trace=counterexample(cleaned)
    except ValueError:trace=None
    loop=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
    row['cycleMarker']=loop.group(0) if loop else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and
      re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and trace and
      row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
    if trace:(case/'counterexample.json').write_text(json.dumps(trace,indent=2)+'\n')
   else:row['expected']='safety-and-conditional-progress'
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(x['accepted'] for x in receipt['rows'])
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),row.get('cycleMarker'),flush=True)
   if 'parsing failed' in log or 'typechecking failed' in log:break
  print(out,flush=True)
 if not receipt['allAccepted']:raise RuntimeError('private reservation controls incomplete; retained result is not a pass')
if __name__=='__main__':main()
