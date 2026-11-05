#!/usr/bin/env python3
"""Study schema/projection hooks; architecture values come from native SysML."""
import argparse
import importlib.util
import json
from pathlib import Path
from types import SimpleNamespace

spec = importlib.util.spec_from_file_location("formal_study", Path(__file__).with_name("formal-study.py"))
engine = importlib.util.module_from_spec(spec)
spec.loader.exec_module(engine)
ROOT = engine.ROOT
stem = "span-storage-handoff"
model = f"dev/architecture/toolchain/models/sysml/{stem}.sysml"
design = f"dev/architecture/toolchain/{stem}-design.org"
matrix = f"dev/architecture/toolchain/{stem}-matrix.org"
diagram = f"dev/architecture/toolchain/diagrams/{stem}.d2"
rules = f"dev/modeling/ascent/{stem}.rules.scm"
param = "models/build/span_storage_parameters.qnt"
groups = [("contract", 6, "key anchor rule openDuty"), ("gate", 5, "key qualified condition"), ("gain", 4, "key avoided added condition")]


def views(p):
    (ROOT / param).write_text("// Native SpanStorageHandoff projection.\nmodule span_storage_parameters {\n"
        f"  pure val MaximumResumptions = {p['maximumResumptions']}\n}}\n")
    lines = ["#+TITLE: Span Storage, Multi-shot Custody and Net-Benefit Matrix",
        "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
        "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: span-storage-matrix",
        ":AUTHORITY: SpanStorageHandoff", ":END:", "",
        "Derived by Python from native SysML. No source/native gate is closed by this view."]
    for name, _, schema in groups:
        fields = schema.split()
        lines += ["", "** " + name.capitalize(), "", "| " + " | ".join(fields) + " |", "|" + "+".join("---" for _ in fields) + "|"]
        lines += ["| " + " | ".join(str(row[field]) for field in fields) + " |" for row in p[name]]
    (ROOT / matrix).write_text("\n".join(lines) + "\n")
    graph = ["# Native SysML containment and proof-duty view; not execution ordering.", "direction: down",
        'domain: "SpanStorageHandoff / modern C baseline"', 'contracts: "Storage and control contracts" {', "  grid-columns: 2"]
    graph += [f" c{n}: " + json.dumps(v["key"] + "\n" + v["anchor"]) for n, v in enumerate(p["contract"])]
    graph += ["}", 'proof: "SH-H QNT / SH-I Lean; SH-S source / SH-E native"',
        'ascent: "ASCENT exact scopes / ancestor RS-S dependencies"', 'gates: "Five qualification gates remain open"',
        "domain -> contracts", "contracts -> proof", "proof -> ascent", "ascent -> gates"]
    (ROOT / diagram).write_text("\n".join(graph) + "\n")


sources = ["../gerbil-gambit-bootstrap-audit/src/" + path for path in [
    "std/error.ss", "gerbil/runtime/error.ss", "gerbil/runtime/syntax.ss",
    "std/text/parser/base.ss", "std/text/parser/ebnf/lexer.ss", "std/text/parser/ebnf/deflexer.ss"]]
sources += ["vendor/gambit/lib/_thread.scm", "vendor/gambit/lib/_io.scm"]


def source_checks(cache):
    tests = [
        (sources[0], "#'(deferror-class (Class Error) slots predicate-alias Error:::init!)"),
        (sources[1], "(defclass (Error StackTrace Exception)"),
        (sources[1], "(unless (&StackTrace-continuation exn)"),
        (sources[1], "(lambda (exn) (##continuation-graft cont handler exn))"),
        (sources[2], "(defclass (SyntaxError Exception StackTrace)"),
        (sources[3], "(defstruct token (t e loc)"),
        (sources[3], "(deferror-class ParseError () parse-error?)"),
        (sources[5], "(action #'(lambda (@@ @loc) $))"),
    ]
    for path, fragment in tests:
        assert fragment in (ROOT / path).read_text(), (path, fragment)
    engine.save(cache / "source-census.json", dict(checks=[dict(path=p, fragment=f) for p, f in tests],
        bindings={p: engine.sha(ROOT / p) for p in sources}, frameReachability="open", aliasClosure="open"))


def facts(p, scenario):
    out = [engine.fact("storageContractFact", [v["key"], v["anchor"], v["rule"]]) for v in p["contract"]]
    for gate in p["gate"]:
        qualified = scenario in {"synthetic-gates", "missing-release"} and not(
            scenario == "missing-release" and gate["key"] == "reclamation-adapter")
        out.append(engine.fact("storageGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
    out.append(engine.fact("storageSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-release"}).lower()]))
    return out


def check_inference(p, results):
    current = results["current"]
    assert sorted(current["storageDuty"]) == sorted(["current", v["key"], v["anchor"], v["rule"]] for v in p["contract"])
    assert len(current["storageMissing"]) == len(p["gate"]) and not current["storageCandidate"]
    assert not results["all-scoped-control"]["storageCandidate"]
    assert len(results["synthetic-gates"]["storageCandidate"]) == 1
    assert not results["missing-release"]["storageCandidate"]


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--resume", action="store_true", help="Reuse digest-verified formal receipts; rerun projection/inference checks")
    args = parser.parse_args()
    study = SimpleNamespace(task=stem, parent="reader-span-custody", package="SpanStorageHandoff", prefix="SH",
        model=model, design=design, matrix=matrix, diagram=diagram, rules=rules, param=param,
        qnt="models/build/span_storage_handoff.qnt", lean="models/build/SpanStorageHandoff.lean",
        parent_design="dev/architecture/toolchain/reader-span-custody-design.org",
        parent_matrix="dev/architecture/toolchain/reader-span-custody-matrix.org",
        groups=groups, scalars=["maximumResumptions", "actualAdmitted"],
        histories=21, controls=9, kernels=8, inits=["init", "initBeforeRead"],
        views=views, source_checks=source_checks, facts=facts, check_inference=check_inference,
        outputs="storageDuty storageMissing storageBlocked storageCandidate", sources=sources,
        artifacts=[model, design, matrix, diagram, rules, param, "models/build/span_storage_handoff.qnt",
            "models/build/SpanStorageHandoff.lean", "dev/modeling/tools/span-storage-study.py", "dev/modeling/tools/formal-study.py"])
    engine.execute(study, resume=args.resume)
