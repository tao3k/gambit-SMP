"""Observe committed successful steps; failed campaigns remain failed.

This module neither executes a checkpoint nor reclassifies a seed as a full
runtime. Native adapters and Evidence rules must authorize any consumption.
"""
import hashlib
import json
import math
import time
from pathlib import Path
from gambit_smp.artifact_storage import observation_root, fixture_name, fixture_path

from gambit_smp.framework import digest, relative


SCHEMA = "successful-step-checkpoint.v1"


def _observe_bindings(root, inventories):
    """Observe bytes only; matching and dependency propagation belong to Scheme."""
    expected, observed = [], []
    for inventory in inventories:
        for name, sha in inventory.items():
            path = Path(name) if Path(name).is_absolute() else root / name
            key = str(path.resolve())
            expected.append((key, sha))
            try:
                if path.is_file():
                    observed.append((key, digest(path)))
            except OSError:
                pass
    return expected, observed


def support_inventory(root, header, row, tools, observation_inputs=None):
    """Seal the enumerator's declared scope separately from receipt custody."""
    declaration = header.get("declaration")
    if not isinstance(declaration, dict) or not header.get("engineId"):
        return None
    steps = [step for step in declaration.get("steps", []) if step.get("id") == row["id"]]
    if len(steps) != 1 or not declaration.get("scope"):
        return None
    declared = steps[0]
    if any(name not in header.get("inputs", {}) for name in declaration.get("inputs", [])):
        return None
    keys = ("id", "capability", "arguments", "dependsOn", "budgetSeconds")
    declared_inputs, _ = _observe_bindings(root, [header.get("inputs", {})])
    observed_inputs, _ = _observe_bindings(root, [observation_inputs or {}])
    recorder_inputs = {key: value for key, value in observed_inputs if key not in dict(declared_inputs)}
    expected, _ = _observe_bindings(root, [header.get("inputs", {}), recorder_inputs, tools, row.get("observedInputs", {})])
    return {"scope": declaration["scope"], "declaration": content_id(declaration),
            "receipt": content_id({key: value for key, value in row.items() if key != "journal"}),
            "checker": header["engineId"], "contract": content_id({key: declared.get(key) for key in keys}),
            "bindings": dict(expected), "recorderBindings": recorder_inputs,
            "toolBindings": dict(tools), "dependencies": declared.get("dependsOn", []),
            "commands": [[str(i), command.get("expectedExit", 0)] for i, command in enumerate(row.get("commands", []))]}


def _support_inventories(root, records):
    """Read immutable enumeration witnesses, never infer closure from a PASS."""
    if not records:
        return {}
    header = records[0]["payload"]
    inventories = {}
    for entry in records[1:]:
        record = entry["payload"]
        if record.get("schema") != "research-step-observation.v1":
            continue
        inventory = record.get("supportInventory")
        if inventory is not None and inventory == support_inventory(root, header, record["step"], record["toolInputs"], entry["inputs"]):
            inventories[record["step"]["id"]] = inventory
    return inventories


