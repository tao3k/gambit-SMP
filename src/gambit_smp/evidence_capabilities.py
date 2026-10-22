"""Project observed execution facts; the installed ASCENT engine evaluates rules."""
import json
from pathlib import Path
import sys
from contextlib import contextmanager, nullcontext
import os
import selectors
import subprocess
import time
import traceback
import hashlib

_evaluation_owner = None


def archive_bytes(directory, name, original, expected):
    """Capture original bytes separately; never retarget their source identity."""
    raw = original.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected:
        raise ValueError("observation archive source identity changed")
    target = directory / name
    with target.open("xb") as stream:
        stream.write(raw)
    target.chmod(0o444)
    return {"originalPath": str(original), "sha256": expected, "archivePath": str(target)}


class EvaluationOwner:
    """One sealed ABI process; request completion is not process completion."""
    def __init__(self, engine, directory, deadline):
        self.engine, self.directory, self.deadline = engine.resolve(), directory, deadline
        self.process = None
        self.records = []
        self.closed = False
        self.log = None
        self.receipt = None
        self.engine_id = None
        self.manifest = None
        self.manifest_sha = None

    def policy_identity(self):
        """Bind metadata; completed requests still require full child checks."""
        from gambit_smp.framework import digest
        from gambit_smp.research_kernel import execution_identity, execution_origin
        if self.closed:
            raise ValueError("evaluation owner is closed")
        execution_origin(self.engine)
        if self.manifest is None:
            before = digest(self.engine / "engine.json")
            manifest = execution_identity(self.engine)
            if digest(self.engine / "engine.json") != before:
                raise ValueError("evaluation manifest changed during validation")
            self.manifest, self.manifest_sha = manifest, before
            self.engine_id = manifest["engineId"]
        elif digest(self.engine / "engine.json") != self.manifest_sha:
            raise ValueError("evaluation manifest changed")
        return self.manifest

    def evaluate(self, request_path, cap, *, progress_deadline=None):
        from gambit_smp.framework import digest
        from gambit_smp.research_kernel import execution_identity, execution_origin
        if self.closed:
            raise ValueError("evaluation owner is closed")
        started = time.monotonic()
        # Progress-mode stages own renewed inactivity deadlines, not the
        # owner's original total-wall deadline. The request cap is unchanged.
        deadline = self.deadline if progress_deadline is None else progress_deadline
        ceiling = min(cap, deadline - started)
        if ceiling <= 0:
            raise TimeoutError("evaluation deadline exhausted")
        if progress_deadline is not None:
            self.deadline = max(self.deadline, progress_deadline)
        execution_origin(self.engine)
        request_sha = digest(request_path)
        if self.process is None:
            from gambit_smp.task_processes import spawn as _task_spawn
            self.policy_identity()
            self.directory.mkdir(parents=True, exist_ok=False)
            self.log = (self.directory / "stderr.log").open("wb")
            argv = [sys.executable, "-I", "-B", str(self.engine / "python/gambit_smp/evidence_capabilities.py")]
            environment = {"PATH": "/usr/bin:/bin", "HOME": os.environ.get("HOME", "/tmp"),
                           "PYTHONDONTWRITEBYTECODE": "1"}
            from gambit_smp.ascent_program import construction_slot
            slot = construction_slot()
            if slot is not None:
                environment.update(GAMBIT_SMP_SESSION_CONSTRUCTION_LOCK=str(slot[0]),
                                   GAMBIT_SMP_SESSION_CONSTRUCTION_DEADLINE=str(slot[1]))
            self.process = _task_spawn(argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                            stderr=self.log, env=environment)
            self.argv = argv
        row = {"request": str(request_path), "requestSha256": request_sha,
               "budgetSeconds": ceiling, "requestCompleted": False, "timeout": False}
        self.records.append(row)
        try:
            archive = self.directory / "requests" / str(len(self.records) - 1)
            archive.mkdir(parents=True, exist_ok=False)
            row["requestArchive"] = archive_bytes(archive, "request.json", request_path, request_sha)
            request = json.loads(request_path.read_bytes())
            row["sourceArchives"] = [archive_bytes(archive, "input-" + str(index), Path(path), sha)
                                     for index, (path, sha) in enumerate(sorted(request.get("observationInputs", {}).items()))]
            if time.monotonic() >= started + ceiling:
                row["timeout"] = True
                raise TimeoutError("sealed evaluation preparation exceeded request budget")
            self.process.stdin.write((json.dumps({"path": str(request_path), "sha256": request_sha}) + "\n").encode())
            self.process.stdin.flush()
            with selectors.DefaultSelector() as selector:
                selector.register(self.process.stdout, selectors.EVENT_READ)
                raw = b""
                while b"\n" not in raw:
                    if not selector.select(max(0, started + ceiling - time.monotonic())):
                        row["timeout"] = True
                        raise TimeoutError("sealed evaluation request timed out")
                    block = os.read(self.process.stdout.fileno(), 4096)
                    if not block:
                        raise ValueError("sealed evaluation process exited before its response")
                    raw += block
            response_path = request_path.parent / "evaluation-response.jsonl"
            with response_path.open("xb") as stream:
                stream.write(raw)
            row["responseSha256"] = digest(response_path)
            row["responseArchive"] = archive_bytes(archive, "response.jsonl", response_path, row["responseSha256"])
            response = json.loads(raw)
            row["response"] = response
            if (response.get("requestSha256") != request_sha or digest(request_path) != request_sha
                    or response.get("engineId") != self.engine_id):
                raise ValueError("sealed evaluation response identity mismatch")
            if response.get("outcome") != "PASS":
                raise ValueError("sealed evaluation failed: " + response.get("error", "unknown"))
            metadata_path = request_path.parent / "native-engine.json"
            row["metadataArchive"] = archive_bytes(archive, "native-engine.json", metadata_path, digest(metadata_path))
            sources = json.loads(metadata_path.read_bytes())["ruleSourceInputs"]
            captured = {item["originalPath"]: item["sha256"] for item in row["sourceArchives"]}
            for path, sha in sorted(sources.items()):
                if path in captured and captured[path] != sha:
                    raise ValueError("observed rule bytes differ from the original archive")
                if path not in captured:
                    row["sourceArchives"].append(archive_bytes(archive, "rule-" + str(len(row["sourceArchives"])), Path(path), sha))
            execution_origin(self.engine)
            if time.monotonic() > started + ceiling:
                row["timeout"] = True
                raise TimeoutError("sealed evaluation exceeded request budget")
            row["requestCompleted"] = True
        except BaseException:
            row["seconds"] = time.monotonic() - started
            self.close()
            raise
        finally:
            row["seconds"] = time.monotonic() - started
            target = request_path.parent / "request-observation.json"
            with target.open("x") as stream:
                json.dump({"schema": "sealed-evaluation-request.v1", "processExit": None,
                           "runtimeAdmitted": False, **row}, stream, indent=2)

    def close(self):
        from gambit_smp.framework import digest
        from gambit_smp.research_kernel import execution_identity
        if self.closed:
            return self.receipt
        self.closed = True
        if self.process is None:
            return None
        started = time.monotonic()
        forced = False
        try:
            from gambit_smp.ascent_program import construction_admission, construction_slot
            admission = (construction_admission(deadline=self.deadline) if construction_slot() is not None
                         and all(row["requestCompleted"] for row in self.records) else nullcontext())
            with admission:
                # Completed owners finalize one at a time; unfinished native
                # requests must not wait on a permit they may themselves hold.
                self.process.stdin.close()
                self.process.wait(timeout=max(.001, self.deadline - time.monotonic()))
        except (subprocess.TimeoutExpired, TimeoutError):
            forced = True
            if not self.process.stdin.closed:
                self.process.stdin.close()
            self.process.kill()
            self.process.wait()
        self.process.stdout.close()
        self.log.close()
        identity_error = None
        try:
            if execution_identity(self.engine)["engineId"] != self.engine_id:
                raise ValueError("evaluation owner seal identity changed")
        except Exception as error:
            identity_error = str(error)
        self.receipt = {"schema": "sealed-evaluation-owner.v1", "engine": str(self.engine),
                        "argv": self.argv, "pid": self.process.pid, "exit": self.process.returncode,
                        "forcedTermination": forced, "parentReaped": True,
                        "teardownSeconds": time.monotonic() - started, "requests": self.records,
                        "stderrSha256": digest(self.directory / "stderr.log"),
                        "engineId": self.engine_id, "terminalIdentityError": identity_error,
                        "terminalIdentityAuthority": "reaped-owner-full-byte-check",
                        "requestIdentityAuthority": "sealed-child-full-before-and-after"}
        with (self.directory / "receipt.json").open("x") as stream:
            json.dump(self.receipt, stream, indent=2)
        if identity_error is not None:
            raise ValueError(identity_error)
        return self.receipt


