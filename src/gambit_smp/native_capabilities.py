"""Typed native capability family; experiment choices remain Evidence data."""
import json
import os
from pathlib import Path
import re
import shutil
import tarfile
import time
from concurrent.futures import ThreadPoolExecutor

from gambit_smp.framework import available_processors, digest, gnu_build_driver, relative


TREE_TYPES = {"source-tree", "configured-tree", "seed-runtime", "source-runtime"}


def fields(value, required, optional=()):
    from gambit_smp.recipes import fields as check
    check(value, required, optional)


def reference(value):
    fields(value, ("step", "output"))
    if any(not isinstance(item, str) for item in value.values()):
        raise ValueError("typed step/output reference required")


def graph(step, by_id, registry):
    contracts = {
        "gambit.configure": {"source": {"source-tree"}},
        "gambit.object": {"source": {"configured-tree"}},
        "gambit.seed-core": {"source": {"configured-tree"}},
        "gambit.regenerate-module": {"runtime": {"seed-runtime"}},
        "gambit.source-core": {"runtime": {"seed-runtime"}},
        "gambit.bootstrap": {"runtime": {"seed-runtime"}},
        "gambit.suite": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.review": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "native.test": {"executable": {"native-executable"}},
    }
    for argument, types in contracts.get(step["capability"], {}).items():
        ref = step["arguments"][argument]
        reference(ref)
        producer = by_id.get(ref["step"])
        if producer is None or ref["step"] not in step["dependsOn"]:
            raise ValueError("artifact reference requires an explicit dependency")
        outputs = dict(registry[producer["capability"]].outputs)
        if producer["capability"] in {"native.c-build", "native.workspace-build"}:
            target = producer["arguments"]["target"]
            outputs = {"executable": "native-executable"} if target == "executable" else {"object": "native-object"}
        if outputs.get(ref["output"]) not in types:
            raise ValueError("artifact reference type mismatch")
    if step["capability"] == "gambit.suite" and (
            step["arguments"]["runtime"]["step"] != step["arguments"]["identity"]["step"]):
        raise ValueError("suite runtime and identity must have the same producer")
    if step["capability"] == "gambit.review":
        args = step["arguments"]
        target = by_id.get(args["target"])
        if (target is None or target["capability"] != "gambit.suite"
                or step["id"] not in target["dependsOn"]
                or target["arguments"].get("retryReview") != {"step": step["id"], "output": "review"}
                or any(target["arguments"][key] != args[key] for key in ("runtime", "identity"))
                or args["runtime"]["step"] != args["identity"]["step"]):
            raise ValueError("review must bind one matching same-producer downstream suite")
    if step["capability"] == "gambit.suite" and isinstance(step["arguments"].get("retryReview"), dict):
        ref = step["arguments"]["retryReview"]
        reference(ref)
        producer = by_id.get(ref["step"])
        if (producer is None or ref["step"] not in step["dependsOn"]
                or producer["capability"] != "gambit.review" or ref["output"] != "review"
                or producer["arguments"]["target"] != step["id"]):
            raise ValueError("suite requires its declared bound review producer")


def validate_materialize(args, inputs):
    fields(args, ("sourceLock",))
    if args["sourceLock"] not in inputs or not args["sourceLock"].endswith(".lock.json"):
        raise ValueError("declared source lock required")


def validate_configure(args, inputs):
    fields(args, ("source", "cOptimization", "rtsOptimization"))
    reference(args["source"])
    for value in (args["cOptimization"], args["rtsOptimization"]):
        if type(value) is not int or value not in range(4):
            raise ValueError("explicit C and RTS optimization levels 0 through 3 required")


def validate_source(args, inputs):
    fields(args, ("source",))
    reference(args["source"])


def validate_object(args, inputs):
    fields(args, ("source",), ("translationUnit", "defines"))
    reference(args["source"])
    unit = args.get("translationUnit", "lib/mem.c")
    if not isinstance(unit, str) or not re.fullmatch(r"lib/[A-Za-z_][A-Za-z0-9_]*\.c", unit):
        raise ValueError("explicit library C translation unit required")
    defines = args.get("defines", [])
    if (not isinstance(defines, list) or any(not isinstance(value, str) or
            not re.fullmatch(r"[A-Z_][A-Z0-9_]*(?:=[0-9]+)?", value) for value in defines)
            or len(set(defines)) != len(defines)):
        raise ValueError("unique typed preprocessor definitions required")


