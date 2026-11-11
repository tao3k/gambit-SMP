#!/usr/bin/env python3
"""Native SysML + source/formal research. Never builds or runs Gambit."""
import copy,importlib.util,json,re,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='frame-seal-root-scope';BASE='dev/refactoring/modern-c/';PKG='GambitFrameSealRootScope'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org'
D2=BASE+'diagrams/'+STEM+'.d2';RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
GROUPS=[['source',32,'key path needle obligation'],['alias',8,'key writer custody gap'],['claim',5,'key mechanism condition result gap'],['memory',5,'key publication consumer gap'],['gain',6,'key avoided added condition'],['contract',12,'fromNode toNode custody'],['binding',20,'actionName lemma scope'],['proof',11,'key lemma'],['seam',3,'producer.componentId consumer.componentId contract actionName lemma']]
SLOTS=['history','induction','composition','projection','source','platform']
def load(name,path):
 s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
h=load('frame_root_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/copy-producer-envelope/input.json';parentDigest=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for v in snapshots.values():assert sha(ROOT/v['path'])==v['sha256']
 adapter=load('frame_root_queries','dev/modeling/tools/default-lease-admission-study.py')
 for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=GROUPS,SLOTS=SLOTS).items():setattr(adapter,k,v)
 adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
 p,scope=adapter.project()
 view=load('frame_root_views','dev/modeling/tools/copy-producer-envelope-study.py')
 for k,v in dict(ROOT=ROOT,GROUPS=GROUPS,MATRIX=MATRIX,D2=D2).items():setattr(view,k,v)
 view.views(p)
 f=ROOT/MATRIX;f.write_text(f.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Private Frame Plan and Resize Root Scope Matrix').replace('GambitCopyProducerEnvelope',PKG))
 witnesses=[]
 for v in p['source']:
  snap=snapshots[v['path']];text=(ROOT/snap['path']).read_text();assert v['needle'] in text,v['key']
  witnesses.append(dict(**v,snapshotPath=snap['path'],sha256=snap['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(OUT/'source-witnesses.json',witnesses)

 # Bounded lexical inventory, including every direct assignment under the known aliases.
 inventories=[]
 for key,path,pattern,count in [
  ('source-thunk-stores','vendor/gambit/lib/setup.c',r'source->thunk\s*=(?!=)',2),
  ('ledger-thunk-stores','vendor/gambit/lib/setup.c',r'r->thunk\s*=(?!=)',2),
  ('setup-source-store','vendor/gambit/lib/setup.c',r'___vms->resize_requests\[i\]\.thunk\s*=(?!=)',1),
  ('setup-ledger-store','vendor/gambit/lib/setup.c',r'___vms->resize\.thunk\s*=(?!=)',1),
  ('return-wrappers','vendor/gambit/gsc/_t-c-2.scm',r"\(targ-make-frame-spec '(?:normal|task|internal)",3),
  ('label-payload-replacements','vendor/gambit/gsc/_t-c-2.scm',r'\(vector-set! lbl-struct [23] ',2)]:
  snapshot=snapshots[path];text=(ROOT/snapshot['path']).read_text();hits=list(re.finditer(pattern,text));assert len(hits)==count,key
  inventories.append(dict(key=key,path=path,sha256=snapshot['sha256'],count=count,lines=[text[:h.start()].count('\n')+1 for h in hits],scope='Bounded lexical aliases only; no preprocessor or whole-program alias proof'))
 save(OUT/'writer-inventory.json',inventories)

 emitter=load('frame_root_projection',EMITTER);cfg=emitter.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 run('qnt-typecheck',['quint','typecheck',qnt,'--out',str(CACHE/(cfg['module']+'.json'))])
 ir=json.loads((CACHE/(cfg['module']+'.json')).read_text());ast,rc=emitter.generate(ir)
 (ROOT/(BASE+'models/lean/FrameSealRootAst.lean')).write_text(ast)
 save(CACHE/'projection-receipt.json',dict(**rc,irSha256=sha(CACHE/(cfg['module']+'.json')),astSha256=sha(ROOT/(BASE+'models/lean/FrameSealRootAst.lean'))))
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
 prior=json.loads(parent.read_text());oldCache=ROOT/'.cache/tasks/copy-producer-envelope'
 imported=[]
 for f,d in prior['sourceBindings'].items():
  if '/models/lean/' not in f:continue
  assert sha(ROOT/f)==d,f
  n=Path(f).name;cached=oldCache/n;obj=cached.with_suffix('.olean')
  assert cached.read_bytes()==(ROOT/f).read_bytes() and obj.is_file(),n
  shutil.copyfile(cached,CACHE/n);shutil.copyfile(obj,CACHE/obj.name);imported.append(f)
 save(CACHE/'imported-proof-bindings.json',{f:sha(ROOT/f) for f in imported})
 for n in ['FrameSealRootAst','FrameSealRoot','FrameRootComposition']:
  original=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',original.read_text())
  f=CACHE/(n+'.lean');f.write_bytes(original.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
 tests=run('qnt-histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==13 and tests.count('ControlTest passed')==5
 run('qnt-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','107','--verbosity','1'])
 neg=CACHE/'negative-issue';neg.mkdir(exist_ok=True)
 bad='\n'.join(l.replace('(q.covered=true)','True') if l.startswith('def issueGuard') else l for l in ast.splitlines())+'\n';assert bad!=ast
 (neg/'FrameSealRootAst.lean').write_text(bad)
 run('negative-ast',['lean','-o',str(neg/'FrameSealRootAst.olean'),str(neg/'FrameSealRootAst.lean')])
 try:run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/FrameSealRoot.lean'])
 except RuntimeError:assert 'error' in (CACHE/'negative-proof.stdout').read_text()
 else:raise AssertionError('mutant proof accepted')
 actions=[['frame_seal_root_scope.'+a] for a in cfg['actions']]
 lemmas=[[n+'.'+v] for n in ['FrameSealRoot','FrameRootComposition'] for v in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witnesses]
 bridges=[['source-cover-parent',str(parent.relative_to(ROOT)),parentDigest,'FrameRootComposition.sourceBudgetFromReceipt']]
 cases=['current','synthetic-all','stale-digest','wrong-scope','missing-action','missing-proof','missing-anchor','wrong-parent','missing-seam']
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
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if case!='missing-proof' or v!=['FrameRootComposition.sourceBudgetFromReceipt']],witness=ws,observation=ws[1:] if case=='missing-anchor' else ws,compositionNeed=[[v['key'],v['lemma']] for v in p['proof']],refinementNeed=[],targetActionName=[],bridgeNeed=bridges,bridgeObservation=bridge,inventoryNeed=[],inventoryObservation=[],seamNeed=seams,seamObservation=seams[1:] if case=='missing-seam' else seams))
   result=session.run(queries=['blocked','candidate','linked','compositionLinked','observed','bridgeLinked','seamLinked']);assert result['complete'];results[case]=result['relations']
  assert {v[1] for v in results['current']['blocked']}=={'FS-source','FS-platform'}
  assert [len(results['current'][k]) for k in ['linked','compositionLinked','observed','bridgeLinked']]==[20,11,32,1]
  assert len(results['current']['seamLinked'])==3
  assert [c for c in cases if results[c]['candidate']]==['synthetic-all']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 checks=dict(status='conditional-formal-pass',sourceSnapshots=len(snapshots),sourceAnchors=len(witnesses),qntActions=len(actions),qntHistories=13,negativeHistories=5,samples=500,sampleSeed=107,leanTheorems=len(lemmas),allStepInduction=True,priorSourceCoverComposition=True,projectionControls=len(controls),negativeLeanControls=1,ascentScenarios=len(cases),actualCandidate=False,sourceAliasClosure=False,allOriginProductRefinement=False,nativeC11Refinement=False,totalFallbackProved=False,nativeTestsRun=False,performanceTestsRun=False,liveSourceDrift=[f for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']])
 save(CACHE/'checks.json',checks)
 own=[MODEL,DESIGN,MATRIX,D2,D2[:-3]+'.svg',RULES,EMITTER,'dev/modeling/tools/'+STEM+'-study.py',qnt]+[BASE+'models/lean/'+n+'.lean' for n in ['FrameSealRootAst','FrameSealRoot','FrameRootComposition']]
 own+=imported+[v['path'] for v in snapshots.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentDigest,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snapshots,sysmlInputs=scope,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
