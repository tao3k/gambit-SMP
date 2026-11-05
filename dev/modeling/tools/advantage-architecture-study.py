#!/usr/bin/env python3
"""Design/formal orchestration; native SysML owns architecture metadata. No runtime execution."""
import hashlib,json,re,subprocess,textwrap
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
STEM="advantage-architecture";PKG="GambitAdvantageArchitecture"
BASE="dev/refactoring/modern-c/"
MODEL=BASE+"models/sysml/"+STEM+".sysml"
QNT=BASE+"models/quint/advantage_architecture.qnt";LEAN=BASE+"models/lean/AdvantageArchitecture.lean"
DESIGN=BASE+STEM+"-design.org";MATRIX=BASE+STEM+"-matrix.org";D2=BASE+"diagrams/"+STEM+".d2"
RULES="dev/modeling/ascent/"+STEM+".rules.scm"
CACHE=ROOT/".cache/tasks"/STEM;OUT=ROOT/"evidence/research"/STEM
GROUPS=[("owner",9,"module.moduleId module.ownerPath module.owns module.provides module.excludes"),
 ("decision",6,"decision.decisionId decision.owner.moduleId decision.replacement decision.retirement decision.interleaving.obligationId decision.interleaving.subjectPath decision.interleaving.subjectScope decision.induction.obligationId decision.induction.subjectPath decision.induction.subjectScope"),
 ("advantage",4,"key paper section basis frameDesign control gcSmp build refutation"),
 ("contract",12,"key seam.interfaceId seam.producerId seam.consumerId actionName guardName lemmaName sourcePath sourceNeedle premise retirement benefit added gap"),
 ("use",23,"advantage.key contract.key obligation"),
 ("benefit",6,"key avoided added condition evidence"),
 ("open",7,"key qualified subjectPath scope reason")]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2,ensure_ascii=False)+"\n")
def run(name,args):
 p=subprocess.run(args,cwd=ROOT,capture_output=True,text=True,timeout=60)
 (CACHE/(name+".stdout")).write_text(p.stdout);(CACHE/(name+".stderr")).write_text(p.stderr)
 save(CACHE/(name+".command.json"),args)
 if p.returncode:
  receipt=dict(argv=args,exit=p.returncode,stdout=p.stdout,stderr=p.stderr)
  save(CACHE/(name+".failure-"+hashlib.sha256(json.dumps(receipt,sort_keys=True).encode()).hexdigest()[:12]+".json"),receipt)
  raise RuntimeError(name+" failed; raw diagnostics retained")
 return p.stdout
def project():
 keys=[]
 for group,count,schema in GROUPS:
  keys += [(group,str(i),f,f"{PKG}::{group}{i}.{f}") for i in range(count) for f in schema.split()]
 for slot in ["history","induction","source","platform"]:
  keys += [("need",slot,f,f"{PKG}::{slot}.{f}") for f in ["obligationId","kind","subjectPath","subjectScope"]]
 for i in range(5):keys += [("dependency",str(i),f,f"{PKG}::dependency{i}.{f}") for f in ["dependent.obligationId","prerequisite.obligationId","prerequisite.subjectPath","prerequisite.subjectScope"]]
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 files=sorted(run("sysml-files",["rg","--files","dev","-g","*.sysml","-g","*.kerml"]).splitlines())
 save(CACHE/"sysml-input-scope.json",dict(files={f:sha(ROOT/f) for f in files},excluded={},scope="whole DEV native load"))
 native=json.loads(run("sysml",args+["dev"]))
 assert native["exit"]==0 and not native.get("errors") and not any(d["severity"]=="error" for d in native.get("diagnostics",[]))
 vals=[json.loads(x[4:]) for x in native["output"] if x.startswith("  = ")];assert len(keys)==len(vals)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);save(CACHE/"native-queries.json",keys)
 return p

