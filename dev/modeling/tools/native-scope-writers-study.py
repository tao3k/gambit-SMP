#!/usr/bin/env python3
"""NativeScope source-bound architecture and formal research; no native execution."""
import copy,hashlib,importlib.util,json,re,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks/future-frame-commit/native-scope';OUT=ROOT/'evidence/research/future-frame-commit/native-scope'
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2)+'\n')
def rel(p):return str(Path(p).relative_to(ROOT))
def module(n,p):
 s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
helper=module('process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');helper.CACHE=CACHE;run=helper.run

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 startFiles=[BASE/'models/sysml/native-scope-writers.sysml',BASE/'models/quint/native_scope_writers.qnt',BASE/'models/lean/NativeScopeAst.lean',BASE/'models/lean/NativeScope.lean',Path(__file__),ROOT/'dev/modeling/ascent/native-scope-writers.rules.scm']
 formalStart={rel(f):sha(f) for f in startFiles}
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitNativeScopeWriters::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs]
 model=BASE/'models/sysml/native-scope-writers.sysml';cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 raw=json.loads(run('sysml',cmd+[str(model)]));assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 bindings={};witness=[]
 for row in p['source']:
  file=ROOT/row['path'];text=file.read_text();assert row['needle'] in text;h=sha(file);bindings[row['path']]=h
  snap=CACHE/('source-'+h+'.txt');snap.write_text(text)
  witness.append(dict(**row,sha256=h,lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]))
 save(CACHE/'source-witnesses.json',witness)
 qnt=BASE/'models/quint/native_scope_writers.qnt';projector=ROOT/'dev/modeling/tools/native-scope-writers-projection.py';pr=module('projection',projector)
 run('typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')]);ir=json.loads((CACHE/'typed-ir.json').read_text());ast,receipt=pr.generate(ir);assert (BASE/'models/lean/NativeScopeAst.lean').read_text()==ast
 controls={}
 for label in ['binding','field','roster','expression']:
  bad=copy.deepcopy(ir);ds={x['name']:x for x in bad['modules'][0]['declarations']}
  if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
  if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if label=='roster':ds['step']['expr']['args'].pop(0)
  if label=='expression':ds['safe']['expr']['opcode']='not-qualified'
  try:pr.generate(bad)
  except (AssertionError,KeyError):controls[label]='rejected'
  else:raise AssertionError(label)
 save(CACHE/'projection.json',dict(**receipt,controls=controls,irSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(BASE/'models/lean/NativeScopeAst.lean')))
 # Recheck the real parent AST against current typed QNT, not an old filename.
 parentQnt=BASE/'models/quint/future_atomic_owner.qnt';parentProjector=ROOT/'dev/modeling/tools/future-atomic-owner-projection.py'
 run('parent-typecheck',['quint','typecheck',str(parentQnt),'--out',str(CACHE/'owner-typed-ir.json')])
 parentAst,parentReceipt=module('ownerprojection',parentProjector).generate(json.loads((CACHE/'owner-typed-ir.json').read_text()));assert parentAst==(BASE/'models/lean/AtomicOwnerAst.lean').read_text()
 save(CACHE/'owner-projection.json',dict(**parentReceipt,typedIrSha256=sha(CACHE/'owner-typed-ir.json')))
 bindings.update({rel(f):sha(f) for f in [parentQnt,parentProjector]})
 # Compile the actual prior owner AST, not an unbound copy of its field names.
 for name in ['AtomicOwnerAst','NativeScopeAst','NativeScope']:
  f=BASE/'models/lean'/(name+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',f.read_text())
  run('lean-'+name,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(name+'.olean')),str(f)]);bindings[rel(f)]=sha(f)
 text=run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953']);assert text.count('ok ')==5
 run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 # Separate admissibility counterexamples. Each original reachable prefix is
 # checked before intentionally demanding a false admission premise.
 prefixes={
 'unknown-before-record':(['issue','beginWrite','loseResponse','closeAdmission'],'recoverRecordedGuard witness'),
 'retire-before-drain':(['issue','beginWrite','loseResponse','closeAdmission'],'retireGuard witness'),
 'target-before-acquire':(['issue','prepareMigration'],'issueTargetGuard witness'),
 'raw-writer-escape':(['issue','rawInterference'],'CanUse witness'),
 'reuse-outer-view':(['issue','beginWrite','publishRelease','recordOutcome','deliverOutcome','acquire0','enterNested','leaveNested'],'(witness.view=1)'),
 'stale-delivery-is-new-completion':(['issue','beginWrite','recordOutcome','deliverOutcome','prepareMigration','targetAcquire','issueTarget','beginWrite','rejectStaleDelivery'],'(witness.pending=0)')}
 actions=pr.SPEC['actions'];lemmas=['NativeScope.'+n for n in re.findall(r'^\s*theorem (\w+)',(BASE/'models/lean/NativeScope.lean').read_text(),re.M)]
 for key,(seq,goal) in prefixes.items():
  expr='initial';defs=['initial'];gs=[]
  for a in seq:
   gs.append('example : '+a+'Guard ('+expr+') := by simp ['+','.join([a+'Guard']+defs)+']')
   expr=a+'Next ('+expr+')';defs.append(a+'Next')
  expand=','.join(['CanUse','Safe']+[n+'Guard' for n in actions]+defs)
  base='import NativeScope\nopen NativeScopeAst NativeScope\ndef witness : State := '+expr+'\n'+'\n'.join(gs)+'\nexample : Safe witness := by simp ['+expand+',witness]\nexample : ¬ ('+goal+') := by simp ['+expand+',witness]\n'
  original=CACHE/(key+'-original.lean');original.write_text(base);run(key+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(original)])
  bad=CACHE/(key+'-negative.lean');bad.write_text(base+'example : '+goal+' := by simp ['+expand+',witness]\n')
  out=run(key+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(bad)],expected=1);assert out.count('error:')==1
 def rows(g):return [list(r.values()) for r in p[g]]
 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in witness];results={};engine=Engine()
 try:
  session=engine.open_sources((ROOT/'dev/modeling/ascent/native-scope-writers.rules.scm').read_text());assert session.run(queries=['blocked'])['complete']
  for case in ['current','synthetic-all','missing-writer','wrong-storage-domain','forged-issuer','missing-proof','stale-source','numeric-only-rf','wrong-memory-order']:
   source=copy.deepcopy(src);writers=rows('writer');issuers=rows('issuer');routes=rows('route');ls=[[x] for x in lemmas];obs=rows('obligation');mem=rows('memory')
   if case=='current':obs=[r for r in obs if r[1]!='unresolved']
   if case=='missing-writer':writers=writers[:-1]
   if case=='wrong-storage-domain':writers[2][2]='task control word'
   if case=='forged-issuer':issuers[3][3]='TLS address is a scope'
   if case=='missing-proof':ls=[r for r in ls if r!=['NativeScope.issuePreserves']]
   if case=='stale-source':source[0][2]='stale'
   if case=='wrong-memory-order':mem[2][1]='relaxed failure grants acquire view'
   if case=='numeric-only-rf':obs=[r for r in obs if r[0]!='rf-witness']
   session.replace(dict(sourceNeed=src,sourceSeen=source,actionName=[[a] for a in actions],lemmaName=ls,routeNeed=rows('route'),routeSeen=routes,writerNeed=rows('writer'),writerSeen=writers,issuerNeed=rows('issuer'),issuerSeen=issuers,obligation=rows('obligation'),qualified=obs,memoryNeed=rows('memory'),memorySeen=mem))
   result=session.run(queries=['blocked','candidate','routeLinked','writerLinked','issuerLinked','memoryLinked']);assert result['complete'];results[case]=result['relations']
 finally:engine.close()
 assert [c for c,r in results.items() if r['candidate']]==['synthetic-all'];save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: NativeScope issuance and closed native writers — evidence and net return','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitNativeScopeWriters',':END:','These rows are generated by the native SysML evaluator. Conditional formal closure is not runtime admission.']
 for g in ['issuer','writer','obligation','memory','gain','route','source']:
  fs=list(p[g][0]);matrix+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(str(r[f]).replace('|',' / ') for f in fs)+' |' for r in p[g]]
 (BASE/'native-scope-writers-matrix.org').write_text('\n'.join(matrix)+'\n')
 d2=BASE/'diagrams/native-scope-writers.d2';d2.write_text('direction: down\ntitle: "C23 NativeScope: real entry cuts, writer closure and retained unknowns"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 files=[model,qnt,projector,Path(__file__),ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py',ROOT/'dev/modeling/ascent/native-scope-writers.rules.scm',BASE/'native-scope-writers-design.org',BASE/'native-scope-writers-matrix.org',BASE/'index.org',BASE/'runtime-blueprint.org',BASE/'future-frame-commit-design.org',d2,d2.with_suffix('.svg'),CACHE/'config.json']
 bindings.update({rel(f):sha(f) for f in files});assert all(sha(ROOT/f)==h for f,h in formalStart.items());assert all(sha(ROOT/f)==h for f,h in bindings.items())
 checks=dict(sourceAnchors=len(src),issuerRows=len(p['issuer']),writerClasses=len(p['writer']),memoryContracts=len(p['memory']),qntFields=len(pr.SPEC['fields']),qntActions=len(actions),histories=5,samples=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,typedIrNegativeControls=len(controls),admissionCounterexamples=len(prefixes),ascentScenarios=len(results),nativeAdmission=False,fullProductSimulation=False,actualReadsFromProof=False,rootCoverageIsPremise=True,nativePathsRetired=0,runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,performanceTests=False,unresolved=[r['key'] for r in p['obligation'] if r['status']=='unresolved'])
 save(CACHE/'checks.json',checks);save(CACHE/'input.json',dict(sourceBindings=bindings,leanBinarySha256=sha(LEAN),parentOwnerAstSha256=sha(BASE/'models/lean/AtomicOwnerAst.lean')))
 save(OUT/'checks.json',dict(checks,validationComplete=False))
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text();org=org.replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/native-scope-writers-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/native-scope-writers-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org');(CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 checks['validationComplete']=True;save(CACHE/'checks.json',checks)
 for f in CACHE.rglob('*'):
  if f.is_file():t=OUT/f.relative_to(CACHE);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,t)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'});print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
