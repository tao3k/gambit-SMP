#!/usr/bin/env python3
"""Source-bound architecture research; no runtime builds, native tests or new proof claims."""
import copy, hashlib, importlib.util, json, os, re, shutil
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
NAME='repair-driven-gc-smp'
BASE=ROOT/'dev/refactoring/modern-c'
CACHE=ROOT/'.cache/tasks/future-frame-commit'/NAME
OUT=ROOT/'evidence/research/future-frame-commit'/NAME
GROUPS=[['source', 18, ['key', 'path', 'needle', 'limit']], ['gate', 4, ['key', 'definition', 'required', 'status', 'limit']], ['edge', 12, ['fromNode', 'toNode', 'contract']], ['cut', 8, ['key', 'owner.moduleId', 'owner.ownerPath', 'seam.interfaceId', 'history.obligationId', 'history.subjectPath', 'history.subjectScope', 'induction.obligationId', 'induction.subjectPath', 'induction.subjectScope', 'evidence', 'observation', 'replacement', 'retirement', 'avoided', 'added', 'sourceGap', 'actionName', 'lemmaName', 'projection', 'status']]]

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return str(Path(p).relative_to(ROOT))
def save(p,v):Path(p).write_text(json.dumps(v,indent=2,ensure_ascii=False)+'\n')
def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 spec=importlib.util.spec_from_file_location('process',ROOT/'dev/modeling/tools/size-family-hold-balance-study.py')
 helper=importlib.util.module_from_spec(spec);spec.loader.exec_module(helper);helper.CACHE=CACHE;run=helper.run
 model=BASE/'models/sysml'/ (NAME+'.sysml');dsl=ROOT/'dev/modeling/ascent'/(NAME+'.rules.scm')
 files=run('sysml-input-files',['rg','--files','dev','-g','*.sysml','-g','*.kerml']).splitlines()
 bindings={f:sha(ROOT/f) for f in files}
 for f in [Path(__file__),dsl,ROOT/'dev/modeling/tools/size-family-hold-balance-study.py']:bindings[rel(f)]=sha(f)
 keys=[(g,i,f,'GambitRepairDrivenRefactor::'+g+str(i)+'.'+f) for g,n,fs in GROUPS for i in range(n) for f in fs]
 cmd=['sysml','-strict','-no-record-cache','-validate','-json']
 for *_,expr in keys:cmd+=['-e',expr]
 raw=json.loads(run('sysml',cmd+['dev']))
 assert raw['exit']==0 and not raw.get('errors') and not any(x['severity']=='error' for x in raw.get('diagnostics') or [])
 vals=[json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')];assert len(vals)==len(keys)
 projected={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):projected.setdefault(g,{}).setdefault(i,{})[f]=v
 p={g:list(rs.values()) for g,rs in projected.items()};save(CACHE/'projection.json',p)
 sourceRows=[]
 for row in p['source']:
  f=ROOT/row['path'];text=f.read_text();assert row['needle'] in text,row
  bindings[row['path']]=sha(f);(CACHE/('source-'+sha(f)+'.txt')).write_text(text)
  physical=[text.count('\n',0,m.start())+1 for m in re.finditer(re.escape(row['needle']),text)]
  line=re.match(r'#line (\d+) ___MEM_SOURCE_FILE',text)
  sourceRows.append(dict(**row,sha256=sha(f),physicalLines=physical,logicalMemLines=([int(line[1])+n-2 for n in physical] if line else [])))
 save(CACHE/'source-witnesses.json',sourceRows)
 # The current fragment tree is not silently equated with a frozen repair image.
 mem=ROOT/'vendor/gambit/lib/mem.c';frags=re.findall(r'#include "(_mem/[^"\n]+)"',mem.read_text())
 incl=[]
 for n in frags:
  f=mem.parent/n;bindings[rel(f)]=sha(f);incl.append(dict(path=rel(f),sha256=sha(f)))
 save(CACHE/'current-memory-include-order.json',dict(wrapperSha256=sha(mem),fragments=incl,qualifiedAgainstRepairImage=False))
 symbols=[];routes=[]
 for r in p['cut']:
  q=r['history.subjectPath'];l=r['induction.subjectPath'];a=r['actionName'];t=r['lemmaName']
  assert re.search(r'^\s*action '+re.escape(a)+r'\b',(ROOT/q).read_text(),re.M),(q,a)
  assert re.search(r'^theorem '+re.escape(t)+r'\b',(ROOT/l).read_text(),re.M),(l,t)
  assert 'source-composition-open' in r['history.subjectScope'] and 'source-composition-open' in r['induction.subjectScope']
  for path,name in [(q,a),(l,t)]:bindings[path]=sha(ROOT/path);symbols.append([path,name,sha(ROOT/path)])
  routes.append([r['key'],r['owner.moduleId'],r['seam.interfaceId'],r['evidence'],q,a,l,t,r['history.subjectScope']])
 save(CACHE/'existing-model-symbols.json',dict(symbols=symbols,recompiled=False,reproved=False,newBehavioralModels=0,limitation='Symbol existence is not a concrete source simulation.'))
 protocol=ROOT/'evidence/model-results/research/delivery-wait-refinement/receipt.json';retained=json.loads(protocol.read_text())
 assert retained['scope']=='bounded-protocol-extensions-not-source-refinement' and retained['accepted'] is True
 assert retained['runtimeAdmitted'] is False and retained['releaseAdmitted'] is False
 assert retained['modelSources']['source/delivery_service_roots.qnt']==sha(ROOT/'models/gambit/delivery_service_roots.qnt')
 assert all(r['accepted'] and r['modelSha256']==sha(ROOT/'models/gambit/delivery_service_roots.qnt') for r in retained['results'])
 bindings[rel(protocol)]=sha(protocol)
 save(CACHE/'retained-wait-protocol.json',dict(receipt=rel(protocol),receiptSha256=sha(protocol),modelSha256=sha(ROOT/'models/gambit/delivery_service_roots.qnt'),scope=retained['scope'],recordedChecks=len(retained['results']),tlcRerun=False,nativeAdmission=False))

 src=[[r['key'],r['path'],r['sha256'],r['needle']] for r in sourceRows]
 refinements=[[r['key'],r['history.subjectScope']] for r in p['cut']]
 native=[[r['key'],'same-final-image-complete-original:'+r['key']] for r in p['gate']]
 scenarios={};engine=Engine()
 try:
  session=engine.open_sources(dsl.read_text())
  assert session.run(queries=['gap'])['complete']
  for case in ['current','synthetic-all','stale-source','wrong-owner','wrong-seam','wrong-action','wrong-lemma','wrong-scope','old-image-credit','short-is-original','model-is-source','wrong-symbol-hash']:
   seen=copy.deepcopy(src);rs=copy.deepcopy(routes);sy=copy.deepcopy(symbols);ss=copy.deepcopy(refinements);ns=copy.deepcopy(native)
   if case=='current':ss=[];ns=[]
   if case=='stale-source':seen[0][2]='stale'
   if case=='wrong-owner':rs[0][1]='collector'
   if case=='wrong-seam':rs[0][2]='WorkClosure'
   if case=='wrong-action':rs[0][5]='requestGC'
   if case=='wrong-lemma':rs[0][7]='zeroCountExcludesActive'
   if case=='wrong-scope':ss[0][1]='finite-model-only'
   if case=='old-image-credit':ns[1][1]='old-image-success'
   if case=='short-is-original':ns[3][1]='120k-short-control'
   if case=='model-is-source':ss[2][1]='fragment-pass-not-source-refinement'
   if case=='wrong-symbol-hash':sy[0][2]='stale'
   session.replace(dict(sourceNeed=src,sourceSeen=seen,routeNeed=routes,routeSeen=rs,symbolNeed=symbols,symbolSeen=sy,sourceRefinementNeed=refinements,sourceRefinementSeen=ss,nativeNeed=native,nativeSeen=ns))
   result=session.run(queries=['routeLinked','gap','candidate']);assert result['complete'];scenarios[case]=result['relations']
 finally:engine.close()
 assert [k for k,v in scenarios.items() if v['candidate']]==['synthetic-all']
 assert len(scenarios['current']['routeLinked'])==8
 save(CACHE/'ascent-results.json',dict(results=scenarios,syntheticInputsAreNotEvidence=True,nativeAdmission=False))
 # Verify independently retained source/diagnostic record edges, never execute an image.
 directory=ROOT/'evidence/research/smp-retirement-study'
 ledgers={n:json.loads((directory/n).read_text()) for n in ['delivery-c38e-wait-handoff.json','delivery-048b-select-return.json','delivery-60b3-cost-attribution.json','delivery-2fe7-first-cause.json']}
 for n in ledgers:bindings[rel(directory/n)]=sha(directory/n)
 current=ledgers['delivery-c38e-wait-handoff.json'];old=ledgers['delivery-048b-select-return.json'];cost=ledgers['delivery-60b3-cost-attribution.json']['profile'];first=ledgers['delivery-2fe7-first-cause.json']
 rawEdges=[]
 for label,path,digest in [('c38e-checkpoint',current['rawCheckpoint'],current['rawCheckpointSha256']),('048b-original',old['originalFinal']['receipt'],old['originalFinal']['receiptSha256']),('2fe7-first-error',first['checkpoint'],first['checkpointSha256'])]:
  f=ROOT/path;available=f.is_file()
  if available:assert sha(f)==digest;bindings[path]=sha(f)
  rawEdges.append(dict(label=label,path=path,expectedSha256=digest,available=available,verified=available))
 assert current['nativeAdmitted'] is False and current['originalStarted'] is False
 assert old['originalFinal']['timeout'] is True and first['firstCause']['acceptance'] is False
 reviewed=json.loads((ROOT/current['rawCheckpoint']).read_text())
 metrics=dict(work=120000,baselineP1=cost['p1']['realDeltaSeconds'],baselineP11=cost['p11']['realDeltaSeconds'],wake048b=reviewed['controls']['profile048bRealSeconds'],c38e=reviewed['controls']['profileRealSeconds'],
  p1AllocationValid=cost['p1']['slot16Used'],p11BytesPerRequestConditional=cost['p11']['bytesPerRequest'],perTargetOriginalCalls=1000000*10,parallelTargetsAtP11=(11+1)//2,
  original048bOutcome=old['originalFinal']['outcome'],firstError2fe7=first['firstCause']['firstDisplay'],c38eOriginalStarted=False)
 metrics['p11OverP1']=metrics['baselineP11']/metrics['baselineP1'];metrics['shortWakeGain']=metrics['baselineP11']/metrics['wake048b']
 metrics['isolated60mC38eExtrapolation']=metrics['c38e']*(60000000/metrics['work'])
 metrics['limits']='Observed samples, no confidence interval or original-deadline guarantee; GC wall overlaps CPU/wait, per-target fairness remains required; invalid negative allocation excluded.'
 save(CACHE/'evidence-cut.json',dict(records=rawEdges,images={n:(v.get('image') or v.get('profile',{}).get('imageSha256')) for n,v in ledgers.items()},metrics=metrics,milestone='8/12 retained cut',newNativeRuns=0))
 lines=['#+TITLE: Repair-driven GC / SMP — mechanism, evidence and retirement matrix','#+SETUPFILE: ../../modeling/org/setup.org','#+LANGUAGE: en','#+PROPERTY: header-args :eval never','','* RESEARCH Native SysML projection',':PROPERTIES:',':AUTHORITY: GambitRepairDrivenRefactor',':STATUS: source-bound-research; source-refinement-and-native-open',':END:','','Existing model symbols are linked, not re-proved. A new architecture does not close old native gates.']
 for group in ['cut','gate','edge','source']:
  fields=list(p[group][0]);lines+=['','** '+group.capitalize(),'','| '+' | '.join(fields)+' |','|'+'+'.join('---' for _ in fields)+'|']
  lines+=['| '+' | '.join(str(r[f]).replace('|',' / ') for f in fields)+' |' for r in p[group]]
 lines+=['','** Observed samples and conditional arithmetic','','| measure | value |','|---+---|']+['| '+k+' | '+str(v).replace('|',' / ')+' |' for k,v in metrics.items()]
 matrix=BASE/(NAME+'-matrix.org');matrix.write_text('\n'.join(lines)+'\n')
 d2=BASE/'diagrams'/(NAME+'.d2');d2.write_text('direction: right\ntitle: "Repair evidence -> coupled Gambit C23 GC/SMP redesign"\n'+'\n'.join(json.dumps(r['fromNode'])+' -> '+json.dumps(r['toNode'])+': '+json.dumps(r['contract']) for r in p['edge'])+'\n')
 run('d2',['d2','--layout','elk',str(d2),str(d2.with_suffix('.svg'))])
 org=(ROOT/'evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org','dev/refactoring/modern-c/'+NAME+'-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org','dev/refactoring/modern-c/'+NAME+'-matrix.org').replace('dev/architecture/toolchain/index.org','dev/refactoring/modern-c/index.org')
 (CACHE/'check-org.el').write_text(org);run('org',['emacs','--batch','-Q','--load',str(CACHE/'check-org.el')])
 for f in [BASE/(NAME+'-design.org'),matrix,BASE/'index.org',BASE/'runtime-blueprint.org',d2,d2.with_suffix('.svg')]:bindings[rel(f)]=sha(f)
 assert all(sha(ROOT/f)==h for f,h in bindings.items()),'live input changed during research; retain this attempt and refresh the cut'
 checks=dict(nativeSysmlValidated=True,sourceAnchors=len(src),architectureCuts=len(routes),nativeGateFamilies=len(native),existingModelSymbols=len(symbols),newBehavioralModels=0,existingProofsRerun=False,ascentScenarios=len(scenarios),currentRoutesLinked=8,currentUnclosedObligations=len(scenarios['current']['gap']),memoryFragments=len(incl),rawReceiptEdgesVerified=sum(x['verified'] for x in rawEdges),nativeRuns=0,runtimeImplementation=False,pathsRetired=0,sourceRefinement=False,c23WeakMemoryProof=False,fullCompositionProof=False,nativeAdmission=False,milestoneChanged=False)
 save(CACHE/'checks.json',checks);save(CACHE/'input.json',dict(sourceBindings=bindings,scope='snapshot architecture research only; immutable historical repair generations remain separate',nativeClaim=False))
 for f in CACHE.rglob('*'):
  if f.is_file():
   target=OUT/f.relative_to(CACHE);target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(f,target)
 save(OUT/'artifacts.json',{rel(f):sha(f) for f in OUT.rglob('*') if f.is_file() and f.name!='artifacts.json'})
 print(json.dumps(checks,indent=2))
if __name__=='__main__':main()
