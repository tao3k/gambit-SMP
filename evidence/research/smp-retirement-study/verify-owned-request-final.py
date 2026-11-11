"""Same-producer flood, procedural-error suffix and raw-unwind refusal."""
from pathlib import Path
import hashlib, importlib.util, json, os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
CALLBACK=r'''
(c-declare #<<end-c
static int smp_first, smp_second, smp_third;
static ___SCMOBJ smp_callback(void *self, ___SCMOBJ op) {
  if (op == ___FAL) return ___FIX(___NO_ERR);
  if (self == (void*)1) return ___FIX(___INVALID_OP_ERR);
  return ___FIX(___NO_ERR);
}
static ___procedural_interrupt_header smp_a, smp_b, smp_c;
static ___SCMOBJ smp_a_fn(void *self, ___SCMOBJ op) {
  smp_first++; return ___FIX(___INVALID_OP_ERR);
}
static ___SCMOBJ smp_b_fn(void *self, ___SCMOBJ op) {
  smp_second++; return ___FIX(___NO_ERR);
}
static ___SCMOBJ smp_c_fn(void *self, ___SCMOBJ op) {
  smp_third++; return ___FIX(___NO_ERR);
}
end-c
)
(define exercise
 (c-lambda () int #<<end-c
  int i;
  smp_a.execute_fn=smp_a_fn; smp_b.execute_fn=smp_b_fn;
  smp_c.execute_fn=smp_c_fn;
  ___EXT(___raise_procedural_interrupt_pstate)(___PSTATE,&smp_a);
  ___EXT(___raise_procedural_interrupt_pstate)(___PSTATE,&smp_b);
  for (i=0;i<16;i++) ___EXT(___service_interrupts_pstate)(___PSTATE);
  ___EXT(___raise_procedural_interrupt_pstate)(___PSTATE,&smp_c);
  for (i=0;i<16;i++) ___EXT(___service_interrupts_pstate)(___PSTATE);
  ___result = smp_first==1 && smp_second==1 && smp_third==1 &&
    ___PSTATE->procedural_interrupts_head==NULL &&
    ___PSTATE->procedural_interrupts_tail==NULL;
end-c
))
(if (not (= (exercise) 1)) (error "procedural error suffix lost"))
(##gc)
(display "PROCEDURAL-ERROR-SUFFIX-ONCE-RELOCK\n")(force-output)
'''
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/owned-request-final');out.mkdir(parents=True,exist_ok=True)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env.pop('GAMBOPT',None)
  dirs=',~~lib='+str(SOURCE/'lib')+',~~bin='+str(SOURCE/'bin')+',~~include='+str(SOURCE/'include')
  receipt=dict(schema='owned-request-final.v1',gsiSha256=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest(),rows=[],nativeAdmitted=False)
  def run(name,args,cap,extra=None):
   selected=dict(env);selected.update(extra or {});meta={}
   rc,log,to,sec=execute(args,out,cap,env=selected,metadata=meta)
   (out/(name+'.log')).write_text(log);row=dict(name=name,exit=rc,timedOut=to,seconds=sec,process=meta);receipt['rows'].append(row)
   (out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(name,rc,to,sec,log[-1200:],flush=True);return row,log
  flood=out/'flood.scm';flood.write_bytes((ROOT/'.cache/tasks/repair-9-12/runs/928d06812af1466ea123872f423efbda/outputs/owned-request-flood/flood.scm').read_bytes())
  receipt['floodSha256']=hashlib.sha256(flood.read_bytes()).hexdigest()
  for i in range(8):
   row,log=run('flood-'+str(i),[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(flood)],12)
   row['passed']=row['exit']==0 and not row['timedOut'] and 'PROBE-DONE 100000' in log
  src=out/'callback.scm';src.write_text(CALLBACK);module=out/'callback.o1'
  row,_=run('compile-callback',[str(SOURCE/'gsc-boot'),'-:p1'+dirs,'-dynamic','-o',str(module),str(src)],30,{'GAMBOPT':'p1'})
  if row['exit']==0 and not row['timedOut']:
   load=out/'callback-load.scm';load.write_text('(load '+json.dumps(str(module))+')\n')
   row,log=run('native-callback',[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(load)],30)
   row['passed']=row['exit']==0 and not row['timedOut'] and 'PROCEDURAL-ERROR-SUFFIX-ONCE-RELOCK' in log
  spec=importlib.util.spec_from_file_location('native_control',ROOT/'evidence/research/smp-retirement-study/verify-owned-request-native.py');control=importlib.util.module_from_spec(spec);spec.loader.exec_module(control)
  injector=out/'wake.c';injector.write_text(control.C);lib=out/'wake.dylib'
  row,_=run('compile-injector',['/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16','-dynamiclib','-O1','-o',str(lib),str(injector)],30)
  if row['exit']==0 and not row['timedOut']:
   raw=out/'raw.scm';raw.write_text(control.FAULT.replace('(call-with-output-file', '(##add-exit-job! (lambda () (display "RAW-UNWIND-BEFORE-PREPARED\\n")(force-output)(##exit-with-err-code-no-cleanup 43)))\n(call-with-output-file',1))
   row,log=run('raw-unwind-refused',[str(SOURCE/'gsi/gsi'),'-:p11'+dirs,str(raw)],30,dict(DYLD_INSERT_LIBRARIES=str(lib),SMP_WAKE_FAULT='2',SMP_WAKE_ARM_FILE=str(out/'arm')))
   row['passed']=not row['timedOut'] and row['exit']!=0 and 'RAW-UNWIND-BEFORE-PREPARED' in log and 'cleanup failed with retained runtime resources' in log and 'SMP-FAULT native-grace' not in log
   row['negativeControl']=True
  (out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(out,flush=True)
  if any(r['timedOut'] or (r['exit']!=0 and not r.get('negativeControl')) or not r.get('passed',True) for r in receipt['rows']):
   raise RuntimeError('final native controls failed: '+str(out))
if __name__=='__main__':main()
