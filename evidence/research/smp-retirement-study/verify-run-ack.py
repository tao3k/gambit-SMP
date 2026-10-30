from pathlib import Path
import json,hashlib,re
from gambit_smp import workspace,work_process
from gambit_smp.framework import available_processors
from gambit_smp.quint_backend import check
R=Path.cwd();E=R/'evidence/research/smp-retirement-study'
POS=['Return','AllocFailure','Throw','Retry','Blocked']
NEG=['BypassKill','TailBeforeKill','AckWithoutRoot','UnlinkDuringScan','RemoteUnlink','DropDomain','DuplicateKill','StaleRoot','PostFreeRead','RetryUnwinds','LockedDetach']
GOALS={'Return':'s.freed and s.kills==1 and s.detaches==1','AllocFailure':'s.freed and s.kills==0 and s.error','Throw':'s.freed and s.kills==1 and s.error','Retry':'s.freed and s.kills==1 and s.retried','Blocked':'s.stage==2 and s.marker and s.domain and s.ack and s.locked','LateAck':'s.stage==5 and s.msg==1 and s.domain and not(s.context)'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def safe(s):
 return not s['bad'] and s['kills']<=1 and s['detaches']<=1 and (s['stage']<4 or not s['marker']) and (not s['tail'] or (s['stage']==5 and not s['marker'] and not s['catcher'])) and (s['stage']!=2 or s['marker']) and (s['stage']>=5 or s['context']) and (not s['ack'] or s['msg']>=2) and (s['msg']!=2 or s['aRoot']) and (not s['bRoot'] or (s['domain'] and s['owner'])) and (s['msg'] not in (1,2) or s['bRoot']) and (s['scan'] or ((not s['bRoot'] or s['bVersion']==s['gc']) and (not s['aRoot'] or s['aVersion']==s['gc']))) and (not s['freed'] or (s['stage']==5 and not s['context'] and not s['marker'] and not s['domain'] and not s['aRoot'] and not s['scan']))
def goal(s,g):
 if g=='Return':return s['freed'] and s['kills']==1 and s['detaches']==1
 if g=='AllocFailure':return s['freed'] and s['kills']==0 and s['error']
 if g=='Throw':return s['freed'] and s['kills']==1 and s['error']
 if g=='Retry':return s['freed'] and s['kills']==1 and s['retried']
 if g=='Blocked':return s['stage']==2 and s['marker'] and s['domain'] and s['ack'] and s['locked']
 if g=='LateAck':return s['stage']==5 and s['msg']==1 and s['domain'] and not s['context']
 raise ValueError(g)
def project(code,name,observer):
 p=re.sub(r'^  action (init[A-Z]\w*)=.*\n',lambda m:m[0] if m[1]==name else '',code,flags=re.M)
 return p[:-2]+'  val targetNotReached=not('+observer+')\n}\n' if observer else p
def main():
 prior=json.loads((E/'lock-main-native-owner-ffi.json').read_text());protected=prior['protectedInputs'];before={n:sha(R/n) for n in protected}
 with work_process.scope(R,'repair-9-12','audit'):
  out=workspace.task_output(R,R/'.cache/run-ack-refinement');out.mkdir(parents=True)
  model=R/'models/gambit/run_ack_refinement.qnt';code=model.read_text()
  cfg=out/'config.json';cfg.write_text(json.dumps(dict(workers=available_processors(),maxHeap='-Xmx1G',stackSize='-Xss8m')))
  result=dict(schema='run-ack-refinement.v1',model=str(model.relative_to(R)),modelSha256=sha(model),sourceReceipt=prior['sourceReceipt'],nativeAdmitted=False,perCaseTimeoutSeconds=30,rows=[],protectedBefore=before,allAccepted=False)
  cases=[(n,None) for n in POS+NEG]+[(('Return' if g=='LateAck' else g),g) for g in GOALS]
  for name,g in cases:
   case=out/(name+('-'+g if g else ''));case.mkdir();p=case/model.name;p.write_text(project(code,'init'+name,GOALS[g] if g else None))
   row,log,trace=check(p,initializer='init'+name,invariant='targetNotReached' if g else 'safe',negative=bool(g or name in NEG),timeout=30,cwd=case,config=cfg,executable='/opt/homebrew/bin/quint',liveness_schedule='final',tlc_jar=Path('/Users/guangtao/.quint/apalache-dist-0.62.1/apalache/lib/apalache.jar'))
   (case/'check.log').write_text(log)
   if trace:(case/'trace.json').write_text(json.dumps(trace,indent=2)+'\n')
   states=[x['s'] for x in (trace or {}).get('states',[])];w=next((s for s in states if goal(s,g)),None) if g else next((s for s in states if not safe(s)),None)
   row.update(initializer='init'+name,goal=g,evidenceDirectory=str(case.relative_to(R)),witness=w)
   if g or name in NEG:row['accepted']=bool(row['accepted'] and w)
   result['rows'].append(row);(out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(name,g,row['accepted'],row.get('seconds'),flush=True)
   if not row['accepted']:raise RuntimeError('retained unexpected model result')
  result['allAccepted']=all(x['accepted'] for x in result['rows']);result['protectedUnchanged']=all(sha(R/n)==h for n,h in before.items());assert result['protectedUnchanged']
  (out/'receipt.json').write_text(json.dumps(result,indent=2)+'\n');print(out,flush=True)
if __name__=='__main__':main()
