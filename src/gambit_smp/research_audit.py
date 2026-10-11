"""Evidence-linked research audit and conservative failed-route preflight.

This module never executes a candidate or grants runtime/release admission.
Changed inputs require source review; unchanged failed inputs are denied.
"""
import argparse
import json
from pathlib import Path

from gambit_smp import evidence_index as index
from gambit_smp.framework import digest
from gambit_smp.protocol_source_audit import ARITIES as SOURCE_ARITIES

ROOT = index.ROOT
ARITIES = {"audit_issue": 3, "audit_pr": 2, "audit_model": 2, "audit_paper": 3,
           "audit_reusable_receipt": 3, "audit_legacy_receipt": 3,
           "protocol_model": 2, "protocol_composes": 2, "protocol_source": 2,
           "protocol_paper": 2, "protocol_control": 3, "protocol_checked": 2,
           "retry_route": 1, "retry_delta": 1, "retry_budget_expanded": 1,
           "retry_scope_mismatch": 1, "retry_hypothesis": 1, "retry_unbound": 1,
           **SOURCE_ARITIES}
QUERIES = {"blockers": "audit_blocker(I, B)",
           "pr_model_source_paths": "audit_value_path(I, P, M, S)",
           "paper_model_paths": "audit_paper_path(I, P, S, M)",
           "missing_model_receipts": "audit_model_gap(I, M)",
           "missing_contract_receipts": "audit_contract_gap(I, M)",
           "reusable_undesignated_receipts": "audit_reusable_receipt(M, P, D)",
           "legacy_evidence_review": "audit_legacy_review(M, P, D)",
           "protocol_remaining": "protocol_gap(M)",
           "protocol_verified": "protocol_checked(M, D)",
           "protocol_source_paths": "protocol_value_path(M, Prior, Source)",
           "protocol_upstream_paths": "protocol_upstream(M, P)",
           "source_repairs": "source_repair_needed(M, I)",
           "source_origin_gaps": "source_origin_needed(M, I)",
           "native_acceptance_pending": "source_native_pending(G)",
           "retry_denials": "retry_denied(R, Reason)",
           "retry_review_required": "retry_review_required(R)"}


def local(root, name):
    if not isinstance(name, str) or Path(name).is_absolute():
        raise ValueError("repository-relative evidence path required")
    path = (root / name).resolve()
    path.relative_to(root.resolve())
    return path


def load_audit(root, base):
    path = root / "evidence/research-audit.json"
    audit = json.loads(path.read_text())
    if audit.get("schema") != "gambit-research-audit.v1":
        raise ValueError("unknown audit schema")
    facts = {name: [] for name in ARITIES}
    inputs = {"evidence/research-audit.json": digest(path)}
    models = {row[0] for row in base["facts"]["model"]}
    prs = {row[0] for row in base["facts"]["pr"]}
    papers = {row["id"] for row in json.loads((root / "evidence/papers.json").read_text())["papers"]}
    seen = set()
    for issue in audit["issues"]:
        name = issue["id"]
        if name in seen or not issue["evidence"] or not issue["next"]:
            raise ValueError("duplicate or ungrounded audit issue")
        seen.add(name)
        if type(issue["priority"]) is not int or issue["priority"] not in (1, 2, 3):
            raise ValueError("invalid audit priority")
        for evidence in issue["evidence"]:
            source = local(root, evidence["path"])
            actual = digest(source)
            if actual != evidence["sha256"]:
                raise ValueError("stale audit evidence: " + evidence["path"])
            inputs[evidence["path"]] = actual
        if not set(issue["models"]).issubset(models) or not set(issue["prs"]).issubset(prs):
            raise ValueError("unknown audit model or PR")
        facts["audit_issue"].append((name, issue["barrier"], issue["priority"]))
        facts["audit_pr"].extend((name, pr) for pr in issue["prs"])
        facts["audit_model"].extend((name, model) for model in issue["models"])
        for paper in issue["papers"]:
            if paper["paper"] not in papers or not paper["section"].strip():
                raise ValueError("unknown audit paper or section")
            facts["audit_paper"].append((name, paper["paper"], paper["section"]))
    return facts, inputs


