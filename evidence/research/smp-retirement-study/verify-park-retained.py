from pathlib import Path
import hashlib,json,re,runpy,sys
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def projection(code,name,start,observer):
 assert all(re.fullmatch(r'[A-Za-z_]\w*',k) and type(v) in (int,bool) for k,v in start.items())
 p=re.sub(r'^  action (init[A-Z]\w*)=.*\n','',code,flags=re.M)
 literal='{'+','.join(k+':'+(str(v).lower() if type(v) is bool else str(v)) for k,v in start.items())+'}'
 return p[:-2]+"  action "+name+"=s'="+literal+'\n  val targetNotReached=not('+observer+')\n}\n'
def main():
 rp=Path(sys.argv[1]).resolve();base=json.loads(rp.read_text());assert base['allAccepted'] and len(base['rows'])==31
 v=runpy.run_path(str(E/'verify-checked-park.py'));model=R/base['model'];code=model.read_text();assert sha(model)==base['modelSha256']
 for row in base['rows']:
  p=R/row['evidenceDirectory']/model.name;assert p.read_text()==v['project'](code,row['initializer'],v['TARGETS'][row['goal']][1] if row['goal'] else None)
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/checked-park-retained-gc');out.mkdir(parents=True)
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  res=dict(base,sourceVerificationReceipt=str(rp.relative_to(R)),sourceVerificationSha256=sha(rp),rows=[dict(x,reusedUnchangedBackendRun=True) for x in base['rows']],allAccepted=False)
  for g in ['RetainedFailure','RetainedRejoin']:
   source=next(x for x in base['rows'] if x['goal']==g);start=source['witness'];assert start['phase']==12 and start['retained'] and v['safe'](start)
   name='initRecorded'+g;observer='s.phase==12 and s.retained and s.carrier and s.domain and s.gcBit=='+str(not start['gcBit']).lower()
   case=out/name;case.mkdir();p=case/model.name;p.write_text(projection(code,name,start,observer))
   row,log,trace=check(p,initializer=name,invariant='targetNotReached',negative=True,timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   states=[x['s'] for x in (trace or {}).get('states',[])];w=next((s for s in states if s['phase']==12 and s['retained'] and s['carrier'] and s['domain'] and s['gcBit']!=start['gcBit']),None)
   row.update(accepted=bool(row['accepted'] and states and states[0]==start and w and all(v['safe'](s) for s in states)),initializer=name,kind='continuation',goal=g+'AfterGc',continuedFrom=g,startState=start,observer=observer,witness=w,evidenceDirectory=str(case.relative_to(R)),reusedUnchangedBackendRun=False)
   res['rows'].append(row);(out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(g,row['accepted'],row['seconds'],flush=True)
   if not row['accepted']:raise RuntimeError('retained-state GC continuation not verified')
  res['allAccepted']=len(res['rows'])==33 and all(x['accepted'] for x in res['rows']);assert res['allAccepted']
  assert all(sha(R/n)==h for n,h in res['protectedInputs'].items())
  (out/'receipt.json').write_text(json.dumps(res,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
