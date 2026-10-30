#!/usr/bin/env python3
"""Source-bound formal study only; native SysML is routing authority."""
import copy, hashlib, importlib.util, json, re, shutil, subprocess, textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM='native-return-domains'; BASE='dev/refactoring/modern-c/'
CACHE=ROOT/'.cache/tasks'/STEM; OUT=ROOT/'evidence/research'/STEM
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x): Path(p).write_text(json.dumps(x,indent=2)+'\n')
def run(n,args,fail=False):
 save(CACHE/(n+'.command.json'),args)
 try: p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,timeout=60)
 except subprocess.TimeoutExpired as e:
  for k,v in [('stdout',e.stdout),('stderr',e.stderr)]:
   if v is not None:(CACHE/(n+'.partial.'+k)).write_bytes(v if isinstance(v,bytes) else v.encode())
  save(CACHE/(n+'.timeout.json'),dict(timeout=60));raise
 (CACHE/(n+'.stdout')).write_text(p.stdout);(CACHE/(n+'.stderr')).write_text(p.stderr)
 save(CACHE/(n+'.status.json'),dict(exit=p.returncode,expectedFailure=fail))
 assert (p.returncode!=0 if fail else p.returncode==0),(n,p.stdout[-3000:],p.stderr[-1000:])
 return p.stdout

