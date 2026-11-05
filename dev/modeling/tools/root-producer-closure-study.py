#!/usr/bin/env python3
"""Native SysML projection and bounded formal research; never executes runtime code."""
import importlib.util,json,re,shutil,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM="root-producer-closure"; BASE="dev/refactoring/modern-c/"; PKG="GambitRootProducerClosure"
CACHE=ROOT/".cache/tasks"/STEM; OUT=ROOT/"evidence/research"/STEM
MODEL=BASE+"models/sysml/"+STEM+".sysml"; QNT=BASE+"models/quint/root_producer_closure.qnt"
LEAN=BASE+"models/lean/RootProducerClosure.lean"; RULES="dev/modeling/ascent/"+STEM+".rules.scm"
DESIGN=BASE+STEM+"-design.org"; MATRIX=BASE+STEM+"-matrix.org"; D2=BASE+"diagrams/"+STEM+".d2"
sp=importlib.util.spec_from_file_location("research_helper",ROOT/"dev/modeling/tools/advantage-architecture-study.py")
h=importlib.util.module_from_spec(sp);sp.loader.exec_module(h);h.CACHE=CACHE;h.OUT=OUT
run=h.run;save=h.save;sha=h.sha
GROUPS=[("root",13,"key sourcePath needle identity worker condition"),("flow",14,"key sourcePath needle nextNode custody diagramLabel"),("obligation",8,"key status scope"),("gain",7,"key avoided added condition"),("binding",3,"actionName lemma condition"),("parameter",5,"key sourcePath needle value"),("diagramedge",4,"fromNode toNode label")]
def project():
 keys=[(g,str(i),f,f"{PKG}::{g}{i}.{f}") for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 keys += [("need",n,f,f"{PKG}::{n}.{f}") for n in ["history","induction","source","bridge"] for f in ["obligationId","kind","subjectPath","subjectScope"]]
 inputs=run("sysml-inputs",["rg","--files","dev","-g","*.sysml","-g","*.kerml"]).splitlines()
 scope={f:sha(ROOT/f) for f in sorted(inputs)};save(CACHE/"sysml-input-scope.json",scope)
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 raw=json.loads(run("sysml",args+["dev"]));assert raw["exit"]==0 and not raw.get("errors"),raw
 vals=[json.loads(x[4:]) for x in raw["output"] if x.startswith("  = ")];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);return p,scope
