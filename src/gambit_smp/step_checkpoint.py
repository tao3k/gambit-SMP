"""Observe committed successful steps; failed campaigns remain failed.

This module neither executes a checkpoint nor reclassifies a seed as a full
runtime. Native adapters and Evidence rules must authorize any consumption.
"""
import hashlib
import json
from pathlib import Path
from gambit_smp.artifact_storage import fixture_root, fixture_name, fixture_path

from gambit_smp.framework import digest, relative


SCHEMA = "successful-step-checkpoint.v1"


def ancestry(rows, target):
    """Require the complete successful dependency closure, rejecting cycles."""
    by_id = {}
    for row in rows:
        name = row["id"]
        if not isinstance(name, str) or name in by_id:
            raise ValueError("unique checkpoint step identities required")
        by_id[name] = row
    visiting, visited, ordered = set(), set(), []

    def visit(name):
        if name in visiting:
            raise ValueError("checkpoint dependency cycle")
        if name in visited:
            return
        if name not in by_id:
            raise ValueError("checkpoint prerequisite missing")
        row = by_id[name]
        if row.get("outcome") != "PASS":
            raise ValueError("checkpoint prerequisite not successful")
        dependencies = row.get("dependsOn")
        if (not isinstance(dependencies, list) or
                any(not isinstance(item, str) for item in dependencies) or
                len(set(dependencies)) != len(dependencies)):
            raise ValueError("complete unique dependency inventory required")
        commands = row.get("commands", [])
        if any(command.get("timeout") is not False or
               command.get("exit") != command.get("expectedExit", 0) or
               command.get("parentReaped") is not True or
               command.get("processGroupQuiescent") is not True
               for command in commands):
            raise ValueError("checkpoint has unsuccessful native command")
        if "exit" in row and (row["exit"] != 0 or row.get("timeout") is not False
                              or row.get("parentReaped") is not True
                              or row.get("processGroupQuiescent") is not True):
            raise ValueError("checkpoint command teardown unverified")
        visiting.add(name)
        for parent in dependencies:
            visit(parent)
        visiting.remove(name)
        visited.add(name)
        ordered.append(row)

    visit(target)
    return ordered


def content_id(value):
    raw = json.dumps(value, sort_keys=True, separators=(",", ":"), allow_nan=False).encode()
    return hashlib.sha256(raw).hexdigest()


