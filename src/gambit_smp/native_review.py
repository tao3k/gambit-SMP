"""Typed retry transport. Native ASCENT owns eligibility and missing premises."""
import math
import re
import shlex
from pathlib import Path

from gambit_smp.framework import digest, relative


POLICY = "evidence/research/suite-review-rules.ss"
SCHEMA = "typed-native-retry-review.v1"


def configured_dynamic_options(runtime, compiler):
    from gambit_smp.framework import gnu_build_driver
    driver = runtime / "bin/gambuild-C"
    before = digest(driver)
    configured = gnu_build_driver(runtime, compiler)
    text = driver.read_text()
    values = [line.split("=", 1)[1] for line in text.splitlines() if line.startswith("FLAGS_OPT=")]
    if len(values) != 1:
        raise ValueError("one literal current dynamic optimization binding required")
    words = shlex.split(values[0])
    if len(words) != 1 or re.fullmatch(r"\s*-O[0-3]\s*", words[0]) is None:
        raise ValueError("explicit literal dynamic optimization level required")
    dynamic = [line for line in text.splitlines() if line.startswith("BUILD_DYN=")]
    if len(dynamic) != 1 or "${FLAGS_OPT}" not in dynamic[0]:
        raise ValueError("dynamic compiler command must use the bound optimization level")
    if before != configured["sha256"] or digest(driver) != before:
        raise ValueError("current compiler changed during correspondence")
    return before, int(words[0].strip()[2:])


def compiler_options_change(root, manifest, previous, runtime, tested_unit, compiler):
    """Bind a historical command to current bytes; policy owns retry eligibility."""
    from gambit_smp.native_archive import validate
    from gambit_smp.recipes import read_json
    inputs = validate(root, manifest)
    archive = root / manifest
    metadata = read_json(archive)
    if metadata["schema"] != "gambit-compiler-probe-archive.v1":
        raise ValueError("typed historical compiler invocation archive required")
    saved = read_json(archive.parent / "receipt.json")
    if saved != previous:
        raise ValueError("compiler invocation must bind the exact failed probe")
    selection = saved["selection"]
    source = relative(tested_unit, selection)
    source_sha = digest(source)
    if source_sha != saved["sourceFiles"].get("unit-tests/" + selection):
        raise ValueError("compiler options cannot explain a changed Scheme fixture")
    before, level = configured_dynamic_options(runtime, compiler)
    command = read_json(archive.parent / "compiler-invocation.json")
    if digest(runtime / "bin/gambuild-C") != before or digest(source) != source_sha:
        raise ValueError("current compiler or fixture changed during correspondence")
    return {"originalOptimizationLevel": command["optimizationLevel"],
            "currentOptimizationLevel": level,
            "currentDriverSha256": before, "fixtureSha256": source_sha,
            "historicalArchiveSha256": digest(archive),
            "rawLogBoundByOriginalReceipt": False}, inputs


def compiler_configuration_change(root, manifest, observation, previous, runtime, compiler):
    """Project image-bound build metadata without promoting it to an invocation."""
    from gambit_smp.native_archive import configure_projection, validate
    from gambit_smp.recipes import read_json, source_path
    inputs = validate(root, manifest)
    archive = source_path(root, manifest)
    metadata = read_json(archive)
    if metadata["schema"] != "gambit-failed-suite-archive.v1" or read_json(archive.parent / "receipt.json") != previous:
        raise ValueError("exact original failed compiled suite archive required")
    path = source_path(root, observation)
    before = digest(path)
    record = read_json(path)
    identity = read_json(archive.parent / "identity.json")
    if (record.get("schema") != "gambit-compiler-configuration-observation.v1"
            or record.get("archiveOnly") is not True
            or any(record.get(key) is not False for key in ("runtimeAdmitted", "releaseAdmitted", "nativeGcPassed"))
            or record.get("historicalDriverSha256") is not None
            or record.get("historicalCommandObserved") is not False
            or record.get("receiptSha256") != metadata["files"]["receipt.json"]
            or record.get("candidateReceiptSha256") != metadata["files"]["identity.json"]
            or not isinstance(record.get("gscSha256"), str)
            or re.fullmatch(r"[0-9a-f]{64}", record["gscSha256"]) is None
            or record.get("gscSha256") != previous.get("gscSha256")
            or record.get("gscSha256") != identity.get("gscSha256")):
        raise ValueError("original image/configuration identity and non-invocation boundary required")
    config = record.get("configuration")
    if (not isinstance(config, dict) or not isinstance(config.get("argv"), list)
            or any(not isinstance(word, str) for word in config["argv"])
            or type(config.get("offset")) is not int or config["offset"] < 0
            or type(config.get("rawBytes")) is not int or config["rawBytes"] <= 0
            or not isinstance(config.get("rawConfigureSha256"), str)
            or re.fullmatch(r"[0-9a-f]{64}", config["rawConfigureSha256"]) is None):
        raise ValueError("typed original embedded configuration projection required")
    projected = configure_projection(shlex.join(config["argv"]))
    if (any(config.get(key) != value for key, value in projected.items())
            or not previous.get("compiler", "").startswith(config["compilerBasename"] + " ")):
        raise ValueError("historical configure projection differs from compiler metadata")
    current_image = digest(runtime / "gsc/gsc")
    if current_image == record["gscSha256"]:
        raise ValueError("unchanged historical compiler image cannot explain a new investigation")
    driver_sha, level = configured_dynamic_options(runtime, compiler)
    if before != digest(path) or current_image != digest(runtime / "gsc/gsc"):
        raise ValueError("configuration or compiler image changed during correspondence")
    inputs[observation] = before
    return {"originalOptimizationLevel": config["optimizationLevel"],
            "currentOptimizationLevel": level, "currentDriverSha256": driver_sha,
            "currentGscSha256": current_image, "historicalCommandObserved": False,
            "historicalDriverSha256": None}, inputs


