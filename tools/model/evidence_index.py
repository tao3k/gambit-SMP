#!/usr/bin/env python3
"""Digest-bound fact export and Datalog coverage queries, never release admission."""
import argparse
from graphlib import CycleError, TopologicalSorter
import json
from pathlib import Path

from check_gambit import digest

ROOT = Path(__file__).resolve().parents[2]
QUERIES = {
    "model_contexts_without_report_snapshot": "context_needs_report(M, P)",
    "reports_without_models": "needs_model(P)",
    "models_without_native_adapters": "needs_native(M)",
    "dependency_closure": "dependency_path(P, D)",
    "shared_obligations": "shared_obligation(P, D, M)",
}


def export(root=ROOT):
    directory = root / "models/gambit"
    manifest = json.loads((directory / "cases.json").read_text())
    catalog = json.loads((directory / "report_catalog.json").read_text())
    cases = {case["id"]: case for case in manifest["cases"]}
    if len(cases) != len(manifest["cases"]):
        raise ValueError("duplicate model identity")
    facts = {name: [] for name in ("pr", "pr_model", "dependency", "model",
             "source_obligation", "native_adapter", "frozen_negative", "unresolved", "model_context_pr")}
    inputs = {}
    def bind(path):
        inputs[str(path.relative_to(root))] = digest(path)
    bind(directory / "cases.json")
    bind(directory / "report_catalog.json")
    seen = set()
    for report in catalog["reports"]:
        number = report["number"]
        if type(number) is not int or number in seen:
            raise ValueError("invalid or duplicate PR identity")
        seen.add(number)
        facts["pr"].append([number, report["headRefOid"], report["status"]])
        for model in report["models"]:
            if model not in cases:
                raise ValueError("unknown report model: " + model)
            facts["pr_model"].append([number, model])
        facts["dependency"].extend([number, dep] for dep in report["dependencies"])
    for name, case in cases.items():
        facts["model_context_pr"].append([name, case["pr"]])
        if case["pr"] in seen:
            facts["pr_model"].append([case["pr"], name])
        path = directory / (name + ".qnt")
        bind(path)
        facts["model"].append([name, digest(path), case.get("mode", "repair-obligation")])
        facts["source_obligation"].extend([name, source] for source in case["source"])
        if case["native"]:
            fixture = directory / "native" / case["native"]
            bind(fixture)
            facts["native_adapter"].append([name, case["native"]])
    for path in sorted((directory / "counterexamples").glob("*.json")):
        trace = json.loads(path.read_text())
        name = trace["case"]
        if name not in cases or trace["modelSha256"] != digest(directory / (name + ".qnt")):
            raise ValueError("stale or unknown frozen trace: " + path.name)
        bind(path)
        facts["frozen_negative"].append([name, trace.get("invariant", "safe"), digest(path)])
    for item in manifest["unresolved"]:
        facts["unresolved"].append([item.get("pr", 0), item["failure"], item["status"]])
    return {"schema": "gambit-smp-relations.v1", "sourceRevision": manifest["sourceRevision"],
            "evidenceBoundary": "coverage-index-only-not-correctness-or-release-admission",
            "inputs": dict(sorted(inputs.items())),
            "facts": {name: sorted({tuple(row) for row in rows}) for name, rows in facts.items()}}


def query(facts, rules):
    graph = {}
    for parent, child in facts["dependency"]:
        graph.setdefault(parent, set()).add(child)
    try:
        tuple(TopologicalSorter(graph).static_order())
    except CycleError as error:
        raise ValueError("cyclic PR dependency; audit before querying") from error
    from pyDatalog import pyDatalog
    pyDatalog.clear()
    # Register empty predicates too, so missing evidence queries remain defined.
    arities = {"pr": 3, "pr_model": 2, "dependency": 2, "model": 3,
               "source_obligation": 2, "native_adapter": 2, "frozen_negative": 3, "unresolved": 3,
               "model_context_pr": 2}
    for name, arity in arities.items():
        sentinel = tuple("__empty_relation__" for _ in range(arity))
        pyDatalog.assert_fact(name, *sentinel)
        pyDatalog.retract_fact(name, *sentinel)
        for row in facts[name]:
            pyDatalog.assert_fact(name, *row)
    pyDatalog.load(rules)
    results = {}
    for name, expression in QUERIES.items():
        result = pyDatalog.ask(expression)
        results[name] = sorted(result.answers) if result else []
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--refresh", action="store_true")
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--out", type=Path)
    args = parser.parse_args()
    current = export()
    path = ROOT / "evidence/relations.json"
    serialized = json.dumps(current, indent=2) + "\n"
    if args.refresh:
        path.write_text(serialized)
        print("FACT-EXPORT-OK")
        return
    if not path.is_file() or path.read_text() != serialized:
        raise ValueError("stale fact export; audit inputs before --refresh")
    rules = ROOT / "evidence/rules.dl"
    results = query(current["facts"], rules.read_text())
    receipt = {"schema": "gambit-smp-query.v1", "diagnosticOnly": True,
               "factsSha256": digest(path), "rulesSha256": digest(rules), "queries": results}
    if args.out:
        args.out.mkdir(parents=True, exist_ok=False)
        (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({name: len(rows) for name, rows in results.items()}, sort_keys=True))
    print("DATALOG-COVERAGE-OK")


if __name__ == "__main__":
    main()
