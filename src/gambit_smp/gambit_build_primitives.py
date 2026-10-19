"""Build-system contracts, with no experiment dispatch or patch generation."""
from pathlib import Path
import re
import shlex
import shutil
import time

from gambit_smp.framework import available_processors, digest


def build_errors(output):
    pattern = re.compile(r"(?:^|\n)(?:[^\n]*\*\*\*[^\n]*(?:Error|Stop\.)|[^\n]*(?:fatal error:|Segmentation fault|Bus error))")
    return [match.group(0).strip() for match in pattern.finditer(output)]


def build_capacity(cpus):
    if type(cpus) is not int or cpus <= 0:
        raise ValueError("positive host CPU budget required")
    # Make shares its jobserver with recursive builds. Each compiler process
    # must share that budget rather than independently using 50% of the host.
    jobs = cpus
    population = max(1, cpus // jobs)
    return {"availableProcessors": cpus, "makeJobs": jobs,
            "compilerProcessors": population, "selection": "host-auto-shared-budget"}


class BootstrapPhaseProgress:
    """A next phase closes the preceding attempt; final success is separate."""
    def __call__(self, stdout, stderr):
        expected = (1, 2, 3, 4, 1, 2, 3, 4)
        reached = 0
        for line in stdout.splitlines():
            if not line.startswith("*** making phase"):
                continue
            if reached >= len(expected) or line != f"*** making phase{expected[reached]}":
                break
            reached += 1
        return max(0, reached - 1)


class ConfigureProbeProgress:
    """Completed unique Autoconf probes, not checking announcements or noise."""
    def __call__(self, stdout, stderr):
        completed = set()
        for line in stdout.splitlines(keepends=True):
            if not line.endswith("\n"):
                continue
            match = re.fullmatch(r"checking (.+?)\.\.\. (\S[^\r\n]*)\n", line)
            if match:
                completed.add(match[1])
        return len(completed)


class CoreBuildProgress(BootstrapPhaseProgress):
    """GNU make reports successful target completion after the recipe exits."""
    def __call__(self, stdout, stderr):
        targets = set()
        for line in stdout.splitlines(keepends=True):
            match = re.fullmatch(r"\s*Successfully remade target file ['`]([^'`\r\n]+)'\.\n", line)
            if match:
                name = match[1]
                if name.endswith((".o", ".a")) or Path(name).name in {"gsi", "gsc", "gsc-boot"}:
                    targets.add(name)
        return super().__call__(stdout, stderr) + len(targets)


def core_command(plan, target="core"):
    if target not in {"core", "from-scratch"}:
        raise ValueError("explicit bounded core or bootstrap target required")
    return ["make", "-j" + str(plan["makeJobs"]),
            "GAMBOPT=p" + str(plan["compilerProcessors"]), target]


def command(plan, compiler, source, output):
    lines = [line for line in plan.splitlines() if line.strip()]
    if len(lines) != 1:
        raise ValueError("single compilation recipe required; no setup or extra tasks")
    args = shlex.split(lines[0])
    if (not args or Path(args[0]).resolve(strict=True) != Path(compiler) or
            args.count("-c") != 1 or args.count("-o") != 1 or args.index("-o") + 1 >= len(args) or
            args[args.index("-o") + 1] != str(output) or args.count(str(source)) != 1 or
            "-D___LIBRARY" not in args or "-D___PRIMAL" not in args or
            any(arg in (";", "&&", "||", ">", "|") for arg in args)):
        raise ValueError("unexpected compiler/input/output recipe")
    return args


def build_seed_core(stages, source, budget):
    plan = build_capacity(available_processors())
    jobs = plan["makeJobs"]
    progress_timed = getattr(stages, "progress_mode", False)
    argv = core_command(plan)
    if progress_timed:
        argv.insert(1, "--debug=b")
    code, log, timeout, _ = stages.run("seed-core", argv, source, budget,
        **({"progress": CoreBuildProgress()} if progress_timed else {}))
    artifacts = {name: digest(source / name) for name in
                 ("gsi/gsi", "gsc/gsc", "lib/libgambit.a") if (source / name).is_file()}
    errors = build_errors(log)
    return code == 0 and not timeout and not errors and len(artifacts) == 3, {
        "processors": jobs, "processorSelection": "host-auto-shared-budget",
        "capacity": plan, "artifacts": artifacts,
        "recursiveBuildErrors": errors, "scmRegenerationEstablished": False,
        "watchdogKind": "completed-native-target-inactivity" if progress_timed else "wall-clock"}


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
    plan = stages.stdout
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
    code, _, timeout, _ = stages.run("regenerate-module", argv, directory, budget)
    stable = all(digest(source / path) == expected for path, expected in inputs.items())
    ok = code == 0 and not timeout and output.is_file() and output.stat().st_size > 0 and stable
    return ok, {"module": name, "inputs": inputs, "inputsStable": stable,
                "generatedSha256": digest(output) if output.is_file() else None,
                "scope": "One actual seed-compiler SCM-to-C invocation, not linked regeneration or full bootstrap.",
                "runtimeAdmitted": False}


def rebuild_source_core(stages, source, budget):
    deadline = time.monotonic() + budget
    progress_timed = getattr(stages, "progress_mode", False)
    plan = build_capacity(available_processors())
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
    remaining = budget if progress_timed else deadline - time.monotonic()
    if remaining <= 0:
        return False, {"scmRegenerationEstablished": False, "wholeBudgetExhausted": True}
    argv = core_command(plan)
    if progress_timed:
        argv.insert(1, "--debug=b")
    code, log, timeout, _ = stages.run("source-core", argv, source, remaining,
        **({"progress": CoreBuildProgress()} if progress_timed else {}))
    missing = [name for name in generated if not (source / name).is_file()]
    stable = all(digest(source / name) == expected for name, expected in scheme.items())
    artifacts = {name: digest(source / name) for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a")
                 if (source / name).is_file()}
    errors = build_errors(log)
    ok = code == 0 and not timeout and not missing and stable and not errors and len(artifacts) == 3
    return ok, {"capacity": plan, "seedCompilerSha256": seed_hash, "schemeInputs": scheme, "schemeInputsStable": stable,
        "generatedSources": generated, "missingGeneratedSources": missing,
        "generatedHashes": {name: digest(source / name) for name in generated if (source / name).is_file()},
        "recursiveBuildErrors": errors, "artifacts": artifacts,
        "watchdogKind": "completed-native-target-inactivity" if progress_timed else "wall-clock",
        "scmRegenerationEstablished": ok, "fullTwoPassBootstrapEstablished": False,
        "runtimeAdmitted": False, "releaseAdmitted": False}
