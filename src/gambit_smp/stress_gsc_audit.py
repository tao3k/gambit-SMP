"""Offline 6-link cryptographic auditor for Family 7 (7/12: stress-gsc).

Verifies one committed Research run of the original compiled stress campaign
(unchanged 4 stress fixtures, mode="gsc", p2/jobs=3 then p1/jobs=4 inside one
shared 295/300-second clock) bound to the exact same sealed producer as Link 4
(3-phase .c/.o1 SHA-256 binding, Compiled-Host Translation Validation, native
.o1 wire-trace controls, and 5 mutated-host negative controls) and Link 5
(SysML, Quint, Lean 4, and CBMC formal models), with peak compiler RSS < 8 GiB.
"""

import hashlib
from pathlib import Path

from gambit_smp.framework import digest, relative
from gambit_smp.ordered_stress_audit import (
    INNER_SECONDS,
    READ_ERRORS,
    TOPOLOGIES,
    WHOLE_SECONDS,
    check_make_lineage,
    check_source_lock,
    checked_json,
    command_result,
    committed_header,
    passed_step,
    require,
    runtime_provider,
    step_file,
)
from gambit_smp.recipes import artifact_path
from gambit_smp.rest_observation import runtime_identity_bytes
from gambit_smp.suite_primitives import (
    admitted_processors,
    admitted_suite,
    completed_unit_cases,
    partitions,
    runner_option,
)

MAX_COMPILER_RSS_BYTES = 8 * 1024 * 1024 * 1024  # 8 GiB hard limit
STRESS_GSC_MANIFEST = "evidence/research/retained/modern-c/stress-gsc/manifest.json"
ORIGINAL_GSC_STRESS_SPEC = (
    "gsc",
    "stress",
    ";".join(str(processors) for _, processors, _ in TOPOLOGIES),
    ";".join(f"{processors}:{jobs}" for _, processors, jobs in TOPOLOGIES),
    INNER_SECONDS,
    WHOLE_SECONDS,
)
REQUIRED_STRESS_FILES = sorted([
    "06-thread/tfib_stress.scm",
    "06-thread/thread_interrupt2_stress.scm",
    "06-thread/thread_interrupt_stress.scm",
    "06-thread/thread_terminate_stress.scm",
])
FORMAL_MODEL_ARTIFACTS = (
    "dev/refactoring/modern-c/models/sysml/stress-gsc-acceptance.sysml",
    "dev/refactoring/modern-c/models/sysml/smp-dev-composition.sysml",
    "dev/refactoring/modern-c/models/quint/compiled_host_admission.qnt",
    "dev/refactoring/modern-c/models/lean/CompiledHostRefinement.lean",
    "tests/contracts/modern-c/compiled-host/macro-equivalence/harness.c",
)


def stress_gsc_compiled_host_check(ctx, plan, candidate, deadline):
    """Preflight check executed by ordered_stress_suite in mode='gsc' before running stress."""
    import time

    ref = plan.get("compiledHostReceipt")
    if not isinstance(ref, str) or not ref:
        raise ValueError("compiled ordered stress requires a Link 4 compiledHostReceipt")
    receipt_path = relative(ctx.root, ref)
    ctx.bind([receipt_path])
    receipt_sha = digest(receipt_path)
    receipt = checked_json(receipt_path, receipt_sha)
    verify_compiled_host_receipt(receipt, candidate)
    if time.monotonic() >= deadline:
        raise TimeoutError("compiled ordered stress inner deadline exhausted at Link 4 preflight")
    return dict(
        schema="stress-gsc-link4-preflight.v1",
        canStart=True,
        receipt=ref,
        receiptSha256=receipt_sha,
        gsiSha256=candidate["binarySha256"],
        gscSha256=candidate["gscSha256"],
        validatedModules=len(receipt["modules"]),
        negativeControlsPassed=receipt["negativeControls"]["passed"],
        nativeControlsPassed=receipt["nativeControls"]["passed"],
        peakCompilerRssBytes=receipt.get("peakCompilerRssBytes", 0),
        runtimeAdmitted=False,
    )