def failure_modes(receipt):
    """Project recorded mode scope; an empty set means unknown, not cleared."""
    results = receipt.get("results", [])
    if any(isinstance(row, dict) and row.get("accepted") is False
           and row.get("mode") not in {"gsi", "gsc"} for row in results):
        return set()
    modes = {row["mode"] for row in results if isinstance(row, dict)
             and row.get("accepted") is False and row.get("mode") in {"gsi", "gsc"}}
    if modes:
        return modes
    if (receipt.get("schema") == "gambit-native-suite-denial-summary.v1"
            and receipt.get("status") == "DENY"
            and receipt.get("mode") in {"gsi", "gsc"}):
        return {receipt["mode"]}
    if (receipt.get("schema") == "gambit-compiler-cost.v1"
            and receipt.get("diagnosticOnly") is True
            and any(row.get("accepted") is False and row.get("name") in
                    {"scheme-to-c", "c-to-dynamic-module", "compiled-assertions"}
                    for row in receipt.get("stages", []) if isinstance(row, dict))):
        return {"gsc"}
    return set()


def compiler_probe_failure(receipt, path, selection, mode):
    """Project an actual stopped phase, never a synthetic suite result."""
    phases = ("scheme-to-c", "c-to-dynamic-module", "compiled-assertions")
    rows = receipt.get("stages")
    if (receipt.get("schema") != "gambit-compiler-cost.v1"
            or receipt.get("diagnosticOnly") is not True or receipt.get("status") != "DENY"
            or receipt.get("sourceStable") is not True or mode != "gsc"
            or not isinstance(selection, str) or not selection
            or Path(selection).is_absolute() or ".." in Path(selection).parts
            or receipt.get("selection") != selection
            or not isinstance(rows, list) or not 1 <= len(rows) <= len(phases)
            or path != f"/stages/{len(rows) - 1}/accepted"):
        return None
    for index, row in enumerate(rows):
        if (not isinstance(row, dict) or row.get("name") != phases[index]
                or type(row.get("exit")) is not int or type(row.get("timeout")) is not bool
                or type(row.get("accepted")) is not bool):
            return None
        if index < len(rows) - 1 and (not row["accepted"] or row["exit"] != 0 or row["timeout"]):
            return None
    return rows[-1]["name"] if rows[-1]["accepted"] is False else None


def build_driver_change(previous, change, runtime):
    """Bind a configured driver change to its recorded original bytes."""
    driver = previous.get("buildDriver")
    if (not isinstance(driver, dict) or driver.get("configuredCompilerVerified") is not True
            or driver.get("relativePath") != "bin/gambuild-C"
            or change.get("path") != driver["relativePath"]
            or change.get("before") != driver.get("sha256")):
        raise ValueError("build driver requires an originally recorded configured driver")
    path = relative(runtime, driver["relativePath"])
    if (not isinstance(driver.get("sha256"), str)
            or not re.fullmatch(r"[0-9a-f]{64}", driver["sha256"])
            or digest(path) != change.get("after")):
        raise ValueError("build driver must bind actual baseline and current bytes")
    return driver["sha256"], path


def selected_scope(name, selected, fixtures):
    path = Path(name)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("repository-relative failure scope required")
    return (name == "tests/run-unit-tests.scm" and bool(fixtures) or name in selected or
            not path.suffix and any(path in Path(file).parents for file in selected))


def make_operation_scope(args):
    if "operations" not in args:
        return {"Makefile:" + args["operation"]} if args.get("operation") is not None else set()
    operations = args["operations"]
    if (not isinstance(operations, list) or not operations or len(operations) != len(set(operations))
            or any(not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9-]{0,63}", name)
                   for name in operations)
            or not isinstance(args.get("requestedOperations"), list)
            or not set(args["requestedOperations"]) <= set(operations)):
        raise ValueError("exact inferred and requested operation inventories required")
    makefile_scope = args.get("makefileScope")
    if args.get("regime") != "upstream-make" or makefile_scope != "tests/makefile":
        raise ValueError("source-bound official Makefile operation scope required")
    return {makefile_scope + ":" + name for name in operations}


def failure_campaign_files(receipt):
    """Project closed recorded inventories; unknown or malformed scope stays open."""
    if (receipt.get("schema") not in {"gambit-upstream-suite.v1", "gambit-upstream-atomic-coverage.v1"}
            or receipt.get("status") != "DENY"):
        return None
    files, sources = receipt.get("selectedFiles"), receipt.get("sourceFiles")
    extras = receipt.get("extraFixtures", {})
    def recorded_sha(name):
        extra = extras.get(name, {}) if isinstance(extras, dict) else {}
        return sources.get("unit-tests/" + name) or (extra.get("testedSha256") if isinstance(extra, dict) else None)
    if (not isinstance(files, list) or not files or not isinstance(sources, dict)
            or type(receipt.get("filesPerMode")) is not int or receipt["filesPerMode"] != len(files)
            or any(not isinstance(name, str) or not name or Path(name).is_absolute()
                   or ".." in Path(name).parts or Path(name).suffix != ".scm" for name in files)
            or len(set(files)) != len(files)
            or any(not isinstance(recorded_sha(name), str)
                   or re.fullmatch(r"[0-9a-f]{64}", recorded_sha(name)) is None for name in files)):
        return None
    return files


def pointer(value, path):
    """Resolve an RFC 6901 reference, without interpreting an expression."""
    if not isinstance(path, str) or not path.startswith("/"):
        raise ValueError("nonempty JSON pointer required")
    for token in path[1:].split("/"):
        if re.search(r"~(?![01])", token):
            raise ValueError("invalid JSON pointer escape")
        token = token.replace("~1", "/").replace("~0", "~")
        value = value[int(token)] if isinstance(value, list) and token.isdecimal() else value[token]
    return value


