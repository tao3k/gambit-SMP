"""Close the two-atomic writer admission handshake under existing custody."""
from pathlib import Path
import difflib, hashlib, json, os
from gambit_smp import workspace as w
from gambit_smp.framework import execute, available_processors
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/writer-close-order');out.mkdir(parents=True,exist_ok=True)
  files={n:(SOURCE/n).read_text() for n in ['lib/os_io.c','lib/setup.c']}
  files['lib/os_io.c']=files['lib/os_io.c'].replace('__atomic_fetch_add (&vm->os.wake_writers, 1, __ATOMIC_ACQ_REL);','''/* This count and the close flag form a two-atomic admission handshake.
     SC prevents both sides observing the other's old value. A live VM borrow
     is still required before this first dereference. */
  __atomic_fetch_add (&vm->os.wake_writers, 1, __ATOMIC_SEQ_CST);''',1).replace('__atomic_load_n (&vm->os.wake_fault_phase, __ATOMIC_ACQUIRE) >= 5','__atomic_load_n (&vm->os.wake_fault_phase, __ATOMIC_SEQ_CST) >= 5',1)
  files['lib/setup.c']=files['lib/setup.c'].replace('__atomic_load_n (&vm->os.wake_writers, __ATOMIC_ACQUIRE)', '__atomic_load_n (&vm->os.wake_writers, __ATOMIC_SEQ_CST)',1).replace('__atomic_store_n (&___vms->os.wake_fault_phase, 5, __ATOMIC_RELEASE);','''/* Paired with writer count/flag SC operations; acquire/release on
     separate atomics alone would permit both admission checks to miss. */
  __atomic_store_n (&___vms->os.wake_fault_phase, 5, __ATOMIC_SEQ_CST);''',1)
  delta=out/'delta';receipt=dict(schema='writer-close-order.v1',sources={},stages=[],nativeAdmitted=False);patch=''
  for n,t in files.items():
   before=out/'before'/n;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/n).read_bytes())
   p=delta/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t)
   assert p.read_bytes()!=before.read_bytes()
   receipt['sources'][n]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest())
   patch+=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  (out/'writer-close-order.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/writer-close-order.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta))
  w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-700:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],197.962969)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],57.214158)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',writerCloseOrderExperiment=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
