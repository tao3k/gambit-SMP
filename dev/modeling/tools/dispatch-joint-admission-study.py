#!/usr/bin/env python3
"""C23 Tcl source custody research; native SysML, ASCENT, QNT and Lean only."""
import copy,hashlib,importlib.util,json,re,shutil,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TASK='dispatch-joint-admission';BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks'/TASK;OUT=ROOT/'evidence/research'/TASK
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def rel(p):return str(Path(p).relative_to(ROOT))
def loadmod(n,p):
 s=importlib.util.spec_from_file_location(n,p);m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
helper=loadmod('process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');helper.CACHE=CACHE;run=helper.run

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitDispatchJointAdmission::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs.split()]
 model=BASE/'models/sysml'/f'{TASK}.sysml';modelHash=sha(model);cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 raw=json.loads(run('sysml',cmd+[str(model)]));assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 bindings={};sources=[];snaps=CACHE/'source-snapshots';snaps.mkdir(exist_ok=True)
 for row in p['source']:
  file=ROOT/row['path'];b=file.read_bytes();text=b.decode();assert row['needle'] in text;digest=sha(file);snapshot=snaps/(digest+'.txt')
  if snapshot.exists():assert snapshot.read_bytes()==b
  else:snapshot.write_bytes(b)
  sources.append(dict(**row,sha256=digest,snapshot=rel(snapshot),lines=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]));bindings[row['path']]=digest
 old=CACHE/'source-witnesses.json'
 if old.exists():shutil.copyfile(old,CACHE/('source-witnesses-'+str(time.time_ns())+'.json'))
 save(old,sources)
 pinned=json.loads((CACHE/'pinned-tcl-sources.json').read_text())
 for r in pinned['records']:
  f=ROOT/r['capturePath'];b=f.read_bytes();assert sha(f)==r['sha256'] and hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()==r['gitBlobSha1']
 paper=json.loads((CACHE/'pvm-paper-source.json').read_text())
 for name,h in paper['files'].items():
  file=CACHE/name;assert sha(file)==h;canonical=ROOT/paper['canonicalFiles'][name];assert sha(canonical)==h;bindings[rel(canonical)]=h
 parent=ROOT/'evidence/research/tcl-source-borrow/input.json';parentHash=sha(parent);pdata=json.loads(parent.read_text());parentAst=BASE/'models/lean/TclBorrowAst.lean';assert pdata['sourceBindings'][rel(parentAst)]==sha(parentAst);bindings[rel(parentAst)]=sha(parentAst)
 for name in ['TclRefusalAst.lean']:
  f=BASE/'models/lean'/name;assert pdata['sourceBindings'][rel(f)]==sha(f);bindings[rel(f)]=sha(f)
 save(CACHE/'parent-currentness.json',dict(parentSha256=parentHash,formalParentUnchanged=True,nativeEvidenceReused=False,drift=[dict(path=k,previous=v,current=sha(ROOT/k)) for k,v in pdata['sourceBindings'].items() if sha(ROOT/k)!=v]))
 data=json.loads((CACHE/'model-data.json').read_text());asts={};actions=[];projections=[];formal=[model,parentAst,Path(__file__),ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']
 for group,d in data.items():
  qnt=BASE/'models/quint'/(d['name']+'.qnt');projector=ROOT/'dev/modeling/tools'/(d['name'].replace('_','-')+'-projection.py');mod=loadmod(group,projector)
  run(group+'-typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/(group+'-ir.json'))]);ir=json.loads((CACHE/(group+'-ir.json')).read_text());ast,receipt=mod.generate(ir);assert (BASE/'models/lean'/(d['namespace']+'.lean')).read_text()==ast;asts[group]=ast
  controls={}
  for label in ['binding','field','roster','expression']:
   bad=copy.deepcopy(ir);ds={x['name']:x for x in bad['modules'][0]['declarations']}
   if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
   if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
   if label=='roster':ds['step']['expr']['args'].pop(0)
   if label=='expression':ds['safe']['expr']['opcode']='not-qualified'
   try:mod.generate(bad)
   except (AssertionError,KeyError):controls[label]='rejected'
   else:raise AssertionError(label)
  save(CACHE/(group+'-projection.json'),dict(**receipt,typedIrSha256=sha(CACHE/(group+'-ir.json')),astSha256=sha(BASE/'models/lean'/(d['namespace']+'.lean')),controls=controls));projections.append(receipt)
  actions += [[d['name']+'.'+a] for a in d['actions']];formal += [qnt,projector]
 modules=['TclBorrowAst','TclRefusalAst','DispatchJointAst']+json.loads((CACHE/'proof-modules.json').read_text());lemmas=[];formal += [BASE/'models/lean'/(n+'.lean') for n in modules];formalStart={rel(f):sha(f) for f in formal}
 proofInputs={k:v for k,v in formalStart.items() if k.endswith(('.lean','.qnt')) or 'projection.py' in k};proofInputs['leanBinary']=sha(LEAN);qualified=[]
 for n in modules:
  file=BASE/'models/lean'/(n+'.lean');assert not re.search(r'\bsorry\b|\baxiom\s',file.read_text());capsule=CACHE/('qualified-'+n+'.json');prior=json.loads(capsule.read_text()) if capsule.exists() else None
  reusable=prior and prior['inputs']==proofInputs and (CACHE/(n+'.olean')).exists() and sha(CACHE/(n+'.olean'))==prior['objectSha256'] and all(sha(ROOT/f)==h for f,h in prior['logs'].items()) and sha(ROOT/prior['sourceSnapshot'])==prior['sourceSnapshotSha256']
  if not reusable:
   run('lean-'+n,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(n+'.olean')),str(file)])
   status=max(CACHE.glob('lean-'+n+'-*.status.json'),key=lambda f:f.stat().st_mtime);stem=status.name.removesuffix('.status.json');snap=CACHE/(stem+'-'+file.name)
   prior=dict(inputs=proofInputs,objectSha256=sha(CACHE/(n+'.olean')),logs={rel(f):sha(f) for f in CACHE.glob(stem+'.*')},sourceSnapshot=rel(snap),sourceSnapshotSha256=sha(snap));save(capsule,prior)
  qualified.append(dict(name=n,reused=bool(reusable),**prior))
  ns='DispatchJointBridge' if n=='DispatchJointBridge' else 'DispatchJoint'
  if not n.endswith('Ast'):lemmas += [ns+'.'+v for v in re.findall(r'^theorem (\w+)',file.read_text(),re.M)]
 save(CACHE/'formal-qualified-scopes.json',qualified)
 for group,d in data.items():
  qnt=BASE/'models/quint'/(d['name']+'.qnt');hist=run(group+'-histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','953']);assert hist.count('ok ')==len(d['histories'])
  run(group+'-samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 counters=json.loads((CACHE/'counter-config.json').read_text())
 for label,group,action,part,before,after,witness,prefix in counters:
  folder=CACHE/('negative-'+label);folder.mkdir(exist_ok=True);ns=data[group]['namespace'];changed=[]
  for line in asts[group].splitlines():
   if line.startswith('def '+action+('Next' if part=='AppendNext' else part)):
    line=line.split(':=',1)[0]+':= True' if part=='Guard' else line.rstrip()[:-1]+', '+after+'}' if part=='AppendNext' else line.replace(before,after)
   changed.append(line)
  mutant='\n'.join(changed)+'\n';assert mutant!=asts[group];(folder/(ns+'.lean')).write_text(mutant);run(label+'-ast',[LEAN,'-o',str(folder/(ns+'.olean')),str(folder/(ns+'.lean'))])
  sequence=list(reversed(re.findall(r'(\w+)Next \(',prefix)));prior='initial';guards=[];defs=[]
  for step in sequence:
   guards.append('example : '+step+'Guard ('+prior+') := by simp ['+','.join([step+'Guard','initial']+defs)+']')
   prior=step+'Next ('+prior+')';defs.append(step+'Next')
  guardText='\n'.join(guards)+'\n'
  goal='Safe ('+action+'Next witness)';text='import '+ns+'\nopen '+ns+'\ndef witness : State := '+witness+'\nexample : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : ¬ ('+goal+') := by simp [Safe,'+action+'Next,witness,initial]\nexample : '+goal+' := by simp [Safe,'+action+'Next,witness,initial]\n'
  text=text.replace('example : witness =',guardText+'example : witness =');failureLine=8+len(guards)
  (folder/'Control.lean').write_text(text);out=run(label+'-control',['env','LEAN_PATH='+str(folder),LEAN,str(folder/'Control.lean')],expected=1);assert out.count('error:')==1 and ('Control.lean:'+str(failureLine)+':') in out,label
 save(CACHE/'countercontrols.json',[r[0] for r in counters])
 src=[[r[k] for k in ['key','path','sha256','needle']] for r in sources]
 def rows(g,fs):return [[r[k] for k in fs.split()] for r in p[g]]
 routes=rows('route','component actionName lemma producerAnchor obligationId');needs=rows('need','key status condition');issuers=rows('issuer','key source existing candidate gap');composition=rows('composition','key lemma source obligation boundary');components=rows('component','componentId sharedContract');paths=rows('path','key producer consumer classification missing');memory=rows('memory','key order premise obligation');results={};engine=Engine()
 try:
  session=engine.open_sources((ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm').read_text());assert session.run(queries=['blocked'])['complete']
  cases=['current','synthetic-all','stale-source','missing-action','missing-lemma','wrong-component','forged-issuer','wrong-bridge','gc-waits-native-scope','scheduler-means-quiescence','registration-means-domain-lock','unmanaged-needs-no-accounting','shared-mail-is-isolated','paper-already-implements-service','normal-free-is-Scheme-reentry','raw-setters-closed','refusal-calls-Scheme','missing-finisher','wrong-shared-contract','missing-paper']
  learning=rows('learning','key source mechanism fact mismatch candidate status')
  for case in cases:
   so=copy.deepcopy(src);ro=copy.deepcopy(routes);io=copy.deepcopy(issuers);co=copy.deepcopy(composition);cn=copy.deepcopy(components);po=copy.deepcopy(paths);mo=copy.deepcopy(memory);lo=copy.deepcopy(learning);aa=copy.deepcopy(actions);ll=[[l] for l in lemmas];nr=[[case,k,t,c] for k,t,c in needs if case!='current' or t!='unresolved']
   if case=='stale-source':so[0][2]='stale'
   if case=='missing-action':aa=aa[1:]
   if case=='missing-lemma':ll=ll[1:]
   if case=='wrong-component':ro[0][0]='other'
   if case=='forged-issuer':io[0][3]='already verified'
   if case=='wrong-bridge':co[0][1]='DispatchJointBridge.nativeC23Complete'
   if case=='gc-waits-native-scope':mo[2][2]='all native scopes must exit before GC freeze'
   if case=='scheduler-means-quiescence':lo[3][5]='any Scheme yield proves native C references dropped'
   if case=='registration-means-domain-lock':lo[1][3]='registered thread automatically holds domain access'
   if case=='unmanaged-needs-no-accounting':lo[4][3]='unmanaged readers need no delay handle'
   if case=='shared-mail-is-isolated':lo[5][5]='copy all Scheme messages without alias change'
   if case=='paper-already-implements-service':lo[0][3]='paper implements the C23 joint source service'
   if case=='normal-free-is-Scheme-reentry':po[4][3]='observed Scheme reentry from release_string'
   if case=='raw-setters-closed':po[2][-1]='all public writers closed'
   if case=='refusal-calls-Scheme':io[4][3]='invoke old Scheme error translator on refusal'
   if case=='missing-finisher':nr=[r for r in nr if r[1]!='stable-finisher']
   if case=='wrong-shared-contract':cn[0][1]='filename-only'
   if case=='missing-paper':so=[r for r in so if r[0]!='feeley-paper']
   session.replace(dict(scenario=[[case]],need=needs,receipt=nr,sourceNeed=src,sourceObservation=so,routeNeed=routes,routeObservation=ro,actionName=aa,lemmaName=ll,issuerNeed=issuers,issuerObservation=io,compositionNeed=composition,compositionObservation=co,memoryNeed=memory,memoryObservation=mo,componentNeed=components,componentObservation=cn,pathNeed=paths,pathObservation=po,learningNeed=learning,learningObservation=lo))
   res=session.run(queries=['blocked','candidate','routeLinked','compositionLinked','groundingLinked','pathLinked','learningLinked']);assert res['complete'];results[case]=res['relations']

 finally:engine.close()
 assert [k for k,v in results.items() if v['candidate']]==['synthetic-all'];save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: Native-scope admission — learning, custody and net return','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML authority',':PROPERTIES:',':CUSTOM_ID: dispatch-joint-admission-matrix',':AUTHORITY: GambitDispatchJointAdmission',':END:','Formal and source-bound rows qualify only their named abstract boundaries. Native issuers remain unresolved.']
 for group in ['component','learning','profile','path','issuer','composition','need','memory','gain','route','source']:
  fs=list(p[group][0]);matrix+=['','** '+group.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(str(r[k]).replace('\n',' / ').replace('|',' / ') for k in fs)+' |' for r in p[group]]
 (BASE/f'{TASK}-matrix.org').write_text('\n'.join(matrix)+'\n')
 d2=BASE/'diagrams'/f'{TASK}.d2';d2.write_text('direction: down\ntitle: "C23 native-scope grace, joint root admission and whole-runtime learning"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['contract'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 checks=dict(sourceAnchors=len(sources),pinnedTclFiles=len(pinned['records']),components=len(components),callerPaths=len(paths),qntActions=len(actions),borrowSafetyOnly=True,nativeScopeCensusQualified=False,histories=sum(len(d['histories']) for d in data.values()),samplesPerModel=500,maxSteps=80,seed=953,leanTheorems=len(lemmas),stepInduction=True,typedIrControls=4,countercontrols=len(counters),ascentScenarios=len(results),compositionJoins=len(composition),learningRows=len(p['learning']),actualCandidate=False,unresolved=[r['key'] for r in p['need'] if r['status']=='unresolved'],sourcePinPredicateBridge=True,parentFullSimulation=False,sourceBorrowIssuerQualified=False,stableFinisherQualified=False,actualSmpScalingClaim=False,loadedTclIdentityQualified=False,c23MemoryRefinement=False,slotValueFidelity=False,destinationCompletionRefined=False,nativePathsRetired=0,runtimeImplementation=False,nativeTests=False,nativeCompilerOrPreprocessorRun=False,performanceTests=False)
 save(CACHE/'checks.json',checks);save(OUT/'checks.json',checks);shutil.copyfile(CACHE/'pinned-tcl-sources.json',OUT/'pinned-tcl-sources.json');shutil.copyfile(CACHE/'reference-revisions.json',OUT/'reference-revisions.json');shutil.copyfile(CACHE/'pvm-paper-source.json',OUT/'pvm-paper-source.json')
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for a,b in [('dev/architecture/toolchain/iter-compiler-service-design.org',rel(BASE/f'{TASK}-design.org')),('dev/architecture/toolchain/iter-compiler-service-matrix.org',rel(BASE/f'{TASK}-matrix.org')),('dev/architecture/toolchain/index.org',rel(BASE/'index.org'))]:org=org.replace(a,b)
 org=org.replace(')) (links 0)', ' "dev/refactoring/modern-c/runtime-blueprint.org" "dev/knowledge/ocaml/index.org" "dev/knowledge/erlang/index.org")) (links 0)')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 files=formal+[ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm',BASE/f'{TASK}-design.org',BASE/f'{TASK}-matrix.org',BASE/'index.org',BASE/'runtime-blueprint.org',ROOT/'dev/knowledge/ocaml/index.org',ROOT/'dev/knowledge/erlang/index.org',d2,d2.with_suffix('.svg')]+[CACHE/n for n in ['config.json','model-data.json','proof-modules.json','counter-config.json','pinned-tcl-sources.json','reference-revisions.json','pvm-paper-source.json']]
 bindings.update({rel(f):sha(f) for f in files});assert modelHash==sha(model) and parentHash==sha(parent);assert all(sha(ROOT/k)==v for k,v in formalStart.items());assert all(sha(ROOT/k)==v for k,v in bindings.items())
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),sourceBindings=bindings,parentInputSha256=parentHash,parentInputPath=rel(parent),leanBinarySha256=sha(LEAN),nativeClaim=False));save(CACHE/'formal-inputs.json',formalStart)
 for f in CACHE.rglob('*'):
  if f.is_file():
   t=OUT/f.relative_to(CACHE);t.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,t)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'});print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