def journal_closure(root, run, outer, header, observations, target):
    """Read immutable stage records, without inventing a final child receipt."""
    from gambit_smp.reasoning_history import normalized
    from gambit_smp.recipes import read_json
    reference = outer["journal"]
    rows, references, visiting = {}, {}, set()

    def read(name, expected=None):
        if not isinstance(name, str) or not name or Path(name).name != name:
            raise ValueError("bounded journal step identity required")
        if name in visiting:
            raise ValueError("journal dependency cycle")
        path = run / "run" / (name + ".observation.json")
        if path.is_symlink():
            raise ValueError("journal stage aliases are not admissible")
        raw = path.read_bytes()
        record = json.loads(raw)
        sha = hashlib.sha256(raw).hexdigest()
        if (record.get("schema") != "research-step-observation.v1"
                or record.get("runId") != header["runId"] or record.get("header") != reference
                or record.get("step", {}).get("id") != name):
            raise ValueError("journal stage belongs to another producer")
        candidates = [identity for identity, body in observations.items()
                      if body.get("scope") == reference["scope"] and
                      body.get("queries") == normalized({"run_record": [record]})]
        if len(candidates) != 1:
            raise ValueError("journal stage lacks one immutable observation binding")
        actual = {"path": str(path), "sha256": sha, "observation": candidates[0],
                  "scope": reference["scope"]}
        if expected is not None and expected != actual:
            raise ValueError("journal prerequisite identity changed")
        if name in rows:
            if references[name] != actual:
                raise ValueError("journal stage changed during closure read")
            return
        body = observations[candidates[0]]
        bound_sources = {}
        for source, value in body.get("inputs", {}).items():
            source_path = Path(source) if Path(source).is_absolute() else relative(root, source)
            if digest(source_path) != value:
                raise ValueError("journal generator or input changed")
            bound_sources[str(source_path.resolve(strict=True))] = value
        for source, value in outer.get("inputs", {}).items():
            if bound_sources.get(str(relative(root, source))) != value:
                raise ValueError("journal stage omits original producer inputs")
        tools = record.get("toolInputs")
        if not isinstance(tools, dict) or not tools:
            raise ValueError("journal stage lacks immutable tool bindings")
        for source, value in tools.items():
            if not Path(source).is_absolute() or digest(Path(source)) != value:
                raise ValueError("journal tool changed")
        dependencies = record.get("dependencies")
        step = record["step"]
        for source, value in step.get("observedInputs", {}).items():
            if not Path(source).is_absolute() or digest(Path(source)) != value:
                raise ValueError("journal observed input changed")
        for artifact, value in step.get("artifacts", {}).items():
            artifact_path = relative(run / "run", artifact)
            if artifact_path.is_symlink() or digest(artifact_path) != value:
                raise ValueError("journal stage artifact changed")
        if not isinstance(dependencies, dict) or set(dependencies) != set(step["dependsOn"]):
            raise ValueError("journal dependency closure incomplete")
        visiting.add(name)
        for parent in step["dependsOn"]:
            if not isinstance(dependencies[parent], dict):
                raise ValueError("journal prerequisite observation missing")
            read(parent, dependencies[parent])
        visiting.remove(name)
        if path.read_bytes() != raw:
            raise ValueError("journal stage changed during observation")
        rows[name], references[name] = step, actual

    read(target)
    return ancestry(list(rows.values()), target), references


def observe_journal(root, run, target, *, historical=False):
    """Bind a successful stage of a terminal failed run; admission stays false."""
    from gambit_smp.reasoning_history import normalized, read_journal
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import read_json, inspect_outputs
    root, run = root.resolve(strict=True), run.resolve(strict=True)
    fixture_root(root, run)
    outer_path = run / "receipt.json"
    raw = outer_path.read_bytes()
    outer = json.loads(raw)
    if (outer.get("schema") != "sealed-research-run.v1" or outer.get("outcome") not in {"PASS", "DENY"}
            or outer.get("executionLaunched") is not True or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True or Path(outer["root"]).resolve() != root):
        raise ValueError("terminal quiescent journal producer required")
    engine = manifest_paths(Path(outer["engine"]))
    if engine["engineId"] != outer["engineId"]:
        raise ValueError("journal generator identity changed")
    if not isinstance(outer.get("inputs"), dict) or not outer["inputs"]:
        raise ValueError("journal original input closure required")
    reference = outer["journal"]
    path = Path(reference["path"])
    if path != run / "run-header.json" or path.is_symlink() or digest(path) != reference["sha256"]:
        raise ValueError("journal header identity changed")
    header = read_json(path)
    history = read_journal(root, reference["scope"])["observations"]
    if (history[reference["observation"]]["queries"] != normalized({"run_record": [header]})
            or header["engineId"] != outer["engineId"] or header["recipe"] != outer["recipe"]
            or header["inputs"] != outer["inputs"]):
        raise ValueError("journal header differs from original producer")
    for name, sha in outer["inputs"].items():
        if digest(relative(root, name)) != sha:
            raise ValueError("journal original input changed")
    closure, references = journal_closure(root, run, outer, header, history, target)
    if historical:
        # An ancestry witness is not an importable executable generation.
        from gambit_smp.artifact_storage import checked_workspace_state
        for row in closure:
            for descriptor in row.get("outputs", {}).values():
                if "identity" in descriptor:
                    if "stateEvidence" not in descriptor:
                        raise ValueError("journal historical tree lacks retained state evidence")
                    checked_workspace_state(root, descriptor["stateEvidence"], descriptor["identity"])
                elif inspect_outputs(run / "run", [{"id": row["id"], "outputs": {"value": descriptor}}],
                                     root=root)["status"] != "AVAILABLE":
                    raise ValueError("journal historical artifact unavailable or changed")
    else:
        state = inspect_outputs(run / "run", closure, root=root)
        if (state["status"] not in {"AVAILABLE", "RETAINED"} or
                any(row["status"] != "AVAILABLE" for row in state["outputs"] if row["step"] == target)):
            raise ValueError("journal final artifact inventory unavailable or changed")
    if not closure[-1].get("outputs"):
        raise ValueError("journal checkpoint has no typed artifacts")
    if outer_path.read_bytes() != raw or digest(path) != reference["sha256"]:
        raise ValueError("journal producer changed during observation")
    return {"schema": "successful-stage-journal.v1", "run": fixture_name(root, run),
            "outerReceiptSha256": hashlib.sha256(raw).hexdigest(), "engineId": outer["engineId"],
            "step": target, "stageReferences": {
                name: {**ref, "path": Path(ref["path"]).relative_to(root).as_posix()}
                for name, ref in references.items()}, "campaignOutcome": outer["outcome"],
            "runtimeAdmitted": False, "resumptionAuthorized": False,
            "missingChildReceiptReconstructed": False}, outer, closure, engine