@contextmanager
def evaluation_owner(engine, directory, deadline):
    global _evaluation_owner
    if _evaluation_owner is not None:
        raise ValueError("evaluation owners cannot be nested")
    owner = EvaluationOwner(engine, directory, deadline)
    _evaluation_owner = owner
    try:
        yield owner
    finally:
        _evaluation_owner = None
        owner.close()


def review_policy_identity(engine):
    """No admission: every review must finish its checked native request."""
    from gambit_smp.research_kernel import manifest_paths
    if _evaluation_owner is None:
        return manifest_paths(engine)
    if Path(engine).resolve() != _evaluation_owner.engine:
        raise ValueError("review selected another evaluation seal")
    return _evaluation_owner.policy_identity()


def validate(args, inputs):
    from gambit_smp.recipes import fields
    entries = set(args) & {"dsl", "rules"}
    if len(entries) != 1:
        raise ValueError("exactly one Evidence entry required")
    entry = next(iter(entries))
    fields(args, (entry, "queries", "expected"), ("recordedQueries", "observationBinding", "rulesContract"))
    if "rulesContract" in args:
        from gambit_smp.ascent_program import INERT_RULE_CONTRACT
        if entry != "rules" or args["rulesContract"] != INERT_RULE_CONTRACT:
            raise ValueError("explicit inert rule contract requires the rules entry")
    if "observationBinding" in args:
        name = args["observationBinding"]
        if not isinstance(name, str) or name not in inputs or not name.endswith(".json"):
            raise ValueError("declared observation binding input required")
    if entry != "rules":
        if (not isinstance(args[entry], str) or args[entry] not in inputs
                or not args[entry].endswith(".json")):
            raise ValueError("declared Evidence JSON entry required")
    elif (not isinstance(args["rules"], list) or not args["rules"] or
          any(name not in inputs or not name.endswith(".ss") for name in args["rules"])):
        raise ValueError("declared native ASCENT rule sources required")
    recorded = args.get("recordedQueries", [])
    if (not isinstance(args["queries"], dict) or not args["queries"]
            or any(not isinstance(key, str) or not isinstance(value, str) for key, value in args["queries"].items())
            or not isinstance(recorded, list) or any(not isinstance(key, str) for key in recorded)
            or len(set(recorded)) != len(recorded) or not isinstance(args["expected"], dict)
            or set(recorded) & set(args["expected"])
            or set(args["expected"]) | set(recorded) != set(args["queries"])):
        raise ValueError("exact native query and result inventory required")
    for rows in args["expected"].values():
        if not isinstance(rows, list) or any(not isinstance(row, list) or
                any(type(value) not in (str, int, bool) for value in row) for row in rows):
            raise ValueError("typed expected relation rows required")


