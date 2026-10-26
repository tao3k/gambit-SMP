#!/usr/bin/env python3
"""Research/formal orchestration only. Native SysML remains canonical metadata."""
import importlib.util,json,re,hashlib,subprocess,textwrap
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
STEM="map-frame-abi";PKG="GambitMapFrameAbi";BASE="dev/refactoring/modern-c/"
CACHE=ROOT/".cache/tasks"/STEM;OUT=ROOT/"evidence/research"/STEM
MODEL=BASE+"models/sysml/"+STEM+".sysml";DESIGN=BASE+STEM+"-design.org";MATRIX=BASE+STEM+"-matrix.org"
QNT=BASE+"models/quint/map_frame_abi.qnt";LEAN=BASE+"models/lean/MapFrameAbi.lean"
D2=BASE+"diagrams/"+STEM+".d2";RULES="dev/modeling/ascent/"+STEM+".rules.scm"
HELPER="dev/modeling/tools/advantage-architecture-study.py"
spec=importlib.util.spec_from_file_location("architecture_research_helpers",ROOT/HELPER)
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
h.CACHE=CACHE;h.OUT=OUT
run=h.run;sha=h.sha;save=h.save
GROUPS=[("owner",9,"moduleId ownerPath owns"),("source",11,"key sourcePath sourceNeedle consumer obligation actionName guardName lemmaName boundary"),("witness",2,"key sourcePath labelIndex storedFs linkSlot mask liveSlots useSite"),("impact",5,"key trigger semantic native runtime retirement"),("refine",8,"key qualified lemma premise gap"),("gain",4,"key avoided added condition"),("gate",7,"key qualified duty"),("field",20,"qntField leanField representation"),("event",11,"actionName guardName lemmaName")]
def project():
 keys=[]
 for group,count,schema in GROUPS:
  keys += [(group,str(i),f,f"{PKG}::{group}{i}.{f}") for i in range(count) for f in schema.split()]
 for slot in ["history","induction","source","platform"]:
  keys += [("need",slot,f,f"{PKG}::{slot}.{f}") for f in ["obligationId","kind","subjectPath","subjectScope"]]
 for i in range(4):keys += [("dependency",str(i),f,f"{PKG}::dependency{i}.{f}") for f in ["dependent.obligationId","prerequisite.obligationId","prerequisite.subjectPath","prerequisite.subjectScope"]]
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 files=sorted(run("sysml-files",["rg","--files","dev","-g","*.sysml","-g","*.kerml"]).splitlines())
 save(CACHE/"sysml-input-scope.json",dict(files={f:sha(ROOT/f) for f in files},excluded={}))
 raw=json.loads(run("sysml",args+["dev"]));assert raw["exit"]==0 and not raw.get("errors")
 vals=[json.loads(x[4:]) for x in raw["output"] if x.startswith("  = ")];assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);save(CACHE/"native-queries.json",keys);return p

