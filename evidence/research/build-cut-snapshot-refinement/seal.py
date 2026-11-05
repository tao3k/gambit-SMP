from pathlib import Path
import collections,datetime,hashlib,json,re,shutil,subprocess
r=Path.cwd();d=r/'dev';t=r/'.cache/tasks/build-cut-snapshot-refinement';e=r/'evidence/research/build-cut-snapshot-refinement'
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
f=read(d/'modeling/formal-bindings.json');entry=read(t/'entry-dev__modeling__formal-bindings.json');original=read(t/'entry.json');old=read(t/'entry-dev__traceability.json')
sync=read(t/'sync-check.json');assert not sync['drift']
for path,h in sync['outputBindings'].items():assert sha(r/path)==h,path
for path,h in f['modelSourceBindings'].items():assert sha(r/path)==h,path
refs=read(t/'bindings-final.json');parser=read(r/'.cache/tasks/org-development-architecture/org-parse.json')
assert refs['orgFiles']==316 and refs['fileLinks']==6101
assert all(not refs[k] for k in ['duplicateIds','missingFiles','missingCustomIds','missingIncludesOrSetup','frozenSourceChanges','missingMigrationTargets','missingOrganizationDirectories','staleFormalBindings','layoutJsonExists'])
for field in ['obligations','relations','copyHandoff']:assert f[field]==entry[field],field
runtime={p:v for p,v in entry['sources'].items() if not p.startswith('models/build/')};assert len(runtime)==15
for p,v in runtime.items():assert f['sources'][p]==v and sha(r/p)==v['sha256'],p
assert len(f['sources'])==17
qnt=(r/'models/build/incremental_build.qnt').read_text();assert qnt.startswith((t/'entry-models__build__incremental_build.qnt').read_text())
assert len(re.findall(r'(?m)^module ',qnt))==3
lean=(r/'models/build/IncrementalBuild.lean').read_text();assert len(re.findall(r'(?m)^theorem ',lean))==15
assert not re.search(r'(?m)^axiom |\bsorry\b',lean)
formal=read(t/'formal-results.json');assert formal==read(e/'formal-results.json')
for method,path in [('quint','models/build/incremental_build.qnt'),('lean','models/build/IncrementalBuild.lean')]:
 row=formal[method];assert row['exitCode']==0 and row['sourceSha256']==sha(r/path)
 for stream in ['stdout','stderr']:assert row[stream+'Sha256']==sha(t/(method+'-check.'+stream+'.txt'))
# Independent literal target-list comparison; no compiler or Make execution.
make=(r/'vendor/gambit/gsc/makefile.in').read_text()
def tokens(name):
 m=re.search(r'(?m)^'+name+r' = ((?:.*\\\n)*.*)',make);assert m,name
 return m.group(1).replace('\\\n',' ').split()
lib=tokens('LIBRARY_MODULES');exe=tokens('EXECUTABLE_MODULES');assert len(lib)==33 and exe==['_gsc']
for variable,stems in [('LIBRARY_MODULES',lib),('EXECUTABLE_MODULES',exe)]:
 for suffix,extension in [('_SCM','.scm'),('_C','.c'),('_O','@obj@')]:assert tokens(variable+suffix)==[p+extension for p in stems],variable+suffix
chain=f['sourceChain'];assert [v['moduleName'] for v in chain['population']]==lib+exe
assert [len(chain[k]) for k in ['nodes','deltas','phases','sources','population','correctness','sourceBindings']]==[10,3,5,14,34,6,64]
assert chain['populationCounts']=={'generation':34,'compilation':34,'composition':6,'sliceActions':74}
for v in chain['sourceBindings']:assert sha(r/v['sourcePath'])==v['sha256'],v['sourcePath']
# Mathematical slice edges used only to verify population/boundary counts.
def deps(n):
 if n<34:return set()
 if n<68:return {n-34}
 if n==68:return set(range(33))
 if n==69:return {68}
 if n==70:return set(range(34,67))|{69}
 if n==71:return {33,68}
 if n==72:return {71}
 return {67,70,72}
