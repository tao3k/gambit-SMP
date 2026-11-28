"""Gerbil build: module products."""
from gambit_smp.gerbil_build.custody import _product_observation_directory


from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import json
from contextlib import contextmanager

from gambit_smp.gerbil_build.batches import _stdlib_outputs, _withdraw_stdlib_batch
from gambit_smp.gerbil_build.custody import _git_blob, _module_witnesses, _scheme_product_data, _module_arguments_supported


@contextmanager
def module_product_scope(ctx, work, source, completed):
    """Lease issued module programs through the last dependent consumer.

    No frontend file is promoted here. The original immutable completion
    witnesses, native outputs, dependency closure and graph output must pass
    the same issuer used by Make. Existing environment fields are scoped to
    this consumer and restored on every exit.
    """
    if completed.get('stageComplete') is not True:
        raise ValueError('initialization planning requires completed stdlib')
    key=completed['context'];store=Path(work)/'compile-products'/key
    # Planning consumes complete module programs, not the native candidate
    # history. Old native requests may name an earlier incarnation of the
    # same output; admitting them here would overwrite the current module's
    # sealed hashes. Native candidates are qualified by the compiler stage.
    admission=_prepare_module_products(ctx,work,source,key,store,{},[])
    valid=ctx.compiler_module_records
    if not valid or any(not record.get('initializationGraph') for record in valid.values()):
        raise ValueError('module program has no same-generation initialization graph')
    from gambit_smp.gerbil_build.compiler_service import ensure_compiler_service
    service=ensure_compiler_service(ctx,work,source,key)
    names=('GERBIL_COMPILE_PRODUCTS','GERBIL_COMPILE_CONTEXT',
           'GERBIL_COMPILE_ATTEMPT','GERBIL_COMPILE_REUSE','GERBIL_GIT')
    saved={name:ctx.env.get(name)for name in names}
    outbox=ctx.directory/'initialization-consumer';outbox.mkdir()
    try:
        ctx.env.update(GERBIL_COMPILE_PRODUCTS=str(store),GERBIL_COMPILE_CONTEXT=key,
            GERBIL_COMPILE_ATTEMPT=str(outbox),GERBIL_COMPILE_REUSE='1',
            GERBIL_GIT=str(ctx.tools['git']))
        from gambit_smp.gerbil_build.initialization_views import planning_views
        with planning_views(ctx,source,store,valid) as views:
            yield dict(admission,initializationViews=len(views),compilerService=service)
    finally:
        for name,value in saved.items():
            if value is None:ctx.env.pop(name,None)
            else:ctx.env[name]=value


