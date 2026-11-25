"""Gerbil build: static products."""
from gambit_smp.gerbil_build.sources import source_identity

from concurrent.futures import ThreadPoolExecutor, as_completed
from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import time

from gambit_smp.gerbil_build.custody import _current, _module_witnesses
from gambit_smp.gerbil_build.policy import _compiler_jobs

def _static_plan(source, value, gcc):
    """Decode the source producer's closed plan; never infer a module inventory."""
    source = Path(source).resolve()
    fields = {'kind', 'compiler', 'generationArgs', 'sources', 'linkOutput',
              'objectArgs', 'nativeCompiler', 'nativeLinkArgs', 'output'}
    if not isinstance(value, dict) or set(value) != fields or value['kind'] != 'StaticModuleProduct':
        raise ValueError('complete StaticModuleProduct plan required')
    if value['compiler'] != str(source/'build/bin/gsc') or value['nativeCompiler'] != str(gcc):
        raise ValueError('static plan compiler identity differs')
    for field in ('generationArgs', 'sources', 'objectArgs', 'nativeLinkArgs'):
        if not isinstance(value[field], list) or not all(isinstance(x, str) for x in value[field]):
            raise ValueError('static plan argv must be string arrays')
    modules = value['sources']
    if not modules or len(set(modules)) != len(modules):
        raise ValueError('empty or duplicate static module inventory')
    for name in modules:
        p = Path(name)
        if (p.parent != source/'build/lib/static' or p.suffix != '.scm'
                or not p.is_file() or p.is_symlink()):
            raise ValueError('static module source outside the owned inventory')
    if (value['linkOutput'] != str(source/'build/lib/gerbil-link.c')
            or value['output'] != str(source/'build/bin/gerbil')
            or value['objectArgs'] != ['-obj', '-cc-options', '-g']
            or value['generationArgs'][:1] != ['-track-scheme']):
        raise ValueError('static plan output or mode differs')
    objects = [str(Path(p).with_suffix('.o')) for p in modules]+[str(source/'build/lib/gerbil-link.o')]
    actual_objects = [x for x in value['nativeLinkArgs'] if x.endswith('.o')]
    if actual_objects != objects or value['nativeLinkArgs'][:2] != ['-o',value['output']]:
        raise ValueError('native link inventory/order differs from static module plan')
    return value


def _static_link_info(path):
    """Bind the existing C metadata block; Gambit's linker remains its decoder."""
    data = Path(path).read_bytes()
    if not data.startswith(b'#ifdef ___LINKER_INFO\n'):
        raise ValueError('generated C has no Gambit link metadata')
    head, marker, _ = data.partition(b'\n#else\n')
    if not marker:
        raise ValueError('generated C link metadata is incomplete')
    return hashlib.sha256(head).hexdigest()


