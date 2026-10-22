"""Project authenticated evidence into the local ASCENT research-review API.

No compiler, test runner or candidate is invoked. Native execution admission
remains in the existing preflight; this adapter cannot grant that permission.
"""
import argparse
import importlib
import json
from pathlib import Path
import time

from gambit_smp import evidence_index, research_audit
from gambit_smp.framework import digest
from gambit_smp.review_inputs import bindings as receipt_bindings

REVIEW_OUTPUTS = ("KnownFailure", "Established", "Reusable", "Missing", "Unusable", "Denial",
                  "Need", "ReceiptPath", "CausalEvidence", "Decision")


def unchanged(root, inputs):
    for name, expected in inputs.items():
        if digest(research_audit.local(root, name)) != expected:
            raise ValueError("review input changed: " + name)


def project(base, failures, snapshot_identity, proposal=None, changed=(), observations=(),
            bindings=None, current_inputs=None, task_model=None, reviewed_links=(), reviewed_dependencies=()):
    """Transport validated facts, leaving closure/negation/reuse to Scheme."""
    facts = {name: [] for name in (
        "Candidate", "Failure", "Passed", "ReceiptInput", "CurrentInput",
        "ReceiptDepends", "Requires", "ClaimDepends", "Cause", "FailureBinding",
        "FailureClaim", "ReviewedLink")}
    facts["CurrentInput"] = [list(row) for row in sorted(
        (current_inputs or {"validated-catalog": snapshot_identity}).items())]
    model_claim = lambda model: "finite-model:" + model
    passed = set()
    def bind(qualified):
        spec = (bindings or {}).get(qualified)
        if spec is None:
            facts["ReceiptInput"].append([qualified, "validated-catalog", snapshot_identity])
            return
        facts["ReceiptInput"].extend([qualified, path, sha]
                                     for path, sha in sorted(spec["inputs"].items()))
        if spec.get("recordedOutputPending"):
            # A summary bit alone has no source-bound output observation.
            facts["ReceiptInput"].append([qualified, "unverified-output:" + qualified,
                                          "verified"])
        if spec["binding"] == "catalog-fallback":
            facts["ReceiptInput"].append([qualified, "validated-catalog", snapshot_identity])
        facts["ReceiptDepends"].extend([qualified, dependency]
                                       for dependency in spec["depends"])

    for relation in ("model_receipt", "protocol_checked"):
        for model, receipt, *_ in base["facts"].get(relation, []):
            qualified = model + ":" + receipt
            if qualified in passed:
                continue
            passed.add(qualified)
            facts["Passed"].append([qualified, model_claim(model)])
            bind(qualified)
    for observation in observations:
        qualified = "audit:" + observation["id"]
        facts["Passed"].append([qualified, "recorded-observation:" + observation["id"]])
        bind(qualified)
    for relation in ("model_contract", "protocol_composes"):
        for model, dependency, *_ in base["facts"].get(relation, []):
            facts["ClaimDepends"].append([model_claim(model), model_claim(dependency)])
    for model, obligation in base["facts"].get("protocol_obligation", []):
        facts["ClaimDepends"].append([model_claim(model), "native-obligation:" + obligation])
    for failure in failures:
        name = failure["id"]
        old = "historical-failure:" + name
        current = "changed-inputs:" + snapshot_identity if proposal and changed else old
        facts["Candidate"].append([name, failure["file"], current])
        facts["Failure"].append([name, failure["file"], old, failure["receipt"]])
        # Free text and binary drift are not evidence of a reviewed source cause.
        facts["Requires"].append([name, "reviewed-causal-link:" + name])
        facts["Requires"].extend([name, model_claim(model)] for model in failure["models"])
    if task_model is not None:
        name = "task:" + task_model
        facts["Candidate"].append([name, name, snapshot_identity])
        facts["Requires"].append([name, model_claim(task_model)])
    # Explicit empty sources withdraw prior links in a retained owner.
    if reviewed_links:
        for row in reviewed_links:
            _, failure, _, report, sha, _, _ = row
            facts["FailureBinding"].append([failure, report, sha])
            facts["FailureClaim"].append(row[:-1])
            facts["ReviewedLink"].append(list(row))
        for receipt, spec in (bindings or {}).items():
            if "claim" in spec:
                facts["Passed"].append([receipt, spec["claim"]])
                bind(receipt)
        facts["ClaimDepends"].extend(reviewed_dependencies)
    return facts