def observe(root, run, target):
    """Bind the original generator, all inputs/artifacts and successful closure."""
    from gambit_smp.research_kernel import inspect, manifest_paths
    root, run = root.resolve(strict=True), run.resolve(strict=True)
    fixture_root(root, run)
    outer_path, child_path = run / "receipt.json", run / "run/receipt.json"
    outer_raw, child_raw = outer_path.read_bytes(), child_path.read_bytes()
    outer, child = json.loads(outer_raw), json.loads(child_raw)
    if (outer.get("schema") != "sealed-research-run.v1"
            or outer.get("outcome") not in {"PASS", "DENY"}
            or outer.get("executionLaunched", True) is not True
            or outer.get("parentReaped") is not True
            or outer.get("processGroupQuiescent") is not True
            or Path(outer["root"]).resolve(strict=True) != root):
        raise ValueError("terminal quiescent sealed checkpoint observation required")
    child_sha = hashlib.sha256(child_raw).hexdigest()
    if child_sha != outer.get("childReceiptSha256"):
        raise ValueError("checkpoint child receipt changed")
    if child.get("recipe") != outer["recipe"] or child.get("inputsStable") is not True:
        raise ValueError("checkpoint campaign or inputs unbound")
    engine = manifest_paths(Path(outer["engine"]))
    if engine["engineId"] != outer["engineId"]:
        raise ValueError("checkpoint generator identity changed")
    if inspect(run)["identityStatus"] != "CURRENT":
        raise ValueError("checkpoint original inputs, tools or outputs changed")
    closure = ancestry(child["steps"], target)
    selected = closure[-1]
    if not selected.get("outputs"):
        raise ValueError("checkpoint has no typed output inventory")
    for descriptor in selected["outputs"].values():
        if not isinstance(descriptor.get("type"), str):
            raise ValueError("checkpoint output type missing")
        relative(run / "run", descriptor["path"])
    proof = {"schema": SCHEMA, "run": fixture_name(root, run),
             "outerReceiptSha256": hashlib.sha256(outer_raw).hexdigest(),
             "childReceiptSha256": child_sha, "engineId": outer["engineId"], "step": target,
             "ancestry": [{"id": row["id"], "observationContentId": content_id(row)} for row in closure],
             "outputsContentId": content_id(selected["outputs"]),
             "campaignOutcome": outer["outcome"],
             "runtimeAdmitted": False, "resumptionAuthorized": False}
    if outer_path.read_bytes() != outer_raw or child_path.read_bytes() != child_raw:
        raise ValueError("checkpoint receipt changed during observation")
    return proof, outer, closure, selected, engine