def verify_compiled_host_receipt(receipt: dict, candidate: dict) -> dict:
    """Verify Link 4 (3-phase .c/.o1 binding + TV + native .o1 controls + 5 negatives)."""
    require(receipt.get("schema") == "family7-compiled-host-validation.v1",
            "compiledHostReceipt has wrong schema")
    require(receipt.get("passed") is True,
            "compiledHostReceipt did not pass all compiled-host gates")
    producer = receipt.get("producer") or {}
    require(producer.get("gsiSha256") == candidate.get("binarySha256")
            and producer.get("gscSha256") == candidate.get("gscSha256")
            and producer.get("runtimeIdentitySha256") == hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest(),
            "Link 4 compiled-host receipt refers to a different sealed gsc/gsi producer")
    peak_rss = receipt.get("peakCompilerRssBytes", 0)
    require(isinstance(peak_rss, int) and 0 <= peak_rss < MAX_COMPILER_RSS_BYTES,
            f"Link 4 peak compiler RSS {peak_rss} exceeds 8 GiB limit")

    modules = receipt.get("modules") or []
    require(sorted(m.get("target") for m in modules) == REQUIRED_STRESS_FILES,
            "Link 4 must validate all four unchanged stress fixtures")
    for mod in modules:
        require(mod.get("passed") is True and mod.get("rssGuardSafe") is True
                and 0 < mod.get("labelCount", 0) < 6000
                and mod.get("violationCount") == 0,
                f"Link 4 translation validation failed for {mod.get('target')}")
        for key in ("sourceSha256", "cSha256", "o1Sha256"):
            val = mod.get(key)
            require(isinstance(val, str) and len(val) == 64,
                    f"Link 4 missing {key} artifact digest for {mod.get('target')}")
        require(mod.get("dlopenExecutionPassed") is True,
                f"Link 4 dynamic .o1 execution check failed for {mod.get('target')}")

    neg = receipt.get("negativeControls") or {}
    require(neg.get("passed") is True and neg.get("total") == 5
            and len(neg.get("controls", [])) == 5
            and all(c.get("passed") is True and c.get("rejected") is True for c in neg["controls"]),
            "Link 4 requires all 5 mutated-host negative controls to be rejected")

    native = receipt.get("nativeControls") or {}
    require(native.get("passed") is True
            and native.get("shortageGcReloadWriteCommitPassed") is True
            and native.get("crossModuleInterruptUnwindPassed") is True
            and native.get("oneWordShortRefusalPassed") is True,
            "Link 4 native .o1 wire-trace controls incomplete or failed")

    return dict(
        modules=len(modules),
        maxLabelCount=max(m["labelCount"] for m in modules),
        peakCompilerRssBytes=peak_rss,
        negativeControls=neg["total"],
        nativeControlsPassed=True,
    )


def verify_formal_models_link(root: Path, manifest: dict) -> dict:
    """Verify Link 5 formal-model SHA-256 bindings against the live workspace."""
    model_inputs = manifest.get("modelInputs") or {}
    verified = {}
    for rel in FORMAL_MODEL_ARTIFACTS:
        expected = model_inputs.get(rel)
        require(isinstance(expected, str) and len(expected) == 64,
                f"stress-gsc manifest missing formal model digest: {rel}")
        actual = digest(relative(root, rel))
        require(actual == expected, f"formal model digest drift: {rel}")
        verified[rel] = actual
    return dict(verifiedModels=len(verified), digests=verified)


def _check_sealed_producer_gsc(runtime: Path, candidate: dict, origin: dict | None) -> dict:
    gsi_sha = digest(relative(runtime, "gsi/gsi"))
    gsc_sha = digest(relative(runtime, "gsc/gsc"))
    lib_sha = digest(relative(runtime, "lib/libgambit.a"))
    hdr_sha = digest(relative(runtime, "include/gambit.h"))
    bld_sha = digest(relative(runtime, "bin/gambuild-C"))
    require(gsi_sha == candidate["binarySha256"],
            "retained GSI bytes differ from the campaign receipt")
    require(gsc_sha == candidate["gscSha256"],
            "retained GSC bytes differ from the campaign receipt")
    if origin and origin["bootstrap"].get("makeLineage"):
        original = origin["bootstrap"]["outputs"]
        imported = origin["provider"]["outputs"]
        binding = origin["bootstrap"]["makeLineage"]
        identity = checked_json(artifact_path(origin["run"], original["identity"]), original["identity"]["sha256"])
        require(original["identity"]["sha256"] == imported["identity"]["sha256"]
                and original["runtime"]["identity"] == imported["runtime"]["identity"]
                and candidate == identity and candidate["makeLineage"] == binding
                and candidate["binarySha256"] == binding["gsiSha256"],
                "bootstrap Make link and campaign refer to different sealed producer bytes")
    return dict(gsiSha256=gsi_sha, gscSha256=gsc_sha, libgambitSha256=lib_sha,
                gambitHeaderSha256=hdr_sha, gambuildCSha256=bld_sha)


