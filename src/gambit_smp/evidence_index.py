#!/usr/bin/env python3
"""Digest-bound fact export and Datalog coverage queries, never release admission."""
import argparse
import hashlib
from graphlib import CycleError, TopologicalSorter
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest

QUERIES = {
    "reports_without_snapshots": "needs_snapshot",
    "model_contexts_without_report_snapshot": "context_needs_report",
    "reports_without_models": "needs_model",
    "models_without_native_adapters": "needs_native",
    "dependency_closure": "dependency_path",
    "shared_obligations": "shared_obligation",
    "source_overlap_review_open": "triage_open",
    "reported_failure_records": "reported_failure",
    "local_assertions_without_models": "local_needs_model",
    "local_environment_failures": "local_environment",
    "local_budget_denials": "local_budget",
    "local_passing_controls": "local_control_pass",
    "local_budget_without_passing_controls": "local_budget_uncontrolled",
    "local_signal_denials": "local_signal",
    "paper_guided_models": "model_paper",
    "model_contract_dependencies": "contract_path",
    "paper_guided_models_without_native_adapters": "paper_needs_native",
    "contract_dependencies_without_native_adapters": "contract_needs_native",
    "recorded_model_admissions": "model_receipt",
    "contract_dependencies_without_model_receipts": "contract_needs_receipt",
    "recorded_source_unit_observations": "source_unit_observation",
    "explicit_progress_obligations": "model_progress_obligation",
    "recorded_progress_checks": "model_progress_checked",
    "progress_obligations_without_checks": "progress_needs_check",
    "protocol_extensions": "protocol_model",
    "recorded_protocol_checks": "protocol_checked",
    "protocol_extensions_without_checks": "protocol_needs_check",
    "protocol_open_obligations": "protocol_obligation",
    "contract_dependencies_with_open_obligations": "contract_open_obligation",
    "protocol_report_links": "protocol_report",
    "protocol_reports_without_checks": "protocol_report_needs_check",
    "local_failure_records": "local_failure_record",
    "recorded_failure_bindings": "observed_field",
    "recorded_failure_gaps": "observed_gap",
    "recorded_failure_category_mismatches": "observed_unmatched",
    "recorded_control_references": "observed_control_reference",
    "recorded_failure_model_references": "observed_model_reference",
    "recorded_failure_unregistered_models": "observed_model_unregistered",
    "recorded_failure_log_attachments": "observed_log_attachment",
}


