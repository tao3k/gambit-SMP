"""Discover declarative Evidence capability graphs; never execute recipe scripts."""
import argparse
from dataclasses import dataclass
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import time

from gambit_smp.framework import ROOT, digest, execute, relative


SCHEMA = "evidence-recipe.v1"
IDENTIFIER = re.compile(r"[a-z][a-z0-9-]{0,95}\Z")
SYMBOL = re.compile(r"[A-Za-z_][A-Za-z0-9_]*\Z")
CACHE_PARTS = {".data", ".cache", "cache", "__pycache__", ".git", ".venv"}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError("duplicate JSON field: " + key)
        result[key] = value
    return result


def read_json(path):
    return json.loads(path.read_text(), object_pairs_hook=unique_object,
                      parse_constant=lambda value: (_ for _ in ()).throw(
                          ValueError("nonfinite JSON value: " + value)))


def source_path(root, name):
    path = relative(root, name)
    resolved = path.relative_to(root.resolve())
    if (any(part.casefold() in CACHE_PARTS for part in Path(name).parts)
            or any(part.casefold() in CACHE_PARTS for part in resolved.parts)
            or not path.is_file()):
        raise ValueError("recipe inputs must be repository files, not Cache aliases: " + name)
    return path


def fields(value, required, optional=()):
    if not isinstance(value, dict) or not set(required) <= value.keys() or value.keys() - set(required) - set(optional):
        raise ValueError("unsupported capability fields")


def budget(value):
    if type(value) not in (int, float) or not math.isfinite(value) or not 0 < value <= 600:
        raise ValueError("finite positive budget at most 600 seconds required")
    return value


def source_operand(args, inputs):
    if args["source"] not in inputs or not args["source"].endswith(".qnt"):
        raise ValueError("Quint source must be a declared .qnt input")


def validate_parse(args, inputs):
    fields(args, ("source",))
    source_operand(args, inputs)


def validate_typecheck(args, inputs):
    fields(args, ("source", "parsed"))
    source_operand(args, inputs)


def validate_test(args, inputs):
    fields(args, ("source", "parsed", "main", "seed", "maxSamples", "expectedTests"))
    source_operand(args, inputs)
    if not isinstance(args["main"], str) or not SYMBOL.fullmatch(args["main"]):
        raise ValueError("explicit Quint main module required")
    if not isinstance(args["seed"], str) or not re.fullmatch(r"0x[0-9a-fA-F]+", args["seed"]):
        raise ValueError("explicit hexadecimal seed required")
    if type(args["maxSamples"]) is not int or not 1 <= args["maxSamples"] <= 10000:
        raise ValueError("bounded Quint sample count required")
    tests = args["expectedTests"]
    if (not isinstance(tests, list) or not tests or len(tests) != len(set(tests))
            or any(not isinstance(name, str) or not SYMBOL.fullmatch(name) or not name.endswith("Test") for name in tests)):
        raise ValueError("exact nonempty Quint test inventory required")


def parse_command(args, directory):
    return ["parse", args["source"], "--out", str(directory / "result.json"),
            "--source-map", str(directory / "sources.json")]


def typecheck_command(args, directory):
    return ["typecheck", args["source"], "--out", str(directory / "result.json")]


def test_command(args, directory):
    return ["test", args["source"], "--main", args["main"], "--backend", "typescript",
            "--seed", args["seed"], "--max-samples", str(args["maxSamples"]),
            "--out", str(directory / "result.json")]


def successful_result(directory, stage):
    result = read_json(directory / "result.json")
    if result.get("stage") != stage or result.get("errors") != []:
        raise ValueError("Quint structured result is not a successful " + stage)
    return result


