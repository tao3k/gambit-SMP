"""Discover declarative Evidence capability graphs; never execute recipe scripts."""
import argparse
from contextlib import ExitStack
from contextvars import ContextVar
from copy import deepcopy
from dataclasses import dataclass
import hashlib
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import time
from threading import Lock

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


def budget(value, ceiling=600):
    if type(value) not in (int, float) or not math.isfinite(value) or not 0 < value <= ceiling:
        raise ValueError(f"finite positive budget at most {ceiling} seconds required")
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
            or any(not isinstance(name, str) or not all(SYMBOL.fullmatch(part) for part in name.split("::"))
                   or not name.endswith("Test") for name in tests)):
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


def quint_test_inventory(ir, main):
    """Resolve declared run names, including imported module namespaces."""
    modules = {}
    for module in ir["modules"]:
        if module["name"] in modules:
            raise ValueError("ambiguous parsed Quint module identity")
        modules[module["name"]] = module

    def collect(name, ancestors):
        if name in ancestors or name not in modules:
            raise ValueError("cyclic or missing parsed Quint import")
        tests = set()
        for item in modules[name]["declarations"]:
            if item.get("qualifier") == "run" and item["name"].endswith("Test"):
                tests.add(item["name"])
            if item.get("kind") in {"import", "instance", "export"}:
                imported = collect(item["protoName"], ancestors | {name})
                selected = item.get("defName")
                if selected not in (None, "*"):
                    imported = {test for test in imported if test == selected}
                qualifier = item.get("qualifiedName")
                tests.update((qualifier + "::" + test) if qualifier else test for test in imported)
        return tests

    return sorted(collect(main, set()))


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

from gambit_smp.quint_capabilities import capabilities as quint_capabilities
CAPABILITIES.update(quint_capabilities(Capability))

from gambit_smp.native_capabilities import capabilities as native_capabilities
CAPABILITIES.update(native_capabilities(Capability))
from gambit_smp.source_capabilities import capabilities as source_capabilities
CAPABILITIES.update(source_capabilities(Capability))
from gambit_smp.evidence_capabilities import capabilities as evidence_capabilities
CAPABILITIES.update(evidence_capabilities(Capability))


def load(root, path):
    path = source_path(root, path.relative_to(root).as_posix())
    recipe = read_json(path)
    fields(recipe, ("schema", "id", "scope", "inputs", "steps"),
           ("budgetSeconds", "timeoutPolicy", "workspacePolicy", "continuationRequest", "continuationLedger"))
    policy = recipe.get("timeoutPolicy")
    if policy is None:
        budget(recipe.get("budgetSeconds"))
    else:
        fields(policy, ("mode", "overheadSeconds"))
        if policy["mode"] not in {"per-stage", "progress"}:
            raise ValueError("explicit per-stage or progress timeout policy required")
        budget(policy["overheadSeconds"])
        if any(key in recipe for key in ("budgetSeconds", "continuationRequest", "continuationLedger")):
            raise ValueError("per-stage watchdog cannot also declare a whole or cumulative quota")
    if recipe.get("workspacePolicy", "isolated") not in {"isolated", "in-place"}:
        raise ValueError("explicit isolated or in-place workspace policy required")
    if recipe["schema"] not in {SCHEMA, "evidence-recipe.v2"} or not isinstance(recipe["id"], str) or not IDENTIFIER.fullmatch(recipe["id"]):
        raise ValueError("declarative Evidence recipe identity required")
    if not isinstance(recipe["scope"], str) or not recipe["scope"].strip():
        raise ValueError("explicit evidence scope required")
    inputs = recipe["inputs"]
    if not isinstance(inputs, list) or not inputs or any(not isinstance(name, str) for name in inputs) or len(set(inputs)) != len(inputs):
        raise ValueError("unique explicit recipe inputs required")
    for name in inputs:
        source_path(root, name)
    if "continuationRequest" in recipe and recipe["continuationRequest"] not in inputs:
        raise ValueError("continuation request must be a declared Evidence input")
    if "continuationRequest" in recipe and recipe.get("continuationLedger") not in inputs:
        raise ValueError("continuation requires its declared shared budget ledger")
    if "continuationLedger" in recipe and "continuationRequest" not in recipe:
        raise ValueError("budget ledger requires its bound continuation request")
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
        budget(step["budgetSeconds"], 3600 if policy is not None and policy["mode"] == "progress" else 600)
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
    if policy is not None:
        caps = [step["budgetSeconds"] for step in ordered]
        recipe["budgetSeconds"] = (max(caps) if policy["mode"] == "progress" else sum(caps)) + policy["overheadSeconds"]
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


class FingerprintPlan:
    """Prepare path metadata once; read every bound byte at every checkpoint."""

    __slots__ = ("entries",)

    def __init__(self, expected):
        self.entries = tuple((Path(name), sha) for name, sha in expected.items())

    def matches(self):
        stable = True
        for path, expected in self.entries:
            # Do not short-circuit: a mismatch must not skip other bound files.
            stable = (digest(path) == expected) and stable
        return stable


