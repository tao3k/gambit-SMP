"""Gerbil build: compiler products."""
from gambit_smp.gerbil_build.custody import _product_observation_directory


from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil

from gambit_smp.gerbil_build.custody import AdmissionFiles, _git_blob, _module_witnesses, _scheme_product_data
from gambit_smp.gerbil_build.make_source import _identity_make_source
from gambit_smp.gerbil_build.compiler_source import module_source
from gambit_smp.gerbil_build.module_products import _module_arguments_supported, _prepare_module_products, _retain_module_products

from gambit_smp.gerbil_build.dependencies import _compiler_dependencies


def _native_policy_source(text):
    """Project only reviewed native eligibility; never project generated IR.

    LET initialization is parsed into ordinary runtime code by Gambit's
    pt-let. This predicate runs on already emitted Scheme and controls reuse
    of a completed native request; it does not change generator invocation.
    """
    old='((declare ##declare define ##define namespace ##namespace) (safe-tree? value))'
    new='((declare ##declare define ##define namespace ##namespace let ##let) (safe-tree? value))'
    old_comment=';; The stricter phase memoization mode remains unchanged.'
    new_comment=';; Other initialization remains outside strict phase memoization.'
    if text.count(new)==1 and text.count(new_comment)==1:
        return text.replace(new,old).replace(new_comment,old_comment)
    if text.count(old)==1 and text.count(old_comment)==1:return text
    raise ValueError('unreviewed compiler native reuse policy')


