"""Reuse a verified completed bootstrap without rewriting historical outcomes."""
import json
import hashlib
import math
from pathlib import Path
from gambit_smp.artifact_storage import observation_root, fixture_name, fixture_path
import shutil
import sys

from gambit_smp.framework import digest, relative


SCHEMA = "completed-bootstrap-reference.v1"
FLAGS = {"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"}


def discovered_reference(path, ctx, *, explicit=False):
    """Historical observations share this store; only references grant reuse."""
    from gambit_smp.recipes import read_json
    try:
        return read_json(path)
    except json.JSONDecodeError as error:
        # A selected or recognizable producer declaration must still fail
        # closed. Never repair, overwrite or promote malformed observations.
        if explicit or SCHEMA in path.read_text():
            raise
        ctx.receipt.setdefault("unreadableHistoricalObservations", []).append({
            "path": str(path.relative_to(ctx.root)), "sha256": digest(path),
            "reason": str(error), "producerAdmitted": False})
        return None


def recover_retained_owner_teardown(root, run, outer, child, step_id):
    """Retire only the obsolete wall-clock decision after all stages passed."""
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.step_checkpoint import observe_journal
    rows = child.get("steps", [])
    if (outer.get("outcome") != "DENY" or outer.get("exit") != 1
            or outer.get("timeout") is not False or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or outer.get("childOutcome") != "DENY" or child.get("outcome") != "DENY"
            or outer.get("timeoutPolicy", {}).get("mode") != "progress"
            or child.get("wholeBudgetExhausted") is not False
            or child.get("inputsStable") is not True or child.get("error")
            or not rows or any(row.get("outcome") != "PASS" for row in rows)):
        raise ValueError("all completed quiescent progress-mode stages required to retire wall-clock verdict")
    launch = run / "launch.log"
    if (outer.get("artifacts", {}).get("launch.log") != digest(launch)
            or not launch.read_text().rstrip().endswith(
                "TimeoutError: research deadline exhausted during evaluation owner teardown")):
        raise ValueError("original denial must identify obsolete owner wall-clock check")
    owner_ref = child.get("evaluationOwner", {})
    owner_path = run / "run" / owner_ref.get("path", "missing-owner")
    if owner_ref.get("sha256") != digest(owner_path):
        raise ValueError("completed evaluation owner receipt changed")
    owner = read_json(owner_path)
    if (owner.get("exit") != 0 or owner.get("forcedTermination") is not False
            or owner.get("parentReaped") is not True
            or owner.get("terminalIdentityError") is not None
            or owner.get("engineId") != outer["engineId"] or not owner.get("requests")
            or any(row.get("requestCompleted") is not True or row.get("timeout") is not False
                   or row.get("response", {}).get("outcome") != "PASS"
                   for row in owner["requests"])):
        raise ValueError("normally reaped and fully checked evaluation owner required")
    recipe_path = relative(root, read_json(run / "request.json")["recipe"])
    if child.get("inputs", {}).get(str(recipe_path)) != digest(recipe_path):
        raise ValueError("retained recipe input closure changed")
    recipe = read_json(recipe_path)
    if (len(rows) != len(recipe["steps"])
            or any(any(row.get(key) != declared.get(key) for key in
                       ("id", "capability", "arguments", "dependsOn", "budgetSeconds"))
                   for row, declared in zip(rows, recipe["steps"]))):
        raise ValueError("exact completed stage declaration required")
    final = rows[-1]
    if final.get("capability") != "evidence.evaluate" or step_id not in final.get("dependsOn", []):
        raise ValueError("final review must bind the completed bootstrap")
    answers = run / "run" / final["id"] / "rule-evaluation/answers.json"
    if (final.get("artifacts", {}).get(str(answers.relative_to(run / "run"))) != digest(answers)
            or read_json(answers) != final["arguments"]["expected"]):
        raise ValueError("retained final ASCENT answer differs from exact contract")
    if manifest_paths(Path(outer["engine"]))["engineId"] != outer["engineId"]:
        raise ValueError("original sealed execution engine changed")
    journal, _, _, _ = observe_journal(root, run, step_id)
    return {"schema": "retained-owner-teardown-revalidation.v1",
            "journal": journal, "recordedOutcome": outer["outcome"],
            "ownerReceiptSha256": owner_ref["sha256"],
            "finalAnswersSha256": digest(answers), "originalLaunchLogSha256": digest(launch),
            "historicalDecision": "expired-total-wall-clock-owner-teardown",
            "currentDecision": "completed-stages-and-reaped-owner",
            "supersedesHistoricalDecision": True,
            "failedStagesRecovered": False, "budgetExtended": False}


