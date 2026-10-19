"""A closed research lane: sealed implementation, typed artifacts, native rules.

The seal is a reproducibility boundary, not a sandbox against a malicious host.
Research data cannot install handlers or select an executable implementation.
"""
import argparse
import ast
import hashlib
import importlib.util
import json
import os
import re
from pathlib import Path
import shutil
import stat
import sys
import time
import uuid
from functools import lru_cache

from gambit_smp.framework import ROOT, digest, execute, relative


SCHEMA = "evidence-recipe.v2"
ENGINE_SCHEMA = "research-engine-seal.v2"
GENERATION = re.compile(r"\.o[1-9][0-9]*")
ALLOWED = frozenset({"gambit.materialize", "source.overlay", "source.project", "source.bind",
                     "native.workspace-build", "native.test", "quint.parse", "quint.typecheck", "quint.test", "quint.verify",
                     "evidence.evaluate", "gambit.configure", "gambit.object", "gambit.seed-core", "gambit.seed-checkpoint",
                     "gambit.regenerate-module", "gambit.source-core", "gambit.bootstrap", "gambit.suite", "gambit.review",
                     "gambit.completed-runtime", "gambit.probe", "gambit.executable-test", "gambit.compiler-observation",
                     "gambit.runtime-import", "gambit.upstream-tests"})
