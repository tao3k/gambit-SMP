"""Close matched marker lifetimes on normal C return, throw and OS retirement."""
from pathlib import Path
import difflib, hashlib, json, os
from gambit_smp import workspace as w
from gambit_smp.framework import execute, available_processors
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'

REGISTRY=r'''
/* The Scheme marker is a still object with an external reference. This native
   entry is not scanned as Scheme and never stores a movable heap pointer.
   Only its OS owner mutates the list; join is the last-reader boundary. */
typedef struct sfun_marker_owner_entry {
  ___SCMOBJ marker;
  struct sfun_marker_owner_entry *next;
} sfun_marker_owner_entry;

static void retire_marker_entry (___processor_state ps,
                                 sfun_marker_owner_entry *entry)
{
  ___VECTORELEM(entry->marker, 0) = ___FAL;
  ___still_obj_refcount_dec (entry->marker);
  __atomic_fetch_sub (&ps->sfun_marker_count, 1, __ATOMIC_RELEASE);
  free (entry);
}

void ___retire_sfun_stack_markers (___processor_state ps)
{
  unsigned int retired = 0;
  /* Called by this worker immediately before nonreturning OS thread exit.
     Every C frame on this stack is now nonreturnable, including nested SFUN. */
  while (ps->sfun_markers != NULL)
    {
      sfun_marker_owner_entry *entry = (sfun_marker_owner_entry*)ps->sfun_markers;
      ps->sfun_markers = entry->next;
      retire_marker_entry (ps, entry);
      retired++;
    }
  if (__atomic_load_n (&___VMSTATE_FROM_PSTATE(ps)->os.wake_fault_errno,
                       __ATOMIC_ACQUIRE) != 0)
    fprintf (stderr, "SMP-FAULT retired-markers p=%d count=%u\n",
      ___PROCESSOR_ID(ps,___VMSTATE_FROM_PSTATE(ps)), retired);
}

'''

GUARD=r'''
static int vm_native_consumers_clear (___virtual_machine_state vm)
{
  int i;
  if (__atomic_load_n (&vm->os.wake_writers, __ATOMIC_ACQUIRE) != 0 ||
      __atomic_load_n (&vm->os.wake_selectors, __ATOMIC_ACQUIRE) != 0)
    return 0;
  for (i=0; i<___MAX_PROCESSORS; i++)
    if (__atomic_load_n (&___PSTATE_FROM_PROCESSOR_ID(i,vm)->sfun_marker_count,
                         __ATOMIC_ACQUIRE) != 0)
      return 0;
  return 1;
}

'''

def once(s,a,b):
 assert s.count(a)==1,a[:100]
 return s.replace(a,b,1)

