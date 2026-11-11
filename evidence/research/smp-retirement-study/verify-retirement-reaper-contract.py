"""Evidence/QNT only: pending retirement and fixed native reaper ownership."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['initNormal','initRollback','initStartupFail','initHardFailure','initNotificationFail','initStuckWorker','initEarlyCommit','initDuplicateJoin','initWrongOwner','initStaleCompletion','initEarlyReclaim','initDropRoots','initDestroyRetained','initPendingAsErrno','initDropMailbox','initDropPriorRoots']
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/retirement-reaper-contract-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/retirement_reaper_contract.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='retirement-reaper-contract-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False,contractMigrationAdmitted=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=i>=6,temporal='completion' if i<6 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if i>=6:
    row['witness']=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i-5),None);row['accepted']=bool(row['accepted'] and row['witness'])
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=all(x['accepted'] for x in receipt['rows']);(out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
  print(out,flush=True)
  if not receipt['allAccepted']:raise RuntimeError('reaper contract model controls failed')
if __name__=='__main__':main()
