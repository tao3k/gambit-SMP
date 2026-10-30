"""Distinguish retryable select EINTR from ambiguous close EINTR."""
from pathlib import Path
import difflib,hashlib,json,os,re
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.framework import execute,available_processors
from gambit_smp.recipes import tree_identity
ROOT=Path(__file__).resolve().parents[3]
BUILD=ROOT/'.cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6'
SOURCE=BUILD/'source'
def main():
 with w.execution_scope(ROOT,'repair-9-12'),workspace_lease(ROOT,SOURCE,tree_identity(SOURCE)):
  out=w.task_output(ROOT,ROOT/'.cache/device-interruption-order');out.mkdir(parents=True,exist_ok=True)
  files={};t=(SOURCE/'lib/os_io.c').read_text();start=t.index('___SCMOBJ ___device_cleanup\n');end=t.index('\n\n/*',start);part=t[start:end]
  # Rechecking close after a readiness wait was interrupted is safe: that close
  # returned EAGAIN and has not committed a close. Never retry close's EINTR.
  pattern=r'(e = ___device_select \(devs, [^;]+;\n)(      if \(e != ___FIX\(___NO_ERR\)\))'
  part,n=re.subn(pattern,r'\1      if (e == ___FIX(___ERRNO_ERR(EINTR))) continue;\n\2',part);assert n==2
  t=t[:start]+part+t[end:]
  point=t.index('___SCMOBJ ___device_group_cleanup_checked')
  t=t[:point]+'''/* POSIX close EINTR does not authorize another close of the same number.
   Device ownership retains the first error rather than retrying a reused fd. */
#ifdef USE_POSIX
#define DEVICE_CLOSE_SOCKET_ONCE(s) close(s)
#else
#define DEVICE_CLOSE_SOCKET_ONCE(s) CLOSE_SOCKET(s)
#endif

'''+t[point:]
  spans=list(re.finditer(r'(?:___HIDDEN )?___SCMOBJ (\w*close\w*virt)\n',t))
  for match in reversed(spans):
   a=match.start();b=t.index('\n}\n',a)+3
   part=t[a:b].replace('___close_no_EINTR (','close (').replace('CLOSE_SOCKET(', 'DEVICE_CLOSE_SOCKET_ONCE(')
   t=t[:a]+part+t[b:]
  files['lib/os_io.c']=t
  delta=out/'delta';receipt=dict(schema='device-interruption-order.v1',sources={},stages=[],nativeAdmitted=False);patch=''
  for n,t in files.items():
   before=out/'before'/n;before.parent.mkdir(parents=True,exist_ok=True);before.write_bytes((SOURCE/n).read_bytes());p=delta/n;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(t);receipt['sources'][n]=dict(before=hashlib.sha256(before.read_bytes()).hexdigest(),after=hashlib.sha256(p.read_bytes()).hexdigest());patch+=''.join(difflib.unified_diff(before.read_text().splitlines(keepends=True),t.splitlines(keepends=True),fromfile='a/'+n,tofile='b/'+n))
  (out/'device-interruption-order.patch').write_text(patch);(ROOT/'evidence/research/smp-retirement-study/device-interruption-order.patch').write_text(patch)
  state=json.loads((BUILD/'source-state.json').read_text());incoming=dict(state['inputs']);incoming.update(tree_identity(delta));w.sync_build_source(ROOT,BUILD,delta,inventory=incoming,mutable=state['mutable'],overlay_files=state['overlayFiles'])
  env=dict(os.environ);env.update(json.loads((BUILD/'configure-proof.json').read_text())['commands'][0]['environment']);env['GAMBOPT']='p1'
  def run(n,args,cap):
   meta={};rc,log,to,sec=execute(args,SOURCE,cap,env=env,metadata=meta);(out/(n+'.log')).write_text(log);receipt['stages'].append(dict(name=n,exit=rc,timedOut=to,seconds=sec,process=meta));(out/'receipt.json').write_text(json.dumps(receipt,indent=2));print(n,rc,to,sec,log[-700:],flush=True)
   if rc or to:raise RuntimeError(n)
  try:
   run('native-core',['make','-j'+str(available_processors()),'-C',str(SOURCE/'lib'),'libgambit.a'],166.904774624)
   run('native-gsi',['make','-j'+str(available_processors()),'-C',str(SOURCE/'gsi'),'gsi'],56.189193917)
   receipt['gsiSha256']=hashlib.sha256((SOURCE/'gsi/gsi').read_bytes()).hexdigest();(out/'receipt.json').write_text(json.dumps(receipt,indent=2))
  finally:w.checkpoint_build_source(SOURCE,phase='building',deviceInterruptionOrder=dict(receipt=str(out/'receipt.json'),diagnosticOnly=True,runtimeAdmitted=False))
  print(out,flush=True)
if __name__=='__main__':main()