def _static_products(ctx, work, source, plan, provider, deadline):
    """Real target-generation products, restored only with durable completion witnesses."""
    from gambit_smp.workspace import write
    from gambit_smp.artifact_storage import clone_file
    from gambit_smp.research_kernel import retain_run_record
    journal = ctx.receipt.get('journal')
    if not journal:raise ValueError('static products require an actual execution journal')
    header = json.loads(Path(journal['path']).read_text())
    store = Path(work)/'gerbil-static-products.json'
    retained = json.loads(store.read_text()) if store.is_file() else {}
    witnesses = _module_witnesses(ctx.root, retained, schema='gerbil-static-product-observation')
    entries, pending = {}, []
    def install(origin, target):
        import uuid
        if target.is_symlink():raise ValueError('static product output alias')
        temporary = target.with_name(target.name+'.pending-'+uuid.uuid4().hex)
        clone_file(origin,temporary)
        temporary.replace(target)
    def input_key(path):
        return hashlib.sha256(json.dumps(dict(provider=provider,source=str(path),
            sourceSha256=digest(path),argv=plan['generationArgs'],mode='static'),sort_keys=True).encode()).hexdigest()
    for name in plan['sources']:
        path = Path(name);key = input_key(path)
        stage = 'static-c-'+key[:24]
        directory = Path(work)/'static-products'/key
        proof = retained.get(key,{})
        ref = proof.get('completion',{})
        witness_key = tuple(ref.get(k) for k in ('path','sha256','observation','scope'))
        core = {k:v for k,v in proof.items() if k not in {'completion','completionRun'}}
        valid = (witnesses.get(witness_key) == core and
                 _current(directory,proof,key,stage=proof.get('producerStage',stage),root=ctx.root))
        if valid:
            cached = directory/'product.c'
            if _static_link_info(cached) != proof.get('linkInfoSha256'):
                raise ValueError('static product metadata drift')
            target = path.with_suffix('.c')
            if target.is_symlink():raise ValueError('static C output alias')
            if not target.is_file() or digest(target) != digest(cached):
                install(cached,target)
            entries[key] = proof
        else:
            cached = directory/'product.c'
            if (witnesses.get(witness_key) == core and cached.is_file()
                    and digest(cached) != proof.get('outputs',{}).get('product.c')):
                raise ValueError('sealed static product drift')
            pending.append((path,key,stage,directory))
    if pending:
        # The source producer already declares one ordered, common generation
        # context. Keep per-module products, but initialize that compiler once
        # for the misses rather than reloading identical support for every SCM.
        # Gambit's -c accepts the same ordered source inventory as its linker.
        batch_key = hashlib.sha256(json.dumps(
            [(str(path), key) for path, key, _, _ in pending], sort_keys=True).encode()).hexdigest()
        batch_stage = 'static-c-batch-' + batch_key[:24]
        command_stage = 'gerbil-' + batch_stage
        quarantine = ctx.directory / (batch_stage + '-previous')
        if quarantine.exists() or quarantine.is_symlink():
            raise ValueError('previous static generation still has custody')
        previous = []
        for index, (path, key, _, directory) in enumerate(pending):
            target = path.with_suffix('.c')
            if target.is_symlink():raise ValueError('static C output alias')
            if target.exists():
                if not target.is_file():raise ValueError('static C output is not a file')
                previous.append(dict(source=str(target), retained=str(quarantine/(str(index)+'.c')),
                                     sha256=digest(target), inputsSha256=key))
        if previous:
            quarantine.mkdir()
            # This is an attempt-local custody record, not a reusable product.
            # On interruption each file may still be at either recorded path.
            write(quarantine/'custody.json', dict(state='transfer-planned', files=previous,
                reusable=False, completionKnown=False))
            for item in previous:
                Path(item['source']).rename(item['retained'])
        remaining = min(ctx.remaining(), deadline-time.monotonic())
        if remaining <= 0:raise TimeoutError('static generation stage budget exhausted')
        ctx.require(command_stage, [plan['compiler'], '-c', *plan['generationArgs'],
            *[str(path) for path, _, _, _ in pending]], source/'src', remaining)
        command = next(c for c in ctx.commands if c['stage'] == command_stage)
        if not command.get('parentReaped') or not command.get('processGroupQuiescent'):
            raise ValueError('static generation has unknown completion')
        # Validate the complete batch before publishing any member. A successful
        # exit with a missing C output must not adopt a previous file as fresh.
        produced = []
        for path, key, _, directory in pending:
            if input_key(path) != key:raise ValueError('static source changed during generation')
            target = path.with_suffix('.c')
            if not target.is_file() or target.is_symlink():
                raise ValueError('static generation missing fresh C output')
            produced.append((path, key, directory, _static_link_info(target)))
        raw = (ctx.directory/(command_stage+'.process.json')).read_text()
        for path, key, directory, metadata in produced:
            directory.mkdir(parents=True, exist_ok=True)
            cached = directory/'product.c'
            install(path.with_suffix('.c'), cached)
            proof = dict(inputsSha256=key, outputs={'product.c':digest(cached)},
                modes={'product.c':cached.stat().st_mode & 0o777}, links={}, command=command,
                receiptBytes=raw, receiptSha256=hashlib.sha256(raw.encode()).hexdigest(),
                producerStage=batch_stage, linkInfoSha256=metadata)
            payload = dict(schema='gerbil-static-product-observation', header=journal,
                runId=header['runId'], moduleProof=proof, runtimeAdmitted=False)
            ref = retain_run_record(ctx.root, ctx.directory/('static-'+key+'.completed.json'),
                journal['scope'], payload, header['inputs'])
            proof.update(completion=ref, completionRun=str(Path(journal['path']).parent))
            retained[key] = entries[key] = proof
            write(store, retained)
    ordered = []
    for name in plan['sources']:
        key = input_key(Path(name));proof = entries[key]
        target = Path(name).with_suffix('.c')
        if digest(target) != proof['outputs']['product.c']:
            raise ValueError('static C changed before link admission')
        ordered.append(dict(source=name,path=str(target),inputSha256=key,
            cSha256=digest(target),linkInfoSha256=proof['linkInfoSha256'],completion=proof['completion']))
    result = dict(kind='LinkPlan',products=ordered,generated=len(pending),reused=len(ordered)-len(pending),
                  generationProcesses=int(bool(pending)))
    write(ctx.directory/'static-module-products.json',result)
    return result