def _resumption_relations(rows, names, inspection, *, checked, campaign_pass, quiescent, support, inventories, declaration=None,
                          execution=None):
    """Transport verified observations to the registered Scheme policy."""
    from gambit_smp.ascent_program import load_component_catalog, query
    from gambit_smp.framework import ROOT
    facts = {key: [] for key in (
        "requirement", "dependency", "contract", "receipt", "verified",
        "support_declaration", "support_witness", "required_command",
        "binding", "required_binding", "current_binding", "command", "command_observation",
        "prerequisite", "quiescent", "material", "available", "withdrawn",
        "required_step", "recorded_failure", "receipt_checked", "campaign_pass",
        "output_retained", "execution_quiescent", "campaign_required", "campaign_enumerated",
        "execution_location", "execution_process", "execution_end", "execution_sample", "execution_custody")}
    for name, values in (execution or {}).items():
        facts[name].extend(values)
    facts["required_step"] = [(name,) for name in names]
    facts["requirement"] = [(name,) for name in names]
    if declaration is not None:
        declared_names = {step["id"] for step in declaration["steps"]}
        facts["requirement"] = [(name,) for name in sorted(set(names) | declared_names)]
        facts["campaign_required"] = [(name,) for name in sorted(declared_names)]
        facts["campaign_enumerated"] = [()]
    if checked:
        facts["receipt_checked"] = [()]
    if campaign_pass:
        facts["campaign_pass"] = [()]
    if quiescent:
        facts["execution_quiescent"] = [()]
    availability = {}
    for row in inspection.get("artifactAvailability", {}).get("outputs", []):
        availability[(row["step"], row["output"])] = row["status"]
    identities = {row["id"]: content_id(row) for row in rows}
    for row in rows:
        name = row["id"]
        identity = identities[name]
        contract = content_id({key: row.get(key) for key in ("id", "capability", "arguments", "dependsOn", "budgetSeconds")})
        facts["contract"].append((name, contract))
        facts["receipt"].append((identity, name, contract, row.get("outcome", "UNKNOWN")))
        facts["prerequisite"].extend((identity, parent, identities.get(parent, "missing:" + parent))
                                     for parent in row.get("dependsOn", []))
        expected, observed = support[name]
        inventory = inventories.get(name)
        if inventory is not None:
            declared_contract = inventory["contract"]
            scope, declaration, checker = inventory["scope"], content_id(inventory), inventory["checker"]
            facts["support_declaration"].append((name, declared_contract, scope, declaration, checker,
                len(inventory["bindings"]), len(inventory["commands"]), len(set(inventory["dependencies"]))))
            facts["required_binding"].extend((name, declared_contract, key) for key in inventory["bindings"])
            facts["required_command"].extend((name, declared_contract, *command) for command in inventory["commands"])
            facts["dependency"].extend((name, parent) for parent in inventory["dependencies"])
            if checked and dict(expected) == inventory["bindings"]:
                facts["support_witness"].append((identity, scope, declaration, checker))
        facts["binding"].extend((identity, key, sha) for key, sha in expected)
        facts["current_binding"].extend(observed)
        # An independent producer admission failure must remain visible even
        # when every observable file still matches (for example an invalid seal).
        if "evidenceBindingStatus" in inspection and inspection["evidenceBindingStatus"] != "CURRENT":
            facts["withdrawn"].append((identity, "producer-inspection"))
        if checked and inventory is not None and inventory["receipt"] == content_id(
                {key: value for key, value in row.items() if key != "journal"}):
            facts["verified"].append((identity,))
        for index, command in enumerate(row.get("commands", [])):
            key = str(index)
            facts["command"].append((identity, key, command.get("expectedExit", 0)))
            fields = ("exit", "timeout", "parentReaped", "processGroupQuiescent")
            if (type(command.get("exit")) is int and
                    all(type(command.get(field)) is bool for field in fields[1:])):
                facts["command_observation"].append((identity, key, *(command[field] for field in fields)))
        if quiescent:
            facts["quiescent"].append((identity,))
        if row.get("outcome") != "PASS":
            facts["recorded_failure"].append((name, row.get("outcome", "UNKNOWN")))
        states = []
        for output in row.get("outputs", {}):
            facts["material"].append((identity, output))
            state = availability.get((name, output), "UNKNOWN")
            states.append(state)
            if state == "AVAILABLE":
                facts["available"].append((identity, output))
        if states and all(state in {"AVAILABLE", "RETAINED"} for state in states):
            facts["output_retained"].append((name,))
    catalog = load_component_catalog(ROOT / "evidence/dsl/components.json",
                                     entry="checkpoint-state", constructor="make-checkpoint-state",
                                     trusted=True)
    queries = {key: key for key in ("historical_complete", "reusable", "satisfied",
        "artifact_unavailable", "historical_only", "unresolved", "invalidated", "failed", "campaign_reusable",
        "consumable", "binding_gap", "invalidated_by", "enumeration_gap",
        "support_declaration", "support_witness", "closed_support",
        "execution_pending", "execution_frontier", "execution_unattributed", "execution_detached",
        "failed_attempt_history")}
    answers = query(facts, catalog, queries)
    if any(digest(Path(path)) != sha for path, sha in catalog["sourceInputs"].items()):
        raise ValueError("checkpoint rules changed during resumption inspection")
    from gambit_smp.ascent_program import _api_inventory
    resources = {str(path): name for name, path in _api_inventory()[0].items() if name.startswith("package:")}
    return answers, {resources.get(path, str(Path(path).relative_to(ROOT)) if Path(path).is_relative_to(ROOT) else path): sha
                     for path, sha in catalog["sourceInputs"].items()}


