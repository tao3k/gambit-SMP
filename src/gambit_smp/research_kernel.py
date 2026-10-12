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
from pathlib import Path
import shutil
import sys
import time

from gambit_smp.framework import ROOT, digest, execute, relative


SCHEMA = "evidence-recipe.v2"
ENGINE_SCHEMA = "research-engine-seal.v1"
ALLOWED = frozenset({"gambit.materialize", "source.overlay", "source.project", "source.bind",
                     "native.workspace-build", "native.test", "quint.parse", "quint.typecheck", "quint.test", "quint.verify",
                     "evidence.evaluate", "gambit.configure", "gambit.object", "gambit.seed-core",
                     "gambit.regenerate-module", "gambit.source-core", "gambit.bootstrap", "gambit.suite", "gambit.review"})
FORBIDDEN_IMPORTS = frozenset({"source_unit", "ffi_source_unit", "allocator_acquire", "allocator_object",
                               "sync_retirement_source", "gc_wait_source", "gc_queue_binding"})


def canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True).encode()


def content_id(value):
    return hashlib.sha256(canonical(value)).hexdigest()


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
        for node in ast.walk(ast.parse(path.read_text(), filename=str(path))):
            dependencies = []
            if isinstance(node, ast.ImportFrom) and node.module == "gambit_smp":
                dependencies.extend(alias.name for alias in node.names)
            elif isinstance(node, ast.ImportFrom) and node.module and node.module.startswith("gambit_smp."):
                dependencies.append(node.module.split(".")[1])
            elif isinstance(node, ast.Import):
                dependencies.extend(alias.name.split(".")[1] for alias in node.names if alias.name.startswith("gambit_smp."))
            for child in dependencies:
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
        if step["capability"] in {"gambit.suite", "gambit.bootstrap"}:
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


def manifest_paths(engine):
    from gambit_smp.recipes import read_json
    engine = engine.resolve(strict=True)
    manifest = read_json(engine / "engine.json")
    if manifest.get("schema") != ENGINE_SCHEMA:
        raise ValueError("sealed research engine required")
    identity = {key: value for key, value in manifest.items() if key != "engineId"}
    if manifest.get("engineId") != content_id(identity):
        raise ValueError("engine manifest identity mismatch")
    for name, expected in manifest["files"].items():
        if not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts:
            raise ValueError("relative sealed implementation path required")
        path = engine / name
        if path.is_symlink() or not path.resolve().is_relative_to(engine) or digest(path) != expected:
            raise ValueError("sealed engine implementation drift")
    inventory = {path.relative_to(engine).as_posix() for path in engine.rglob("*") if path.is_file()}
    if inventory != set(manifest["files"]) | {"engine.json"}:
        raise ValueError("sealed engine inventory drift")
    for name, row in manifest["hostTools"].items():
        if digest(Path(row["path"])) != row["sha256"]:
            raise ValueError("sealed host tool drift: " + name)
    return manifest


