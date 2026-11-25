"""Gerbil build: bazel build."""
from gambit_smp.gerbil_build.sources import source_files

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil
import time

from gambit_smp.gerbil_build.batches import _withdraw_stage1_outputs, _withdraw_stdlib_batch
from gambit_smp.gerbil_build.bootstrap_inputs import _configure_host_bootstrap, _index_gambit_snapshot
from gambit_smp.gerbil_build.custody import _current, _stage_completion, _prepared_ci_products
from gambit_smp.gerbil_build.policy import STAGES, _admit_runtime_profile, _bootstrap_release, _configured_smp, _runtime_profile, _through_stage
from gambit_smp.gerbil_build.stage0 import _install_runtime
from gambit_smp.gerbil_build.source_tests import check_compilation_resources

def build_bazel_compiler(ctx, gambit_source, gerbil_checkout, bazel_root, *,
                         multiple_threaded_vms, budgets, prior=None, through_stage='tools',
                         rebuild_bootstrap=False, source_only=False, bootstrap_release=None, source_policy='published-support', runtime_profile=None,
                         phase_products=False, prepared=None):
    """Use the repository's source producer, with a bound local Gambit tree.

    No installed frontend or foreign native library is overlaid. The producer
    owns Gerbil patch selection, all upstream stages, installation and checks.
    A failed construction never returns a package-ready compiler home.
    """
    import re
    from gambit_smp.native_capabilities import fields, compiler
    from gambit_smp.recipes import tree_identity
    from gambit_smp.source_capabilities import source_name
    from gambit_smp.workspace import build_output, write
    bootstrap_release = _bootstrap_release(bootstrap_release)
    if type(phase_products) is not bool:raise ValueError('phaseProducts must be boolean')
    if phase_products and prior is not None:
        raise ValueError('legacy continuation cannot consume stage-product construction')
    if source_policy not in ('direct','published-support') or (source_policy == 'direct' and bootstrap_release):
        raise ValueError('direct source construction forbids bootstrap rewrites')
    fields(budgets, ('prepare', 'build', 'verify'))
    _through_stage(through_stage)
    if type(rebuild_bootstrap) is not bool or (rebuild_bootstrap and prior is None):
        raise ValueError('bootstrap replacement requires an explicit owned prior producer')
    if prior is None and through_stage != 'tools' and not (phase_products and through_stage=='stage1'):
        raise ValueError('phase-scoped continuation requires its bound prior producer observation')
    if any(type(value) is not int or value <= 0 for value in budgets.values()):
        raise ValueError('positive fixed source-producer budgets required')
    expected_runtime = _runtime_profile(runtime_profile)
    if multiple_threaded_vms is not expected_runtime['multipleThreadedVms']:
        raise ValueError('requested threaded VM mode differs from the explicit runtime profile')
    gambit_source, gerbil_checkout, bazel_root = map(
        lambda path: Path(path).resolve(strict=True),
        (gambit_source, gerbil_checkout, bazel_root))
    script = bazel_root/'tools/ci/build_source_toolchain.sh'
    configured_header = gambit_source/'include/gambit.h'
    profile_macro = 'MULTIPLE' if multiple_threaded_vms else 'SINGLE'
    if not source_only and not re.search(r'^#define ___'+profile_macro+r'_THREADED_VMS\s*$',
                     configured_header.read_text(), re.MULTILINE):
        raise ValueError('requested VM profile differs from the Darwin source configuration')
    configured_features = gambit_source/'lib/Makefile'
    vm_macro = 'MULTIPLE_VMS' if expected_runtime['multipleVms'] else 'SINGLE_VM'
    if not source_only and (not re.search(r'^#define ___'+vm_macro+r'\s*$', configured_header.read_text(), re.MULTILINE)
            or _configured_smp(configured_features.read_text()) is not expected_runtime['smp']):
        raise ValueError('configured VM/SMP capabilities differ from the explicit runtime profile')
    ctx.bind([*source_files(), *([] if source_only else [configured_header, configured_features])])
    from gambit_smp.work_items import admit_source_delta, require_boundary_context
    policy = require_boundary_context(ctx)
    if policy and policy.get('sourcePolicy',source_policy) != source_policy:
        raise ValueError('source policy differs from the SysML execution boundary')
    _admit_runtime_profile(policy,expected_runtime)
    admit_source_delta(ctx, gambit_source)
    resource_admission = check_compilation_resources(ctx, gambit_source) if phase_products else None
    compiler(ctx)
    ctx.bind([Path(ctx.tools['gcc'])])
    configuration_inputs = dict(ctx.extra_inputs)
    configuration = dict(**expected_runtime,
        phaseProducts=phase_products,
        runtimeSource=str(gambit_source),
        sourceOnly=source_only,
        sourcePolicy=source_policy,
        bootstrapRelease=bootstrap_release,
        headerSha256=None if source_only else digest(configured_header),
        featuresSha256=None if source_only else digest(configured_features),
        boundInputsSha256=hashlib.sha256(json.dumps(ctx.extra_inputs,sort_keys=True).encode()).hexdigest(),
        environment={key:ctx.env.get(key) for key in (
            'CFLAGS', 'CPPFLAGS', 'LDFLAGS', 'SDKROOT', 'MACOSX_DEPLOYMENT_TARGET',
            'CPATH', 'LIBRARY_PATH', 'PKG_CONFIG_PATH', 'PKG_CONFIG_LIBDIR',
            'PKG_CONFIG_SYSROOT_DIR', 'GERBIL_BUILD_CORES')})
    producer_inputs = [script, bazel_root/'tools/release/activate-gerbil.sh',
                       bazel_root/'tools/ci/multiple_vm_globals.ss',
                       *(sorted((bazel_root/'patches').rglob('*.patch')) if source_policy == 'published-support' else [])]
    ctx.bind(producer_inputs)
    producer_hash = hashlib.sha256(json.dumps(
        {str(path.relative_to(bazel_root)): digest(path) for path in producer_inputs},
        sort_keys=True).encode()).hexdigest()
    heads = {}
    for kind, checkout in (('gambit', gambit_source), ('gerbil', gerbil_checkout)):
        heads[kind] = ctx.require('bazel-'+kind+'-head',
            [ctx.tools['git'], '-C', checkout, 'rev-parse', 'HEAD'], ctx.root, 5).strip()
        if not re.fullmatch('[0-9a-f]{40}', heads[kind]):
            raise ValueError('exact source revision required')
    names = sorted(set(filter(None, ctx.require('bazel-gambit-inventory',
        [ctx.tools['git'], '-C', gambit_source, 'ls-files', '--cached', '--others',
         '--exclude-standard', '-z'], ctx.root, 10).split('\0'))))
    staged = ctx.directory/'gambit-inputs'; staged.mkdir()
    inventory = {}
    for name in names:
        source_name(name)
        origin = gambit_source/name
        if not origin.exists():
            continue  # tracked deletions remain absent in the snapshot
        if not origin.is_file() or origin.is_symlink():
            raise ValueError('local Gambit input needs explicit file custody: '+name)
        target = staged/name; target.parent.mkdir(parents=True, exist_ok=True)
        inventory[name] = dict(sha256=digest(origin), mode=origin.stat().st_mode & 0o777)
        shutil.copy2(origin, target)
    if not {'configure', 'gsc/_t-c-1.scm', 'include/gambit.h.in', 'lib/setup.c'} <= inventory.keys():
        raise ValueError('complete Gambit working source required')
    if any(digest(gambit_source/name) != row['sha256'] or
           digest(staged/name) != row['sha256'] for name, row in inventory.items()):
        raise ValueError('local Gambit changed during source snapshot')
    ctx.bind([gambit_source/name for name in inventory])
    source_hash = hashlib.sha256(json.dumps(inventory, sort_keys=True).encode()).hexdigest()
    if prior is not None:
        return _continue_bazel_compiler(ctx, Path(prior), script, heads, inventory,
            source_hash, configuration, budgets, through_stage, producer_hash=producer_hash,
            rebuild_bootstrap=rebuild_bootstrap)
    retained = None
    if prepared is not None:
        if not phase_products or prior is not None:
            raise ValueError('prepared CI phases require the phase-product producer')
        retained = _prepared_ci_products(ctx,prepared,heads,configuration,source_hash,producer_hash,script,
            bound_inputs=configuration_inputs,gerbil_checkout=gerbil_checkout)
        source = Path(retained['source']); work = source.parent
        if retained.get('sourceUpdated'):_withdraw_stdlib_batch(ctx,source,{})
    else:
        work = build_output(ctx.root, 'gerbil', compiler=ctx.tools['gcc'],
            flags=['bazel-source-producer', heads['gerbil'], heads['gambit'], source_hash,
                   producer_hash, json.dumps(configuration, sort_keys=True)])
        source = work/'source'; source.mkdir(exist_ok=True)
        ctx.lease_workspace(source, tree_identity(source))
    # Construction is deliberately not resumed from unqualified native files.
    # Successful reuse requires the producer's verify plus the recorded inputs.
    if retained is None and any(source.iterdir()):
        raise ValueError('source producer requires an empty owned checkout')
    result = dict(source=str(source), compilerHome=None, constructionPassed=False,
                  constructionOwner='bazel-ci-source-producer',
                  packageReady=False, mergeAllowed=False, heads=heads,
                  gambitInputSha256=source_hash, producerInputSha256=producer_hash,
                  configuration=configuration, budgets=budgets, stages={})
    result['compilationResources'] = resource_admission
    if retained and retained.get('retainedCoreHeads'):
        result.update(retainedCoreHeads=retained['retainedCoreHeads'],sourceOverlayCount=0)
    write(work/'bazel-source-inputs.json', dict(heads=heads, files=inventory,
          gambitSource=str(gambit_source), gerbilRepository=str(gerbil_checkout)))
    saved = dict(ctx.env)
    try:
        ctx.env.update(GERBIL_SOURCE_REVISION=heads['gerbil'],
            GAMBIT_SOURCE_REVISION=heads['gambit'],
            GERBIL_SOURCE_REPOSITORY=str(gerbil_checkout),
            GERBIL_SOURCE_DIRECTORY=str(source), GERBIL_PREFIX=str(work/'prefix'),
            GAMBIT_SOURCE_DIRECTORY=str(gambit_source),
            GAMBIT_SOURCE_INPUT_HASH=source_hash, CC=str(ctx.tools['gcc']))
        ctx.env['GAMBIT_LOCAL_THREADED_VMS'] = profile_macro.lower()
        ctx.env['GAMBIT_MULTIPLE_VMS'] = str(expected_runtime['multipleVms']).lower()
        ctx.env['GAMBIT_SMP'] = str(expected_runtime['smp']).lower()
        ctx.env['GERBIL_SOURCE_POLICY'] = source_policy

        for mode in ('prepare', 'build', 'verify'):
            if retained is not None and mode == 'prepare':
                continue
            if mode == 'build' and retained is None:
                if source_policy == 'direct':
                    changed = ctx.require('direct-gerbil-source-check', [ctx.tools['git'],'-C',source,
                        'diff','--name-only','HEAD','--',':(exclude)src/gambit'],ctx.root,10).strip()
                    if changed:
                        raise ValueError('direct Gerbil source was rewritten before build: '+changed)
                    result['sourceOverlayCount'] = 0
                if bootstrap_release:
                    result['hostBootstrapProducer'] = _configure_host_bootstrap(source)
                nested = source/'src/gambit'
                nested.mkdir(parents=True, exist_ok=True)
                if any(nested.iterdir()):
                    raise ValueError('producer unexpectedly populated the Gambit gitlink')
                shutil.copytree(staged, nested, dirs_exist_ok=True)
                ctx.require('bazel-gambit-init', [ctx.tools['git'], 'init',
                    '--initial-branch=darwin', nested], ctx.root, 5)
                ctx.require('bazel-gambit-fetch', [ctx.tools['git'], '-C', nested,
                    'fetch', '--no-tags', '--depth=1', str(gambit_source), heads['gambit']], ctx.root, 15)
                if bootstrap_release:
                    ref = 'refs/tags/'+bootstrap_release['tag']
                    ctx.require('bazel-bootstrap-release-fetch',[ctx.tools['git'],'-C',nested,
                        'fetch','--depth=1',str(gambit_source),ref],ctx.root,30)
                    actual = ctx.require('bazel-bootstrap-release-head',[ctx.tools['git'],'-C',nested,
                        'rev-parse','FETCH_HEAD^{commit}'],ctx.root,10).strip()
                    if actual != bootstrap_release['revision']:
                        raise ValueError('nested bootstrap seed identity differs')
                    ctx.require('bazel-bootstrap-release-pin',[ctx.tools['git'],'-C',nested,
                        'update-ref',ref,actual],ctx.root,10)
                result['targetHeadBeforeBuild'] = _index_gambit_snapshot(ctx,nested,heads['gambit'])
                if any(digest(nested/name) != row['sha256'] for name, row in inventory.items()):
                    raise ValueError('nested Gambit differs from the working source snapshot')
                # The snapshot is a disposable transfer, not another retained
                # source tree hidden under the attempt directory. The bound
                # authoritative inputs and owned destination keep the bytes.
                shutil.rmtree(staged)
                result['inputStagingConsumed']=True
                ctx.require('bazel-source-manifest',
                    ['/bin/sh', source/'manifest.sh', heads['gerbil'][:7]], source, 10)
                manifest_path = source/'MANIFEST'
                manifest = manifest_path.read_text()
                # Upstream emits HHMMSS verbatim into a C integer constant.
                # Preserve its numeric decimal meaning, including 00:00:00,
                # rather than letting a leading zero select C's octal base.
                matches = re.findall(r'^gambit_stamp_hms=([0-9]{6})$', manifest, re.MULTILINE)
                if len(matches) != 1:
                    raise ValueError('one generated six-digit UTC source timestamp required')
                manifest_path.write_text(re.sub(r'^gambit_stamp_hms=[0-9]{6}$',
                    'gambit_stamp_hms='+str(int(matches[0], 10)), manifest, flags=re.MULTILINE))
                result['manifest'] = dict(rawSha256=hashlib.sha256(manifest.encode()).hexdigest(),
                    sha256=digest(manifest_path), decimalUtcTime=int(matches[0], 10))
            if mode=='build' and phase_products:
                command=_ci_stage_products(ctx,source,script,budgets[mode],result,work,through_stage=through_stage,prepared=retained)
                code,timeout=command['exit'],command['timeout']
            else:
                code, _, timeout, _ = ctx.run('bazel-source-'+mode,
                    ['/bin/bash', script, mode], ctx.root, budgets[mode])
                command = ctx.commands[-1]
            result['stages'][mode] = command
            if mode == 'build':
                result['targetHeadAfterBuild'] = ctx.require('bazel-target-final-head',
                    [ctx.tools['git'],'-C',source/'src/gambit','rev-parse','HEAD'],ctx.root,5).strip()
                if result['targetHeadAfterBuild'] != heads['gambit']:
                    result.update(blockedAt='target-identity',constructionPassed=False,packageReady=False)
                    return result
            if (code != 0 or timeout or command.get('parentReaped') is not True
                    or command.get('processGroupQuiescent') is not True):
                result['blockedAt'] = mode
                return result
            if mode=='build' and phase_products and through_stage=='stage1':
                required=['bin/gerbil','bin/gxi','bin/gxc','bin/gsc',
                          'lib/gerbil/compiler.ssi','lib/gerbil/compiler/driver.ssi']
                if not all((source/'build'/name).is_file() for name in required):
                    result.update(blockedAt='compiler-core-readiness')
                    return result
                result.update(throughStage='stage1',compilerCoreReady=True,
                    phaseConstructionPassed=True,compilerHome=str(source/'build'))
                return result
        prefix = work/'prefix'
        required = ['bin/gerbil', 'bin/gxi', 'bin/gxc', 'bin/gsc', 'bin/gxpkg',
                    'bin/gxtest', 'include/gambit.h']
        for tool in ('gxpkg', 'gxtest'):
            required.extend('lib/gerbil/tools/'+tool+suffix for suffix in ('.ssi', '~0.o1'))
        missing = [name for name in required if not (prefix/name).is_file()]
        if missing:
            result.update(blockedAt='compiled-tool-readiness', missing=missing)
            return result
        home=(prefix/'current').resolve(strict=True)
        if not home.is_relative_to(prefix):
            raise ValueError('installed compiler home escapes its producer prefix')
        result.update(compilerHome=str(home), constructionPassed=True, packageReady=True)
        return result
    finally:
        header, features = source/'src/gambit/include/gambit.h', source/'src/gambit/lib/Makefile'
        if header.is_file() and features.is_file():
            text = header.read_text()
            result['generatedProfile'] = dict(
                multipleThreadedVms=bool(re.search(r'^#define ___MULTIPLE_THREADED_VMS\s*$', text, re.MULTILINE)),
                multipleVms=bool(re.search(r'^#define ___MULTIPLE_VMS\s*$', text, re.MULTILINE)),
                smp=_configured_smp(features.read_text()),
                headerSha256=digest(header), featuresSha256=digest(features))
            result['generatedProfile']['matchesRequestedProfile'] = (
                all(result['generatedProfile'][key] is expected_runtime[key] for key in expected_runtime)
                and bool(re.search(r'^#define ___'+profile_macro+r'_THREADED_VMS\s*$',text,re.MULTILINE))
                and bool(re.search(r'^#define ___'+vm_macro+r'\s*$',text,re.MULTILINE)))
            if not result['generatedProfile']['matchesRequestedProfile']:
                result.update(constructionPassed=False, packageReady=False, compilerHome=None)
        ctx.env.clear(); ctx.env.update(saved)
        write(ctx.directory/'bazel-compiler-result.json', result)