def validate_runtime(args, inputs):
    fields(args, ("runtime",))
    reference(args["runtime"])


def validate_bootstrap(args, inputs):
    fields(args, ("runtime",), ("identity", "failures", "reviewRules", "retryReview"))
    reference(args["runtime"])
    if "identity" in args:
        reference(args["identity"])
    if "retryReview" in args and (args["retryReview"] not in inputs or not args["retryReview"].endswith(".json")):
        raise ValueError("retry review must be a declared typed data input")


def validate_regenerate(args, inputs):
    fields(args, ("runtime", "module"))
    reference(args["runtime"])
    if not isinstance(args["module"], str) or not re.fullmatch(r"(?:lib|gsi|gsc)/_[A-Za-z0-9_-]+\.scm", args["module"]):
        raise ValueError("explicit Gambit Scheme module required")


def validate_suite(args, inputs):
    fields(args, ("runtime", "identity", "mode", "regime", "selection", "expectedFiles"),
           ("processors", "jobs", "batchBudgetSeconds", "failures", "reviewRules", "retryReview"))
    reference(args["runtime"])
    reference(args["identity"])
    if "retryReview" in args:
        if isinstance(args["retryReview"], dict):
            reference(args["retryReview"])
        elif args["retryReview"] not in inputs or not args["retryReview"].endswith(".json"):
            raise ValueError("retry review must be declared data or a typed artifact")
    if args["mode"] not in {"gsi", "gsc"}:
        raise ValueError("explicit suite mode required")
    if args["regime"] not in {"whole-sequential", "whole-parallel", "atomic-coverage"}:
        raise ValueError("explicit suite budget regime required")
    for field in ("selection", "expectedFiles"):
        value = args[field]
        if (not isinstance(value, list) or not value or any(not isinstance(name, str) or
                Path(name).is_absolute() or ".." in Path(name).parts for name in value)
                or len(value) != len(set(value))):
            raise ValueError("exact nonempty suite selection and file inventory required")
    for key in ("processors", "jobs"):
        if key in args and (type(args[key]) is not int or args[key] <= 0):
            raise ValueError("positive processor/job control required")
    if args["regime"] == "whole-sequential" and "jobs" in args:
        raise ValueError("sequential suite cannot request shard jobs")
    if args["regime"] == "atomic-coverage":
        from gambit_smp.recipes import budget
        budget(args.get("batchBudgetSeconds"))
    elif "batchBudgetSeconds" in args:
        raise ValueError("batch budget belongs only to atomic coverage")


def validate_c(args, inputs):
    fields(args, ("sources", "headers", "standard", "optimization", "pthread", "target"), ("defines",))
    defines = args.get("defines", [])
    if (not isinstance(defines, list) or any(
            not isinstance(value, str) or not re.fullmatch(r"[A-Z_][A-Z0-9_]*(?:=[0-9]+)?", value)
            for value in defines) or len(defines) != len(set(defines))):
        raise ValueError("C defines require unique typed macro names and optional integer values")
    if args["standard"] not in {"c11", "gnu11"} or args["target"] not in {"executable", "object"}:
        raise ValueError("supported C standard and target required")
    if type(args["optimization"]) is not int or args["optimization"] not in range(4) or type(args["pthread"]) is not bool:
        raise ValueError("typed optimization and pthread controls required")
    for field, suffixes in (("sources", {".c"}), ("headers", {".h", ".inc"})):
        value = args[field]
        if (not isinstance(value, list) or (field == "sources" and len(value) != 1)
                or any(not isinstance(name, str) or name not in inputs or Path(name).suffix not in suffixes for name in value)
                or len(value) != len(set(value))):
            raise ValueError("one declared C translation unit and explicit local include closure required")


def validate_native_test(args, inputs):
    fields(args, ("executable", "cases"))
    reference(args["executable"])
    cases = args["cases"]
    if not isinstance(cases, list) or not 1 <= len(cases) <= 128:
        raise ValueError("bounded exact native case inventory required")
    names = set()
    from gambit_smp.recipes import IDENTIFIER
    for case in cases:
        fields(case, ("id", "integers", "stdout"), ("expectedExit", "negativeControl"))
        expected = case.get("expectedExit", 0)
        negative = case.get("negativeControl", False)
        if (type(expected) is not int or not 0 <= expected <= 125
                or type(negative) is not bool or negative != (expected != 0)):
            raise ValueError("nonzero native exit requires an explicit negative control; signals cannot pass")
        if not isinstance(case["id"], str) or not IDENTIFIER.fullmatch(case["id"]) or case["id"] in names:
            raise ValueError("unique native case identity required")
        names.add(case["id"])
        if (not isinstance(case["integers"], list) or len(case["integers"]) > 16
                or any(type(value) is not int or abs(value) > 2**31 - 1 for value in case["integers"])):
            raise ValueError("bounded integer native operands required")
        if not isinstance(case["stdout"], str) or len(case["stdout"].encode()) > 65536:
            raise ValueError("bounded exact stdout observation required")