def collect(root, selected=None, proposal=None, task_model=None):
    from gambit_smp.framework import path_resolution
    with path_resolution(root) as canonical:
        return _collect(canonical, selected, proposal, task_model)


def _review_catalogs(root):
    """Bind the configured program closure, not every registered component."""
    from gambit_smp.ascent_program import load_component_catalog
    from gambit_smp.framework import relative
    name = "evidence/scenarios/catalog-review-history/scenario.json"
    path = relative(root, name)
    before = digest(path)
    scenario = json.loads(path.read_text())
    if scenario.get("schema") != "ascent.consumer-scenario.v1":
        raise ValueError("declared Evidence consumer scenario required")
    catalogs = {entry: load_component_catalog(relative(root, scenario["manifest"]), entry=entry,
                    constructor=declaration["constructor"], trusted=True)
                for entry, declaration in scenario["entries"].items()}
    if digest(path) != before:
        raise ValueError("Evidence consumer scenario changed during binding")
    inputs = {name: before}
    for catalog in catalogs.values():
        inputs.update({str(Path(path).relative_to(root)): sha for path, sha in catalog["sourceInputs"].items()})
    return catalogs, inputs


def _collect(root, selected=None, proposal=None, task_model=None):
    from ascent.evidence import identity
    from gambit_smp.protocol_evidence import BUNDLE_REGISTRY

    root = root.resolve()
    base = evidence_index.export(root=root)
    if BUNDLE_REGISTRY not in base["inputs"]:
        raise ValueError("review requires the Catalog's complete protocol inventory")
    audit_facts, audit_inputs = research_audit.load_audit(root, base)
    observations = json.loads((root / "evidence/research-audit.json").read_text())["issues"]
    if task_model is not None and task_model not in {row[0] for row in base["facts"].get("model", []) +
                                                    base["facts"].get("protocol_model", [])}:
        raise ValueError("unknown review model: " + task_model)
    inputs = {**base["inputs"], **audit_inputs}
    from gambit_smp.evidence_views import registry, load as load_view
    view_names, view_inputs = registry(root)
    for name in view_names:
        from gambit_smp.view_materialize import check_binding
        view_inputs.update(check_binding(root,name))
        _, _, _, bound_view = load_view(root, name)
        view_inputs.update(bound_view)
    inputs.update({str(Path(path).relative_to(root)): sha for path, sha in view_inputs.items()})
    from gambit_smp.review_inputs import proof_observations
    _, proof_inputs = proof_observations(root)
    inputs.update(proof_inputs)
    inputs["evidence/catalog.ss"] = digest(root / "evidence/catalog.ss")
    inputs["evidence/history-rules.ss"] = digest(root / "evidence/history-rules.ss")
    inputs["evidence/review-rules.ss"] = digest(root / "evidence/review-rules.ss")
    _, program_inputs = _review_catalogs(root)
    inputs.update(program_inputs)
    from gambit_smp.review_inputs import RAW_LOG_MANIFEST
    if (root / RAW_LOG_MANIFEST).is_file():
        inputs[RAW_LOG_MANIFEST] = digest(root / RAW_LOG_MANIFEST)
    manifest = "evidence/native-failures.json"
    inputs[manifest] = digest(root / manifest)
    failures = json.loads((root / manifest).read_text())["failures"]
    changed, guard = [], {}
    if proposal:
        guard, bound, changed = research_audit.retry_facts(root, proposal)
        inputs.update(bound)
        selected = [proposal["failure"]]
    if selected:
        missing = set(selected) - {f["id"] for f in failures}
        if missing:
            raise ValueError("unknown failure selection: " + ", ".join(sorted(missing)))
        failures = [f for f in failures if f["id"] in selected]
    # Bind adapter semantics as well as data; partial concurrent snapshots fail.
    for name in ("ascent_review", "review_links", "review_inputs", "review_brief", "review_graph",
                 "review_validation", "agent_context", "ascent_program", "native_support", "reasoning_history", "research_audit",
                 "evidence_index", "evidence_views", "evidence_interface", "protocol_evidence", "check_gambit", "reflection"):
        module = importlib.import_module("gambit_smp." + name)
        path = Path(module.__file__).resolve()
        inputs[str(path.relative_to(root))] = digest(path)
    unchanged(root, inputs)
    snapshot = identity(inputs)
    bindings, current = receipt_bindings(root, base, observations, snapshot)
    unchanged(root, {name: sha for name, sha in current.items()
                     if name != "validated-catalog"})
    facts = project(base, failures, snapshot, proposal, changed, observations,
                    bindings, current, task_model)
    links_path = "evidence/review-links.json"
    if (root / links_path).exists():
        from gambit_smp.review_links import load
        links, dependencies, reviewed, link_inputs = load(
            root, links_path, facts["Candidate"], failures, inputs[manifest])
        inputs.update(link_inputs)
        bindings.update(reviewed)
        current.update(link_inputs)
        facts = project(base, failures, snapshot, proposal, changed, observations,
                        bindings, current, task_model, links, dependencies)
        unchanged(root, inputs)
    source_facts = {name: list(rows) for name, rows in base["facts"].items()}
    for name, rows in audit_facts.items():
        source_facts.setdefault(name, []).extend(rows)
    return facts, inputs, failures, guard, changed, observations, bindings, current, source_facts


