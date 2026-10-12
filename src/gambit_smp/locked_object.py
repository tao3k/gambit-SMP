"""Configure a locked source slice and compile mem.c, without runtime admission."""
import argparse
import json
from pathlib import Path
import shutil
import shlex
import time
from contextlib import contextmanager

from gambit_smp.allocator_object import command
from gambit_smp.framework import ROOT, available_processors, digest, execute, gnu_compiler
from gambit_smp.source_materialize import locked_source


class BuildStages:
    """Capture effective commands, budgets and raw/portable logs for each stage."""
    def __init__(self, source, out, env):
        self.source, self.out, self.env = source, out, env
        self.results = []

    def portable(self, text):
        for path, replacement in ((self.source, "${SOURCE}"), (self.out, "${OUTPUT}"),
                                  (ROOT, "${RESEARCH_ROOT}")):
            text = text.replace(str(path), replacement)
        return text

    def run(self, name, argv, cwd, cap):
        code, log, timeout, seconds = execute(argv, cwd, cap, env=self.env)
        path = self.out / (name + ".log")
        path.write_text(log)
        portable = self.out / (name + ".portable.log")
        portable.write_text(self.portable(log))
        self.results.append(dict(stage=name, exit=code, timeout=timeout, seconds=seconds,
            budgetSeconds=cap, argv=[self.portable(str(arg)) for arg in argv],
            cwd=self.portable(str(cwd)), rawLogSha256=digest(path),
            portableLogSha256=digest(portable)))
        return code, log, timeout, seconds


@contextmanager
def preserve_failure(record):
    """A rejected source-context exit must still leave a DENY receipt."""
    try:
        yield
    except (ValueError, OSError) as error:
        record["contextStable"] = False
        record["failure"] = {"type": type(error).__name__, "message": str(error)}


def configure_source(source, out, compiler, env, autoconf, *, c_opt="-O1", rts_opt=None):
    stages = BuildStages(source, out, env)
    flags = ["--enable-smp", "--enable-multiple-vms", "--enable-multiple-threaded-vms",
             "--enable-c-opt=" + c_opt]
    if rts_opt is not None:
        flags.append("--enable-c-opt-rts=" + rts_opt)
    for name, argv, cap in (
            ("autoconf", [autoconf, "-o", "configure", "configure.ac"], 30),
            ("configure", ["sh", "./configure", *flags], 90)):
        code, _, timeout, _ = stages.run(name, argv, source, cap)
        if name == "configure" and (source / "config.log").is_file():
            log = (source / "config.log").read_text()
            (out / "config.log").write_text(log)
            (out / "config.portable.log").write_text(stages.portable(log))
        if code != 0 or timeout:
            return stages, False
    return stages, True


def build_seed_core(stages, source, budget):
    from gambit_smp.bootstrap_runtime import build_errors
    jobs = available_processors()
    code, log, timeout, _ = stages.run("seed-core", ["make", "-j" + str(jobs), "core"], source, budget)
    artifacts = {name: digest(source / name) for name in
                 ("gsi/gsi", "gsc/gsc", "lib/libgambit.a") if (source / name).is_file()}
    errors = build_errors(log)
    return code == 0 and not timeout and not errors and len(artifacts) == 3, {
        "processors": jobs, "processorSelection": "host-auto", "artifacts": artifacts,
        "recursiveBuildErrors": errors, "scmRegenerationEstablished": False}


def regenerate_module(stages, source, name, budget):
    module = Path(name)
    if (len(module.parts) != 2 or module.parts[0] not in {"lib", "gsi", "gsc"}
            or module.suffix != ".scm" or not module.name.startswith("_")):
        raise ValueError("explicit runtime/compiler Scheme module required")
    directory = source / module.parent
    compiler = source / "gsc/gsc"
    inputs = {name: digest(source / module), "gsc/gsc": digest(compiler)}
    code, plan, timeout, _ = stages.run("regeneration-recipe",
        ["make", "-n", "-W", module.name, module.with_suffix(".c").name], directory, 10)
    if code != 0 or timeout or len(plan.strip().splitlines()) != 1:
        return False, {"module": name, "recipeAccepted": False}
    argv = shlex.split(plan.strip())
    if (Path(argv[0]).name != "gsc-boot" or argv[-1] != module.name
            or "-c" not in argv or "-f" not in argv or "-o" in argv):
        raise ValueError("unexpected source regeneration recipe")
    output = stages.out / module.with_suffix(".c").name
    if output.exists():
        raise ValueError("fresh generated module output required")
    argv[0] = str(compiler)
    argv[1] = argv[1].replace("-:", "-:p" + str(available_processors()) + ",", 1)
    argv[-1:] = ["-o", str(output), module.name]
    code, log, timeout, _ = stages.run("regenerate-module", argv, directory, budget)
    stable = all(digest(source / path) == sha for path, sha in inputs.items())
    ok = code == 0 and not timeout and output.is_file() and output.stat().st_size > 0 and stable
    return ok, {"module": name, "inputs": inputs, "inputsStable": stable,
                "generatedSha256": digest(output) if output.is_file() else None,
                "scope": "One actual seed-compiler SCM-to-C invocation; not linked regeneration or full bootstrap.",
                "runtimeAdmitted": False}


