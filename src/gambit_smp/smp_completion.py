"""Validate the first-three-family source cut without changing its producer."""
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.native_development import generated_inventory
from gambit_smp.runtime_binding import authenticate_distribution_predecessor
from gambit_smp.suite_coverage import (
    SMP_LEDGER_FOLDER, _load_smp_evidence, accepted_smp_progress,
)


def complete_mvp(root, workspace, producer_path, acceptance_path):
    """Issue a scoped source receipt after native and family revalidation.

    The caller holds the existing task and build-workspace leases. The producer
    envelope's monolithic-check and publication flags remain its own facts.
    """
    root, workspace = Path(root).resolve(), Path(workspace)
    producer, producer_ref = _load_smp_evidence(root, producer_path)
    packet, acceptance_ref = _load_smp_evidence(root, acceptance_path)
    accepted = accepted_smp_progress(
        root, SMP_LEDGER_FOLDER / "smp-acceptance.json", acceptance_path)
    if (accepted["closed"] != ["bootstrap", "gsi", "gsc"]
            or accepted["passed"] != 3 or packet.get("mvpAdmitted") is not True
            or accepted["sourceTree"] != producer.get("targetTree")):
        raise ValueError("exact first-three-family MVP acceptance required")
    bootstrap, _ = _load_smp_evidence(
        root, accepted["receipts"]["bootstrap"]["path"],
        accepted["receipts"]["bootstrap"]["sha256"])
    if (bootstrap["producerSha256"] != producer_ref["sha256"]
            or bootstrap["phaseCounts"] != producer.get("phaseCounts")
            or bootstrap["artifacts"] != producer.get("artifacts")):
        raise ValueError("MVP producer differs from the actual accepted producer")
    # Checks the ordered real bootstrap/core commands, original limits and
    # every current canonical source, generated input and linked product.
    authenticate_distribution_predecessor(workspace, producer)
    generated = generated_inventory(workspace)
    if not generated or generated != producer.get("generatedArtifacts"):
        raise ValueError("complete current generated cohort required")
    if len(generated) != 51:
        raise ValueError("frozen first-three MVP requires its declared 51 generated files")
    gsc_ref = accepted["receipts"]["gsc"]
    gsc, _ = _load_smp_evidence(root, gsc_ref["path"], gsc_ref["sha256"])
    if (gsc.get("wholeBudgetSeconds") != 300 or gsc.get("jobs") != 5
            or gsc.get("counters") != {"PASS": 408}
            or len(gsc.get("caseObservations", [])) != 408
            or any(row.get("status") != "PASS" for row in gsc["caseObservations"])):
        raise ValueError("one complete original 408-case GSC campaign required")
    from gambit_smp.native_capabilities import validate_suite
    request = gsc.get("suiteRequest", {})
    if request.get("sharedAssertions") is not True or not gsc.get("validationInputs"):
        raise ValueError("source-bound shared assertion suite entry required")
    validate_suite(request, gsc.get("declaredSuiteInputs", {}))
    for name, expected in gsc["validationInputs"].items():
        path = Path(name)
        if path.is_absolute() or ".." in path.parts or digest(root / path) != expected:
            raise ValueError("MVP suite execution input changed")
    if (producer.get("heapRaised") is not False or producer.get("waitExtended") is not False
            or producer.get("wholeLimitSeconds") != 600):
        raise ValueError("original producer resource limits required")
    return dict(
        schema="independent-smp-first-three-native",
        qualificationKind="independent-smp-first-three",
        complete=True, completeScope="bootstrap-stock-core-original-gsi-original-gsc",
        baseRevision=producer["baseRevision"], targetTree=producer["targetTree"],
        profileSha256=accepted["profileSha256"],
        producerReference=producer_ref, acceptanceReference=acceptance_ref,
        producerEnvelope=dict(complete=producer["complete"],
                              producerComplete=producer["producerComplete"],
                              generatedProductsPublished=producer["generatedProductsPublished"]),
        canonicalSources=producer["canonicalSources"],
        generatedArtifacts=generated, artifacts=producer["artifacts"],
        generatedProductsReady=True, generatedProductsPublished=False,
        phaseCounts=producer["phaseCounts"], acceptedFamilies=accepted["closed"],
        familyReceipts=accepted["receipts"], sourceCopies=0,
        suiteValidationInputs=gsc["validationInputs"],
        heapRaised=False, waitExtended=False, wholeSmpAdmitted=False,
    )


def validate_mvp_completion(root, workspace, receipt):
    """Reject a flag-only wrapper, stale receipt or changed physical cohort."""
    if (receipt.get("schema") != "independent-smp-first-three-native"
            or receipt.get("qualificationKind") != "independent-smp-first-three"):
        raise ValueError("typed first-three source completion required")
    expected = complete_mvp(
        root, workspace, receipt["producerReference"]["path"],
        receipt["acceptanceReference"]["path"])
    actual = {key: value for key, value in receipt.items() if key != "deliveryEvidence"}
    if actual != expected:
        raise ValueError("MVP completion differs from its validated native scope")
    return expected
