#!/usr/bin/env python3
"""Digest-bound fact export and Datalog coverage queries, never release admission."""
import argparse
import hashlib
from graphlib import CycleError, TopologicalSorter
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest

QUERIES = {
    "reports_without_snapshots": "needs_snapshot(P)",
    "model_contexts_without_report_snapshot": "context_needs_report(M, P)",
    "reports_without_models": "needs_model(P)",
    "models_without_native_adapters": "needs_native(M)",
    "dependency_closure": "dependency_path(P, D)",
    "shared_obligations": "shared_obligation(P, D, M)",
    "source_overlap_review_open": "triage_open(P)",
    "reported_failure_records": "reported_failure(P, F, S)",
    "local_assertions_without_models": "local_needs_model(F)",
    "local_environment_failures": "local_environment(F)",
    "local_budget_denials": "local_budget(F)",
    "local_passing_controls": "local_control_pass(F, K, M, D)",
    "local_budget_without_passing_controls": "local_budget_uncontrolled(F)",
    "local_signal_denials": "local_signal(F)",
    "paper_guided_models": "model_paper(M, P, S)",
    "model_contract_dependencies": "contract_path(M, D)",
    "paper_guided_models_without_native_adapters": "paper_needs_native(M)",
    "contract_dependencies_without_native_adapters": "contract_needs_native(M, D)",
    "recorded_model_admissions": "model_receipt(M, H, E)",
    "contract_dependencies_without_model_receipts": "contract_needs_receipt(M, D)",
    "recorded_source_unit_observations": "source_unit_observation(M, K, R, L)",
    "explicit_progress_obligations": "model_progress_obligation(M, H, S)",
    "recorded_progress_checks": "model_progress_checked(M, R)",
    "progress_obligations_without_checks": "progress_needs_check(M)",
    "protocol_extensions": "protocol_model(M, H)",
    "recorded_protocol_checks": "protocol_checked(M, R)",
    "protocol_extensions_without_checks": "protocol_needs_check(M)",
}


def admitted_control(denied, control, file, mode, output):
    from gambit_smp.native_suite import admitted_suite
    fields = ("candidateReceiptSha256", "gsiSha256", "gscSha256", "sourceFiles",
              "extraFixtures", "processors", "minHeapKiBControl", "compiler", "selectedFiles", "wholeSuiteBudgetPerMode")
    rows = [row for row in control.get("results", []) if row.get("mode") == mode]
    return (denied.get("status") == "DENY" and control.get("status") == "PASS"
            and denied.get("schema") == control.get("schema") == "gambit-upstream-suite.v1"
            and all(field in denied and field in control and denied[field] == control[field] for field in fields)
            and denied.get("buildDriver") == control.get("buildDriver")
            and denied.get("adapterSources") == control.get("adapterSources")
            and denied.get("fixturePatches", []) == control.get("fixturePatches", [])
            and denied.get("jobs", 1) == control.get("jobs", 1) == 1
            and control.get("selectedFiles") == [file] and control.get("filesPerMode") == 1
            and any(row.get("mode") == mode and row.get("accepted") is False for row in denied.get("results", []))
            and len(rows) == 1 and rows[0].get("accepted") is True and rows[0].get("sourceStable") is True
            and rows[0].get("timeout") is False
            and admitted_suite(rows[0].get("exit"), output, rows[0].get("timeout"), 1))


