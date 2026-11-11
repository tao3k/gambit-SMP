#!/usr/bin/env python3
"""Source-bound C23 admission/refusal research. No runtime/native compiler or tests."""
import copy,hashlib,importlib.util,json,re,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TASK='sfun-admission-refusal';BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks'/TASK;OUT=ROOT/'evidence/research'/TASK
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def rel(p):return str(Path(p).relative_to(ROOT))
def loadmod(name,path):
 s=importlib.util.spec_from_file_location(name,path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
helper=loadmod('guard_study_process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');helper.CACHE=CACHE
run=helper.run

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitSfunAdmissionRefusal::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs.split()]
 cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 model=BASE/'models/sysml'/f'{TASK}.sysml';startModel=sha(model);raw=json.loads(run('sysml',cmd+[str(model)]))
 assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 values=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(values)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,values,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 sources=[];bindings={}
 for row in p['source']:
  file=ROOT/row['path'];text=file.read_text();assert row['needle'] in text
  sources.append(dict(**row,sha256=sha(file),lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]));bindings[row['path']]=sha(file)
 save(CACHE/'source-witnesses.json',sources)
 parent=ROOT/'evidence/research/size-family-guard-gc/input.json';parentDigest=sha(parent);pdata=json.loads(parent.read_text())
 parentFiles=['dev/refactoring/modern-c/models/lean/SizeGuardAst.lean','dev/refactoring/modern-c/models/quint/size_family_guard_gc.qnt','dev/modeling/tools/size-family-guard-gc-projection.py']
 for path in parentFiles:assert pdata['sourceBindings'][path]==sha(ROOT/path);bindings[path]=sha(ROOT/path)
 drift=[dict(path=k,previous=v,current=sha(ROOT/k)) for k,v in pdata['sourceBindings'].items() if sha(ROOT/k)!=v]
 save(CACHE/'parent-currentness.json',dict(inputSha256=parentDigest,formalParentsUnchanged=True,drift=drift,parentNativeEvidenceReused=False))
 paperBase=ROOT/'evidence/research/sfun-converter-use-closure';paper=json.loads((paperBase/'primary-paper.json').read_text())
 for name,digest in paper['files'].items():assert sha(paperBase/name)==digest;bindings[rel(paperBase/name)]=digest
 callText=(ROOT/'vendor/gambit/lib/setup.c').read_text();start=callText.index('___EXP_FUNC(___SCMOBJ,___call)');end=callText.index('___EXP_FUNC(___SCMOBJ,___run)',start);body=callText[start:end]
 returns=[line.strip() for line in body.splitlines() if line.lstrip().startswith('return ')];assert returns==['return ___FIX(___UNKNOWN_ERR);','return ___FIX(___NO_ERR);']
 macros=(ROOT/'vendor/gambit/include/_gambit/foreign_conversion.h.in').read_text();loops=[]
 for shape in ['VOID','SCMOBJ','TYPED']:
  suffix='_'+shape if shape!='TYPED' else ''
  lines=[line for line in macros.splitlines() if line.startswith('#define ___SFUN_ERROR'+suffix+' ')];assert len(lines)==1
  line=lines[0];assert '___NO_ERR' in line and '___UNWIND_C_STACK' in line and '___UNKNOWN_ERR' not in line and '___EXT(___call)' in line
  loops.append(dict(shape=shape,line=line,gateCodeClassified=False))
 save(CACHE/'operation-inventory.json',dict(callNormalReturns=returns,sfunLoops=loops,requiresSuccessfulMarker=True,notAFullPreprocessorProof=True,nativeLibraryBindingQualified=False))
 qnt=BASE/'models/quint/sfun_admission_refusal.qnt';proj=ROOT/'dev/modeling/tools'/f'{TASK}-projection.py';mod=loadmod('guard_projection',proj)
 formal=[model,qnt,proj,ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py',ROOT/'dev/modeling/tools'/f'{TASK}-study.py']+list((BASE/'models/lean').glob('SfunAdmission*.lean'))+[ROOT/v for v in parentFiles]
 formalStart={rel(f):sha(f) for f in formal}
 run('typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')]);ir=json.loads((CACHE/'typed-ir.json').read_text());ast,receipt=mod.generate(ir)
 assert (BASE/'models/lean/SfunAdmissionAst.lean').read_text()==ast
 save(CACHE/'projection.json',dict(**receipt,typedIrSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(BASE/'models/lean/SfunAdmissionAst.lean')))
 controls={}
 for label in ['binding','field','roster','expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
  if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if label=='roster':ds['step']['expr']['args'].pop(0)
  if label=='expression':ds['safe']['expr']['opcode']='not-qualified'
  try:mod.generate(bad)
  except (AssertionError,KeyError):controls[label]='rejected'
  else:raise AssertionError(label)
 save(CACHE/'projection-controls.json',controls)
 modules=['SizeGuardAst','SfunAdmissionAst']+json.loads((CACHE/'proof-modules.json').read_text());lemmas=[]
 proofInputs={rel(f):sha(f) for f in [qnt,proj,ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE/'models/lean'/f'{n}.lean' for n in modules]};proofInputs['leanBinary']=sha(Path(LEAN));qualified=[]
 for n in modules:
  file=BASE/'models/lean'/f'{n}.lean';assert not re.search(r'\bsorry\b|\baxiom\s',file.read_text())
  capsule=CACHE/('qualified-'+n+'.json');prior=json.loads(capsule.read_text()) if capsule.exists() else None
  reusable=prior and prior['inputs']==proofInputs and (CACHE/(n+'.olean')).exists() and sha(CACHE/(n+'.olean'))==prior['objectSha256'] and all(sha(ROOT/f)==h for f,h in prior['logs'].items()) and sha(ROOT/prior['sourceSnapshot'])==prior['sourceSnapshotSha256']
  if not reusable:
   run('lean-'+n,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(n+'.olean')),str(file)])
   status=max(CACHE.glob('lean-'+n+'-*.status.json'),key=lambda p:p.stat().st_mtime);stem=status.name.removesuffix('.status.json');snap=CACHE/(stem+'-'+file.name)
   prior=dict(inputs=proofInputs,objectSha256=sha(CACHE/(n+'.olean')),logs={rel(f):sha(f) for f in CACHE.glob(stem+'.*')},sourceSnapshot=rel(snap),sourceSnapshotSha256=sha(snap),qualifiedFrom='fresh current-task formal invocation');save(capsule,prior)
  qualified.append(dict(name=n,reused=bool(reusable),**prior))
  if n.startswith('SfunAdmission'):lemmas+=['SfunAdmissionBridge.'+v if n=='SfunAdmissionBridge' else 'SfunAdmission.'+v for v in re.findall(r'^theorem (\w+)',file.read_text(),re.M)]
 save(CACHE/'formal-qualified-scopes.json',qualified)
 histories=run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','947']);assert histories.count('ok ')==14
 run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','947','--verbosity','1'])
 counters=json.loads((CACHE/'counter-config.json').read_text())
 for row in counters:
  label,action,part,before,after,witness,prefix=row;folder=CACHE/('negative-'+label);folder.mkdir(exist_ok=True);changed=[]
  for line in ast.splitlines():
   if line.startswith('def '+action+('Guard' if part=='GuardExtra' else part)):
    line=(line+' ∧ ('+after+')') if part=='GuardExtra' else (line.split(':=',1)[0]+':= True' if part=='Guard' else line.replace(before,after))
   changed.append(line)
  mutant='\n'.join(changed)+'\n';assert mutant!=ast,label
  (folder/'SfunAdmissionAst.lean').write_text(mutant);run(label+'-ast',[LEAN,'-o',str(folder/'SfunAdmissionAst.olean'),str(folder/'SfunAdmissionAst.lean')])
  goal='Safe ('+action+'Next witness)'
  if part=='GuardExtra':
   text='import SfunAdmissionAst\nopen SfunAdmissionAst\ndef witness : State := '+witness+'\nexample : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : ¬ '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\n'
   line=7
  else:
   text='import SfunAdmissionAst\nopen SfunAdmissionAst\ndef witness : State := '+witness+'\nexample : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : ¬ ('+goal+') := by simp [Safe,'+action+'Next,witness,initial]\nexample : '+goal+' := by simp [Safe,'+action+'Next,witness,initial]\n'
   line=8
  (folder/'Control.lean').write_text(text);out=run(label+'-control',['env','LEAN_PATH='+str(folder),LEAN,str(folder/'Control.lean')],expected=1);assert out.count('error:')==1 and ('Control.lean:'+str(line)+':') in out,label
 save(CACHE/'countercontrols.json',[r[0] for r in counters])
 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources]
 routes=[[r[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for r in p['route']]
 needs=[[r['key'],r['status'],r['condition']] for r in p['need']]
 issuers=[[r[k] for k in ['key','source','existing','candidate','gap']] for r in p['issuer']]
 composition=[[r[k] for k in ['key','lemma','source','obligation','boundary']] for r in p['composition']]
 components=[[r['componentId'],r['sharedContract']] for r in p['component']]
 engine=Engine();results={}
 try:
  session=engine.open_sources((ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm').read_text());assert session.run(queries=['blocked'])['complete']
  paths=[[r[k] for k in ['key','producer','consumer','classification','phase','missing','loopStatus']] for r in p['path']]
  cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-component','forged-issuer','wrong-bridge','raw-call-is-SFUN','ordinary-callback-is-cleanup','delete-is-Scheme-call','mutex-is-GC-gate','marker-failure-enters-loop','global-UNKNOWN-blacklist','missing-native-root-adapter','wrong-shared-contract','missing-paper']
  for case in cases:
   so=copy.deepcopy(src);ro=copy.deepcopy(routes);io=copy.deepcopy(issuers);co=copy.deepcopy(composition);cn=copy.deepcopy(components);po=copy.deepcopy(paths);mo=[[r[k] for k in ['key','order','premise','obligation']] for r in p['memory']];mn=copy.deepcopy(mo)
   nr=[[case,k,s,c] for k,s,c in needs if case!='current' or s!='unresolved']
   if case=='stale-source':so[0][2]='stale'
   if case=='wrong-component':ro[0][0]='unrelated'
   if case=='forged-issuer':io[0][3]='existing verified guard signer'
   if case=='wrong-bridge':co[0][1]='SfunAdmission.nativeC23Complete'
   if case=='raw-call-is-SFUN':po[0][-1]='observed-SFUN-loop'
   if case=='ordinary-callback-is-cleanup':po[2][4]='OWNER_CLEANUP'
   if case=='delete-is-Scheme-call':po[4][-1]='observed-SFUN-loop'
   if case=='mutex-is-GC-gate':po[6][3]='complete-GC-admission'
   if case=='marker-failure-enters-loop':co[3][-1]='marker failure suffices for legacy inner retry'
   if case=='global-UNKNOWN-blacklist':mo[2][2]='Every UNKNOWN value means admission refusal'
   if case=='missing-native-root-adapter':nr=[r for r in nr if r[1]!='guard-and-root-registration']
   if case=='wrong-shared-contract':cn[0][1]='filename-only'
   if case=='missing-paper':so=[r for r in so if r[0]!='feeley-paper']
   session.replace(dict(scenario=[[case]],need=needs,receipt=nr,sourceNeed=src,sourceObservation=so,routeNeed=routes,routeObservation=ro,actionName=[[mod.SPEC['module']+'.'+a] for a in mod.SPEC['actions'][1 if case=='missing-action' else 0:]],lemmaName=[[l] for l in lemmas[1 if case=='missing-lemma' else 0:]],issuerNeed=issuers,issuerObservation=io,compositionNeed=composition,compositionObservation=co,memoryNeed=mn,memoryObservation=mo,componentNeed=components,componentObservation=cn,pathNeed=paths,pathObservation=po))
   res=session.run(queries=['blocked','candidate','routeLinked','compositionLinked','groundingLinked','pathLinked']);assert res['complete'];results[case]=res['relations']
 finally:engine.close()
 assert [k for k,v in results.items() if v['candidate']]==['synthetic-all']
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: SFUN admission refusal — caller reachability and net return','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML authority',':PROPERTIES:',':CUSTOM_ID: sfun-admission-refusal-matrix',':AUTHORITY: GambitSfunAdmissionRefusal',':END:','Formal and source-bound rows qualify only their named abstract boundaries. Native issuers remain unresolved.']
 for group in ['component','path','issuer','composition','need','memory','gain','route','source']:
  fs=list(p[group][0]);matrix+=['','** '+group.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(str(r[k]).replace('\n',' / ').replace('|',' / ') for k in fs)+' |' for r in p[group]]
 (BASE/f'{TASK}-matrix.org').write_text('\n'.join(matrix)+'\n')
 d2=BASE/'diagrams'/f'{TASK}.d2';d2.write_text('direction: down\ntitle: "C23 SFUN admission refusal, source roots and native outcomes"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['contract'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 checks=dict(sourceAnchors=len(sources),components=len(components),callerPaths=len(paths),qntActions=len(mod.SPEC['actions']),histories=14,samples=500,maxSteps=80,seed=947,leanTheorems=len(lemmas),stepInduction=True,managedModeInvariant=True,legacyRecurrenceConditional=True,legacyLoopNativeObserved=False,actualGcToSfunEdgeEstablished=False,markerSuccessRequired=True,markerFailureSkipsInnerLoop=True,callReturnInventoryExact=True,parentAdmissionPredicateBridge=True,parentFullSimulation=False,typedIrControls=len(controls),countercontrols=len(counters),ascentScenarios=len(results),compositionJoins=len(composition),actualCandidate=False,unresolved=[r['key'] for r in p['need'] if r['status']=='unresolved'],sourcePathNotNativeTrace=True,sourcePinIssuerQualified=False,allNativeIssuersQualified=False,c23MemoryRefinement=False,nestedGuardSubtreeRefinement=False,allAliasesClosed=False,nativePathsRetired=0,runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,performanceTests=False)
 save(CACHE/'checks.json',checks)
 save(OUT/'checks.json',checks)
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for a,b in [('dev/architecture/toolchain/iter-compiler-service-design.org',rel(BASE/f'{TASK}-design.org')),('dev/architecture/toolchain/iter-compiler-service-matrix.org',rel(BASE/f'{TASK}-matrix.org')),('dev/architecture/toolchain/index.org',rel(BASE/'index.org'))]:org=org.replace(a,b)
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])

 files=formal+[ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm',BASE/f'{TASK}-design.org',BASE/f'{TASK}-matrix.org',BASE/'index.org',d2,d2.with_suffix('.svg')]+[CACHE/n for n in ['config.json','model-data.json','proof-modules.json','counter-config.json']]
 bindings.update({rel(f):sha(f) for f in files})
 assert startModel==sha(model) and parentDigest==sha(parent)
 assert all(sha(ROOT/k)==v for k,v in formalStart.items()) and all(sha(ROOT/r['path'])==r['sha256'] for r in sources)
 assert all(sha(ROOT/k)==v for k,v in bindings.items())
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),sourceBindings=bindings,parentInputSha256=parentDigest,parentInputPath=rel(parent),leanBinarySha256=sha(LEAN),nativeClaim=False))
 save(CACHE/'formal-inputs.json',formalStart)
 for f in CACHE.rglob('*'):
  if f.is_file():
   target=OUT/f.relative_to(CACHE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,target)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
