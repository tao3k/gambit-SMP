#!/usr/bin/env python3
"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
import copy, importlib.util, json, re, shutil, sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='carrier-slot-mapping';BASE='dev/refactoring/modern-c/';PKG='GambitCarrierSlotMapping'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM

def load(n,p):
 spec=importlib.util.spec_from_file_location(n,ROOT/p);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load('research','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
save,sha=h.save,h.sha
# Exact local formal executable may be selected without invoking the version shim.
import os
def run(name,args):
 args=[os.environ.get('CARRIER_LEAN','lean') if x=='lean' else x for x in args]
 return h.run(name,args)

def formal():
 e=load('issuer_projection','dev/modeling/tools/'+STEM+'-projection.py');cfg=e.SPEC
 qnt=BASE+'models/quint/'+cfg['module']+'.qnt'
 imported=['CarrierCoverageAst']
 parent=json.loads((ROOT/'evidence/research/persistent-carrier-coverage/input.json').read_text())
 for name in imported:
  source=BASE+'models/lean/'+name+'.lean';assert sha(ROOT/source)==parent['sourceBindings'][source],source
  target=CACHE/(name+'.lean')
  if '--reuse-imports' in sys.argv:
   cp=json.loads((CACHE/'imported-checkpoint.json').read_text());assert all(sha(ROOT/f)==d for f,d in cp.items())
   assert target.read_bytes()==(ROOT/source).read_bytes()
  else:target.write_bytes((ROOT/source).read_bytes())
  if '--reuse-formal' not in sys.argv and '--reuse-imports' not in sys.argv:run(name,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(name+'.olean')),str(target)])
 formalPaths=[qnt,'dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/lean/'+n+'.lean' for n in imported+['SlotMappingAst','SlotMapping','SlotCensus','SlotMappingBridge']]
 namespaces=['SlotMapping','SlotCensus','SlotMappingBridge']
 def names():return [[ns+'.'+n] for ns in namespaces for n in re.findall(r'^\s*theorem (\w+)',(ROOT/(BASE+'models/lean/'+ns+'.lean')).read_text(),re.M)]
 if '--reuse-formal' in sys.argv:
  cp=json.loads((CACHE/'formal-checkpoint.json').read_text())
  assert {f:sha(ROOT/f) for f in formalPaths}==cp['sources']
  assert all(sha(ROOT/f)==d for f,d in cp['logs'].items())
  return [[cfg['module']+'.'+n] for n in cfg['actions']],names()
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rc=e.generate(ir)
 path=BASE+'models/lean/SlotMappingAst.lean';(ROOT/path).write_text(ast)
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
 for n in ['SlotMappingAst','SlotMapping','SlotCensus','SlotMappingBridge']:
  src=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',src.read_text())
  target=CACHE/(n+'.lean');target.write_bytes(src.read_bytes())
  run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(target)])
 tests=run('histories',['quint','test',qnt,'--match','Test$']);assert tests.count('ok ')==13
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','100','--seed','431','--verbosity','1'])
 for label,decl,old,new in [('negative-lookup-drain','def retire0Guard','(q.lookup0=(0))','True'),('negative-value-dedup','def freeze011Next','m1:=(1), task0:=(1), task1:=(1)','m1:=(0), task0:=(1), task1:=(0)'),('negative-shared-slot-free','def freeStore0Guard','(((q.d1=(0)) ∨ (q.d1=(4))) ∨ (q.alias=(0)))','True')]:
  neg=CACHE/label;neg.mkdir(exist_ok=True)
  bad='\n'.join(line.replace(old,new) if line.startswith(decl) else line for line in ast.splitlines())+'\n'
  assert bad!=ast,(label,old);(neg/'SlotMappingAst.lean').write_text(bad)
  run(label+'-ast',['lean','-o',str(neg/'SlotMappingAst.olean'),str(neg/'SlotMappingAst.lean')])
  try:run(label+'-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',BASE+'models/lean/SlotMapping.lean'])
  except RuntimeError:assert 'error:' in (CACHE/(label+'-proof.stdout')).read_text()
  else:raise AssertionError('unsafe mapping accepted '+label)
 save(CACHE/'formal-checkpoint.json',dict(sources={f:sha(ROOT/f) for f in formalPaths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and (f.stem in imported+['typecheck','SlotMappingAst','SlotMapping','SlotCensus','SlotMappingBridge','histories','samples'] or f.stem.startswith('negative-'))}))
 return [[cfg['module']+'.'+n] for n in cfg['actions']],names()

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());snap=json.loads((CACHE/'source-snapshots.json').read_text())
 for f,v in snap.items():assert sha(ROOT/f)==sha(ROOT/v['path'])==v['sha256'],f
 parent=ROOT/'evidence/research/persistent-carrier-coverage/input.json';parentHash=sha(parent)
 # Scope the native query to this self-contained package; the bounded all-DEV
 # query timeout is retained separately and is not relabeled as global validation.
 cfgPath=CACHE/'config.json'
 model=BASE+'models/sysml/'+STEM+'.sysml'
 scope={model:sha(ROOT/model)}
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in cfg['groups'] for i in range(n) for f in fs.split()]
 keys += [('need',slot,f,f'{PKG}::{slot}.{f}') for slot in cfg['slots'] for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
 if '--reuse-sysml' in sys.argv:
  checkpoint=json.loads((CACHE/'native-checkpoint.json').read_text())
  assert checkpoint['scopeKind']=='self-contained-native-package'
  assert sha(cfgPath)==checkpoint['config'] and scope==checkpoint['inputs']
  assert sha(CACHE/'sysml-scoped.stdout')==checkpoint['raw']
  assert sha(CACHE/'native-queries.json')==checkpoint['queries']
  p=json.loads((CACHE/'sysml-projection.json').read_text());assert sha(CACHE/'sysml-projection.json')==checkpoint['projection']
 else:
  args=['sysml','-strict','-no-record-cache','-validate','-json']
  for *_,expr in keys:args+=['-e',expr]
  raw=json.loads(run('sysml-scoped',args+[model]))
  assert raw['exit']==0 and not raw.get('errors') and not any(d['severity']=='error' for d in (raw.get('diagnostics') or []))
  vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys)
  p={}
  for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
  for g,_,_ in cfg['groups']:p[g]=list(p[g].values())
  save(CACHE/'sysml-projection.json',p);save(CACHE/'native-queries.json',keys)
  save(CACHE/'native-checkpoint.json',dict(scopeKind='self-contained-native-package',config=sha(cfgPath),inputs=scope,raw=sha(CACHE/'sysml-scoped.stdout'),queries=sha(CACHE/'native-queries.json'),projection=sha(CACHE/'sysml-projection.json')))
 save(CACHE/'global-sysml-status.json',dict(status='scoped-native-only-no-whole-DEV-qualification',wholeDevValidated=False,scopedNativeValidation=True))
 view=load('native_views','dev/modeling/tools/copy-producer-envelope-study.py')
 for k,v in dict(ROOT=ROOT,GROUPS=cfg['groups'],MATRIX=BASE+STEM+'-matrix.org',D2=BASE+'diagrams/'+STEM+'.d2').items():setattr(view,k,v)
 view.views(p)
 matrix=ROOT/(BASE+STEM+'-matrix.org');matrix.write_text(matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix','Carrier Registry to Physical Root Slots Matrix').replace('GambitCopyProducerEnvelope',PKG).replace('source-and-C11-open','source-root-exception-C23-platform-open'))
 d2=ROOT/(BASE+'diagrams/'+STEM+'.d2');d2.write_text(d2.read_text().replace('legal-input and C11 OPEN','source / roots / exceptions / C23 OPEN'))
 witnesses=[]
 for v in p['source']:
  text=(ROOT/snap[v['path']]['path']).read_text();assert v['needle'] in text,v
  witnesses.append(dict(**v,sha256=snap[v['path']]['sha256'],lines=[text[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),text)]))
 save(CACHE/'source-witnesses.json',witnesses)
 corpus=['vendor/gambit/lib','vendor/gambit/include','vendor/gambit/examples']
 globs=['-g','*.c','-g','*.h','-g','*.inc','-g','*.scm','-g','*.h.in']
 paths=run('writer-corpus',['rg','--files']+corpus+globs).splitlines()
 inventoryInputs={f:sha(ROOT/f) for f in sorted(paths)}
 pattern=r'___gc_root_task_|___gc_origin_|mark_array|___set_data_rc|___register_rc|___addref_rc|___release_rc|cleanup_rc|___cleanup_mem_pstate|___cleanup_mem_vmstate|h->data'
 raw=run('writer-sites',['rg','-n','--no-heading',pattern]+corpus+globs);matches=[]
 for line in raw.splitlines():
  path,no,body=line.split(':',2);matches.append(dict(path=path,line=int(no),text=body.strip()))
 save(CACHE/'source-token-inventory.json',dict(inputs=inventoryInputs,matches=matches,scope=corpus,completeLiteralEnumeration=True,completeWriterAuthorityClosure=False,includesDeclarationsCommentsAndIndirectExports=True))
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
   receipts=[[case,n,path,digest,sc] for n,k,path,digest,sc in needs if case!='current' or n in ['SM-formal','SM-bridge']]
   if case=='missing-formal':receipts=[v for v in receipts if v[1]!='SM-formal']
   if case=='wrong-scope':receipts[0][-1]='native-performance'
   obs=copy.deepcopy(sources)
   if case=='stale-source':obs[0][2]='stale'
   io=copy.deepcopy(issuers)
   if case=='wrong-issuer':io[4][2]='existing-global-last-alias-signer-without-evidence'
   ro=copy.deepcopy(routes)
   if case=='wrong-owner':ro[0][0]='wrong-component'
   if case=='missing-intent-route':ro=[r for r in ro if r[1]!='carrier_slot_mapping.retire0']
   session.replace(dict(scenario=[[case]],need=needs,needOwner=owners,receipt=receipts,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=[v for v in lemmas if (case!='missing-lemma' or v!=['SlotMapping.stepPreserves']) and (case!='missing-projection' or v!=['SlotMappingBridge.parentMembershipObligation'])],sourceNeed=sources,sourceObservation=obs,issuerNeed=issuers,issuerObservation=io,routeNeed=routes,routeObservation=ro,proofNeed=proofs))
   r=session.run(queries=['blocked','candidate','linked','sourceLinked','issuerLinked','routeLinked','proofLinked']);assert r['complete'];results[case]=r['relations']
 finally:engine.close()
 save(CACHE/'ascent-scenario-diagnostics.json',results)
 assert [k for k in cases if results[k]['candidate']]==['synthetic-all'],[k for k in cases if results[k]['candidate']]
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==6,gaps
 assert len(results['current']['routeLinked'])==len(routes)
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))
 # Closure status is an observation over SysML-owned obligations, not a second
 # manually maintained requirement list.
 closure=['','** Closure observation','','| Obligation | Owner | Status | Scoped subject |','|---+---+---+---|']
 for v in p['need'].values():
  status='unresolved' if v['obligationId'] in gaps else 'provided: scoped conditional formal receipt'
  closure.append('| '+' | '.join([v['obligationId'],v['owner.componentId'],status,v['subjectScope']])+' |')
 matrix.write_text(matrix.read_text()+'\n'.join(closure)+'\n')

 run('d2-svg',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT))])
 run('d2-png',['d2','--layout','elk',str(d2.relative_to(ROOT)),str(CACHE/'diagram.png')])
 checks=dict(status='conditional-slot-mapping-and-lifetime-pass-native-integration-denied',languageBaseline='C23',sourceSnapshots=len(snap),sourceAnchors=len(witnesses),issuerRoles=len(issuers),sourceCallSlices=len(slices),componentSourceActionRoutes=len(routes),qntActions=len(actions),qntHistories=13,qntSamples=500,seed=431,leanTheorems=len(lemmas),allStepInduction=True,sysmlScope='self-contained-native-package',wholeDevValidated=False,typedIrControls=4,negativeProofControls=3,literalCallerHits=len(matches),callerCorpusFiles=len(paths),completeSemanticIntentCensus=False,completeWriterAuthorityClosure=False,persistentCoverageNativeQualified=False,ascentScenarios=len(cases),fixedDescriptors=2,fixedPhysicalSlots=2,rawHeaderInventoryIncludesTemplates=True,genericConcurrentKeyedProtocol=False,genericSlotKeyAlgebra=True,genericFiniteCensus=True,nativePointerBijectionProved=False,privateInitializationRefinement=False,payloadBindingProductProved=False,fullUnboundedProductRefinement=False,actualCandidate=False,firstNativeRetirement=False,secondNativeRetirement=False,realIssuerClosure=False,genericSchemeLastAliasSigner=False,compiledRootMapQualified=False,eventualCompletionProved=False,crashRecoveryProved=False,c23RefinementProved=False,blockers=gaps,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 # Native Org parser and link audit, without Babel evaluation.
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for old,new in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(old,new)
 (CACHE/'check-org.el').write_text(org)
 for f,v in snap.items():assert sha(ROOT/f)==v['sha256'],f
 assert sha(parent)==parentHash
 for f,digest in inventoryInputs.items():assert sha(ROOT/f)==digest,('inventory drift',f)
 for f,digest in scope.items():assert sha(ROOT/f)==digest,('sysml drift',f)
 own=[BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'models/sysml/'+STEM+'.sysml',BASE+'models/quint/carrier_slot_mapping.qnt',BASE+'models/lean/SlotMappingAst.lean',BASE+'models/lean/SlotMapping.lean',BASE+'models/lean/SlotMappingBridge.lean',BASE+'models/lean/CarrierCoverageAst.lean',BASE+'models/lean/SlotCensus.lean',BASE+'index.org',BASE+'language-baseline-design.org',BASE+'persistent-carrier-coverage-design.org',str(d2.relative_to(ROOT)),str(d2.with_suffix('.svg').relative_to(ROOT)),'dev/modeling/ascent/'+STEM+'.rules.scm','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/tools/default-lease-admission-study.py','dev/modeling/tools/copy-producer-envelope-study.py','dev/modeling/tools/advantage-architecture-study.py',str((CACHE/'config.json').relative_to(ROOT)),str((CACHE/'source-snapshots.json').relative_to(ROOT))]+[v['path'] for v in snap.values()]
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parentHash,sourceBindings={f:sha(ROOT/f) for f in own},sourceSnapshots=snap,sysmlInputs=scope,lexicalInputs=inventoryInputs))
 def copy_receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr']:shutil.copyfile(f,OUT/f.name)
 copy_receipts();run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 data=json.loads((CACHE/'input.json').read_text());data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);copy_receipts()
 for n in ['negative-lookup-drain','negative-value-dedup','negative-shared-slot-free']:shutil.copytree(CACHE/n,OUT/n,dirs_exist_ok=True)
 for f in CACHE.glob('negative-*.lean'):shutil.copyfile(f,OUT/f.name)
 for d in CACHE.glob('retained-*-failure'):shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':
 if '--formal-only' in sys.argv:formal()
 else:main()
