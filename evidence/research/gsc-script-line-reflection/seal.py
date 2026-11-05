from pathlib import Path
import collections,datetime,hashlib,json,re,shutil,subprocess
r=Path.cwd();d=r/'dev';t=r/'.cache/tasks/gsc-script-line-reflection';e=r/'evidence/research/gsc-script-line-reflection'
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
f=read(d/'modeling/formal-bindings.json');entry=read(t/'entry-dev__modeling__formal-bindings.json');original=read(t/'entry.json');old=read(t/'entry-dev__traceability.json')
sync=read(t/'sync-check.json');assert not sync['drift'] and len(sync['outputBindings'])==64
for path,h in sync['outputBindings'].items():assert sha(r/path)==h,path
for path,h in f['modelSourceBindings'].items():assert sha(r/path)==h,path
refs=read(t/'bindings-final.json');parser=read(r/'.cache/tasks/org-development-architecture/org-parse.json')
assert refs['orgFiles']==328 and refs['fileLinks']>6181
assert all(not refs[k] for k in ['duplicateIds','missingFiles','missingCustomIds','missingIncludesOrSetup','frozenSourceChanges','missingMigrationTargets','missingOrganizationDirectories','staleFormalBindings','layoutJsonExists'])
for field in ['obligations','relations','copyHandoff']:assert f[field]==entry[field],field
runtime={p:v for p,v in entry['sources'].items() if not p.startswith('models/build/')};assert len(runtime)==15
for p,v in runtime.items():assert f['sources'][p]==v and sha(r/p)==v['sha256'],p
assert len(f['sources'])==17
qnt=(r/'models/build/incremental_build.qnt').read_text();before=(t/'entry-models__build__incremental_build.qnt').read_text()
assert qnt.startswith(before)
assert len(re.findall(r'(?m)^module ',qnt))==8
lean=(r/'models/build/IncrementalBuild.lean').read_text();assert len(re.findall(r'(?m)^theorem ',lean))==68
assert lean.startswith((t/'entry-models__build__IncrementalBuild.lean').read_text().rsplit('end GambitBuild',1)[0])
assert not re.search(r'(?m)^axiom |\bsorry\b|\bnative_decide\b',lean)
formal=read(t/'formal-results.json');assert formal==read(e/'formal-results.json')
for method,path in [('quint','models/build/incremental_build.qnt'),('lean','models/build/IncrementalBuild.lean')]:
 row=formal[method];assert row['exitCode']==0 and row['sourceSha256']==sha(r/path)
 for stream in ['stdout','stderr']:
  log=row.get(stream+'Path',method+'-check.'+stream+'.txt');assert row[stream+'Sha256']==sha(t/log)
assert read(t/'formal-attempt-1.json')['lean']['exitCode']==1
chain=f['sourceChain'];assert [len(chain[k]) for k in ['nodes','deltas','phases','sources','population','correctness','readBoundaries','issueConditions','refinementSteps','capabilityGates','outputObservations','fidelityObligations','sourceBindings']]==[10,3,5,14,34,6,13,8,8,14,5,39,151]
for v in chain['sourceBindings']:assert sha(r/v['sourcePath'])==v['sha256'],v['sourcePath']
# Literal target correspondence, independently of the maintained view extractor.
make=(r/'vendor/gambit/gsc/makefile.in').read_text()
def tokens(name):
 m=re.search(r'(?m)^'+name+r' = ((?:.*\\\n)*.*)',make);assert m,name
 return m.group(1).replace('\\\n',' ').split()
lib=tokens('LIBRARY_MODULES');exe=tokens('EXECUTABLE_MODULES');assert len(lib)==33 and exe==['_gsc']
for variable,stems in [('LIBRARY_MODULES',lib),('EXECUTABLE_MODULES',exe)]:
 for suffix,extension in [('_SCM','.scm'),('_C','.c'),('_O','@obj@')]:assert tokens(variable+suffix)==[p+extension for p in stems],variable+suffix
