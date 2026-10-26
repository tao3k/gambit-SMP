"""Evidence-only recurrent-GC and independent join-lane model controls."""
from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
ROOT=Path(__file__).resolve().parents[3]
NAMES=['initAllFinish', 'initBlockedA', 'initJoinErrorB', 'initGraceA', 'initCapacityRefusal', 'initFinalizeErrorA', 'initStrictGcPriority', 'initSerialReaper', 'initGlobalGraceGate', 'initUnfairScheduler', 'initSharedOwner', 'initDropBlockedRoot', 'initFreePinnedVm', 'initIgnoreScanLease', 'initPartialTransferLoss']

def classify_temporal(row,log,name,case):
 row['backendAccepted']=row.get('backendAccepted',row['accepted'])
 row['expected']='temporal-counterexample'
 # Stuttering is TLC's edge marker, not an additional state assignment.
 # Preserve the raw log; strip only this marker for the shared value decoder.
 cleaned=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
 try:trace=counterexample(cleaned)
 except ValueError:trace=None
 loop=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
 row['cycleMarker']=loop.group(0) if loop else None
 expected_bug={'initStrictGcPriority':1,'initSerialReaper':2,'initGlobalGraceGate':3,'initUnfairScheduler':0}[name]
 witness=bool(trace and all(x['s']['status'][1]!=4 and x['s']['bug']==expected_bug for x in trace['states']))
 row['accepted']=bool(not row['timeout'] and row['exit']!=0 and
   re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and loop and witness and
   row['checker']['inputsStable'] and row['checker']['phase']=='tlc')
 if trace:(case/'counterexample.json').write_text(json.dumps(trace,indent=2)+'\n')
 return row

def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/retirement-progress-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/retirement_progress.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  receipt=dict(schema='retirement-progress-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  for i,name in enumerate(NAMES):
   case=out/name;case.mkdir();temporal=('noSchedulerAssumption' if i==9 else 'progress') if i<10 else None
   row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=i>=10,temporal=temporal,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if 6<=i<10:row=classify_temporal(row,log,name,case)
   elif i>=10:
    row['expected']='invariant-counterexample';row['witness']=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('violation')==i-6),None)
    row['accepted']=bool(row['accepted'] and row['witness'])
   else:row['expected']='safety-and-conditional-progress'
   receipt['rows'].append(dict(initializer=name,**row));receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(x['accepted'] for x in receipt['rows'])
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),row.get('cycleMarker'),flush=True)
   if 'parsing failed' in log or 'typechecking failed' in log:break
  print(out,flush=True)
 if not receipt['allAccepted']:raise RuntimeError('progress controls incomplete; retained evidence is not a pass')
def reclassify(prior):
 prior=Path(prior).resolve();old=json.loads(prior.read_text())
 model=ROOT/'models/gambit/retirement_progress.qnt'
 digest=hashlib.sha256(model.read_bytes()).hexdigest()
 assert old['modelSha256']==digest
 assert hashlib.sha256((prior.parent/model.name).read_bytes()).hexdigest()==digest
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/retirement-progress-reclassified');out.mkdir(parents=True,exist_ok=True)
  receipt=dict(schema='retirement-progress-model.v2',modelSha256=digest,rows=[],
   originalReceipt=str(prior.relative_to(ROOT)),originalReceiptSha256=hashlib.sha256(prior.read_bytes()).hexdigest(),
   reclassificationOnly=True,modelReexecuted=False,nativeAdmitted=False)
  for i,original in enumerate(old['rows']):
   row=dict(original);name=row.pop('initializer');case=out/name;case.mkdir()
   logpath=prior.parent/name/'check.log';log=logpath.read_text()
   if 6<=i<10:row=classify_temporal(row,log,name,case)
   row['rawLog']=str(logpath.relative_to(ROOT));row['rawLogSha256']=hashlib.sha256(logpath.read_bytes()).hexdigest()
   receipt['rows'].append(dict(initializer=name,**row))
  receipt['allAccepted']=len(receipt['rows'])==len(NAMES) and all(x['accepted'] for x in receipt['rows'])
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
  print(json.dumps(dict(receipt=str((out/'receipt.json').relative_to(ROOT)),allAccepted=receipt['allAccepted'],rows=len(receipt['rows']))))
 if not receipt['allAccepted']:raise RuntimeError('reclassification incomplete; no model result overridden')

if __name__=='__main__':
 import sys
 if len(sys.argv)==3 and sys.argv[1]=='--reclassify':reclassify(sys.argv[2])
 else:main()
