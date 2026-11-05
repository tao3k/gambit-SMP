"""Disarm canonical device foreign wrappers before native group release."""
from pathlib import Path
import difflib,hashlib,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute,available_processors
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
HELPER='''/* Native device foreigns are still objects with this exact canonical
   release function. No object/storage is freed by this traversal. A failed
   callback has transferred responsibility to its still-linked native group.
   The sealed, joined owner performs this before any VM root destruction. */
___SCMOBJ ___prepare_device_foreigns_vmstate (___virtual_machine_state vm)
{
  int i;
  for (i=0; i<vm->processor_count; i++)
    {
      ___WORD *base = ___CAST(___WORD*,___PSTATE_FROM_PROCESSOR_ID(i,vm)->mem.still_objs_);
      while (base != NULL)
        {
          ___WORD *next = ___CAST(___WORD*,base[___STILL_LINK]);
          if (___HD_SUBTYPE(base[___STILL_BODY-1]) == ___sFOREIGN)
            {
              ___SCMOBJ obj = ___TAG(base+___STILL_BODY-___REFERENCE_TO_BODY,___tSUBTYPED);
              if (___FOREIGN_RELEASE_FN_FIELD(obj) ==
                  ___CAST(___SCMOBJ,___device_cleanup_from_ptr))
                {
                  ___SCMOBJ e = ___release_foreign(obj);
                  if (e != ___FIX(___NO_ERR)) return e;
                }
            }
          base = next;
        }
    }
  return ___FIX(___NO_ERR);
}

'''
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/device-foreign-handoff');out.mkdir(parents=True,exist_ok=True)
  files={}
  t=(SOURCE/'lib/mem.h').read_text();needle='extern void ___cleanup_mem_vmstate';assert needle in t;t=t.replace(needle,'extern ___SCMOBJ ___prepare_device_foreigns_vmstate (___virtual_machine_state vm);\n\n'+needle,1);files['lib/mem.h']=t
  t=(SOURCE/'lib/mem.c').read_text();t=t.replace('#include "os_time.h"','#include "os_time.h"\n#include "os_io.h"',1);needle='___HIDDEN void free_still_objs';assert needle in t;t=t.replace(needle,HELPER+needle,1);files['lib/mem.c']=t
  t=(SOURCE/'lib/setup.c').read_text();needle='\n  err = ___cleanup_io_module_checked ();';assert t.count(needle)==1
  t=t.replace(needle,'''
  {
    ___virtual_machine_state probe = &___GSTATE->vmstate0;
    do {
      err = ___prepare_device_foreigns_vmstate(probe);
      if (err != ___FIX(___NO_ERR))
        { cleanup_error = err; cleanup_phase = 2; return err; }
#ifndef ___SINGLE_VM
      probe = probe->prev;
#endif
    } while (probe != &___GSTATE->vmstate0);
  }
'''+needle,1);files['lib/setup.c']=t
  receipt=dict(schema='device-foreign-handoff.v1',sources={},stages=[],nativeAdmitted=False);delta=out/'delta';patch=''
  for n,t in files.items():
   before=out/'before'/n;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/n).read_bytes());p=delta/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t);receipt['sources'][n]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest());patch+=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  (out/'device-foreign-handoff.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/device-foreign-handoff.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta));w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-1300:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],182.848100707)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],56.345830625)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',deviceForeignHandoff=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