def milliseconds(seconds):
    if type(seconds) not in (int, float) or not math.isfinite(seconds) or seconds <= 0:
        raise ValueError("recorded positive finite seconds required")
    value = seconds * 1000
    if value != int(value):
        raise ValueError("budget must have exact millisecond precision")
    return int(value)


def campaign_tree_identity(runtime, tested_unit):
    """Bind actual native bytes plus the complete prospective unit-test overlay."""
    from gambit_smp.recipes import tree_identity
    inventory = tree_identity(runtime)
    if tested_unit.resolve() != (runtime / "tests/unit-tests").resolve():
        prefix = "tests/unit-tests"
        inventory = {name: row for name, row in inventory.items()
                     if name != prefix and not name.startswith(prefix + "/")}
        inventory[prefix] = {"directory": True}
        inventory.update({prefix + "/" + name: row
                          for name, row in tree_identity(tested_unit).items()})
    return inventory


def campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, *, suite_budget=None):
    from gambit_smp.recipes import tree_identity
    from gambit_smp.research_kernel import content_id
    from gambit_smp.framework import available_processors
    from gambit_smp.suite_primitives import capacity
    step = next(row for row in ctx.receipt["steps"] if row["id"] == ctx.directory.name)
    cpu = available_processors()
    population, jobs = ((None, cpu) if args.get("operation") else
                        capacity(cpu, len(files), args["regime"] != "whole-sequential",
                                 args.get("processors"), args.get("jobs")))
    result = {"candidateReceiptSha256": digest(candidate_receipt), "mode": args["mode"],
            "runtimeTreeId": content_id(campaign_tree_identity(runtime, tested_unit)),
            "failureInventorySha256": digest(ctx.root / "evidence/native-failures.json"),
            "reviewRulesSha256": digest(ctx.root / args["reviewRules"]),
            "regime": args["regime"],
            "watchdogMode": "no-progress" if ctx.receipt.get("timeoutPolicy", {}).get("mode") == "progress" else "wall-clock",
            "selectedFiles": {str(file): digest(tested_unit / file) for file in files},
            "operation": args.get("operation"),
            "suiteBudgetSeconds": step["budgetSeconds"] if suite_budget is None else suite_budget,
            "recipeBudgetSeconds": ctx.receipt["budgetSeconds"],
            "batchBudgetSeconds": args.get("batchBudgetSeconds"),
            "fileBudgetSeconds": args.get("fileBudgetSeconds", {}),
            "groupBudgetSeconds": args.get("groupBudgetSeconds", {}),
            "processors": args.get("processors"), "jobs": args.get("jobs"),
            "hostCpuCapacity": cpu, "effectiveProcessors": population, "effectiveJobs": jobs}
    if 'numericGrouping' in args:
        from gambit_smp.compiler_phase_primitives import bind_numeric_grouping
        # The original Scheme bytes alone do not identify a transformed
        # compiler input. Review and execution bind the same real producer.
        bind_numeric_grouping(ctx, tested_unit.parent, args['numericGrouping'])
        result['numericGrouping'] = dict(args['numericGrouping'])
    if 'targetProcessors' in args:
        result['targetProcessors'] = args['targetProcessors']
    if 'reviewRulesExtension' in args:
        result['reviewRulesExtensionSha256'] = digest(ctx.root / args['reviewRulesExtension'])
    if "environmentProbe" in args:
        observation = ctx.artifact(args["environmentProbe"], "current-producer-observation")
        result.update(environmentProbe=args["environmentProbe"], environmentObservationSha256=digest(observation))
        if args['regime'] == 'upstream-make':
            from gambit_smp.recipes import read_json
            result['makeProcessors'] = read_json(observation)['processors']
    if "operations" in args:
        result.update(operations=args["operations"], requestedOperations=args["requestedOperations"],
                      unitModes=args["unitModes"], makefileScope=args["makefileScope"])
    return result


def resource_plan_change(previous, current):
    """Transport recorded populations; native DSL decides budget eligibility."""
    import hashlib
    import json
    from gambit_smp.suite_primitives import capacity
    if (previous.get("schema") != "gambit-upstream-suite.v1"
            or current.get("mode") not in previous.get("modes", [])
            or current.get("regime") != "whole-parallel"):
        raise ValueError("recorded whole-suite topology and matching current mode required")
    old_jobs, old_processors = previous.get("jobs"), previous.get("processors")
    cpu = current.get("hostCpuCapacity")
    jobs, processors = current.get("effectiveJobs"), current.get("effectiveProcessors")
    if any(type(value) is not int or value < 1 for value in
           (old_jobs, old_processors, cpu, jobs, processors)):
        raise ValueError("recorded positive processor/job populations required")
    rows = [row for row in previous.get("results", []) if row.get("mode") == current["mode"]]
    if len(rows) != 1 or len(rows[0].get("process", {}).get("shards", [])) != old_jobs:
        raise ValueError("original shard inventory must corroborate the recorded job count")
    population, workers = capacity(cpu, len(current["selectedFiles"]), True,
                                   current.get("processors"), current.get("jobs"))
    if (processors, jobs) != (population, workers):
        raise ValueError("current plan differs from the actual shared-capacity scheduler")
    plan = {"originalProcessors": old_processors, "originalJobs": old_jobs,
            "originalChildDemand": old_jobs * old_processors,
            "currentProcessors": processors, "currentJobs": jobs,
            "currentRunnerProcessors": 1, "currentTotalDemand": jobs * (processors + 1),
            "hostCpuCapacity": cpu}
    encoded = json.dumps(plan, sort_keys=True, separators=(",", ":")).encode()
    return plan, hashlib.sha256(encoded).hexdigest()


