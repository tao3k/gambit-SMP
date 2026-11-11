#!/usr/bin/env python3
"""Native architecture projection, candidate behavioral model and semantic kernels; no runtime work."""
import copy,hashlib,importlib.util,json,re,shutil
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'dev/refactoring/modern-c'
CACHE=ROOT/'.cache/tasks/future-frame-commit/runtime-ownership'
OUT=ROOT/'evidence/research/future-frame-commit/runtime-ownership'
GROUPS=[['source', 25, ['key', 'path', 'needle', 'limit']], ['obligation', 8, ['key', 'scope', 'missing']], ['edge', 16, ['fromNode', 'toNode', 'contract']], ['alternative', 3, ['key', 'choice', 'benefit', 'cost', 'decision']], ['domain', 6, ['key', 'owner.moduleId', 'role', 'owns', 'lifetime', 'modelFields', 'boundary']], ['cursorStep', 5, ['key','condition','update','projection','obligation']], ['bitmapStage', 6, ['key','sourceKey','operand','result','obligation']], ['enumerationOp', 4, ['key','sourceKey','authority','operand','rights','reuse','invalidation']], ['writerFamily', 6, ['key','sourceKey','authority','targetContract','observed','closure']], ['slotFamily', 6, ['key','sourceKey','cells','issuer','custody','order','gap']], ['mathScope', 6, ['key','lawKey','kernelPath','kernel','claim','limit']], ['law', 32, ['key', 'domain.key', 'predicate', 'kernel', 'law', 'proofLimit', 'refinement', 'seam.interfaceId', 'sourceKey', 'modelPath','kernelPath']]]
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return str(Path(p).relative_to(ROOT))
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 spec=importlib.util.spec_from_file_location('helper',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h);h.CACHE=CACHE;run=h.run
 frameq=BASE/'models/quint/frame_roots.qnt'
 contractq=BASE/'models/quint/frame_contract.qnt'
 bitmap=BASE/'models/lean/FrameBitmapComposition.lean'
 enumq=BASE/'models/quint/root_enumeration.qnt'
 slotq=BASE/'models/quint/root_store_projection.qnt'
 model=BASE/'models/sysml/runtime-ownership.sysml';qnt=BASE/'models/quint/runtime_ownership.qnt';lean=BASE/'models/lean/RuntimeOwnership.lean';dsl=ROOT/'dev/modeling/ascent/runtime-ownership.rules.scm'
 files=run('sysml-files',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines();bindings={f:sha(ROOT/f) for f in files}
 for f in [qnt,slotq,enumq,frameq,contractq,bitmap,lean,dsl,Path(__file__),ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']:bindings[rel(f)]=sha(f)
 save(CACHE/'sysml-input-cut.json',bindings)
 keys=[(g,i,f,'GambitRuntimeOwnership::'+g+str(i)+'.'+f) for g,n,fs in GROUPS for i in range(n) for f in fs]
 # Bound each native query invocation without raising the existing 60-second limit.
 # Every batch validates the same complete DEV model; final hashes reject source drift.
 vals=[];queryBatches=0
 for start in range(0,len(keys),160):
  cmd=['sysml','-strict','-no-record-cache','-validate','-json']
  for *_,expr in keys[start:start+160]:cmd+=['-e',expr]
  raw=json.loads(run('sysml-batch-'+str(queryBatches),cmd+['dev']))
  assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
  batch=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')]
  assert len(batch)==len(keys[start:start+160]);vals+=batch;queryBatches+=1
 assert len(vals)==len(keys)
 rows={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):rows.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(v.values()) for g,v in rows.items()};save(CACHE/'projection.json',p)
 composition=ROOT/'dev/architecture/runtime/models/sysml/composition.sysml'
 assert 'ref part ownershipContract : GambitRuntimeOwnership::CompositionContract = GambitRuntimeOwnership::contract;' in composition.read_text()
 sources=[]
 for r in p['source']:
  f=ROOT/r['path'];text=f.read_text();assert r['needle'] in text,r;bindings[r['path']]=sha(f)
  (CACHE/('source-'+sha(f)+'.txt')).write_text(text)
  sources.append(dict(**r,sha256=sha(f),lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(r['needle']),text)]))
 save(CACHE/'source-witnesses.json',sources)
 assert all(r['sourceKey'] in {x['key'] for x in sources} for r in p['slotFamily']+p['writerFamily']+p['enumerationOp']+p['bitmapStage'])
 run('qnt-type',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')])
 assert not re.search(r'\bsorry\b|\baxiom\s',lean.read_text())
 run('lean',['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/'RuntimeOwnership.olean'),str(lean)])
 for name in ['FrameRoots','FrameContract','FutureCoordinates','FrameBitmapComposition','FrameCursorClosure']:
  f=BASE/'models/lean'/(name+'.lean');bindings[rel(f)]=sha(f)
  assert not re.search(r'\bsorry\b|\baxiom\s',f.read_text())
  run('lean-'+name,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(name+'.olean')),str(f)])
 audit=CACHE/'cursor-proof-axioms.lean'
 audit.write_text('import FrameCursorClosure\n'+''.join('#print axioms Gambit.FrameCursorClosure.'+n+'\n' for n in ['preserves','pendingRangeIsFresh','totalCorrect','initialBudget']))
 axioms=run('lean-cursor-axioms',['env','LEAN_PATH='+str(CACHE),LEAN,str(audit)])
 assert 'sorryAx' not in axioms
 run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
 run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 run('slot-type',['quint','typecheck',str(slotq),'--out',str(CACHE/'slot-typed-ir.json')])
 run('slot-histories',['quint','test',str(slotq),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
 run('slot-samples',['quint','run',str(slotq),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 run('enum-type',['quint','typecheck',str(enumq),'--out',str(CACHE/'enum-typed-ir.json')])
 run('enum-histories',['quint','test',str(enumq),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
 run('enum-samples',['quint','run',str(enumq),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 for label,f in [('frame',frameq),('contract',contractq)]:
  run(label+'-type',['quint','typecheck',str(f),'--out',str(CACHE/(label+'-typed-ir.json'))])
  run(label+'-histories',['quint','test',str(f),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953'])
  run(label+'-samples',['quint','run',str(f),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 run('cursor-microstep-samples',['quint','run',str(frameq),'--backend','typescript','--init','runInit','--step','runStep','--invariant','runSafe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 predicates=re.findall(r'^ val (\w+)\s*=',qnt.read_text(),re.M);lemmas=re.findall(r'^theorem (\w+)',lean.read_text(),re.M)
 assert all(re.search(r'^\s*val '+re.escape(r['predicate'])+r'\s*=',(ROOT/r['modelPath']).read_text(),re.M) and re.search(r'^theorem '+re.escape(r['kernel'])+r'\b',(ROOT/r['kernelPath']).read_text(),re.M) for r in p['law'])
 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources]
 routes=[[r['key'],r['domain.key'],r['seam.interfaceId'],r['sourceKey'],r['modelPath'],r['predicate'],r['kernelPath'],r['kernel'],'candidate-ownership;whole-source-open'] for r in p['law']]
 symbols=[[r['modelPath'],r['predicate'],sha(ROOT/r['modelPath'])] for r in p['law']]+[[r['kernelPath'],r['kernel'],sha(ROOT/r['kernelPath'])] for r in p['law']]
 ref=[[r['key'],'actual-source-simulation:'+r['key']] for r in p['law']]
 whole=[[r['key'],r['scope']+':whole-composition-open'] for r in p['obligation']]
 scopes=[[r['key'],r['kernelPath'],r['kernel'],sha(ROOT/r['kernelPath']),r['claim']] for r in p['mathScope']]
 assert all(any(l['key']==r['lawKey'] and l['kernel']==r['kernel'] and l['kernelPath']==r['kernelPath'] for l in p['law']) for r in p['mathScope'])
 proofChecks=sorted({(r['kernelPath'],sha(ROOT/r['kernelPath']),sha(LEAN),'lean-accepted-default') for r in p['mathScope']})
 engine=Engine();scenarios={} 
 try:
  session=engine.open_sources(dsl.read_text());assert session.run(queries=['gap'])['complete']
  for case in ['current','synthetic-all','stale-source','wrong-owner','wrong-seam','wrong-predicate','wrong-kernel','wrong-root-source','sample-is-source','kernel-is-full-semantics','physical-pool-inferred','wrong-symbol-hash','missing-kernel-check','stale-kernel-check','scope-inflation']:
   seen=copy.deepcopy(src);rt=copy.deepcopy(routes);sy=copy.deepcopy(symbols);rf=copy.deepcopy(ref);wh=copy.deepcopy(whole)
   sc=copy.deepcopy(scopes);pc=copy.deepcopy(proofChecks)
   if case=='current':rf=[];wh=[]
   if case=='missing-kernel-check':pc=[]
   if case=='stale-kernel-check':pc=[(pc[0][0],'old',pc[0][2],pc[0][3])]
   if case=='scope-inflation':sc[0][4]='full-native-C23-GC-closure'
   if case=='stale-source':seen[0][2]='old'
   if case=='wrong-owner':rt[0][1]='collector'
   if case=='wrong-seam':rt[0][2]='WorkClosure'
   if case=='wrong-predicate':rt[0][5]='closedComplete'
   if case=='wrong-kernel':rt[0][7]='returnIdentityPreserved'
   if case=='wrong-root-source':rt[1][3]='pvm'
   if case=='sample-is-source':rf[0][1]='500-samples-not-source-simulation'
   if case=='kernel-is-full-semantics':wh[1][1]='pure-slot-lemma'
   if case=='physical-pool-inferred':wh[3][1]='logical-worker-is-native-pool'
   if case=='wrong-symbol-hash':sy[0][2]='old'
   session.replace(dict(sourceNeed=src,sourceSeen=seen,routeNeed=routes,routeSeen=rt,symbolNeed=symbols,symbolSeen=sy,sourceRefinementNeed=ref,sourceRefinementSeen=rf,wholeNeed=whole,wholeSeen=wh,scopeNeed=scopes,scopeSeen=sc,kernelCheckNeed=proofChecks,kernelCheckSeen=pc))
   result=session.run(queries=['routeLinked','gap','candidate','mathematicalClosure']);assert result['complete'];scenarios[case]=result['relations']
 finally:engine.close()
 assert [k for k,v in scenarios.items() if v['candidate']]==['synthetic-all'];assert len(scenarios['current']['routeLinked'])==32
 assert len(scenarios['current']['mathematicalClosure'])==6
 assert not scenarios['missing-kernel-check']['mathematicalClosure'] and not scenarios['stale-kernel-check']['mathematicalClosure']
 assert len(scenarios['scope-inflation']['mathematicalClosure'])==5
 save(CACHE/'ascent-results.json',dict(results=scenarios,syntheticNotEvidence=True,sourceRefinement=False))
 lines=['#+TITLE: Runtime ownership architecture — responsibilities, alternatives and proof boundaries','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitRuntimeOwnership',':STATUS: candidate behavioral witnesses and parametric kernels; whole composition open',':END:']
 for group in ['alternative','domain','mathScope','law','cursorStep','bitmapStage','enumerationOp','slotFamily','writerFamily','obligation','edge','source']:
  fields=list(p[group][0]);lines+=['','** '+group.capitalize(),'','| '+' | '.join(fields)+' |','|'+'+'.join('---' for _ in fields)+'|']
  lines+=['| '+' | '.join(str(r[f]).replace('|',' / ') for f in fields)+' |' for r in p[group]]
 matrix=BASE/'runtime-ownership-matrix.org';matrix.write_text('\n'.join(lines)+'\n')
 d2=BASE/'diagrams/runtime-ownership.d2';d2.write_text('direction: right\ntitle: "Gambit C23 target: independently owned execution, roots, work and control"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n')
 run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/runtime-ownership-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/runtime-ownership-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f in [BASE/'runtime-ownership-design.org',matrix,BASE/'index.org',BASE/'runtime-blueprint.org',d2,d2.with_suffix('.svg')]:bindings[rel(f)]=sha(f)
 drift=[f for f,v in bindings.items() if sha(ROOT/f)!=v]
 save(CACHE/'source-currentness.json',dict(changedDuringCheck=drift))
 assert not drift,'Concurrent source drift: retain attempts; refresh or bind an explicit snapshot.'
 checks=dict(nativeSysmlValidated=True,sysmlQueryBatches=queryBatches,sysmlQueryBatchSize=160,ownershipDomains=6,laws=32,mathematicalScopes=6,cursorClosureKernels=len(re.findall(r'^theorem ',(BASE/'models/lean/FrameCursorClosure.lean').read_text(),re.M)),cursorAbstractTotalCorrectness=True,cursorLogicalStepBound='3*fs+2',bitmapCompositionKernels=20,frameHistories=17,cursorMicrostepSamples=500,cursorMicrostepMaxSteps=80,frameContractHistories=4,frameSampledTraces=500,frameContractSampledTraces=500,enumerationOps=4,enumerationHistories=13,enumerationNegativeWitnesses=8,enumerationSampledTraces=500,alternatives=3,sourceAnchors=len(sources),deterministicHistories=11,negativeArchitectureWitnesses=6,slotHistories=13,slotNegativeWitnesses=8,slotSampledTraces=500,sampledTraces=500,maxSteps=80,seed=953,exhaustiveStateProof=False,leanKernels=len(lemmas),quintToLeanExtraction=False,wholeSemanticProof=False,sourceRefinement=False,c23WeakMemoryProof=False,physicalWorkerScheduling=False,ascentScenarios=len(scenarios),unclosedObligations=len(scenarios['current']['gap']),nativeRuns=0,runtimeImplementation=False,nativeAdmission=False,pathsRetired=0)
 save(CACHE/'checks.json',checks);save(CACHE/'input.json',dict(sourceBindings=bindings,leanBinarySha256=sha(LEAN),scope='candidate ownership mechanism; not repair execution or native admission'))
 for f in CACHE.rglob('*'):
  if f.is_file():
   t=OUT/f.relative_to(CACHE);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,t)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
