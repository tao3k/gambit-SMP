"""Root/publication evidence only; not a C11 model checker or runtime test."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['init','initNoReadyRelease','initNoReadyAcquire','initNoDoneRelease','initNoDoneAcquire','initReadBeforeAcquire','initOverwriteBeforeConsume','initRawFrameCommit','initMissingStillScan','initCallbackAfterFreeze','initFreeWithScanLease','initPublishBeforePayload','initStaleEpoch','initUnrootedCarrier','initProducerAfterDone','initPartialExport','initSkipSecondRcScan','initNoPreparedRelease','initNoPreparedAcquire']
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/reaper-root-publication-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/reaper_root_publication.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='reaper-root-publication-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False,c11ExecutionModel=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=i>0,temporal='completion' if i==0 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if i:
    row['witness']=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i),None);row['accepted']=bool(row['accepted'] and row['witness'])
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(x['accepted'] for x in receipt['rows']);(out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if 'parsing failed' in log or 'typechecking failed' in log:break
  print(out,flush=True)
 if not receipt['allAccepted']:raise RuntimeError('root/publication controls failed; retained audit receipt')
if __name__=='__main__':main()
