"""Same-producer targeted delivery and permanent-wake-fault controls."""
from pathlib import Path
import hashlib, json, os, re
from gambit_smp import workspace as w
from gambit_smp.framework import execute
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
C=r'''#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
static unsigned long attempts, failures, active, badclose, held;
static int mode;
static const char *arm;
static unsigned char known[4096];
__attribute__((constructor)) static void setup(void) {
 const char *p=getenv("SMP_WAKE_FAULT");mode=p?atoi(p):0;arm=getenv("SMP_WAKE_ARM_FILE");
}
static ssize_t injected_write(int fd,const void *p,size_t n) {
 struct stat st;
 if((!arm || access(arm,F_OK)==0) && n==1 && *(const unsigned char*)p==0 &&
    fstat(fd,&st)==0 && S_ISFIFO(st.st_mode) && (fcntl(fd,F_GETFL)&O_NONBLOCK)) {
  unsigned long k=__sync_add_and_fetch(&attempts,1);
  if(fd>=0 && fd<4096)known[fd]=1;
  __sync_add_and_fetch(&active,1);
  if(mode==3 && k==2) {__sync_add_and_fetch(&held,1);usleep(200000);}
  if(mode>=2 || (mode==1 && k==1)) {
   __sync_add_and_fetch(&failures,1);__sync_sub_and_fetch(&active,1);
   errno=(mode==1 || mode==4)?EINTR:EBADF;return -1;
  }
  ssize_t r=write(fd,p,n);__sync_sub_and_fetch(&active,1);return r;
 }
 return write(fd,p,n);
}
static int injected_close(int fd) {
 if(fd>=0 && fd<4096 && known[fd] && __sync_add_and_fetch(&active,0)>0)
  __sync_add_and_fetch(&badclose,1);
 return close(fd);
}
__attribute__((used,section("__DATA,__interpose")))
static const struct{const void *replacement,*original;} hooks[]={
 {(const void*)injected_write,(const void*)write},
 {(const void*)injected_close,(const void*)close}};
__attribute__((destructor)) static void report(void) {
 char b[240];int n=snprintf(b,sizeof(b),
 "WAKE-INJECT mode=%d attempts=%lu failures=%lu active=%lu badclose=%lu held=%lu\n",
 mode,attempts,failures,active,badclose,held);write(2,b,n);
}
'''

DELIVERY=r'''
(define receiver (make-thread (lambda () (let loop () (thread-sleep! 10) (loop)))))
(thread-start! receiver)
(define calls 0)
(let loop ((i 0))
 (if (< i 1000)
  (let ((answer (thread-interrupt! receiver
    (lambda () (set! calls (+ calls 1))
     (if (= (modulo calls 100) 0) (begin (##gc) (thread-yield!)))
     (vector i (+ i 1))))))
   (if (not (= (vector-ref answer 0) i)) (exit 23)) (loop (+ i 1)))))
(if (not (= calls 1000)) (exit 24))
(thread-terminate! receiver)
(display "REQUEST-ONCE-REPLY-ONCE 1000\n")(force-output)
'''

MIGRATION=r'''
(define calls 0)
(define a (make-thread (lambda () (let loop () (thread-sleep! 10) (loop)))))
(define b (make-thread (lambda () (let loop () (thread-sleep! 10) (loop)))))
(thread-start! a)(thread-start! b)
(let loop ((i 0))
 (if (< i 40)
  (let ((v (thread-interrupt! a (lambda ()
    (##thread-migrate-to! (modulo (+ (##current-processor-id) 1) 11))
    (thread-interrupt! b (lambda () (##gc)(set! calls (+ calls 1))(vector i calls)))))))
   (if (not (= (vector-ref v 0) i)) (exit 25)) (loop (+ i 1)))))
(if (not (= calls 40)) (exit 26))
(thread-terminate! a)(thread-terminate! b)
(display "MIGRATION-NESTED-GC 40\n")(force-output)
'''