def graph(step, by_id, registry):
    previous = set(by_id) - {step["id"]}
    if set(step["dependsOn"]) != previous:
        raise ValueError("evidence evaluation must depend on the complete observation graph")


def facts(receipt):
    result = {name: [] for name in ("observed_step", "required_step", "step_dependency", "source_binding",
                                   "workspace_projection", "compiled_workspace", "tested_executable",
                                   "control_case", "native_process")}
    for step in receipt["steps"]:
        if step["capability"] == "evidence.evaluate":
            continue
        name, args = step["id"], step["arguments"]
        result["required_step"].append([name])
        result["observed_step"].append([name, step["outcome"], step["capability"]])
        result["step_dependency"].extend([name, parent] for parent in step["dependsOn"])
        storage = step.get('workspaceReuse')
        if isinstance(storage, dict) and 'sourceContentId' in storage:
            result.setdefault('runtime_storage_observation', []).append([
                name, storage['mode'], storage['sourceContentId'], storage['copiedFiles']])
        if step["outcome"] == "PASS":
            decision = step.get("producerDecisionSupersession")
            if decision is not None:
                result.setdefault("producer_decision_history", []).append([
                    name, decision["historicalReceiptSha256"], decision["recordedOutcome"]])
                result.setdefault("producer_decision_current", []).append([
                    name, decision["historicalReceiptSha256"], "PASS"])
                result.setdefault("producer_decision_supersedes", []).append([
                    name, decision["historicalReceiptSha256"],
                    decision["historicalDecision"], decision["currentDecision"]])
            if step["capability"] == "source.bind":
                result["source_binding"].append([name, args["workspace"]["step"]])
            if step["capability"] == "source.project":
                result["workspace_projection"].append([name, args["source"]["step"]])
            if step["capability"] == "native.workspace-build":
                result["compiled_workspace"].append([name, args["binding"]["step"]])
            if step["capability"] == "native.test":
                result["tested_executable"].append([name, args["executable"]["step"]])
                result["control_case"].extend([name, case, case in step.get("expectedFailureControls", [])]
                                              for case in step["passedCases"])
        result["native_process"].extend([name, row["stage"], row["exit"], row["timeout"]]
                                        for row in step.get("commands", []))
    return result