def tool_files(quint, node):
    quint, node = quint.resolve(strict=True), node.resolve(strict=True)
    package = next((parent for parent in quint.parents if (parent / "package.json").is_file()), None)
    if package is None or read_json(package / "package.json").get("name") != "@informalsystems/quint":
        raise ValueError("installed Quint package and explicit Node runtime required")
    return [node, quint, *(path for path in package.rglob("*") if path.is_file())]


_leased_tree_checks = ContextVar("leased_tree_checks", default=None)


def _tree_stamp(path):
    def stamp(state):
        return (state.st_dev, state.st_ino, state.st_mode, state.st_nlink,
                state.st_size, state.st_mtime_ns, state.st_ctime_ns)
    entries = []
    def visit(directory, prefix):
        with os.scandir(directory) as children:
            for child in children:
                name = prefix + child.name
                state = child.stat(follow_symlinks=False)
                entries.append((name, stamp(state)))
                if child.is_dir(follow_symlinks=False):
                    visit(child.path, name + "/")
    root_stamp = stamp(path.lstat())
    visit(path, "")
    return (root_stamp, tuple(sorted(entries, key=lambda row: tuple(row[0].split("/")))))


class LeasedTreeChecks:
    """Request-local reuse, with full hashing before reuse and at release."""
    def __init__(self):
        self.roots = {}
        self.checked = {}
        self.full_reads = self.reused = self.final_reads = 0

    def identity(self, path):
        self.check_root(path)
        before = _tree_stamp(path)
        previous = self.checked.get(path)
        if previous is not None and before == previous[0]:
            self.reused += 1
            return deepcopy(previous[1])
        result = _tree_identity_uncached(path)
        self.full_reads += 1
        if before != _tree_stamp(path):
            raise ValueError("leased tree changed during hashing")
        self.checked[path] = (before, deepcopy(result))
        return result

    def check_root(self, path):
        state = path.lstat()
        if path.is_symlink() or (state.st_dev, state.st_ino) != self.roots[path]:
            raise ValueError("workspace replaced while leased")

    def verify(self):
        for path, (stamp, expected) in self.checked.items():
            self.check_root(path)
            actual = _tree_identity_uncached(path)
            self.final_reads += 1
            if actual != expected or _tree_stamp(path) != stamp:
                raise ValueError("leased tree changed before final verification")


def tree_identity(path, *, broken_links=None):
    path = Path(path)
    checks = _leased_tree_checks.get()
    if checks is not None and broken_links is None and path in checks.roots:
        return checks.identity(path)
    return _tree_identity_uncached(path, broken_links=broken_links)


def _tree_identity_uncached(path, *, broken_links=None):
    """Bind exact tree inventory, modes and internal links, not just old files."""
    result = {}
    root = path.resolve(strict=True)
    for file in sorted(path.rglob("*")):
        name = file.relative_to(path).as_posix()
        if file.is_symlink():
            try:
                target = file.resolve(strict=True)
            except (OSError, RuntimeError) as error:
                if (broken_links is None or broken_links.get(name) != os.readlink(file)
                        or not file.resolve(strict=False).is_relative_to(root)):
                    raise ValueError("artifact tree has an unresolved symlink") from error
                result[name] = {"link": os.readlink(file), "unresolved": True}
                continue
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


def artifact_path(out, descriptor, *, root=None, _seen=None):
    """Resolve a managed workspace reference without filesystem aliases."""
    if "origin" in descriptor:
        if root is None:
            raise ValueError("retained artifact requires its repository custody")
        from gambit_smp.reasoning_history import read_execution_checkpoint
        from gambit_smp.step_checkpoint import content_id
        origin = descriptor["origin"]
        producer = relative(root, origin["run"])
        from gambit_smp.artifact_storage import observation_root
        observation_root(root, producer)
        key = (str(producer), origin["step"], origin["receipt"])
        seen = set() if _seen is None else set(_seen)
        if key in seen:
            raise ValueError("retained artifact provenance cycle")
        seen.add(key)
        rows = [entry["payload"]["step"] for entry in read_execution_checkpoint(root, producer)["records"]
                if entry["payload"].get("schema") == "research-step-observation.v1"
                and entry["payload"]["step"]["id"] == origin["step"]]
        if len(rows) != 1 or content_id(rows[0]) != origin["receipt"]:
            raise ValueError("retained artifact producer identity changed")
        original = rows[0].get("outputs", {}).get(origin["output"])
        if original is None or {k: v for k, v in descriptor.items() if k != "origin"} != {
                k: v for k, v in original.items() if k != "origin"}:
            raise ValueError("retained artifact does not match its committed output")
        return artifact_path(producer / "run", original, root=root, _seen=seen)
    path = relative(out, descriptor["path"])
    if "workspace" not in descriptor:
        return path
    if root is None or descriptor.get("type") not in {
            "source-tree", "configured-tree", "seed-runtime", "source-runtime"}:
        raise ValueError("managed workspace requires same-project source type")
    if digest(path) != descriptor.get("locationSha256"):
        raise ValueError("managed workspace location receipt drift")
    if read_json(path) != {"schema": "managed-workspace-location.v1", "workspace": descriptor["workspace"]}:
        raise ValueError("managed workspace location does not match output")
    literal = root / descriptor["workspace"]
    if literal.is_symlink():
        raise ValueError("managed workspace cannot be a symlink alias")
    workspace = relative(root, descriptor["workspace"])
    from gambit_smp.artifact_storage import fixture_root
    fixture_root(root, workspace)
    return workspace