def resumption(root, run, inspection, *, required=None):
    """Observe immutable receipts/availability; Scheme owns reuse and gap rules."""
    root, run = Path(root).resolve(), Path(run).resolve()
    outer_path, child_path = run / "receipt.json", run / "run/receipt.json"
    outer_bytes = outer_path.read_bytes()
    outer = json.loads(outer_bytes)
    child_bytes = child_path.read_bytes() if child_path.is_file() else None
    checked = (outer.get("schema") == "sealed-research-run.v1"
               and Path(outer.get("root", "")).resolve() == root
               and child_bytes is not None
               and hashlib.sha256(child_bytes).hexdigest() == outer.get("childReceiptSha256"))
    child = json.loads(child_bytes) if checked else {}
    checked = (checked and child.get("recipe") == outer.get("recipe")
               and child.get("inputsStable") is True
               and (outer.get("outcome") != "PASS" or child.get("outcome") == "PASS"))
    rows = child.get("steps", []) if checked else []
    names = list(required if required is not None else outer.get("stepBudgets", {}))
    quiescent = (checked and outer.get("parentReaped") is True
                 and outer.get("processGroupQuiescent") is True)
    support = {row["id"]: _observe_bindings(root, [outer.get("inputs", {}), row.get("observedInputs", {})])
               for row in rows}
    from gambit_smp.reasoning_history import read_execution_checkpoint
    records = read_execution_checkpoint(root, run)["records"]
    inventories = _support_inventories(root, records)
    # A completed child names all tool inputs independently of its input list.
    for row in rows:
        if row["id"] in inventories:
            support[row["id"]] = _observe_bindings(root, [outer.get("inputs", {}),
                inventories[row["id"]]["recorderBindings"], inventories[row["id"]]["toolBindings"], row.get("observedInputs", {})])
    answers, rules = _resumption_relations(rows, names, inspection, checked=checked,
                                          campaign_pass=outer.get("outcome") == "PASS", quiescent=quiescent,
                                          support=support, inventories=inventories,
                                          declaration=records[0]["payload"].get("declaration") if records else None)
    if (outer_path.read_bytes() != outer_bytes or
            (child_bytes is not None and child_path.read_bytes() != child_bytes)):
        raise ValueError("checkpoint changed during resumption inspection")
    return {"schema": "research-resumption-state.v1",
            "scope": "recipe-stages-not-cumulative-milestone-count",
            "recordedRecipe": outer["recipe"], "recordedEngineId": outer["engineId"],
            "recordedInputIdentity": content_id(outer.get("inputs", {})),
            "receiptSha256": hashlib.sha256(outer_bytes).hexdigest(),
            "historyStatus": "VERIFIED" if checked else "UNVERIFIED",
            "parentCompletionObserved": quiescent,
            "rules": rules,
            "requiredSteps": names, "relations": answers,
            "executionAuthorized": False, "runtimeAdmitted": False}


