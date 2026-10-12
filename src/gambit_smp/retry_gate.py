"""Failed concrete suite routes require evidence review before execution."""
import json
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp import research_audit as audit


def selected_failure(fixture, selected):
    """Legacy catalog scopes: concrete fixture, directory, or suite driver."""
    path = Path(fixture)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("failure scope must be repository-relative")
    if fixture == "tests/run-unit-tests.scm":
        return bool(selected)
    if fixture in selected:
        return True
    if not path.suffix and ":" not in fixture:
        return any(path in Path(name).parents for name in selected)
    return False


def preflight(root, runtime, candidate_receipt, files, modes, budget, hypotheses=None,
              tested_unit=None, scope_review=None):
    root = root.resolve()
    runtime = runtime.resolve()
    candidate_receipt = candidate_receipt.resolve()
    tested_unit = (tested_unit or runtime / "tests/unit-tests").resolve()
    tested_unit.relative_to(root)
    manifest = root / "evidence/native-failures.json"
    failures = json.loads(manifest.read_text())["failures"]
    selected = {str(path) for path in files}
    facts = {name: [] for name in audit.ARITIES}
    inputs = {"evidence/native-failures.json": digest(manifest)}
    routes, unsupported = [], []
    reviewed = []
    review = json.loads(scope_review.read_text()) if scope_review else None
    if review:
        if (review.get("schema") != "gambit-aggregate-retry-review.v1"
                or review.get("candidateReceiptSha256") != digest(candidate_receipt)
                or review.get("modes") != sorted(modes)
                or review.get("budgetSeconds") != budget
                or review.get("selectedFiles") != {
                    name: digest(audit.local(tested_unit, name)) for name in sorted(selected)}):
            raise ValueError("scope review does not bind this exact candidate and campaign")
        inputs[str(scope_review.resolve().relative_to(root))] = digest(scope_review)
        if not review.get("references"):
            raise ValueError("scope review requires durable source/model evidence")
        for name, expected in review["references"].items():
            if any(part in {".data", ".cache"} for part in Path(name).parts):
                raise ValueError("scope review evidence cannot depend on a cache")
            path = audit.local(root, name)
            if digest(path) != expected:
                raise ValueError("stale scope review evidence")
            inputs[name] = expected
    for failure in failures:
        fixture = failure["file"]
        if not selected_failure(fixture, selected):
            continue
        old_path = audit.local(root, failure["receipt"])
        old = json.loads(old_path.read_text())
        inputs[failure["receipt"]] = digest(old_path)
        denied_modes = {row["mode"] for row in old.get("results", [])
                        if row.get("accepted") is False and "mode" in row}
        if denied_modes and not set(modes) & denied_modes:
            continue
        if fixture not in selected or not fixture.endswith(".scm") or not denied_modes:
            entry = review.get("failures", {}).get(failure["id"]) if review else None
            if entry:
                candidate = json.loads(candidate_receipt.read_text())
                old_budget = old.get("atomicBatchBudgetPerMode") or old.get("wholeSuiteBudgetPerMode")
                old_selected = old.get("selectedFiles", [])
                if (failure.get("category") != "budget" or not denied_modes
                        or len(selected) >= len(old_selected)
                        or not isinstance(old_budget, (int, float)) or budget > old_budget
                        or entry.get("receiptSha256") != digest(old_path)
                        or not entry.get("cause", "").strip()
                        or not entry.get("expectedObservation", "").strip()
                        or not old.get("gscSha256") or not old.get("gsiSha256")
                        or candidate.get("gscSha256") == old["gscSha256"]
                        or candidate.get("binarySha256") == old["gsiSha256"]):
                    raise ValueError("aggregate review cannot waive unchanged or non-budget failures")
                for field, name in (("binarySha256", "gsi/gsi"), ("gscSha256", "gsc/gsc")):
                    actual = digest(runtime / name)
                    if actual != candidate.get(field):
                        raise ValueError("scope review candidate binary drift")
                    inputs[str((runtime / name).relative_to(root))] = actual
                reviewed.append(failure["id"])
                facts["retry_aggregate_review"].append((failure["id"],))
                continue
            unsupported.append(failure["id"])
            continue
        for mode in sorted(set(modes) & denied_modes):
            if not (runtime / "tests/unit-tests" / fixture).is_file():
                unsupported.append(failure["id"] + ":" + mode)
                continue
            proposal = {"schema": "gambit-retry-proposal.v1",
                        "failure": failure["id"],
                        "candidateReceipt": str(candidate_receipt.relative_to(root)),
                        "runtime": str(runtime.relative_to(root)),
                        "fixture": fixture, "mode": mode, "budgetSeconds": budget,
                        "hypothesis": (hypotheses or {}).get(failure["id"], {})}
            extra, bound, changes = audit.retry_facts(root, proposal)
            tested = audit.local(tested_unit, fixture)
            inputs[str(tested.relative_to(root))] = digest(tested)
            before = old.get("sourceFiles", {}).get("unit-tests/" + fixture)
            before = old.get("extraFixtures", {}).get(fixture, {}).get("testedSha256", before)
            for fixture_patch in old.get("fixturePatches", []):
                before = fixture_patch.get("derivedFiles", {}).get("unit-tests/" + fixture, before)
            # Compare the tested snapshot, not the unpatched original. Keep
            # the audit's strict binary-root containment unchanged.
            changes = [change for change in changes if change != "fixtureSha256"]
            if before is not None and digest(tested) != before:
                changes.append("fixtureSha256")
            extra["retry_delta"] = [(failure["id"],)] if changes else []
            inputs.update(bound)
            # Route identities include the mode: two denied modes must not
            # accidentally merge a changed and unchanged comparison in Datalog.
            route = failure["id"] + ":" + mode
            for name, rows in extra.items():
                facts[name].extend((route, *row[1:]) for row in rows)
            routes.append({"failure": failure["id"], "mode": mode,
                           "fixture": fixture, "route": route,
                           "changedTestedInputs": changes})
    rules = root / "evidence/research-rules.ss"
    inputs["evidence/research-rules.ss"] = digest(rules)
    inputs["evidence/catalog.ss"] = digest(root / "evidence/catalog.ss")
    execution_inputs = dict(inputs)
    base = audit.index.export(root=root)
    inputs.update(base["inputs"])
    backend = {}
    queries = audit.query(base, facts, root, metrics=backend)
    if any(digest(audit.local(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("retry preflight inputs changed during observation")
    denials = queries["retry_denials"]
    verified_reviews = {row[0] for row in queries["reviewed_aggregate_scopes"]}
    if verified_reviews != set(reviewed):
        raise ValueError("native audit did not confirm reviewed aggregate scopes")
    decision = ("DENY" if denials else "REVIEW_REQUIRED" if routes or unsupported
                else "SCOPED_REVIEWED" if reviewed else "NOT_REQUIRED")
    from gambit_smp.reasoning_history import record, fingerprint
    scope = "retry:" + fingerprint({"files": sorted(selected), "modes": sorted(modes)})
    history = record(root, scope, inputs, queries, backend)
    if any(digest(audit.local(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("retry inputs changed during history recording")
    return {"schema": "gambit-suite-retry-preflight.v1", "decision": decision,
            "runtimeAdmitted": False, "routes": routes,
            "unsupportedSelectedFailures": sorted(set(unsupported)),
            "reviewedAggregateScopes": sorted(verified_reviews),
            "retryDenials": denials,
            "reviewRequired": queries["retry_review_required"], "inputs": inputs,
            "backend": backend,
            "history": history,
            "executionInputs": execution_inputs,
            "scope": "concrete file/mode identity comparisons; overlapping directory and whole-suite failures require explicit review, without attributing the aggregate failure to every file; bootstrap remains a separate gate"}
