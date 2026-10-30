#!/usr/bin/env python3
"""Formal/source research only. Native SysML owns architecture and proof metadata."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='chunk-capacity-charge';BASE='dev/refactoring/modern-c/';PKG='GambitChunkCapacityCharge'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/chunk_capacity_charge.qnt'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
h=load('research_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[('source',24,'key path needle obligation'),('call',9,'key callerName callee siteCount effect'),('charge',7,'key mechanism bound excluded status'),('receipt',5,'key issuer condition failure gap'),('memory',5,'key ordering obligation gap'),('gain',6,'key avoided added condition'),('contract',11,'fromNode toNode custody'),('obligation',6,'key status scope gap'),('binding',12,'actionName lemma targetStep simulation'),('proof',12,'key lemma scope'),('seam',3,'producer.moduleId consumer.moduleId contract modelNeed')]
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
 lines=['#+TITLE: Chunk Capacity Charges — Source Closure and Net Benefit Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitChunkCapacityCharge',':STATUS: conditional-formal-model; native-and-C11-open',':END:']
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

def caller_audit(p,snapshots):
 sv=snapshots['vendor/gambit/lib/mem.c'];text=(ROOT/sv['path']).read_text()
 # Lexical masking preserves source offsets; no claim of full C parsing.
 mask=re.compile(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',re.S)
 clean=mask.sub(lambda m:''.join('\n' if x=='\n' else ' ' for x in m.group()),text)
 decls=list(re.finditer(r'^.*?\b(\w+)\s*\n\s+___P\(',clean,re.M))
 actual=[];rows=[]
 for f in sorted({v['callee'] for v in p['call']}):
  for hit in re.finditer(r'\b'+re.escape(f)+r'\s*\(',clean):
   owner=[d for d in decls if d.start()<hit.start()];assert owner,f
   actual.append(dict(callee=f,caller=owner[-1].group(1),line=text[:hit.start()].count('\n')+1))
 expected={(v['callerName'],v['callee']) for v in p['call']}
 assert {(v['caller'],v['callee']) for v in actual}==expected,(actual,expected)
 for v in p['call']:
  matches=[x for x in actual if (x['caller'],x['callee'])==(v['callerName'],v['callee'])]
  assert len(matches)==int(v['siteCount']),v
  rows.append([v['key'],v['callerName'],v['callee'],v['siteCount'],sv['sha256']])
 save(CACHE/'caller-audit.json',dict(status='pass-lexical-snapshot',snapshot=sv,rows=rows,sites=actual,effectivePreprocessedCallGraph=False))
 return rows

def formal_files():
 return [EMITTER,QNT]+[BASE+'models/lean/'+n+'.lean' for n in ['CapacityChargeAst','CapacityCharge','CapacityChargeComposition','NodePoolAst','NodePool']]

def formals():
 e=load('charge_emitter',EMITTER);cfg=e.SPEC;ir=json.loads((CACHE/'chunk_capacity_charge.json').read_text())
 ast,rc=e.generate(ir,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace']);(ROOT/(BASE+'models/lean/CapacityChargeAst.lean')).write_text(ast)
 save(CACHE/'typed-projection.json',dict(**rc,typedIrSha256=sha(CACHE/'chunk_capacity_charge.json'),astSha256=sha(ROOT/(BASE+'models/lean/CapacityChargeAst.lean'))))
 controls={}
 for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression','nonliteral-multiplication']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if case=='wrong-state-binding':bad['table'][str(rc['stateReferences'][0][0])]['id']=-1
  if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if case=='missing-step':ds['step']['expr']['args'].pop(0)
  if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
  if case=='nonliteral-multiplication':
   def visit(x):
    if isinstance(x,dict):
     if x.get('opcode')=='imul':x['args']=[copy.deepcopy(ds['safe']['expr']['args'][0]['args'][0])]*2;return True
     return any(visit(v) for v in x.values())
    if isinstance(x,list):return any(visit(v) for v in x)
    return False
   assert visit(ds['safe']['expr'])
  try:e.generate(bad,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
  except (AssertionError,KeyError):controls[case]='rejected'
  else:raise AssertionError('accepted '+case)
 save(CACHE/'projection-controls.json',controls)
 # Validate actual previous typed AST, not only filenames or hand-written target names.
 old=load('old_pool_projection','dev/modeling/tools/chunk-node-pool-projection.py')
 oldir=ROOT/'evidence/research/chunk-node-pool/chunk_node_pool.json';targetAst,tr=old.generate(json.loads(oldir.read_text()))
 assert targetAst==(ROOT/(BASE+'models/lean/NodePoolAst.lean')).read_text()
 parent=json.loads((ROOT/'evidence/research/chunk-node-pool/input.json').read_text())
 for n in ['NodePoolAst','NodePool']:
  f=BASE+'models/lean/'+n+'.lean';assert sha(ROOT/f)==parent['sourceBindings'][f],f
 save(CACHE/'target-projection.json',dict(**tr,typedIrSha256=sha(oldir),targetAstSha256=sha(ROOT/(BASE+'models/lean/NodePoolAst.lean'))))
 if '--reuse-formal' in sys.argv:
  checkpoint=json.loads((CACHE/'formal-checkpoint.json').read_text())
  for f,v in checkpoint['sourceBindings'].items():assert sha(ROOT/f)==v,f
  for f,v in checkpoint['logs'].items():assert sha(ROOT/f)==v,f
 else:
  tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==12 and tests.count('ControlTest passed')==5
  run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','83','--verbosity','1'])
  for n in ['CapacityChargeAst','CapacityCharge','NodePoolAst','NodePool','CapacityChargeComposition']:
   f=CACHE/(n+'.lean');original=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',original.read_text())
   if '--reuse-compiled' in sys.argv:
    assert f.read_bytes()==original.read_bytes() and (CACHE/(n+'.olean')).is_file(),n
    assert 'error:' not in (CACHE/(n+'.stdout')).read_text(),n
   else:
    f.write_bytes(original.read_bytes());run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
  neg=CACHE/'negative-birth';neg.mkdir(exist_ok=True);bad=ast.replace('starts:=(q.starts+(1))','starts:=(q.starts+(2))');assert bad!=ast
  f=neg/'CapacityChargeAst.lean';f.write_text(bad);run('negative-birth-ast',['lean','-o',str(neg/'CapacityChargeAst.olean'),str(f)])
  try:run('negative-birth-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',str(ROOT/(BASE+'models/lean/CapacityCharge.lean'))])
  except RuntimeError:assert 'error:' in (CACHE/'negative-birth-proof.stdout').read_text()
  else:raise AssertionError('bad birth proved')
  neg=CACHE/'negative-composition';neg.mkdir(exist_ok=True);orig=(ROOT/(BASE+'models/lean/CapacityChargeComposition.lean')).read_text();bad=orig.replace('p.issued=q.starts','p.issued=q.starts+1');assert bad!=orig
  f=neg/'CapacityChargeComposition.lean';f.write_text(bad)
  try:run('negative-composition',['env','LEAN_PATH='+str(CACHE),'lean',str(f)])
  except RuntimeError:assert 'error:' in (CACHE/'negative-composition.stdout').read_text()
  else:raise AssertionError('bad composition proved')
  save(CACHE/'formal-checkpoint.json',dict(sourceBindings={f:sha(ROOT/f) for f in formal_files()},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and any(k in f.name for k in ['CapacityCharge','NodePool','quint-','negative-'])}))
 actions=[[cfg['module']+'.'+x] for x in cfg['actions']]
 targets=[['chunk_node_pool.'+x] for x in old.SPEC['actions']+['stutter']]
 lemmas=[[n+'.'+x] for n in ['CapacityCharge','CapacityChargeComposition'] for x in re.findall(r'^\s*theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
 return actions,targets,lemmas

def ascend(p,w,actions,targets,lemmas,calls):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 binds=[[v['actionName'],v['lemma']] for v in p['binding']];refs=[[v['actionName'],v['targetStep'],v['simulation']] for v in p['binding']]
 ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in w];cs=[[v['key'],v['lemma']] for v in p['proof']]
 queries=['checked','blocked','candidate','linked','observed','compositionLinked','refinementLinked','callLinked']
 cases=['current','synthetic-all','stale-hash','wrong-scope','missing-source','missing-platform','missing-action','missing-lemma','missing-target','missing-child-proof','missing-witness','wrong-caller','wrong-site-count','wrong-source-digest','missing-composition']
 engine=h.Engine();results={}
 try:
  ss=engine.open_sources((ROOT/RULES).read_text());assert ss.run(queries=queries)['complete']
  for case in cases:
   rc=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction','restricted-projection']]
   if case=='stale-hash':rc[0][3]='stale'
   if case=='wrong-scope':rc[0][4]='unproved-global-native'
   for label,n in [('missing-source','CC-source'),('missing-platform','CC-platform'),('missing-composition','CC-composition')]:
    if case==label:rc=[v for v in rc if v[1]!=n]
   ac=[v for v in actions if case!='missing-action' or v!=['chunk_capacity_charge.advanceVisit']]
   ls=[v for v in lemmas if (case!='missing-lemma' or v!=['CapacityCharge.exactBirthCount']) and (case!='missing-child-proof' or v!=['CapacityChargeComposition.thresholdChild'])]
   ts=[v for v in targets if case!='missing-target' or v!=['chunk_node_pool.reserve']]
   obs=copy.deepcopy(calls)
   if case=='wrong-caller':obs[0][1]='not-a-caller'
   if case=='wrong-site-count':obs[0][3]='99'
   if case=='wrong-source-digest':obs[0][4]='stale'
   ss.replace(dict(scenario=[[case]],need=needs,receipt=rc,binding=binds,actionName=ac,lemmaName=ls,witness=ws,observation=ws[1:] if case=='missing-witness' else ws,compositionNeed=cs,refinementNeed=refs,targetActionName=ts,callNeed=calls,callObservation=obs))
   result=ss.run(queries=queries);assert result['complete'];results[case]=result['relations']
  assert results['synthetic-all']['candidate']
  for c in cases:
   if c!='synthetic-all':assert not results[c]['candidate'],c
  a=results['current'];assert {v[1] for v in a['blocked']}=={'CC-source','CC-platform'}
  assert [len(a[k]) for k in ['linked','refinementLinked','compositionLinked','callLinked']]==[12,12,12,9]
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/chunk-node-pool/input.json';parentHash=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for v in snapshots.values():assert sha(ROOT/v['path'])==v['sha256']
 p,scope=project();views(p);w=[]
 for v in p['source']:
  sv=snapshots[v['path']];t=(ROOT/sv['path']).read_text();assert v['needle'] in t,v['key'];w.append(dict(**v,snapshotPath=sv['path'],sha256=sv['sha256'],lines=[t[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),t)]))
 save(CACHE/'source-witnesses.json',w);save(OUT/'source-witnesses.json',w)
 calls=caller_audit(p,snapshots);shutil.copyfile(CACHE/'caller-audit.json',OUT/'caller-audit.json')
 if '--reuse-formal' not in sys.argv:run('typecheck',['quint','typecheck',QNT,'--out',str(CACHE/'chunk_capacity_charge.json')])
 ac,ts,ls=formals();ascend(p,w,ac,ts,ls,calls)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 org=org.replace('(missing nil))','(missing nil) (external-missing nil))')
 org=org.replace('(unless (file-exists-p target) (push (list file target) missing))','(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "chunk[-_]capacity[-_]charge\\\\|CapacityCharge" target))) (push (list file target) external-missing) (push (list file target) missing)))')
 org=org.replace('missing=%S; no Babel executed" (length files) links missing','missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 assert sha(parent)==parentHash
 drift=[dict(path=f,analyzed=v['sha256'],live=sha(ROOT/f)) for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']]
 scopeDrift=[dict(path=f,checked=d,live=sha(ROOT/f)) for f,d in scope.items() if sha(ROOT/f)!=d]
 checks=dict(status='conditional-charge-product-induction-pass',sysmlInputs=len(scope),sourceAnchors=len(w),literalCallClasses=len(calls),qntActions=len(ac),qntHistories=12,negativeQntControls=5,samples=500,maxSteps=200,leanTheorems=len(ls),allStepInduction=True,guardedPoolProductProved=True,phaseCarryProved=True,projectionControls=5,negativeLeanControls=2,ascentScenarios=15,actualCandidate=False,sourceQualified=False,c11Refinement=False,sourceLeaseInjection=False,defaultProfileAdmitted=False,realCapacityReceiptIssuer=False,fairnessProved=False,parserVerified=False,emitterVerified=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[],liveSourceDrift=drift,concurrentScopeDrift=scopeDrift)
 save(CACHE/'checks.json',checks)
 files=set(formal_files())|{MODEL,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py','dev/modeling/tools/chunk-node-pool-projection.py','dev/modeling/tools/chunk-transport-ledger-projection.py'}|{v['path'] for v in snapshots.values()}
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceSnapshots=snapshots,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name not in ['artifacts.json','final-audit.json']})
 print(json.dumps(checks))
if __name__=='__main__':main()
