#!/usr/bin/env python3
"""Native SysML/ASCENT projection hooks for owner/notifier closure research."""
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
stem = "owner-notifier-closure"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/owner_notifier_parameters.qnt"
groups = [("holder", 7, "key anchor actualEdge requiredChange"),
          ("gate", 7, "key qualified condition"), ("gain", 4, "key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native OwnerNotifierClosure projection.\nmodule owner_notifier_parameters {\n"
        f"  pure val OwnerGeneration = {p['ownerGeneration']}\n}}\n")
    lines = ["#+TITLE: Owner Holders, Notifier Closure and Net-Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: owner-notifier-matrix",
        ":AUTHORITY: OwnerNotifierClosure", ":END:", "",
        "Derived from native SysML. Proposed owner/notifier protocol is not current implementation."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph = ["# Native SysML holder containment and proof obligations; no runtime ordering implied.", "direction: down",
        'domain: "Owner token coverage / restricted notifier / modern C"', 'holders: "Actual holder shapes to be covered" {', "  grid-columns: 2"]
    graph += [f" h{n}: " + json.dumps(v["key"] + "\n" + v["anchor"]) for n, v in enumerate(p["holder"])]
    graph += ["}", 'proof: "NC-H QNT / NC-I Lean; NC-S source / NC-E native"',
        'ascent: "ASCENT exact scopes / ancestor RA-S dependencies"', 'gates: "Seven source/native gates remain open"',
        "domain -> holders", "holders -> proof", "proof -> ascent", "ascent -> gates"]
    (ROOT / diagram).write_text("\n".join(graph) + "\n")


sources = ["vendor/gambit/" + path for path in ["lib/_kernel.scm", "lib/_nonstd.scm", "lib/mem.c",
    "lib/_thread.scm", "lib/_io.scm", "lib/os_dyn.c", "tests/mem.scm"]]
sources += ["../gerbil-gambit-bootstrap-audit/src/" + path for path in ["std/text/parser/ebnf/lexer.ss",
    "std/text/parser/ebnf/stream.ss", "std/text/parser/ebnf/lang-reader.ss", "std/text/parser/ebnf/defparser.ss",
    "std/text/parser/base.ss", "gerbil/runtime/error.ss", "gerbil/runtime/syntax.ss", "std/db/sqlite.ss"]]
sources += ["vendor/gambit/include/gambit.h.in"]


def source_checks(cache):
    cohort = {name: subprocess.check_output(["git", "-C", path, "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
              for name, path in [("research", "."), ("gerbil", "../gerbil-gambit-bootstrap-audit"), ("gambit", "vendor/gambit")]}
    engine.save(cache / "source-cohort.json", cohort)
    tests = [(sources[0], "(##will-testator-set! will #f)"), (sources[0], "(action testator)"),
        (sources[0], "(##declare (interrupts-enabled))"), (sources[0], "(let loop ((lst (macro-fifo->list jobs)))"),
        (sources[0], "(##execute-jobs! ##gc-interrupt-jobs)"),
        (sources[1], "(macro-check-will will 1 (will-execute! will)"),
        (sources[1], "(##will-execute! will))))"),
        (sources[6], "(lambda (o) (p o) (set! obj9 o))"),
        (sources[7], "(defstruct token-stream (cs buf Ls Rs $$)"),
        (sources[8], "(defstruct char-stream (port buf loc lines)"),
        (sources[12], "(unless (&StackTrace-continuation exn)"),
        (sources[14], "(make-will driver __sqlite-driver-close)"),
        (sources[2], "___RETN_GET_FS_LINK_GCMAP(ra1,fs,link,gcmap,nextgcmap)"),
        (sources[2], "mark_array (___PSP ___ps->r, sizeof(___ps->r)/sizeof(*___ps->r));"),
        (sources[-1], "#define ___RETI_GET_FS_LINK_GCMAP")]
    for path, fragment in tests:
        assert fragment in (ROOT / path).read_text(), (path, fragment)
    engine.save(cache / "source-census.json", dict(checks=[dict(path=p, fragment=f) for p, f in tests],
        bindings={p: engine.sha(ROOT / p) for p in sources}, holderCoverage="open",
        closureCallGraph="open", dispatcherRootMap="open", upstreamResurrectionTest="source-read-only"))


def facts(p, scenario):
    out = [engine.fact("notifierHolderFact", [v[k] for k in ["key", "anchor", "actualEdge", "requiredChange"]]) for v in p["holder"]]
    for gate in p["gate"]:
        qualified = scenario in {"synthetic-gates", "missing-release"} and not(
            scenario == "missing-release" and gate["key"] == "callback-frame-exit")
        out.append(engine.fact("notifierGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
    out.append(engine.fact("notifierSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-release"}).lower()]))
    return out


def check_inference(p, results):
    c = results["current"]
    assert sorted(c["notifierHolder"]) == sorted(["current"] + [v[k] for k in ["key", "anchor", "actualEdge", "requiredChange"]] for v in p["holder"])
    assert len(c["notifierMissing"]) == len(p["gate"]) and not c["notifierCandidate"]
    assert not results["all-scoped-control"]["notifierCandidate"]
    assert len(results["synthetic-gates"]["notifierCandidate"]) == 1
    assert not results["missing-release"]["notifierCandidate"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="stream-release-authority", package="OwnerNotifierClosure", prefix="NC",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/owner_notifier_closure.qnt", lean="models/build/OwnerNotifierClosure.lean",
        parent_design="dev/architecture/toolchain/stream-release-authority-design.org",
        parent_matrix="dev/architecture/toolchain/stream-release-authority-matrix.org",
        groups=groups, scalars=["ownerGeneration", "actualAdmitted"], histories=27, controls=13, kernels=8, inits=["init", "initPublic"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="notifierHolder notifierMissing notifierBlocked notifierCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/owner_notifier_closure.qnt",
            "models/build/OwnerNotifierClosure.lean", "dev/modeling/tools/owner-notifier-study.py", "dev/modeling/tools/formal-study.py"])
    engine.execute(study, resume=args.resume)
