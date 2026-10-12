"""Typed retry transport. Native ASCENT owns eligibility and missing premises."""
import math
import re
from pathlib import Path

from gambit_smp.framework import digest, relative


POLICY = "evidence/research/suite-review-rules.ss"
SCHEMA = "typed-native-retry-review.v1"


def selected_scope(name, selected):
    path = Path(name)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("repository-relative failure scope required")
    return (name == "tests/run-unit-tests.scm" and bool(selected) or name in selected or
            not path.suffix and any(path in Path(file).parents for file in selected))


def pointer(value, path):
    """Resolve an RFC 6901 reference, without interpreting an expression."""
    if not isinstance(path, str) or not path.startswith("/"):
        raise ValueError("nonempty JSON pointer required")
    for token in path[1:].split("/"):
        if re.search(r"~(?![01])", token):
            raise ValueError("invalid JSON pointer escape")
        token = token.replace("~1", "/").replace("~0", "~")
        value = value[int(token)] if isinstance(value, list) and token.isdecimal() else value[token]
    return value


def milliseconds(seconds):
    if type(seconds) not in (int, float) or not math.isfinite(seconds) or seconds <= 0:
        raise ValueError("recorded positive finite seconds required")
    value = seconds * 1000
    if value != int(value):
        raise ValueError("budget must have exact millisecond precision")
    return int(value)


def campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, *, suite_budget=None):
    from gambit_smp.recipes import tree_identity
    from gambit_smp.research_kernel import content_id
    from gambit_smp.framework import available_processors
    from gambit_smp.suite_primitives import capacity
    step = next(row for row in ctx.receipt["steps"] if row["id"] == ctx.directory.name)
    cpu = available_processors()
    population, jobs = ((None, cpu) if args.get("operation") else
                        capacity(cpu, len(files), args["regime"] != "whole-sequential",
                                 args.get("processors"), args.get("jobs")))
    return {"candidateReceiptSha256": digest(candidate_receipt), "mode": args["mode"],
            "runtimeTreeId": content_id(tree_identity(runtime)),
            "failureInventorySha256": digest(ctx.root / "evidence/native-failures.json"),
            "reviewRulesSha256": digest(ctx.root / args["reviewRules"]),
            "regime": args["regime"], "selectedFiles": {str(file): digest(tested_unit / file) for file in files},
            "operation": args.get("operation"),
            "suiteBudgetSeconds": step["budgetSeconds"] if suite_budget is None else suite_budget,
            "recipeBudgetSeconds": ctx.receipt["budgetSeconds"],
            "batchBudgetSeconds": args.get("batchBudgetSeconds"),
            "processors": args.get("processors"), "jobs": args.get("jobs"),
            "hostCpuCapacity": cpu, "effectiveProcessors": population, "effectiveJobs": jobs}