def checked_owner_shutdown_failure(run, outer, child):
    """Recognize completed work followed only by the old owner shutdown failure."""
    from gambit_smp.recipes import read_json
    if (outer.get("timeout") is not False or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or child.get("inputsStable") is not True or child.get("error")
            or child.get("wholeBudgetExhausted") is not False
            or not child.get("steps")
            or any(row.get("outcome") != "PASS" for row in child["steps"])):
        raise ValueError("only completed stable native stages can revalidate owner shutdown")
    launch = run / "launch.log"
    if (outer.get("artifacts", {}).get("launch.log") != digest(launch)
            or not launch.read_text().rstrip().endswith(
                'ValueError: evaluation owner did not complete and tear down normally')):
        raise ValueError("exact retained owner shutdown failure required")
    ref = child.get("evaluationOwner", {})
    path = run / "run" / ref.get("path", "missing-owner")
    if ref.get("sha256") != digest(path):
        raise ValueError("retained owner receipt changed")
    owner = read_json(path)
    if (owner.get("forcedTermination") is not True or owner.get("exit") != -9
            or owner.get("parentReaped") is not True or owner.get("terminalIdentityError") is not None
            or owner.get("engineId") != outer["engineId"] or not owner.get("requests")
            or any(row.get("requestCompleted") is not True or row.get("timeout") is not False
                   or row.get("response", {}).get("outcome") != "PASS" for row in owner["requests"])):
        raise ValueError("completed owner requests and checked quiescence required")
    return {"priorOwnerReceiptSha256": ref["sha256"], "priorOwnerForcedTermination": True}