assert [v['moduleName'] for v in chain['population']]==lib+exe
assert {v['fidelityId']:v['runtimeContractRefs'] for v in chain['fidelityObligations'] if v.get('runtimeContractRefs')}=={'V-ROOTS':'ROOT-HANDOFF','V-RELOC':'ROOT-HANDOFF','V-ADMIT':'ROOT-HANDOFF','S-CUT':'ROOT-HANDOFF'}
models=f['componentModels'];assert len(models['uses'])==7 and len(models['formalSets'])==1
for path,h in models['associationInputs'].items():assert sha(r/path)==h,path
ascent=read(t/'ascent-checks.json');assert ascent['exactBundleHash']==models['associationBundle']
assert ascent['fidelityRows']==39 and ascent['runtimeContractRows']==4 and ascent['statusRows']==10 and ascent['exactRows']==53
assert ascent['supportObservations']==0 and not ascent['runtimeAdmitted'] and not ascent['executionAuthorized']
assert ascent['rawReadSha256']==sha(t/'ascent-read.scm') and ascent['rawSubmitSha256']==sha(t/'ascent-submit.scm')
assert ascent['sharedFactorSelectorBytes']==len((d/'modeling/ascent/component-models.ss').read_bytes())<65536
neg=read(t/'drift-negative-control.json');pos=read(t/'drift-restored-control.json');assert neg['exitCode']==1 and pos['exitCode']==0
assert neg['toolSha256']==pos['toolSha256']==sha(d/'modeling/tools/sync-views.py')
assert pos['restoredD2Sha256']==sha(d/'architecture/toolchain/diagrams/source-chain.d2')
inv=read(t/'sysml-final-invocation.json');diag=read(t/'sysml-final.stdout.json');assert inv['exitCode']==0 and not diag['errors'] and not diag['diagnostics']
digests=read(t/'openssl-digests.json');assert len(digests['models'])==26
assert all(x['match'] and x['pythonSha256']==sha(r/x['argv'][-1]) for x in digests['models'])
pres=read(t/'source-preservation.json');assert not pres['changed']
views=read(t/'d2-render.json');assert len(views)==2 and all(v['exit']==v['previewExit']==0 for v in views)
for path,h in original['bindings'].items():
 if path.startswith('evidence/'):assert sha(r/path)==h,path
for audit in f['historicalReportAudits']:assert audit['allContextInputsMatch'] and all(x['matches'] for x in audit['reportSources'])
for path,h in read(t/'writer-census.json')['sourceHashes'].items():assert sha(r/path)==h,path
# Immutable evidence copies; these are not additional maintained model roots.
for p in t.iterdir():
 if p.is_file() and not p.name.endswith('views.api.json'):shutil.copy2(p,e/p.name)
source_snapshot={}
for path in sorted({v['sourcePath'] for v in chain['fidelityObligations']} | {'vendor/gambit/gsc/_gsclib.scm','vendor/gambit/gsi/main.scm','vendor/gambit/lib/_io.scm','vendor/gambit/gsc/_gambitgsc.c','vendor/gambit/gsc/_gsc_.c','vendor/gambit/lib/_module.scm','vendor/gambit/include/gambit.h.in','dev/architecture/runtime/interfaces/models/sysml/model-relations.sysml','vendor/gambit/lib/_io#.scm','vendor/gambit/lib/_eval#.scm','vendor/gambit/lib/_define-library/define-library-expand.scm','vendor/gambit/lib/gambit/string/string.scm'} | set(read(t/'writer-census.json')['sourceHashes'])):
 src=r/path;dest=e/'source-snapshot'/path;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dest)
 source_snapshot[path]={'path':str(dest.relative_to(r)),'sha256':sha(dest)};assert sha(src)==sha(dest)
for path in ['models/build/incremental_build.qnt','models/build/IncrementalBuild.lean']:
 dest=e/'formal-source-snapshot'/Path(path).name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(r/path,dest)
