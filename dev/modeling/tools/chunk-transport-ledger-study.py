#!/usr/bin/env python3
"""Formal research pipeline only; native SysML, ASCENT, QNT and Lean."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='chunk-transport-ledger';BASE='dev/refactoring/modern-c/';PKG='GambitChunkTransportLedger'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/chunk_marker_transport.qnt'
LEAN=BASE+'models/lean/MarkerTransport.lean';AST=BASE+'models/lean/MarkerTransportAst.lean'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 sp=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);return m
h=load('research_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[['source', 21, 'key path needle obligation'], ['option', 2, 'key representation accessRule reuse cost mechanism decision'], ['trace', 7, 'key operationText consequence gap'], ['contract', 17, 'fromNode toNode custody'], ['obligation', 10, 'key status scope gap'], ['gain', 8, 'key avoided added condition'], ['binding', 30, 'actionName lemma scope'], ['refinement', 18, 'actionName targetStep lemma'], ['composition', 14, 'key lemma scope'], ['access', 8, 'key source.key callerName accessMode lane lock scope'], ['seam', 4, 'producer.moduleId consumer.moduleId contract modelNeed']]
def project():
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [('need',n,f,f'{PKG}::{n}.{f}') for n in ['frameHistory','weakHistory','frameInduction','weakInduction','compositionProof','projection','source','platform'] for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
 scope={p:sha(ROOT/p) for p in sorted(run('sysml-inputs',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines())}
 save(CACHE/'sysml-input-scope.json',scope);args=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:args+=['-e',expr]
 raw=json.loads(run('sysml',args+['dev']));assert raw['exit']==0 and not raw.get('errors'),raw
 vals=[json.loads(x[4:]) for x in raw['output'] if x.startswith('  = ')];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/'projection.json',p);return p,scope
def views(p):
 def cell(v):return str(v).replace('\n',r'\n').replace('|',r'\vert{}')
 lines=['#+TITLE: Chunk Transport and Unified Work Custody — Closure and Net Benefit Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitChunkTransportLedger',':STATUS: conditional-model-induction; source-schedule-and-c11-open',':END:']
 for g,_,fields in GROUPS:
  fs=fields.split();lines+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
  lines+=['| '+' | '.join(cell(v[f]) for f in fs)+' |' for v in p[g]]
 lines+=['','** Proof routing','','| ID | kind | subject | scope |','|---+---+---+---|']
 lines+=['| '+' | '.join(v[f] for f in ['obligationId','kind','subjectPath','subjectScope'])+' |' for v in p['need'].values()]
 (ROOT/MATRIX).write_text('\n'.join(lines)+'\n')
 width=None
 for line in lines:
  if not line.startswith('|'):width=None;continue
  if set(line)<=set('|-+ '):continue
  n=len(line.split('|'))
  if width is None:width=n
  assert n==width,line
 save(CACHE/'org-table-columns.json',dict(status='pass',embeddedNewlinesEscaped=True,pipeEntitiesEscaped=True))
 graph=['direction: down']
 nodes={v[f] for v in p['contract'] for f in ['fromNode','toNode']}
 for n in sorted(nodes):graph.append(json.dumps(n)+': '+json.dumps(n))
 for v in p['contract']:graph.append(json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(textwrap.fill(v['custody'],22)))
 graph+=['qualification: "Conditional model induction\\nNative allocation / phase / C11 open"']
 (ROOT/D2).write_text('\n'.join(graph)+'\n')
def projection():
 emitter=load('coverage_emitter',EMITTER);receipts={}
 for cfg in emitter.SPECS:
  ir=json.loads((CACHE/(cfg['module']+'.json')).read_text())
  ast,receipt=emitter.generate(ir,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
  path=BASE+'models/lean/'+cfg['namespace']+'.lean';(ROOT/path).write_text(ast)
  receipts[cfg['module']]=dict(**receipt,typedIrSha256=sha(CACHE/(cfg['module']+'.json')),astSha256=sha(ROOT/path),sourceSimulation=False)
  controls={}
  for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
   bad=copy.deepcopy(ir);defs={d['name']:d for d in bad['modules'][0]['declarations']}
   if case=='wrong-state-binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
   if case=='wrong-field-kind':
    field=defs['State']['type']['fields']['fields'][0]['fieldType'];field['kind']='int' if field['kind']=='bool' else 'bool'
   if case=='missing-step':defs['step']['expr']['args'].pop(0)
   if case=='unsupported-expression':defs['safe']['expr']['opcode']='unsupported'
   try:emitter.generate(bad,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
   except (AssertionError,KeyError):controls[case]='rejected'
   else:raise AssertionError('accepted '+case)
  save(CACHE/(cfg['module']+'-projection-controls.json'),controls)
 save(CACHE/'expression-projection.json',receipts);return emitter

def validate_target():
 old=load('old_weak_emitter','dev/modeling/tools/frame-chunk-weak-producers-projection.py');cfg=old.SPECS[1]
 irPath=ROOT/'evidence/research/frame-chunk-weak-producers/weak_producer_admission.json';ir=json.loads(irPath.read_text())
 ast,receipt=old.generate(ir,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
 target=BASE+'models/lean/WeakAdmissionAst.lean';assert ast==(ROOT/target).read_text()
 parent=json.loads((ROOT/'evidence/research/frame-chunk-weak-producers/input.json').read_text())
 for f in [target,BASE+'models/lean/WeakAdmission.lean',BASE+'models/quint/weak_producer_admission.qnt']:
  assert sha(ROOT/f)==parent['sourceBindings'][f],f
 save(CACHE/'target-projection.json',dict(**receipt,typedIrSha256=sha(irPath),targetAstSha256=sha(ROOT/target),targetBoundToParent=True))
 return [[cfg['module']+'.'+x] for x in cfg['actions']+['stutter']]

def access_contexts(p,witness):
 byId={v['key']:v for v in witness};facts=[];audit=[]
 for v in p['access']:
  w=byId[v['source.key']];text=(ROOT/w['snapshotPath']).read_text()
  decls=list(re.finditer(r'^___HIDDEN\s+(?:void|int|___SIZE_TS|___copy_reservation|___WORD\s*\*)\s*(\w+)\s*$',text,re.M))
  expected=v['callerName'].split(' / ');observed=[]
  for hit in re.finditer(re.escape(w['needle']),text):
   owners=[d for d in decls if d.start()<hit.start()]
   if owners:observed.append((owners[-1].group(1),text[:hit.start()].count('\n')+1))
  assert all(any(name==want for name,_ in observed) for want in expected),(v['key'],expected,observed)
  facts.append([v['key'],v['source.key'],w['sha256']])
  audit.append(dict(key=v['key'],expectedCallers=expected,observed=observed,snapshotSha256=w['sha256']))
 save(CACHE/'access-context-audit.json',dict(status='pass',scope='Lexical function context only; not preprocessing or full C alias analysis',rows=audit))
 return facts

def ascend(p,witness,emitter):
 contexts=access_contexts(p,witness);targets=validate_target();needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 actions=[];lemmas=[]
 for cfg in emitter.SPECS:
  ir=json.loads((CACHE/(cfg['module']+'.json')).read_text())
  actions += [[cfg['module']+'.'+d['name']] for d in ir['modules'][0]['declarations'] if d.get('qualifier')=='action']
 for name in [c['proof'] for c in emitter.SPECS]+['TransportComposition']:
  txt=(ROOT/(BASE+'models/lean/'+name+'.lean')).read_text();assert 'namespace '+name in txt
  lemmas += [[name+'.'+x] for x in re.findall(r'^\s*theorem (\w+)',txt,re.M)]
 rows=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witness]
 bindings=[[v['actionName'],v['lemma']] for v in p['binding']]
 refs=[[v['actionName'],v['targetStep'],v['lemma']] for v in p['refinement']]
 accesses=[[v['key'],v['source.key']] for v in p['access']]
 results={};engine=h.Engine()
 cases=['current','synthetic-all','stale-digest','wrong-scope','missing-source','missing-action','wrong-lemma','missing-witness','missing-projection','missing-c11','missing-induction','missing-target','missing-simulation','missing-composition','missing-access','wrong-access-context']
 try:
  session=engine.open_sources((ROOT/RULES).read_text());queries=['checked','blocked','candidate','linked','observed','compositionLinked','refinementLinked','accessLinked'];assert session.run(queries=queries)['complete']
  for case in cases:
   receipts=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction','restricted-projection']]
   if case=='stale-digest':receipts[0][3]='stale'
   if case=='wrong-scope':receipts[0][4]='native-all-paths-closed'
   for label,need in [('missing-source','TL-source'),('missing-projection','TL-projection'),('missing-c11','TL-platform'),('missing-composition','TL-compositionProof')]:
    if case==label:receipts=[v for v in receipts if v[1]!=need]
   ac=[v for v in actions if case!='missing-action' or v!=['delayed_chunk_ledger.publishAccepted']]
   ls=[v for v in lemmas if (case!='wrong-lemma' or v!=['DelayedLedger.publishAcceptedPreserves']) and (case!='missing-induction' or v!=['DelayedLedger.reachableSafe']) and (case!='missing-simulation' or v!=['TransportComposition.publishAcceptedSimulates'])]
   ts=[v for v in targets if case!='missing-target' or v!=['weak_producer_admission.continuationProducer']]
   ws=rows if case!='missing-witness' else rows[1:]
   if case=='missing-access':ws=[v for v in ws if v[0]!='scan-classifier']
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=bindings,actionName=ac,lemmaName=ls,witness=rows,observation=ws,compositionNeed=[[v['key'],v['lemma']] for v in p['composition']],refinementNeed=refs,targetActionName=ts,accessNeed=accesses,accessContext=contexts if case!='wrong-access-context' else [[v[0],v[1],'stale'] if i==0 else v for i,v in enumerate(contexts)]))
   result=session.run(queries=queries);assert result['complete'];results[case]=result['relations']
  save(CACHE/'ascent-attempt-results.json',results)
  assert len(results['current']['checked'])==6 and len(results['current']['linked'])==30 and len(results['current']['compositionLinked'])==14
  assert len(results['current']['refinementLinked'])==18 and len(results['current']['accessLinked'])==8
  assert len(results['synthetic-all']['candidate'])==1
  for case in cases:
   if case!='synthetic-all':assert not results[case]['candidate'],case
  assert ['current','TL-source'] in results['current']['blocked'] and ['current','TL-platform'] in results['current']['blocked']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotRealEvidence=True,sourceQualified=False,c11Qualified=False))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/frame-chunk-weak-producers/input.json';parentHash=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snapshots.items():assert sha(ROOT/v['path'])==v['sha256'],f
 p,scope=project();views(p);witness=[]
 for v in p['source']:
  sv=snapshots[v['path']];text=(ROOT/sv['path']).read_text();assert v['needle'] in text,v['key']
  witness.append(dict(**v,snapshotPath=sv['path'],sha256=sv['sha256'],line=text[:text.index(v['needle'])].count('\n')+1,lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witness)
 run('frame-and-weak-callers',['rg','-n','mark_captured_continuation|publish_object_scan|process_wills|UNMARKED_TESTATOR_WILL|process_gc_hash_tables|scan_ptr =','vendor/gambit/lib/mem.c'])
 emitter=load('coverage_emitter',EMITTER);reuse='--reuse-formal' in sys.argv
 formalFiles=[EMITTER,BASE+'models/lean/TransportComposition.lean',BASE+'models/lean/WeakAdmissionAst.lean',BASE+'models/lean/WeakAdmission.lean',BASE+'models/quint/weak_producer_admission.qnt','dev/modeling/tools/frame-chunk-weak-producers-projection.py']+[BASE+'models/'+suffix for cfg in emitter.SPECS for suffix in ['quint/'+cfg['module']+'.qnt','lean/'+cfg['namespace']+'.lean','lean/'+cfg['proof']+'.lean']]
 if reuse:
  old=json.loads((CACHE/('input.json' if (CACHE/'input.json').exists() else 'formal-checkpoint.json')).read_text())
  for f in formalFiles:assert sha(ROOT/f)==old['sourceBindings'][f],f
  for f,d in old['logs'].items():
   if any(k in f for k in ['quint-','typecheck','MarkerTransport','DelayedLedger','TransportComposition','WeakAdmission','negative-lean']):assert sha(ROOT/f)==d,f
 else:
  for cfg in emitter.SPECS:run(cfg['module']+'-typecheck',['quint','typecheck',BASE+'models/quint/'+cfg['module']+'.qnt','--out',str(CACHE/(cfg['module']+'.json'))])
 emitter=projection()
 if not reuse:
  for name in ['WeakAdmissionAst','WeakAdmission']:
   f=CACHE/(name+'.lean');f.write_bytes((ROOT/(BASE+'models/lean/'+name+'.lean')).read_bytes());run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(f)])
  for cfg,n,neg in zip(emitter.SPECS,[7,8],[4,4],strict=True):
   qnt=BASE+'models/quint/'+cfg['module']+'.qnt';tests=run(cfg['module']+'-quint-tests',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==n and tests.count('ControlTest passed')==neg
   run(cfg['module']+'-quint-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','41','--verbosity','1'])
   for name in [cfg['namespace'],cfg['proof']]:
    src=CACHE/(name+'.lean');src.write_bytes((ROOT/(BASE+'models/lean/'+name+'.lean')).read_bytes());assert 'sorry' not in src.read_text() and 'axiom ' not in src.read_text()
    run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(src)])
   negdir=CACHE/('negative-'+cfg['proof']);negdir.mkdir(exist_ok=True)
   ast=(ROOT/(BASE+'models/lean/'+cfg['namespace']+'.lean')).read_text()
   if cfg['proof']=='MarkerTransport':mutant='\n'.join(line.replace('atomicStorage:=true','atomicStorage:=false') if line.startswith('def chooseAtomicNext') else line for line in ast.splitlines())+'\n'
   else:mutant='\n'.join(line.replace('chunk:=(3)','chunk:=(3),debt:=(q.debt+(1))') if line.startswith('def publishAcceptedNext') else line for line in ast.splitlines())+'\n'
   assert mutant!=ast;(negdir/(cfg['namespace']+'.lean')).write_text(mutant)
   run('negative-lean-'+cfg['proof']+'-ast',['lean','-o',str(negdir/(cfg['namespace']+'.olean')),str(negdir/(cfg['namespace']+'.lean'))])
   try:run('negative-lean-'+cfg['proof']+'-proof',['env','LEAN_PATH='+str(negdir)+':'+str(CACHE),'lean',str(ROOT/(BASE+'models/lean/'+cfg['proof']+'.lean'))])
   except RuntimeError:assert 'error:' in (CACHE/('negative-lean-'+cfg['proof']+'-proof.stdout')).read_text()
   else:raise AssertionError('negative mutation proved '+cfg['proof'])
 if not reuse:
  name='TransportComposition';f=CACHE/(name+'.lean');f.write_bytes((ROOT/(BASE+'models/lean/'+name+'.lean')).read_bytes());assert 'sorry' not in f.read_text() and 'axiom ' not in f.read_text();run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(f)])
  neg=CACHE/'negative-composition';neg.mkdir(exist_ok=True);bad=f.read_text().replace('active:=q.debt,','active:=(q.debt+1),');assert bad!=f.read_text();g=neg/f.name;g.write_text(bad)
  try:run('negative-lean-composition',['env','LEAN_PATH='+str(CACHE),'lean',str(g)])
  except RuntimeError:assert 'error:' in (CACHE/'negative-lean-composition.stdout').read_text()
  else:raise AssertionError('bad projection proved')
 ascend(p,witness,emitter)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f,d in scope.items():assert sha(ROOT/f)==d,f
 for w in witness:assert sha(ROOT/w['snapshotPath'])==w['sha256'],w['path']
 drift=[dict(path=f,analyzed=v['sha256'],live=sha(ROOT/f)) for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']]
 save(CACHE/'live-source-drift.json',dict(drift=drift,nativeAdmission=False,scope='Analyzed immutable snapshots; current source drift never qualifies native behavior'))
 assert sha(parent)==parentHash
 files={MODEL,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',EMITTER,BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py'}|set(formalFiles)|{w['snapshotPath'] for w in witness}
 old=json.loads(parent.read_text());save(CACHE/'predecessor-source-drift.json',dict(parentInputSha256=parentHash,parentFrozen=True,changed=[f for f,d in old['sourceBindings'].items() if not (ROOT/f).is_file() or sha(ROOT/f)!=d]))
 theoremCount=sum(len(re.findall(r'^\s*theorem ',(ROOT/(BASE+'models/lean/'+cfg['proof']+'.lean')).read_text(),re.M)) for cfg in emitter.SPECS)+len(re.findall(r'^\s*theorem ',(ROOT/(BASE+'models/lean/TransportComposition.lean')).read_text(),re.M))
 checks=dict(status='conditional-model-induction-pass',formalChecksReused=reuse,sysmlInputs=len(scope),sourceAnchors=21,qntActions=30,qntHistories=15,negativeQntControls=8,samplesPerModel=500,maxSteps=200,leanTheorems=theoremCount,allStepInduction=True,negativeLeanControls=3,projectionNegativeControls=8,ascentScenarios=16,formalBindings=30,formalCompositionBindings=14,legacySourceSchedule='enabled-under-explicit-premises',actualCandidate=False,sourceQualified=False,c11Refinement=False,parserVerified=False,emitterVerified=False,fullFrameChainRefinement=False,markerAccessModelProved=True,unifiedWorkConservationProved=True,oldWeakStepSimulationProved=True,guardedProductInductionProved=True,allNativeWeakProducersProved=False,crossModelSourceCompositionProved=False,taskRetryDeduplicationProved=False,sharedSentinelC11Proved=False,refinementBindings=18,accessBindings=8,fullHashCleanupRefinement=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[])
 save(CACHE/'checks.json',checks)
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceSnapshots=snapshots,liveSourceDrift=drift,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
