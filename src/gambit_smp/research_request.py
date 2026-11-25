"""Use ASCENT requests to select read-only reviews of retained research evidence."""

import re

from gambit_smp.framework import relative
from gambit_smp.recipes import fields


def request_reviews(root, source):
    """Resolve named operand groups without letting a selector grant authority."""
    from ascent import EngineError
    from ascent.trajectory import ClueExchange
    from gambit_smp.ascent_program import engine_api, load_component_catalog, query

    names = ("research_review", "research_operand")
    try:
        request = ClueExchange.parse_request(source)
        fields(request, (), ("bindings", "selector", "constructor"))
        bindings = request.get("bindings", [])
        if "selector" in request:
            with engine_api(retain=True) as (engine, _):
                with engine.evidence(request["selector"], request.get("constructor", "query"),
                                     trusted=True) as session:
                    if bindings:
                        session.replace({"binding": bindings})
                    evaluated = session.run(queries=list(names))
                    if not evaluated["complete"] or evaluated.get("scalarProjection") != "supported":
                        raise ValueError("complete scalar Research selector result required")
                    rows = evaluated["relations"]
        else:
            if "constructor" in request or not bindings:
                raise ValueError("Research review requires bindings or a selector")
            catalog = load_component_catalog(root / "evidence/dsl/components.json", entry="research-request",
                                             constructor="make-research-request", trusted=True)
            rows = query({"binding": bindings}, catalog, {name: name for name in names})
    except EngineError as error:
        raise ValueError(str(error)) from error

    reviews, operands = (rows[name] for name in names)
    if (any(len(row) != 2 or any(type(value) is not str or not value for value in row) for row in reviews)
            or any(len(row) != 3 or any(type(value) is not str or not value for value in row) for row in operands)):
        raise ValueError("Research selectors require string research_review and research_operand rows")
    selected = {name: (kind, {}) for name, kind in reviews}
    if not selected or len(selected) != len(reviews):
        raise ValueError("Research selectors must produce uniquely named reviews")
    for name, key, value in operands:
        if name not in selected or key in selected[name][1]:
            raise ValueError(f"Research operand {key} has no unique review binding for {name}")
        selected[name][1][key] = value
    return selected


def _gate2(root, out, operands):
    from gambit_smp.gate2_evidence import investigation, review_retained_links
    from gambit_smp.gate2_collection import collection_origin

    fields(operands, ("gsiSha256",), ("correspondence", "step", "collect", "subject", "collection", "witness"))
    target = operands["gsiSha256"]
    if not re.fullmatch(r"[0-9a-f]{64}", target):
        raise ValueError("Gate 2 requires a full lowercase GSI SHA-256")
    if "witness" in operands and operands.get("collect") != "native-frame":
        raise ValueError("witness is an input to focused native-frame collection")
    direct = collection_origin(root, out, target, operands.get("step"))
    if direct is not None:
        if "collection" in operands:
            raise ValueError("direct Gate 2 collection read already selects its collection")
        producer, step = direct
        operands = dict(operands, collection=out.relative_to(root).as_posix())
        if step is not None:
            operands["step"] = step
        out = producer
    report = review_retained_links(root, out, target, operands.get("step"),
                                   correspondence=operands.get("correspondence"))
    basis = report
    if "collection" in operands:
        from gambit_smp.gate2_collection import apply_observations, read_collection
        from gambit_smp.recipes import decode_json

        selected = operands["collection"]
        runs = decode_json(selected) if selected.startswith("[") else [selected]
        if not isinstance(runs, list) or not runs or any(not isinstance(name, str) or not name for name in runs):
            raise ValueError("Gate 2 collection requires a retained run or a list of retained runs")
        reports = {name: read_collection(root, relative(root, name), expected_run=out, expected_gsi=target,
                                         expected_step=report.get("bootstrapStep"))
                   for name in dict.fromkeys(runs)}
        if len(reports) == 1:
            report["collectionReview"] = next(iter(reports.values()))
        else:
            report["collectionReviews"] = reports
        if report.get("collectionReady"):
            basis = apply_observations(report, [row for item in reports.values() for row in item["steps"]])
    if direct is not None:
        report["bootstrapRun"] = out.relative_to(root).as_posix()
    report["investigation"] = investigation(basis)
    if "collect" in operands:
        from gambit_smp.gate2_collection import project

        # Plan a semantic collection from the outstanding review. The supplied
        # draft is the proposed evidence that the new Recipe will check.
        plan_basis = basis
        if operands["collect"] == "scheme-gvm" and "correspondence" in operands:
            plan_basis = dict(basis)
            plan_basis.pop("correspondenceReview", None)
            if "collection" in operands and report.get("collectionReady"):
                plan_basis = apply_observations(
                    plan_basis, [row for item in reports.values() for row in item["steps"]])
            plan_basis["investigation"] = investigation(plan_basis)
        if "investigation" not in plan_basis:
            plan_basis = dict(plan_basis, investigation=report["investigation"])
        try:
            report["collectionRecipe"] = project(
                root, out, target, plan_basis, step=operands.get("step"),
                correspondence=operands.get("correspondence"), collect=operands["collect"],
                subject=operands.get("subject"), witness=operands.get("witness"))
        except (OSError, ValueError) as error:
            report["collectionPlan"] = dict(status="BLOCKED", reason=str(error))
    elif "subject" in operands:
        raise ValueError("Gate 2 subject requires a collection selection")
    return report


