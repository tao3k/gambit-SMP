"""Read the original Family 6 campaign from one committed Research run."""

import hashlib
from pathlib import Path
from subprocess import CalledProcessError

from gambit_smp.framework import digest, relative
from gambit_smp.recipes import artifact_path, decode_json, read_json
from gambit_smp.family6_recipes import OBSERVATION_PROVIDER
from gambit_smp.rest_observation import runtime_identity_bytes
from gambit_smp.suite_primitives import (
    admitted_processors, admitted_suite, completed_unit_cases, partitions, runner_option,
)


RECIPE_TEMPLATE = "evidence/fixtures/dev-rest-original-runner/stress.recipe.json"
TOPOLOGIES = ((10, 2, 3), (11, 1, 4))
INNER_SECONDS = 295
WHOLE_SECONDS = 300
ORIGINAL_STRESS_SPEC = (
    "gsi", "stress",
    ";".join(str(processors) for _, processors, _ in TOPOLOGIES),
    ";".join(f"{processors}:{jobs}" for _, processors, jobs in TOPOLOGIES),
    INNER_SECONDS, WHOLE_SECONDS,
)
READ_ERRORS = (OSError, ValueError, KeyError, TypeError, StopIteration, CalledProcessError)


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def checked_json(path, sha):
    raw = path.read_bytes()
    require(hashlib.sha256(raw).hexdigest() == sha, f"receipt-bound bytes changed: {path.name}")
    return decode_json(raw)


def step_file(run, step, name, sha=None):
    path = step["id"] + "/" + name
    expected = step.get("artifacts", {}).get(path)
    if expected is None:
        raise FileNotFoundError(f"missing receipt-bound artifact: {path}")
    require(sha is None or expected == sha, f"artifact and command disagree: {path}")
    return relative(run, path), expected


def committed_header(out, outer, child, steps=(), checkpoint=None):
    from gambit_smp.reasoning_history import read_execution_checkpoint

    journal = outer["journal"]
    path = out / "run-header.json"
    require(journal["path"] == str(path) and child["journal"] == journal,
            "campaign receipts identify different run headers")
    header = checked_json(path, journal["sha256"])
    require(header["schema"] == "research-run-header.v1"
            and all(header[key] == outer[key] for key in ("recipe", "engineId", "inputs")),
            "sealed receipt and its run header identify different inputs or executors")
    if checkpoint is None:
        checkpoint = read_execution_checkpoint(Path(outer["root"]), out)
    prefix = checkpoint["records"]
    if not prefix or prefix[-1]["payload"].get("schema") != "research-terminal-observation.v1":
        raise FileNotFoundError("sealed terminal checkpoint is missing")
    require(prefix[0]["path"] == str(path) and prefix[0]["payload"] == header,
            "campaign header has no matching immutable checkpoint")
    terminal = prefix[-1]["payload"]
    require(terminal["runId"] == header["runId"] and terminal["outer"] == outer
            and terminal["child"] == child, "campaign terminal receipts differ from the committed run")
    records = [record["payload"] for record in prefix
               if record["payload"].get("schema") == "research-step-observation.v1"]
    for step in steps:
        retained = [row for row in records if row["step"]["id"] == step["id"]]
        require(len(retained) == 1 and retained[0]["runId"] == header["runId"]
                and retained[0]["header"] == journal
                and retained[0]["step"] == {key: value for key, value in step.items() if key != "journal"},
                f"{step['id']} step differs from the committed run")
    return header


def original_inventory(root):
    template = read_json(relative(root, RECIPE_TEMPLATE))
    stress = next(row for row in template["steps"] if "orderedStress" in row["arguments"])
    plan = stress["arguments"]["orderedStress"]
    return plan, sorted(stress["arguments"]["expectedFiles"])


def declares_ordered_stress(steps):
    return any(step.get("capability") == "gambit.suite"
               and "orderedStress" in step.get("arguments", {}) for step in steps)