FORBIDDEN_IMPORTS = frozenset({"source_unit", "ffi_source_unit", "allocator_acquire", "allocator_object",
                               "sync_retirement_source", "gc_wait_source", "gc_queue_binding"})


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def content_id(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def clock_epoch():
    """Read an OS boot identity; absence never establishes clock continuity."""
    try:
        if sys.platform == "darwin":
            import ctypes
            library = ctypes.CDLL(None, use_errno=True)
            query = library.sysctlbyname
            query.argtypes = [ctypes.c_char_p, ctypes.c_void_p,
                             ctypes.POINTER(ctypes.c_size_t), ctypes.c_void_p, ctypes.c_size_t]
            query.restype = ctypes.c_int
            buffer = ctypes.create_string_buffer(128)
            length = ctypes.c_size_t(len(buffer))
            if query(b"kern.bootsessionuuid", buffer, ctypes.byref(length), None, 0) != 0:
                return None
            value = buffer.value.decode("ascii")
        elif sys.platform.startswith("linux"):
            value = Path("/proc/sys/kernel/random/boot_id").read_text().strip()
        else:
            return None
        return str(uuid.UUID(value))
    except (OSError, ValueError, UnicodeError, AttributeError):
        return None


def retain_run_record(root, path, scope, payload, inputs):
    """Commit immutable transport evidence, not a published analysis or PASS."""
    pending = path.with_name(path.name + ".pending-" + uuid.uuid4().hex)
    try:
        if path.exists() or path.is_symlink():
            raise FileExistsError(path)
        with pending.open("x") as stream:
            json.dump(payload, stream, sort_keys=True, indent=2, allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        reference = retain_record_observation(root, path, scope, payload, inputs, record_sha=digest(pending))
        os.link(pending, path)
        directory = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
        return reference
    finally:
        pending.unlink(missing_ok=True)


def retain_record_observation(root, path, scope, payload, inputs, *, record_sha=None):
    from gambit_smp.reasoning_history import append_observation, CheckpointConflict
    header = payload.get("header")
    run = Path(header["path"]).parent if header else path.parent
    checkpoint = ({"run": str(run.resolve()), "runId": payload["runId"], "path": str(path.resolve()),
                   "scope": scope}
                  if payload.get("runId") else None)
    record_sha = digest(path) if record_sha is None else record_sha
    backend = {"name": "reported-process", "inputs": {}, "recordSha256": record_sha}
    try:
        identity = append_observation(root, scope, inputs, {"run_record": [payload]}, backend, checkpoint=checkpoint)
    except CheckpointConflict:
        append_observation(root, scope, inputs, {"run_record": [payload]},
                           dict(backend, publicationRejected=True))
        raise
    return {"path": str(path), "sha256": record_sha, "observation": identity, "scope": scope}


def process_recorder(root, run, journal, *, owner_path=None, deadline=None):
    """Record process births, including incomplete births, before exposing results."""
    from gambit_smp.reasoning_history import CheckpointConflict, CheckpointClosed
    def record(event, token, fields):
        header = json.loads(Path(journal["path"]).read_text())
        payload = {"schema": "research-process-observation.v1", "runId": header["runId"],
                   "header": journal, "event": event, "token": token,
                   "clockEpoch": clock_epoch(), **fields}
        suffix = event
        if event == "progress":
            if type(fields.get("count")) is not int or fields["count"] <= 0:
                raise ValueError("positive progress observation sequence required")
            suffix += "-" + str(fields["count"])
        target = (owner_path if event == "started" and owner_path is not None else
                  run / ("process-" + token + "-" + suffix + ".json"))
        while True:
            try:
                return retain_run_record(root, target, journal["scope"], payload, header["inputs"])
            except CheckpointClosed:
                raise
            except CheckpointConflict:
                if deadline is None or time.monotonic() >= deadline:
                    raise
    return record


def retain_terminal_run(root, out, receipt):
    """Bind completed parent/child receipts into the same durable observation store."""
    from gambit_smp.reasoning_history import read_execution_checkpoint
    state = read_execution_checkpoint(root, out)
    if not state["records"]:
        return
    if state["records"][-1]["payload"].get("schema") == "research-terminal-observation.v1":
        return
    header = state["records"][0]["payload"]
    child_path = out / "run/receipt.json"
    child = json.loads(child_path.read_text()) if child_path.is_file() else None
    if receipt.get("childReceiptSha256") is not None and (
            child is None or digest(child_path) != receipt["childReceiptSha256"]):
        raise ValueError("terminal checkpoint child receipt changed")
    payload = {"schema": "research-terminal-observation.v1", "runId": header["runId"],
               "header": {"path": str(out / "run-header.json")}, "outer": receipt, "child": child}
    retain_record_observation(root, out / "receipt.json", state["records"][0]["scope"], payload, header["inputs"])


def retain_existing_run(root, out):
    """Index only records already authenticated by the existing immutable journal."""
    from gambit_smp.reasoning_history import read_execution_checkpoint, read_journal, normalized
    if not (out / "run-header.json").is_file():
        return
    header = json.loads((out / "run-header.json").read_text())
    paths = [out / "run-header.json", *sorted((out / "run").glob("*.observation.json"))]
    scope = next((json.loads(path.read_text())["header"]["scope"] for path in paths[1:]),
                 "research:" + header["recipe"])
    observations = read_journal(root, scope)["observations"]
    known = {row["path"]: row for row in read_execution_checkpoint(root, out)["records"]}
    records = []
    for path in paths:
        payload = json.loads(path.read_text())
        matches = [(identity, body) for identity, body in observations.items()
                   if body.get("queries") == normalized({"run_record": [payload]})]
        if len(matches) != 1:
            raise ValueError("existing checkpoint record lacks immutable custody")
        records.append((path, payload, matches[0][1]["inputs"]))
    pending, published = records[1:], set()
    ordered = [records[0]]
    while pending:
        ready = [row for row in pending if set(row[1]["step"]["dependsOn"]) <= published]
        if not ready:
            raise ValueError("existing checkpoint dependency closure is incomplete")
        for row in ready:
            ordered.append(row)
            published.add(row[1]["step"]["id"])
            pending.remove(row)
    for path, payload, inputs in ordered:
        if str(path) in known:
            if known[str(path)]["payload"] != payload:
                raise ValueError("existing checkpoint differs from the committed prefix")
        else:
            retain_record_observation(root, path, scope, payload, inputs)
    if (out / "receipt.json").is_file():
        retain_terminal_run(root, out, json.loads((out / "receipt.json").read_text()))


@lru_cache(maxsize=256)
def _static_dependencies(source):
    """Parse exact bytes only; file availability and policy are never cached."""
    dependencies = []
    for node in ast.walk(ast.parse(source)):
        if isinstance(node, ast.ImportFrom) and node.module == "gambit_smp":
            dependencies.extend(alias.name for alias in node.names)
        elif isinstance(node, ast.ImportFrom) and node.module and node.module.startswith("gambit_smp."):
            dependencies.append(node.module.split(".")[1])
        elif isinstance(node, ast.Import):
            dependencies.extend(alias.name.split(".")[1] for alias in node.names
                                if alias.name.startswith("gambit_smp."))
    return tuple(dependencies)


def implementation_paths(package):
    """Seal the static implementation closure, not unrelated experiment runners."""
    pending = ["__init__", "research_kernel", "recipes", "native_capabilities", "source_capabilities",
               "evidence_capabilities", "process_observation", "ascent_program", "validation_domains"]
    used = set()
    parents = {}
    while pending:
        name = pending.pop()
        if name in used:
            continue
        if name in FORBIDDEN_IMPORTS or name == "cli":
            chain = [name]
            while chain[-1] in parents:
                chain.append(parents[chain[-1]])
            raise ValueError("historical producer reachable from the research kernel: " + " <- ".join(chain))
        path = package / (name + ".py")
        if not path.is_file() or path.is_symlink():
            raise ValueError("unavailable static research implementation: " + name)
        used.add(name)
        for child in _static_dependencies(path.read_bytes()):
            if child not in used and child not in pending:
                parents[child] = name
                pending.append(child)
    return [package / (name + ".py") for name in sorted(used)]


def validate_graph(recipe, steps):
    if any(step["capability"] not in ALLOWED for step in steps):
        raise ValueError("new research cannot call a historical producer or untyped C-file builder")
    for name in recipe["inputs"]:
        parts = Path(name).parts
        if (name.endswith((".py", ".sh", ".inc")) or
                len(parts) >= 2 and parts[:2] in {("evidence", "source-results"), ("evidence", "model-results")}):
            raise ValueError("new research cannot consume executable scripts or archived producer outputs")
    evaluations = [step for step in steps if step["capability"] == "evidence.evaluate"]
    if len(evaluations) != 1 or steps[-1] != evaluations[0]:
        raise ValueError("one terminal native evidence evaluation required")
    dsl_only = len(steps) == 1 and "dsl" in evaluations[0]["arguments"]
    if not dsl_only and not any(step["capability"] == "gambit.materialize" for step in steps):
        raise ValueError("a new research run must start from a locked source producer")
    for step in steps:
        if step["capability"] in {"gambit.suite", "gambit.bootstrap", "gambit.upstream-tests"}:
            args = step["arguments"]
            if (args.get("failures") not in recipe["inputs"] or args.get("reviewRules") not in recipe["inputs"]
                    or not args["failures"].endswith(".json") or not args["reviewRules"].endswith(".ss")):
                raise ValueError("suite requires declared known-failure inventory and native review rules")
            if step["capability"] == "gambit.bootstrap":
                ref = args.get("identity")
                if (not isinstance(ref, dict) or ref.get("output") != "identity"
                        or ref.get("step") != args["runtime"]["step"] or ref["step"] not in step["dependsOn"]):
                    raise ValueError("bootstrap needs matching producer identity")
        if step["capability"] == "source.project":
            if not any(row["origin"]["kind"] == "source-artifact" for row in step["arguments"]["files"]):
                raise ValueError("workspace must contain actual locked-source bytes, not only a synthetic fixture")
            if any(row["origin"]["kind"] == "research-asset" and not row["origin"]["path"].endswith((".c", ".h"))
                   for row in step["arguments"]["files"]):
                raise ValueError("workspace research assets must be C sources or headers")


def sealed_inventory(engine):
    """Read each byte through no-follow directory handles, without path aliases."""
    found = {}
    def visit(fd, prefix):
        with os.scandir(fd) as entries:
            for entry in entries:
                name = prefix + entry.name
                if entry.is_symlink():
                    raise ValueError("sealed engine implementation drift")
                directory = entry.is_dir(follow_symlinks=False)
                if not directory and not entry.is_file(follow_symlinks=False):
                    raise ValueError("sealed engine implementation drift")
                flags = os.O_RDONLY | os.O_NOFOLLOW | (os.O_DIRECTORY if directory else os.O_NONBLOCK)
                child = os.open(entry.name, flags, dir_fd=fd)
                try:
                    mode = os.fstat(child).st_mode
                    if directory:
                        if not stat.S_ISDIR(mode):
                            raise ValueError("sealed engine implementation drift")
                        visit(child, name + "/")
                    else:
                        if not stat.S_ISREG(mode):
                            raise ValueError("sealed engine implementation drift")
                        sha = hashlib.sha256()
                        while block := os.read(child, 1048576):
                            sha.update(block)
                        found[name] = sha.hexdigest()
                finally:
                    os.close(child)
    fd = os.open(engine, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        visit(fd, "")
    finally:
        os.close(fd)
    return found


@lru_cache(maxsize=2)
def manifest_content_identity(manifest_bytes):
    """Memoize canonical encoding only, keyed by the entire immutable bytes."""
    manifest = json.loads(manifest_bytes)
    return content_id({key: value for key, value in manifest.items() if key != "engineId"})


def check_generation_identity(recorded, current, mounted_devices):
    """A device number is mount-local; hashed bytes and the inode remain checked."""
    if (not isinstance(recorded, list) or len(recorded) != 2
            or any(type(value) is not int for value in recorded)
            or current[1] != recorded[1]):
        raise ValueError("sealed generation inode drift")
    prior = mounted_devices.setdefault(recorded[0], current[0])
    if prior != current[0]:
        raise ValueError("sealed generation device mapping is inconsistent")


def manifest_paths(engine):
    engine = engine.resolve(strict=True)
    manifest_bytes = (engine / "engine.json").read_bytes()
    manifest = json.loads(manifest_bytes)
    if manifest.get("schema") != ENGINE_SCHEMA:
        raise ValueError("sealed research engine required")
    if manifest.get("engineId") != manifest_content_identity(manifest_bytes):
        raise ValueError("engine manifest identity mismatch")
    inventory = sealed_inventory(engine)
    if inventory.get("engine.json") != hashlib.sha256(manifest_bytes).hexdigest():
        raise ValueError("engine manifest changed during validation")
    if set(inventory) != set(manifest["files"]) | {"engine.json"}:
        raise ValueError("sealed engine inventory drift")
    for name, expected in manifest["files"].items():
        if not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError("relative sealed implementation path required")
        if inventory[name] != expected:
            raise ValueError("sealed engine implementation drift")
    if manifest["schema"] == ENGINE_SCHEMA:
        ownership = manifest.get("resourceOwnership", {})
        if ownership.get("contract") != "checked-generation-sharing.v1":
            raise ValueError("sealed generation ownership contract required")
        transfers = ownership.get("generations", {})
        expected = {name for name in manifest["files"]
                    if name.startswith(("native/syntax/", "runtime/", "python/ascent/")) and GENERATION.fullmatch(Path(name).suffix)}
        if set(transfers) != expected:
            raise ValueError("sealed generation ownership inventory drift")
        mounted_devices = {}
        for name, row in transfers.items():
            if row.get("sha256") != manifest["files"][name] or row.get("mode") not in ("linked-generation", "copied"):
                raise ValueError("sealed generation ownership identity drift")
            if row["mode"] == "linked-generation":
                info = (engine / name).stat(follow_symlinks=False)
                check_generation_identity(row.get("targetIdentity"),
                                          [info.st_dev, info.st_ino], mounted_devices)
    for name, row in manifest["hostTools"].items():
        if digest(Path(row["path"])) != row["sha256"]:
            raise ValueError("sealed host tool drift: " + name)
    provider_schema = manifest.get("providerSources", {}).get("schema")
    if provider_schema in {"ascent.rust-source-archive.v1", "ascent.rust-wheel-archive.v1"}:
        build = json.loads((engine / "ascent-build.json").read_text())
        mapping = json.loads((engine / "ascent-runtime.json").read_text())
        if (build.get("schema") != "ascent.rust-build.v1" or not build.get("runtimeInputs")
                or manifest.get("externalRuntimeInputs") != ({} if provider_schema == "ascent.rust-wheel-archive.v1" else build["runtimeInputs"])
                or manifest["providerSources"].get("inputs") != build.get("sourceInputs")
                or manifest["providerSources"].get("runtimeInputs") != build["runtimeInputs"]
                or set(mapping) != set(build["runtimeInputs"])
                or any(manifest["files"].get(mapping[name]) != sha
                       for name, sha in build["runtimeInputs"].items())
                or any(manifest["files"].get("provider-source/" + name) != sha
                       for name, sha in build["sourceInputs"].items())):
            raise ValueError("sealed Rust provider source/runtime inventory drift")
        if provider_schema == "ascent.rust-wheel-archive.v1":
            if (not build.get("packageInputs")
                    or set(build.get("runtimePackagePaths", {})) != set(build["runtimeInputs"])
                    or any(manifest["files"].get("python/ascent/" + name) != sha
                           for name, sha in build["packageInputs"].items())
                    or any(mapping[name] != "python/ascent/" + relative
                           for name, relative in build["runtimePackagePaths"].items())):
                raise ValueError("sealed wheel package inventory drift")
    for name, expected in manifest.get("externalRuntimeInputs", {}).items():
        path = Path(name)
        if not path.is_absolute() or ".." in path.parts or path.is_symlink() or digest(path) != expected:
            raise ValueError("sealed runtime resource drift: " + name)
    return manifest


def seal(out, *, gcc, quint=None, node=None, ascent_api, provider_sources=None, portable=False):
    from gambit_smp.artifact_storage import transfer_generation, clone_file
    from gambit_smp.recipes import tool_files
    from gambit_smp.native_review import POLICY
    from gambit_smp.provider_contract import inspect_provider
    from gambit_smp.ascent_runtime import inventory, require_packaged_runtime
    out = out.resolve()
    if out.exists():
        raise ValueError("engine seals are immutable; a fresh directory is required")
    package = Path(__file__).resolve().parent
    if out.is_relative_to(package):
        raise ValueError("engine seal cannot overwrite its implementation")
    # The installed extension is authoritative; no alternate ABI directory.
    api = ascent_api.resolve(strict=True)
    if provider_sources is not None:
        manifest_paths(provider_sources)
    files, build = inventory(sealed_root=provider_sources)
    binding = files["ascent"].parent
    if api != binding:
        raise ValueError("ascent_api must identify the installed Rust Python package")
    require_packaged_runtime(build, binding)
    originals = {path: "python/gambit_smp/" + path.relative_to(package).as_posix()
                 for path in implementation_paths(package)}
    originals.update({path: "python/ascent/" + path.relative_to(binding).as_posix()
                      for path in (files["ascent"], files["ascent._core"])})
    originals[ROOT / POLICY] = "policy/suite-review-rules.ss"
    from gambit_smp.upstream_tests import POLICIES
    originals.update({ROOT / name: sealed for name, sealed in POLICIES.items()})
    packaged = build.get("packageInputs", {})
    package_sources = {}
    for name, sha in packaged.items():
        path = relative(binding, name)
        if digest(path) != sha:
            raise ValueError("installed ASCENT package input drift")
        originals[path] = "python/ascent/" + name
    runtime = {}
    for name, path in files.items():
        if name.startswith("distribution:"):
            originals[path] = "python/" + path.parent.name + "/" + path.name
        elif name.startswith("package:"):
            originals[path] = "python/" + name.removeprefix("package:")
        elif name.startswith("source:"):
            if packaged:
                # The same bytes can have both source and runtime roles. Keep
                # the independent source archive when runtime mapping wins.
                package_sources[path] = ("provider-source/" + name.removeprefix("source:"),
                                         "python/ascent/_sources/" + name.removeprefix("source:"))
            originals[path] = "provider-source/" + name.removeprefix("source:")
        elif name.startswith("runtime:"):
            original = name.removeprefix("runtime:")
            target = ("python/ascent/" + build["runtimePackagePaths"][original] if packaged else
                      "runtime/" + hashlib.sha256(original.encode()).hexdigest() + "/" + path.name)
            originals[path] = target
            runtime[original] = target
    before = {path: digest(path) for path in originals}
    provider_contract = inspect_provider(api, binding)
    host = {"python": Path(sys.executable).resolve(strict=True), "gcc": gcc.absolute()}
    if sys.platform == "darwin" and Path("/usr/bin/sample").is_file():
        host["darwinSample"] = Path("/usr/bin/sample")
    if (quint is None) != (node is None):
        raise ValueError("Quint and Node must be sealed together")
    if quint is not None:
        host.update(quint=quint.absolute(), node=node.absolute())
        host.update({"quint-file:" + str(path): path for path in tool_files(quint, node)})
    tools = {name: {"path": str(path), "sha256": digest(path)} for name, path in host.items()}
    out.mkdir(parents=True)
    generations, shared = {}, set()
    private_transfers = {"copy-on-write": 0, "byte-copy": 0}
    for path, name in originals.items():
        target = relative(out, name)
        target.parent.mkdir(parents=True, exist_ok=True)
        if target.exists() or target.is_symlink():
            if target.is_symlink() or not target.is_file() or digest(target) != before[path]:
                raise ValueError("sealed resource role collision")
            continue
        if name.startswith(("runtime/", "python/ascent/")) and GENERATION.fullmatch(path.suffix):
            mode = transfer_generation(path, target, portable=portable)
            if digest(target) != before[path]:
                raise ValueError("runtime generation changed during transfer")
            info = target.stat(follow_symlinks=False)
            generations[name] = {"mode": mode, "sha256": before[path],
                                 "source": str(path), "targetIdentity": [info.st_dev, info.st_ino]}
            if mode == "linked-generation":
                shared.add(target)
        else:
            private_transfers[clone_file(path, target)] += 1
    for path, names in package_sources.items():
        for name in names:
            target = relative(out, name)
            target.parent.mkdir(parents=True, exist_ok=True)
            if target.exists() or target.is_symlink():
                if target.is_symlink() or not target.is_file() or digest(target) != before[path]:
                    raise ValueError("provider source/runtime role collision")
                continue
            private_transfers[clone_file(path, target)] += 1
    (out / "ascent-runtime.json").write_text(json.dumps(runtime, sort_keys=True, indent=2) + "\n")
    (out / "ascent-build.json").write_text(json.dumps(build, sort_keys=True, indent=2) + "\n")
    runner = out / "runner.py"
    runner.write_text("import sys\nfrom pathlib import Path\n"
                      "root = Path(__file__).resolve().parent\n"
                      "sys.path.insert(0, str(root / 'python'))\n"
                      "from gambit_smp.research_kernel import worker\n"
                      "raise SystemExit(worker(root))\n")
    if any(digest(path) != expected for path, expected in before.items()):
        raise ValueError("implementation/provider changed while sealing; incomplete seal is not admissible")
    sealed_files = {path.relative_to(out).as_posix(): digest(path)
                    for path in out.rglob("*") if path.is_file()}
    identity = {"schema": ENGINE_SCHEMA, "files": sealed_files, "hostTools": tools,
                "privateFileTransfers": {**private_transfers, "hardlinks": False},
                "resourceOwnership": {"contract": "checked-generation-sharing.v1", "generations": generations,
                                      "boundary": "byte-bound resources; shared generations are not write-isolated"},
                "providerContract": provider_contract,
                "externalRuntimeInputs": {} if packaged else build["runtimeInputs"],
                "providerSources": {"schema": "ascent.rust-wheel-archive.v1" if packaged else "ascent.rust-source-archive.v1",
                                    "inputs": build["sourceInputs"],
                                    "runtimeInputs": build["runtimeInputs"]},
                "capabilities": sorted(ALLOWED), "pythonVersion": sys.version,
                "scope": "closed research implementation and installed PyO3 provider",
                "runtimeAdmitted": False, "releaseAdmitted": False}
    manifest = {**identity, "engineId": content_id(identity)}
    (out / "engine.json").write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n")
    for path in out.rglob("*"):
        if path.is_file() and path not in shared:
            path.chmod(0o444)
    for path in sorted((path for path in out.rglob("*") if path.is_dir()), reverse=True):
        path.chmod(0o555)
    out.chmod(0o555)
    manifest_paths(out)
    return manifest


def execution_origin(engine):
    """Check loaded code origins; filesystem identity is a separate boundary."""
    engine = engine.resolve(strict=True)
    code = engine / "python/gambit_smp"
    if not Path(__file__).resolve().is_relative_to(code.resolve()):
        raise ValueError("new research must execute the sealed implementation, not the editable checkout")
    for name, module in tuple(sys.modules.items()):
        if name.startswith("gambit_smp.") and name.rsplit(".", 1)[1] in FORBIDDEN_IMPORTS:
            raise ValueError("historical feature producer loaded into the new research lane")
        if (name == "ascent" or name.startswith(("gambit_smp", "ascent."))) and getattr(module, "__file__", None):
            path = Path(module.__file__).resolve()
            if not path.is_relative_to(engine):
                raise ValueError("research implementation escaped its engine seal")


def execution_identity(engine):
    manifest = manifest_paths(engine)
    execution_origin(engine)
    return manifest


def evaluation_teardown_deadline(recipe, requested_deadline, owner):
    """Use the last real progress-stage review window, not expired total wall time."""
    if recipe.get("timeoutPolicy", {}).get("mode") == "progress":
        return owner.deadline
    return requested_deadline


def worker(engine):
    from gambit_smp.recipes import load, read_json, run
    if sys.argv[1] == "runtime-export":
        from gambit_smp.runtime_artifact import export
        manifest = execution_identity(engine)
        request = read_json(Path(sys.argv[2]))
        root = Path(request["root"])
        producer = read_json(Path(request["run"]) / "receipt.json")
        if producer["engineId"] != manifest["engineId"]:
            raise ValueError("runtime export selected another producer engine")
        print(json.dumps(export(root, Path(request["run"]), request["step"], Path(request["out"]))))
        return 0
    if sys.argv[1] == "rules":
        from gambit_smp.evidence_capabilities import native_evaluate
        from gambit_smp.ascent_program import sealed_api_boundary
        with sealed_api_boundary(engine) as manifest:
            request = read_json(Path(sys.argv[2]))
            if request["engineId"] != manifest["engineId"]:
                raise ValueError("native evaluator selected a different engine seal")
            native_evaluate(request)
        return 0
    manifest = execution_identity(engine)
    request = read_json(Path(sys.argv[1]))
    if request["engineId"] != manifest["engineId"]:
        raise ValueError("launch selected a different engine seal")
    journal = request["journal"]
    header_path = Path(journal["path"])
    if digest(header_path) != journal["sha256"]:
        raise ValueError("launch run header changed")
    header = read_json(header_path)
    if header["request"] != {key: value for key, value in request.items() if key != "journal"}:
        raise ValueError("launch request differs from committed run header")
    if "launchOwner" in request:
        owner_path = Path(request["launchOwner"])
        while not owner_path.is_file():
            if time.monotonic() >= request["deadline"]:
                raise TimeoutError("launch owner observation was not committed")
            time.sleep(.01)
        owner = read_json(owner_path)
        if (owner.get("pid") != os.getpid() or owner.get("runId") != header["runId"]
                or owner.get("clockEpoch") != clock_epoch() or owner.get("event") != "started"):
            raise ValueError("launch owner identity mismatch")
    if header["inputs"] != {name: digest(Path(request["root"]) / name) for name in header["inputs"]}:
        raise ValueError("launch input differs from committed run header")
    def guard(event, args):
        if event == "import" and args[0].startswith("gambit_smp.") and args[0].split(".")[1] in FORBIDDEN_IMPORTS:
            raise ImportError("historical feature producers are unavailable in the sealed research lane")
    sys.addaudithook(guard)
    root = Path(request["root"])
    recipe, _ = load(root, root / request["recipe"])
    if recipe["schema"] != SCHEMA:
        raise ValueError("new research lane requires artifact-graph v2")
    tools = manifest["hostTools"]
    from gambit_smp.evidence_capabilities import evaluation_owner
    with evaluation_owner(engine, Path(request["out"]) / "evaluation-owner", request["deadline"]) as owner:
        receipt = run(root, root / request["recipe"], Path(request["out"]),
                      Path(tools["quint"]["path"]) if "quint" in tools else Path("quint"),
                      Path(tools["node"]["path"]) if "node" in tools else Path("node"),
                      Path(request["prior"]) if request["prior"] else None,
                      gcc=Path(tools["gcc"]["path"]), allow_native=request["allowNative"],
                      engine=engine, deadline=request["deadline"], journal=request["journal"],
                      budget_reservation=request.get("budgetReservation"), resume_prefix=request.get("resumePrefix"))
        owner_finalization_started = time.monotonic()
    owner_result = owner.receipt
    teardown_deadline = evaluation_teardown_deadline(recipe, request["deadline"], owner)
    if owner_result is not None:
        owner_path = Path(request["out"]) / "evaluation-owner/receipt.json"
        receipt["evaluationOwner"] = {"path": "evaluation-owner/receipt.json", "sha256": digest(owner_path)}
        receipt["evaluationOwnerFinalizationSeconds"] = time.monotonic() - owner_finalization_started
        receipt["wholeSeconds"] += receipt["evaluationOwnerFinalizationSeconds"]
        if (owner_result["exit"] != 0 or owner_result["forcedTermination"]
                or any(not row["requestCompleted"] or row["timeout"] for row in owner_result["requests"])
                or time.monotonic() > teardown_deadline):
            receipt["outcome"] = "DENY"
        (Path(request["out"]) / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    if owner_result is not None and (owner_result["exit"] != 0 or owner_result["forcedTermination"]
            or any(not row["requestCompleted"] or row["timeout"] for row in owner_result["requests"])):
        raise ValueError("evaluation owner did not complete and tear down normally")
    if time.monotonic() > teardown_deadline:
        raise TimeoutError("research deadline exhausted during evaluation owner teardown")
    # A reaped owner just performed this exact full byte check. The parent
    # independently rehashes the seal after worker exit as well.
    if owner_result is None:
        execution_identity(engine)
    elif owner_result["engineId"] != manifest["engineId"] or owner_result["terminalIdentityError"] is not None:
        raise ValueError("evaluation owner terminal seal mismatch")
    print(json.dumps({"engineId": manifest["engineId"], "recipe": receipt["recipe"], "outcome": receipt["outcome"]}))
    return 0 if receipt["outcome"] == "PASS" else 2


def completed_stage_frontier(out, steps, journal):
    """Recognize completed execution, not permission for another native stage."""
    from gambit_smp.recipes import read_json
    try:
        header = read_json(Path(journal["path"]))
        if digest(Path(journal["path"])) != journal["sha256"]:
            return False
        for declared in steps:
            path = out / "run" / (declared["id"] + ".observation.json")
            if path.is_symlink():
                return False
            record = read_json(path)
            result = record["step"]
            if (record.get("schema") != "research-step-observation.v1"
                    or record.get("header") != journal or record.get("runId") != header["runId"]
                    or result.get("id") != declared["id"]
                    or result.get("outcome") not in ("PASS", "DENY", "STALE", "TIMEOUT", "FAIL", "BLOCKED")
                    or result.get("capability") != declared["capability"]
                    or result.get("arguments") != declared["arguments"]):
                return False
            observations = result.get("commands", [])
            if "exit" in result:
                observations = [*observations, result]
            if any(item.get("parentReaped") is not True or
                   item.get("processGroupQuiescent") is not True for item in observations):
                return False
        return bool(steps)
    except (OSError, KeyError, TypeError, ValueError):
        return False


def completed_work(out, steps):
    """Observe completed stages/processes/files, never timestamps or log volume."""
    count = 0
    run = out / "run"
    for step in steps:
        try:
            stage = json.loads((run / (step["id"] + ".observation.json")).read_text())
            if (stage.get("schema") == "research-step-observation.v1"
                    and stage.get("step", {}).get("id") == step["id"]
                    and stage.get("step", {}).get("outcome") in {"PASS", "DENY", "FAIL", "TIMEOUT", "STALE", "BLOCKED"}):
                count += 1
        except (OSError, ValueError, TypeError):
            pass
        directory = run / step["id"]
        for path in directory.glob("*.process.json"):
            try:
                row = json.loads(path.read_text())
                count += int(row.get("schema") == "recipe-process-observation.v1"
                             and row.get("state") == "OBSERVED" and type(row.get("exit")) is int
                             and row.get("completionObserved") is True and row.get("parentReaped") is True)
            except (OSError, ValueError, TypeError):
                pass
        for path in directory.glob("*.progress.json"):
            try:
                row = json.loads(path.read_text())
                value = row.get("completed")
                if row.get("schema") == "native-completed-progress.v1" and type(value) is int and value > 0:
                    count += value
            except (OSError, ValueError, TypeError):
                pass
    return count


def run_sealed(root, path, out, engine, *, prior=None, allow_native=False):
    from gambit_smp.recipes import load, read_json, authorization_repair
    from gambit_smp import host_environment
    started = time.monotonic()
    if prior is not None:
        prior = prior.resolve()
    recipe, steps = load(root, path)
    progress_mode = recipe.get("timeoutPolicy", {}).get("mode") == "progress"
    if recipe["schema"] != SCHEMA:
        raise ValueError("historical recipes cannot claim a new architecture run")
    manifest = manifest_paths(engine)
    inputs = {name: digest(root / name) for name in [path.relative_to(root).as_posix(), *recipe["inputs"]]}
    out = out.resolve()
    if out.is_relative_to(root / "evidence") or any((root / name).resolve().is_relative_to(out) for name in inputs):
        raise ValueError("execution cannot overwrite its Evidence inputs")
    from gambit_smp.reasoning_history import read_execution_checkpoint
    if (out / "run-header.json").is_file():
        retain_existing_run(root, out)
    prefix = read_execution_checkpoint(root, out)
    if (out / "receipt.json").is_file() or (out / "run-header.json").is_file() or prefix["records"]:
        if (out / "receipt.json").is_file():
            terminal = True
            original = read_json(out / "receipt.json")
        elif prefix["records"]:
            tail = prefix["records"][-1]["payload"]
            terminal = tail.get("schema") == "research-terminal-observation.v1"
            original = tail["outer"] if terminal else prefix["records"][0]["payload"]
        else:
            terminal = False
            original = read_json(out / "run-header.json")
        state = inspect(out, include_resumption=True)
        origin_root = original.get("root", original.get("request", {}).get("root"))
        matching = (origin_root == str(root.resolve()) and original.get("recipe") == recipe["id"]
                    and original.get("inputs") == inputs and original.get("engineId") == manifest["engineId"]
                    and original.get("stepBudgets") == {s["id"]: s["budgetSeconds"] for s in steps})
        reusable = False
        if terminal and original.get("outcome") == "PASS" and matching and state["resumption"]["relations"]["campaign_reusable"]:
            final_state = inspect(out)
            reusable = (final_state["identityStatus"] == "CURRENT"
                        and final_state["evidenceBindingStatus"] == "CURRENT"
                        and (digest(out / "receipt.json") == state["resumption"]["receiptSha256"]
                             if (out / "receipt.json").is_file() else
                             read_execution_checkpoint(root, out)["prefixIdentity"] == state["resumption"]["prefixIdentity"])
                        and inputs == {name: digest(root / name) for name in inputs})
        # A restart consumes the original receipt; it never rewrites history or
        # reports a repeated native launch. Partial/changed runs expose gaps.
        return {"schema": "research-resume-observation.v1", "recipe": recipe["id"],
                "engineId": manifest["engineId"],
                "outcome": "PASS" if reusable else "DENY", "recordedOutcome": original.get("outcome"),
                "resumeStatus": "REUSED" if reusable else "UNRESOLVED" if terminal else "INCOMPLETE",
                "requestedIdentityMatches": matching, "resumption": state["resumption"],
                "executionLaunched": False, "wholeSeconds": time.monotonic() - started,
                "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
    out.mkdir(parents=True, exist_ok=False)
    deadline = started + recipe["budgetSeconds"]
    request = {"engineId": manifest["engineId"], "root": str(root), "recipe": path.relative_to(root).as_posix(),
               "out": str(out / "run"), "prior": str(prior / "run") if prior else None,
               "allowNative": allow_native, "deadline": deadline}
    prior_identity = None
    reservation = None
    if "continuationRequest" in recipe:
        from gambit_smp.recipe_continuation import reserve_budget
        continuation = read_json(root / recipe["continuationRequest"])
        ledger = read_json(root / recipe["continuationLedger"])
        reservation = reserve_budget(root, ledger, continuation, out.name)
        request["budgetReservation"] = reservation

    def retain_receipt(receipt):
        if "timeoutPolicy" in recipe:
            receipt["timeoutPolicy"] = recipe["timeoutPolicy"]
            receipt["supervisorWatchdogSeconds"] = recipe["budgetSeconds"]
            receipt["supervisorWatchdogKind"] = "no-progress" if progress_mode else "wall-clock"
            receipt["supervisorWatchdogExceeded"] = receipt.get("timeout", False) if progress_mode else time.monotonic() > deadline
            receipt.pop("performanceBudgetExceeded", None)
        if reservation is not None:
            receipt["budgetReservation"] = reservation
            if receipt.get("executionLaunched") is False:
                receipt.update(parentReaped=True, processGroupQuiescent=True,
                               wholeSeconds=time.monotonic() - started)
        target = out / "receipt.json"
        target.write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
        retain_terminal_run(root, out, receipt)
        if reservation is not None:
            from gambit_smp.recipe_continuation import settle_budget
            settlement = settle_budget(root, reservation, target, digest(target))
            with (out / "budget-settlement.json").open("x") as stream:
                json.dump({"ledger": reservation["ledger"], "event": settlement,
                           "outerReceiptSha256": digest(target)}, stream, sort_keys=True)
                stream.write("\n")
        return receipt
    host = host_environment.observe(steps)
    partial_prior = prior is not None and not (prior / "receipt.json").is_file()
    if partial_prior:
        try:
            from gambit_smp.step_checkpoint import recovered_resumption
            state = recovered_resumption(root, prior)
            old = read_execution_checkpoint(root, prior)
            header = old["records"][0]["payload"]
            if (state["outcome"] != "INCOMPLETE" or state["engineId"] != manifest["engineId"]
                    or state["recipe"] != recipe["id"]):
                raise ValueError("interrupted continuation requires the same engine and recipe contract")
            if not state["resumption"]["executionQuiescence"]["observed"]:
                raise ValueError("interrupted process births are not observed quiescent")
            if any(step["budgetSeconds"] > header["stepBudgets"].get(step["id"], step["budgetSeconds"]) for step in steps):
                raise ValueError("interrupted continuation cannot expand a phase budget")
            if header["inputs"] == inputs and state["resumption"]["relations"]["failed"]:
                raise ValueError("unchanged failed stage is not an interrupted-only continuation")
            request["resumePrefix"] = state["resumption"]["prefixIdentity"]
            prior_identity = {"committedPrefix": request["resumePrefix"], "engineId": header["engineId"],
                              "interruptedContinuation": True, "oldAggregateOutcome": None,
                              "changedInputs": {name: sha for name, sha in inputs.items() if header["inputs"].get(name) != sha}}
        except (OSError, KeyError, ValueError, TypeError) as error:
            return retain_receipt({"schema": "sealed-research-run.v1", "recipe": recipe["id"],
                "engine": str(engine), "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps}, "budgetSeconds": recipe["budgetSeconds"],
                "outcome": "DENY", "denial": str(error), "executionLaunched": False,
                "prior": prior_identity, "hostEnvironment": host, "artifacts": {}, "childReceiptSha256": None,
                "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False})
    if prior is not None and not partial_prior:
        try:
            previous = read_json(prior / "receipt.json")
            prior_identity = {"receiptSha256": digest(prior / "receipt.json"), "engineId": previous["engineId"],
                              "changedInputs": {name: value for name, value in inputs.items() if previous["inputs"].get(name) != value},
                              "engineChanged": previous["engineId"] != manifest["engineId"]}
            if previous.get("schema") != "sealed-research-run.v1":
                raise ValueError("matching sealed prior observation required")
            if previous["recipe"] != recipe["id"]:
                if "timeoutPolicy" not in recipe:
                    raise ValueError("matching sealed prior observation required")
                old_request = prior / "request.json"
                if digest(old_request) != previous.get("artifacts", {}).get("request.json"):
                    raise ValueError("timeout migration requires the bound original request")
                old_name = read_json(old_request)["recipe"]
                old_path = root / old_name
                if digest(old_path) != previous["inputs"].get(old_name):
                    raise ValueError("timeout migration original recipe drifted")
                old_recipe, old_graph = load(root, old_path)
                old_mode = old_recipe.get("timeoutPolicy", {}).get("mode", "whole")
                migration = old_mode == "whole" or (old_mode == "per-stage" and progress_mode)
                if (not migration or old_recipe["id"] != previous["recipe"] or old_graph != steps
                        or not set(old_recipe["inputs"]) <= set(recipe["inputs"])
                        or any(previous["inputs"].get(name) != inputs.get(name)
                               for name in old_recipe["inputs"])):
                    raise ValueError("timeout migration must preserve the exact graph and input closure")
                if (previous.get("parentReaped") is not True
                        or previous.get("processGroupQuiescent") is not True):
                    raise ValueError("timeout migration requires a quiescent prior attempt")
                request["prior"] = None
                prior_identity["timeoutPolicyMigration"] = {
                    "originalRecipeSha256": digest(old_path), "sameGraph": True,
                    "sameInputs": True, "freshAttempt": True, "deadlineResumed": False}
            if "timeoutPolicy" not in recipe and recipe["budgetSeconds"] > previous["budgetSeconds"]:
                raise ValueError("prior budget cannot expand")
            old_steps = previous["stepBudgets"]
            if any(step["id"] in old_steps and step["budgetSeconds"] > old_steps[step["id"]] for step in steps):
                raise ValueError("prior step budget cannot expand")
            repaired_authorization = False
            repaired_environment = host_environment.repaired(previous, host, fresh_attempt=True)
            child_path = prior / "run/receipt.json"
            if previous.get("childReceiptSha256") is not None:
                if digest(child_path) != previous["childReceiptSha256"]:
                    raise ValueError("prior child receipt was changed")
                repaired_authorization = authorization_repair(read_json(child_path), allow_native,
                                                             manifest["hostTools"].get("gcc"))
            elif not repaired_environment and ("timeoutPolicy" in recipe or previous.get("timeout") is True):
                if (previous.get("parentReaped") is not True
                        or previous.get("processGroupQuiescent") is not True):
                    raise ValueError("prior process group must be quiescent before a fresh attempt")
                if child_path.exists():
                    raise ValueError("prior child receipt exists without a bound digest")
                request["prior"] = None
                prior_identity["interruptedPriorExpenditure"] = {
                    "wholeSeconds": previous.get("wholeSeconds"), "timeout": previous.get("timeout"),
                    "accountingOnly": True, "freshAttempt": True, "deadlineResumed": False}
            prior_identity["authorizationRepaired"] = repaired_authorization
            prior_identity["environmentRepaired"] = repaired_environment
            if repaired_environment:
                request["prior"] = None  # This exact prelaunch denial has no child run.
                prior_identity["environmentPriorExpenditure"] = {
                    "budgetSeconds": previous["budgetSeconds"], "wholeSeconds": previous["wholeSeconds"],
                    "freshAttempt": True, "deadlineResumed": False}
            if (previous["outcome"] != "PASS" and previous["inputs"] == inputs
                    and previous["engineId"] == manifest["engineId"]
                    and not repaired_authorization and not repaired_environment):
                raise ValueError("unchanged failed research route; a new directory is not a causal change")
        except (OSError, KeyError, ValueError, TypeError) as error:
            receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
                       "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                       "budgetSeconds": recipe["budgetSeconds"], "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps},
                       "outcome": "DENY", "denial": str(error), "executionLaunched": False,
                       "prior": prior_identity, "hostEnvironment": host, "artifacts": {}, "childReceiptSha256": None,
                       "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
            return retain_receipt(receipt)
    if host is not None and host["available"] is not True:
        receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
                   "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                   "budgetSeconds": recipe["budgetSeconds"], "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps},
                   "outcome": "DENY", "denial": host_environment.ERROR, "hostEnvironment": host,
                   "wholeSeconds": time.monotonic() - started,
                   "executionLaunched": False, "prior": prior_identity, "artifacts": {}, "childReceiptSha256": None,
                   "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
        return retain_receipt(receipt)
    request["launchOwner"] = str(out / "launch-owner.json")
    header = {"schema": "research-run-header.v1", "runId": uuid.uuid4().hex,
              "declaration": dict(recipe, steps=steps),
              "recipe": recipe["id"], "inputs": inputs, "engineId": manifest["engineId"],
              "clockEpoch": clock_epoch(), "startedMonotonic": started, "deadlineMonotonic": deadline,
              "budgetSeconds": recipe["budgetSeconds"],
              "stepBudgets": {step["id"]: step["budgetSeconds"] for step in steps},
              "request": dict(request), "executionCompleted": False,
              "prior": prior_identity,
              "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
    if "timeoutPolicy" in recipe:
        header["timeoutPolicy"] = recipe["timeoutPolicy"]
    journal = retain_run_record(root, out / "run-header.json", "research:" + recipe["id"], header, inputs)
    request["journal"] = journal
    (out / "request.json").write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    environment = host_environment.execution_environment(root, os.environ)
    metadata = {}
    command = [manifest["hostTools"]["python"]["path"], "-I", "-B", str(engine / "runner.py"), str(out / "request.json")]
    code, log, timeout, seconds = execute(command, root, max(0.001, deadline - time.monotonic()),
                                        env=environment, metadata=metadata,
                                        process_recorder=process_recorder(root, out, journal,
                                            owner_path=Path(request["launchOwner"]), deadline=deadline),
                                        completion_check=lambda: completed_stage_frontier(out, steps, journal),
                                        completion_grace=30,
                                        **({"progress_check": lambda stdout, stderr: completed_work(out, steps)}
                                           if progress_mode else {}))
    (out / "launch.log").write_text(log)
    child = out / "run/receipt.json"
    child_outcome = read_json(child)["outcome"] if child.is_file() else "DENY"
    try:
        manifest_paths(engine)
        stable = inputs == {name: digest(root / name) for name in inputs}
    except (OSError, ValueError):
        stable = False
    outcome = "STALE" if not stable else "PASS" if code == 0 and not timeout and child_outcome == "PASS" else "DENY"
    receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
               "engineId": manifest["engineId"], "inputs": inputs, "root": str(root), "budgetSeconds": recipe["budgetSeconds"],
               "stepBudgets": {step["id"]: step["budgetSeconds"] for step in steps},
               "outcome": outcome, "childOutcome": child_outcome, "argv": command, "environment": environment,
               "performanceBudgetExceeded": time.monotonic() > deadline,
               "exit": code, "timeout": timeout, "seconds": seconds, "wholeSeconds": time.monotonic() - started,
               "executionLaunched": True, "prior": prior_identity, "hostEnvironment": host,
               "journal": journal,
               "artifacts": {name: digest(out / name) for name in ("launch.log", "request.json")},
               "childReceiptSha256": digest(child) if child.is_file() else None,
               "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False,
               **metadata}
    return retain_receipt(receipt)


def inspect(out, *, input_archive=None, include_resumption=False):
    from gambit_smp.recipes import inspect_run, read_json
    if (out / "engine.json").is_file():
        if input_archive is not None or (out / "receipt.json").exists():
            raise ValueError("engine inspection requires an unambiguous seal, not a run or input archive")
        manifest = manifest_paths(out)
        dependencies = {name for name in manifest["hostTools"] if name.startswith("quint-file:")}
        return {"artifactKind": "sealed-engine", "engineId": manifest["engineId"],
                "hostTools": {name: row for name, row in manifest["hostTools"].items()
                              if name not in dependencies},
                "hostToolDependencyCount": len(dependencies),
                "capabilities": manifest["capabilities"],
                "identityStatus": "CURRENT", "executionLaunched": False,
                "runtimeAdmitted": False, "releaseAdmitted": False,
                "sourceRefinementAdmitted": False}
    if not (out / "receipt.json").exists():
        from gambit_smp.artifact_storage import repository_root
        from gambit_smp.step_checkpoint import recovered_resumption, interrupted_resumption
        from gambit_smp.reasoning_history import read_execution_checkpoint
        ancestor = out
        while not ancestor.exists():
            ancestor = ancestor.parent
        root = repository_root(ancestor)
        if read_execution_checkpoint(root, out)["records"]:
            return recovered_resumption(root, out)
        if (out / "run-header.json").is_file():
            return interrupted_resumption(root, out)
    receipt = read_json(out / "receipt.json")
    if receipt.get("schema") != "sealed-research-run.v1":
        raise ValueError("sealed research receipt required")
    child_state = None
    binding_stable = False
    try:
        from gambit_smp.historical_inputs import bindings, match
        root = Path(receipt["root"])
        archived, _ = bindings(root, out / "receipt.json", input_archive) if input_archive else ({}, [])
        engine = manifest_paths(Path(receipt["engine"]))
        stable = engine["engineId"] == receipt["engineId"]
        stable = stable and match({str(root / name): value for name, value in receipt["inputs"].items()}, archived)
        stable = stable and all(digest(out / name) == value for name, value in receipt["artifacts"].items())
        if receipt.get("executionLaunched", True):
            stable = stable and digest(out / "run/receipt.json") == receipt["childReceiptSha256"]
            child_state = inspect_run(out / "run", input_bindings=archived)
            binding_stable = stable and child_state["evidenceBindingStatus"] in {"CURRENT", "HISTORICAL_BOUND"}
            stable = stable and child_state["identityStatus"] in {"CURRENT", "HISTORICAL_BOUND"}
        else:
            binding_stable = stable
    except (OSError, KeyError, ValueError, TypeError):
        stable = False
    result = {"recipe": receipt["recipe"], "engineId": receipt["engineId"], "outcome": receipt["outcome"],
            "identityStatus": ("HISTORICAL_BOUND" if input_archive else "CURRENT") if stable else "STALE",
            "evidenceBindingStatus": (("HISTORICAL_BOUND" if input_archive else "CURRENT")
                                      if binding_stable else "STALE"),
            "artifactAvailability": child_state["artifactAvailability"] if child_state else
                                    {"status": "UNKNOWN", "outputs": []},
            "recordedOutcome": receipt["outcome"],
            "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
    if include_resumption and input_archive is None:
        from gambit_smp.step_checkpoint import resumption
        result["resumption"] = resumption(Path(receipt["root"]), out, result)
    return result


def main():
    from gambit_smp.recipes import discover, load, source_path
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--seal", type=Path)
    selection.add_argument("--run")
    selection.add_argument("--read", type=Path,
                           help="validate and inspect a sealed engine or retained research run; never execute")
    selection.add_argument("--export-producer", type=Path)
    selection.add_argument("--export-runtime", type=Path)
    parser.add_argument("--step")
    parser.add_argument("--input-archive", help="exact historical source-input archive for producer export")
    parser.add_argument("--engine", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--prior", type=Path)
    parser.add_argument("--gcc", type=Path)
    parser.add_argument("--quint", type=Path)
    parser.add_argument("--node", type=Path)
    parser.add_argument("--ascent-api", type=Path)
    parser.add_argument("--provider-sources", type=Path,
                        help="validated engine archive for exact provider build inputs")
    parser.add_argument("--portable-seal", action="store_true",
                        help="copy sealed generations for transport to another host job")
    args = parser.parse_args()
    if args.portable_seal and not args.seal:
        parser.error("--portable-seal requires --seal")
    from gambit_smp.artifact_storage import runtime_output
    if args.seal:
        args.seal = runtime_output(ROOT, args.seal)
    if args.out and not args.export_producer:
        args.out = runtime_output(ROOT, args.out)
    try:
        if args.seal:
            if args.gcc is None or args.ascent_api is None:
                parser.error("--seal requires host-selected --gcc and --ascent-api")
            manifest = seal(args.seal, gcc=args.gcc, quint=args.quint, node=args.node,
                            ascent_api=args.ascent_api, provider_sources=args.provider_sources,
                            portable=args.portable_seal)
            print(json.dumps({"engineId": manifest["engineId"], "files": len(manifest["files"])}))
            return 0
        if args.read:
            if args.step is not None:
                from gambit_smp.step_checkpoint import observe_journal
                proof, _, _, _ = observe_journal(ROOT, args.read, args.step)
                print(json.dumps(proof, indent=2))
            else:
                print(json.dumps(inspect(args.read.resolve(), input_archive=args.input_archive,
                                         include_resumption=True), indent=2))
            return 0
        if args.export_producer:
            from gambit_smp.completed_producer import export_reference
            if args.out is None or args.step is None:
                parser.error("--export-producer requires --step and a fresh research Evidence --out")
            print(json.dumps(export_reference(ROOT, args.export_producer, args.step, args.out,
                                              input_archive=args.input_archive), indent=2))
            return 0
        if args.export_runtime:
            from gambit_smp.runtime_artifact import supervised_export
            if args.out is None or args.step is None:
                parser.error("--export-runtime requires --step and a fresh archive --out")
            print(json.dumps(supervised_export(ROOT, args.export_runtime.resolve(), args.step, args.out), indent=2))
            return 0
        root = ROOT.resolve()
        if "/" in args.run or args.run.endswith(".recipe.json"):
            selected = source_path(root, args.run)
            load(root, selected)
        else:
            selected = discover(root).get(args.run)
        if selected is None or args.engine is None or args.out is None:
            parser.error("--run requires a declared recipe, --engine seal, and --out run directory")
        receipt = run_sealed(root, selected, args.out, args.engine.resolve(), prior=args.prior, allow_native=True)
        keys = (("recipe", "engineId", "outcome", "resumeStatus", "executionLaunched", "wholeSeconds",
                 "requestedIdentityMatches", "resumption")
                if "resumption" in receipt else ("recipe", "engineId", "outcome", "exit", "timeout", "denial"))
        print(json.dumps({key: receipt.get(key) for key in keys}))
        return 0 if receipt["outcome"] == "PASS" else 2
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("RESEARCH-DENY " + str(error), file=sys.stderr)
        return 2