def interrupted_resumption(root, run):
    """Recover committed journal facts without inventing a terminal receipt."""
    from gambit_smp.reasoning_history import normalized, read_journal, read_execution_checkpoint
    from gambit_smp.recipes import inspect_outputs
    root, run = Path(root).resolve(), Path(run).resolve()
    path = run / "run-header.json"
    raw = path.read_bytes()
    header = json.loads(raw)
    if header.get("schema") != "research-run-header.v1" or not header.get("runId"):
        raise ValueError("bound run header required for interrupted state")
    records = {}
    for record_path in (run / "run").glob("*.observation.json"):
        if record_path.is_symlink():
            raise ValueError("journal record alias is not admissible")
        record = json.loads(record_path.read_bytes())
        step = record.get("step", {})
        if (record.get("schema") != "research-step-observation.v1"
                or record.get("runId") != header["runId"]
                or record_path.name != step.get("id", "") + ".observation.json"):
            raise ValueError("journal stage belongs to another producer")
        records[step["id"]] = (record_path, record)
    reference = next((record["header"] for _, record in records.values()), None)
    scope = reference["scope"] if reference else "research:" + header["recipe"]
    observations = read_journal(root, scope)["observations"]
    headers = [identity for identity, body in observations.items()
               if body.get("queries") == normalized({"run_record": [header]})]
    if len(headers) != 1:
        raise ValueError("run header lacks its immutable observation")
    expected = {"path": str(path), "sha256": hashlib.sha256(raw).hexdigest(),
                "observation": headers[0], "scope": scope}
    references, rows, support = {}, [], {}
    for name, (record_path, record) in records.items():
        identities = [identity for identity, body in observations.items()
                      if body.get("queries") == normalized({"run_record": [record]})]
        if record.get("header") != expected or len(identities) != 1:
            raise ValueError("journal stage lacks its immutable observation")
        references[name] = {"path": str(record_path), "sha256": digest(record_path),
                            "observation": identities[0], "scope": scope}
        rows.append(record["step"])
        body = observations[identities[0]]
        tools = record.get("toolInputs")
        if not isinstance(tools, dict) or not tools or any(not Path(source).is_absolute() for source in tools):
            raise ValueError("journal stage lacks immutable tool bindings")
        bound_sources = {str((Path(source) if Path(source).is_absolute() else root / source).resolve()): sha
                         for source, sha in body.get("inputs", {}).items()}
        if any(bound_sources.get(str((root / source).resolve())) != sha
               for source, sha in header["inputs"].items()):
            raise ValueError("journal stage omits original producer inputs")
        support[name] = _observe_bindings(root, [body.get("inputs", {}), record.get("toolInputs", {}),
                                               record["step"].get("observedInputs", {})])
    for _, record in records.values():
        dependencies = record.get("dependencies")
        parents = record["step"]["dependsOn"]
        if any(name not in references for name in parents) or dependencies != {name: references[name] for name in parents}:
            raise ValueError("journal prerequisite identity changed")
    try:
        availability = inspect_outputs(run / "run", rows, root=root)
    except (OSError, ValueError, KeyError):
        availability = {"status": "UNKNOWN", "outputs": []}
    names = list(header.get("stepBudgets", {})) or list(records)
    inspection = {"artifactAvailability": availability}
    answers, rules = _resumption_relations(rows, names, inspection, checked=True,
                                          campaign_pass=False, quiescent=False, support=support,
                                          inventories=_support_inventories(root, read_execution_checkpoint(root, run)["records"]),
                                          declaration=header.get("declaration"))
    inspection["evidenceBindingStatus"] = "STALE" if answers["binding_gap"] else "CURRENT"
    if path.read_bytes() != raw or any(digest(Path(ref["path"])) != ref["sha256"]
                                       for ref in references.values()):
        raise ValueError("journal changed during resumption inspection")
    state = {"schema": "research-resumption-state.v1", "scope": "recipe-stages-not-cumulative-milestone-count",
             "run": run.relative_to(root).as_posix(),
             "recordedRecipe": header["recipe"], "recordedEngineId": header["engineId"],
             "recordedInputIdentity": content_id(header["inputs"]),
             "headerSha256": expected["sha256"], "historyStatus": "COMMITTED_PREFIX",
             "requiredSteps": names, "relations": answers, "rules": rules,
             "stageReferences": {name: {**ref, "path": Path(ref["path"]).relative_to(root).as_posix()}
                                 for name, ref in references.items()},
             "parentCompletionObserved": False, "executionAuthorized": False, "runtimeAdmitted": False}
    return {"recipe": header["recipe"], "engineId": header["engineId"], "outcome": "INCOMPLETE",
            "recordedOutcome": None, "identityStatus": "INCOMPLETE", **inspection,
            "resumption": state, "runtimeAdmitted": False, "sourceRefinementAdmitted": False}


