#!/usr/bin/env python3
"""Design/model orchestration only; native SysML is canonical. No native runtime tests."""
import hashlib, json, re, subprocess, textwrap
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
STEM="decrement-restore-closure"; PACKAGE="DecrementRestoreClosure"
CACHE=ROOT/".cache/tasks"/STEM; OUT=ROOT/"evidence/research"/STEM
BASE="dev/architecture/toolchain/"
MODEL=BASE+"models/sysml/"+STEM+".sysml"
DESIGN=BASE+STEM+"-design.org"; MATRIX=BASE+STEM+"-matrix.org"
DIAGRAM=BASE+"diagrams/"+STEM+".d2"
QNT="models/build/decrement_restore_closure.qnt"; LEAN="models/build/DecrementRestoreClosure.lean"
RULES="dev/modeling/ascent/"+STEM+".rules.scm"
GROUPS=[("contract",8,"key anchor actionName lemmaName guardName duty status"),("gain",4,"key avoided added condition"),("gate",7,"key qualified duty"),("profile",1,"key driver header compiler declaredMode macroParity sourceMatch status")]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p,v):Path(p).write_text(json.dumps(v,indent=2,ensure_ascii=False)+"\n")
def run(name,args):
 p=subprocess.run(args,cwd=ROOT,text=True,capture_output=True,timeout=60)
 (CACHE/(name+".stdout")).write_text(p.stdout);(CACHE/(name+".stderr")).write_text(p.stderr)
 save(CACHE/(name+".command.json"),args)
 if p.returncode:
  f=dict(argv=args,exit=p.returncode,stdout=p.stdout,stderr=p.stderr)
  save(CACHE/(name+".failure-"+hashlib.sha256(json.dumps(f,sort_keys=True).encode()).hexdigest()[:12]+".json"),f)
  raise RuntimeError(name+" failed; cache diagnostics retained")
 return p.stdout

def project():
 keys=[]
 for group,count,schema in GROUPS:
  keys += [(group,str(i),f,f"{PACKAGE}::{group}{i}.{f}") for i in range(count) for f in schema.split()]
 for i in range(10):
  keys += [("edge",str(i),f,f"{PACKAGE}::edge{i}.{f}") for f in ["dependent.key","prerequisite.key","reason"]]
 for slot in ["history","induction","source","platform"]:
  keys += [("need",slot,f,f"{PACKAGE}::{slot}.{f}") for f in ["obligationId","kind","subjectPath","subjectScope","owner.componentId"]]
 for i in range(4):
  keys += [("dependency",str(i),f,f"{PACKAGE}::dependency{i}.{f}") for f in ["dependent.obligationId","prerequisite.obligationId"]]
 args=["sysml","-strict","-no-record-cache","-validate","-json"]
 for *_,expr in keys:args += ["-e",expr]
 native=json.loads(run("sysml",args+["dev"]))
 assert native["exit"]==0 and not native.get("errors") and not any(d["severity"]=="error" for d in native.get("diagnostics",[]))
 vals=[json.loads(line[4:]) for line in native["output"] if line.startswith("  = ")]
 assert len(vals)==len(keys)
 p={}
 for (g,i,f,_),v in zip(keys,vals,strict=True):p.setdefault(g,{}).setdefault(i,{})[f]=v
 for g,_,_ in GROUPS:p[g]=list(p[g].values())
 save(CACHE/"projection.json",p);save(CACHE/"native-queries.json",keys)
 return p