EXCEPTION=r'''
(define errors 0)
(define ready (make-mutex))
(mutex-lock! ready #f #f)
(define receiver (make-thread (lambda ()
 (let loop ((first? #t)) (with-exception-catcher
  (lambda (e) (set! errors (+ errors 1)) (loop #f))
  (lambda () (if first? (mutex-unlock! ready))
             (thread-sleep! 10) (loop #f)))))))
(thread-start! receiver)
(mutex-lock! ready)(mutex-unlock! ready)
(define abandoned
 (with-exception-catcher (lambda (e) (abandoned-mutex-exception? e))
  (lambda () (thread-interrupt! receiver (lambda () (##gc)(error "request-fault"))) #f)))
(if (not abandoned) (exit 27))
(let wait () (if (= errors 0) (begin (thread-yield!) (wait))))
(let ((v (thread-interrupt! receiver (lambda () (vector 'alive errors)))))
 (if (not (= (vector-ref v 1) 1)) (exit 28)))
(thread-terminate! receiver)
(display "EXCEPTION-REPLY-OWNER-RELEASED\n")(force-output)
'''

ESCAPE=r'''
(define escape-target #f)
(define escaped #f)
(define ready (make-mutex))(mutex-lock! ready #f #f)
(define target (make-thread (lambda ()
 (call/cc (lambda (k) (set! escape-target k)(mutex-unlock! ready)
           (let loop () (thread-sleep! 10)(loop))))
 (set! escaped #t)
 (let loop () (thread-sleep! 10)(loop)))))
(thread-start! target)(mutex-lock! ready)(mutex-unlock! ready)
(define abandoned
 (with-exception-catcher (lambda (e) (abandoned-mutex-exception? e))
  (lambda () (thread-interrupt! target (lambda () (##gc)(escape-target 'escaped))) #f)))
(if (not abandoned) (exit 38))
(let wait () (if (not escaped) (begin (thread-yield!)(wait))))
(if (not (= (thread-interrupt! target (lambda () 619)) 619)) (exit 39))
(thread-terminate! target)
(display "CONTINUATION-ESCAPE-OWNER-RELEASED\n")(force-output)
'''

FAULT=r'''
(define payload (make-vector 2048 713))
(define target (make-thread (lambda () (let loop () (thread-sleep! 10)(loop)))))
(thread-start! target)
(##add-exit-job! (lambda ()
 (##gc)
 (if (not (= (vector-ref payload 2047) 713)) (error "payload root lost"))
 (let ((e (##vector-ref (##fault-control-record) 5)))
  (if (not (and (error-object? e) (equal? (error-object-message e) "exit-job-fault")))
      (error "caught error root lost")))
 (display "EXIT-SUFFIX-ERROR-ROOT\n")(force-output)
 (with-exception-catcher
  (lambda (e)
   (if (not (and (error-object? e) (equal? (error-object-message e) "exit callback admission closed after wake fault"))) (error "wrong callback refusal"))
   (display "EXIT-ADMISSION-REFUSED\n")(force-output))
  (lambda () (##add-exit-job! (lambda () (display "UNEXPECTED-NEW-JOB"))) (exit 39)))
 (with-exception-catcher
  (lambda (e)
   (if (not (and (error-object? e) (equal? (error-object-message e) "thread interrupt admission closed after wake fault"))) (error "wrong request refusal"))
   (display "REQUEST-ADMISSION-REFUSED\n")(force-output))
  (lambda () (thread-interrupt! target (lambda () (display "UNEXPECTED-NEW-REQUEST"))) (exit 40)))
 (exit 41)
 (display "RECURSIVE-EXIT-INTENT\n")(force-output)))
(##add-exit-job! (lambda () (##gc)(display "EXIT-JOB-THROW\n")(force-output)(error "exit-job-fault")))
(##add-job-at-tail! ##final-will-registry
 (make-will (vector 919)
  (lambda (v) (##gc)(if (not (= (vector-ref v 0) 919)) (error "will root lost"))
   (display "FINAL-WILL-ROOT\n")(force-output))))
(call-with-output-file (getenv "SMP_WAKE_ARM_FILE") (lambda (p) (display "armed" p)))
(##device-select-abort! 0)
(let loop ((i 0))
 (if (< i 20)
  (begin (thread-sleep! 0.02) (loop (+ i 1)))
  (begin (display "NO-PERMANENT-FAULT\n")(force-output)
         (##clear-exit-jobs!)(##clear-jobs! ##final-will-registry))))
'''

