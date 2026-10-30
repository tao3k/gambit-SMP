#!/usr/bin/env python3
"""Scoped research checks: Python -> native SysML -> ASCENT -> QNT/Lean.

No runtime compilation/execution. No shell, jq, SysML parser or Scheme parser.
The retained ancestor projection and policy are evidence inputs, not new authority.
"""
from __future__ import annotations

import hashlib
import json
import os
from pathlib import Path
import subprocess

from gambit_smp import repository_clues

ROOT = Path(__file__).resolve().parents[3]
TASK = "logical-cursor-contract"
CACHE = ROOT / ".cache/tasks" / TASK
EVIDENCE = ROOT / "evidence/research" / TASK
PARENT = ROOT / "evidence/research/ebnf-cursor-handoff"
MODEL = "dev/architecture/toolchain/models/sysml/logical-cursor.sysml"
DESIGN = "dev/architecture/toolchain/logical-cursor-design.org"
MATRIX = "dev/architecture/toolchain/logical-cursor-matrix.org"
DIAGRAM = "dev/architecture/toolchain/diagrams/logical-cursor.d2"
RULES = "dev/modeling/ascent/logical-cursor.rules.scm"
QNT = "models/build/logical_cursor.qnt"
PARAMETERS = "models/build/logical_cursor_parameters.qnt"
LEAN = "models/build/LogicalCursor.lean"


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def save(path: Path, value: object) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def run(name: str, argv: list[str], *, env=None) -> str:
    completed = subprocess.run(argv, cwd=ROOT, env=env, capture_output=True,
                               text=True, timeout=60, check=False)
    save(CACHE / f"{name}.command.json", argv)
    (CACHE / f"{name}.stdout").write_text(completed.stdout)
    (CACHE / f"{name}.stderr").write_text(completed.stderr)
    if completed.returncode:
        failure = CACHE / f"{name}.failure-{hashlib.sha256(completed.stdout.encode()).hexdigest()[:12]}.json"
        save(failure, dict(argv=argv, exit=completed.returncode, stdout=completed.stdout, stderr=completed.stderr))
        raise RuntimeError(f"{name}: exit {completed.returncode}; retained logs in {CACHE}")
    return completed.stdout


def native_projection() -> dict:
    # Re-evaluate retained native expressions, not a hand-translated SysML model.
    queries = [tuple(line.split("\t")) for line in (PARENT / "queries.tsv").read_text().splitlines()]
    for group, count, fields in [
        ("facet", 6, "key semantic anchor rule"),
        ("gate", 6, "key qualified rule"),
        ("retirement", 3, "key anchor condition avoided added"),
    ]:
        for n in range(count):
            for field in fields.split():
                queries.append((f"logical.{group}.{n}.{field}", f"LogicalCursor::{group}{n}.{field}"))
    for field in ["actualAdmitted", "fixtureChars"]:
        queries.append((f"logical.{field}", f"LogicalCursor::{field}"))
    for slot in ["history", "induction", "source", "platform"]:
        for field in "obligationId kind subjectPath subjectScope premise owner.componentId".split():
            queries.append((f"needs.logical-{slot}.{field}", f"LogicalCursor::{slot}.{field}"))
    for n in range(4):
        for field in "dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId".split():
            queries.append((f"dependencies.logical-{n}.{field}", f"LogicalCursor::dependency{n}.{field}"))
    argv = ["sysml", "-strict", "-no-record-cache", "-validate", "-json"]
    for _, expression in queries:
        argv.extend(["-e", expression])
    result = json.loads(run("sysml", argv + ["dev"]))
    assert result.get("exit") == 0 and not result.get("errors"), result
    assert not any(d.get("severity") == "error" for d in result.get("diagnostics", [])), result
    values = [json.loads(line.removeprefix("  = ")) for line in result["output"] if line.startswith("  = ")]
    assert len(values) == len(queries)
    # Numeric path components are handled as dictionary keys until final conversion.
    projection = {}
    for (key, _), value in zip(queries, values, strict=True):
        target = projection
        parts = key.split(".")
        for part in parts[:-1]:
            target = target.setdefault(part, {})
        target[parts[-1]] = value
    for group in ["facet", "gate", "retirement"]:
        projection["logical"][group] = list(projection["logical"][group].values())
    save(CACHE / "projection.json", projection)
    save(CACHE / "native-queries.json", queries)
    return projection


