"""Execute the original Family 6 campaign through the shared suite runner."""

import hashlib
import time

from gambit_smp.family6_recipes import OBSERVATION_PROVIDER, rest_campaign_evidence
from gambit_smp.framework import available_processors, digest, gnu_build_driver, relative
from gambit_smp.ordered_stress_audit import INNER_SECONDS, TOPOLOGIES, WHOLE_SECONDS, original_test_inputs


def _matches_original_profile(recorded, expected):
    if recorded == expected:
        return True
    if not isinstance(recorded, dict) or not isinstance(expected, dict):
        return False
    if recorded.get("cflagsBinding") != ["-D___GAMBIT_REST_OBSERVATION"]:
        return False
    base_cflags = expected.get("cflags")
    if not isinstance(base_cflags, str):
        return False
    return recorded == dict(expected, cflags=base_cflags + " -D___GAMBIT_REST_OBSERVATION",
                            cflagsBinding=["-D___GAMBIT_REST_OBSERVATION"])


def ordered_stress_start_check(ctx, plan, candidate, deadline):
    from gambit_smp.rest_observation import runtime_identity_bytes

    reference = plan.get('restEvidence')
    if reference is None:
        raise ValueError('ordered stress requires the sealed eleven-case rest receipt')
    out = relative(ctx.root, reference['run'])
    ctx.bind([out/'receipt.json', out/'run/receipt.json'])
    check, _ = rest_campaign_evidence(ctx.root, reference)
    if (check['executableSha256'] != candidate['binarySha256']
            or check['runtimeIdentitySha256'] != hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest()):
        raise ValueError('ordered stress GSI or runtime identity differs from the eleven rest observations')
    if time.monotonic() >= deadline:
        raise TimeoutError('ordered stress inner deadline exhausted at the item 10 preflight')
    return check


