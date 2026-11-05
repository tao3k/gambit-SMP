from pathlib import Path
import json,hashlib,re
r=Path.cwd();t=r/'.cache/tasks/script-view-lifecycle-darwin';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());text=(t/'ascent-read.scm').read_text();submit=(t/'ascent-submit.scm').read_text()
# Assert exact returned wire rows; Scheme/ASCENT performed the inference.
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def row(values):return '('+' '.join(json.dumps(x) for x in values)+')'
bundle=f['componentModels']['associationBundle'];modelHash=sha(r/'dev/modeling/models/sysml/assurance.sysml');claim='component-model:build-planner:'+bundle
assert text.count(row([claim,'build-planner','models/build/incremental_build.qnt','models/build/IncrementalBuild.lean',modelHash,bundle]))==1
expected=json.loads((t/'expected-ascent-rows.json').read_text());assert len(expected)==124
for kind,idFactor,valueFactor,identity,premise in expected:assert text.count(row([claim,kind,identity,premise]))==1,identity
report=f['componentModels']['formalSets'][0]['evidenceReport'];assert text.count(row([claim,report,sha(r/report)]))==1
assert re.search(r'\("counts"\s+\(\("counter"\s+0\)\s+\("hypotheses"\s+1\)\s+\("support"\s+0\)\)\)',text)
for flag in ['runtimeAdmitted','executionAuthorized']:
 assert '('+json.dumps(flag)+' #f)' in text
 assert '('+json.dumps(flag)+' #t)' not in text
assert all(json.dumps(v['componentId']+':'+bundle) in submit for v in f['componentModels']['uses'])
assert '("submissions" 3)' in submit and '("retainedClues" 21)' in submit
result={'acceptedCurrentAssociationHypotheses':7,'successfulTaskSubmissions':3,'taskRetainedHypotheses':21,'earlierConditionalScopeRetained':True,'selectedComponent':'build-planner','exactCanonicalHash':modelHash,'exactBundleHash':bundle,'witnessRows':1,'fidelityRows':52,'runtimeContractRows':7,'statusRows':23,'capabilityRows':42,'exactRows':124,'formalReceiptRows':1,'supportObservations':0,'runtimeAdmitted':False,'executionAuthorized':False,'wireAssertionsNotNewInference':True,'rawReadSha256':sha(t/'ascent-read.scm'),'rawSubmitSha256':sha(t/'ascent-submit.scm'),'sharedFactorSelectorBytes':len((r/'dev/modeling/ascent/component-models.ss').read_bytes())}
(t/'ascent-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