class WorkspaceValidationScope:
    """One Recipe owns its locks; each capability still rechecks full SHA."""
    def __init__(self):
        self.leases = ExitStack()
        self.paths = set()
        self.checks = LeasedTreeChecks()
        self.closed = False

    def close(self):
        self.closed = True
        try:
            self.leases.close()
        finally:
            self.paths.clear()
            self.checks.roots.clear()
            self.checks.checked.clear()


class ExecutionContext:
    """One deadline and process recorder shared by every capability subcommand."""
    def __init__(self, root, out, directory, environment, deadline, outcomes, receipt, tools, *, workspace_scope=None):
        if workspace_scope is not None and workspace_scope.closed:
            raise ValueError("closed workspace validation scope")
        self.workspace_scope = workspace_scope
        self.root, self.out, self.directory = root, out, directory
        self.env, self.deadline = dict(environment), deadline
        self.outcomes, self.receipt, self.tools = outcomes, receipt, tools
        self.commands = []
        self.progress_mode = receipt.get("timeoutPolicy", {}).get("mode") == "progress"
        self.idle_window = deadline - time.monotonic()
        self.progress_lock = Lock()
        self.extra_inputs = {}
        self.last_stdout = None
        self.workspace_leases = ExitStack()
        self.lease_stack = workspace_scope.leases if workspace_scope is not None else self.workspace_leases
        self.leased_workspaces = workspace_scope.paths if workspace_scope is not None else set()
        self.leased_tree_checks = workspace_scope.checks if workspace_scope is not None else LeasedTreeChecks()
        self.lease_check_token = None
        if self.leased_workspaces:
            self.activate_lease_checks()

    def activate_lease_checks(self):
        if self.lease_check_token is None:
            self.lease_check_token = _leased_tree_checks.set(self.leased_tree_checks)
            self.workspace_leases.callback(_leased_tree_checks.reset, self.lease_check_token)

    def lease_workspace(self, path, expected_identity):
        if self.workspace_scope is not None and self.workspace_scope.closed:
            raise ValueError("closed workspace validation scope")
        from gambit_smp.artifact_storage import workspace_lease
        path = Path(path)
        if path.is_symlink():
            raise ValueError("workspace root cannot be a symlink")
        path = path.resolve(strict=True)
        if path in self.leased_workspaces:
            self.activate_lease_checks()
            if tree_identity(path) != expected_identity:
                raise ValueError("held workspace state differs from requested input")
            self.remaining()
            return path
        state = path.lstat()
        self.leased_tree_checks.roots[path] = (state.st_dev, state.st_ino)
        try:
            leased = self.lease_stack.enter_context(workspace_lease(self.root, path, expected_identity,
                identity_reader=self.leased_tree_checks.identity))
        except BaseException:
            self.leased_tree_checks.roots.pop(path, None)
            self.leased_tree_checks.checked.pop(path, None)
            raise
        self.leased_workspaces.add(leased)
        self.activate_lease_checks()
        self.remaining()
        return leased

    def reuse_workspace(self, reference, kind):
        path = self.artifact(reference, kind)
        step = next(row for row in self.receipt["steps"] if row["id"] == reference["step"])
        descriptor = step["outputs"][reference["output"]]
        leased = self.lease_workspace(path, descriptor["identity"])
        self.receipt.setdefault("workspaceReuse", []).append({
            "step": self.directory.name, "input": reference, "path": descriptor["path"],
            "claim": "exclusive-in-place-mutation-not-native-admission"})
        return leased

    def remaining(self):
        remaining = self.deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError("capability or whole recipe budget exhausted")
        return remaining

    def renew_progress(self):
        if self.progress_mode:
            with self.progress_lock:
                self.deadline = time.monotonic() + self.idle_window

    def run(self, name, argv, cwd, cap, *, diagnostic=None, progress=None):
        path = self.directory / (name + ".log")
        checkpoint = self.directory / (name + ".process.json")
        if path.exists() or checkpoint.exists():
            raise ValueError("unique subcommand log required")
        actual = cap if self.progress_mode else min(cap, self.remaining())
        request = dict(stage=name, argv=[str(arg) for arg in argv], cwd=str(cwd),
                       effectiveBudgetSeconds=actual, environment=dict(self.env))
        checkpoint.write_text(json.dumps({"schema": "recipe-process-observation.v1",
            "state": "STARTED", "completionObserved": False, "runtimeAdmitted": False,
            **request}, sort_keys=True, indent=2) + "\n")
        metadata = {}
        recorder = None
        if self.receipt.get("journal"):
            from gambit_smp.research_kernel import process_recorder
            recorder = process_recorder(self.root, self.out.parent, self.receipt["journal"], deadline=self.deadline)
        if "engine" in self.receipt:
            from gambit_smp.process_observation import capture
            completed = [0]

            def observe(stdout, stderr):
                count = progress(stdout, stderr)
                if count > completed[0]:
                    completed[0] = count
                    self.renew_progress()
                    target = self.directory / (name + ".progress.json")
                    pending = target.with_suffix(".pending")
                    pending.write_text(json.dumps({"schema": "native-completed-progress.v1", "completed": count}))
                    pending.replace(target)
                return count

            observation = capture([str(arg) for arg in argv], cwd, actual, self.env,
                                  **({"recorder": recorder} if recorder else {}),
                                  **({"diagnostic": diagnostic} if diagnostic is not None else {}),
                                  **({"progress": observe} if self.progress_mode and progress is not None else {}))
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
                            processGroupProbes=list(observation.group_probes),
                            logOrdering="stdout-then-stderr; streams preserved separately")
        else:
            code, log, timeout, seconds = execute([str(arg) for arg in argv], cwd, actual,
                                                env=self.env, metadata=metadata,
                                                **({"process_recorder": recorder} if recorder else {}))
            self.last_stdout = log
        path.write_text(log)
        record = dict(**request, exit=code, timeout=timeout, seconds=seconds,
                      log=path.name, logSha256=digest(path), **metadata)
        pending = checkpoint.with_suffix(".pending")
        with pending.open("x") as stream:
            json.dump({"schema": "recipe-process-observation.v1", "state": "OBSERVED",
                       "completionObserved": True, "runtimeAdmitted": False, **record},
                      stream, sort_keys=True, indent=2)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        pending.replace(checkpoint)
        self.commands.append(record)
        self.renew_progress()
        return code, log, timeout, seconds

    def require(self, name, argv, cwd, cap, *, diagnostic=None, progress=None):
        code, log, timeout, _ = self.run(name, argv, cwd, cap,
                                       **({"diagnostic": diagnostic} if diagnostic is not None else {}),
                                       **({"progress": progress} if progress is not None else {}))
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
        path = artifact_path(self.out, descriptor, root=self.root)
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
        descriptor = {"type": kind}
        if not path.is_relative_to(self.out):
            if self.receipt.get("workspacePolicy") != "in-place" or path.resolve() not in self.leased_workspaces:
                raise ValueError("external workspace publication requires exclusive managed lease")
            descriptor["workspace"] = path.relative_to(self.root).as_posix()
            location = self.directory / (name + "-workspace.json")
            with location.open("x") as stream:
                json.dump({"schema": "managed-workspace-location.v1", "workspace": descriptor["workspace"]}, stream)
                stream.write("\n")
            descriptor.update(path=location.relative_to(self.out).as_posix(), locationSha256=digest(location))
        else:
            descriptor["path"] = path.relative_to(self.out).as_posix()
        if path.is_dir():
            descriptor["identity"] = tree_identity(path)
            if (self.receipt.get("workspacePolicy") == "in-place" and
                    kind in {"source-tree", "configured-tree", "seed-runtime", "source-runtime"}):
                from gambit_smp.artifact_storage import cache_path, seal_workspace_state
                bindings = {Path(key).relative_to(self.root).as_posix(): sha
                            for key, sha in self.receipt["inputs"].items()
                            if Path(key).is_relative_to(self.root)
                            and not any(part.casefold() in CACHE_PARTS for part in Path(key).relative_to(self.root).parts)}
                run_key = hashlib.sha256(self.out.relative_to(self.root).as_posix().encode()).hexdigest()
                target = (cache_path(self.root, "research/workspace-states") /
                          self.receipt["recipe"] / run_key / (self.directory.name + "-" + name + ".json"))
                descriptor["stateEvidence"] = seal_workspace_state(self.root, path, target, bindings)
        else:
            descriptor["sha256"] = digest(path)
            descriptor["mode"] = path.stat().st_mode & 0o777
        return {name: descriptor}