def retry_facts(root, proposal):
    root = root.resolve()
    if proposal.get("schema") != "gambit-retry-proposal.v1":
        raise ValueError("unknown retry proposal schema")
    failures = json.loads((root / "evidence/native-failures.json").read_text())["failures"]
    failure = next((row for row in failures if row["id"] == proposal.get("failure")), None)
    if failure is None:
        raise ValueError("known failure identity required")
    old_path = local(root, failure["receipt"])
    old = json.loads(old_path.read_text())
    if old.get("status") != "DENY":
        raise ValueError("retry baseline must be a denied receipt")
    candidate_path = local(root, proposal["candidateReceipt"])
    candidate = json.loads(candidate_path.read_text())
    runtime = local(root, proposal["runtime"])
    fixture = proposal["fixture"]
    if not isinstance(fixture, str) or not fixture.endswith(".scm"):
        raise ValueError("one concrete Scheme fixture required")
    fixture_path = local(runtime / "tests/unit-tests", fixture)
    mode = proposal["mode"]
    if mode not in ("gsi", "gsc"):
        raise ValueError("gsi or gsc mode required")
    budget = proposal["budgetSeconds"]
    if type(budget) not in (int, float) or not 0 < budget < float("inf"):
        raise ValueError("finite positive budget required")
    name = failure["id"]
    facts = {key: [] for key in ARITIES}
    facts["retry_route"].append((name,))
    failed_file = failure["file"]
    denied_modes = {row["mode"] for row in old.get("results", [])
                    if row.get("accepted") is False and "mode" in row}
    if fixture != failed_file or mode not in denied_modes:
        facts["retry_scope_mismatch"].append((name,))
    before_fixture = old.get("sourceFiles", {}).get("unit-tests/" + fixture)
    patches = old.get("extraFixtures", {}).get(fixture, {})
    before_fixture = patches.get("testedSha256", before_fixture)
    # Fixture patches must be represented by their actually tested bytes.
    for patch in old.get("fixturePatches", []):
        before_fixture = patch.get("derivedFiles", {}).get("unit-tests/" + fixture, before_fixture)
    binary_keys = [("gsi/gsi", "binarySha256", "gsiSha256")]
    if mode == "gsc":
        binary_keys.append(("gsc/gsc", "gscSha256", "gscSha256"))
    changes = []
    inputs = {failure["receipt"]: digest(old_path), proposal["candidateReceipt"]: digest(candidate_path)}
    for binary, candidate_key, old_key in binary_keys:
        path = local(runtime, binary)
        actual = digest(path)
        inputs[str(path.relative_to(root))] = actual
        if actual != candidate.get(candidate_key) or not old.get(old_key):
            facts["retry_unbound"].append((name,))
        elif actual != old[old_key]:
            changes.append(old_key)
    if mode == "gsc":
        driver = old.get("buildDriver", {})
        driver_path = local(runtime, driver.get("relativePath", "bin/gambuild-C"))
        actual_driver = digest(driver_path)
        inputs[str(driver_path.relative_to(root))] = actual_driver
        if not driver.get("sha256"):
            facts["retry_unbound"].append((name,))
        elif actual_driver != driver["sha256"]:
            changes.append("buildDriverSha256")
        for helper, expected in driver.get("helperSha256", {}).items():
            path = local(runtime / "bin", helper)
            actual = digest(path)
            inputs[str(path.relative_to(root))] = actual
            if actual != expected:
                changes.append("helper:" + helper)
    actual_fixture = digest(fixture_path)
    inputs[str(fixture_path.relative_to(root))] = actual_fixture
    if before_fixture is None:
        facts["retry_unbound"].append((name,))
    elif actual_fixture != before_fixture:
        changes.append("fixtureSha256")
    old_budget = old.get("atomicBatchBudgetPerMode") or old.get("wholeSuiteBudgetPerMode")
    if type(old_budget) not in (int, float) or budget > old_budget:
        facts["retry_budget_expanded"].append((name,))
    if changes:
        facts["retry_delta"].append((name,))
    hypothesis = proposal.get("hypothesis", {})
    if (isinstance(hypothesis, dict) and isinstance(hypothesis.get("cause"), str)
            and hypothesis["cause"].strip() and isinstance(hypothesis.get("expectedObservation"), str)
            and hypothesis["expectedObservation"].strip()):
        facts["retry_hypothesis"].append((name,))
    return facts, inputs, changes