def recover_retained_evaluation(root, run, outer, child, step_id, *, owner_shutdown=False):
    """Re-evaluate only an expired final review; never recover native failure."""
    from gambit_smp.recipes import read_json
    from gambit_smp.evidence_capabilities import facts
    from gambit_smp.framework import execute
    from gambit_smp.research_kernel import manifest_paths
    rows = child.get("steps", [])
    if (outer.get("outcome") != "DENY" or outer.get("exit") != 1
            or outer.get("timeoutPolicy", {}).get("mode") != "progress"
            or not rows or any(row.get("outcome") != "PASS" for row in rows[:-1])):
        raise ValueError("only completed quiescent progress-mode execution can revalidate final review")
    last = rows[-1]
    owner_proof = checked_owner_shutdown_failure(run, outer, child) if owner_shutdown else {}
    if (last.get("capability") != "evidence.evaluate"
            or step_id not in last.get("dependsOn", [])):
        raise ValueError("final evaluation must bind completed bootstrap")
    if not owner_shutdown and (last.get("outcome") != "TIMEOUT"
            or last.get("reason") != "evaluation deadline exhausted" or last.get("commands")
            or step_id not in last.get("dependsOn", [])):
        raise ValueError("only an undispatched expired final evaluation can revalidate")
    recipe = relative(root, read_json(run / "request.json")["recipe"])
    if child.get("inputs", {}).get(str(recipe)) != digest(recipe):
        raise ValueError("original final evaluation recipe changed")
    declared = read_json(recipe)["steps"]
    if ([row["id"] for row in rows] != [row["id"] for row in declared]
            or last["arguments"] != declared[-1]["arguments"]):
        raise ValueError("original final evaluation inventory changed")
    path = run / "run" / last["id"] / "rule-evaluation/evaluation.json"
    if last.get("artifacts", {}).get(str(path.relative_to(run / "run"))) != digest(path):
        raise ValueError("original final evaluation request changed")
    request = read_json(path)
    args = last["arguments"]
    if (request["facts"] != facts(child) or request["queries"] != args["queries"]
            or request["rules"] != [str(relative(root, name)) for name in args["rules"]]
            or request["engineId"] != outer["engineId"]):
        raise ValueError("final evaluation must bind complete original observations")
    directory = run / "completion-revalidation-prepared"
    record_path = directory / "proof.json"
    if record_path.exists():
        proof = read_json(record_path)
        if (proof["originalOuterReceiptSha256"] != digest(run / "receipt.json")
                or proof["originalRequestSha256"] != digest(path)):
            raise ValueError("retained final evaluation revalidation changed")
    else:
        directory.mkdir(exist_ok=False)
        request["output"] = str(directory / "review")
        (directory / "review").mkdir()
        target = directory / "evaluation.json"
        target.write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
        window = declared[-1]["budgetSeconds"]
        engine = Path(outer["engine"])
        if manifest_paths(engine)["engineId"] != outer["engineId"]:
            raise ValueError("original evaluation engine changed")
        metadata = {}
        code, log, timed_out, seconds = execute(
            [sys.executable, "-I", "-B", engine / "runner.py", "rules", target],
            root, window, metadata=metadata)
        (directory / "evaluation.log").write_text(log)
        observed = {"exit": code, "timeout": timed_out, "seconds": seconds, **metadata}
        (directory / "evaluation.process.json").write_text(json.dumps(observed, indent=2) + "\n")
        if (code != 0 or timed_out or not metadata.get("parentReaped")
                or not metadata.get("processGroupQuiescent")
                or manifest_paths(engine)["engineId"] != outer["engineId"]):
            raise ValueError("original sealed final evaluation did not complete")
        proof = {"schema": "retained-final-evaluation-revalidation.v1",
                 "originalOuterReceiptSha256": digest(run / "receipt.json"),
                 "originalRequestSha256": digest(path), "recordedOutcome": outer["outcome"],
                 "failedStagesRecovered": False, "budgetExtended": False,
                 "reviewWindowSeconds": window, "engineId": outer["engineId"],
                 **owner_proof,
                 "artifacts": {name: digest(directory / name) for name in
                               ("evaluation.json", "review/answers.json", "evaluation.process.json")}}
        record_path.write_text(json.dumps(proof, sort_keys=True, indent=2) + "\n")
    if any(proof.get(key) != value for key, value in owner_proof.items()):
        raise ValueError("retained owner failure binding changed")
    if any(digest(directory / name) != sha for name, sha in proof["artifacts"].items()):
        raise ValueError("revalidation artifact changed")
    observed = read_json(directory / "evaluation.process.json")
    answers = read_json(directory / "review/answers.json")
    if (observed.get("exit") != 0 or observed.get("timeout")
            or not observed.get("parentReaped") or not observed.get("processGroupQuiescent")
            or answers != args["expected"]):
        raise ValueError("exact final relation and sealed owner completion required")
    return {**proof, "proofPath": str(record_path.relative_to(root)),
            "proofSha256": digest(record_path)}


def recover_retained_completion(root, run, outer, child, step_id):
    """Recheck a false-stale inventory verdict; never recover a failed stage."""
    from gambit_smp.recipes import read_json
    from gambit_smp.step_checkpoint import observe_journal
    if (outer.get("outcome") != "DENY" or outer.get("exit") != 2
            or outer.get("childOutcome") != "STALE" or child.get("outcome") != "STALE"
            or child.get("workspacePolicy") != "in-place"
            or child.get("wholeBudgetExhausted") is not False or child.get("error")
            or not child.get("steps") or any(row.get("outcome") != "PASS" for row in child["steps"])):
        raise ValueError("completed quiescent same-project producer required")
    request = read_json(run / "request.json")
    recipe_path = relative(root, request["recipe"])
    if child.get("inputs", {}).get(str(recipe_path)) != digest(recipe_path):
        raise ValueError("recovery recipe must belong to the original input closure")
    recipe = read_json(recipe_path)
    if [row["id"] for row in child["steps"]] != [row["id"] for row in recipe["steps"]]:
        raise ValueError("incomplete stage inventory cannot recover")
    proof, _, _, _ = observe_journal(root, run, step_id)
    return {"schema": "retained-completion-revalidation.v1", "journal": proof,
            "recordedOutcome": outer["outcome"], "recordedChildOutcome": child["outcome"],
            "failedStagesRecovered": False, "budgetExtended": False}


