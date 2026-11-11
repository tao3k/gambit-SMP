#!/usr/bin/env python3
"""Research-only native SysML/ASCENT/QNT/Lean checks, orchestrated in Python."""
from __future__ import annotations

from collections import defaultdict
import importlib.util
import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("cursor_study_support", HERE / "logical-cursor-study.py")
support = importlib.util.module_from_spec(spec)
spec.loader.exec_module(support)
ROOT = support.ROOT
TASK = "reader-span-custody"
CACHE = ROOT / ".cache/tasks" / TASK
EVIDENCE = ROOT / "evidence/research" / TASK
PARENT = ROOT / "evidence/research/logical-cursor-contract"
support.CACHE = CACHE
save, sha, fact, chunks = support.save, support.sha, support.fact, support.chunks
MODEL = "dev/architecture/toolchain/models/sysml/reader-span-custody.sysml"
DESIGN = "dev/architecture/toolchain/reader-span-custody-design.org"
MATRIX = "dev/architecture/toolchain/reader-span-custody-matrix.org"
DIAGRAM = "dev/architecture/toolchain/diagrams/reader-span-custody.d2"
RULES = "dev/modeling/ascent/reader-span-custody.rules.scm"
QNT = "models/build/reader_span_custody.qnt"
LEAN = "models/build/ReaderSpanCustody.lean"
PARAM = "models/build/reader_span_parameters.qnt"


def run(name, argv):
    try:
        return support.run(name, argv)
    except RuntimeError:
        # Distinguish errors with empty stdout by hashing stderr and argv too.
        import hashlib
        diagnostic = dict(argv=argv, stdout=(CACHE / f"{name}.stdout").read_text(),
                          stderr=(CACHE / f"{name}.stderr").read_text())
        key = hashlib.sha256(json.dumps(diagnostic, sort_keys=True).encode()).hexdigest()[:16]
        save(CACHE / f"{name}.retained-failure-{key}.json", diagnostic)
        raise


def projection():
    queries = json.loads((PARENT / "native-queries.json").read_text())
    for group, count, fields in [
        ("producer", 8, "key anchor custodian interval interruption"),
        ("reader", 5, "key lineNumber bodyCatch consumer failure"),
        ("reset", 2, "key lineNumber nextStep condition"),
        ("gate", 5, "key qualified condition"),
        ("gain", 3, "key avoided added threshold"),
    ]:
        queries += [(f"span.{group}.{n}.{field}", f"ReaderSpanCustody::{group}{n}.{field}")
                    for n in range(count) for field in fields.split()]
    for field in ["fixtureCharacters", "actualAdmitted"]:
        queries.append((f"span.{field}", f"ReaderSpanCustody::{field}"))
    for slot in ["history", "induction", "source", "platform"]:
        queries += [(f"needs.span-{slot}.{field}", f"ReaderSpanCustody::{slot}.{field}")
                    for field in "obligationId kind subjectPath subjectScope premise owner.componentId".split()]
    for n in range(4):
        queries += [(f"dependencies.span-{n}.{field}", f"ReaderSpanCustody::dependency{n}.{field}")
                    for field in "dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId".split()]
    argv = ["sysml", "-strict", "-no-record-cache", "-validate", "-json"]
    for _, expression in queries:
        argv += ["-e", expression]
    native = json.loads(run("sysml", argv + ["dev"]))
    assert native["exit"] == 0 and not native.get("errors")
    assert not any(d.get("severity") == "error" for d in native.get("diagnostics", []))
    values = [json.loads(line[4:]) for line in native["output"] if line.startswith("  = ")]
    assert len(values) == len(queries)
    p = {}
    for (key, _), value in zip(queries, values, strict=True):
        node = p
        fields = key.split(".")
        for field in fields[:-1]:
            node = node.setdefault(field, {})
        node[fields[-1]] = value
    for field in ["producer", "reader", "reset", "gate", "gain"]:
        p["span"][field] = list(p["span"][field].values())
    save(CACHE / "projection.json", p)
    save(CACHE / "native-queries.json", queries)
    return p, native


