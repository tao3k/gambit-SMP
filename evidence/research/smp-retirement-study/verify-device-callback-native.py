"""Actual device-vtable failure injection and winding callback escapes."""
from pathlib import Path
import hashlib,importlib.util,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
DEVICE=r'''
(c-declare #<<end-c
#include "@IO@"
#include "@BASE@"
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
typedef struct { ___device base; int mode,rd,wr,reads,writes,releases; } probe_device;
static int freed_count,global_mode,root_index=-1;
static ___global_state observed_gstate;
static probe_device *global_probe;
static int kind(___device *d) {return ___FILE_DEVICE_KIND;}
static ___SCMOBJ sel(___device *d,int op,int i,int pass,___device_select_state *s) {
 if(pass==___SELECT_PASS_1) {s->timeout=___time_mod.time_neg_infinity;return ___FIX(___SELECT_SETUP_DONE);}
 s->devs[i]=NULL;return ___FIX(___NO_ERR);
}
static ___SCMOBJ release(___device *d) {
 probe_device *p=(probe_device*)d;p->releases++;
 if(p->mode==4) return ___FIX(___INVALID_OP_ERR);
 freed_count++;return ___FIX(___NO_ERR);
}
static ___SCMOBJ force(___device *d,int n) {return ___FIX(___NO_ERR);}
static ___SCMOBJ cls(___device *d,int dir) {
 probe_device *p=(probe_device*)d;
 if(dir==___DIRECTION_RD) {
  p->reads++;
  if(p->mode==3 && p->reads==1)return ___ERR_CODE_EAGAIN;
  d->read_stage=___STAGE_CLOSED; /* emulate a close consuming its stage first */
  if(p->mode==1)return ___FIX(___INVALID_OP_ERR);
  if(p->rd>=0){close(p->rd);p->rd=-1;}
 } else {
  p->writes++;d->write_stage=___STAGE_CLOSED;
  if(p->mode==2)return ___FIX(___INVALID_OP_ERR);
  if(p->wr>=0){close(p->wr);p->wr=-1;}
 }
 return ___FIX(___NO_ERR);
}
static ___device_vtbl table={kind,sel,release,force,cls};
static probe_device *make_probe(___device_group *g,int mode) {
 int fds[2];probe_device *p=(probe_device*)___ALLOC_MEM(sizeof(*p));
 if(!p || pipe(fds))return NULL;
 memset(p,0,sizeof(*p));p->rd=fds[0];p->wr=fds[1];p->mode=mode;
 p->base.vtbl=&table;p->base.refcount=1;
 p->base.direction=p->base.close_direction=___DIRECTION_RD|___DIRECTION_WR;
 p->base.read_stage=p->base.write_stage=___STAGE_OPEN;
 ___device_add_to_group(g,&p->base);return p;
}
static int check_local(int mode) {
 ___device_group *g;probe_device *p;___SCMOBJ e;int calls;
 if(___device_group_setup(&g)!=___FIX(___NO_ERR))return 0;
 p=make_probe(g,mode);if(!p)return 0;
 freed_count=0;e=___device_group_cleanup_checked(g);
 if(mode==0 || mode==3) {fprintf(stderr,"DEVICE-LOCAL mode=%d err=%ld freed=%d\n",mode,(long)___INT(e),freed_count);return e==___FIX(___NO_ERR)&&freed_count==1;}
 if(e==___FIX(___NO_ERR)||g->list!=&p->base||p->base.group!=g||p->base.refcount!=1||freed_count!=0)return 0;
 calls=p->reads+p->writes+p->releases;
 if(___device_group_cleanup_checked(g)!=e || calls!=p->reads+p->writes+p->releases)return 0;
 if(mode==1 && (p->writes!=0 || fcntl(p->rd,F_GETFD)<0))return 0;
 if(mode==2 && (p->rd!=-1 || fcntl(p->wr,F_GETFD)<0))return 0;
 if(mode==4 && (p->releases!=1 || p->rd!=-1 || p->wr!=-1))return 0;
 /* Test-owned local fixture: no escaped pointer/consumer remains. Its explicit
    owner can dispose known synthetic failure state without retrying runtime. */
 if(p->rd>=0)close(p->rd);if(p->wr>=0)close(p->wr);
 ___device_remove_from_group(&p->base);___FREE_MEM(p);___FREE_MEM(g);return 1;
}
static void retained(void) {
 probe_device *p=global_probe;int ok=p && ___io_mod.setup && p->base.group &&
  p->base.group->list==&p->base && p->base.refcount==1 && p->reads==1 &&
  p->writes==0 && p->releases==0 && observed_gstate->setup_state==2 &&
  observed_gstate->vmstate0.processor_count==1 && fcntl(p->rd,F_GETFD)>=0;
 /* VM field2 is unused-field2 in this bound _thread#.scm, type field at0. */
 if(ok && root_index>=0) {___SCMOBJ record=___UNCHECKEDSTRUCTUREREF(___VM_SCMOBJ(&observed_gstate->vmstate0),___FIX(root_index),___FAL,___FAL);
  ok=___VECTORELEM(record,1)==___FIX(4);}
 fprintf(stderr,"DEVICE-GLOBAL-RETAINED owner=%d roots=%d reads=%d releases=%d\n",ok,ok,p?p->reads:-1,p?p->releases:-1);
}
static int install_global(___SCMOBJ record) {
 int i;observed_gstate=___GSTATE;
 for(i=0;i<___VM_SIZE;i++)if(___UNCHECKEDSTRUCTUREREF(___VM_SCMOBJ(&observed_gstate->vmstate0),___FIX(i),___FAL,___FAL)==record)root_index=i;
 if(root_index<0)return 0;
 ___device_group *g=___global_device_group();global_probe=make_probe(g,1);
 if(!global_probe)return 0;
 g->list=&global_probe->base;atexit(retained);return 1;
}

static ___SCMOBJ wrapped_object;
static int wrapped_releases,wrapped_mode;
static void wrapped_end(void) {
 int ok;
 if(wrapped_mode==0) {ok=wrapped_releases==1;fprintf(stderr,"DEVICE-WRAPPER-SUCCESS released-once=%d\n",ok);return;}
 ok=global_probe && global_probe->base.group && global_probe->base.refcount==1 && ___io_mod.setup && observed_gstate->setup_state==2 && observed_gstate->vmstate0.processor_count==1 &&
   ___FOREIGN_RELEASE_FN_FIELD(wrapped_object)==0 && ___FOREIGN_PTR_FIELD(wrapped_object)==0;
 if(ok) {___SCMOBJ record=___UNCHECKEDSTRUCTUREREF(___VM_SCMOBJ(&observed_gstate->vmstate0),___FIX(root_index),___FAL,___FAL);ok=___VECTORELEM(record,1)==___FIX(4);}
 fprintf(stderr,"DEVICE-WRAPPER-FAILED disarmed-rooted-owner=%d calls=%d\n",ok,wrapped_releases);
}
static ___SCMOBJ wrapped_release(___device *d) {
 wrapped_releases++;
 if(wrapped_mode==4)return ___FIX(___INVALID_OP_ERR);
 return ___FIX(___NO_ERR);
}
static ___device_vtbl wrapped_table={kind,sel,wrapped_release,force,cls};
static ___SCMOBJ make_wrapped(int mode,___SCMOBJ record) {
 ___SCMOBJ result,e;int i;observed_gstate=___GSTATE;wrapped_mode=mode;
 for(i=0;i<___VM_SIZE;i++)if(___UNCHECKEDSTRUCTUREREF(___VM_SCMOBJ(&observed_gstate->vmstate0),___FIX(i),___FAL,___FAL)==record)root_index=i;
 if(root_index<0)return ___FIX(___INVALID_OP_ERR);
 global_probe=make_probe(___global_device_group(),mode);
 if(!global_probe)return ___FIX(___HEAP_OVERFLOW_ERR);
 global_probe->base.vtbl=&wrapped_table;global_probe->base.group->list=&global_probe->base;
 e=___NONNULLPOINTER_to_SCMOBJ(___PSTATE,global_probe,___FAL,___device_cleanup_from_ptr,&result,___RETURN_POS);
 if(e!=___FIX(___NO_ERR))return e;
 wrapped_object=result;atexit(wrapped_end);fprintf(stderr,"DEVICE-WRAPPER-CREATED p=%d\n",___PROCESSOR_ID(___PSTATE,___VMSTATE));return ___release_scmobj(result);
}
end-c
)
(define make-wrapped (c-lambda (int scheme-object) scheme-object "make_wrapped"))
(define check-local (c-lambda (int) int "check_local"))
(define install-global (c-lambda (scheme-object) int "install_global"))
(if (equal? (getenv "SMP_DEVICE_GLOBAL") "definitions") (##void)
(if (equal? (getenv "SMP_DEVICE_GLOBAL") "1")
 (if (not (= (install-global (##fault-control-record)) 1)) (error "global injection setup failed"))
 (begin
  (let loop ((mode 0))
   (if (< mode 5) (begin (if (not (= (check-local mode) 1)) (error "device ownership control failed" mode)) (##gc)(loop (+ mode 1)))))
  (display "DEVICE-READ-WRITE-RELEASE-RETAINED-EAGAIN 5\n")(force-output))))
'''
ESCAPE=r'''
(define outside #f)(define initialized? #f)(define saved #f)(define step 0)
(call/cc (lambda (k) (set! outside k)))
(if initialized? (error "escaped destination executed"))
(set! initialized? #t)
(define outside-cont (continuation-capture (lambda (k) k)))
(define payload (make-vector 4096 617))
(define (final-check)
 (##gc)
 (if (not (= step 2)) (error "callback prefix duplicated or suffix lost" step))
 (if (not (= (vector-ref payload 4095) 617)) (error "suffix payload lost"))
 (let ((e (##vector-ref (##fault-control-record) 5)))
  (if (not (and (vector? e) (eq? (vector-ref e 0) 'fault-callback-escape))) (error "escape root lost")))
 (display "ESCAPE-SUFFIX-ERROR-ROOTED-ONCE\n")(force-output))
(define (first)
 (set! step 1)
 (call/cc (lambda (k) (set! saved k)))
 (if (equal? (getenv "SMP_ESCAPE_WILL") "1")
     (continuation-graft outside-cont (lambda () (error "escaped graft destination executed")))
     (outside 'escape))
 (error "escape returned"))
(define (second)
 (if (not (= step 1)) (error "first callback did not execute once"))
 (set! step 2)(##gc)(saved 'reenter)
 (error "retired callback continuation returned"))
(define (add f) (##add-job-at-tail! ##final-will-registry (make-will payload (lambda (v) (f)))))
(if (equal? (getenv "SMP_ESCAPE_WILL") "1")
 (begin
  (add first)(add second)(add final-check))
 (begin (##add-exit-job! final-check)(##add-exit-job! second)(##add-exit-job! first)))
(call-with-output-file (getenv "SMP_WAKE_ARM_FILE") (lambda (p) (display "armed" p)))
(##device-select-abort! 0)
(let loop () (thread-sleep! 0.02)(loop))
'''
def main():
 spec=importlib.util.spec_from_file_location('control',ROOT/'evidence/research/smp-retirement-study/verify-owned-request-native.py');control=importlib.util.module_from_spec(spec);spec.loader.exec_module(control)
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/device-callback-native');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  dirs=',~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include')
  receipt=dict(schema='device-callback-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  def run(n,args,cap,extra=None):
   e=dict(env);e.update(extra or {});meta={};rc,log,to,sec=execute(args,out,cap,env=e,metadata=meta);(out/(n+'.log')).write_text(log);row=dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['rows'].append(row);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-2200:],flush=True);return row,log
  src=out/'device.scm';src.write_text(DEVICE.replace('@IO@',str(SOURCE/'lib/os_io.h')).replace('@BASE@',str(SOURCE/'lib/os_base.h')));module=out/'device.o1'
  row,_=run('compile-device',[str(SOURCE/'gsc-boot'),'-:p1'+dirs,'-dynamic','-o',str(module),str(src)],30,{'GAMBOPT':'p1'})
  if row['exit'] or row['timedOut']:raise RuntimeError('device fixture compile failed')
  load=out/'load.scm';load.write_text('(load '+json.dumps(str(module))+')\n')
  row,log=run('device-local',[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(load)],30,{'SMP_DEVICE_GLOBAL':'0'})
  row['passed']=row['exit']==0 and not row['timedOut'] and 'DEVICE-READ-WRITE-RELEASE-RETAINED-EAGAIN 5' in log
  c=out/'wake.c';c.write_text(control.C);lib=out/'wake.dylib';row,_=run('compile-injector',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(c)],30)
  if row['exit'] or row['timedOut']:raise RuntimeError('injector failed')
  for will in [0,1]:
   p=out/('escape-'+str(will)+'.scm');p.write_text(ESCAPE)
   row,log=run('escape-'+str(will),[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(p)],30,dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/('arm-escape-'+str(will))),SMP_ESCAPE_WILL=str(will)))
   row['passed']=row['exit']==70 and not row['timedOut'] and log.count('SMP-FAULT callback-escape-contained')==2 and 'ESCAPE-SUFFIX-ERROR-ROOTED-ONCE' in log and 'SMP-FAULT coordinator=P0 prepared' in log and 'SMP-FAULT native-grace' in log and 'escaped destination executed' not in log
  p=out/'global.scm';p.write_text(load.read_text()+control.FAULT)
  row,log=run('device-global-failure',[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(p)],30,dict(SMP_DEVICE_GLOBAL='1',DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/'arm-global')))
  row['passed']=row['exit']==70 and not row['timedOut'] and 'DEVICE-GLOBAL-RETAINED owner=1 roots=1 reads=1 releases=0' in log and 'cleanup failed with retained runtime resources' in log
  for mode in [0,1,4]:
   p=out/('wrapped-'+str(mode)+'.scm');program=load.read_text()+'(define kept-wrapper (make-wrapped '+str(mode)+' (##fault-control-record)))\n(##gc)\n'
   if mode:program+=control.FAULT
   else:program+='(display "WRAPPER-ALIVE-UNTIL-EXIT\\n")(force-output)\n'
   p.write_text(program)
   extra=dict(SMP_DEVICE_GLOBAL='definitions')
   if mode:extra.update(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/('arm-wrap-'+str(mode))))
   row,log=run('wrapped-'+str(mode),[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(p)],30,extra)
   row['passed']=not row['timedOut'] and (row['exit']==0 and 'DEVICE-WRAPPER-SUCCESS released-once=1' in log if mode==0 else row['exit']==70 and 'DEVICE-WRAPPER-FAILED disarmed-rooted-owner=1' in log and 'cleanup failed with retained runtime resources' in log)
  for mode in [0,1]:
   p=out/('wrapped-worker-'+str(mode)+'.scm');p.write_text(load.read_text()+'(define maker (make-thread (lambda () (##thread-migrate-to! 1) (make-wrapped '+str(mode)+' (##fault-control-record)))))\n(thread-start! maker)\n(define kept-wrapper (thread-join! maker))\n(##gc)\n'+(control.FAULT if mode else '(display "WORKER-WRAPPER-ROOTED\\n")(force-output)\n'))
   extra=dict(SMP_DEVICE_GLOBAL='definitions')
   if mode:extra.update(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/'arm-worker'))
   row,log=run('wrapped-worker-'+str(mode),[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(p)],30,extra)
   row['passed']=not row['timedOut'] and 'DEVICE-WRAPPER-CREATED p=1' in log and (row['exit']==0 and 'DEVICE-WRAPPER-SUCCESS released-once=1' in log if mode==0 else row['exit']==70 and 'DEVICE-WRAPPER-FAILED disarmed-rooted-owner=1' in log)
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
  if not all(r.get('passed',True) for r in receipt['rows']):raise RuntimeError('device/callback native control failed')
if __name__=='__main__':main()