def export(root=ROOT):
    directory = root / "models/gambit"
    manifest = json.loads((directory / "cases.json").read_text())
    catalog = json.loads((directory / "report_catalog.json").read_text())
    cases = {case["id"]: case for case in manifest["cases"]}
    if len(cases) != len(manifest["cases"]):
        raise ValueError("duplicate model identity")
    facts = {name: [] for name in ("pr", "pr_model", "dependency", "model",
             "source_obligation", "native_adapter", "frozen_negative", "unresolved", "model_context_pr",
             "report_kind", "report_snapshot", "window_disposition", "reported_failure", "source_unit_fixture", "source_unit_observation", "native_observation", "local_native_failure", "local_failure_model", "local_control_pass", "paper", "model_paper", "model_contract", "model_receipt",
             "model_progress_obligation", "model_progress_checked", "protocol_model", "protocol_composes", "protocol_source", "protocol_paper", "protocol_control", "protocol_checked")}
    inputs = {}
    def bind(path):
        inputs[str(path.relative_to(root))] = digest(path)
    bind(directory / "cases.json")
    bind(directory / "report_catalog.json")
    paper_path = root / "evidence/papers.json"
    papers = json.loads(paper_path.read_text())["papers"] if paper_path.is_file() else []
    paper_ids = {paper["id"] for paper in papers}
    if len(paper_ids) != len(papers):
        raise ValueError("duplicate paper identity")
    if papers:
        bind(paper_path)
    facts["paper"].extend([paper["id"], paper["url"]] for paper in papers)
    contract_graph = {}
    for name, case in cases.items():
        targets = [contract["model"] for contract in case.get("contracts", [])]
        if len(targets) != len(set(targets)) or any(target not in cases for target in targets):
            raise ValueError("duplicate or unknown model contract")
        contract_graph[name] = set(targets)
    try:
        tuple(TopologicalSorter(contract_graph).static_order())
    except CycleError as error:
        raise ValueError("cyclic model contracts") from error
    if "nativeFailureManifest" in manifest:
        path = (root / manifest["nativeFailureManifest"]).resolve()
        path.relative_to(root.resolve())
        bind(root / manifest["nativeFailureManifest"])
        local_seen = set()
        for row in json.loads(path.read_text())["failures"]:
            if row["id"] in local_seen or row["category"] not in ("assertion", "environment", "budget", "signal"):
                raise ValueError("invalid or duplicate local native failure")
            local_seen.add(row["id"])
            receipt_path = (root / row["receipt"]).resolve()
            receipt_path.relative_to(root.resolve())
            receipt = json.loads(receipt_path.read_text())
            if receipt.get("status") != "DENY":
                raise ValueError("local failure receipt is not denied")
            if row["category"] == "signal":
                log = (root / row["log"]).resolve()
                log.relative_to(root.resolve())
                signal = row["signal"]
                marker = f"*** FAILED {row['file']} WITH EXIT CODE HI=0 LO={signal}"
                if (type(signal) is not int or not 0 < signal < 128
                    or marker not in log.read_text().splitlines()
                    or row["file"] not in receipt.get("extraFixtures", {})
                    or not any(not r.get("accepted", True) for r in receipt.get("results", []))):
                    raise ValueError("local signal is absent from denied source-bound log")
                bind(root / row["log"])
            if row["category"] == "assertion" and row["file"] not in {r["file"] for r in receipt.get("assertionFailures", [])}:
                if "log" not in row:
                    raise ValueError("local assertion is absent from receipt")
                log = (root / row["log"]).resolve()
                log.relative_to(root.resolve())
                output = log.read_text()
                if not any(line.startswith('"unit-tests/' + row["file"] + '"@') and ': FAILED ' in line
                           for line in output.splitlines()):
                    raise ValueError("local assertion is absent from bound log")
                if not any(not result.get("accepted", True) for result in receipt.get("results", [])):
                    raise ValueError("local assertion log has no denied native mode")
                if row["file"] not in receipt.get("extraFixtures", {}) and "unit-tests/" + row["file"] not in receipt.get("sourceFiles", {}):
                    raise ValueError("local assertion source is not inventoried")
                bind(root / row["log"])
            bind(root / row["receipt"])
            facts["local_native_failure"].append([row["id"], row["category"], row["status"], digest(receipt_path)])
            for control in row.get("controls", []):
                control_path = (root / control["receipt"]).resolve()
                control_log = (root / control["log"]).resolve()
                control_path.relative_to(root.resolve())
                control_log.relative_to(root.resolve())
                if not admitted_control(receipt, json.loads(control_path.read_text()), row["file"],
                                        control["mode"], control_log.read_text()):
                    raise ValueError("local passing control is not identical-source/runtime native evidence")
                bind(root / control["receipt"])
                bind(root / control["log"])
                facts["local_control_pass"].append([row["id"], control["kind"], control["mode"], digest(control_path)])
            for model in row["models"]:
                if model not in cases:
                    raise ValueError("unknown local failure model")
                facts["local_failure_model"].append([row["id"], model])
    for field in ("scopeManifest", "classificationManifest", "triageManifest"):
        if field in catalog:
            path = (root / catalog[field]).resolve()
            path.relative_to(root.resolve())
            bind(root / catalog[field])
            if field == "triageManifest":
                triage = json.loads(path.read_text())
                for source, expected in triage["inputs"].items():
                    source_path = (root / source).resolve()
                    source_path.relative_to(root.resolve())
                    if digest(source_path) != expected:
                        raise ValueError("stale discovery triage input")
                    bind(root / source)
                facts["window_disposition"] = [[r["number"], r["disposition"]] for r in triage["pulls"]]
    seen = set()
    for report in catalog["reports"]:
        number = report["number"]
        if type(number) is not int or number in seen:
            raise ValueError("invalid or duplicate PR identity")
        seen.add(number)
        facts["pr"].append([number, report["headRefOid"], report["status"]])
        kind = report.get("kind", "runtime-repair")
        if kind not in ("runtime-repair", "supporting-tests"):
            raise ValueError("unknown report kind")
        facts["report_kind"].append([number, kind])
        for model in report["models"]:
            if model not in cases:
                raise ValueError("unknown report model: " + model)
            facts["pr_model"].append([number, model])
        facts["dependency"].extend([number, dep] for dep in report["dependencies"])
        if "snapshot" in report:
            path = (root / report["snapshot"]).resolve()
            path.relative_to(root.resolve())
            snapshot = json.loads(path.read_text())
            if (snapshot["number"] != number or snapshot["head"] != report["headRefOid"]
                or snapshot["base"] != report["baseRefOid"]):
                raise ValueError("report snapshot identity mismatch")
            if (snapshot["state"] != report["upstreamState"]
                or snapshot["merged"] != report["upstreamMerged"]):
                raise ValueError("report snapshot merge state mismatch")
            bind(root / report["snapshot"])
            facts["report_snapshot"].append([number, snapshot["head"], digest(path), len(snapshot["files"])])
    for name, case in cases.items():
        facts["model_context_pr"].append([name, case["pr"]])
        path = directory / (name + ".qnt")
        bind(path)
        facts["model"].append([name, digest(path), case.get("mode", "repair-obligation")])
        if "modelReceipt" in case:
            from gambit_smp.check_gambit import reuse_model_receipt
            receipt_path = (root / case["modelReceipt"]).resolve()
            receipt_path.relative_to(root.resolve())
            rows = reuse_model_receipt(receipt_path, case, directory)
            if not all(row.get("sourceStable") is True for row in rows):
                raise ValueError("model receipt has no stable-source admission")
            bind(root / case["modelReceipt"])
            facts["model_receipt"].append([name, digest(receipt_path), "finite-state-TLC"])
        facts["source_obligation"].extend([name, source] for source in case["source"])
        for reference in case.get("paperSections", []):
            if reference["paper"] not in paper_ids or not reference["sections"]:
                raise ValueError("unknown paper or missing section")
            for section in reference["sections"]:
                if not isinstance(section, str) or not section.strip():
                    raise ValueError("invalid paper section")
                facts["model_paper"].append([name, reference["paper"], section])
        for contract in case.get("contracts", []):
            if not isinstance(contract["obligation"], str) or not contract["obligation"].strip():
                raise ValueError("model contract has no obligation")
            facts["model_contract"].append([name, contract["model"], contract["obligation"]])
        for observation in case.get("nativeObservations", []):
            for key in ("receipt", "log"):
                path = (root / observation[key]).resolve()
                path.relative_to(root.resolve())
                bind(root / observation[key])
            facts["native_observation"].append([name, observation["kind"],
                digest(root / observation["receipt"]), digest(root / observation["log"])])
        for observation in case.get("sourceUnitObservations", []):
            for key in ("receipt", "log"):
                path = (root / observation[key]).resolve()
                path.relative_to(root.resolve())
                bind(root / observation[key])
            facts["source_unit_observation"].append([name, observation["kind"],
                digest(root / observation["receipt"]), digest(root / observation["log"])])
        for fixture_name in case.get("sourceUnitFixtures", []):
            fixture = (root / fixture_name).resolve()
            fixture.relative_to(root.resolve())
            bind(root / fixture_name)
            bind(root / "src/gambit_smp/source_unit.py")
            bind(root / "src/gambit_smp/framework.py")
            facts["source_unit_fixture"].append([name, fixture_name, digest(fixture)])
        if case["native"]:
            fixture = directory / "native" / case["native"]
            bind(fixture)
            facts["native_adapter"].append([name, case["native"]])
    if "failureManifest" in catalog:
        path = (root / catalog["failureManifest"]).resolve()
        path.relative_to(root.resolve())
        bind(root / catalog["failureManifest"])
        for row in json.loads(path.read_text())["reports"]:
            if row["pr"] not in seen:
                raise ValueError("reported failure has no catalog identity")
            report = next(r for r in catalog["reports"] if r["number"] == row["pr"])
            saved = json.loads((root / report["snapshot"]).read_text())
            links = {saved["url"], *(comment["url"] for comment in saved["comments"])}
            if "issueSnapshot" in row:
                issue_path = (root / row["issueSnapshot"]).resolve()
                issue_path.relative_to(root.resolve())
                issue = json.loads(issue_path.read_text())
                if issue["number"] != row["issue"]:
                    raise ValueError("reported failure issue identity mismatch")
                bind(root / row["issueSnapshot"])
                links.update({issue["url"], *(c["url"] for c in issue["comments"])})
            if any(url not in links for url in [row["url"], *row.get("additionalUrls", [])]):
                raise ValueError("reported failure provenance is absent from snapshot")
            facts["reported_failure"].append([row["pr"], row["failure"], row["status"]])
    for path in sorted((directory / "counterexamples").glob("*.json")):
        trace = json.loads(path.read_text())
        name = trace["case"]
        if name not in cases or trace["modelSha256"] != digest(directory / (name + ".qnt")):
            raise ValueError("stale or unknown frozen trace: " + path.name)
        bind(path)
        facts["frozen_negative"].append([name, trace.get("invariant", "safe"), digest(path)])
    for item in manifest["unresolved"]:
        facts["unresolved"].append([item.get("pr", 0), item["failure"], item["status"]])
    if (root / "evidence/progress-obligations.json").is_file():
        from gambit_smp.progress_evidence import facts as progress_facts
        extra, bound = progress_facts(root)
        if any(row[0] not in cases for row in extra["model_progress_obligation"]):
            raise ValueError("progress obligation refers to an unknown base model")
        for name, rows in extra.items():
            facts[name].extend(rows)
        inputs.update(bound)
    if (root / "evidence/protocol-extensions.json").is_file():
        from gambit_smp.protocol_evidence import facts as protocol_facts, bundle_facts
        extra, bound = protocol_facts(root)
        for manifest_name, receipt_name in (
                ("evidence/pstate-setup-protocol.json", "evidence/model-results/pstate-setup-helper-owned/receipt.json"),
                ("evidence/pstate-resize-composition.json", "evidence/model-results/pstate-resize-composition/receipt.json")):
            if (root / manifest_name).is_file():
                rows, more_inputs = bundle_facts(root, manifest_name, receipt_name)
                for name, values in rows.items():
                    extra.setdefault(name, []).extend(values)
                bound.update(more_inputs)
        known = set(cases) | {row[0] for row in extra["protocol_model"]}
        if any(parent not in known for _, parent in extra["protocol_composes"]):
            raise ValueError("protocol composition refers to an unknown model")
        for name, rows in extra.items():
            facts[name].extend(rows)
        inputs.update(bound)
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
               "model_context_pr": 2, "source_unit_fixture": 3, "native_observation": 4,
               "local_native_failure": 4, "local_failure_model": 2, "local_control_pass": 4}
    arities.update(report_kind=2, report_snapshot=4, window_disposition=2, reported_failure=3)
    arities.update(paper=2, model_paper=3, model_contract=3, model_receipt=3)
    arities.update(source_unit_observation=4)
    arities.update(model_progress_obligation=3, model_progress_checked=2,
                   protocol_model=2, protocol_composes=2, protocol_source=2,
                   protocol_paper=2, protocol_control=3, protocol_checked=2)
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
    mode.add_argument("--validate", action="store_true",
                      help="validate current available inputs; missing local context stays pending")
    mode.add_argument("--out", type=Path)
    args = parser.parse_args()
    current = export()
    path = ROOT / "evidence/relations.json"
    serialized = json.dumps(current, indent=2) + "\n"
    if args.refresh:
        path.write_text(serialized)
        print("FACT-EXPORT-OK")
        return
    if not args.validate and (not path.is_file() or path.read_text() != serialized):
        raise ValueError("stale fact export; audit inputs before --refresh")
    rules = ROOT / "evidence/rules.dl"
    results = query(current["facts"], rules.read_text())
    receipt = {"schema": "gambit-smp-query.v1", "diagnosticOnly": True,
               "factsSha256": hashlib.sha256(serialized.encode()).hexdigest(),
               "rulesSha256": digest(rules), "queries": results}
    if args.out:
        args.out.mkdir(parents=True, exist_ok=False)
        (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({name: len(rows) for name, rows in results.items()}, sort_keys=True))
    print("DATALOG-COVERAGE-OK")


if __name__ == "__main__":
    main()