def views(p):
 lines=["#+TITLE: Real map FrameSpec, ABI and Refinement Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+LANGUAGE: en","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: map-frame-abi-matrix",":AUTHORITY: GambitMapFrameAbi",":STATUS: stored-source; mirror-laws-checked; QNT-encoding-and-source-open",":END:"]
 for g,_,schema in GROUPS:
  fields=schema.split();lines += ["","** "+g.capitalize(),"","| "+" | ".join(fields)+" |","|"+"+".join("---" for _ in fields)+"|"]
  lines += ["| "+" | ".join(str(v[f]) for f in fields)+" |" for v in p[g]]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 graph=['direction: down','title: "map FrameSpec: source consumers, old-cohort lifetime and build impact"']
 for i,v in enumerate(p["source"]):graph += [f"s{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["obligation"],55))]
 for a,b in [(0,1),(1,2),(2,3),(3,4),(3,5),(3,7),(5,6),(6,4),(7,10),(2,8),(8,7),(9,4),(9,5)]:graph.append(f"s{a} -> s{b}")
 graph += ['proof: "SysML -> ASCENT -> QNT / Lean\\nFlat/nested mirror simulation: proved\\nQNT encoding + source + C11/native: OPEN"','s4 -> proof','s7 -> proof','s8 -> proof']
 for i,v in enumerate(p["impact"]):graph += [f"abi{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["retirement"],48)),f"s8 -> abi{i}"]
 (ROOT/D2).write_text("\n".join(graph)+"\n")

def ascend(p,witnesses):
 needs=[[v["obligationId"],v["kind"],v["subjectPath"],sha(ROOT/v["subjectPath"]),v["subjectScope"]] for v in p["need"].values()]
 ext=[v for v in p["dependency"].values() if v["prerequisite.obligationId"]=="AA-S"][0]
 parent=[[ext["prerequisite.obligationId"],ext["prerequisite.subjectPath"],sha(ROOT/ext["prerequisite.subjectPath"]),ext["prerequisite.subjectScope"]]]
 rows=[[v["key"],v["sourcePath"],sha(ROOT/v["sourcePath"]),v["sourceNeedle"],v["actionName"],v["guardName"],v["lemmaName"]] for v in p["source"]]
 steps=[[v["actionName"],v["guardName"],v["lemmaName"]] for v in p["event"]]
 refs=[[v["key"],v["lemma"]] for v in p["refine"]]
 cases=["current","stale-digest","wrong-scope","missing-source","wrong-guard","missing-parent","widened-mirror","missing-refinement","synthetic-all"]
 engine=h.Engine();results={}
 try:
  session=engine.open_sources((ROOT/RULES).read_text());queries=["route","checked","blocked","candidate","sourceok","refineok","externalok"]
  assert session.run(queries=queries)["complete"]
  for case in cases:
   full=case!="current"
   receipts=[[case,n,path,digest,scope] for n,k,path,digest,scope in needs if full or k in ["interleaving","induction"]]
   if case=="stale-digest":receipts=[r[:3]+["stale"]+r[4:] if r[1]=="MF-H" else r for r in receipts]
   if case=="wrong-scope":receipts=[r[:4]+["wrong-scope"] if r[1]=="MF-I" else r for r in receipts]
   bindings=[v.copy() for i,v in enumerate(rows) if not(case=="missing-source" and i==0)]
   if case=="wrong-guard":bindings[0][5]="wrong-guard"
   rr=[[case,v["key"],v["lemma"]] for v in p["refine"] if (full or v["qualified"]) and not(case=="missing-refinement" and v["key"]=="steps")]
   if case=="widened-mirror":rr=[r[:2]+["forwardSimulation"] if r[1]=="qnt-encoding" else r for r in rr]
   session.replace(dict(scenario=[[case]],need=needs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source"],["environment-refinement","platform"]],receipt=receipts,gate=[[case,v["key"],str(full).lower()] for v in p["gate"]],sourceneed=rows,sourcebinding=bindings,modelstep=steps,refinement=refs,refined=rr,externalneed=parent,externalreceipt=[[case]+v for v in parent if full and case!="missing-parent"]))
   result=session.run(queries=queries);assert result["complete"];results[case]=result["relations"]
  save(CACHE/"ascent-attempt-results.json",results)
  assert len(results["current"]["checked"])==2 and len(results["current"]["sourceok"])==11
  assert len(results["current"]["refineok"])==6 and len(results["widened-mirror"]["refineok"])==7
  assert len(results["synthetic-all"]["candidate"])==1
  assert all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-results.json",dict(results=results,syntheticIsNotRealReceipt=True,mirrorProofIsNotQntEncoding=True,repositoryRegistered=False))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/"evidence/research/advantage-architecture/input.json";parenthash=sha(parent)
 old=json.loads(parent.read_text())["sourceBindings"]
 drift=[dict(path=f,oldSha256=d,currentSha256=sha(ROOT/f)) for f,d in old.items() if sha(ROOT/f)!=d]
 save(CACHE/"parent-drift.json",dict(drift=drift,parentFrozen=True,inheritedSourceQualified=False))
 p=project();views(p);q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text()
 assert "sorry" not in l and "axiom " not in l
 witnesses=[]
 for v in p["source"]:
  text=(ROOT/v["sourcePath"]).read_text();assert v["sourceNeedle"] in text,v["key"]
  witnesses.append(dict(key=v["key"],path=v["sourcePath"],sha256=sha(ROOT/v["sourcePath"]),needle=v["sourceNeedle"],line=text[:text.index(v["sourceNeedle"])].count("\n")+1))
 for v in p["event"]:
  match=re.search(r"action "+v["actionName"]+r"=all\{(.*?)(?=\n action|\n run|\n})",q,re.S)
  assert match and v["guardName"] in match.group(1).split("s'=",1)[0],v
  assert "theorem "+v["lemmaName"]+" " in l
 for v in p["refine"]:
  if v["qualified"]:assert "theorem "+v["lemma"]+" " in l
 save(CACHE/"source-witnesses.json",witnesses)
 c=(ROOT/"vendor/gambit/lib/_std.c").read_text();block=c.split(',___DEF_LBL_INTRO(___H_map,',1)[1].split(',___DEF_LBL_INTRO',1)[0]
 rows=re.findall(r'DEF_LBL_RET\(___H_map,___IFD\((___RET[INT]),(\d+),(\d+),(0x[0-9a-f]+)L\)\)',block)
 assert len(rows)==22
 for v in p["witness"]:
  kind,fs,link,mask=rows[v["labelIndex"]-1]
  assert kind=="___RETN" and int(fs)==v["storedFs"] and int(link)==v["linkSlot"] and int(mask,16)==v["mask"],v
 save(CACHE/"stored-map-descriptors.json",dict(rows=rows,normalWitnesses=p["witness"],currentGeneratedProvenance=False,matchedNativeObject=False))
 tests=run("quint-tests",["quint","test",QNT,"--match","Test$"]);assert tests.count("ok ")==12 and tests.count("ControlTest passed")==6
 run("quint-samples",["quint","run",QNT,"--init","init","--invariant","safe","--max-samples","300","--max-steps","160","--seed","29","--verbosity","1"])
 run("lean",["lean",LEAN]);ascend(p,witnesses)
 run("d2-svg",["d2",D2,D2[:-3]+".svg"]);run("d2-png",["d2",D2,str(CACHE/"diagram.png")])
 save(OUT/"checks.json",dict(status="pending",nativeAdmitted=False))
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text().replace("dev/architecture/toolchain/iter-compiler-service-design.org",DESIGN).replace("dev/architecture/toolchain/iter-compiler-service-matrix.org",MATRIX).replace("dev/architecture/toolchain/index.org",BASE+"index.org")
 (CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 files={v["sourcePath"] for v in p["source"]}|{MODEL,DESIGN,MATRIX,D2,D2[:-3]+".svg",QNT,LEAN,RULES,HELPER,"dev/modeling/tools/"+STEM+"-study.py",BASE+"index.org",BASE+"advantage-architecture-design.org",BASE+"models/sysml/advantage-architecture.sysml","dev/architecture/runtime/models/sysml/composition.sysml","vendor/gambit/lib/gambit/list/list.scm","vendor/gambit/gsc/_front.scm","vendor/gambit/gsc/_back.scm","vendor/gambit/lib/_kernel.scm"}
 assert sha(parent)==parenthash
 for v in witnesses:assert sha(ROOT/v["path"])==v["sha256"]
 scope=json.loads((CACHE/"sysml-input-scope.json").read_text())
 for f,d in scope["files"].items():assert sha(ROOT/f)==d,f
 checks=dict(status="conditional-local-models-pass",wholeDevSysmlInputs=len(scope["files"]),excluded=0,sourceLinks=11,storedReturnDescriptors=22,normalWitnesses=2,stateFieldMappings=20,namedActions=11,leanEventCases=12,qntHistories=12,negativeControls=6,sampledRuns=300,maxSteps=160,leanTheorems=len(re.findall(r"^theorem ",l,re.M)),ascentScenarios=9,mirrorRefinementScopes=6,openLargerRefinementScopes=2,openSourcePlatformGates=7,fullQntLeanEncoding=False,sourceSimulation=False,c11Refinement=False,parentSourceQualified=False,nativeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False,hostRegistration="inherited unresolved; not retried")
 save(CACHE/"checks.json",checks)
 save(CACHE/"input.json",dict(head=run("head",["git","rev-parse","HEAD"]).strip(),branch=run("branch",["git","branch","--show-current"]).strip(),sourceBindings={f:sha(ROOT/f) for f in sorted(files)},parentInput=str(parent.relative_to(ROOT)),parentInputSha256=parenthash,parentFrozen=True,parentDrift=drift,inheritedSourceQualified=False,logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in {".stdout",".stderr"}}))
 for f in CACHE.iterdir():
  if f.is_file() and f.suffix in {".json",".el"}:(OUT/f.name).write_bytes(f.read_bytes())
 save(OUT/"artifacts.json",{str(f.relative_to(ROOT)):sha(f) for f in OUT.iterdir() if f.is_file() and f.name!="artifacts.json"})
 print(json.dumps(checks))
if __name__=="__main__":main()