def source_census(p):
    name = "../gerbil-gambit-bootstrap-audit/src/std/text/parser/ebnf/lang-reader.ss"
    lines = (ROOT / name).read_text().splitlines()
    actual = [i + 1 for i, line in enumerate(lines) if "(read-syntax port)" in line]
    assert actual == [r["lineNumber"] for r in p["reader"]]
    assert actual == [23, 99, 123, 166, 238]
    for reset, spelling in zip(p["reset"], ["(lex-parser port)", "(lex-lexer port)"], strict=True):
        assert spelling in lines[reset["lineNumber"] - 1]
    # Exact bounded sites, not a parser or whole-repository alias proof.
    bypasses = {"peek-char": [90, 105], "read-char": [96, 111, 120], "read-line": [114]}
    for operator, expected in bypasses.items():
        found = [i + 1 for i, line in enumerate(lines) if f"({operator} port)" in line]
        assert found == expected
    assert "(read-section-head port)" in lines[73] and "(with-catch raise-e" in lines[75]
    save(CACHE / "source-census.json", dict(source=name, sha256=sha(ROOT / name), datumSites=actual,
         rawHeaderSites=bypasses, resetSites=[r["lineNumber"] for r in p["reset"]],
         headerBeforeBodyCatch=True, semanticAliasClosure="open"))


def views(p):
    (ROOT / PARAM).write_text("// Derived from native ReaderSpanCustody values.\nmodule reader_span_parameters {\n"
        f"  pure val FixtureCharacters = {p['fixtureCharacters']}\n"
        "  pure val BodyCatch = List(" + ",".join(str(r["bodyCatch"]).lower() for r in p["reader"]) + ")\n}\n")
    lines = ["#+TITLE: Reader Span Custody and Net-Benefit Matrix", "#+SETUPFILE: ../../modeling/org/setup.org",
             "#+PROPERTY: header-args :eval never", "", "* RESEARCH Native SysML projection", ":PROPERTIES:",
             ":CUSTOM_ID: reader-span-matrix", ":AUTHORITY: ReaderSpanCustody", ":END:", "",
             "Derived with Python from native SysML evaluation. Source/native refinement remains open.", "",
             "| Producer | Actual source | Custodian | Interval | Interruption |", "|---+---+---+---+---|"]
    lines += [f"| {v['key']} | {v['anchor']} | {v['custodian']} | {v['interval']} | {v['interruption']} |" for v in p["producer"]]
    lines += ["", "** Reader and reset paths", "", "| Entry | Source line | Body catch | Consumer | Failure |", "|---+---+---+---+---|"]
    lines += [f"| {v['key']} | {v['lineNumber']} | {v['bodyCatch']} | {v['consumer']} | {v['failure']} |" for v in p["reader"]]
    lines += ["", "| Reset | Line | Next observation | Retirement condition |", "|---+---+---+---|"]
    lines += [f"| {v['key']} | {v['lineNumber']} | {v['nextStep']} | {v['condition']} |" for v in p["reset"]]
    lines += ["", "** Open gates", "", "| Gate | Qualified | Remaining condition |", "|---+---+---|"]
    lines += [f"| {v['key']} | {v['qualified']} | {v['condition']} |" for v in p["gate"]]
    lines += ["", "** Net work / modern C baseline", "", "| Mechanism | Avoided work | Added work | Positive threshold / limit |", "|---+---+---+---|"]
    lines += [f"| {v['key']} | {v['avoided']} | {v['added']} | {v['threshold']} |" for v in p["gain"]]
    (ROOT / MATRIX).write_text("\n".join(lines) + "\n")
    graph = ["# Native SysML producer/caller containment and proof projection; not an execution schedule.",
             "direction: down", 'domain: ' + json.dumps('ReaderSpanCustody\nModern C / Scheme semantic ownership'),
             'contracts: "Canonical source contracts (containment view)" {', "  grid-columns: 1",
             'producers: "Eight real producer boundaries" {', "  grid-columns: 2"]
    graph += [f"  p{n}: " + json.dumps(v["key"] + "\n" + v["custodian"]) for n, v in enumerate(p["producer"])]
    graph += ["}", 'readers: "Five datum entries + six header I/O bypasses" {', "  grid-columns: 3"]
    graph += [f"  r{n}: " + json.dumps(v["key"] + "\n" + ("body catch" if v["bodyCatch"] else "outside body catch")) for n, v in enumerate(p["reader"])]
    graph += ["}", 'resets: "Two reset paths with distinct consumers" {', "  grid-columns: 2"]
    graph += [f"  x{n}: " + json.dumps(v["key"] + "\n" + v["nextStep"]) for n, v in enumerate(p["reset"])]
    graph += ["}", "}", 'models: ' + json.dumps('RS-H QNT / RS-I Lean\nRS-S source / RS-E native obligations'),
              'ascent: ' + json.dumps('ASCENT\nScoped receipts + LC-S dependency'), 'gate: "Five source/native gates remain open"',
              "domain -> contracts", "contracts -> models", "models -> ascent", "ascent -> gate"]
    (ROOT / DIAGRAM).write_text("\n".join(graph) + "\n")