def seal(out, *, gcc, quint=None, node=None, ascent_api):
    from gambit_smp.recipes import read_json, tool_files
    from gambit_smp.native_review import POLICY
    from gambit_smp.provider_contract import inspect_provider
    out = out.resolve()
    if out.exists():
        raise ValueError("engine seals are immutable; a fresh directory is required")
    package = Path(__file__).resolve().parent
    if out.is_relative_to(package):
        raise ValueError("engine seal cannot overwrite its implementation")
    api = ascent_api.resolve(strict=True)
    build = read_json(api / "receipt.json")
    libraries = [path for path in api.iterdir() if path.name.startswith("_ascent_cffi") and path.suffix in {".so", ".pyd"}]
    library = api / ("libascent.dylib" if sys.platform == "darwin" else "libascent.so")
    if (len(libraries) != 1 or build.get("schema") != "ascent.cffi-api-build.v1"
            or digest(libraries[0]) != build.get("extensionSha256") or digest(library) != build.get("librarySha256")):
        raise ValueError("receipt-bound installed native ASCENT API required")
    spec = importlib.util.find_spec("ascent_engine")
    if spec is None or not spec.submodule_search_locations:
        raise ValueError("installed ASCENT Python binding required; no fallback")
    binding = Path(next(iter(spec.submodule_search_locations))).resolve(strict=True)
    originals = {**{path: "python/gambit_smp/" + path.relative_to(package).as_posix()
                    for path in implementation_paths(package)},
                 **{path: "python/ascent_engine/" + path.relative_to(binding).as_posix()
                    for path in binding.rglob("*.py")},
                 **{path: "native/" + path.name for path in [*libraries, library, api / "receipt.json"]},
                 ROOT / POLICY: "policy/suite-review-rules.ss"}
    for name, expected in build.get("syntaxResources", {}).items():
        source = relative(api / "syntax", name)
        if digest(source) != expected:
            raise ValueError("receipt-bound native syntax resources required")
        originals[source] = "native/syntax/" + name
    before = {path: digest(path) for path in originals}
    provider_contract = inspect_provider(api, binding)
    host = {"python": Path(sys.executable).absolute(), "gcc": gcc.absolute()}
    if (quint is None) != (node is None):
        raise ValueError("Quint and Node must be sealed together")
    if quint is not None:
        host.update(quint=quint.absolute(), node=node.absolute())
        host.update({"quint-file:" + str(path): path for path in tool_files(quint, node)})
    tools = {name: {"path": str(path), "sha256": digest(path)} for name, path in host.items()}
    out.mkdir(parents=True)
    for path, name in originals.items():
        target = relative(out, name)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(path, target)
    runner = out / "runner.py"
    runner.write_text("import sys\nfrom pathlib import Path\n"
                      "root = Path(__file__).resolve().parent\n"
                      "sys.path[:0] = [str(root / 'python'), str(root / 'native')]\n"
                      "from gambit_smp.research_kernel import worker\n"
                      "raise SystemExit(worker(root))\n")
    if any(digest(path) != expected for path, expected in before.items()):
        raise ValueError("implementation/provider changed while sealing; incomplete seal is not admissible")
    files = {path.relative_to(out).as_posix(): digest(path) for path in out.rglob("*") if path.is_file()}
    identity = {"schema": ENGINE_SCHEMA, "files": files, "hostTools": tools,
                "providerContract": provider_contract,
                "capabilities": sorted(ALLOWED), "pythonVersion": sys.version,
                "scope": "closed research implementation and selected native API, host transitive libraries not hermetic",
                "runtimeAdmitted": False, "releaseAdmitted": False}
    manifest = {**identity, "engineId": content_id(identity)}
    (out / "engine.json").write_text(json.dumps(manifest, sort_keys=True, indent=2) + "\n")
    for path in out.rglob("*"):
        if path.is_file():
            path.chmod(0o444)
    for path in sorted((path for path in out.rglob("*") if path.is_dir()), reverse=True):
        path.chmod(0o555)
    out.chmod(0o555)
    manifest_paths(out)
    return manifest


def execution_identity(engine):
    manifest = manifest_paths(engine)
    code = engine / "python/gambit_smp"
    if not Path(__file__).resolve().is_relative_to(code.resolve()):
        raise ValueError("new research must execute the sealed implementation, not the editable checkout")
    for name, module in tuple(sys.modules.items()):
        if name.startswith("gambit_smp.") and name.rsplit(".", 1)[1] in FORBIDDEN_IMPORTS:
            raise ValueError("historical feature producer loaded into the new research lane")
        if name.startswith(("gambit_smp", "ascent_engine", "_ascent_cffi")) and getattr(module, "__file__", None):
            path = Path(module.__file__).resolve()
            if not path.is_relative_to(engine.resolve()):
                raise ValueError("research implementation escaped its engine seal")
    return manifest


