"""Identity and scope audit only; does not execute a Gambit/native workload."""
from pathlib import Path
import hashlib,json
ROOT=Path(__file__).resolve().parents[3]
OUT=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text())
i=read(OUT/'input.json');c=read(OUT/'checks.json');scope=read(OUT/'sysml-input-scope.json')
for f,d in i['sourceBindings'].items():assert sha(ROOT/f)==d,f
for f,d in i['logs'].items():assert sha(ROOT/f)==d,f
for f,d in scope['files'].items():assert sha(ROOT/f)==d,f
parent=ROOT/'evidence/research/pin-roster-detachment/input.json'
assert sha(parent)==i['parentInputSha256']
p=read(parent);drift=[]
for f,d in p['sourceBindings'].items():
 q=ROOT/f
 if not q.is_file() or sha(q)!=d:drift.append(dict(path=f,status='changed' if q.is_file() else 'missing'))
a=read(OUT/'ascent-results.json')['results']
assert not a['current']['candidate']
assert len(a['current']['checked'])==4
assert len(a['synthetic-all']['candidate'])==1
assert all(not v['candidate'] for k,v in a.items() if k!='synthetic-all')
assert ['missing-endorsement','semantic'] in a['missing-endorsement']['blocked']
assert ['stale-endorsement-source','semantic'] in a['stale-endorsement-source']['blocked']
assert c['qntHistories']==17 and c['negativeControls']==10
assert c['leanTheorems']==15 and c['astTheorems']==8
assert not c['sourceQualified'] and not c['c11Refinement']
assert not c['nativeTestsRun'] and not c['performanceTestsRun']
archive=OUT/'before-ingress-refinement'
for f,d in read(archive/'identity.json').items():assert sha(archive/f)==d,f
result=dict(status='exact-input-audit-pass',sourceBindings=len(i['sourceBindings']),sysmlInputs=len(scope['files']),parentInputFrozen=True,parentSourceDrift=drift,currentCandidate=False,threeEndorsementsUnqualified=True,formalSourceBridgeQualified=False,runtimeFilesModifiedByStudy=[],nativeTestsRun=False,performanceTestsRun=False,auditorSha256=sha(Path(__file__)))
(OUT/'final-audit.json').write_text(json.dumps(result,indent=2)+'\n')
manifest={str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'}
(OUT/'artifacts.json').write_text(json.dumps(manifest,indent=2)+'\n')
print(json.dumps(result))