def transformed():
 files={}
 t=(SOURCE/'include/gambit.h.in').read_text()
 t=once(t,'    ___BOOL procedural_interrupts_ready;', '''    ___BOOL procedural_interrupts_ready;
    void *sfun_markers; /* native ownership entries, not Scheme roots */
    volatile unsigned int sfun_marker_count;''')
 files['include/gambit.h.in']=t
 t=(SOURCE/'lib/c_intf.h').read_text()
 t=once(t,'#define ___C_INTF_H','#define ___C_INTF_H\n\nextern void ___retire_sfun_stack_markers (___processor_state ps);')
 files['lib/c_intf.h']=t
 t=(SOURCE/'lib/c_intf.c').read_text()
 start=t.index('___EXP_FUNC(___SCMOBJ,___make_sfun_stack_marker)')
 t=t[:start]+REGISTRY+t[start:]
 start=t.index('___EXP_FUNC(___SCMOBJ,___make_sfun_stack_marker)')
 pos=t.index('  *marker = stack_marker;',start)
 t=t[:pos]+'''  {
    sfun_marker_owner_entry *entry = (sfun_marker_owner_entry*)malloc(sizeof(*entry));
    if (entry == NULL)
      { ___still_obj_refcount_dec (stack_marker);
        return ___FIX(___SFUN_HEAP_OVERFLOW_ERR); }
    entry->marker = stack_marker;
    entry->next = (sfun_marker_owner_entry*)___ps->sfun_markers;
    ___ps->sfun_markers = entry;
    __atomic_fetch_add (&___ps->sfun_marker_count, 1, __ATOMIC_RELEASE);
  }

'''+t[pos:]
 old='''  ___VECTORELEM(marker, 0) = ___FAL; /* invalidate the C stack frame */
  ___still_obj_refcount_dec (marker); /* allow GC of stack marker */'''
 new='''  ___processor_state ps = ___PSTATE;
  sfun_marker_owner_entry **link;
#ifndef ___SINGLE_THREADED_VMS
  if (___INT(___VECTORELEM(marker,1)) !=
      ___PROCESSOR_ID(ps,___VMSTATE_FROM_PSTATE(ps)))
    return; /* A foreign OS owner cannot mutate this marker list. */
#endif
  link = (sfun_marker_owner_entry**)&ps->sfun_markers;
  while (*link != NULL && (*link)->marker != marker)
    link = &(*link)->next;
  if (*link != NULL)
    {
      sfun_marker_owner_entry *entry = *link;
      *link = entry->next;
      retire_marker_entry (ps, entry);
    }
  /* An unmatched/stale kill cannot decrement somebody else's external ref.
     The actual owner's remaining entry keeps retirement refused. */'''
 t=once(t,old,new);files['lib/c_intf.c']=t
 t=(SOURCE/'lib/setup.c').read_text()
 start=t.index('___EXP_FUNC(___SCMOBJ,___setup_pstate)')
 pos=t.index('  /*',start)
 t=t[:pos]+'''  if (___ps->sfun_markers != NULL ||
      __atomic_load_n (&___ps->sfun_marker_count, __ATOMIC_ACQUIRE) != 0)
    return ___FIX(___INVALID_OP_ERR);

'''+t[pos:]
 t=once(t,'''          cleanup_interrupts_pstate (___ps);
          ___cleanup_os_pstate (___ps);
          ___thread_exit ();''','''          cleanup_interrupts_pstate (___ps);
          ___retire_sfun_stack_markers (___ps);
          ___cleanup_os_pstate (___ps);
          ___thread_exit ();''')
 start=t.index('___EXP_FUNC(___SCMOBJ,___setup_vmstate)')
 pos=t.index('  ___vms->processor_count = 0;',start)
 t=t[:pos]+'''  {
    int p;
    for (p=0; p<___MAX_PROCESSORS; p++)
      {
        ___processor_state ps = ___PSTATE_FROM_PROCESSOR_ID(p,___vms);
        ps->sfun_markers = NULL;
        __atomic_store_n (&ps->sfun_marker_count, 0, __ATOMIC_RELAXED);
      }
  }
'''+t[pos:]
 pos=t.index('___EXP_FUNC(___SCMOBJ,___cleanup_owned_vmstate)')
 t=t[:pos]+GUARD+t[pos:]
 pos=t.index('  ___cleanup_pstate(___PSTATE_FROM_PROCESSOR_ID(0,___vms));',t.index('___EXP_FUNC(___SCMOBJ,___cleanup_owned_vmstate)'))
 t=t[:pos]+'''  if (!vm_native_consumers_clear(___vms))
    {
      ___vm_registry_open();
      ___MUTEX_UNLOCK(___GSTATE->vm_list_mut);
      return ___FIX(___INVALID_OP_ERR);
    }
'''+t[pos:]
 start=t.index('___EXP_FUNC(___SCMOBJ,___cleanup_checked)')
 pos=t.index('  ___ps = ___PSTATE;',start)
 t=t[:pos]+'''  /* Cleanup from a returnable Scheme/C invocation is refused before any
     admission, interrupt, processor-count or root mutation. */
  if (___vms->processor_count > 0 &&
      (___PSTATE != ___PSTATE_FROM_PROCESSOR_ID(0,___vms) ||
       __atomic_load_n (&___PSTATE_FROM_PROCESSOR_ID(0,___vms)->sfun_marker_count,
                        __ATOMIC_ACQUIRE) != 0))
    return ___FIX(___INVALID_OP_ERR);

'''+t[pos:]
 old='''  if (__atomic_load_n (&___vms->os.wake_writers, __ATOMIC_ACQUIRE) != 0 ||
      __atomic_load_n (&___vms->os.wake_selectors, __ATOMIC_ACQUIRE) != 0)'''
 assert t.find(old,start)>=0
 t=t[:start]+t[start:].replace(old,'  if (!vm_native_consumers_clear(___vms))',1)
 pos=t.index('  ___cleanup_pstate (___ps);',start)
 t=t[:pos]+'''  if (__atomic_load_n (&___vms->os.wake_fault_errno, __ATOMIC_ACQUIRE) != 0)
    fprintf (stderr, "SMP-FAULT native-grace writers=0 selectors=0 markers=0\\n");

'''+t[pos:]
 # Other registered VMs retain their roots too, before any VM memory cleanup.
 old='''      ___vms = ___vms->prev;
      cleanup_vmstate_locked (___vms);'''
 new='''      ___vms = ___vms->prev;
      if (!vm_native_consumers_clear(___vms))
        {
          ___MUTEX_UNLOCK(___GSTATE->vm_list_mut);
          cleanup_error = ___FIX(___INVALID_OP_ERR); cleanup_phase = 2;
          return cleanup_error;
        }
      cleanup_vmstate_locked (___vms);'''
 t=once(t,old,new);files['lib/setup.c']=t
 return files

def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/marker-retirement-repair');out.mkdir(parents=True,exist_ok=True)
  files=transformed();delta=out/'delta';receipt=dict(schema='marker-retirement-repair.v1',stages=[],sources={},nativeAdmitted=False)
  patch=''
  for n,t in files.items():
   before=out/'before'/n;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/n).read_bytes())
   p=delta/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t)
   receipt['sources'][n]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest())
   patch+=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  (out/'marker-retirement.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/marker-retirement.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta))
  w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-700:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('configured-header',['/bin/sh','./config.status','include/gambit.h'],59.52238483203109)
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],226.86804100096924)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],58.03175566601567)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',markerRetirementExperiment=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