def host_tools(gcc, steps, environment):
    tools = {"gcc": gcc.resolve(strict=True)}
    kinds = {step["capability"] for step in steps}
    required = {"as", "ld"}
    if any(kind.startswith("gambit.") for kind in kinds) or "source.overlay" in kinds:
        required.update({"git", "make", "sh"})
    if "gambit.configure" in kinds:
        required.update({"autoconf", "m4"})
    env = dict(environment)
    # An explicitly selected Node installation must not replace the native
    # compiler's system assembler/linker with its unrelated package-manager tools.
    directories = [str(gcc.absolute().parent), "/usr/bin", "/bin", "/usr/sbin", "/sbin",
                   *environment.get("PATH", "").split(os.pathsep)]
    directories = [directory for directory in directories if directory]
    for name in sorted(required):
        path = shutil.which(name, path=os.pathsep.join(directories)) or (
            shutil.which(name) if name in {"autoconf", "m4"} else None)
        if path is None:
            raise ValueError("required native tool missing: " + name)
        tools[name] = Path(path).resolve(strict=True)
        if name in {"autoconf", "m4"}:
            directories.append(str(Path(path).absolute().parent))
    env.update(PATH=os.pathsep.join(dict.fromkeys(directories)), CC=str(tools["gcc"]))
    return tools, env


def implementation_files(steps):
    # Bind reusable helpers conservatively, including the retry reasoning closure.
    return list(Path(__file__).parent.glob("*.py"))


def compiler(ctx):
    gcc = ctx.tools["gcc"]
    version = ctx.require("compiler-version", [gcc, "--version"], ctx.root, 10)
    if "gcc" not in version.lower() or "clang" in version.lower():
        raise ValueError("GNU GCC required")
    backend = ctx.require("compiler-backend", [gcc, "-print-prog-name=cc1"], ctx.root, 10).strip()
    path = Path(backend)
    if not path.is_absolute():
        path = Path(shutil.which(backend, path=ctx.env["PATH"]) or backend)
    ctx.bind([path])
    return gcc


def materialize(args, ctx):
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.source_capabilities import validate_source_lock, source_file
    lock_path = source_path(ctx.root, args["sourceLock"])
    lock = read_json(lock_path)
    validate_source_lock(lock)
    if lock["patch"] not in ctx.receipt["declaredInputs"]:
        raise ValueError("source overlay must be an explicitly declared input")
    patch = source_path(ctx.root, lock["patch"])
    if digest(patch) != lock["patchSha256"] or not isinstance(lock["files"], dict) or not lock["files"]:
        raise ValueError("locked overlay identity required")
    checkout = relative(ctx.root, lock["submodule"])
    if checkout != ctx.root.resolve() / "vendor/gambit":
        raise ValueError("source repository cannot be an alias")
    from gambit_smp.recipes import CACHE_PARTS
    if any(part.casefold() in CACHE_PARTS for part in checkout.relative_to(ctx.root.resolve()).parts):
        raise ValueError("source repository cannot be a Cache alias")
    git = ctx.tools["git"]
    if ctx.require("revision", [git, "-C", checkout, "rev-parse", "HEAD"], ctx.root, 10).strip() != lock["revision"]:
        raise ValueError("source revision drift")
    gitdir = Path(ctx.require("git-directory", [git, "-C", checkout, "rev-parse", "--absolute-git-dir"], ctx.root, 10).strip())
    head = gitdir / "HEAD"
    ctx.bind([head])
    value = head.read_text().strip()
    if value.startswith("ref: "):
        ref = gitdir / value[5:]
        ctx.bind([ref if ref.is_file() else gitdir / "packed-refs"])
    archive = ctx.directory / "source.tar"
    ctx.require("archive", [git, "-C", checkout, "archive", "--output=" + str(archive), lock["revision"]], ctx.root, 30)
    source = ctx.directory / "source"
    source.mkdir()
    with tarfile.open(archive) as tree:
        tree.extractall(source, filter="data")
    for name, row in lock["files"].items():
        if digest(source_file(source, name)) != row["baseSha256"]:
            raise ValueError("archived source differs from lock")
    command = [git, "--git-dir=/dev/null", "apply"]
    stats = ctx.require("patch-inventory", [*command, "--numstat", "-z", patch], source, 10)
    names = []
    for row in stats.split("\0"):
        if row:
            added, removed, name = row.split("\t", 2)
            if not added.isdecimal() or not removed.isdecimal() or name not in lock["files"] or name in names:
                raise ValueError("source patch exceeds locked existing files")
            relative(source, name)
            names.append(name)
    if not names:
        raise ValueError("empty source patch")
    ctx.require("patch-check", [*command, "--whitespace=error", "--check", patch], source, 10)
    ctx.require("patch-apply", [*command, "--whitespace=error", patch], source, 10)
    for name, row in lock["files"].items():
        if digest(source_file(source, name)) != row["candidateSha256"]:
            raise ValueError("materialized candidate differs from lock")
    if ctx.require("revision-after", [git, "-C", checkout, "rev-parse", "HEAD"], ctx.root, 10).strip() != lock["revision"]:
        raise ValueError("source revision changed during materialization")
    return {"outputs": ctx.publish("source", "source-tree", source), "claim": "locked-source-slice-only"}


