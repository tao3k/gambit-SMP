#!/usr/bin/env python3
"""Native SysML, official typed IR and Lean certificates; no runtime implementation/test."""
import json,re,copy,hashlib,importlib.util,subprocess,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];STEM="reti-ofd-semantics";PKG="GambitRetiOfdSemantics";BASE="dev/refactoring/modern-c/"
CACHE=ROOT/".cache/tasks"/STEM;OUT=ROOT/"evidence/research"/STEM
MODEL=BASE+"models/sysml/"+STEM+".sysml";DESIGN=BASE+STEM+"-design.org";MATRIX=BASE+STEM+"-matrix.org";D2=BASE+"diagrams/"+STEM+".d2"
RULES="dev/modeling/ascent/"+STEM+".rules.scm";QNT=BASE+"models/quint/reti_ofd_retirement.qnt";PARENTQ=BASE+"models/quint/map_frame_abi.qnt"
LEAN=BASE+"models/lean/RetiOfdSemantics.lean";AST=BASE+"models/lean/MapExpressionAst.lean";PARENTL=BASE+"models/lean/MapFrameAbi.lean"
HELPER="dev/modeling/tools/advantage-architecture-study.py";PROJECTOR="dev/modeling/tools/map-expression-projection.py"
def load(name,f):
 spec=importlib.util.spec_from_file_location(name,ROOT/f);m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m);return m
h=load("research_helper",HELPER);h.CACHE=CACHE;h.OUT=OUT;run=h.run;sha=h.sha;save=h.save
GROUPS=[("owner",9,"moduleId ownerPath owns"),("route",10,"key sourcePath needle obligation proofScope"),("shape",9,"key kind count storedFs linkSlot mask actualFs provenance"),("bridge",8,"key qualified lemma premise gap"),("user",8,"key sourcePath needle resource close finalUse unknown"),("gain",4,"key avoided added condition"),("gate",7,"key qualified duty")]
def project():
 keys=[]
 for group,count,schema in GROUPS:keys += [(group,str(i),f,f"{PKG}::{group}{i}.{f}") for i in range(count) for f in schema.split()]
 for slot in ["history","induction","expression","source","platform"]:keys += [("need",slot,f,f"{PKG}::{slot}.{f}") for f in ["obligationId","kind","subjectPath","subjectScope"]]
 for i in range(5):keys += [("dependency",str(i),f,f"{PKG}::dependency{i}.{f}") for f in ["dependent.obligationId","prerequisite.obligationId","prerequisite.subjectPath","prerequisite.subjectScope"]]
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 files=sorted(run("sysml-files",["rg","--files","dev","-g","*.sysml","-g","*.kerml"]).splitlines());save(CACHE/"sysml-input-scope.json",dict(files={f:sha(ROOT/f) for f in files},excluded={}))
 raw=json.loads(run("sysml",args+["dev"]));assert raw["exit"]==0 and not raw.get("errors")
 vals=[json.loads(x[4:]) for x in raw["output"] if x.startswith("  = ")];assert len(vals)==len(keys);p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);save(CACHE/"native-queries.json",keys);return p