def _ci_stage_products(ctx,source,script,seconds,result,work,*,through_stage='tools',prepared=None):
    """The same source producer, with a single deadline and terminal phase receipts.

    No interrupted native files are adopted and no stage gets a fresh whole
    build budget. Completed products are retained, not automatically qualified
    for reuse, module loading, or package acceptance by this ledger alone.
    """
    from gambit_smp.workspace import write
    remaining_seconds = seconds - (prepared.get('priorSpentSeconds',0) if prepared else 0)
    if remaining_seconds <= 0:
        raise TimeoutError('whole CI construction allowance already spent')
    deadline=time.monotonic()+min(remaining_seconds,ctx.remaining())
    key=hashlib.sha256(json.dumps(dict(heads=result['heads'],configuration=result['configuration'],
        gambit=result['gambitInputSha256'],producer=result['producerInputSha256']),sort_keys=True).encode()).hexdigest()
    progress=dict(schema='gerbil-ci-stage-products',source=str(source),inputsSha256=key,
        heads=result['heads'],configuration=result['configuration'],wholeBuildSeconds=seconds,
        completed={},products={},compilerReady=False,packageReady=False,automaticReuseAdmitted=False)
    path=Path(work)/'ci-stage-products.json'
    if path.exists() and prepared is None:raise ValueError('unreconciled stage-product construction; no blind retry')
    if prepared is not None:
        progress.update(completed=dict(prepared['completed']),products=dict(prepared['products']),
            retainedPhases=prepared['retainedPhases'],priorSpentSeconds=prepared['priorSpentSeconds'],
            preparedFrom=prepared['preparedFrom'],sourceProfilePrepared=prepared['sourceProfilePrepared'],
            retainedCoreHeads=prepared.get('retainedCoreHeads'))
        progress['retainedPhaseHeads']=prepared.get('retainedPhaseHeads',{})
    snapshot=ctx.directory/'ci-stage-products.json'
    def retain():
        # The work copy serves live observation. Only the step artifact copy
        # is sealed by the terminal receipt; a mutable work path is not reuse
        # authority. Both copies come from this single in-memory ledger.
        write(path,progress)
        write(snapshot,progress)
    retain()
    started=time.monotonic()
    if through_stage not in ('stage1','tools'):
        raise ValueError('CI phase products support stage1 or the complete tools pipeline')
    stages=STAGES[:STAGES.index('stage1')+1] if through_stage=='stage1' else STAGES
    phases=[('configure',['configure']),('prepare',['stage','prepare']),
            *((stage,['stage',stage]) for stage in ('gambit',*stages))]
    if through_stage=='tools':phases.append(('install',['install']))
    for phase,argv in phases:
        if phase in progress.get('retainedPhases',[]):
            continue
        progress.update(active=phase,completionKnown=False)
        retain()
        remaining=min(ctx.remaining(),deadline-time.monotonic())
        if remaining<=0:raise TimeoutError('whole CI construction deadline exhausted')
        if phase == 'stage0':
            from gambit_smp.gerbil_build.stage0 import _stage0_modules
            modules,schedule=_stage0_modules(ctx,work,source,key,
                stage_budget_seconds=remaining,retire_frontend=True)
            outputs = {name:sha for proof in modules.values() for name,sha in proof['outputs'].items()}
            modes = {name:mode for proof in modules.values() for name,mode in proof['modes'].items()}
            progress['products'][phase] = dict(kind='completed-stage0-modules.v1',inputsSha256=key,
                modules=modules,outputs=outputs,modes=modes,links={})
            progress['completed'][phase] = dict(kind='joined-module-products',schedule=schedule,
                parentReaped=True,processGroupQuiescent=True)
            progress.update(completionKnown=True)
            retain()
            continue
        retirement=None
        if phase == 'stage1':
            from gambit_smp.gerbil_build.batches import stage1_products
            retirement=stage1_products(ctx,source,deadline)
            code,timeout=0,False
        elif phase == 'stdlib':
            from gambit_smp.gerbil_build.batches import stdlib_products
            prior_stdlib=(prepared or {}).get('stdlibRecoveryFrom')
            retirement=stdlib_products(ctx,source,deadline,prior=prior_stdlib) if prior_stdlib else stdlib_products(ctx,source,deadline)
            code,timeout=0,False
        else:
            code,_,timeout,_=ctx.run('gerbil-'+phase,['/bin/bash',script,*argv],ctx.root,remaining)
        command=ctx.commands[-1]
        if (code!=0 or timeout or command.get('parentReaped') is not True
                or command.get('processGroupQuiescent') is not True):
            progress.update(failed=phase,failedCommand=command,completionKnown=True)
            retain()
            return dict(kind='stage-products',exit=code if code else 125,timeout=timeout,
                parentReaped=command.get('parentReaped'),processGroupQuiescent=command.get('processGroupQuiescent'),
                failedPhase=phase,progress=str(path),progressArtifact=str(snapshot),
                progressSha256=digest(snapshot),seconds=time.monotonic()-started)
        progress['completed'][phase]=command
        if phase in ('gambit',*STAGES,'install'):
            prefixes=['bootstrap','build']+(['src/gerbil/boot-gxi'] if phase=='boot-gxi' else [])
            progress['products'][phase]=_stage_completion(ctx,source,phase,key,prefixes)
            if retirement is not None:
                progress['products'][phase]['predecessors']=retirement['dependencies']
                progress[phase+'Retirement']=retirement
        progress.update(completionKnown=True)
        retain()
    progress.update(active=None,allStagesCompleted=through_stage=='tools',
                    requestedStagesCompleted=True,throughStage=through_stage)
    retain()
    return dict(kind='stage-products',exit=0,timeout=False,parentReaped=True,
                processGroupQuiescent=True,progress=str(path),progressArtifact=str(snapshot),
                progressSha256=digest(snapshot),seconds=time.monotonic()-started)