def original_test_inputs(manifest, original, manifest_sha, profile_sha, files):
    """Check the same workload contract at launch and during independent audit."""
    spec = manifest["spec"]
    inputs = original["testInputFiles"]
    require(profile_sha == original["profileSha256"] == spec["profile"]
            and manifest_sha == original["manifestSha256"]
            and (spec["mode"], spec["inventory"], spec["processors"], spec["jobs"],
                 spec["innerSeconds"], spec["wholeSeconds"]) == ORIGINAL_STRESS_SPEC
            and len(files) == 4 and sorted(case["target"] for case in manifest["cases"]) == files
            and all(case["kind"] == "original-stress" and case["seconds"] == 0
                    and inputs.get("unit-tests/" + case["target"]) == case["sha256"]
                    for case in manifest["cases"]), "campaign differs from the original manifest or profile")
    require({"run-unit-tests.scm", "unit-tests/#.scm", "unit-tests/06-thread/#.scm"} <= inputs.keys(),
            "ordered stress requires the original runner and assertion chain")
    return inputs


def check_original_inputs(root, outer, step, original_plan, files):
    plan = step["arguments"]["orderedStress"]
    paths = {}
    for name in ("manifest", "inputReceipt", "profile"):
        require(plan[name] == original_plan[name], f"campaign changed the original {name} reference")
        paths[name] = relative(root, plan[name])
    manifest_sha = outer["inputs"][plan["manifest"]]
    manifest = checked_json(paths["manifest"], manifest_sha)
    original = checked_json(paths["inputReceipt"], outer["inputs"][plan["inputReceipt"]])["originalCampaign"]
    profile_sha = outer["inputs"][plan["profile"]]
    require(digest(paths["profile"]) == profile_sha and sorted(step["arguments"]["expectedFiles"]) == files,
            "campaign differs from the original manifest or profile")
    return manifest_sha, profile_sha, original_test_inputs(manifest, original, manifest_sha, profile_sha, files)


def runtime_provider(child, step):
    args = step["arguments"]
    runtime, identity = args["runtime"], args["identity"]
    require(runtime["step"] == identity["step"] and runtime["output"] == "runtime"
            and identity["output"] == "identity" and runtime["step"] in step["dependsOn"],
            "campaign runtime and identity name different providers")
    return passed_step(child, runtime["step"])


def passed_step(child, name):
    matches = [row for row in child["steps"] if row["id"] == name]
    if not matches:
        raise FileNotFoundError(f"required step receipt is missing: {name}")
    require(len(matches) == 1, f"duplicate step receipt: {name}")
    step, = matches
    require(step["outcome"] == "PASS", f"required step did not pass: {name}")
    return step


def locked_source(child, provider):
    reference = provider["arguments"]["source"]
    source = passed_step(child, reference["step"])
    require(reference["output"] == "source" and source["id"] in provider["dependsOn"]
            and source["capability"] == "gambit.materialize", "runtime provider has no locked source dependency")
    return source


def check_runtime_binding(root, run, provider, step):
    runtime_output = provider["outputs"]["runtime"]
    runtime = artifact_path(run, runtime_output, root=root)
    identity = provider["outputs"]["identity"]
    identity_path = artifact_path(run, identity, root=root)
    candidate = checked_json(identity_path, identity["sha256"])
    executable_sha = candidate["binarySha256"]
    observed = step["observedInputs"]
    require(runtime_output["type"] == "source-runtime" and identity["type"] == "runtime-identity"
            and candidate["schema"] == "gambit-recipe-runtime-identity.v1"
            and executable_sha == observed[str(relative(runtime, "gsi/gsi"))]
            and executable_sha == runtime_output["identity"]["gsi/gsi"]["sha256"]
            and identity["sha256"] == observed[str(identity_path)],
            "campaign GSI or runtime identity differs from its sealed provider")
    return runtime, candidate