def views(p):
 lines=["#+TITLE: Physical Root and Producer Closure Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+LANGUAGE: en","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":AUTHORITY: GambitRootProducerClosure",":STATUS: conditional-formal-results; source-bridge-open",":END:"]
 for g,_,fields in GROUPS:
  fs=fields.split();lines += ["","** "+g.capitalize(),"","| "+" | ".join(fs)+" |","|"+"+".join("---" for _ in fs)+"|"]
  lines += ["| "+" | ".join(v[f] for f in fs)+" |" for v in p[g]]
 lines += ["","** Proof routing","","| ID | kind | subject | scope |","|---+---+---+---|"]
 lines += ["| "+" | ".join(v[f] for f in ["obligationId","kind","subjectPath","subjectScope"])+" |" for v in p["need"].values()]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 graph=['direction: down','classes: {','  open: {style.fill: "#fff0dd"}','}']
 nodes={v['key'] for v in p['flow']}|{v['nextNode'] for v in p['flow']}
 nodes |= {v['fromNode'] for v in p['diagramedge']} | {v['toNode'] for v in p['diagramedge']}
 for n in sorted(nodes):graph.append(json.dumps(n)+": "+json.dumps(n))
 for v in p['flow']:graph.append(json.dumps(v['key'])+" -> "+json.dumps(v['nextNode'])+": "+json.dumps(v['diagramLabel']))
 for v in p['diagramedge']:graph.append(json.dumps(v['fromNode'])+' -> '+json.dumps(v['toNode'])+': '+json.dumps(v['label']))
 graph += ['qualification: "Conditional formal model\nFull source / C11 closure open"'.replace('\n',r'\n')]
 (ROOT/D2).write_text("\n".join(graph)+"\n")
def ascend(p,witness):
 needs=[[v['obligationId'],v['kind'],v['subjectPath'],sha(ROOT/v['subjectPath']),v['subjectScope']] for v in p['need'].values()]
 bindings=[[v['actionName'],v['lemma']] for v in p['binding']]
 actions=[[x] for x in re.findall(r'^ action (\w+)',(ROOT/QNT).read_text(),re.M)]
 lemmas=[[x] for x in re.findall(r'^theorem (\w+)',(ROOT/LEAN).read_text(),re.M)]
 rows=[[v['key'],v['sourcePath'],v['sha256'],v['needle']] for v in witness]
 assert len({v[0] for v in rows})==len(rows)
 results={};engine=h.Engine()
 try:
  session=engine.open_sources((ROOT/RULES).read_text());queries=['checked','blocked','candidate','linked','observed'];assert session.run(queries=queries)['complete']
  for case in ['current','synthetic-all','stale-digest','wrong-scope','missing-source','missing-action','wrong-lemma','missing-witness','missing-bridge']:
   receipts=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!='current' or k in ['interleaving','induction']]
   if case=='stale-digest':receipts[0][3]='stale'
   if case=='wrong-scope':receipts[0][4]='all-runtime-proved'
   if case=='missing-source':receipts=[v for v in receipts if v[1]!='RPC-source']
   if case=='missing-bridge':receipts=[v for v in receipts if v[1]!='RPC-bridge']
   ac=actions if case!='missing-action' else [x for x in actions if x!=['claim']]
   ls=lemmas if case!='wrong-lemma' else [x for x in lemmas if x!=['claimPreserves']]
   session.replace(dict(scenario=[[case]],need=needs,receipt=receipts,binding=bindings,actionName=ac,lemmaName=ls,witness=rows,observation=rows if case!='missing-witness' else rows[1:]))
   result=session.run(queries=queries);assert result['complete'];results[case]=result['relations']
  save(CACHE/'ascent-attempt-results.json',results)
  assert len(results['current']['checked'])==2 and len(results['current']['linked'])==3
  assert len(results['synthetic-all']['candidate'])==1
  for case in results:
   if case!='synthetic-all':assert not results[case]['candidate'],case
  assert ['current','RPC-source'] in results['current']['blocked'] and ['current','RPC-bridge'] in results['current']['blocked']
 finally:engine.close()
 save(CACHE/'ascent-results.json',dict(results=results,syntheticNotRealEvidence=True,sourceQualified=False,expressionBridgeQualified=False))
