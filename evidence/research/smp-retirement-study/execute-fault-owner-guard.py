"""Protect the coordinator from public non-winding terminate/suspend exits."""
from pathlib import Path
import difflib,hashlib,json,os
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute,available_processors
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/fault-owner-guard');out.mkdir(parents=True,exist_ok=True)
  t=(SOURCE/'lib/_thread.scm').read_text()
  for op in ['terminate','suspend']:
   a=t.index('(define-prim (##thread-'+op+'! thread)');pos=t.index('  (##declare (not interrupts-enabled))',a)+len('  (##declare (not interrupts-enabled))')
   t=t[:pos]+'\n  (##fault-control-protect-owner! thread \''+op+')'+t[pos:]
  pos=t.index('(define-prim (##fault-control-callback!')
  t=t[:pos]+'''(define-prim (##fault-control-protect-owner! thread operation)
  (##declare (not interrupts-enabled))
  (if (##fx> (##fault-control-native-phase) 0)
      (let ((record (##fault-control-record)))
        (if (and (##vector? record) (##eq? thread (##vector-ref record 0)))
            (##error "fault coordinator lifecycle admission closed" operation)))))

'''+t[pos:]
  before=out/'before/lib/_thread.scm';before.parent.mkdir(parents=True);before.write_bytes((SOURCE/'lib/_thread.scm').read_bytes());delta=out/'delta';p=delta/'lib/_thread.scm';p.parent.mkdir(parents=True);p.write_text(t)
  patch=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/lib/_thread.scm',tofile='b/lib/_thread.scm'));(out/'fault-owner-guard.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/fault-owner-guard.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta));w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  receipt=dict(schema='fault-owner-guard.v1',sources={'lib/_thread.scm':dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest())},stages=[],nativeAdmitted=False)
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-700:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('scheme-generation',['make','-C',str(SOURCE/'lib'),'_thread.c','_gambit.c'],88.617475999)
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],165.937837415)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],56.037366417)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',faultOwnerGuard=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