def check_source_lock(root, outer, child, provider):
    from gambit_smp.completed_producer import SCHEMA, bootstrap_ancestry, completed
    from gambit_smp.artifact_storage import fixture_path
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.source_capabilities import validate_source_lock

    if provider["capability"] == OBSERVATION_PROVIDER:
        raise FileNotFoundError("the observed GSI has no completed source-lock and Make producer reference")
    source = locked_source(child, provider)
    lock_name = source["arguments"]["sourceLock"]
    lock_sha = outer["inputs"][lock_name]
    lock = checked_json(relative(root, lock_name), lock_sha)
    validate_source_lock(lock)
    require(digest(relative(root, lock["patch"])) == lock["patchSha256"] == outer["inputs"][lock["patch"]],
            "source lock and sealed patch digest differ")
    if provider["capability"] != "gambit.completed-runtime":
        raise FileNotFoundError("campaign provider has no completed bootstrap reference")
    proof_name = provider["arguments"]["producer"]
    proof_path = relative(root, proof_name)
    proof = checked_json(proof_path, outer["inputs"][proof_name])
    require(proof["schema"] == SCHEMA and proof["sourceLock"] == lock_name
            and proof["sourceLockSha256"] == lock_sha, "completed producer references a different source lock")
    origin = fixture_path(root, proof["run"])
    run = origin / "run"
    original_outer = checked_json(origin / "receipt.json", proof["outerReceiptSha256"])
    original = checked_json(run / "receipt.json", proof["childReceiptSha256"])
    require(original_outer["schema"] == "sealed-research-run.v1" and original_outer["root"] == str(root)
            and original_outer["childReceiptSha256"] == proof["childReceiptSha256"]
            and original["recipe"] == original_outer["recipe"]
            and original["schema"] == "evidence-recipe-run.v1"
            and original_outer["engineId"] == proof["engineId"],
            "completed producer reference selects another sealed execution")
    bootstrap = passed_step(original, proof["step"])
    rows = {row["id"]: row for row in original["steps"]}
    require(len(rows) == len(original["steps"]) and bootstrap["capability"] == "gambit.bootstrap",
            "completed producer must select one bootstrap step")
    seed, configured, materialized = bootstrap_ancestry(root, rows, bootstrap)
    local_steps = [materialized, seed, bootstrap]
    # Seed-checkpoint ancestry already checks the external configure step at its owner.
    if rows.get(configured["id"]) == configured:
        local_steps.append(configured)
    committed_header(origin, original_outer, original, local_steps)
    archive = proof.get("inputArchive")
    if original_outer["outcome"] != "PASS" or original_outer.get("exit") != 0:
        archive_name = archive["path"] if archive else None
        require(completed(root, origin, bootstrap["id"], input_archive=archive_name)[0] == proof,
                "completed producer recovery differs from its sealed reference")
    else:
        require(original["outcome"] == "PASS" and original_outer["timeout"] is False
                and original_outer["parentReaped"] is True and original_outer["processGroupQuiescent"] is True,
                "completed producer did not finish with process custody")
    engine = manifest_paths(Path(original_outer["engine"]))
    require(engine["engineId"] == proof["engineId"] and engine["hostTools"]["gcc"]["sha256"] == proof["gccSha256"],
            "completed producer seal or GCC digest changed")
    step_path = run / bootstrap["id"] / "step-receipt.json"
    disk = checked_json(step_path, proof["stepReceiptSha256"])
    require(disk == {key: value for key, value in bootstrap.items() if key != "journal"},
            "bootstrap step bytes differ from the committed producer")
    observed = provider["observedInputs"]
    require(all(observed[str(path)] == sha for path, sha in (
        (proof_path, outer["inputs"][proof_name]), (origin / "receipt.json", proof["outerReceiptSha256"]),
        (run / "receipt.json", proof["childReceiptSha256"]), (step_path, proof["stepReceiptSha256"]))),
        "campaign provider did not consume the exact completed producer receipts")
    original_source = materialized["outputs"]["source"]["identity"]
    expected_source = (bootstrap["outputs"]["runtime"]["identity"]
                       if child.get("workspacePolicy") == "in-place" else original_source)
    worktree = lock["worktreeFiles"] if lock.get("trackWorktree") is True else {}
    require(materialized["arguments"]["sourceLock"] == lock_name
            and original_outer["inputs"].get(lock_name) == lock_sha
            and original_outer["inputs"].get(lock["patch"]) == lock["patchSha256"]
            and source["outputs"]["source"]["identity"] == expected_source
            and all(original_source.get(name, {}).get("sha256") == row["candidateSha256"]
                    for name, row in lock["files"].items())
            and all(expected_source.get(name, {}).get("sha256") == pinned
                    for name, pinned in worktree.items()),
            "materialized source or original producer does not match the sealed source lock")
    return dict(lock=lock_name, sha=lock_sha, bootstrap=bootstrap, run=run, proof=proof, provider=provider,
                seed=seed, configured=configured, producerInputs=original_outer["inputs"],
                lockedFiles={name: row["candidateSha256"] for name, row in lock["files"].items()},
                worktreeFiles=worktree)


