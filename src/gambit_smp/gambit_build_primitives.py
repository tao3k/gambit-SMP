"""Build-system contracts, with no experiment dispatch or patch generation."""
from pathlib import Path
import json
import os
import re
import shlex
import shutil
import sys
import time

from gambit_smp.framework import available_processors, digest

MODULE_CHECK_INPUTS = ('lib/_kernel.scm', 'lib/_nonstd.scm', 'lib/_system.scm')


def scheme_inputs(source):
    """Complete Scheme input set used by the generation manifest."""
    source = Path(source)
    return {p.relative_to(source).as_posix(): digest(p)
            for folder in ('lib', 'gsi', 'gsc')
            for p in (source / folder).rglob('*.scm')}


def build_errors(output):
    pattern = re.compile(r"(?:^|\n)(?:[^\n]*\*\*\*[^\n]*(?:Error|Stop\.)|[^\n]*(?:fatal error:|Segmentation fault|Bus error))")
    return [match.group(0).strip() for match in pattern.finditer(output)]


def host_compiler_reservation():
    """Bound every native compiler build within an 8 GiB runner envelope."""
    physical = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES")
    if type(physical) is not int or physical <= 0:
        raise ValueError("host physical memory is required for the compiler reservation")
    budget = min(physical, 8 * 1024 ** 3)
    parent = min(1024 ** 3, budget // 4)
    job = min(7 * 1024 ** 3, budget - parent)
    if job <= 0:
        raise ValueError("host memory cannot reserve one compiler job")
    return {"memory_bytes": budget, "parent_reserve_bytes": parent,
            "job_reserve_bytes": job}


def compiler_rss_limit(reservation):
    """Bound the compiler process group by the reserved host memory budget."""
    if type(reservation) is not dict:
        raise ValueError("compiler reservation required")
    budget = reservation.get("memory_bytes")
    if type(budget) is not int or budget <= 0:
        raise ValueError("compiler reservation requires a positive memory budget")
    return budget


def build_capacity(cpus, *, memory_bytes=None, parent_reserve_bytes=None, job_reserve_bytes=None):
    if type(cpus) is not int or cpus <= 0:
        raise ValueError("positive host CPU budget required")
    # Make shares its jobserver with recursive builds. Each compiler process
    # must share that budget rather than independently using 50% of the host.
    jobs = cpus
    population = max(1, cpus // jobs)
    if any(value is not None for value in (memory_bytes,parent_reserve_bytes,job_reserve_bytes)):
        if (type(memory_bytes) is not int or memory_bytes<=0 or
                type(parent_reserve_bytes) is not int or not 0<=parent_reserve_bytes<memory_bytes or
                type(job_reserve_bytes) is not int or job_reserve_bytes<=0):
            raise ValueError('complete positive build memory reservation required')
        jobs=min(cpus,(memory_bytes-parent_reserve_bytes)//job_reserve_bytes)
        if jobs<1:raise ValueError('one native build job does not fit the memory envelope')
        # This is the bootstrap compiler population, not target VM parallelism.
        # Lower Make concurrency must not enlarge each Scheme compiler gang.
        return dict(availableProcessors=cpus,makeJobs=jobs,compilerProcessors=1,
                    selection='shared-cpu-and-memory-reservation',memoryBytes=memory_bytes,
                    parentReserveBytes=parent_reserve_bytes,jobReserveBytes=job_reserve_bytes,
                    reservationIsMeasuredUpperBound=False)
    return {"availableProcessors": cpus, "makeJobs": jobs,
            "compilerProcessors": population, "selection": "host-auto-shared-budget"}


class BootstrapPhaseProgress:
    """A next phase closes the preceding attempt; final success is separate."""
    def __init__(self, *, clock=time.monotonic, observation_path=None):
        self.clock = clock
        self.started = clock()
        self.boundaries = []
        self.observation_path = observation_path
        self.streams = {"stdout": "", "stderr": ""}

    def checkpoint(self, stdout, stderr):
        if self.observation_path is None:
            return
        changed = False
        for name, value in (("stdout", stdout), ("stderr", stderr)):
            previous = self.streams[name]
            if not value.startswith(previous):
                raise ValueError("phase observer requires cumulative stream prefixes")
            if len(value) > len(previous):
                with self.observation_path.with_name("from-scratch.partial." + name).open("a") as output:
                    output.write(value[len(previous):])
                self.streams[name] = value
                changed = True
        if not changed and self.observation_path.exists():
            return
        pending = self.observation_path.with_suffix(".pending")
        pending.write_text(json.dumps({"basis": "first observer receipt of make phase announcements; buffered output and polling may coalesce boundaries",
            "boundaries": self.boundaries, "nativeStageDurationsMeasured": False,
            "completionObserved": False}, indent=2) + "\n")
        pending.replace(self.observation_path)

    def __call__(self, stdout, stderr):
        expected = (1, 2, 3, 4, 1, 2, 3, 4)
        reached = 0
        for line in stdout.splitlines():
            if not line.startswith("*** making phase"):
                continue
            if reached >= len(expected) or line != f"*** making phase{expected[reached]}":
                break
            reached += 1
        if reached > len(self.boundaries):
            observed = self.clock() - self.started
            for index in range(len(self.boundaries), reached):
                self.boundaries.append({"pass": index // 4 + 1,
                    "phase": expected[index], "firstObservedSeconds": observed})
        self.checkpoint(stdout, stderr)
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


def build_hosted_core(stages, source, budget, *, required_generated=None, bootstrap_compiler=None):
    """Regenerate target C before compiling against a changed runtime ABI.

    Use either this tree's interpreted igsc sources or a source-bound complete
    AOT compiler. The host runtime is never linked into the target. The
    following self-source pass remains a separate observation.
    """
    deadline = time.monotonic() + budget
    scheme = scheme_inputs(source)
    # Linker-generated _gambit*.c / *_*.c have no matching Scheme source.
    # They belong to the cohort just as much as Scheme-to-C module products.
    generated = (list(required_generated) if required_generated is not None else
                 sorted(str(p.relative_to(source)) for folder in ("lib", "gsi", "gsc")
                        for p in (source/folder).glob("_*.c")))
    if not generated:
        raise ValueError("explicit old generated-C inventory required")
    boot = source / "gsc-boot"
    shutil.copy2(bootstrap_compiler or source/"gsc/igsc.scm", boot)
    boot.chmod(boot.stat().st_mode | 0o111)
    boot_hash = digest(boot)
    code, _, timed, _ = stages.run("hosted-bootclean", ["make", "bootclean"], source, min(10, budget))
    remaining_old = [name for name in generated if (source/name).exists()]
    if code != 0 or timed or remaining_old or digest(boot) != boot_hash:
        return False, {"sourceRegenerationEstablished": False, "remainingOldC": remaining_old}
    remaining = deadline-time.monotonic()
    if remaining <= 0:return False, {"sourceRegenerationEstablished": False, "wholeBudgetExhausted": True}
    ok, observation = build_seed_core(stages, source, remaining)
    missing = [name for name in generated if not (source/name).is_file()]
    stable = scheme_inputs(source) == scheme
    ok = ok and not missing and stable
    observation.update(sourceRegenerationEstablished=ok, scmRegenerationEstablished=ok,
        sourceCompilerSha256=boot_hash, schemeInputs=scheme, schemeInputsStable=stable,
        generatedSources=generated, missingGeneratedSources=missing,
        generatedHashes={name:digest(source/name) for name in generated if (source/name).is_file()},
        hostRuntimeLinkedIntoTarget=False, fullTwoPassBootstrapEstablished=False)
    return ok, observation


def build_seed_core(stages, source, budget):
    plan = build_capacity(available_processors(),**getattr(stages,'memory_reservation',{}))
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
        "processors": jobs, "processorSelection": plan["selection"],
        "capacity": plan, "artifacts": artifacts,
        "recursiveBuildErrors": errors, "scmRegenerationEstablished": False,
        "watchdogKind": "completed-native-target-inactivity" if progress_timed else "wall-clock"}


def regenerate_module(stages, source, name, budget, *, interpreted=False, processors=None,
                      syntax_check=False, gcc=None, bootstrap_host=None, bootstrap_host_sha256=None,
                      phase_trace=False, work_trace=False):
    deadline = time.monotonic() + budget
    module = Path(name)
    if (len(module.parts) != 2 or module.parts[0] not in {"lib", "gsi", "gsc"}
            or module.suffix != ".scm" or not module.name.startswith("_")):
        raise ValueError("explicit runtime/compiler Scheme module required")
    directory = source / module.parent
    if type(interpreted) is not bool:
        raise ValueError("interpreted must select the in-tree source compiler")
    if type(phase_trace) is not bool or (phase_trace and interpreted):
        raise ValueError('phase_trace selects only the compiled GSC observer')
    if type(work_trace) is not bool or (work_trace and not phase_trace):
        raise ValueError('work_trace requires the native phase observer')
    count = processors
    if count is not None and (type(count) is not int or not 0 < count <= available_processors()):
        raise ValueError("regeneration processors must fit host capacity")
    compiler = source / ("gsc/igsc.scm" if interpreted else "gsc/gsc")
    if bootstrap_host is not None and (not interpreted or not syntax_check):
        raise ValueError('an external interpreter host is diagnostic-only')
    inputs = {name: digest(source / module), str(compiler.relative_to(source)): digest(compiler)}
    frozen = None
    frozen_host = None
    host_sha = None
    gcc_sha = None
    if syntax_check or phase_trace:
        if syntax_check and ((interpreted and bootstrap_host is None) or module.parts[0] != 'lib' or gcc is None):
            raise ValueError('module syntax checks require a bound emitter host and configured library GCC')
        from gambit_smp.make_lineage import freeze_emitter
        inputs.update(scheme_inputs(source))
        inputs.update({str(p.relative_to(source)): digest(p) for p in source.rglob('*')
                       if p.is_file() and (p.suffix in {'.h', '.inc'} or p.name == 'makefile')})
        gcc_sha = digest(Path(gcc)) if gcc is not None else None
        if any(getattr(stages, 'env', {}).get(key) for key in
               ('DYLD_LIBRARY_PATH', 'DYLD_INSERT_LIBRARIES', 'DYLD_FRAMEWORK_PATH',
                'DYLD_FALLBACK_LIBRARY_PATH', 'LD_LIBRARY_PATH', 'LD_PRELOAD', 'LD_AUDIT')):
            raise ValueError('module emitter loader has an unbound library override')
        holder = stages.out / 'emitter'
        holder.mkdir()
        def loader(argv):
            code, _, timed_out, _ = stages.run('module-emitter-loader', argv, source,
                                              min(10, max(.001, deadline - time.monotonic())))
            if code != 0 or timed_out:
                raise ValueError('module emitter loader inspection failed')
            return stages.stdout
        if bootstrap_host is not None:
            host_sha = digest(Path(bootstrap_host))
            if bootstrap_host_sha256 is not None and host_sha != bootstrap_host_sha256:
                raise ValueError('declared module interpreter host changed before freezing')
            frozen_host = freeze_emitter(holder, Path(bootstrap_host), 1, run=loader)
            if digest(frozen_host) != host_sha:
                raise ValueError('module interpreter host changed during freezing')
        else:
            frozen = freeze_emitter(holder, compiler, 1, run=loader)
    if interpreted:
        host = getattr(stages, 'env', {}).get('GAMBIT_BOOT_GSI')
        if bootstrap_host is None and host is not None and Path(host).resolve() != (source/'gsi/gsi').resolve():
            raise ValueError("interpreted regeneration requires the bound in-tree GSI")
        # igsc loads this tree's compiler and macro sources. Bind that closure,
        # not just the executable script or selected emission input.
        inputs.update(scheme_inputs(source))
        if bootstrap_host is None:
            inputs["gsi/gsi"] = digest(source/"gsi/gsi")
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
    argv[0] = str(frozen or compiler)
    if count is not None:
        argv[1] = argv[1].replace("-:", "-:p" + str(count) + ",", 1)
    argv[-1:] = ["-o", str(output), module.name]
    observer = None
    if phase_trace:
        from gambit_smp.compiler_trace import native_observer_argv
        ld_options = ''
        if work_trace:
            inputs['bin/gambuild-C'] = digest(source/'bin/gambuild-C')
            if sys.platform == 'darwin':
                code, _, timed, _ = stages.run('work-observer-sdk',
                    ['/usr/bin/xcrun', '--show-sdk-path'], source,
                    min(10, max(.001, deadline-time.monotonic())))
                sdk = stages.stdout.strip()
                if code != 0 or timed or not Path(sdk).is_absolute() or not Path(sdk).is_dir():
                    raise ValueError('work observer needs the actual linker SDK')
                ld_options = '-Wl,-syslibroot,' + shlex.quote(sdk)
        argv, observer = native_observer_argv(argv, stages.out,
            work_source=source if work_trace else None, work_ld_options=ld_options)
    host_environment = {}
    previous_environment = {}
    if frozen_host:
        host_environment = {'GAMBIT_BOOT_GSI': str(frozen_host), 'GAMBIT_COMPILER_TRACE': '1'}
        previous_environment = {key: stages.env.get(key) for key in host_environment}
        stages.env.update(host_environment)
    try:
        code, _, timeout, _ = stages.run("regenerate-module", argv, directory,
                                        max(.001, deadline - time.monotonic()))
    finally:
        for key, value in previous_environment.items():
            if value is None:
                stages.env.pop(key, None)
            else:
                stages.env[key] = value
    stable = all(digest(source / path) == expected for path, expected in inputs.items())
    stable = stable and (gcc_sha is None or digest(Path(gcc)) == gcc_sha)
    stable = stable and (observer is None or digest(Path(observer['path'])) == observer['sha256'])
    if observer and observer.get('work'):
        work = observer['work']
        stable = stable and digest(Path(work['path'])) == work['sha256']
        stable = stable and all(digest(Path(path)) == sha for path, sha in work['sourceInputs'].items())
        for kind in ('nativeSource','nativeModule'):
            path = Path(work[kind])
            if path.is_file():
                work[kind+'Sha256'] = digest(path)
    stable = stable and (frozen is None or digest(frozen) == inputs[str(compiler.relative_to(source))])
    if frozen_host:
        stable = stable and digest(Path(bootstrap_host)) == host_sha and digest(frozen_host) == host_sha
    ok = code == 0 and not timeout and output.is_file() and output.stat().st_size > 0 and stable
    observation = {"module": name, "inputs": inputs, "inputsStable": stable,
                "generatedSha256": digest(output) if output.is_file() else None,
                "scope": "One actual SCM-to-C invocation; no linked regeneration, target producer or full bootstrap admission.",
                "runtimeAdmitted": False, "interpretedSourceCompiler": interpreted,
                "processors": count, 'emissionCommand': argv, 'syntaxChecked': False}
    if observer is not None:
        observation['phaseObserver'] = observer
    if work_trace:
        observation.update(mode='source-instantiated-frontend-work-diagnostic',
            targetProducerAdmitted=False, familyAdmitted=False,
            diagnosticCNotReusable=True,
            performanceMeaning='diagnostic overhead included; source bodies need not match linked native compiler')
    if frozen_host:
        observation.update(mode='hosted-source-compiler-diagnostic',
            compilerScriptSha256=digest(compiler), hostSha256=host_sha,
            hostLoader=json.loads((frozen_host.parent / 'identity.json').read_text())['loader'],
            hostEnvironment=host_environment, familyAdmitted=False,
            targetProducerAdmitted=False)
    if frozen:
        observation['emitterSha256'] = digest(frozen)
        observation['emitterLoader'] = json.loads((frozen.parent / 'identity.json').read_text())['loader']
    if not ok or not syntax_check:
        observation['failedAt'] = None if ok else 'emission'
        return ok, observation
    object_path = stages.out / (module.stem + '.o')
    code, _, timeout, _ = stages.run('module-syntax-recipe',
        ['make', '-n', '-o', 'makefile', '-W', output.name, object_path.name,
         'BUILD_OBJ_INPUT_FILENAMES_PARAM=' + str(output),
         'BUILD_OBJ_OUTPUT_FILENAME_PARAM=' + str(object_path)], directory,
        min(10, max(.001, deadline - time.monotonic())))
    if code != 0 or timeout:
        observation['failedAt'] = 'syntax-recipe'
        return False, observation
    configured = command(stages.stdout, Path(gcc).resolve(strict=True), output, object_path)
    syntax = []
    skip = False
    for arg in configured:
        if skip:
            skip = False
        elif arg == '-o':
            skip = True
        elif arg != '-c':
            syntax.append(arg)
    standards = [arg for arg in syntax if arg.startswith('-std=')]
    if standards and any(arg not in {'-std=c23', '-std=gnu23'} for arg in standards):
        raise ValueError('configured syntax-check recipe differs from GCC/C23')
    dependencies = stages.out / 'syntax.d'
    syntax += ([] if standards else ['-std=c23']) + ['-fsyntax-only', '-MD', '-MF', str(dependencies)]
    code, _, timeout, _ = stages.run('module-syntax-check', syntax, directory,
                                    max(.001, deadline - time.monotonic()))
    headers = {}
    if dependencies.is_file():
        _, separator, paths = dependencies.read_text().replace('\\\n', ' ').partition(':')
        if separator:
            headers = {str(p): digest(p) for p in
                       dict.fromkeys((directory / token).resolve(strict=True) for token in shlex.split(paths))}
    stable = (all(digest(source / path) == expected for path, expected in inputs.items())
              and digest(Path(gcc)) == gcc_sha and digest(output) == observation['generatedSha256'])
    if frozen_host:
        stable = stable and digest(Path(bootstrap_host)) == host_sha and digest(frozen_host) == host_sha
    else:
        stable = stable and digest(compiler) == observation['emitterSha256'] and digest(frozen) == observation['emitterSha256']
    ok = code == 0 and not timeout and stable and bool(headers) and not object_path.exists()
    observation.update(configuredObjectCommand=configured, syntaxCommand=syntax,
                       gccSha256=gcc_sha,
                       headersAndSources=headers, inputsStable=stable, syntaxChecked=ok,
                       failedAt=None if ok else 'syntax', familyAdmitted=False)
    return ok, observation


def rebuild_source_core(stages, source, budget, *, incremental=False, retained_generation=None, checkpoint=None,
                        witness=None):
    deadline = time.monotonic() + budget
    progress_timed = getattr(stages, "progress_mode", False)
    plan = build_capacity(available_processors(),**getattr(stages,'memory_reservation',{}))
    scheme = scheme_inputs(source)
    generated = sorted(str(p.relative_to(source)) for folder in ("lib", "gsi", "gsc")
                       for p in (source/folder).glob("_*.c"))
    if incremental and retained_generation:
        generated = retained_generation['generatedSources']
    if not generated:
        raise ValueError("seed source must have an explicit generated-C inventory")
    compiler = source / ("gsc-boot" if incremental else "gsc/gsc")
    seed_hash = digest(compiler)
    if not incremental:
        shutil.copy2(compiler, source / "gsc-boot")
        code, _, timeout, _ = stages.run("bootclean", ["make", "bootclean"], source, min(10, budget))
        retained = [name for name in generated if (source / name).exists()]
        if code != 0 or timeout or retained or digest(source / "gsc-boot") != seed_hash:
            return False, {"generatedCStillPresent": retained, "scmRegenerationEstablished": False}
        if checkpoint is not None:
            checkpoint(dict(generatedSources=generated, bootstrapCompilerSha256=seed_hash,
                            schemeInputs=scheme))
    remaining = budget if progress_timed else deadline - time.monotonic()
    if remaining <= 0:
        return False, {"scmRegenerationEstablished": False, "wholeBudgetExhausted": True}
    argv = core_command(plan)
    if witness is not None:
        argv.insert(-1, witness)
    if progress_timed:
        argv.insert(1, "--debug=b")
    code, log, timeout, _ = stages.run("source-core", argv, source, remaining,
        **({"progress": CoreBuildProgress()} if progress_timed else {}))
    missing = [name for name in generated if not (source / name).is_file()]
    stable = scheme_inputs(source) == scheme
    artifacts = {name: digest(source / name) for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a")
                 if (source / name).is_file()}
    errors = build_errors(log)
    ok = code == 0 and not timeout and not missing and stable and not errors and len(artifacts) == 3
    return ok, {"capacity": plan, "seedCompilerSha256": seed_hash, "schemeInputs": scheme, "schemeInputsStable": stable,
        'generationMode': 'incremental' if incremental else 'cold-bootclean',
        'bootstrapCompilerSha256': digest(source / 'gsc-boot'),
        "generatedSources": generated, "missingGeneratedSources": missing,
        "generatedHashes": {name: digest(source / name) for name in generated if (source / name).is_file()},
        "recursiveBuildErrors": errors, "artifacts": artifacts,
        "watchdogKind": "completed-native-target-inactivity" if progress_timed else "wall-clock",
        "scmRegenerationEstablished": ok, "fullTwoPassBootstrapEstablished": False,
        "runtimeAdmitted": False, "releaseAdmitted": False}