def project_review(ctx, document, current, failures, runtime, tested_unit, facts, inputs, *, producer_binding=False):
    from gambit_smp.recipes import fields, read_json, source_path
    fields(document, ("schema", "campaign", "failures"))
    if document["schema"] != SCHEMA or not isinstance(document["failures"], list):
        raise ValueError("typed retry review document required")
    if document["campaign"] != current:
        raise ValueError("retry review must bind the exact candidate, inventory, topology and budgets")
    indexed = {}
    for entry in document["failures"]:
        fields(entry, ("id", "receiptSha256", "baselineIdentity", "failurePointer", "log",
                       "budget", "changes", "claims"))
        if not isinstance(entry["id"], str) or entry["id"] in indexed:
            raise ValueError("unique typed failure review required")
        indexed[entry["id"]] = entry
    if set(indexed) - set(failures):
        raise ValueError("retry review names an unselected or unknown failure")

    def bound(reference):
        fields(reference, ("path", "sha256"))
        path = source_path(ctx.root, reference["path"])
        if digest(path) != reference["sha256"]:
            raise ValueError("retry review evidence identity drift")
        inputs[reference["path"]] = reference["sha256"]
        ctx.bind([path])
        return path

    for route, entry in indexed.items():
        failure, previous = failures[route]
        if entry["receiptSha256"] != inputs[failure["receipt"]]:
            raise ValueError("retry review changed the failure receipt")
        log = bound(entry["log"])
        if failure.get("log") != entry["log"]["path"] or not log.stat().st_size:
            raise ValueError("archived known-failure raw log required")
        # Old execution inputs may be obsolete; the failed observation itself stays immutable.
        outcome = entry["failurePointer"]
        accepted = (isinstance(outcome, str) and re.fullmatch(r"/results/(?:0|[1-9][0-9]*)/accepted", outcome)
                    and pointer(previous, outcome) is False
                    and pointer(previous, outcome.rsplit("/", 1)[0] + "/mode") == current["mode"])
        exited = (isinstance(outcome, str) and re.fullmatch(r"/steps/(?:0|[1-9][0-9]*)/exit", outcome)
                  and type(pointer(previous, outcome)) is int and pointer(previous, outcome) != 0
                  and pointer(previous, outcome.rsplit("/", 1)[0] + "/name") == current["operation"]
                  and current["regime"] == "build-step")
        if not accepted and not exited:
            raise ValueError("retry review must point to an actual unaccepted result")
        baseline_path = bound(entry["baselineIdentity"])
        baseline = read_json(baseline_path)
        if previous.get("candidateReceiptSha256", previous.get("seedReceiptSha256")) != digest(baseline_path):
            raise ValueError("failure does not bind the supplied baseline identity")
        fields(entry["budget"], ("regime", "pointer"))
        regime, budget_pointer = entry["budget"]["regime"], entry["budget"]["pointer"]
        if regime not in {"whole-sequential", "whole-parallel", "atomic-coverage", "build-step"}:
            raise ValueError("original budget regime required")
        allowed = {"atomic-coverage": "/atomicBatchBudgetPerMode", "build-step": "/wholeBootstrapBudget"}.get(
            regime, "/wholeSuiteBudgetPerMode")
        if budget_pointer != allowed:
            raise ValueError("budget pointer must identify the original native budget, not elapsed time")
        original = milliseconds(pointer(previous, budget_pointer))
        facts["review_present"].append([route])
        facts["campaign_bound"].append([route])
        facts["budget_regime"].append([route, regime, current["regime"]])
        axis = "atomic-batch" if regime == "atomic-coverage" else "suite-step"
        facts["required_budget"].append([route, axis])
        facts["original_budget"].append([route, axis, original])
        proposed = current["batchBudgetSeconds"] if axis == "atomic-batch" else current["suiteBudgetSeconds"]
        if proposed is not None:
            facts["requested_budget"].append([route, axis, milliseconds(proposed)])
        if not isinstance(entry["changes"], list) or not isinstance(entry["claims"], list):
            raise ValueError("typed change and claim inventories required")
        change_ids = set()
        for change in entry["changes"]:
            fields(change, ("id", "kind", "path", "before", "after"))
            if any(not isinstance(change[key], str) or not re.fullmatch(r"[0-9a-f]{64}", change[key])
                   for key in ("before", "after")):
                raise ValueError("complete before/after source identities required")
            name = change["path"]
            if not isinstance(change["id"], str) or change["id"] in change_ids:
                raise ValueError("unique change identity required")
            change_ids.add(change["id"])
            if change["kind"] == "source":
                old = baseline["sourceFiles"].get(name)
                actual_path = relative(runtime, name)
            elif change["kind"] == "fixture":
                old = previous["sourceFiles"].get("unit-tests/" + name)
                if name not in current["selectedFiles"]:
                    raise ValueError("fixture change must belong to the selected inventory")
                actual_path = relative(tested_unit, name)
            else:
                raise ValueError("unsupported change domain; environment/tool changes need typed observations")
            if old != change["before"] or digest(actual_path) != change["after"]:
                raise ValueError("change must bind actual baseline and current bytes")
            ctx.bind([actual_path])
            if change["before"] != change["after"]:
                facts["changed_input"].append([route, change["id"], change["kind"], name,
                                               change["before"], change["after"]])
        claim_ids = set()
        for claim in entry["claims"]:
            fields(claim, ("id", "evidence", "pointer"))
            if not isinstance(claim["id"], str) or claim["id"] in claim_ids:
                raise ValueError("unique claim identity required")
            claim_ids.add(claim["id"])
            evidence_path = bound(claim["evidence"])
            evidence = read_json(evidence_path)
            if evidence.get("schema") != "typed-causal-review-evidence.v1":
                raise ValueError("typed causal-review evidence required, not model/local PASS")
            row = pointer(evidence, claim["pointer"])
            fields(row, ("claim", "domain", "status", "failureReceiptSha256", "candidateReceiptSha256",
                         "changes", "premises", "references", "reasoning"))
            candidate_bound = (row["candidateReceiptSha256"] == current["candidateReceiptSha256"] or
                               producer_binding and row["candidateReceiptSha256"] == {"binding": "current-producer"})
            if (row["claim"] != claim["id"] or row["failureReceiptSha256"] != entry["receiptSha256"]
                    or not candidate_bound):
                raise ValueError("causal evidence must bind the failure and exact current candidate")
            if (not isinstance(row["premises"], list) or any(not isinstance(p, str) for p in row["premises"])
                    or not isinstance(row["changes"], list) or not set(row["changes"]) <= change_ids
                    or not isinstance(row["references"], list) or not row["references"]
                    or not isinstance(row["reasoning"], str) or not row["reasoning"].strip()
                    or type(row["domain"]) is not str or type(row["status"]) is not str):
                raise ValueError("explicit causal reasoning, references and typed premise inventory required")
            for ref in row["references"]:
                bound(ref)
            facts["claim_evidence"].append([route, claim["id"], row["domain"], row["status"], digest(evidence_path)])
            facts["claim_dependency"].extend([route, claim["id"], premise] for premise in row["premises"])
            facts["claim_change"].extend([route, claim["id"], change] for change in row["changes"])


