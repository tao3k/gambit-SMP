#!/usr/bin/env python3
"""Design/formal evidence orchestration only. Native SysML owns model metadata."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='chunk-node-pool';BASE='dev/refactoring/modern-c/';PKG='GambitChunkNodePool'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/chunk_node_pool.qnt'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
h=load('study_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[('source',20,'key path needle obligation'),('capacity',5,'key bound premise counterexample status'),('progress',5,'key mechanism condition gap'),('receipt',4,'key issuer prerequisite revocation gap'),('memory',5,'key ordering obligation gap'),('gain',8,'key avoided added condition'),('contract',10,'fromNode toNode custody'),('obligation',7,'key status scope gap'),('binding',17,'actionName lemma targetStep simulation'),('proof',15,'key lemma scope'),('seam',3,'producer.moduleId consumer.moduleId contract modelNeed')]
SLOTS=['history','induction','composition','projection','source','platform']
def project():
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [('need',s,f,f'{PKG}::{s}.{f}') for s in SLOTS for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
 scope={p:sha(ROOT/p) for p in sorted(run('sysml-inputs',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines())};save(CACHE/'sysml-input-scope.json',scope)
 args=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,e in keys:args+=['-e',e]
 raw=json.loads(run('sysml',args+['dev']));assert raw['exit']==0 and not raw.get('errors') and not any(d['severity']=='error' for d in raw.get('diagnostics',[])),raw
 vals=[json.loads(x[4:]) for x in raw['output'] if x.startswith('  = ')];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/'projection.json',p);save(CACHE/'native-queries.json',keys);return p,scope

def views(p):
 def cell(s):return str(s).replace('\n',r'\n').replace('|',r'\vert{}')
 lines=['#+TITLE: Independent Chunk Node Pool — Capacity and Net Benefit Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitChunkNodePool',':STATUS: conditional-formal-model; native-and-C11-open',':END:']
 for g,_,schema in GROUPS:
  fs=schema.split();lines+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
  lines+=['| '+' | '.join(cell(v[f]) for f in fs)+' |' for v in p[g]]
 lines+=['','** Scoped proof routing','','| ID | kind | path | scope |','|---+---+---+---|']
 lines+=['| '+' | '.join(v[f] for f in ['obligationId','kind','subjectPath','subjectScope'])+' |' for v in p['need'].values()]
 (ROOT/MATRIX).write_text('\n'.join(lines)+'\n')
 graph=['direction: down']
 for n in sorted({v[f] for v in p['contract'] for f in ['fromNode','toNode']}):graph+=[json.dumps(n)+': '+json.dumps(n)]
 for v in p['contract']:graph+=[json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(textwrap.fill(v['custody'],24))]
 graph+=['proof: '+json.dumps('SysML -> ASCENT -> QNT / Lean\nConditional model; native / C11 OPEN')]
 (ROOT/D2).write_text('\n'.join(graph)+'\n')

def formals():
 e=load('pool_emitter',EMITTER);ir=json.loads((CACHE/'chunk_node_pool.json').read_text());ast,rc=e.generate(ir)
 (ROOT/(BASE+'models/lean/NodePoolAst.lean')).write_text(ast);save(CACHE/'typed-projection.json',dict(**rc,typedIrSha256=sha(CACHE/'chunk_node_pool.json'),astSha256=sha(ROOT/(BASE+'models/lean/NodePoolAst.lean'))))
 controls={}
 for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if case=='wrong-state-binding':bad['table'][str(rc['stateReferences'][0][0])]['id']=-1
  if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if case=='missing-step':ds['step']['expr']['args'].pop(0)
  if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
  try:e.generate(bad)
  except (AssertionError,KeyError):controls[case]='rejected'
  else:raise AssertionError('projection accepted '+case)
 save(CACHE/'projection-controls.json',controls)
 actions=[[e.SPEC['module']+'.'+x] for x in e.SPEC['actions']]
 imported=['WeakAdmissionAst','WeakAdmission','DelayedLedgerAst','DelayedLedger','MarkerTransportAst','MarkerTransport','TransportComposition']
 files=[EMITTER,'dev/modeling/tools/chunk-transport-ledger-projection.py',QNT]+[BASE+'models/lean/'+n+'.lean' for n in ['NodePoolAst','NodePool','NodePoolComposition']+imported]
 if '--reuse-formal' in sys.argv:
  old=json.loads((CACHE/'formal-checkpoint.json').read_text())
  for f,d in old['sourceBindings'].items():assert sha(ROOT/f)==d,f
  for f,d in old['logs'].items():assert sha(ROOT/f)==d,f
 else:
  tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==10 and tests.count('ControlTest passed')==4
  run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','73','--verbosity','1'])
  for n in ['NodePoolAst','NodePool']+imported+['NodePoolComposition']:
   f=CACHE/(n+'.lean')
   if '--reuse-compiled' in sys.argv:assert f.read_bytes()==(ROOT/(BASE+'models/lean/'+n+'.lean')).read_bytes(),n
   else:f.write_bytes((ROOT/(BASE+'models/lean/'+n+'.lean')).read_bytes())
   assert not re.search(r'\bsorry\b|\baxiom\s',f.read_text())
   if '--reuse-compiled' in sys.argv:
    assert (CACHE/(n+'.olean')).is_file(),n
    assert 'error:' not in (CACHE/(n+'.stdout')).read_text(),n
   else:run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
  neg=CACHE/'negative-reserve';neg.mkdir(exist_ok=True);bad=ast.replace('issued:=(q.issued+(1))','issued:=(q.issued+(2))');assert bad!=ast
  f=neg/'NodePoolAst.lean';f.write_text(bad);run('negative-reserve-ast',['lean','-o',str(neg/'NodePoolAst.olean'),str(f)])
  try:run('negative-reserve-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',str(ROOT/(BASE+'models/lean/NodePool.lean'))])
  except RuntimeError:assert 'error:' in (CACHE/'negative-reserve-proof.stdout').read_text()
  else:raise AssertionError('bad reserve proved')
  neg=CACHE/'negative-composition';neg.mkdir(exist_ok=True);original=(ROOT/(BASE+'models/lean/NodePoolComposition.lean')).read_text();bad=original.replace('active:=q.debt','active:=q.debt+1');assert bad!=original
  f=neg/'NodePoolComposition.lean';f.write_text(bad)
  try:run('negative-composition',['env','LEAN_PATH='+str(CACHE),'lean',str(f)])
  except RuntimeError:assert 'error:' in (CACHE/'negative-composition.stdout').read_text()
  else:raise AssertionError('bad composition proved')
  save(CACHE/'formal-checkpoint.json',dict(sourceBindings={f:sha(ROOT/f) for f in files},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and any(k in f.name for k in ['NodePool','WeakAdmission','DelayedLedger','MarkerTransport','TransportComposition','quint-','negative-'])}))
 # Verify imported AST and proof identities against frozen predecessor input.
 old=json.loads((ROOT/'evidence/research/chunk-transport-ledger/input.json').read_text())
 for n in imported:
  f=BASE+'models/lean/'+n+'.lean';assert sha(ROOT/f)==old['sourceBindings'][f] if f in old['sourceBindings'] else sha(ROOT/f)==json.loads((ROOT/'evidence/research/frame-chunk-weak-producers/input.json').read_text())['sourceBindings'][f]
 target=json.loads((ROOT/'evidence/research/frame-chunk-weak-producers/weak_producer_admission.json').read_text());targets=[[target['modules'][0]['name']+'.'+d['name']] for d in target['modules'][0]['declarations'] if d.get('qualifier')=='action']+[['weak_producer_admission.stutter']]
 lemmas=[]
 for n in ['NodePool','NodePoolComposition']:lemmas += [[n+'.'+x] for x in re.findall(r'^\s*theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
 return e,actions,targets,lemmas,files

def ascend(p,witness,actions,targets,lemmas):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 binds=[[v['actionName'],v['lemma']] for v in p['binding']];refs=[[v['actionName'],v['targetStep'],v['simulation']] for v in p['binding']]
 ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witness];cs=[[v['key'],v['lemma']] for v in p['proof']]
 queries=['checked','blocked','candidate','linked','observed','compositionLinked','refinementLinked'];cases=['current','synthetic-all','stale-hash','wrong-scope','missing-source','missing-platform','missing-action','missing-lemma','missing-target','missing-simulation','missing-witness','missing-capacity-proof','missing-induction']
 engine=h.Engine();results={}
 try:
  ss=engine.open_sources((ROOT/RULES).read_text());assert ss.run(queries=queries)['complete']
  for c in cases:
   rc=[[c,n,path,d,scope] for n,k,path,d,scope in needs if c!='current' or k in ['interleaving','induction','restricted-projection']]
   if c=='stale-hash':rc[0][3]='stale'
   if c=='wrong-scope':rc[0][4]='wider-native-scope'
   for case,need in [('missing-source','NP-source'),('missing-platform','NP-platform'),('missing-induction','NP-induction')]:
    if c==case:rc=[v for v in rc if v[1]!=need]
   ac=[v for v in actions if c!='missing-action' or v!=['chunk_node_pool.reserve']]
   ls=[v for v in lemmas if (c!='missing-lemma' or v!=['NodePool.reservePreserves']) and (c!='missing-simulation' or v!=['NodePoolComposition.reserveSimulates']) and (c!='missing-capacity-proof' or v!=['NodePool.permittedReserveHasSpace'])]
   ts=[v for v in targets if c!='missing-target' or v!=['weak_producer_admission.deriveChild']]
   ss.replace(dict(scenario=[[c]],need=needs,receipt=rc,binding=binds,actionName=ac,lemmaName=ls,witness=ws,observation=ws[1:] if c=='missing-witness' else ws,compositionNeed=cs,refinementNeed=refs,targetActionName=ts))
   res=ss.run(queries=queries);assert res['complete'];results[c]=res['relations']
  assert len(results['synthetic-all']['candidate'])==1
  for c in cases:
   if c!='synthetic-all':assert not results[c]['candidate'],c
  assert {v[1] for v in results['current']['blocked']}=={'NP-source','NP-platform'}
  assert len(results['current']['refinementLinked'])==17 and len(results['current']['linked'])==17 and len(results['current']['compositionLinked'])==15
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/chunk-transport-ledger/input.json';parentHash=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snapshots.items():assert sha(ROOT/v['path'])==v['sha256']
 p,scope=project();views(p);w=[]
 for v in p['source']:
  sv=snapshots[v['path']];t=(ROOT/sv['path']).read_text();assert v['needle'] in t,v['key'];w.append(dict(**v,snapshotPath=sv['path'],sha256=sv['sha256'],lines=[t[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),t)]))
 save(CACHE/'source-witnesses.json',w);save(OUT/'source-witnesses.json',w)
 if '--reuse-formal' not in sys.argv:run('typecheck',['quint','typecheck',QNT,'--out',str(CACHE/'chunk_node_pool.json')])
 e,ac,ts,ls,formalFiles=formals();ascend(p,w,ac,ts,ls)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 # The shared index can have incomplete concurrent study links; report them separately.
 org=org.replace('(missing nil))','(missing nil) (external-missing nil))')
 org=org.replace('(unless (file-exists-p target) (push (list file target) missing))','(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "chunk[-_]node[-_]pool\\\\|NodePool" target))) (push (list file target) external-missing) (push (list file target) missing)))')
 org=org.replace('missing=%S; no Babel executed" (length files) links missing','missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
 save(OUT/'input.json',dict(status='validation-in-progress',sourceSnapshots=snapshots,sourceWitnessesSha256=sha(CACHE/'source-witnesses.json'),parentInputSha256=parentHash))
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 assert sha(parent)==parentHash
 # Whole-scope validation receipt stays bound to its checked digests amid concurrent edits.
 scopeDrift=[dict(path=f,checked=d,live=sha(ROOT/f)) for f,d in scope.items() if sha(ROOT/f)!=d]
 drift=[dict(path=f,analyzed=v['sha256'],live=sha(ROOT/f)) for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']]
 checks=dict(status='conditional-pool-model-induction-pass',sourceAnchors=len(w),sysmlInputs=len(scope),qntActions=len(ac),qntHistories=10,negativeQntControls=4,samples=500,maxSteps=200,leanTheorems=len(ls),allStepInduction=True,weakStepSimulations=17,compositionProofs=15,projectionControls=4,negativeLeanControls=2,ascentScenarios=13,actualCandidate=False,sourceQualified=False,c11Refinement=False,sourceCapacityInjection=False,sourceProducerClosure=False,sourceReclaimIssuer=False,fairnessProved=False,parserVerified=False,emitterVerified=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[],liveSourceDrift=drift,concurrentScopeDrift=scopeDrift)
 save(CACHE/'checks.json',checks)
 files=set(formalFiles)|{MODEL,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py'}|{v['path'] for v in snapshots.values()}
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceSnapshots=snapshots,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name not in ['artifacts.json','final-audit.json']})
 print(json.dumps(checks))
if __name__=='__main__':main()
