from pathlib import Path
import subprocess,json,hashlib,shutil
r=Path.cwd();t=r/'.cache/tasks/gsc-recursive-codec-domain';p=r/'dev/architecture/toolchain/diagrams/source-chain.d2'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def record(name,data):(t/name).write_text(json.dumps(data,indent=2)+'\n')
# Document drift control, restoring only our exact temporary delta.
original=p.read_bytes();changed=original+b'# controlled documentation drift\n';p.write_bytes(changed)
try:
 q=subprocess.run([str(r/'.venv/bin/python'),'dev/modeling/tools/sync-views.py','--task','gsc-recursive-codec-domain','--check'],capture_output=True,text=True,timeout=60)
 record('drift-negative-control.json',{'exitCode':q.returncode,'stdout':q.stdout,'stderr':q.stderr,'toolSha256':sha(r/'dev/modeling/tools/sync-views.py'),'originalD2Sha256':hashlib.sha256(original).hexdigest()})
 assert q.returncode==1 and str(p.relative_to(r)) in q.stdout
finally:
 assert p.read_bytes()==changed,'Concurrent edit; do not overwrite'
 p.write_bytes(original)
q=subprocess.run([str(r/'.venv/bin/python'),'dev/modeling/tools/sync-views.py','--task','gsc-recursive-codec-domain','--check'],capture_output=True,text=True,timeout=60)
record('drift-restored-control.json',{'exitCode':q.returncode,'stdout':q.stdout,'stderr':q.stderr,'toolSha256':sha(r/'dev/modeling/tools/sync-views.py'),'restoredD2Sha256':sha(p)});assert q.returncode==0,q.stderr
# OpenSSL command availability is used for digest evidence, not native tests.
rows=[]
for p in sorted((r/'dev').rglob('*.sysml')):
 cmd=['openssl','dgst','-sha256',str(p.relative_to(r))];q=subprocess.run(cmd,capture_output=True,text=True,timeout=10)
 expected=sha(p);actual=q.stdout.strip().rsplit(' ',1)[-1]
 rows.append({'argv':cmd,'exitCode':q.returncode,'pythonSha256':expected,'opensslSha256':actual,'match':expected==actual})
 assert q.returncode==0 and expected==actual
record('openssl-digests.json',{'tool':shutil.which('openssl'),'models':rows,'purpose':'independent digest comparison only','runtimeOrNativeTesting':False})
f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());entry=json.loads((t/'entry-dev__modeling__formal-bindings.json').read_text());changed=[]
for name,v in entry['sources'].items():
 if name.startswith('models/build/'):continue
 if sha(r/name)!=v['sha256']:changed.append(name)
for v in entry['sourceAnchors']:
 if sha(r/v['path'])!=v['sha256']:changed.append(v['path'])
record('source-preservation.json',{'entryFormalSourceCount':len(entry['sources']),'entryAnchorCount':len(entry['sourceAnchors']),'changed':sorted(set(changed)),'inspectedSourceBindings':{v['path']:sha(r/v['path']) for v in f['producerFamilies']},'earlierRuntimeFormalSourcesUnchanged':True,'selectedBuildSpecificationsChanged':True})
assert not changed
# Final strict invocation is retained separately from structural export.
cmd=['sysml','-strict','-no-record-cache','-validate','-json']+sorted(str(p.relative_to(r)) for p in (r/'dev').rglob('*.sysml'))
q=subprocess.run(cmd,capture_output=True,text=True,timeout=60)
(t/'sysml-final.stdout.json').write_text(q.stdout);(t/'sysml-final.stderr.txt').write_text(q.stderr);record('sysml-final-invocation.json',{'argv':cmd,'exitCode':q.returncode})
j=json.loads(q.stdout);assert q.returncode==0 and not j['diagnostics'] and not j['errors']
# Final changed view and retained unchanged contract relation view.
out=[]
for source in ['dev/architecture/toolchain/diagrams/output-fidelity.d2','dev/architecture/toolchain/diagrams/recursive-codec.d2']:
 src=Path(source);name=src.stem;svg=src.with_suffix('.svg');preview=t/(name+'.png')
 q=subprocess.run(['d2',str(src),str(svg)],capture_output=True,text=True,timeout=60)
 (t/(name+'-render.stdout.txt')).write_text(q.stdout);(t/(name+'-render.stderr.txt')).write_text(q.stderr)
 v=subprocess.run(['rsvg-convert','--width','1400',str(svg),'-o',str(preview)],capture_output=True,text=True,timeout=30)
 out.append({'source':str(src),'svg':str(svg),'exit':q.returncode,'previewExit':v.returncode,'preview':str(preview.relative_to(r))})
 assert q.returncode==0 and v.returncode==0
record('d2-render.json',out)
print(json.dumps({'driftControls':'passed','opensslModelDigests':len(rows),'entryFormalAndAnchoredSourcesUnchanged':not changed,'strictDiagnostics':len(j['diagnostics'] or [])}))
