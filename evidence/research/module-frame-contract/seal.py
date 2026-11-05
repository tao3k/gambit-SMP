from pathlib import Path
import json,hashlib,shutil,collections,datetime,subprocess,re
r=Path.cwd();d=r/'dev';t=r/'.cache/tasks/module-frame-contract';e=r/'evidence/research/module-frame-contract'
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
entry=read(t/'entry.json');f=read(d/'modeling/formal-bindings.json');oldf=read(t/'entry-dev__modeling__formal-bindings.json');old=read(t/'entry-dev__traceability.json');n=f['nativeDescriptors'];sync=read(t/'sync-check.json');refs=read(t/'bindings-final.json');native=read(t/'native-ascent-checks.json');component=read(t/'ascent-checks.json')
assert not sync['drift'] and len(sync['outputBindings'])==72
assert len(f['modelSourceBindings'])==29
assert refs['orgFiles']==334 and refs['fileLinks']==6673
for key in ['duplicateIds','missingFiles','missingCustomIds','missingIncludesOrSetup','frozenSourceChanges','missingMigrationTargets','missingOrganizationDirectories','staleFormalBindings','layoutJsonExists']:assert not refs[key],key
for path,h in sync['outputBindings'].items():assert sha(r/path)==h,path
for path,h in f['modelSourceBindings'].items():assert sha(r/path)==h,path
for key,num in [('fields',6),('consumers',7),('proofDuties',8),('migration',5),('gains',6),('bindingOptions',4),('pipeline',9),('reasoning',1)]:assert len(n[key])==num,key
assert all(v['status']=='open-design-only' for v in n['proofDuties'])
assert n['runtimePathsRetired']==0
assert len(f['sources'])==17 and f['sources']==oldf['sources']
for path,v in f['sources'].items():assert sha(r/path)==v['sha256'],path
for field in ['obligations','relations','copyHandoff','sourceChain','stableViewTransitions','cRefactorRoles']:assert f[field]==oldf[field],field
assert sha(r/'evidence/research/script-view-lifecycle-darwin/checks.json')==entry['bindings']['evidence/research/script-view-lifecycle-darwin/checks.json']
assert read(t/'drift-negative-control.json')['exitCode']==1 and read(t/'drift-restored-control.json')['exitCode']==0
assert read(t/'drift-restored-control.json')['toolSha256']==sha(d/'modeling/tools/sync-views.py')
assert read(t/'source-preservation.json')['allSeventeenFormalSourcesUnchanged']
assert len(read(t/'openssl-digests.json')['models'])==29
assert native['exactAssociationEdges']==307 and native['routeWitnesses']==7 and native['taskRetainedHypotheses']==14
assert component['exactRows']==124 and component['acceptedCurrentAssociationHypotheses']==7
assert native['modelSha256']==sha(r/n['reasoning'][0]['modelSource']) and native['associationBundle']==n['associationBundle']
for row in native['readReceipts']:assert sha(t/('native-read-'+row['route']+'.scm'))==row['rawReadSha256']
for p,h in n['sourceBindings'].items():assert sha(r/p)==h,p
assert sha(t/'native-submit.scm')==native['rawSubmitSha256']
render=read(t/'d2-render.json');assert render['exitCode']==render['previewExitCode']==0
parser=read(r/'.cache/tasks/org-development-architecture/org-parse.json');assert parser['files']==334 and not parser['duplicateIds']
counts=dict(collections.Counter(v['disposition'] for v in f['obligations']));assert counts=={'open':59,'conditional-only':4,'source-slice-established':9,'source-guard-excludes-prior-trace':1}
head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip();assert head==entry['head']
# Existing formal receipts stay historical; no new formal execution is inferred.
historicalFormal=read(r/'evidence/research/script-view-lifecycle-darwin/formal-results.json')
for kind,path in [('quint','models/build/incremental_build.qnt'),('lean','models/build/IncrementalBuild.lean')]:assert historicalFormal[kind]['sourceSha256']==sha(r/path) and historicalFormal[kind]['exitCode']==0
for path,h in read(t/'descriptor-use-census.json')['sourceHashes'].items():assert sha(r/path)==h,path
# Retain task evidence and source snapshots. The structural API export is large;
# its hash is retained in sync-check rather than copying it into maintained docs.
for p in t.iterdir():
 if p.is_file() and p.name!='views.api.json':shutil.copy2(p,e/p.name)
sourceSnapshots={}
for path,h in n['sourceBindings'].items():
 dest=e/'source-snapshot'/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/path,dest);assert sha(dest)==h
 sourceSnapshots[path]={'path':str(dest.relative_to(r)),'sha256':h}
