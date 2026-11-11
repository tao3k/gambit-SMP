#!/usr/bin/env python3
"""Formal research pipeline only; native SysML, ASCENT, QNT and Lean."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='object-scan-custody';BASE='dev/refactoring/modern-c/';PKG='GambitObjectScanCustody'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/object_scan_custody.qnt'
LEAN=BASE+'models/lean/ObjectScanCustody.lean';AST=BASE+'models/lean/ObjectScanAst.lean'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 sp=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);return m
h=load('research_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[('source',19,'key path needle obligation'),('contract',14,'fromNode toNode custody c11 premise'),('obligation',9,'key status scope'),('gain',7,'key avoided added condition'),('binding',20,'actionName lemma scope'),('composition',3,'key lemma scope'),('seam',4,'producer.moduleId consumer.moduleId contract modelNeed')]
def project():
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [('need',n,f,f'{PKG}::{n}.{f}') for n in ['history','induction','projection','source','platform'] for f in ['obligationId','kind','subjectPath','subjectScope']]
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
 lines=['#+TITLE: Object Scan Custody — Closure and Net Benefit Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitObjectScanCustody',':STATUS: abstract-induction-closed; source-and-c11-open',':END:']
 for g,_,fields in GROUPS:
  fs=fields.split();lines+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']
  lines+=['| '+' | '.join(v[f] for f in fs)+' |' for v in p[g]]
 lines+=['','** Proof routing','','| ID | kind | subject | scope |','|---+---+---+---|']
 lines+=['| '+' | '.join(v[f] for f in ['obligationId','kind','subjectPath','subjectScope'])+' |' for v in p['need'].values()]
 (ROOT/MATRIX).write_text('\n'.join(lines)+'\n')
 graph=['direction: down']
 nodes={v[f] for v in p['contract'] for f in ['fromNode','toNode']}
 for n in sorted(nodes):graph.append(json.dumps(n)+': '+json.dumps(n))
 for v in p['contract']:graph.append(json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(textwrap.fill(v['custody'],22)))
 graph+=['qualification: "Abstract induction closed\\nFrame fixups / C11 / epochs open"']
 (ROOT/D2).write_text('\n'.join(graph)+'\n')
def projection():
 emitter=load('scan_emitter',EMITTER);ir=json.loads((CACHE/'typed-ir.json').read_text())
 ast,receipt=emitter.generate(ir);(ROOT/AST).write_text(ast)
 save(CACHE/'expression-projection.json',dict(**receipt,typedIrSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(ROOT/AST),sourceSimulation=False))
 controls={}
 for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
  bad=copy.deepcopy(ir);ds=bad['modules'][0]['declarations'];defs={d['name']:d for d in ds}
  if case=='wrong-state-binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
  if case=='wrong-field-kind':defs['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if case=='missing-step':defs['step']['expr']['args'].pop(0)
  if case=='unsupported-expression':defs['safe']['expr']['opcode']='unsupported'
  try:emitter.generate(bad)
  except (AssertionError,KeyError):controls[case]='rejected'
  else:raise AssertionError('accepted '+case)
 save(CACHE/'projection-negative-controls.json',controls);return emitter,ast
def ascend(p,witness):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 bindings=[[v['actionName'],v['lemma']] for v in p['binding']]
 actions=[[x] for x in re.findall(r'^ action (\w+)',(ROOT/QNT).read_text(),re.M)]
 lemmas=[[x] for x in re.findall(r'^theorem (\w+)',(ROOT/LEAN).read_text(),re.M)]
 rows=[[v['key'],v['path'],v['sha256'],v['needle']] for v in witness];assert len({x[0] for x in rows})==len(rows)
 results={};engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/RULES).read_text());queries=['checked','blocked','candidate','linked','observed','compositionLinked'];assert session.run(queries=queries)['complete']
  for case in ['current','synthetic-all','stale-digest','wrong-scope','missing-source','missing-action','wrong-lemma','missing-witness','missing-projection','missing-c11','missing-induction']:
   receipts=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction','restricted-projection']]
   if case=='stale-digest':receipts[0][3]='stale'
   if case=='wrong-scope':receipts[0][4]='all-native-termination'
   for label,need in [('missing-source','OSC-source'),('missing-projection','OSC-projection'),('missing-c11','OSC-platform')]:
    if case==label:receipts=[v for v in receipts if v[1]!=need]
   ac=[x for x in actions if case!='missing-action' or x!=['own1']]
   ls=[x for x in lemmas if (case!='wrong-lemma' or x!=['own1Preserves']) and (case!='missing-induction' or x!=['reachableSafe'])]
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=bindings,actionName=ac,lemmaName=ls,witness=rows,observation=rows if case!='missing-witness' else rows[1:],compositionNeed=[[v['key'],v['lemma']] for v in p['composition']]))
   result=session.run(queries=queries);assert result['complete'];results[case]=result['relations']
  save(CACHE/'ascent-attempt-results.json',results)
  assert len(results['current']['checked'])==3 and len(results['current']['linked'])==20 and len(results['current']['compositionLinked'])==3
  assert len(results['synthetic-all']['candidate'])==1
  for case in results:
   if case!='synthetic-all':assert not results[case]['candidate'],case
  assert ['current','OSC-source'] in results['current']['blocked'] and ['current','OSC-platform'] in results['current']['blocked']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotRealEvidence=True,sourceQualified=False,c11Qualified=False))
def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/root-producer-closure/input.json';parentHash=sha(parent)
 p,scope=project();views(p);witness=[]
 for v in p['source']:
  text=(ROOT/v['path']).read_text();assert v['needle'] in text,v['key']
  witness.append(dict(**v,sha256=sha(ROOT/v['path']),line=text[:text.index(v['needle'])].count('\n')+1))
 save(CACHE/'source-witnesses.json',witness)
 run('publisher-callers',['rg','-n','publish_object_scan|GC_SCAN_|scan_workers_count|scan_and_advance','vendor/gambit/lib/mem.c'])
 run('atomics-and-trailer',['rg','-n','___COMPARE_AND_SWAP_WORD|msection_scan_words|sizeof_msection','vendor/gambit/include/gambit.h.in'])
 reuse='--reuse-formal' in sys.argv
 if reuse:
  old=json.loads((CACHE/'input.json').read_text())
  for f in [QNT,LEAN,AST,EMITTER]:assert sha(ROOT/f)==old['sourceBindings'][f],f
  for f,d in old['logs'].items():
   if any(k in f for k in ['quint-','typecheck.','ObjectScan','negative-lean']):assert sha(ROOT/f)==d,f
 else:run('typecheck',['quint','typecheck',QNT,'--out',str(CACHE/'typed-ir.json')])
 emitter,ast=projection()
 if not reuse:
  tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==12 and tests.count('ControlTest passed')==7
  run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','1000','--max-steps','200','--seed','41','--verbosity','1'])
  for name,path in [('ObjectScanAst',AST),('ObjectScanCustody',LEAN)]:
   src=CACHE/(name+'.lean');src.write_bytes((ROOT/path).read_bytes());assert 'sorry' not in src.read_text() and 'axiom ' not in src.read_text()
   run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(src)])
  neg=CACHE/'negative';neg.mkdir(exist_ok=True)
  mutant='\n'.join(line.replace('(¬(q.child1=true))','True') if line.startswith('def idle1Guard') else line for line in ast.splitlines())+'\n';assert mutant!=ast
  (neg/'ObjectScanAst.lean').write_text(mutant)
  run('negative-lean-ast',['lean','-o',str(neg/'ObjectScanAst.olean'),str(neg/'ObjectScanAst.lean')])
  try:run('negative-lean-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',str(ROOT/LEAN)])
  except RuntimeError:assert 'error:' in (CACHE/'negative-lean-proof.stdout').read_text()
  else:raise AssertionError('missing child debt guard was proved')
 ascend(p,witness)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f,d in scope.items():assert sha(ROOT/f)==d,f
 for w in witness:assert sha(ROOT/w['path'])==w['sha256'],w['path']
 assert sha(parent)==parentHash
 files={MODEL,QNT,LEAN,AST,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',EMITTER,BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py'}|{w['path'] for w in witness}
 lean=(ROOT/LEAN).read_text();old=json.loads(parent.read_text())
 save(CACHE/'predecessor-source-drift.json',dict(parentInputSha256=parentHash,parentFrozen=True,changed=[f for f,d in old['sourceBindings'].items() if not (ROOT/f).is_file() or sha(ROOT/f)!=d]))
 checks=dict(status='abstract-model-induction-pass',formalChecksReused=reuse,sysmlInputs=len(scope),sourceAnchors=19,qntActions=len(emitter.ACTIONS),qntHistories=12,negativeQntControls=7,samples=1000,maxSteps=200,leanTheorems=len(re.findall(r'^theorem ',lean,re.M)),allStepInduction=True,negativeLeanControls=1,projectionNegativeControls=4,ascentScenarios=11,actualCandidate=False,sourceQualified=False,c11Refinement=False,parserVerified=False,emitterVerified=False,arbitraryTaskRefinement=False,epochRefinement=False,phaseFootprintRefinement=False,frameFixupRefinement=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[])
 save(CACHE/'checks.json',checks)
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
