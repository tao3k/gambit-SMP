#!/usr/bin/env python3
"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
import copy, importlib.util, json, re, shutil, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='ticket-capability-retirement';BASE='dev/refactoring/modern-c/';PKG='GambitTicketCapabilityRetirement'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM

def load(n,p):
 spec=importlib.util.spec_from_file_location(n,ROOT/p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load('research','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run,save,sha=h.run,h.save,h.sha

def formal():
 e=load('carry_projection','dev/modeling/tools/'+STEM+'-projection.py');cfg=e.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 formalPaths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in ['TicketCapabilityAst','TicketCapability','TicketIdentityAlgebra']]
 if '--reuse-formal' in sys.argv:
  checkpoint=json.loads((CACHE/'formal-checkpoint.json').read_text())
  assert {f:sha(ROOT/f) for f in formalPaths}==checkpoint['sources']
  assert all(sha(ROOT/f)==d for f,d in checkpoint['logs'].items())
  lemmas=[[ns+'.'+n] for ns in ['TicketCapability','TicketIdentityAlgebra'] for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+ns+'.lean')).read_text(),re.M)]
  return [[cfg['module']+'.'+n] for n in cfg['actions']],lemmas
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rc=e.generate(ir)
 path=BASE+'models/lean/TicketCapabilityAst.lean';(ROOT/path).write_text(ast)
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
 for n in ['TicketCapabilityAst','TicketCapability','TicketIdentityAlgebra']:
  src=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
  target=CACHE/(n+'.lean');target.write_bytes(src.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(target)])
 tests=run('histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==15
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','293','--verbosity','1'])
 neg=CACHE/'negative-root';neg.mkdir(exist_ok=True)
 bad='\n'.join(line.replace('(¬(q.s0open=true))','True') if line.startswith('def retireRootGuard') else line for line in ast.splitlines())+'\n'
 assert bad!=ast;(neg/'TicketCapabilityAst.lean').write_text(bad)
 run('negative-ast',['lean','-o',str(neg/'TicketCapabilityAst.olean'),str(neg/'TicketCapabilityAst.lean')])
 try:run('negative-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/TicketCapability.lean'])
 except RuntimeError:assert 'error:' in (CACHE/'negative-proof.stdout').read_text()
 else:raise AssertionError('live scanner root retirement accepted')
 lemmas=[[ns+'.'+n] for ns in ['TicketCapability','TicketIdentityAlgebra'] for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+ns+'.lean')).read_text(),re.M)]
 for name,old,new in [('negative-other-ticket','if q=key then finish (ledger key) payload value else ledger q','finish (ledger key) payload value'),('negative-other-handle','if q=key then false else handles q','false')]:
  algebra=(ROOT/(BASE+'models/lean/TicketIdentityAlgebra.lean')).read_text();bad=algebra.replace(old,new);assert bad!=algebra
  target=CACHE/(name+'.lean');target.write_text(bad)
  try:run(name,['env','LEAN_PATH='+str(CACHE),'lean',str(target)])
  except RuntimeError:assert 'error:' in (CACHE/(name+'.stdout')).read_text()
  else:raise AssertionError('identity mutation proved '+name)
 save(CACHE/'formal-checkpoint.json',dict(sources={f:sha(ROOT/f) for f in formalPaths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and f.stem in ['typecheck','TicketCapabilityAst','TicketCapability','TicketIdentityAlgebra','histories','samples','negative-ast','negative-proof','negative-other-ticket','negative-other-handle']}))
 return [[cfg['module']+'.'+n] for n in cfg['actions']],lemmas

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());snap=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snap.items():assert sha(ROOT/f)==sha(ROOT/v['path'])==v['sha256'],f
 parent=ROOT/'evidence/research/will-action-drain/input.json';parentHash=sha(parent)
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
 matrix=ROOT/(BASE+STEM+'-matrix.org');matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Exact Ticket Settlement and Capability Retirement Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-root-exception-C23-platform-open'))
 d2=ROOT/(BASE+'diagrams/'+STEM+'.d2');d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / roots / exceptions / C23 OPEN'))
 witnesses=[]
 for v in p['source']:
  text=(ROOT/snap[v['path']]['path']).read_text();assert v['needle'] in text,v
  witnesses.append(dict(**v,sha256=snap[v['path']]['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witnesses)
 # Exact bounded slices; lexical call ordering is not full source simulation.
 slices=[]
 specs=[('vendor/gambit/lib/_thread.scm','(define-prim (##call-with-current-continuation','(define-prim (call-with-current-continuation','(define (reify-continuation cont)'),('vendor/gambit/lib/_thread.scm','(define-prim (##continuation-unwind-wind src dst continue)','(define-prim (##continuation-graft-aux','((macro-dynwind-before dst))'),('vendor/gambit/lib/_thread.scm','(define-prim (##continuation-return-aux cont val1 val2 val3 others)','(define-prim (##continuation-return\n','(if (or (##eq? src dst)'),('vendor/gambit/lib/_kernel.scm','(define-prim (##continuation-copy cont)','(define-prim (##continuation-next! cont)','___SCMOBJ frame = ___CONTINUATION_FRAME_FIELD(cont);'),('vendor/gambit/lib/_io.scm','(define-prim (##implode-continuation re fields)','(define-prim (##explode-procedure proc)','(##make-continuation'),('vendor/gambit/lib/_kernel.scm','(define-prim (##will-execute! will)','(define ##final-will-registry','(action testator)')]
 for path,begin,end,call in specs:
  text=(ROOT/snap[path]['path']).read_text()
  for i,hit in enumerate(re.finditer(re.escape(begin),text)):
   stop=text.index(end,hit.end());body=text[hit.start():stop];assert call in body
   slices.append(dict(path=path,sha256=snap[path]['sha256'],occurrence=i,startLine=text[:hit.start()].count('\n')+1,endLine=text[:stop].count('\n')+1,call=call,scope='bounded lexical slice; source/ABI/authority correspondence open'))
 save(CACHE/'source-call-slices.json',slices)
 inventoryInputs={f:v['sha256'] for f,v in snap.items()}
 matches=[]
 for path,v in snap.items():
  for lineNo,line in enumerate((ROOT/v['path']).read_text().splitlines(),1):
   if any(t in line for t in ['continuation-copy','continuation-return-no-winding','procedure->continuation','implode-continuation','refcount','will-execute!']):matches.append(dict(path=path,line=lineNo,text=line.strip()))
 save(CACHE/'source-token-inventory.json',dict(inputs=inventoryInputs,matches=matches,scope='selected source snapshots only; aliases and caller closure unproved'))
 actions,lemmas=formal()
 for v in p['proof']:assert [v['lemma']] in lemmas,v
 needs=[[v[k] for k in ['obligationId','kind','subjectPath']]+[sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 owners=[[v['obligationId'],v['owner.componentId']] for v in p['need'].values()]
 sources=[[v[k] for k in ['key','path','sha256','needle']] for v in witnesses]
 issuers=[[v[k] for k in ['key','proposedIssuer','actualSource','status','responsibility']] for v in p['issuer']]
 routes=[[v[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for v in p['route']]
 proofs=[[v['key'],v['lemma']] for v in p['proof']]
 results={};cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-issuer','missing-formal','wrong-scope','wrong-owner','missing-raw-route','missing-projection']
 engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
  assert session.run(queries=['blocked'])['complete']
  for case in cases:
   receipts=[[case,n,path,digest,sc] for n,k,path,digest,sc in needs if case!='current' or n in ['TC-formal','TC-algebra']]
   if case=='missing-formal':receipts=[v for v in receipts if v[1]!='TC-formal']
   if case=='wrong-scope':receipts[0][-1]='native-performance'
   obs=copy.deepcopy(sources)
   if case=='stale-source':obs[0][2]='stale'
   io=copy.deepcopy(issuers)
   if case=='wrong-issuer':io[4][2]='existing-global-last-alias-signer-without-evidence'
   ro=copy.deepcopy(routes)
   if case=='wrong-owner':ro[0][0]='roots'
   if case=='missing-raw-route':ro=[r for r in ro if r[1]!='ticket_capability_retirement.discoverRawEscape']
   session.replace(dict(scenario=[[case]],need=needs,needOwner=owners,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if (case!='missing-lemma' or v!=['TicketCapability.stepPreserves']) and (case!='missing-projection' or v!=['TicketIdentityAlgebra.commitProjection0'])],sourceNeed=sources,sourceObservation=obs,issuerNeed=issuers,issuerObservation=io,routeNeed=routes,routeObservation=ro,proofNeed=proofs))
   r=session.run(queries=['blocked','candidate','linked','sourceLinked','issuerLinked','routeLinked','proofLinked']);assert r['complete'];results[case]=r['relations']
 finally:engine.close()
 assert [k for k in cases if results[k]['candidate']]==['synthetic-all']
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==5,gaps
 assert len(results['current']['routeLinked'])==len(routes)
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT))])
 run('d2-png',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(CACHE/'diagram.png')])
 checks=dict(status='conditional-per-key-and-capability-safety-pass-native-retirement-denied',languageBaseline='C23',sourceSnapshots=len(snap),sourceAnchors=len(witnesses),issuerRoles=len(issuers),sourceCallSlices=len(slices),componentSourceActionRoutes=len(routes),qntActions=len(actions),qntHistories=15,qntSamples=500,seed=293,leanTheorems=len(lemmas),allStepInduction=True,typedIrControls=4,negativeProofControls=3,ascentScenarios=len(cases),concreteTicketIds=2,genericKeyedAlgebra=True,fullUnboundedProductRefinement=False,actualCandidate=False,firstNativeRetirement=False,secondNativeRetirement=False,realIssuerClosure=False,genericSchemeLastAliasSigner=False,compiledRootMapQualified=False,eventualCompletionProved=False,crashRecoveryProved=False,c23RefinementProved=False,blockers=gaps,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 # Native Org parser and link audit, without Babel evaluation.
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
 (CACHE/'check-org.el').write_text(org)
 for f,v in snap.items():assert sha(ROOT/f)==v['sha256'],f
 assert sha(parent)==parentHash
 for f,digest in inventoryInputs.items():assert sha(ROOT/f)==digest,('inventory drift',f)
 for f,digest in scope.items():assert sha(ROOT/f)==digest,('sysml drift',f)
 own=[BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'models/sysml/'+STEM+'.sysml',BASE+'models/quint/ticket_capability_retirement.qnt',BASE+'models/lean/TicketCapabilityAst.lean',BASE+'models/lean/TicketCapability.lean',BASE+'index.org',BASE+'language-baseline-design.org',BASE+'will-action-drain-design.org',BASE+'models/lean/TicketIdentityAlgebra.lean',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT)),'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/advantage-architecture-study.py',str((CACHE/'config.json').relative_to(ROOT)),str((CACHE/'source-snapshots.json').relative_to(ROOT))]+[v['path'] for v in snap.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snap,sysmlInputs=scope,lexicalInputs=inventoryInputs))
 def copy_receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 copy_receipts();run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 data=json.loads((CACHE/'input.json').read_text());data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);copy_receipts()
 shutil.copytree(CACHE/'negative-root',OUT/'negative-root',dirs_exist_ok=True)
 for f in CACHE.glob('negative-other-*.lean'):shutil.copyfile(f,OUT/f.name)
 for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':
 if '--formal-only' in sys.argv:formal()
 else:main()