def views(p: dict) -> None:
    (ROOT / PARAMETERS).write_text(
        "// Derived only from native LogicalCursor scalar evaluation.\n"
        f"module logical_cursor_parameters {{\n  pure val FixtureChars = {p['fixtureChars']}\n}}\n")
    lines = ["#+TITLE: Logical Cursor Closure and Net-Benefit Matrix",
             "#+SETUPFILE: ../../modeling/org/setup.org", "#+PROPERTY: header-args :eval never", "",
             "* RESEARCH Native SysML projection", ":PROPERTIES:", ":CUSTOM_ID: logical-cursor-matrix",
             ":AUTHORITY: LogicalCursor", ":END:", "",
             "Generated by the Python study runner. All gates remain source/native-open.", "",
             "| Facet | Semantics | Source | Contract |", "|---+---+---+---|"]
    lines.extend(f"| {x['key']} | {x['semantic']} | {x['anchor']} | {x['rule']} |" for x in p["facet"])
    lines.extend(["", "** Admission / closure", "", "| Gate | Qualified | Remaining obligation |", "|---+---+---|"])
    lines.extend(f"| {x['key']} | {str(x['qualified']).lower()} | {x['rule']} |" for x in p["gate"])
    lines.extend(["", "** Net benefit and retirement", "", "| Path | Retirement condition | Avoided work / value | Added cost |", "|---+---+---+---|"])
    lines.extend(f"| {x['key']} | {x['condition']} | {x['avoided']} | {x['added']} |" for x in p["retirement"])
    lines.extend(["", "Modern C and Zig both require the listed semantic/native supports. No uniquely Zig net gain is established.",
                  "The constructor saving is the same source-call upper bound retained in the prior study; do not double count it.", ""])
    (ROOT / MATRIX).write_text("\n".join(lines))
    lines = ["# Native SysML containment/qualification projection; no invented execution ordering.",
             "direction: down", 'domain: ' + json.dumps('LogicalCursor\nScheme semantics / modern C lifetime support'),
             'gates: ' + json.dumps('Source/native qualification\nAll six gates remain open'),
             'models: ' + json.dumps('LC-H QNT / LC-I Lean\nLC-S simulation / LC-E native adapter'),
             'ascent: ' + json.dumps('ASCENT\nScoped receipts + dependency frontier'),
             'domain -> models', 'models -> ascent', 'ascent -> gates']
    for n, facet in enumerate(p["facet"]):
        lines.extend([f"f{n}: " + json.dumps(facet["key"] + "\n" + facet["semantic"]), f"domain -> f{n}"])
    for n, retirement in enumerate(p["retirement"]):
        lines.extend([f"r{n}: " + json.dumps(retirement["key"] + "\nConditional retirement"), f"gates -> r{n}"])
    (ROOT / DIAGRAM).write_text("\n".join(lines) + "\n")


def fact(relation: str, values: list[str]) -> str:
    return " (fact (" + relation + " " + " ".join(json.dumps(x, ensure_ascii=False) for x in values) + "))"


def chunks(rows: list, count: int):
    return (rows[i:i + count] for i in range(0, len(rows), count))