def bound(root, reference, *, historical=False):
    """Reject changed or legacy references; never reconstruct missing closure."""
    if isinstance(reference, dict) and reference.get("schema") == "successful-stage-journal.v1":
        run = fixture_path(root, reference["run"])
        proof, outer, closure, engine = observe_journal(root, run, reference["step"], historical=historical)
        if proof != reference:
            raise ValueError("successful-stage journal reference drift")
        return proof, outer, closure, closure[-1], engine
    expected = {"schema", "run", "outerReceiptSha256", "childReceiptSha256", "engineId",
                "step", "ancestry", "outputsContentId", "campaignOutcome", "runtimeAdmitted",
                "resumptionAuthorized"}
    if not isinstance(reference, dict) or set(reference) != expected or reference["schema"] != SCHEMA:
        raise ValueError("complete typed successful-step reference required")
    run = fixture_path(root, reference["run"])
    result = observe(root, run, reference["step"])
    if result[0] != reference:
        raise ValueError("successful-step checkpoint reference drift")
    return result


def expenditures(root, checkpoint, records, *, historical_only=False):
    """Follow every prior edge; omission cannot create a new budget."""
    from gambit_smp.recipe_continuation import remaining_budget
    if not isinstance(records, list) or not records:
        raise ValueError("complete checkpoint expenditure lineage required")
    by_sha, paths = {}, []
    for record in records:
        if not isinstance(record, dict) or set(record) != {"run", "sha256"}:
            raise ValueError("typed expenditure record required")
        path = fixture_path(root, record["run"]) / "receipt.json"
        raw = path.read_bytes()
        sha = hashlib.sha256(raw).hexdigest()
        if sha != record["sha256"] or sha in by_sha:
            raise ValueError("expenditure identity changed or duplicated")
        by_sha[sha] = json.loads(raw)
        paths.append((path, sha))
    sha, visited = checkpoint["outerReceiptSha256"], set()
    while True:
        if sha in visited or sha not in by_sha:
            raise ValueError("missing or cyclic expenditure predecessor")
        visited.add(sha)
        current = by_sha[sha]
        if current.get("recipe") != by_sha[checkpoint["outerReceiptSha256"]].get("recipe"):
            raise ValueError("unrelated checkpoint expenditure")
        previous = current.get("prior")
        if previous is None:
            original_budget = current["budgetSeconds"]
            break
        sha = previous["receiptSha256"]
    if visited != set(by_sha):
        raise ValueError("expenditure list must be the complete exact prior lineage")
    if historical_only:
        import math
        observations, spent = [], 0.0
        for sha, receipt in by_sha.items():
            elapsed, cap = receipt.get("wholeSeconds"), receipt.get("budgetSeconds")
            if (receipt.get("schema") != "sealed-research-run.v1"
                    or receipt.get("parentReaped") is not True
                    or receipt.get("processGroupQuiescent") is not True
                    or receipt.get("outcome") not in {"PASS", "DENY"}
                    or receipt.get("timeoutPolicy", {}).get("mode") != "progress"
                    or receipt.get("budgetReservation") is not None
                    or type(elapsed) not in (int, float) or not math.isfinite(elapsed) or elapsed <= 0
                    or type(cap) not in (int, float) or not math.isfinite(cap) or cap <= 0):
                raise ValueError("unreserved quiescent progress-mode expenditure history required")
            spent += elapsed
            observations.append({"sha256": sha, "outcome": receipt["outcome"],
                                 "watchdogSeconds": cap, "wholeSeconds": elapsed})
        if any(digest(path) != sha for path, sha in paths):
            raise ValueError("expenditure history changed during observation")
        return {"controlRole": "history-only", "originalWatchdogSeconds": original_budget,
                "spentSeconds": spent, "observations": observations,
                "prefixReusable": False, "producerAdmitted": False}
    return remaining_budget(original_budget, paths)


