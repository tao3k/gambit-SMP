"""Verification only: self terminate/suspend must not consume the carrier."""
from pathlib import Path
import hashlib,importlib.util,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
PROGRAM=r'''
(define steps 0)(define refusals 0)
(define (expect-refusal operation thunk)
 (with-exception-catcher
  (lambda (e)
   (if (not (and (error-object? e) (equal? (error-object-message e) "fault coordinator lifecycle admission closed"))) (error "wrong lifecycle refusal" operation))
   (set! refusals (+ refusals 1))
   (display "OWNER-REFUSED ")(write operation)(newline)(force-output)
   (raise e))
  (lambda () (thunk)(error "coordinator operation unexpectedly returned" operation))))
(define payload (make-vector 4096 827))
(##add-exit-job! (lambda ()
 (##gc)
 (if (not (= refusals 2)) (error "both lifecycle refusals were not observed"))
 (if (not (= steps 2)) (error "coordinator lifecycle consumed suffix"))
 (if (not (= (vector-ref payload 4095) 827)) (error "owner root lost"))
 (let ((e (##vector-ref (##fault-control-record) 5)))
  (if (not (and (error-object? e) (equal? (error-object-message e) "fault coordinator lifecycle admission closed"))) (error "owner refusal root lost")))
 (if (not (eq? (current-thread) (##vector-ref (##fault-control-record) 0))) (error "carrier identity changed"))
 (display "OWNER-SUFFIX-ERROR-GC-ROOTED\n")(force-output)))
(##add-exit-job! (lambda ()
 (if (not (= steps 1)) (error "termination prefix lost or repeated"))
 (set! steps 2)(display "OWNER-SELF-SUSPEND-ATTEMPT\n")(force-output)
 (expect-refusal 'suspend (lambda () (thread-suspend! (current-thread))))
 (error "coordinator suspend unexpectedly returned")))
(##add-exit-job! (lambda ()
 (set! steps 1)(display "OWNER-SELF-TERMINATE-ATTEMPT\n")(force-output)
 (expect-refusal 'terminate (lambda () (thread-terminate! (current-thread))))
 (error "coordinator terminate unexpectedly returned")))
(call-with-output-file (getenv "SMP_WAKE_ARM_FILE") (lambda (p) (display "armed" p)))
(##device-select-abort! 0)
(let loop () (thread-sleep! 0.02)(loop))
'''
def main():
 spec=importlib.util.spec_from_file_location('control',ROOT/'evidence/research/smp-retirement-study/verify-owned-request-native.py');control=importlib.util.module_from_spec(spec);spec.loader.exec_module(control)
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/fault-owner-native');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  receipt=dict(schema='fault-owner-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],runtimeModified=False,nativeAdmitted=False)
  def run(n,args,cap,extra=None):
   e=dict(env);e.update(extra or {});meta={};rc,log,to,sec=execute(args,out,cap,env=e,metadata=meta);(out/(n+'.log')).write_text(log);row=dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['rows'].append(row);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-1800:],flush=True);return row,log
  c=out/'wake.c';c.write_text(control.C);lib=out/'wake.dylib';row,_=run('compile-injector',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(c)],30)
  if row['exit'] or row['timedOut']:raise RuntimeError('owner injector compilation failed')
  p=out/'owner.scm';p.write_text(PROGRAM)
  for mode in [2,4]:
   row,log=run('owner-'+str(mode),[str(SOURCE/'gsi/gsi'),'-:p11,~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include'),str(p)],30,dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT=str(mode),SMP_WAKE_ARM_FILE=str(out/('arm-'+str(mode)))))
   row['passed']=bool(row['exit']==70 and not row['timedOut'] and all(log.count(x)==1 for x in ['OWNER-SELF-TERMINATE-ATTEMPT','OWNER-SELF-SUSPEND-ATTEMPT','OWNER-SUFFIX-ERROR-GC-ROOTED','OWNER-REFUSED terminate','OWNER-REFUSED suspend']) and 'SMP-FAULT coordinator=P0 prepared' in log and 'SMP-FAULT native-grace writers=0 selectors=0 markers=0' in log and 'unexpectedly returned' not in log)
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  print(out,flush=True)
  if not all(r.get('passed',True) for r in receipt['rows']):raise RuntimeError('coordinator owner control failed')
if __name__=='__main__':main()