def _static_link_product(ctx, work, source, plan, products, provider, deadline):
    from gambit_smp.workspace import write
    from gambit_smp.research_kernel import retain_run_record
    from gambit_smp.artifact_storage import clone_file
    import uuid
    key = hashlib.sha256(json.dumps(dict(provider=provider,output=plan['linkOutput'],
        ordered=[(p['path'],p['linkInfoSha256']) for p in products['products']]),
        sort_keys=True).encode()).hexdigest()
    store = Path(work)/'gerbil-static-products.json'
    retained = json.loads(store.read_text())
    directory = Path(work)/'static-products'/key
    proof = retained.get(key,{})
    witnesses = _module_witnesses(ctx.root,retained,schema='gerbil-static-product-observation')
    ref = proof.get('completion',{})
    witness_key = tuple(ref.get(k) for k in ('path','sha256','observation','scope'))
    core = {k:v for k,v in proof.items() if k not in {'completion','completionRun'}}
    stage = 'static-link-'+key[:24]
    cached = directory/'product.c';target = Path(plan['linkOutput'])
    if target.is_symlink():raise ValueError('link product output alias')
    valid = witnesses.get(witness_key) == core and _current(directory,proof,key,stage=stage,root=ctx.root)
    if not valid:
        if (witnesses.get(witness_key) == core and cached.is_file()
                and digest(cached) != proof.get('outputs',{}).get('product.c')):
            raise ValueError('sealed link product drift')
        cap = min(ctx.remaining(),deadline-time.monotonic())
        if cap <= 0:raise TimeoutError('static metadata link budget exhausted')
        ctx.require('gerbil-'+stage,[plan['compiler'],'-link','-o',target,
            *[p['path'] for p in products['products']]],source/'src',cap)
        _static_link_info(target)
        directory.mkdir(parents=True,exist_ok=True)
        temporary = directory/('pending-'+uuid.uuid4().hex)
        clone_file(target,temporary);temporary.replace(cached)
        command = next(c for c in ctx.commands if c['stage'] == 'gerbil-'+stage)
        if not command.get('parentReaped') or not command.get('processGroupQuiescent'):
            raise ValueError('static metadata link has unknown completion')
        raw = (ctx.directory/('gerbil-'+stage+'.process.json')).read_text()
        proof = dict(inputsSha256=key,outputs={'product.c':digest(cached)},
            modes={'product.c':cached.stat().st_mode & 0o777},links={},command=command,
            receiptBytes=raw,receiptSha256=hashlib.sha256(raw.encode()).hexdigest())
        journal = ctx.receipt['journal'];header = json.loads(Path(journal['path']).read_text())
        payload = dict(schema='gerbil-static-product-observation',header=journal,
            runId=header['runId'],moduleProof=proof,runtimeAdmitted=False)
        reference = retain_run_record(ctx.root,ctx.directory/('static-'+key+'.completed.json'),
            journal['scope'],payload,header['inputs'])
        proof.update(completion=reference,completionRun=str(Path(journal['path']).parent))
        retained[key]=proof;write(store,retained)
    elif not target.is_file() or digest(target) != proof['outputs']['product.c']:
        temporary = target.with_name(target.name+'.pending-'+uuid.uuid4().hex)
        clone_file(cached,temporary);temporary.replace(target)
    return dict(inputSha256=key,cSha256=digest(target),reused=valid,completion=proof['completion'])