def seed_ancestry(closure):
    """Validate the existing native seed/configuration/source type contracts."""
    by_id = {row["id"]: row for row in closure}
    seed = closure[-1]
    if (seed["capability"] != "gambit.seed-core"
            or set(seed["outputs"]) != {"runtime", "identity"}
            or seed["outputs"]["runtime"]["type"] != "seed-runtime"
            or seed["outputs"]["identity"]["type"] != "runtime-identity"
            or seed.get("claim") != "pre-generated-C-seed-only"):
        raise ValueError("a successful native seed is not a completed runtime")
    config_ref = seed["arguments"]["source"]
    configured = by_id[config_ref["step"]]
    if config_ref["output"] != "source" or configured["capability"] != "gambit.configure":
        raise ValueError("seed must bind its configured source producer")
    materialized_ref = configured["arguments"]["source"]
    materialized = by_id[materialized_ref["step"]]
    if materialized_ref["output"] != "source" or materialized["capability"] != "gambit.materialize":
        raise ValueError("seed must bind its locked source producer")
    return configured, materialized


def validate_seed_reference(reference):
    if (isinstance(reference, dict) and reference.get("schema") == "seed-step-checkpoint-reference.v3"
            and set(reference) == {"schema", "checkpoint", "expenditures", "timerPolicy"}
            and reference["timerPolicy"] == {
                "mode": "progress", "scope": "fresh-stage", "expenditureRole": "history-only"}):
        return
    if (isinstance(reference, dict) and reference.get("schema") == "seed-step-checkpoint-reference.v2"
            and set(reference) == {"schema", "checkpoint", "ledger"}):
        return
    if (not isinstance(reference, dict) or set(reference) != {"schema", "checkpoint", "expenditures"}
            or reference["schema"] != "seed-step-checkpoint-reference.v1"):
        raise ValueError("typed seed checkpoint and complete expenditure reference required")


def seed_reference(root, reference, *, reservation=None, continuation=None, historical=False):
    validate_seed_reference(reference)
    result = bound(root, reference["checkpoint"], historical=historical)
    configured, materialized = seed_ancestry(result[2])
    if reference["schema"] == "seed-step-checkpoint-reference.v2":
        from gambit_smp.recipe_continuation import checkpoint_allowance
        if reservation is None or continuation is None:
            raise ValueError("ledger checkpoint consumption requires an existing continuation reservation")
        ledger = checkpoint_allowance(root, reference["ledger"], result[1]["budgetReservation"],
                                      result[0]["outerReceiptSha256"], reservation, continuation)
    else:
        history_only = reference["schema"] == "seed-step-checkpoint-reference.v3"
        if history_only and (reservation is not None or continuation is not None):
            raise ValueError("fresh-stage checkpoint cannot replace reserved continuation budget")
        ledger = expenditures(root, reference["checkpoint"], reference["expenditures"],
                              **({"historical_only": True} if history_only else {}))
    return result, configured, materialized, ledger


def validate_seed_arguments(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("source", "checkpoint", "buildProfile"))
    reference(args["source"])
    for name in ("checkpoint", "buildProfile"):
        if args[name] not in inputs or not args[name].endswith(".json"):
            raise ValueError("declared typed checkpoint/profile input required")