def _continue_bazel_compiler(ctx, prior, script, heads, inventory, source_hash,
                             configuration, budgets, through_stage, *, producer_hash=None,
                             rebuild_bootstrap=False):
    """Continue the same owned source via the producer's real stage interface.

    The old whole-command timeout stays failed. Bootstrap qualification is
    obtained from its actual stage1 consumer; an unproved core is withdrawn
    before it can shadow bootstrap. No extra import-only process is required.
    The existing stage proof checker owns reuse; labels are never receipts.
    """
    from gambit_smp.recipes import read_json, tree_identity
    from gambit_smp.workspace import write
    prior = prior.resolve(strict=True); ctx.bind([prior])
    previous = read_json(prior)
    if previous.get('heads') != heads or (previous.get('gambitInputSha256') != source_hash
                                         and not rebuild_bootstrap):
        raise ValueError('continuation source cohort differs from the original producer')
    failed = previous.get('stages', {}).get('build', {})
    if (type(failed.get('exit')) is not int or failed.get('timeout') is not True or failed.get('parentReaped') is not True
            or failed.get('processGroupQuiescent') is not True):
        raise ValueError('continuation requires a retained reaped, quiescent timeout')
    source = Path(previous['source']).resolve(strict=True)
    ctx.lease_workspace(source, tree_identity(source))
    work, runtime = source.parent, source/'src/gambit'
    if rebuild_bootstrap and runtime.resolve() != Path(configuration['runtimeSource']).resolve():
        raise ValueError('bootstrap replacement must use the owned nested runtime')
    for kind, path in (('gerbil',source), ('gambit',runtime)):
        actual = ctx.require('continue-'+kind+'-head',
            [ctx.tools['git'],'-C',path,'rev-parse','HEAD'],ctx.root,5).strip()
        if actual != heads[kind]:raise ValueError('continuation checkout identity changed')
    # From-scratch legitimately regenerates C. Semantic inputs and modular
    # native sources must still match; bind each regenerated product as well.
    regenerated = []
    for name, row in inventory.items():
        path = runtime/name
        if not path.is_file():raise ValueError('continuation source input missing: '+name)
        if digest(path) != row['sha256']:
            if not (len(Path(name).parts)==2 and Path(name).parts[0] in {'lib','gsi','gsc'}
                    and Path(name).name.startswith('_') and name.endswith('.c')):
                raise ValueError('continuation source input drift: '+name)
            regenerated.append(name)
    ctx.bind([runtime/name for name in inventory])
    stage_environment = dict(GERBIL_SOURCE_REVISION=heads['gerbil'],
        GAMBIT_SOURCE_REVISION=heads['gambit'], GAMBIT_SOURCE_DIRECTORY=str(runtime),
        GAMBIT_SOURCE_INPUT_HASH=source_hash, GAMBIT_LOCAL_THREADED_VMS='multiple',
        GERBIL_SOURCE_DIRECTORY=str(source), GERBIL_PREFIX=str(work/'prefix'),
        CC=str(ctx.tools['gcc']), GERBIL_SOURCE=str(source/'src'),
        GERBIL_STAGE0=str(source/'bootstrap'), GERBIL_HOME=str(source/'bootstrap'),
        GERBIL_BUILD_PREFIX=str(source/'build'), GERBIL_LOADPATH=str(source/'build/lib'),
        PATH=str(source/'build/bin')+':'+str(source/'bootstrap/bin')+':'+ctx.env.get('PATH',''),
        GAMBOPT='~~bin='+str(source/'build/bin')+',~~lib='+str(source/'build/lib')+',~~include='+str(source/'build/include'))
    if rebuild_bootstrap:
        ctx.require('gambit-refresh-core',['make','-j12','core'],runtime,budgets['build'])
    payloads = _install_runtime(runtime,source)
    core = {str(path.relative_to(source)):digest(path)
            for path in (source/'src').rglob('*') if path.is_file()
            and not path.is_relative_to(runtime) and path.suffix in {'.ss','.scm','.sh','.c'}
            and str(path.relative_to(source)) not in {'src/gerbil/runtime/version.ss','src/gerbil/boot-gxi.c'}}
    core.update({name:digest(source/name) for name in (
        'build.sh','install.sh','configure','build-env.sh','MANIFEST',
        'src/gambit/include/gambit.h','src/gambit/include/config.h')})
    ctx.bind([source/name for name in core])
    proofs_path = work/'gerbil-stages.json'
    proofs = read_json(proofs_path) if proofs_path.is_file() else {}
    replacement_key = hashlib.sha256(json.dumps(dict(source=source_hash,
        payloads=payloads, core=core, producer=producer_hash),sort_keys=True).encode()).hexdigest()
    if rebuild_bootstrap and not _current(source,proofs.get('bazel-stage0'),
                                          replacement_key,stage='bazel-stage0',root=ctx.root):
        # A native layout change invalidates every bootstrap object. Retain the
        # old bytes outside lookup before loading the new runtime, never overlay
        # new headers on old .o1 files. Reuse the producer's actual stage0 loop.
        saved = dict(ctx.env)
        try:
            ctx.env.update(stage_environment)
            _withdraw_stage1_outputs(ctx,source)
            retired = []
            for path in sorted((source/'bootstrap/lib').rglob('*.o1')):
                name = path.relative_to(source)
                target = ctx.directory/'retired-bootstrap'/name
                target.parent.mkdir(parents=True,exist_ok=True)
                path.rename(target); retired.append(str(name))
            write(ctx.directory/'bootstrap-retirement.json',dict(
                oldSourceSha256=previous.get('gambitInputSha256'),
                newSourceSha256=source_hash, retired=retired, historicalTimeoutPreserved=True))
            ctx.require('gerbil-boot-gxi',['/bin/bash',script,'stage','boot-gxi'],
                        ctx.root,budgets['prepare'])
            ctx.require('gerbil-bazel-stage0',['/bin/bash',script,'stage','stage0'],
                        ctx.root,budgets['build'])
            proofs['bazel-stage0'] = _stage_completion(ctx,source,'bazel-stage0',
                                                      replacement_key,['bootstrap'])
            write(proofs_path,proofs)
        finally:
            ctx.env.clear();ctx.env.update(saved)
    bootstrap = {}
    originals = source/'src/bootstrap/gerbil'
    for path in originals.rglob('*.scm'):
        target = source/'bootstrap/lib/gerbil'/path.relative_to(originals)
        obj = target.with_suffix('.o1')
        if (not target.is_file() or digest(target)!=digest(path) or not obj.is_file()
                or obj.is_symlink() or obj.stat().st_size==0):
            raise ValueError('bootstrap source/native closure incomplete: '+str(path))
    bootstrap = {str(path.relative_to(source)):digest(path)
                 for path in (source/'bootstrap').rglob('*') if path.is_file()}
    if not bootstrap:raise ValueError('bootstrap closure is empty')
    ctx.bind([source/name for name in bootstrap])
    key = hashlib.sha256(json.dumps(dict(heads=heads,source=source_hash,
        configuration=configuration,payloads=payloads,core=core,bootstrap=bootstrap,
        producer=producer_hash or digest(script),
        tools={name:dict(path=str(path),sha256=digest(Path(path)))
               for name,path in ctx.tools.items() if path and Path(path).is_file()},
        externalBindings={name:sha for name,sha in ctx.extra_inputs.items()
                          if not Path(name).is_relative_to(ctx.root)}),sort_keys=True).encode()).hexdigest()
    result = dict(source=str(source), compilerHome=None, packageReady=False,
        constructionPassed=False, wholeCommandTimeoutPreserved=True,
        prior=str(prior), priorSha256=digest(prior), throughStage=through_stage,
        bootstrapObjects=len(list(originals.rglob('*.scm'))), regeneratedInputs=regenerated,
        completed=[], reused=[], mergeAllowed=False, packageSpeedup=None)
    result['bootstrapRebuiltForSourceChange'] = rebuild_bootstrap
    consumer = (source/'src/build/build1.ss').read_text()
    import_form = '(import :gerbil/compiler)'
    marker_form = '(displayln "building gerbil in " gerbil-libdir)'
    if (consumer.count(import_form) != 1 or consumer.count(marker_form) != 1
            or consumer.index(import_form) >= consumer.index(marker_form)):
        raise ValueError('stage1 bootstrap-consumer contract drift')
    consumer_marker = 'building gerbil in '+str(source/'build/lib')
    result['bootstrapQualification'] = 'actual stage1 import and completed native consumer'
    saved = dict(ctx.env)
    try:
        ctx.env.update(stage_environment)
        if (not _current(source,proofs.get('stage1'),key,stage='stage1',root=ctx.root)
                or proofs['stage1'].get('bootstrapConsumerMarker') != consumer_marker):
            _withdraw_stage1_outputs(ctx,source)
        for stage in STAGES[STAGES.index('stage1'):STAGES.index(through_stage)+1]:
            if stage=='stdlib':
                # The legacy producer includes address-stable global growth.
                # A local modern-C tree must satisfy that same prerequisite
                # before more library/tool construction can qualify it.
                control=script.parents[2]/'tools/ci/multiple_vm_globals.ss'
                ctx.bind([control])
                ctx.env['GERBIL_HOME']=str(source/'build')
                code,text,timeout,_=ctx.run('gerbil-global-capacity',
                    [source/'build/bin/gxi',control],source,min(budgets['verify'],ctx.remaining()))
                row=ctx.commands[-1]
                result['globalCapacityPassed']=(code==0 and not timeout
                    and row.get('parentReaped') is True and row.get('processGroupQuiescent') is True
                    and 'MULTIPLE-VM-GLOBALS-OK' in text.splitlines()
                    and 'MULTIPLE-VM-THREADS-OK' in text.splitlines())
                if not result['globalCapacityPassed']:
                    result.update(blockedAt='global-capacity',command=row,compilerCoreReady=True)
                    return result
            if (_current(source,proofs.get(stage),key,stage=stage,root=ctx.root)
                    and (stage != 'stage1' or
                         proofs[stage].get('bootstrapConsumerMarker') == consumer_marker)):
                result['reused'].append(stage);continue
            if stage=='stdlib':_withdraw_stdlib_batch(ctx,source,{})
            code,_,timeout,_=ctx.run('gerbil-'+stage,
                ['/bin/bash',script,'stage',stage],ctx.root,min(budgets['build'],ctx.remaining()))
            row=ctx.commands[-1]
            if (code!=0 or timeout or row.get('parentReaped') is not True
                    or row.get('processGroupQuiescent') is not True):
                result.update(blockedAt=stage,command=row);return result
            proofs[stage]=_stage_completion(ctx,source,stage,key,['build'],
                required_marker=consumer_marker if stage=='stage1' else None)
            if stage=='stage1':proofs[stage]['bootstrapConsumerMarker']=consumer_marker
            write(proofs_path,proofs);result['completed'].append(stage)
        result['compilerCoreReady']=True
        if through_stage!='tools':return result
        ctx.require('bazel-source-install',['/bin/bash',script,'install'],ctx.root,budgets['verify'])
        home=(work/'prefix/current').resolve(strict=True)
        for name in ['bin/gerbil','bin/gxi','bin/gxc','bin/gsc','bin/gxpkg','bin/gxtest',
                     'lib/gerbil/tools/gxpkg.ssi','lib/gerbil/tools/gxtest.ssi']:
            if not (home/name).is_file():raise ValueError('installed compiler closure missing '+name)
        result.update(compilerHome=str(home),constructionPassed=True,packageReady=True)
        return result
    finally:
        drift=[name for name,sha in ctx.extra_inputs.items()
               if not Path(name).is_file() or digest(Path(name))!=sha]
        result['boundInputDrift']=drift
        if drift:
            result.update(compilerCoreReady=False,constructionPassed=False,
                          packageReady=False,compilerHome=None)
        ctx.env.clear();ctx.env.update(saved)
        write(ctx.directory/'bazel-continuation-result.json',result)
