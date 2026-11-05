#!/usr/bin/env python3
"""Native prefix effect and root-permission research: native SysML, ASCENT, QNT and Lean; no runtime work."""
import copy,hashlib,importlib.util,json,re,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks/future-frame-commit/native-prefix';OUT=ROOT/'evidence/research/future-frame-commit/native-prefix'
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
 model=BASE/'models/sysml/native-prefix-permission.sysml';qnt=BASE/'models/quint/native_prefix_permission.qnt';projector=ROOT/'dev/modeling/tools/native-prefix-permission-projection.py';proof=BASE/'models/lean/NativePrefix.lean';astFile=BASE/'models/lean/NativePrefixAst.lean';dsl=ROOT/'dev/modeling/ascent/native-prefix-permission.rules.scm'
 startFiles=[model,qnt,projector,proof,astFile,dsl,Path(__file__),ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py'];bindings={rel(f):sha(f) for f in startFiles}
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitNativePrefixPermission::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs];cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,e in keys:cmd+=['-e',e]
 raw=json.loads(run('sysml',cmd+[str(model)]));assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 sources=[]
 for row in p['source']:
  f=ROOT/row['path'];text=f.read_text();assert row['needle'] in text;h=sha(f);bindings[row['path']]=h;(CACHE/('source-'+h+'.txt')).write_text(text)
  sources.append(dict(**row,sha256=h,lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]))
 save(CACHE/'source-witnesses.json',sources)
 run('typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')]);ir=json.loads((CACHE/'typed-ir.json').read_text());pr=module('projection',projector);ast,receipt=pr.generate(ir);assert astFile.read_text()==ast;actions=pr.SPEC['actions'];controls={}
 for label in ['binding','field','roster','expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
  if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if label=='roster':ds['step']['expr']['args'].pop(0)
  if label=='expression':ds['safe']['expr']['opcode']='not-qualified'
  try:pr.generate(bad)
  except (AssertionError,KeyError):controls[label]='rejected'
  else:raise AssertionError(label)
 save(CACHE/'projection.json',dict(**receipt,controls=controls,irSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(astFile)))
 parent=ROOT/'evidence/research/future-frame-commit/native-entry';pi=json.loads((parent/'input.json').read_text());pa=json.loads((parent/'artifacts.json').read_text());parentBound={};assert sha(LEAN)==pi['leanBinarySha256']
 closure=['AtomicOwnerAst','NativeScopeAst','NativeScope','NativeEntryAst','NativeEntry']
 for n in closure:
  f=BASE/'models/lean'/(n+'.lean');assert sha(f)==pi['sourceBindings'][rel(f)];bindings[rel(f)]=sha(f);o=parent/(n+'.olean');assert sha(o)==pa[rel(o)];shutil.copyfile(o,CACHE/o.name);parentBound[rel(f)]=dict(sourceSha256=sha(f),objectSha256=sha(o))
 for name in ['native_scope_writers','future_atomic_owner','native_entry_admission']:
  f=BASE/'models/quint'/(name+'.qnt');assert sha(f)==pi['sourceBindings'][rel(f)];bindings[rel(f)]=sha(f)
 for name in ['native-scope-writers','future-atomic-owner','native-entry-admission']:
  f=ROOT/'dev/modeling/tools'/(name+'-projection.py');assert sha(f)==pi['sourceBindings'][rel(f)];bindings[rel(f)]=sha(f)
 assert sha(ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py')==pi['sourceBindings']['dev/modeling/tools/chunk-capacity-charge-projection.py']
 save(CACHE/'parent-proof-reuse.json',dict(bound=parentBound,parentInputSha256=sha(parent/'input.json'),leanBinarySha256=sha(LEAN),freshBoundaryOnly=True,fullProductSimulation=False))
 for n in ['NativePrefixAst','NativePrefix']:
  f=BASE/'models/lean'/(n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',f.read_text());run('lean-'+n,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(n+'.olean')),str(f)])
 lemmas=['NativePrefix.'+n for n in re.findall(r'^theorem (\w+)',proof.read_text(),re.M)]
 for row in p['component']:assert all(a in actions for a in row['actionSlice'].split('/')) and row['proof'] in lemmas
 histories=re.findall(r'^run (\w+Test)=',qnt.read_text(),re.M);t=run('histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953']);assert t.count('ok ')==len(histories)
 run('samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 prefixes={
 'collecting-is-fast':(['selectCollecting'],'grantFastGuard witness'),
 'wrong-self-durable':(['selectWrongSelf'],'grantDurableGuard witness'),
 'opaque-durable':(['selectOpaque'],'grantDurableGuard witness'),
 'debug-is-fast':(['selectDebugIO'],'grantFastGuard witness'),
 'stale-binding':(['selectPlain','replaceBeforeGrant'],'grantFastGuard witness'),
 'raw-local-across-callback':(['selectReentrant','grantDurable','beginAllocation','obtainNativeMemory','enterHook','gcRound','returnHook','captureOutcome'],'publishInputsGuard witness'),
 'uncaptured-is-recoverable':(['selectAbandoning','grantDurable','beginAllocation','obtainNativeMemory','abandonBeforeRecord'],'recoverPrivateRecordGuard witness'),
 'uncaptured-can-rollback':(['selectAbandoning','grantDurable','beginAllocation','obtainNativeMemory','abandonBeforeRecord'],'rollbackPlainGuard witness'),
 'published-fast-gc-before-bank':(['selectPlain','grantFast','beginAllocation'],'gcRoundGuard witness'),
 'closed-preparation-admission':(['selectPlain','closeAdmission'],'grantFastGuard witness')}
 for name,(seq,goal) in prefixes.items():
  e='initial';defs=['initial'];gs=[]
  for a in seq:
   gs+=['example : '+a+'Guard ('+e+') := by simp ['+','.join([a+'Guard']+defs)+']'];e=a+'Next ('+e+')';defs+=[a+'Next']
  simp=','.join(['Safe','witness']+defs+[n+'Guard' for n in actions]);text='import NativePrefix\nopen NativePrefixAst NativePrefix\ndef witness : State := '+e+'\n'+'\n'.join(gs)+'\nexample : Safe witness := by simp ['+simp+']\nexample : ¬ ('+goal+') := by simp ['+simp+']\n'
  f=CACHE/(name+'-original.lean');f.write_text(text);run(name+'-original',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)])
  f=CACHE/(name+'-negative.lean');f.write_text(text+'example : '+goal+' := by simp ['+simp+']\n');err=run(name+'-negative',['env','LEAN_PATH='+str(CACHE),LEAN,str(f)],expected=1);assert err.count('error:')==1
 def rows(g):return [list(r.values()) for r in p[g]]
 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources];results={};engine=Engine()
 cases=['current','synthetic-all','missing-callee','unqualified-external','wrong-self-fast','proc-root-only','debug-auto-fast','missing-entry-join','stale-binding-source','missing-lemma','mutable-table-after-grant','unknown-is-failed','component-filename-only','direct-signal-callback']
 external=[[r['key'],r['effect']] for r in p['call'] if r['status']=='external-unresolved']
 try:
  session=engine.open_sources(dsl.read_text());assert session.run(queries=['blocked'])['complete']
  for case in cases:
   so=copy.deepcopy(src);ca=rows('call');prf=rows('profile');iss=rows('issuer');jo=rows('join');co=rows('component');ls=[[l] for l in lemmas];qualified=rows('obligation');ex=copy.deepcopy(external)
   if case=='current':qualified=[r for r in qualified if r[1]!='unresolved'];ex=[]
   if case=='missing-callee':ca=ca[1:]
   if case=='unqualified-external':ex=ex[1:]
   if case=='wrong-self-fast':prf[5][3]='fast despite wrong source identity'
   if case=='proc-root-only':iss[2][3]='procedure root alone covers every raw Scheme argument'
   if case=='debug-auto-fast':prf[6][3]='fast because no direct GC call appears'
   if case=='missing-entry-join':jo=jo[:-2]
   if case=='stale-binding-source':so=[r[:2]+['stale-slot-generation']+r[3:] if r[0]=='ext-mode' else r for r in so]
   if case=='missing-lemma':ls=[r for r in ls if r!=['NativePrefix.grantFastPreserves']]
   if case=='mutable-table-after-grant':ca=[r[:4]+['table may be rewritten after permission is issued']+r[5:] if r[0]=='binding-mode' else r for r in ca]
   if case=='unknown-is-failed':iss[3][4]='timeout frees uncaptured allocation and source root'
   if case=='component-filename-only':co[0][3]='NativePrefix.fileExists'
   if case=='direct-signal-callback':ca=[r[:4]+['default heartbeat immediately executes Scheme']+r[5:] if r[0]=='default-signal' else r for r in ca]
   session.replace(dict(sourceNeed=src,sourceSeen=so,obligation=rows('obligation'),qualified=qualified,actionName=[[n] for n in actions],lemmaName=ls,routeNeed=rows('route'),routeSeen=rows('route'),callNeed=rows('call'),callSeen=ca,externalNeed=external,externalQualified=ex,profileNeed=rows('profile'),profileSeen=prf,issuerNeed=rows('issuer'),issuerSeen=iss,joinNeed=rows('join'),joinSeen=jo,componentNeed=rows('component'),componentSeen=co))
   result=session.run(queries=['blocked','candidate','routeLinked','callLinked','externalLinked','profileLinked','issuerLinked','joinLinked','componentLinked']);assert result['complete'];results[case]=result['relations']
 finally:engine.close()
 assert [c for c,r in results.items() if r['candidate']]==['synthetic-all'];save(CACHE/'ascent-results.json',dict(results=results,syntheticIsNotNativeEvidence=True))
 matrix=['#+TITLE: SFUN/Tcl prefix effects — source closure and root-permission return','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitNativePrefixPermission',':END:','Protocol safety and the actual NativeEntry publish step join are conditional. Native effect closure remains unresolved.']
 for group in ['component','profile','call','issuer','obligation','gain','join','route','source']:
  fs=list(p[group][0]);matrix+=['','** '+group.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(str(r[f]).replace('|',' / ') for f in fs)+' |' for r in p[group]]
 (BASE/'native-prefix-permission-matrix.org').write_text('\n'.join(matrix)+'\n')
 d2=BASE/'diagrams/native-prefix-permission.d2';d2.write_text('direction: down\ntitle: "C23 prefix permission: effects, identity, root coverage and capture"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 checks=dict(sourceAnchors=len(sources),callerEdges=len(p['call']),externalLeaves=len(external),profiles=len(p['profile']),components=len(p['component']),jointIssuers=len(p['issuer']),qntFields=len(pr.SPEC['fields']),qntActions=len(actions),histories=len(histories),samples=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,actualNativeEntryStepJoin=True,fullProductSimulation=False,typedIrNegativeControls=len(controls),admissionCounterexamples=len(prefixes),ascentScenarios=len(cases),nativeAdmission=False,actualEffectClosure=False,effectiveBinaryQualified=False,sourceSetCoverageIsPremise=True,allocationCaptureIsPremise=True,globalClosureSelfFound=True,dynamicClosureOnArm64Claim=False,nativePathsRetired=0,runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,performanceTests=False,unresolved=[r['key'] for r in p['obligation'] if r['status']=='unresolved'])
 save(CACHE/'checks.json',checks);save(OUT/'checks.json',dict(checks,validationComplete=False))
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/native-prefix-permission-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/native-prefix-permission-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org');(CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 checks['validationComplete']=True;save(CACHE/'checks.json',checks)
 for f in [BASE/'native-prefix-permission-design.org',BASE/'native-prefix-permission-matrix.org',BASE/'index.org',BASE/'runtime-blueprint.org',BASE/'native-entry-admission-design.org',d2,d2.with_suffix('.svg'),CACHE/'config.json']:
  bindings[rel(f)]=sha(f)
 assert all(sha(ROOT/f)==h for f,h in bindings.items());save(CACHE/'input.json',dict(sourceBindings=bindings,leanBinarySha256=sha(LEAN),parentInputSha256=sha(parent/'input.json'),runtimeClaim=False))
 for f in CACHE.rglob('*'):
  if f.is_file():t=OUT/f.relative_to(CACHE);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,t)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'});print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