def _compile_product_context(ctx, source, runtime):
    """Bind the producer and native provider; depfiles bind actual header reads.

    This remains a managed toolchain contract, not an OS-wide syscall proof.
    Arbitrary macro/eval results receive no standalone reuse authority. A
    quiescent, dependency-closed managed generation can continue the same
    module program without admitting its interface or its pending native work.
    """
    import os
    source, runtime = Path(source), Path(runtime)
    inputs = {str(p):digest(p) for p in (source/'src').rglob('*') if p.is_file()}
    for prefix, pattern in [('include','*.h'),('lib','*#.scm'),('gsc','*#.scm')]:
        inputs.update({str(p):digest(p) for p in (runtime/prefix).rglob(pattern) if p.is_file()})
    for name in ['gsc/gsc','gsi/gsi','bin/gambuild-C','lib/libgambit.a']:
        inputs[str(runtime/name)] = digest(runtime/name)
    inputs[str(source/'build/bin/gerbil')] = digest(source/'build/bin/gerbil')
    for path in (source/'build/lib').glob('*#.scm'):
        if path.is_file():inputs[str(path.resolve())]=digest(path)
    for name in ('Makefile','build.sh','run.sh','build-env.sh','configure'):
        if (source/name).is_file():inputs[str(source/name)] = digest(source/name)
    for name in ('gsc','gambuild-C'):
        inputs[str(source/'build/bin'/name)] = digest(source/'build/bin'/name)
    for name, path in ctx.tools.items():
        if Path(path).is_file():inputs[str(path)] = digest(Path(path))
    native_providers=[Path(ctx.tools['gcc'])]
    for role in ('cc1','collect2'):
        path = ctx.require('gerbil-compiler-'+role,[ctx.tools['gcc'],'-print-prog-name='+role],
                           source/'src',min(10,ctx.remaining())).strip()
        if not Path(path).is_absolute() or not Path(path).is_file():
            raise ValueError('resolved native compiler component required: '+role)
        inputs[path] = digest(Path(path))
        native_providers.append(Path(path))
    # The compiler's installed interfaces are build-host inputs, not target
    # stdlib completion. Preserve their lexical identities in the snapshot.
    for prefix in ('build/lib/gerbil','build/lib/static/gerbil'):
        for path in (source/prefix).rglob('*'):
            if path.is_file():inputs[str(path.resolve())]=digest(path)
    # Establish the header snapshot before any compiler reads it. A depfile
    # path outside this declared snapshot cannot acquire reuse authority.
    directories = [source/'build/include']
    for role, option in [('sysroot','-print-sysroot'), ('include','-print-file-name=include'),
                         ('include-fixed','-print-file-name=include-fixed')]:
        path = ctx.require('gerbil-headers-'+role,[ctx.tools['gcc'],option],
                           source/'src',min(10,ctx.remaining())).strip()
        if Path(path).is_absolute() and Path(path).is_dir():directories.append(Path(path).resolve())
    # Use the stdlib's existing four pkg-config dependencies. The resolver,
    # search metadata, headers and link providers are frozen before any task;
    # unobserved dependencies still cannot acquire module reuse authority.
    import shlex
    pkg=shutil.which(ctx.env.get('PKG_CONFIG','pkg-config'),path=ctx.env.get('PATH'))
    if pkg:
        inputs[pkg]=digest(Path(pkg));native_providers.append(Path(pkg))
        rc,flags,timeout,_=ctx.run('gerbil-stdlib-provider-flags',
            [pkg,'--cflags','--libs','libcrypto','libssl','sqlite3','zlib'],source/'src',min(10,ctx.remaining()))
        if rc==0 and not timeout:
            paths=shlex.split(flags);link_directories=[]
            for word in paths:
                if word.startswith('-I') and Path(word[2:]).is_dir():directories.append(Path(word[2:]).resolve())
                if word.startswith('-L') and Path(word[2:]).is_dir():link_directories.append(Path(word[2:]).resolve())
            for directory in link_directories:
                for pattern in ('*.dylib','*.a'):
                    for path in directory.glob(pattern):
                        if path.is_file():inputs[str(path.resolve())]=digest(path)
        rc,search,timeout,_=ctx.run('gerbil-pkg-config-search-path',
            [pkg,'--variable=pc_path','pkg-config'],source/'src',min(10,ctx.remaining()))
        if rc==0 and not timeout:
            search=search.strip()+os.pathsep+ctx.env.get('PKG_CONFIG_PATH','')+os.pathsep+ctx.env.get('PKG_CONFIG_LIBDIR','')
            for name in search.split(os.pathsep):
                if name and Path(name).is_dir():
                    for path in Path(name).glob('*.pc'):
                        if path.is_file():inputs[str(path.resolve())]=digest(path)
    for directory in directories:
        for pattern in ('*.h','*.tbd'):
            for path in directory.rglob(pattern):
                if path.is_file():inputs[str(path.resolve())] = digest(path)
        for name in ('SDKSettings.json','SDKSettings.plist'):
            if (directory/name).is_file():inputs[str((directory/name).resolve())]=digest(directory/name)
    # GCC's versioned non-system dylibs are provider inputs too. Do not guess
    # an @rpath/loader environment; such a provider stays non-reusable.
    loader_supported=True
    if os.uname().sysname=='Darwin':
        otool=shutil.which(os.environ.get('OTOOL','otool'),path=ctx.env.get('PATH'))
        if not otool:loader_supported=False
        else:
            inputs[otool]=digest(Path(otool));seen=set()
            while native_providers:
                provider=native_providers.pop().resolve()
                if provider in seen:continue
                seen.add(provider)
                output=ctx.require('gerbil-provider-'+str(len(seen)),[otool,'-L',provider],
                                   source/'src',min(10,ctx.remaining()))
                for line in output.splitlines()[1:]:
                    name=line.strip().split(' (compatibility version',1)[0]
                    if name.startswith(('/usr/lib/','/System/Library/')):continue
                    p=Path(name)
                    if not p.is_absolute() or not p.is_file():loader_supported=False;continue
                    inputs[str(p.resolve())]=digest(p);native_providers.append(p)
    env = {k:v for k,v in ctx.env.items() if not k.startswith((
        'CODEX_', 'GAMBIT_SMP_', 'BROWSER_USE_', 'NODE_REPL_', 'GERBIL_COMPILE_'))
        and k not in {'SHLVL','_','OLDPWD','PWD'}}
    # The normal GSC CLI can evaluate ~/.gambini. Without -f, an existing init
    # file is an unmanaged compile-time capability, not a cacheable dependency.
    init = Path(env.get('HOME',''))/'.gambini'
    reuse = not init.exists() and loader_supported and not env.get('DYLD_INSERT_LIBRARIES')
    record = dict(inputs=inputs,environment=env,system=list(os.uname()),
                  producerEntry=ctx.receipt.get('producerEntry','make stdlib'),
                  unmanagedInitialization=init.exists(),providerLoaderSupported=loader_supported,
                  reuseAllowed=reuse)
    # Make is both a library target and the build consumer. Its query-only
    # adapter is not the language generator. Keep exact observed bytes in the
    # run snapshot, but fingerprint the unchanged producer outside this owned
    # adapter. The library target's own source hash still invalidates it.
    make_path=source/'src/std/make.ss'
    make_text=make_path.read_text()
    producer_text=_identity_make_source(make_text,inverse=True)
    material=dict(record);material['inputs']=dict(inputs)
    projections={}
    if producer_text!=make_text:
        logical=hashlib.sha256(producer_text.encode()).hexdigest()
        material['inputs'][str(make_path)]=logical
        projections[str(make_path)]=dict(observedSha256=inputs[str(make_path)],
            producerSha256=logical,rule='owned Make identity/timestamp queries only; native invocation and generator unchanged')
    policy_path=source/'src/gerbil/compiler/compile-products.ss'
    policy_text=policy_path.read_text()
    generator_policy=_native_policy_source(module_source(policy_text,inverse=True))
    if generator_policy!=policy_text:
        logical=hashlib.sha256(generator_policy.encode()).hexdigest()
        material['inputs'][str(policy_path)]=logical
        projections[str(policy_path)]=dict(observedSha256=inputs[str(policy_path)],
            producerSha256=logical,
            rule='reviewed native eligibility, owned scheduling and closed generation continuation; actual source, generated inputs and native requests remain bound')
    driver_path=source/'src/gerbil/compiler/driver.ss'
    driver_text=driver_path.read_text()
    generator_driver=module_source(driver_text,driver=True,inverse=True)
    if generator_driver!=driver_text:
        logical=hashlib.sha256(generator_driver.encode()).hexdigest()
        material['inputs'][str(driver_path)]=logical
        projections[str(driver_path)]=dict(observedSha256=inputs[str(driver_path)],
            producerSha256=logical,
            rule='module-owned native scheduling and interface publication; generator and native requests unchanged')
    key = hashlib.sha256(json.dumps(material,sort_keys=True).encode()).hexdigest()
    # Library ordering consumes completed stdlib programs; it does not produce
    # them. Only this exact inverse may preserve their existing producer key.
    from gambit_smp.gerbil_build.library_source import library_order_source, library_initialization_source
    library_path=source/'src/build/build-libgerbil.ss'
    library_text=library_path.read_text()
    from gambit_smp.gerbil_build.static_units import library_static_source
    library_producer=library_order_source(library_initialization_source(library_static_source(library_text,inverse=True),inverse=True),inverse=True)
    if library_producer!=library_text:
        logical=hashlib.sha256(library_producer.encode()).hexdigest()
        material['inputs'][str(library_path)]=logical
        projections[str(library_path)]=dict(observedSha256=inputs[str(library_path)],
            producerSha256=logical,rule='library consumer context-subgraph completion only; stdlib generator unchanged')
        key = hashlib.sha256(json.dumps(material,sort_keys=True).encode()).hexdigest()
    # The catalogue is a derived read-only view of existing definitions. It
    # cannot create a generator input: only its checked bootstrap consumer can
    # load it, and actual compilation still activates the same source driver.
    from gambit_smp.gerbil_build.catalog_source import catalog_source, catalog_bootstrap_source
    catalog_path=source/'src/gerbil/compiler/compile-product-catalog.ss'
    if catalog_path.exists():
        if catalog_path.read_text()!=catalog_source():
            raise ValueError('unreviewed compiler catalogue source')
        material['inputs'].pop(str(catalog_path),None)
        projections[str(catalog_path)]=dict(observedSha256=digest(catalog_path),
            producerSha256=None,rule='derived metadata consumer only; absent from generator inputs')
    bootstrap=source/'src/std/build.ss'
    if str(bootstrap) in material['inputs']:
        observed=bootstrap.read_text()
        logical=catalog_bootstrap_source(observed,inverse=True)
        if logical!=observed:
            sha=hashlib.sha256(logical.encode()).hexdigest()
            material['inputs'][str(bootstrap)]=sha
            projections[str(bootstrap)]=dict(observedSha256=digest(bootstrap),
                producerSha256=sha,rule='catalogue bootstrap only; source driver unchanged before actual compilation')
    key=hashlib.sha256(json.dumps(material,sort_keys=True).encode()).hexdigest()
    ctx.compiler_source_projections=projections
    if projections:record['inputProjections']=projections
    return key,record


