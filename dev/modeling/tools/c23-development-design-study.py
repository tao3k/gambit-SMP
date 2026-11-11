#!/usr/bin/env python3
"""Research-only coordination of existing architecture owners and formal models."""
import copy,hashlib,importlib.util,json,re,shutil,time
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
BASE=ROOT/'dev/architecture/toolchain'
CACHE=ROOT/'.cache/tasks/future-frame-commit/c23-development'
OUT=ROOT/'evidence/research/future-frame-commit/c23-development'
GROUPS=[('c23Feature',6,['key','origin','application','limit','benefit','primary']),
 ('c23Boundary',4,['key','role.roleId','stage.key','descriptor.fieldId','producer','consumer','contract','retirement','added','sourcePath','needle','qntPath','qntTest','leanPath','lemma','proofLimit']),
 ('c23Edge',6,['fromNode','toNode','contract'])]
LEAN='/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,x):Path(p).write_text(json.dumps(x,indent=2)+'\n')
def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 spec=importlib.util.spec_from_file_location('helper',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py');h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h);h.CACHE=CACHE;run=h.run
 model=BASE/'models/sysml/macos-development.sysml';rules=ROOT/'dev/modeling/ascent/c23-development-design.rules.scm'
 files=[str(p.relative_to(ROOT)) for p in (ROOT/'dev').rglob('*.sysml')]+[str(p.relative_to(ROOT)) for p in (ROOT/'dev').rglob('*.kerml')]
 ix={}
 for f in files:
  for name in re.findall(r'\bpackage\s+([A-Za-z_]\w*)\s*\{',(ROOT/f).read_text()):ix.setdefault(name,set()).add(f)
 selected={str(model.relative_to(ROOT))};todo=list(selected)
 while todo:
  f=todo.pop()
  for name in set(re.findall(r'\b[A-Za-z_]\w*\b',(ROOT/f).read_text())).intersection(ix):
   for dep in ix[name]:
    if dep not in selected:selected.add(dep);todo.append(dep)
 selected=sorted(selected);bindings={f:sha(ROOT/f) for f in selected}
 for f in [str(Path(__file__).relative_to(ROOT)),str(rules.relative_to(ROOT))]:bindings[f]=sha(ROOT/f)
 keys=[(g,i,f,'GambitDarwinDevelopment::'+g+str(i)+'.'+f) for g,n,fs in GROUPS for i in range(n) for f in fs]
 vals=[]
 for start in range(0,len(keys),100):
  cmd=['sysml','-strict','-no-record-cache','-validate','-json']
  for *_,expr in keys[start:start+100]:cmd+=['-e',expr]
  raw=json.loads(run('sysml-'+str(start),cmd+selected));assert raw['exit']==0 and not raw.get('errors')
  values=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(values)==len(keys[start:start+100]);vals+=values
 rows={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):rows.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(v.values()) for g,v in rows.items()};save(CACHE/'projection.json',p)
 for b in p['c23Boundary']:
  for name in ['sourcePath','qntPath','leanPath']:
   f=ROOT/b[name];assert f.exists();bindings[b[name]]=sha(f)
  assert b['needle'] in (ROOT/b['sourcePath']).read_text()
  assert re.search(r'\brun '+b['qntTest']+r'\s*=',(ROOT/b['qntPath']).read_text())
  assert re.search(r'^theorem '+b['lemma']+r'\b',(ROOT/b['leanPath']).read_text(),re.M)
 # Existing scheduler/context models retain their owners; check the selected routes.
 for q in sorted({b['qntPath'] for b in p['c23Boundary']}):
  stem=Path(q).stem;run(stem+'-type',['quint','typecheck',q,'--out',str(CACHE/(stem+'-ir.json'))])
  tests=[b['qntTest'] for b in p['c23Boundary'] if b['qntPath']==q]
  match='|'.join(tests) if stem!='native_artifact_partition' else 'Test$'
  run(stem+'-histories',['quint','test',q,'--backend','typescript','--match',match,'--max-samples','1','--seed','953'])
 q=BASE/'models/quint/native_artifact_partition.qnt'
 run('partition-samples',['quint','run',str(q),'--backend','typescript','--init','init','--invariant','safe','--max-samples','500','--max-steps','80','--seed','953','--verbosity','1'])
 foundations=['FrameRoots','FrameContract','FutureCoordinates','FrameBitmapComposition','FrameCursorClosure','FrameCursorAst','FrameCursorRefinement','FrameCursorWords']
 leanFiles=[ROOT/'dev/refactoring/modern-c/models/lean'/(n+'.lean') for n in foundations]
 leanFiles += sorted({ROOT/b['leanPath'] for b in p['c23Boundary'] if Path(b['leanPath']).stem not in foundations})
 for f in leanFiles:
  bindings[str(f.relative_to(ROOT))]=sha(f);assert not re.search(r'\bsorry\b|\baxiom\s',f.read_text())
  run('lean-'+f.stem,['env','LEAN_PATH='+str(CACHE),LEAN,'-o',str(CACHE/(f.stem+'.olean')),str(f)])
 routes=[[b[k] for k in ['key','role.roleId','stage.key','descriptor.fieldId','sourcePath','qntPath','qntTest','leanPath','lemma','proofLimit']] for b in p['c23Boundary']]
 artifacts=sorted({(b[k],sha(ROOT/b[k])) for b in p['c23Boundary'] for k in ['sourcePath','qntPath','leanPath']})
 need=[[b['key'],'actual-source-refinement:'+b['key']] for b in p['c23Boundary']];perf=[['matched-macos-whole-request-and-runtime-cost']]
 results={};engine=Engine()
 try:
  session=engine.open_sources(rules.read_text());assert session.run(queries=['gap'])['complete']
  for case in ['current','synthetic-all','stale-source','wrong-stage','wrong-descriptor','wrong-proof','model-is-source','component-is-speedup']:
   seen=copy.deepcopy(routes);av=copy.deepcopy(artifacts);sv=copy.deepcopy(need);pv=copy.deepcopy(perf)
   if case=='current':sv=[];pv=[]
   if case=='stale-source':av=[(x[0],'stale') for x in av]
   if case=='wrong-stage':seen[0][2]='native-manifest'
   if case=='wrong-descriptor':seen[0][3]='FS-SEMANTIC'
   if case=='wrong-proof':seen[0][8]='sourceProofSeparate'
   if case=='model-is-source':sv[0][1]='typecheck-and-samples-only'
   if case=='component-is-speedup':pv=[['historical-single-object-result']]
   session.replace(dict(routeNeed=routes,routeSeen=seen,artifactNeed=artifacts,artifactSeen=av,sourceNeed=need,sourceSeen=sv,performanceNeed=perf,performanceSeen=pv))
   result=session.run(queries=['designLinked','gap','nativeGainAccepted']);assert result['complete'];results[case]=result['relations']
 finally:engine.close()
 assert len(results['current']['designLinked'])==4 and not results['current']['nativeGainAccepted']
 assert [k for k,v in results.items() if v['nativeGainAccepted']]==['synthetic-all']
 save(CACHE/'ascent.json',dict(results=results,syntheticIsNotEvidence=True))
 lines=['#+TITLE: C23 Development Refactor Decisions and Retirement Matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitDarwinDevelopment',':STATUS: design checked; native source and performance open',':END:']
 for g,_,_ in GROUPS:
  fields=list(p[g][0]);lines+=['','** '+g,'','| '+' | '.join(fields)+' |','|'+'+'.join('---' for _ in fields)+'|']
  lines+=['| '+' | '.join(str(r[k]).replace('|',' / ') for k in fields)+' |' for r in p[g]]
 matrix=BASE/'c23-development-refactor-matrix.org';matrix.write_text('\n'.join(lines)+'\n')
 d2=BASE/'diagrams/c23-development-refactor.d2';d2.write_text('direction: right\n'+'\n'.join(json.dumps(e['fromNode'])+' -> '+json.dumps(e['toNode'])+': '+json.dumps(e['contract']) for e in p['c23Edge'])+'\n');run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 for f in [BASE/'c23-development-refactor-design.org',matrix,d2,d2.with_suffix('.svg'),BASE/'index.org']:bindings[str(f.relative_to(ROOT))]=sha(f)
 drift=[f for f,v in bindings.items() if sha(ROOT/f)!=v];assert not drift,drift
 checks=dict(nativeSysml=True,nativeSysmlFiles=len(selected),wholeDevValidation=False,featurePolicies=6,typedBoundaryRoutes=4,newPartitionHistories=11,partitionSamples=500,maxSteps=80,seed=953,partitionLeanLaws=8,ascentScenarios=len(results),sourceRefinement=False,verifiedExtractor=False,measuredSpeedup=False,runtimeImplementation=False,nativeTests=0,pathsRetired=0,timeoutSeconds=60)
 save(CACHE/'checks.json',checks);save(CACHE/'input.json',dict(sourceBindings=bindings,leanBinarySha256=sha(LEAN),scope='C23 design and conditional formal routes; no native admission'))
 for f,digest in bindings.items():
  target=CACHE/'input-cut'/f;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(ROOT/f,target);assert sha(target)==digest
 for f in CACHE.rglob('*'):
  if f.is_file():target=OUT/f.relative_to(CACHE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,target)
 save(OUT/'artifacts.json',{str(f.relative_to(ROOT)):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