def import_seed(args, ctx):
    """Checked artifact consumption in a new reviewed campaign, never resume."""
    import shutil
    from gambit_smp.artifact_storage import transfer_tree
    from gambit_smp.build_profile import read_profile
    from gambit_smp.recipes import read_json, source_path, tree_identity
    in_place = ctx.receipt.get("workspacePolicy") == "in-place"
    source = (ctx.reuse_workspace(args["source"], "source-tree") if in_place
              else ctx.artifact(args["source"], "source-tree"))
    reference_path = source_path(ctx.root, args["checkpoint"])
    reference = read_json(reference_path)
    allowance = ({"reservation": ctx.receipt.get("budgetReservation"),
                  "continuation": ctx.receipt.get("continuation")}
                 if reference.get("schema") == "seed-step-checkpoint-reference.v2" else {})
    observed, configured, materialized, ledger = seed_reference(ctx.root, reference, **allowance)
    proof, outer, _, seed, engine = observed
    history_only = reference.get("schema") == "seed-step-checkpoint-reference.v3"
    if history_only:
        if (ctx.receipt.get("timeoutPolicy", {}).get("mode") != "progress"
                or ctx.receipt.get("budgetReservation") is not None
                or ctx.receipt.get("continuation") is not None
                or ledger.get("controlRole") != "history-only"):
            raise ValueError("fresh progress-stage timers required; reserved or wall budgets remain active")
    elif ctx.receipt["budgetSeconds"] > ledger["remainingSeconds"]:
        raise ValueError("checkpoint consumption cannot reset the cumulative budget")
    if digest(Path(ctx.tools["gcc"])) != engine["hostTools"]["gcc"]["sha256"]:
        raise ValueError("checkpoint GNU compiler differs from the consumer")
    if (configured["arguments"].get("buildProfile") != args["buildProfile"]
            or read_profile(source_path(ctx.root, args["buildProfile"])) != configured.get("buildProfile")):
        raise ValueError("checkpoint build profile differs from the consumer")
    command = next(row for row in configured["commands"] if row["stage"] == "configure")
    required = {"--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms"}
    if not required <= set(command["argv"]):
        raise ValueError("checkpoint lacks the three required concurrency flags")
    expected_source = (seed["outputs"]["runtime"]["identity"] if in_place
                       else materialized["outputs"]["source"]["identity"])
    producer = next(row for row in ctx.receipt["steps"] if row["id"] == args["source"]["step"])
    if (in_place and (producer["capability"] != "gambit.materialize" or
                      producer["arguments"]["sourceLock"] != materialized["arguments"]["sourceLock"])):
        raise ValueError("in-place checkpoint source lock differs from its producer")
    if tree_identity(source) != expected_source:
        raise ValueError("consumer locked source differs from checkpoint source")
    run = fixture_path(ctx.root, proof["run"])
    stage_inputs = ([relative(ctx.root, row["path"]) for row in proof["stageReferences"].values()]
                    + [run / "run-header.json"] if proof.get("schema") == "successful-stage-journal.v1"
                    else [run / "run/receipt.json"])
    ctx.bind([reference_path, run / "receipt.json", *stage_inputs,
              source_path(ctx.root, args["buildProfile"]),
              *[fixture_path(ctx.root, r["run"]) / "receipt.json"
                for r in reference.get("expenditures", [])],
              *([relative(ctx.root, reference["ledger"]["path"])] if "ledger" in reference else [])])
    from gambit_smp.recipes import artifact_path
    original = artifact_path(run / "run", seed["outputs"]["runtime"], root=ctx.root)
    target, identity = ctx.directory / "runtime", ctx.directory / "identity.json"
    if in_place:
        if original.resolve(strict=True) != source.resolve(strict=True):
            raise ValueError("in-place checkpoint cannot import another workspace")
        target = source
        storage = {"schema": "in-place-checkpoint-storage.v1", "copiedFiles": 0,
                   "claim": "same-leased-workspace-not-native-admission"}
    else:
        storage = transfer_tree(original, target)
    shutil.copy2(relative(run / "run", seed["outputs"]["identity"]["path"]), identity)
    if (tree_identity(target) != seed["outputs"]["runtime"]["identity"]
            or digest(identity) != seed["outputs"]["identity"]["sha256"]):
        raise ValueError("checkpoint artifact changed during transfer")
    repeated, _, _, repeated_ledger = seed_reference(ctx.root, reference, **allowance)
    if repeated[0] != proof or repeated_ledger != ledger:
        raise ValueError("checkpoint or expenditure changed during transfer")
    if tree_identity(source) != expected_source:
        raise ValueError("consumer source changed during checkpoint transfer")
    ctx.receipt.setdefault("checkpointExpenditures", []).append(ledger)
    return {"outputs": {**ctx.publish("runtime", "seed-runtime", target),
                        **ctx.publish("identity", "runtime-identity", identity)},
            "checkpoint": proof, "campaignOutcome": outer["outcome"],
            "storageTransfer": storage, "cumulativeExpenditure": ledger,
            "runtimeAdmitted": False, "resumptionAuthorized": False,
            "claim": "checked-seed-artifact-transfer-not-completed-runtime-or-interrupted-resumption"}
