from pathlib import Path
import json,hashlib,re
r=Path.cwd();t=r/'.cache/tasks/module-frame-contract';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text())['nativeDescriptors'];expected=json.loads((t/'expected-native-rows.json').read_text());manifest=json.loads((t/'native-read-manifest.json').read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def row(xs):return '('+' '.join(json.dumps(x) for x in xs)+')'
bundle=f['associationBundle'];model=f['reasoning'][0]['modelSource'];h=sha(r/model);submit=(t/'native-submit.scm').read_text()
assert '("submissions" 2)' in submit and '("retainedClues" 14)' in submit
for v in f['consumers']:assert json.dumps(v['routeId']+':'+bundle) in submit
readReceipts=[]
for item in manifest:
 route=item['route'];p=t/('native-read-'+route+'.scm');text=p.read_text();claim='native-descriptor:'+route+':'+bundle
 assert text.count(row([claim,route,h,bundle]))==1
 rows=[v for v in expected if v[0]==route];assert len(rows)==item['expectedRows']
 for _,kind,value in rows:assert text.count(row([claim,route,kind,value]))==1,(route,kind,value)
 assert re.search(r'\("counts"\s+\(\("counter"\s+0\)\s+\("hypotheses"\s+1\)\s+\("support"\s+0\)\)\)',text)
 for key in ['runtimeAdmitted','executionAuthorized']:
  assert '('+json.dumps(key)+' #f)' in text and '('+json.dumps(key)+' #t)' not in text
 readReceipts.append({'route':route,'expectedAndReturnedEdges':len(rows),'rawReadSha256':sha(p),'requestSha256':sha(t/item['request']),'invocation':json.loads((t/('native-read-'+route+'.invocation.json')).read_text())})
assert len(expected)==307 and len(readReceipts)==7
result={'acceptedRouteHypotheses':7,'taskRetainedHypotheses':14,'successfulTaskSubmissions':2,'modelSource':model,'modelSha256':h,'associationBundle':bundle,'routeWitnesses':7,'exactAssociationEdges':len(expected),'readReceipts':readReceipts,'rawSubmitSha256':sha(t/'native-submit.scm'),'sourceUseAndDutyIdentitiesPreserved':True,'proofDutiesClosed':0,'supportObservations':0,'runtimeAdmitted':False,'executionAuthorized':False,'parserLimitsRaised':False,'nativeImplementationOrTesting':False}
(t/'native-ascent-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({k:v for k,v in result.items() if k!='readReceipts'}))
