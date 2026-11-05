#!/usr/bin/env python3
"""Formal/source research only. Native SysML owns architecture and proof metadata."""
import copy,importlib.util,json,re,shutil,sys,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM='default-lease-admission';BASE='dev/refactoring/modern-c/';PKG='GambitDefaultLeaseAdmission'
CACHE=ROOT/'.cache/tasks'/STEM;OUT=ROOT/'evidence/research'/STEM
MODEL=BASE+'models/sysml/'+STEM+'.sysml';QNT=BASE+'models/quint/default_section_leases.qnt'
DESIGN=BASE+STEM+'-design.org';MATRIX=BASE+STEM+'-matrix.org';D2=BASE+'diagrams/'+STEM+'.d2'
RULES='dev/modeling/ascent/'+STEM+'.rules.scm';EMITTER='dev/modeling/tools/'+STEM+'-projection.py'
def load(name,path):
 s=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
h=load('research_helper','dev/modeling/tools/advantage-architecture-study.py');h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[['source', 35, 'key path needle obligation'], ['call', 28, 'key path callerName callee siteCount scope'], ['claim', 5, 'key mechanism condition result gap'], ['policy', 7, 'key sourcePath policyAction why migration'], ['receipt', 6, 'key issuer prerequisite failure gap'], ['memory', 5, 'key obligation reuse cost'], ['gain', 5, 'key avoided added condition'], ['contract', 14, 'fromNode toNode custody'], ['obligation', 6, 'key status scope gap'], ['binding', 30, 'actionName lemma scope'], ['proof', 16, 'key lemma scope'], ['seam', 4, 'producer.moduleId consumer.moduleId contract modelNeed'], ['bridge', 1, 'key targetStep lemma scope']]
SLOTS=['leasesHistory','collectiveHistory','leasesInduction','collectiveInduction','composition','projection','source','platform']
def project():
 keys=[(g,str(i),f,f'{PKG}::{g}{i}.{f}') for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [('need',s,f,f'{PKG}::{s}.{f}') for s in SLOTS for f in ['obligationId','kind','subjectPath','subjectScope','owner.componentId']]
 scope={p:sha(ROOT/p) for p in sorted(run('sysml-inputs',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines())};save(CACHE/'sysml-input-scope.json',scope)
 args=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,e in keys:args+=['-e',e]
 try:
  raw=json.loads(run('sysml-all',args+['dev']))
  save(CACHE/'global-sysml-status.json',dict(status='pass',loaded=len(scope)))
 except RuntimeError:
  raw=json.loads((CACHE/'sysml-all.stdout').read_text());errors=[d for d in raw.get('diagnostics',[]) if d['severity']=='error']
  excluded='dev/refactoring/modern-c/models/sysml/copy-custody.sysml'
  assert errors and all(d.get('file')==excluded for d in errors),errors
  # No other package references this concurrently edited package. Native resolution
  # of the remaining graph must still succeed; no diagnostics are downgraded.
  save(CACHE/'global-sysml-status.json',dict(status='blocked-by-independent-model',errors=errors,excluded={excluded:scope[excluded]},wholeDevValidated=False))
  scope={f:d for f,d in scope.items() if f!=excluded};save(CACHE/'sysml-input-scope.json',scope)
  raw=json.loads(run('sysml',args+list(scope)))
 assert raw['exit']==0 and not raw.get('errors') and not any(d['severity']=='error' for d in raw.get('diagnostics',[])),raw
 vals=[json.loads(x[4:]) for x in raw['output'] if x.startswith('  = ')];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/'projection.json',p);save(CACHE/'native-queries.json',keys);return p,scope

def views(p):
 def cell(s):return str(s).replace('\n',r'\n').replace('|',r'\vert{}')
 lines=['#+TITLE: Default Section Leases — Physical Ownership and Collective Admission Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitDefaultLeaseAdmission',':STATUS: conditional-formal-model; native-and-C11-open',':END:']
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
 rows=[];sites=[]
 for path in sorted({v['path'] for v in p['call']}):
  sv=snapshots[path];text=(ROOT/sv['path']).read_text()
  mask=re.compile(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',re.S)
  clean=mask.sub(lambda m:''.join('\n' if x=='\n' else ' ' for x in m.group()),text)
  decls=list(re.finditer(r'^.*?\b(\w+)\s*\n\s+___P\(',clean,re.M))
  need=[v for v in p['call'] if v['path']==path];actual=[]
  for f in sorted({v['callee'] for v in need}):
   for hit in re.finditer(r'\b'+re.escape(f)+r'\s*\(',clean):
    owner=[d for d in decls if d.start()<hit.start()];assert owner,f
    actual.append(dict(path=path,callee=f,caller=owner[-1].group(1),line=text[:hit.start()].count('\n')+1))
  assert {(v['caller'],v['callee']) for v in actual}=={(v['callerName'],v['callee']) for v in need}
  for v in need:
   count=sum(1 for x in actual if (x['caller'],x['callee'])==(v['callerName'],v['callee']));assert count==int(v['siteCount']),v
   rows.append([v['key'],v['callerName'],v['callee'],v['siteCount'],sv['sha256']])
  sites+=actual
 save(CACHE/'caller-audit.json',dict(status='pass-lexical-snapshot',rows=rows,sites=sites,effectivePreprocessedCallGraph=False))
 return rows

def formal_files(e):
 return [EMITTER,'dev/modeling/tools/chunk-capacity-charge-projection.py']+[BASE+'models/'+suffix for cfg in e.SPECS for suffix in ['quint/'+cfg['module']+'.qnt','lean/'+cfg['namespace']+'.lean','lean/'+cfg['proof']+'.lean']]+[BASE+'models/lean/'+n+'.lean' for n in ['DefaultLeaseComposition','CapacityChargeAst','CapacityCharge']]

def formals():
 e=load('lease_emitter',EMITTER)
 for cfg in e.SPECS:
  ir=json.loads((CACHE/(cfg['module']+'.json')).read_text());ast,rc=e.generate(ir,cfg);(ROOT/(BASE+'models/lean/'+cfg['namespace']+'.lean')).write_text(ast)
  save(CACHE/(cfg['module']+'-projection.json'),dict(**rc,typedIrSha256=sha(CACHE/(cfg['module']+'.json')),astSha256=sha(ROOT/(BASE+'models/lean/'+cfg['namespace']+'.lean'))))
  controls={}
  for case in ['wrong-state-binding','wrong-field-kind','missing-step','unsupported-expression']:
   bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
   if case=='wrong-state-binding':bad['table'][str(rc['stateReferences'][0][0])]['id']=-1
   if case=='wrong-field-kind':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
   if case=='missing-step':ds['step']['expr']['args'].pop(0)
   if case=='unsupported-expression':ds['safe']['expr']['opcode']='unsupported'
   try:e.generate(bad,cfg)
   except (AssertionError,KeyError):controls[case]='rejected'
   else:raise AssertionError('accepted '+case)
  save(CACHE/(cfg['module']+'-projection-controls.json'),controls)
 # Re-extract exact old charge AST and bind its proof to the prior input.
 old=load('old_charge_projection','dev/modeling/tools/chunk-capacity-charge-projection.py');cfg=old.SPEC;oldir=ROOT/'evidence/research/chunk-capacity-charge/chunk_capacity_charge.json';ir=json.loads(oldir.read_text());a,rr=old.generate(ir,cfg['module'],cfg['fields'],cfg['actions'],cfg['namespace'])
 assert a==(ROOT/(BASE+'models/lean/CapacityChargeAst.lean')).read_text()
 parent=json.loads((ROOT/'evidence/research/chunk-capacity-charge/input.json').read_text())
 for n in ['CapacityChargeAst','CapacityCharge']:
  f=BASE+'models/lean/'+n+'.lean';assert sha(ROOT/f)==parent['sourceBindings'][f],f
 save(CACHE/'target-projection.json',dict(**rr,typedIrSha256=sha(oldir),targetAstSha256=sha(ROOT/(BASE+'models/lean/CapacityChargeAst.lean'))))
 if '--reuse-formal' in sys.argv:
  checkpoint=json.loads((CACHE/'formal-checkpoint.json').read_text())
  for f,d in checkpoint['sourceBindings'].items():assert sha(ROOT/f)==d,f
  for f,d in checkpoint['logs'].items():assert sha(ROOT/f)==d,f
 else:
  for cf,nt in zip(e.SPECS,[9,10],strict=True):
   q=BASE+'models/quint/'+cf['module']+'.qnt';test=run(cf['module']+'-tests',['quint','test',q,'--match','Test$']);assert test.count('ok ')==nt and test.count('ControlTest passed')==4
   run(cf['module']+'-samples',['quint','run',q,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','97','--verbosity','1'])
  for n in ['SectionLeasesAst','SectionLeases','CapacityCollectiveAst','CapacityCollective','CapacityChargeAst','CapacityCharge','DefaultLeaseComposition']:
   f=CACHE/(n+'.lean');orig=ROOT/(BASE+'models/lean/'+n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',orig.read_text())
   if '--reuse-compiled' in sys.argv:assert f.read_bytes()==orig.read_bytes() and (CACHE/(n+'.olean')).is_file() and 'error:' not in (CACHE/(n+'.stdout')).read_text(),n
   else:f.write_bytes(orig.read_bytes());run(n,['env','LEAN_PATH='+str(CACHE),'lean','-o',str(CACHE/(n+'.olean')),str(f)])
  for cf in e.SPECS:
   ast=(ROOT/(BASE+'models/lean/'+cf['namespace']+'.lean')).read_text();neg=CACHE/('negative-'+cf['proof']);neg.mkdir(exist_ok=True)
   if cf['proof']=='SectionLeases':bad='\n'.join(line.replace('owner4:=(0)','owner4:=(1)') if line.startswith('def fresh4worker0Next') else line for line in ast.splitlines())+'\n'
   else:bad='\n'.join(line.replace('(q.ack1=true)','True') if line.startswith('def releaseGuard') else line for line in ast.splitlines())+'\n'
   assert bad!=ast;f=neg/(cf['namespace']+'.lean');f.write_text(bad);run('negative-'+cf['proof']+'-ast',['lean','-o',str(neg/(cf['namespace']+'.olean')),str(f)])
   try:run('negative-'+cf['proof']+'-proof',['env','LEAN_PATH='+str(neg)+':'+str(CACHE),'lean',str(ROOT/(BASE+'models/lean/'+cf['proof']+'.lean'))])
   except RuntimeError:assert 'error:' in (CACHE/('negative-'+cf['proof']+'-proof.stdout')).read_text()
   else:raise AssertionError('mutant proved '+cf['proof'])
  neg=CACHE/'negative-composition';neg.mkdir(exist_ok=True);orig=(ROOT/(BASE+'models/lean/DefaultLeaseComposition.lean')).read_text();bad=orig.replace('c.decision=1','c.decision=2');assert bad!=orig;f=neg/'DefaultLeaseComposition.lean';f.write_text(bad)
  try:run('negative-composition',['env','LEAN_PATH='+str(CACHE),'lean',str(f)])
  except RuntimeError:assert 'error:' in (CACHE/'negative-composition.stdout').read_text()
  else:raise AssertionError('bad collective product proved')
  save(CACHE/'formal-checkpoint.json',dict(sourceBindings={f:sha(ROOT/f) for f in formal_files(e)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and any(k in f.name for k in ['SectionLeases','CapacityCollective','CapacityCharge','DefaultLeaseComposition','-tests','-samples','negative-'])}))
 acts=[[cf['module']+'.'+a] for cf in e.SPECS for a in cf['actions']]
 targets=[['chunk_capacity_charge.'+a] for a in old.SPEC['actions']+['step','stutter']]
 lemmas=[[n+'.'+x] for n in ['SectionLeases','CapacityCollective','DefaultLeaseComposition'] for x in re.findall(r'^\s*theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
 return e,acts,targets,lemmas

def ascend(p,w,acts,targets,lemmas,calls):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 binds=[[v['actionName'],v['lemma']] for v in p['binding']];ws=[[v['key'],v['path'],v['sha256'],v['needle']] for v in w];proofs=[[v['key'],v['lemma']] for v in p['proof']];bridges=[[v['key'],v['targetStep'],v['lemma']] for v in p['bridge']]
 queries=['checked','blocked','candidate','linked','observed','compositionLinked','callLinked','bridgeLinked']
 cases=['current','synthetic-all','stale-hash','wrong-scope','missing-source','missing-platform','missing-action','missing-restore-proof','missing-target','missing-collective-proof','missing-witness','wrong-caller','wrong-count','wrong-source-digest','missing-collective-receipt']
 engine=h.Engine();results={}
 try:
  ss=engine.open_sources((ROOT/RULES).read_text());assert ss.run(queries=queries)['complete']
  for case in cases:
   rc=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction','restricted-projection']]
   if case=='stale-hash':rc[0][3]='stale'
   if case=='wrong-scope':rc[0][4]='whole-native-closed'
   for label,n in [('missing-source','DL-source'),('missing-platform','DL-platform'),('missing-collective-receipt','DL-collectiveInduction')]:
    if case==label:rc=[v for v in rc if v[1]!=n]
   ac=[v for v in acts if case!='missing-action' or v!=['capacity_collective.release']]
   ls=[v for v in lemmas if (case!='missing-restore-proof' or v!=['DefaultLeaseComposition.restoredStackSeparate']) and (case!='missing-collective-proof' or v!=['CapacityCollective.flipRequiresAllAcknowledged'])]
   ts=[v for v in targets if case!='missing-target' or v!=['chunk_capacity_charge.advanceVisit']]
   obs=copy.deepcopy(calls)
   if case=='wrong-caller':obs[0][1]='not-the-caller'
   if case=='wrong-count':obs[0][3]='99'
   if case=='wrong-source-digest':obs[0][4]='stale'
   ss.replace(dict(scenario=[[case]],need=needs,receipt=rc,binding=binds,actionName=ac,lemmaName=ls,witness=ws,observation=ws[1:] if case=='missing-witness' else ws,compositionNeed=proofs,refinementNeed=[],targetActionName=ts,callNeed=calls,callObservation=obs,bridgeNeed=bridges))
   result=ss.run(queries=queries);assert result['complete'];results[case]=result['relations']
  assert results['synthetic-all']['candidate']
  for c in cases:
   if c!='synthetic-all':assert not results[c]['candidate'],c
  a=results['current'];assert {v[1] for v in a['blocked']}=={'DL-source','DL-platform'}
  assert [len(a[k]) for k in ['linked','compositionLinked','callLinked','bridgeLinked']]==[30,16,28,1]
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotEvidence=True))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/chunk-capacity-charge/input.json';parentHash=sha(parent)
 snapshots=json.loads((CACHE/'source-snapshots.json').read_text())
 for v in snapshots.values():assert sha(ROOT/v['path'])==v['sha256']
 p,scope=project();views(p);w=[]
 for v in p['source']:
  sv=snapshots[v['path']];t=(ROOT/sv['path']).read_text();assert v['needle'] in t,v['key'];w.append(dict(**v,snapshotPath=sv['path'],sha256=sv['sha256'],lines=[t[:m.start()].count('\n')+1 for m in re.finditer(re.escape(v['needle']),t)]))
 save(CACHE/'source-witnesses.json',w);save(OUT/'source-witnesses.json',w)
 calls=caller_audit(p,snapshots);shutil.copyfile(CACHE/'caller-audit.json',OUT/'caller-audit.json')
 if '--reuse-formal' not in sys.argv:
  e=load('lease_emitter_for_typecheck',EMITTER)
  for cf in e.SPECS:run(cf['module']+'-typecheck',['quint','typecheck',BASE+'models/quint/'+cf['module']+'.qnt','--out',str(CACHE/(cf['module']+'.json'))])
 e,ac,ts,ls=formals();ascend(p,w,ac,ts,ls,calls)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 org=org.replace('(missing nil))','(missing nil) (external-missing nil))')
 org=org.replace('(unless (file-exists-p target) (push (list file target) missing))','(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "default[-_]lease[-_]admission\\\\|DefaultLease\\\\|SectionLeases\\\\|CapacityCollective" target))) (push (list file target) external-missing) (push (list file target) missing)))')
 org=org.replace('missing=%S; no Babel executed" (length files) links missing','missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 assert sha(parent)==parentHash
 drift=[dict(path=f,analyzed=v['sha256'],live=sha(ROOT/f)) for f,v in snapshots.items() if sha(ROOT/f)!=v['sha256']]
 scopeDrift=[dict(path=f,checked=d,live=sha(ROOT/f)) for f,d in scope.items() if sha(ROOT/f)!=d]
 checks=dict(status='conditional-default-lease-collective-model-pass',sysmlInputs=len(scope),sourceAnchors=len(w),literalCallClasses=len(calls),qntModels=2,qntActions=len(ac),qntHistories=19,negativeQntControls=8,samplesPerModel=500,maxSteps=200,leanTheorems=len(ls),allStepInduction=True,guardedProductProved=True,generalCountBoundProved=True,conditionalIntervalGeometryProved=True,actualPriorChargeGuardBridged=True,projectionControls=8,negativeLeanControls=3,ascentScenarios=15,actualCandidate=False,sourceQualified=False,c11Refinement=False,legalSchemeRestoreCounterexample=False,sourceRestoreBound=False,arbitraryRosterRefinement=False,fullMultiContextChargeComposition=False,realCollectiveReceiptIssuer=False,fairnessProved=False,parserVerified=False,emitterVerified=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[],liveSourceDrift=drift,concurrentScopeDrift=scopeDrift)
 save(CACHE/'checks.json',checks)
 files=set(formal_files(e))|{MODEL,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py'}|{v['path'] for v in snapshots.values()}
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceSnapshots=snapshots,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name not in ['artifacts.json','final-audit.json']})
 print(json.dumps(checks))
if __name__=='__main__':main()
