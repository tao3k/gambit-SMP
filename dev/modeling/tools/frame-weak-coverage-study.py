#!/usr/bin/env python3
"""Formal research pipeline only; native SysML, ASCENT, QNT and Lean."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='frame-weak-coverage';BASE='dev/refactoring/modern-c/';PKG='GambitFrameWeakCoverage'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/frame_publish_seal.qnt'
LEAN=BASE+'models/lean/FrameSeal.lean';AST=BASE+'models/lean/FrameSealAst.lean'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 sp=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);return m
h=load('research_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[('source',24,'key path needle obligation'),('footprint',8,'key required reuse premise'),('contract',12,'fromNode toNode custody'),('obligation',8,'key status scope gap'),('gain',5,'key avoided added condition'),('binding',33,'actionName lemma scope'),('composition',7,'key lemma scope'),('seam',4,'producer.moduleId consumer.moduleId contract modelNeed')]
def project():
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [('need',n,f,f'{PKG}::{n}.{f}') for n in ['frameHistory','weakHistory','frameInduction','weakInduction','projection','source','platform'] for f in ['obligationId','kind','subjectPath','subjectScope']]
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
 lines=['#+TITLE: Frame Publication and Weak Coverage — Closure and Net Benefit Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitObjectScanCustody',':STATUS: conditional-model-induction; source-schedule-and-c11-open',':END:']
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
 graph+=['qualification: "Conditional model induction\\nNative frame chain / C11 open"']
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

def ascend(p,witness,emitter):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 bindings=[[v['actionName'],v['lemma']] for v in p['binding']]
 actions=[];lemmas=[]
 for cfg in emitter.SPECS:
  ir=json.loads((CACHE/(cfg['module']+'.json')).read_text())
  actions += [[cfg['module']+'.'+d['name']] for d in ir['modules'][0]['declarations'] if d.get('qualifier')=='action']
  proof=(ROOT/(BASE+'models/lean/'+cfg['proof']+'.lean')).read_text();assert 'namespace '+cfg['proof'] in proof
  lemmas += [[cfg['proof']+'.'+x] for x in re.findall(r'^\s*theorem (\w+)',proof,re.M)]
 rows=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witness];assert len({x[0] for x in rows})==len(rows)
 results={};engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/RULES).read_text());queries=['checked','blocked','candidate','linked','observed','compositionLinked'];assert session.run(queries=queries)['complete']
  for case in ['current','synthetic-all','stale-digest','wrong-scope','missing-source','missing-action','wrong-lemma','missing-witness','missing-projection','missing-c11','missing-induction']:
   receipts=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction','restricted-projection']]
   if case=='stale-digest':receipts[0][3]='stale'
   if case=='wrong-scope':receipts[0][4]='native-all-paths-closed'
   for label,need in [('missing-source','FW-source'),('missing-projection','FW-projection'),('missing-c11','FW-platform')]:
    if case==label:receipts=[v for v in receipts if v[1]!=need]
   ac=[x for x in actions if case!='missing-action' or x!=['weak_done_coverage.repairWill']]
   ls=[x for x in lemmas if (case!='wrong-lemma' or x!=['WeakCoverage.repairWillPreserves']) and (case!='missing-induction' or x!=['FrameSeal.reachableSafe'])]
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=bindings,actionName=ac,lemmaName=ls,witness=rows,observation=rows if case!='missing-witness' else rows[1:],compositionNeed=[[v['key'],v['lemma']] for v in p['composition']]))
   result=session.run(queries=queries);assert result['complete'];results[case]=result['relations']
  save(CACHE/'ascent-attempt-results.json',results)
  assert len(results['current']['checked'])==5 and len(results['current']['linked'])==33 and len(results['current']['compositionLinked'])==7
  assert len(results['synthetic-all']['candidate'])==1
  for case in results:
   if case!='synthetic-all':assert not results[case]['candidate'],case
  assert ['current','FW-source'] in results['current']['blocked'] and ['current','FW-platform'] in results['current']['blocked']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotRealEvidence=True,sourceQualified=False,c11Qualified=False))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/object-scan-custody/input.json';parentHash=sha(parent)
 p,scope=project();views(p);witness=[]
 for v in p['source']:
  text=(ROOT/v['path']).read_text();assert v['needle'] in text,v['key']
  witness.append(dict(**v,sha256=sha(ROOT/v['path']),line=text[:text.index(v['needle'])].count('\n')+1))
 save(CACHE/'source-witnesses.json',witness)
 run('frame-and-weak-callers',['rg','-n','mark_captured_continuation|publish_object_scan|process_wills|UNMARKED_TESTATOR_WILL|process_gc_hash_tables|scan_ptr =','vendor/gambit/lib/mem.c'])
 emitter=load('coverage_emitter',EMITTER);reuse='--reuse-formal' in sys.argv
 formalFiles=[EMITTER]+[BASE+'models/'+suffix for cfg in emitter.SPECS for suffix in ['quint/'+cfg['module']+'.qnt','lean/'+cfg['namespace']+'.lean','lean/'+cfg['proof']+'.lean']]
 if reuse:
  old=json.loads((CACHE/'input.json').read_text())
  for f in formalFiles:assert sha(ROOT/f)==old['sourceBindings'][f],f
  for f,d in old['logs'].items():
   if any(k in f for k in ['quint-','typecheck','FrameSeal','WeakCoverage','negative-lean']):assert sha(ROOT/f)==d,f
 else:
  for cfg in emitter.SPECS:run(cfg['module']+'-typecheck',['quint','typecheck',BASE+'models/quint/'+cfg['module']+'.qnt','--out',str(CACHE/(cfg['module']+'.json'))])
 emitter=projection()
 if not reuse:
  for cfg,n,neg in zip(emitter.SPECS,[8,10],[3,3],strict=True):
   qnt=BASE+'models/quint/'+cfg['module']+'.qnt';tests=run(cfg['module']+'-quint-tests',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==n and tests.count('ControlTest passed')==neg
   run(cfg['module']+'-quint-samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','41','--verbosity','1'])
   for name in [cfg['namespace'],cfg['proof']]:
    src=CACHE/(name+'.lean');src.write_bytes((ROOT/(BASE+'models/lean/'+name+'.lean')).read_bytes());assert 'sorry' not in src.read_text() and 'axiom ' not in src.read_text()
    run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(src)])
   negdir=CACHE/('negative-'+cfg['proof']);negdir.mkdir(exist_ok=True)
   ast=(ROOT/(BASE+'models/lean/'+cfg['namespace']+'.lean')).read_text()
   if cfg['proof']=='FrameSeal':mutant='\n'.join(line.replace('deferred:=true','deferred:=true,copier:=false') if line.startswith('def deferChunkNext') else line for line in ast.splitlines())+'\n'
   else:mutant='\n'.join(line.replace('testatorSeen:=true','testatorSeen:=false') if line.startswith('def repairWillNext') else line for line in ast.splitlines())+'\n'
   assert mutant!=ast;(negdir/(cfg['namespace']+'.lean')).write_text(mutant)
   run('negative-lean-'+cfg['proof']+'-ast',['lean','-o',str(negdir/(cfg['namespace']+'.olean')),str(negdir/(cfg['namespace']+'.lean'))])
   try:run('negative-lean-'+cfg['proof']+'-proof',['env','LEAN_PATH='+str(negdir)+':'+str(CACHE),'lean',str(ROOT/(BASE+'models/lean/'+cfg['proof']+'.lean'))])
   except RuntimeError:assert 'error:' in (CACHE/('negative-lean-'+cfg['proof']+'-proof.stdout')).read_text()
   else:raise AssertionError('negative mutation proved '+cfg['proof'])
 ascend(p,witness,emitter)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f,d in scope.items():assert sha(ROOT/f)==d,f
 for w in witness:assert sha(ROOT/w['path'])==w['sha256'],w['path']
 assert sha(parent)==parentHash
 files={MODEL,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',EMITTER,BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py'}|set(formalFiles)|{w['path'] for w in witness}
 old=json.loads(parent.read_text());save(CACHE/'predecessor-source-drift.json',dict(parentInputSha256=parentHash,parentFrozen=True,changed=[f for f,d in old['sourceBindings'].items() if not (ROOT/f).is_file() or sha(ROOT/f)!=d]))
 theoremCount=sum(len(re.findall(r'^\s*theorem ',(ROOT/(BASE+'models/lean/'+cfg['proof']+'.lean')).read_text(),re.M)) for cfg in emitter.SPECS)
 checks=dict(status='conditional-model-induction-pass',formalChecksReused=reuse,sysmlInputs=len(scope),sourceAnchors=24,qntActions=33,qntHistories=18,negativeQntControls=6,samplesPerModel=500,maxSteps=200,leanTheorems=theoremCount,allStepInduction=True,negativeLeanControls=2,projectionNegativeControls=8,ascentScenarios=11,formalBindings=33,formalCompositionBindings=7,legacySourceSchedule='enabled-under-explicit-premises',actualCandidate=False,sourceQualified=False,c11Refinement=False,parserVerified=False,emitterVerified=False,fullFrameChainRefinement=False,globalWillDecisionProved=False,fullHashCleanupRefinement=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[])
 save(CACHE/'checks.json',checks)
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