def observation_bindings(root, inventory_path, rows, bind):
    """Transport explicit hash/pointer bindings, without admitting observations."""
    from gambit_smp.native_review import pointer
    from gambit_smp.recipes import fields, read_json, source_path
    import re

    def resolve(document, location):
        if location == "":
            return document
        try:
            return pointer(document, location)
        except (KeyError, IndexError, TypeError) as error:
            raise ValueError("missing or invalid observation JSON pointer") from error

    path = root / "evidence/native-observation-bindings.json"
    if not path.is_file():
        return {}
    document = read_json(path)
    fields(document, ("schema", "inventorySha256", "bindings"))
    if (document["schema"] != "gambit-native-observation-bindings.v1"
            or document["inventorySha256"] != digest(inventory_path)):
        raise ValueError("stale native observation inventory binding")
    if not isinstance(document["bindings"], dict):
        raise ValueError("observation bindings must be an identity map")
    known = {row["id"]: row for row in rows}
    if set(document["bindings"]) - known.keys():
        raise ValueError("unknown native observation identity")
    bind(path)
    result = {}
    kinds = {"exit": int, "timeout": bool, "accepted": bool,
             "fixture": str, "fixture-sha": str, "source-lock-sha": str,
             "runtime-identity-sha": str, "binary-sha": str,
             "operation": str, "original-budget": (int, float),
             "whole-budget": (int, float), "argv": list,
             "teardown": bool, "stdout": str, "stderr": str}
    for name, entry in document["bindings"].items():
        fields(entry, ("receiptSha256", "recordPointer", "eventPointer", "scope", "fields"), ("logSha256Pointer",))
        row = known[name]
        receipt_path = source_path(root, row["receipt"])
        if entry["receiptSha256"] != digest(receipt_path):
            raise ValueError("stale native observation receipt binding")
        receipt = read_json(receipt_path)
        if receipt.get("status") == "DENY":
            raise ValueError("normalized suite receipts must retain their strict admission path")
        record, event = entry["recordPointer"], entry["eventPointer"]
        if (not isinstance(record, str) or not isinstance(event, str)
                or not (event == record or event.startswith(record + "/"))):
            raise ValueError("process event is outside bound record")
        if record:
            resolve(receipt, record)
        if not isinstance(resolve(receipt, event), dict) or entry["scope"] not in ("fixture", "build"):
            raise ValueError("invalid native observation process scope")
        mappings = entry["fields"]
        if not isinstance(mappings, dict) or set(mappings) - kinds.keys():
            raise ValueError("unsupported typed observation field")
        expected = {"exit": event + "/exit", "timeout": event + "/timeout"}
        if (any(mappings.get(key) != value for key, value in expected.items())
                or mappings.get("accepted") not in (record + "/accepted", "/accepted")):
            raise ValueError("failure process fields must share one event and record")
        if entry["scope"] == "fixture" and (mappings.get("fixture") != record + "/fixture"
                or mappings.get("fixture-sha") != record + "/fixtureSha256"):
            raise ValueError("fixture identity must belong to bound failure record")
        values = {}
        origins = []
        for key, location in mappings.items():
            value = resolve(receipt, location)
            types = kinds[key] if isinstance(kinds[key], tuple) else (kinds[key],)
            if type(value) not in types:
                raise ValueError("invalid typed observation value: " + key)
            if key.endswith("-sha") and not re.fullmatch(r"[0-9a-f]{64}", value):
                raise ValueError("invalid observation digest")
            if key in ("original-budget", "whole-budget") and value <= 0:
                raise ValueError("invalid original observation budget")
            original_names = {"source-lock-sha": ("sourceLockSha256",),
                              "runtime-identity-sha": ("identitySha256", "runtimeIdentitySha256"),
                              "binary-sha": ("binarySha256",), "whole-budget": ("wholeBudgetSeconds",)}
            if key in original_names and not any(location.endswith("/" + name) for name in original_names[key]):
                raise ValueError("observation identity is not its original named field")
            # A duration or inventory label cannot supply a missing original cap/stage.
            if key in ("original-budget", "operation", "argv", "teardown", "stdout", "stderr"):
                suffix = {"original-budget": "budgetSeconds", "operation": "stage",
                          "teardown": "group_quiescent"}.get(key, key)
                allowed = {event + "/" + suffix}
                if key == "original-budget":
                    allowed.add("/processBudgetSeconds")
                if location not in allowed:
                    raise ValueError("observation field is not an original event field: " + key)
            values[key] = value
            origins.append([name, key, entry["receiptSha256"], location,
                            json.dumps(value, sort_keys=True, separators=(",", ":"))])
        if entry["scope"] == "fixture" and values["fixture"] != row["file"]:
            raise ValueError("observation fixture does not match failure inventory")
        if digest(receipt_path) != entry["receiptSha256"]:
            raise ValueError("native observation receipt changed during projection")
        signal = row.get("signal")
        if signal is not None and (type(signal) is not int or not 0 < signal < 128):
            raise ValueError("invalid declared observation signal")
        controls = []
        for control in row.get("controls", []):
            control_path = source_path(root, control["receipt"])
            read_json(control_path)
            bind(root / control["receipt"])
            controls.append([name, control["kind"], control["mode"], digest(control_path)])
        models = []
        for model in row["models"]:
            model_path = source_path(root, "models/gambit/" + model + ".qnt")
            bind(root / "models/gambit" / (model + ".qnt"))
            models.append([name, model, digest(model_path)])
        attachments = []
        if "logSha256Pointer" in entry:
            location = entry["logSha256Pointer"]
            if location not in (event + "/rawLogSha256", event + "/portableLogSha256"):
                raise ValueError("log must bind an original process log digest")
            log_path = source_path(root, row["log"])
            sha = resolve(receipt, location)
            if sha != digest(log_path):
                raise ValueError("original observation log digest mismatch")
            bind(root / row["log"])
            attachments.append([name, row["log"], sha, location])
        bind(root / row["receipt"])
        result[name] = {"observed_failure": [[name, row["category"], row["status"], entry["receiptSha256"], entry["scope"]]],
                        "observed_process": [[name, values["exit"], values["timeout"], values["accepted"]]],
                        "observed_field": origins,
                        "observed_signal": [] if signal is None else [[name, signal]],
                        "observed_control_reference": controls,
                        "observed_model_reference": models,
                        "observed_log_attachment": attachments}
    if digest(inventory_path) != document["inventorySha256"]:
        raise ValueError("native observation inventory changed during projection")
    return result


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
             "model_progress_obligation", "model_progress_checked", "protocol_model", "protocol_composes", "protocol_source", "protocol_paper", "protocol_control", "protocol_checked", "protocol_obligation", "protocol_report",
             "observed_failure", "observed_process", "observed_field", "observed_signal", "observed_control_reference", "observed_model_reference", "observed_log_attachment")}
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
        rows = json.loads(path.read_text())["failures"]
        observations = observation_bindings(root, path, rows, bind)
        for row in rows:
            if row["id"] in local_seen or row["category"] not in ("assertion", "environment", "budget", "signal"):
                raise ValueError("invalid or duplicate local native failure")
            local_seen.add(row["id"])
            if row["id"] in observations:
                for relation, values in observations[row["id"]].items():
                    facts[relation].extend(values)
                continue
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
    historical_path = root / "evidence/frozen-trace-history.json"
    historical = {}
    if historical_path.exists():
        history = json.loads(historical_path.read_text())
        if history.get("schema") != "gambit-frozen-trace-history.v1":
            raise ValueError("typed frozen trace history required")
        bind(historical_path)
        for entry in history["traces"]:
            if set(entry) != {"path", "sha256", "modelSnapshot", "modelSha256"} or entry["path"] in historical:
                raise ValueError("unique exact historical trace binding required")
            historical[entry["path"]] = entry
    for path in sorted((directory / "counterexamples").glob("*.json")):
        trace = json.loads(path.read_text())
        name = trace["case"]
        if name not in cases:
            raise ValueError("stale or unknown frozen trace: " + path.name)
        if trace["modelSha256"] != digest(directory / (name + ".qnt")):
            entry = historical.get(str(path.relative_to(root)))
            from gambit_smp.recipes import source_path
            if (entry is None or digest(path) != entry["sha256"]
                    or trace["modelSha256"] != entry["modelSha256"]
                    or digest(source_path(root, entry["modelSnapshot"])) != entry["modelSha256"]):
                raise ValueError("stale or unknown frozen trace: " + path.name)
            bind(path)
            bind(root / entry["modelSnapshot"])
            # Preserve source-bound history, but never count it as a current
            # model's negative control. New controls require new trace bytes.
            facts.setdefault("historical_frozen_negative", []).append(
                [name, trace.get("invariant", "safe"), digest(path), entry["modelSnapshot"]])
            continue
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
        report_heads = {row[0]: row[1] for row in facts["pr"]}
        if any(report_heads.get(report) != head for _, report, head, _ in extra["protocol_report"]):
            raise ValueError("protocol report link differs from catalog head")
        for name, rows in extra.items():
            facts[name].extend(rows)
        inputs.update(bound)
    if (root / "evidence/source-observations.json").is_file():
        from gambit_smp.source_evidence import facts as source_facts
        rows, bound = source_facts(root, {row[0] for row in facts["protocol_checked"]})
        facts["source_unit_observation"].extend(rows)
        inputs.update(bound)
    validate_contract_graph(facts)
    return {"schema": "gambit-smp-relations.v1", "sourceRevision": manifest["sourceRevision"],
            "evidenceBoundary": "coverage-index-only-not-correctness-or-release-admission",
            "inputs": dict(sorted(inputs.items())),
            "facts": {name: sorted({tuple(row) for row in rows}) for name, rows in facts.items()}}


