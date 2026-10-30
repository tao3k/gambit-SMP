from pathlib import Path
import subprocess,json,hashlib
r=Path.cwd();t=r/'.cache/tasks/module-frame-contract'
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def record(name,x):(t/name).write_text(json.dumps(x,indent=2)+'\n')
p=r/'dev/architecture/toolchain/diagrams/native-descriptor.d2';original=p.read_bytes();changed=original+b'# controlled native descriptor drift\n';p.write_bytes(changed)
try:
 q=subprocess.run([str(r/'.venv/bin/python'),'dev/modeling/tools/sync-views.py','--task','module-frame-contract','--check'],capture_output=True,text=True,timeout=60)
 record('drift-negative-control.json',{'exitCode':q.returncode,'stdout':q.stdout,'stderr':q.stderr,'toolSha256':sha(r/'dev/modeling/tools/sync-views.py'),'originalSha256':hashlib.sha256(original).hexdigest()})
 assert q.returncode==1 and str(p.relative_to(r)) in q.stdout
finally:
 assert p.read_bytes()==changed,'Concurrent edit; do not overwrite'
 p.write_bytes(original)
q=subprocess.run([str(r/'.venv/bin/python'),'dev/modeling/tools/sync-views.py','--task','module-frame-contract','--check'],capture_output=True,text=True,timeout=60)
record('drift-restored-control.json',{'exitCode':q.returncode,'stdout':q.stdout,'stderr':q.stderr,'toolSha256':sha(r/'dev/modeling/tools/sync-views.py'),'restoredSha256':sha(p)});assert q.returncode==0,q.stderr
f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());entry=json.loads((t/'entry-dev__modeling__formal-bindings.json').read_text())
assert len(f['sources'])==len(entry['sources'])==17
for name,v in entry['sources'].items():assert f['sources'][name]==v and sha(r/name)==v['sha256'],name
for v in entry['sourceAnchors']:assert sha(r/v['path'])==v['sha256'],v['path']
assert f['relations']==entry['relations'] and f['obligations']==entry['obligations']
for v in entry['sourceChain']['sourceBindings']:assert sha(r/v['sourcePath'])==v['sha256'],v['sourcePath']
for path,h in f['nativeDescriptors']['sourceBindings'].items():assert sha(r/path)==h,path
record('source-preservation.json',{'allSeventeenFormalSourcesUnchanged':True,'existingRuntimeContractsAndObligationsUnchanged':True,'allEntryAnchorsAndChainSourcesUnchanged':True,'newDescriptorSourceBindings':f['nativeDescriptors']['sourceBindings'],'newFormalExecution':False,'nativeTesting':False})
rows=[]
for p in sorted((r/'dev').rglob('*.sysml')):
 q=subprocess.run(['openssl','dgst','-sha256',str(p.relative_to(r))],capture_output=True,text=True,timeout=10);actual=q.stdout.strip().rsplit(' ',1)[-1]
 rows.append({'path':str(p.relative_to(r)),'exitCode':q.returncode,'opensslSha256':actual,'pythonSha256':sha(p)});assert q.returncode==0 and actual==sha(p)
record('openssl-digests.json',{'models':rows,'purpose':'independent digest comparison, no native validation'})
# sync --check already runs strict diagnostics and structural export together.
j=json.loads((t/'view-diagnostics.stdout.json').read_text());assert not j.get('errors') and not j.get('diagnostics')
print(json.dumps({'negativeControl':1,'restoredControl':0,'strictDiagnostics':0,'sysmlModels':len(rows),'formalSourcesUnchanged':17,'nativeTesting':False}))