def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/owned-request-native');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment'])
  env.pop('GAMBOPT',None)
  option='-:p11,~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include')
  result=dict(schema='owned-request-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  def save():(out/'receipt.json').write_text(json.dumps(result,indent=2))
  def run(name,argv,cap,extra=None):
   selected=dict(env);selected.update(extra or {});meta={}
   rc,log,timed,sec=execute(argv,out,cap,env=selected,metadata=meta)
   (out/(name+'.log')).write_text(log)
   row=dict(name=name,exit=rc,timedOut=timed,seconds=sec,process=meta)
   result['rows'].append(row);save();print(name,rc,timed,sec,log[-1800:],flush=True)
   return row,log
  for name,code,marker in [('smoke','(if (not (= (##current-vm-processor-count) 11)) (exit 37))(display "HEALTHY-SMOKE\\n")(force-output)','HEALTHY-SMOKE'),
                           ('delivery',DELIVERY,'REQUEST-ONCE-REPLY-ONCE'),
                           ('migration-nested',MIGRATION,'MIGRATION-NESTED-GC'),
                           ('exception',EXCEPTION,'EXCEPTION-REPLY-OWNER-RELEASED'),
                           ('continuation-escape',ESCAPE,'CONTINUATION-ESCAPE-OWNER-RELEASED')]:
   p=out/(name+'.scm');p.write_text(code);row,log=run(name,[str(SOURCE/'gsi/gsi'),option,str(p)],30)
   row['passed']=row['exit']==0 and not row['timedOut'] and marker in log;save()
   if not row['passed']:raise RuntimeError('native control failed: '+name+' '+str(out))
  p=out/'wake-fault.c';p.write_text(C);lib=out/'wake-fault.dylib'
  row,_=run('injector-build',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(p)],30)
  if row['exit']!=0 or row['timedOut']:raise RuntimeError('injector build failed')
  p=out/'fault.scm';p.write_text(FAULT)
  for mode in [1,2,3,4]:
   arm=out/('arm-'+str(mode))
   row,log=run('fault-'+str(mode),[str(SOURCE/'gsi/gsi'),option,str(p)],30,
    dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT=str(mode),SMP_WAKE_ARM_FILE=str(arm)))
   m=re.search(r'WAKE-INJECT mode=(\d+) attempts=(\d+) failures=(\d+) active=(\d+) badclose=(\d+) held=(\d+)',log)
   row['injection']=list(map(int,m.groups())) if m else None
   row['retiredMarkers']={int(p):int(n) for p,n in re.findall(r'SMP-FAULT retired-markers p=(\d+) count=(\d+)',log)}
   expected=0 if mode==1 else 70
   row['passed']=bool(not row['timedOut'] and row['exit']==expected and m and int(m[3])>0 and int(m[4])==0 and int(m[5])==0 and
    ('NO-PERMANENT-FAULT' in log if mode==1 else all(x in log for x in ['EXIT-JOB-THROW','EXIT-SUFFIX-ERROR-ROOT','EXIT-ADMISSION-REFUSED','REQUEST-ADMISSION-REFUSED','RECURSIVE-EXIT-INTENT','FINAL-WILL-ROOT','SMP-FAULT coordinator=P0 prepared','SMP-FAULT native-grace writers=0 selectors=0 markers=0']) and set(row['retiredMarkers'])==set(range(1,11))) and
    (mode!=3 or int(m[6])>0))
   save()
  if not all(r['passed'] for r in result['rows'] if 'passed' in r):
   raise RuntimeError('native fault control failed: '+str(out))
  print(out,flush=True)
if __name__=='__main__':main()
