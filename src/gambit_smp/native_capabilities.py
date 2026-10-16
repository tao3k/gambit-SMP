"""Typed native capability family; experiment choices remain Evidence data."""
import json
import math
import os
from pathlib import Path
import re
import shutil
import sys
import tarfile
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

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
        "gambit.completed-runtime": {"source": {"source-tree"}},
        "gambit.seed-checkpoint": {"source": {"source-tree"}},
        "gambit.object": {"source": {"configured-tree", "source-runtime"}},
        "gambit.seed-core": {"source": {"configured-tree"}},
        "gambit.regenerate-module": {"runtime": {"seed-runtime"}},
        "gambit.source-core": {"runtime": {"seed-runtime"}},
        "gambit.runtime-import": {"source": {"source-tree"}},
        "gambit.upstream-tests": {"runtime": {"source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.bootstrap": {"runtime": {"seed-runtime"}},
        "gambit.suite": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.review": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.probe": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.executable-test": {"runtime": {"seed-runtime", "source-runtime"}, "identity": {"runtime-identity"}},
        "gambit.compiler-observation": {"runtime": {"source-runtime"}, "identity": {"runtime-identity"}},
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
    if "environmentProbe" in step["arguments"]:
        ref = step["arguments"]["environmentProbe"]
        reference(ref)
        producer = by_id.get(ref["step"])
        if (producer is None or producer["capability"] != "gambit.probe"
                or ref["step"] not in step["dependsOn"] or ref["output"] != "observation"
                or any(producer["arguments"][key] != step["arguments"][key] for key in ("runtime", "identity"))):
            raise ValueError("environment observation requires the same current producer and explicit dependency")
    if step["capability"] in {"gambit.suite", "gambit.probe", "gambit.executable-test", "gambit.upstream-tests"} and (
            step["arguments"]["runtime"]["step"] != step["arguments"]["identity"]["step"]):
        raise ValueError("suite runtime and identity must have the same producer")
    if step["capability"] == "gambit.review":
        args = step["arguments"]
        target = by_id.get(args["target"])
        if (target is None or target["capability"] not in {"gambit.suite", "gambit.bootstrap"}
                or step["id"] not in target["dependsOn"]
                or target["arguments"].get("retryReview") != {"step": step["id"], "output": "review"}
                or any(target["arguments"][key] != args[key] for key in ("runtime", "identity"))
                or target["arguments"].get("environmentProbe") != args.get("environmentProbe")
                or args["runtime"]["step"] != args["identity"]["step"]):
            raise ValueError("review must bind one matching same-producer downstream suite or bootstrap")
    if step["capability"] in {"gambit.suite", "gambit.bootstrap"} and isinstance(step["arguments"].get("retryReview"), dict):
        ref = step["arguments"]["retryReview"]
        reference(ref)
        producer = by_id.get(ref["step"])
        if (producer is None or ref["step"] not in step["dependsOn"]
                or producer["capability"] != "gambit.review" or ref["output"] != "review"
                or producer["arguments"]["target"] != step["id"]):
            raise ValueError("suite requires its declared bound review producer")


def validate_materialize(args, inputs):
    fields(args, ("sourceLock",), ("workspace", "cacheReceipt", "workspaceState"))
    if "workspace" in args:
        name = args["workspace"]
        if (not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts
                or not name.startswith(".data/fixtures/") or ".git" in Path(name).parts):
            raise ValueError("explicit managed fixture workspace required")
    if "cacheReceipt" in args and ("workspace" not in args or args["cacheReceipt"] not in inputs):
        raise ValueError("workspace cache requires a declared custody receipt")
    if "workspaceState" in args and ("workspace" not in args or args["workspaceState"] not in inputs
                                     or "cacheReceipt" in args):
        raise ValueError("workspace state requires an exclusive declared custody reference")
    if args["sourceLock"] not in inputs or not args["sourceLock"].endswith(".lock.json"):
        raise ValueError("declared source lock required")


def validate_configure(args, inputs):
    if "buildProfile" in args:
        fields(args, ("source", "buildProfile"))
        reference(args["source"])
        if args["buildProfile"] not in inputs or not args["buildProfile"].endswith(".json"):
            raise ValueError("declared pinned Bazel build profile required")
        return
    fields(args, ("source", "cOptimization", "rtsOptimization"))
    reference(args["source"])
    for value in (args["cOptimization"], args["rtsOptimization"]):
        if type(value) is not int or value not in range(4):
            raise ValueError("explicit C and RTS optimization levels 0 through 3 required")


def validate_source(args, inputs):
    fields(args, ("source",))
    reference(args["source"])


def validate_object(args, inputs):
    fields(args, ("source",), ("translationUnit", "defines", "debugSymbols"))
    reference(args["source"])
    if "debugSymbols" in args and not isinstance(args["debugSymbols"], bool):
        raise ValueError("boolean debug-symbol selection required")
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
    if "retryReview" in args:
        if isinstance(args["retryReview"], dict):
            reference(args["retryReview"])
        elif args["retryReview"] not in inputs or not args["retryReview"].endswith(".json"):
            raise ValueError("retry review must be a declared typed data input")


def validate_regenerate(args, inputs):
    fields(args, ("runtime", "module"))
    reference(args["runtime"])
    if not isinstance(args["module"], str) or not re.fullmatch(r"(?:lib|gsi|gsc)/_[A-Za-z0-9_-]+\.scm", args["module"]):
        raise ValueError("explicit Gambit Scheme module required")


def fixture_parameters(args):
    parameters = args.get("parameters", {})
    if (not isinstance(parameters, dict) or any(
            not isinstance(name, str) or not re.fullmatch(r"GAMBIT_SMP_[A-Z][A-Z0-9_]*", name)
            or name in {"GAMBIT_SMP_ROOT", "GAMBIT_SMP_AVAILABLE_CPUS", "GAMBIT_SMP_EXPECTED_PROCESSORS"}
            or type(value) is not int or not 0 < value <= 2147483647
            for name, value in parameters.items())):
        raise ValueError("declared positive numeric fixture parameters cannot override host identity or capacity")
    return {name: str(value) for name, value in parameters.items()}


def validate_suite(args, inputs):
    fields(args, ("runtime", "identity", "mode", "regime", "selection", "expectedFiles"),
           ("processors", "jobs", "batchBudgetSeconds", "fileBudgetSeconds", "groupBudgetSeconds", "additionalFixtures", "failures", "reviewRules", "retryReview", "environmentProbe", "inventory", "observationFiles", "parameters", "compilerPhaseFiles"))
    fixture_parameters(args)
    if "observationFiles" in args:
        from gambit_smp.suite_observations import validate
        validate(args["observationFiles"], args["expectedFiles"])
    if args.get("inventory", "unit") not in {"unit", "stress"}:
        raise ValueError("explicit unit or stress inventory required")
    reference(args["runtime"])
    reference(args["identity"])
    if "environmentProbe" in args:
        reference(args["environmentProbe"])
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
    caps = args.get("fileBudgetSeconds", {})
    if not isinstance(caps, dict) or not set(caps) <= set(args["expectedFiles"]):
        raise ValueError("file budgets must belong to the exact selected inventory")
    from gambit_smp.recipes import budget
    for cap in caps.values():
        budget(cap)
    phase_files = args.get("compilerPhaseFiles", [])
    if (not isinstance(phase_files, list)
            or any(not isinstance(name, str) or name not in caps for name in phase_files)
            or len(phase_files) != len(set(phase_files))
            or phase_files and (args["mode"] != "gsc" or args["regime"] == "atomic-coverage"
                                or "observationFiles" in args)):
        raise ValueError("compiled phase files require disjoint explicit GSC file windows")
    groups = args.get("groupBudgetSeconds", {})
    if not isinstance(groups, dict) or groups and args["regime"] == "atomic-coverage":
        raise ValueError("group budgets require a whole campaign")
    grouped = set()
    for name, group in groups.items():
        if not isinstance(name, str) or not re.fullmatch(r"[a-z][a-z0-9-]*", name):
            raise ValueError("semantic group budget identity required")
        fields(group, ("files", "budgetSeconds"))
        names = group["files"]
        if (not isinstance(names, list) or not names or any(not isinstance(item, str) for item in names)
                or len(set(names)) != len(names) or not set(names) <= set(args["expectedFiles"])
                or grouped.intersection(names) or set(caps).intersection(names)):
            raise ValueError("group budgets require disjoint exact selected file inventories")
        budget(group["budgetSeconds"])
        grouped.update(names)
    fixtures = args.get("additionalFixtures", {})
    if not isinstance(fixtures, dict) or not set(fixtures) <= set(args["expectedFiles"]):
        raise ValueError("additional fixtures must belong to the exact selected inventory")
    for name, item in fixtures.items():
        fields(item, ("source", "sha256"))
        if (not name.endswith(".scm") or item["source"] not in inputs
                or not item["source"].endswith(".scm") or not isinstance(item["sha256"], str)
                or not re.fullmatch(r"[0-9a-f]{64}", item["sha256"])):
            raise ValueError("declared hash-bound Scheme test fixture required")


def validate_compiler_observation(args, inputs):
    fields(args, ("runtime", "identity", "selection", "scheduling", "phaseBudgetSeconds"), ("loader",))
    reference(args["runtime"])
    reference(args["identity"])
    name = args["selection"]
    if (not isinstance(name, str) or Path(name).is_absolute() or ".." in Path(name).parts
            or not name.endswith(".scm")):
        raise ValueError("one original relative Scheme fixture required")
    if args["scheduling"] not in {"default-control", "no-modulo", "no-scheduling"}:
        raise ValueError("explicit bounded scheduling diagnostic required")
    if args.get("loader", "diagnostic-entry") not in {"diagnostic-entry", "original-gsi"}:
        raise ValueError("explicit known loader contract required")
    if args.get("loader") == "original-gsi" and args["scheduling"] != "default-control":
        raise ValueError("original loader control must retain the configured driver defaults")
    cap = args["phaseBudgetSeconds"]
    if type(cap) not in (int, float) or not math.isfinite(cap) or not 0 < cap <= 90:
        raise ValueError("compiler phase watchdog must remain within 90 seconds")


def validate_executable_test(args, inputs):
    fields(args, ("runtime", "identity", "program", "stdout"),
           ("latency", "stackSampleAfterSeconds", "processorTopology", "executionBudgetSeconds", "stderr", "stdoutTranscript", "parameters", "completedUnits"))
    fixture_parameters(args)
    if "completedUnits" in args:
        from gambit_smp.completed_units import validate
        validate(args["completedUnits"])
        if "stackSampleAfterSeconds" in args or "stdoutTranscript" in args:
            raise ValueError("completed units require an independent progress transport")
    if "stdoutTranscript" in args:
        fields(args["stdoutTranscript"], ("contract", "rules"))
        for field, suffix in (("contract", ".json"), ("rules", ".ss")):
            path = args["stdoutTranscript"][field]
            if not isinstance(path, str) or path not in inputs or not path.endswith(suffix):
                raise ValueError("declared typed transcript contract and Evidence rules required")
    if not isinstance(args.get("stderr", ""), str):
        raise ValueError("exact native stderr transcript required")
    if args.get("processorTopology", "fixture-managed") not in {"fixture-managed", "host-managed"}:
        raise ValueError("explicit fixture-managed or host-managed processor topology required")
    cap = args.get("executionBudgetSeconds")
    if cap is not None and (type(cap) not in (int, float) or not math.isfinite(cap) or cap <= 0):
        raise ValueError("finite positive native execution budget required")
    reference(args["runtime"])
    reference(args["identity"])
    if (args["program"] not in inputs or not args["program"].endswith(".scm")
            or not isinstance(args["stdout"], str) or not args["stdout"]):
        raise ValueError("declared Scheme executable fixture and exact output required")
    if "latency" in args:
        from gambit_smp.latency_observation import validate_options
        validate_options(args["latency"])
    delay = args.get("stackSampleAfterSeconds")
    if delay is not None and (type(delay) not in (int, float) or not 0 < delay <= 60):
        raise ValueError("bounded positive stack observation delay required")


def validate_c(args, inputs):
    fields(args, ("sources", "headers", "standard", "optimization", "pthread", "target"), ("defines",))
    defines = args.get("defines", [])
    if (not isinstance(defines, list) or any(
            not isinstance(value, str) or not re.fullmatch(r"[A-Z_][A-Z0-9_]*(?:=[0-9]+)?", value)
            for value in defines) or len(defines) != len(set(defines))):
        raise ValueError("C defines require unique typed macro names and optional integer values")
    if args["standard"] not in {"c11", "gnu11", "c23", "gnu23"} or args["target"] not in {"executable", "object"}:
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
    if any(step["capability"] == "gambit.executable-test" and
           "stackSampleAfterSeconds" in step["arguments"] for step in steps):
        sample = Path("/usr/bin/sample")
        if sys.platform != "darwin" or not sample.is_file():
            raise ValueError("Darwin sampling requested but native tool unavailable")
        tools["darwinSample"] = sample.resolve(strict=True)
    kinds = {step["capability"] for step in steps}
    required = {"as", "ld"}
    if any(kind.startswith("gambit.") for kind in kinds) or "source.overlay" in kinds:
        required.update({"git", "make", "sh"})
    if "gambit.configure" in kinds:
        required.update({"aclocal", "autoconf", "m4"})
    env = dict(environment)
    # An explicitly selected Node installation must not replace the native
    # compiler's system assembler/linker with its unrelated package-manager tools.
    directories = [str(gcc.absolute().parent), "/usr/bin", "/bin", "/usr/sbin", "/sbin",
                   *environment.get("PATH", "").split(os.pathsep)]
    directories = [directory for directory in directories if directory]
    for name in sorted(required):
        path = shutil.which(name, path=os.pathsep.join(directories)) or (
            shutil.which(name) if name in {"aclocal", "autoconf", "m4"} else None)
        if path is None:
            raise ValueError("required native tool missing: " + name)
        tools[name] = Path(path).resolve(strict=True)
        if name in {"aclocal", "autoconf", "m4"}:
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
    if "workspace" in args:
        if ctx.receipt.get("workspacePolicy") != "in-place":
            raise ValueError("workspace adoption requires in-place recipe policy")
        return _materialize(args, ctx)
    from gambit_smp.fixture_storage import source_capacity
    with source_capacity(ctx.directory / "source"):
        return _materialize(args, ctx)


def _materialize(args, ctx):
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
    from gambit_smp.completed_producer import reuse_materialized_source
    reused = reuse_materialized_source(lock_path, ctx)
    if reused is not None:
        if ctx.require("revision-after", [git, "-C", checkout, "rev-parse", "HEAD"], ctx.root, 10).strip() != lock["revision"]:
            raise ValueError("source revision changed during reuse")
        return reused
    archive = ctx.directory / "source.tar"
    ctx.require("archive", [git, "-C", checkout, "archive", "--output=" + str(archive), lock["revision"]], ctx.root, 30)
    if "workspace" in args:
        from gambit_smp.artifact_storage import adopt_source_archive
        from gambit_smp.recipes import tree_identity
        source = relative(ctx.root, args["workspace"])
        source = ctx.lease_workspace(source, tree_identity(source))
        if "workspaceState" in args:
            from gambit_smp.artifact_storage import checked_workspace_state
            reference_path = source_path(ctx.root, args["workspaceState"])
            reference = read_json(reference_path)
            state_path = source_path(ctx.root, reference["path"])
            state = read_json(state_path)
            checked_workspace_state(ctx.root, reference, tree_identity(source))
            if state["bindings"].get(args["sourceLock"]) != digest(lock_path):
                raise ValueError("workspace state identifies another source lock")
            for name, row in lock["files"].items():
                if digest(source_file(source, name)) != row["candidateSha256"]:
                    raise ValueError("retained workspace candidate differs from source lock")
            ctx.bind([reference_path, state_path])
            archive.unlink()
            if ctx.require("revision-after", [git, "-C", checkout, "rev-parse", "HEAD"], ctx.root, 10).strip() != lock["revision"]:
                raise ValueError("source revision changed during state reuse")
            return {"outputs": ctx.publish("source", "source-tree", source),
                    "claim": "exact-retained-workspace-cache-not-runtime-admission"}
        cache_files = {}
        if "cacheReceipt" in args:
            receipt_path = source_path(ctx.root, args["cacheReceipt"])
            diagnostic = read_json(receipt_path)
            if (diagnostic.get("schema") not in {"gambit-collector-compile-diagnostic.v1", "managed-source-cache-custody.v1"}
                    or diagnostic.get("sourceLock") != args["sourceLock"]
                    or diagnostic.get("sourceLockSha256") != digest(lock_path)):
                raise ValueError("cache custody must bind current source lock")
            ctx.bind([receipt_path])
            if diagnostic["schema"] == "managed-source-cache-custody.v1":
                cache_files = diagnostic["files"]
                if not isinstance(cache_files, dict) or len(cache_files) > 128:
                    raise ValueError("bounded explicit source cache inventory required")
            else:
                cache_files = {"include/gambit.h": diagnostic["generatedHeaderSha256"],
                               "lib/continuation-segment-diagnostic.o": diagnostic["outputObjectSha256"]}
        adopt_source_archive(source, archive, lock["files"], cache_files)
        archive.unlink()
        if ctx.require("revision-after", [git, "-C", checkout, "rev-parse", "HEAD"], ctx.root, 10).strip() != lock["revision"]:
            raise ValueError("source revision changed during workspace adoption")
        return {"outputs": ctx.publish("source", "source-tree", source),
                "claim": "locked-source-in-place-adoption-not-runtime-admission"}
    source = ctx.directory / "source"
    source.mkdir()
    with tarfile.open(archive) as tree:
        tree.extractall(source, filter="data")
    archive.unlink()
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
    if ctx.receipt.get("workspacePolicy") == "in-place":
        return ctx.reuse_workspace(ref, kind)
    from gambit_smp.artifact_storage import transfer_tree
    source = ctx.artifact(ref, kind)
    destination = ctx.directory / "source"
    storage = transfer_tree(source, destination)
    producer = next(step for step in ctx.receipt["steps"] if step["id"] == ref["step"])
    actual_type = producer["outputs"][ref["output"]]["type"]
    allowed = [kind] if isinstance(kind, str) else sorted(kind)
    ctx.receipt.setdefault("storageTransfers", []).append(
        {"purpose": actual_type, "allowedTypes": allowed, **storage})
    ctx.remaining()
    return destination


def configure(args, ctx):
    from gambit_smp.recipes import source_path
    from gambit_smp.completed_producer import prevent_duplicate_configuration
    prevent_duplicate_configuration(args, ctx)
    source = clone(ctx, args["source"], "source-tree")
    gcc = compiler(ctx)
    ctx.require("aclocal", [ctx.tools["aclocal"]], source, min(30, ctx.remaining()))
    ctx.require("autoconf", [ctx.tools["autoconf"], "-o", "configure", "configure.ac"], source, 30)
    profile = None
    if "buildProfile" in args:
        from gambit_smp.build_profile import read_profile
        path = source_path(ctx.root, args["buildProfile"])
        ctx.bind([path])
        profile = read_profile(path)
        flags = profile["flags"]
        ctx.env["CFLAGS"] = profile["cflags"]
    else:
        flags = ["--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms",
                 "--enable-c-opt=-O" + str(args["cOptimization"]),
                 "--enable-c-opt-rts=-O" + str(args["rtsOptimization"])]
    from gambit_smp.gambit_build_primitives import ConfigureProbeProgress
    progress_timed = getattr(ctx, "progress_mode", False)
    ctx.require("configure", [ctx.tools["sh"], "./configure", *flags], source,
                min(90, ctx.remaining()),
                **({"progress": ConfigureProbeProgress()} if progress_timed else {}))
    effective = effective_configuration(ctx, source, gcc)
    return {"outputs": ctx.publish("source", "configured-tree", source), "claim": "configuration-only",
            "buildProfile": profile, **effective}


def effective_configuration(ctx, source, gcc):
    """Probe generated bytes, not requested switches; reuse after each build."""
    configured_files = {name: digest(source / name) for name in ("include/gambit.h", "lib/makefile")}
    macros = ctx.require("configuration-macros", [gcc, "-dM", "-E", "-x", "c", "-I", source / "include",
        "-include", "gambit.h", "/dev/null"], source, min(10, ctx.remaining()))
    defined = {line.split()[1] for line in macros.splitlines() if line.startswith("#define ")}
    if not {"___MULTIPLE_VMS", "___MULTIPLE_THREADED_VMS"} <= defined:
        raise ValueError("effective configuration omits required VM concurrency macros")
    prelude = source / "lib/makefile"
    if "define-cond-expand-feature|enable-smp|" not in prelude.read_text():
        raise ValueError("effective Scheme prelude omits SMP")
    if any(digest(source / name) != sha for name, sha in configured_files.items()):
        raise ValueError("configuration artifacts changed during the effective-flag probe")
    return {"configurationFiles": configured_files, "effectiveConcurrency": {
                "smp": True, "multipleVMs": True, "multipleThreadedVMs": True}}


class Stages:
    """Use only stable build primitives; historical experiment CLIs are absent."""
    def __init__(self, ctx):
        self.ctx, self.out = ctx, ctx.directory

    def run(self, name, argv, cwd, cap, *, progress=None):
        return self.ctx.run(name, argv, cwd, cap,
                            **({"progress": progress} if progress is not None else {}))

    @property
    def progress_mode(self):
        return getattr(self.ctx, "progress_mode", False)

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
    gcc = compiler(ctx)
    ok, observation = build_seed_core(Stages(ctx), source, ctx.remaining())
    (ctx.directory / "observation.json").write_text(json.dumps(observation, indent=2) + "\n")
    if not ok:
        raise ValueError("seed core was not established")
    return {"observation": observation, "claim": "pre-generated-C-seed-only",
            **effective_configuration(ctx, source, gcc),
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
    return {"observation": observation, **effective_configuration(ctx, source, ctx.tools["gcc"]), "outputs": {
        **ctx.publish("runtime", "source-runtime", source), **identity(ctx, source)},
        "claim": "source-regenerated-core-not-full-two-pass-bootstrap"}


def bootstrap_phase_counts(log):
    counts = {f"phase{phase}": log.splitlines().count(f"*** making phase{phase}") for phase in range(1, 5)}
    if any(count != 2 for count in counts.values()):
        raise ValueError("complete two-pass bootstrap phase inventory was not established")
    return counts


def bootstrap(args, ctx):
    from gambit_smp.gambit_build_primitives import (build_errors, build_capacity,
                                                   core_command, BootstrapPhaseProgress)
    from gambit_smp.native_review import preflight
    if "engine" not in ctx.receipt or "identity" not in args:
        raise ValueError("bootstrap execution requires sealed known-failure review and matching identity")
    runtime = ctx.artifact(args["runtime"], "seed-runtime")
    candidate = ctx.artifact(args["identity"], "runtime-identity")
    if args["runtime"]["step"] != args["identity"]["step"]:
        raise ValueError("bootstrap runtime and identity must have the same producer")
    review_args = {key: value for key, value in args.items() if key in {"failures", "reviewRules", "retryReview"}}
    review_args.update(mode="bootstrap", regime="build-step", operation="from-scratch")
    retry = preflight(ctx, review_args, runtime, candidate, [Path("makefile")], runtime)
    (ctx.directory / "retry-preflight.json").write_text(json.dumps(retry, indent=2) + "\n")
    if retry["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
        raise ValueError("bootstrap retry preflight: " + retry["decision"])
    from gambit_smp.completed_producer import prevent_duplicate_bootstrap
    prevent_duplicate_bootstrap(args, ctx)
    capacity = build_capacity(available_processors())
    if capacity["makeJobs"] != retry["campaign"]["effectiveJobs"]:
        raise ValueError("bootstrap host CPU budget changed after causal review")
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
    command = core_command(capacity, "from-scratch")
    code, _, timed_out, _ = ctx.run("from-scratch", [ctx.tools["make"], *command[1:]],
                                   source, ctx.remaining(), progress=BootstrapPhaseProgress())
    if timed_out:
        raise TimeoutError("from-scratch timed out")
    if code != 0:
        raise ValueError("from-scratch failed with exit " + str(code))
    log = ctx.last_stdout
    if (build_errors(log) or any(not (source / name).is_file() for name in generated)
            or any(digest(source / name) != sha for name, sha in scheme.items())):
        raise ValueError("from-scratch source closure not established")
    phases = bootstrap_phase_counts(log)
    return {"outputs": {**ctx.publish("runtime", "source-runtime", source), **identity(ctx, source)},
            "claim": "source-bound-two-pass-bootstrap-not-full-native-acceptance",
            "phaseCounts": phases, "capacity": capacity, "fullTwoPassBootstrapEstablished": True}


def object_build(args, ctx):
    from gambit_smp.gambit_build_primitives import command
    source = clone(ctx, args["source"], {"configured-tree", "source-runtime"})
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
    if args.get("debugSymbols", False):
        argv.append("-g")
    ctx.require("object-compile", argv, source / "lib", ctx.remaining())
    return {"outputs": ctx.publish("object", "native-object", output),
            "translationUnit": unit.as_posix(), "debugSymbols": args.get("debugSymbols", False),
            "claim": "configured-library-object-not-linked"}


def validate_review(args, inputs):
    fields(args, ("runtime", "identity", "intent", "target"), ("environmentProbe",))
    reference(args["runtime"])
    reference(args["identity"])
    if "environmentProbe" in args:
        reference(args["environmentProbe"])
    if args["intent"] not in inputs or not args["intent"].endswith(".json") or not isinstance(args["target"], str):
        raise ValueError("declared review intent and target step required")


def validate_probe(args, inputs):
    fields(args, ("runtime", "identity", "program", "operations"))
    reference(args["runtime"])
    reference(args["identity"])
    if not isinstance(args["program"], str) or args["program"] not in inputs or not args["program"].endswith(".scm"):
        raise ValueError("declared Scheme probe program required")
    if (not isinstance(args["operations"], list) or not args["operations"]
            or any(not isinstance(value, str) or value not in {"udp-open", "process-pipe-sort", "user-info"} for value in args["operations"])
            or len(set(args["operations"])) != len(args["operations"])):
        raise ValueError("exact known environment operation inventory required")


def probe(args, ctx):
    from gambit_smp.framework import available_processors
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.suite_primitives import capacity, check_runtime
    runtime = ctx.artifact(args["runtime"], {"seed-runtime", "source-runtime"})
    identity = ctx.artifact(args["identity"], "runtime-identity")
    candidate = read_json(identity)
    check_runtime(runtime, candidate)
    program = source_path(ctx.root, args["program"])
    ctx.bind([program, identity])
    copied = ctx.directory / "probe.scm"
    shutil.copyfile(program, copied)
    program_sha = digest(program)
    population, _ = capacity(available_processors(), 1, False)
    ctx.env["GAMBOPT"] = f"p{population},~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    output = ctx.require("environment-probe", [runtime / "gsi/gsi",
        "-:debug-settings=-,io-settings=lu", copied], ctx.directory, ctx.remaining())
    expected = [f"ENVIRONMENT:{operation}:PASS" for operation in args["operations"]]
    if (output.splitlines() != [*expected, f"PROCESSORS:{population}"]
            or ctx.commands[-1].get("stderrBytes", 0) or digest(copied) != program_sha):
        raise ValueError("probe operation, processor observation or source integrity differs")
    check_runtime(runtime, candidate)
    observation = ctx.directory / "observation.json"
    observation.write_text(json.dumps({"schema": "current-producer-observation.v1",
        "candidateReceiptSha256": digest(identity), "program": args["program"],
        "programSha256": program_sha, "processors": population,
        "operations": args["operations"], "complete": True,
        "runtimeAdmitted": False, "nativeGcPassed": False,
        "scope": "Current-run environment observation; not a permission lease or full native acceptance"}, indent=2) + "\n")
    return {"observedOperations": args["operations"], "processors": population,
            "outputs": ctx.publish("observation", "current-producer-observation", observation)}


def bind_review(args, ctx):
    from gambit_smp.artifact_storage import transfer_tree
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
    target_args = target["arguments"]
    if target["capability"] == "gambit.bootstrap":
        selection, tested_unit = [Path("makefile")], runtime
        target_args = {**target_args, "mode": "bootstrap", "regime": "build-step", "operation": "from-scratch"}
    else:
        tested_unit = runtime / "tests/unit-tests"
        if target_args.get("additionalFixtures"):
            copied = ctx.directory / "test-fixtures"
            storage = transfer_tree(runtime / "tests", copied)
            ctx.receipt.setdefault("storageTransfers", []).append({"purpose": "review-fixtures", **storage})
            tested_unit = copied / "unit-tests"
            additional_fixtures(target_args, ctx, tested_unit)
        selection = selected_files(tested_unit, target_args["selection"], inventory=target_args.get("inventory", "unit"))
        if sorted(map(str, selection)) != sorted(target_args["expectedFiles"]):
            raise ValueError("review target exact fixture inventory mismatch")
    current = campaign(ctx, target_args, runtime, identity, selection,
                       tested_unit, suite_budget=target["budgetSeconds"])
    document = {"schema": SCHEMA, "campaign": current, "failures": intent["failures"]}
    result = preflight(ctx, target_args, runtime, identity, selection, tested_unit,
                       document=document, suite_budget=target["budgetSeconds"], producer_binding=True)
    (ctx.directory / "retry-preflight.json").write_text(json.dumps(result, indent=2) + "\n")
    if result["decision"] not in {"NOT_REQUIRED", "RETRY_ELIGIBLE"}:
        raise ValueError("current-producer causal review: " + result["decision"])
    output = ctx.directory / "bound-review.json"
    output.write_text(json.dumps({"schema": "bound-native-review.v1", "document": document,
        "candidateReceiptSha256": digest(identity), "intent": {"path": args["intent"], "sha256": digest(intent_path)},
        "policyResult": result, "runtimeAdmitted": False}, indent=2) + "\n")
    return {"reviewDecision": result["decision"], "target": args["target"],
            "outputs": ctx.publish("review", "bound-native-review", output)}


def additional_fixtures(args, ctx, unit):
    from gambit_smp.recipes import source_path
    for name, item in args.get("additionalFixtures", {}).items():
        target = relative(unit, name)
        source = source_path(ctx.root, item["source"])
        if target.exists() or digest(source) != item["sha256"]:
            raise ValueError("additional fixture cannot replace upstream bytes or drift")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        if digest(target) != item["sha256"]:
            raise ValueError("additional fixture changed during transport")
        ctx.bind([source])


def suite(args, ctx):
    from gambit_smp.artifact_storage import transfer_tree
    from gambit_smp.suite_primitives import selected_files, runtime_view, capacity, admitted_processors, admitted_suite, runner_option
    from gambit_smp.native_review import preflight
    from gambit_smp.suite_primitives import check_runtime as check
    from gambit_smp.recipes import read_json
    if args.get("compilerPhaseFiles") and not getattr(ctx, "progress_mode", False):
        raise ValueError("compiled phase execution requires completed-work inactivity timing")
    runtime = ctx.artifact(args["runtime"], {"seed-runtime", "source-runtime"})
    producer = next(row for row in ctx.receipt["steps"] if row["id"] == args["runtime"]["step"])
    descriptor = producer["outputs"][args["runtime"]["output"]]
    if "workspace" in descriptor:
        ctx.lease_workspace(runtime, descriptor["identity"])
    identity_path = ctx.artifact(args["identity"], "runtime-identity")
    candidate = read_json(identity_path)
    check(runtime, candidate)
    gcc = compiler(ctx)
    driver = gnu_build_driver(runtime, gcc)
    copied = runtime_view(runtime, ctx.directory / "runtime")
    storage = transfer_tree(runtime / "tests", copied, dirs_exist_ok=True)
    additional_fixtures(args, ctx, copied / "unit-tests")
    files = selected_files(copied / "unit-tests", args["selection"], inventory=args.get("inventory", "unit"))
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
    ctx.env = dict(ctx.env)
    ctx.env.update(GAMBOPT=option, GAMBIT_SMP_EXPECTED_PROCESSORS=str(population),
                   GAMBIT_SMP_AVAILABLE_CPUS=str(available_processors()))
    ctx.env.update(fixture_parameters(args))
    code, output, timeout, _ = ctx.run("processor-probe", [runtime / "gsi/gsi", "-:debug-settings=-,io-settings=lu", "-e",
        '(println "PROCESSORS:" (##current-vm-processor-count))'], copied, 10)
    if not admitted_processors(code, output, timeout, population):
        raise ValueError("suite processor topology was not established")
    observations = run_suite_groups(ctx, runtime, copied, args, files, jobs, option)
    outputs = {}
    if "observationFiles" in args:
        directory = ctx.directory / "suite-observations"
        directory.mkdir(exist_ok=True)
        (directory / "index.json").write_text(json.dumps({
            "schema": "gambit-suite-observations.v1",
            "groups": [{"batch": row["batch"], "shard": row["shard"],
                        "observations": row.get("observations", [])} for row in observations],
            "semanticAdmitted": False}, indent=2) + "\n")
        outputs = ctx.publish("observations", "suite-observations", directory)
    check(runtime, candidate)
    if not all(row["accepted"] for row in observations) or gnu_build_driver(runtime, gcc) != driver:
        raise ValueError("suite child exit, exact completion marker or build driver was not admitted")
    original = runtime / "tests"
    if any(digest(path) != digest(copied / path.relative_to(original)) for path in original.rglob("*") if path.is_file()):
        raise ValueError("suite fixture drift")
    return {"passedFiles": [str(path) for path in files], "mode": args["mode"], "processors": population,
            "jobs": jobs, "buildDriver": driver, "regime": args["regime"], "suiteGroups": observations,
            "storageTransfer": storage,
            "outputs": outputs,
            "claim": "atomic-correctness-coverage-not-whole-mode-timing" if args["regime"] == "atomic-coverage"
                     else "bounded-whole-step-suite-not-performance", "performanceAdmitted": False}


def run_suite_groups(ctx, runtime, copied, args, files, jobs, option):
    from gambit_smp.artifact_storage import transfer_tree
    from gambit_smp.suite_primitives import admitted_suite, partitions, runner_option, runtime_view, SuiteCompletionProgress
    atomic = args["regime"] == "atomic-coverage"
    progress_timed = getattr(ctx, "progress_mode", False)
    file_caps = args.get("fileBudgetSeconds", {})
    group_caps = args.get("groupBudgetSeconds", {})
    batches = [files[index:index + jobs] for index in range(0, len(files), jobs)] if atomic else [files]
    observations = []
    planned = []

    def snapshot(name, value):
        target = ctx.directory / name
        pending = target.with_suffix(".pending.json")
        pending.write_text(json.dumps(value, indent=2) + "\n")
        os.replace(pending, target)

    for batch_index, batch in enumerate(batches):
        deadline = min(ctx.deadline, time.monotonic() + args["batchBudgetSeconds"]) if atomic else ctx.deadline
        grouped = {name for group in group_caps.values() for name in group["files"]}
        ungrouped = [file for file in batch if str(file) not in grouped]
        groups = ([[file] for file in batch] if atomic else
                  [[Path(name) for name in group["files"]] for group in group_caps.values()] +
                  partitions(ungrouped, jobs))
        if file_caps and not atomic:
            bounded = []
            for group in groups:
                pending = []
                for file in group:
                    if str(file) in file_caps:
                        if pending:
                            bounded.append(pending)
                            pending = []
                        bounded.append([file])
                    else:
                        pending.append(file)
                if pending:
                    bounded.append(pending)
            groups = bounded

        planned.extend({"batch": batch_index, "shard": index, "files": [str(file) for file in group]}
                       for index, group in enumerate(groups))
        snapshot("suite-plan.json", {"schema": "gambit-suite-execution-plan.v1",
            "selectedFiles": [str(file) for file in files], "mode": args["mode"],
            "regime": args["regime"], "jobs": jobs, "groups": planned,
            **({"compilerPhaseFiles": args["compilerPhaseFiles"]} if args.get("compilerPhaseFiles") else {}),
            "runtimeAdmitted": False})

        def worker(item):
            from gambit_smp.suite_observations import prepare, capture
            index, group = item
            name = f"suite-{batch_index}-{index}"
            file_cap = file_caps.get(str(group[0])) if len(group) == 1 else None
            group_binding = next(((key, value["budgetSeconds"]) for key, value in group_caps.items()
                                  if value["files"] == [str(file) for file in group]), None)
            local_cap = group_binding[1] if group_binding is not None else file_cap
            child_deadline = min(deadline, time.monotonic() + local_cap) if local_cap is not None else deadline
            work = runtime_view(runtime, ctx.directory / "shards" / name)
            storage = transfer_tree(copied, work, dirs_exist_ok=True)
            selected_observations = prepare(work, args.get("observationFiles", {}), group)
            idle_cap = (local_cap if local_cap is not None else
                        args["batchBudgetSeconds"] if atomic else ctx.idle_window) if progress_timed else None
            cap = idle_cap if progress_timed else child_deadline - time.monotonic()
            if cap <= 0:
                raise TimeoutError("suite batch deadline exhausted before launch")
            phases = None
            if len(group) == 1 and str(group[0]) in args.get("compilerPhaseFiles", []):
                if not progress_timed or args["mode"] != "gsc":
                    raise ValueError("compiled phases require GSC inactivity semantics")
                from gambit_smp.compiler_phase_primitives import run_suite_phases
                phase_started = time.monotonic()
                phases = run_suite_phases(ctx, runtime, work, group[0], name, cap)
                code, timeout = phases[-1]["exit"], any(row["timeout"] for row in phases)
                seconds = time.monotonic() - phase_started
                command_accepted = len(phases) == 3 and all(row["accepted"] for row in phases)
            else:
                code, output, timeout, seconds = ctx.run(name, [runtime / "gsi/gsi", "-:" + runner_option(option), "-f",
                    "run-unit-tests.scm", "-" + args["mode"],
                    *(["-stress"] if args.get("inventory", "unit") == "stress" else []),
                    *[str(Path("unit-tests") / file) for file in group]], work, cap,
                    **({"progress": SuiteCompletionProgress(len(group))} if progress_timed else {}))
                command_accepted = admitted_suite(code, output, timeout, len(group))
            stable = all(digest(path) == digest(work / path.relative_to(copied))
                         for path in copied.rglob("*") if path.is_file())
            accepted = command_accepted and stable and (progress_timed or time.monotonic() <= child_deadline)
            captured = capture(work, selected_observations,
                ctx.directory / "suite-observations" / name) if accepted else []
            if not progress_timed and time.monotonic() > child_deadline:
                accepted = False
            return {"batch": batch_index, "shard": index, "files": [str(file) for file in group],
                    "exit": code, "timeout": timeout, "seconds": seconds, "fileBudgetSeconds": file_cap,
                    "storageTransfer": storage,
                    "observations": captured,
                    "groupBudget": group_binding[0] if group_binding is not None else None,
                    "groupBudgetSeconds": group_binding[1] if group_binding is not None else None,
                    **({"compilerPhases": phases,
                        "phaseInactivitySeconds": cap,
                        "assertionProtocol": "original-gsi-loader-and-unit-test-exit"} if phases is not None else {}),
                    "accepted": accepted}

        with ThreadPoolExecutor(max_workers=jobs) as pool:
            futures = [pool.submit(worker, item) for item in enumerate(groups)]
            rows = []
            for future in as_completed(futures):
                rows.append(future.result())
                # A slow owner must not hide already observed completed groups.
                snapshot("suite-progress.json", sorted(observations + rows,
                    key=lambda row: (row["batch"], row["shard"])))
        rows.sort(key=lambda row: row["shard"])
        observations.extend(rows)
        if not all(row["accepted"] for row in rows):
            return observations
    if sorted(file for row in observations for file in row["files"]) != sorted(str(file) for file in files):
        raise ValueError("suite shards did not cover the exact file inventory")
    return observations


def compiler_observation(args, ctx):
    """Observe default or changed C scheduling phases; never qualify a suite."""
    from gambit_smp.recipes import read_json
    from gambit_smp.suite_primitives import check_runtime, runtime_view, selected_files
    from gambit_smp.compiler_phase_primitives import phase_commands, suite_phase_commands, stage_accepted, EXECUTION_WITNESS
    from gambit_smp.artifact_storage import transfer_tree
    runtime = ctx.artifact(args["runtime"], "source-runtime")
    identity = ctx.artifact(args["identity"], "runtime-identity")
    candidate = read_json(identity)
    check_runtime(runtime, candidate)
    gcc = compiler(ctx)
    driver = gnu_build_driver(runtime, gcc)
    selected = selected_files(runtime / "tests/unit-tests", [args["selection"]])
    if len(selected) != 1:
        raise ValueError("one unchanged original compiler fixture required")
    work = runtime_view(runtime, ctx.directory / "runtime")
    transfer_tree(runtime / "tests/unit-tests", work / "unit-tests")
    inputs = {str(path): digest(path) for path in (runtime / "tests/unit-tests").rglob("*") if path.is_file()}
    ctx.bind(Path(name) for name in inputs)
    cpu = available_processors()
    paths = f",~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    ctx.env = {**ctx.env, "GAMBOPT": f"p{cpu}" + paths}
    flags = ([] if args["scheduling"] == "default-control" else
             ["-fno-modulo-sched", "-fno-reschedule-modulo-scheduled-loops"])
    if args["scheduling"] == "no-scheduling":
        flags.append("-fno-schedule-insns2")
    started = time.monotonic()
    phases = []
    original_loader = args.get("loader") == "original-gsi"
    plan = suite_phase_commands(selected[0], work) if original_loader else phase_commands(selected[0], work)
    if any(artifact is not None and artifact.exists() for _, _, _, artifact in plan):
        raise ValueError("compiler phase outputs must not preexist")
    stage_timed = getattr(ctx, "receipt", {}).get("timeoutPolicy", {}).get("mode") in {"per-stage", "progress"}
    for name, executable, options, artifact in plan:
        if name == "c-to-dynamic-module" and not original_loader:
            options = ["-f", "-e", '(exit (if (compile-file "probe.c" options: (quote (verbose)) '
                       'cc-options: ' + json.dumps(" ".join(flags)) + ' output: "probe.o1") 0 1))']
        phase_cap = args["phaseBudgetSeconds"]
        remaining = min(ctx.remaining(), phase_cap if stage_timed else phase_cap - (time.monotonic() - started))
        if remaining <= 0:
            raise TimeoutError("compiler phase watchdog exhausted")
        output = ctx.require(name, [runtime / executable, *options], work, remaining)
        row = ctx.commands[-1]
        if not stage_accepted(row["exit"], row["timeout"], output, artifact,
                              EXECUTION_WITNESS if name == "compiled-execution" and not original_loader else None):
            raise ValueError("compiler phase lacks successful artifact or execution witness")
        phases.append({"phase": name, "seconds": row["seconds"],
                       "artifactSha256": digest(artifact) if artifact else None})
    check_runtime(runtime, candidate)
    if any(digest(Path(name)) != sha for name, sha in inputs.items()) or gnu_build_driver(runtime, gcc) != driver:
        raise ValueError("compiler diagnostic input or driver drift")
    return {"phases": phases, "scheduling": args["scheduling"], "ccOptions": flags,
            "loaderContract": "original-gsi" if original_loader else "diagnostic-entry",
            "phaseBudgetSeconds": args["phaseBudgetSeconds"], "hostCpuCapacity": cpu,
            "phaseTiming": "independent-watchdogs" if stage_timed else "legacy-shared-budget",
            "claim": ("default-command-phase-control-not-suite-or-performance-admission"
                      if args["scheduling"] == "default-control" else
                      "changed-command-phase-diagnostic-not-suite-or-performance-admission"),
            "runtimeAdmitted": False, "performanceAdmitted": False}


def executable_test(args, ctx):
    """Compile and execute a standalone fixture against the same current runtime."""
    # Per-fixture parameters must not become undeclared inputs to later stages.
    ctx.env = dict(ctx.env)
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.suite_primitives import check_runtime, capacity
    runtime = ctx.artifact(args["runtime"], {"seed-runtime", "source-runtime"})
    identity = ctx.artifact(args["identity"], "runtime-identity")
    candidate = read_json(identity)
    check_runtime(runtime, candidate)
    gcc = compiler(ctx)
    driver = gnu_build_driver(runtime, gcc)
    source = source_path(ctx.root, args["program"])
    source_sha = digest(source)
    ctx.bind([source])
    copied = ctx.directory / "fixture.scm"
    shutil.copy2(source, copied)
    output = ctx.directory / "fixture"
    cpu = available_processors()
    population, _ = capacity(cpu, 1, False)
    paths = f",~~lib={runtime / 'lib'},~~bin={runtime / 'bin'},~~include={runtime / 'include'}"
    ctx.env.update(GAMBOPT=f"p{population}" + paths)
    ctx.require("compile-executable", [runtime / "gsc/gsc", "-exe", "-o", output,
                "-cc-options", "-pthread", "-ld-options", "-pthread", copied], ctx.directory, ctx.remaining())
    if not output.is_file() or digest(source) != source_sha or digest(copied) != source_sha:
        raise ValueError("Scheme executable source or output changed")
    executable_sha = digest(output)
    topology = args.get("processorTopology", "fixture-managed")
    # Independent VM fixtures expand their own cohorts; single-VM controls use
    # the same host-derived population as compilation, never a fixed CPU count.
    execution_population = population if topology == "host-managed" else 1
    ctx.env.update(GAMBOPT=f"p{execution_population}" + paths,
                   GAMBIT_SMP_AVAILABLE_CPUS=str(cpu),
                   GAMBIT_SMP_EXPECTED_PROCESSORS=str(execution_population))
    ctx.env.update(fixture_parameters(args))
    diagnostic = None
    if "stackSampleAfterSeconds" in args:
        tool = ctx.tools.get("darwinSample")
        if tool is None:
            raise ValueError("sealed Darwin sampling tool required")
        diagnostic = {"tool": tool, "toolSha256": digest(Path(tool)),
                      "directory": str(ctx.directory), "afterSeconds": args["stackSampleAfterSeconds"]}
    execution_cap = min(ctx.remaining(), args.get("executionBudgetSeconds", ctx.remaining()))
    units = None
    if "completedUnits" in args:
        from gambit_smp.completed_units import CompletedUnits
        if not getattr(ctx, "progress_mode", False):
            raise ValueError("completed units require the declared inactivity watchdog policy")
        units = CompletedUnits(args["completedUnits"])
    log = ctx.require("run-executable", [output], ctx.directory, execution_cap,
                      **({"diagnostic": diagnostic} if diagnostic is not None else {}),
                      **({"progress": units} if units is not None else {}))
    execution_command = ctx.commands[-1]
    completed = {}
    if units is not None:
        count, log = units.project(log, final=True)
        completed = {"completedUnitCount": count, "completionContract": args["completedUnits"],
                     "watchdogKind": "no-completed-unit-progress"}
    expected_stderr = args.get("stderr", "").encode("utf-8")
    stderr_matches = execution_command.get("stderrBytes", 0) == len(expected_stderr)
    if expected_stderr:
        stderr_matches = stderr_matches and (ctx.directory / "run-executable.stderr").read_bytes() == expected_stderr
    transcript = {}
    if "stdoutTranscript" in args:
        from gambit_smp.native_transcript import review
        transcript["transcriptObservation"] = review(args["stdoutTranscript"], ctx, log, execution_population)
        stdout_matches = log.endswith(args["stdout"])
    else:
        stdout_matches = log == args["stdout"]
    if (not stdout_matches or not stderr_matches
            or digest(output) != executable_sha or digest(source) != source_sha
            or digest(copied) != source_sha or available_processors() != cpu
            or gnu_build_driver(runtime, gcc) != driver):
        raise ValueError("Scheme executable observation, identity or host capacity changed")
    check_runtime(runtime, candidate)
    latency = {}
    if "latency" in args:
        from gambit_smp.latency_observation import summarize
        latency["latencyObservation"] = summarize(ctx.directory, args["latency"], cpu,
                                                    execution_command["seconds"])
    return {"program": args["program"], "programSha256": source_sha,
            "executableSha256": executable_sha, "candidateReceiptSha256": digest(identity),
            "hostCpuCapacity": cpu, "compileProcessors": population,
            "processorTopology": topology, "executionProcessors": execution_population,
            "runtimeAdmitted": False, "nativeGcPassed": False,
            "claim": "same-producer-standalone-fixture-only", **latency, **transcript, **completed}


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
    ctx.env["GAMBIT_SMP_AVAILABLE_CPUS"] = str(available_processors())
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
    from gambit_smp.completed_producer import validate as validate_completed, reuse as reuse_completed
    from gambit_smp.step_checkpoint import validate_seed_arguments, import_seed
    from gambit_smp.runtime_artifact import validate_import, consume
    from gambit_smp.upstream_tests import validate as validate_upstream, execute as execute_upstream
    entries = {
        "gambit.materialize": (validate_materialize, materialize, (("source", "source-tree"),)),
        "gambit.configure": (validate_configure, configure, (("source", "configured-tree"),)),
        "gambit.object": (validate_object, object_build, (("object", "native-object"),)),
        "gambit.seed-core": (validate_source, seed, (("runtime", "seed-runtime"), ("identity", "runtime-identity"))),
        "gambit.seed-checkpoint": (validate_seed_arguments, import_seed, (("runtime", "seed-runtime"), ("identity", "runtime-identity"))),
        "gambit.regenerate-module": (validate_regenerate, regenerate, (("generated", "c-source"),)),
        "gambit.source-core": (validate_runtime, source_core, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.runtime-import": (validate_import, consume, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.upstream-tests": (validate_upstream, execute_upstream, (("observations", "upstream-test-observations"),)),
        "gambit.bootstrap": (validate_bootstrap, bootstrap, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.completed-runtime": (validate_completed, reuse_completed, (("runtime", "source-runtime"), ("identity", "runtime-identity"))),
        "gambit.suite": (validate_suite, suite, (("observations", "suite-observations"),)),
        "gambit.review": (validate_review, bind_review, (("review", "bound-native-review"),)),
        "gambit.probe": (validate_probe, probe, (("observation", "current-producer-observation"),)),
        "gambit.executable-test": (validate_executable_test, executable_test, ()),
        "gambit.compiler-observation": (validate_compiler_observation, compiler_observation, ()),
        "native.c-build": (validate_c, c_build, (("executable", "native-executable"), ("object", "native-object"))),
        "native.test": (validate_native_test, native_test, ()),
    }
    return {name: Capability(validate, executor=executor, graph=graph, outputs=outputs)
            for name, (validate, executor, outputs) in entries.items()}