def bootstrap_ancestry(root, rows, step):
    seed = rows[step["arguments"]["runtime"]["step"]]
    if (seed.get("outcome") != "PASS"
            or step["arguments"]["identity"]["step"] != seed["id"]):
        raise ValueError("bootstrap must bind its exact seed producer")
    if seed["capability"] in {"gambit.seed-core", "gambit.bootstrap-input"}:
        if seed['capability'] == 'gambit.bootstrap-input' and (
                seed.get('claim') != 'qualified-host-compiler-not-target-runtime'
                or seed['outputs']['source']['type'] != 'bootstrap-input'
                or seed['outputs']['identity']['type'] != 'bootstrap-input-identity'):
            raise ValueError('typed compiler-only bootstrap ancestry required')
        configured = rows[seed["arguments"]["source"]["step"]]
        materialized = rows[configured["arguments"]["source"]["step"]]
    elif seed["capability"] == "gambit.source-core":
        # A real completed self-source pass can precede the official two-pass
        # bootstrap. Trace its seed ancestry; do not promote it to a completed
        # bootstrap or accept an unrelated runtime with the same filenames.
        parent = seed["arguments"]["runtime"]
        if parent["step"] == seed["id"] or rows[parent["step"]]["capability"] not in {
                "gambit.seed-core", "gambit.seed-checkpoint"}:
            raise ValueError("self-source runtime needs its exact typed seed ancestry")
        _, configured, materialized = bootstrap_ancestry(root, rows, {"arguments": {
            "runtime": parent, "identity": {"step": parent["step"], "output": "identity"}}})
    elif seed["capability"] == "gambit.seed-checkpoint":
        from gambit_smp.recipes import read_json
        from gambit_smp.step_checkpoint import seed_reference
        reference = read_json(relative(root, seed["arguments"]["checkpoint"]))
        original, configured, original_source, _ = seed_reference(root, reference, historical=True)
        materialized = rows[seed["arguments"]["source"]["step"]]
        in_place = seed.get("storageTransfer", {}).get("schema") == "in-place-checkpoint-storage.v1"
        expected_source = (original[3]["outputs"]["runtime"]["identity"] if in_place
                           else original_source["outputs"]["source"]["identity"])
        if (seed.get("checkpoint") != original[0]
                or materialized["outputs"]["source"]["identity"] != expected_source
                or seed["outputs"]["runtime"]["identity"] != original[3]["outputs"]["runtime"]["identity"]
                or seed["outputs"]["identity"]["sha256"] != original[3]["outputs"]["identity"]["sha256"]):
            raise ValueError("bootstrap checkpoint ancestry or artifacts drifted")
    else:
        raise ValueError("bootstrap needs a successful typed seed producer")
    if (configured["capability"] != "gambit.configure" or configured["outcome"] != "PASS"
            or materialized["capability"] != "gambit.materialize" or materialized["outcome"] != "PASS"):
        raise ValueError("bootstrap source must have the locked producer ancestry")
    return seed, configured, materialized


def configure_command(root, configured):
    """Read a real configure observation, including checked configuration reuse.

    Reuse does not manufacture a new configure invocation. The original full
    process receipt and all generated configuration hashes stay authenticated
    by the successful configure stage and its producer envelope.
    """
    from gambit_smp.step_checkpoint import stage_commands
    commands=[r for r in stage_commands(root,configured) if r['stage']=='configure']
    if commands:
        if len(commands)!=1:raise ValueError('unique completed configure observation required')
        return commands[0]
    proof=configured.get('configurationReuse',{})
    raw=proof.get('receiptBytes','')
    if (proof.get('schema')!='gambit-configure-reuse.v1' or not raw
            or hashlib.sha256(raw.encode()).hexdigest()!=proof.get('receiptSha256')):
        raise ValueError('bound original configure receipt required')
    observed=json.loads(raw)
    if (observed.get('stage')!='configure' or observed.get('state')!='OBSERVED'
            or observed.get('exit')!=0 or observed.get('timeout') is not False
            or observed.get('parentReaped') is not True or observed.get('processGroupQuiescent') is not True
            or len(proof.get('commands',[]))!=1
            or any(observed.get(k)!=v for k,v in proof['commands'][0].items())
            or observed.get('argv',[])[2:]!=proof.get('flags')):
        raise ValueError('configure reuse lacks completed process evidence')
    from gambit_smp.native_capabilities import CONFIGURATION_OUTPUTS
    identity=configured.get('outputs',{}).get('source',{}).get('identity',{})
    if (set(proof.get('files',{}))!=set(CONFIGURATION_OUTPUTS)
            or any(identity.get(name,{}).get('sha256')!=sha for name,sha in proof['files'].items())):
        raise ValueError('configure reuse generated-byte identity differs')
    return proof['commands'][0]