def _stage1_static(ctx, work, source, payloads, identity, stage_budget_seconds):
    """One bounded stage: prepare -> products -> ordered link -> objects -> native consumer."""
    from gambit_smp.workspace import write
    deadline = time.monotonic()+min(stage_budget_seconds,ctx.remaining())
    def remaining():
        cap = min(ctx.remaining(),deadline-time.monotonic())
        if cap <= 0:raise TimeoutError('Gerbil stage1 static pipeline budget exhausted')
        return cap
    plan_path = ctx.directory/'static-module-plan.json'
    previous = ctx.env.get('GERBIL_STATIC_PLAN')
    ctx.env['GERBIL_STATIC_PLAN'] = str(plan_path)
    try:
        ctx.require('gerbil-stage1-prepare',[ctx.tools['sh'],'./build.sh','stage1'],source/'src',remaining())
    finally:
        if previous is None:ctx.env.pop('GERBIL_STATIC_PLAN',None)
        else:ctx.env['GERBIL_STATIC_PLAN']=previous
    plan = _static_plan(source,json.loads(plan_path.read_text()),ctx.tools['gcc'])
    # Runtime/compiler payloads include the generated header and macro support;
    # source paths and argv are also identity, so tracking/naming cannot drift.
    provider = dict(runtime=digest(identity),payloads=payloads,
        producer=digest(source/'src/build/build-bach.ss'),
        implementation=source_identity(),
        environment={k:v for k,v in ctx.env.items() if k in {
            'GAMBOPT','PATH','LC_ALL','LANG','GERBIL_GSC','GERBIL_GCC','CFLAGS','LDFLAGS'}})
    products = _static_products(ctx,work,source,plan,provider,deadline)
    c_files = [p['path'] for p in products['products']]
    # Gambit reads existing metadata from these C files. No SCM input can hide
    # another frontend invocation in this ordered link operation.
    link = _static_link_product(ctx,work,source,plan,products,provider,deadline)
    write(ctx.directory/'link-plan.json',dict(products=products,link=link))
    def compile_object(path):
        name = hashlib.sha256(str(path).encode()).hexdigest()[:24]
        ctx.require('gerbil-static-object-'+name,[plan['compiler'],*plan['objectArgs'],path],
                    source/'src',remaining())
        command = next(c for c in ctx.commands if c['stage'] == 'gerbil-static-object-'+name)
        if not command.get('parentReaped') or not command.get('processGroupQuiescent'):
            raise ValueError('static object has unknown completion')
    # Native include closure is not yet sealed: do NOT reuse .o by C hash alone.
    with ThreadPoolExecutor(max_workers=_compiler_jobs(ctx.env)) as pool:
        futures = [pool.submit(compile_object,p) for p in [*c_files,plan['linkOutput']]]
        failure = None
        for future in as_completed(futures):
            try:future.result()
            except Exception as error:
                failure = failure or error
                for other in futures:other.cancel()
        if failure:raise failure
    ctx.require('gerbil-static-executable',[plan['nativeCompiler'],*plan['nativeLinkArgs']],
                source/'src',remaining())
    ctx.env['GERBIL_HOME'] = str(source/'build')
    text = ctx.require('gerbil-stage1',[source/'build/bin/gxi','-e',
        '(import :gerbil/compiler) (displayln "STATIC-COMPILER-READY")'],source,remaining())
    if 'STATIC-COMPILER-READY' not in text:raise ValueError('static compiler consumer missing')
    write(ctx.directory/'static-pipeline.json',dict(products=products,link=link,nativeObjectsReused=0,
        wholeStageBudgetSeconds=stage_budget_seconds,consumerPassed=True,mergeAllowed=False))