def execution_observations(run, records, names):
    """Observe committed process records and the kernel; Scheme projects state."""
    from gambit_smp.research_kernel import clock_epoch
    from gambit_smp.process_identity import process, same_birth
    from gambit_smp.process_observation import probe_group
    import time
    facts = {name: [] for name in ('execution_location', 'execution_process', 'execution_end', 'execution_sample',
                                   'execution_custody')}
    observations, by_token = [], {}
    epoch = clock_epoch()
    for entry in records:
        value = entry['payload']
        if value.get('schema') != 'research-process-observation.v1':
            continue
        by_token.setdefault(value['token'], []).append((value, entry))
    for token, entries in by_token.items():
        events = {value['event']: value for value, _ in entries}
        planned, started = events.get('planned', {}), events.get('started', {})
        cwd = Path(planned.get('cwd', ''))
        if cwd.is_absolute() and cwd.is_relative_to(run / 'run'):
            parts = cwd.relative_to(run / 'run').parts
            if parts and parts[0] in names:
                facts['execution_location'].append((token, parts[0]))
        if 'finished' in events or 'spawn-failed' in events:
            facts['execution_end'].append((token,))
        pid = started.get('pid')
        if type(pid) is int and pid > 1:
            state = 'unknown'
            if epoch is not None and started.get('clockEpoch') == epoch:
                try:
                    quiet, _ = probe_group(pid, time.monotonic() + .05)
                    state = 'absent' if quiet is True else 'present-unattributed' if quiet is False else 'unknown'
                    birth = started.get('birth', {}).get('process')
                    if not quiet and birth and same_birth(birth, process(pid)):
                        state = 'present'
                except OSError:
                    state = 'unknown'
            facts['execution_process'].append((token, pid, state))
        for value, entry in entries:
            if value['event'] != 'progress':
                continue
            count, at = value.get('count'), value.get('observedMonotonic')
            if type(count) is not int or count <= 0 or type(at) not in (int, float) or not math.isfinite(at):
                raise ValueError('invalid committed completed-work observation')
            reference = entry['observation']
            # Clue catalog scalars use integral time units, not floating tags.
            facts['execution_sample'].append((token, count, round(at * 1_000_000_000), reference))
            observations.append(dict(reference=reference, token=token, count=count, monotonic=at,
                clockEpoch=value.get('clockEpoch'), clockContinuous=epoch is not None and value.get('clockEpoch') == epoch,
                witness=value.get('witness'), path=entry['path']))
    return facts, observations


def execution_owner(root, run):
    """Read the existing task-run custody record; return status is not AI success."""
    from gambit_smp.workspace import bounded
    try:
        parts = run.relative_to(root / '.cache/tasks').parts
    except ValueError:
        return None
    if len(parts) < 3:
        return None
    task = parts[0]
    if parts[1] == 'runs':
        owner = bounded(root, f'.state/task-runs/{task}/{parts[2]}.json')
        output = root / '.cache/tasks' / task / 'runs' / parts[2]
    elif len(parts) >= 5 and parts[1] == 'processes' and parts[3] == 'runs':
        owner = bounded(root, f'.state/work-process-runs/{task}/{parts[2]}/{parts[4]}.json')
        output = root / '.cache/tasks' / task / 'processes' / parts[2] / 'runs' / parts[4]
    else:
        return None
    if not owner.is_file():
        return None
    raw = owner.read_bytes()
    value = json.loads(raw)
    if value.get('task') != task or Path(value.get('output', '')) != output:
        return dict(provider='unknown', recordedTaskState='unknown', bindingStatus='MISMATCH',
                    reference=hashlib.sha256(raw).hexdigest(), path=str(owner), sessionCompletionObserved=False)
    return dict(provider=value['provider'], recordedTaskState=value['state'],
                reference=hashlib.sha256(raw).hexdigest(), path=str(owner), bindingStatus='CURRENT',
                sessionCompletionObserved=False)