def admit_parse(args, directory, root, inputs):
    successful_result(directory, "parsing")
    sources = read_json(directory / "sources.json").get("sourceIndex")
    if not isinstance(sources, dict) or not sources:
        raise ValueError("Quint did not report its source closure")
    closure = []
    for name in sources.values():
        path = Path(name).resolve(strict=True)
        local = path.relative_to(root.resolve()).as_posix()
        if local not in inputs or source_path(root, local) != path:
            raise ValueError("undeclared or Cache-backed Quint import: " + local)
        closure.append(local)
    if args["source"] not in closure:
        raise ValueError("Quint source closure omitted the requested input")
    return {"sourceClosure": sorted(set(closure))}


def admit_typecheck(args, directory, root, inputs):
    successful_result(directory, "typechecking")
    return {"claim": "type-and-effect-check-only"}


def admit_test(args, directory, root, inputs):
    result = successful_result(directory, "testing")
    expected = args["expectedTests"]
    if (result.get("failed") != [] or result.get("ignored") != []
            or not isinstance(result.get("passed"), list)
            or len(result["passed"]) != len(expected) or sorted(result["passed"]) != sorted(expected)):
        raise ValueError("Quint test outcomes differ from the exact inventory")
    return {"passedTests": result["passed"], "claim": "sampled-local-controls-only"}


@dataclass(frozen=True)
class Capability:
    validate: object
    command: object = None
    admit: object = None
    executor: object = None
    graph: object = None
    outputs: tuple = ()


CAPABILITIES = {
    "quint.parse": Capability(validate_parse, parse_command, admit_parse),
    "quint.typecheck": Capability(validate_typecheck, typecheck_command, admit_typecheck),
    "quint.test": Capability(validate_test, test_command, admit_test),
}

from gambit_smp.native_capabilities import capabilities as native_capabilities
CAPABILITIES.update(native_capabilities(Capability))
from gambit_smp.source_capabilities import capabilities as source_capabilities
CAPABILITIES.update(source_capabilities(Capability))
from gambit_smp.evidence_capabilities import capabilities as evidence_capabilities
CAPABILITIES.update(evidence_capabilities(Capability))


def load(root, path):
    path = source_path(root, path.relative_to(root).as_posix())
    recipe = read_json(path)
    fields(recipe, ("schema", "id", "scope", "inputs", "steps", "budgetSeconds"))
    if recipe["schema"] not in {SCHEMA, "evidence-recipe.v2"} or not isinstance(recipe["id"], str) or not IDENTIFIER.fullmatch(recipe["id"]):
        raise ValueError("declarative Evidence recipe identity required")
    if not isinstance(recipe["scope"], str) or not recipe["scope"].strip():
        raise ValueError("explicit evidence scope required")
    budget(recipe["budgetSeconds"])
    inputs = recipe["inputs"]
    if not isinstance(inputs, list) or not inputs or any(not isinstance(name, str) for name in inputs) or len(set(inputs)) != len(inputs):
        raise ValueError("unique explicit recipe inputs required")
    for name in inputs:
        source_path(root, name)
    steps = recipe["steps"]
    if not isinstance(steps, list) or not 1 <= len(steps) <= 128:
        raise ValueError("bounded nonempty capability graph required")
    by_id = {}
    for step in steps:
        fields(step, ("id", "capability", "dependsOn", "arguments", "budgetSeconds"))
        name = step["id"]
        if not isinstance(name, str) or not IDENTIFIER.fullmatch(name) or name in by_id:
            raise ValueError("unique capability step identity required")
        if step["capability"] not in CAPABILITIES:
            raise ValueError("unknown capability; Evidence cannot supply executable code")
        budget(step["budgetSeconds"])
        if not isinstance(step["dependsOn"], list) or any(not isinstance(item, str) for item in step["dependsOn"]) or len(set(step["dependsOn"])) != len(step["dependsOn"]):
            raise ValueError("unique explicit dependencies required")
        CAPABILITIES[step["capability"]].validate(step["arguments"], inputs)
        by_id[name] = step
    ordered, pending = [], dict(by_id)
    while pending:
        ready = [step for step in pending.values() if set(step["dependsOn"]) <= {item["id"] for item in ordered}]
        if not ready:
            raise ValueError("cyclic or unknown recipe dependencies")
        for step in ready:
            ordered.append(step)
            del pending[step["id"]]
    for step in ordered:
        args = step["arguments"]
        capability = CAPABILITIES[step["capability"]]
        if capability.graph is not None:
            capability.graph(step, by_id, CAPABILITIES)
        if step["capability"] in {"quint.typecheck", "quint.test"}:
            parsed = by_id.get(args["parsed"])
            if (args["parsed"] not in step["dependsOn"] or parsed is None
                    or parsed["capability"] != "quint.parse" or parsed["arguments"]["source"] != args["source"]):
                raise ValueError("capability requires its own declared parse dependency")
    if recipe["schema"] == "evidence-recipe.v2":
        from gambit_smp.research_kernel import validate_graph
        validate_graph(recipe, ordered)
    return recipe, ordered


