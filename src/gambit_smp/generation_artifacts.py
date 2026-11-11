"""Import one authenticated generation product, without rematerializing source.

The old materialize -> completed-runtime pair validated the same immutable
producer repeatedly. This selected route replaces that pair with one owner.
"""
import json
import shutil
from pathlib import Path
from gambit_smp.framework import digest, relative


def validate(args, inputs):
    from gambit_smp.recipes import fields
    fields(args, ('sourceLock', 'producer'))
    for key in ('sourceLock', 'producer'):
        if args[key] not in inputs or not args[key].endswith('.json'):
            raise ValueError('declared generation producer and source lock required')
    if not args['sourceLock'].endswith('.lock.json'):
        raise ValueError('locked generation source origin required')


def consume(args, ctx):
    from gambit_smp.recipes import source_path, read_json, artifact_path
    from gambit_smp.completed_producer import completed, fixture_path, native_ancestry, NATIVE_SCHEMA
    from gambit_smp.historical_inputs import bindings
    from gambit_smp.source_capabilities import validate_source_lock
    from gambit_smp.native_development import generated_inventory, generation_inputs, generation_recipe_projection
    lock_path=source_path(ctx.root,args['sourceLock']);lock=read_json(lock_path)
    validate_source_lock(lock)
    reference_path=source_path(ctx.root,args['producer']);reference=read_json(reference_path)
    if (reference['sourceLock'] != args['sourceLock']
            or reference['sourceLockSha256'] != digest(lock_path)):
        raise ValueError('generation source lock differs from the producer')
    run=fixture_path(ctx.root,reference['run'])
    archive=reference.get('inputArchive')
    if reference.get('schema') == NATIVE_SCHEMA:
        actual,source,identity_source,bound=native_ancestry(ctx.root,run,
            reference['declaration'],context=ctx,expected=reference)
        bound += [lock_path, reference_path]
    else:
        if archive and digest(source_path(ctx.root,archive['path'])) != archive['sha256']:
            raise ValueError('historical generation source archive drifted')
        actual,outer,step,_=completed(ctx.root,run,reference['step'],
            input_archive=archive['path'] if archive else None,workspace_context=ctx)
        source=artifact_path(run/'run',step['outputs']['runtime'],root=ctx.root)
        identity_source=relative(run/'run',step['outputs']['identity']['path'])
        bound=[lock_path,reference_path,run/'receipt.json',run/'run/receipt.json',
               run/'run'/reference['step']/'step-receipt.json',identity_source]
    if actual != reference or reference['gccSha256'] != digest(Path(ctx.tools['gcc'])):
        raise ValueError('completed generation origin or selected GNU toolchain differs')
    if archive:
        _,paths=bindings(ctx.root,run/'receipt.json',archive['path']);bound.extend(paths)
    ctx.bind(bound)
    inventory=generated_inventory(source)
    if not inventory:raise ValueError('complete generated C inventory required')
    manifest=ctx.directory/'generation.json'
    manifest.write_text(json.dumps(dict(producer=reference,generatedArtifacts=inventory,
        generationInputs=generation_inputs(source),generationRecipes=generation_recipe_projection(source),freshnessIssued=False,
        logicalContext='original Make-relative paths and pinned gsc-boot'),indent=2)+'\n')
    identity=ctx.directory/'identity.json';shutil.copy2(identity_source,identity)
    ctx.remaining()
    return dict(claim='one-owner-import-of-explicit-generation-product',
        originalProducerUnchanged=True,fullProducerValidations=1,sourceCopies=0,
        runtimeAdmitted=False,
        outputs={**ctx.publish('runtime','source-runtime',source),
                 **ctx.publish('identity','runtime-identity',identity),
                 **ctx.publish('generation','generation-manifest',manifest)})
