"""Evidence-only finalization protocol; does not patch runtime or qualify9/12."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['Success','PreflightRefusal','PartialRollForward','DestroyFailure','UnlockUncertain','HeldReader','EarlyDomainRemove','DoubleSplice','DoubleAccount','ErasePartialLog','IgnoreDestroyFailure','DropFinalizerPin','TransferWithReader','CallbackInCleanup','RejoinAfterPartial','ResumeAfterUnknownUnlock','DropCarrierBeforeDest','CommitWithoutIntent']
def violation(s,b):
 s=dict(s)
 for k in ('moved','intent'):
  if isinstance(s[k],dict):s[k]=s[k]['$integerSet']
 return {1:lambda:not s['domain'] and s['owners'][1]!=1,
  2:lambda:s['transfers'][0]==2,3:lambda:s['recvWords']!=len(s['moved']),
  4:lambda:s['owners'][0]==1 and 1 not in s['moved'],
  5:lambda:s['freed'] and not s['destroyed'],6:lambda:not s['freed'] and not s['pin'],
  7:lambda:s['readers']>0 and bool(s['moved']),8:lambda:s['callback'],
  9:lambda:s['calls']==2,10:lambda:s['uncertain'] and not s['exclusive'],
  11:lambda:not s['carrier'] and not s['destRoots'],
  12:lambda:not set(s['moved']).issubset(set(s['intent']))}[b]()
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/post-join-finalize-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/post_join_finalize.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='post-join-finalize-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,contractMigrationAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir()
   row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=i>=6,temporal='completion' if i<6 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=6:
    witness=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i-5 and violation(x['s'],i-5)),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(r['accepted'] for r in receipt['rows'])
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected checker result; retained failure')
  print(out,flush=True)
if __name__=='__main__':main()
