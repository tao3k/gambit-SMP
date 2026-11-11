"""Render a bounded model task brief from ASCENT review conclusions."""


def render(model, facts, rows, bindings, failures, observations, source_facts):
    candidate = "task:" + model
    needs = {claim for name, claim in rows["Need"] if name == candidate}
    missing = {claim for name, claim in rows["Missing"] if name == candidate}
    required_models = {claim.removeprefix("finite-model:") for claim in needs
                       if claim.startswith("finite-model:")}
    current = dict(facts["CurrentInput"])
    invalid = {}
    for receipt, reason in rows["Unusable"]:
        invalid.setdefault(receipt, []).append(reason)

    reusable = []
    unusable = []
    unverified = []
    for receipt, claim in sorted({tuple(row) for row in facts["Passed"]}):
        if claim not in needs:
            continue
        spec = bindings.get(receipt, {})
        entry = {"claim": claim, "receipt": receipt,
                 "path": spec.get("path"),
                 "binding": spec.get("binding", "catalog-fallback"),
                 "inputPaths": sorted(spec.get("inputs", {})),
                 "receiptDependencies": spec.get("depends", []),
                 "supersededVerifierInputs": spec.get("supersededVerifierInputs", [])}
        if spec.get("recordedOutputPending"):
            entry["reasons"] = ["missing-recorded-output-evidence"]
            unverified.append(entry)
        elif receipt in invalid:
            entry["reasons"] = sorted(set(invalid[receipt]))
            entry["changedInputs"] = sorted(name for name, expected in
                spec.get("inputs", {}).items() if current.get(name) != expected)
            unusable.append(entry)
        elif [receipt, claim] in rows["Reusable"]:
            reusable.append(entry)

    related_failures = [
        {"id": failure["id"], "receipt": failure["receipt"],
         "scope": failure["file"], "recordedResult": failure["status"],
         "routeDecision": next((decision for name, decision in rows["Denial"]
                                if name == failure["id"]), "review-required")}
        for failure in failures if required_models.intersection(failure["models"])]
    related_issues = [
        {"id": issue["id"], "priority": issue["priority"],
         "next": issue["next"], "evidence": [item["path"] for item in issue["evidence"]]}
        for issue in observations if required_models.intersection(issue["models"])]
    source = [item for name, item in source_facts.get("protocol_source", [])
              if name in required_models]
    source.extend(item for name, item in source_facts.get("source_obligation", [])
                  if name in required_models)
    target = "finite-model:" + model
    target_reusable = any(row["claim"] == target for row in reusable)
    open_models = sorted(claim for claim in missing if claim.startswith("finite-model:"))
    open_native = sorted(claim for claim in missing if claim.startswith("native-obligation:"))
    return {
        "schema": "gambit-task-brief.v1", "task": model,
        "requiredModelClaims": sorted(required_models),
        "reusable": sorted(reusable, key=lambda row: row["receipt"]),
        "invalidated": sorted(unusable, key=lambda row: row["receipt"]),
        "unverified": sorted(unverified, key=lambda row: row["receipt"]),
        "openPremises": sorted(missing),
        "openModelClaims": open_models,
        "openNativeObligations": open_native,
        "knownFailedRoutes": related_failures,
        "reviewedCausalLinks": [list(row) for row in rows["CausalEvidence"]
                                if row[0] == candidate],
        "relatedAuditIssues": related_issues,
        "sourceReferences": sorted(set(source)),
        "gates": {
            "finiteModelReceipt": "admitted" if target_reusable else "open",
            "componentPremises": "open" if open_models else "satisfied-in-snapshot",
            "sourceCorrespondence": "open",
            "nativeGcAndLifecycle": "open",
            "fullBootstrap": "open",
            "gerbilBuildAndFullTests": "open",
        },
        "metrics": {
            "reusableReceipts": len(reusable),
            "invalidatedReceipts": len(unusable),
            "unverifiedReceipts": len(unverified),
            "recordedFailedRoutes": len(related_failures),
            "actualRerunsAvoided": 0,
            "actualRerunsAvoidedMeasured": False,
        },
        "runtimeAdmitted": False,
        "scope": "Current source-bound finite evidence and recorded failures. This brief does not authorize a retry or establish a native result.",
    }
