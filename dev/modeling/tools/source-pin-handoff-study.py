#!/usr/bin/env python3
"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
import copy, importlib.util, json, re, shutil, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='source-pin-handoff';BASE='dev/refactoring/modern-c/';PKG='GambitSourcePinHandoff'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM

def load(n,p):
 spec=importlib.util.spec_from_file_location(n,ROOT/p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load('research','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run,save,sha=h.run,h.save,h.sha

def formal():
 e=load('issuer_projection','dev/modeling/tools/'+STEM+'-projection.py');cfg=e.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 imported=['RestoreIssuerAst','RestoreIssuer']
 parent=json.loads((ROOT/'evidence/research/restore-entry-issuers/input.json').read_text())
 for name in imported:
  source=BASE+'models/lean/'+name+'.lean';assert sha(ROOT/source)==parent['sourceBindings'][source],source
  target=CACHE/(name+'.lean')
  if '--reuse-imports' in sys.argv:
   cp=json.loads((CACHE/'imported-checkpoint.json').read_text());assert all(sha(ROOT/f)==d for f,d in cp.items())
   assert target.read_bytes()==(ROOT/source).read_bytes()
  else:target.write_bytes((ROOT/source).read_bytes())
  if '--reuse-formal' not in sys.argv and '--reuse-imports' not in sys.argv:run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(target)])
 formalPaths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in imported+['SourcePinAst','SourcePin','SourcePinBridge']]
 namespaces=['SourcePin','SourcePinBridge']
 def names():return [[ns+'.'+n] for ns in namespaces for n in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+ns+'.lean')).read_text(),re.M)]
 if '--reuse-formal' in sys.argv:
  cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
  assert {f:sha(ROOT/f) for f in formalPaths}==cp['sources']
  assert all(sha(ROOT/f)==d for f,d in cp['logs'].items())
  return [[cfg['module']+'.'+n] for n in cfg['actions']],names()
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rc=e.generate(ir)
 path=BASE+'models/lean/SourcePinAst.lean';(ROOT/path).write_text(ast)
 save(CACHE/'projection.json',dict(**rc,irSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(ROOT/path),scope='restricted typed IR; JSON parser/projector trusted; source and GC witness fidelity open'))
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
 for n in ['SourcePinAst','SourcePin','SourcePinBridge']:
  src=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
  target=CACHE/(n+'.lean');target.write_bytes(src.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(target)])
 tests=run('histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==12
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','359','--verbosity','1'])
 for label,decl,old,new in [('negative-early-delete','def retireSourceGuard','(q.pin0=(0))','True'),('negative-stale-enrollment','def enroll0Guard','(q.value0=q.epoch)','True')]:
  neg=CACHE/label;neg.mkdir(exist_ok=True)
  bad='\n'.join(line.replace(old,new) if line.startswith(decl) else line for line in ast.splitlines())+'\n'
  assert bad!=ast,(label,old);(neg/'SourcePinAst.lean').write_text(bad)
  run(label+'-ast',['lean','-o',str(neg/'SourcePinAst.olean'),str(neg/'SourcePinAst.lean')])
  try:run(label+'-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/SourcePin.lean'])
  except RuntimeError:assert 'error:' in (CACHE/(label+'-proof.stdout')).read_text()
  else:raise AssertionError('unsafe handoff accepted '+label)
 save(CACHE/'formal-checkpoint.json',dict(sources={f:sha(ROOT/f) for f in formalPaths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and (f.stem in imported+['typecheck','SourcePinAst','SourcePin','SourcePinBridge','histories','samples'] or f.stem.startswith('negative-'))}))
 return [[cfg['module']+'.'+n] for n in cfg['actions']],names()

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());snap=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snap.items():assert sha(ROOT/f)==sha(ROOT/v['path'])==v['sha256'],f
 parent=ROOT/'evidence/research/restore-entry-issuers/input.json';parentHash=sha(parent)
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
 matrix=ROOT/(BASE+STEM+'-matrix.org');matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Source Pin, Carrier Enrollment and Guard Handoff Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-root-exception-C23-platform-open'))
 d2=ROOT/(BASE+'diagrams/'+STEM+'.d2');d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / roots / exceptions / C23 OPEN'))
 witnesses=[]
 for v in p['source']:
  text=(ROOT/snap[v['path']]['path']).read_text();assert v['needle'] in text,v
  witnesses.append(dict(**v,sha256=snap[v['path']]['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witnesses)
 inventoryInputs={f:v['sha256'] for f,v in snap.items()};paths=sorted(inventoryInputs);matches=[]
 for path in paths:
  for no,line in enumerate((ROOT/snap[path]['path']).read_text().splitlines(),1):
   if any(token in line for token in ['___data_rc','___set_data_rc','___release_rc','___addref_rc','cleanup_rc','mark_rc','scheme_delete_cmd','scheme_call_cmd','startup_thunk','entry_marker']):matches.append(dict(path=path,line=no,text=line.strip()))
 save(CACHE/'source-token-inventory.json',dict(inputs=inventoryInputs,matches=matches,scope='selected hashed producer/consumer source snapshots; dynamic caller closure open'))
 slices=[]
 for path,begin,end,call in [('vendor/gambit/lib/memory/rc-allocation.inc','___EXP_FUNC(void,___release_rc)','___EXP_FUNC(void,___addref_rc)','___FREE_MEM(h);'),('vendor/gambit/lib/memory/rc-roots.inc','___HIDDEN void mark_rc','#define UNMARKED_MOVABLE','mark_array (work, &h->data, 1);'),('vendor/gambit/examples/tcltk/tcltk.scm','___HIDDEN void scheme_delete_cmd','c-declare-end','___EXT(___release_rc)')]:
  text=(ROOT/snap[path]['path']).read_text();start=text.index(begin);stop=text.index(end,start+len(begin));assert call in text[start:stop]
  slices.append(dict(path=path,sha256=snap[path]['sha256'],startLine=text[:start].count('\n')+1,endLine=text[:stop].count('\n')+1,call=call,scope='bounded lexical lifetime/scan order; platform/source simulation open'))
 save(CACHE/'source-call-slices.json',slices)
 actions,lemmas=formal()
 for v in p['proof']:assert [v['lemma']] in lemmas,v
 needs=[[v[k] for k in ['obligationId','kind','subjectPath']]+[sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 owners=[[v['obligationId'],v['owner.componentId']] for v in p['need'].values()]
 sources=[[v[k] for k in ['key','path','sha256','needle']] for v in witnesses]
 issuers=[[v[k] for k in ['key','proposedIssuer','actualSource','status','responsibility']] for v in p['issuer']]
 routes=[[v[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for v in p['route']]
 proofs=[[v['key'],v['lemma']] for v in p['proof']]
 results={};cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-issuer','missing-formal','wrong-scope','wrong-owner','missing-intent-route','missing-projection']
 engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/('dev/modeling/ascent/'+STEM+'.rules.scm')).read_text())
  assert session.run(queries=['blocked'])['complete']
  for case in cases:
   receipts=[[case,n,path,digest,sc] for n,k,path,digest,sc in needs if case!='current' or n in ['SP-formal','SP-bridge']]
   if case=='missing-formal':receipts=[v for v in receipts if v[1]!='SP-formal']
   if case=='wrong-scope':receipts[0][-1]='native-performance'
   obs=copy.deepcopy(sources)
   if case=='stale-source':obs[0][2]='stale'
   io=copy.deepcopy(issuers)
   if case=='wrong-issuer':io[4][2]='existing-global-last-alias-signer-without-evidence'
   ro=copy.deepcopy(routes)
   if case=='wrong-owner':ro[0][0]='roots'
   if case=='missing-intent-route':ro=[r for r in ro if r[1]!='source_pin_handoff.returnPin1']
   session.replace(dict(scenario=[[case]],need=needs,needOwner=owners,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if (case!='missing-lemma' or v!=['SourcePin.stepPreserves']) and (case!='missing-projection' or v!=['SourcePinBridge.guardReservationAgreement'])],sourceNeed=sources,sourceObservation=obs,issuerNeed=issuers,issuerObservation=io,routeNeed=routes,routeObservation=ro,proofNeed=proofs))
   r=session.run(queries=['blocked','candidate','linked','sourceLinked','issuerLinked','routeLinked','proofLinked']);assert r['complete'];results[case]=r['relations']
 finally:engine.close()
 save(CACHE/'ascent-scenario-diagnostics.json',results)
 assert [k for k in cases if results[k]['candidate']]==['synthetic-all'],[k for k in cases if results[k]['candidate']]
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==6,gaps
 assert len(results['current']['routeLinked'])==len(routes)
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 run('d2-svg',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT))])
 run('d2-png',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(CACHE/'diagram.png')])
 checks=dict(status='conditional-source-pin-and-enrollment-pass-native-retirement-denied',languageBaseline='C23',sourceSnapshots=len(snap),sourceAnchors=len(witnesses),issuerRoles=len(issuers),sourceCallSlices=len(slices),componentSourceActionRoutes=len(routes),qntActions=len(actions),qntHistories=12,qntSamples=500,seed=359,leanTheorems=len(lemmas),allStepInduction=True,typedIrControls=4,negativeProofControls=2,literalCallerHits=len(matches),callerCorpusFiles=len(paths),completeSemanticIntentCensus=False,ascentScenarios=len(cases),fixedPinIds=2,genericKeyedAlgebra=False,fullUnboundedProductRefinement=False,actualCandidate=False,firstNativeRetirement=False,secondNativeRetirement=False,realIssuerClosure=False,genericSchemeLastAliasSigner=False,compiledRootMapQualified=False,eventualCompletionProved=False,crashRecoveryProved=False,c23RefinementProved=False,blockers=gaps,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 # Native Org parser and link audit, without Babel evaluation.
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
 (CACHE/'check-org.el').write_text(org)
 for f,v in snap.items():assert sha(ROOT/f)==v['sha256'],f
 assert sha(parent)==parentHash
 for f,digest in inventoryInputs.items():assert sha(ROOT/f)==digest,('inventory drift',f)
 for f,digest in scope.items():assert sha(ROOT/f)==digest,('sysml drift',f)
 own=[BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'models/sysml/'+STEM+'.sysml',BASE+'models/quint/source_pin_handoff.qnt',BASE+'models/lean/SourcePinAst.lean',BASE+'models/lean/SourcePin.lean',BASE+'models/lean/SourcePinBridge.lean',BASE+'models/lean/RestoreIssuerAst.lean',BASE+'models/lean/RestoreIssuer.lean',BASE+'index.org',BASE+'language-baseline-design.org',BASE+'restore-entry-issuers-design.org',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT)),'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/advantage-architecture-study.py',str((CACHE/'config.json').relative_to(ROOT)),str((CACHE/'source-snapshots.json').relative_to(ROOT))]+[v['path'] for v in snap.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snap,sysmlInputs=scope,lexicalInputs=inventoryInputs))
 def copy_receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 copy_receipts();run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 data=json.loads((CACHE/'input.json').read_text());data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);copy_receipts()
 for n in ['negative-early-delete','negative-stale-enrollment']:shutil.copytree(CACHE/n,OUT/n,dirs_exist_ok=True)
 for f in CACHE.glob('negative-*.lean'):shutil.copyfile(f,OUT/f.name)
 for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':
 if '--formal-only' in sys.argv:formal()
 else:main()
