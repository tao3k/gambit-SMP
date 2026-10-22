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
stem = "notifier-root-retirement"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/notifier_root_parameters.qnt"
groups = [("root", 6, "key anchor actualEdge requiredChange"),
          ("gate", 7, "key qualified condition"), ("gain", 4, "key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native NotifierRootRetirement projection.\nmodule notifier_root_parameters {\n"
        f"  pure val ReceiptGeneration = {p['receiptGeneration']}\n}}\n")
    lines = ["#+TITLE: Callback Root Retirement and Net-Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: notifier-root-matrix",
        ":AUTHORITY: NotifierRootRetirement", ":END:", "",
        "Derived from native SysML. Proposed root-retirement protocol is not current implementation."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph = ["# Derived from native SysML; protocol is proposed, source/native gates remain open.", "direction: down",
        'domain: "gxi/gxc reader-session ownership / Scheme + modern C"',
        'roots: "Six root/restoration boundaries" {', " grid-columns: 2"]
    graph += [f" r{n}: " + json.dumps(v["key"] + "\n" + v["anchor"]) for n, v in enumerate(p["root"])]
    graph += ["}", 'prepare: "Prepared notification / live roots"',
        'returned: "Normal return / roots may remain"',
        'cut: "Certified cut / no roots or restoration edges"',
        'receipt: "RootRetirementReceipt / matching attempt and root domain"',
        'join: "Ancestor release join / notice alone is insufficient"',
        'denied: "Capture, exception, escape or unknown / retain custody"',
        'proof: "SysML NR-H/I/S/E -> ASCENT -> QNT / Lean"',
        'gates: "Seven source/native gates OPEN"',
        "domain -> roots", "roots -> prepare", "prepare -> returned", "returned -> cut", "cut -> receipt", "receipt -> join",
        "prepare -> denied", "returned -> denied", "cut -> proof", "proof -> gates"]
    (ROOT / diagram).write_text("\n".join(graph) + "\n")


sources = ["vendor/gambit/" + path for path in ["lib/_kernel.scm", "lib/_nonstd.scm", "lib/mem.c",
    "lib/_thread.scm", "lib/_io.scm", "lib/os_dyn.c", "tests/mem.scm"]]
sources += ["../gerbil-gambit-bootstrap-audit/src/" + path for path in ["std/text/parser/ebnf/lexer.ss",
    "std/text/parser/ebnf/stream.ss", "std/text/parser/ebnf/lang-reader.ss", "std/text/parser/ebnf/defparser.ss",
    "std/text/parser/base.ss", "gerbil/runtime/error.ss", "gerbil/runtime/syntax.ss", "std/db/sqlite.ss"]]
sources += ["vendor/gambit/include/gambit.h.in", "vendor/gambit/gsc/_t-c-1.scm", "vendor/gambit/gsc/_t-c-2.scm"]


def source_checks(cache):
    cohort = {name: subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
              for name, path in [("research", "."), ("gerbil", "../gerbil-gambit-bootstrap-audit"), ("gambit", "vendor/gambit")]}
    engine.save(cache / "source-cohort.json", cohort)
    tests = [(sources[0], "(action testator)"), (sources[0], "___POP_REGS"),
        (sources[0], "___SCMOBJ frame = ___CONTINUATION_FRAME_FIELD(cont);"),
        (sources[0], "___SCMOBJ denv  = ___CONTINUATION_DENV_FIELD(cont);"),
        (sources[2], "mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));"),
        (sources[2], "mark_array (___PSP ___ps->saved, sizeof(___ps->saved)/sizeof(*___ps->saved));"),
        (sources[2], "mark_captured_continuation (___PSP &body[___CONTINUATION_FRAME]);"),
        (sources[2], "___RETN_GET_FS_LINK_GCMAP(ra1,fs,link,gcmap,nextgcmap)"),
        (sources[2], "mark_frame (___PSP fp, fs, gcmap, nextgcmap);"),
        (sources[3], "((macro-dynwind-after src))"),
        (sources[3], "((macro-dynwind-before dst))"),
        (sources[12], "(unchecked-slot-set! exn 'continuation cont)"),
        (sources[12], "(lambda (exn) (##continuation-graft cont handler exn))"),
        (sources[-3], "(a = (ps)->saved[0],"), (sources[-3], "___GC_SAVE1(ps,___VOID))"),
        (sources[-3], "___SET_STK(-2,___THREAD_DENV_FIELD(___CURRENTTHREAD))"),
        (sources[-3], "___CONTINUATION_FRAME_FIELD(___THREAD_CONT_FIELD(thread)) = frame;"),
        (sources[-3], "___CONTINUATION_FRAME_FIELD(cont) = ___END_OF_CONT_MARKER;"),
        (sources[2], "mark_processor_scmobj (___PSPNC);"),
        (sources[-3], "___SET_STK(-___BREAK_FRAME_NEXT,___CONTINUATION_FRAME_FIELD(cont))"),
        (sources[-2], '(list "DEF_LBL_PROC"'), (sources[-2], '"DEF_LBL_RET"'),
        (sources[-1], '(targ-jump-inline "##continuation-capture"'),
        (sources[-1], '(targ-jump-inline "##continuation-return-no-winding"')]
    for path, fragment in tests:
        assert fragment in (ROOT / path).read_text(), (path, fragment)
    assert (ROOT / "models/build/NotifierRootRetirement.lean").read_text().count("theorem ") == 8
    engine.save(cache / "source-census.json", dict(checks=[dict(path=p, fragment=f) for p, f in tests],
        bindings={p: engine.sha(ROOT / p) for p in sources},
        exactGeneratedPoint="open", allRootRestoreClosure="open", transitiveEffects="open",
        actualIssuer="absent-proposed", runtimeAdmitted=False,
        externalReference=dict(url="https://standards.scheme.org/corrected-r7rs/r7rs-Z-H-8.html",
            role="Scheme control semantics, not implementation refinement")))


def facts(p, scenario):
    out = [engine.fact("retirementRootFact", [v[k] for k in ["key", "anchor", "actualEdge", "requiredChange"]]) for v in p["root"]]
    for gate in p["gate"]:
        qualified = scenario in {"synthetic-gates", "missing-release"} and not(
            scenario == "missing-release" and gate["key"] == "retirement-cut")
        out.append(engine.fact("retirementGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
    out.append(engine.fact("retirementSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-release"}).lower()]))
    return out


def check_inference(p, results):
    c = results["current"]
    assert sorted(c["retirementRoot"]) == sorted(["current"] + [v[k] for k in ["key", "anchor", "actualEdge", "requiredChange"]] for v in p["root"])
    assert len(c["retirementMissing"]) == len(p["gate"]) and not c["retirementCandidate"]
    assert not results["all-scoped-control"]["retirementCandidate"]
    assert len(results["synthetic-gates"]["retirementCandidate"]) == 1
    assert not results["missing-release"]["retirementCandidate"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="owner-notifier-closure", package="NotifierRootRetirement", prefix="NR",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/notifier_root_retirement.qnt", lean="models/build/NotifierRootRetirement.lean",
        parent_design="dev/architecture/toolchain/owner-notifier-closure-design.org",
        parent_matrix="dev/architecture/toolchain/owner-notifier-closure-matrix.org",
        groups=groups, scalars=["receiptGeneration", "actualAdmitted"], histories=32, controls=15, kernels=8, inits=["init", "initUnqualified"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="retirementRoot retirementMissing retirementBlocked retirementCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/notifier_root_retirement.qnt",
            "models/build/NotifierRootRetirement.lean", "dev/modeling/tools/notifier-root-study.py", "dev/modeling/tools/formal-study.py"])
    engine.execute(study, resume=args.resume)