def views(p):
 lines=["#+TITLE: Decrement and Restoration — Closure and Benefit Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: decrement-restore-closure-matrix",":AUTHORITY: DecrementRestoreClosure",":STATUS: conditional-models-source-open",":END:","","Derived by native SysML queries. Benefits are conditional work/capacity bounds, not timings."]
 for group,_,schema in GROUPS:
  fields=schema.split();lines += ["","** "+group.capitalize(),"","| "+" | ".join(fields)+" |","|"+"+".join("---" for _ in fields)+"|"]
  lines += ["| "+" | ".join(str(v[f]) for f in fields)+" |" for v in p[group]]
 lines += ["","** Shared-contract dependencies","","| dependent | prerequisite | obligation |","|---+---+---|"]
 lines += ["| "+" | ".join(v[f] for f in ["dependent.key","prerequisite.key","reason"])+" |" for v in p["edge"].values()]
 (ROOT/MATRIX).write_text("\n".join(lines)+"\n")
 graph=["direction: down"]
 for v in p["contract"]:
  graph.append(json.dumps(v["key"])+": "+json.dumps(v["key"]+"\n"+textwrap.fill(v["duty"],52)))
 for edge in p["edge"].values():
  graph.append(json.dumps(edge["prerequisite.key"])+" -> "+json.dumps(edge["dependent.key"]))
 graph += ['proof: "SysML -> ASCENT -> QNT / Lean; source + platform OPEN"','"storage-commit" -> proof']
 for i,v in enumerate(p["gain"]):graph += [f"gain{i}: "+json.dumps(v["key"]+"\n"+textwrap.fill(v["condition"],55)),f"proof -> gain{i}"]
 (ROOT/DIAGRAM).write_text("\n".join(graph)+"\n")