def _prepare_compile_products(ctx, work, source, runtime, *, expected_context=None):
    """Expose only checked native products to the existing Scheme producer."""
    from gambit_smp.workspace import write
    work, source = Path(work), Path(source)
    if source.resolve() not in ctx.leased_workspaces:
        raise ValueError('compile products require the exclusive source lease')
    if '(compile-product-invoke ' not in (source/'src/gerbil/compiler/driver.ss').read_text():
        raise ValueError('source compiler completion contract is unavailable')
    ctx.env['GERBIL_GIT'] = str(ctx.tools['git'])
    settled = getattr(ctx, 'compiler_settled_context', None)
    if settled is None:
        key, context = _compile_product_context(ctx,source,runtime)
    else:
        del ctx.compiler_settled_context
        old_source, old_runtime, environment, tools, key, context = settled
        if (source != old_source or Path(runtime) != old_runtime or ctx.env != environment or
                ctx.tools != tools or any(not Path(p).is_file() or digest(Path(p)) != sha
                                         for p, sha in context['inputs'].items())):
            raise ValueError('settled producer context changed before Make preparation')
    epoch_path = work/'compile-product-epoch.json'
    epoch = json.loads(epoch_path.read_text()) if epoch_path.is_file() else {}
    retained=expected_context or epoch.get('context')
    if retained is not None and key!=retained:
        from gambit_smp.gerbil_build.compiler_roles import bind_retained_context
        prior_store=work/'compile-products'/retained
        proof=(bind_retained_context(ctx,work,source,retained,key,context)
               if epoch.get('context')==retained and prior_store.is_dir()
                  and any(prior_store.glob('*.json')) else None)
        if proof is not None:
            context['observedContext']=key
            context['producerEquivalence']=proof
            key=retained
        elif expected_context is not None:
            raise ValueError('requested compiler cohort changed before product withdrawal')
    if epoch.get('context') != key:
        # Inputs changed or this cohort has no producer receipts. Preserve
        # unqualified old bytes, preventing stale frontend/native mixtures.
        write(epoch_path,dict(context=key,frontendReuse=False))
    store = work/'compile-products'/key
    store.mkdir(parents=True,exist_ok=True)
    outbox = ctx.directory/'compile-products'
    outbox.mkdir()
    admitted, stale = [], []
    records = {p.stem:json.loads(p.read_text()) for p in store.glob('*.json')}
    # Native tasks and their enclosing module programs refer to the same
    # immutable completed runs. Read each checkpoint once for this preparation;
    # never reuse this in-memory view across separate producer attempts.
    ctx.compiler_execution_checkpoints={}
    files=AdmissionFiles()
    witnesses = _module_witnesses(ctx.root, records, schema='gerbil-compiler-product-observation',
                                 payload_key='product',checkpoints=ctx.compiler_execution_checkpoints)
    for identity,record in records.items():
        p = store/(identity+'.json')
        data = record['data'];cache = p.with_suffix('.scm')
        ref = record.get('completion',{})
        witness_key = tuple(ref.get(k) for k in ('path','sha256','observation','scope'))
        core = {k:v for k,v in record.items() if k not in {'completion','completionRun'}}
        valid = (witnesses.get(witness_key)==core and record['context']==key and len(data)==9 and
                 cache.is_file() and not cache.is_symlink() and
                 cache.read_text()==_scheme_product_data(data)+'\n' and
                 all(files.matches(x,h) for x,h in record['inputIdentities'].items()))
        if valid:admitted.append(p.stem)
        else:
            # Keep the successful historical receipt. Removing only its
            # derived Scheme transport prevents it from authorizing a hit.
            if cache.exists() or cache.is_symlink():cache.unlink()
            stale.append(p.stem)
    if any(store.glob('frontend-*.unqualified')):
        raise ValueError('frontend reuse marker has no semantic authority')
    native_runs=len(ctx.compiler_execution_checkpoints)
    try:
        modules=_prepare_module_products(ctx,work,source,key,store,records,admitted,
                                        reuse_allowed=context['reuseAllowed'],
                                        file_observations=files)
        checkpoint_reads=dict(actual=len(ctx.compiler_execution_checkpoints),
                              separateSchemaReads=native_runs+modules['executionCheckpointRuns'],
                              lifetime='one preparation; released before the Make process')
    finally:
        ctx.compiler_execution_checkpoints.clear()
    ctx.env.update(GERBIL_COMPILE_PRODUCTS=str(store),GERBIL_COMPILE_CONTEXT=key,
                   GERBIL_COMPILE_ATTEMPT=str(outbox),GERBIL_GIT=str(ctx.tools['git']),
                   GERBIL_COMPILE_REUSE='1'if context['reuseAllowed']else '0')
    write(ctx.directory/'compile-product-context.json',dict(context=key,**context,
          admitted=admitted,stale=stale,checkpointReads=checkpoint_reads,
          fileObservations=files.summary(),frontendReuse=False,sourceCopies=0))
    return key,context,store,outbox