def worker(engine):
    from gambit_smp.recipes import load, read_json, run
    manifest = execution_identity(engine)
    if sys.argv[1] == "rules":
        from gambit_smp.evidence_capabilities import native_evaluate
        request = read_json(Path(sys.argv[2]))
        if request["engineId"] != manifest["engineId"]:
            raise ValueError("native evaluator selected a different engine seal")
        native_evaluate(request)
        execution_identity(engine)
        return 0
    request = read_json(Path(sys.argv[1]))
    if request["engineId"] != manifest["engineId"]:
        raise ValueError("launch selected a different engine seal")
    def guard(event, args):
        if event == "import" and args[0].startswith("gambit_smp.") and args[0].split(".")[1] in FORBIDDEN_IMPORTS:
            raise ImportError("historical feature producers are unavailable in the sealed research lane")
    sys.addaudithook(guard)
    root = Path(request["root"])
    recipe, _ = load(root, root / request["recipe"])
    if recipe["schema"] != SCHEMA:
        raise ValueError("new research lane requires artifact-graph v2")
    tools = manifest["hostTools"]
    receipt = run(root, root / request["recipe"], Path(request["out"]),
                  Path(tools["quint"]["path"]) if "quint" in tools else Path("quint"),
                  Path(tools["node"]["path"]) if "node" in tools else Path("node"),
                  Path(request["prior"]) if request["prior"] else None,
                  gcc=Path(tools["gcc"]["path"]), allow_native=request["allowNative"],
                  engine=engine, deadline=request["deadline"])
    execution_identity(engine)
    print(json.dumps({"engineId": manifest["engineId"], "recipe": receipt["recipe"], "outcome": receipt["outcome"]}))
    return 0 if receipt["outcome"] == "PASS" else 2