def environment_change(ctx, change, current, failure, previous, facts, inputs):
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.suite_primitives import capacity
    if (change["after"] != current.get("environmentProbe")
            or change["path"] not in {"udp-open", "process-pipe-sort", "user-info"}):
        raise ValueError("environment change must bind this campaign's same-run observation")
    path = ctx.artifact(change["after"], "current-producer-observation")
    observation = read_json(path)
    if (observation.get("schema") != "current-producer-observation.v1"
            or observation.get("candidateReceiptSha256") != current["candidateReceiptSha256"]
            or digest(path) != current["environmentObservationSha256"]
            or observation.get("complete") is not True
            or observation.get("runtimeAdmitted") is not False or observation.get("nativeGcPassed") is not False
            or observation.get("program") != "models/gambit/native/host_environment_probe.scm"
            or type(observation.get("processors")) is not int
            or observation["processors"] != capacity(current["hostCpuCapacity"], 1, False)[0]
            or not isinstance(observation.get("operations"), list)
            or change["path"] not in observation["operations"]):
        raise ValueError("current producer, operation, completion and processor observation required")
    program = source_path(ctx.root, observation["program"])
    if digest(program) != observation.get("programSha256"):
        raise ValueError("environment probe source drift")
    inputs[observation["program"]] = observation["programSha256"]
    ctx.bind([program, path])
    route, operation = failure["id"], change["path"]
    facts["environment_observation"].append([route, operation])
    for control in failure.get("controls", []):
        if control.get("kind") != "outside-sandbox-unchanged-source-and-artifacts":
            continue
        control_path = source_path(ctx.root, control["receipt"])
        log = source_path(ctx.root, control["log"])
        record = read_json(control_path)
        if not log.stat().st_size:
            raise ValueError("environment control requires its retained raw log")
        inputs.update({control["receipt"]: digest(control_path), control["log"]: digest(log)})
        ctx.bind([control_path, log])
        if record.get("schema") != "gambit-upstream-suite.v1":
            raise ValueError("typed native environment control required")
        rows = [row for row in record["results"] if row.get("mode") == current["mode"]]
        if len(rows) != 1:
            raise ValueError("exact environment control mode required")
        row = rows[0]
        same_config = all(key in record and key in previous and record[key] == previous[key]
                          for key in ("processors", "processorSelection", "minHeapKiBControl", "compiler", "gsiSha256", "gscSha256"))
        facts["environment_control"].append([route, operation, previous["status"], record["status"],
            row["exit"], row["timeout"], row["accepted"],
            previous.get("candidateReceiptSha256") == record.get("candidateReceiptSha256"),
            previous.get("selectedFiles") == record.get("selectedFiles"),
            bool(previous.get("sourceFiles")) and previous["sourceFiles"] == record.get("sourceFiles"),
            same_config, milliseconds(previous["wholeSuiteBudgetPerMode"]),
            milliseconds(record["wholeSuiteBudgetPerMode"])])