def _retain_compile_products(ctx, source, prepared, producer):
    """Promote guarded native returns only after the whole producer is quiescent.

    A timed-out parent never becomes a passing stage. Its independently
    completed pure native products can survive; a request or .o1 alone cannot.
    """
    from gambit_smp.workspace import write
    from gambit_smp.research_kernel import retain_run_record
    key,context,store,outbox = prepared
    if producer.get('parentReaped') is not True or producer.get('processGroupQuiescent') is not True:
        raise ValueError('native result custody requires producer quiescence')
    if any(not Path(p).is_file() or digest(Path(p))!=h for p,h in context['inputs'].items()):
        raise ValueError('compiler provider/source changed during production')
    source = Path(source).resolve()
    rows = [];native_records={}
    for path in sorted(outbox.glob('*.completed.json')):
        value = json.loads(path.read_text())
        identity = path.name.removesuffix('.completed.json')
        request = json.loads((outbox/(identity+'.request.json')).read_text())
        if (not isinstance(value,list) or len(value)!=11 or value[:7]!=request
                or value[0]!=key or value[1]!=str(source/'build/bin/gsc')
                or Path(value[3]).resolve()!=source/'src/std' or value[10]not in ('executed','reused')):
            raise ValueError('native completion differs from its actual request')
        _,program,argv,cwd,input_name,input_oid,output_name,output_oid,plain,dep_text,outcome = value
        inp,out = Path(input_name),Path(output_name)
        if (not inp.is_relative_to(source/'build/lib/std') or inp.suffix!='.scm'
                or inp.resolve()!=inp or out!=inp.with_suffix('.o1')
                or out.is_symlink() or not out.is_file() or inp.is_symlink()
                or not argv or argv[-1]!=str(inp) or _git_blob(inp)!=input_oid
                or _git_blob(out)!=output_oid or type(plain)is not bool):
            raise ValueError('native completion lacks current source/output custody')
        if outcome=='reused':
            prior = json.loads((store/(identity+'.json')).read_text())
            if prior['data'][:8]!=value[:8]:raise ValueError('reuse has no matching completed native witness')
            dependencies = [Path(p) for p,_ in prior['data'][8]]
        else:
            # _gsclib.scm passes output-dir to ##gambuild. GCC's relative
            # dependency paths use that directory, not the outer GSC cwd.
            dependencies = _compiler_dependencies(dep_text,out.parent,inp.with_suffix('.c'))
        identities = {str(p):digest(p)for p in [inp,out,*dependencies]}
        if outcome=='reused' and identities!=prior['inputIdentities']:
            raise ValueError('reused native dependency changed after preparation')
        supported = all(str(p) in context['inputs'] for p in dependencies)
        if any(str(p) in context['inputs'] and identities[str(p)]!=context['inputs'][str(p)]
               for p in dependencies):
            raise ValueError('native header snapshot changed during compilation')
        data = [*value[:8],[[str(p),_git_blob(p)]for p in dependencies]]
        record = dict(context=key,data=data,inputIdentities=identities,
                      guardedCompilerReturn=outcome=='executed',observationKind=outcome,
                      producerStage=producer['stage'],producerExit=producer.get('exit'),
                      producerTimedOut=producer.get('timeout'),runtimeAdmitted=False,
                      sourceBoundary='Actual gxc invoke returned after process-status/close; parent reaped and group quiescent. This is a source-refined native observation, not a separate Python waitpid receipt.')
        record['moduleReusable']=bool(context['reuseAllowed'] and supported and _module_arguments_supported(argv,context))
        native_records[identity]=record
        reusable = plain and context['reuseAllowed'] and supported
        if reusable and outcome=='executed':
            # Durable evidence is published before its derived Scheme cache.
            journal=ctx.receipt.get('journal')
            if not journal:raise ValueError('native completion needs the existing execution journal')
            header=json.loads(Path(journal['path']).read_text())
            ref=retain_run_record(ctx.root,_product_observation_directory(ctx,outbox)/(identity+'.observed.json'),journal['scope'],
                dict(schema='gerbil-compiler-product-observation',header=journal,runId=header['runId'],
                     product=record,runtimeAdmitted=False),header['inputs'])
            record['completion']=ref
            record['completionRun']=str(Path(journal['path']).parent)
            write(store/(identity+'.json'),record)
            target=store/(identity+'.scm');temporary=target.with_suffix('.pending')
            temporary.write_text(_scheme_product_data(data)+'\n');temporary.replace(target)
        rows.append(dict(id=identity,outcome=outcome,reusable=reusable,
                         source=input_name,output=output_name,outputSha256=digest(out)))
    modules=_retain_module_products(ctx,source,prepared,producer,native_records)
    result=dict(context=key,moduleProducts=modules,products=rows,executed=sum(x['outcome']=='executed'for x in rows),
                reused=sum(x['outcome']=='reused'for x in rows),
                unfinishedRequests=len(list(outbox.glob('*.request.json')))-len(rows),
                stageComplete=producer.get('exit')==0 and producer.get('timeout')is False,
                frontendReuse=False,runtimeAdmitted=False)
    if result['stageComplete'] and ((not rows and not modules['reusedPrograms']) or result['unfinishedRequests']):
        raise ValueError('successful producer lacks a complete native completion inventory')
    write(ctx.directory/'compile-product-observations.json',result)
    return result