def completed(root, run, step_id, *, input_archive=None, workspace_context=None):
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import inspect, manifest_paths
    root, run = root.resolve(), run.resolve(strict=True)
    observation_root(root, run)
    outer = read_json(run / "receipt.json")
    child = read_json(run / "run/receipt.json")
    if (outer.get("timeout") is not False or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or Path(outer["root"]).resolve() != root):
        raise ValueError("completed quiescent same-project producer required")
    budget, spent = outer["budgetSeconds"], outer["wholeSeconds"]
    if (type(budget) not in (int, float) or type(spent) not in (int, float)
            or not math.isfinite(budget) or not math.isfinite(spent) or budget <= 0 or spent <= 0
            or (spent > budget and outer.get("timeoutPolicy", {}).get("mode") != "progress")):
        raise ValueError("original completed producer expenditure must fit its budget")
    if workspace_context is not None:
        from gambit_smp.recipes import artifact_path
        output = next(row for row in child["steps"] if row["id"] == step_id)["outputs"]["runtime"]
        workspace = artifact_path(run / "run", output, root=root)
        # Locking protects validation; it is not admission of the unverified receipt.
        workspace_context.lease_workspace(workspace, output["identity"])
    if inspect(run, input_archive=input_archive)["identityStatus"] not in {"CURRENT", "HISTORICAL_BOUND"}:
        raise ValueError("completed producer evidence or artifacts drifted")
    recovery = None
    if outer.get("outcome") != "PASS" or outer.get("exit") != 0:
        if outer.get("childOutcome") == "STALE":
            recovery = recover_retained_completion(root, run, outer, child, step_id)
        elif all(row.get("outcome") == "PASS" for row in child.get("steps", [])):
            if outer.get("outcome") != "DENY" or outer.get("exit") != 1:
                raise ValueError("exact completed quiescent owner finalization required")
            owner_ref = child.get("evaluationOwner", {})
            owner_path = run / "run" / owner_ref.get("path", "missing-owner")
            if not owner_path.is_file() or owner_ref.get("sha256") != digest(owner_path):
                raise ValueError("retained owner receipt required")
            owner = read_json(owner_path)
            if owner.get("forcedTermination") is True:
                recovery = recover_retained_evaluation(root, run, outer, child, step_id, owner_shutdown=True)
            else:
                recovery = recover_retained_owner_teardown(root, run, outer, child, step_id)
        else:
            recovery = recover_retained_evaluation(root, run, outer, child, step_id)
    rows = {row["id"]: row for row in child["steps"]}
    step = rows[step_id]
    if (step.get("capability") != "gambit.bootstrap" or step.get("outcome") != "PASS"
            or step.get("fullTwoPassBootstrapEstablished") is not True
            or step.get("phaseCounts") != {"phase1": 2, "phase2": 2, "phase3": 2, "phase4": 2}):
        raise ValueError("complete two-pass bootstrap producer required")
    seed, configured, materialized = bootstrap_ancestry(root, rows, step)
    from gambit_smp.recipes import artifact_path, tree_identity
    output = step["outputs"]["runtime"]
    current_runtime = artifact_path(run / "run", output, root=root)
    if tree_identity(current_runtime) != output["identity"]:
        raise ValueError("completed runtime bytes unavailable or changed")
    command = configure_command(root, configured)
    if command["exit"] != 0 or command["timeout"] is not False or not FLAGS <= set(command["argv"]):
        raise ValueError("all three concurrency flags must be observed in the producer")
    manifest = manifest_paths(Path(outer["engine"]))
    source_lock = materialized["arguments"]["sourceLock"]
    reference = {"schema": SCHEMA, "run": fixture_name(root, run),
                 "outerReceiptSha256": digest(run / "receipt.json"),
                 "childReceiptSha256": digest(run / "run/receipt.json"),
                 "step": step_id, "stepReceiptSha256": digest(run / "run" / step_id / "step-receipt.json"),
                 "engineId": outer["engineId"], "sourceLock": source_lock,
                 "sourceLockSha256": digest(relative(root, source_lock)),
                 "gccSha256": manifest["hostTools"]["gcc"]["sha256"]}
    if input_archive is not None:
        reference["inputArchive"] = {"path": input_archive, "sha256": digest(relative(root, input_archive))}
    if recovery is not None:
        reference["completionRevalidation"] = recovery
    return reference, outer, step, materialized