def check_make_lineage(origin, profile_sha):
    from gambit_smp.make_lineage import audit_retained_graph

    bootstrap = origin["bootstrap"]
    binding = bootstrap["makeLineage"]
    producer = origin["provider"]
    commands = [row for row in bootstrap["commands"] if row["stage"] == "from-scratch"]
    require(bootstrap["fullTwoPassBootstrapEstablished"] is True
            and bootstrap["phaseCounts"] == dict.fromkeys(("phase1", "phase2", "phase3", "phase4"), 2)
            and len(commands) == 1 and commands[0]["argv"][-1] == "from-scratch"
            and commands[0]["exit"] == 0 and commands[0]["timeout"] is False
            and commands[0]["parentReaped"] is True and commands[0]["processGroupQuiescent"] is True,
            "producer lacks a complete two-pass Make process receipt")
    require(bootstrap["artifacts"][binding["path"]] == binding["sha256"]
            and producer["makeLineage"] == binding, "producer and campaign Make lineage bindings differ")
    tree = bootstrap["outputs"]["runtime"]["identity"]
    configured = origin["configured"]
    require(origin["producerInputs"][configured["arguments"]["buildProfile"]] == profile_sha
            and all(configured["configurationFiles"][name] == tree[name]["sha256"]
                    for name in ("include/gambit.h", "lib/makefile")),
            "Make configuration differs from the original campaign profile")
    seed = origin["seed"]
    seed_tree = seed["outputs"][bootstrap["arguments"]["runtime"]["output"]]["identity"]
    emitter = "gsc-boot" if seed["capability"] == "gambit.bootstrap-input" else "gsc/gsc"
    counts, graph = audit_retained_graph(origin["run"], binding, binding["gsiSha256"], tree,
                                 origin["proof"]["gccSha256"], seed_sha=seed_tree[emitter]["sha256"],
                                 locked_files=origin["lockedFiles"])
    return dict(binding=binding, actionsPerPass=counts), graph


def check_producer_gsi(origin, candidate):
    original = origin["bootstrap"]["outputs"]
    imported = origin["provider"]["outputs"]
    binding = origin["bootstrap"]["makeLineage"]
    identity = checked_json(artifact_path(origin["run"], original["identity"]), original["identity"]["sha256"])
    require(original["identity"]["sha256"] == imported["identity"]["sha256"]
            and original["runtime"]["identity"] == imported["runtime"]["identity"]
            and candidate == identity and candidate["makeLineage"] == binding
            and candidate["binarySha256"] == binding["gsiSha256"],
            "bootstrap Make link and campaign refer to different sealed GSI bytes")


def check_sealed_gsi(runtime, candidate, origin):
    require(digest(relative(runtime, "gsi/gsi")) == candidate["binarySha256"],
            "retained GSI bytes differ from the campaign receipt")
    if origin and origin["bootstrap"].get("makeLineage"):
        check_producer_gsi(origin, candidate)