def _settled_borrows(ctx, prior, key, store):
    """Reconstruct exactly the programs the stopped attempt actually borrowed.

    The current mutable store alone is not proof of an earlier admission.
    Module snapshots and generation-use fingerprints must match their original
    immutable issuer observations before the normal consumer validator runs.
    """
    outbox = prior/'compile-products'
    saved_path = prior/'admitted-module-programs.json'
    saved = json.loads(saved_path.read_text()) if saved_path.is_file() else []
    witnesses = _module_witnesses(ctx.root, dict(enumerate(saved)),
        schema='gerbil-module-product-observation', payload_key='moduleProduct')
    modules = {}
    for path in outbox.glob('*.module-used.json'):
        value = json.loads(path.read_text())
        matches = [row for row in saved if row['context'] == key and
                   value[:3] == [key, row['source'], row['interface']]]
        if len(matches) != 1:
            raise ValueError('borrowed module has no original admission snapshot')
        row = matches[0]
        ref = row['completion']; wk = tuple(ref[k] for k in ('path','sha256','observation','scope'))
        if witnesses.get(wk) != {k:v for k,v in row.items() if k not in ('completion','completionRun')}:
            raise ValueError('borrowed module immutable observation changed')
        modules[path.name.removesuffix('.module-used.json')] = row
    generations = {}
    for path in outbox.glob('*.generation-used.json'):
        identity = path.name.removesuffix('.generation-used.json')
        row = json.loads((store/'generations'/(identity+'.json')).read_text())
        if row['data'][0] != key:
            raise ValueError('borrowed generation belongs to another context')
        witnesses = _module_witnesses(ctx.root, {identity: row},
            schema='gerbil-module-generation-observation', payload_key='moduleGeneration')
        ref = row['completion']; wk = tuple(ref[k] for k in ('path','sha256','observation','scope'))
        raw = (_scheme_product_data(row['data'])+'\n').encode()
        oid = hashlib.sha1(b'blob '+str(len(raw)).encode()+b'\0'+raw).hexdigest()
        if (witnesses.get(wk) != {k:v for k,v in row.items() if k not in ('completion','completionRun')} or
                json.loads(path.read_text()) != [key, row['source'], row['data'][2], oid]):
            raise ValueError('borrowed generation has no exact original marker witness')
        generations[identity] = dict(row, markerOid=oid)
    if saved_path.is_file():ctx.bind([saved_path])
    ctx.compiler_module_records = modules
    ctx.compiler_generation_records = generations