def export_reference(root, run, step, out, *, input_archive=None):
    reference, _, _, _ = completed(root, run, step, input_archive=input_archive)
    out = out.resolve()
    if not out.is_relative_to(root.resolve() / "evidence/research") or out.suffix != ".json":
        raise ValueError("producer reference must be a research Evidence JSON file")
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("x") as stream:
        json.dump(reference, stream, indent=2)
        stream.write("\n")
    return reference


def validate(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("source", "producer"))
    reference(args["source"])
    if args["producer"] not in inputs or not args["producer"].endswith(".json"):
        raise ValueError("declared completed producer reference required")


def prevent_duplicate_bootstrap(args, ctx):
    """Require explicit completed-runtime reuse before another costly bootstrap."""
    rows = {row["id"]: row for row in ctx.receipt["steps"]}
    seed = rows[args["runtime"]["step"]]
    if seed["capability"] == "gambit.seed-checkpoint":
        from gambit_smp.recipes import read_json
        from gambit_smp.step_checkpoint import seed_reference
        reference = read_json(relative(ctx.root, seed["arguments"]["checkpoint"]))
        _, configured, _, _ = seed_reference(ctx.root, reference)
        configuration = {**configured["arguments"], "source": seed["arguments"]["source"]}
        prevent_duplicate_configuration(configuration, ctx, stage="bootstrap")
        return
    configured = rows[seed["arguments"]["source"]["step"]]
    prevent_duplicate_configuration(configured["arguments"], ctx, stage="bootstrap")


