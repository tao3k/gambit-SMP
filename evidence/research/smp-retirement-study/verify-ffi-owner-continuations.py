from pathlib import Path
import hashlib,json,re,runpy,sys
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def project(code,name,goal,start=None):
 s=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if start is None and m[1]==name else '',code,flags=re.M)
 if start is not None:
  assert all(re.fullmatch(r'[A-Za-z_]\w*',k) and type(v) in (bool,int) for k,v in start.items())
  literal='{'+','.join(k+':'+('true' if v else 'false' if type(v) is bool else str(v)) if type(v) is bool else k+':'+str(v) for k,v in start.items())+'}'
  s=s[:-2]+'  action '+name+"=s'="+literal+'\n}\n'
 return s[:-2]+'  val targetNotReached=not('+goal+')\n}\n' if goal else s
def main():
 old=Path(sys.argv[1]).resolve();previous=json.loads((old/'receipt.json').read_text());v=runpy.run_path(str(E/'verify-ffi-owner.py'));model=R/'models/gambit/ffi_native_owner_handoff.qnt';code=model.read_text();assert previous['allAccepted'] and sha(model)==previous['modelSha256']
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/ffi-owner-distinct-errors');out.mkdir(parents=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(schema='ffi-owner-distinct-errors.v1',modelSha256=sha(model),retainedPredecessor=str((old/'receipt.json').relative_to(R)),rows=[],allAccepted=False,nativeAdmitted=False,perCaseTimeoutSeconds=30,correction='prior failed-status targets also reached pre-entry refusal; these do not certify distinct prefix/body-error recovery')
  for row in previous['rows']:
   if row['goal'] in ['BodyError','PrefixError']:continue
   row=dict(row);case=old/row['caseName'];expected=project(code,row['initializer'],v['TARGETS'][row['goal']] if row['goal'] else None);assert (case/model.name).read_text()==expected and sha(case/model.name)==row['checker']['modelSha256']
   if row['goal']:assert v['target'](row['witness'],row['goal'])
   elif row['initializer'] not in ['init'+n for n in v['NAMES'][:7]]:assert not v['safe'](row['witness'])
   row.update(evidenceDirectory=str(case.relative_to(R)),reusedUnchangedBackendRun=True);res['rows'].append(row)
  starts={}
  for goal in ['BodyError','PrefixError','BodyErrorCompletion','PrefixErrorCompletion']:
   continuation=goal.endswith('Completion');source=goal[:-10] if continuation else goal
   start=starts[source] if continuation else None;name='initRecorded'+source if continuation else 'init'+source;case=out/name;case.mkdir();compiled=case/model.name;observer='s.vmFree and s.failed' if continuation else v['TARGETS'][source];compiled.write_text(project(code,name,observer,start))
   row,log,trace=check(compiled,initializer=name,invariant='targetNotReached',negative=True,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   states=[v['normalize'](x['s']) for x in (trace or {}).get('states',[])];w=next((s for s in states if s['vmFree'] and s['failed']),None) if continuation else next((s for s in states if v['target'](s,source)),None)
   if continuation:assert states and states[0]==start
   elif w:starts[source]=w
   row.update(accepted=bool(row['accepted'] and w),witness=w,initializer=name,caseName=case.name,goal=goal,observer=observer,startState=start,continuedFrom=source if continuation else None,evidenceDirectory=str(case.relative_to(R)),reusedUnchangedBackendRun=False)
   res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(goal,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected distinct-error result')
  res['allAccepted']=len(res['rows'])==32 and all(x['accepted'] for x in res['rows']);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
