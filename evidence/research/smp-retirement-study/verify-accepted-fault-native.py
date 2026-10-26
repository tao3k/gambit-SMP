"""Permanent wake fault while an already accepted result request is active."""
from pathlib import Path
import hashlib,importlib.util,json,os,re
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
ACTIVE=r'''
(define request-entered (make-mutex))(mutex-lock! request-entered #f #f)
(define sender-completed? #f)
(define request-payload (make-vector 3072 827))
(define sender (make-thread (lambda ()
 (thread-interrupt! target (lambda ()
  (mutex-unlock! request-entered)
  (let loop () (##gc)(thread-sleep! 10)(loop))))
 (set! sender-completed? #t))))
(thread-start! sender)(mutex-lock! request-entered)(mutex-unlock! request-entered)
(##add-exit-job! (lambda ()
 (##gc)
 (if sender-completed? (error "active request unexpectedly returned"))
 (if (not (= (vector-ref request-payload 3071) 827)) (error "active request payload lost"))
 (display "ACCEPTED-ACTIVE-SENDER-PENDING-ROOTED\n")(force-output)))
'''
def main():
 spec=importlib.util.spec_from_file_location('control',ROOT/'evidence/research/smp-retirement-study/verify-owned-request-native.py');control=importlib.util.module_from_spec(spec);spec.loader.exec_module(control)
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/accepted-fault-native');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  receipt=dict(schema='accepted-fault-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  def run(name,args,cap,extra=None):
   e=dict(env);e.update(extra or {});meta={};rc,log,to,sec=execute(args,out,cap,env=e,metadata=meta);(out/(name+'.log')).write_text(log);row=dict(name=name,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['rows'].append(row);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(name,rc,to,sec,log[-2000:],flush=True);return row,log
  c=out/'wake.c';c.write_text(control.C);lib=out/'wake.dylib'
  row,_=run('compile-injector',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(c)],30)
  if row['exit'] or row['timedOut']:raise RuntimeError('injector compile failed')
  p=out/'active.scm';p.write_text(control.FAULT.replace('(##add-exit-job!',ACTIVE+'\n(##add-exit-job!',1))
  for mode in [2,4]:
   row,log=run('active-fault-'+str(mode),[str(SOURCE/'gsi/gsi'),'-:p11,~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include'),str(p)],30,dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT=str(mode),SMP_WAKE_ARM_FILE=str(out/('arm-'+str(mode)))))
   m=re.search(r'WAKE-INJECT mode=(\d+) attempts=(\d+) failures=(\d+) active=(\d+) badclose=(\d+) held=(\d+)',log)
   row['passed']=bool(row['exit']==70 and not row['timedOut'] and m and int(m[3])>0 and int(m[4])==0 and int(m[5])==0 and all(x in log for x in ['ACCEPTED-ACTIVE-SENDER-PENDING-ROOTED','EXIT-SUFFIX-ERROR-ROOT','SMP-FAULT coordinator=P0 prepared','SMP-FAULT native-grace writers=0 selectors=0 markers=0']))
   row['disposition']='VM terminal failure, not a fabricated request reply'
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  print(out,flush=True)
  if not all(r.get('passed',True) for r in receipt['rows']):raise RuntimeError('active request fault control failed')
if __name__=='__main__':main()
