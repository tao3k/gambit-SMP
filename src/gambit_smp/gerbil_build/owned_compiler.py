"""Gerbil build: owned compiler."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
from contextlib import ExitStack

from gambit_smp.gerbil_build.batches import _stdlib_batches, _withdraw_stage1_outputs
from gambit_smp.gerbil_build.compiler_products import _stdlib_compile_products
from gambit_smp.gerbil_build.module_products import module_product_scope
from gambit_smp.gerbil_build.static_units import static_unit_products
from gambit_smp.gerbil_build.custody import _current
from gambit_smp.gerbil_build.dynamic_products import _stdlib_native_products
from gambit_smp.gerbil_build.policy import STAGES, _batch_size, _compiler_jobs, _native_jobs, _through_stage
from gambit_smp.gerbil_build.stage0 import _install_runtime, _stage0_modules
from gambit_smp.gerbil_build.static_products import _stage1_static

def build_owned_compiler(ctx, work, source, runtime, identity, *, revision, core, delta,
                         archive_skipped, stdlib_batch_size=None, through_stage='tools',
                         stage_budget_seconds=600, static_products=False,
                         stdlib_native_products=False, stdlib_native_jobs=None):
    """Experimental staged construction in the leased source tree.

    This driver's 600-second stage envelope and optional product barriers are
    experimental contracts, not the Bazel CI baseline. Darwin construction
    baselines use build_bazel_compiler and the existing source producer.
    Materialization and branch selection stay with the caller.
    """
    from gambit_smp.recipes import read_json, tree_identity
    from gambit_smp.workspace import checkpoint_build_source, write
    from gambit_smp.suite_primitives import check_runtime
    source, runtime, work = Path(source).resolve(), Path(runtime).resolve(), Path(work).resolve()
    if type(stage_budget_seconds) is not int or not 0 < stage_budget_seconds <= 600:
        raise ValueError('Gerbil stage budget must be a positive integer at most 600 seconds')
    if static_products is True or stdlib_native_products is True:
        raise ValueError('unqualified custom native-plan execution withdrawn; use official Gerbil compiler interfaces')
    if type(static_products) is not bool:
        raise ValueError('staticProducts must select a declared boolean build contract')
    if type(stdlib_native_products) is not bool or (stdlib_native_products and stdlib_batch_size is not None):
        raise ValueError('one declared standard-library phase contract required')
    _native_jobs(stdlib_native_jobs)
    if stdlib_native_jobs is not None and not stdlib_native_products:
        raise ValueError('stdlibNativeJobs requires the retired-producer native contract')
    if source not in ctx.leased_workspaces:
        raise ValueError('compiler build requires the current exclusive source lease')
    _batch_size(stdlib_batch_size)
    _through_stage(through_stage)
    if (not isinstance(revision, str) or len(revision) != 40
            or any(c not in '0123456789abcdef' for c in revision)):
        raise ValueError('pinned Gerbil revision required')
    check_runtime(runtime, read_json(identity))
    ctx.bind([identity])
    # Idempotent initialization replaces upstream prepare's rm -rf operations.
    for prefix in ('bootstrap', 'build'):
        for folder in ('bin', 'lib', 'include'):
            (source / prefix / folder).mkdir(parents=True, exist_ok=True)
    payloads = _install_runtime(runtime, source)
    jobs = _compiler_jobs(ctx.env)
    inherited_runtime = ctx.env.get('GAMBOPT', '')
    owned_runtime = ((inherited_runtime + ',') if inherited_runtime else '') + (
        'p1,~~bin='+str(source/'build/bin')+',~~lib='+str(source/'build/lib')+
        ',~~include='+str(source/'build/include'))
    ctx.env.update(GERBIL_PREFIX=str(work / 'prefix'), GERBIL_VERSION=revision,
        GERBIL_VERSION_STRING=revision, GERBIL_BUILD_CORES=str(jobs),
        # Build workers own inter-module concurrency. Bound each compiler VM
        # as stage0 already does explicitly; three compiled VM/SMP features
        # remain enabled, without multiplying workers by host-auto VM resize.
        GAMBOPT=owned_runtime,
        GERBIL_PATH=str(work / 'user'),
        CC=str(ctx.tools['gcc']), GERBIL_GCC=str(ctx.tools['gcc']))
    proofs_path = work / 'gerbil-stages.json'
    proofs = read_json(proofs_path) if proofs_path.is_file() else {}
    reuse = []
    module_schedule = None
    library_schedule = None
    with ExitStack() as consumers:
        for stage in STAGES[:STAGES.index(through_stage)+1]:
            # Only actual completed bootstrap stages with current exact artifacts
            # can be consumed. The downstream dependency-aware builders always run.
            dependencies = {name: proofs[name]['outputs'] for name in ('boot-gxi', 'stage0')
                            if name in proofs and STAGES.index(name) < STAGES.index(stage)}
            inputs = hashlib.sha256(json.dumps(dict(configuration=digest(work / 'configuration.json'),
                runtime=payloads, dependencies=dependencies, coreInputs=core,
                # The pinned bootstrap/compiler scripts use build cores to schedule
                # independent actions. Keep that execution budget in observations,
                # not the native module's semantic input identity.
                compilerContext={'GAMBOPT':ctx.env.get('GAMBOPT')},
                nativePlan=bool(static_products) if stage == 'stage1' else False), sort_keys=True).encode()).hexdigest()
            if stage in {'boot-gxi', 'stage0', 'stage1'} and _current(source, proofs.get(stage), inputs, stage=stage, root=ctx.root):
                reuse.append(stage)
                continue
            if stage == 'libgerbil' and library_schedule and library_schedule.get('stageComplete') is True:
                consumers.enter_context(module_product_scope(ctx,work,source,library_schedule))
            modules = None
            if stage == 'stdlib' and stdlib_native_products:
                library_schedule = _stdlib_native_products(ctx, source, stage_budget_seconds=stage_budget_seconds,
                                                          native_jobs=stdlib_native_jobs)
            elif stage == 'stdlib' and stdlib_batch_size is not None:
                library_schedule = _stdlib_batches(ctx, work, source, inputs, stdlib_batch_size,
                                                   stage_budget_seconds=stage_budget_seconds)
            elif stage == 'stage0':
                modules,module_schedule = _stage0_modules(ctx,work,source,inputs,
                                                         stage_budget_seconds=stage_budget_seconds)
            elif stage == 'stdlib' and (source/'src/gerbil/compiler/compile-products.ss').is_file():
                library_schedule = _stdlib_compile_products(ctx,work,source,runtime,
                                                            stage_budget_seconds=stage_budget_seconds)
            else:
                if stage == 'stage1':
                    _withdraw_stage1_outputs(ctx, source)
                if stage == 'stage1' and static_products:
                    _stage1_static(ctx,work,source,payloads,identity,stage_budget_seconds)
                else:
                    if stage == 'libgerbil' and library_schedule and library_schedule.get('stageComplete') is True:
                        with static_unit_products(ctx,work,source,library_schedule):
                            ctx.require('gerbil-' + stage, [ctx.tools['sh'], './build.sh', stage],
                                        source / 'src', min(stage_budget_seconds, ctx.remaining()))
                    else:
                        ctx.require('gerbil-' + stage, [ctx.tools['sh'], './build.sh', stage],
                                    source / 'src', min(stage_budget_seconds, ctx.remaining()))
                if (ctx.commands[-1].get('parentReaped') is not True
                        or ctx.commands[-1].get('processGroupQuiescent') is not True):
                    raise ValueError('Gerbil stage has no completed quiescent process observation: ' + stage)
            if stage in {'boot-gxi', 'stage0', 'stage1'}:
                roots = {'boot-gxi': ['src/gerbil/boot-gxi'],
                         'stage0': ['bootstrap'], 'stage1': ['build/bin', 'build/lib/gerbil', 'build/lib/static']}[stage]
                outputs, links = {}, {}
                for name in roots:
                    target = source / name
                    paths = list(target.rglob('*')) if target.is_dir() else [target]
                    outputs.update({str(path.relative_to(source)): digest(path) for path in paths
                                    if path.is_file() and not path.is_symlink()})
                    links.update({str(path.relative_to(source)): str(path.readlink()) for path in paths
                                  if path.is_symlink()})
                if not outputs:
                    raise ValueError('Gerbil stage has no actual output inventory: ' + stage)
                modes = {name:(source/name).stat().st_mode & 0o777 for name in outputs}
                if modules is not None:
                    proofs[stage] = dict(kind='completed-stage0-modules.v1',modules=modules,
                        outputs=outputs,links=links,modes=modes,inputsSha256=inputs)
                else:
                    raw = (ctx.directory / ('gerbil-' + stage + '.process.json')).read_text()
                    proofs[stage] = dict(outputs=outputs, links=links, modes=modes,command=ctx.commands[-1], receiptBytes=raw,
                                        receiptSha256=hashlib.sha256(raw.encode()).hexdigest(), inputsSha256=inputs)
                write(proofs_path, proofs)
            checkpoint_build_source(source)
    executable = source / 'build/bin/gerbil'
    if not executable.is_file():
        raise ValueError('Gerbil build did not produce its executable')
    checkpoint_build_source(source, phase='ready', throughStage=through_stage)
    check_runtime(runtime, read_json(identity))
    observation = dict(workspace=str(source), throughStage=through_stage,
        constructionOwner='experimental-staged', ciBaselineEquivalent=False,
        compilerCoreReady=True, standardLibraryReady=through_stage in {'stdlib','tools'},
        toolsReady=through_stage=='tools',
        sourceDelta=delta, sourceArchiveSkipped=archive_skipped, bootstrapReused=reuse,
        compilerResourcePlan=dict(workers=jobs,stage0CompilerProcessors=1,compilerVmProcessors=1,
            stdlibNativeWorkers=(stdlib_native_jobs or jobs) if stdlib_native_products else None,
            stageBudgetSeconds=stage_budget_seconds,
            compilerRuntimeOptions=ctx.env['GAMBOPT'],schedulingEnvelope=2*jobs+1,
            hostCpuCapacity=available_processors(),enforcedOsThreadQuota=False),
        stage0Schedule=module_schedule, librarySchedule=library_schedule,
        runtimePayloads=payloads, executableSha256=digest(executable), runtimeAdmitted=False,
        configurationSha256=digest(work / 'configuration.json'),
        workspaceIdentitySha256=hashlib.sha256(json.dumps(tree_identity(source),sort_keys=True).encode()).hexdigest())
    output = ctx.directory / 'gerbil-build.json'
    output.write_text(json.dumps(observation, indent=2) + '\n')
    return {'outputs': ctx.publish('observations', 'gerbil-build-observations', output),
            'observation': observation,
            'claim': 'scoped-Gerbil-compiler-build-not-runtime-or-package-acceptance'}