def inference(projection: dict) -> dict:
    previous = json.loads((PARENT / "input.json").read_text())
    old = {(n["component"], n["obligationId"]): n for n in previous["needs"]}
    methods = list(projection["methods"].values())
    needs = []
    for need in projection["needs"].values():
        n = dict(need, component=need["owner"]["componentId"], digest=sha(ROOT / need["subjectPath"]))
        if (n["component"], n["obligationId"]) in old:
            retained = old[n["component"], n["obligationId"]]
            assert all(n[k] == retained[k] for k in ["subjectPath", "subjectScope", "digest"]), "Ancestor identity drift"
        needs.append(n)
    dependencies = [dict(component=d["dependent"]["owner"]["componentId"], obligation=d["dependent"]["obligationId"],
                         prerequisiteComponent=d["prerequisite"]["owner"]["componentId"], prerequisite=d["prerequisite"]["obligationId"])
                    for d in projection["dependencies"].values()]
    policy = (PARENT / "planner-policy.ss").read_text()
    assert hashlib.sha256(policy.encode()).hexdigest() == "2df360ae4ecc6e1ce2fd407d75f3522a750466e054b53aa434573c54c00e235c"
    (CACHE / "planner-policy.ss").write_text(policy)
    artifacts = {n["subjectPath"] for n in needs} | {MODEL, RULES, PARAMETERS, DIAGRAM, MATRIX,
                  "dev/modeling/tools/logical-cursor-study.py"}
    bindings = {name: sha(ROOT / name) for name in sorted(artifacts)}
    # Bind the actual source bytes, not only the design document that cites them.
    source_names = ["std/text/parser/base.ss", "std/text/parser/ebnf/lexer.ss", "std/text/parser/ebnf/stream.ss",
                    "std/text/parser/ebnf/lang-reader.ss", "std/text/parser/ebnf/deflexer.ss",
                    "std/text/parser/ebnf/defparser.ss", "gerbil/runtime/syntax.ss", "gerbil/expander/module.ss"]
    for name in source_names:
        path = "../gerbil-gambit-bootstrap-audit/src/" + name
        bindings[path] = sha(ROOT / path)
    for path in ["vendor/gambit/lib/_thread.scm", "vendor/gambit/lib/_io.scm"]:
        bindings[path] = sha(ROOT / path)
    save(CACHE / "source-bindings.json", bindings)
    bundle = sha(CACHE / "source-bindings.json")
    native_hash = sha(CACHE / "sysml.stdout")
    dsl_hash = hashlib.sha256(policy.encode()).hexdigest()
    claim = TASK + ":" + bundle
    registers = ["(define-evidence (register) (sources binding) (outputs clue factor)",
                 "(relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))",
                 fact("clue", [claim, claim, "support", MODEL])]
    bind_pairs = [["target-model-bundle-sha256", bundle], ["native-output-sha256", native_hash], ["planner-dsl-sha256", dsl_hash]]
    registers += [fact("factor", [claim, key, value]) for key, value in bind_pairs]
    request = "((selector " + json.dumps("\n".join(registers + [")"])) + ") (constructor \"register\"))"
    run("register", [str(ROOT / ".venv/bin/gambit-smp"), "--task", TASK, "trajectory", "submit", request])
    inherited = {row[2] for row in json.loads((PARENT / "current.json").read_text())["locallyChecked"]}
    outputs = "logicalFacet logicalMissing logicalRepair logicalBlocked logicalCandidate"
    policy = policy.rstrip().removesuffix(")").replace("sharedContract sourceRoute)", "sharedContract sourceRoute " + outputs + ")")
    results = {}
    for scenario in ["current", "wrong-scope", "stale-subject", "missing-qnt", "all-scoped-control", "synthetic-gates", "missing-lifetime"]:
        forms = [policy, (ROOT / RULES).read_text()]
        forms += [fact("componentFact", [c["componentId"], claim, "LogicalCursor:native-projection"])
                  for c in projection["components"].values()]
        for component in sorted({n["component"] for n in needs}):
            for group in chunks([n for n in needs if n["component"] == component], 3):
                if len(group) == 3:
                    forms.append(fact("needTripleFact", [component] + [v for n in group for v in
                        [n["obligationId"], n["kind"], n["premise"], n["subjectPath"], n["subjectScope"]]]))
                else:
                    forms += [fact("needFact", [component, n["obligationId"], n["kind"], n["premise"], n["subjectPath"], n["subjectScope"]]) for n in group]
        forms += [fact("methodFact", [m["kind"], m["method"], m["requiredCheck"]]) for m in methods]
        for group in chunks(dependencies, 1):
            d = group[0]
            forms.append(fact("dependencyFact", [d["component"], d["obligation"], d["prerequisiteComponent"], d["prerequisite"]]))
        forms.append(fact("scenarioFact", [scenario, "inference-control" if scenario != "current" else "scoped-formal-receipts"]))
        subjects = sorted({(n["subjectPath"], n["digest"]) for n in needs})
        for group in chunks(subjects, 7):
            forms += ([fact("availableSubjectSeptFact", [scenario] + [v for pair in group for v in pair])]
                      if len(group) == 7 else [fact("availableSubjectFact", [scenario, *pair]) for pair in group])
        receipts = []
        for n in needs:
            if scenario != "all-scoped-control" and n["obligationId"] not in inherited | {"LC-H", "LC-I"}:
                continue
            if scenario == "missing-qnt" and n["obligationId"] == "LC-H":
                continue
            m = next(m for m in methods if m["kind"] == n["kind"])
            receipts.append([n["component"], n["obligationId"], m["method"], n["subjectPath"],
                "stale-control" if scenario == "stale-subject" and n["obligationId"] == "LC-H" else n["digest"],
                m["requiredCheck"], "wrong-control" if scenario == "wrong-scope" and n["obligationId"] == "LC-I" else n["subjectScope"]])
        for group in chunks(receipts, 2):
            forms.append(fact("receiptPairFact", [scenario, "pass"] + group[0] + group[1]) if len(group) == 2
                         else fact("receiptFact", [scenario] + group[0] + ["pass"]))
        for facet in projection["logical"]["facet"]:
            forms.append(fact("logicalFacetFact", [facet["key"], facet["semantic"], facet["anchor"]]))
        for gate in projection["logical"]["gate"]:
            qualified = scenario in {"synthetic-gates", "missing-lifetime"} and not(
                scenario == "missing-lifetime" and gate["key"] == "continuation-lifetime")
            forms.append(fact("logicalGateFact", [scenario, gate["key"], str(qualified or gate["qualified"]).lower()]))
        forms.append(fact("logicalSourceFact", [scenario, str(scenario in {"synthetic-gates", "missing-lifetime"}).lower()]))
        selector = "\n".join(forms + [")"])
        (CACHE / f"{scenario}.ss").write_text(selector)
        result = repository_clues(ROOT, selector=selector, bindings=bind_pairs, scope=TASK, display_bytes=1048576)
        save(CACHE / f"{scenario}.json", result)
        assert result["brief"]["evaluationComplete"] and result["brief"]["presentationComplete"]
        assert not result["brief"]["runtimeAdmitted"]
        results[scenario] = result["brief"]["association"]
    current = results["current"]
    expected = sorted([n["component"], n["obligationId"], m["method"], m["requiredCheck"], n["subjectPath"], n["subjectScope"], n["premise"]]
                      for n in needs for m in methods if m["kind"] == n["kind"])
    assert sorted(row[1:] for row in current["modelRequired"]) == expected
    assert len(current["locallyChecked"]) == 14 and len(current["componentFrontier"]) == 26
    assert not current["componentReady"] and len(current["logicalMissing"]) == 6
    assert len(current["logicalRepair"]) == 1 and not current["logicalCandidate"]
    for scenario in ["wrong-scope", "stale-subject", "missing-qnt"]:
        assert len(results[scenario]["locallyChecked"]) == 13
    assert len(results["all-scoped-control"]["locallyChecked"]) == 40
    assert not results["all-scoped-control"]["logicalCandidate"]
    assert len(results["synthetic-gates"]["logicalCandidate"]) == 1
    assert not results["missing-lifetime"]["logicalCandidate"]
    save(CACHE / "input.json", dict(needs=needs, dependencies=dependencies, sourceBindings=bindings,
                                   nativeHash=native_hash, dslHash=dsl_hash, bundle=bundle, inheritedReceipts=sorted(inherited)))
    return dict(needs=len(needs), dependencies=len(dependencies), local=14, frontier=26,
                componentsClosed=0, scenarios=len(results), gatesOpen=6, runtimeAdmitted=False)


