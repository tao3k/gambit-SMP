from pathlib import Path
import subprocess,json,hashlib,concurrent.futures
r=Path.cwd();t=r/'.cache/tasks/script-view-lifecycle-darwin';e=r/'evidence/research/script-view-lifecycle-darwin';e.mkdir(parents=True,exist_ok=True)
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
cmds={'quint':['quint','typecheck','models/build/incremental_build.qnt'],'lean':['/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean','models/build/IncrementalBuild.lean']}
def run(item):
 name,argv=item;q=subprocess.run(argv,capture_output=True,text=True,timeout=60)
 for stream in ['stdout','stderr']:(t/(name+'-check.'+stream+'.txt')).write_text(getattr(q,stream))
 return name,{'argv':argv,'exitCode':q.returncode,'sourceSha256':sha(r/argv[-1]),'stdoutSha256':sha(t/(name+'-check.stdout.txt')),'stderrSha256':sha(t/(name+'-check.stderr.txt')),'scope':('Ten modules typechecked only; lifecycle and development-work projections; no native refinement or exploration' if name=='quint' else '82 statements; lifecycle identity, revocation/custody separation and conditional work accounting; concrete issuer, continuation and I/O refinement open')}
with concurrent.futures.ThreadPoolExecutor(2) as pool:result=dict(pool.map(run,cmds.items()))
(t/'formal-results.json').write_text(json.dumps(result,indent=2)+'\n')
if any(v['exitCode'] for v in result.values()):
 assert not (t/'formal-attempt-3.json').exists(), 'Preserve existing failures'
 (t/'formal-attempt-3.json').write_text(json.dumps(result,indent=2)+'\n')
 for name,v in result.items():
  if v['exitCode']:
   (t/(name+'-attempt-3-source.txt')).write_bytes((r/v['argv'][-1]).read_bytes())
   for stream in ['stdout','stderr']:(t/(name+'-attempt-3.'+stream+'.txt')).write_bytes((t/(name+'-check.'+stream+'.txt')).read_bytes())
else:(e/'formal-results.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps({k:v['exitCode'] for k,v in result.items()}))