def recovered_resumption(root, run, *, require_current_prefix=True):
    """Recover attested record bytes, never reconstruct a missing aggregate PASS."""
    from gambit_smp.reasoning_history import read_execution_checkpoint, execution_checkpoint_head
    from gambit_smp.recipes import inspect_outputs
    root, run = Path(root).resolve(), Path(run).resolve()
    prefix = read_execution_checkpoint(root, run)
    records = prefix["records"]
    if not records or records[0]["payload"].get("schema") != "research-run-header.v1":
        raise ValueError("committed execution header required")
    header = records[0]["payload"]
    rows, references, terminal, processes, support = [], {}, None, {}, {}
    header_ref = {"path": records[0]["path"], "sha256": hashlib.sha256(
        (json.dumps(header, sort_keys=True, indent=2, allow_nan=False) + "\n").encode()).hexdigest(),
        "observation": records[0]["observation"], "scope": records[0]["scope"]}
    for entry in records[1:]:
        payload = entry["payload"]
        if payload.get("schema") == "research-process-observation.v1":
            if payload.get("header") != header_ref or payload.get("runId") != header["runId"]:
                raise ValueError("process observation belongs to another execution")
            processes.setdefault(payload["token"], {})[payload["event"]] = payload
            continue
        if payload.get("schema") == "gerbil-bootstrap-module-observation.v1":
            if (payload.get("header") != header_ref or payload.get("runId") != header["runId"]
                    or payload.get("runtimeAdmitted") is not False
                    or not isinstance(payload.get("moduleProof"),dict)):
                raise ValueError("bootstrap module observation belongs to another execution")
            # Child completion witnesses are retained evidence, not recipe
            # stages. The Gerbil consumer independently validates their exact
            # process/input/output bindings before any module can be reused.
            # In particular, these records cannot manufacture stage0 PASS.
            continue
        if payload.get("schema") == "research-terminal-observation.v1":
            if entry != records[-1] or terminal is not None:
                raise ValueError("terminal checkpoint is not the committed tail")
            terminal = payload["outer"]
            continue
        if payload.get("schema") != "research-step-observation.v1" or payload.get("header") != header_ref:
            raise ValueError("committed stage belongs to another header")
        row = payload["step"]
        if row["id"] in references or payload.get("dependencies") != {
                name: references.get(name) for name in row["dependsOn"]}:
            raise ValueError("committed prerequisite identity mismatch")
        tools = payload.get("toolInputs", {})
        if not tools or any(not Path(path).is_absolute() for path in tools):
            raise ValueError("committed stage lacks tool bindings")
        recorded_inputs = {str((Path(path) if Path(path).is_absolute() else root / path).resolve()): sha
                           for path, sha in entry["inputs"].items()}
        if any(recorded_inputs.get(str((root / path).resolve())) != sha for path, sha in header["inputs"].items()):
            raise ValueError("committed stage omits producer inputs")
        support[row["id"]] = _observe_bindings(root, [entry["inputs"], tools, row.get("observedInputs", {})])
        rows.append(row)
        references[row["id"]] = {"path": entry["path"], "sha256": hashlib.sha256(
            (json.dumps(payload, sort_keys=True, indent=2, allow_nan=False) + "\n").encode()).hexdigest(),
            "observation": entry["observation"], "scope": entry["scope"]}
    availability = inspect_outputs(run / "run", rows, root=root)
    inspection = {"artifactAvailability": availability}
    parent_complete = (terminal is not None and terminal.get("parentReaped") is True
                       and terminal.get("processGroupQuiescent") is True)
    quiescence = {"observed": parent_complete, "basis": "recorded-terminal" if parent_complete else "unknown"}
    if not parent_complete and processes:
        from gambit_smp.research_kernel import clock_epoch
        from gambit_smp.process_observation import probe_group
        epoch = clock_epoch()
        absent = True
        for events in processes.values():
            planned = events.get("planned")
            if planned is None or not planned.get("clockEpoch") or epoch is None:
                absent = False
                break
            if planned["clockEpoch"] != epoch or "spawn-failed" in events:
                continue
            started = events.get("started")
            if started is None or type(started.get("pid")) is not int or started["pid"] <= 1:
                absent = False
                break
            observed, _ = probe_group(started["pid"], time.monotonic() + .05)
            if observed is not True:
                absent = False
                break
        quiescence = {"observed": absent, "basis": "recorded-births-reobserved"}
    names = list(header.get("stepBudgets", {})) or [row["id"] for row in rows]
    execution, progress_observations = execution_observations(run, records, names)
    owner = execution_owner(root, run)
    if owner is not None and owner.get('bindingStatus', 'CURRENT') == 'CURRENT':
        execution['execution_custody'] = [(owner['provider'], owner['recordedTaskState'], owner['reference'])]
    relations, rules = _resumption_relations(rows, names, inspection, checked=True,
        campaign_pass=terminal is not None and terminal.get("outcome") == "PASS", quiescent=quiescence["observed"],
        support=support, inventories=_support_inventories(root, records), declaration=header.get("declaration"),
        execution=execution)
    current = not relations["binding_gap"]
    inspection["evidenceBindingStatus"] = "CURRENT" if current else "STALE"
    observed_head = execution_checkpoint_head(root, run)
    prefix_is_head = observed_head == prefix["prefixIdentity"]
    if require_current_prefix and not prefix_is_head:
        raise ValueError("checkpoint prefix changed during recovery")
    state = {"schema": "research-resumption-state.v1", "scope": "recipe-stages-not-cumulative-milestone-count",
             "recordedRecipe": header["recipe"], "recordedEngineId": header["engineId"],
             "recordedInputIdentity": content_id(header["inputs"]), "historyStatus": "COMMITTED_PREFIX",
             "recordedInputs": dict(header["inputs"]),
             "prefixIdentity": prefix["prefixIdentity"], "requiredSteps": names, "relations": relations,
             "run": run.relative_to(root).as_posix(),
             "observedHeadIdentity": observed_head, "prefixStillHead": prefix_is_head,
             "rules": rules, "parentCompletionObserved": parent_complete, "executionQuiescence": quiescence,
             "executionAuthorized": False, "runtimeAdmitted": False,
             "executionObservation": {"processes": execution['execution_process'],
                 "owner": owner,
                 "progress": [row for row in progress_observations if row['reference'] in
                              {entry[4] for entry in relations['execution_frontier']}],
                 "completionCountsArePasses": False, "deadlockEstablished": False,
                 "observedMonotonic": time.monotonic()}}
    return {"recipe": header["recipe"], "engineId": header["engineId"],
            "outcome": terminal["outcome"] if terminal else "INCOMPLETE",
            "recordedOutcome": terminal["outcome"] if terminal else None,
            "identityStatus": "CURRENT" if current and availability["status"] in {"AVAILABLE", "RETAINED"} else "STALE",
            **inspection, "resumption": state, "runtimeAdmitted": False, "sourceRefinementAdmitted": False}


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
        expected_queries = normalized({"run_record": [record]})
        candidates = [identity for identity, body in observations.items()
                      if body.get("scope") == reference["scope"] and
                      body.get("queries") == expected_queries]
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