def evaluate(args, ctx):
    projected = facts(ctx.receipt)
    bindings = {}
    if "observationBinding" in args:
        from gambit_smp.observation_contract import bind_execution
        observed, bindings = bind_execution(ctx.root, args["observationBinding"], ctx.receipt["steps"])
        if not {Path(path).relative_to(ctx.root).as_posix() for path in bindings} <= set(ctx.receipt["declaredInputs"]):
            raise ValueError("observation contract must belong to the complete Recipe input inventory")
        ctx.bind([Path(path) for path in bindings])
        projected.update(observed)
    actual = evaluate_observations(ctx, args.get("rules", []), projected, args["queries"],
                                   "rule-evaluation", dsl=args.get("dsl"),
                                   rules_contract=args.get("rulesContract"))
    if any(not isinstance(actual[key], list) or
           sorted(actual[key], key=repr) != sorted(rows, key=repr) for key, rows in args["expected"].items()):
        raise ValueError("native ASCENT relation outcomes differ from the declared exact inventory")
    return {"claim": "native-rule-evaluation-of-local-observations-only", "answers": actual,
            "recordedOnlyQueries": args.get("recordedQueries", []), "observationInputs": bindings,
            "sourceRefinementAdmitted": False, "runtimeAdmitted": False}


def dsl_entry(value):
    from gambit_smp.recipes import fields
    components = value.get("schema") == "ascent.evidence-component-entry.v1"
    required = ("schema", "sources", "constructor", "arguments", "trusted")
    fields(value, required + (("manifest", "entry") if components else ()))
    if (value["schema"] not in ("ascent.evidence-dsl-entry.v1", "ascent.evidence-component-entry.v1") or value["trusted"] is not True
            or not isinstance(value["constructor"], str) or not 0 < len(value["constructor"]) < 129
            or not isinstance(value["arguments"], list) or not isinstance(value["sources"], list)
            or not value["sources"]):
        raise ValueError("typed trusted host Evidence DSL entry required")
    paths = set()
    inventory = value["sources"] + ([value["manifest"]] if components else [])
    if components and (not isinstance(value["entry"], str) or not 0 < len(value["entry"]) < 129):
        raise ValueError("Evidence component entry name required")
    for item in inventory:
        fields(item, ("path", "sha256"))
        path, sha = item["path"], item["sha256"]
        suffix = ".json" if components and item is value["manifest"] else ".ss"
        if (not isinstance(path, str) or not path.endswith(suffix) or Path(path).is_absolute()
                or ".." in Path(path).parts or path in paths
                or not isinstance(sha, str) or len(sha) != 64
                or any(char not in "0123456789abcdef" for char in sha)):
            raise ValueError("unique relative hash-bound DSL sources required")
        paths.add(path)
    return value


def dsl_sources(entry, root):
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path
    inventory = entry["sources"] + ([entry["manifest"]] if "manifest" in entry else [])
    paths = [source_path(root, item["path"]) for item in inventory]
    if any(digest(path) != item["sha256"] for path, item in zip(paths, inventory)):
        raise ValueError("Evidence DSL source changed before execution")
    return paths


