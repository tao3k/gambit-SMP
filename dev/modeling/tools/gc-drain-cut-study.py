#!/usr/bin/env python3
"""Native SysML/ASCENT projection hooks for callback root retirement research."""
import argparse
import importlib.util
import json
import subprocess
from pathlib import Path
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("formal_study", Path(__file__).with_name("formal-study.py"))
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
ROOT = engine.ROOT
stem = "gc-drain-retirement-cut"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/gc_drain_cut_parameters.qnt"
groups = [("point", 7, "key anchor descriptor actualEdge requiredChange"),
          ("gate", 7, "key qualified condition"), ("gain", 4, "key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native GcDrainRetirementCut projection.\nmodule gc_drain_cut_parameters {\n"
        f"  pure val GvmRegisters = {p['defaultRegisters']}\n"
        f"  pure val WillInternalMask = {p['willInternalMask']}\n"
        f"  pure val WillReturnMask = {p['willReturnMask']}\n}}\n")
    lines = ["#+TITLE: Generated GC Drain Cuts and Net-Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: notifier-root-matrix",
        ":AUTHORITY: GcDrainRetirementCut", ":END:", "",
        "Derived from native SysML. Proposed root-retirement protocol is not current implementation."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph = ["# Source-bound retained generated path; proposed cuts are not current issuers.", "direction: down",
        'points: "Retained generated path / modern C" {']
    graph += [f" p{n}: " + json.dumps(v["key"] + "\n" + v["descriptor"]) for n, v in enumerate(p["point"][:6])]
    graph += ["}"]
    graph += [f"points.p{n} -> points.p{n+1}" for n in range(5)]
    graph += ['restore: "POLL -> all-register snapshot -> internal/thread restore"',
        'epi: "Candidate per-action cut after VOID / not admitted"',
        'batch: "Candidate explicit batch barrier before jobs / not admitted"',
        'proof: "SysML DC-H/I/S/E -> ASCENT -> QNT / Lean"',
        'open: "Generation provenance + root/effect closure + native publication OPEN"',
        "points.p0 -> restore", "restore -> points.p0", "points.p1 -> epi", "points.p4 -> batch",
        "epi -> proof", "batch -> proof", "proof -> open"]
    (ROOT / diagram).write_text("\n".join(graph) + "\n")


sources = ["vendor/gambit/" + path for path in ["lib/_kernel.scm", "lib/_nonstd.scm", "lib/mem.c",
    "lib/_thread.scm", "lib/_io.scm", "lib/os_dyn.c", "tests/mem.scm"]]
sources += ["../gerbil-gambit-bootstrap-audit/src/" + path for path in ["std/text/parser/ebnf/lexer.ss",
    "std/text/parser/ebnf/stream.ss", "std/text/parser/ebnf/lang-reader.ss", "std/text/parser/ebnf/defparser.ss",
    "std/text/parser/base.ss", "gerbil/runtime/error.ss", "gerbil/runtime/syntax.ss", "std/db/sqlite.ss"]]
sources += ["vendor/gambit/include/gambit.h.in", "vendor/gambit/gsc/_t-c-1.scm", "vendor/gambit/gsc/_t-c-2.scm", "vendor/gambit/gsc/_t-c-3.scm", "vendor/gambit/lib/_kernel.c"]


def source_checks(cache):
    cohort = {name: subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
              for name, path in [("research", "."), ("gerbil", "../gerbil-gambit-bootstrap-audit"), ("gambit", "vendor/gambit")]}
    engine.save(cache / "source-cohort.json", cohort)
    import re
    generated = (ROOT / "vendor/gambit/lib/_kernel.c").read_text()
    projection = json.loads((cache / "projection.json").read_text())["detail"]
    assert 'produced by Gambit v4.9.8' in generated
    hosts = {}
    names = ["will_2d_execute_21_", "gc_2d_finalize_21_", "gc_2d_final_2d_will_2d_registry_21_",
             "handle_2d_gc_2d_interrupt_21_", "execute_2d_jobs_21_"]
    for name in names:
        host = "___H__23__23_" + name
        start = generated.index("#define ___PH_PROC " + host + "\n")
        end = generated.index("\n#undef ___PH_PROC", start)
        body = generated[start:end]
        descriptors = re.findall(r"___DEF_LBL_RET\(" + re.escape(host) + r",___IFD\(___(RETI|RETN),(\d+),(\d+),(0x[0-9a-f]+)L\)\)", generated)
        hosts[name] = dict(startLine=generated.count("\n", 0, start)+1,
            body=body, returnDescriptors=[dict(labelIndex=i+1, kind=k, size=int(fs), link=int(link), mask=int(mask,16))
                for i,(k,fs,link,mask) in enumerate(descriptors)],
            writes=re.findall(r"___SET_R(\d+)\(([^\n]*)", body),
            bankSavedClearingPresent="___GC_RESTORE" in body or "->saved" in body,
            labels=re.findall(r"___DEF_SLBL\((\d+),([^)]*)\)", body))
    will=hosts[names[0]]
    assert will["returnDescriptors"] == [dict(labelIndex=1,kind="RETI",size=4,link=0,mask=projection["willInternalMask"]),
        dict(labelIndex=2,kind="RETN",size=1,link=0,mask=projection["willReturnMask"])]
    assert [v["mask"] for v in hosts[names[4]]["returnDescriptors"]] == [0x3f,0x3,0x3f,0x3f03]
    assert all(not hosts[n]["bankSavedClearingPresent"] for n in names)
    assert not re.search(r"___SET_R4\(", hosts[names[1]]["body"] + hosts[names[2]]["body"] + hosts[names[3]]["body"])
    epilogue=will["body"].split("___DEF_SLBL(2,",1)[1]
    assert "___SET_R1(___VOID)" in epilogue and not re.search(r"___SET_R[234]\(", epilogue)
    hdr=(ROOT / "vendor/gambit/include/gambit.h.in").read_text()
    emitter=(ROOT / "vendor/gambit/gsc/_t-c-1.scm").read_text()
    assert int(re.search(r"#define ___NB_GVM_REGS (\d+)",hdr)[1]) == projection["defaultRegisters"]
    assert int(re.search(r"\(define targ-default-nb-gvm-regs (\d+)\)",emitter)[1]) == projection["defaultRegisters"]
    tests=[("vendor/gambit/lib/_kernel.scm", "___PUSH_REGS /* push all GVM registers (live or not) */"),
        ("vendor/gambit/lib/_kernel.scm", "___POP_REGS"),
        ("vendor/gambit/lib/_kernel.scm", "(##execute-jobs! ##gc-interrupt-jobs)"),
        ("vendor/gambit/gsc/_t-c-2.scm", "; all saved GVM regs are live"),
        ("vendor/gambit/include/gambit.h.in", "#define ___W_ALL ___SM(___MW_ALL,___PW_ALL)"),
        ("vendor/gambit/include/gambit.h.in", "___GC_SAVE1(ps,___VOID))"),
        ("vendor/gambit/include/gambit.h.in", "___CONTINUATION_FRAME_FIELD(___THREAD_CONT_FIELD(thread)) = frame;"),
        ("vendor/gambit/lib/mem.c", "mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));")]
    for path,fragment in tests: assert fragment in (ROOT/path).read_text(),(path,fragment)
    assert (ROOT/"models/build/GcDrainRetirementCut.lean").read_text().count("theorem ") == 8
    lines=generated.splitlines()
    assert lines[17164].strip() == "___SET_R1(___VOID)" and lines[17165].strip() == "___JUMPRET(___R0)"
    assert lines[17333].strip() == "___ADJFP(-4)" and "execute_2d_jobs_21_" in lines[17334]
    engine.save(cache/"candidate-cuts.json", dict(perAction=dict(afterLine=17165,beforeLine=17166),
        preJobs=dict(afterLine=17334,beforeLine=17335), currentIssuer=False, qualified=False))
    engine.save(cache/"generated-path.json",dict(source="vendor/gambit/lib/_kernel.c",digest=engine.sha(ROOT/sources[-1]),
        hosts=hosts, originalGenerationReceipt="unresolved", configuredDarwinObject="unresolved",
        callbackR4Postcondition="adversarial-not-observed", currentIssuer=False))
    engine.save(cache/"source-census.json",dict(checks=[dict(path=p,fragment=f) for p,f in tests],
        bindings={p:engine.sha(ROOT/p) for p in sources}, originalGenerationReceipt="unresolved",
        exactConfiguredRootMap="unresolved", registerRestoreClosure="unresolved", actualIssuer=False))


def facts(p, scenario):
    out = [engine.fact("drainPointFact", [v[k] for k in ["key", "anchor", "descriptor", "actualEdge", "requiredChange"]]) for v in p["point"]]
    for gate in p["gate"]:
        qualified = scenario in {"synthetic-gates", "missing-release"} and not(
            scenario == "missing-release" and gate["key"] == "restore-closure")
        out.append(engine.fact("drainGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
    out.append(engine.fact("drainSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-release"}).lower()]))
    return out


def check_inference(p, results):
    c = results["current"]
    assert sorted(c["drainPoint"]) == sorted(["current"] + [v[k] for k in ["key", "anchor", "descriptor", "actualEdge", "requiredChange"]] for v in p["point"])
    assert len(c["drainMissing"]) == len(p["gate"]) and not c["drainCandidate"]
    assert not results["all-scoped-control"]["drainCandidate"]
    assert len(results["synthetic-gates"]["drainCandidate"]) == 1
    assert not results["missing-release"]["drainCandidate"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="notifier-root-retirement", package="GcDrainRetirementCut", prefix="DC",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/gc_drain_retirement_cut.qnt", lean="models/build/GcDrainRetirementCut.lean",
        parent_design="dev/architecture/toolchain/notifier-root-retirement-design.org",
        parent_matrix="dev/architecture/toolchain/notifier-root-retirement-matrix.org",
        groups=groups, scalars=["defaultRegisters", "willInternalMask", "willReturnMask", "actualAdmitted"], histories=35, controls=17, kernels=8, inits=["init", "initCandidate"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="drainPoint drainMissing drainBlocked drainCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/gc_drain_retirement_cut.qnt",
            "models/build/GcDrainRetirementCut.lean", "dev/modeling/tools/gc-drain-cut-study.py", "dev/modeling/tools/formal-study.py"])
    engine.execute(study, resume=args.resume)