def reusable_receipts(root, base, facts, inputs):
    from gambit_smp.check_gambit import reuse_model_receipt
    directory = root / "models/gambit"
    cases = {row["id"]: row for row in json.loads((directory / "cases.json").read_text())["cases"]}
    designated = {row[0] for row in base["facts"].get("model_receipt", [])}
    needed = {row[1] for row in facts["audit_model"]}
    pending = list(needed)
    while pending:
        for contract in cases[pending.pop()].get("contracts", []):
            if contract["model"] not in needed:
                needed.add(contract["model"])
                pending.append(contract["model"])
    for path in sorted((root / "evidence/model-results").glob("*.json")):
        saved = json.loads(path.read_text())
        if saved.get("schema") != "gambit-smp-model-receipt.v1":
            continue
        present = {row.get("case") for row in saved.get("results", [])}
        for name in sorted((needed - designated) & present):
            try:
                rows = reuse_model_receipt(path, cases[name], directory)
            except (KeyError, ValueError, OSError):
                continue
            if any(row.get("sourceStable") is False for row in rows):
                continue
            relative = str(path.relative_to(root))
            value = digest(path)
            inputs[relative] = value
            predicate = ("audit_reusable_receipt"
                         if all(row.get("sourceStable") is True for row in rows)
                         else "audit_legacy_receipt")
            facts[predicate].append((name, relative, value))


def query(base, audit, root):
    from pyDatalog import pyDatalog
    index.query(base["facts"], (root / "evidence/rules.dl").read_text())
    for predicate, arity in ARITIES.items():
        sentinel = ("__audit_empty__",) * arity
        pyDatalog.assert_fact(predicate, *sentinel)
        pyDatalog.retract_fact(predicate, *sentinel)
        for row in audit[predicate]:
            pyDatalog.assert_fact(predicate, *row)
    pyDatalog.load((root / "evidence/research-rules.dl").read_text())
    result = {}
    for name, expression in QUERIES.items():
        answer = pyDatalog.ask(expression)
        result[name] = sorted(answer.answers) if answer else []
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--check", action="store_true")
    group.add_argument("--proposal", type=Path)
    parser.add_argument("--out", type=Path)
    args = parser.parse_args()
    base = index.export()
    facts, inputs = load_audit(ROOT, base)
    inputs.update(base["inputs"])
    reusable_receipts(ROOT, base, facts, inputs)
    from gambit_smp.protocol_evidence import facts as protocol_facts
    extensions, bound = protocol_facts(ROOT)
    facts.update(extensions)
    inputs.update(bound)
    from gambit_smp.protocol_source_audit import facts as source_facts
    observations, bound = source_facts(ROOT)
    facts.update(observations)
    inputs.update(bound)
    inputs["evidence/research-rules.dl"] = digest(ROOT / "evidence/research-rules.dl")
    inputs["evidence/rules.dl"] = digest(ROOT / "evidence/rules.dl")
    for name in ("research_audit.py", "evidence_index.py", "check_gambit.py", "protocol_evidence.py", "protocol_source_audit.py"):
        inputs["src/gambit_smp/" + name] = digest(ROOT / "src/gambit_smp" / name)
    changes = []
    if args.proposal:
        proposal_path = args.proposal.resolve()
        inputs[str(proposal_path.relative_to(ROOT))] = digest(proposal_path)
        extra, bound, changes = retry_facts(ROOT, json.loads(args.proposal.read_text()))
        inputs.update(bound)
        for name, rows in extra.items():
            facts[name].extend(rows)
    results = query(base, facts, ROOT)
    # Concurrent Working edits invalidate this observation rather than producing
    # a receipt assembled from different source versions.
    if any(digest(local(ROOT, path)) != expected for path, expected in inputs.items()):
        raise ValueError("audit inputs changed during observation")
    decision = "AUDIT-CHECKED"
    if args.proposal:
        decision = "DENY" if results["retry_denials"] else "REVIEW_REQUIRED"
    receipt = {"schema": "gambit-research-audit-receipt.v1", "decision": decision,
               "runtimeAdmitted": False, "releaseAdmitted": False,
               "changedTestedInputs": changes, "inputs": inputs, "queries": results}
    if args.out:
        args.out.mkdir(parents=True, exist_ok=False)
        (args.out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(json.dumps({"decision": decision, "queries": {k: len(v) for k, v in results.items()},
                      "retryDenials": results["retry_denials"]}, sort_keys=True))
    return 0 if args.check else 2 if decision == "DENY" else 3


if __name__ == "__main__":
    raise SystemExit(main())