def evaluate_observations(ctx, rules, projected, queries, label, *, dsl=None, rules_contract=None):
    if rules_contract is not None:
        from gambit_smp.ascent_program import INERT_RULE_CONTRACT
        if rules_contract != INERT_RULE_CONTRACT or not rules or dsl is not None:
            raise ValueError("explicit inert rule contract requires the rules entry")
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.research_kernel import execution_identity
    engine = Path(ctx.receipt["engine"]["path"])
    # The retained owner checks the full seal immediately before dispatch.
    # Fresh execution still needs this boundary before starting its runner.
    if _evaluation_owner is None:
        execution_identity(engine)
    elif _evaluation_owner.engine != engine.resolve():
        raise ValueError("evaluation owner belongs to another seal")
    directory = ctx.directory / label
    directory.mkdir()
    paths = [source_path(ctx.root, name) for name in rules]
    (directory / "facts.json").write_text(json.dumps(projected, sort_keys=True, indent=2) + "\n")
    request = {"rules": [str(path) for path in paths], "facts": projected, "queries": queries,
               "output": str(directory), "engineId": ctx.receipt["engine"]["engineId"]}
    if rules_contract is not None:
        request["rulesContract"] = rules_contract
    if dsl is not None:
        entry_path = source_path(ctx.root, dsl)
        request["dsl"] = dsl_entry(read_json(entry_path))
        paths = dsl_sources(request["dsl"], ctx.root)
        inventory = request["dsl"]["sources"] + ([request["dsl"]["manifest"]] if "manifest" in request["dsl"] else [])
        if any(item["path"] not in ctx.receipt["declaredInputs"] for item in inventory):
            raise ValueError("all DSL sources must be declared recipe inputs")
        ctx.bind([entry_path, *paths])
        request.update(dslInput=str(entry_path), dslInputSha256=ctx.extra_inputs[str(entry_path.resolve())],
                       dslRoot=str(ctx.root))
    target = directory / "evaluation.json"
    request["observationInputs"] = dict(getattr(ctx, "extra_inputs", {}))
    target.write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    if _evaluation_owner is None:
        ctx.require("native-" + label, [sys.executable, "-I", "-B", engine / "runner.py", "rules", target],
                    ctx.root, ctx.remaining())
    else:
        if _evaluation_owner.engine != engine.resolve():
            raise ValueError("evaluation owner belongs to another seal")
        _evaluation_owner.evaluate(target, ctx.remaining(),
            **({"progress_deadline": ctx.deadline} if ctx.progress_mode else {}))
    return read_json(directory / "answers.json")


def native_evaluate(request, *, retain=False):
    from gambit_smp.ascent_program import load_catalog, load_inert_catalog, INERT_RULE_CONTRACT, load_evidence_catalog, load_component_catalog, engine_api, query
    from gambit_smp.framework import digest
    from gambit_smp.ascent_program import result_explanation
    from gambit_smp.recipes import read_json
    directory = Path(request["output"])
    paths = [Path(name) for name in request["rules"]]
    if "module" in request:
        raise ValueError("compiled Scheme module entries were removed; declare hash-bound DSL sources")
    if paths and "dsl" in request:
        raise ValueError("Evidence entries are exclusive")
    if "rulesContract" in request and (request["rulesContract"] != INERT_RULE_CONTRACT
            or not paths or "module" in request or "dsl" in request):
        raise ValueError("explicit inert rule contract requires the rules entry")
    metrics = {}
    with engine_api(retain=retain) as (engine, identities):
        if "dsl" in request:
            entry = dsl_entry(request["dsl"])
            entry_path = Path(request["dslInput"])
            if digest(entry_path) != request["dslInputSha256"] or read_json(entry_path) != entry:
                raise ValueError("Evidence DSL entry changed before execution")
            paths = dsl_sources(entry, Path(request["dslRoot"]))
            if "manifest" in entry:
                catalog = load_component_catalog(paths[-1], entry=entry["entry"], constructor=entry["constructor"],
                                                arguments=entry["arguments"], trusted=entry["trusted"])
                expected = {str(path.resolve()): item["sha256"]
                            for path, item in zip(paths, entry["sources"] + [entry["manifest"]])}
                if catalog["sourceInputs"] != expected:
                    raise ValueError("Evidence component entry omits or changes its complete source inventory")
            else:
                catalog = load_evidence_catalog(*paths, constructor=entry["constructor"],
                                            arguments=entry["arguments"], trusted=entry["trusted"])
            catalog["sourceInputs"][str(entry_path.resolve())] = request["dslInputSha256"]
        else:
            catalog = load_inert_catalog(*paths) if "rulesContract" in request else load_catalog(*paths)
        answers = query(request["facts"], catalog, request["queries"], engine=engine, metrics=metrics,
                        reuse_program=retain)
        if any(digest(Path(path)) != sha for path, sha in catalog["sourceInputs"].items()):
            raise ValueError("Evidence entry source changed during execution")
        actual = {key: rows if isinstance(rows, dict) else [list(row) for row in rows]
                  for key, rows in answers.items()}
        explanations = {}
        if "dsl" in request:
            for key, relation in request["queries"].items():
                proof = result_explanation(engine, metrics["sessionOwner"],
                                           metrics["nativeResultHandle"], relation)
                try:
                    explanations[key] = {"graph": proof.graph, "current": proof.current,
                                         "sourceGeneration": proof.source_generation}
                finally:
                    proof.close()
        (directory / "explanations.json").write_text(json.dumps({"answers": explanations,
            "status": "recorded-only", "handleLifetime": "native-worker-process",
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False}, sort_keys=True, indent=2) + "\n")
    (directory / "answers.json").write_text(json.dumps(actual, sort_keys=True, indent=2) + "\n")
    (directory / "native-engine.json").write_text(json.dumps({"identities": identities, **metrics}, sort_keys=True, indent=2) + "\n")


