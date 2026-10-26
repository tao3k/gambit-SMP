"""Retained backend deadline controls against the final coordinator producer."""
from pathlib import Path
import hashlib,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
CASES=[('independent-return','(let loop ((i 0)) (if (< i 5) (begin (write (list "enter" i))(newline)(force-output)(##os-condvar-select! #f #t)(loop (+ i 1))) (begin (display "INDEPENDENT-RETURN\\n")(force-output))))','INDEPENDENT-RETURN'),
 ('real-deadline','(let ((start (##current-time-point))) (thread-sleep! 0.25) (let ((elapsed (- (##current-time-point) start))) (write (list "REAL-DEADLINE" elapsed))(newline)(force-output)(if (< elapsed 0.24) (exit 21))))','REAL-DEADLINE')]
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/final-deadline-native');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  receipt=dict(schema='final-deadline-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  for name,program,marker in CASES:
   p=out/(name+'.scm');p.write_text(program);meta={}
   rc,log,to,sec=execute([str(SOURCE/'gsi/gsi'),'-:p11,~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include'),str(p)],out,15,env=env,metadata=meta)
   (out/(name+'.log')).write_text(log);receipt['rows'].append(dict(name=name,exit=rc,timedOut=to,seconds=sec,passed=rc==0 and not to and marker in log,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(name,rc,to,sec,log,flush=True)
  print(out,flush=True)
  if not all(r['passed'] for r in receipt['rows']):raise RuntimeError('final deadline control failed')
if __name__=='__main__':main()