AUTHORIZATION_ERROR = "native execution requires host --allow-native and --gcc"


def authorization_preflight(receipt):
    return (receipt.get("outcome") == "DENY" and receipt.get("steps") == []
            and receipt.get("error") == AUTHORIZATION_ERROR)


def prior_tool_observation(out, receipt):
    descriptor = receipt.get("toolInputs")
    if descriptor is None:
        if not authorization_preflight(receipt):
            raise ValueError("missing prior tool observation outside authorization preflight")
        return None
    path = relative(out, descriptor["path"])
    if digest(path) != descriptor["sha256"]:
        raise ValueError("prior tool observation was changed")
    return read_json(path)


def authorization_repair(receipt, allow_native, gcc):
    config = receipt.get("executionConfig", {})
    return (authorization_preflight(receipt) and allow_native is True and gcc is not None
            and config.get("allowNative", False) is False)


def inspect_outputs(out, steps, *, root=None, input_bindings=None):
    """Inspect disposable output availability separately from evidence binding."""
    rows = []
    for index, step in enumerate(steps):
        for name, descriptor in step.get("outputs", {}).items():
            try:
                path = artifact_path(out, descriptor, root=root)
                if not path.exists():
                    state = "MISSING"
                elif "identity" in descriptor:
                    state = "AVAILABLE" if tree_identity(path) == descriptor["identity"] else "MODIFIED"
                else:
                    matches = (digest(path) == descriptor["sha256"] and
                               path.stat().st_mode & 0o777 == descriptor.get("mode", path.stat().st_mode & 0o777))
                    state = "AVAILABLE" if matches else "MODIFIED"
                if "stateEvidence" in descriptor and root is not None:
                    from gambit_smp.artifact_storage import checked_workspace_state
                    checked_workspace_state(root, descriptor["stateEvidence"], descriptor["identity"],
                                            input_bindings=input_bindings)
                    successors = [item for later in steps[index + 1:] if later.get("outcome") == "PASS"
                                  for item in later.get("outputs", {}).values()
                                  if item.get("workspace", item.get("path")) == descriptor.get("workspace", descriptor["path"])
                                  and "stateEvidence" in item]
                    if state == "MODIFIED" and any(
                            tree_identity(path) == successor.get("identity") for successor in successors):
                        state = "RETAINED"
            except (KeyError, TypeError, ValueError, OSError):
                state = "UNKNOWN"
            rows.append({"step": step["id"], "output": name, "status": state})
    states = {row["status"] for row in rows}
    status = next((state for state in ("UNKNOWN", "MODIFIED", "MISSING") if state in states), "AVAILABLE")
    if status == "AVAILABLE" and "RETAINED" in states:
        status = "RETAINED"
    return {"status": status, "outputs": rows}


