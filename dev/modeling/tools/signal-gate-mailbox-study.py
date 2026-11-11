#!/usr/bin/env python3
"""Design/model orchestration only; native SysML is canonical. No native runtime tests."""
import hashlib, json, re, subprocess, textwrap
from pathlib import Path
from ascent import Engine
ROOT=Path(__file__).resolve().parents[3]
STEM="signal-gate-mailbox"; PACKAGE="SignalGateMailbox"
CACHE=ROOT/".cache/tasks"/STEM; OUT=ROOT/"evidence/research"/STEM
BASE="dev/architecture/toolchain/"
MODEL=BASE+"models/sysml/"+STEM+".sysml"
DESIGN=BASE+STEM+"-design.org"; MATRIX=BASE+STEM+"-matrix.org"
DIAGRAM=BASE+"diagrams/"+STEM+".d2"
QNT="models/build/signal_gate_mailbox.qnt"; LEAN="models/build/SignalGateMailbox.lean"
RULES="dev/modeling/ascent/"+STEM+".rules.scm"
GROUPS=[("contract",8,"key anchor actionName lemmaName duty status"),("gain",4,"key avoided added condition"),("gate",7,"key qualified duty")]
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
 lines=["#+TITLE: Signal Gate and Mailbox — Admission, Ownership and Benefit Matrix","#+SETUPFILE: ../../modeling/org/setup.org","#+PROPERTY: header-args :eval never","","* RESEARCH Native SysML projection",":PROPERTIES:",":CUSTOM_ID: signal-gate-mailbox-matrix",":AUTHORITY: SignalGateMailbox",":STATUS: conditional-models-source-open",":END:","","Derived by native SysML queries. Benefits are conditional work/capacity bounds, not timings."]
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
 contracts=p["contract"];queries=["checked","missing","route","blocked","candidate","aligned","prioraligned","componentmapped","edgealigned"]
 engine=Engine();results={}
 try:
  session=engine.open_sources((ROOT/RULES).read_text())
  assert session.run(queries=queries)["complete"]
  for case in ["current","stale-subject","wrong-scope","missing-step","missing-component","missing-prior","parent-open","synthetic-all"]:
   full=case not in ["current","stale-subject","wrong-scope"]
   receipts=[[case,n,path,h,scope] for n,k,path,h,scope in needs if full or k in ["interleaving","induction"]]
   if case=="stale-subject":receipts=[x[:3]+["stale"]+x[4:] if x[1]=="SGM-H" else x for x in receipts]
   if case=="wrong-scope":receipts=[x[:4]+["wrong"] if x[1]=="SGM-I" else x for x in receipts]
   steps=[[v["actionName"],v["lemmaName"]] for v in contracts if not(case=="missing-step" and v["key"]=="derived-credit")]
   components=[[v["key"],v["anchor"],v["actionName"],v["lemmaName"]] for v in contracts]
   priorrows=[[v["key"],v["path"],v["sha256"],v["invariant"],v["action"],v["lemma"]] for v in prior]
   session.replace(dict(scenario=[[case]],need=needs,method=[["interleaving","quint"],["induction","lean"],["source-refinement","source-audit"],["environment-refinement","platform"]],receipt=receipts,dependency=deps,
    external=[[case,"SRR-S",str(full and case!="parent-open").lower()]],gate=[[case,v["key"],str(full).lower()] for v in p["gate"]],
    anchor=[[v["key"],v["anchor"]] for v in contracts],binding=[[v["key"],v["actionName"],v["lemmaName"],v["anchor"]] for v in contracts],modelstep=steps,
    component=components,componentbinding=[v for v in components if not(case=="missing-component" and v[0]=="storage-commit")],
    componentedge=[[v["dependent.key"],v["prerequisite.key"],v["reason"]] for v in p["edge"].values()],prior=priorrows,priorbinding=[v for v in priorrows if not(case=="missing-prior" and v[0]=="old-roster")]))
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
  assert len(results["synthetic-all"]["candidate"])==1
  assert all(not v["candidate"] for k,v in results.items() if k!="synthetic-all")
 finally:engine.close()
 save(CACHE/"ascent-model-results.json",dict(results=results,repositoryRegistered=False,hostAttested=False,syntheticNotRealReceipt=True))