def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/'evidence/research/manifest-scan-qualification/input.json';parentHash=sha(parent)
 p,scope=project();views(p);witness=[]
 for group,v in [(g,v) for g in ['root','flow','parameter'] for v in p[g]]:
  text=(ROOT/v['sourcePath']).read_text();assert v['needle'] in text,v['key']
  witness.append(dict(**{**v,'key':group+':'+v['key']},sha256=sha(ROOT/v['sourcePath']),line=text[:text.index(v['needle'])].count('\n')+1))
 save(CACHE/'source-witnesses.json',witness)
 census={v['key']:int(v['value']) for v in p['parameter']}
 fixed=census['registers']+census['saved']+census['type-cache']+2+census['processor-body']
 assert fixed==34 and census['vm-body']+3==23
 save(CACHE/'root-census.json',dict(templateDefaultContextVisits=fixed,vmAndTablesVisits=census['vm-body']+3,formula='34*W+23+G+RC+F+W_break_links',notDistinctObjects=True,includesDerivedGraph=False,effectiveDarwinConfigurationQualified=False,parameters=census))
 # Exact locations make this a source inventory, never a proof of hidden callers.
 run('source-mark-array-callers',['rg','-n','mark_array \\(work|mark_captured_continuation|setup_still_objs_to_scan','vendor/gambit/lib/mem.c'])
 run('frame-and-denv-anchors',['rg','-n','___frame_root_(begin|advance|next_run)|___CONTINUATION_DENV|___THREAD_DENV|___CONTEXT_PROCESSOR_SCMOBJ','vendor/gambit/include/gambit.h.in'])
 reuse='--reuse-formal' in sys.argv
 lean=(ROOT/LEAN).read_text()
 if reuse:
  previous=json.loads((CACHE/'input.json').read_text())
  for f in [QNT,LEAN]:assert sha(ROOT/f)==previous['sourceBindings'][f],f
  for f,d in previous['logs'].items():
   if any(k in f for k in ['typecheck.','quint-tests.','quint-samples.','/lean.','negative-lean.']):assert sha(ROOT/f)==d,f
 else:
  run('typecheck',['quint','typecheck',QNT,'--out',str(CACHE/'typed-ir.json')])
  tests=run('quint-tests',['quint','test',QNT,'--match','Test$']);assert tests.count('ok ')==10 and tests.count('ControlTest passed')==6
  run('quint-samples',['quint','run',QNT,'--init','init','--invariant','safe','--max-samples','500','--max-steps','200','--seed','41','--verbosity','1'])
  lean=(ROOT/LEAN).read_text();assert 'sorry' not in lean and 'axiom ' not in lean
  run('lean',['lean','-o',str(CACHE/'RootProducerClosure.olean'),LEAN])
  # Removing the Tail guard must make the actual preservation proof fail.
  mutant=lean.replace(' ∧ ¬s.tail=true','');assert mutant!=lean
  (CACHE/'WrongIdle.lean').write_text(mutant)
  try:run('negative-lean',['lean',str(CACHE/'WrongIdle.lean')])
  except RuntimeError:assert 'error:' in (CACHE/'negative-lean.stdout').read_text()
  else:raise AssertionError('Tail guard mutation unexpectedly proved')
 ascend(p,witness)
 run('d2-svg',['d2',D2,D2[:-3]+'.svg']);run('d2-png',['d2',D2,str(CACHE/'diagram.png')])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org',DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org',MATRIX).replace('dev/architecture/toolchain/index.org',BASE+'index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f,d in scope.items():assert sha(ROOT/f)==d,f
 for w in witness:assert sha(ROOT/w['sourcePath'])==w['sha256']
 assert sha(parent)==parentHash
 files={MODEL,QNT,LEAN,RULES,DESIGN,MATRIX,D2,D2[:-3]+'.svg',BASE+'index.org','dev/modeling/tools/'+STEM+'-study.py','dev/modeling/tools/advantage-architecture-study.py','vendor/gambit/include/gambit.h.in','vendor/gambit/lib/mem.c','vendor/gambit/lib/setup.c'}
 old=json.loads(parent.read_text());drift=[f for f,d in old['sourceBindings'].items() if not (ROOT/f).is_file() or sha(ROOT/f)!=d]
 save(CACHE/'predecessor-source-drift.json',dict(parentFrozen=True,changed=drift))
 checks=dict(status='conditional-models-pass',formalChecksReused=reuse,sysmlInputs=len(scope),rootFamilies=13,producerAnchors=14,qntHistories=10,negativeQntControls=6,samples=500,maxSteps=200,leanTheorems=len(re.findall(r'^theorem ',lean,re.M)),negativeLeanControls=1,ascentScenarios=9,actualCandidate=False,sourceEnumerationQualified=False,qntLeanExtractionQualified=False,c11Refinement=False,wholeGcTerminationProved=False,nativeTestsRun=False,performanceTestsRun=False,runtimeFilesModifiedByStudy=[])
 save(CACHE/'checks.json',checks)
 save(CACHE/'input.json',dict(head=run('head',['git','rev-parse','HEAD']).strip(),parentInputSha256=parentHash,parentFrozen=True,sourceBindings={f:sha(ROOT/f) for f in sorted(files)},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr']}))
 for f in CACHE.iterdir():
  if f.suffix in ['.json','.el','.lean']:shutil.copyfile(f,OUT/f.name)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks))
if __name__=='__main__':main()