def discover(root):
    found = {}
    for path in sorted((root / "evidence").rglob("*.recipe.json")):
        recipe, _ = load(root, path)
        if recipe["id"] in found:
            raise ValueError("duplicate discovered recipe identity")
        found[recipe["id"]] = path
    return found


def fingerprints(paths):
    return {str(path): digest(path) for path in sorted(set(paths))}


def tool_files(quint, node):
    quint, node = quint.resolve(strict=True), node.resolve(strict=True)
    package = next((parent for parent in quint.parents if (parent / "package.json").is_file()), None)
    if package is None or read_json(package / "package.json").get("name") != "@informalsystems/quint":
        raise ValueError("installed Quint package and explicit Node runtime required")
    return [node, quint, *(path for path in package.rglob("*") if path.is_file())]


def tree_identity(path):
    """Bind exact tree inventory, modes and internal links, not just old files."""
    result = {}
    root = path.resolve(strict=True)
    for file in sorted(path.rglob("*")):
        name = file.relative_to(path).as_posix()
        if file.is_symlink():
            try:
                target = file.resolve(strict=True)
            except (OSError, RuntimeError) as error:
                raise ValueError("artifact tree has an unresolved symlink") from error
            if not target.is_relative_to(root):
                raise ValueError("artifact tree contains an external symlink")
            result[name] = {"link": os.readlink(file)}
        elif file.is_file():
            result[name] = {"sha256": digest(file), "mode": file.stat().st_mode & 0o777}
        elif file.is_dir():
            result[name] = {"directory": True}
        else:
            raise ValueError("unsupported artifact tree entry")
    return result


