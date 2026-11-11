"""Run checked-retention/winding-boundary positive and decoded negatives."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['init','initUnlinkBeforeClose','initFreeGroupOnError','initClosedStageForgetsError','initCallbackEscapes','initCallbackReentry','initFreeRootsBeforeIo','initFailedReleaseFrees','initFreeBeforeForeignHandoff','initTerminateCoordinator','initSuspendCoordinator']
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/device-callback-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/device_callback_retention.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='device-callback-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=i>0,temporal='completion' if i==0 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if i:
    row['witness']=next((v['s'] for v in reversed((trace or {}).get('states',[])) if v.get('s',{}).get('bug')==i),None);row['accepted']=bool(row['accepted'] and row['witness'])
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=all(r['accepted'] for r in receipt['rows']);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(name,row['accepted'],row.get('seconds'),flush=True)
  print(out,flush=True)
  if not receipt['allAccepted']:raise RuntimeError('device/callback model control failed')
if __name__=='__main__':main()