def rebuild_source_core(stages, source, budget):
    """Remove generated C before rebuilding with the exact freshly linked seed."""
    from gambit_smp.bootstrap_runtime import build_errors
    deadline = time.monotonic() + budget
    scheme = {str(path.relative_to(source)): digest(path)
              for folder in ("lib", "gsi", "gsc") for path in (source / folder).glob("*.scm")}
    generated = sorted(name[:-4] + ".c" for name in scheme
                       if Path(name).name.startswith("_") and (source / (name[:-4] + ".c")).is_file())
    if not generated:
        raise ValueError("seed source must have an explicit generated-C inventory")
    compiler = source / "gsc/gsc"
    seed_hash = digest(compiler)
    shutil.copy2(compiler, source / "gsc-boot")
    code, _, timeout, _ = stages.run("bootclean", ["make", "bootclean"], source, min(10, budget))
    retained = [name for name in generated if (source / name).exists()]
    if code != 0 or timeout or retained or digest(source / "gsc-boot") != seed_hash:
        return False, {"generatedCStillPresent": retained, "scmRegenerationEstablished": False}
    remaining = deadline - time.monotonic()
    if remaining <= 0:
        return False, {"scmRegenerationEstablished": False, "wholeBudgetExhausted": True}
    code, log, timeout, _ = stages.run("source-core", ["make", "-j" + str(available_processors()), "core"], source, remaining)
    missing = [name for name in generated if not (source / name).is_file()]
    stable = all(digest(source / name) == sha for name, sha in scheme.items())
    artifacts = {name: digest(source / name) for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a")
                 if (source / name).is_file()}
    errors = build_errors(log)
    ok = code == 0 and not timeout and not missing and stable and not errors and len(artifacts) == 3
    return ok, {"seedCompilerSha256": seed_hash, "schemeInputs": scheme, "schemeInputsStable": stable,
        "generatedSources": generated, "missingGeneratedSources": missing,
        "generatedHashes": {name: digest(source / name) for name in generated if (source / name).is_file()},
        "recursiveBuildErrors": errors, "artifacts": artifacts,
        "scmRegenerationEstablished": ok, "fullTwoPassBootstrapEstablished": False,
        "runtimeAdmitted": False, "releaseAdmitted": False}