injection={0:31,1:1,2:65,3:35,4:68,5:69,6:70,7:71,8:72,9:73};selected=set(injection.values())
assert all(d<n for n in range(74) for d in deps(n))
boundary=sorted((dep,n) for n in selected for dep in deps(n)-selected);assert len(boundary)==64
inventory={'sourceLibraryModules':33,'sourceExecutableModules':1,'realGenerationTargets':34,'compilationActions':34,'compositionActions':6,'sliceActions':74,'selectedProtocolActions':10,'omittedActions':64,'selectedConsumerModuleBoundaryEdges':64,'selectedInjection':injection,'boundaryEdges':boundary,'scope':'source-template and mathematical inventory checks only; not action execution or producer simulation'}
models=f['componentModels'];assert len(models['uses'])==7
for path,h in models['associationInputs'].items():assert sha(r/path)==h,path
ascent=read(t/'ascent-checks.json');assert ascent['exactBundleHash']==models['associationBundle']
assert ascent['correctnessContractRows']==6 and ascent['witnessRows']==1 and ascent['formalReceiptRows']==1
assert ascent['supportObservations']==0 and not ascent['runtimeAdmitted'] and not ascent['executionAuthorized']
assert ascent['rawReadSha256']==sha(t/'ascent-read.scm') and ascent['rawSubmitSha256']==sha(t/'ascent-submit.scm')
neg=read(t/'drift-negative-control.json');pos=read(t/'drift-restored-control.json');assert neg['exitCode']==1 and pos['exitCode']==0
assert neg['toolSha256']==pos['toolSha256']==sha(d/'modeling/tools/sync-views.py')
assert pos['restoredD2Sha256']==sha(d/'architecture/toolchain/diagrams/source-chain.d2')
inv=read(t/'sysml-final-invocation.json');diag=read(t/'sysml-final.stdout.json');assert inv['exitCode']==0 and not diag['errors'] and not diag['diagnostics']
digests=read(t/'openssl-digests.json');assert len(digests['models'])==26
assert all(x['match'] and x['pythonSha256']==sha(r/x['argv'][-1]) for x in digests['models'])
pres=read(t/'source-preservation.json');assert not pres['changed']
views=read(t/'d2-render.json');assert len(views)==1 and all(v['exit']==v['previewExit']==0 for v in views)
# Prior source-bound reports remain byte-identical historical receipts.
for path,h in original['bindings'].items():
 if path.startswith('evidence/'):assert sha(r/path)==h,path
for audit in f['historicalReportAudits']:assert audit['allContextInputsMatch'] and all(x['matches'] for x in audit['reportSources'])
for p in t.iterdir():
 if p.is_file() and p.name!='views.api.json':shutil.copy2(p,e/p.name)