def project_review(ctx, document, current, failures, runtime, tested_unit, facts, inputs, *, producer_binding=False):
    from gambit_smp.recipes import fields, read_json, source_path
    fields(document, ("schema", "campaign", "failures"))
    if document["schema"] != SCHEMA or not isinstance(document["failures"], list):
        raise ValueError("typed retry review document required")
    if document["campaign"] != current:
        raise ValueError("retry review must bind the exact candidate, inventory, topology and budgets")
    indexed = {}
    for entry in document["failures"]:
        fields(entry, ("id", "receiptSha256", "baselineIdentity", "failurePointer", "log",
                       "budget", "changes", "claims"))
        if not isinstance(entry["id"], str) or entry["id"] in indexed:
            raise ValueError("unique typed failure review required")
        indexed[entry["id"]] = entry
    if set(indexed) - set(failures):
        raise ValueError("retry review names an unselected or unknown failure")

    def bound(reference):
        fields(reference, ("path", "sha256"))
        path = source_path(ctx.root, reference["path"])
        if digest(path) != reference["sha256"]:
            raise ValueError("retry review evidence identity drift")
        inputs[reference["path"]] = reference["sha256"]
        ctx.bind([path])
        return path

    for route, entry in indexed.items():
        failure, previous = failures[route]
        if entry["receiptSha256"] != inputs[failure["receipt"]]:
            raise ValueError("retry review changed the failure receipt")
        log = bound(entry["log"])
        if failure.get("log") != entry["log"]["path"] or not log.stat().st_size:
            raise ValueError("archived known-failure raw log required")
        # Old execution inputs may be obsolete; the failed observation itself stays immutable.
        outcome = entry["failurePointer"]
        accepted = (isinstance(outcome, str) and re.fullmatch(r"/results/(?:0|[1-9][0-9]*)/accepted", outcome)
                    and pointer(previous, outcome) is False
                    and pointer(previous, outcome.rsplit("/", 1)[0] + "/mode") == current["mode"])
        exited = (isinstance(outcome, str) and re.fullmatch(r"/steps/(?:0|[1-9][0-9]*)/exit", outcome)
                  and type(pointer(previous, outcome)) is int and pointer(previous, outcome) != 0
                  and pointer(previous, outcome.rsplit("/", 1)[0] + "/name") == current["operation"]
                  and current["regime"] == "build-step")
        probe_phase = compiler_probe_failure(previous, outcome, failure["file"], current["mode"])
        if not accepted and not exited and probe_phase is None:
            raise ValueError("retry review must point to an actual unaccepted result")
        baseline_path = bound(entry["baselineIdentity"])
        baseline = read_json(baseline_path)
        if previous.get("candidateReceiptSha256", previous.get("seedReceiptSha256")) != digest(baseline_path):
            raise ValueError("failure does not bind the supplied baseline identity")
        fields(entry["budget"], ("regime", "pointer"), ("file", "group"))
        regime, budget_pointer = entry["budget"]["regime"], entry["budget"]["pointer"]
        if regime not in {"whole-sequential", "whole-parallel", "atomic-coverage", "build-step", "compiler-probe", "upstream-make"}:
            raise ValueError("original budget regime required")
        allowed = {"atomic-coverage": "/atomicBatchBudgetPerMode", "build-step": "/wholeBootstrapBudget",
                   "upstream-make": "/wholeUpstreamTestBudget",
                   "compiler-probe": "/wholeProbeBudget"}.get(
            regime, "/wholeSuiteBudgetPerMode")
        if budget_pointer != allowed:
            raise ValueError("budget pointer must identify the original native budget, not elapsed time")
        original = milliseconds(pointer(previous, budget_pointer))
        scoped = entry["budget"].get("file")
        group_id = entry["budget"].get("group")
        if regime == "compiler-probe":
            if probe_phase is None or scoped != previous["selection"] or group_id is not None:
                raise ValueError("compiler probe must bind its actual failed phase and original fixture cap")
            facts["compiler_probe_failure"].append([route, probe_phase])
        elif probe_phase is not None:
            raise ValueError("compiler probe cannot be relabeled as a suite or bootstrap")
        if group_id is not None:
            group = current["groupBudgetSeconds"].get(group_id)
            original_files = previous.get("selectedFiles")
            if (scoped is not None or regime not in {"whole-sequential", "whole-parallel"}
                    or current["regime"] not in {"whole-sequential", "whole-parallel"}
                    or not isinstance(group, dict) or not isinstance(original_files, list)
                    or not original_files or len(set(original_files)) != len(original_files)
                    or sorted(group["files"]) != sorted(original_files)
                    or not set(original_files) <= set(current["selectedFiles"])
                    or failure["file"] not in original_files):
                raise ValueError("group budget must bind the exact original whole-group campaign")
            facts["scoped_file_group"].append([route, group_id])
        if scoped is not None:
            original_selection = [previous["selection"]] if regime == "compiler-probe" else previous.get("selectedFiles")
            if (regime not in {"whole-sequential", "whole-parallel", "compiler-probe"}
                    or original_selection != [scoped]
                    or failure["file"] != scoped or scoped not in current["selectedFiles"]):
                raise ValueError("file budget must bind the exact original single-file campaign")
            facts["scoped_single_file"].append([route, scoped])
        facts["review_present"].append([route])
        facts["campaign_bound"].append([route])
        facts["budget_regime"].append([route, regime, current["regime"]])
        whole_regimes = {"whole-sequential", "whole-parallel"}
        original_files = previous.get("selectedFiles")
        exact_whole = regime in whole_regimes and current["regime"] in whole_regimes
        exact_atomic = regime == current["regime"] == "atomic-coverage"
        if ((current["regime"] in whole_regimes and not current.get("operation")
             or current["regime"] == "upstream-make" and current["mode"] in current.get("unitModes", []))
                and isinstance(original_files, list) and original_files
                and all(isinstance(name, str) for name in original_files)
                and len(set(original_files)) == len(original_files)):
            # The native suite step's deadline encloses copying, compilation
            # and execution. Policy, not transport, decides inventory coverage.
            facts["whole_budget_interval"].append([route])
            facts["review_original_file"].extend([route, name] for name in original_files)
            facts["review_current_file"].extend([route, name] for name in current["selectedFiles"])
        if ((exact_whole or exact_atomic)
                and isinstance(original_files, list) and original_files
                and all(isinstance(name, str) for name in original_files)
                and len(set(original_files)) == len(original_files)
                and sorted(original_files) == sorted(current["selectedFiles"])):
            facts["exact_whole_inventory" if exact_whole else "exact_atomic_inventory"].append([route])
        axis = "group-step" if group_id is not None else "file-step" if scoped is not None else "atomic-batch" if regime == "atomic-coverage" else "suite-step"
        facts["required_budget"].append([route, axis])
        facts["original_budget"].append([route, axis, original])
        dominating_whole = axis == "atomic-batch" and current["regime"] in whole_regimes
        proposed = (current["suiteBudgetSeconds"] if dominating_whole else
                    current["groupBudgetSeconds"][group_id]["budgetSeconds"] if group_id is not None else
                    current["fileBudgetSeconds"].get(scoped) if scoped is not None else
                    current["batchBudgetSeconds"] if axis == "atomic-batch" else current["suiteBudgetSeconds"])
        if proposed is not None:
            facts["requested_budget"].append([route, "suite-step" if dominating_whole else axis,
                                               milliseconds(proposed)])
        if not isinstance(entry["changes"], list) or not isinstance(entry["claims"], list):
            raise ValueError("typed change and claim inventories required")
        change_ids = set()
        for change in entry["changes"]:
            fields(change, ("id", "kind", "path", "before", "after"))
            if change["kind"] == "compiler-configuration":
                if (not producer_binding or current["mode"] != "gsc"
                        or previous.get("schema") != "gambit-upstream-suite.v1"
                        or change["before"] != entry["receiptSha256"]
                        or change["path"] != "image-build-configuration"):
                    raise ValueError("compiler configuration requires the original compiled suite and current producer")
                fields(change["after"], ("binding", "archive", "observation"))
                if change["after"]["binding"] != "current-compiler-configuration":
                    raise ValueError("current compiler configuration binding required")
                archive_path = bound(change["after"]["archive"])
                observation_path = bound(change["after"]["observation"])
                plan, archive_inputs = compiler_configuration_change(ctx.root,
                    archive_path.relative_to(ctx.root).as_posix(),
                    observation_path.relative_to(ctx.root).as_posix(), previous, runtime, ctx.tools["gcc"])
                inputs.update(archive_inputs)
                ctx.bind([ctx.root / name for name in archive_inputs])
                ctx.bind([runtime / "bin/gambuild-C", runtime / "gsc/gsc"])
                facts["compiler_configuration_observation"].append([route,
                    plan["originalOptimizationLevel"], plan["currentOptimizationLevel"]])
                after = plan["currentDriverSha256"]
            elif change["kind"] == "compiler-options":
                if (not producer_binding or current["mode"] != "gsc"
                        or probe_phase != "c-to-dynamic-module"
                        or change["before"] != entry["receiptSha256"]
                        or change["path"] != "dynamic-c-optimization"):
                    raise ValueError("compiler options require the exact failed C phase and current producer")
                fields(change["after"], ("binding", "archive"))
                if change["after"]["binding"] != "current-compiler-options":
                    raise ValueError("current compiler options binding required")
                archive_path = bound(change["after"]["archive"])
                plan, archive_inputs = compiler_options_change(ctx.root,
                    archive_path.relative_to(ctx.root).as_posix(), previous, runtime,
                    tested_unit, ctx.tools["gcc"])
                inputs.update(archive_inputs)
                ctx.bind([ctx.root / name for name in archive_inputs])
                ctx.bind([runtime / "bin/gambuild-C", relative(tested_unit, previous["selection"])])
                facts["compiler_options_observation"].append([route,
                    plan["originalOptimizationLevel"], plan["currentOptimizationLevel"]])
                after = plan["currentDriverSha256"]
            elif change["kind"] == "resource-plan":
                if (not producer_binding or change["before"] != entry["receiptSha256"]
                        or change["path"] != "shared-cpu-capacity"
                        or change["after"] != {"binding": "current-resource-plan"}):
                    raise ValueError("resource plan requires the exact original denial and current producer")
                plan, after = resource_plan_change(previous, current)
                facts["resource_plan_observation"].append([route,
                    plan["originalChildDemand"], plan["currentTotalDemand"], plan["hostCpuCapacity"]])
            elif change["kind"] == "environment":
                if change["before"] != entry["receiptSha256"] or not producer_binding:
                    raise ValueError("environment change requires the exact original denial and current producer")
                environment_change(ctx, change, current, failure, previous, facts, inputs)
                after = current["environmentObservationSha256"]
            else:
                after = change["after"]
            if any(not isinstance(value, str) or not re.fullmatch(r"[0-9a-f]{64}", value)
                   for value in (change["before"], after)):
                raise ValueError("complete before/after source identities required")
            name = change["path"]
            if not isinstance(change["id"], str) or change["id"] in change_ids:
                raise ValueError("unique change identity required")
            change_ids.add(change["id"])
            if change["kind"] == "compiler-configuration":
                old, actual_path = entry["receiptSha256"], runtime / "bin/gambuild-C"
            elif change["kind"] == "compiler-options":
                old, actual_path = entry["receiptSha256"], runtime / "bin/gambuild-C"
            elif change["kind"] == "resource-plan":
                old, actual_path = entry["receiptSha256"], None
            elif change["kind"] == "environment":
                old, actual_path = entry["receiptSha256"], ctx.artifact(change["after"], "current-producer-observation")
            elif change["kind"] == "source":
                old = baseline["sourceFiles"].get(name)
                actual_path = relative(runtime, name)
            elif change["kind"] == "fixture":
                old = previous["sourceFiles"].get("unit-tests/" + name)
                if name not in current["selectedFiles"]:
                    raise ValueError("fixture change must belong to the selected inventory")
                actual_path = relative(tested_unit, name)
            elif change["kind"] == "build-driver":
                if not producer_binding or current["mode"] != "gsc":
                    raise ValueError("build driver requires the exact current compiled producer")
                old, actual_path = build_driver_change(previous, change, runtime)
            else:
                raise ValueError("unsupported change domain; environment/tool changes need typed observations")
            if old != change["before"] or (actual_path is not None and digest(actual_path) != after):
                raise ValueError("change must bind actual baseline and current bytes")
            if actual_path is not None:
                ctx.bind([actual_path])
            if change["before"] != after:
                facts["changed_input"].append([route, change["id"], change["kind"], name,
                                               change["before"], after])
        claim_ids = set()
        for claim in entry["claims"]:
            fields(claim, ("id", "evidence", "pointer"))
            if not isinstance(claim["id"], str) or claim["id"] in claim_ids:
                raise ValueError("unique claim identity required")
            claim_ids.add(claim["id"])
            evidence_path = bound(claim["evidence"])
            evidence = read_json(evidence_path)
            if evidence.get("schema") != "typed-causal-review-evidence.v1":
                raise ValueError("typed causal-review evidence required, not model/local PASS")
            row = pointer(evidence, claim["pointer"])
            fields(row, ("claim", "domain", "status", "failureReceiptSha256", "candidateReceiptSha256",
                         "changes", "premises", "references", "reasoning"))
            candidate_bound = (row["candidateReceiptSha256"] == current["candidateReceiptSha256"] or
                               producer_binding and row["candidateReceiptSha256"] == {"binding": "current-producer"})
            if (row["claim"] != claim["id"] or row["failureReceiptSha256"] != entry["receiptSha256"]
                    or not candidate_bound):
                raise ValueError("causal evidence must bind the failure and exact current candidate")
            if (not isinstance(row["premises"], list) or any(not isinstance(p, str) for p in row["premises"])
                    or not isinstance(row["changes"], list) or not set(row["changes"]) <= change_ids
                    or not isinstance(row["references"], list) or not row["references"]
                    or not isinstance(row["reasoning"], str) or not row["reasoning"].strip()
                    or type(row["domain"]) is not str or type(row["status"]) is not str):
                raise ValueError("explicit causal reasoning, references and typed premise inventory required")
            for ref in row["references"]:
                bound(ref)
            facts["claim_evidence"].append([route, claim["id"], row["domain"], row["status"], digest(evidence_path)])
            facts["claim_dependency"].extend([route, claim["id"], premise] for premise in row["premises"])
            facts["claim_change"].extend([route, claim["id"], change] for change in row["changes"])