now=datetime.datetime.now(datetime.timezone.utc).isoformat()
execution={'sysmlStrictDiagnostics':True,'structuralExport':True,'orgParse':True,'documentDerivation':True,'driftNegativeAndRestoredControl':True,'d2RenderAndVisualReview':True,'independentOpenSslDigests':True,'ascentHypothesisQueries':True,'newQuintTypecheckOrExploration':False,'newLeanExecution':False,'runtimeImplementation':False,'buildImplementation':False,'contractGeneratorImplementation':False,'abiWitnessCompilation':False,'nativeTesting':False,'performanceValidation':False}
checks={'kind':'modern-c-module-frame-source-to-consumer-contracts','status':'source-and-document-associations-checked-native-refinement-open','recordedAt':now,'repositoryHead':head,'repositoryBranch':entry['branch'],'entryDirtyEntries':entry['dirtyEntries'],'nativeDescriptors':n,'sourceSnapshots':sourceSnapshots,'literature':read(t/'literature.json'),'lexicalUseCensus':read(t/'descriptor-use-census.json'),'derivation':sync,'org':{k:v for k,v in parser.items() if k!='fileLinks'},'references':refs,'sourcePreservation':read(t/'source-preservation.json'),'sysml':{'models':29,'strictDiagnostics':0,'requirementSatisfactionClaimed':False},'ascentComponentAssociations':component,'ascentSourceContractAssociations':native,'formalEvidence':{'existingSourcesUnchanged':17,'historicalBuildLeanTheorems':82,'historicalBuildQuintModulesTypechecked':10,'newFormalExecution':False,'newProofDuties':8,'newProofDutiesClosed':0,'actualEncoderDecoderRefinementProved':False,'actualRootCoverageProved':False,'actualControlAndModuleInitRefinementProved':False,'actualCWeakMemoryRefinementProved':False},'globalProofFrontier':{'obligations':73,'dispositions':counts,'runtimeCompositionallyClosed':0},'retainedFailures':['attempt-1-sync-write.stderr.txt','attempt-2-sync-write.stderr.txt'],'gainBoundary':'Conditional work/storage/runtime-overhead vector; no measured speedup, person-day or GC scan-reduction claim','bindingGenerationDecision':'Scheme-owned declarative contract generator is the design direction; bindgen-like ABI observation is optional and requires production-compiler correspondence; no Rust dependency selected','fullExternalFfiAndBootstrapConsumerClosure':False,'sourceToFrameworkRefinementProved':False,'views':[{'source':'dev/architecture/toolchain/diagrams/native-descriptor.d2','sourceSha256':sha(d/'architecture/toolchain/diagrams/native-descriptor.d2'),'svg':'dev/architecture/toolchain/diagrams/native-descriptor.svg','svgSha256':sha(d/'architecture/toolchain/diagrams/native-descriptor.svg'),'visuallyReviewed':True}],'execution':execution,'nativeProfilesAccepted':0,'runtimePathsRetired':0,'buildPathsRetired':0,'registeredClaimsPromoted':0}
write(e/'checks.json',checks)
trace=dict(old);trace.update({'kind':'development-modern-c-module-frame-contracts','status':checks['status'],'recordedAt':now,'repositoryHead':head,'artifactBindings':{str(p.relative_to(r)):sha(p) for p in sorted(d.rglob('*')) if p.is_file() and p!=d/'traceability.json' and '__pycache__' not in p.parts},'checks':{'path':str((e/'checks.json').relative_to(r)),'sha256':sha(e/'checks.json')},'predecessor':{'snapshot':str((e/'entry-dev__traceability.json').relative_to(r)),'sha256':sha(e/'entry-dev__traceability.json'),'scope':'Earlier checked formal scope, failures and native gates preserved'},'componentModels':dict(old['componentModels'],ascentTaskHypothesesRetained=14,associationBundle=f['componentModels']['associationBundle']),'formalSourcePolicy':dict(old['formalSourcePolicy'],selectedBuildSourcesExtended=0,existingFormalSourcesUnchanged=17,newFormalExecution=False),'nativeDescriptorContracts':{'records':6,'consumerRoutes':7,'openProofDuties':8,'migrationCuts':5,'gainCases':6,'bindingOptions':4,'ascentRouteWitnesses':7,'ascentAssociationEdges':307,'sourceModel':n['reasoning'][0]['modelSource'],'sourceModelSha256':native['modelSha256'],'associationBundle':n['associationBundle'],'sourceToNativeRefinement':'open'},'execution':execution,'nativeProfilesAccepted':0,'runtimePathsRetired':0,'buildPathsRetired':0})
write(d/'traceability.json',trace)
assert all(sha(r/p)==h for p,h in trace['artifactBindings'].items()) and sha(e/'checks.json')==trace['checks']['sha256']
print(json.dumps({'models':29,'orgFiles':334,'fileLinks':6673,'derivedOutputs':72,'ascentExactSourceContractEdges':307,'openNewProofDuties':8,'formalSourcesUnchanged':17,'nativeTesting':False,'receipt':trace['checks']['path']}))