counts=dict(collections.Counter(x['disposition'] for x in f['obligations']))
execution={'orgParsing':True,'strictSysmlDiagnostics':True,'sysmlStructuralApiExport':True,'documentDerivation':True,'documentDriftControl':True,'d2RenderingAndVisualReview':True,'independentOpenSslDigestCheck':True,'quintTypechecking':True,'quintExploration':False,'leanStandaloneKernel':True,'leanScope':'15 conditional theorems; older LeanPoo environment not requalified','ascentHypothesisEvaluation':True,'buildImplementation':False,'runtimeImplementation':False,'gambitCompilation':False,'nativeTesting':False,'performanceValidation':False}
now=datetime.datetime.now(datetime.timezone.utc).isoformat();head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip();assert head==original['head']
frontier=dict(old['proofFrontier']);assert frontier['obligations']==73
checks={'kind':'gsc-dynamic-cut-snapshot-consumer-cutoff-correctness','status':'source-inventory-document-checks-and-conditional-theorems-checked-refinement-open','recordedAt':now,'repositoryHead':head,'entryDirtyEntries':original['dirtyEntries'],'inventory':inventory,'correctnessContracts':chain['correctness'],'canonicalSources':{'toolchain':'dev/architecture/toolchain/models/sysml/architecture.sysml','assurance':'dev/modeling/models/sysml/assurance.sysml'},'sourceAttributionCorrection':read(t/'source-attribution-correction.json'),'formalChecks':formal,'conditionalLeanTheorems':15,'addedConditionalLeanTheorems':7,'qntModules':3,'originalTenNodeQntModuleUnchanged':True,'quintExploration':False,'sourceRefinementProved':False,'qntToLeanSimulationProved':False,'snapshotIssuerProved':False,'consumerFactorizationProved':False,'benefitClass':'conditional avoided-work inventory and accounting only; no measured speedup','derivation':sync,'sysml':{'models':26,'invocation':inv,'diagnostics':diag['diagnostics'],'satisfactionClaimed':False},'org':{k:v for k,v in parser.items() if k!='fileLinks'},'references':refs,'proofFrontier':dict(frontier,dispositions=counts),'formalSourceBindings':f['sources'],'earlierRuntimeFormalSourcesUnchanged':15,'historicalReportAudits':f['historicalReportAudits'],'sourcePreservation':pres,'documentationDriftControls':{'negative':neg,'restored':pos},'ascent':ascent,'views':[dict(v,sourceSha256=sha(r/v['source']),svgSha256=sha(r/v['svg']),visuallyReviewed=True) for v in views],'execution':execution,'retainedFailuresAndCorrections':['quint-check-attempt-1.stderr.txt','formal-attempt-1.json','prior-source-attribution-ascent-submit.scm','prior-source-attribution-ascent-read.scm','source-attribution-correction.json'],'nativeProfilesAccepted':0,'buildPathsRetired':0,'runtimePathsRetired':0,'registeredClaimsPromoted':0}
checks['primaryReferences']=[{'url':'https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf','scope':'scheduler/rebuilder distinction, traces and cutoff; no Gambit theorem'},{'url':'https://www.mathematik.uni-marburg.de/~seba/publications/pluto-incremental-build.pdf','scope':'dynamic builder dependency consistency and well-formedness'},{'url':'https://arxiv.org/abs/2007.12737','scope':'Spall/Mitchell/Tobin-Hochstadt; tracing and hazards, not Darwin snapshot proof'},{'url':'https://github.com/microsoft/BuildXL/blob/main/Documentation/Wiki/Advanced-Features/Filesystem-modes-and-Enumerations.md','scope':'absence/enumeration observations; not admission of a Gambit adapter'}]
write(e/'checks.json',checks)
trace=dict(old);trace.update({'kind':'development-gsc-dynamic-cut-snapshot-correctness','status':checks['status'],'recordedAt':now,'repositoryHead':head,'artifactBindings':{str(p.relative_to(r)):sha(p) for p in sorted(d.rglob('*')) if p.is_file() and p!=d/'traceability.json' and '__pycache__' not in p.parts},'checks':{'path':str((e/'checks.json').relative_to(r)),'sha256':sha(e/'checks.json')},'predecessor':{'snapshot':str((e/'entry-dev__traceability.json').relative_to(r)),'sha256':sha(e/'entry-dev__traceability.json'),'scope':'Earlier receipts preserved; no native gate promoted'},'sourceChain':{'nodes':10,'sourceDeltas':3,'phaseCuts':5,'sourceFacts':14,'realGenerationTargets':34,'fullSliceActions':74,'correctnessSubcontracts':6},'componentModels':{'components':7,'formalSets':1,'existingRuntimeBindings':4,'ascentCurrentHypotheses':7,'ascentTaskHypothesesRetained':14,'exactCorrectnessRows':6,'associationBundle':models['associationBundle']},'formalSourcePolicy':{'uniqueMaintainedRoot':'models/','boundSources':17,'earlierRuntimeSourcesUnchanged':15,'selectedBuildSourcesExtended':2,'newNativeRefinementClaimed':False},'execution':execution,'nativeProfilesAccepted':0,'buildPathsRetired':0,'runtimePathsRetired':0,'registeredClaimsPromoted':0})
write(d/'traceability.json',trace)
assert all(sha(r/p)==h for p,h in trace['artifactBindings'].items());assert sha(e/'checks.json')==trace['checks']['sha256']
print(json.dumps({'orgFiles':refs['orgFiles'],'links':refs['fileLinks'],'models':26,'derivedViews':len(sync['outputBindings']),'generationTargets':34,'sliceActions':74,'correctnessSubcontracts':6,'leanConditionalTheorems':15,'ascentContractRows':6,'runtimeObligationsChanged':False,'nativeTesting':False,'receipt':trace['checks']['path']}))