def _prepare_module_products(ctx, work, source, key, store, native_records, admitted,
                             *, reuse_allowed=True, file_observations=None):
    """Expose only complete, dependency-closed module programs to the builder."""
    from gambit_smp.workspace import write
    from gambit_smp.gerbil_build.custody import AdmissionFiles
    import os
    source=Path(source);directory=store/'modules';directory.mkdir(exist_ok=True)
    files=file_observations if file_observations is not None else AdmissionFiles()
    records={p.stem:json.loads(p.read_text()) for p in directory.glob('*.json')}
    witnesses=_module_witnesses(ctx.root,records,schema='gerbil-module-product-observation',payload_key='moduleProduct',
                                checkpoints=getattr(ctx,'compiler_execution_checkpoints',None))
    valid={};rejected={}
    projected=set(getattr(ctx,'compiler_source_projections',{}))
    newest_source=max((p.stat().st_mtime for p in (source/'src').rglob('*')
                       if p.is_file() and str(p) not in projected),default=0)
    for identity,record in records.items():
        ref=record.get('completion',{});wk=tuple(ref.get(k) for k in ('path','sha256','observation','scope'))
        core={k:v for k,v in record.items()if k not in ('completion','completionRun')}
        # The generator's interfaces/IR certify this source incarnation.
        # A native object can have been reused byte-for-byte from an earlier
        # successful request. Its birth time is not the module's completion
        # time; its exact bytes and immutable native witness remain required.
        generated=[Path(p) for p in record['ownedOutputs']
                   if Path(p).suffix in ('.ssi','.scm')]
        if (reuse_allowed and record['context']==key and witnesses.get(wk)==core and
                all(files.matches(p,sha) for p,sha in record['identities'].items()) and
                all(Path(p).resolve()==Path(p) and Path(p).stat().st_nlink==1 for p in record['ownedOutputs']) and
                generated and Path(record['interface']) in generated and
                max(newest_source,Path(record['source']).stat().st_mtime)<=
                    min(p.stat().st_mtime for p in generated)):
            valid[identity]=record
        else:rejected[identity]='missing/changed module or immutable completion witness'
    # A module's phase ABI is not independent of its imported syntax objects.
    # Keep a closed subset; never mix a saved interface with a rebuilt provider.
    while True:
        ids={r['moduleId']for r in valid.values()}
        bad={k:r for k,r in valid.items()if any(d.startswith('std/') and d!=r['moduleId'] and d not in ids for d in r['dependencies'])}
        if not bad:break
        for identity in bad:valid.pop(identity);rejected[identity]='module dependency has no complete reusable program'
    if len({r['moduleId']for r in valid.values()})!=len(valid):raise ValueError('duplicate module program identity')
    keep={};owned=_stdlib_outputs(source)
    for record in valid.values():
        keep.update({str(Path(p).relative_to(source)):sha for p,sha in record['identities'].items() if Path(p).is_relative_to(source) and str(Path(p).relative_to(source)) in owned})
    # Exact phase artifacts remain candidates for GSC, but their descriptors
    # are never exposed as independently completed modules.
    for identity in admitted:
        record=native_records[identity]
        for p,sha in record['inputIdentities'].items():
            if Path(p).is_relative_to(source) and str(Path(p).relative_to(source)) in owned and Path(p).suffix in ('.scm','.o1'):
                keep[str(Path(p).relative_to(source))]=sha
    from gambit_smp.gerbil_build.module_generations import prepare_generations
    prepare_generations(ctx, source, key, store, valid, files, keep,
                        reuse_allowed=reuse_allowed)
    # Static C/object programs own their outputs independently of a module's
    # SSI/native completion. Preserve only requalified, journal-backed units;
    # an unfinished static file still has no reuse authority.
    from gambit_smp.gerbil_build.static_units import prepare_static_units
    for unit in prepare_static_units(ctx,store/'static-units',key,source).values():
        output=unit['data'][0][7]
        name=str(Path(output).relative_to(source))
        sha=unit['identities'][output]
        if name not in owned:
            continue  # Other static namespaces are outside stdlib withdrawal.
        if name in keep and keep[name]!=sha:
            raise ValueError('module and static unit disagree on physical ownership')
        keep[name]=sha
    _withdraw_stdlib_batch(ctx,source,keep)
    for marker in directory.rglob('*.ready'):marker.unlink()
    for identity,record in valid.items():
        relative=Path(record['source']).relative_to(source)
        marker=directory/(str(relative)+'.ready');marker.parent.mkdir(parents=True,exist_ok=True)
        plan=[record['moduleId'],record['dependencies']]
        if record.get('initializationGraph'):
            plan.append(record['initializationGraph'])
        marker.write_text(_scheme_product_data([key,record['source'],record['interface'],identity,plan])+'\n')
        # Completion belongs to this program, not to an older borrowed input.
        # All ordinary SSI/static output freshness checks remain independent.
        stamp=max(Path(p).stat().st_mtime for p in record['ownedOutputs'])
        os.utime(marker,(stamp,stamp))
    ctx.compiler_module_records=valid
    # Preserve the exact admitted witnesses before later builds can replace
    # store entries. Audit must not reconstruct an earlier admission from the
    # current mutable store or infer it from frontend files.
    write(ctx.directory/'admitted-module-programs.json',list(valid.values()))
    report=dict(context=key,admitted=len(valid),rejected=rejected,moduleIds=sorted(r['moduleId']for r in valid.values()),
                executionCheckpointRuns=len({r.get('completionRun')for r in records.values()}-{None}),
                frontendFilesAlone=False,runtimeAdmitted=False)
    write(ctx.directory/'module-product-admission.json',report)
    return report