def main():
 CACHE.mkdir(parents=True,exist_ok=True);OUT.mkdir(parents=True,exist_ok=True)
 parent=ROOT/"evidence/research/signal-route-retirement/input.json"
 parenthash=sha(parent);bindings=json.loads(parent.read_text())["sourceBindings"]
 assert all(sha(ROOT/path)==h for path,h in bindings.items()),"Frozen parent drift"
 p=project();views(p)
 q=(ROOT/QNT).read_text();l=(ROOT/LEAN).read_text()
 assert "sorry" not in l and "axiom " not in l
 for v in p["contract"]:
  assert re.search(r"action\s+"+v["actionName"]+r"(?:\(|=)",q)
  assert "theorem "+v["lemmaName"]+" " in l
 prior=[]
 for key,path,inv,action,lemma in [
  ("old-roster","models/build/signal_route_retirement.qnt","safe","enterCollective","rosterEveryParticipant"),
  ("foreign-closure","models/build/foreign_cleanup_closure.qnt","safe","takeMailbox","takePreservesCoverage"),
  ("still-authority","models/gambit/still_authority_handoff.qnt","safe","mismatchCas","failedCasNoPin"),
  ("work-closure","models/gambit/gc_work_closure.qnt","terminationSafe","retireVm","leaseBlocksRetirement")]:
  assert re.search(r"(?:val|def)\s+"+inv+r"\s*=",(ROOT/path).read_text())
  prior.append(dict(key=key,path=path,invariant=inv,action=action,lemma=lemma,sha256=sha(ROOT/path),productSimulationProved=False,rerun=False))
 save(CACHE/"prior-model-alignment.json",prior)
 sources=["vendor/gambit/lib/"+f for f in ["mem.c","c_intf.c","os_io.c","setup.c","os_setup.c","os.h","_thread.scm","_kernel.scm","os_time.c","os_tty.c","os_thread.c","os_thread.h","os_base.c","os_base.h"]]+["vendor/gambit/doc/gambit.txi","vendor/gambit/examples/tcltk/tcltk.scm","vendor/gambit/include/gambit.h.in"]
 counts={}
 for name,pattern,path in [
  ("signal-callers",r"___set_signal_handler|___thread_sigmask|interrupt_handler \(\)|___cleanup_all_interrupt_handling","vendor/gambit/lib"),
  ("release-origins",r"release_fn \(x\)|___release_foreign|cleanup_rc|free_still_objs|free_unmarked_still_objs","vendor/gambit/lib"),
  ("device-effects",r"___device_cleanup \(|___device_release \(|___device_select \(|___device_remove_from_group \(","vendor/gambit/lib/os_io.c")]:
  raw=run(name,["rg","--json","-g","*.c",pattern,path])
  matches=[json.loads(x)["data"] for x in raw.splitlines() if json.loads(x)["type"]=="match"]
  save(CACHE/(name+"-census.json"),dict(matches=matches,scope=path,qualification="syntactic source witnesses; conditional branches and exported aliases not qualified"));counts[name]=len(matches)
 mem=(ROOT/sources[0]).read_text();cint=(ROOT/sources[1]).read_text();io=(ROOT/sources[2]).read_text()
 release=cint[cint.index("___EXP_FUNC(___SCMOBJ,___release_foreign)"):cint.index("return ___FIX(___NO_ERR);",cint.index("___EXP_FUNC(___SCMOBJ,___release_foreign)"))]
 assert release.index("___FOREIGN_RELEASE_FN_FIELD(obj) =")<release.index("release_fn (ptr)")
 dev=io[io.index("___SCMOBJ ___device_cleanup\n"):io.index("___SCMOBJ ___device_cleanup_from_ptr")]
 assert dev.index("___device_remove_from_group")<dev.index("___DIRECTION_RD")<dev.index("___DIRECTION_WR")<dev.index("return ___device_release")
 native=io[io.index("___SCMOBJ ___device_release\n"):io.index("___SCMOBJ ___device_cleanup\n")]
 assert native.index("___device_release_virt")<native.index("___FREE_MEM(self)")
 cleanup=mem[mem.index("___HIDDEN void cleanup_rc"):mem.index("___EXP_FUNC(void*,___alloc_rc_no_register)")]
 assert "refcount" not in cleanup and "___FREE_MEM(h);" in cleanup
 save(CACHE/"source-facts.json",dict(wrapperClearedBeforeHook=True,deviceDetachedBeforeDirectionalClose=True,nativeSelfFreedAfterVirtualErrorPossible=True,bulkRcIgnoresRefcount=True,counts=counts,effectClosure=False,actualDarwinProfileQualified=False,proposedProtocolImplemented=False))
 select=io[io.index("___SCMOBJ ___device_select\n"):io.index("void ___device_select_abort")]
 assert "service_sync_op" not in select and "___ERRNO_ERR(EINTR)" in select
 assert select.index("___SELECT_PASS_CHECK")<select.index("if (aborted && e ==")
 ossetup=(ROOT/"vendor/gambit/lib/os_setup.c").read_text()
 close=ossetup[ossetup.index("int ___close_no_EINTR"):ossetup.index("return result;",ossetup.index("int ___close_no_EINTR"))]
 assert "result = close (fd);" in close and "errno != EINTR" in close
 save(CACHE/"wait-source-facts.json",dict(selectDoesNotServiceSyncOp=True,readyCheckBeforeFinalAbortCode=True,selfPipeWriteErrorIgnored=True,currentFdsetBorrow=True,rawStagesNotKernelReceipt=True,closeWrapperRetriesEintr=True,durableWakeRefinement=False,actualDarwinTlsProfile=False))
 header=(ROOT/"vendor/gambit/include/gambit.h.in").read_text()
 assert "___VOLATILE ___WORD intr_flag[___NB_INTRS]" in header
 assert "__sync_synchronize()" in header and "#define ___SHARED_MEMORY_BARRIER()" in header
 sender=io[io.index("void ___device_select_abort"):io.index("___SCMOBJ ___device_close")]
 assert "write (___ps->os.select_abort.writing_fd, buf, 1); /* ignore error */" in sender
 closer=ossetup[ossetup.index("void ___close_half_duplex_pipe"):ossetup.index("#ifdef USE_opendir",ossetup.index("void ___close_half_duplex_pipe"))]
 assert closer.index("___close_no_EINTR (hdp->reading_fd)")<closer.index("hdp->reading_fd = -1")
 save(CACHE/"native-channel-source-facts.json",dict(oneByteWriteErrorIgnored=True,drainDistinguishesEintrAndEagain=True,endpointFieldsInvalidatedAfterClose=True,volatileFlagsAndLegacyFences=True,signalCallbacksReachInterruptRaises=True,completeExternalAliasClosure=False,isoCMemoryOrderProved=False,nativeNoLossAdmitted=False))
 base=(ROOT/"vendor/gambit/lib/os_base.c").read_text()
 signal=base[base.index("void ___set_signal_handler"):base.index("/* Basic OS services",base.index("void ___set_signal_handler"))]
 assert "sigemptyset (&act.sa_mask);" in signal and "sigaction (sig, &act, 0);" in signal
 thread=(ROOT/"vendor/gambit/lib/os_thread.c").read_text()
 assert "return pthread_sigmask (how, set, oldset);" in thread and "return sigprocmask (how, set, oldset);" in thread
 timer=(ROOT/"vendor/gambit/lib/os_time.c").read_text()
 timerCleanup=timer[timer.index("void ___cleanup_heartbeat_interrupt_handling",timer.index("___HIDDEN void heartbeat_interrupt_handler")):]
 assert timerCleanup.index("___set_heartbeat_interval (-1.0);")<timerCleanup.index("___set_signal_handler (HEARTBEAT_SIG, SIG_IGN)")
 save(CACHE/"signal-retirement-source-facts.json",dict(dispositionHelperReturnsVoid=True,dispositionStatusNotDelivered=True,heartbeatMaskUsesCallingThreadWrapper=True,heartbeatCleanupStopsTimerThenIgnoresAndUnblocks=True,sigmaskNativeReturnConventionsDiffer=True,sourceHasManagedGate=False,allThreadDrainProved=False,actualDarwinSignalAbiQualified=False))
 user=ossetup[ossetup.index("___HIDDEN void user_intr"):ossetup.index("___HIDDEN void terminate_intr")]
 assert "&___GSTATE->vmstate0" in user and "___PSTATE_FROM_PROCESSOR_ID(0,___vms)" in user
 assert "___waitpid_no_EINTR (-1, &status, WNOHANG)" in io and "head = ___global_device_group ()->list;" in io
 setup=(ROOT/"vendor/gambit/lib/setup.c").read_text()
 assert "___ps->intr_flag[code] = ___FIX(0);" in setup
 save(CACHE/"gate-mailbox-source-facts.json",dict(userInterruptSelectsVm0Processor0AtCallback=True,heartbeatAndTerminationUseBroadcast=True,currentHandlerHasNoSiginfoGeneration=True,childStatusHandlerReconcilesNativeGroup=True,currentFlagClearIsNotProposedMailboxExchange=True,coalescingObservationalEquivalenceProved=False,packedGateImplemented=False,processMailboxImplemented=False))
 tests=run("quint-tests",["quint","test",QNT,"--match","Test$"])
 assert tests.count("ok ")==21 and tests.count("ControlTest passed")==10
 run("quint-samples",["quint","run",QNT,"--init","init","--invariant","safe","--max-samples","200","--max-steps","80","--seed","17","--verbosity","1"])
 run("lean",["lean",LEAN]);ascend(p,prior)
 run("d2-svg",["d2",DIAGRAM,DIAGRAM[:-3]+".svg"]);run("d2-png",["d2",DIAGRAM,str(CACHE/"diagram.png")])
 save(OUT/"checks.json",dict(status="pending-local-checks",runtimeAdmitted=False))
 org=(ROOT/"evidence/research/iter-compiler-service/check-org.el").read_text().replace("iter-compiler-service-design.org",STEM+"-design.org").replace("iter-compiler-service-matrix.org",STEM+"-matrix.org")
 (CACHE/"check-org.el").write_text(org);run("org",["emacs","--batch","-Q","--load",str(CACHE/"check-org.el")])
 for path in sources+[MODEL,DESIGN,MATRIX,DIAGRAM,DIAGRAM[:-3]+".svg",QNT,LEAN,RULES,"dev/modeling/tools/"+STEM+"-study.py"]+[v["path"] for v in prior]:bindings[path]=sha(ROOT/path)
 assert sha(parent)==parenthash
 save(CACHE/"input.json",dict(sourceBindings=bindings,parentInputSha256=parenthash,parentFrozen=True,head=run("head",["git","rev-parse","HEAD"]).strip(),dirtySourceIdentity="per-file SHA256",logs={str(p.relative_to(ROOT)):sha(p) for p in CACHE.iterdir() if p.suffix in {".stdout",".stderr"}}))
 checks=dict(status="conditional-local-models-pass",qntHistories=21,negativeControls=10,sampledRuns=200,maxSteps=80,leanTheorems=len(re.findall(r"^theorem ",l,re.M)),ascentCases=8,componentBindings=8,contractDependencies=10,priorBindings=4,gatesOpen=7,sourceSimulation="open",cMemoryOrder="open",hostRegistration="inherited unresolved; not retried",runtimeAdmitted=False,nativeTestsRun=False,performanceTestsRun=False)
 save(CACHE/"checks.json",checks)
 for path in CACHE.iterdir():
  if path.is_file() and path.suffix in {".json",".el"}:(OUT/path.name).write_bytes(path.read_bytes())
 save(OUT/"artifacts.json",{str(p.relative_to(ROOT)):sha(p) for p in OUT.iterdir() if p.is_file() and p.name!="artifacts.json"})
 print(json.dumps(checks))
if __name__=="__main__":main()