def capabilities(Capability):
    return {"evidence.evaluate": Capability(validate, executor=evaluate, graph=graph)}


def serve():
    engine = Path(__file__).resolve().parents[2]
    sys.path[:0] = [str(engine / "python"), str(engine / "native")]
    from contextlib import nullcontext
    from gambit_smp.ascent_program import session_construction_slot
    lock = os.environ.get("GAMBIT_SMP_SESSION_CONSTRUCTION_LOCK")
    deadline = os.environ.get("GAMBIT_SMP_SESSION_CONSTRUCTION_DEADLINE")
    if (lock is None) != (deadline is None):
        raise ValueError("incomplete session construction admission")
    scope = nullcontext() if lock is None else session_construction_slot(Path(lock), float(deadline))
    with scope:
        return _serve()


def _serve():
    engine = Path(__file__).resolve().parents[2]
    sys.path[:0] = [str(engine / "python"), str(engine / "native")]
    from gambit_smp.framework import digest
    from gambit_smp.research_kernel import execution_identity, execution_origin
    # This is an expected metadata identity, not a file-validation verdict.
    # Each request's boundary hashes every file before any evaluator executes.
    from gambit_smp.research_kernel import manifest_content_identity
    manifest_bytes = (engine / "engine.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    if manifest_content_identity(manifest_bytes) != manifest["engineId"]:
        raise ValueError("evaluation manifest identity mismatch")
    from gambit_smp.ascent_program import sealed_api_boundary
    for line in sys.stdin:
        message = json.loads(line)
        path = Path(message["path"])
        try:
            with sealed_api_boundary(engine) as current:
                if current["engineId"] != manifest["engineId"]:
                    raise ValueError("evaluation seal changed before request")
                if digest(path) != message["sha256"]:
                    raise ValueError("evaluation request changed")
                request = json.loads(path.read_text())
                if request["engineId"] != manifest["engineId"]:
                    raise ValueError("evaluation request selected another seal")
                native_evaluate(request, retain=True)
            response = {"requestSha256": message["sha256"], "engineId": manifest["engineId"], "outcome": "PASS"}
        except Exception as error:
            traceback.print_exc(file=sys.stderr)
            response = {"requestSha256": message["sha256"], "engineId": manifest["engineId"],
                        "outcome": "DENY", "error": str(error)}
        print(json.dumps(response), flush=True)
    from gambit_smp.ascent_program import close_retained_queries
    close_retained_queries()
    # Every request has a full before/after check. The reaping owner performs
    # the full terminal byte check after this process exits, within its deadline.
    execution_origin(engine)
    return 0


if __name__ == "__main__":
    raise SystemExit(serve())
