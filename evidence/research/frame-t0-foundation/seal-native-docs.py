from pathlib import Path
import json,hashlib,shutil,datetime,collections
r=Path.cwd();d=r/'dev';t=r/'.cache/tasks/frame-t0-foundation';e=r/'evidence/research/frame-t0-foundation'
def read(p):return json.loads(p.read_text())
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
f=read(d/'modeling/formal-bindings.json');entry=read(t/'entry.json');oldf=read(t/'entry-dev__modeling__formal-bindings.json');old=read(t/'entry-dev__traceability.json');refs=read(t/'bindings-native-final.json');sync=read(t/'sync-write.json');native=read(t/'native-final-validation.json')
assert native['exit']==0 and not native['diagnostics'] and not native['errors']
assert sha(d/'modeling/tools/sync-views.py')==entry['bindings']['dev/modeling/tools/sync-views.py']
assert sha(r/'evidence/research/module-frame-contract/checks.json')==entry['bindings']['evidence/research/module-frame-contract/checks.json']
assert f['sources']==oldf['sources'] and len(f['sources'])==17
assert all(sha(r/p)==v['sha256'] for p,v in f['sources'].items())
assert all(f[k]==oldf[k] for k in ['obligations','relations','sourceChain','copyHandoff','componentModels','nativeDescriptors'])
assert len(f['modelSourceBindings'])==30 and len(sync['outputBindings'])==72
assert all(sha(r/p)==h for p,h in sync['outputBindings'].items())
assert all(sha(r/p)==h for p,h in f['modelSourceBindings'].items())
assert refs['orgFiles']==336 and refs['fileLinks']==6706
assert not any(refs[k] for k in ['duplicateIds','missingFiles','missingCustomIds','missingIncludesOrSetup','frozenSourceChanges','missingMigrationTargets','missingOrganizationDirectories','staleFormalBindings','layoutJsonExists'])
# Historical wire correspondence only; the withdrawn projection is not current.
a=t/'initial-root-only-scope';initial=read(a/'formal-bindings.json')['frameFoundation'];rows=read(a/'expected-ascent-rows.json');manifest=read(a/'read-manifest.json');bundle=initial['associationBundle'];mh=initial['sourceBindings']['dev/architecture/runtime/interfaces/models/sysml/frame-contract.sysml']
def wire(xs):return '('+' '.join(json.dumps(v) for v in xs)+')'
for cohort in manifest:
 body=(a/(cohort['stem']+'.scm')).read_text()
 for law in cohort['laws']:
  claim='frame-foundation:'+law+':'+bundle
  assert body.count(wire([claim,law,mh,bundle]))==1
  for key,kind,value in rows:
   if key==law:assert body.count(wire([claim,law,kind,value]))==1
 for flag in ['runtimeAdmitted','executionAuthorized']:assert '('+json.dumps(flag)+' #f)' in body and '('+json.dumps(flag)+' #t)' not in body
assert len(rows)==332
views=[]
for stem,kind,model,qname in [('t0-foundation','interconnection','dev/architecture/runtime/models/sysml/composition.sysml','GambitRuntimeComposition::T0TargetGraph'),('frame-contract','tree','dev/architecture/runtime/interfaces/models/sysml/frame-contract.sysml','GambitFrameContract::FrameAdmission')]:
 base='dev/refactoring/modern-c/diagrams/' if stem=='t0-foundation' else 'dev/architecture/runtime/interfaces/diagrams/'
 views.append({'qualifiedElement':qname,'renderKind':kind,'model':model,'modelSha256':sha(r/model),'source':base+stem+'.d2','sourceSha256':sha(r/(base+stem+'.d2')),'svg':base+stem+'.svg','svgSha256':sha(r/(base+stem+'.svg')),'producer':'installed sysml -strict -render native element -render-form d2; D2 ELK renders SVG','visuallyReviewed':True,'structureOnly':True})
assert (r/views[0]['source']).read_text().count(' { class: connection }')==9
assert 'frameFoundation' not in f and not (d/'modeling/ascent/frame-foundation.ss').exists()
# Preserve diagnostic failures and withdrawn artifacts as history, never as current admission.
e.mkdir(parents=True,exist_ok=True)
for p in t.iterdir():
 if p.name=='views.api.json':continue
 if p.is_file():shutil.copy2(p,e/p.name)
 elif p.name in ['initial-root-only-scope','withdrawn-python-projection']:shutil.copytree(p,e/p.name,dirs_exist_ok=True)
