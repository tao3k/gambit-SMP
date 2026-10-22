#!/usr/bin/env python3
"""Python transport for native SysML and source-bound research-model evidence.

No language/runtime implementation; no shell, jq or SysML/Scheme parser.
Study metadata describe projection schemas, not a second architecture model.
"""
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import subprocess
import traceback

from gambit_smp import repository_clues

ROOT = Path(__file__).resolve().parents[3]


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def save(path, value):
    Path(path).write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n")


def fact(name, row):
    return " (fact (" + name + " " + " ".join(json.dumps(v) for v in row) + "))"


def chunks(rows, n):
    return [rows[i:i+n] for i in range(0, len(rows), n)]


def execute(s, resume=False):
    cache = ROOT / ".cache/tasks" / s.task
    evidence = ROOT / "evidence/research" / s.task
    parent = ROOT / "evidence/research" / s.parent
    cache.mkdir(parents=True, exist_ok=True)
    evidence.mkdir(parents=True, exist_ok=True)

    def run(name, argv):
        proc = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=60)
        save(cache / f"{name}.command.json", argv)
        (cache / f"{name}.stdout").write_text(proc.stdout)
        (cache / f"{name}.stderr").write_text(proc.stderr)
        if proc.returncode:
            record = dict(argv=argv, exit=proc.returncode, stdout=proc.stdout, stderr=proc.stderr)
            key = hashlib.sha256(json.dumps(record, sort_keys=True).encode()).hexdigest()[:16]
            save(cache / f"{name}.failure-{key}.json", record)
            raise RuntimeError(f"{name} failed; retained diagnostics: {cache}")
        return proc.stdout

    queries = json.loads((parent / "native-queries.json").read_text())
    for group, count, fields in s.groups:
        queries += [(f"detail.{group}.{n}.{field}", f"{s.package}::{group}{n}.{field}")
                    for n in range(count) for field in fields.split()]
    queries += [(f"detail.{field}", f"{s.package}::{field}") for field in s.scalars]
    for slot in ["history", "induction", "source", "platform"]:
        queries += [(f"needs.{s.prefix}-{slot}.{field}", f"{s.package}::{slot}.{field}")
                    for field in "obligationId kind subjectPath subjectScope premise owner.componentId".split()]
    for n in range(4):
        queries += [(f"dependencies.{s.prefix}-{n}.{field}", f"{s.package}::dependency{n}.{field}")
                    for field in "dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId".split()]
    argv = ["sysml", "-strict", "-no-record-cache", "-validate", "-json"]
    for _, expression in queries:
        argv += ["-e", expression]
    native = json.loads(run("sysml", argv + ["dev"]))
    assert native["exit"] == 0 and not native.get("errors")
    assert not any(d["severity"] == "error" for d in native.get("diagnostics", []))
    values = [json.loads(line[4:]) for line in native["output"] if line.startswith("  = ")]
    assert len(values) == len(queries)
    p = {}
    for (key, _), value in zip(queries, values, strict=True):
        node = p
        parts = key.split(".")
        for field in parts[:-1]:
            node = node.setdefault(field, {})
        node[parts[-1]] = value
    for group, _, _ in s.groups:
        p["detail"][group] = list(p["detail"][group].values())
    save(cache / "projection.json", p)
    save(cache / "native-queries.json", queries)
    s.views(p["detail"])
    s.source_checks(cache)
    commands = {"quint-tests": ["quint", "test", s.qnt, "--match", "Test$"], "lean": ["lean", s.lean]}
    for initial in s.inits:
        commands["quint-" + initial] = ["quint", "run", s.qnt, "--init", initial, "--invariant", "safe",
            "--max-samples", "100", "--max-steps", "80", "--seed", "17", "--verbosity", "1"]
    formal_subjects = {name: sha(ROOT / name) for name in [s.model, s.qnt, s.lean, s.param]}
    if resume:
        receipt = json.loads((cache / "formal-receipt.json").read_text())
        assert receipt["subjects"] == formal_subjects and receipt["commands"] == commands
        assert all(sha(cache / name) == h for name, h in receipt["logs"].items())
    else:
        for name, command in commands.items():
            result = run(name, command)
            if name == "quint-tests":
                assert result.count("ok ") == s.histories and result.count("ControlTest passed") == s.controls
        save(cache / "formal-receipt.json", dict(subjects=formal_subjects, commands=commands,
            logs={name + ".stdout": sha(cache / (name + ".stdout")) for name in commands}))
    run("d2-svg", ["d2", s.diagram, s.diagram[:-3] + ".svg"])
    run("d2-png", ["d2", s.diagram, str(cache / "diagram.png")])
    org = (parent / "check-org.el").read_text().replace(s.parent_design, s.design).replace(s.parent_matrix, s.matrix)
    (cache / "check-org.el").write_text(org)
    # Link target exists during validation; it carries no successful result yet.
    save(evidence / "checks.json", dict(status="pending", runtimeAdmitted=False))
    run("org", ["emacs", "--batch", "-Q", "--load", str(cache / "check-org.el")])
    old = json.loads((parent / "input.json").read_text())
    needs = [dict(n, component=n["owner"]["componentId"], digest=sha(ROOT / n["subjectPath"])) for n in p["needs"].values()]
    indexed = {(n["component"], n["obligationId"]): n for n in needs}
    for n in old["needs"]:
        assert all(indexed[n["component"], n["obligationId"]][k] == n[k] for k in ["subjectPath", "subjectScope", "digest"])
    dependencies = [dict(component=d["dependent"]["owner"]["componentId"], obligation=d["dependent"]["obligationId"],
        prerequisiteComponent=d["prerequisite"]["owner"]["componentId"], prerequisite=d["prerequisite"]["obligationId"])
        for d in p["dependencies"].values()]
    bindings = dict(old["sourceBindings"])
    assert all(sha(ROOT / path) == digest for path, digest in bindings.items()), "Ancestor input drift"
    for path in s.artifacts + s.sources:
        bindings[path] = sha(ROOT / path)
    save(cache / "source-bindings.json", bindings)
    policy = (parent / "planner-policy.ss").read_text()
    (cache / "planner-policy.ss").write_text(policy)
    bundle, nh, dh = sha(cache / "source-bindings.json"), sha(cache / "sysml.stdout"), sha(cache / "planner-policy.ss")
    claim = s.task + ":" + bundle
    bind_pairs = [["target-model-bundle-sha256", bundle], ["native-output-sha256", nh], ["planner-dsl-sha256", dh]]
    register = ["(define-evidence (register) (sources binding) (outputs clue factor)",
        "(relation binding (name value)) (relation clue (id claim polarity source)) (relation factor (id name value))",
        fact("clue", [claim, claim, "support", s.model])]
    register += [fact("factor", [claim, key, value]) for key, value in bind_pairs]
    request = "((selector " + json.dumps("\n".join(register + [")"])) + ") (constructor \"register\"))"
    try:
        run("register", [str(ROOT / ".venv/bin/gambit-smp"), "--task", s.task, "trajectory", "submit", request])
    except RuntimeError:
        assert 'ValueError: trajectory clue id is already retained' in (cache / "register.stderr").read_text()
        # Exact bundle/native/policy joins below must still recover every need.
    prior = json.loads((parent / "current.json").read_text())["brief"]["association"]
    checked = {row[2] for row in prior["locallyChecked"]} | {s.prefix + "-H", s.prefix + "-I"}
    methods = list(p["methods"].values())
    policy = policy.rstrip().removesuffix(")").replace("sharedContract sourceRoute)", "sharedContract sourceRoute " + s.outputs + ")")
    results = {}
    for scenario in ["current", "wrong-scope", "stale-subject", "missing-qnt", "all-scoped-control", "synthetic-gates", "missing-release"]:
        forms = [policy, (ROOT / s.rules).read_text()]
        forms += [fact("componentFact", [c["componentId"], claim, s.package + ":native-projection"]) for c in p["components"].values()]
        grouped = defaultdict(list)
        for n in needs:
            grouped[n["component"]].append([n["obligationId"], n["kind"], n["premise"], n["subjectPath"], n["subjectScope"]])
        for component, rows in grouped.items():
            for g in chunks(rows, 3):
                forms += [fact("needTripleFact", [component] + sum(g, []))] if len(g) == 3 else [fact("needFact", [component] + row) for row in g]
        forms += [fact("methodFact", [m["kind"], m["method"], m["requiredCheck"]]) for m in methods]
        grouped = defaultdict(list)
        for d in dependencies:
            grouped[d["component"], d["obligation"]].append([d["prerequisiteComponent"], d["prerequisite"]])
        for key, rows in grouped.items():
            for g in chunks(rows, 3):
                forms += [fact("dependencyTripleFact", list(key) + sum(g, []))] if len(g) == 3 else [fact("dependencyFact", list(key) + row) for row in g]
        forms.append(fact("scenarioFact", [scenario, "conditional-model-receipts" if scenario == "current" else "inference-control"]))
        for g in chunks(sorted({(n["subjectPath"], n["digest"]) for n in needs}), 7):
            forms += [fact("availableSubjectSeptFact", [scenario] + [v for row in g for v in row])] if len(g) == 7 else [fact("availableSubjectFact", [scenario, *row]) for row in g]
        rows = []
        for n in needs:
            if (scenario != "all-scoped-control" and n["obligationId"] not in checked) or (scenario == "missing-qnt" and n["obligationId"] == s.prefix + "-H"):
                continue
            m = next(m for m in methods if m["kind"] == n["kind"])
            rows.append([n["component"], n["obligationId"], m["method"], n["subjectPath"],
                "stale" if scenario == "stale-subject" and n["obligationId"] == s.prefix + "-H" else n["digest"], m["requiredCheck"],
                "wrong" if scenario == "wrong-scope" and n["obligationId"] == s.prefix + "-I" else n["subjectScope"]])
        for g in chunks(rows, 2):
            forms.append(fact("receiptPairFact", [scenario, "pass"] + sum(g, [])) if len(g) == 2 else fact("receiptFact", [scenario] + g[0] + ["pass"]))
        forms += s.facts(p["detail"], scenario)
        selector = "\n".join(forms + [")"])
        (cache / (scenario + ".ss")).write_text(selector)
        for attempt in range(3):
            try:
                result = repository_clues(ROOT, selector=selector, bindings=bind_pairs, scope=s.task, display_bytes=1048576)
                break
            except ValueError as error:
                (cache / f"{scenario}.stale-{attempt}.txt").write_text(traceback.format_exc())
                if 'trajectory action source changed:' not in str(error) or attempt == 2:
                    raise
        save(cache / (scenario + ".json"), result)
        assert result["brief"]["evaluationComplete"] and result["brief"]["presentationComplete"] and not result["brief"]["runtimeAdmitted"]
        results[scenario] = result["brief"]["association"]
    c = results["current"]
    expected = sorted([n["component"], n["obligationId"], m["method"], m["requiredCheck"], n["subjectPath"], n["subjectScope"], n["premise"]]
                      for n in needs for m in methods if m["kind"] == n["kind"])
    assert sorted(row[1:] for row in c["modelRequired"]) == expected
    assert len(c["locallyChecked"]) == len(checked) and len(c["componentFrontier"]) == len(needs) - len(checked)
    assert not c["componentReady"] and not c["danglingDependency"] and not c["unboundDependency"] and not c["dependencyCycle"]
    for scenario in ["wrong-scope", "stale-subject", "missing-qnt"]:
        assert len(results[scenario]["locallyChecked"]) == len(checked) - 1
    assert len(results["all-scoped-control"]["locallyChecked"]) == len(needs)
    s.check_inference(p["detail"], results)
    assert all(sha(ROOT / path) == digest for path, digest in bindings.items()), "Inputs changed during study"
    save(cache / "input.json", dict(needs=needs, dependencies=dependencies, sourceBindings=bindings, bundle=bundle, nativeHash=nh, dslHash=dh))
    save(cache / "checks.json", dict(status="conditional-model-checks-pass", needs=len(needs), dependencies=len(dependencies),
        local=len(checked), frontier=len(needs)-len(checked), componentsClosed=0, gatesOpen=len(p["detail"]["gate"]),
        qntHistories=s.histories, qntNegativeControls=s.controls, leanKernels=s.kernels, sampledRuns=100*len(s.inits),
        maxSteps=80, requestedSeed=17, nativeSysmlFields=len(queries), scenarios=len(results), formalToolsResumed=resume,
        sourceRefinement="open", runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False,
        retainedSysmlWarnings=[d for d in native.get("diagnostics", []) if d["severity"] == "warning"]))
    for path in cache.iterdir():
        if path.is_file() and path.suffix != ".png":
            (evidence / path.name).write_bytes(path.read_bytes())
    save(evidence / "artifacts.json", {str(path.relative_to(ROOT)): sha(path) for path in evidence.iterdir() if path.is_file() and path.name != "artifacts.json"})
    print(json.dumps({k: v for k, v in json.loads((cache / "checks.json").read_text()).items() if k != "retainedSysmlWarnings"}))