class ExecutionContext:
    """One deadline and process recorder shared by every capability subcommand."""
    def __init__(self, root, out, directory, environment, deadline, outcomes, receipt, tools):
        self.root, self.out, self.directory = root, out, directory
        self.env, self.deadline = dict(environment), deadline
        self.outcomes, self.receipt, self.tools = outcomes, receipt, tools
        self.commands = []
        self.extra_inputs = {}
        self.last_stdout = None

    def remaining(self):
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("capability or whole recipe budget exhausted")
        return remaining

    def run(self, name, argv, cwd, cap):
        path = self.directory / (name + ".log")
        if path.exists():
            raise ValueError("unique subcommand log required")
        actual = min(cap, self.remaining())
        metadata = {}
        if "engine" in self.receipt:
            from gambit_smp.process_observation import capture
            observation = capture([str(arg) for arg in argv], cwd, actual, self.env)
            code, timeout, seconds = observation.exit, observation.timeout, observation.seconds
            log = observation.stdout + observation.stderr
            self.last_stdout = observation.stdout
            streams = {"stdout": observation.stdout, "stderr": observation.stderr}
            for stream, value in streams.items():
                stream_path = self.directory / (name + "." + stream)
                stream_path.write_text(value)
                metadata[stream + "Path"] = stream_path.name
                metadata[stream + "Sha256"] = digest(stream_path)
                metadata[stream + "Bytes"] = len(value.encode())
            metadata.update(pid=observation.pid, startedAt=observation.started_at, endedAt=observation.ended_at,
                            parentReaped=observation.exit is not None, processGroupQuiescent=observation.group_quiescent,
                            logOrdering="stdout-then-stderr; streams preserved separately")
        else:
            code, log, timeout, seconds = execute([str(arg) for arg in argv], cwd, actual,
                                                env=self.env, metadata=metadata)
            self.last_stdout = log
        path.write_text(log)
        self.commands.append(dict(stage=name, argv=[str(arg) for arg in argv], cwd=str(cwd),
                                  effectiveBudgetSeconds=actual, exit=code, timeout=timeout,
                                  seconds=seconds, log=path.name, environment=dict(self.env), **metadata))
        return code, log, timeout, seconds

    def require(self, name, argv, cwd, cap):
        code, log, timeout, _ = self.run(name, argv, cwd, cap)
        if timeout:
            raise TimeoutError(name + " timed out")
        if code != 0:
            raise ValueError(name + " failed with exit " + str(code))
        return self.last_stdout

    def artifact(self, reference, kind):
        step = next(row for row in self.receipt["steps"] if row["id"] == reference["step"])
        descriptor = step["outputs"][reference["output"]]
        kinds = {kind} if isinstance(kind, str) else kind
        if step["outcome"] != "PASS" or descriptor["type"] not in kinds:
            raise ValueError("unadmitted or mistyped artifact dependency")
        path = relative(self.out, descriptor["path"])
        if "identity" in descriptor:
            if tree_identity(path) != descriptor["identity"]:
                raise ValueError("artifact dependency drift")
        elif (digest(path) != descriptor["sha256"] or
              path.stat().st_mode & 0o777 != descriptor.get("mode", path.stat().st_mode & 0o777)):
            raise ValueError("artifact dependency drift")
        return path

    def bind(self, paths):
        for path in paths:
            path = path.resolve(strict=True)
            sha = digest(path)
            if str(path) in self.extra_inputs and self.extra_inputs[str(path)] != sha:
                raise ValueError("observed native input changed between subcommands")
            self.extra_inputs[str(path)] = sha

    def publish(self, name, kind, path):
        descriptor = {"type": kind, "path": path.relative_to(self.out).as_posix()}
        if path.is_dir():
            descriptor["identity"] = tree_identity(path)
        else:
            descriptor["sha256"] = digest(path)
            descriptor["mode"] = path.stat().st_mode & 0o777
        return {name: descriptor}


def inspect_run(out):
    """Recheck stored bytes, never import a historical observation as permission."""
    receipt = read_json(out / "receipt.json")
    if receipt.get("schema") != "evidence-recipe-run.v1":
        raise ValueError("recipe run receipt required")
    try:
        stable = fingerprints(Path(name) for name in receipt["inputs"]) == receipt["inputs"]
        tool_manifest = relative(out, receipt["toolInputs"]["path"])
        tools = read_json(tool_manifest)
        stable = stable and digest(tool_manifest) == receipt["toolInputs"]["sha256"]
        stable = stable and fingerprints(Path(name) for name in tools) == tools
        for step in receipt["steps"]:
            for name, sha in step.get("artifacts", {}).items():
                stable = stable and digest(relative(out, name)) == sha
            stable = stable and fingerprints(Path(name) for name in step.get("observedInputs", {})) == step.get("observedInputs", {})
            for descriptor in step.get("outputs", {}).values():
                path = relative(out, descriptor["path"])
                stable = stable and (tree_identity(path) == descriptor["identity"] if "identity" in descriptor
                                     else digest(path) == descriptor["sha256"] and
                                     path.stat().st_mode & 0o777 == descriptor.get("mode", path.stat().st_mode & 0o777))
    except (KeyError, TypeError, ValueError, OSError):
        stable = False
    return {"recipe": receipt["recipe"], "outcome": receipt["outcome"],
            "identityStatus": "CURRENT" if stable else "STALE", "steps": receipt["steps"],
            "runtimeAdmitted": False, "releaseAdmitted": False, "executionAuthorized": False}


