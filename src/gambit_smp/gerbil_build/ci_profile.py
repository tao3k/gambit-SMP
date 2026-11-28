"""Gerbil build: ci profile."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil

from gambit_smp.gerbil_build.bazel_build import build_bazel_compiler
from gambit_smp.gerbil_build.bootstrap_observation import observe_bazel_bootstrap
from gambit_smp.gerbil_build.policy import CI_ENVIRONMENT_KEYS, _admit_runtime_profile, _bootstrap_release, _runtime_profile

def construction_capacity(environment, inherited):
    """Resolve the official environment variable without changing VM options."""
    capacity = available_processors()
    requested = inherited.get('GERBIL_BUILD_CORES')
    origin = 'caller-environment'
    if requested is None:
        requested = environment.get('GERBIL_BUILD_CORES')
        origin = 'profile-environment'
    if requested is None:
        requested = str(capacity)
        origin = 'available-processors'
    if not isinstance(requested, str) or not requested.isascii() or not requested.isdecimal() or int(requested) < 1:
        raise ValueError('GERBIL_BUILD_CORES must be a positive integer')
    return dict(variable='GERBIL_BUILD_CORES', value=requested, origin=origin,
                hostCpuCapacity=capacity, memorySafetyProved=False)

def build_ci_profile(args, ctx):
    """The existing gerbil.build capability owns CI construction, not inline drivers.

    Published support is materialized as an exact baseline commit. It receives
    no acceleration credit. Experimental runtime/source trees are never inputs.
    """
    from gambit_smp.recipes import source_path, tree_identity, read_json
    from gambit_smp.workspace import build_output, write
    from gambit_smp.native_capabilities import fields
    profile_path = source_path(ctx.root, args['sourceLock'])
    profile = read_json(profile_path)
    fields(profile, ('schema','gerbil','gambit','bazelRoot','environment','constructionBudgets',
                     'packageSources','packageBudgets'), ('bootstrapRelease','sourcePolicy','runtimeProfile','phaseProducts','prepared'))
    if profile['schema'] != 'gerbil-ci-source-profile':
        raise ValueError('typed source-only CI profile required')
    if profile['constructionBudgets'] != dict(prepare=180,build=21600,verify=120):
        raise ValueError('CI construction deadlines must retain the approved profile')
    if profile['packageBudgets'] != dict(clean=30,build=300,test=300) or set(profile['packageSources']) != {'mcp','poo'}:
        raise ValueError('both original package acceptance budgets required')
    allowed_env = CI_ENVIRONMENT_KEYS
    required_env = allowed_env - {'GERBIL_BUILD_CORES'}
    if not required_env <= set(profile['environment']) <= allowed_env or any(type(v) is not str for v in profile['environment'].values()):
        raise ValueError('closed CI environment required; heap/processor overrides are not profile inputs')
    source_policy = profile.get('sourcePolicy','published-support')
    if source_policy not in ('direct','published-support'):
        raise ValueError('closed source policy required')
    if source_policy == 'direct' and (profile['gambit'].get('patches') or profile.get('bootstrapRelease')):
        raise ValueError('direct source policy forbids patch overlays and bootstrap source rewrites')
    expected_runtime = _runtime_profile(profile.get('runtimeProfile'))
    phase_products=profile.get('phaseProducts',False)
    if args.get('throughStage','tools')!='tools' and phase_products is not True:
        raise ValueError('scoped CI construction requires phase products')
    if type(phase_products) is not bool:raise ValueError('phaseProducts must be a boolean stage contract')
    bootstrap_release = _bootstrap_release(profile.get('bootstrapRelease'))
    ctx.bind([profile_path])
    from gambit_smp.work_items import require_boundary_context
    boundary_policy = require_boundary_context(ctx)
    if boundary_policy and boundary_policy.get('sourcePolicy',source_policy) != source_policy:
        raise ValueError('source policy differs from the SysML execution boundary')
    _admit_runtime_profile(boundary_policy,expected_runtime)
    if 'bootstrapObservation' in args:
        return observe_bazel_bootstrap(ctx, profile, source_path(ctx.root, args['bootstrapObservation']), trace=args.get('bootstrapTrace'))
    base = (ctx.root/profile['bazelRoot']).resolve(strict=True)
    g = profile['gambit'];fields(g,('repository','revision','baselineCommit','baselineTree','patches'),('commitDate','commitMessage'))
    if source_policy == 'direct' and (g['baselineCommit'] != g['revision'] or g['patches']):
        raise ValueError('direct source identity must be its authoritative commit without overlays')
    if g['baselineCommit'] != g['revision'] and not {'commitDate','commitMessage'} <= g.keys():
        raise ValueError('historical support materialization requires exact commit metadata')
    gerbil = profile['gerbil'];fields(gerbil,('repository','revision','optionalObjectCache'))
    for value in (g['revision'],g['baselineCommit'],g['baselineTree'],gerbil['revision']):
        if not __import__('re').fullmatch('[0-9a-f]{40}',value):
            raise ValueError('exact Git object identities required')
    git = ctx.tools['git']
    saved = dict(ctx.env)
    try:
        for key in ('GERBIL_HOME','GERBIL_PATH','GERBIL_LOADPATH','GERBIL_GSC','GAMBOPT',
                    'CPATH','LIBRARY_PATH','PKG_CONFIG_LIBDIR','PKG_CONFIG_SYSROOT_DIR'):
            ctx.env.pop(key,None)
        ctx.env.update(profile['environment'])
        capacity = construction_capacity(profile['environment'], saved)
        ctx.env[capacity['variable']] = capacity['value']
        write(ctx.directory/'construction-capacity.json', capacity)
        dependencies = {}
        for name in ('autoconf','aclocal','m4','pkg-config','make','as','ld'):
            tool = shutil.which(name,path=ctx.env['PATH'])
            if not tool:
                raise ValueError('CI tool unavailable: '+name)
            ctx.bind([Path(tool).resolve(strict=True)])
        pkg = shutil.which('pkg-config',path=ctx.env['PATH'])
        for name in ('libcrypto','libssl','zlib','sqlite3'):
            directory=ctx.require('ci-pcdir-'+name,[pkg,'--variable=pcfiledir',name],ctx.root,10).strip()
            metadata=Path(directory)/(name+'.pc');ctx.bind([metadata])
            dependencies[name]=dict(metadata=str(metadata),sha256=digest(metadata),
                version=ctx.require('ci-version-'+name,[pkg,'--modversion',name],ctx.root,10).strip())
        sdk_metadata=Path(ctx.env['SDKROOT'])/'SDKSettings.json'
        if sdk_metadata.is_file():ctx.bind([sdk_metadata])
        write(ctx.directory/'ci-dependencies.json',dependencies)
        for name,sha in g['patches'].items():
            patch=(base/name).resolve(strict=True)
            if not patch.is_relative_to(base) or digest(patch)!=sha:
                raise ValueError('published baseline source input differs: '+name)
            ctx.bind([patch])
        work = build_output(ctx.root,'darwin',compiler=ctx.tools['gcc'],
            flags=['bazel-baseline',g['baselineCommit']])
        runtime = work/'source';runtime.mkdir(exist_ok=True)
        ctx.lease_workspace(runtime,tree_identity(runtime))
        if not any(runtime.iterdir()):
            ctx.require('baseline-init',[git,'init','--initial-branch=darwin-acceleration',runtime],ctx.root,10)
            ctx.require('baseline-fetch',[git,'-C',runtime,'fetch','--no-tags','--depth=1','--update-shallow',str((ctx.root/g['repository']).resolve()),g['revision']],ctx.root,30)
            ctx.require('baseline-checkout',[git,'-C',runtime,'checkout','-B','darwin-acceleration',g['revision']],ctx.root,10)
            for i,(name,sha) in enumerate(g['patches'].items()):
                patch = (base/name).resolve(strict=True)
                if not patch.is_relative_to(base) or digest(patch)!=sha:
                    raise ValueError('published baseline source input differs: '+name)
                ctx.bind([patch])
                ctx.require('baseline-support-'+str(i),[git,'-C',runtime,'apply',patch],ctx.root,10)
            ctx.require('baseline-index',[git,'-C',runtime,'add','--all'],ctx.root,10)
            actual = ctx.require('baseline-tree',[git,'-C',runtime,'write-tree'],ctx.root,10).strip()
            if actual != g['baselineTree']:
                raise ValueError('published baseline tree differs; no native construction')
            if g['baselineCommit'] != g['revision']:
                for key in ('GIT_AUTHOR_DATE','GIT_COMMITTER_DATE'):
                    ctx.env[key]=g['commitDate']
                ctx.require('baseline-commit',[git,'-C',runtime,'-c','user.name=Darwin baseline materializer',
                    '-c','user.email=baseline@local.invalid','-c','commit.gpgsign=false','-c','core.hooksPath=/dev/null',
                    'commit','-m',g['commitMessage']],ctx.root,10)
                for key in ('GIT_AUTHOR_DATE','GIT_COMMITTER_DATE'):
                    ctx.env.pop(key,None)
            elif g['patches']:
                raise ValueError('exact source snapshot cannot apply additional support')
        if ctx.require('baseline-head',[git,'-C',runtime,'rev-parse','HEAD'],ctx.root,10).strip()!=g['baselineCommit']:
            raise ValueError('owned baseline identity differs; do not reuse mixed source')
        if boundary_policy and boundary_policy['baselineRevision'] != g['revision']:
            ctx.require('scope-reference-fetch',[git,'-C',runtime,'fetch','--no-tags',
                '--depth=1','--update-shallow',str((ctx.root/g['repository']).resolve()),
                boundary_policy['baselineRevision']],ctx.root,30)
        if source_policy == 'direct':
            tree = ctx.require('direct-baseline-tree',[git,'-C',runtime,'rev-parse','HEAD^{tree}'],ctx.root,10).strip()
            dirty = ctx.require('direct-baseline-clean',[git,'-C',runtime,'status','--porcelain','--untracked-files=normal'],ctx.root,10).strip()
            if tree != g['baselineTree'] or dirty:
                raise ValueError('direct baseline must match its clean authoritative source tree')
        # A reused baseline may originate from the old incomplete shallow import.
        # Fetch the exact source parent with explicit shallow semantics, then
        # require traversable ancestry before acquiring a release or compiling.
        ctx.require('baseline-history-fetch',[git,'-C',runtime,'fetch','--no-tags',
            '--depth=1','--update-shallow',str((ctx.root/g['repository']).resolve()),
            g['revision']],ctx.root,30)
        ctx.require('baseline-history-check',[git,'-C',runtime,'rev-list','--count','HEAD'],ctx.root,10)
        if bootstrap_release:
            ref = 'refs/tags/'+bootstrap_release['tag']
            ctx.require('bootstrap-release-fetch',[git,'-C',runtime,'fetch','--no-tags','--depth=1',
                bootstrap_release['repository'],ref],ctx.root,120)
            actual = ctx.require('bootstrap-release-head',[git,'-C',runtime,'rev-parse',
                'FETCH_HEAD^{commit}'],ctx.root,10).strip()
            if actual != bootstrap_release['revision']:
                raise ValueError('bootstrap release tag moved; refuse native construction')
            ctx.require('bootstrap-release-pin',[git,'-C',runtime,'update-ref',ref,actual],ctx.root,10)
        repo_work=build_output(ctx.root,'gerbil',compiler=ctx.tools['gcc'],
            flags=['git-source',gerbil['repository'],gerbil['revision']])
        repo=repo_work/'source';repo.mkdir(exist_ok=True)
        ctx.lease_workspace(repo,tree_identity(repo))
        if not any(repo.iterdir()):
            ctx.require('gerbil-repository-init',[git,'init',repo],ctx.root,10)
            cached=(ctx.root/gerbil['optionalObjectCache']).resolve()
            origin=str(cached) if (cached/'.git').exists() else gerbil['repository']
            ctx.require('gerbil-repository-fetch',[git,'-C',repo,'fetch','--depth=1',origin,gerbil['revision']],ctx.root,120)
            ctx.require('gerbil-repository-checkout',[git,'-C',repo,'checkout','--detach',gerbil['revision']],ctx.root,10)
        if ctx.require('gerbil-repository-head',[git,'-C',repo,'rev-parse','HEAD'],ctx.root,10).strip()!=gerbil['revision']:
            raise ValueError('Gerbil source revision differs')
        result=build_bazel_compiler(ctx,runtime,repo,base,multiple_threaded_vms=expected_runtime['multipleThreadedVms'],
            source_only=True,budgets=profile['constructionBudgets'],bootstrap_release=bootstrap_release,source_policy=source_policy,
            runtime_profile=expected_runtime,phase_products=phase_products,
            through_stage=args.get('throughStage','tools'),prepared=profile.get('prepared'))
        result['constructionCapacity'] = capacity
        # Checkout and installation are producer-owned mutations. Seal their
        # final views after all native children have quiesced, rather than
        # verifying an initial empty checkout or a pre-install snapshot.
        # Immutable observed inputs remain independently checked by the engine.
        from gambit_smp.recipes import tree_identity
        result['workspaceOutputs']={}
        for owned in (runtime,repo,Path(result['source'])):
            if owned not in ctx.leased_workspaces:
                raise ValueError('producer output lacks its original workspace lease')
            tree=tree_identity(owned)
            result['workspaceOutputs'][str(owned)]=dict(
                sha256=hashlib.sha256(json.dumps(tree,sort_keys=True).encode()).hexdigest())
        result.update(packageSources={k:str((ctx.root/v).resolve(strict=True)) for k,v in profile['packageSources'].items()},
            packageBudgets=profile['packageBudgets'],
            packageEnvironment=dict(profile['environment'], GERBIL_BUILD_CORES=capacity['value']),
            baselinePerformanceCredit=0)
        output=ctx.directory/'gerbil-build.json';write(output,result)
        if not result.get('constructionPassed') and not (
                args.get('throughStage')=='stage1' and result.get('compilerCoreReady') is True
                and result.get('phaseConstructionPassed') is True):
            raise ValueError('CI construction failed at '+str(result.get('blockedAt'))+'; runtime blockers grant no redesign authority')
        return dict(outputs=ctx.publish('observations','gerbil-build-observations',output))
    finally:
        ctx.env.clear();ctx.env.update(saved)
