"""Real nested C/Scheme calls, GC and live-owner cleanup refusal."""
from pathlib import Path
import os,json,hashlib
from gambit_smp import workspace as w
from gambit_smp.framework import execute
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
FIXTURE=r'''
(c-declare "int smp_marker_callback(int); int smp_cleanup_callback(void);")
(define marker-count
 (c-lambda () int "___result = __atomic_load_n (&___PSTATE->sfun_marker_count, __ATOMIC_ACQUIRE);"))
(define invoke-marker (c-lambda (int) int "smp_marker_callback"))
(define invoke-cleanup (c-lambda () int "smp_cleanup_callback"))
(define try-cleanup
 (c-lambda () int
  "___result = ___cleanup_checked() == ___FIX(___INVALID_OP_ERR) && ___VMSTATE->processor_count == 11 && ___GSTATE->setup_state == 1;"))
(c-define (smp-marker-callback n) (int) int "smp_marker_callback" ""
 (if (= n 0) (begin (##gc) (marker-count)) (invoke-marker (- n 1))))
(c-define (smp-cleanup-callback) () int "smp_cleanup_callback" ""
 (let ((before (marker-count)))
  (if (not (= (try-cleanup) 1)) (error "live marker cleanup was not refused"))
  (##gc)
  (if (not (= (marker-count) before)) (error "live marker changed across refusal"))
  1))
(define baseline (marker-count))
(let loop ((i 0))
 (if (< i 100)
  (begin
   (if (not (= (invoke-marker 5) (+ baseline 6))) (error "nested marker count mismatch"))
   (if (not (= (marker-count) baseline)) (error "matched marker leaked"))
   (loop (+ i 1)))))
(if (not (= (invoke-cleanup) 1)) (error "cleanup owner control failed"))
(if (not (= (marker-count) baseline)) (error "cleanup marker leaked"))
(if (not (= (##current-vm-processor-count) 11)) (error "cleanup mutated cohort"))
(display "NESTED-FFI-GC-MARKERS 600\n")
(display "LIVE-OWNER-CLEANUP-REFUSED cohort=11\n")(force-output)
'''
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/marker-ffi-native');out.mkdir(parents=True,exist_ok=True)
  source=out/'marker.scm';source.write_text(FIXTURE);module=out/'marker.o1'
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment'])
  receipt=dict(schema='marker-ffi-native.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),compilerSha256=hashlib.sha256((SOURCE/'gsc-boot').read_bytes()).hexdigest(),stages=[],nativeAdmitted=False)
  def run(name,args,cap,extra=None):
   e=dict(env);e.update(extra or {});meta={};rc,log,to,sec=execute(args,out,cap,env=e,metadata=meta);(out/(name+'.log')).write_text(log);row=dict(name=name,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['stages'].append(row);(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(name,rc,to,sec,log[-1600:],flush=True);return row,log
  dirs=',~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include')
  row,_=run('compile-ffi',[str(SOURCE/'gsc-boot'),'-:p1'+dirs,'-dynamic','-o',str(module),str(source)],30,{'GAMBOPT':'p1'})
  if row['exit']!=0 or row['timedOut']:raise RuntimeError('FFI fixture compilation failed')
  load=out/'load.scm';load.write_text('(load '+json.dumps(str(module))+')\n')
  row,log=run('native-ffi',[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(load)],30)
  row['passed']=row['exit']==0 and not row['timedOut'] and all(t in log for t in ['NESTED-FFI-GC-MARKERS 600','LIVE-OWNER-CLEANUP-REFUSED cohort=11'])
  receipt['moduleSha256']=hashlib.sha256(module.read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(out)
  if not row['passed']:raise RuntimeError('native FFI control failed: '+str(out))
if __name__=='__main__':main()