counts=dict(collections.Counter(x['disposition'] for x in f['obligations']))
assert counts=={'open':59,'conditional-only':4,'source-slice-established':9,'source-guard-excludes-prior-trace':1}
execution={'orgParsing':True,'strictSysmlDiagnostics':True,'sysmlStructuralApiExport':True,'documentDerivation':True,'documentDriftControl':True,'d2RenderingAndVisualReview':True,'independentOpenSslDigestCheck':True,'quintTypechecking':True,'quintExploration':False,'leanStandaloneKernel':True,'leanScope':'68 statements; source-aligned script selection, finite counterexamples and conditional full-observation reflection; actual textual readback, writer closure and trace refinement open','ascentHypothesisEvaluation':True,'buildImplementation':False,'runtimeImplementation':False,'gambitCompilation':False,'nativeTesting':False,'performanceValidation':False}
now=datetime.datetime.now(datetime.timezone.utc).isoformat();head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip();assert head==original['head']
frontier=dict(old['proofFrontier']);assert frontier['obligations']==73
checks={'kind':'gsc-script-line-capture-and-complete-linker-observation','status':'source-slice-document-checks-and-bounded-theory-checked-concrete-refinement-open','recordedAt':now,'repositoryHead':head,'repositoryBranch':original['branch'],'entryDirtyEntries':original['dirtyEntries'],'inventory':{'generationTargets':34,'moduleCompilationActions':34,'compositionActions':6,'sliceActions':74,'selectedProtocolActions':10,'omittedActions':64,'incomingOmittedModuleEdges':64,'scope':'template/source population only; no measured execution'},'fidelityObligations':chain['fidelityObligations'],'capabilityGates':chain['capabilityGates'],'outputObservations':chain['outputObservations'],'readBoundaries':chain['readBoundaries'],'snapshotIssueConditions':chain['issueConditions'],'refinementSteps':chain['refinementSteps'],'sourceSnapshots':source_snapshot,'formalChecks':formal,'toolIdentities':read(t/'tool-identities.json'),'standaloneLeanTheorems':68,'addedTheorems':12,'newTheorems':['scriptFalseRetainsPrevious','scriptEmptyTextWins','scriptFoldAppend','scriptTrailingFalseRetains','scriptFirstMatchWins','malformedLatestRemainsVisible','singletonScriptEncodingReflects','untouchedPayloadPreservesView','sameReturnedPathCanChangeDiagnostics','abortCanRetainPartialWrite','scriptFullObservationCongruence','scriptPropertyReflection'],'concreteReflectionTheorem':'concreteSafetyFromRefinement requires a separately proved property reflection','originalTenNodeModuleUnchanged':True,'previousFiftySixTheoremsUnchanged':True,'previousSevenQntModulesUnchanged':True,'quintModulesTypechecked':8,'logicalSchemeAdmissionSpecified':True,'actualRootScannerQualified':False,'actualInternerIdentityRefinementProved':False,'intervalStabilityFromEndpointsClaimed':False,'runtimeContractReferences':{'ROOT-HANDOFF':['V-ROOTS','V-RELOC','V-ADMIT','S-CUT']},'mathematicalWireRoundtripAndInjectionProved':True,'actualSchemeDomainBridgeProved':False,'actualWriterReaderLawProved':False,'formatTokenCount':'2*N+U mathematical integers','formatCountLeanProved':False,'nativeWorkBoundProved':False,'actualMacroCallbackAndNativeClosureProved':False,'configuredNativeProviderQualified':False,'parserEncodingFidelityProved':False,'quintExploration':False,'sourceReadClosureProved':False,'realBootProducerQualified':False,'snapshotIssuerProved':False,'actualCompilerOracleAdequacyProved':False,'actualGscStepSimulationProved':False,'concreteSafetyReflectionInstantiated':False,'wholeMacroWorkCountTransferProved':False,'actualCleanBuildPerformed':False,'recursiveSchemeCodecImplemented':False,'realConsumerFactorizationProved':False,'concreteFailureMapProved':False,'sharedMacroBoundary':'Old input credentials invalidate; consumed output observations may be equal after full revalidation; omitted work remains charged','benefitClass':'conditional recipe-work avoidance and explicit support accounting; no timings or speedup','derivation':sync,'sysml':{'models':26,'invocation':inv,'diagnostics':diag['diagnostics'],'satisfactionClaimed':False},'org':{k:v for k,v in parser.items() if k!='fileLinks'},'references':refs,'proofFrontier':dict(frontier,dispositions=counts),'formalSourceBindings':f['sources'],'earlierRuntimeFormalSourcesUnchanged':15,'historicalReportAudits':f['historicalReportAudits'],'sourcePreservation':pres,'documentationDriftControls':{'negative':neg,'restored':pos},'ascent':ascent,'ascentSharedIdentityProjection':{'canonicalSourceAndBundleStoredOnce':True,'existingPublicFactorNamesRetained':True,'parserLimitsRaised':False},'views':[dict(v,sourceSha256=sha(r/v['source']),svgSha256=sha(r/v['svg']),visuallyReviewed=True) for v in views],'execution':execution,'retainedFailuresAndScopeHistory':{'previousReportsUnchanged':True,'currentLeanFirstAttemptFailed':True,'firstQuintExitRecorded':True,'capturedFinalFormalExitsPassed':True,'retainedCurrentFailures':['lean-attempt-1-source.txt','lean-attempt-1.stdout.txt','formal-attempt-1.json','quint-attempt-1-source.txt','quint-attempt-1.stderr.txt'],'historicalModelLimitationsRemainOpen':True},'nativeProfilesAccepted':0,'buildPathsRetired':0,'runtimePathsRetired':0,'registeredClaimsPromoted':0}
checks['primaryReferences']=[
 {'url':'https://small.r7rs.org/attachment/r7rs.pdf','scope':'Datum read/write, sharing and textual port distinction; not complete Gambit extensions'},
 {'url':'https://simon.peytonjones.org/assets/pdfs/build-systems-jfp.pdf','scope':'Explicit task input assumptions and rebuilding; not a Gambit effect equivalence proof'},
 {'url':'https://www.mathematik.uni-marburg.de/~seba/publications/pluto-incremental-build.pdf','scope':'Consistency of dynamically required/produced resources; not actual Gambit trace refinement'}]
