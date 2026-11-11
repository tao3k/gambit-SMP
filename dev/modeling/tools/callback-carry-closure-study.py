#!/usr/bin/env python3
"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
import copy, importlib.util, json, re, shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='callback-carry-closure';BASE='dev/refactoring/modern-c/';PKG='GambitCallbackCarryClosure'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM

def load(n,p):
 spec=importlib.util.spec_from_file_location(n,ROOT/p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load('research','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run,save,sha=h.run,h.save,h.sha

def formal():
 e=load('carry_projection','dev/modeling/tools/'+STEM+'-projection.py');cfg=e.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rc=e.generate(ir)
 path=BASE+'models/lean/CallbackCarryAst.lean';(ROOT/path).write_text(ast)
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
 for n in ['CallbackCarryAst','CallbackCarry']:
  src=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
  target=CACHE/(n+'.lean');target.write_bytes(src.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(target)])
 tests=run('histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==7
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','223','--verbosity','1'])
 neg=CACHE/'negative-release';neg.mkdir(exist_ok=True)
 bad='\n'.join(line.replace('(q.closed=true)','True').replace('(q.mapped=true)','True').replace('(q.roots=(0))','True').replace('(q.active=(0))','True') if line.startswith('def releaseGuard') else line for line in ast.splitlines())+'\n'
 assert bad!=ast;(neg/'CallbackCarryAst.lean').write_text(bad)
 run('negative-ast',['lean','-o',str(neg/'CallbackCarryAst.olean'),str(neg/'CallbackCarryAst.lean')])
 try:run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/CallbackCarry.lean'])
 except RuntimeError:assert 'error:' in (CACHE/'negative-proof.stdout').read_text()
 else:raise AssertionError('weak release guard accepted')
 lemmas=[['CallbackCarry.'+n] for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/CallbackCarry.lean')).read_text(),re.M)]
 return [[cfg['module']+'.'+n] for n in cfg['actions']],lemmas

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());snap=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snap.items():assert sha(ROOT/f)==sha(ROOT/v['path'])==v['sha256'],f
 parent=ROOT/'evidence/research/emission-pipe-refinement/input.json';parentHash=sha(parent)
 adapter=load('native_sysml','dev/modeling/tools/default-lease-admission-study.py')
 for k,v in dict(CACHE=CACHE,OUT=OUT,PKG=PKG,GROUPS=cfg['groups'],SLOTS=cfg['slots']).items():setattr(adapter,k,v)
 adapter.h.CACHE=CACHE;adapter.h.OUT=OUT
 p,scope=adapter.project();save(CACHE/'sysml-projection.json',p)
 view=load('native_views','dev/modeling/tools/copy-producer-envelope-study.py')
 for k,v in dict(ROOT=ROOT,GROUPS=cfg['groups'],MATRIX=BASE+STEM+'-matrix.org',D2=BASE+'diagrams/'+STEM+'.d2').items():setattr(view,k,v)
 view.views(p)
 matrix=ROOT/(BASE+STEM+'-matrix.org');matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Callback Authority, Carry-over and Root Custody Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-root-exception-C23-platform-open'))
 d2=ROOT/(BASE+'diagrams/'+STEM+'.d2');d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / roots / exceptions / C23 OPEN'))
 witnesses=[]
 for v in p['source']:
  text=(ROOT/snap[v['path']]['path']).read_text();assert v['needle'] in text,v
  witnesses.append(dict(**v,sha256=snap[v['path']]['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witnesses)
 # Exact bounded lexical slices, not a Scheme parser or a whole-program call graph.
 io=(ROOT/snap['vendor/gambit/lib/_io.scm']['path']).read_text();slices=[]
 for name,end,guard in [('##char-ready?1','##char-ready?0','(##fx< char-rlo char-rhi)'),('##peek-char1','##peek-char0','(##fx< char-rlo char-rhi)'),('##read-char1','##read-char1?','(##fx< char-rlo char-rhi)'),('##read-substring','read-substring','(##fx< 0 chars-buffered)')]:
  start=io.index('(define-prim ('+name+' ' if name!='##read-substring' else '(define-prim (##read-substring\n')
  stop=io.index('(define-prim ('+end,start+1);text=io[start:stop]
  call='((macro-character-port-rbuf-fill port)';assert text.count(call)==1 and guard in text
  slices.append(dict(caller=name,startLine=io[:start].count('\n')+1,endLine=io[:stop].count('\n')+1,guard=guard,call=call,digest=snap['vendor/gambit/lib/_io.scm']['sha256']))
 assert io.count('((macro-character-port-rbuf-fill port)')==4
 save(CACHE/'reader-caller-slices.json',dict(slices=slices,scope='four direct lexical character callers; valid index and no hidden mutation premises remain open'))
 inventoryFiles=sorted(set((ROOT/'vendor/gambit/gsc').glob('*.scm'))|set((ROOT/'vendor/gambit/lib').glob('*.scm')))
 inventoryInputs={str(f.relative_to(ROOT)):sha(f) for f in inventoryFiles}
 matches=[]
 # Simple literal token inventory avoids treating Scheme syntax as Python grammar.
 tokens=['(##wr-set!','(##add-gc-interrupt-job!','(##clear-gc-interrupt-jobs!','(##port-io-exception-handler-set!','(port-io-exception-handler-set!','(##primordial-exception-handler-hook-set!']
 for f in inventoryFiles:
  for lineNo,line in enumerate(f.read_text().splitlines(),1):
   for token in tokens:
    if token in line:matches.append(dict(path=str(f.relative_to(ROOT)),line=lineNo,token=token,text=line.strip(),comment=line.lstrip().startswith(';'),definition='define-prim' in line or '(define (' in line))
 save(CACHE/'registration-inventory.json',dict(inputs=inventoryInputs,matches=matches,scope='direct lexical tokens in immediate gsc/lib Scheme files; comments and definitions classified; nested libraries, aliases, native stores and loaded user code not closed'))
 actions,lemmas=formal()
 for v in p['proof']:assert [v['lemma']] in lemmas,v
 needs=[[v[k] for k in ['obligationId','kind','subjectPath']]+[sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 sources=[[v[k] for k in ['key','path','sha256','needle']] for v in witnesses]
 callbacks=[[v[k] for k in ['key','registrant','closure','authority','status']] for v in p['callback']]
 results={};cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-callback','missing-formal','wrong-scope']
 engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
  assert session.run(queries=['blocked'])['complete']
  for case in cases:
   receipts=[[case,n,path,digest,sc] for n,k,path,digest,sc in needs if case!='current' or n=='CC-formal']
   if case=='missing-formal':receipts=[v for v in receipts if v[1]!='CC-formal']
   if case=='wrong-scope':receipts[0][-1]='native-performance'
   obs=copy.deepcopy(sources)
   if case=='stale-source':obs[0][2]='stale'
   cb=copy.deepcopy(callbacks)
   if case=='wrong-callback':cb[0][3]='effect-free-without-proof'
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if case!='missing-lemma' or v!=['CallbackCarry.beginLegalPreserves']],sourceNeed=sources,sourceObservation=obs,callbackNeed=callbacks,callbackObservation=cb))
   r=session.run(queries=['blocked','candidate','linked','sourceLinked','callbackLinked']);assert r['complete'];results[case]=r['relations']
 finally:engine.close()
 assert [k for k in cases if results[k]['candidate']]==['synthetic-all']
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==6,gaps
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT))])
 run('d2-png',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(CACHE/'diagram.png')])
 checks=dict(status='conditional-formal-pass-actual-retirement-denied',languageBaseline='C23',sourceSnapshots=len(snap),sourceAnchors=len(witnesses),directReaderSlices=len(slices),callbackClasses=len(callbacks),qntActions=len(actions),qntHistories=7,qntSamples=500,seed=223,leanTheorems=len(lemmas),allStepInduction=True,typedIrControls=4,negativeReleaseControl=True,ascentScenarios=len(cases),actualCandidate=False,firstNativeRetirement=False,secondNativeRetirement=False,legalPublicCarryWitness=False,compiledRootMapQualified=False,blockers=gaps,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 # Native Org parser and link audit, without Babel evaluation.
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
 (CACHE/'check-org.el').write_text(org)
 for f,v in snap.items():assert sha(ROOT/f)==v['sha256'],f
 assert sha(parent)==parentHash
 for f,digest in inventoryInputs.items():assert sha(ROOT/f)==digest,('inventory drift',f)
 for f,digest in scope.items():assert sha(ROOT/f)==digest,('sysml drift',f)
 own=[BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'models/sysml/'+STEM+'.sysml',BASE+'models/quint/callback_carry_closure.qnt',BASE+'models/lean/CallbackCarryAst.lean',BASE+'models/lean/CallbackCarry.lean',BASE+'index.org',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT)),'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/advantage-architecture-study.py',str((CACHE/'config.json').relative_to(ROOT)),str((CACHE/'source-snapshots.json').relative_to(ROOT))]+[v['path'] for v in snap.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snap,sysmlInputs=scope,lexicalInputs=inventoryInputs))
 def copy_receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 copy_receipts();run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 data=json.loads((CACHE/'input.json').read_text());data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);copy_receipts()
 shutil.copytree(CACHE/'negative-release',OUT/'negative-release',dirs_exist_ok=True)
 for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