def clone(ctx, ref, kind):
    source = ctx.artifact(ref, kind)
    destination = ctx.directory / "source"
    shutil.copytree(source, destination, symlinks=True)
    ctx.remaining()
    return destination


def configure(args, ctx):
    source = clone(ctx, args["source"], "source-tree")
    compiler(ctx)
    ctx.require("autoconf", [ctx.tools["autoconf"], "-o", "configure", "configure.ac"], source, 30)
    flags = ["--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms",
             "--enable-c-opt=-O" + str(args["cOptimization"]),
             "--enable-c-opt-rts=-O" + str(args["rtsOptimization"])]
    ctx.require("configure", [ctx.tools["sh"], "./configure", *flags], source, 90)
    return {"outputs": ctx.publish("source", "configured-tree", source), "claim": "configuration-only"}


class Stages:
    """Use only stable build primitives; historical experiment CLIs are absent."""
    def __init__(self, ctx):
        self.ctx, self.out = ctx, ctx.directory

    def run(self, name, argv, cwd, cap):
        return self.ctx.run(name, argv, cwd, cap)

    @property
    def stdout(self):
        return self.ctx.last_stdout


def identity(ctx, source):
    files = {path.relative_to(source).as_posix(): digest(path) for folder in ("lib", "include", "gsi", "gsc")
             for path in (source / folder).rglob("*") if path.is_file() and
             (path.suffix in {".c", ".h", ".scm"} or path.name.endswith(".h.in"))}
    result = {"schema": "gambit-recipe-runtime-identity.v1", "sourceFiles": files,
              "binarySha256": digest(source / "gsi/gsi"), "gscSha256": digest(source / "gsc/gsc"),
              "librarySha256": digest(source / "lib/libgambit.a"),
              "runtimeAdmitted": False, "releaseAdmitted": False}
    path = ctx.directory / "identity.json"
    path.write_text(json.dumps(result, indent=2) + "\n")
    return ctx.publish("identity", "runtime-identity", path)


def seed(args, ctx):
    from gambit_smp.gambit_build_primitives import build_seed_core
    source = clone(ctx, args["source"], "configured-tree")
    compiler(ctx)
    ok, observation = build_seed_core(Stages(ctx), source, ctx.remaining())
    (ctx.directory / "observation.json").write_text(json.dumps(observation, indent=2) + "\n")
    if not ok:
        raise ValueError("seed core was not established")
    return {"observation": observation, "claim": "pre-generated-C-seed-only",
            "outputs": {**ctx.publish("runtime", "seed-runtime", source), **identity(ctx, source)}}


def regenerate(args, ctx):
    from gambit_smp.gambit_build_primitives import regenerate_module
    source = clone(ctx, args["runtime"], "seed-runtime")
    ok, observation = regenerate_module(Stages(ctx), source, args["module"], ctx.remaining())
    (ctx.directory / "observation.json").write_text(json.dumps(observation, indent=2) + "\n")
    if not ok:
        raise ValueError("actual Scheme module regeneration was not established")
    output = ctx.directory / Path(args["module"]).with_suffix(".c").name
    return {"observation": observation, "outputs": ctx.publish("generated", "c-source", output),
            "claim": "one-module-regeneration-not-linked"}


