"""Failed concrete suite routes require evidence review before execution."""
import json
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp import research_audit as audit


def preflight(root, runtime, candidate_receipt, files, modes, budget, hypotheses=None,
              tested_unit=None):
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
    for failure in failures:
        fixture = failure["file"]
        if fixture not in selected:
            continue
        old_path = audit.local(root, failure["receipt"])
        old = json.loads(old_path.read_text())
        inputs[failure["receipt"]] = digest(old_path)
        denied_modes = {row["mode"] for row in old.get("results", [])
                        if row.get("accepted") is False and "mode" in row}
        if not fixture.endswith(".scm") or not denied_modes:
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
    rules = root / "evidence/research-rules.dl"
    inputs["evidence/research-rules.dl"] = digest(rules)
    inputs["evidence/rules.dl"] = digest(root / "evidence/rules.dl")
    execution_inputs = dict(inputs)
    base = audit.index.export(root=root)
    inputs.update(base["inputs"])
    queries = audit.query(base, facts, root)
    if any(digest(audit.local(root, name)) != sha for name, sha in inputs.items()):
        raise ValueError("retry preflight inputs changed during observation")
    denials = queries["retry_denials"]
    decision = ("DENY" if denials else "REVIEW_REQUIRED" if routes or unsupported
                else "NOT_REQUIRED")
    return {"schema": "gambit-suite-retry-preflight.v1", "decision": decision,
            "runtimeAdmitted": False, "routes": routes,
            "unsupportedSelectedFailures": sorted(set(unsupported)),
            "retryDenials": denials,
            "reviewRequired": queries["retry_review_required"], "inputs": inputs,
            "executionInputs": execution_inputs,
            "scope": "concrete selected file/mode failures only; directory, whole-suite and bootstrap denials remain separate obligations"}