def main() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    EVIDENCE.mkdir(parents=True, exist_ok=True)
    # Place a pending receipt before Org file-link validation; replace only after checks.
    save(EVIDENCE / "checks.json", {"status": "pending", "runtimeAdmitted": False})
    p = native_projection()
    views(p["logical"])
    tests = run("quint-tests", ["quint", "test", QNT, "--match", "Test$"])
    run("quint-invariant", ["quint", "run", QNT, "--invariant", "safe", "--max-samples", "100", "--max-steps", "80", "--seed", "17", "--verbosity", "1"])
    run("lean", ["lean", LEAN])
    # Native render is a documentation check, never a runtime/native program test.
    run("d2-svg", ["d2", DIAGRAM, DIAGRAM.removesuffix(".d2") + ".svg"])
    run("d2-png", ["d2", DIAGRAM, str(CACHE / "logical-cursor.png")])
    # Use Org's actual parser. Python orchestrates; it does not parse Org markup.
    files = [DESIGN, MATRIX, "dev/architecture/toolchain/index.org"]
    org = '''(require 'org)
(require 'org-element)
(setq enable-local-variables nil)
(let ((files 'FILES) (links 0) (missing nil))
 (dolist (file files)
  (with-temp-buffer
   (setq buffer-file-name (expand-file-name file))
   (setq default-directory (file-name-directory buffer-file-name))
   (insert-file-contents buffer-file-name)
   (org-mode)
   (org-element-map (org-element-parse-buffer) 'link
    (lambda (link)
     (when (equal (org-element-property :type link) "file")
      (setq links (1+ links))
      (let ((target (expand-file-name (org-element-property :path link))))
       (unless (file-exists-p target) (push (list file target) missing))))))))
 (princ (format "Org parsed: %d files; %d links; missing=%S; no Babel executed" (length files) links missing))
 (when missing (kill-emacs 1)))
'''.replace("FILES", "(" + " ".join(json.dumps(f) for f in files) + ")")
    (CACHE / "check-org.el").write_text(org)
    run("org", ["emacs", "--batch", "-Q", "--load", str(CACHE / "check-org.el")])
    summary = inference(p)
    assert tests.count("ok ") == 16 and tests.count("ControlTest passed") == 8
    diagnostics = json.loads((CACHE / "sysml.stdout").read_text()).get("diagnostics", [])
    save(CACHE / "checks.json", dict(status="conditional-model-checks-pass", **summary,
         qntHistories=16, qntPositive=8, qntNegativeControls=8,
         sampledRuns=100, maxSteps=80, seed=17, leanKernels=7,
         sourceRefinement="open", nativeTestsRun=False, performanceTestsRun=False,
         pythonOrchestration=True, shellPipeline=False, jqPipeline=False,
         nativeSysmlFields=len(json.loads((CACHE / "native-queries.json").read_text())),
         retainedSysmlWarnings=[d for d in diagnostics if d.get("severity") == "warning"]))
    for path in CACHE.iterdir():
        if path.is_file() and path.suffix != ".png":
            (EVIDENCE / path.name).write_bytes(path.read_bytes())
    retained = {str(path.relative_to(ROOT)): sha(path) for path in EVIDENCE.iterdir()
                if path.is_file() and path.name != "artifacts.json"}
    save(EVIDENCE / "artifacts.json", retained)
    print(json.dumps(json.loads((EVIDENCE / "checks.json").read_text())))


if __name__ == "__main__":
    main()