def preflight(ctx, args, runtime, candidate_receipt, files, tested_unit, *, document=None, suite_budget=None,
              producer_binding=False):
    from gambit_smp.evidence_capabilities import evaluate_observations
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.suite_primitives import check_runtime
    check_runtime(runtime, read_json(candidate_receipt))
    ctx.bind([candidate_receipt])
    manifest = source_path(ctx.root, args["failures"])
    if manifest != source_path(ctx.root, "evidence/native-failures.json"):
        raise ValueError("suite must use the complete canonical known-failure inventory")
    declared = read_json(manifest)
    if declared.get("schema") != "gambit-local-native-failures.v1" or not isinstance(declared.get("failures"), list):
        raise ValueError("declared failure inventory required")
    rules = source_path(ctx.root, args["reviewRules"])
    engine = manifest_paths(Path(ctx.receipt["engine"]["path"]))
    if digest(rules) != engine["files"].get("policy/suite-review-rules.ss"):
        raise ValueError("retry safety policy must match the sealed engine")
    names = ("retry_marker", "known_failure", "selected_failure", "failure_category", "review_present", "campaign_bound", "budget_regime",
             "required_budget", "original_budget", "requested_budget", "changed_input",
             "claim_evidence", "claim_dependency", "claim_change")
    facts = {name: [] for name in names}
    facts["retry_marker"] = [[True]]
    inputs = {args["failures"]: digest(manifest), args["reviewRules"]: digest(rules)}
    selected = {str(path) for path in files}
    if args.get("operation") is not None:
        selected.add("Makefile:" + args["operation"])
    overlaps, failures = [], {}
    seen = set()
    for failure in declared["failures"]:
        if failure["id"] in seen:
            raise ValueError("duplicate known-failure identity")
        seen.add(failure["id"])
        if not selected_scope(failure["file"], selected):
            continue
        observed = relative(ctx.root, failure["receipt"])
        prior = read_json(observed)
        inputs[failure["receipt"]] = digest(observed)
        denied = {row["mode"] for row in prior.get("results", []) if row.get("accepted") is False and "mode" in row}
        if denied and args["mode"] not in denied:
            continue
        route = failure["id"]
        facts["known_failure"].append([route, args["mode"]])
        facts["selected_failure"].append([route])
        facts["failure_category"].append([route, failure.get("category", "unknown")])
        failures[route] = (failure, prior)
        overlaps.append(route)
    current = campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, suite_budget=suite_budget)
    if document is None and "retryReview" in args:
        if isinstance(args["retryReview"], dict):
            review_path = ctx.artifact(args["retryReview"], "bound-native-review")
            bound_document = read_json(review_path)
            if (bound_document.get("schema") != "bound-native-review.v1"
                    or bound_document.get("candidateReceiptSha256") != digest(candidate_receipt)):
                raise ValueError("bound review producer identity mismatch")
            intent = bound_document["intent"]
            path = source_path(ctx.root, intent["path"])
            if digest(path) != intent["sha256"]:
                raise ValueError("bound review intent changed")
            inputs[intent["path"]] = intent["sha256"]
            ctx.bind([review_path])
            document, producer_binding = bound_document["document"], True
        else:
            review_path = source_path(ctx.root, args["retryReview"])
            inputs[args["retryReview"]] = digest(review_path)
            document = read_json(review_path)
    if document is not None:
        project_review(ctx, document, current, failures, runtime, tested_unit, facts, inputs,
                       producer_binding=producer_binding)
    ctx.bind(ctx.root / name for name in inputs)
    answers = evaluate_observations(ctx, [args["reviewRules"]], facts,
        {"selected": "selected_known_failure", "eligible": "retry_eligible", "denied": "retry_denied",
         "missing": "missing_claim", "review": "review_required", "need": "needed_claim",
         "decision": "retry_decision"}, "retry-review")
    expected = sorted([[route, args["mode"]] for route in overlaps])
    if sorted(answers["selected"]) != expected:
        raise ValueError("native retry rules did not preserve all selected known failures")
    if sorted(answers["eligible"] + answers["review"]) != expected:
        raise ValueError("native retry disposition omitted or duplicated a known failure")
    check_runtime(runtime, read_json(candidate_receipt))
    if campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, suite_budget=suite_budget) != current:
        raise ValueError("candidate campaign or topology drift during native inference")
    if any(digest(ctx.root / name) != expected for name, expected in inputs.items()):
        raise ValueError("retry review input drift during native inference")
    ctx.bind([candidate_receipt])
    decisions = answers["decision"]
    if len(decisions) != 1 or decisions[0][0] not in {"DENY", "REVIEW_REQUIRED", "RETRY_ELIGIBLE", "NOT_REQUIRED"}:
        raise ValueError("native retry policy must return exactly one disposition")
    decision = decisions[0][0]
    return {"schema": "typed-suite-retry-review.v2", "decision": decision, "campaign": current,
            "knownSelectedFailures": overlaps, "answers": answers, "inputs": inputs,
            "facts": facts, "runtimeAdmitted": False, "executionAuthorized": False,
            "policyProgram": "research-suite-review.v1",
            "scope": "Conditional investigation eligibility only. Host authorization and full native results remain independent."}
