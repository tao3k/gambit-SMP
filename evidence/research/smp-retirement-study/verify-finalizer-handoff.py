"""Evidence-only lifetime handoff and shared/native-fault disposition model."""
from pathlib import Path
import hashlib,json,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check,counterexample
ROOT=Path(__file__).resolve().parents[3]
NAMES=['Normal','ClaimRefused','HeldReader','DestroyRetained','PrivateUnlockRetained','GuardUnknown','MiscUnknown','SyncUnknown','PinGap','CounterOnlyClean','StaleClaim','TailBeforeJoin','DropReaderPin','ResumeSharedFault','UnprovenIsolation','MemberEarlyReturn','FatalCallback','UseAfterRelease','DoubleClaim','IgnoreFinalReader','WaitBarrierFault','WaitHookFault']
def witness(s,b):
 return {1:lambda:s['stage'][0]==2 and not s['pin'][0],
  2:lambda:s['vmFreed'] and any(s['pin']),3:lambda:s['key'][0]!=1,
  4:lambda:not s['tail'][0] and not s['joined'][0],
  5:lambda:s['readers'][0]>0 and not s['pin'][0],
  6:lambda:s['fault'] and s['earlyReturn'],7:lambda:s['localRetained'] and not s['cutProved'],
  8:lambda:s['window'] and s['earlyReturn'],9:lambda:s['fault'] and s['hookCalled'],
  10:lambda:s['lateUse'],11:lambda:s['claims'][0]==2,
  12:lambda:s['stage'][1]==6 and s['readers'][1]>0}[b]()
def temporal_negative(row,log,bug,case):
 row['backendAccepted']=row['accepted']
 clean=re.sub(r'^State \d+: Stuttering[^\n]*\n','',log,flags=re.M)
 try:trace=counterexample(clean)
 except ValueError:trace=None
 cycle=re.search(r'Back to state (\d+)|State (\d+): Stuttering',log)
 valid=bool(trace and any(x['s']['fault'] and not x['s']['stopped'] for x in trace['states']) and all(x['s']['bug']==bug and not x['s']['stopped'] for x in trace['states']))
 row['cycleMarker']=cycle.group(0) if cycle else None
 row['accepted']=bool(not row['timeout'] and row['exit']!=0 and cycle and valid and re.search(r'Temporal propert(?:y|ies).* (?:was|were) violated',log) and row['checker']['phase']=='tlc' and row['checker']['inputsStable'])
 if trace:(case/'decoded-temporal-trace.json').write_text(json.dumps(trace,indent=2)+'\n')
 return row
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/finalizer-handoff-model');out.mkdir(parents=True,exist_ok=True)
  model=ROOT/'models/gambit/finalizer_handoff.qnt';snap=out/model.name;snap.write_bytes(model.read_bytes())
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='finalizer-handoff-model.v1',modelSha256=hashlib.sha256(model.read_bytes()).hexdigest(),rows=[],allAccepted=False,nativeAdmitted=False,contractMigrationAdmitted=False,perCaseTimeoutSeconds=30)
  for i,suffix in enumerate(NAMES):
   name='init'+suffix;case=out/name;case.mkdir();kind='positive' if i<8 else 'invariant-counterexample' if i<20 else 'temporal-counterexample'
   row,log,trace=check(snap,initializer=name,invariant='safe',negative=8<=i<20,temporal='completion' if i<8 or i>=20 else None,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   if 8<=i<20:
    w=next((x['s'] for x in reversed((trace or {}).get('states',[])) if x.get('s',{}).get('bug')==i-7 and witness(x['s'],i-7)),None)
    row['witness']=w;row['accepted']=bool(row['accepted'] and w)
   elif i>=20:row=temporal_negative(row,log,i-7,case)
   result['rows'].append(dict(initializer=name,expected=kind,**row));result['allAccepted']=len(result['rows'])==len(NAMES) and all(x['accepted'] for x in result['rows'])
   (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,row['accepted'],row.get('seconds'),row.get('cycleMarker'),flush=True)
   if not row['accepted']:raise RuntimeError('unexpected model/checker result; retained failure')
  print(out,flush=True)
if __name__=='__main__':main()
