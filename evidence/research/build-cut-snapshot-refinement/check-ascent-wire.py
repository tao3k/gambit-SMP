from pathlib import Path
import json,hashlib,re
r=Path.cwd();t=r/'.cache/tasks/build-cut-snapshot-refinement';f=json.loads((r/'dev/modeling/formal-bindings.json').read_text());text=(t/'ascent-read.scm').read_text();submit=(t/'ascent-submit.scm').read_text()
# Exact known wire-relation assertions only; the existing Scheme/ASCENT owner
# performed evaluation. No Python Datalog evaluator or alternate Scheme API.
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def row(values):return '('+' '.join(json.dumps(x) for x in values)+')'
bundle=f['componentModels']['associationBundle'];modelHash=sha(r/'dev/modeling/models/sysml/assurance.sysml');claim='component-model:build-planner:'+bundle
witness=[claim,'build-planner','models/build/incremental_build.qnt','models/build/IncrementalBuild.lean',modelHash,bundle]
assert text.count(row(witness))==1
for c in f['sourceChain']['correctness']:
 assert text.count(row([claim,c['contractId'],c['contractId']+':'+c['status'],c['contractId']+':'+c['openPremise']]))==1,c['contractId']
report='evidence/research/build-cut-snapshot-refinement/formal-results.json'
assert text.count(row([claim,report,sha(r/report)]))==1
assert re.search(r'\("counts"\s+\(\("counter"\s+0\)\s+\("hypotheses"\s+1\)\s+\("support"\s+0\)\)\)',text)
for flag in ['runtimeAdmitted','executionAuthorized']:
 assert '('+json.dumps(flag)+' #f)' in text
 assert '('+json.dumps(flag)+' #t)' not in text
assert all(json.dumps(v['componentId']+':'+bundle) in submit for v in f['componentModels']['uses'])
assert '("submissions" 2)' in submit
result={'acceptedCurrentAssociationHypotheses':7,'taskTotalSubmissions':2,'taskRetainedHypotheses':14,'earlierSourceAttributionBundleRetainedUnqualified':True,'selectedComponent':'build-planner','exactCanonicalHash':modelHash,'exactBundleHash':bundle,'witnessRows':1,'correctnessContractRows':6,'formalReceiptRows':1,'supportObservations':0,'runtimeAdmitted':False,'executionAuthorized':False,'wireAssertionsNotNewInference':True,'rawReadSha256':sha(t/'ascent-read.scm'),'rawSubmitSha256':sha(t/'ascent-submit.scm')}
(t/'ascent-checks.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result))