def main():
 from ascent import Engine
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 cfg=json.loads((CACHE/'config.json').read_text());keys=[(g,i,f,'GambitNativeReturnDomains::'+g+str(i)+'.'+f) for g,n,fs in cfg for i in range(n) for f in fs.split()]
 args=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,e in keys:args+=['-e',e]
 raw=json.loads(run('sysml',args+[BASE+'models/sysml/'+STEM+'.sysml']))
 assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in (raw.get('diagnostics') or []))
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(v.values()) for g,v in p.items()};save(CACHE/'sysml-projection.json',p)
 sources=[]
 for v in p['source']:
  data=(ROOT/v['path']).read_text();assert v['needle'] in data
  sources.append([v['key'],v['path'],sha(ROOT/v['path']),v['needle']])
 save(CACHE/'source-witnesses.json',[dict(key=k,path=f,sha256=h,needle=n,lines=[s.count('\n',0,m.start())+1 for m in re.finditer(re.escape(n),s)]) for k,f,h,n in sources for s in [(ROOT/f).read_text()]])
 qnt=BASE+'models/quint/native_return_domains.qnt'
 formalpaths=[qnt,BASE+'models/lean/NativeReturn.lean','dev/modeling/tools/native-return-domains-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py']
 formalinputs={f:sha(ROOT/f) for f in formalpaths}
 run('typecheck',['quint','typecheck',qnt,'--out',str(CACHE/'typed-ir.json')])
 sp=importlib.util.spec_from_file_location('projection',ROOT/'dev/modeling/tools/native-return-domains-projection.py');m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m)
 ir=json.loads((CACHE/'typed-ir.json').read_text());ast,rec=m.generate(ir)
 astpath=ROOT/(BASE+'models/lean/NativeReturnAst.lean');astpath.write_text(ast)
 save(CACHE/'projection.json',dict(**rec,typedIrSha256=sha(CACHE/'typed-ir.json'),astSha256=sha(astpath),c23Refinement=False))
 controls={}
 for kind in ['binding','field','roster','expression']:
  bad=copy.deepcopy(ir);ds={d['name']:d for d in bad['modules'][0]['declarations']}
  if kind=='binding':bad['table'][str(rec['stateReferences'][0][0])]['id']=-1
  if kind=='field':ds['State']['type']['fields']['fields'][0]['fieldType']['kind']='bool'
  if kind=='roster':ds['step']['expr']['args'].pop(0)
  if kind=='expression':ds['safe']['expr']['opcode']='unsupported'
  try:m.generate(bad)
  except (AssertionError,KeyError):controls[kind]='rejected'
  else:raise AssertionError(kind)
 save(CACHE/'projection-controls.json',controls)
 run('ast',[LEAN,'-o',str(CACHE/'NativeReturnAst.olean'),str(astpath)])
 proof=ROOT/(BASE+'models/lean/NativeReturn.lean');assert not re.search(r'\bsorry\b|\baxiom\s',proof.read_text())
 run('proof',['env','LEAN_PATH='+str(CACHE),LEAN,str(proof)])
 lemmas=[['NativeReturn.'+x] for x in re.findall(r'^theorem (\w+)',proof.read_text(),re.M)]
 histories=run('histories',['quint','test',qnt,'--match','Test$','--max-samples','1','--seed','521']);assert histories.count('ok ')==5
 run('samples',['quint','run',qnt,'--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','521','--verbosity','1'])
 # Countercontrols use actual projected updates on a reachable canonical state.
 neg=[]
 for label,action,field,before,after,witness in [('return-resurrection', 'rejectStaleReturn', 'returnRight', 'returnRight:=(0)', 'returnRight:=(1)', '{initial with phase:=7,threadLive:=1,stackLive:=0,returnRight:=0,guard:=1,root:=1,shot:=2,ticket:=3,retained:=1,closed:=0,grace:=0}'), ('unknown-root-loss', 'unknownExit', 'root', 'root:=(1)', 'root:=(0)', '{initial with phase:=4,threadLive:=1,stackLive:=1,returnRight:=1,guard:=1,root:=1,shot:=1,ticket:=2,retained:=1,closed:=0,grace:=0}'), ('replayed-ticket', 'resumeSecond', 'ticket', 'ticket:=(3)', 'ticket:=(2)', '{initial with phase:=6,threadLive:=1,stackLive:=0,returnRight:=0,guard:=0,root:=1,shot:=1,ticket:=2,retained:=1,closed:=0,grace:=0}')]:
  d=CACHE/('negative-'+label);d.mkdir(exist_ok=True)
  changed='\n'.join(line.replace(before,after) if line.startswith('def '+action+'Next') else line for line in ast.splitlines())+'\n';assert changed!=ast
  (d/'NativeReturnAst.lean').write_text(changed)
  run(label+'-ast',[LEAN,'-o',str(d/'NativeReturnAst.olean'),str(d/'NativeReturnAst.lean')])
  goal='Safe ('+action+'Next witness)'
  t='import NativeReturnAst\nopen NativeReturnAst\ndef witness : State := '+witness+'\nexample : Safe witness := by simp [Safe,witness,initial]\nexample : '+action+'Guard witness := by simp ['+action+'Guard,witness,initial]\nexample : ¬ ('+goal+') := by simp [Safe,'+action+'Next,witness,initial]\nexample : '+goal+' := by simp [Safe,'+action+'Next,witness,initial]\n'
  (d/'Control.lean').write_text(t)
  out=run(label+'-control',['env','LEAN_PATH='+str(d),LEAN,str(d/'Control.lean')],fail=True);assert out.count('error:')==1 and 'Control.lean:7:' in out
  neg.append(label)
 save(CACHE/'countercontrols.json',neg)
 actions=[[m.SPEC['module']+'.'+a] for a in m.SPEC['actions']];needs=[[v['key'],v['kind'],v['path'],sha(ROOT/v['path']),v['scope']] for v in p['need']]
 routes=[[v[k] for k in ['component','actionName','lemma','producerAnchor','obligationId']] for v in p['route']]
 issuers=[[v[k] for k in ['key','proposedIssuer','actualSource','status','responsibility']] for v in p['issuer']]
 engine=Engine();results={}
 try:
  s=engine.open_sources((ROOT/'dev/modeling/ascent/native-return-domains.rules.scm').read_text());assert s.run(queries=['blocked'])['complete']
  for case in ['current','synthetic-all','missing-action','missing-lemma','wrong-owner','stale-source','wrong-scope','wrong-issuer','substituted-Gambit-paper','missing-grounding-source']:
   receipt=[[case,n,path,h,scope] for n,kind,path,h,scope in needs if case!='current' or kind in ['formal','bridge']]
   observations=copy.deepcopy(sources);ro=copy.deepcopy(routes);io=copy.deepcopy(issuers)
   papers=[[v[k] for k in ['key','title','url','section','basis','boundary']] for v in p['paper']];po=copy.deepcopy(papers)
   if case=='substituted-Gambit-paper':po[1][4]='OCaml documentation substitutes for Gambit primary proof'
   if case=='missing-grounding-source':observations=[v for v in observations if v[0]!='paper-fulltext']
   if case=='wrong-owner':ro[0][0]='other'
   if case=='stale-source':observations[0][2]='stale'
   if case=='wrong-scope':receipt[0][-1]='native-performance'
   if case=='wrong-issuer':io[0][3]='existing verified signer'
   s.replace(dict(scenario=[[case]],need=needs,needOwner=[[v['key'],v['owner.componentId']] for v in p['need']],receipt=receipt,binding=[[v['actionName'],v['lemma']] for v in p['binding']],actionName=actions[1:] if case=='missing-action' else actions,lemmaName=lemmas[1:] if case=='missing-lemma' else lemmas,sourceNeed=sources,sourceObservation=observations,routeNeed=routes,routeObservation=ro,proofNeed=[[v['key'],v['lemma']] for v in p['proof']],issuerNeed=issuers,issuerObservation=io,paperNeed=papers,paperObservation=po,groundingNeed=[[v[k] for k in ['component','producerAnchor','paperKey','obligationId']] for v in p['grounding']]))
   res=s.run(queries=['candidate','blocked','routeLinked','proofLinked','paperLinked','groundingLinked']);assert res['complete'];results[case]=res['relations']
 finally:engine.close()
 assert [k for k,v in results.items() if v['candidate']]==['synthetic-all']
 gaps=sorted(v[1] for v in results['current']['blocked']);assert len(gaps)==6
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotNativeEvidence=True))
 matrix=['#+TITLE: Native thread and return domains — modernization and net benefit matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML evaluated authority',':PROPERTIES:',':CUSTOM_ID: native-return-domains-matrix',':AUTHORITY: GambitNativeReturnDomains',':END:','Generated rows below come from the native SysML evaluator. No native issuer is qualified by a formal route.']
 for group in ['role','gain','memory','issuer','paper','grounding','need','route','proof','source']:
  fields=list(p[group][0]);matrix+=['','** '+group.capitalize(),'','| '+' | '.join(fields)+' |','|'+'+'.join('---' for _ in fields)+'|']+['| '+' | '.join(v[f] for f in fields)+' |' for v in p[group]]
 matrix+=['','** Closure','', '| Obligation | Receipt |','|---+---|']+['| '+v['key']+' | '+('Unresolved native contract' if v['key'] in gaps else 'Scoped conditional formal evidence')+' |' for v in p['need']]
 (ROOT/(BASE+STEM+'-matrix.org')).write_text('\n'.join(matrix)+'\n')
 graph=['direction: down','title: "Gambit multi-shot control and C23 native lifetime domains"']+[json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(textwrap.fill(v['custody'],38)) for v in p['contract']]
 d2=BASE+'diagrams/'+STEM+'.d2';(ROOT/d2).write_text('\n'.join(graph)+'\n');run('d2-svg',['d2','--layout','elk',d2,d2[:-3]+'.svg']);run('d2-png',['d2','--layout','elk',d2,str(CACHE/'diagram.png')])
 checks=dict(baseline='C23',sourceAnchors=len(sources),qntActions=len(actions),histories=5,samples=500,maxSteps=80,seedArgument=521,leanTheorems=len(lemmas),allStepInduction=True,typedIrControls=len(controls),countercontrols=len(neg),ascentScenarios=len(results),routes=len(routes),blockers=gaps,actualCandidate=False,twoSchemeShotsOneNativeSegment=True,nativeSegmentProposalImplemented=False,arbitraryNestingProved=False,physicalStackReclamationProved=False,multiShotUnboundedProved=False,poolConcurrencyProved=False,c23RefinementProved=False,rootProductProved=False,unknownRecoveryProved=False,nativePathsRetired=0,runtimeImplementation=False,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/'checks.json',checks)
 parent=ROOT/'evidence/research/guard-thread-admission/input.json';parenthash=sha(parent);pdata=json.loads(parent.read_text()); composition={f:sha(ROOT/f) for f in pdata['compositionInputs']}
 save(CACHE/'parent-composition-drift.json',[dict(path=f,parent=h,current=composition[f]) for f,h in pdata['compositionInputs'].items() if h!=composition[f]])
 paths={v[1] for v in sources}|{'.cache/tasks/'+STEM+'/'+name for name in ['feeley-sfp-paper.ps','feeley-sfp-paper.pdf','primary-paper.json','external-evidence.json']}|{BASE+STEM+'-design.org',BASE+STEM+'-matrix.org',BASE+'index.org',BASE+'models/sysml/'+STEM+'.sysml',qnt,str(astpath.relative_to(ROOT)),str(proof.relative_to(ROOT)),d2,d2[:-3]+'.svg','dev/modeling/tools/'+STEM+'-projection.py','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/chunk-capacity-charge-projection.py','dev/modeling/ascent/'+STEM+'.rules.scm','.cache/tasks/'+STEM+'/config.json','.cache/tasks/'+STEM+'/model-data.json'}
 data=dict(head=run('head',['git','rev-parse','HEAD']).strip(),branch=run('branch',['git','branch','--show-current']).strip(),parentPath=str(parent.relative_to(ROOT)),parentInputSha256=parenthash,sourceBindings={f:sha(ROOT/f) for f in sorted(paths)},compositionInputs=composition)
 save(CACHE/'input.json',data)
 def receipts():
  for f in CACHE.iterdir():
   if f.is_file() and f.suffix in ['.json','.stdout','.stderr','.ps','.pdf','.txt']:shutil.copyfile(f,OUT/f.name)
 receipts();save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text()
 for a,b in [('dev/architecture/toolchain/iter-compiler-service-design.org',BASE+STEM+'-design.org'),('dev/architecture/toolchain/iter-compiler-service-matrix.org',BASE+STEM+'-matrix.org'),('dev/architecture/toolchain/index.org',BASE+'index.org')]:org=org.replace(a,b)
 (CACHE/'check-org.el').write_text(org);run('org-check',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 assert sha(parent)==parenthash and all(sha(ROOT/f)==h for f,h in data['sourceBindings'].items())
 assert all(sha(ROOT/f)==h for f,h in formalinputs.items()), 'formal input drift'
 assert all(sha(ROOT/f)==h for f,h in composition.items()), 'composition drift'
 save(CACHE/'formal-inputs.json',formalinputs)
 data['logs']={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']};save(CACHE/'input.json',data);receipts()
 for d in list(CACHE.glob('negative-*')) + list(CACHE.glob('retained-*-failure')):
  if d.is_dir():shutil.copytree(d,OUT/d.name,dirs_exist_ok=True)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