def validate_contract_graph(facts):
    graph = {}
    edges = [(parent, child) for parent, child, _ in facts["model_contract"]]
    edges.extend(facts["protocol_composes"])
    for parent, child in edges:
        graph.setdefault(parent, set()).add(child)
    try:
        tuple(TopologicalSorter(graph).static_order())
    except CycleError as error:
        raise ValueError("cyclic model/protocol contracts; circular premises cannot admit a repair") from error


def validate_graphs(facts):
    validate_contract_graph(facts)
    graph = {}
    for parent, child in facts["dependency"]:
        graph.setdefault(parent, set()).add(child)
    try:
        tuple(TopologicalSorter(graph).static_order())
    except CycleError as error:
        raise ValueError("cyclic PR dependency; audit before querying") from error


def query(facts, rules, *, engine=None, metrics=None):
    from gambit_smp.ascent_program import query as native_query
    validate_graphs(facts)
    return native_query(facts, rules, QUERIES, engine=engine, metrics=metrics)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--refresh", action="store_true")
    mode.add_argument("--check", action="store_true")
    mode.add_argument("--validate", action="store_true",
                      help="validate current available inputs; missing local context stays pending")
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    if args.out:
        from gambit_smp.artifact_storage import runtime_output
        args.out = runtime_output(ROOT, args.out)
    current = export()
    path = ROOT / "evidence/relations.json"
    serialized = json.dumps(current, indent=2) + "\n"
    if args.refresh:
        path.write_text(serialized)
        print("FACT-EXPORT-OK")
        return
    if not args.validate and (not path.is_file() or path.read_text() != serialized):
        raise ValueError("stale fact export; audit inputs before --refresh")
    rules = ROOT / "evidence/dsl/catalog.ss"
    backend = {}
    from gambit_smp.ascent_program import load_component_catalog
    catalog = load_component_catalog(ROOT / "evidence/dsl/components.json", entry="catalog",
                                  constructor="make-catalog", trusted=True)
    results = query(current["facts"], catalog, metrics=backend)
    receipt = {"schema": "gambit-smp-query.v1", "diagnosticOnly": True,
               "factsSha256": hashlib.sha256(serialized.encode()).hexdigest(),
               "rulesSha256": digest(rules), "queries": results, "backend": backend}
    inputs = {**current["inputs"], **{str(Path(path).relative_to(ROOT.resolve())): sha
              for path, sha in catalog["sourceInputs"].items()}}
    if any(digest(ROOT / name) != sha for name, sha in inputs.items()):
        raise ValueError("evidence inputs changed during query")
    from gambit_smp.reasoning_history import record
    receipt["history"] = record(ROOT, "evidence:catalog", inputs, results, backend)
    if any(digest(ROOT / name) != sha for name, sha in inputs.items()):
        raise ValueError("evidence inputs changed during history recording")
    if args.out:
        args.out.mkdir(parents=True, exist_ok=False)
        (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({name: len(rows) for name, rows in results.items()}, sort_keys=True))
    print("DATALOG-COVERAGE-OK")


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('evidence')(main)

if __name__ == "__main__":
    main()
