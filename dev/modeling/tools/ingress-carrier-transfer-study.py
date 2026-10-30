#!/usr/bin/env python3
"""Formal architecture study only: native SysML, ASCENT, Quint and Lean; no runtime tests."""
import json,re,importlib.util,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM="ingress-carrier-transfer";PKG="GambitIngressCarrierTransfer";BASE="dev/refactoring/modern-c/"
CACHE=ROOT/".cache/tasks"/STEM;OUT=ROOT/"evidence/research"/STEM
MODEL=BASE+"models/sysml/"+STEM+".sysml";DESIGN=BASE+STEM+"-design.org";MATRIX=BASE+STEM+"-matrix.org"
QNT=BASE+"models/quint/ingress_carrier_transfer.qnt";LEAN=BASE+"models/lean/IngressCarrierTransfer.lean";AST=BASE+"models/lean/IngressCarrierAst.lean";SHARDS=BASE+"models/quint/ingress_nested_custody.qnt"
RULES="dev/modeling/ascent/"+STEM+".rules.scm";D2=BASE+"diagrams/"+STEM+".d2"
spec=importlib.util.spec_from_file_location("helper",ROOT/"dev/modeling/tools/advantage-architecture-study.py");h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
h.CACHE=CACHE;h.OUT=OUT;run=h.run;sha=h.sha;save=h.save
GROUPS=[("route",12,"key sourcePath needle obligation"),("contract",6,"key owner accountable.moduleId counterpart.moduleId actionName invariant gap"),("obligation",7,"key status scope counterexample"),("gain",5,"key avoided added condition"),("binding",3,"key qntAction leanLemma refinement guardLemma updateLemma"),("flow",16,"fromNode toNode reason"),("endorsement",3,"roleName scope issuer sourcePath needle")]
def project():
 keys=[(g,str(i),f,f"{PKG}::{g}{i}.{f}") for g,n,fs in GROUPS for i in range(n) for f in fs.split()]
 for slot in ["history","shards","induction","expression","source","platform"]:
  keys += [("need",slot,f,f"{PKG}::{slot}.{f}") for f in ["obligationId","kind","subjectPath","subjectScope"]]
 for i in range(6):keys += [("dependency",str(i),f,f"{PKG}::dependency{i}.{f}") for f in ["dependent.obligationId","prerequisite.obligationId","prerequisite.subjectPath","prerequisite.subjectScope"]]
 files=sorted(run("sysml-files",["rg","--files","dev","-g","*.sysml","-g","*.kerml"]).splitlines());save(CACHE/"sysml-input-scope.json",dict(files={f:sha(ROOT/f) for f in files},excluded={}))
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 native=json.loads(run("sysml",args+["dev"]));assert native["exit"]==0 and not native.get("errors")
 vals=[json.loads(x[4:]) for x in native["output"] if x.startswith("  = ")];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);save(CACHE/"native-queries.json",keys);return p

def views(p):
 lines=["#+TITLE: Ingress Carrier Transfer and Nested Custody Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+LANGUAGE: en","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: ingress-carrier-transfer-matrix",":AUTHORITY: GambitIngressCarrierTransfer",":STATUS: conditional-models-only; source-and-platform-open",":END:"]
 for g,_,fs in GROUPS:
  fs=fs.split();lines += ["","** "+g.capitalize(),"","| "+" | ".join(fs)+" |","|"+"+".join("---" for _ in fs)+"|"]
  lines += ["| "+" | ".join(str(v[f]) for f in fs)+" |" for v in p[g]]
 lines += ["","** Model admission scopes","","| ID | kind | subject | scope |","|---+---+---+---|"]
 lines += ["| "+" | ".join(v[f] for f in ["obligationId","kind","subjectPath","subjectScope"])+" |" for v in p["need"].values()]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 graph=['direction: down']
 for i,v in enumerate(p["contract"]):graph += [f"c{i}: "+json.dumps(v["key"]+"\n"+v["invariant"])]
 
 for i,v in enumerate(p["obligation"]):graph += [f"o{i}: "+json.dumps(v["key"]+"\n"+v["status"])]
 valid={f"c{i}" for i in range(len(p["contract"]))}|{f"o{i}" for i in range(len(p["obligation"]))}
 for v in p["flow"]:
  assert v["fromNode"] in valid and v["toNode"] in valid
  graph.append(v["fromNode"]+" -> "+v["toNode"]+": "+json.dumps(v["reason"]))
 (ROOT/D2).write_text("\n".join(graph)+"\n")