def run_sealed(root, path, out, engine, *, prior=None, allow_native=False):
    from gambit_smp.recipes import load, read_json, authorization_repair
    started = time.monotonic()
    recipe, steps = load(root, path)
    if recipe["schema"] != SCHEMA:
        raise ValueError("historical recipes cannot claim a new architecture run")
    manifest = manifest_paths(engine)
    inputs = {name: digest(root / name) for name in [path.relative_to(root).as_posix(), *recipe["inputs"]]}
    out = out.resolve()
    if out.is_relative_to(root / "evidence") or any((root / name).resolve().is_relative_to(out) for name in inputs):
        raise ValueError("execution cannot overwrite its Evidence inputs")
    out.mkdir(parents=True, exist_ok=False)
    deadline = started + recipe["budgetSeconds"]
    request = {"engineId": manifest["engineId"], "root": str(root), "recipe": path.relative_to(root).as_posix(),
               "out": str(out / "run"), "prior": str(prior / "run") if prior else None,
               "allowNative": allow_native, "deadline": deadline}
    prior_identity = None
    if prior is not None:
        try:
            previous = read_json(prior / "receipt.json")
            prior_identity = {"receiptSha256": digest(prior / "receipt.json"), "engineId": previous["engineId"],
                              "changedInputs": {name: value for name, value in inputs.items() if previous["inputs"].get(name) != value},
                              "engineChanged": previous["engineId"] != manifest["engineId"]}
            if previous.get("schema") != "sealed-research-run.v1" or previous["recipe"] != recipe["id"]:
                raise ValueError("matching sealed prior observation required")
            if recipe["budgetSeconds"] > previous["budgetSeconds"]:
                raise ValueError("prior budget cannot expand")
            old_steps = previous["stepBudgets"]
            if any(step["id"] in old_steps and step["budgetSeconds"] > old_steps[step["id"]] for step in steps):
                raise ValueError("prior step budget cannot expand")
            repaired_authorization = False
            child_path = prior / "run/receipt.json"
            if previous.get("childReceiptSha256") is not None:
                if digest(child_path) != previous["childReceiptSha256"]:
                    raise ValueError("prior child receipt was changed")
                repaired_authorization = authorization_repair(read_json(child_path), allow_native,
                                                             manifest["hostTools"].get("gcc"))
            prior_identity["authorizationRepaired"] = repaired_authorization
            if (previous["outcome"] != "PASS" and previous["inputs"] == inputs
                    and previous["engineId"] == manifest["engineId"] and not repaired_authorization):
                raise ValueError("unchanged failed research route; a new directory is not a causal change")
        except (OSError, KeyError, ValueError, TypeError) as error:
            receipt = {"schema": "sealed-research-run.v1", "recipe": recipe["id"], "engine": str(engine),
                       "engineId": manifest["engineId"], "inputs": inputs, "root": str(root),
                       "budgetSeconds": recipe["budgetSeconds"], "stepBudgets": {s["id"]: s["budgetSeconds"] for s in steps},
                       "outcome": "DENY", "denial": str(error), "executionLaunched": False,
                       "prior": prior_identity, "artifacts": {}, "childReceiptSha256": None,
                       "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False}
            (out / "receipt.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
            return receipt
    (out / "request.json").write_text(json.dumps(request, sort_keys=True, indent=2) + "\n")
    environment = {"GAMBIT_SMP_ROOT": str(root), "PYTHONDONTWRITEBYTECODE": "1",
                   "PATH": "/usr/bin:/bin", "HOME": os.environ.get("HOME", str(root)), "LANG": "C", "LC_ALL": "C"}
    metadata = {}
    command = [manifest["hostTools"]["python"]["path"], "-I", "-B", str(engine / "runner.py"), str(out / "request.json")]
    code, log, timeout, seconds = execute(command, root, max(0.001, deadline - time.monotonic()),
                                        env=environment, metadata=metadata)
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
               "exit": code, "timeout": timeout, "seconds": seconds, "wholeSeconds": time.monotonic() - started,
               "executionLaunched": True, "prior": prior_identity,
               "artifacts": {name: digest(out / name) for name in ("launch.log", "request.json")},
               "childReceiptSha256": digest(child) if child.is_file() else None,
               "runtimeAdmitted": False, "releaseAdmitted": False, "sourceRefinementAdmitted": False,
               **metadata}
    (out / "receipt.json").write_text(json.dumps(receipt, sort_keys=True, indent=2) + "\n")
    return receipt


def inspect(out):
    from gambit_smp.recipes import inspect_run, read_json
    receipt = read_json(out / "receipt.json")
    if receipt.get("schema") != "sealed-research-run.v1":
        raise ValueError("sealed research receipt required")
    try:
        engine = manifest_paths(Path(receipt["engine"]))
        stable = engine["engineId"] == receipt["engineId"]
        stable = stable and all(digest(Path(receipt["root"]) / name) == value for name, value in receipt["inputs"].items())
        stable = stable and all(digest(out / name) == value for name, value in receipt["artifacts"].items())
        if receipt.get("executionLaunched", True):
            stable = stable and digest(out / "run/receipt.json") == receipt["childReceiptSha256"]
            stable = stable and inspect_run(out / "run")["identityStatus"] == "CURRENT"
    except (OSError, KeyError, ValueError, TypeError):
        stable = False
    return {"recipe": receipt["recipe"], "engineId": receipt["engineId"], "outcome": receipt["outcome"],
            "identityStatus": "CURRENT" if stable else "STALE", "runtimeAdmitted": False, "sourceRefinementAdmitted": False}


def main():
    from gambit_smp.recipes import discover
    parser = argparse.ArgumentParser(description=__doc__)
    selection = parser.add_mutually_exclusive_group(required=True)
    selection.add_argument("--seal", type=Path)
    selection.add_argument("--run")
    selection.add_argument("--read", type=Path)
    parser.add_argument("--engine", type=Path)
    parser.add_argument("--out", type=Path)
    parser.add_argument("--prior", type=Path)
    parser.add_argument("--gcc", type=Path)
    parser.add_argument("--quint", type=Path)
    parser.add_argument("--node", type=Path)
    parser.add_argument("--ascent-api", type=Path)
    args = parser.parse_args()
    try:
        if args.seal:
            if args.gcc is None or args.ascent_api is None:
                parser.error("--seal requires host-selected --gcc and --ascent-api")
            manifest = seal(args.seal, gcc=args.gcc, quint=args.quint, node=args.node, ascent_api=args.ascent_api)
            print(json.dumps({"engineId": manifest["engineId"], "files": len(manifest["files"])}))
            return 0
        if args.read:
            print(json.dumps(inspect(args.read.resolve()), indent=2))
            return 0
        found = discover(ROOT)
        if args.run not in found or args.engine is None or args.out is None:
            parser.error("--run requires a declared recipe, --engine seal, and fresh --out")
        receipt = run_sealed(ROOT, found[args.run], args.out, args.engine.resolve(), prior=args.prior, allow_native=True)
        print(json.dumps({key: receipt.get(key) for key in ("recipe", "engineId", "outcome", "exit", "timeout", "denial")}))
        return 0 if receipt["outcome"] == "PASS" else 2
    except (OSError, ValueError, KeyError, TypeError) as error:
        print("RESEARCH-DENY " + str(error), file=sys.stderr)
        return 2