def observe_stage_record(root, path, engine):
    """Consume a committed phase, not an absent or failed aggregate receipt."""
    from gambit_smp.reasoning_history import read_execution_checkpoint, read_journal, execution_checkpoint_head
    from gambit_smp.recipes import read_json
    root, path = Path(root).resolve(strict=True), Path(path)
    if path.is_symlink() or path.parent.name != "run" or not path.name.endswith(".observation.json"):
        raise ValueError("bounded stage observation path required")
    run = path.parent.parent.resolve(strict=True)
    observation_root(root, run)
    prefix = read_execution_checkpoint(root, run)
    records = prefix["records"]
    if not records or records[0]["payload"].get("schema") != "research-run-header.v1":
        raise ValueError("committed producer header required")
    header = records[0]["payload"]
    selected = [entry for entry in records if entry["path"] == str(path)]
    if len(selected) != 1 or selected[0]["payload"] != read_json(path):
        raise ValueError("stage differs from its committed observation")
    record = selected[0]["payload"]
    if record.get("schema") != "research-step-observation.v1" or header["engineId"] != engine["engineId"]:
        raise ValueError("stage producer generation differs from pinned seal")
    reference = record["header"]
    header_path = run / "run-header.json"
    if (reference["path"] != str(header_path) or header_path.is_symlink()
            or digest(header_path) != reference["sha256"] or read_json(header_path) != header):
        raise ValueError("stage header identity changed")
    history = read_journal(root, reference["scope"])["observations"]
    context = {"journal": reference, "inputs": header["inputs"]}
    target = record["step"]["id"]
    closure, references = journal_closure(root, run, context, header, history, target)
    if not set(row["id"] for row in closure) <= set(_support_inventories(root, records)):
        raise ValueError("stage support enumeration witness incomplete")
    state = recovered_resumption(root, run)["resumption"]
    if (state["prefixIdentity"] != prefix["prefixIdentity"]
            or not any(row[0] == target for row in state["relations"]["consumable"])):
        raise ValueError("Scheme checkpoint does not admit this phase for consumption")
    if execution_checkpoint_head(root, run) != prefix["prefixIdentity"]:
        raise ValueError("stage producer changed during consumption")
    terminal = [entry['payload']['outer'] for entry in records
                if entry['payload'].get('schema') == 'research-terminal-observation.v1']
    proof = {"schema": "committed-stage-checkpoint.v1", "run": fixture_name(root, run),
             "step": target, "engineId": engine["engineId"], "prefixIdentity": prefix["prefixIdentity"],
             "stageReferences": {name: {**ref, "path": Path(ref["path"]).relative_to(root).as_posix()}
                                 for name, ref in references.items()},
             "parentCompletionObserved": state["parentCompletionObserved"],
             "campaignOutcome": terminal[-1]['outcome'] if terminal else "INCOMPLETE",
             "runtimeAdmitted": False, "resumptionAuthorized": False,
             "missingChildReceiptReconstructed": False}
    return proof, header, closure, run