def _item12_native(audit, projection):
    from gambit_smp.gate2_evidence import SITES

    sites = projection.get("sites", {})
    complete = [site for site in SITES if any(
        row["check"] == "nativeFrameComplete" and row["status"] == "PASS"
        for row in sites.get(site, {}).get("checks", ()))]
    missing = [site for site in SITES if site not in complete]
    audit["links"]["nativeFrame"] = dict(status="MISSING" if missing else "PASS", missingSites=missing)
    if missing:
        audit["passed"] = False
        audit.setdefault("gaps", []).append("native frame correspondence is incomplete for " + ", ".join(missing))
    return complete


def _item12(root, out, operands):
    from gambit_smp.framework import digest
    from gambit_smp.item12_retained import retained_item12
    from gambit_smp.ordered_stress_audit import declares_ordered_stress, runtime_provider
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.research_kernel import bound_child_receipt, inspect
    from gambit_smp.gate2_collection import apply_observations, read_collection
    from gambit_smp.gate2_evidence import investigation, require, review_retained_links
    from gambit_smp.ordered_stress_audit import checked_json

    fields(operands, ("evidence",))
    path = source_path(root, operands["evidence"])
    evidence_sha = digest(path)
    declaration = read_json(path)
    outer = read_json(out / "receipt.json")
    child = bound_child_receipt(out, outer)
    if declaration.get("schema") == "family6-item12-candidate-evidence.v1":
        fields(declaration, ("schema", "gsiSha256", "bootstrap", "sourceLock", "correspondence", "collections"))
        bootstrap = declaration["bootstrap"]
        fields(bootstrap, ("run", "receiptSha256", "step"))
        producer = relative(root, bootstrap["run"])
        checked_json(producer / "receipt.json", bootstrap["receiptSha256"])
        correspondence = declaration["correspondence"]
        fields(correspondence, ("path", "sha256"))
        checked_json(source_path(root, correspondence["path"]), correspondence["sha256"])
        target = declaration["gsiSha256"]
        require(isinstance(target, str) and re.fullmatch(r"[0-9a-f]{64}", target),
                "candidate requires a full lowercase GSI SHA-256")
        basis = review_retained_links(root, producer, target, bootstrap["step"],
                                      correspondence=correspondence["path"])
        require(basis.get("collectionReady") and basis["producerReceiptSha256"] == bootstrap["receiptSha256"],
                basis.get("reason", "candidate lacks completed Make provenance"))
        lock = declaration["sourceLock"]
        fields(lock, ("path", "sha256"))
        require(basis.get("sourceLock") == lock and basis.get("lockedPatch", {}).get("status") == "PASS",
                basis.get("lockedPatch", {}).get("reason", "candidate source lock did not verify"))
        require(isinstance(declaration["collections"], list), "candidate collections must be a list of sealed runs")
        collections = []
        for ref in declaration["collections"]:
            fields(ref, ("run", "receiptSha256"))
            run = relative(root, ref["run"])
            receipt = checked_json(run / "receipt.json", ref["receiptSha256"])
            collections.append(read_collection(root, run, outer=receipt, expected_run=producer,
                                               expected_gsi=target, expected_step=bootstrap["step"]))
        view = apply_observations(basis, [row for collection in collections for row in collection["steps"]])
        projection = investigation(view)
        if declares_ordered_stress(child.get("plannedSteps", child["steps"])):
            audit = inspect(out)["executionSummary"]["item12Audit"]
            require(audit.get("executableSha256") == target, "campaign belongs to another candidate")
        else:
            require(out == producer, "candidate review requires its producer or exact campaign receipt")
            audit = dict(checklist=12, passed=False, runtimeAdmitted=False, executionAuthorized=False,
                         links={"originalCampaign": dict(status="MISSING", reason="no original campaign selected")})
        require(digest(path) == evidence_sha, "candidate evidence declaration changed during read")
        native_complete = _item12_native(audit, projection)
        audit["candidateEvidence"] = dict(gsiSha256=target, sourceLock=lock, makeLineageSha256=basis["makeLineageSha256"],
                                          correspondence=basis["correspondenceReview"], collections=collections,
                                          investigation=projection, nativeSitesComplete=native_complete,
                                          declarationSha256=evidence_sha)
        return dict(status="PASS" if audit["passed"] else "OPEN", item12Audit=audit)
    if declares_ordered_stress(child.get("plannedSteps", child["steps"])):
        audit = inspect(out)["executionSummary"]["item12Audit"]
        if audit.get("executableSha256") != declaration["gsiSha256"]:
            raise ValueError("campaign receipt has no verified binding to the selected GSI")
        step, = [row for row in child["steps"] if "orderedStress" in row.get("arguments", {})]
        expected_identity = runtime_provider(child, step)["outputs"]["identity"]["sha256"]
    elif out != relative(root, declaration["restoration"]["run"]):
        raise ValueError("read the restoration receipt or a campaign on its exact GSI")
    else:
        expected_identity = None
        audit = dict(checklist=12, passed=False, runtimeAdmitted=False, executionAuthorized=False,
                     links={"originalCampaign": dict(status="MISSING", reason="no campaign receipt selected")})
    retained = retained_item12(root, declaration)
    if expected_identity is not None and retained["identitySha256"] != expected_identity:
        raise ValueError("campaign and restoration have different runtime identities")
    audit["retainedEvidence"] = retained
    _item12_native(audit, retained["investigation"])
    if digest(path) != evidence_sha:
        raise ValueError("retained evidence declaration changed during read")
    audit["retainedEvidence"].update(declaration=operands["evidence"], declarationSha256=evidence_sha)
    return dict(status="PASS" if audit["passed"] else "OPEN", item12Audit=audit)


READ_REVIEWERS = {"gate2": _gate2, "item12": _item12}


def inspect_request(root, out, reviews):
    from gambit_smp.artifact_storage import observation_root

    reports = {}
    for name, (kind, operands) in reviews.items():
        reviewer = READ_REVIEWERS.get(kind)
        if reviewer is None:
            reports[name] = dict(kind=kind, status="INVALID", reason=f"unknown Research reviewer: {kind}")
            continue
        inputs = dict(operands)
        run = out
        try:
            if run_name := inputs.pop("run", None):
                run = relative(root, run_name)
                observation_root(root, run)
            report = reviewer(root, run, inputs)
        except (OSError, ValueError) as error:
            report = dict(status="INVALID", reason=str(error))
        reports[name] = dict(report, kind=kind, run=str(run))
    return dict(reviews=reports, executionLaunched=False, executionAuthorized=False, runtimeAdmitted=False)