def reuse_materialized_source(lock_path, ctx):
    """Reuse validated source bytes, not compiler output or native admission."""
    from gambit_smp.recipes import read_json, tree_identity, source_path
    from gambit_smp.artifact_storage import transfer_tree
    lock_sha = digest(lock_path)
    plan = getattr(ctx, "planned_steps", ctx.receipt["steps"])
    materializers = {row["id"] for row in plan
                    if row["capability"] == "gambit.materialize"
                    and relative(ctx.root, row["arguments"]["sourceLock"]) == lock_path.resolve()}
    explicit = {source_path(ctx.root, row["arguments"]["producer"])
                for row in plan if row["capability"] == "gambit.completed-runtime"
                and row["arguments"]["source"]["step"] in materializers}
    if len(explicit) > 1:
        raise ValueError("materialized source has ambiguous explicit completed producers")
    paths = explicit if explicit else sorted((ctx.root / "evidence/research").rglob("*.json"))
    for path in paths:
        ctx.remaining()
        if path.is_symlink():
            continue
        proof = discovered_reference(path, ctx, explicit=bool(explicit))
        if (not isinstance(proof, dict) or proof.get("schema") != SCHEMA
                or proof.get("sourceLockSha256") != lock_sha):
            if explicit:
                raise ValueError("explicit completed producer does not match the source lock")
            continue
        run = fixture_path(ctx.root, proof["run"])
        if not run.exists():
            if explicit:
                raise ValueError("explicit completed producer runtime is unavailable")
            continue
        archive = proof.get("inputArchive", {}).get("path")
        actual, _, bootstrap, materialized = completed(ctx.root, run, proof["step"], input_archive=archive,
                                                      workspace_context=ctx if ctx.receipt.get("workspacePolicy") == "in-place" else None)
        if actual != proof:
            raise ValueError("registered completed source drift; no silent rematerialization")
        output = materialized["outputs"]["source"]
        if ctx.receipt.get("workspacePolicy") == "in-place":
            output = bootstrap["outputs"]["runtime"]
        from gambit_smp.recipes import artifact_path
        original = artifact_path(run / "run", output, root=ctx.root)
        if tree_identity(original) != output["identity"]:
            raise ValueError("completed source tree drift")
        ctx.bind([path, run / "receipt.json", run / "run/receipt.json"])
        if ctx.receipt.get("workspacePolicy") == "in-place":
            ctx.lease_workspace(original, output["identity"])
            target = original
            storage = {"mode": "same-workspace", "copiedFiles": 0}
        else:
            target = ctx.directory / "source"
            storage = transfer_tree(original, target)
        if tree_identity(target) != output["identity"] or tree_identity(original) != output["identity"]:
            raise ValueError("completed source changed during transfer")
        if completed(ctx.root, run, proof["step"], input_archive=archive,
                     workspace_context=ctx if ctx.receipt.get("workspacePolicy") == "in-place" else None)[0] != proof:
            raise ValueError("completed source evidence changed during transfer")
        ctx.remaining()
        decision = {"decision": "REUSE_MATERIALIZED_SOURCE", "stage": "materialize",
                    "producer": path.relative_to(ctx.root).as_posix(),
                    "sourceLockSha256": lock_sha, "storageTransfer": storage}
        ctx.receipt.setdefault("buildReuseDecisions", []).append(decision)
        return {"outputs": ctx.publish("source", "source-tree", target),
                "storageTransfer": storage, "claim": "locked-source-reuse-not-native-admission"}
    return None


def prevent_duplicate_configuration(args, ctx, *, stage="configure"):
    """Reject redundant work before cloning, configuring or compiling a seed."""
    from gambit_smp.recipes import read_json
    rows = {row["id"]: row for row in ctx.receipt["steps"]}
    materialized = rows[args["source"]["step"]]
    lock = materialized["arguments"]["sourceLock"]
    lock_sha = digest(relative(ctx.root, lock))
    gcc_sha = digest(Path(ctx.tools["gcc"]))
    configuration = {key: value for key, value in args.items() if key != "source"}
    store = ctx.root / "evidence/research"
    for path in sorted(store.rglob("*.json")):
        ctx.remaining()
        if path.is_symlink():
            continue
        proof = discovered_reference(path, ctx)
        if not isinstance(proof, dict) or proof.get("schema") != SCHEMA:
            continue
        if proof.get("sourceLockSha256") != lock_sha or proof.get("gccSha256") != gcc_sha:
            continue
        run = fixture_path(ctx.root, proof["run"])
        # A registered reference whose tree is gone is not a completed runtime.
        # Fresh configure stays allowed, matching missing-cache materialization.
        if not run.exists():
            continue
        actual, _, step, _ = completed(ctx.root, run, proof["step"],
                                      input_archive=proof.get("inputArchive", {}).get("path"))
        if actual != proof:
            raise ValueError("registered completed producer drift; no silent duplicate rebuild")
        previous = {row["id"]: row for row in read_json(run / "run/receipt.json")["steps"]}
        _, old_config, _ = bootstrap_ancestry(ctx.root, previous, step)
        old_configuration = {key: value for key, value in old_config["arguments"].items() if key != "source"}
        if old_configuration != configuration:
            continue
        name = path.relative_to(ctx.root).as_posix()
        ctx.bind([path, run / "receipt.json", run / "run/receipt.json"])
        ctx.receipt.setdefault("buildReuseDecisions", []).append({
            "decision": "DENY_DUPLICATE_BOOTSTRAP", "producer": name,
            "stage": stage,
            "sourceLockSha256": lock_sha, "gccSha256": gcc_sha,
            "requiredCapability": "gambit.completed-runtime"})
        raise ValueError("completed bootstrap already exists; use gambit.completed-runtime with " + name)