def ordered_stress_suite(ctx, args, runtime, identity, files, gcc, driver):
    """Observe both original populations under one sealed wall deadline."""
    from gambit_smp.build_profile import read_profile
    from gambit_smp.native_capabilities import run_suite_groups
    from gambit_smp.native_review import preflight
    from gambit_smp.recipes import decode_json, read_json, source_path
    from gambit_smp.step_checkpoint import ancestry
    from gambit_smp.suite_primitives import admitted_processors, check_runtime
    from gambit_smp.workspace import write

    identity_bytes = identity.read_bytes()
    frozen_identity = decode_json(identity_bytes)
    identity_sha = hashlib.sha256(identity_bytes).hexdigest()
    plan = args["orderedStress"]
    manifest_path, receipt_path, profile_path = (
        source_path(ctx.root, plan[key]) for key in ("manifest", "inputReceipt", "profile"))
    manifest = read_json(manifest_path)
    original = read_json(receipt_path)["originalCampaign"]
    spec = manifest["spec"]
    inventory = sorted(map(str, files))
    manifest_sha = digest(manifest_path)
    test_inputs = original_test_inputs(manifest, original, manifest_sha, digest(profile_path), inventory)
    copied = runtime / "tests"
    inputs = {relative(copied, name): expected for name, expected in test_inputs.items()}
    if len(inputs) != len(test_inputs) or any(digest(path) != expected for path, expected in inputs.items()):
        raise ValueError("ordered stress runner, assertions or workload changed")

    lineage = ancestry(ctx.receipt["steps"], args["runtime"]["step"])
    producer = lineage[-1]
    make_lineage = producer.get("makeLineage")
    if plan.get("makeLineage") and not make_lineage:
        raise ValueError("ordered stress requires a verified Make lineage for the GSI")
    if make_lineage and (frozen_identity.get("makeLineage") != make_lineage
                         or digest(runtime / "gsi/gsi") != make_lineage["gsiSha256"]):
        raise ValueError("ordered stress GSI differs from the recorded Make link")
    if producer["capability"] == "gambit.runtime-import":
        generation = producer["producerGeneration"]
        if (generation["kind"] != "pinned-completed-stage"
                or producer["workspaceReuse"]["mode"] != "same-producer-workspace"):
            raise ValueError("ordered stress requires the existing producer workspace")
        configuration = generation.get("configuration", {})
    elif producer["capability"] == "gambit.completed-runtime":
        from gambit_smp.completed_producer import campaign_configuration
        configuration = campaign_configuration(ctx.root, producer["arguments"]["producer"])
    elif producer["capability"] == OBSERVATION_PROVIDER:
        source_files = frozen_identity.get("sourceFiles") or {}
        recorded = {name: source_files[name] for name in ("include/gambit.h", "lib/makefile")
                    if isinstance(source_files.get(name), str)}
        if "include/gambit.h" not in recorded:
            raise ValueError("ordered stress runtime identity has no include/gambit.h")
        configuration = dict(files=recorded)
    else:
        configs = [row for row in lineage if row["capability"] == "gambit.configure"]
        if len(configs) != 1:
            raise ValueError("ordered stress requires its producer configuration ancestry")
        configured = configs[0]
        profile = configured["arguments"].get("buildProfile")
        configuration = dict(profileSha256=ctx.receipt["inputs"].get(profile),
                             profile=configured.get("buildProfile"), files=producer.get("configurationFiles", {}))
        if configuration["files"] != configured["configurationFiles"]:
            raise ValueError("ordered stress producer configuration changed after configure")
    same_headers = all(digest(runtime / name) == expected
                       for name, expected in configuration["files"].items())
    if producer["capability"] == OBSERVATION_PROVIDER:
        if not same_headers:
            raise ValueError("ordered stress runtime differs from its eleven-case identity")
    elif (configuration.get("profileSha256") != spec["profile"]
            or not _matches_original_profile(configuration.get("profile"), read_profile(profile_path))
            or not same_headers):
        raise ValueError("ordered stress runtime differs from the original Bazel profile")

    journal = ctx.receipt["journal"]
    header_path = ctx.out.parent / "run-header.json"
    if str(header_path) != journal["path"] or digest(header_path) != journal["sha256"]:
        raise ValueError("ordered stress requires its original sealed clock header")
    header = read_json(header_path)
    if (ctx.progress_mode or header["schema"] != "research-run-header.v1"
            or ctx.receipt["budgetSeconds"] != WHOLE_SECONDS or header["budgetSeconds"] != WHOLE_SECONDS
            or header["stepBudgets"].get(ctx.directory.name) != INNER_SECONDS
            or abs(header["deadlineMonotonic"] - header["startedMonotonic"] - WHOLE_SECONDS) > 0.000001):
        raise ValueError("ordered stress requires a single 295/300-second campaign")
    ctx.bind([identity, runtime / "gsi/gsi", manifest_path, receipt_path, profile_path, header_path, *inputs])
    preflight_report = ctx.directory / 'item10-preflight.json'
    inner_deadline = min(ctx.deadline, header["startedMonotonic"] + INNER_SECONDS)
    try:
        start_check = ordered_stress_start_check(ctx, plan, frozen_identity, inner_deadline)
    except (OSError, ValueError, KeyError, TypeError, TimeoutError) as error:
        write(preflight_report, dict(checklist=10, canStart=False, reason=str(error),
                                    requiredCases=11, innerBudgetSeconds=INNER_SECONDS,
                                    wholeBudgetSeconds=WHOLE_SECONDS, runtimeAdmitted=False))
        raise
    write(preflight_report, start_check)
    rows = [dict(processors=population, jobs=jobs, started=False, complete=False,
                 reason="predecessor-unresolved") for _, population, jobs in TOPOLOGIES]
    observation = dict(manifestSha256=manifest_sha, profileSha256=spec["profile"],
                       runtimeIdentitySha256=identity_sha, runtimeIdentityStable=None, selectedFiles=inventory,
                       innerBudgetSeconds=INNER_SECONDS, wholeBudgetSeconds=WHOLE_SECONDS, observationsSpliced=False,
                       wholeFamilyComplete=False, topologies=rows, runtimeAdmitted=False)
    clock = dict(runId=header.get("runId"), clockEpoch=header.get("clockEpoch"),
                 headerSha256=journal["sha256"])
    observation["campaignClock"] = clock
    if make_lineage:
        observation["makeLineage"] = make_lineage
    report = ctx.directory / "ordered-stress-progress.json"
    write(report, observation)
    previous_deadline, previous_env = ctx.deadline, ctx.env
    ctx.deadline = inner_deadline
    ctx.ordered_stress_clock = clock
    try:
        for row in rows:
            if digest(identity) != identity_sha:
                observation["runtimeIdentityStable"] = False
                row["reason"] = "runtime-identity-drift"
                raise ValueError("ordered stress runtime identity changed during campaign")
            if time.monotonic() >= ctx.deadline:
                row["reason"] = "whole-deadline-exhausted-before-topology"
                continue
            population, jobs = row["processors"], row["jobs"]
            prefix = f"p{population}-"
            ctx.env = previous_env
            request = {key: value for key, value in args.items() if key != "orderedStress"}
            request.update(processors=population, jobs=jobs)
            review = plan.get("reviews", {}).get(f"p{population}")
            if review is not None:
                request["retryReview"] = review
            retry = preflight(ctx, request, runtime, identity, files, copied / "unit-tests",
                              label=prefix + "retry-review")
            write(ctx.directory / (prefix + "retry-preflight.json"), retry)
            ctx.bind(ctx.root / name for name in retry["inputs"])
            campaign = retry["campaign"]
            if (retry["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}
                    or (campaign["effectiveProcessors"], campaign["effectiveJobs"]) != (population, jobs)):
                row["reason"] = "retry-review-or-capacity-refused"
                break
            if time.monotonic() >= ctx.deadline:
                row["reason"] = "whole-deadline-exhausted-before-topology"
                continue
            option = f"p{population},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
            ctx.env = {**previous_env, "GAMBOPT": option, "GAMBIT_SMP_EXPECTED_PROCESSORS": str(population),
                       "GAMBIT_SMP_AVAILABLE_CPUS": str(available_processors())}
            row.update(reason="probing", probes=[])
            write(report, observation)
            command_start = len(ctx.commands)
            for role, runtime_option, expected in (("runner", "p1", 1),
                                                    ("fixture", "debug-settings=-,io-settings=lu", population)):
                code, output, timeout, seconds = ctx.run(prefix + "topology-" + role,
                    [runtime / "gsi/gsi", "-:" + runtime_option, "-e",
                     '(println "PROCESSORS:" (##current-vm-processor-count))'], copied, 10)
                row["started"] = True
                complete = admitted_processors(code, output, timeout, expected)
                row["probes"].append(dict(role=role, expected=expected, observed=output.strip(),
                                          exit=code, timeout=timeout, seconds=seconds, complete=complete))
                if not complete:
                    row["reason"] = "topology-probe-failed"
                    break
            if row["reason"] == "topology-probe-failed":
                break
            row["reason"] = "running"
            write(report, observation)
            row["shards"] = run_suite_groups(ctx, runtime, copied, request, files, jobs, option, prefix=prefix)
            if any(command.get("parentReaped") is not True or command.get("processGroupQuiescent") is not True
                   for command in ctx.commands[command_start:]):
                row["reason"] = "child-custody-unresolved"
                break
            row["complete"] = (sorted(name for shard in row["shards"] for name in shard["files"]) == inventory
                               and all(shard["accepted"] for shard in row["shards"]))
            row["reason"] = None if row["complete"] else "shard-incomplete"
            write(report, observation)
        if not all(row["complete"] for row in rows):
            raise ValueError("original ordered stress campaign did not complete")
        if digest(identity) != identity_sha:
            observation["runtimeIdentityStable"] = False
            raise ValueError("ordered stress runtime identity changed during campaign")
        check_runtime(runtime, frozen_identity)
        observation["runtimeIdentityStable"] = True
        if (gnu_build_driver(runtime, gcc) != driver
                or any(digest(path) != expected for path, expected in inputs.items())):
            raise ValueError("ordered stress build driver or test input changed")
        ctx.remaining()
        observation["completedMonotonic"] = time.monotonic()
        observation["wholeFamilyComplete"] = True
        return {**observation, "passedFiles": inventory, "performanceAdmitted": False}
    finally:
        ctx.deadline, ctx.env = previous_deadline, previous_env
        ctx.ordered_stress_clock = None
        write(report, observation)