def inspect_run(out, *, input_bindings=None):
    """Recheck stored bytes, never import a historical observation as permission."""
    receipt = read_json(out / "receipt.json")
    if receipt.get("schema") != "evidence-recipe-run.v1":
        raise ValueError("recipe run receipt required")
    workspace_root = None
    if receipt.get("workspacePolicy") == "in-place" or any(
            "origin" in output for step in receipt["steps"] for output in step.get("outputs", {}).values()):
        from gambit_smp.artifact_storage import repository_root
        workspace_root = repository_root(out)
    try:
        from gambit_smp.historical_inputs import match
        stable = match(receipt["inputs"], input_bindings or {})
        tools = prior_tool_observation(out, receipt)
        stable = stable and (tools is None or fingerprints(Path(name) for name in tools) == tools)
        if "evaluationOwner" in receipt:
            owner_path = relative(out, receipt["evaluationOwner"]["path"])
            stable = stable and digest(owner_path) == receipt["evaluationOwner"]["sha256"]
            owner = read_json(owner_path)
            if receipt["outcome"] == "PASS":
                stable = stable and (owner["exit"] == 0 and owner["parentReaped"] is True
                    and owner["forcedTermination"] is False and owner["terminalIdentityError"] is None
                    and owner["engineId"] == receipt["engine"]["engineId"]
                    and all(row["requestCompleted"] and not row["timeout"] for row in owner["requests"]))
        for step in receipt["steps"]:
            for descriptor in step.get("outputs", {}).values():
                if "stateEvidence" in descriptor:
                    if workspace_root is None:
                        raise ValueError("retained workspace requires same-project root")
                    from gambit_smp.artifact_storage import checked_workspace_state
                    checked_workspace_state(workspace_root, descriptor["stateEvidence"], descriptor["identity"],
                                            input_bindings=input_bindings)
            for name, sha in step.get("artifacts", {}).items():
                stable = stable and digest(relative(out, name)) == sha
            stable = stable and match(step.get("observedInputs", {}), input_bindings or {})
    except (KeyError, TypeError, ValueError, OSError):
        stable = False
    binding_status = ("HISTORICAL_BOUND" if input_bindings else "CURRENT") if stable else "STALE"
    availability = inspect_outputs(out, receipt["steps"], root=workspace_root, input_bindings=input_bindings)
    stable = stable and availability["status"] in {"AVAILABLE", "RETAINED"}
    return {"recipe": receipt["recipe"], "outcome": receipt["outcome"],
            "identityStatus": ("HISTORICAL_BOUND" if input_bindings else "CURRENT") if stable else "STALE", "steps": receipt["steps"],
            "evidenceBindingStatus": binding_status, "artifactAvailability": availability,
            "recordedOutcome": receipt["outcome"],
            "runtimeAdmitted": False, "releaseAdmitted": False, "executionAuthorized": False}