def run(root, path, out, quint, node, prior=None, *, gcc=None, allow_native=False, engine=None, deadline=None):
    recipe, steps = load(root, path)
    engine_identity = None
    if recipe["schema"] == "evidence-recipe.v2":
        from gambit_smp.research_kernel import execution_identity
        if engine is None:
            raise ValueError("new research requires a sealed executor; use the research entry point")
        engine_identity = execution_identity(engine)
    out = out.resolve()
    if out.is_relative_to(root / "evidence") or any(source_path(root, name).is_relative_to(out) for name in recipe["inputs"]):
        raise ValueError("run outputs must not overwrite Evidence or recipe inputs")
    out.mkdir(parents=True, exist_ok=False)
    started = time.monotonic()
    deadline = min(deadline, started + recipe["budgetSeconds"]) if deadline is not None else started + recipe["budgetSeconds"]
    inputs = fingerprints([path, *(source_path(root, name) for name in recipe["inputs"]),
                           Path(__file__), Path(__file__).with_name("framework.py"),
                           Path(__file__).with_name("native_capabilities.py"),
                           Path(__file__).with_name("source_capabilities.py"), Path(sys.executable).resolve()])
    receipt = {"schema": "evidence-recipe-run.v1", "recipe": recipe["id"], "scope": recipe["scope"],
               "budgetSeconds": recipe["budgetSeconds"], "inputs": inputs, "steps": [],
               "declaredInputs": recipe["inputs"],
               "runtimeAdmitted": False, "releaseAdmitted": False, "executionAuthorized": False}
    if engine_identity is not None:
        receipt["engine"] = {"path": str(engine), "engineId": engine_identity["engineId"]}
    uses_quint = any(step["capability"].startswith("quint.") for step in steps)
    uses_native = any(CAPABILITIES[step["capability"]].executor is not None for step in steps)
    environment = {"PATH": os.pathsep.join((str(node.parent), "/usr/bin", "/bin")) if uses_quint else "/usr/bin:/bin",
                   "HOME": os.environ.get("HOME", str(root)), "LANG": "C", "LC_ALL": "C"}
    receipt["environment"] = environment
    tools = {}
    try:
        paths = tool_files(quint, node) if uses_quint else []
        receipt["tools"] = {"quint": str(quint.resolve()), "node": str(node.resolve())} if uses_quint else {}
        if uses_native:
            if not allow_native or gcc is None:
                raise ValueError("native execution requires host --allow-native and --gcc")
            from gambit_smp.native_capabilities import host_tools, implementation_files
            native_tools, environment = host_tools(gcc, steps, environment)
            paths.extend(native_tools.values())
            receipt["tools"].update({name: str(value) for name, value in native_tools.items()})
            inputs.update(fingerprints(implementation_files(steps)))
            receipt["environment"] = environment
        tools = fingerprints(paths)
        (out / "tools.json").write_text(json.dumps(tools, sort_keys=True, indent=2) + "\n")
        receipt["toolInputs"] = {"path": "tools.json", "sha256": digest(out / "tools.json"), "count": len(tools)}
        if prior is not None:
            previous = read_json(prior / "receipt.json")
            if previous.get("schema") != "evidence-recipe-run.v1" or previous.get("recipe") != recipe["id"]:
                raise ValueError("prior observation must identify this recipe")
            previous_tools = read_json(relative(prior, previous["toolInputs"]["path"]))
            if digest(relative(prior, previous["toolInputs"]["path"])) != previous["toolInputs"]["sha256"]:
                raise ValueError("prior tool observation was changed")
            delta = {name: sha for name, sha in inputs.items() if previous["inputs"].get(name) != sha}
            tool_delta = {name: sha for name, sha in tools.items() if previous_tools.get(name) != sha}
            previous_budgets = {step["id"]: step["budgetSeconds"] for step in previous["steps"]}
            previous_arguments = {step["id"]: step.get("arguments", {}) for step in previous["steps"]}
            if recipe["budgetSeconds"] > previous["budgetSeconds"] or any(
                    step["id"] in previous_budgets and (step["budgetSeconds"] > previous_budgets[step["id"]]
                        or ("batchBudgetSeconds" in previous_arguments[step["id"]]
                            and step["arguments"].get("batchBudgetSeconds", 0) > previous_arguments[step["id"]]["batchBudgetSeconds"]))
                    for step in steps):
                raise ValueError("prior failure cannot be retried by expanding a budget")
            if previous["outcome"] != "PASS" and not delta and not tool_delta:
                raise ValueError("unchanged failed recipe; no causal input/tool delta")
            receipt["prior"] = {"receiptSha256": digest(prior / "receipt.json"),
                                "changedInputs": delta, "changedTools": tool_delta}
        outcomes = {}
        for step in steps:
            result = {"id": step["id"], "capability": step["capability"], "budgetSeconds": step["budgetSeconds"],
                      "dependsOn": step["dependsOn"],
                      "arguments": step["arguments"]}
            receipt["steps"].append(result)
            if step["capability"] != "evidence.evaluate" and any(outcomes[dependency] != "PASS" for dependency in step["dependsOn"]):
                result["outcome"] = "BLOCKED"
            elif (fingerprints(Path(name) for name in inputs) != inputs
                  or fingerprints(Path(name) for name in tools) != tools):
                result.update(outcome="STALE", reason="input changed before capability execution")
            else:
                directory = out / step["id"]
                directory.mkdir()
                capability = CAPABILITIES[step["capability"]]
                if capability.executor is not None:
                    context = ExecutionContext(root, out, directory, environment,
                                               min(deadline, time.monotonic() + step["budgetSeconds"]),
                                               outcomes, receipt, receipt["tools"])
                    try:
                        result.update(capability.executor(step["arguments"], context))
                        context.remaining()
                        if any(row["exit"] != row.get("expectedExit", 0) or row["timeout"] for row in context.commands):
                            raise ValueError("native subcommand did not complete successfully")
                        if fingerprints(Path(name) for name in context.extra_inputs) != context.extra_inputs:
                            raise ValueError("native observed input drift")
                        result["outcome"] = "PASS"
                    except TimeoutError as error:
                        result.update(outcome="TIMEOUT", reason=str(error))
                    except (KeyError, TypeError, ValueError, OSError) as error:
                        result.update(outcome="DENY", reason=str(error))
                    result.update(commands=context.commands, observedInputs=context.extra_inputs)
                    if any(row["timeout"] for row in context.commands):
                        result["outcome"] = "TIMEOUT"
                    result["artifacts"] = {file.relative_to(out).as_posix(): digest(file)
                                           for file in sorted(directory.rglob("*")) if file.is_file() and not file.is_symlink()}
                    outcomes[step["id"]] = result["outcome"]
                    (directory / "step-receipt.json").write_text(json.dumps(result, sort_keys=True, indent=2) + "\n")
                    continue
                argv = [str(node.resolve()), str(quint.resolve()), *capability.command(step["arguments"], directory)]
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    result.update(outcome="TIMEOUT", reason="whole recipe budget exhausted")
                else:
                    actual_budget = min(step["budgetSeconds"], remaining)
                    meta = {}
                    code, log, timeout, seconds = execute(argv, root, actual_budget, env=environment, metadata=meta)
                    (directory / "raw.log").write_text(log)
                    result.update(argv=argv, cwd=str(root), effectiveBudgetSeconds=actual_budget,
                                  exit=code, timeout=timeout, seconds=seconds, **meta)
                    result["outcome"] = "TIMEOUT" if timeout else "FAIL" if code != 0 else "PASS"
                    if result["outcome"] == "PASS":
                        try:
                            result.update(capability.admit(step["arguments"], directory, root, recipe["inputs"]))
                            if step["capability"] == "quint.test":
                                ir = read_json(out / step["arguments"]["parsed"] / "result.json")
                                modules = [module for module in ir["modules"] if module["name"] == step["arguments"]["main"]]
                                inventory = [item["name"] for module in modules for item in module["declarations"]
                                             if item.get("qualifier") == "run" and item.get("name", "").endswith("Test")]
                                if len(modules) != 1 or sorted(inventory) != sorted(step["arguments"]["expectedTests"]):
                                    raise ValueError("test inventory differs from the parsed main module")
                        except (KeyError, TypeError, ValueError, OSError) as error:
                            result.update(outcome="DENY", reason=str(error))
                result["artifacts"] = {file.relative_to(out).as_posix(): digest(file) for file in sorted(directory.iterdir()) if file.is_file()}
            outcomes[step["id"]] = result["outcome"]
    except (KeyError, TypeError, ValueError, OSError) as error:
        receipt["error"] = str(error)
    try:
        stable = fingerprints(Path(name) for name in inputs) == inputs and fingerprints(Path(name) for name in tools) == tools
        for step in receipt["steps"]:
            stable = stable and fingerprints(Path(name) for name in step.get("observedInputs", {})) == step.get("observedInputs", {})
            for descriptor in step.get("outputs", {}).values():
                file = relative(out, descriptor["path"])
                stable = stable and (tree_identity(file) == descriptor["identity"] if "identity" in descriptor
                                     else digest(file) == descriptor["sha256"] and
                                     file.stat().st_mode & 0o777 == descriptor.get("mode", file.stat().st_mode & 0o777))
    except (OSError, ValueError):
        stable = False
    receipt["inputsStable"] = stable
    passed = len(receipt["steps"]) == len(steps) and all(step["outcome"] == "PASS" for step in receipt["steps"])
    receipt["wholeBudgetExhausted"] = time.monotonic() > deadline
    receipt["wholeSeconds"] = time.monotonic() - started
    passed = passed and not receipt["wholeBudgetExhausted"]
    receipt["outcome"] = "STALE" if not stable else "PASS" if passed and "error" not in receipt else "DENY"
    (out / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    return receipt


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--list", action="store_true")
    selection.add_argument("--run", metavar="RECIPE")
    selection.add_argument("--read", type=Path, metavar="RUN_DIRECTORY")
    parser.add_argument("--out", type=Path)
    parser.add_argument("--prior", type=Path, help="retain a previous failure and require an input/tool delta without budget expansion")
    parser.add_argument("--quint", type=Path, default=Path(shutil.which("quint") or "quint"))
    parser.add_argument("--node", type=Path, default=Path(shutil.which("node") or "node"))
    parser.add_argument("--gcc", type=Path, help="host-selected GNU compiler for native capabilities")
    parser.add_argument("--allow-native", action="store_true", help="explicit native execution request; not evidence admission")
    parser.add_argument("--historical-reproduction", action="store_true",
                        help="run a retained v1 observation; cannot establish v2 architecture completion")
    args = parser.parse_args()
    try:
        if args.read is not None:
            print(json.dumps(inspect_run(args.read.resolve()), indent=2))
            return 0
        found = discover(ROOT)
        if args.list:
            print(json.dumps([{ "id": name, "path": path.relative_to(ROOT).as_posix(),
                               "scope": read_json(path)["scope"]} for name, path in found.items()], indent=2))
            return 0
        if args.run not in found or args.out is None:
            parser.error("select a discovered recipe and a fresh --out directory")
        if not args.historical_reproduction:
            parser.error("new experiments use research --engine with v2 artifact graphs; v1 replay requires --historical-reproduction")
        receipt = run(ROOT, found[args.run], args.out, args.quint, args.node, args.prior,
                      gcc=args.gcc, allow_native=args.allow_native)
        print(json.dumps({key: receipt[key] for key in ("recipe", "outcome", "inputsStable", "runtimeAdmitted")}))
        return 0 if receipt["outcome"] == "PASS" else 2
    except (ValueError, OSError, TypeError, KeyError) as error:
        parser.error(str(error))


if __name__ == "__main__":
    raise SystemExit(main())
