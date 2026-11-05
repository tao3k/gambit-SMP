"""Retain source bindings, replayable final patch and the admission litmus."""
from pathlib import Path
import difflib,hashlib,json
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors,execute
from gambit_smp.quint_backend import check
ROOT=Path(__file__).resolve().parents[3]
AREA=ROOT/'evidence/research/smp-retirement-study'
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
def diff(a,b,n):return ''.join(difflib.unified_diff(a.splitlines(keepends=True),b.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
def main():
 with work_process.scope(ROOT,'repair-9-12','audit'):
  out=workspace.task_output(ROOT,ROOT/'.cache/owned-request-final-audit');out.mkdir(parents=True,exist_ok=True)
  receipt=dict(schema='owned-request-final-audit.v1',nativeAdmitted=False,qualification='8/12 unchanged',sources={},patches={},models=[])
  owned=ROOT/'.cache/tasks/repair-9-12/runs/b6707f33fef04d6e972ee0e7e6eff261/outputs/owned-request-repair/before'
  fault=ROOT/'.cache/tasks/repair-9-12/runs/3eb090bb0b5f4f5f8c14ad313c801857/outputs/fault-coordinator-repair/before'
  marker=ROOT/'.cache/tasks/repair-9-12/runs/8fb42d0a52414f448712f566f25d5c22/outputs/marker-retirement-repair/before'
  backend=ROOT/'.cache/tasks/repair-9-12/processes/audit/runs/5ca6966c39c442c39a2f5bf73ae7563e/outputs/independent-wait-backend-proposal/before'
  names=['include/gambit.h.in','lib/_thread.scm','lib/_kernel.scm','lib/setup.c','lib/os_io.c','lib/c_intf.c','lib/c_intf.h']
  full='';first='';second=''
  for n in names:
   base=backend/n if n=='lib/os_io.c' else owned/n if (owned/n).exists() else fault/n if (fault/n).exists() else marker/n
   a=base.read_text();b=(SOURCE/n).read_text();full+=diff(a,b,n)
   p=out/'replay'/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(base.read_bytes())
   receipt['sources'][n]=dict(before=sha(base),after=sha(SOURCE/n),beforePath=str(base.relative_to(ROOT)))
   stage=(fault/n).read_text().replace('\n+} while (0)','\n} while (0)') if (owned/n).exists() else (fault/n).read_text() if (fault/n).exists() else a
   if (owned/n).exists():first+=diff(a,stage,n)
   second+=diff(stage,b,n)
  for name,body in [('owned-request-fault-coordinator-native.patch',full),('owned-request-repair.patch',first),('fault-coordinator-repair.patch',second)]:
   (AREA/name).write_text(body);(out/name).write_text(body);receipt['patches'][name]=sha(AREA/name)
  meta={};rc,log,to,sec=execute(['/usr/bin/patch','--batch','-p1','-i',str(out/'owned-request-fault-coordinator-native.patch')],out/'replay',30,metadata=meta)
  (out/'patch-replay.log').write_text(log)
  receipt['patchReplay']=dict(exit=rc,timedOut=to,seconds=sec,process=meta,identical=all(sha(out/'replay'/n)==sha(SOURCE/n) for n in names))
  assert rc==0 and not to and receipt['patchReplay']['identical']
  final=ROOT/'.cache/tasks/repair-9-12/runs/bf4296759c0f4a20b2ef6c43dbb2ab54/outputs'
  receipt['gsiSha256']=sha(SOURCE/'gsi/gsi')
  receipt['generatedSources']={n:sha(SOURCE/n) for n in ['include/gambit.h','lib/_kernel.c','lib/_thread.c']}
  receipt['native']={}
  for name,key in [('owned-request-native','rows'),('marker-ffi-native','stages'),('owned-request-final','rows')]:
   path=final/name/'receipt.json';data=read(path)
   assert data['gsiSha256']==receipt['gsiSha256']
   checks=[r for r in data[key] if 'passed' in r]
   assert checks and all(r['passed'] for r in checks),name
   receipt['native'][name]=dict(receipt=str(path.relative_to(ROOT)),sha256=sha(path),passed=len(checks),rows=checks)
  prior=ROOT/'.cache/tasks/repair-9-12/processes/audit/runs/eedc727ed7434d9b9e04e95d5f5cb41f/outputs/owned-request-model/receipt.json'
  assert read(prior)['modelSha256']==sha(ROOT/'models/gambit/owned_request_fault_coordinator.qnt') and read(prior)['allAccepted']
  receipt['priorCombinedModel']=dict(receipt=str(prior.relative_to(ROOT)),sha256=sha(prior),controls=13)
  model=ROOT/'models/gambit/writer_close_admission.qnt';snapshot=out/model.name;snapshot.write_bytes(model.read_bytes())
  config=out/'config.json';config.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  for name,negative in [('init',False),('initAcquireRelease',True)]:
   case=out/name;case.mkdir()
   row,log,trace=check(snapshot,initializer=name,invariant='safe',negative=negative,timeout=30,cwd=case,config=config,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if negative:
    row['witness']=next((s for s in reversed((trace or {}).get('states',[])) if s.get('freed') and s.get('admitted')),None)
    row['accepted']=bool(row['accepted'] and row['witness'])
   receipt['models'].append(dict(initializer=name,**row));print(name,row.get('accepted'),row.get('seconds'),flush=True)
  receipt['allAccepted']=all(r['accepted'] for r in receipt['models'])
  receipt['openConditions']=['Complete native inventory and repeated qualified 9/12 receipts have not run.', 'Host must hold a valid live VM borrow before native ingress and quiesce external publishers before cleanup.', 'Device-group cleanup error ownership and arbitrary nonlocal exit-job continuation escape remain outside these controls.', 'No matched whole-program performance or embedding ABI qualification is claimed.']
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2));(AREA/'owned-request-native-validation.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
if __name__=='__main__':main()