def check_family_a(root, out, outer, child, step, provider, candidate):
    from gambit_smp.family6_recipes import rest_campaign_evidence
    from gambit_smp.observation_runtime import check_observation_tree
    from gambit_smp.recipes import tree_identity

    reference = step["arguments"]["orderedStress"]["restEvidence"]
    rest_run = relative(root, reference["run"])
    receipt = checked_json(rest_run / "receipt.json", reference["receiptSha256"])
    check, rest_child = rest_campaign_evidence(root, reference, diagnose_cases=True)
    committed_header(rest_run, receipt, rest_child)
    gate = checked_json(*step_file(out / "run", step, "item10-preflight.json"))
    observed = step["observedInputs"]
    rest_provider = passed_step(rest_child, check["provider"])
    require(check == gate and check["verifiedCases"] == 11
            and observed[str(rest_run / "receipt.json")] == reference["receiptSha256"]
            and observed[str(rest_run / "run/receipt.json")] == check["childReceiptSha256"],
            "Family A receipts differ from the ones consumed by the campaign")
    require(check["executableSha256"] == candidate["binarySha256"]
            and check["runtimeIdentitySha256"] == hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest()
            and rest_provider["capability"] == provider["capability"]
            and rest_provider["outputs"]["identity"]["sha256"] == provider["outputs"]["identity"]["sha256"],
            "Family A and original campaign refer to different sealed runtimes")
    rest_tree = rest_provider["outputs"]["runtime"]["identity"]
    campaign_tree = provider["outputs"]["runtime"]["identity"]
    if provider["capability"] == OBSERVATION_PROVIDER:
        declared = provider["arguments"]
        retained = dict(reference, step=check["provider"])
        same_location = rest_provider["arguments"]["source"] == declared["source"]
        require(rest_provider["arguments"]["gsiSha256"] == declared["gsiSha256"],
                "Family A and original campaign select different GSI digests")
        if same_location:
            check_observation_tree(rest_tree, campaign_tree)
        else:
            require(rest_tree == campaign_tree, "restored runtime tree differs from the committed Family A tree")
        if "retainedRuntime" in declared or not same_location:
            require(declared.get("retainedRuntime") == retained,
                    "campaign runtime does not select the verified Family A provider")
    else:
        require(rest_tree == campaign_tree, "Family A and original campaign select different runtime trees")
        rest_source = locked_source(rest_child, rest_provider)
        lock = locked_source(child, provider)["arguments"]["sourceLock"]
        proof_name = provider["arguments"].get("producer") or provider["arguments"]["archive"]
        require(proof_name == (rest_provider["arguments"].get("producer")
                               or rest_provider["arguments"].get("archive"))
                and rest_source["arguments"]["sourceLock"] == lock
                and receipt["inputs"][lock] == outer["inputs"][lock]
                and receipt["inputs"][proof_name] == outer["inputs"][proof_name],
                "Family A and original campaign pin different locked producer inputs")
    rest_runtime = artifact_path(rest_run / "run", rest_provider["outputs"]["runtime"], root=root)
    if provider["capability"] == OBSERVATION_PROVIDER and not same_location:
        require(rest_runtime == relative(root, rest_provider["arguments"]["source"])
                and artifact_path(out / "run", provider["outputs"]["runtime"], root=root)
                    == relative(root, declared["source"]),
                "restored runtime location differs from its receipt")
        rest_bytes = relative(root, declared["source"])
        require(tree_identity(rest_bytes) == rest_tree,
                "restored runtime no longer matches the committed Family A tree")
    else:
        rest_bytes = rest_runtime
    require(digest(relative(rest_bytes, "gsi/gsi")) == candidate["binarySha256"]
            and digest(relative(rest_bytes, "gsc/gsc")) == candidate["gscSha256"],
            "Family A GSI or GSC differs from its sealed provider")
    for row in rest_child["steps"]:
        if "case" not in row.get("arguments", {}).get("restObservation", {}):
            continue
        commands = row.get("originCommands") if row.get("reused") else row["commands"]
        for stage, executable in (("compile-rest-fixture", "gsc/gsc"), ("run-executable", "gsi/gsi")):
            processes = [command for command in commands if command["stage"] == stage]
            require(len(processes) == 1 and processes[0]["argv"][0] == str(rest_runtime / executable)
                    and processes[0]["parentReaped"] is True and processes[0]["processGroupQuiescent"] is True,
                    f"Family A {row['id']}: {stage} does not bind the sealed process")
        require(row["executableSha256"] == candidate["binarySha256"]
                and row["candidateReceiptSha256"] == rest_provider["outputs"]["identity"]["sha256"],
                f"Family A {row['id']}: runtime receipt differs from the sealed provider")
    return dict(run=reference["run"], receiptSha256=reference["receiptSha256"], verifiedCases=check["verifiedCases"])


def command_result(run, step, command, clock, started, deadline, argv):
    name = command["stage"]
    checkpoint = checked_json(*step_file(run, step, name + ".process.json"))
    require(checkpoint == dict(command, schema="recipe-process-observation.v1", state="OBSERVED",
                               completionObserved=True, runtimeAdmitted=False),
            f"{name}: process receipt differs from the committed command")
    require(command["argv"] == argv and command["log"] == name + ".log",
            f"{name}: wrong executable or runner arguments")
    timing = command["campaignClock"]
    require(all(timing[key] == value for key, value in clock.items())
            and timing["deadlineMonotonic"] == deadline
            and started <= timing["startedMonotonic"] <= timing["endedMonotonic"],
            f"{name}: process belongs to another campaign clock")
    path, sha = step_file(run, step, command["log"], command["logSha256"])
    raw = path.read_bytes()
    require(hashlib.sha256(raw).hexdigest() == sha, f"{name}: runner output changed")
    natural = (command["timeout"] is False and command["exit"] == 0
               and command["parentReaped"] is True and command["processGroupQuiescent"] is True
               and command["streamCaptureComplete"] is True and timing["endedMonotonic"] <= deadline)
    return raw.decode(), timing, natural