def ascend(p):
 needs=[[v["obligationId"],v["kind"],v["subjectPath"],sha(ROOT/v["subjectPath"]),v["subjectScope"]] for v in p["need"].values()]
 parent=p["dependency"]["3"];needs.append([parent["prerequisite.obligationId"],"source-refinement",parent["prerequisite.subjectPath"],sha(ROOT/parent["prerequisite.subjectPath"]),parent["prerequisite.subjectScope"]])
 rows=[[v["key"],v["sourcePath"],sha(ROOT/v["sourcePath"]),v["needle"]] for v in p["route"]]
 bindings=[[v["key"],v["qntAction"],v["leanLemma"]] for v in p["binding"]]
 actions=[[x] for x in re.findall(r"^ action (\w+)", (ROOT/QNT).read_text(),re.M)]
 lemmas=[[x] for x in re.findall(r"^theorem (\w+)", (ROOT/LEAN).read_text(),re.M)]
 results={};engine=h.Engine()
 try:
  s=engine.open_sources((ROOT/RULES).read_text());queries=["candidate","blocked","checked","linked","observed","route","bridgeLinked","envLinked","endorsed"];assert s.run(queries=queries)["complete"]
  for case in ["current","stale-digest","wrong-scope","missing-parent","missing-action","wrong-lemma","missing-source","missing-expression","missing-certificate","missing-shards","missing-environment","missing-endorsement","stale-endorsement-source","synthetic-all"]:
   rec=[[case,n,path,d,scope] for n,k,path,d,scope in needs if case!="current" or k in ["interleaving","induction"]]
   if case=="stale-digest":rec=[x[:3]+["stale"]+x[4:] if x[1]=="IC-I" else x for x in rec]
   if case=="wrong-scope":rec=[x[:4]+["all-extraction-verified"] if x[1]=="IC-I" else x for x in rec]
   if case=="missing-shards":rec=[x for x in rec if x[1]!="IC-B"]
   if case=="missing-expression":rec=[x for x in rec if x[1]!="IC-X"]
   if case=="missing-parent":rec=[x for x in rec if x[1]!="FA-S"]
   bs=[x.copy() for x in bindings]
   if case=="wrong-lemma":bs[0][2]="nonexistentLemma"
   ac=[x for x in actions if case!="missing-action" or x[0]!="publishTarget"]
   obs=rows[1:] if case=="missing-source" else rows
   cb=[[v["key"],v["guardLemma"],v["updateLemma"]] for v in p["binding"]]
   certs=[[x] for x in re.findall(r"^theorem (\w+)",(ROOT/AST).read_text(),re.M) if case!="missing-certificate" or x!="publishTargetNextMeaning"]
   envs=[x for x in lemmas+certs if case!="missing-environment" or x[0]!="environmentExactDomain"]
   endorsements=[[v["roleName"],v["scope"],v["issuer"]] for v in p["endorsement"]]
   delivered=[[case]+v for v in endorsements if case!="current" and (case!="missing-endorsement" or v[0]!="semantic")]
   sourceEndorsements=[[v["roleName"],v["sourcePath"],sha(ROOT/v["sourcePath"]),v["needle"]] for v in p["endorsement"]]
   for v in p["endorsement"]:assert v["needle"] in (ROOT/v["sourcePath"]).read_text()
   attestations=[[case]+v for v in sourceEndorsements if case!="current"]
   if case=="stale-endorsement-source":attestations[0][3]="stale"
   s.replace(dict(endorsementSource=sourceEndorsements,endorsementAttestation=attestations,endorsementNeed=endorsements,endorsementReceipt=delivered,scenario=[[case]],envNeed=[["environmentNoFabrication"],["environmentExactDomain"],["actualEnvAgrees"]],envLemma=envs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source"],["environment-refinement","platform"]],need=needs,receipt=rec,bridgeBinding=cb,certificateLemma=certs,binding=bs,modelAction=ac,modelLemma=lemmas,witness=rows,observation=obs))
   result=s.run(queries=queries);assert result["complete"];results[case]=result["relations"]
  save(CACHE/"ascent-attempt-results.json",results)
  assert len(results["current"]["checked"])==4 and len(results["current"]["linked"])==3 and len(results["current"]["bridgeLinked"])==3
  assert len(results["synthetic-all"]["candidate"])==1
  for case,reason in [("stale-digest","IC-I"),("wrong-scope","IC-I"),("missing-parent","FA-S"),("missing-action","roots"),("wrong-lemma","guard"),("missing-source",p["route"][0]["key"]),("missing-expression","IC-X"),("missing-certificate","roots"),("missing-shards","IC-B"),("missing-environment","environmentExactDomain"),("missing-endorsement","semantic"),("stale-endorsement-source","semantic")]:
   assert [case,reason] in results[case]["blocked"],(case,reason)
  assert all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-results.json",dict(results=results,syntheticNotRealEvidence=True,sourceRefinement=False))

def load(name,path):
 sp=importlib.util.spec_from_file_location(name,ROOT/path);m=importlib.util.module_from_spec(sp);sp.loader.exec_module(m);return m

def extraction_evidence():
 import copy
 checker=load("binding_checker","dev/modeling/tools/typed-binding-witness.py")
 irpath=ROOT/"evidence/research/reti-ofd-semantics/typed-ir.json";old=checker.read_json(irpath.read_text());w=checker.check(old)
 refs=w["references"];save(CACHE/"binding-witness.json",dict(**w,inputSha256=sha(irpath)))
 projector=load("receipt_projector","dev/modeling/tools/ingress-carrier-transfer-projection.py")
 ir=checker.read_json((CACHE/"typed-ir.json").read_text());ast=projector.generate(ir,refs);(ROOT/AST).write_text(ast)
 line=next(x for x in ast.splitlines() if x.startswith("def actualRows"))
 pairs=[(int(k),int(v)) for k,v in re.findall(r"\((\d+),(\d+)\)",line)]
 expected=[(v["occurrence"],v["target"]) for v in refs];assert pairs==expected
 controls={"drop":pairs[1:],"wrong-target":[(pairs[0][0],pairs[0][1]+1)]+pairs[1:],"reorder":list(reversed(pairs))}
 assert all(v!=expected for v in controls.values())
 save(CACHE/"row-projection-controls.json",dict(rejected=list(controls),exactOrderedWitness=True,reorderIsManifestMismatchNotSemanticCounterexample=True))
 save(CACHE/"expression-projection.json",dict(actions=["registerTarget","publishTarget","releaseSource"],typedIrSha256=sha(CACHE/"typed-ir.json"),astSha256=sha(ROOT/AST),references=len(refs),parserVerified=False,projectorVerified=False))
 return ast


def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/"evidence/research/ffi-scope-root-admission/input.json";ph=sha(parent)
 p=project();views(p)
 witnesses=[]
 for v in p["route"]:
  text=(ROOT/v["sourcePath"]).read_text();assert v["needle"] in text
  witnesses.append(dict(**v,sha256=sha(ROOT/v["sourcePath"]),line=text[:text.index(v["needle"])].count("\n")+1))
 save(CACHE/"source-witnesses.json",witnesses)
 inventory=run("native-scope-callers",["rg","-l","___write_authority_(try_handoff|try_acquire|release|close|quiescent)","vendor/gambit/lib","vendor/gambit/gsc","vendor/gambit/include","-g","*.[ch]","-g","*.scm","-g","*.in"])
 save(CACHE/"native-scope-callers.json",dict(paths=inventory.splitlines(),scope="lib/gsc/include production sources only",integrationQualified=False))
 callers=run("carrier-source-callers",["rg","-n",r"___run[[:space:]]*\(|data_scmobj", "vendor/gambit/lib","vendor/gambit/gsc","vendor/gambit/include","vendor/gambit/examples","-g","*.[ch]","-g","*.in","-g","*.scm"])
 save(CACHE/"carrier-source-callers.json",dict(observations=callers.splitlines(),scope="bounded lib/gsc/include/examples source inventory; not arbitrary external callers",callerClosureQualified=False))
 lean=(ROOT/LEAN).read_text();assert "sorry" not in lean and "axiom " not in lean
 reuse="--reuse-formal" in sys.argv
 if reuse:
  old=json.loads((CACHE/"input.json").read_text())
  for f in [QNT,SHARDS,LEAN,AST,"dev/modeling/tools/ingress-carrier-transfer-projection.py","dev/modeling/tools/typed-binding-witness.py",BASE+"models/lean/DarwinForceBinding.lean",BASE+"models/lean/DerivationReceiptEnvironment.lean",BASE+"models/lean/SnapshotObserverRefinement.lean",BASE+"models/lean/PinRosterDetachment.lean",BASE+"models/lean/FfiScopeRootAdmission.lean"]:
   assert sha(ROOT/f)==old["sourceBindings"][f],f
  for f,d in old["logs"].items():
   if any(k in f for k in ["quint-","typecheck","IngressCarrier","FfiScopeRoot","PinRoster","SnapshotObserver","DerivationReceiptEnvironment.","DarwinForceBinding.","negative-guard"]):assert sha(ROOT/f)==d,f
  ast=extraction_evidence();assert sha(ROOT/AST)==old["sourceBindings"][AST]
 else:
  run("quint-typecheck",["quint","typecheck",QNT,"--out",str(CACHE/"typed-ir.json")])
  run("shard-typecheck",["quint","typecheck",SHARDS,"--out",str(CACHE/"shard-typed-ir.json")])
  ast=extraction_evidence()
  for name,path,n,neg in [("pin",QNT,8,4),("shard",SHARDS,6,3)]:
   tests=run(name+"-quint-tests",["quint","test",path,"--match","Test$"]);assert tests.count("ok ")==n and tests.count("ControlTest passed")==neg
   run(name+"-quint-samples",["quint","run",path,"--init","init","--invariant","safe","--max-samples","500","--max-steps","200","--seed","41","--verbosity","1"])
  for name,path in [("DarwinForceBinding",BASE+"models/lean/DarwinForceBinding.lean"),("DerivationReceiptEnvironment",BASE+"models/lean/DerivationReceiptEnvironment.lean"),("SnapshotObserverRefinement",BASE+"models/lean/SnapshotObserverRefinement.lean"),("PinRosterDetachment",BASE+"models/lean/PinRosterDetachment.lean"),("FfiScopeRootAdmission",BASE+"models/lean/FfiScopeRootAdmission.lean"),("IngressCarrierTransfer",LEAN),("IngressCarrierAst",AST)]:
   src=CACHE/(name+".lean");src.write_bytes((ROOT/path).read_bytes())
   run(name,["env",f"LEAN_PATH={CACHE}","lean","-o",str(CACHE/(name+".olean")),str(src)])
  mutant="\n".join(line.replace("¬"," ") if line.startswith("def irReleaseGuard") else line for line in ast.splitlines())+"\n"
  assert mutant!=ast;(CACHE/"WrongGuard.lean").write_text(mutant)
  try:run("negative-guard-certificate",["env",f"LEAN_PATH={CACHE}","lean",str(CACHE/"WrongGuard.lean")])
  except RuntimeError:assert "error:" in (CACHE/"negative-guard-certificate.stdout").read_text()
  else:raise AssertionError("wrong receipt guard certified")
 ascend(p)
 run("d2-svg",["d2",D2,D2[:-3]+".svg"]);run("d2-png",["d2",D2,str(CACHE/"diagram.png")])
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text().replace("dev/architecture/toolchain/iter-compiler-service-design.org",DESIGN).replace("dev/architecture/toolchain/iter-compiler-service-matrix.org",MATRIX).replace("dev/architecture/toolchain/index.org",BASE+"index.org")
 (CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 files={BASE+"models/lean/FfiScopeRootAdmission.lean",BASE+"models/lean/PinRosterDetachment.lean",BASE+"models/lean/SnapshotObserverRefinement.lean"}|{v["sourcePath"] for v in p["route"]}|{SHARDS,AST,BASE+"models/lean/DerivationReceiptEnvironment.lean","dev/modeling/tools/ingress-carrier-transfer-projection.py",BASE+"models/lean/DarwinForceBinding.lean",MODEL,DESIGN,MATRIX,QNT,LEAN,RULES,D2,D2[:-3]+".svg",BASE+"index.org","dev/modeling/tools/"+STEM+"-study.py","dev/modeling/tools/advantage-architecture-study.py","dev/modeling/tools/map-expression-projection.py","dev/modeling/tools/typed-binding-witness.py","dev/refactoring/modern-c/models/quint/map_frame_abi.qnt","evidence/research/reti-ofd-semantics/typed-ir.json","dev/refactoring/modern-c/models/lean/MapExpressionAst.lean","vendor/gambit/include/gambit.h.in","vendor/gambit/lib/setup.h","vendor/gambit/lib/write_authority.h"}
 scope=json.loads((CACHE/"sysml-input-scope.json").read_text())
 for f,d in scope["files"].items():assert sha(ROOT/f)==d,f
 for v in witnesses:assert sha(ROOT/v["sourcePath"])==v["sha256"]
 assert sha(parent)==ph
 checks=dict(status="conditional-local-models-pass",wholeDevSysmlInputs=len(scope["files"]),sourceRoutes=12,qntHistories=14,transferHistories=8,nestedHistories=6,negativeControls=7,sampledRuns=500,maxSteps=200,leanTheorems=len(re.findall(r"^theorem ",lean,re.M)),ascentScenarios=14,formalBindings=3,negativeLeanCertificates=1,astTheorems=len(re.findall(r"^theorem ",ast,re.M)),formalChecksReused=reuse,sourceQualified=False,bindingWitnessReferences=91,rowProjectionRefusals=3,jsonBindingExtractionVerified=False,fullActionExtractionVerified=False,qntToLeanFullSimulation=False,c11Refinement=False,nativeTestsRun=False,performanceTestsRun=False,hostRegistration="inherited unresolved; not retried")
 save(CACHE/"checks.json",checks)
 save(CACHE/"input.json",dict(head=run("head",["git","rev-parse","HEAD"]).strip(),branch=run("branch",["git","branch","--show-current"]).strip(),sourceBindings={f:sha(ROOT/f) for f in sorted(files)},parentInputSha256=ph,parentFrozen=True,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in {".stdout",".stderr"}}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in {".json",".el",".lean",".qnt"}:(OUT/f.name).write_bytes(f.read_bytes())
 save(OUT/"artifacts.json",{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!="artifacts.json"});print(json.dumps(checks))
if __name__=="__main__":main()