def settle_compile_products(ctx, work, source, runtime, prior):
    """Settle a stopped attempt before preparing another Make invocation.

    The old parent keeps its failed outcome. Actual joined native results and
    closed generation prefixes may survive a retainer failure, but only under
    the identical producer context and the existing exclusive source lease.
    """
    from gambit_smp.workspace import write
    source, prior = Path(source).resolve(), Path(prior)
    if (source not in ctx.leased_workspaces or prior.resolve() != prior
            or not prior.is_relative_to(ctx.root / '.cache')):
        raise ValueError('settlement requires owned source and original attempt custody')
    result_path, context_path = prior/'result.json', prior/'compile-product-context.json'
    previous = json.loads(result_path.read_text())
    old = json.loads(context_path.read_text())
    producers = [c for c in previous['commands'] if c['stage'] == 'gerbil-stdlib']
    if len(producers) != 1:
        raise ValueError('one original stdlib producer required')
    producer = producers[0]
    if producer.get('argv') != [str(ctx.tools['make']), 'stdlib'] or producer.get('cwd') != str(source):
        raise ValueError('settlement requires the original Make stdlib entry and cwd')
    process_path = prior/'gerbil-stdlib.process.json'
    process = json.loads(process_path.read_text())
    if (process.get('state') != 'OBSERVED' or
            producer.get('parentReaped') is not True or
            any(process.get(k) != producer.get(k) for k in
                ('argv', 'cwd', 'environment', 'exit', 'timeout', 'parentReaped',
                 'processGroupQuiescent', 'stdoutSha256', 'stderrSha256'))):
        raise ValueError('original producer lacks matching stopped process observation')
    bound = [result_path, context_path, process_path]
    for field in ('stdout', 'stderr'):
        path = Path(producer[field+'Path'])
        path = path if path.is_absolute() else prior/path
        if (path.resolve() != path or not path.is_relative_to(prior) or
                digest(path) != producer[field+'Sha256']):
            raise ValueError('original producer stream identity changed')
        bound.append(path)
    ctx.bind(bound)
    late_custody = None
    if producer.get('processGroupQuiescent') is not True:
        # Keep the original incomplete stream/group observation unchanged.
        # Existing birth-bound task reconciliation can establish a later stop;
        # it cannot reconstruct missing output or turn a timeout into success.
        from gambit_smp.task_processes import check
        from gambit_smp.process_identity import boot_id
        from gambit_smp.workspace import bounded, identifier
        task = identifier(producer['environment']['GAMBIT_SMP_TASK_ID'])
        run = identifier(producer['environment']['GAMBIT_SMP_TASK_RUN'])
        records = bounded(ctx.root, '.state/task-processes/'+task+'/'+run)
        candidates = [(p, json.loads(p.read_text())) for p in records.glob('*.json')]
        candidates = [(p, row) for p, row in candidates if row.get('pid') == producer.get('pid')]
        if len(candidates) != 1:
            raise ValueError('late settlement needs the exact recorded producer birth')
        path, old_record = candidates[0]
        if (old_record.get('birth', {}).get('bootId') != boot_id() or
                old_record.get('cwd') != str(source) or
                old_record.get('argvSha256') != hashlib.sha256(json.dumps(producer['argv']).encode()).hexdigest()):
            raise ValueError('late settlement producer identity differs')
        check(ctx.root, task, run=run, process=old_record.get('process'))
        record = json.loads(path.read_text())
        if (record.get('groupObservation', {}).get('result') != 'absent' or
                record.get('sessionObservation', {}).get('result') != 'absent'):
            raise ValueError('late producer stop remains unresolved')
        ctx.bind([path])
        late_custody = dict(recordSha256=digest(path), birth=record['birth'],
            group=record['groupObservation'], session=record['sessionObservation'],
            originalGroupObservation=producer.get('processGroupQuiescent'),
            originalStreamComplete=producer.get('streamCaptureComplete'), originalResultPreserved=True)
        producer = dict(producer, processGroupQuiescent=True)
    key, context = _compile_product_context(ctx, source, runtime)
    if key != old['context']:
        raise ValueError('settlement cannot migrate a producer context')
    _settled_borrows(ctx, prior, key, Path(work)/'compile-products'/key)
    result = _retain_compile_products(ctx, source,
        (key, context, Path(work)/'compile-products'/key, prior/'compile-products'), producer)
    original_stage_passed = result['stageComplete']
    result = dict(result, stageComplete=False, settlementOnly=True)
    ctx.compiler_settled_context = (source, Path(runtime), dict(ctx.env), dict(ctx.tools), key, context)
    write(ctx.directory/'settled-compile-products.json', dict(
        originalResultSha256=digest(result_path), originalStagePassed=original_stage_passed,
        lateCustody=late_custody, products=result, runtimeAdmitted=False))
    return result


