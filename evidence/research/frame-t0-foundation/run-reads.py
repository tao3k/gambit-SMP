from pathlib import Path
import subprocess,json
r=Path.cwd();t=r/'.cache/tasks/frame-t0-foundation';base=[str(r/'.venv/bin/gambit-smp'),'--task','frame-t0-foundation','trajectory','clues']
for row in json.loads((t/'read-manifest.json').read_text()):
 stem=row['stem'];request=t/(stem+'.request.scm');p=subprocess.run(base,input=request.read_text(),capture_output=True,text=True,timeout=60)
 (t/(stem+'.scm')).write_text(p.stdout);(t/(stem+'.stderr.txt')).write_text(p.stderr);(t/(stem+'.invocation.json')).write_text(json.dumps({'argv':base,'request':str(request.relative_to(r)),'exitCode':p.returncode},indent=2)+'\n');assert p.returncode==0,p.stderr
 print(json.dumps({'completed':stem,'laws':row['laws'],'exitCode':p.returncode}),flush=True)
