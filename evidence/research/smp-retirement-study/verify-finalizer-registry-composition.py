"""Evidence-only full-key, sealed registration, OWNED publication and service."""
from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
ROOT=Path(__file__).resolve().parents[3]
NAMES=['Normal','GuardBusy','SlotBusy','MiscBusy','SealRace','RepeatedEpoch','ReaderGrace','RetryBusyOnce','EnrollmentAbort','ServiceOutlivesResource','CrossVm','WrongVmGeneration','OldEpoch','WrongSlot','OldIncarnation','ReusedHandle','OldLaneGeneration','EnrollAfterSeal','ReleaseBeforePublish','CompleteIgnoresPin','OwnedBeforeReceiver','CompetingWriter','BlockingBorrowCheck','MemberEarlyReturn','ResetLiveReader','DropServiceUnit','DeriveAfterDestroy','WaitInsideWindow']
def witness(s,b):
 if b<=7:return s['used'][0]!=s['key'][0]
 return {8:lambda:s['pin'][0] and not s['granted'][0],
  9:lambda:s['held'][0] and s['refs'][0]==0,
  10:lambda:s['freed'][0] and s['pin'][0],
  11:lambda:s['stage'][0]==3 and not s['ready'][0],
  12:lambda:s['writers'][0]>1,13:lambda:s['window'] and s['blockingUsed'],
  14:lambda:s['window'] and s['earlyReturn'],
  15:lambda:s['readers'][0]>0 and not s['pin'][0],
  16:lambda:s['window'] and s['refs'][s['selected']-1] < (int(s['held'][s['selected']-1] or s['pin'][s['selected']-1])+s['readers'][s['selected']-1]+1),
  17:lambda:s['freed'][0] and s['refs'][0]>0}[b]()
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/finalizer-registry-composition');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/finalizer_registry_composition.qnt';snap=out/model.name;snap.write_bytes(model.read_bytes())
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='finalizer-registry-composition-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,contractMigrationAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir();kind='positive' if i<10 else 'invariant-counterexample' if i<27 else 'temporal-counterexample'
   compiled=case/model.name
   code=snap.read_text();removed=[]
   for match in list(re.finditer(r'^  action (init[A-Z]\w*)=.*\n',code,re.M)):
    other=match.group(1)
    if other!=name:
     assert len(re.findall(r'\b'+re.escape(other)+r'\b',code))==1
     removed.append(other)
   compiled.write_text(re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m.group(0) if m.group(1)==name else '',code,flags=re.M))
   row,log,trace=check(compiled,initializer=name,invariant='safe',negative=10<=i<27,temporal='completion' if i<10 or i>=27 else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   row['projection']=dict(kind='unreferenced-initializer-erasure',canonicalSha256=result['modelSha256'],compiledSha256=hashlib.sha256(compiled.read_bytes()).hexdigest(),selected=name,erased=removed)
   (case/'projection.json').write_text(json.dumps(row['projection'],indent=2)+'\n')
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if 10<=i<27:
    w=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i-9 and witness(x['s'],i-9)),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   elif i>=27:
    row['backendAccepted']=row['accepted'];clean=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
    try:decoded=counterexample(clean)
    except ValueError:decoded=None
    cycle=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
    valid=bool(decoded and any(x['s']['waiting'] and x['s']['window'] for x in decoded['states']) and all(x['s']['bug']==18 for x in decoded['states']))
    row['cycleMarker']=cycle.group(0) if cycle else None
    row['accepted']=bool(not row['timeout'] and row['exit']!=0 and cycle and valid and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and row['checker']['phase']=='tlc' and row['checker']['inputsStable'])
    if decoded:(case/'temporal-trace.json').write_text(json.dumps(decoded,indent=2)+'\n')
   result['rows'].append(dict(initializer=name,expected=kind,**row));result['allAccepted']=len(result['rows'])==len(NAMES) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),row.get('cycleMarker'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected model/checker result; retained failure')
  print(out,flush=True)
if __name__=='__main__':main()
