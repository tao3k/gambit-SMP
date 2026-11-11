from pathlib import Path
import subprocess,json
r=Path.cwd();t=r/'.cache/tasks/module-frame-contract'
def run(args,request,stem):
 p=subprocess.run(args,input=request.read_text(),text=True,capture_output=True,timeout=60)
 (t/(stem+'.scm')).write_text(p.stdout);(t/(stem+'.stderr.txt')).write_text(p.stderr)
 (t/(stem+'.invocation.json')).write_text(json.dumps({'argv':args,'exitCode':p.returncode,'request':str(request.relative_to(r))},indent=2)+'\n')
 assert p.returncode==0,(stem,p.stderr)
 print(json.dumps({'completed':stem,'exitCode':p.returncode}),flush=True)
base=[str(r/'.venv/bin/gambit-smp'),'--task','module-frame-contract','trajectory']
run(base+['clues'],t/'ascent-read.request.scm','ascent-read')
p=subprocess.run(['python3',str(t/'check-ascent-wire.py')],capture_output=True,text=True);(t/'component-wire.stdout.txt').write_text(p.stdout);(t/'component-wire.stderr.txt').write_text(p.stderr);assert p.returncode==0,p.stderr
run(base+['submit'],r/'dev/modeling/ascent/native-descriptor.request.scm','native-submit')
for row in json.loads((t/'native-read-manifest.json').read_text()):run(base+['clues'],t/row['request'],'native-read-'+row['route'])
print('All source-to-contract association queries completed',flush=True)