def ascend(p,prior):
 needs=[[v["obligationId"],v["kind"],v["subjectPath"],sha(ROOT/v["subjectPath"]),v["subjectScope"]] for v in p["need"].values()]
 deps=[[v["dependent.obligationId"],v["prerequisite.obligationId"]] for v in p["dependency"].values()]
 contracts=p["contract"];queries=["checked","missing","route","blocked","candidate","aligned","prioraligned","componentmapped","edgealigned","guardaligned","profilechecked"]
 engine=Engine();results={}
 try:
  session=engine.open_sources((ROOT/RULES).read_text())
  assert session.run(queries=queries)["complete"]
  for case in ["current","stale-subject","wrong-scope","missing-step","missing-component","missing-prior","parent-open","missing-guard","wrong-guard","unmatched-profile","synthetic-all"]:
   full=case not in ["current","stale-subject","wrong-scope"]
   receipts=[[case,n,path,h,scope] for n,k,path,h,scope in needs if full or k in ["interleaving","induction"]]
   if case=="stale-subject":receipts=[x[:3]+["stale"]+x[4:] if x[1]=="DRC-H" else x for x in receipts]
   if case=="wrong-scope":receipts=[x[:4]+["wrong"] if x[1]=="DRC-I" else x for x in receipts]
   steps=[[v["actionName"],v["lemmaName"]] for v in contracts if not(case=="missing-step" and v["key"]=="derived-credit")]
   components=[[v["key"],v["anchor"],v["actionName"],v["lemmaName"]] for v in contracts]
   priorrows=[[v["key"],v["path"],v["sha256"],v["invariant"],v["action"],v["lemma"]] for v in prior]
   session.replace(dict(scenario=[[case]],need=needs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source-audit"],["environment-refinement","platform"]],receipt=receipts,dependency=deps,
    external=[[case,"GER-S",str(full and case!="parent-open").lower()]],gate=[[case,v["key"],str(full).lower()] for v in p["gate"]],
    anchor=[[v["key"],v["anchor"]] for v in contracts],binding=[[v["key"],v["actionName"],v["lemmaName"],v["anchor"]] for v in contracts],modelstep=steps,
    component=components,componentbinding=[v for v in components if not(case=="missing-component" and v[0]=="storage-commit")],
    componentedge=[[v["dependent.key"],v["prerequisite.key"],v["reason"]] for v in p["edge"].values()],prior=priorrows,priorbinding=[v for v in priorrows if not(case=="missing-prior" and v[0]=="old-roster")],
    guardneed=[[v["key"],v["actionName"],v["guardName"],v["lemmaName"]] for v in contracts],
    profilewitness=[[case,v["key"],sha(ROOT/v["driver"]),sha(ROOT/v["header"]),str(full and case!="unmatched-profile").lower()] for v in p["profile"]],
    guardreceipt=[[v["actionName"],("wrong" if case=="wrong-guard" and i==0 else v["guardName"]),v["lemmaName"]] for i,v in enumerate(contracts) if not(case=="missing-guard" and i==0)]))
   result=session.run(queries=queries);assert result["complete"];results[case]=result["relations"]
  assert len(results["current"]["checked"])==2
  assert len(results["current"]["aligned"])==8 and len(results["current"]["componentmapped"])==8
  assert len(results["current"]["prioraligned"])==4
  assert len(results["current"]["edgealigned"])==10
  assert len(results["missing-component"]["edgealigned"])<10
  assert len(results["missing-step"]["aligned"])==7
  assert len(results["missing-component"]["componentmapped"])==7
  assert len(results["missing-prior"]["prioraligned"])==3
  for k in ["stale-subject","wrong-scope"]:assert len(results[k]["checked"])==1
  assert len(results["current"]["guardaligned"])==8
  assert len(results["missing-guard"]["guardaligned"])==7 and len(results["wrong-guard"]["guardaligned"])==7
  assert not results["current"]["profilechecked"] and not results["unmatched-profile"]["profilechecked"]
  assert len(results["synthetic-all"]["profilechecked"])==1
  assert len(results["synthetic-all"]["candidate"])==1
  assert all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-model-results.json",dict(results=results,repositoryRegistered=False,hostAttested=False,syntheticNotRealReceipt=True))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/"evidence/research/gate-empty-root-materialization/input.json"
 parenthash=sha(parent);bindings=json.loads(parent.read_text())["sourceBindings"].copy()
 assert all(sha(ROOT/path)==h for path,h in bindings.items()),"Frozen parent drift"
 p=project();views(p)
 q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text()
 assert "sorry" not in l and "axiom " not in l
 guardrows=[]
 for v in p["contract"]:
  pattern=r"action\s+"+v["actionName"]+r"(?:\([^\n]*?\))?=all\{(.*?)(?=\n action|\n run|\n})"
  body=re.search(pattern,q,re.S)
  assert body and v["guardName"] in body.group(1).split("s'=",1)[0],v
  assert "theorem "+v["lemmaName"]+" " in l
  guardrows.append(dict(key=v["key"],action=v["actionName"],guard=v["guardName"],lemma=v["lemmaName"],qualification="syntactic pre-update guard and theorem declaration; implication/source simulation not proved"))
 save(CACHE/"guard-alignment.json",guardrows)
 prior=[]
 for key,path,inv,action,lemma in [
  ("old-roster","models/build/gate_empty_root_materialization.qnt","safe","decrementClaim","handoffReleaseCovered"),
  ("foreign-closure","models/build/foreign_cleanup_closure.qnt","safe","unwindGuard","deadMarkerDeniesC"),
  ("still-authority","models/gambit/still_authority_handoff.qnt","safe","invokeK","captureDoesNotPinOldProcessor"),
  ("work-closure","models/gambit/gc_work_closure.qnt","terminationSafe","retireVm","captureBlocksVmRetirement")]:
  assert re.search(r"(?:val|def)\s+"+inv+r"\s*=",(ROOT/path).read_text())
  prior.append(dict(key=key,path=path,invariant=inv,action=action,lemma=lemma,sha256=sha(ROOT/path),productSimulationProved=False,rerun=False))
 save(CACHE/"prior-model-alignment.json",prior)
 sources=["vendor/gambit/lib/"+f for f in ["setup.c","_kernel.scm","_kernel.c","c_intf.c","_thread.scm"]]+["vendor/gambit/include/gambit.h.in","vendor/gambit/configure.ac"]
 setup=(ROOT/sources[0]).read_text();kernel=(ROOT/sources[1]).read_text();cint=(ROOT/sources[3]).read_text();header=(ROOT/sources[5]).read_text()
 call=setup.split("___EXP_FUNC(___SCMOBJ,___call)",1)[1].split("___EXP_FUNC(___SCMOBJ,___run)",1)[0]
 assert "stack_marker != ___ps->fp[___FRAME_SPACE(2)-2]" in call
 assert "___ps->fp += ___FRAME_SPACE(2);" in call and "___PSR0 = ___ps->fp[-1];" in call
 assert "___ps->catcher = ___old_catcher;" in header and "___ps->longjmp_err" in header
 assert "___VECTORELEM(marker, 0) = ___FAL;" in cint
 assert "TODO: proc_or_false may have been GC'd" in cint
 ret=kernel.split("This is the return to C handler.",1)[1].split("end-of-code",1)[0]
 assert ret.index("WRONG_PROCESSOR")<ret.index("MULTIPLE_RETURN")<ret.index("___throw_error")
 assert "#define ___THREAD_RESTORE" in header and "___CONTINUATION_DENV_FIELD(cont)" in header
 profile=json.loads((CACHE/"darwin-declared-profile.json").read_text())
 nativeProfile=p["profile"][0]
 assert nativeProfile["driver"]==profile["driver"] and nativeProfile["header"]==profile["header"] and not nativeProfile["sourceMatch"]
 assert sha(profile["driver"])==profile["driverSha256"] and sha(profile["header"])==profile["headerSha256"]
 installed=(Path(profile["driver"])).read_text();installedHeader=Path(profile["header"]).read_text()
 assert 'C_COMPILER="/opt/homebrew/bin/gcc-16"' in installed and "-D___TRUST_C_TCO" in installed
 assert "#define ___SINGLE_THREADED_VMS" in installedHeader and "#define ___VERSION 409008" in installedHeader
 spans=[("r1-local-direct","#define ___PSR1 ","#if ___NB_ARG_REGS == 1"),("host-exit","#define ___END_COD ","#define ___CALL_LABEL_HOST"),("catcher","#define ___BEGIN_TRY ","#define ___ON_THROW_AUX"),("thread-restore","#define ___THREAD_RESTORE ","#define ___JUMP_THREAD_RESTORE2"),("continuation-capture","#define ___CONTINUATION_CAPTURE ","#define ___JUMP_CONTINUATION_CAPTURE1"),("self-transfer","#define ___JUMPNOTSAFE","#define ___JUMPGENSAFE")]
 parity=[]
 for key,start,end in spans:
  x=header[header.index(start):header.index(end,header.index(start))];y=installedHeader[installedHeader.index(start):installedHeader.index(end,installedHeader.index(start))]
  assert x==y,key
  parity.append(dict(key=key,equal=True,sourceSha256=hashlib.sha256(x.encode()).hexdigest(),installedSha256=hashlib.sha256(y.encode()).hexdigest(),sourceLines=[header[:header.index(start)].count("\n")+1,header[:header.index(end,header.index(start))].count("\n")+1],installedLines=[installedHeader[:installedHeader.index(start)].count("\n")+1,installedHeader[:installedHeader.index(end,installedHeader.index(start))].count("\n")+1]))
 save(CACHE/"installed-macro-parity.json",dict(spans=parity,qualification="literal macros only; not selected branch, effective argv, masks or object identity"))
 external=[profile["driver"],profile["header"],"../../gerbil/gambit_runtime.bzl","../../gerbil/host_system.bzl","../../gerbil/repository.bzl","../../patches/gerbil-v19-darwin/0004-gambit-darwin-gcc-macro-expansion.patch"]
 externalHashes={path:sha(ROOT/path) for path in external}
 save(CACHE/"source-facts.json",dict(callTailUsesPstate=True,catchRestoreUsesPstate=True,normalMarkerInvalidation=True,allAbnormalMarkerCleanup=False,wrongProcessorCheckBeforeMarker=True,continuationUsesCurrentContext=True,staticSdkDriverAndHeaderPinned=True,effectiveArgvObserved=False,matchedSmpObject=False,c11GraphProved=False))
 raw=run("source-census",["rg","--json",r"catcher|longjmp_err|kill_sfun_stack_marker|make_sfun_stack_marker|CONTINUATION_CAPTURE|CONTINUATION_GRAFT|THREAD_RESTORE|CALL_LABEL_HOST|END_SFUN|TRUST_C_TCO|SUPPORT_MULTIPLE_C_COMPILERS",*sources])
 matches=[json.loads(x)["data"] for x in raw.splitlines() if json.loads(x)["type"]=="match"]
 save(CACHE/"source-census.json",dict(matches=matches,scope=sources,qualification="bounded syntactic witnesses; not complete alias/embedding/configuration closure"))
 tests=run("quint-tests",["quint","test",QNT,"--match","Test$"])
 assert tests.count("ok ")==14 and tests.count("ControlTest passed")==6
 run("quint-samples",["quint","run",QNT,"--init","init","--invariant","safe","--max-samples","200","--max-steps","120","--seed","17","--verbosity","1"])
 run("lean",["lean",LEAN]);ascend(p,prior)
 run("d2-svg",["d2",DIAGRAM,DIAGRAM[:-3]+".svg"]);run("d2-png",["d2",DIAGRAM,str(CACHE/"diagram.png")])
 save(OUT/"checks.json",dict(status="pending-local-checks",runtimeAdmitted=False))
 save(OUT/"input.json",dict(status="pending-receipt-finalization",parentInputSha256=parenthash))
 for name in ["prior-model-alignment.json","ascent-model-results.json","darwin-declared-profile.json","installed-macro-parity.json"]:(OUT/name).write_bytes((CACHE/name).read_bytes())
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text().replace("iter-compiler-service-design.org",STEM+"-design.org").replace("iter-compiler-service-matrix.org",STEM+"-matrix.org")
 (CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 for path in sources+[MODEL,DESIGN,MATRIX,DIAGRAM,DIAGRAM[:-3]+".svg",QNT,LEAN,RULES,"dev/modeling/tools/"+STEM+"-study.py"]+[v["path"] for v in prior]:bindings[path]=sha(ROOT/path)
 assert all(sha(ROOT/path)==h for path,h in externalHashes.items())
 bindings.update(externalHashes)
 assert sha(parent)==parenthash
 save(CACHE/"input.json",dict(sourceBindings=bindings,parentInputSha256=parenthash,parentFrozen=True,head=run("head",["git","rev-parse","HEAD"]).strip(),dirtySourceIdentity="per-file SHA256",logs={str(p.relative_to(ROOT)):sha(p) for p in CACHE.iterdir() if p.suffix in {".stdout",".stderr"}}))
 checks=dict(status="conditional-local-models-pass",qntHistories=14,negativeControls=6,sampledRuns=200,maxSteps=120,leanTheorems=len(re.findall(r"^theorem ",l,re.M)),ascentCases=11,componentBindings=8,guardBindings=8,contractDependencies=10,priorBindings=4,gatesOpen=7,staticDarwinProfile=True,matchedMacroSpans=6,effectiveArgvObserved=False,matchedSmpObject=False,sourceSimulation="open",cMemoryOrder="open",hostRegistration="inherited unresolved; not retried",runtimeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/"checks.json",checks)
 for path in CACHE.iterdir():
  if path.is_file() and path.suffix in {".json",".el"}:(OUT/path.name).write_bytes(path.read_bytes())
 save(OUT/"artifacts.json",{str(p.relative_to(ROOT)):sha(p) for p in OUT.iterdir() if p.is_file() and p.name!="artifacts.json"})
 print(json.dumps(checks))
if __name__=="__main__":main()