now=datetime.datetime.now(datetime.timezone.utc).isoformat();execution={'sysmlStructuralValidation':True,'nativeSysmlViews':True,'orgParseAndLinkChecks':True,'d2RenderAndVisualReview':True,'newQuintOrLeanExecution':False,'runtimeImplementation':False,'nativeRuntimeTesting':False,'performanceValidation':False}
checks={'kind':'modern-c-t0-target-refactoring-native-sysml-views','status':'structural-and-document-checks-complete-target-refinement-open','recordedAt':now,'repositoryHead':entry['head'],'repositoryBranch':entry['branch'],'entryDirtyEntries':entry['dirtyEntries'],'nativeSysml':{'binary':'/opt/homebrew/bin/sysml','binarySha256':sha(Path('/opt/homebrew/bin/sysml')),'version':(t/'sysml-version.txt').read_text().strip(),'modelBindings':f['modelSourceBindings'],'modelCount':30,'strictExitCode':0,'requirementSatisfactionClaimed':False},'targetDesign':{'t0Lanes':7,'typedArchitecturalConnections':9,'existingRootBindingIds':['ROOT-HANDOFF','CONTROL-ORIGIN','RETIRE-WINDOW','GC-WORK-CLOSURE'],'newCoordinateLaws':6,'newFrameDuties':10,'newFrameDutiesClosed':0,'classifiedCounterexampleSketches':10,'costCases':6,'newCurrentGcModelCopied':False,'fineGrainedFlAscentAdapter':'open; no current executable projection','globalObligations':dict(collections.Counter(v['disposition'] for v in f['obligations']))},'views':views,'references':refs,'orgParse':{k:v for k,v in read(r/'.cache/tasks/org-development-architecture/org-parse.json').items() if k!='fileLinks'},'existingAdapter':{'entryBytesRestored':True,'maintainedPythonExtensionAdded':False,'legacyOutputCount':72,'outputBindings':sync['outputBindings'],'nativeEquivalentMigration':'open; not silently retired'},'formalSourcesUnchanged':17,'priorComponentAndNativeDescriptorAssociationsUnchanged':True,'historicalWithdrawnAscent':{'exactWireEdges':332,'lawWitnesses':10,'bundle':bundle,'current':False,'reason':'custom Python projection withdrawn after user required native tool ownership; later canonical models changed','runtimeAdmitted':False,'executionAuthorized':False},'retainedFailures':['initial-root-only-scope/document-checks.stderr.txt','native-values.json'],'sourceToNativeRefinementProved':False,'runtimePathsRetired':0,'nativeProfilesAccepted':0,'execution':execution}
write(e/'checks.json',checks)
trace=dict(old);trace.update({'kind':'development-modern-c-t0-native-sysml-refactoring','status':checks['status'],'recordedAt':now,'artifactBindings':{str(p.relative_to(r)):sha(p) for p in sorted(d.rglob('*')) if p.is_file() and p!=d/'traceability.json' and '__pycache__' not in p.parts},'checks':{'path':str((e/'checks.json').relative_to(r)),'sha256':sha(e/'checks.json')},'predecessor':{'snapshot':str((e/'entry-dev__traceability.json').relative_to(r)),'sha256':sha(e/'entry-dev__traceability.json'),'scope':'Prior scoped formal and native gates preserved'},'t0TargetRefactoring':checks['targetDesign'],'nativeSysmlViews':views,'toolBoundary':checks['existingAdapter'],'execution':execution})
write(d/'traceability.json',trace)
assert all(sha(r/p)==h for p,h in trace['artifactBindings'].items())
print(json.dumps({'sysmlModels':30,'orgFiles':336,'fileLinks':6706,'nativeD2Views':2,'newMaintainedPythonExtension':False,'rootFormalSourcesUnchanged':17,'openFrameDuties':10,'newRuntimeOrNativeTesting':False,'receipt':trace['checks']['path']}))