def views(p):
 lines=["#+TITLE: Gambit Advantage Architecture — Benefit and Closure Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+LANGUAGE: en","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: advantage-architecture-matrix",":AUTHORITY: GambitAdvantageArchitecture",":STATUS: finite-protocols-pass; whole-source-and-platform-open",":END:","","Native SysML owns these rows; all modern-C responsibilities reference existing owners."]
 for group,_,schema in GROUPS:
  fields=schema.split();lines += ["","** "+group.capitalize(),"","| "+" | ".join(fields)+" |","|"+"+".join("---" for _ in fields)+"|"]
  lines += ["| "+" | ".join(str(v[f]) for f in fields)+" |" for v in p[group]]
 lines += ["","** Exact scoped model subjects","","| id | kind | subject | scope |","|---+---+---+---|"]
 lines += ["| "+" | ".join(v[f] for f in ["obligationId","kind","subjectPath","subjectScope"])+" |" for v in p["need"].values()]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 # Cross-module diagram uses only canonical interface endpoints and native model rows.
 graph=["direction: right",'title: "Gambit modern C: one semantic contract across control, GC/SMP and builds"']
 for v in p["owner"]:
  key=v["module.moduleId"];graph.append(json.dumps(key)+": "+json.dumps(key+"\n"+textwrap.fill(v["module.provides"],45)))
 seen=set()
 for v in p["contract"]:
  edge=(v["seam.producerId"],v["seam.consumerId"],v["seam.interfaceId"])
  if edge not in seen:graph.append(json.dumps(edge[0])+" -> "+json.dumps(edge[1])+": "+json.dumps(edge[2]));seen.add(edge)
 graph += ['proof: "SysML -> ASCENT -> QNT / Lean\\nFinite / conditional checks; whole source and native OPEN"','"build" -> proof']
 for i,v in enumerate(p["advantage"]):graph += [f"idea{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["refutation"],48)),f"idea{i} -> proof"]
 (ROOT/D2).write_text("\n".join(graph)+"\n")

def ascend(p,witnesses):
 needs=[[v["obligationId"],v["kind"],v["subjectPath"],sha(ROOT/v["subjectPath"]),v["subjectScope"]] for v in p["need"].values()]
 whole=[]
 for v in p["decision"]:
  for kind in ["interleaving","induction"]:
   path=v["decision."+kind+".subjectPath"]
   whole.append([v["decision."+kind+".obligationId"],path,sha(ROOT/path),v["decision."+kind+".subjectScope"]])
 for v in p["dependency"].values():
  if v["prerequisite.obligationId"] not in [n[0] for n in needs]:
   path=v["prerequisite.subjectPath"];whole.append([v["prerequisite.obligationId"],path,sha(ROOT/path),v["prerequisite.subjectScope"]])
 assert len(whole)==14 and len(set(x[0] for x in whole))==14
 owners=[[v["module.moduleId"],v["module.ownerPath"]] for v in p["owner"]]
 papers=[[v["key"],v["paper"],v["section"]] for v in p["advantage"]]
 uses=[[v["advantage.key"],v["contract.key"],v["obligation"]] for v in p["use"]]
 assert len(uses)==len(set(tuple(v) for v in uses))
 contracts=[[v[k] for k in ["key","seam.interfaceId","seam.producerId","seam.consumerId","actionName","guardName","lemmaName","sourcePath"]]+[sha(ROOT/v["sourcePath"]),v["sourceNeedle"]] for v in p["contract"]]
 steps=[[v["actionName"],v["guardName"],v["lemmaName"]] for v in p["contract"]]
 queries=["candidate","blocked","checked","route","ownerok","paperok","contractok","useok","wholeok"]
 cases=["current","stale-hash","wrong-scope","missing-contract","wrong-guard","wrong-source","missing-owner","missing-use","missing-whole","scope-widening","missing-paper","synthetic-all"]
 engine=Engine();results={}
 try:
  sess=engine.open_sources((ROOT/RULES).read_text());assert sess.run(queries=queries)["complete"]
  for case in cases:
   full=case!="current"
   receipts=[[case,n,path,h,scope] for n,k,path,h,scope in needs if full or k in ["interleaving","induction"]]
   if case=="stale-hash":receipts=[v[:3]+["stale"]+v[4:] if v[1]=="AA-H" else v for v in receipts]
   if case=="wrong-scope":receipts=[v[:4]+["wider-scope"] if v[1]=="AA-I" else v for v in receipts]
   wholereceipts=[[case]+v for i,v in enumerate(whole) if full and not(case=="missing-whole" and i==0)]
   if case=="scope-widening":wholereceipts=[v[:4]+["local-fragment-only"] if i==0 else v for i,v in enumerate(wholereceipts)]
   cb=[v.copy() for i,v in enumerate(contracts) if not(case=="missing-contract" and i==0)]
   if case=="wrong-guard":cb[0][5]="wrong-guard"
   if case=="wrong-source":cb[0][8]="wrong-source-digest"
   sess.replace(dict(scenario=[[case]],need=needs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source-audit"],["environment-refinement","platform"]],receipt=receipts,
    gate=[[case,v["key"],str(full).lower()] for v in p["open"]],ownerneed=owners,ownerbinding=[v for i,v in enumerate(owners) if not(case=="missing-owner" and i==0)],
    contractneed=contracts,contractbinding=cb,modelstep=steps,sourcewitness=[[v["path"],v["sha256"],v["needle"]] for v in witnesses],
    paperneed=papers,paperbinding=[v for i,v in enumerate(papers) if not(case=="missing-paper" and i==0)],useneed=uses,usebinding=[v for i,v in enumerate(uses) if not(case=="missing-use" and i==0)],
    wholeneed=whole,wholereceipt=wholereceipts))
   res=sess.run(queries=queries);assert res["complete"];results[case]=res["relations"]
  save(CACHE/"ascent-attempt-results.json",dict(results=results,whole=whole))
  assert len(results["current"]["checked"])==2 and len(results["current"]["route"])==4
  assert len(results["current"]["contractok"])==12 and len(results["current"]["useok"])==23
  assert len(results["current"]["ownerok"])==9 and len(results["current"]["paperok"])==4
  assert len(results["missing-use"]["useok"])==22
  assert len(results["scope-widening"]["wholeok"])==13 and len(results["missing-whole"]["wholeok"])==13
  assert not results["current"]["wholeok"]
  assert len(results["synthetic-all"]["candidate"])==1
  assert all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-results.json",dict(results=results,wholeRequired=whole,syntheticIsNotRealEvidence=True,repositoryRegistered=False,nativeAdmitted=False))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parents=["evidence/research/marker-alias-revocation/input.json","evidence/research/iter-compiler-service/input.json"]
 parenthash={f:sha(ROOT/f) for f in parents}
 frozen={}
 for f in parents:
  old=json.loads((ROOT/f).read_text()).get("sourceBindings",{})
  frozen[f]=[dict(path=k,oldSha256=h,currentSha256=sha(ROOT/k)) for k,h in old.items() if sha(ROOT/k)!=h]
 save(CACHE/"parent-drift.json",dict(parents=parenthash,drift=frozen,inheritedSourceQualified=False,parentsNeverRewritten=True))
 p=project();views(p)
 q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text();assert "sorry" not in l and "axiom " not in l
 witnesses=[]
 for v in p["contract"]:
  path=v["sourcePath"];text=(ROOT/path).read_text();needle=v["sourceNeedle"]
  assert needle in text,(v["key"],path,needle)
  action=re.search(r"action\s+"+v["actionName"]+r"(?:\([^\n]*?\))?=all\{(.*?)(?=\n action|\n run|\n})",q,re.S)
  assert action and v["guardName"] in action.group(1).split("s'=",1)[0],v["key"]
  assert "theorem "+v["lemmaName"]+" " in l,v["key"]
  witnesses.append(dict(key=v["key"],path=path,sha256=sha(ROOT/path),needle=needle,line=text[:text.index(needle)].count("\n")+1,action=v["actionName"],guard=v["guardName"],lemma=v["lemmaName"],sourceSimulationProved=False))
 save(CACHE/"source-contract-witnesses.json",witnesses)
 tests=run("quint-tests",["quint","test",QNT,"--match","Test$"])
 assert tests.count("ok ")==23 and tests.count("ControlTest passed")==11,tests
 run("quint-samples",["quint","run",QNT,"--init","init","--invariant","safe","--max-samples","300","--max-steps","160","--seed","23","--verbosity","1"])
 run("lean",["lean",LEAN]);ascend(p,witnesses)
 run("d2-svg",["d2",D2,D2[:-3]+".svg"]);run("d2-png",["d2",D2,str(CACHE/"diagram.png")])
 save(OUT/"checks.json",dict(status="pending-final-receipt",runtimeAdmitted=False))
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text()
 org=org.replace("dev/architecture/toolchain/iter-compiler-service-design.org",DESIGN).replace("dev/architecture/toolchain/iter-compiler-service-matrix.org",MATRIX).replace("dev/architecture/toolchain/index.org",BASE+"index.org")
 (CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 sources={v["sourcePath"] for v in p["contract"]}
 sources.update(["vendor/gambit/gsc/_back.scm","vendor/gambit/gsc/_t-c-2.scm","vendor/gambit/gsc/_t-c-3.scm","vendor/gambit/lib/gambit/list/list.scm","vendor/gambit/lib/_std.c","vendor/gambit/lib/_io.scm","../gerbil-gambit-bootstrap-audit/src/std/make.ss","../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss","../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss","../gerbil-gambit-bootstrap-audit/src/std/iter.ss","../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss","../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss"])
 sources.update([MODEL,DESIGN,MATRIX,D2,D2[:-3]+".svg",QNT,LEAN,RULES,"dev/modeling/tools/"+STEM+"-study.py",BASE+"index.org",BASE+"modernization-target.org",BASE+"map-multishot-composition.org",BASE+"models/sysml/modernization-target.sysml",BASE+"models/sysml/map-multishot-composition.sysml","dev/architecture/runtime/models/sysml/composition.sysml","dev/architecture/toolchain/models/sysml/iter-compiler-service.sysml","dev/architecture/toolchain/models/sysml/marker-alias-revocation.sysml"])
 for v in p["decision"]:
  sources.update([v["decision.interleaving.subjectPath"],v["decision.induction.subjectPath"]])
 for f,h in parenthash.items():assert sha(ROOT/f)==h,f
 for v in witnesses:assert sha(ROOT/v["path"])==v["sha256"],v["path"]
 scope=json.loads((CACHE/"sysml-input-scope.json").read_text())
 for f,h in scope["files"].items():assert sha(ROOT/f)==h,f
 checks=dict(status="conditional-local-models-pass",wholeDevSysmlInputs=len(scope["files"]),sysmlExcluded=0,canonicalOwners=9,canonicalInterfaces=9,existingDecisions=6,advantages=4,advantageUses=23,sourceContractBindings=12,benefitRows=6,qntHistories=23,negativeControls=11,sampledRuns=300,maxSteps=160,leanTheorems=len(re.findall(r"^theorem ",l,re.M)),ascentScenarios=12,wholeCompositionRequiredScopes=14,wholeCompositionQualifiedScopes=0,openScopes=7,fullQntLeanSimulation=False,sourceSimulation=False,c11Refinement=False,nativeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False,hostRegistration="inherited unresolved; not retried")
 save(CACHE/"checks.json",checks)
 save(CACHE/"input.json",dict(head=run("head",["git","rev-parse","HEAD"]).strip(),branch=run("branch",["git","branch","--show-current"]).strip(),sourceBindings={f:sha(ROOT/f) for f in sorted(sources)},parentInputs=parenthash,parentDrift=frozen,inheritedSourceQualified=False,logs={str(x.relative_to(ROOT)):sha(x) for x in CACHE.iterdir() if x.suffix in {".stdout",".stderr"}}))
 for x in CACHE.iterdir():
  if x.is_file() and x.suffix in {".json",".el"}:(OUT/x.name).write_bytes(x.read_bytes())
 save(OUT/"artifacts.json",{str(x.relative_to(ROOT)):sha(x) for x in OUT.iterdir() if x.is_file() and x.name!="artifacts.json"})
 print(json.dumps(checks))
if __name__=="__main__":main()
