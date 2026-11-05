#!/usr/bin/env python3
"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
import copy, importlib.util, json, re, shutil, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='will-action-drain';BASE='dev/refactoring/modern-c/';PKG='GambitWillActionDrain'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM

def load(n,p):
 spec=importlib.util.spec_from_file_location(n,ROOT/p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load('research','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run,save,sha=h.run,h.save,h.sha

def formal():
 e=load('carry_projection','dev/modeling/tools/'+STEM+'-projection.py');cfg=e.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 formalPaths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in ['WillDrainAst','WillDrain']]
 if '--reuse-formal' in sys.argv:
  checkpoint=json.loads((CACHE/'formal-checkpoint.json').read_text())
  assert {f:sha(ROOT/f) for f in formalPaths}==checkpoint['sources']
  assert all(sha(ROOT/f)==d for f,d in checkpoint['logs'].items())
  lemmas=[['WillDrain.'+n] for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/WillDrain.lean')).read_text(),re.M)]
  return [[cfg['module']+'.'+n] for n in cfg['actions']],lemmas
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rc=e.generate(ir)
 path=BASE+'models/lean/WillDrainAst.lean';(ROOT/path).write_text(ast)
 save(CACHE/'projection.json',dict(**rc,irSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(ROOT/path),scope='restricted typed IR; JSON parser and projection trusted; C23 source simulation open'))
 controls={}
 for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if case=='wrong-state-binding':bad['table'][str(rc['stateReferences'][0][0])]['id']=-1
  if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if case=='missing-step':ds['step']['expr']['args'].pop(0)
  if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
  try:e.generate(bad)
  except (AssertionError,KeyError):controls[case]='rejected'
  else:raise AssertionError(case)
 save(CACHE/'projection-controls.json',controls)
 for n in ['WillDrainAst','WillDrain']:
  src=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
  target=CACHE/(n+'.lean');target.write_bytes(src.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(target)])
 tests=run('histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==11
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','257','--verbosity','1'])
 neg=CACHE/'negative-issue';neg.mkdir(exist_ok=True)
 bad='\n'.join(line.replace('(q.weak=(0))','True') if line.startswith('def issueGuard') else line for line in ast.splitlines())+'\n'
 assert bad!=ast;(neg/'WillDrainAst.lean').write_text(bad)
 run('negative-ast',['lean','-o',str(neg/'WillDrainAst.olean'),str(neg/'WillDrainAst.lean')])
 try:run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/WillDrain.lean'])
 except RuntimeError:assert 'error:' in (CACHE/'negative-proof.stdout').read_text()
 else:raise AssertionError('weak-pending issue guard accepted')
 lemmas=[['WillDrain.'+n] for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/WillDrain.lean')).read_text(),re.M)]
 save(CACHE/'formal-checkpoint.json',dict(sources={f:sha(ROOT/f) for f in formalPaths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and f.stem in ['typecheck','WillDrainAst','WillDrain','histories','samples','negative-ast','negative-proof']}))
 return [[cfg['module']+'.'+n] for n in cfg['actions']],lemmas

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());snap=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snap.items():assert sha(ROOT/f)==sha(ROOT/v['path'])==v['sha256'],f
 parent=ROOT/'evidence/research/callback-carry-closure/input.json';parentHash=sha(parent)
 adapter=load('native_sysml','dev/modeling/tools/default-lease-admission-study.py')
 for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=cfg['groups'],SLOTS=cfg['slots']).items():setattr(adapter,k,v)
 adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
 if '--reuse-sysml' in sys.argv:
  checkpoint=json.loads((CACHE/'native-checkpoint.json').read_text());scope=checkpoint['inputs']
  assert sha(CACHE/'config.json')==checkpoint['config']
  assert all(sha(ROOT/f)==d for f,d in scope.items())
  assert set(scope)==set(run('sysml-inputs',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines())
  assert sha(CACHE/'sysml-all.stdout')==checkpoint['raw'] and sha(CACHE/'native-queries.json')==checkpoint['queries']
  assert sha(CACHE/'sysml-projection.json')==checkpoint['projection']
  p=json.loads((CACHE/'sysml-projection.json').read_text())
 else:
  p,scope=adapter.project();save(CACHE/'sysml-projection.json',p)
  save(CACHE/'native-checkpoint.json',dict(config=sha(CACHE/'config.json'),inputs=scope,raw=sha(CACHE/'sysml-all.stdout'),queries=sha(CACHE/'native-queries.json'),projection=sha(CACHE/'sysml-projection.json')))
 view=load('native_views','dev/modeling/tools/copy-producer-envelope-study.py')
 for k,v in dict(ROOT=ROOT,GROUPS=cfg['groups'],MATRIX=BASE+STEM+'-matrix.org',D2=BASE+'diagrams/'+STEM+'.d2').items():setattr(view,k,v)
 view.views(p)
 matrix=ROOT/(BASE+STEM+'-matrix.org');matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Will Creator, Restoration Custody and Retirement Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-root-exception-C23-platform-open'))
 d2=ROOT/(BASE+'diagrams/'+STEM+'.d2');d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / roots / exceptions / C23 OPEN'))
 witnesses=[]
 for v in p['source']:
  text=(ROOT/snap[v['path']]['path']).read_text();assert v['needle'] in text,v
  witnesses.append(dict(**v,sha256=snap[v['path']]['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witnesses)
 # Bounded artifact procedure slice; no assertion that its generation matches current source.
 generated=(ROOT/snap['vendor/gambit/lib/_kernel.c']['path']).read_text()
 start=generated.index('#define ___PH_PROC ___H__23__23_will_2d_execute_21_')
 end=generated.index('#undef ___PH_PROC',start)
 body=generated[start:end]
 ordered=['___SET_R2(___WILLTESTATOR(___R1))','___SET_R3(___WILLACTION(___R1))','___WILLTESTATORSET(___R1,___FAL)','___WILLACTIONSET(___R1,___FAL)','___SET_R1(___R2)','___POLL(1)','___JUMPGENNOTSAFE(___SET_NARGS(1),___R3)']
 positions=[body.index(v) for v in ordered];assert positions==sorted(positions)
 save(CACHE/'action-artifact-slice.json',dict(path='vendor/gambit/lib/_kernel.c',sha256=snap['vendor/gambit/lib/_kernel.c']['sha256'],startLine=generated[:start].count('\n')+1,endLine=generated[:end].count('\n')+1,orderedTokens=ordered,positions=positions,configurationMatched=False,scope='lexical artifact order; generated roots and source/configuration match unresolved'))
 inventoryFiles=sorted(set((ROOT/'vendor/gambit/gsc').rglob('*.scm'))|set((ROOT/'vendor/gambit/lib').rglob('*.scm')))
 inventoryInputs={str(f.relative_to(ROOT)):sha(f) for f in inventoryFiles}
 matches=[]
 for f in inventoryFiles:
  path=str(f.relative_to(ROOT));corpus='gsc-tests' if '/gsc/tests/' in path else 'gsc-core' if '/gsc/' in path else 'runtime-core' if f.parent==ROOT/'vendor/gambit/lib' else 'runtime-library-or-fixture'
  for lineNo,line in enumerate(f.read_bytes().decode('utf-8','surrogateescape').splitlines(),1):
   if not any(token in line for token in ['make-will','make-final-will','will-action-set!','will-testator-set!']):continue
   matches.append(dict(path=path,corpus=corpus,line=lineNo,text=line.strip(),comment=line.lstrip().startswith(';'),applicationLooking=bool(re.search(r'\((?:##make-will|make-will|##make-final-will)(?:\s|\))',line)),definition='define-prim' in line or '(define (' in line))
 save(CACHE/'creator-inventory.json',dict(inputs=inventoryInputs,matches=matches,encoding='UTF8 with byte-preserving surrogateescape; raw hashes bind original fixtures',scope='recursive Scheme lexical inventory; no verified parser or indirect/native call closure; core/specifications/optional libraries/tests distinguished'))
 actions,lemmas=formal()
 for v in p['proof']:assert [v['lemma']] in lemmas,v
 needs=[[v[k] for k in ['obligationId','kind','subjectPath']]+[sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 owners=[[v['obligationId'],v['owner.componentId']] for v in p['need'].values()]
 sources=[[v[k] for k in ['key','path','sha256','needle']] for v in witnesses]
 creators=[[v[k] for k in ['key','producer','captures','writes','reachability','retirement']] for v in p['creator']]
 routes=[[v[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for v in p['route']]
 proofs=[[v['key'],v['lemma']] for v in p['proof']]
 results={};cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-creator','missing-formal','wrong-scope','wrong-owner','missing-weak-route']
 engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
  assert session.run(queries=['blocked'])['complete']
  for case in cases:
   receipts=[[case,n,path,digest,sc] for n,k,path,digest,sc in needs if case!='current' or n=='WD-formal']
   if case=='missing-formal':receipts=[v for v in receipts if v[1]!='WD-formal']
   if case=='wrong-scope':receipts[0][-1]='native-performance'
   obs=copy.deepcopy(sources)
   if case=='stale-source':obs[0][2]='stale'
   co=copy.deepcopy(creators)
   if case=='wrong-creator':co[3][4]='proved-default-core-startup-without-evidence'
   ro=copy.deepcopy(routes)
   if case=='wrong-owner':ro[0][0]='execution'
   if case=='missing-weak-route':ro=[r for r in ro if r[1]!='will_action_drain.makeExecutable']
   session.replace(dict(scenario=[[case]],need=needs,needOwner=owners,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if case!='missing-lemma' or v!=['WillDrain.stepPreserves']],sourceNeed=sources,sourceObservation=obs,creatorNeed=creators,creatorObservation=co,routeNeed=routes,routeObservation=ro,proofNeed=proofs))
   r=session.run(queries=['blocked','candidate','linked','sourceLinked','creatorLinked','routeLinked','proofLinked']);assert r['complete'];results[case]=r['relations']
 finally:engine.close()
 assert [k for k in cases if results[k]['candidate']]==['synthetic-all']
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==6,gaps
 assert len(results['current']['routeLinked'])==len(routes)
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT))])
 run('d2-png',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(CACHE/'diagram.png')])
 checks=dict(status='conditional-will-drain-safety-pass-actual-retirement-denied',languageBaseline='C23',sourceSnapshots=len(snap),sourceAnchors=len(witnesses),creatorClasses=len(creators),componentSourceActionRoutes=len(routes),inventoryFiles=len(inventoryInputs),qntActions=len(actions),qntHistories=11,qntSamples=500,seed=257,leanTheorems=len(lemmas),allStepInduction=True,typedIrControls=4,negativeIssueControl=True,ascentScenarios=len(cases),actualCandidate=False,firstNativeRetirement=False,secondNativeRetirement=False,defaultSessionEffectfulWillWitness=False,compiledRootMapQualified=False,currentProducerConsumerMatched=False,eventualDrainProved=False,c23RefinementProved=False,blockers=gaps,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 # Native Org parser and link audit, without Babel evaluation.
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
 (CACHE/'check-org.el').write_text(org)
 for f,v in snap.items():assert sha(ROOT/f)==v['sha256'],f
 assert sha(parent)==parentHash
 for f,digest in inventoryInputs.items():assert sha(ROOT/f)==digest,('inventory drift',f)
 for f,digest in scope.items():assert sha(ROOT/f)==digest,('sysml drift',f)
 own=[BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'models/sysml/'+STEM+'.sysml',BASE+'models/quint/will_action_drain.qnt',BASE+'models/lean/WillDrainAst.lean',BASE+'models/lean/WillDrain.lean',BASE+'index.org',BASE+'language-baseline-design.org',BASE+'callback-carry-closure-design.org',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT)),'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/advantage-architecture-study.py',str((CACHE/'config.json').relative_to(ROOT)),str((CACHE/'source-snapshots.json').relative_to(ROOT))]+[v['path'] for v in snap.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snap,sysmlInputs=scope,lexicalInputs=inventoryInputs))
 def copy_receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 copy_receipts();run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 data=json.loads((CACHE/'input.json').read_text());data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);copy_receipts()
 shutil.copytree(CACHE/'negative-issue',OUT/'negative-issue',dirs_exist_ok=True)
 for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':
 if '--formal-only' in sys.argv:formal()
 else:main()