def run(root, path, out, quint, node, prior=None, *, gcc=None, allow_native=False, engine=None, deadline=None, journal=None,
        budget_reservation=None, resume_prefix=None):
    from gambit_smp import host_environment
    recipe, steps = load(root, path)
    progress_mode = recipe.get("timeoutPolicy", {}).get("mode") == "progress"
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
               "plannedSteps": steps,
               "runtimeAdmitted": False, "releaseAdmitted": False, "executionAuthorized": False}
    receipt["executionConfig"] = {"allowNative": allow_native, "gcc": str(gcc) if gcc is not None else None}
    receipt["workspacePolicy"] = recipe.get("workspacePolicy", "isolated")
    if journal is not None:
        receipt["journal"] = journal
    if "timeoutPolicy" in recipe:
        receipt["timeoutPolicy"] = recipe["timeoutPolicy"]
    if "continuationRequest" in recipe:
        from gambit_smp.recipe_continuation import check_reservation, revalidate_continuation_request
        request = read_json(source_path(root, recipe["continuationRequest"]))
        continuation = revalidate_continuation_request(root, request)
        if (continuation["recipe"] != path.relative_to(root).as_posix()
                or continuation["requestedSeconds"] != recipe["budgetSeconds"]):
            raise ValueError("continuation request identifies a different recipe or cap")
        materialized = [step for step in steps if step["capability"] == "gambit.materialize"]
        if not materialized or any(step["arguments"]["sourceLock"] != continuation["sourceLock"] for step in materialized):
            raise ValueError("continuation source differs from materialization plan")
        receipt["continuation"] = continuation
        if budget_reservation is None or budget_reservation["ledger"] != read_json(source_path(root, recipe["continuationLedger"])):
            raise ValueError("continuation needs its exact parent budget reservation")
        check_reservation(root, budget_reservation, continuation)
        receipt["budgetReservation"] = budget_reservation
    receipt["hostEnvironment"] = host_environment.observe(steps)
    if engine_identity is not None:
        receipt["engine"] = {"path": str(engine), "engineId": engine_identity["engineId"]}
    uses_quint = any(step["capability"].startswith("quint.") for step in steps)
    uses_native = any(CAPABILITIES[step["capability"]].executor is not None for step in steps)
    environment = host_environment.execution_environment(root, os.environ)
    if uses_quint:
        environment["PATH"] = os.pathsep.join((str(node.parent), "/usr/bin", "/bin"))
    receipt["environment"] = environment
    tools = {}
    input_plan = tool_plan = None
    journal_steps = {}

    def retain_step(result):
        if journal is None:
            return
        from gambit_smp.research_kernel import retain_run_record
        header_path = Path(journal["path"])
        if digest(header_path) != journal["sha256"]:
            raise ValueError("run header changed before step observation")
        header = read_json(header_path)
        if header["engineId"] != engine_identity["engineId"] or header["recipe"] != recipe["id"]:
            raise ValueError("run header identifies another producer")
        record = {"schema": "research-step-observation.v1", "runId": header["runId"],
                  "header": journal, "step": result,
                  "toolInputs": dict(tools),
                  "dependencies": {name: journal_steps.get(name) for name in result["dependsOn"]},
                  "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
        from gambit_smp.step_checkpoint import support_inventory
        record["supportInventory"] = support_inventory(root, header, result, tools, inputs)
        if record["supportInventory"] is None:
            raise ValueError("source-bound declaration inventory required before stage publication")
        saved = retain_run_record(root, out / (result["id"] + ".observation.json"),
                                  journal["scope"], record, inputs)
        journal_steps[result["id"]] = saved
        result["journal"] = saved
    workspace_scope = WorkspaceValidationScope()
    try:
        paths = tool_files(quint, node) if uses_quint else []
        receipt["tools"] = {"quint": str(quint.resolve()), "node": str(node.resolve())} if uses_quint else {}
        if uses_native:
            if not allow_native or gcc is None:
                raise ValueError(AUTHORIZATION_ERROR)
            from gambit_smp.native_capabilities import host_tools, implementation_files
            native_tools, environment = host_tools(gcc, steps, environment)
            paths.extend(native_tools.values())
            receipt["tools"].update({name: str(value) for name, value in native_tools.items()})
            inputs.update(fingerprints(implementation_files(steps)))
            receipt["environment"] = environment
        tools = fingerprints(paths)
        input_plan, tool_plan = FingerprintPlan(inputs), FingerprintPlan(tools)
        (out / "tools.json").write_text(json.dumps(tools, sort_keys=True, indent=2) + "\n")
        receipt["toolInputs"] = {"path": "tools.json", "sha256": digest(out / "tools.json"), "count": len(tools)}
        if receipt["hostEnvironment"] is not None and receipt["hostEnvironment"]["available"] is not True:
            raise ValueError(host_environment.ERROR)
        retained = {}
        if prior is not None and journal is not None:
            from gambit_smp.reasoning_history import read_execution_checkpoint
            from gambit_smp.step_checkpoint import recovered_resumption, content_id
            prefix = read_execution_checkpoint(root, prior.parent)
            if prefix["records"]:
                state = recovered_resumption(root, prior.parent)
                if resume_prefix is not None and state["resumption"]["prefixIdentity"] != resume_prefix:
                    raise ValueError("resumption prefix changed before consumption")
                eligible = set(state["resumption"]["relations"]["consumable"])
                retained = {entry["payload"]["step"]["id"]: entry["payload"]["step"]
                            for entry in prefix["records"]
                            if entry["payload"].get("schema") == "research-step-observation.v1"
                            and (entry["payload"]["step"]["id"], content_id(entry["payload"]["step"])) in eligible}
                receipt["checkpointConsumption"] = {"run": str(prior.parent.relative_to(root)),
                    "prefixIdentity": state["resumption"]["prefixIdentity"], "reusedSteps": []}
        if prior is not None and resume_prefix is None:
            previous = read_json(prior / "receipt.json")
            if previous.get("schema") != "evidence-recipe-run.v1" or previous.get("recipe") != recipe["id"]:
                raise ValueError("prior observation must identify this recipe")
            previous_tools = prior_tool_observation(prior, previous)
            delta = {name: sha for name, sha in inputs.items() if previous["inputs"].get(name) != sha}
            tool_delta = ({name: sha for name, sha in tools.items() if previous_tools.get(name) != sha}
                          if previous_tools is not None else {})
            repaired_authorization = authorization_repair(previous, allow_native, gcc)
            repaired_environment = host_environment.repaired(previous, receipt["hostEnvironment"], fresh_attempt=True)
            previous_budgets = {step["id"]: step["budgetSeconds"] for step in previous["steps"]}
            previous_arguments = {step["id"]: step.get("arguments", {}) for step in previous["steps"]}
            if ("timeoutPolicy" not in recipe and recipe["budgetSeconds"] > previous["budgetSeconds"]) or any(
                    step["id"] in previous_budgets and (step["budgetSeconds"] > previous_budgets[step["id"]]
                        or ("batchBudgetSeconds" in previous_arguments[step["id"]]
                            and step["arguments"].get("batchBudgetSeconds", 0) > previous_arguments[step["id"]]["batchBudgetSeconds"]))
                    for step in steps):
                raise ValueError("prior failure cannot be retried by expanding a budget")
            if (previous["outcome"] != "PASS" and not delta and not tool_delta
                    and not repaired_authorization and not repaired_environment):
                raise ValueError("unchanged failed recipe; no causal input/tool delta")
            receipt["prior"] = {"receiptSha256": digest(prior / "receipt.json"),
                                "changedInputs": delta, "changedTools": tool_delta,
                                "toolObservation": "absent-preflight" if previous_tools is None else "observed",
                                "authorizationRepaired": repaired_authorization,
                                "environmentRepaired": repaired_environment}
            if repaired_environment:
                receipt["prior"]["environmentPriorExpenditure"] = {
                    "budgetSeconds": previous["budgetSeconds"], "wholeSeconds": previous["wholeSeconds"],
                    "freshAttempt": True, "deadlineResumed": False}
        outcomes = {}
        for step in steps:
            stage_started = time.monotonic()
            if "continuation" in receipt:
                from gambit_smp.recipe_continuation import check_reservation
                check_reservation(root, receipt["budgetReservation"], receipt["continuation"])
            result = {"id": step["id"], "capability": step["capability"], "budgetSeconds": step["budgetSeconds"],
                      "dependsOn": step["dependsOn"],
                      "arguments": step["arguments"]}
            receipt["steps"].append(result)
            previous = retained.get(step["id"])
            if previous is not None and any(previous.get(key) != step.get(key)
                    for key in ("capability", "arguments", "dependsOn", "budgetSeconds")):
                previous = None
            if previous is not None and all(dependency in receipt["checkpointConsumption"]["reusedSteps"]
                                             for dependency in step["dependsOn"]):
                from gambit_smp.step_checkpoint import content_id
                if not (input_plan.matches() and tool_plan.matches()):
                    raise ValueError("input changed before checkpoint consumption")
                origin = {"run": str(prior.parent.relative_to(root)), "step": step["id"], "receipt": content_id(previous)}
                carried = {key: value for key, value in previous.items() if key not in {
                    *result, "outputs", "commands", "artifacts", "journal", "stageSeconds", "executionLaunched", "reused"}}
                result.update(carried)
                result.update(outcome="PASS", outputs={name: dict(value, origin=dict(origin, output=name))
                    for name, value in previous.get("outputs", {}).items()},
                    reused=origin, originStageSeconds=previous.get("stageSeconds"), executionLaunched=False,
                    originCommands=previous.get("commands", []), originArtifacts=previous.get("artifacts", {}))
                for descriptor in result["outputs"].values():
                    artifact_path(out, descriptor, root=root)
                receipt["checkpointConsumption"]["reusedSteps"].append(step["id"])
            elif step["capability"] != "evidence.evaluate" and any(outcomes[dependency] != "PASS" for dependency in step["dependsOn"]):
                result["outcome"] = "BLOCKED"
            elif not (input_plan.matches() and tool_plan.matches()):
                result.update(outcome="STALE", reason="input changed before capability execution")
            else:
                directory = out / step["id"]
                directory.mkdir()
                capability = CAPABILITIES[step["capability"]]
                if capability.executor is not None:
                    context = ExecutionContext(root, out, directory, environment,
                                               time.monotonic() + step["budgetSeconds"] if progress_mode else
                                               min(deadline, time.monotonic() + step["budgetSeconds"]),
                                               outcomes, receipt, receipt["tools"], workspace_scope=workspace_scope)
                    context.planned_steps = tuple(steps)
                    try:
                        result.update(capability.executor(step["arguments"], context))
                        context.remaining()
                        if any(row["exit"] != row.get("expectedExit", 0) or row["timeout"] for row in context.commands):
                            raise ValueError("native subcommand did not complete successfully")
                        if any(row.get("processGroupQuiescent") is False for row in context.commands):
                            raise ValueError("native child process group is not quiescent")
                        if fingerprints(Path(name) for name in context.extra_inputs) != context.extra_inputs:
                            raise ValueError("native observed input drift")
                        context.leased_tree_checks.verify()
                        context.remaining()
                        result["outcome"] = "PASS"
                    except TimeoutError as error:
                        result.update(outcome="TIMEOUT", reason=str(error))
                    except Exception as error:
                        import traceback
                        result.update(outcome="DENY", reason=str(error), errorType=type(error).__name__)
                        (directory / "capability-error.log").write_text(traceback.format_exc())
                    finally:
                        if any(row.get("processGroupQuiescent") is False for row in context.commands):
                            from gambit_smp.artifact_storage import quarantine_workspace
                            for workspace in context.leased_workspaces:
                                quarantine_workspace(root, workspace, context.commands)
                        context.workspace_leases.close()
                    result.update(commands=context.commands, observedInputs=context.extra_inputs)
                    if any(row["timeout"] for row in context.commands):
                        result["outcome"] = "TIMEOUT"
                    mutable_trees = [artifact_path(out, descriptor, root=root) for descriptor in result.get("outputs", {}).values()
                                     if "stateEvidence" in descriptor]
                    result["artifacts"] = {file.relative_to(out).as_posix(): digest(file)
                                           for file in sorted(directory.rglob("*")) if file.is_file() and not file.is_symlink()
                                           and not any(file.is_relative_to(tree) for tree in mutable_trees)}
                    outcomes[step["id"]] = result["outcome"]
                    result["stageSeconds"] = time.monotonic() - stage_started
                    (directory / "step-receipt.json").write_text(json.dumps(result, sort_keys=True, indent=2) + "\n")
                    retain_step(result)
                    continue
                argv = [str(node.resolve()), str(quint.resolve()), *capability.command(step["arguments"], directory)]
                remaining = step["budgetSeconds"] if progress_mode else deadline - time.monotonic()
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
                                inventory = quint_test_inventory(ir, step["arguments"]["main"])
                                if inventory != sorted(step["arguments"]["expectedTests"]):
                                    raise ValueError("test inventory differs from the parsed main module")
                        except (KeyError, TypeError, ValueError, OSError) as error:
                            result.update(outcome="DENY", reason=str(error))
                result["artifacts"] = {file.relative_to(out).as_posix(): digest(file) for file in sorted(directory.iterdir()) if file.is_file()}
            outcomes[step["id"]] = result["outcome"]
            result["stageSeconds"] = time.monotonic() - stage_started
            retain_step(result)
    except (KeyError, TypeError, ValueError, OSError) as error:
        receipt["error"] = str(error)
    finally:
        workspace_scope.close()
    finalization_started = time.monotonic()
    try:
        stable = ((input_plan or FingerprintPlan(inputs)).matches()
                  and (tool_plan or FingerprintPlan(tools)).matches())
        for step in receipt["steps"]:
            stable = stable and fingerprints(Path(name) for name in step.get("observedInputs", {})) == step.get("observedInputs", {})
            for name, sha in step.get("artifacts", {}).items():
                stable = stable and digest(relative(out, name)) == sha
        # In-place successors supersede sealed intermediate inventories, not evidence.
        availability = inspect_outputs(out, receipt["steps"], root=root)
        stable = stable and availability["status"] in {"AVAILABLE", "RETAINED"}
    except (OSError, ValueError):
        stable = False
    receipt["inputsStable"] = stable
    receipt["finalizationCheckSeconds"] = time.monotonic() - finalization_started
    passed = len(receipt["steps"]) == len(steps) and all(step["outcome"] == "PASS" for step in receipt["steps"])
    receipt["wholeBudgetExhausted"] = not progress_mode and time.monotonic() > deadline
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
    from gambit_smp.artifact_storage import runtime_argument
    parser.add_argument("--out", type=runtime_argument)
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