def _retain_module_products(ctx, source, prepared, producer, native_records):
    """Publish coherent programs only after actual native and metadata completion."""
    from gambit_smp.workspace import write
    from gambit_smp.research_kernel import retain_run_record
    if producer.get('parentReaped') is not True or producer.get('processGroupQuiescent') is not True:
        raise ValueError('module result custody requires producer quiescence')
    key,context,store,outbox=prepared;source=Path(source).resolve();directory=store/'modules';directory.mkdir(exist_ok=True)
    results=[]
    for path in sorted(outbox.glob('*.module-completed.json')):
        value=json.loads(path.read_text());identity=path.name.removesuffix('.module-completed.json')
        request=json.loads((outbox/(identity+'.module-request.json')).read_text())
        if len(value)!=9 or value[:3]!=request or value[0]!=key:raise ValueError('module completion lacks its original request')
        _,src,oid,module_id,deps,tasks,outputs,dependency_files,dependency_complete=value
        if not Path(src).is_relative_to(source/'src/std') or _git_blob(Path(src))!=oid:raise ValueError('module source changed')
        if not tasks or len({x[0]for x in tasks})!=len(tasks):raise ValueError('module native task inventory must be nonempty and unique')
        native=[];supported=dependency_complete is True and context.get('reuseAllowed', False)
        for task,safe in tasks:
            if type(safe)is not bool or task not in native_records:raise ValueError('module refers to an unfinished native task')
            row=native_records[task];native.append(row)
            supported=supported and safe and row['moduleReusable']
        identities={str(Path(src)):digest(Path(src))}
        for p,git_oid in outputs:
            output=Path(p)
            if (not output.is_relative_to(source/'build/lib') or not output.is_file() or
                    output.resolve()!=output or output.stat().st_nlink!=1 or
                    _git_blob(output)!=git_oid):raise ValueError('module output ownership changed')
            identities[p]=digest(output)
        owned_outputs=list(identities)
        emitted=set(identities)
        for row in native:
            if row['data'][4] not in emitted:raise ValueError('module omitted an owned native input')
            identities.update(row['inputIdentities']);owned_outputs.append(row['data'][6])
        for p,git_oid in dependency_files:
            if not Path(p).is_file() or _git_blob(Path(p))!=git_oid:raise ValueError('module imported a different dependency incarnation')
            identities[p]=digest(Path(p))
        interface=source/'build/lib'/(module_id+'.ssi')
        if str(interface)not in emitted:raise ValueError('module has no completed interface writer')
        record=dict(context=key,source=src,moduleId=module_id,dependencies=deps,nativeTasks=[x[0]for x in tasks],
                    interface=str(interface),identities=identities,ownedOutputs=[p for p in owned_outputs if Path(p).is_relative_to(source/'build/lib')],moduleReusable=bool(supported),runtimeAdmitted=False,
                    boundary='Official Make incremental policy plus frozen complete producer inputs and coherent native/metadata completion; not an arbitrary macro/native-I/O clean-build equivalence theorem.')
        graph=interface.with_suffix('.init')
        if str(graph) in emitted:
            record['initializationGraph']=str(graph)
        if supported:
            journal=ctx.receipt['journal'];header=json.loads(Path(journal['path']).read_text())
            ref=retain_run_record(ctx.root,_product_observation_directory(ctx,outbox)/(identity+'.module-observed.json'),journal['scope'],
                dict(schema='gerbil-module-product-observation',header=journal,runId=header['runId'],moduleProduct=record,runtimeAdmitted=False),header['inputs'])
            record.update(completion=ref,completionRun=str(Path(journal['path']).parent));write(directory/(identity+'.json'),record)
        results.append(dict(moduleId=module_id,nativeTasks=len(tasks),reusable=bool(supported)))
    uses=[];rebuilt={p.name.removesuffix('.module-request.json')for p in outbox.glob('*.module-request.json')}
    for path in sorted(outbox.glob('*.module-used.json')):
        identity=path.name.removesuffix('.module-used.json');value=json.loads(path.read_text())
        record=getattr(ctx,'compiler_module_records',{}).get(identity)
        if (record is None or len(value) not in (3,4) or
                value[:3]!=[key,record['source'],record['interface']] or
                (len(value)==4 and value[3] not in ('phase-import','build-metadata'))):
            raise ValueError('module consumption has no admitted complete program')
        if identity not in rebuilt and any(
                not Path(p).is_file() or digest(Path(p))!=sha
                for p,sha in record['identities'].items()
                if p not in context.get('inputs',{})):
            raise ValueError('consumed module program changed during Make')
        uses.append(dict(moduleId=record['moduleId'],rebuilt=identity in rebuilt,nativeTasks=len(record['nativeTasks']),
                         consumption=value[3] if len(value)==4 else 'phase-import'))
    from gambit_smp.gerbil_build.module_generations import retain_generations
    generations = retain_generations(ctx, source, prepared, producer)
    report=dict(usedInterfaces=uses,reusedPrograms=sum(not x['rebuilt']for x in uses),avoidedNativeTasks=sum(x['nativeTasks']for x in uses if not x['rebuilt']),completed=results,count=len(results),reusable=sum(x['reusable']for x in results),
                unfinishedModules=len(list(outbox.glob('*.module-request.json')))-len(results),parentComplete=producer.get('exit')==0 and not producer.get('timeout'),runtimeAdmitted=False)
    report['generations'] = generations
    write(ctx.directory/'module-product-observations.json',report)
    return report