def historical_observation(ctx, failure, original, inputs, facts):
    from gambit_smp.recipes import fields, read_json, source_path
    from gambit_smp.native_archive import validate
    if "observation" not in failure:
        return failure, original
    version_path = source_path(ctx.root, failure["observation"])
    version = read_json(version_path)
    fields(version, ("schema", "original", "archive", "log", "agreements"))
    if version["schema"] != "historical-failure-observation.v1":
        raise ValueError("typed historical failure observation required")
    inputs[failure["observation"]] = digest(version_path)
    for label in ("original", "archive", "log"):
        reference = version[label]
        fields(reference, ("path", "sha256"))
        path = source_path(ctx.root, reference["path"])
        if digest(path) != reference["sha256"]:
            raise ValueError("historical observation reference drift: " + label)
        inputs[reference["path"]] = reference["sha256"]
    if version["original"] != {"path": failure["receipt"], "sha256": inputs[failure["receipt"]]}:
        raise ValueError("historical observation must retain the exact canonical failure")
    archive_path = source_path(ctx.root, version["archive"]["path"])
    archived_inputs = validate(ctx.root, version["archive"]["path"])
    # Transcript observations are represented by publication bindings in the
    # validator's input closure. Membership still belongs to the validated
    # archive inventory, not to the set of ordinary repository input paths.
    log_path = source_path(ctx.root, version["log"]["path"])
    try:
        log_member = log_path.relative_to(archive_path.parent).as_posix()
    except ValueError:
        raise ValueError("historical observation log must belong to the verified archive")
    archived = read_json(archive_path)
    if archived.get("files", {}).get(log_member) != version["log"]["sha256"]:
        raise ValueError("historical observation log must belong to the verified archive")
    inputs.update(archived_inputs)
    recovered = read_json(archive_path.parent / "receipt.json")
    if not isinstance(version["agreements"], list):
        raise ValueError("explicit historical field agreements required")
    route = failure["id"]
    facts["observation_bridge"].append([route, original.get("schema", "unknown")])
    seen = set()
    for agreement in version["agreements"]:
        fields(agreement, ("field", "original", "observed"))
        if not isinstance(agreement["field"], str) or agreement["field"] in seen:
            raise ValueError("unique historical agreement field required")
        seen.add(agreement["field"])
        before, after = pointer(original, agreement["original"]), pointer(recovered, agreement["observed"])
        same_type = type(before) is type(after) or (type(before) in (int, float) and type(after) in (int, float))
        if same_type and before == after:
            facts["observation_equal_pointer"].append(
                [route, agreement["field"], agreement["original"], agreement["observed"]])
    ctx.bind(ctx.root / name for name in inputs)
    return {**failure, "log": version["log"]["path"]}, recovered