def inference(p):
    parent = json.loads((PARENT / "input.json").read_text())
    old = {(n["component"], n["obligationId"]): n for n in parent["needs"]}
    needs = [dict(n, component=n["owner"]["componentId"], digest=sha(ROOT / n["subjectPath"])) for n in p["needs"].values()]
    for n in needs:
        if (n["component"], n["obligationId"]) in old:
            previous = old[n["component"], n["obligationId"]]
            assert all(n[k] == previous[k] for k in ["subjectPath", "subjectScope", "digest"])
    deps = [dict(component=d["dependent"]["owner"]["componentId"], obligation=d["dependent"]["obligationId"],
                 prerequisiteComponent=d["prerequisite"]["owner"]["componentId"], prerequisite=d["prerequisite"]["obligationId"])
            for d in p["dependencies"].values()]
    methods = list(p["methods"].values())
    bindings = dict(parent["sourceBindings"])
    for name in list(bindings):
        assert sha(ROOT / name) == bindings[name], f"Retained input drift: {name}"
    for name in [MODEL, DESIGN, MATRIX, DIAGRAM, RULES, QNT, LEAN, PARAM, "dev/modeling/tools/reader-span-study.py"]:
        bindings[name] = sha(ROOT / name)
    save(CACHE / "source-bindings.json", bindings)
    policy = (PARENT / "planner-policy.ss").read_text()
    (CACHE / "planner-policy.ss").write_text(policy)
    bundle, native_hash, dsl_hash = sha(CACHE / "source-bindings.json"), sha(CACHE / "sysml.stdout"), sha(CACHE / "planner-policy.ss")
    claim = TASK + ":" + bundle
    bind_pairs = [["target-model-bundle-sha256", bundle], ["native-output-sha256", native_hash], ["planner-dsl-sha256", dsl_hash]]
    register = ["(define-evidence (register) (sources binding) (outputs clue factor)",
                "(relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))",
                fact("clue", [claim, claim, "support", MODEL])]
    register += [fact("factor", [claim, key, value]) for key, value in bind_pairs]
    request = "((selector " + json.dumps("\n".join(register + [")"])) + ") (constructor \"register\"))"
    try:
        run("register", [str(ROOT / ".venv/bin/gambit-smp"), "--task", TASK, "trajectory", "submit", request])
    except RuntimeError:
        diagnostic = (CACHE / "register.stderr").read_text()
        if 'ValueError: trajectory clue id is already retained' not in diagnostic:
            raise
        # Replaying a refused duplicate is safe only if the later native joins
        # still recover every exact bundle/native/policy-bound modelRequired row.
        save(CACHE / "registration-reuse.json", dict(claim=claim, bindings=bind_pairs,
             condition="Exact native joins and all model/receipt mappings must pass before finalization"))
    parent_result = json.loads((PARENT / "current.json").read_text())["brief"]["association"]
    inherited = {row[2] for row in parent_result["locallyChecked"]}
    outputs = "spanCustody spanExceptionRoute spanMissing spanBlocked spanCandidate"
    policy = policy.rstrip().removesuffix(")").replace("sharedContract sourceRoute)", "sharedContract sourceRoute " + outputs + ")")
    results = {}
    for scenario in ["current", "wrong-scope", "stale-subject", "missing-qnt", "all-scoped-control", "synthetic-gates", "missing-isolation"]:
        forms = [policy, (ROOT / RULES).read_text()]
        forms += [fact("componentFact", [c["componentId"], claim, "ReaderSpanCustody:native-projection"]) for c in p["components"].values()]
        groups = defaultdict(list)
        for n in needs:
            groups[n["component"]].append(n)
        for component, ns in groups.items():
            for group in chunks(ns, 3):
                rows = [[n["obligationId"], n["kind"], n["premise"], n["subjectPath"], n["subjectScope"]] for n in group]
                forms += ([fact("needTripleFact", [component] + sum(rows, []))] if len(group) == 3
                          else [fact("needFact", [component] + row) for row in rows])
        forms += [fact("methodFact", [m["kind"], m["method"], m["requiredCheck"]]) for m in methods]
        groups = defaultdict(list)
        for d in deps:
            groups[d["component"], d["obligation"]].append([d["prerequisiteComponent"], d["prerequisite"]])
        for key, rows in groups.items():
            for group in chunks(rows, 3):
                forms += ([fact("dependencyTripleFact", list(key) + sum(group, []))] if len(group) == 3
                          else [fact("dependencyFact", list(key) + row) for row in group])
        forms.append(fact("scenarioFact", [scenario, "conditional-model-evidence" if scenario == "current" else "inference-control"]))
        for group in chunks(sorted({(n["subjectPath"], n["digest"]) for n in needs}), 7):
            forms += ([fact("availableSubjectSeptFact", [scenario] + [v for row in group for v in row])]
                      if len(group) == 7 else [fact("availableSubjectFact", [scenario, *row]) for row in group])
        receipts = []
        for n in needs:
            if scenario != "all-scoped-control" and n["obligationId"] not in inherited | {"RS-H", "RS-I"}:
                continue
            if scenario == "missing-qnt" and n["obligationId"] == "RS-H":
                continue
            m = next(m for m in methods if m["kind"] == n["kind"])
            receipts.append([n["component"], n["obligationId"], m["method"], n["subjectPath"],
                "stale" if scenario == "stale-subject" and n["obligationId"] == "RS-H" else n["digest"], m["requiredCheck"],
                "wrong" if scenario == "wrong-scope" and n["obligationId"] == "RS-I" else n["subjectScope"]])
        for group in chunks(receipts, 2):
            forms.append(fact("receiptPairFact", [scenario, "pass"] + sum(group, [])) if len(group) == 2
                         else fact("receiptFact", [scenario] + group[0] + ["pass"]))
        forms += [fact("spanProducerFact", [v["key"], v["anchor"], v["custodian"]]) for v in p["span"]["producer"]]
        forms += [fact("spanReaderFact", [v["key"], str(v["bodyCatch"]).lower(), v["consumer"]]) for v in p["span"]["reader"]]
        for gate in p["span"]["gate"]:
            qualified = scenario in {"synthetic-gates", "missing-isolation"} and not(scenario == "missing-isolation" and gate["key"] == "mutable-source-isolation")
            forms.append(fact("spanGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
        forms.append(fact("spanSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-isolation"}).lower()]))
        selector = "\n".join(forms + [")"])
        (CACHE / f"{scenario}.ss").write_text(selector)
        result = support.repository_clues(ROOT, selector=selector, bindings=bind_pairs, scope=TASK, display_bytes=1048576)
        save(CACHE / f"{scenario}.json", result)
        assert result["brief"]["evaluationComplete"] and result["brief"]["presentationComplete"] and not result["brief"]["runtimeAdmitted"]
        results[scenario] = result["brief"]["association"]
    c = results["current"]
    expected = sorted([n["component"], n["obligationId"], m["method"], m["requiredCheck"], n["subjectPath"], n["subjectScope"], n["premise"]]
                      for n in needs for m in methods if m["kind"] == n["kind"])
    assert sorted(row[1:] for row in c["modelRequired"]) == expected
    assert len(c["locallyChecked"]) == 16 and len(c["componentFrontier"]) == 28
    assert len(c["spanCustody"]) == 8 and len(c["spanExceptionRoute"]) == 5
    assert sorted(c["spanCustody"]) == sorted(["current", v["key"], v["anchor"], v["custodian"]] for v in p["span"]["producer"])
    assert sorted(c["spanExceptionRoute"]) == sorted(["current", v["key"],
        "body-parseerror-only" if v["bodyCatch"] else "outside-body-catch", v["consumer"]] for v in p["span"]["reader"])
    assert not c["danglingDependency"] and not c["unboundDependency"] and not c["dependencyCycle"]
    assert len(c["spanMissing"]) == 5 and not c["componentReady"] and not c["spanCandidate"]
    for s in ["wrong-scope", "stale-subject", "missing-qnt"]:
        assert len(results[s]["locallyChecked"]) == 15
    assert len(results["all-scoped-control"]["locallyChecked"]) == 44 and not results["all-scoped-control"]["spanCandidate"]
    assert len(results["synthetic-gates"]["spanCandidate"]) == 1 and not results["missing-isolation"]["spanCandidate"]
    save(CACHE / "input.json", dict(needs=needs, dependencies=deps, sourceBindings=bindings, bundle=bundle,
         nativeHash=native_hash, dslHash=dsl_hash, inheritedReceipts=sorted(inherited)))
    return dict(needs=44, dependencies=43, local=16, frontier=28, componentsClosed=0, scenarios=7, gatesOpen=5)


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    save(EVIDENCE / "checks.json", {"status": "pending", "runtimeAdmitted": False})
    p, native = projection()
    cohort = {name: run("head-" + name, ["git", "-C", path, "rev-parse", "HEAD"]).strip()
              for name, path in [("research", "."), ("gerbil", "../gerbil-gambit-bootstrap-audit"), ("gambit", "vendor/gambit")]}
    save(CACHE / "source-cohort.json", cohort)
    source_census(p["span"])
    views(p["span"])
    tests = run("quint-tests", ["quint", "test", QNT, "--match", "Test$"])
    assert tests.count("ok ") == 21 and tests.count("ControlTest passed") == 10
    for init in ["init", "initHeader"]:
        run("quint-" + init, ["quint", "run", QNT, "--init", init, "--invariant", "safe", "--max-samples", "100", "--max-steps", "80", "--seed", "17", "--verbosity", "1"])
    run("lean", ["lean", LEAN])
    run("d2-svg", ["d2", DIAGRAM, DIAGRAM.removesuffix(".d2") + ".svg"])
    run("d2-png", ["d2", DIAGRAM, str(CACHE / "reader-span-custody.png")])
    org = (PARENT / "check-org.el").read_text().replace(support.DESIGN, DESIGN).replace(support.MATRIX, MATRIX)
    (CACHE / "check-org.el").write_text(org)
    run("org", ["emacs", "--batch", "-Q", "--load", str(CACHE / "check-org.el")])
    summary = inference(p)
    save(CACHE / "checks.json", dict(status="conditional-model-checks-pass", **summary,
         qntHistories=21, qntPositive=11, qntNegativeControls=10, sampledRuns=200, maxSteps=80,
         requestedSeed=17, leanKernels=7, nativeSysmlFields=len(json.loads((CACHE / "native-queries.json").read_text())),
         retainedSysmlWarnings=[d for d in native.get("diagnostics", []) if d.get("severity") == "warning"],
         sourceRefinement="open", runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False,
         pythonOrchestration=True, shellPipeline=False, jqPipeline=False))
    for path in CACHE.iterdir():
        if path.is_file() and path.suffix != ".png":
            (EVIDENCE / path.name).write_bytes(path.read_bytes())
    save(EVIDENCE / "artifacts.json", {str(path.relative_to(ROOT)): sha(path) for path in EVIDENCE.iterdir()
                                      if path.is_file() and path.name != "artifacts.json"})
    print(json.dumps({k: v for k, v in json.loads((CACHE / "checks.json").read_text()).items() if k != "retainedSysmlWarnings"}))


if __name__ == "__main__":
    main()
