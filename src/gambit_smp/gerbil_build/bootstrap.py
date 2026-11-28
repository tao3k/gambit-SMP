"""Gerbil build: bootstrap."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import json
import shutil

from gambit_smp.gerbil_build.ci_profile import build_ci_profile
from gambit_smp.gerbil_build.owned_compiler import build_owned_compiler
from gambit_smp.gerbil_build.policy import _batch_size, _native_jobs, _through_stage

def validate(args, inputs):
    from gambit_smp.native_capabilities import fields, reference
    if args.get('producer') == 'bazel-ci':
        fields(args, ('producer', 'sourceLock'), ('bootstrapObservation','bootstrapTrace','throughStage'))
        _through_stage(args.get('throughStage','tools'))
        if args.get('throughStage','tools') not in ('stage1','tools'):
            raise ValueError('CI scope must be stage1 or complete tools')
        if args['sourceLock'] not in inputs:
            raise ValueError('declared CI source profile required')
        if 'bootstrapObservation' in args and args['bootstrapObservation'] not in inputs:
            raise ValueError('declared retained bootstrap observation required')
        if 'bootstrapTrace' in args and (args['bootstrapTrace'] not in ('fatal-stack','disassembly','section-capacity','header-comparison','failed-command-stack') or 'bootstrapObservation' not in args):
            raise ValueError('bootstrap trace requires its retained observation')
        return
    fields(args, ('sourceLock', 'runtime', 'identity'), ('stdlibBatchSize', 'throughStage', 'staticProducts', 'stdlibNativeProducts', 'stdlibNativeJobs'))
    if args.get('staticProducts') is True or args.get('stdlibNativeProducts') is True:
        raise ValueError('unqualified custom native-plan execution withdrawn; use official Gerbil compiler interfaces')
    if type(args.get('staticProducts',False)) is not bool:
        raise ValueError('staticProducts must select a declared boolean build contract')
    if type(args.get('stdlibNativeProducts', False)) is not bool:
        raise ValueError('stdlibNativeProducts must be boolean')
    if args.get('stdlibNativeProducts') and args.get('stdlibBatchSize') is not None:
        raise ValueError('native products and cumulative batches are different stage contracts')
    _native_jobs(args.get('stdlibNativeJobs'))
    if args.get('stdlibNativeJobs') is not None and not args.get('stdlibNativeProducts'):
        raise ValueError('stdlibNativeJobs requires the retired-producer native contract')
    _batch_size(args.get('stdlibBatchSize'))
    _through_stage(args.get('throughStage', 'tools'))
    if args['sourceLock'] not in inputs:
        raise ValueError('declared pinned Gerbil source lock required')
    reference(args['runtime']); reference(args['identity'])
    if args['runtime']['step'] != args['identity']['step']:
        raise ValueError('Gerbil must consume one same-producer Gambit runtime and identity')


def build(args, ctx):
    if args.get('producer') == 'bazel-ci':
        return build_ci_profile(args, ctx)
    from gambit_smp.recipes import read_json, source_path, tree_identity
    from gambit_smp.workspace import build_output, sync_build_source, checkpoint_build_source, write
    from gambit_smp.source_capabilities import source_name
    from gambit_smp.native_capabilities import compiler
    if ctx.receipt.get('workspacePolicy') != 'in-place':
        raise ValueError('Gerbil builds require the shared in-place workspace policy')
    lock_path = source_path(ctx.root, args['sourceLock'])
    lock = read_json(lock_path)
    if (lock.get('schema') != 'gerbil-source-lock.v1' or lock.get('runtimeAdmitted') is not False
            or len(lock.get('revision', '')) != 40):
        raise ValueError('non-admitting pinned Gerbil source revision required')
    checkout = relative(ctx.root, lock['checkout'])
    runtime = ctx.artifact(args['runtime'], 'source-runtime')
    identity = ctx.artifact(args['identity'], 'runtime-identity')
    from gambit_smp.suite_primitives import check_runtime
    check_runtime(runtime, read_json(identity))
    from gambit_smp.work_items import admit_source_delta
    admit_source_delta(ctx, runtime)
    ctx.bind([identity])
    compiler(ctx)
    # The pinned base/runtime/tools own the physical workspace. Declared core
    # source deltas invalidate action proofs below, rather than forking another
    # checkout. Keep the existing empty base field in the workspace identity.
    core = {name: value for name, value in lock.get('files', {}).items()
            if name.startswith(('src/gerbil/', 'src/bootstrap/', 'src/build/'))
            or name in {'src/build.sh', 'build.sh', 'configure'}}
    configuration = dict(revision=lock['revision'], runtimeSha256=digest(identity),
        compilerInputs={path: sha for path, sha in ctx.extra_inputs.items() if path != str(identity)}, coreInputs={},
        tools={name: digest(Path(path)) for name, path in ctx.tools.items() if name in {'gcc', 'as', 'ld', 'sh', 'make'}})
    work = build_output(ctx.root, 'gerbil', compiler=ctx.tools['gcc'],
                        flags=[json.dumps(configuration, sort_keys=True)])
    source = work / 'source'
    source.mkdir(exist_ok=True)
    ctx.lease_workspace(source, tree_identity(source))
    state_path = work / 'source-state.json'
    previous = read_json(state_path) if state_path.is_file() else {}
    partial = bool(previous.get('inputs')) and 'overlayFiles' in previous
    selected = sorted(set(lock.get('files', {})) | set(previous.get('overlayFiles', []))
                      | set(previous.get('pendingOverlayFiles', []))) if partial else []
    for name in selected:source_name(name)
    archive = ctx.directory / 'gerbil-source.tar'
    staged = ctx.directory / 'gerbil-inputs'
    archive_skipped = partial and not selected and 'patch' not in lock
    if archive_skipped:
        # The owned configuration already binds this pinned Git revision.
        # Let the normal source synchronizer validate existing inputs against
        # its checkpoint; no full-tree transport is needed for an empty delta.
        staged.mkdir()
    else:
        ctx.require('gerbil-archive', [ctx.tools['git'], '-C', checkout, 'archive',
            '--output=' + str(archive), lock['revision'], '--', *selected], ctx.root, min(30, ctx.remaining()))
        from gambit_smp.artifact_storage import extract_archive
        extract_archive(archive,staged,ctx,stage='gerbil-extract',preserve_modes=False)
        archive.unlink()
    if 'patch' in lock:
        if lock['patch'] not in ctx.receipt['declaredInputs']:
            raise ValueError('Gerbil overlay must be a declared input')
        patch = source_path(ctx.root, lock['patch'])
        if digest(patch) != lock.get('patchSha256'):
            raise ValueError('Gerbil overlay drift')
        inventory = ctx.require('gerbil-overlay-inventory', [ctx.tools['git'], '--git-dir=/dev/null',
            'apply', '--numstat', '-z', patch], staged, min(10, ctx.remaining()))
        for line in inventory.split('\0'):
            if line and line.split('\t', 2)[-1] not in lock.get('files', {}):
                raise ValueError('Gerbil overlay exceeds its declared source files')
        ctx.require('gerbil-overlay', [ctx.tools['git'], '--git-dir=/dev/null', 'apply',
            '--whitespace=error', patch], staged, min(10, ctx.remaining()))
    for name, sha in lock.get('files', {}).items():
        source_name(name)
        if digest(staged / name) != sha:
            raise ValueError('Gerbil candidate differs from source lock: ' + name)
    incoming = dict(previous['inputs'], **tree_identity(staged)) if partial else tree_identity(staged)
    delta = sync_build_source(ctx.root, work, staged, mutable=['src/gerbil/runtime/version.ss'],
                             inventory=incoming, overlay_files=sorted(lock.get('files', {})), consume_staged=True)
    shutil.rmtree(staged)
    return build_owned_compiler(ctx, work, source, runtime, identity,
                           revision=lock['revision'], core=core, delta=delta,
                           archive_skipped=archive_skipped,
                           stdlib_batch_size=args.get('stdlibBatchSize'),
                           through_stage=args.get('throughStage', 'tools'),
                           static_products=args.get('staticProducts',False),
                           stdlib_native_products=args.get('stdlibNativeProducts', False),
                           stdlib_native_jobs=args.get('stdlibNativeJobs'))