def preflight(ctx, args, runtime, candidate_receipt, files, tested_unit, *, document=None, suite_budget=None,
              producer_binding=False, label="retry-review"):
    from gambit_smp.evidence_capabilities import evaluate_observations, review_policy_identity
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.research_kernel import manifest_paths
    from gambit_smp.suite_primitives import check_runtime
    candidate = read_json(candidate_receipt)
    if candidate.get('schema') == 'gambit-bootstrap-input-identity':
        if args.get('mode') != 'bootstrap' or args.get('operation') != 'from-scratch':
            raise ValueError('compiler-only identity cannot admit a runtime operation')
        from gambit_smp.bootstrap_artifacts import check
        check(runtime, candidate)
    else:
        check_runtime(runtime, candidate)
    ctx.bind([candidate_receipt])
    manifest = source_path(ctx.root, args["failures"])
    if manifest != source_path(ctx.root, "evidence/native-failures.json"):
        raise ValueError("suite must use the complete canonical known-failure inventory")
    declared = read_json(manifest)
    if declared.get("schema") != "gambit-local-native-failures.v1" or not isinstance(declared.get("failures"), list):
        raise ValueError("declared failure inventory required")
    rules = source_path(ctx.root, args["reviewRules"])
    engine = review_policy_identity(Path(ctx.receipt["engine"]["path"]))
    if digest(rules) != engine["files"].get("policy/suite-review-rules.ss"):
        raise ValueError("retry safety policy must match the sealed engine")
    rule_paths = [args['reviewRules']]
    extension = args.get('reviewRulesExtension')
    if extension:
        from gambit_smp.upstream_tests import POLICIES
        path = source_path(ctx.root, extension)
        if (current_regime := args.get('regime')) != 'upstream-make' or digest(path) != engine['files'].get(POLICIES.get(extension)):
            raise ValueError('unsealed or non-Make retry policy extension')
        rule_paths.append(extension)
        ctx.bind([path])
    names = ("retry_marker", "known_failure", "selected_failure", "failure_category", "failure_scope", "review_present", "campaign_bound", "budget_regime",
             "required_budget", "original_budget", "requested_budget", "scoped_single_file", "scoped_file_group", "exact_whole_inventory", "exact_atomic_inventory", "changed_input",
             "claim_evidence", "claim_dependency", "claim_change", "observation_bridge", "observation_equal_pointer",
             "environment_observation", "environment_control", "resource_plan_observation", "whole_budget_interval",
             "review_original_file", "review_current_file", "compiler_probe_failure", "compiler_options_observation",
             "compiler_configuration_observation", "failure_campaign_file", "failure_campaign_closed",
             "current_campaign_file", "budget_toolchain_distinct", "budget_watchdog_distinct")
    facts = {name: [] for name in names}
    facts["retry_marker"] = [[True]]
    inputs = {args["failures"]: digest(manifest), **{name: digest(ctx.root/name) for name in rule_paths}}
    selected = {str(path) for path in files}
    facts["current_campaign_file"] = [[name] for name in sorted(selected)]
    selected.update(make_operation_scope(args))
    overlaps, failures, budget_compilers = [], {}, []
    seen = set()
    for failure in declared["failures"]:
        if failure["id"] in seen:
            raise ValueError("duplicate known-failure identity")
        seen.add(failure["id"])
        if not selected_scope(failure["file"], selected, files):
            continue
        observed = relative(ctx.root, failure["receipt"])
        prior = read_json(observed)
        inputs[failure["receipt"]] = digest(observed)
        failure, prior = historical_observation(ctx, failure, prior, inputs, facts)
        denied = failure_modes(prior)
        if denied and args["mode"] not in denied:
            continue
        route = failure["id"]
        facts["known_failure"].append([route, args["mode"]])
        facts["selected_failure"].append([route])
        facts["failure_category"].append([route, failure.get("category", "unknown")])
        facts["failure_scope"].append([route, failure["file"]])
        original_compiler = prior.get("compiler", prior.get("compilerVersion"))
        if (failure.get("category") == "budget" and isinstance(original_compiler, str)
                and original_compiler.strip()):
            budget_compilers.append((route, original_compiler.splitlines()[0]))
        if (failure.get("category") == "budget"
                and ctx.receipt.get("timeoutPolicy", {}).get("mode") == "progress"
                and prior.get("timeoutPolicy", {}).get("mode") != "progress"):
            facts["budget_watchdog_distinct"].append([route])
        recorded_files = failure_campaign_files(prior)
        if recorded_files is not None:
            facts["failure_campaign_closed"].append([route])
            facts["failure_campaign_file"].extend([route, name] for name in recorded_files)
        failures[route] = (failure, prior)
        overlaps.append(route)
    comparisons = []
    if budget_compilers:
        output = ctx.require("budget-compiler-version", [ctx.tools["gcc"], "--version"], ctx.root, 10)
        version = output.splitlines()[0] if output.splitlines() else ""
        if "gcc" not in version.lower() or "clang" in version.lower():
            raise ValueError("GNU GCC budget comparison requires current compiler identity")
        for route, original in budget_compilers:
            distinct = original != version
            comparisons.append({"route": route, "original": original, "current": version,
                                "comparable": not distinct})
            if distinct:
                facts["budget_toolchain_distinct"].append([route])
    current = campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, suite_budget=suite_budget)
    if document is None and "retryReview" in args:
        if isinstance(args["retryReview"], dict):
            review_path = ctx.artifact(args["retryReview"], "bound-native-review")
            bound_document = read_json(review_path)
            if (bound_document.get("schema") != "bound-native-review.v1"
                    or bound_document.get("candidateReceiptSha256") != digest(candidate_receipt)):
                raise ValueError("bound review producer identity mismatch")
            intent = bound_document["intent"]
            path = source_path(ctx.root, intent["path"])
            if digest(path) != intent["sha256"]:
                raise ValueError("bound review intent changed")
            inputs[intent["path"]] = intent["sha256"]
            ctx.bind([review_path])
            successor = bound_document.get("sourceSuccessor")
            if successor is not None:
                from gambit_smp.recipes import fields, source_path
                fields(successor, ("path", "sha256"))
                source = source_path(ctx.root, successor["path"])
                if digest(source) != successor["sha256"]:
                    raise ValueError("bound source successor changed")
                inputs[successor["path"]] = successor["sha256"]
                ctx.bind([source])
            document, producer_binding = bound_document["document"], True
        else:
            review_path = source_path(ctx.root, args["retryReview"])
            inputs[args["retryReview"]] = digest(review_path)
            document = read_json(review_path)
    if document is not None:
        distinct = {route for relation in ("budget_toolchain_distinct", "budget_watchdog_distinct")
                    for route, in facts[relation]}
        reviewable = {**document, "failures": [entry for entry in document["failures"]
                                              if entry["id"] not in distinct]}
        project_review(ctx, reviewable, current, failures, runtime, tested_unit, facts, inputs,
                       producer_binding=producer_binding)
    ctx.bind(ctx.root / name for name in inputs)
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,95}", label):
        raise ValueError("bounded retry observation label required")
    answers = evaluate_observations(ctx, rule_paths, facts,
        {"selected": "selected_known_failure", "disjoint": "failure_campaign_disjoint",
         "eligible": "retry_eligible", "denied": "retry_denied",
         "missing": "missing_claim", "review": "review_required", "need": "needed_claim",
         "decision": "retry_decision"}, label)
    expected = sorted([[route, args["mode"]] for route in overlaps])
    disjoint = answers.get("disjoint", [])
    if sorted(answers["selected"] + disjoint) != expected:
        raise ValueError("native retry rules did not partition all scoped known failures exactly once")
    if sorted(answers["eligible"] + answers["review"]) != sorted(answers["selected"]):
        raise ValueError("native retry disposition omitted or duplicated a known failure")
    candidate = read_json(candidate_receipt)
    if candidate.get('schema') == 'gambit-bootstrap-input-identity':
        if args.get('mode') != 'bootstrap' or args.get('operation') != 'from-scratch':
            raise ValueError('compiler-only identity cannot admit a runtime operation')
        from gambit_smp.bootstrap_artifacts import check
        check(runtime, candidate)
    else:
        check_runtime(runtime, candidate)
    if campaign(ctx, args, runtime, candidate_receipt, files, tested_unit, suite_budget=suite_budget) != current:
        raise ValueError("candidate campaign or topology drift during native inference")
    if any(digest(ctx.root / name) != expected for name, expected in inputs.items()):
        raise ValueError("retry review input drift during native inference")
    ctx.bind([candidate_receipt])
    decisions = answers["decision"]
    if len(decisions) != 1 or decisions[0][0] not in {"DENY", "REVIEW_REQUIRED", "RETRY_ELIGIBLE", "NOT_REQUIRED"}:
        raise ValueError("native retry policy must return exactly one disposition")
    decision = decisions[0][0]
    return {"schema": "typed-suite-retry-review.v2", "decision": decision, "campaign": current,
            "knownSelectedFailures": [row[0] for row in answers["selected"]],
            "knownScopeCandidates": overlaps, "disjointCampaignFailures": [row[0] for row in disjoint],
            "answers": answers, "inputs": inputs,
            "facts": facts, "budgetCompilerComparisons": comparisons,
            "runtimeAdmitted": False, "executionAuthorized": False,
            "policyProgram": "research-suite-review.v1",
            "scope": "Conditional investigation eligibility only. Host authorization and full native results remain independent."}