def audit_topology(run, step, row, commands, runtime, clock, started, deadline, errors):
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
                         "-gsi", "-stress", *["unit-tests/" + file for file in group]])
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
            # The runner emits the active filename before advancing its counter.
            active = next((cases[file] for file in group if cases[file]["runnerCounter"] == "UNRESOLVED"), None)
            if active and any(line.startswith("[") and line.rstrip().endswith(" " + active["file"])
                              for line in output.splitlines()):
                active.update(status="FAILED", reason="timeout" if command["timeout"] else "runner-did-not-complete")
            errors.append(f"{command['stage']}: original runner did not exit naturally with all cases complete")
    actual = {name for name in commands if name.startswith(prefix)}
    if not actual <= expected:
        errors.append(f"p{population}: unexpected campaign command inventory")
    ordered = (probe_windows == 2 and windows[0]["endedMonotonic"] <= windows[1]["startedMonotonic"]
               and all(window["startedMonotonic"] >= windows[1]["endedMonotonic"] for window in windows[2:]))
    row["complete"] = (ordered and all(probes) and all(shards)
                       and all(case["status"] == "COMPLETED" for case in cases.values()))
    return windows, actual


def item12_audit(out, outer, child, *, checkpoint=None):
    """Join the producer, native rest evidence and original ordered campaign."""
    from gambit_smp.gate2_evidence import SITES, audit_correspondence, blocked_selection

    links = {name: dict(status="BLOCKED", reason="requires a verified campaign receipt and its dependencies")
             for name in ("sourceLock", "makeLineage", "sealedGsi", "gate2", "familyA", "originalCampaign")}
    links["gate2"]["reason"] = "requires the verified source lock, final Make lineage and sealed runtime"
    result = dict(checklist=12, passed=False, innerBudgetSeconds=INNER_SECONDS, wholeBudgetSeconds=WHOLE_SECONDS,
                  topologies=[], links=links, gaps=[], executionAuthorized=False, runtimeAdmitted=False)
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
        original_plan, files = original_inventory(root)
        result["topologies"] = [dict(checklist=item, processors=p, jobs=jobs, complete=False,
                                     cases=[dict(file=file, status="MISSING") for file in files])
                                for item, p, jobs in TOPOLOGIES]
        if child is None:
            raise FileNotFoundError("sealed campaign has no verified child receipt")
        steps = [row for row in child["steps"] if "orderedStress" in row.get("arguments", {})]
        require(len(steps) == 1 and steps[0]["capability"] == "gambit.suite",
                "one original ordered stress step is required")
        step = steps[0]
        header = committed_header(out, outer, child, [step], checkpoint)
        provider = runtime_provider(child, step)
        run = out / "run"
        sealed = verify("sealedGsi", lambda: check_runtime_binding(root, run, provider, step))
        origin = verify("sourceLock", lambda: check_source_lock(root, outer, child, provider))
        lineage = None
        links["makeLineage"]["reason"] = "requires the verified source lock and completed Make producer"
        if origin:
            links["sourceLock"].update(path=origin["lock"], sha256=origin["sha"],
                                       producerReceiptSha256=origin["proof"]["outerReceiptSha256"],
                                       worktreeFiles=origin.get("worktreeFiles") or {})
            lineage = verify("makeLineage", lambda: check_make_lineage(
                origin, outer["inputs"][step["arguments"]["orderedStress"]["profile"]]))
            if lineage:
                links["makeLineage"].update(lineage[0])
        if sealed:
            runtime, candidate = sealed
            executable_sha = candidate["binarySha256"]
            links["sealedGsi"]["executableSha256"] = executable_sha
            result["executableSha256"] = executable_sha
            try:
                check_sealed_gsi(runtime, candidate, origin)
            except READ_ERRORS as error:
                failure("sealedGsi", error)
            if lineage and links["sealedGsi"]["status"] == "PASS":
                gate = audit_correspondence(root, outer, step, runtime, origin, lineage[1])
                links["gate2"] = gate
                if gate["status"] != "PASS":
                    errors.append(gate["reason"])
            family = verify("familyA", lambda: check_family_a(root, out, outer, child, step, provider, candidate))
            if family:
                links["familyA"].update(family)
        require(next(row for row in header["declaration"]["steps"] if row["id"] == step["id"])["arguments"]
                    == step["arguments"]
                and header["budgetSeconds"] == outer["budgetSeconds"] == child["budgetSeconds"] == WHOLE_SECONDS
                and header["stepBudgets"][step["id"]] == outer["stepBudgets"][step["id"]] == INNER_SECONDS
                and abs(header["deadlineMonotonic"] - header["startedMonotonic"] - WHOLE_SECONDS) < 0.000001
                and header["runId"] and header["clockEpoch"], "campaign has no original shared 295/300-second clock")
        started = header["startedMonotonic"]
        deadline = started + INNER_SECONDS
        clock = dict(runId=header["runId"], clockEpoch=header["clockEpoch"], headerSha256=outer["journal"]["sha256"])
        progress = checked_json(*step_file(run, step, "ordered-stress-progress.json"))
        manifest_sha, profile_sha, inputs = check_original_inputs(root, outer, step, original_plan, files)
        require(progress["campaignClock"] == clock and progress["manifestSha256"] == manifest_sha
                and progress["profileSha256"] == profile_sha and progress["selectedFiles"] == files,
                "campaign report differs from the original clock, manifest or inventory")
        if sealed is None:
            raise FileNotFoundError("campaign process receipts require the bound runtime")
        require(progress["runtimeIdentitySha256"] == provider["outputs"]["identity"]["sha256"]
                and all(step["observedInputs"][str(relative(runtime / "tests", name))] == sha
                        for name, sha in inputs.items()), "campaign identity, runner or original case inputs differ")
        result.update(manifestSha256=manifest_sha, campaignClock=clock)
        campaign_errors = []
        commands = {command["stage"]: command for command in step["commands"]}
        require(len(commands) == len(step["commands"]), "duplicate campaign command receipt")
        first, second = result["topologies"]
        p2, p2_names = audit_topology(run, step, first, commands, runtime, clock, started, deadline, campaign_errors)
        p1, p1_names = audit_topology(run, step, second, commands, runtime, clock, started, deadline, campaign_errors)
        if not (p2 and p1 and max(row["endedMonotonic"] for row in p2) <= min(row["startedMonotonic"] for row in p1)):
            campaign_errors.append("p1 has no verified start after p2 settled on the shared clock")
        extra_names = set(commands.keys()) - (p2_names | p1_names)
        probe_args = {
            "compiler-version": ["--version"],
            "compiler-backend": ["-print-prog-name=cc1"],
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
            campaign_errors.append("the original eight case completions are incomplete")
        if not (progress["runtimeIdentityStable"] is True and progress["wholeFamilyComplete"] is True
                and started <= progress.get("completedMonotonic", -1) <= deadline
                and all(row["endedMonotonic"] <= progress["completedMonotonic"] for row in p2 + p1)
                and step["outcome"] == child["outcome"] == outer["outcome"] == "PASS"
                and child["wholeBudgetExhausted"] is False and outer["performanceBudgetExceeded"] is False
                and outer["exit"] == 0 and outer["timeout"] is False and outer["parentReaped"] is True
                and outer["processGroupQuiescent"] is True and 0 <= outer["wholeSeconds"] <= WHOLE_SECONDS):
            campaign_errors.append("campaign did not settle naturally within the shared 295/300-second budget")
        if campaign_errors:
            missing = any(len(names) < row["jobs"] + 2
                          for row, names in ((first, p2_names), (second, p1_names)))
            links["originalCampaign"] = dict(status="MISSING" if missing else "MISMATCH",
                                             reason=campaign_errors[0], issues=campaign_errors)
            errors.extend(campaign_errors)
        else:
            links["originalCampaign"] = dict(status="PASS", manifestSha256=manifest_sha, completedCases=8)
    except READ_ERRORS as error:
        failure("originalCampaign", error)
    if links["gate2"]["status"] == "BLOCKED":
        prerequisites = {name: links[name] for name in ("sourceLock", "makeLineage", "sealedGsi")
                         if links[name]["status"] != "PASS"}
        edge = next(iter(prerequisites), "campaignReceipt")
        reason = prerequisites.get(edge, links["gate2"])["reason"]
        sites = [dict(id=name, image=image, procedure=procedure, object=unit + ".o",
                      status="BLOCKED", edge=edge, reason=reason)
                 for name, (unit, image, procedure, _, _) in SITES.items()]
        links["gate2"].update(prerequisites=prerequisites, linkSelection=blocked_selection(edge, reason), sites=sites)
    for topology in result["topologies"]:
        for status in ("COMPLETED", "FAILED", "MISSING"):
            topology[status.lower()] = [case["file"] for case in topology["cases"] if case["status"] == status]
    result["passed"] = all(link["status"] == "PASS" for link in links.values())
    return result