def run_review(root, selected=None, proposal=None, task_model=None, proposal_path=None,
               validation_path=None, validation_profile=None, *, native_engine=None,
               campaign_paths=(), history_lineage=None):
    from gambit_smp.ascent_program import artifact_paths, load_component_catalog, engine_api, evaluate
    from gambit_smp.native_support import observe

    root = Path(root).resolve()
    facts, inputs, failures, guard, changed, observations, bindings, current, source_facts = collect(
        root, selected, proposal, task_model)
    if proposal_path:
        proposal_path = Path(proposal_path).resolve()
        inputs[str(proposal_path.relative_to(root))] = digest(proposal_path)
    started = time.monotonic()
    with engine_api(engine=native_engine, retain=native_engine is None) as (engine, engine_inputs):
        catalog_backend = {}
        catalogs, program_inputs = _review_catalogs(root)
        inputs.update(program_inputs)
        evidence_catalog, review_catalog = catalogs["catalog"], catalogs["review"]
        catalog_rows = evidence_index.query(source_facts, evidence_catalog,
                                            engine=engine, metrics=catalog_backend)
        rows, review_backend = evaluate(engine, facts, review_catalog,
                                       {name: name for name in REVIEW_OUTPUTS})
        from gambit_smp.evidence_views import registry, evaluate as evaluate_view
        evidence_views = [evaluate_view(root, name, engine) for name in registry(root)[0]]
        result = {"schema": "ascent-evidence-review.v1", "result": {"complete": True,
                  "relations": {name: [list(row) for row in values] for name, values in rows.items()}},
                  "decisions": [{"candidate": candidate, "decision": decision}
                                for candidate, decision in rows["Decision"]],
                  "executionAuthorized": False, "reviewBackend": review_backend}
        requests = {name: [list(row) for row in rows[name]
                          if not task_model or row[0] == "task:" + task_model]
                    for name in ("Need", "KnownFailure", "Missing", "Denial", "Decision")}
        requests = {name: values for name, values in requests.items() if values}
        native_observations = observe(engine, facts, review_catalog, requests,
                                      generation=review_backend["sourceGeneration"])
        campaigns = []
        if campaign_paths:
            from gambit_smp.campaign_evidence import collect as collect_campaigns
            campaigns, campaign_inputs = collect_campaigns(root, campaign_paths, engine)
            inputs.update(campaign_inputs)
    unchanged(root, inputs)
    unchanged(root, {name: sha for name, sha in current.items()
                     if name != "validated-catalog"})
    result.update(inputs=inputs, engineInputs=engine_inputs,
                  engineArtifacts={name: {"path": str(path.resolve()), "sha256": engine_inputs[name],
                                          "insideResearchCheckout": path.resolve().is_relative_to(root)}
                                   for name, path in artifact_paths().items()},
                  receiptCurrentInputs={name: sha for name, sha in current.items()
                                        if name != "validated-catalog"},
                  backend="api",
                  catalogQueries=catalog_rows, catalogBackend=catalog_backend,
                  seconds=time.monotonic() - started, failures=failures,
                  recordedObservations=observations,
                  retryFacts=guard, changedTestedInputs=changed,
                  nativeResultReused=review_backend["nativeResultReused"],
                  nativeObservations=native_observations,
                  nativeCampaigns=campaigns,
                  evidenceViews=evidence_views,
                  runtimeAdmitted=False, releaseAdmitted=False,
                  scope="Historical route review or unapproved proposal; finite-model conclusions are not native fixes. Causal admission remains pending.")
    if task_model:
        from gambit_smp.review_brief import render
        result["taskBrief"] = render(task_model, facts, result["result"]["relations"],
                                     bindings, failures, observations, source_facts)
    from gambit_smp.reasoning_history import record, fingerprint, lineage
    legacy_scope = "review:" + fingerprint({"failures": sorted(f["id"] for f in failures),
                                             "model": task_model})
    scope = (lineage("review", task=task_model, selection=sorted(selected) if selected is not None else "all")
             if history_lineage is None else history_lineage)
    result["history"] = record(root, scope, inputs, result["result"]["relations"],
                               {"name": "ascent-rust", "inputs": engine_inputs},
                               legacy_scope=legacy_scope)
    if validation_path:
        from gambit_smp.review_validation import load
        result["frameworkValidation"] = load(root, validation_path, inputs, engine_inputs, validation_profile)
    else:
        result["frameworkValidation"] = {"status": "not-supplied", "frameworkValidated": False}
    if task_model:
        from gambit_smp.review_graph import build
        result["agentGraph"] = build(root, task_model, facts, result["result"]["relations"],
                                    bindings, source_facts, inputs, engine_inputs,
                                    result["frameworkValidation"], catalog_rows=catalog_rows,
                                    engine_artifacts=result["engineArtifacts"],
                                    native_observations=native_observations, campaigns=campaigns,
                                    evidence_views=evidence_views)
    unchanged(root, inputs)
    unchanged(root, {name: sha for name, sha in current.items()
                     if name != "validated-catalog"})
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--api", action="store_true", help=argparse.SUPPRESS)
    parser.add_argument("--failure", action="append")
    parser.add_argument("--model", help="emit a model-scoped working brief and evidence graph")
    parser.add_argument("--proposal", type=Path)
    parser.add_argument("--validation", type=Path, help="input-bound Python validation receipt")
    parser.add_argument("--graph-out", type=Path, help="write the model-scoped Agent graph separately")
    parser.add_argument("--campaign", type=Path, action="append", default=[])
    parser.add_argument("--history-lineage", help="stable caller-owned task/branch/policy journal label")
    parser.add_argument("--out", type=Path, required=True)
    args = parser.parse_args()
    if args.graph_out and not args.model:
        parser.error("--graph-out requires --model")
    from gambit_smp.artifact_storage import runtime_output
    args.out = runtime_output(evidence_index.ROOT, args.out)
    if args.graph_out:
        args.graph_out = runtime_output(evidence_index.ROOT, args.graph_out)
    proposal = json.loads(args.proposal.read_text()) if args.proposal else None
    result = run_review(evidence_index.ROOT, args.failure, proposal, args.model,
                        args.proposal, args.validation, campaign_paths=args.campaign,
                        history_lineage=args.history_lineage)
    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("x") as output:
        output.write(json.dumps(result, indent=2) + "\n")
    if args.graph_out:
        args.graph_out.parent.mkdir(parents=True, exist_ok=True)
        with args.graph_out.open("x") as output:
            output.write(json.dumps(result["agentGraph"], indent=2) + "\n")
    summary = {"seconds": result["seconds"],
               "nativeResultReused": result["nativeResultReused"],
               "receiptPath": str(args.out),
               "executionAuthorized": False}
    if args.model:
        brief = result["taskBrief"]
        summary.update(task=args.model, metrics=brief["metrics"], gates=brief["gates"],
                       openModelClaims=len(brief["openModelClaims"]),
                       openNativeObligations=len(brief["openNativeObligations"]))
        graph = result["agentGraph"]
        summary["agentGraph"] = {"sha256": graph["graphSha256"], "nodes": len(graph["nodes"]),
                                 "edges": len(graph["edges"]),
                                 "frameworkValidated": graph["frameworkValidated"]}
    else:
        summary.update(decisions=result["decisions"],
                       rows={name: len(rows) for name, rows in result["result"]["relations"].items()})
    print(json.dumps(summary, sort_keys=True))
    # A generated explanation is not a successful execution-admission check.
    return 2 if any(d["decision"] == "DENY" for d in result["decisions"]) else 3


from gambit_smp.task_entry import managed_entry as _managed_entry
main = _managed_entry('ascent-review')(main)

if __name__ == "__main__":
    from gambit_smp.task_entry import module_main
    raise SystemExit(module_main('ascent-review', main))