def reuse(args, ctx):
    from gambit_smp.recipes import fields, read_json, source_path, tree_identity
    source = ctx.artifact(args["source"], "source-tree")
    proof_path = source_path(ctx.root, args["producer"])
    proof = read_json(proof_path)
    fields(proof, ("schema", "run", "outerReceiptSha256", "childReceiptSha256", "step",
                   "stepReceiptSha256", "engineId", "sourceLock", "sourceLockSha256", "gccSha256"), ("inputArchive", "completionRevalidation"))
    if proof["schema"] != SCHEMA:
        raise ValueError("typed completed bootstrap reference required")
    run = fixture_path(ctx.root, proof["run"])
    history = proof.get("inputArchive")
    archive_paths = []
    if history is not None:
        fields(history, ("path", "sha256"))
        if digest(source_path(ctx.root, history["path"])) != history["sha256"]:
            raise ValueError("historical source-input archive drift")
        from gambit_smp.historical_inputs import bindings
        _, archive_paths = bindings(ctx.root, run / "receipt.json", history["path"])
    archive_name = history["path"] if history is not None else None
    actual, outer, step, materialized = completed(ctx.root, run, proof["step"], input_archive=archive_name,
                                                 workspace_context=ctx if ctx.receipt.get("workspacePolicy") == "in-place" else None)
    if actual != proof:
        raise ValueError("completed producer reference drift")
    if digest(Path(ctx.tools["gcc"])) != proof["gccSha256"]:
        raise ValueError("consumer GNU compiler differs from the producer")
    in_place = ctx.receipt.get("workspacePolicy") == "in-place"
    expected_source = step["outputs"]["runtime"] if in_place else materialized["outputs"]["source"]
    if tree_identity(source) != expected_source["identity"]:
        raise ValueError("consumer locked source differs from the completed producer")
    bindings = [proof_path, run / "receipt.json", run / "run/receipt.json",
                run / "run" / proof["step"] / "step-receipt.json"]
    ctx.bind([*bindings, *archive_paths])
    from gambit_smp.recipes import artifact_path
    original = artifact_path(run / "run", step["outputs"]["runtime"], root=ctx.root)
    original_identity = relative(run / "run", step["outputs"]["identity"]["path"])
    target, identity = ctx.directory / "runtime", ctx.directory / "identity.json"
    from gambit_smp.artifact_storage import transfer_tree
    if in_place:
        if source != original:
            raise ValueError("in-place producer requires the same workspace")
        ctx.lease_workspace(original, expected_source["identity"])
        target = original
        storage = {"mode": "same-workspace", "copiedFiles": 0}
    else:
        storage = transfer_tree(original, target)
    shutil.copy2(original_identity, identity)
    if (tree_identity(target) != step["outputs"]["runtime"]["identity"]
            or digest(identity) != step["outputs"]["identity"]["sha256"]):
        raise ValueError("completed artifact changed during transfer")
    if completed(ctx.root, run, proof["step"], input_archive=archive_name,
                 workspace_context=ctx if ctx.receipt.get("workspacePolicy") == "in-place" else None)[0] != proof:
        raise ValueError("completed producer changed during transfer")
    expenditure = {"receiptSha256": proof["outerReceiptSha256"], "budgetSeconds": outer["budgetSeconds"],
                   "seconds": outer["seconds"], "wholeSeconds": outer["wholeSeconds"],
                   "scope": "Completed source stage, retained separately; not a reset or interrupted continuation"}
    ctx.receipt.setdefault("upstreamProducerExpenditures", {})[proof["outerReceiptSha256"]] = expenditure
    return {"outputs": {**ctx.publish("runtime", "source-runtime", target),
                        **ctx.publish("identity", "runtime-identity", identity)},
            "producerDecisionSupersession": (
                {**proof["completionRevalidation"],
                 "historicalReceiptSha256": proof["outerReceiptSha256"]}
                if proof.get("completionRevalidation", {}).get("supersedesHistoricalDecision") else None),
            "producerExpenditure": expenditure, "runtimeAdmitted": False,
            "storageTransfer": storage,
            "claim": "same-source-completed-bootstrap-transfer-not-native-admission-or-performance"}
