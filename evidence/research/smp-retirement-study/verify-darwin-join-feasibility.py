"""Evidence-only: distinguish OS join returns from deferred retirement."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['initPlatform','initDeferred','initInventError','initBreakCycle','initReturnEintr','initBusyAsErrno','initFreePendingRoots','initJoinTwice','initCancelTarget','cancelTargetReachability']
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/darwin-join-feasibility-model');out.mkdir(parents=True,exist_ok=True)
  m=ROOT/'models/gambit/darwin_join_feasibility.qnt';snapshot=out/m.name;snapshot.write_bytes(m.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='darwin-join-feasibility-model.v1',modelSha256=hashlib.sha256(m.read_bytes()).hexdigest(),rows=[],runtimeAdmitted=False,nativeAdmitted=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();row,log,trace=check(snapshot,initializer='initCancelTarget' if i==9 else name,invariant='notRecovered' if i==9 else 'safe',negative=(2<=i<=7 or i==9),temporal='completion' if i==1 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if 2<=i<=7:
    row['witness']=next((v['s'] for v in reversed((trace or {}).get('states',[])) if v.get('s',{}).get('bug')==i-1),None)
    row['accepted']=bool(row['accepted'] and row['witness'])
   if i==9:
    row['witness']=next((v['s'] for v in reversed((trace or {}).get('states',[])) if v.get('s',{}).get('targetCanceled') and v['s'].get('first')==11 and v['s'].get('second')==0),None)
    row['accepted']=bool(row['accepted'] and row['witness']);row['classification']='wider-API reachability witness, not a repair or native admission'
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=all(x['accepted'] for x in receipt['rows']);(out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
  print(out,flush=True)
  if not receipt['allAccepted']:raise RuntimeError('feasibility controls failed')
if __name__=='__main__':main()