def views(p):
 lines=["#+TITLE: RETI/OFD, Typed Expression Bridge and Retirement Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+LANGUAGE: en","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: reti-ofd-semantics-matrix",":AUTHORITY: GambitRetiOfdSemantics",":STATUS: restricted-AST-proved; trusted-extraction-and-source-open",":END:"]
 for g,_,schema in GROUPS:
  fs=schema.split();lines += ["","** "+g.capitalize(),"","| "+" | ".join(fs)+" |","|"+"+".join("---" for _ in fs)+"|"]
  lines += ["| "+" | ".join(str(v[f]) for f in fs)+" |" for v in p[g]]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 graph=['direction: down']
 for i,v in enumerate(p["route"]):graph.append(f"r{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["obligation"],55)))
 for a,b in [(0,1),(1,2),(2,3),(3,4),(4,5),(5,6),(5,7),(2,8),(8,5),(8,9)]:graph.append(f"r{a} -> r{b}")
 graph += ['ast: "Official typed IR -> rejecting extraction -> Lean AST interpreter\\nKernel meaning proofs: selected AST only"','trust: "Parser/extractor conformance + concrete Scheme/C/native: OPEN"','ast -> trust','r6 -> trust','r9 -> trust']
 for i,v in enumerate(p["gain"]):graph += [f"g{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["condition"],52)),f"trust -> g{i}"]
 (ROOT/D2).write_text("\n".join(graph)+"\n")

def ascend(p):
 needs=[[v["obligationId"],v["kind"],v["subjectPath"],sha(ROOT/v["subjectPath"]),v["subjectScope"]] for v in p["need"].values()]
 v=next(v for v in p["dependency"].values() if v["prerequisite.obligationId"]=="MF-S");external=[[v["prerequisite.obligationId"],v["prerequisite.subjectPath"],sha(ROOT/v["prerequisite.subjectPath"]),v["prerequisite.subjectScope"]]]
 rows=[[v["key"],v["sourcePath"],sha(ROOT/v["sourcePath"]),v["needle"],v["proofScope"]] for v in p["route"]]
 queries=["candidate","blocked","checked","route","witnessok","bridgeok","externalok"];results={};engine=h.Engine()
 cases=["current","stale-digest","wrong-scope","missing-witness","wrong-witness","missing-parent","widened-tcb","missing-bridge","synthetic-all"]
 try:
  s=engine.open_sources((ROOT/RULES).read_text());assert s.run(queries=queries)["complete"]
  for case in cases:
   full=case!="current";rec=[[case,n,path,d,scope] for n,k,path,d,scope in needs if full or k in ["interleaving","induction"]]
   if case=="stale-digest":rec=[x[:3]+["stale"]+x[4:] if x[1]=="RO-X" else x for x in rec]
   if case=="wrong-scope":rec=[x[:4]+["whole-tool-proof"] if x[1]=="RO-X" else x for x in rec]
   wr=[r.copy() for i,r in enumerate(rows) if not(case=="missing-witness" and i==0)]
   if case=="wrong-witness":wr[0][2]="wrong-source-digest"
   br=[[case,v["key"],v["lemma"]] for v in p["bridge"] if (full or v["qualified"]) and not(case=="missing-bridge" and v["key"]=="typed-ast-meaning")]
   if case=="widened-tcb":br=[x[:2]+["stepMeaning"] if x[1]=="trusted-extraction" else x for x in br]
   s.replace(dict(scenario=[[case]],need=needs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source"],["environment-refinement","platform"]],receipt=rec,gate=[[case,v["key"],str(full).lower()] for v in p["gate"]],witnessneed=rows,witnessbinding=wr,bridge=[[v["key"],v["lemma"]] for v in p["bridge"]],bridgereceipt=br,externalneed=external,externalreceipt=[[case]+r for r in external if full and case!="missing-parent"]))
   result=s.run(queries=queries);assert result["complete"];results[case]=result["relations"]
  save(CACHE/"ascent-attempt-results.json",results)
  assert len(results["current"]["checked"])==3 and len(results["current"]["bridgeok"])==6 and len(results["current"]["witnessok"])==10
  assert len(results["synthetic-all"]["candidate"])==1 and all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-results.json",dict(results=results,syntheticNotRealEvidence=True,fullQuintToolProof=False,repositoryRegistered=False))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/"evidence/research/map-frame-abi/input.json";ph=sha(parent);old=json.loads(parent.read_text())["sourceBindings"]
 save(CACHE/"parent-drift.json",dict(parentSha256=ph,drift=[dict(path=f,old=d,current=sha(ROOT/f)) for f,d in old.items() if sha(ROOT/f)!=d],inheritedSourceQualified=False))
 p=project();views(p)
 import collections
 block=(ROOT/"vendor/gambit/lib/_std.c").read_text().split(",___DEF_LBL_INTRO(___H_map,",1)[1].split(",___DEF_LBL_INTRO",1)[0]
 actual=collections.Counter((kind,int(fs),int(link),int(mask,16)) for kind,fs,link,mask in re.findall(r"DEF_LBL_RET\(___H_map,___IFD\((___RET[INT]),(\d+),(\d+),(0x[0-9a-f]+)L\)\)",block))
 expected={(v["kind"],v["storedFs"],v["linkSlot"],v["mask"]):v["count"] for v in p["shape"]}
 assert dict(actual)==expected and sum(actual.values())==22 and "___OFD(" not in block
 save(CACHE/"stored-shape-observations.json",dict(rows=p["shape"],total=22,directOfd=0,nativeProvenance=False))
 witnesses=[]
 for v in p["route"]+p["user"]:
  text=(ROOT/v["sourcePath"]).read_text();assert v["needle"] in text,v
  witnesses.append(dict(key=v["key"],path=v["sourcePath"],sha256=sha(ROOT/v["sourcePath"]),line=text[:text.index(v["needle"])].count("\n")+1))
 save(CACHE/"source-witnesses.json",witnesses)
 run("typecheck",["quint","typecheck",PARENTQ,"--out",str(CACHE/"typed-ir.json")])
 projector=load("expression_projector",PROJECTOR);ir=json.loads((CACHE/"typed-ir.json").read_text());ast,meta=projector.generate(ir,sha(ROOT/PARENTQ));(ROOT/AST).write_text(ast);save(CACHE/"expression-projection.json",dict(**meta,sourceSha256=sha(ROOT/PARENTQ),irSha256=sha(CACHE/"typed-ir.json"),astSha256=sha(ROOT/AST),extractorSha256=sha(ROOT/PROJECTOR)))
 negatives=[]
 for case in ["unknown-op","dynamic-field","unknown-field","duplicate-update","wrong-int-type","extra-state","wrong-initial"]:
  bad=copy.deepcopy(ir);ds={d.get("name"):d for d in bad["modules"][0]["declarations"]}
  if case=="unknown-op":ds["safe"]["expr"]["opcode"]="unsupported"
  if case=="dynamic-field":ds["safe"]["expr"]["args"][0]["args"][0]["args"][1]={"kind":"name","name":"dynamic"}
  if case=="unknown-field":ds["safe"]["expr"]["args"][0]["args"][0]["args"][1]["value"]="notAField"
  if case=="duplicate-update":
   rhs=ds["capture"]["expr"]["args"][-1]["args"][1];ds["capture"]["expr"]["args"][-1]["args"][1]={"kind":"app","opcode":"with","args":[rhs,{"kind":"str","value":"shots"},{"kind":"int","value":2}]}
  if case=="wrong-int-type":ds["safe"]["expr"]["args"][0]["args"][1]={"kind":"bool","value":True}
  if case=="extra-state":bad["modules"][0]["declarations"].append({"kind":"var","name":"extra","id":100000})
  if case=="wrong-initial":ds["init"]["expr"]["args"][1]["name"]="s"
  try:projector.generate(bad,sha(ROOT/PARENTQ))
  except (AssertionError,KeyError):negatives.append(case)
 assert len(negatives)==7;save(CACHE/"projection-refusals.json",dict(rejected=negatives,notTranslatorProof=True))
 for name,path in [("MapFrameAbi",PARENTL),("RetiOfdSemantics",LEAN),("MapExpressionAst",AST)]:
  src=CACHE/(name+".lean");src.write_bytes((ROOT/path).read_bytes());args=["lean",f"--root={CACHE}","-o",str(CACHE/(name+".olean")),str(src)]
  if name!="MapFrameAbi":args=["env",f"LEAN_PATH={CACHE}"]+args
  run(name,args)
 mutant=[]
 for line in ast.splitlines():mutant.append(line.replace('(.lt (.get .shots) (.lit (3)))','(.le (.get .shots) (.lit (3)))') if line.startswith('def a_resume ') else line)
 assert "\n".join(mutant)!=ast.strip();(CACHE/"MutatedAst.lean").write_text("\n".join(mutant)+"\n")
 try:run("negative-guard-certificate",["env",f"LEAN_PATH={CACHE}","lean",f"--root={CACHE}",str(CACHE/"MutatedAst.lean")])
 except RuntimeError:assert "error:" in (CACHE/"negative-guard-certificate.stdout").read_text()
 else:raise AssertionError("wrong AST unexpectedly certified")
 alllean=(ROOT/LEAN).read_text()+ast
 assert "sorry" not in alllean and "axiom " not in alllean
 for v in p["bridge"]:
  if v["qualified"]:assert "theorem "+v["lemma"]+" " in alllean,v
 tests=run("quint-tests",["quint","test",QNT,"--match","Test$"]);assert tests.count("ok ")==9 and tests.count("ControlTest passed")==4
 run("quint-samples",["quint","run",QNT,"--init","init","--invariant","safe","--max-samples","300","--max-steps","160","--seed","31","--verbosity","1"])
 ascend(p);run("d2-svg",["d2",D2,D2[:-3]+".svg"]);run("d2-png",["d2",D2,str(CACHE/"diagram.png")])
 save(OUT/"checks.json",dict(status="pending",nativeAdmitted=False))
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text().replace("dev/architecture/toolchain/iter-compiler-service-design.org",DESIGN).replace("dev/architecture/toolchain/iter-compiler-service-matrix.org",MATRIX).replace("dev/architecture/toolchain/index.org",BASE+"index.org");(CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 files={v["sourcePath"] for v in p["route"]+p["user"]}|{MODEL,DESIGN,MATRIX,D2,D2[:-3]+".svg",RULES,QNT,PARENTQ,PARENTL,LEAN,AST,HELPER,PROJECTOR,"dev/modeling/tools/"+STEM+"-study.py",BASE+"index.org","dev/architecture/runtime/models/sysml/composition.sysml",BASE+"models/sysml/map-frame-abi.sysml"}
 installed=Path("/opt/homebrew/Cellar/quint/0.33.0/libexec/lib/node_modules/@informalsystems/quint/dist/src")
 for f in ["cli.js","runtime/impl/builtins.js","runtime/impl/builder.js"]:files.add(str(installed/f))
 for v in witnesses:assert sha(ROOT/v["path"])==v["sha256"]
 assert sha(parent)==ph
 scope=json.loads((CACHE/"sysml-input-scope.json").read_text())
 for f,d in scope["files"].items():assert sha(ROOT/f)==d,f
 checks=dict(status="conditional-local-models-pass",wholeDevSysmlInputs=len(scope["files"]),sourceRoutes=10,retirementUserClasses=8,storedShapes=9,directMapOfd=0,storedReti=13,storedRetn=9,selectedAstActions=12,astTheorems=len(re.findall(r"^theorem ",ast,re.M)),interpreterFrameTheorems=len(re.findall(r"^theorem ",(ROOT/LEAN).read_text(),re.M)),projectionRefusals=7,negativeLeanCertificates=1,qntRetirementHistories=9,negativeQntControls=4,sampledRuns=300,maxSteps=160,ascentScenarios=9,qualifiedBridgeScopes=6,openLargerScopes=2,openGates=7,parserExtractorVerified=False,fullQuintToolVerified=False,sourceSimulation=False,c11Refinement=False,nativeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False,hostRegistration="inherited unresolved; not retried")
 save(CACHE/"checks.json",checks);save(CACHE/"input.json",dict(head=run("head",["git","rev-parse","HEAD"]).strip(),branch=run("branch",["git","branch","--show-current"]).strip(),sourceBindings={f:sha(ROOT/f) for f in sorted(files)},parentInputSha256=ph,parentFrozen=True,inheritedSourceQualified=False,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in {".stdout",".stderr"}}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in {".json",".el",".lean"}:(OUT/f.name).write_bytes(f.read_bytes())
 save(OUT/"artifacts.json",{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!="artifacts.json"});print(json.dumps(checks))
if __name__=="__main__":main()