def tool_identity(env):
    result = {}
    for name in ("as", "ld", "sh", "make", "m4"):
        path = shutil.which(name, path=env["PATH"])
        if path is None:
            raise ValueError("required build tool missing: " + name)
        result[name] = dict(path=path, sha256=digest(Path(path).resolve(strict=True)))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-lock", required=True)
    parser.add_argument("--gcc", type=Path, required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--target", choices=("object", "seed-core"), default="object")
    parser.add_argument("--c-opt", choices=("0", "1", "2", "3"), default="1")
    parser.add_argument("--rts-opt", choices=("0", "1", "2", "3"))
    parser.add_argument("--build-budget", type=float, default=120)
    parser.add_argument("--regenerate-source", action="store_true",
                        help="after seed-core, remove generated C and rebuild using the new seed")
    args = parser.parse_args()
    if not 0 < args.build_budget <= 600:
        parser.error("native build budget must be positive and at most 600 seconds")
    if args.target == "seed-core" and args.rts_opt is None:
        parser.error("seed build requires an explicit RTS optimization level")
    if args.regenerate_source and args.target != "seed-core":
        parser.error("source regeneration requires the seed-core target")
    args.out.mkdir(parents=True, exist_ok=False)
    out = args.out.resolve()
    compiler, env, version = gnu_compiler(args.gcc)
    autoconf = shutil.which("autoconf")
    if autoconf is None:
        raise ValueError("autoconf required to regenerate the locked configure.ac")
    autoconf = str(Path(autoconf).resolve(strict=True))
    # Keep the GCC runner's audited Apple assembler/linker search order.
    env["PATH"] += ":" + str(Path(shutil.which("autoconf")).absolute().parent)
    env["CC"] = compiler
    if args.target == "seed-core":
        env.pop("GAMBOPT", None)
    record = {"schema": "gambit-locked-object.v1", "sourceLock": args.source_lock,
              "compiler": version.splitlines()[0], "compilerSha256": digest(Path(compiler)),
              "autoconfSha256": digest(Path(autoconf)), "results": [],
              "environment": {key: env.get(key) for key in ("PATH", "CC", "CFLAGS", "CPPFLAGS", "LDFLAGS", "LIBS")},
              "tools": tool_identity(env),
              "runtimeAdmitted": False, "releaseAdmitted": False,
              "scope": "Configured full mem.c compilation only; no linking or GC execution."}
    if args.target == "seed-core":
        record["scope"] = "Initial core from pinned pre-generated C; not SCM regeneration, full bootstrap or GC admission."
    record["target"] = args.target
    ok = False
    with preserve_failure(record), locked_source(ROOT, args.source_lock) as (source, inputs):
        if args.target == "seed-core":
            retained = out / "source"
            shutil.copytree(source, retained)
            source = retained
        for name in ("locked_object.py", "allocator_object.py", "bootstrap_runtime.py"):
            path = ROOT / "src/gambit_smp" / name
            inputs[path.relative_to(ROOT).as_posix()] = digest(path)
        record["inputs"] = inputs
        record["sourceSha256"] = digest(source / "lib/mem.c")
        stages, ok = configure_source(source, out, compiler, env, autoconf,
                                     c_opt="-O" + args.c_opt,
                                     rts_opt=None if args.rts_opt is None else "-O" + args.rts_opt)
        record["results"] = stages.results
        if ok and args.target == "seed-core":
            ok, built = build_seed_core(stages, source, args.build_budget)
            record.update(built)
            if ok and args.regenerate_source:
                record["seedArtifacts"] = built["artifacts"]
                ok, regenerated = rebuild_source_core(stages, source, args.build_budget)
                record["sourceRegeneration"] = regenerated
                record["scope"] = "One source-regenerated core; not complete two-pass bootstrap or native GC admission."
            record["generatedHeaderSha256"] = digest(source / "include/gambit.h")
            record["configuredMakefileSha256"] = digest(source / "lib/makefile")
        elif ok:
            library = source / "lib"
            output = out / "mem.o"
            code, plan, timeout, seconds = stages.run("recipe",
                ["make", "-n", "-o", "makefile", "-W", "mem.c", "mem.o",
                 "BUILD_OBJ_INPUT_FILENAMES_PARAM=" + str(library / "mem.c"),
                 "BUILD_OBJ_OUTPUT_FILENAME_PARAM=" + str(output)], library, 10)
            ok = code == 0 and not timeout
            if ok:
                argv = command(plan, compiler, library / "mem.c", output)
                code, log, timeout, seconds = stages.run("object", argv, library, 90)
                ok = code == 0 and not timeout and output.is_file()
                if output.is_file():
                    record["objectSha256"] = digest(output)
            record["generatedHeaderSha256"] = digest(source / "include/gambit.h")
            record["configuredMakefileSha256"] = digest(library / "makefile")
        record["contextStable"] = all(digest(ROOT / name) == sha for name, sha in inputs.items())
        record["contextStable"] &= digest(Path(compiler)) == record["compilerSha256"]
        ok &= record["contextStable"]
    ok = ok and record.get("contextStable", False)
    record["status"] = ("seed-core-built" if args.target == "seed-core" else "object-compiled") if ok else "DENY"
    if ok and args.regenerate_source:
        record["status"] = "source-core-rebuilt"
    (out / "receipt.json").write_text(json.dumps(record, indent=2) + "\n")
    print(json.dumps({key: record[key] for key in ("status", "results", "runtimeAdmitted")}))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