def _stdlib_compile_products(ctx, work, source, runtime, *, stage_budget_seconds=600,
                             expected_context=None):
    """Use the official Scheme queue and retain each joined native product.

    No alternate scheduler/runner is introduced. Reserve validation time inside
    the existing deadline; neither a timed-out stage nor frontend files pass.
    """
    if type(stage_budget_seconds)is not int or not 0<stage_budget_seconds<=600:
        raise ValueError('unchanged stdlib stage envelope required')
    owned=lambda name:name.startswith('GERBIL_COMPILE_') or name=='GERBIL_GIT'
    saved={k:v for k,v in ctx.env.items() if owned(k)}
    try:
        _ensure_gerbil_build_environment(ctx,source)
        prepared=_prepare_compile_products(ctx,work,source,runtime,
                                           expected_context=expected_context)
        error=None
        try:
            budget=min(stage_budget_seconds,ctx.remaining())-20
            if budget<=0:raise TimeoutError('no stdlib budget after completion validation reserve')
            ctx.require('gerbil-stdlib',[ctx.tools['make'],'stdlib'],Path(source),budget)
        except Exception as original:error=original
        producer=next((c for c in ctx.commands if c['stage']=='gerbil-stdlib'),None)
        if producer is not None:
            result=_retain_compile_products(ctx,source,prepared,producer)
        else:result=None
        from gambit_smp.workspace import checkpoint_build_source
        checkpoint_build_source(source)
        if error is not None:raise error
        return result
    finally:
        for name in list(ctx.env):
            if owned(name):ctx.env.pop(name)
        ctx.env.update(saved)


def _ensure_gerbil_build_environment(ctx, source):
    """Materialize configure's existing three-field output for the owned SDK.

    The Gambit profile is already configured. Running integrated configure
    would reconfigure that runtime; no second profile or shell runner is added.
    """
    import shlex
    names=('GERBIL_PREFIX','GERBIL_VERSION','GERBIL_VERSION_STRING')
    if any(not isinstance(ctx.env.get(k),str) or not ctx.env[k] for k in names):
        raise ValueError('existing declared Gerbil construction environment required')
    text=''.join(k+'='+shlex.quote(ctx.env[k])+'\n' for k in names)
    text+='export '+' '.join(names)+'\n'
    path=Path(source)/'build-env.sh'
    if path.exists() and path.read_text()!=text:
        raise ValueError('existing configure output differs; no silent reconfiguration')
    if not path.exists():path.write_text(text)
