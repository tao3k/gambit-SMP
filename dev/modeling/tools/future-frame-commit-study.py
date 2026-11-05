#!/usr/bin/env python3
"""C23 lazy-future correspondence, split safety and conditional costs; no runtime tests."""
import copy,hashlib,importlib.util,json,re,shutil,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TASK='future-frame-commit';BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks'/TASK;OUT=ROOT/'evidence/research'/TASK
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def rel(p):return str(Path(p).relative_to(ROOT))
def loadmod(n,p):
 s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
helper=loadmod('process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');helper.CACHE=CACHE;run=helper.run

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitFutureFrameCommit::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs.split()]
 model=BASE/'models/sysml'/f'{TASK}.sysml';modelHash=sha(model);cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 raw=json.loads(run('sysml',cmd+[str(model)]));assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 bindings={};sources=[];snaps=CACHE/'source-snapshots';snaps.mkdir(exist_ok=True)
 for row in p['source']:
  file=ROOT/row['path'];b=file.read_bytes();text=b.decode();assert row['needle'] in text;digest=sha(file);snapshot=snaps/(digest+'.txt')
  if snapshot.exists():assert snapshot.read_bytes()==b
  else:snapshot.write_bytes(b)
  sources.append(dict(**row,sha256=digest,snapshot=rel(snapshot),lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]));bindings[row['path']]=digest
 old=CACHE/'source-witnesses.json'
 if old.exists():shutil.copyfile(old,CACHE/('source-witnesses-'+str(time.time_ns())+'.json'))
 save(old,sources)
 paper=json.loads((CACHE/'pvm-paper-source.json').read_text())
 for name,h in paper['files'].items():
  f=ROOT/paper['canonicalFiles'][name];assert sha(f)==h;bindings[rel(f)]=h
 parent=ROOT/'evidence/research/lazy-future-split/input.json';parentHash=sha(parent)
 parentAst=BASE/'models/lean/LazySplitAst.lean';parentData=json.loads(parent.read_text());assert parentData['sourceBindings'][rel(parentAst)]==sha(parentAst);bindings[rel(parentAst)]=sha(parentAst)
 save(CACHE/'parent-currentness.json',dict(parentSha256=parentHash,actualParentAstBound=True,formalSimulationClaim=False,nativeEvidenceReused=False))
 header=(ROOT/'vendor/gambit/include/_gambit/module_generation.h.in').read_text();defs=[x.strip() for x in header.splitlines() if x.startswith('#define ___TASK_PUSH') or x.startswith('#define ___TASK_POP')];assert defs==['#define ___TASK_PUSH(i)','#define ___TASK_POP(n)']
 save(CACHE/'task-hook-inventory.json',dict(definitions=defs,sourceHooksEmpty=True,preprocessorExecuted=False,loadedBinaryQualified=False,currentTaskAllocationSavingsClaim=False))
 data=json.loads((CACHE/'model-data.json').read_text());asts={};actions=[];projections=[];formal=[model,Path(__file__),ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']
 for group,d in data.items():
  qnt=BASE/'models/quint'/(d['name']+'.qnt');projector=ROOT/'dev/modeling/tools'/(d['name'].replace('_','-')+'-projection.py');mod=loadmod(group,projector)
  run(group+'-typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/(group+'-ir.json'))]);ir=json.loads((CACHE/(group+'-ir.json')).read_text());ast,receipt=mod.generate(ir);assert (BASE/'models/lean'/(d['namespace']+'.lean')).read_text()==ast;asts[group]=ast
  controls={}
  for label in ['binding','field','roster','expression']:
   bad=copy.deepcopy(ir);ds={x['name']:x for x in bad['modules'][0]['declarations']}
   if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
   if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
   if label=='roster':ds['step']['expr']['args'].pop(0)
   if label=='expression':ds['safe']['expr']['opcode']='not-qualified'
   try:mod.generate(bad)
   except (AssertionError,KeyError):controls[label]='rejected'
   else:raise AssertionError(label)
  save(CACHE/(group+'-projection.json'),dict(**receipt,typedIrSha256=sha(CACHE/(group+'-ir.json')),astSha256=sha(BASE/'models/lean'/(d['namespace']+'.lean')),controls=controls));projections.append(receipt)
  actions += [[d['name']+'.'+a] for a in d['actions']];formal += [qnt,projector]
 modules=['LazySplitAst','FrameCommitAst']+json.loads((CACHE/'proof-modules.json').read_text());lemmas=[];formal += [BASE/'models/lean'/(n+'.lean') for n in modules];formalStart={rel(f):sha(f) for f in formal}
 for n in modules:
  if n.startswith('LazySplit'):
   f=BASE/'models/lean'/(n+'.lean');assert parentData['sourceBindings'][rel(f)]==sha(f)
 mathBase={k:v for k,v in formalStart.items() if k.endswith('.qnt') or 'projection.py' in k};mathBase['leanBinary']=sha(LEAN);qualified=[]
 basisMemo={}
 def moduleBasis(name,seen=None):
  seen=set() if seen is None else seen
  assert name not in seen,'import cycle'
  if name in basisMemo:return dict(basisMemo[name])
  seen=seen|{name};f=BASE/'models/lean'/(name+'.lean');basis={rel(f):sha(f)}
  for line in f.read_text().splitlines():
   if not line.startswith('import '):continue
   match=re.fullmatch(r'import ([A-Za-z0-9_]+)',line);assert match,line;dep=match.group(1)
   if dep in modules:basis.update(moduleBasis(dep,seen))
   else:assert dep=='Std',dep
  basisMemo[name]=dict(basis)
  return basis
 for n in modules:
  basis=moduleBasis(n);proofInputs=dict(basis,leanBinary=sha(LEAN))
  # Typed AST equations were checked above; bind only the QNT/projectors in
  # this actual import closure. Preserve old superset receipts when narrowing.
  for d in data.values():
   if rel(BASE/'models/lean'/(d['namespace']+'.lean')) in basis:
    for f in [BASE/'models/quint'/(d['name']+'.qnt'),ROOT/'dev/modeling/tools'/(d['name'].replace('_','-')+'-projection.py'),ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py']:proofInputs[rel(f)]=sha(f)
  file=BASE/'models/lean'/(n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',file.read_text());capsule=CACHE/('qualified-'+n+'.json');prior=json.loads(capsule.read_text()) if capsule.exists() else None
  reusable=prior and all(prior['inputs'].get(k)==v for k,v in proofInputs.items()) and (CACHE/(n+'.olean')).exists() and sha(CACHE/(n+'.olean'))==prior['objectSha256'] and all(sha(ROOT/f)==h for f,h in prior['logs'].items()) and sha(ROOT/prior['sourceSnapshot'])==prior['sourceSnapshotSha256']
  if not reusable:
   run('lean-'+n,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(n+'.olean')),str(file)])
   status=max(CACHE.glob('lean-'+n+'-*.status.json'),key=lambda f:f.stat().st_mtime);stem=status.name.removesuffix('.status.json');snap=CACHE/(stem+'-'+file.name)
   prior=dict(inputs=proofInputs,objectSha256=sha(CACHE/(n+'.olean')),logs={rel(f):sha(f) for f in CACHE.glob(stem+'.*')},sourceSnapshot=rel(snap),sourceSnapshotSha256=sha(snap));save(capsule,prior)
  if reusable and prior['inputs']!=proofInputs:
   legacy=CACHE/('retained-full-basis-'+n+'-'+sha(capsule)+'.json')
   if not legacy.exists():shutil.copyfile(capsule,legacy)
   prior=dict(prior,inputs=proofInputs,narrowedFrom=rel(legacy),dependencyScope='strict supported import roster; external Std trusted with compiler installation');save(capsule,prior)
  qualified.append(dict(name=n,reused=bool(reusable),**prior))
  ns='AtomicOwner' if n.startswith('AtomicOwner') else 'ControlWord' if n.startswith('ControlWord') else 'FutureCoordinates' if n=='FutureCoordinates' else 'FrameCommitBridge' if n=='FrameCommitBridge' else 'FrameActivation' if n.startswith('FrameActivation') else 'LazySplit' if n.startswith('LazySplit') else 'FrameCommit'
  if not n.endswith('Ast'):lemmas += [ns+'.'+v for v in re.findall(r'^theorem (\w+)',file.read_text(),re.M)]
 save(CACHE/'formal-qualified-scopes.json',qualified)
 for group,d in data.items():
  qnt=BASE/'models/quint'/(d['name']+'.qnt');hist=run(group+'-histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953']);assert hist.count('ok ')==len(d['histories'])
  run(group+'-samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 counters=json.loads((CACHE/'counter-config.json').read_text())
 for label,group,action,part,before,after,witness,prefix in counters:
  folder=CACHE/('negative-'+label);folder.mkdir(exist_ok=True);ns=data[group]['namespace'];changed=[]
  for line in asts[group].splitlines():
   if line.startswith('def '+action+('Next' if part=='AppendNext' else 'Guard' if part=='GuardPredicate' else part)):
    line=line.split(':=',1)[0]+':= True' if part in ['Guard','GuardPredicate'] else line.rstrip()[:-1]+', '+after+'}' if part=='AppendNext' else line.replace(before,after)
   changed.append(line)
  mutant='\n'.join(changed)+'\n';assert mutant!=asts[group];(folder/(ns+'.lean')).write_text(mutant);run(label+'-ast',[LEAN,'-o',str(folder/(ns+'.olean')),str(folder/(ns+'.lean'))])
  sequence=list(reversed(re.findall(r'(\w+)Next \(',prefix)));prior='initial';guards=[];defs=[]
  for step in sequence:
   guards.append('example : '+step+'Guard ('+prior+') := by simp ['+','.join([step+'Guard','initial']+defs)+']')
   prior=step+'Next ('+prior+')';defs.append(step+'Next')
  guardText='\n'.join(guards)+'\n'
  # Check reachability premises with the ORIGINAL AST, independently of the mutant.
  prefixFile=CACHE/('original-prefix-'+label+'.lean')
  prefixText='import '+ns+'\nopen '+ns+'\ndef witness : State := '+witness+'\n'+guardText+'example : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\n'
  if part in ['Guard','GuardPredicate']:prefixText+='example : ¬ '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\n'
  prefixFile.write_text(prefixText);run(label+'-original-prefix',['env','LEAN_PATH='+str(CACHE),LEAN,str(prefixFile)])
  goal=after if part=='GuardPredicate' else 'Safe ('+action+'Next witness)';text='import '+ns+'\nopen '+ns+'\ndef witness : State := '+witness+'\nexample : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : ¬ ('+goal+') := by simp [Safe,'+action+'Next,witness,initial]\nexample : '+goal+' := by simp [Safe,'+action+'Next,witness,initial]\n'
  text=text.replace('example : witness =',guardText+'example : witness =');failureLine=8+len(guards)
  (folder/'Control.lean').write_text(text);out=run(label+'-control',['env','LEAN_PATH='+str(folder),LEAN,str(folder/'Control.lean')],expected=1);assert out.count('error:')==1 and ('Control.lean:'+str(failureLine)+':') in out,label
 save(CACHE/'countercontrols.json',[r[0] for r in counters])
 src=[[r[k] for k in ['key','path','sha256','needle']] for r in sources]
 def rows(g,fs):return [[r[k] for k in fs.split()] for r in p[g]]
 routes=rows('route','component actionName lemma producerAnchor obligationId');needs=rows('need','key status condition');issuers=rows('issuer','key source existing candidate gap');composition=rows('composition','key lemma source obligation boundary');pairNeed=rows('pair','actionName nativeAction queueAction lemma boundary');wordNeed=rows('word','actionName parentAction lemma source premise');layoutNeed=rows('layout','value route ready meaning');ownerNeed=rows('owner','actionName parentAction lemma source authority');adapterNeed=rows('adapter','backend observation expectedEffect failureSet visibility admission');ownerDomainNeed=rows('ownerDomain','key propertyName bridgeLemma modelSlice');components=rows('component','componentId sharedContract');paths=rows('path','key producer consumer classification missing');memory=rows('memory','key order premise obligation');results={};engine=Engine()
 try:
  session=engine.open_sources((ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm').read_text());assert session.run(queries=['blocked'])['complete']
  cases=['filename-only-owner-domain','foreign-owner-capability','numeric-rf-only','post-load-observed','emulated-empty-fence','relaxed-activation','failure-grants-reservation','word-layout-overlap','independent-commit','missing-activation-gate','current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-component','forged-issuer','wrong-bridge','scheduler-already-in-gate','reset-ignores-split-users','pointer-is-logical-index','child-fs-minus-reserve','forwarding-no-refresh','split-can-fallthrough-local','captured-bit-is-local-route','copy-revalidation-is-recopy','disjoint-address-proves-no-alias','missing-product-step','wrong-shared-contract','missing-paper']
  learning=rows('learning','key source mechanism fact mismatch candidate status')
  for case in cases:
   ownerDomainObservation=copy.deepcopy(ownerDomainNeed);ownerObservation=copy.deepcopy(ownerNeed);adapterObservation=copy.deepcopy(adapterNeed);wordObservation=copy.deepcopy(wordNeed);layoutObservation=[[str(d+4*r),str(d),str(r),name+(' / result ready' if r else ' / result pending')] for r in range(2) for d,name in enumerate(['OPEN','RESERVED','SPLIT','LOCAL'])];pairObservation=copy.deepcopy(pairNeed);so=copy.deepcopy(src);ro=copy.deepcopy(routes);io=copy.deepcopy(issuers);co=copy.deepcopy(composition);cn=copy.deepcopy(components);po=copy.deepcopy(paths);mo=copy.deepcopy(memory);lo=copy.deepcopy(learning);ga=copy.deepcopy(rows('gain','key benefit cost condition refutation'));aa=copy.deepcopy(actions);ll=[[l] for l in lemmas];nr=[[case,k,t,c] for k,t,c in needs if case!='current' or t!='unresolved']
   if case=='filename-only-owner-domain':ownerDomainObservation[0][1]='AtomicOwner.fileExists'
   if case=='foreign-owner-capability':ownerObservation=[r[:-1]+['A1 borrows A0 global flag'] if r[0]=='future_atomic_owner.activateA1' else r for r in ownerObservation]
   if case=='numeric-rf-only':ownerObservation=[r[:-1]+['numeric value alone supplies RF identity'] if r[0]=='future_atomic_owner.acquireChildA0' else r for r in ownerObservation]
   if case=='post-load-observed':adapterObservation=[r[:1]+['load again after Boolean CAS']+r[2:] if r[0]=='legacy-Boolean' else r for r in adapterObservation]
   if case=='emulated-empty-fence':adapterObservation=[r[:4]+['empty fence supplies complete HB']+r[5:] if r[0]=='legacy-raw-mutex' else r for r in adapterObservation]
   if case=='relaxed-activation':wordObservation=[r[:-1]+['relaxed value is enough'] if r[0]=='future_control_word.acquireCommit' else r for r in wordObservation]
   if case=='failure-grants-reservation':wordObservation=[r[:1]+['future_frame_activation.reserve']+r[2:] if r[0]=='future_control_word.splitFailure' else r for r in wordObservation]
   if case=='word-layout-overlap':layoutObservation[4][0]='0'
   if case=='independent-commit':
    pairObservation=[r[:2]+['stutter']+r[3:] if r[0]=='future_frame_activation.commit' else r for r in pairObservation]
   if case=='missing-activation-gate':pairObservation=pairObservation[:-1]
   if case=='stale-source':so[0][2]='stale'
   if case=='missing-action':aa=aa[1:]
   if case=='missing-lemma':ll=ll[1:]
   if case=='wrong-component':ro[0][0]='other'
   if case=='forged-issuer':io[2][3]='already admitted scheduler worker'
   if case=='wrong-bridge':co[-1][1]='FrameCommitBridge.fullNativeSimulation'
   if case=='scheduler-already-in-gate':lo[2][3]='current helper already admits arbitrary scheduler readers'
   if case=='reset-ignores-split-users':io[-1][3]='reset may ignore old scheduler grants'
   if case=='pointer-is-logical-index':lo[0][5]='GVM slot number is directly a C pointer'
   if case=='child-fs-minus-reserve':po[1][3]='all child points use ordinary fs=height-3'
   if case=='forwarding-no-refresh':mo[4][2]='cached raw source fp remains valid across GC'
   if case=='split-can-fallthrough-local':mo[2][2]='child reads OPEN then returns locally without CAS'
   if case=='captured-bit-is-local-route':lo[1][5]='task kind bit is a local execution grant'
   if case=='copy-revalidation-is-recopy':ga[1][3]='all copies can be reused without registered root fields'
   if case=='disjoint-address-proves-no-alias':ga[4][3]='coordinate partition proves all shared-frame aliases disjoint'
   if case=='missing-product-step':nr=[r for r in nr if r[1]!='two-model-steps']
   if case=='wrong-shared-contract':cn[0][1]='filename-only'
   if case=='missing-paper':so=[r for r in so if r[0]!='feeley-paper']
   session.replace(dict(ownerDomainNeed=ownerDomainNeed,ownerDomainObservation=ownerDomainObservation,modelProperty=[['AtomicOwner.'+n] for n in re.findall(r'^def (\w+Facts)',(BASE/'models/lean/AtomicOwnerMaps.lean').read_text(),re.M)],ownerNeed=ownerNeed,ownerObservation=ownerObservation,adapterNeed=adapterNeed,adapterObservation=adapterObservation,wordNeed=wordNeed,wordObservation=wordObservation,parentAction=[['stutter']]+actions,layoutNeed=layoutNeed,layoutObservation=layoutObservation,pairNeed=pairNeed,pairObservation=pairObservation,scenario=[[case]],need=needs,receipt=nr,sourceNeed=src,sourceObservation=so,routeNeed=routes,routeObservation=ro,actionName=aa,lemmaName=ll,issuerNeed=issuers,issuerObservation=io,compositionNeed=composition,compositionObservation=co,memoryNeed=memory,memoryObservation=mo,componentNeed=components,componentObservation=cn,pathNeed=paths,pathObservation=po,learningNeed=learning,learningObservation=lo,gainNeed=rows('gain','key benefit cost condition refutation'),gainObservation=ga))
   res=session.run(queries=['blocked','candidate','routeLinked','compositionLinked','groundingLinked','pathLinked','learningLinked','gainLinked','pairLinked','wordLinked','layoutLinked','ownerLinked','adapterLinked','ownerDomainLinked']);assert res['complete'];results[case]=res['relations']

 finally:engine.close()
 assert [k for k,v in results.items() if v['candidate']]==['synthetic-all'];save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: Future frame coordinates — return commit, forwarding and net return','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML authority',':PROPERTIES:',':CUSTOM_ID: future-frame-commit-matrix',':AUTHORITY: GambitFutureFrameCommit',':END:','Formal and source-bound rows qualify only their named abstract boundaries. Native issuers remain unresolved.']
 for group in ['component','learning','profile','path','issuer','composition','need','memory','gain','route','pair','word','layout','owner','ownerDomain','adapter','source']:
  fs=list(p[group][0]);matrix+=['','** '+group.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(str(r[k]).replace('\n',' / ').replace('|',' / ') for k in fs)+' |' for r in p[group]]
 (BASE/f'{TASK}-matrix.org').write_text('\n'.join(matrix)+'\n')
 d2=BASE/'diagrams'/f'{TASK}.d2';d2.write_text('direction: down\ntitle: "C23 gen-fut: matched commit, inactive publication and GC custody"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['contract'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 wordD2=BASE/'diagrams/future-control-word.d2';wordD2.write_text('direction: down\ntitle: \"C23 shared control word and cross-owner publication\"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['wordEdge'])+'\n');run('word-d2',['d2','--layout','elk',str(wordD2),str(wordD2.with_suffix('.svg'))])
 ownerD2=BASE/'diagrams/future-atomic-outcome.d2';ownerD2.write_text('direction: down\ntitle: \"C23 AtomicOutcome and owner-local acquire provenance\"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['ownerEdge'])+'\n');run('owner-d2',['d2','--layout','elk',str(ownerD2),str(ownerD2.with_suffix('.svg'))])
 checks=dict(sourceAnchors=len(sources),components=len(components),callerPaths=len(paths),qntActions=len(actions),histories=sum(len(d['histories']) for d in data.values()),samplesPerModel=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,atomicOutcomeNormalization=True,necessaryCoherenceGuards=True,scopeRenewKeepsThreadHistory=True,ownerSemanticDomains=len(ownerDomainNeed),ownerIndexedScopes=True,ghostRfNotRuntimeOutput=True,nativeRfClosure=False,activatorRoles=2,claimantRoles=2,sourceFenceStubFound=True,controlWordScRefinement=True,conditionalHbGraph=True,fullC23ExecutionProof=False,stateChangingProtocolCasBound=5,wordProtocolCasBound=3,allBackendRmwBound=False,typedIrControls=4*len(data),ownerActions=len(data['owner']['actions']),ownerHistories=len(data['owner']['histories']),controlActions=len(data['control']['actions']),controlHistories=len(data['control']['histories']),productActions=len(data['activation']['actions']),productHistories=len(data['activation']['histories']),countercontrols=len(counters),originalPrefixChecks=len(counters),invariantMutants=sum(r[3]!='GuardPredicate' for r in counters),guardRequirementMutants=sum(r[3]=='GuardPredicate' for r in counters),ascentScenarios=len(results),compositionJoins=len(composition),learningRows=len(p['learning']),actualCandidate=False,unresolved=[r['key'] for r in p['need'] if r['status']=='unresolved'],modelScope='one normal return decision; shared logical access domain; rooted-copy relocation premise',coordinateArithmetic=True,parentNormalParameters=dict(reserve=3,alignment=4),workedLayoutIsGenerated=False,currentSchedulerFrameGateAdmitted=False,legacyBridgeCouplingAssumed=True,parentCouplingAssumed=False,normalProductStepSimulation=True,productScope='admitted normal occurrence through first return; paired commit and gated activation; no cancellation or multishot retirement',safePairsDoNotImplyCoupling=True,parentFullSimulation=False,actualCanonicalResolver=False,c23MemoryRefinement=False,physicalSlotRefinement=False,sourceSemanticEquivalence=False,nativePathsRetired=0,runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,performanceTests=False)
 save(CACHE/'checks.json',checks);save(OUT/'checks.json',checks);shutil.copyfile(CACHE/'pvm-paper-source.json',OUT/'pvm-paper-source.json')
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for a,b in [('dev/architecture/toolchain/iter-compiler-service-design.org',rel(BASE/f'{TASK}-design.org')),('dev/architecture/toolchain/iter-compiler-service-matrix.org',rel(BASE/f'{TASK}-matrix.org')),('dev/architecture/toolchain/index.org',rel(BASE/'index.org'))]:org=org.replace(a,b)
 org=org.replace(')) (links 0)', ' "dev/refactoring/modern-c/runtime-blueprint.org" "dev/knowledge/ocaml/index.org" "dev/knowledge/erlang/index.org")) (links 0)')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 files=formal+[ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm',BASE/f'{TASK}-design.org',BASE/f'{TASK}-matrix.org',BASE/'index.org',BASE/'runtime-blueprint.org',ROOT/'dev/knowledge/ocaml/index.org',ROOT/'dev/knowledge/erlang/index.org',d2,d2.with_suffix('.svg'),wordD2,wordD2.with_suffix('.svg'),ownerD2,ownerD2.with_suffix('.svg')]+[CACHE/n for n in ['config.json','model-data.json','proof-modules.json','counter-config.json','pvm-paper-source.json','activation-pairs.json','control-pairs.json','owner-pairs.json']]
 bindings.update({rel(f):sha(f) for f in files});assert modelHash==sha(model) and parentHash==sha(parent);assert all(sha(ROOT/k)==v for k,v in formalStart.items());assert all(sha(ROOT/k)==v for k,v in bindings.items())
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),sourceBindings=bindings,parentInputSha256=parentHash,parentInputPath=rel(parent),leanBinarySha256=sha(LEAN),nativeClaim=False));save(CACHE/'formal-inputs.json',formalStart)
 for f in CACHE.rglob('*'):
  if f.is_file():
   t=OUT/f.relative_to(CACHE);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,t)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'});print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