checks.update({'scriptLineWriterCensus':read(t/'writer-census.json'),'researchStatuses':{v['fidelityId']:v['researchStatus'] for v in chain['fidelityObligations'] if v.get('researchStatus')},'actualWriterCapabilityClosureProved':False,'actualStableViewIssuerProved':False,'actualTextualRoundtripProved':False,'actualLinkerTraceRefinementProved':False,'scriptSelectionSourceAlignedSpecified':True,'effectBoundary':'Full declared semantic observation; physical I/O cannot be erased without an independent boundary/delivery proof','positiveNetWorkCondition':'A > V + S + R + E + F; no timing constants or native speedup established'})

for failure in checks['retainedFailuresAndScopeHistory']['retainedCurrentFailures']:
 assert (e/failure).is_file(),failure
write(e/'checks.json',checks)
trace=dict(old);trace.update({'kind':'development-gsc-script-line-observation','status':checks['status'],'recordedAt':now,'repositoryHead':head,'artifactBindings':{str(p.relative_to(r)):sha(p) for p in sorted(d.rglob('*')) if p.is_file() and p!=d/'traceability.json' and '__pycache__' not in p.parts},'checks':{'path':str((e/'checks.json').relative_to(r)),'sha256':sha(e/'checks.json')},'predecessor':{'snapshot':str((e/'entry-dev__traceability.json').relative_to(r)),'sha256':sha(e/'entry-dev__traceability.json'),'scope':'Earlier source-bound reports and all native gates preserved'},'sourceChain':{'nodes':10,'realGenerationTargets':34,'fullSliceActions':74,'sourceFacts':14,'correctnessSubcontracts':6,'readBoundaries':13,'snapshotIssueConditions':8,'refinementSteps':8,'capabilityGates':14,'outputObservations':5,'fidelityObligations':39},'componentModels':{'components':7,'formalSets':1,'existingRuntimeBindings':4,'ascentCurrentHypotheses':7,'ascentTaskHypothesesRetained':ascent['taskRetainedHypotheses'],'exactFidelityRows':39,'runtimeContractRows':4,'statusRows':10,'ascentExactRows':53,'associationBundle':models['associationBundle']},'formalSourcePolicy':{'uniqueMaintainedRoot':'models/','boundSources':17,'earlierRuntimeSourcesUnchanged':15,'selectedBuildSourcesExtended':2,'standaloneTheorems':68,'actualSourceRefinementClaimed':False},'execution':execution,'nativeProfilesAccepted':0,'buildPathsRetired':0,'runtimePathsRetired':0,'registeredClaimsPromoted':0})
write(d/'traceability.json',trace)
assert all(sha(r/p)==h for p,h in trace['artifactBindings'].items());assert sha(e/'checks.json')==trace['checks']['sha256']
print(json.dumps({'orgFiles':refs['orgFiles'],'links':refs['fileLinks'],'models':26,'derivedViews':len(sync['outputBindings']),'readBoundaries':13,'issueConditions':8,'refinementSteps':8,'leanTheorems':68,'ascentExactRows':53,'actualGscRefinementProved':False,'nativeTesting':False,'receipt':trace['checks']['path']}))
