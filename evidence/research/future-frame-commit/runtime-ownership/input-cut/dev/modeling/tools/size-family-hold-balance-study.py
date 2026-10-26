#!/usr/bin/env python3
"""Research-only native SysML routing, ASCENT DSL, QNT and Lean checks.
No native compiler, preprocessor, runtime build, benchmark or test is invoked.
"""
import copy,hashlib,importlib.util,json,re,shutil,subprocess,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
TASK='size-family-hold-balance';BASE=ROOT/'dev/refactoring/modern-c';CACHE=ROOT/'.cache/tasks'/TASK;OUT=ROOT/'evidence/research'/TASK
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2)+'\n')
def rel(p):
 try:return str(Path(p).relative_to(ROOT))
 except ValueError:return str(p)
def run(name,args,expected=0):
 stamp=str(time.time_ns());stem=CACHE/(name+'-'+stamp)
 save(str(stem)+'.command.json',args)
 for arg in args:
  f=Path(arg)
  if f.suffix in ['.lean','.qnt','.sysml'] and f.is_file():shutil.copyfile(f,str(stem)+'-'+f.name)
 try:p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,timeout=60)
 except subprocess.TimeoutExpired as e:
  save(str(stem)+'.timeout.json',dict(seconds=60,stdout=str(e.stdout),stderr=str(e.stderr)));raise
 Path(str(stem)+'.stdout').write_text(p.stdout);Path(str(stem)+'.stderr').write_text(p.stderr)
 save(str(stem)+'.status.json',dict(exit=p.returncode,expected=expected))
 assert p.returncode==expected,(name,p.stdout[-2500:],p.stderr[-1000:])
 return p.stdout

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitSizeFamilyHoldBalance::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs.split()]
 cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 model=BASE/'models/sysml'/f'{TASK}.sysml';raw=json.loads(run('sysml',cmd+[str(model)]))
 assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in p.items()};save(CACHE/'sysml-projection.json',p)
 sources=[];bindings={}
 for row in p['source']:
  path=ROOT/row['path'];data=path.read_text();assert row['needle'] in data
  sources.append(dict(**row,sha256=sha(path),lines=[data.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),data)]));bindings[row['path']]=sha(path)
 save(CACHE/'source-witnesses.json',sources)
 paperBase=ROOT/'evidence/research/sfun-converter-use-closure'
 paper=json.loads((paperBase/'primary-paper.json').read_text())
 for name,digest in paper['files'].items():
  file=paperBase/name;assert sha(file)==digest;bindings[rel(file)]=digest
 # Enumerate six macro responsibilities independently from actual source text.
 header=ROOT/'vendor/gambit/include/_gambit/foreign_conversion.h.in';text=header.read_text();registry=(ROOT/'vendor/gambit/gsc/_parms.scm').read_text();inventory=[]
 for family in ['SIZE_T','SSIZE_T','PTRDIFF_T']:
  typ=family.lower()
  assert re.search(r'\(cons '+typ+r'-sym\s+\(vector \'c-type.*?"'+family+r'_TO_SCMOBJ"\s+"SCMOBJ_TO_'+family+r'"\s+#f\)\)',registry,re.S)
  for d,args,end in [('SFUN','c,s,i','}'),('CFUN','c,s','')]:
   pattern=r'^#define ___END_'+d+'_'+family+r'_TO_SCMOBJ\('+args+r'\)([^\n]*)$'
   match=re.search(pattern,text,re.M);assert match and match.group(1)==end
   inventory.append(dict(family=family,direction=d,endEffect=end or 'empty',automaticRelease=False))
 save(CACHE/'macro-inventory.json',inventory)
 # A textual inventory is not an all-aliases or indirect-call proof.
 output=run('release-writer-inventory',['rg','-n','still_obj_refcount_dec|release_scmobj|STILL_REFCOUNT.*(--|-=|=)|free_still_objs','vendor/gambit/lib','vendor/gambit/include/_gambit','-g','*.inc','-g','*.c','-g','*.scm','-g','*.in'])
 hits=output.splitlines();save(CACHE/'release-writer-inventory.json',dict(pattern='still decrement/release/init/teardown',rows=hits,openIndirectAliases=True,notAnAllWritersProof=True))
 for line in hits:
  path=line.split(':',1)[0];bindings[path]=sha(ROOT/path)
 profile=p['profile'][0];power=1<<(int(profile['fixWidth'])-1)
 assert profile['minimum']==str(-power) and profile['maximum']==str(power-1)
 assert int(profile['bits'])==64 and profile['unsignedMax']==str(2**64-1)
 assert profile['signedMin']==str(-2**63) and profile['signedMax']==str(2**63-1)
 qnt=BASE/'models/quint/size_family_hold_balance.qnt';run('quint-typecheck',['quint','typecheck',str(qnt),'--out',str(CACHE/'typed-ir.json')])
 proj=ROOT/'dev/modeling/tools/size-family-hold-balance-projection.py';sp=importlib.util.spec_from_file_location('projection',proj);mod=importlib.util.module_from_spec(sp);sp.loader.exec_module(mod)
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,receipt=mod.generate(ir);astpath=BASE/'models/lean/SizeHoldAst.lean';assert astpath.read_text()==ast
 assert str(2**64-1) in ast and str(2**63-1) in ast
 assert str(power) in ast and ('(-('+str(power)+'))') in ast and str(power-1) in ast
 save(CACHE/'projection.json',dict(**receipt,irSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(astpath)))
 ctrls={}
 for label in ['binding','field','roster','expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if label=='binding':bad['table'][str(receipt['stateReferences'][0][0])]['id']=-1
  if label=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if label=='roster':ds['step']['expr']['args'].pop(0)
  if label=='expression':ds['safe']['expr']['opcode']='unqualified'
  try:mod.generate(bad)
  except (AssertionError,KeyError):ctrls[label]='rejected'
  else:raise AssertionError(label)
 save(CACHE/'projection-controls.json',ctrls)
 formalStart={rel(f):sha(f) for f in [model,qnt,proj,ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py']+list((BASE/'models/lean').glob('SizeHold*.lean'))}
 modules=['SizeHoldAst']+json.loads((CACHE/'proof-modules.json').read_text());lemmas=[]
 for name in modules:
  source=BASE/'models/lean'/f'{name}.lean';assert not re.search(r'\bsorry\b|\baxiom\s',source.read_text())
  run('lean-'+name,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(name+'.olean')),str(source)])
  lemmas+=['SizeHold.'+n for n in re.findall(r'^theorem (\w+)',source.read_text(),re.M)]
 result=run('quint-histories',['quint','test',str(qnt),'--backend','typescript','--match','Test$','--max-samples','1','--seed','521']);assert result.count('ok ')==8
 run('quint-samples',['quint','run',str(qnt),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','521','--verbosity','1'])
 # Each mutated effect/guard has a Safe witness and an enabled step, then
 # a proved unsafe postcondition. The final intentionally false goal must fail.
 negative=[('missing-drop','physicalDrop','Next','hold:=(0)','hold:=(q.hold)','{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}'),('double-drop','physicalDrop','Next','effects:=q.created','effects:=(q.created+1)','{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}'),('unrooted-cfun','finishNative','Guard',None,None,'{initial with phase:=2,direction:=1,x:=1152921504606846976,created:=1,hold:=1}'),('gc-in-effect-gap','beginGc','Guard',None,None,'{initial with phase:=4,x:=18446744073709551615,created:=1,hold:=1,critical:=1,exited:=1}')]
 for label,action,part,before,after,witness in negative:
  folder=CACHE/('negative-'+label);folder.mkdir(exist_ok=True)
  lines=[]
  for line in ast.splitlines():
   if line.startswith('def '+action+part):line=(line.split(':=',1)[0]+':= True') if part=='Guard' else line.replace(before,after)
   lines.append(line)
  mutant='\n'.join(lines)+'\n';assert mutant!=ast
  path=folder/'SizeHoldAst.lean';path.write_text(mutant)
  run(label+'-ast',[LEAN,'-o',str(folder/'SizeHoldAst.olean'),str(path)])
  goal='Safe ('+action+'Next witness)'
  prefix='convertBoxedNext (selectAboveFixNext initial)' if label=='unrooted-cfun' else 'enterDropNext (finishNativeNext (convertBoxedNext (selectSizeMaxNext initial)))'
  test='import SizeHoldAst\nopen SizeHoldAst\ndef witness : State := '+witness+'\nexample : witness = '+prefix+' := by rfl\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : ¬ ('+goal+') := by simp [Safe,'+action+'Next,witness,initial]\nexample : '+goal+' := by simp [Safe,'+action+'Next,witness,initial]\n'
  path=folder/'Control.lean';path.write_text(test)
  out=run(label+'-control',['env','LEAN_PATH='+str(folder),LEAN,str(path)],expected=1);assert out.count('error:')==1 and 'Control.lean:8:' in out
 save(CACHE/'countercontrols.json',[v[0] for v in negative])
 # Actual ASCENT evaluates source + semantic profile + component/action/proof joins.
 needs=[[r['key'],r['status'],r['condition']] for r in p['need']]
 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sources]
 routes=[[r[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for r in p['route']]
 profiles=[[r[k] for k in ['key','fixWidth','minimum','maximum','status']] for r in p['profile']]
 engine=Engine();results={}
 try:
  session=engine.open_sources((ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm').read_text());assert session.run(queries=['blocked'])['complete']
  for case in ['current','synthetic-all','wrong-source','missing-action','missing-proof','wrong-component','wrong-boundary','wrong-release-direction','GC-is-release','forged-native-cohort']:
   so=copy.deepcopy(src);ro=copy.deepcopy(routes);po=copy.deepcopy(profiles);iv=copy.deepcopy(inventory)
   needrows=[[case,k,s,c] for k,s,c in needs if case!='current' or s!='unresolved']
   if case=='wrong-source':so[0][2]='stale'
   if case=='wrong-component':ro[0][0]='unrelated'
   if case=='wrong-boundary':po[0][3]=str(power)
   if case=='wrong-release-direction':iv[0]['direction']='Scheme-to-C'
   if case=='GC-is-release':iv[0]['automaticRelease']=True
   if case=='forged-native-cohort':needrows=[r for r in needrows if r[1]!='generated-cohort']
   def inv(rs):return [[r['family'],r['direction'],r['endEffect'],str(r['automaticRelease'])] for r in rs]
   session.replace(dict(scenario=[[case]],need=needs,receipt=needrows,sourceNeed=src,sourceObservation=so,routeNeed=routes,routeObservation=ro,actionName=[[mod.SPEC['module']+'.'+a] for a in mod.SPEC['actions'][1 if case=='missing-action' else 0:]],lemmaName=[[x] for x in lemmas[1 if case=='missing-proof' else 0:]],profileNeed=profiles,profileObservation=po,inventoryNeed=inv(inventory),inventoryObservation=inv(iv),groundingNeed=[['ffi-conversion',r[3],'paper-fulltext',r[4]] for r in routes]))
   res=session.run(queries=['blocked','candidate','routeLinked','groundingLinked']);assert res['complete'];results[case]=res['relations']
 finally:engine.close()
 assert [k for k,v in results.items() if v['candidate']]==['synthetic-all']
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: Size-family conversion ownership and net return matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projections',':PROPERTIES:',':CUSTOM_ID: size-family-hold-matrix',':AUTHORITY: GambitSizeFamilyHoldBalance',':END:','These rows are evaluated by native SysML. Formal routes do not qualify native issuers.']
 for g in ['profile','releaser','need','gain','memory','route','source']:
  fs=list(p[g][0]);matrix+=['','** '+g.capitalize(),'','| '+' | '.join(fs)+' |','|'+'+'.join('---' for _ in fs)+'|']+['| '+' | '.join(r[f].replace('\n',' / ').replace('|',' / ') for f in fs)+' |' for r in p[g]]
 (BASE/f'{TASK}-matrix.org').write_text('\n'.join(matrix)+'\n')
 diagram='direction: down\ntitle: "C23 size conversions: native holds and Scheme roots"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['custody']) for r in p['contract'])+'\n'
 d2=BASE/'diagrams'/f'{TASK}.d2';d2.write_text(diagram);run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 checks=dict(sourceAnchors=len(sources),macroResponsibilities=len(inventory),qntActions=len(mod.SPEC['actions']),histories=8,samples=500,maxSteps=80,seed=521,leanTheorems=len(lemmas),stepInduction=True,quintBackend="typescript",rustBackendU64Rejected=True,typedIrControls=len(ctrls),effectCountercontrols=len(negative),ascentScenarios=len(results),routes=len(routes),releaseInventoryRows=len(hits),unresolved=[r[0] for r in needs if r[1]=='unresolved'],actualCandidate=False,sourceMismatchConditional=True,nativeLeakObserved=False,allWritersClosed=False,preprocessorOrNativeCompilerRun=False,runtimeImplementation=False,nativeTests=False,performanceTests=False,c23Refinement=False,nativePathsRetired=0)
 save(CACHE/'checks.json',checks)
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for a,b in [('dev/architecture/toolchain/iter-compiler-service-design.org',rel(BASE/(TASK+'-design.org'))),('dev/architecture/toolchain/iter-compiler-service-matrix.org',rel(BASE/(TASK+'-matrix.org'))),('dev/architecture/toolchain/index.org',rel(BASE/'index.org'))]:org=org.replace(a,b)
 (CACHE/'check-org.el').write_text(org)
 run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 # Source hashes are rechecked at the end; concurrent runtime work is not overwritten.
 files=[model,qnt,proj,ROOT/'dev/modeling/tools'/f'{TASK}-study.py',ROOT/'dev/modeling/ascent'/f'{TASK}.rules.scm',ROOT/'dev/modeling/tools/chunk-capacity-charge-projection.py',BASE/f'{TASK}-design.org',BASE/f'{TASK}-matrix.org',BASE/'index.org',d2,d2.with_suffix('.svg')]+[BASE/'models/lean'/f'{n}.lean' for n in modules]+[CACHE/'config.json',CACHE/'model-data.json',CACHE/'proof-modules.json']
 bindings.update({rel(f):sha(f) for f in files});save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),sourceBindings=bindings,leanBinarySha256=sha(LEAN),nativeClaim=False))
 assert all(sha(ROOT/f)==h for f,h in bindings.items()),'source drift during study'
 assert all(sha(ROOT/f)==h for f,h in formalStart.items()),'formal input drift during study'
 assert all(sha(ROOT/r['path'])==r['sha256'] for r in sources),'source witness drift during study'
 save(CACHE/'formal-inputs.json',formalStart)
 for f in CACHE.rglob('*'):
  if f.is_file():
   target=OUT/f.relative_to(CACHE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,target)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