def _audit_compiled_topology(run, step, row, commands, runtime, clock, started, deadline, errors):
    population, jobs = row["processors"], row["jobs"]
    prefix = f"p{population}-"
    executable = str(runtime / "gsi/gsi")
    option = f"p{population},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    cases = {case["file"]: case for case in row["cases"]}
    windows = []
    expected = set()

    def observe(suffix, argv):
        name = prefix + suffix
        expected.add(name)
        if name not in commands:
            return None
        command = commands[name]
        try:
            env = command["environment"]
            require(env["GAMBOPT"] == option and env["GAMBIT_SMP_EXPECTED_PROCESSORS"] == str(population),
                    f"{name}: wrong fixture population")
            output, timing, natural = command_result(run, step, command, clock, started, deadline,
                                                     [executable, *argv])
            windows.append(timing)
            return output, natural, command
        except READ_ERRORS as error:
            errors.append(f"{name}: {error}")
            return None

    probes = []
    for role, option_arg, count in (("runner", "p1", 1), ("fixture", "debug-settings=-,io-settings=lu", population)):
        probe = observe("topology-" + role, ["-:" + option_arg, "-e",
                        '(println "PROCESSORS:" (##current-vm-processor-count))'])
        probes.append(bool(probe and probe[1] and admitted_processors(0, probe[0], False, count)))
    probe_windows = len(windows)
    shards = []
    for index, group in enumerate(partitions(list(cases), jobs)):
        result = observe(f"suite-0-{index}", ["-:" + runner_option(option), "-f", "run-unit-tests.scm",
                         "-gsc", "-stress", *["unit-tests/" + file for file in group]])
        if result is None:
            continue
        output, natural, command = result
        try:
            counters = completed_unit_cases(group, output)
        except ValueError as error:
            errors.append(f"{command['stage']}: {error}")
            continue
        shard_passed = natural and admitted_suite(command["exit"], output, command["timeout"], len(group))
        shards.append(shard_passed)
        for counter in counters:
            case = cases[counter["file"]]
            case.update(command=command["stage"], runnerCounter=counter["status"],
                        exit=command["exit"], timeout=command["timeout"])
            if counter["status"] == "FAIL":
                case.update(status="FAILED", reason="original-runner-failure")
            elif counter["status"] == "PASS":
                case.update(status="COMPLETED")
        if not shard_passed:
            active = next((cases[file] for file in group if cases[file]["runnerCounter"] == "UNRESOLVED"), None)
            if active and any(line.startswith("[") and line.rstrip().endswith(" " + active["file"])
                              for line in output.splitlines()):
                active.update(status="FAILED", reason="timeout" if command["timeout"] else "runner-did-not-complete")
            errors.append(f"{command['stage']}: original compiled runner did not exit naturally with all cases complete")
    budget_probe = f"{prefix}retry-review-budget-compiler-version"
    actual = {name for name in commands if name.startswith(prefix) and name != budget_probe}
    if not actual <= expected:
        errors.append(f"p{population}: unexpected compiled campaign command inventory")
    ordered = (probe_windows == 2 and windows[0]["endedMonotonic"] <= windows[1]["startedMonotonic"]
               and all(window["startedMonotonic"] >= windows[1]["endedMonotonic"] for window in windows[2:]))
    row["complete"] = (ordered and all(probes) and all(shards)
                       and all(case["status"] == "COMPLETED" for case in cases.values()))
    return windows, actual


