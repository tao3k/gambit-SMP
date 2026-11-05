"""Apply checked device retention and winding callback containment in-place."""
from pathlib import Path
import difflib,hashlib,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute,available_processors
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def once(s,a,b):
 assert s.count(a)==1,a[:90]
 return s.replace(a,b,1)
def transformed():
 files={}
 t=(SOURCE/'lib/os_io.h').read_text()
 t=once(t,'    int close_direction;','    ___SCMOBJ cleanup_error;       /* sticky immediate error; group retains owner */\n    int close_direction;')
 t=once(t,'extern void ___device_group_cleanup','extern ___SCMOBJ ___device_group_cleanup_checked\n   ___P((___device_group *dgroup),());\n\nextern void ___device_group_cleanup')
 t=once(t,'extern void ___cleanup_io_module ___PVOID;','extern ___SCMOBJ ___cleanup_io_module_checked ___PVOID;\nextern void ___cleanup_io_module ___PVOID;');files['lib/os_io.h']=t
 t=(SOURCE/'lib/os_io.c').read_text()
 start=t.index('void ___device_group_cleanup\n');end=t.index('\n\nvoid ___device_add_to_group',start)
 t=t[:start]+'''___SCMOBJ ___device_group_cleanup_checked
   ___P((___device_group *dgroup),(dgroup)
___device_group *dgroup;)
{
  ___SCMOBJ e;
  while (dgroup->list != NULL)
    if ((e = ___device_cleanup (dgroup->list)) != ___FIX(___NO_ERR))
      return e; /* group, failed device and untouched suffix remain owned */
  ___FREE_MEM(dgroup);
  return ___FIX(___NO_ERR);
}

void ___device_group_cleanup
   ___P((___device_group *dgroup),(dgroup)
___device_group *dgroup;)
{
  (void)___device_group_cleanup_checked (dgroup);
}'''+t[end:]
 t=once(t,'  dev->group = dgroup;','  dev->cleanup_error = ___FIX(___NO_ERR);\n  dev->group = dgroup;')
 t=once(t,'  return ___device_close_virt (self, direction);','''  ___SCMOBJ e;
  if (self->cleanup_error != ___FIX(___NO_ERR))
    return self->cleanup_error;
  e = ___device_close_virt (self, direction);
  /* A close may already have consumed its descriptor before reporting error.
     Never retry it or trust an already-CLOSED stage as proof of success. */
  if (e != ___FIX(___NO_ERR) && e != ___ERR_CODE_EAGAIN)
    self->cleanup_error = e;
  return e;''')
 t=once(t,'      e = ___device_release_virt (self);\n      ___FREE_MEM(self);','''      e = self->cleanup_error;
      if (e == ___FIX(___NO_ERR)) e = ___device_release_virt (self);
      if (e == ___FIX(___NO_ERR))
        ___FREE_MEM(self);
      else
        {
          self->cleanup_error = e;
#ifdef USE_PUMPS
          InterlockedIncrement (&self->refcount);
#else
          self->refcount++;
#endif
        }''')
 start=t.index('___SCMOBJ ___device_cleanup\n');end=t.index('\n\n/*',start)
 part=t[start:end]
 part=once(part,'  ___device *devs[1];','  ___device *devs[1];\n  ___device_group *owner = self->group;')
 part=once(part,'  ___device_remove_from_group (self);','  if (self->cleanup_error != ___FIX(___NO_ERR))\n    return self->cleanup_error;')
 part=part.replace('        return e;', '        { self->cleanup_error = e; return e; }')
 part=once(part,'  return ___device_release (self);','''  ___device_remove_from_group (self);
  e = ___device_release (self);
  if (e != ___FIX(___NO_ERR))
    {
      /* Failed release retained allocation/ref; restore group ownership but
         preserve its sticky error (add_to_group initializes fresh devices). */
      ___device_add_to_group (owner, self);
      self->cleanup_error = e;
    }
  return e;''')
 t=t[:start]+part+t[end:]
 t=once(t,'___HIDDEN void io_module_cleanup ___PVOID\n{\n  ___cleanup_child_interrupt_handling ();','''___HIDDEN ___SCMOBJ io_module_cleanup ___PVOID
{
  ___SCMOBJ e = ___device_group_cleanup_checked (___io_mod.dgroup);
  if (e != ___FIX(___NO_ERR)) return e;
  ___io_mod.dgroup = NULL;
  ___cleanup_child_interrupt_handling ();''')
 # Only the terminal module-cleanup occurrence; setup-failure wrapper retained.
 start=t.index('___HIDDEN ___SCMOBJ io_module_cleanup');end=t.index('/*---------------------------------------------------------------------------*/',start)
 part=t[start:end];part=once(part,'  ___device_group_cleanup (___io_mod.dgroup);','  return ___FIX(___NO_ERR);');t=t[:start]+part+t[end:]
 start=t.index('void ___cleanup_io_module ___PVOID');end=t.index('/*---------------------------------------------------------------------------*/',start)
 part=t[start:end].replace('void ___cleanup_io_module','___SCMOBJ ___cleanup_io_module_checked',1)
 part=once(part,'      io_module_cleanup ();/*****************************/','      ___SCMOBJ e = io_module_cleanup ();\n      if (e != ___FIX(___NO_ERR)) return e;')
 pos=part.rfind('}')
 part=part[:pos]+'  return ___FIX(___NO_ERR);\n'+part[pos:]
 part+='\nvoid ___cleanup_io_module ___PVOID\n{\n  (void)___cleanup_io_module_checked ();\n}\n\n'
 t=t[:start]+part+t[end:];files['lib/os_io.c']=t
 t=(SOURCE/'lib/setup.c').read_text();start=t.index('___EXP_FUNC(___SCMOBJ,___cleanup_checked)')
 head=t[:start];part=t[start:]
 # Zero-population and normal teardown must check IO before freeing roots.
 part=once(part,'      /* VM setup already unwound its private prefix, not this global prefix. */','''      err = ___cleanup_io_module_checked ();
      if (err != ___FIX(___NO_ERR))
        { cleanup_error = err; cleanup_phase = 2; return err; }
      /* VM setup already unwound its private prefix, not this global prefix. */''')
 needle='  ___cleanup_pstate (___ps);'
 part=once(part,needle,'''  /* Preflight every native consumer before global IO ownership transfer.
     Host VM borrows must already be quiescent; the registry is sealed. */
#ifndef ___SINGLE_VM
  ___MUTEX_LOCK(___GSTATE->vm_list_mut);
  {
    ___virtual_machine_state probe = &___GSTATE->vmstate0;
    do {
      if (!vm_native_consumers_clear(probe))
        {
          ___MUTEX_UNLOCK(___GSTATE->vm_list_mut);
          cleanup_error = ___FIX(___INVALID_OP_ERR); cleanup_phase = 2;
          return cleanup_error;
        }
      probe = probe->prev;
    } while (probe != &___GSTATE->vmstate0);
  }
  ___MUTEX_UNLOCK(___GSTATE->vm_list_mut);
#endif
  err = ___cleanup_io_module_checked ();
  if (err != ___FIX(___NO_ERR))
    { cleanup_error = err; cleanup_phase = 2; return err; }

'''+needle)
 files['lib/setup.c']=head+part
 t=(SOURCE/'lib/_thread.scm').read_text();start=t.index('(define-prim (##fault-control-cursor!');end=t.index('(define-prim (##fault-control-run!',start)
 t=t[:start]+'''(define-prim (##fault-control-callback! record item execute)
  ;; Recovery is outside the winding guard, but still inside the mapped
  ;; coordinator frame. No public continuation may carry this callback out.
  (##continuation-capture
   (lambda (recovery)
     (let ((live? #t) (returned? #f))
       (##dynamic-wind
        (lambda ()
          (if (##not live?)
              (##error "fault callback continuation retired")))
        (lambda ()
          (##with-exception-catcher
           (lambda (exc) (##vector-set! record 5 exc))
           (lambda () (execute item)))
          (set! returned? #t))
        (lambda ()
          (set! live? #f)
          (if (##not returned?)
              (begin
                (##vector-set! record 5 (##vector 'fault-callback-escape item))
                (##c-code "fprintf(stderr, \\"SMP-FAULT callback-escape-contained\\\\n\\");")
                (##continuation-return recovery #f)))))))))

(define-prim (##fault-control-cursor! record slot execute)
  (let loop ()
    (let ((lst (##vector-ref record slot)))
      (if (##pair? lst)
          (let ((item (##car lst)))
            (##vector-set! record slot (##cdr lst))
            (##vector-set! record 7 item)
            (##fault-control-callback! record item execute)
            (##vector-set! record 7 #f)
            (loop))))))

'''+t[end:];files['lib/_thread.scm']=t
 return files
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/device-callback-closure');out.mkdir(parents=True,exist_ok=True)
  files=transformed();delta=out/'delta';receipt=dict(schema='device-callback-closure.v1',sources={},stages=[],nativeAdmitted=False);patch=''
  for n,t in files.items():
   before=out/'before'/n;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/n).read_bytes());p=delta/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t)
   receipt['sources'][n]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest());patch+=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  (out/'device-callback-closure.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/device-callback-closure.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta));w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-1000:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('scheme-generation',['make','-C',str(SOURCE/'lib'),'_thread.c','_gambit.c'],97.97998325)
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],196.73063379)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],56.99985775)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',deviceCallbackClosure=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