def source_core(args, ctx):
    from gambit_smp.gambit_build_primitives import rebuild_source_core
    source = clone(ctx, args["runtime"], "seed-runtime")
    compiler(ctx)
    ok, observation = rebuild_source_core(Stages(ctx), source, ctx.remaining())
    (ctx.directory / "observation.json").write_text(json.dumps(observation, indent=2) + "\n")
    if not ok:
        raise ValueError("source-regenerated core was not established")
    return {"observation": observation, "outputs": {
        **ctx.publish("runtime", "source-runtime", source), **identity(ctx, source)},
        "claim": "source-regenerated-core-not-full-two-pass-bootstrap"}


def bootstrap(args, ctx):
    from gambit_smp.gambit_build_primitives import build_errors
    from gambit_smp.native_review import preflight
    if "engine" not in ctx.receipt or "identity" not in args:
        raise ValueError("bootstrap execution requires sealed known-failure review and matching identity")
    runtime = ctx.artifact(args["runtime"], "seed-runtime")
    candidate = ctx.artifact(args["identity"], "runtime-identity")
    if args["runtime"]["step"] != args["identity"]["step"]:
        raise ValueError("bootstrap runtime and identity must have the same producer")
    review_args = {key: value for key, value in args.items() if key in {"failures", "reviewRules", "retryReview"}}
    review_args.update(mode="bootstrap", regime="build-step", operation="from-scratch")
    retry = preflight(ctx, review_args, runtime, candidate, [Path("Makefile")], runtime)
    (ctx.directory / "retry-preflight.json").write_text(json.dumps(retry, indent=2) + "\n")
    if retry["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
        raise ValueError("bootstrap retry preflight: " + retry["decision"])
    source = clone(ctx, args["runtime"], "seed-runtime")
    compiler(ctx)
    scheme = {str(path.relative_to(source)): digest(path) for folder in ("lib", "gsi", "gsc")
              for path in (source / folder).glob("*.scm")}
    generated = [name[:-4] + ".c" for name in scheme if Path(name).name.startswith("_")
                 and (source / (name[:-4] + ".c")).is_file()]
    shutil.copy2(source / "gsc/gsc", source / "gsc-boot")
    ctx.require("bootclean", [ctx.tools["make"], "bootclean"], source, 10)
    if not generated or any((source / name).exists() for name in generated):
        raise ValueError("generated C removal was not established")
    log = ctx.require("from-scratch", [ctx.tools["make"], "-j" + str(retry["campaign"]["effectiveJobs"]), "from-scratch"], source, ctx.remaining())
    if (build_errors(log) or any(not (source / name).is_file() for name in generated)
            or any(digest(source / name) != sha for name, sha in scheme.items())):
        raise ValueError("from-scratch source closure not established")
    return {"outputs": {**ctx.publish("runtime", "source-runtime", source), **identity(ctx, source)},
            "claim": "bounded-from-scratch-command-observation", "fullTwoPassBootstrapEstablished": False}


def object_build(args, ctx):
    from gambit_smp.gambit_build_primitives import command
    source = clone(ctx, args["source"], "configured-tree")
    gcc = compiler(ctx)
    unit = Path(args.get("translationUnit", "lib/mem.c"))
    output = ctx.directory / (unit.stem + ".o")
    translation = source / unit
    if not translation.is_file() or translation.is_symlink():
        raise ValueError("existing nonsymlink translation unit required")
    plan = ctx.require("object-recipe", [ctx.tools["make"], "-n", "-o", "makefile", "-W", unit.name, output.name,
        "BUILD_OBJ_INPUT_FILENAMES_PARAM=" + str(translation), "BUILD_OBJ_OUTPUT_FILENAME_PARAM=" + str(output)], source / "lib", 10)
    argv = command(plan, gcc, translation, output)
    argv.extend("-D" + value for value in args.get("defines", []))
    ctx.require("object-compile", argv, source / "lib", ctx.remaining())
    return {"outputs": ctx.publish("object", "native-object", output),
            "translationUnit": unit.as_posix(), "claim": "configured-library-object-not-linked"}


def validate_review(args, inputs):
    fields(args, ("runtime", "identity", "intent", "target"))
    reference(args["runtime"])
    reference(args["identity"])
    if args["intent"] not in inputs or not args["intent"].endswith(".json") or not isinstance(args["target"], str):
        raise ValueError("declared review intent and target step required")


def bind_review(args, ctx):
    from gambit_smp.native_review import campaign, preflight, SCHEMA
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.suite_primitives import selected_files, check_runtime
    runtime = ctx.artifact(args["runtime"], {"seed-runtime", "source-runtime"})
    identity = ctx.artifact(args["identity"], "runtime-identity")
    check_runtime(runtime, read_json(identity))
    target = next(row for row in ctx.receipt["plannedSteps"] if row["id"] == args["target"])
    intent_path = source_path(ctx.root, args["intent"])
    ctx.bind([intent_path])
    intent = read_json(intent_path)
    fields(intent, ("schema", "failures"))
    if intent["schema"] != "current-producer-review-intent.v1" or not isinstance(intent["failures"], list):
        raise ValueError("typed causal intent required")
    selection = selected_files(runtime / "tests/unit-tests", target["arguments"]["selection"])
    if sorted(map(str, selection)) != sorted(target["arguments"]["expectedFiles"]):
        raise ValueError("review target exact fixture inventory mismatch")
    current = campaign(ctx, target["arguments"], runtime, identity, selection,
                       runtime / "tests/unit-tests", suite_budget=target["budgetSeconds"])
    document = {"schema": SCHEMA, "campaign": current, "failures": intent["failures"]}
    result = preflight(ctx, target["arguments"], runtime, identity, selection, runtime / "tests/unit-tests",
                       document=document, suite_budget=target["budgetSeconds"], producer_binding=True)
    if result["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
        raise ValueError("current-producer causal review: " + result["decision"])
    output = ctx.directory / "bound-review.json"
    output.write_text(json.dumps({"schema": "bound-native-review.v1", "document": document,
        "candidateReceiptSha256": digest(identity), "intent": {"path": args["intent"], "sha256": digest(intent_path)},
        "policyResult": result, "runtimeAdmitted": False}, indent=2) + "\n")
    return {"reviewDecision": result["decision"], "target": args["target"],
            "outputs": ctx.publish("review", "bound-native-review", output)}


def suite(args, ctx):
    from gambit_smp.suite_primitives import selected_files, runtime_view, capacity, admitted_processors, admitted_suite, runner_option
    from gambit_smp.native_review import preflight
    from gambit_smp.suite_primitives import check_runtime as check
    from gambit_smp.recipes import read_json
    runtime = ctx.artifact(args["runtime"], {"seed-runtime", "source-runtime"})
    identity_path = ctx.artifact(args["identity"], "runtime-identity")
    candidate = read_json(identity_path)
    check(runtime, candidate)
    gcc = compiler(ctx)
    driver = gnu_build_driver(runtime, gcc)
    copied = runtime_view(runtime, ctx.directory / "runtime")
    shutil.copytree(runtime / "tests/unit-tests", copied / "unit-tests")
    shutil.copy2(runtime / "tests/run-unit-tests.scm", copied / "run-unit-tests.scm")
    files = selected_files(copied / "unit-tests", args["selection"])
    if sorted(str(path) for path in files) != sorted(args["expectedFiles"]):
        raise ValueError("suite selected inventory differs from exact declared files")
    if "engine" not in ctx.receipt:
        raise ValueError("suite execution requires the sealed native-rule review lane")
    retry = preflight(ctx, args, runtime, identity_path, files, copied / "unit-tests")
    (ctx.directory / "retry-preflight.json").write_text(json.dumps(retry, indent=2) + "\n")
    ctx.bind(ctx.root / name for name in retry["inputs"])
    if retry["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
        raise ValueError("suite retry preflight: " + retry["decision"])
    population, jobs = retry["campaign"]["effectiveProcessors"], retry["campaign"]["effectiveJobs"]
    option = f"p{population},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    ctx.env.update(GAMBOPT=option, GAMBIT_SMP_EXPECTED_PROCESSORS=str(population))
    code, output, timeout, _ = ctx.run("processor-probe", [runtime / "gsi/gsi", "-:debug-settings=-,io-settings=lu", "-e",
        '(println "PROCESSORS:" (##current-vm-processor-count))'], copied, 10)
    if not admitted_processors(code, output, timeout, population):
        raise ValueError("suite processor topology was not established")
    observations = run_suite_groups(ctx, runtime, copied, args, files, jobs, option)
    check(runtime, candidate)
    if not all(row["accepted"] for row in observations) or gnu_build_driver(runtime, gcc) != driver:
        raise ValueError("suite child exit, exact completion marker or build driver was not admitted")
    original = runtime / "tests"
    if any(digest(path) != digest(copied / path.relative_to(original)) for path in original.rglob("*") if path.is_file()):
        raise ValueError("suite fixture drift")
    return {"passedFiles": [str(path) for path in files], "mode": args["mode"], "processors": population,
            "jobs": jobs, "buildDriver": driver, "regime": args["regime"], "suiteGroups": observations,
            "claim": "atomic-correctness-coverage-not-whole-mode-timing" if args["regime"] == "atomic-coverage"
                     else "bounded-whole-step-suite-not-performance", "performanceAdmitted": False}


def run_suite_groups(ctx, runtime, copied, args, files, jobs, option):
    from gambit_smp.suite_primitives import admitted_suite, partitions, runner_option, runtime_view
    atomic = args["regime"] == "atomic-coverage"
    batches = [files[index:index + jobs] for index in range(0, len(files), jobs)] if atomic else [files]
    observations = []
    for batch_index, batch in enumerate(batches):
        deadline = min(ctx.deadline, time.monotonic() + args["batchBudgetSeconds"]) if atomic else ctx.deadline
        groups = [[file] for file in batch] if atomic else partitions(batch, jobs)

        def worker(item):
            index, group = item
            name = f"suite-{batch_index}-{index}"
            work = runtime_view(runtime, ctx.directory / "shards" / name)
            shutil.copytree(copied / "unit-tests", work / "unit-tests")
            shutil.copy2(copied / "run-unit-tests.scm", work / "run-unit-tests.scm")
            cap = deadline - time.monotonic()
            if cap <= 0:
                raise TimeoutError("suite batch deadline exhausted before launch")
            code, output, timeout, seconds = ctx.run(name, [runtime / "gsi/gsi", "-:" + runner_option(option), "-f",
                "run-unit-tests.scm", "-" + args["mode"], *[str(Path("unit-tests") / file) for file in group]], work, cap)
            stable = all(digest(path) == digest(work / path.relative_to(copied))
                         for path in copied.rglob("*") if path.is_file())
            return {"batch": batch_index, "shard": index, "files": [str(file) for file in group],
                    "exit": code, "timeout": timeout, "seconds": seconds,
                    "accepted": admitted_suite(code, output, timeout, len(group)) and stable and time.monotonic() <= deadline}

        with ThreadPoolExecutor(max_workers=jobs) as pool:
            rows = list(pool.map(worker, enumerate(groups)))
        observations.extend(rows)
        (ctx.directory / "suite-progress.json").write_text(json.dumps(observations, indent=2) + "\n")
        if not all(row["accepted"] for row in rows):
            return observations
    if sorted(file for row in observations for file in row["files"]) != sorted(str(file) for file in files):
        raise ValueError("suite shards did not cover the exact file inventory")
    return observations


def c_build(args, ctx):
    from gambit_smp.recipes import source_path
    copied = ctx.directory / "inputs"
    copied.mkdir()
    for name in [*args["sources"], *args["headers"]]:
        path = source_path(ctx.root, name)
        target = copied / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
    originals = {name: digest(source_path(ctx.root, name)) for name in [*args["sources"], *args["headers"]]}
    return compile_workspace(args, ctx, copied, copied / args["sources"][0], originals)


def compile_workspace(args, ctx, copied, source, originals, *, required_origins=()):
    """Compile a bound workspace; both historical and typed producers use this primitive."""
    gcc = compiler(ctx)
    output = ctx.directory / ("program" if args["target"] == "executable" else "program.o")
    dependencies = ctx.directory / "dependencies.d"
    argv = [gcc, "-std=" + args["standard"], "-O" + str(args["optimization"]), "-Wall", "-Wextra",
            "-MD", "-MF", dependencies, "-I", copied]
    if args["pthread"]:
        argv.append("-pthread")
    if args["target"] == "object":
        argv.append("-c")
    dependency_argv = [gcc, "-std=" + args["standard"], "-M", "-MF", dependencies, "-I", copied]
    defines = ["-D" + value for value in args.get("defines", [])]
    argv.extend(defines)
    dependency_argv.extend(defines)
    if args["pthread"]:
        dependency_argv.append("-pthread")
    ctx.require("c-dependencies", [*dependency_argv, source], copied, ctx.remaining())
    # GCC make dependencies use backslash escaping; shlex handles spaces after continuation removal.
    import shlex
    dependency_bytes = dependencies.read_bytes()
    closure = shlex.split(dependency_bytes.decode().replace("\\\n", " ").split(":", 1)[1])
    observed_origins = set()
    if "engine" in ctx.receipt:
        local_dependencies = ctx.directory / "local-dependencies.d"
        local_argv = ["-MM" if value == "-M" else local_dependencies if value == dependencies else value
                      for value in dependency_argv]
        ctx.require("c-local-dependencies", [*local_argv, source], copied, ctx.remaining())
        local_closure = shlex.split(local_dependencies.read_text().replace("\\\n", " ").split(":", 1)[1])
        for name in local_closure:
            path = Path(name)
            path = (path if path.is_absolute() else copied / path).resolve(strict=True)
            if not path.is_relative_to(copied.resolve()):
                raise ValueError("new workspace cannot consume an external non-system compiler input")
    for name in closure:
        path = Path(name)
        if not path.is_absolute():
            path = copied / path
        path = path.resolve(strict=True)
        if path.is_relative_to(copied):
            original = path.relative_to(copied).as_posix()
            if original not in originals or digest(path) != originals[original]:
                raise ValueError("undeclared or changed local compiler input")
            observed_origins.add(original)
        else:
            if "engine" in ctx.receipt and path.is_relative_to(ctx.root.resolve()):
                raise ValueError("new workspace cannot escape to checkout or archived producer headers")
            ctx.bind([path])
    if not set(required_origins) <= observed_origins:
        raise ValueError("compiler did not consume the required locked-source projections")
    ctx.require("c-build", [*argv, source, "-o", output], copied, ctx.remaining())
    compiled_closure = shlex.split(dependencies.read_text().replace("\\\n", " ").split(":", 1)[1])
    if compiled_closure != closure:
        raise ValueError("compiler dependency closure changed during compilation")
    kind = "native-executable" if args["target"] == "executable" else "native-object"
    return {"outputs": ctx.publish("executable" if args["target"] == "executable" else "object", kind, output),
            "claim": "local-C-build-only"}


def native_test(args, ctx):
    executable = ctx.artifact(args["executable"], "native-executable")
    passed = []
    expected_failures = []
    for case in args["cases"]:
        argv = [executable, *[str(value) for value in case["integers"]]]
        if case.get("negativeControl", False):
            code, log, timed_out, _ = ctx.run("case-" + case["id"], argv, ctx.directory, ctx.remaining())
            if timed_out or code != case["expectedExit"]:
                raise ValueError("negative control did not produce its exact ordinary failure exit")
            ctx.commands[-1].update(expectedExit=case["expectedExit"], negativeControl=True)
            expected_failures.append(case["id"])
        else:
            log = ctx.require("case-" + case["id"], argv, ctx.directory, ctx.remaining())
        if ctx.commands[-1].get("stderrBytes", 0):
            raise ValueError("native control produced unexpected stderr")
        if log != case["stdout"]:
            raise ValueError("native case stdout differs from exact observation: " + case["id"])
        passed.append(case["id"])
    return {"passedCases": passed, "expectedFailureControls": expected_failures,
            "claim": "explicit-local-native-controls-only"}


def capabilities(Capability):
    entries = {
        "gambit.materialize": (validate_materialize, materialize, (("source", "source-tree"),)),
        "gambit.configure": (validate_configure, configure, (("source", "configured-tree"),)),
        "gambit.object": (validate_object, object_build, (("object", "native-object"),)),
        "gambit.seed-core": (validate_source, seed, (("runtime", "seed-runtime"), ("identity", "runtime-identity"))),
        "gambit.regenerate-module": (validate_regenerate, regenerate, (("generated", "c-source"),)),
        "gambit.source-core": (validate_runtime, source_core, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.bootstrap": (validate_bootstrap, bootstrap, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.suite": (validate_suite, suite, ()),
        "gambit.review": (validate_review, bind_review, (("review", "bound-native-review"),)),
        "native.c-build": (validate_c, c_build, (("executable", "native-executable"), ("object", "native-object"))),
        "native.test": (validate_native_test, native_test, ()),
    }
    return {name: Capability(validate, executor=executor, graph=graph, outputs=outputs)
            for name, (validate, executor, outputs) in entries.items()}