def stress_gsc_audit(out, outer, child, *, checkpoint=None):
    """Audit all 6 Family 7 (stress-gsc) cryptographic links from one committed Research run."""
    links = {
        name: dict(status="BLOCKED", reason="requires a verified compiled stress campaign receipt and its dependencies")
        for name in (
            "sourceLock",
            "makeLineage",
            "sealedProducer",
            "compiledHostValidation",
            "formalModelsAndContracts",
            "originalCompiledCampaign",
        )
    }
    result = dict(
        family="stress-gsc",
        checklist=12,
        passed=False,
        innerBudgetSeconds=INNER_SECONDS,
        wholeBudgetSeconds=WHOLE_SECONDS,
        maxCompilerRssBytes=MAX_COMPILER_RSS_BYTES,
        topologies=[],
        links=links,
        gaps=[],
        executionAuthorized=False,
        runtimeAdmitted=False,
    )
    errors = result["gaps"]

    def failure(name, error):
        missing = isinstance(error, (FileNotFoundError, KeyError, StopIteration))
        reason = f"missing field or binding: {error}" if isinstance(error, KeyError) else str(error)
        reason = reason or "required evidence is missing"
        links[name] = dict(status="MISSING" if missing else "MISMATCH", reason=reason)
        errors.append(reason)

    def verify(name, action):
        try:
            evidence = action()
        except READ_ERRORS as error:
            failure(name, error)
            return None
        links[name] = dict(status="PASS")
        return evidence

    try:
        root = Path(outer["root"])
        files = list(REQUIRED_STRESS_FILES)
        result["topologies"] = [
            dict(checklist=item, processors=p, jobs=jobs, complete=False,
                 cases=[dict(file=file, status="MISSING") for file in files])
            for item, p, jobs in TOPOLOGIES
        ]
        if child is None:
            raise FileNotFoundError("sealed campaign has no verified child receipt")
        steps = [row for row in child["steps"] if "orderedStress" in row.get("arguments", {})]
        require(len(steps) == 1 and steps[0]["capability"] == "gambit.suite"
                and steps[0]["arguments"].get("mode") == "gsc",
                "one original compiled ordered stress step (mode=gsc) is required")
        step = steps[0]
        header = committed_header(out, outer, child, [step], checkpoint)
        provider = runtime_provider(child, step)
        run = out / "run"

        plan = step["arguments"]["orderedStress"]
        manifest_path = relative(root, plan["manifest"])
        manifest_sha = outer["inputs"][plan["manifest"]]
        manifest = checked_json(manifest_path, manifest_sha)
        profile_path = relative(root, plan["profile"])
        profile_sha = outer["inputs"][plan["profile"]]
        require(digest(profile_path) == profile_sha, "compiled campaign profile changed")
        original = checked_json(relative(root, plan["inputReceipt"]), outer["inputs"][plan["inputReceipt"]])["originalCampaign"]
        spec = manifest["spec"]
        require(profile_sha == original["profileSha256"] == spec["profile"]
                and (spec["mode"], spec["inventory"], spec["processors"], spec["jobs"],
                     spec["innerSeconds"], spec["wholeSeconds"]) == ORIGINAL_GSC_STRESS_SPEC
                and spec.get("maxCompilerRssGiB") == 8
                and sorted(case["target"] for case in manifest["cases"]) == files
                and sorted(step["arguments"]["expectedFiles"]) == files
                and all(case["kind"] == "original-stress" and case["seconds"] == 0
                        and original["testInputFiles"].get("unit-tests/" + case["target"]) == case["sha256"]
                        for case in manifest["cases"]),
                "compiled stress campaign differs from the original manifest or profile")
        inputs = original["testInputFiles"]

        # Link 5: Formal Models & Contracts
        models_info = verify("formalModelsAndContracts", lambda: verify_formal_models_link(root, manifest))
        if models_info:
            links["formalModelsAndContracts"].update(models_info)

        # Link 1 & 2: Source Lock & Make Lineage
        origin = verify("sourceLock", lambda: check_source_lock(root, outer, child, provider))
        if origin:
            links["sourceLock"].update(
                path=origin["lock"],
                sha256=origin["sha"],
                producerReceiptSha256=origin["proof"]["outerReceiptSha256"],
                worktreeFiles=origin.get("worktreeFiles") or {},
            )
            lineage = verify("makeLineage", lambda: check_make_lineage(origin, profile_sha))
            if lineage:
                links["makeLineage"].update(lineage[0])

        # Link 3: Sealed Producer (gsc + gsi + libgambit.a + gambit.h + gambuild-C)
        def _bind_producer():
            runtime_output = provider["outputs"]["runtime"]
            runtime = artifact_path(run, runtime_output, root=root)
            identity = provider["outputs"]["identity"]
            identity_path = artifact_path(run, identity, root=root)
            candidate = checked_json(identity_path, identity["sha256"])
            observed = step["observedInputs"]
            require(runtime_output["type"] == "source-runtime" and identity["type"] == "runtime-identity"
                    and candidate["schema"] == "gambit-recipe-runtime-identity.v1"
                    and candidate["binarySha256"] == observed[str(relative(runtime, "gsi/gsi"))]
                    and candidate["gscSha256"] == observed[str(relative(runtime, "gsc/gsc"))]
                    and identity["sha256"] == observed[str(identity_path)],
                    "compiled campaign GSI/GSC or runtime identity differs from its sealed provider")
            digests = _check_sealed_producer_gsc(runtime, candidate, origin)
            return runtime, candidate, digests

        sealed = verify("sealedProducer", _bind_producer)
        if sealed:
            runtime, candidate, digests = sealed
            links["sealedProducer"].update(digests)
            result["gsiSha256"] = candidate["binarySha256"]
            result["gscSha256"] = candidate["gscSha256"]

            # Link 4: Compiled-Host Validation receipt
            def _check_link4():
                ref = plan.get("compiledHostReceipt")
                require(isinstance(ref, str) and ref in outer["inputs"],
                        "compiled campaign lacks declared Link 4 compiledHostReceipt input")
                path = relative(root, ref)
                sha = outer["inputs"][ref]
                receipt = checked_json(path, sha)
                require(step["observedInputs"].get(str(path)) == sha,
                        "compiled campaign did not bind Link 4 compiledHostReceipt")
                gate = checked_json(*step_file(run, step, "link4-preflight.json"))
                require(gate.get("canStart") is True and gate.get("receiptSha256") == sha
                        and gate.get("gscSha256") == candidate["gscSha256"]
                        and gate.get("gsiSha256") == candidate["binarySha256"],
                        "Link 4 preflight receipt disagrees with the bound compiledHostReceipt")
                summary = verify_compiled_host_receipt(receipt, candidate)
                summary.update(path=ref, sha256=sha)
                return summary

            link4 = verify("compiledHostValidation", _check_link4)
            if link4:
                links["compiledHostValidation"].update(link4)
        else:
            runtime = None

        # Link 6: Original Compiled Campaign (p2/j3 then p1/j4 under shared 295/300s clock)
        require(next(row for row in header["declaration"]["steps"] if row["id"] == step["id"])["arguments"]
                    == step["arguments"]
                and header["budgetSeconds"] == outer["budgetSeconds"] == child["budgetSeconds"] == WHOLE_SECONDS
                and header["stepBudgets"][step["id"]] == outer["stepBudgets"][step["id"]] == INNER_SECONDS
                and abs(header["deadlineMonotonic"] - header["startedMonotonic"] - WHOLE_SECONDS) < 0.000001
                and header["runId"] and header["clockEpoch"],
                "compiled campaign has no original shared 295/300-second clock")
        started = header["startedMonotonic"]
        deadline = started + INNER_SECONDS
        clock = dict(runId=header["runId"], clockEpoch=header["clockEpoch"], headerSha256=outer["journal"]["sha256"])
        progress = checked_json(*step_file(run, step, "ordered-stress-progress.json"))
        require(progress["campaignClock"] == clock and progress["manifestSha256"] == manifest_sha
                and progress["profileSha256"] == profile_sha and progress["selectedFiles"] == files,
                "compiled campaign report differs from the original clock, manifest or inventory")
        if runtime is None:
            raise FileNotFoundError("compiled campaign process receipts require the bound producer")
        require(progress["runtimeIdentitySha256"] == provider["outputs"]["identity"]["sha256"]
                and all(step["observedInputs"][str(relative(runtime / "tests", name))] == sha
                        for name, sha in inputs.items()),
                "compiled campaign identity, runner or original case inputs differ")
        result.update(manifestSha256=manifest_sha, campaignClock=clock)
        campaign_errors = []
        commands = {command["stage"]: command for command in step["commands"]}
        require(len(commands) == len(step["commands"]), "duplicate compiled campaign command receipt")
        first, second = result["topologies"]
        p2, p2_names = _audit_compiled_topology(run, step, first, commands, runtime, clock, started, deadline, campaign_errors)
        p1, p1_names = _audit_compiled_topology(run, step, second, commands, runtime, clock, started, deadline, campaign_errors)
        if not (p2 and p1 and max(row["endedMonotonic"] for row in p2) <= min(row["startedMonotonic"] for row in p1)):
            campaign_errors.append("p1 has no verified start after p2 settled on the shared clock")
        extra_names = set(commands.keys()) - (p2_names | p1_names)
        probe_args = {
            "compiler-version": ["--version"],
            "compiler-backend": ["-print-prog-name=cc1"],
            "budget-compiler-version": ["--version"],
            "p2-retry-review-budget-compiler-version": ["--version"],
            "p1-retry-review-budget-compiler-version": ["--version"],
        }
        probes_valid = extra_names <= set(probe_args)
        for probe_name in sorted(extra_names & set(probe_args)):
            cmd = commands[probe_name]
            try:
                log_path, log_sha = step_file(run, step, cmd["log"], cmd["logSha256"])
                raw_log = log_path.read_bytes()
                require(
                    isinstance(cmd.get("argv"), list) and len(cmd["argv"]) >= 2
                    and cmd["argv"][1:] == probe_args[probe_name]
                    and cmd.get("exit") == 0 and cmd.get("timeout") is False
                    and cmd.get("parentReaped") is True
                    and cmd.get("processGroupQuiescent") is True
                    and cmd.get("streamCaptureComplete") is True
                    and hashlib.sha256(raw_log).hexdigest() == log_sha,
                    f"{probe_name}: toolchain probe receipt invalid",
                )
            except READ_ERRORS:
                probes_valid = False
        if not (probes_valid and all(row["complete"] for row in result["topologies"])):
            campaign_errors.append("the original eight compiled stress completions are incomplete")
        if not (progress["runtimeIdentityStable"] is True and progress["wholeFamilyComplete"] is True
                and started <= progress.get("completedMonotonic", -1) <= deadline
                and all(row["endedMonotonic"] <= progress["completedMonotonic"] for row in p2 + p1)
                and step["outcome"] == child["outcome"] == outer["outcome"] == "PASS"
                and child["wholeBudgetExhausted"] is False and outer["performanceBudgetExceeded"] is False
                and outer["exit"] == 0 and outer["timeout"] is False and outer["parentReaped"] is True
                and outer["processGroupQuiescent"] is True and 0 <= outer["wholeSeconds"] <= WHOLE_SECONDS):
            campaign_errors.append("compiled campaign did not settle naturally within the shared 295/300-second budget")
        if campaign_errors:
            missing = any(len(names) < row["jobs"] + 2
                          for row, names in ((first, p2_names), (second, p1_names)))
            links["originalCompiledCampaign"] = dict(
                status="MISSING" if missing else "MISMATCH",
                reason=campaign_errors[0],
                issues=campaign_errors,
            )
            errors.extend(campaign_errors)
        else:
            links["originalCompiledCampaign"] = dict(
                status="PASS",
                manifestSha256=manifest_sha,
                completedCases=8,
                wholeSeconds=outer["wholeSeconds"],
            )
    except READ_ERRORS as error:
        failure("originalCompiledCampaign", error)

    for topology in result["topologies"]:
        for status in ("COMPLETED", "FAILED", "MISSING"):
            topology[status.lower()] = [case["file"] for case in topology["cases"] if case["status"] == status]
    result["passed"] = all(link["status"] == "PASS" for link in links.values())
    return result
