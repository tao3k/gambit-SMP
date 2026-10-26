#!/usr/bin/env python3
"""Native SysML + source/formal research. Never builds or runs Gambit."""
import copy,importlib.util,json,re,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='global-module-unload';BASE='dev/refactoring/modern-c/';PKG='GambitGlobalModuleUnload'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org'
D2=BASE+'diagrams/'+STEM+'.d2';RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
GROUPS=[['source',40,'key path needle obligation'],['inventory',6,'key path pattern count scope'],['consumer',9,'key callers custody gap'],['claim',5,'key mechanism condition result gap'],['memory',5,'key publication consumer gap'],['gain',6,'key avoided added condition'],['contract',14,'fromNode toNode custody'],['binding',28,'actionName lemma scope'],['proof',11,'key lemma'],['seam',4,'producer.componentId consumer.componentId contract actionName lemma']]
SLOTS=['history','induction','composition','projection','source','platform']
def load(name,path):
 s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
h=load('frame_root_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/frame-seal-start-retire/input.json';parentDigest=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for v in snapshots.values():assert sha(ROOT/v['path'])==v['sha256']
 adapter=load('frame_root_queries','dev/modeling/tools/default-lease-admission-study.py')
 for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=GROUPS,SLOTS=SLOTS).items():setattr(adapter,k,v)
 adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
 try:
  p,scope=adapter.project()
 except AssertionError:
  # Preserve whole-DEV failure. Only this independently unreferenced package may
  # be excluded, and native resolution of every remaining input must still pass.
  raw=json.loads((CACHE/'sysml-all.stdout').read_text())
  errors=[d for d in raw.get('diagnostics',[]) if d['severity']=='error']
  excluded='dev/refactoring/modern-c/models/sysml/causal-architecture.sysml'
  assert errors and all(d.get('file')==excluded for d in errors),errors
  fullScope=json.loads((CACHE/'sysml-input-scope.json').read_text())
  refs=run('independent-package-references',['rg','-l','GambitCausalArchitecture','dev','-g','*.sysml','-g','*.kerml']).splitlines()
  assert refs==[excluded],refs
  for ext in ['stdout','stderr']:shutil.copyfile(CACHE/('sysml-all.'+ext),CACHE/('sysml-whole-dev-failure.'+ext))
  scope={f:d for f,d in fullScope.items() if f!=excluded}
  keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
  keys += [('need',slot,f,f'{PKG}::{slot}.{f}') for slot in SLOTS for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
  args=['sysml','-strict','-no-record-cache','-validate','-json']
  for *_,expr in keys:args+=['-e',expr]
  result=json.loads(run('sysml-scoped',args+list(scope)))
  assert result['exit']==0 and not any(d['severity']=='error' for d in result.get('diagnostics',[]))
  vals=[json.loads(x[4:]) for x in result['output'] if x.startswith('  = ')];assert len(vals)==len(keys)
  p={}
  for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
  for g,_,_ in GROUPS:p[g]=list(p[g].values())
  save(CACHE/'projection.json',p);save(CACHE/'native-queries.json',keys)
  save(CACHE/'sysml-input-scope.json',scope)
  save(CACHE/'global-sysml-status.json',dict(status='blocked-by-independent-model',wholeDevValidated=False,fullInputCount=len(fullScope),validatedInputCount=len(scope),errors=errors,excluded={excluded:fullScope[excluded]}))
 view=load('frame_root_views','dev/modeling/tools/copy-producer-envelope-study.py')
 for k,v in dict(ROOT=ROOT,GROUPS=GROUPS,MATRIX=MATRIX,D2=D2).items():setattr(view,k,v)
 view.views(p)
 f=ROOT/MATRIX;f.write_text(f.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Global Image Owner and Unload Permission Matrix').replace('GambitCopyProducerEnvelope',PKG))
 witnesses=[]
 for v in p['source']:
  snap=snapshots[v['path']];text=(ROOT/snap['path']).read_text();assert v['needle'] in text,v['key']
  witnesses.append(dict(**v,snapshotPath=snap['path'],sha256=snap['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(OUT/'source-witnesses.json',witnesses)

 inventory=[]
 for v in p['inventory']:
  sv=snapshots[v['path']];text=(ROOT/sv['path']).read_text();hits=list(re.finditer(v['pattern'],text,re.M));assert len(hits)==int(v['count']),v
  inventory.append([v['key'],v['path'],str(len(hits)),sv['sha256'],v['scope']])
 save(CACHE/'writer-inventory.json',inventory);save(OUT/'writer-inventory.json',inventory)


 emitter=load('frame_root_projection',EMITTER);cfg=emitter.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 run('qnt-typecheck',['quint','typecheck',qnt,'--out',str(CACHE/(cfg['module']+'.json'))])
 ir=json.loads((CACHE/(cfg['module']+'.json')).read_text());ast,rc=emitter.generate(ir)
 (ROOT/(BASE+'models/lean/GlobalUnloadAst.lean')).write_text(ast)
 save(CACHE/'projection-receipt.json',dict(**rc,irSha256=sha(CACHE/(cfg['module']+'.json')),astSha256=sha(ROOT/(BASE+'models/lean/GlobalUnloadAst.lean'))))
 controls={}
 for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if case=='wrong-state-binding':bad['table'][str(rc['stateReferences'][0][0])]['id']=-1
  if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if case=='missing-step':ds['step']['expr']['args'].pop(0)
  if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
  try:emitter.generate(bad)
  except (AssertionError,KeyError):controls[case]='rejected'
  else:raise AssertionError(case)
 save(CACHE/'projection-controls.json',controls)
 prior=json.loads(parent.read_text());oldCache=ROOT/'.cache/tasks/frame-seal-start-retire'
 imported=[]
 for f,d in prior['sourceBindings'].items():
  if '/models/lean/' not in f:continue
  assert sha(ROOT/f)==d,f
  n=Path(f).name;cached=oldCache/n;obj=cached.with_suffix('.olean')
  assert cached.read_bytes()==(ROOT/f).read_bytes() and obj.is_file(),n
  shutil.copyfile(cached,CACHE/n);shutil.copyfile(obj,CACHE/obj.name);imported.append(f)
 save(CACHE/'imported-proof-bindings.json',{f:sha(ROOT/f) for f in imported})
 formalPaths=['dev/refactoring/modern-c/models/quint/global_module_unload.qnt', 'dev/refactoring/modern-c/models/lean/GlobalUnloadAst.lean', 'dev/refactoring/modern-c/models/lean/GlobalUnload.lean', 'dev/refactoring/modern-c/models/lean/GlobalUnloadComposition.lean', 'dev/modeling/tools/global-module-unload-projection.py', 'dev/modeling/tools/chunk-capacity-charge-projection.py']+imported
 if '--reuse-formal' in sys.argv:
  cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
  assert {f:sha(ROOT/f) for f in formalPaths}==cp['sourceBindings']
  for f,d in cp['logs'].items():assert sha(ROOT/f)==d,f
 else:
  for n in ['GlobalUnloadAst','GlobalUnload','GlobalUnloadComposition']:
   original=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',original.read_text())
   f=CACHE/(n+'.lean');f.write_bytes(original.read_bytes())
   run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
  tests=run('qnt-histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==16 and tests.count('ControlTest passed')==7
  run('qnt-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','113','--verbosity','1'])
  neg=CACHE/'negative-issue';neg.mkdir(exist_ok=True)
  bad='\n'.join(l.replace('(q.observers=(0))','True') if l.startswith('def permitGuard') else l for l in ast.splitlines())+'\n';assert bad!=ast
  (neg/'GlobalUnloadAst.lean').write_text(bad)
  run('negative-ast',['lean','-o',str(neg/'GlobalUnloadAst.olean'),str(neg/'GlobalUnloadAst.lean')])
  try:run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/GlobalUnload.lean'])
  except RuntimeError:assert 'error' in (CACHE/'negative-proof.stdout').read_text()
  else:raise AssertionError('mutant proof accepted')
 actions=[['global_module_unload.'+a] for a in cfg['actions']]
 lemmas=[[n+'.'+v] for n in ['GlobalUnload','GlobalUnloadComposition'] for v in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witnesses]
 bridges=[['prior-global-retirement-contract',str(parent.relative_to(ROOT)),parentDigest,'GlobalUnloadComposition.permitRefinesPriorGlobalReadiness']]
 cases=['current','synthetic-all','stale-digest','wrong-scope','missing-action','missing-proof','missing-anchor','wrong-parent','missing-seam','wrong-inventory']
 seams=[[v[f] for f in ['producer.componentId','consumer.componentId','contract','actionName','lemma']] for v in p['seam']]
 results={};engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/RULES).read_text());assert session.run(queries=['blocked'])['complete']
  for case in cases:
   receipts=[[case,n,f,d,s] for n,k,f,d,s in needs if case!='current' or k in ['induction','interleaving','restricted-projection']]
   if case=='stale-digest':receipts[0][3]='stale'
   if case=='wrong-scope':receipts[0][4]='native-pass'
   bridge=copy.deepcopy(bridges)
   if case=='wrong-parent':bridge[0][2]='stale'
   observedInventory=copy.deepcopy(inventory)
   if case=='wrong-inventory':observedInventory[0][2]='999'
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if case!='missing-proof' or v!=['GlobalUnloadComposition.permitRefinesPriorGlobalReadiness']],witness=ws,observation=ws[1:] if case=='missing-anchor' else ws,compositionNeed=[[v['key'],v['lemma']] for v in p['proof']],refinementNeed=[],targetActionName=[],bridgeNeed=bridges,bridgeObservation=bridge,inventoryNeed=inventory,inventoryObservation=observedInventory,seamNeed=seams,seamObservation=seams[1:] if case=='missing-seam' else seams))
   result=session.run(queries=['blocked','candidate','linked','compositionLinked','observed','bridgeLinked','seamLinked','inventoryLinked']);assert result['complete'];results[case]=result['relations']
  assert {v[1] for v in results['current']['blocked']}=={'GU-source','GU-platform'}
  assert [len(results['current'][k]) for k in ['linked','compositionLinked','observed','bridgeLinked']]==[28,11,40,1]
  assert len(results['current']['seamLinked'])==4
  assert len(results['current']['inventoryLinked'])==6
  assert [c for c in cases if results[c]['candidate']]==['synthetic-all']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 checks=dict(status='conditional-formal-pass',sourceSnapshots=len(snapshots),sourceAnchors=len(witnesses),qntActions=len(actions),qntHistories=16,negativeHistories=7,samples=500,sampleSeed=113,leanTheorems=len(lemmas),allStepInduction=True,priorGlobalReadinessComposition=True,projectionControls=len(controls),negativeLeanControls=1,ascentScenarios=len(cases),actualCandidate=False,sourceAliasClosure=False,allOriginProductRefinement=False,nativeC11Refinement=False,totalFallbackProved=False,nativeTestsRun=False,performanceTestsRun=False,liveSourceDrift=[f for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']])
 save(CACHE/'checks.json',checks)
 own=[MODEL,DESIGN,MATRIX,D2,D2[:-3]+'.svg',RULES,EMITTER,'dev/modeling/tools/'+STEM+'-study.py',qnt]+[BASE+'models/lean/'+n+'.lean' for n in ['GlobalUnloadAst','GlobalUnload','GlobalUnloadComposition']]
 own += [BASE+'index.org','dev/modeling/tools/advantage-architecture-study.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/chunk-capacity-charge-projection.py']
 own+=imported+[v['path'] for v in snapshots.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentDigest,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snapshots,sysmlInputs=scope,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
