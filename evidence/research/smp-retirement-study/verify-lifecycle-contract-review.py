"""Evidence only; does not implement or authorize a replacement qualifier."""
from pathlib import Path
import hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
NAMES=['Success','RetainedError','PendingErrno','WrongOwner','WrongIncarnation','StaleKey','ProducerDrift','NoAcquire','NoGrace','LoseRoot','DuplicateJoin','FakeZero','ClearDebt','ClearError']
def violation(s,b):
 return {1:lambda:s['errno']==11 and not s['retained'],2:lambda:s['acceptedOwner']!=s['owner'],3:lambda:s['acceptedIncarnation']!=s['incarnation'],4:lambda:s['acceptedKey']!=s['key'],5:lambda:s['acceptedProducer']!=s['producer'],6:lambda:s['phase']==5 and not s['acquired'],7:lambda:s['transfers']==1 and not s['grace'],8:lambda:not s['roots'] and s['phase']==1,9:lambda:s['calls']==2,10:lambda:s['nativeZero'] and not s['exited'],11:lambda:s['phase']==1 and not s['debt'],12:lambda:s['retained'] and not s['debt']}[b]()
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/lifecycle-contract-review-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/lifecycle_contract_review.qnt';snap=out/model.name;snap.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='lifecycle-contract-review-model.v1',modelSha256=hashlib.sha256(snap.read_bytes()).hexdigest(),nativeAdmitted=False,contractMigrationAdmitted=False,timeoutPerCaseSeconds=30,rows=[])
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir()
   row,log,trace=check(snap,initializer=name,invariant='safe',negative=i>=2,temporal='completion' if i<2 else None,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if i>=2:
    witness=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i-1 and violation(x['s'],i-1)),None)
    row['witness']=witness;row['accepted']=bool(row['accepted'] and witness)
   result['rows'].append(dict(initializer=name,**row));result['allAccepted']=all(r['accepted'] for r in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('model control did not meet expectation; retained receipt')
  print(out,flush=True)
if __name__=='__main__':main()