def observe_journal(root, run, target, *, historical=False):
    """Bind a successful stage of a terminal failed run; admission stays false."""
    from gambit_smp.reasoning_history import normalized, read_journal
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.recipes import read_json, inspect_outputs
    root, run = root.resolve(strict=True), run.resolve(strict=True)
    observation_root(root, run)
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


def stage_commands(root, row, seen=None):
    """Read authenticated command origins without claiming a reused launch ran."""
    if 'reused' not in row:
        if not isinstance(row.get('commands'), list):
            raise ValueError('observed stage command inventory required')
        return row['commands']
    if row.get('executionLaunched') is not False or row.get('commands'):
        raise ValueError('reused commands are ancestry, not a new native launch')
    origin = row['reused']
    from gambit_smp.recipes import fields, read_json
    from gambit_smp.research_kernel import content_id
    fields(origin, ('run', 'step', 'receipt'))
    key = (origin['run'], origin['step'], origin['receipt'])
    seen = set() if seen is None else set(seen)
    if key in seen or len(seen) >= 64:
        raise ValueError('cyclic or unbounded command ancestry')
    seen.add(key)
    run = fixture_path(root, origin['run'])
    _, outer, closure, _ = observe_journal(root, run, origin['step'], historical=True)
    child_path = run / 'run/receipt.json'
    if digest(child_path) != outer.get('childReceiptSha256'):
        raise ValueError('command-origin child receipt changed')
    originals = [r for r in read_json(child_path)['steps'] if r['id'] == origin['step']]
    # Prefix reuse names the immutable journal step, before its mutable
    # receipt envelope received the separate journal-reference field.
    if len(originals) != 1 or content_id(closure[-1]) != origin['receipt']:
        raise ValueError('command-origin stage receipt changed')
    original = originals[0]
    if ({k: v for k, v in original.items() if k != 'journal'} != closure[-1]
            or any(original.get(k) != row.get(k) for k in ('id', 'capability', 'arguments', 'dependsOn'))):
        raise ValueError('command-origin journal or declaration differs')
    commands = stage_commands(root, original, seen)
    if row.get('originCommands') != commands:
        raise ValueError('reused command inventory differs from authenticated origin')
    return commands


def observe(root, run, target):
    """Bind the original generator, all inputs/artifacts and successful closure."""
    from gambit_smp.research_kernel import inspect, manifest_paths
    root, run = root.resolve(strict=True), run.resolve(strict=True)
    observation_root(root, run)
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
    command = next(row for row in stage_commands(ctx.root, configured) if row["stage"] == "configure")
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
