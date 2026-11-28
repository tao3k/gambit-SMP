"""AOT implementation of the existing gxc service; no compiler executor."""

import json
import shutil
from pathlib import Path
from gambit_smp.framework import digest
from gambit_smp.workspace import write
from gambit_smp.gerbil_build.custody import _git_blob, _module_witnesses, _scheme_product_data
from gambit_smp.gerbil_build.compiler_roles import module_roles, project_inputs, fingerprint


def ensure_compiler_service(ctx,work,source,key):
    """Build one existing compiler module through public gxc and admit it.

    The source implementation is already the managed producer. Compiling that
    same source is an implementation handoff, not a new language/profile or
    authority to change a module's retained producer identity.
    """
    source=Path(source);directory=Path(work)/'compile-products'/key/'compiler-driver'
    directory.mkdir(exist_ok=True);manifest=directory/'producer.json';ready=directory/'ready.scm'
    context=json.loads((ctx.directory/'compile-product-context.json').read_text())
    roles=context.get('producerEquivalence',{}).get('sourceRoles')or module_roles(ctx,source)
    projected,_=project_inputs(dict(inputs=context['inputs']),source,roles)
    inputs={p:h for p,h in projected['inputs'].items()
            if not Path(p).is_relative_to(source/'src')
               or Path(p).is_relative_to(source/'src/gerbil')}
    signature=fingerprint(dict(inputs=inputs,environment=context['environment'],
                               contract=digest(Path(__file__)),
                               mode='existing gxc compiler module'))
    driver=source/'src/gerbil/compiler/driver.ss';support=source/'src/gerbil/compiler/compile-products.ss'
    previous=json.loads(manifest.read_text())if manifest.exists()else None
    valid=False
    if previous:
        ref=previous['completion'];wk=tuple(ref[k]for k in ('path','sha256','observation','scope'))
        core={k:v for k,v in previous.items()if k not in ('completion','completionRun')}
        witnesses=_module_witnesses(ctx.root,{'driver':previous},schema='gerbil-compiler-service-observation',payload_key='service')
        valid=(witnesses.get(wk)==core and previous['signature']==signature
               and all(Path(p).is_file()and Path(p).resolve()==Path(p)and digest(Path(p))==h
                       for p,h in previous['outputs'].items()))
    if not valid:
        if ready.exists():ready.unlink()
        library=directory/'lib'
        if library.exists():
            retained=ctx.directory/'unpublished-compiler-driver'
            write(ctx.directory/'compiler-driver-withdrawal.json',dict(source=str(library),destination=str(retained),reusable=False))
            library.rename(retained)
        library.mkdir()
        # This is the compiler's own public bootstrap entry, not another job
        # queue or a Python reproduction of its native command planning.
        saved={k:v for k,v in ctx.env.items()if k.startswith('GERBIL_COMPILE_')}
        for name in saved:ctx.env.pop(name)
        try:
            # run.sh establishes the original loader paths but replaces
            # GAMBOPT. Restore the already-declared profile after that step,
            # so its child GSC inherits the same p1 runtime as its parent.
            env_program=shutil.which('env',path=ctx.env.get('PATH'))
            if not env_program:raise ValueError('existing environment utility unavailable')
            ctx.require('compiler-driver-aot',[str(source/'run.sh'),env_program,
                        'GAMBOPT='+ctx.env['GAMBOPT'],'gxc','-:p1',
                        '-d',str(library),str(driver)],
                        source/'src',min(120,ctx.remaining()))
        finally:ctx.env.update(saved)
        producer=ctx.commands[-1]
        if not producer.get('parentReaped')or not producer.get('processGroupQuiescent'):
            raise ValueError('compiled compiler service has unknown writers')
        if any(not Path(p).is_file()or digest(Path(p))!=h for p,h in inputs.items()):
            raise ValueError('compiler service input changed during bootstrap')
        obj=library/'gerbil/compiler/driver~0.o1'
        if not obj.is_file():raise ValueError('compiler service has no native runtime object')
        outputs={str(p):digest(p)for p in library.rglob('*')if p.is_file()}
        if any(Path(p).resolve()!=Path(p)or Path(p).stat().st_nlink!=1 for p in outputs):
            raise ValueError('compiler service output has an alias')
        # Real generation must pass through the newly loaded entry and close
        # the module protocol; a native file by itself cannot grant readiness.
        smoke=ctx.directory/'compiler-driver-smoke';smoke.mkdir();outbox=smoke/'observations';outbox.mkdir()
        bindings=dict(ctx.env)
        ctx.env.update(GERBIL_COMPILE_CONTEXT=key,GERBIL_COMPILE_PRODUCTS=str(directory.parent),
                       GERBIL_COMPILE_ATTEMPT=str(outbox),GERBIL_COMPILE_REUSE='0')
        expression=('(import :gerbil/expander) (load '+json.dumps(str(obj))+') '
          +'((eval \'gxc#compile-product-module) '+json.dumps(str(source/'src/std/time/timeout.ss'))
          +' (lambda () ((eval \'gxc#compile-module) '+json.dumps(str(source/'src/std/time/timeout.ss'))
          +' [output-dir: '+json.dumps(str(smoke/'lib'))+' invoke-gsc: #t parallel: #f target: \'C]))) '
          +'(displayln "COMPILED-COMPILER-PROTOCOL-PASS")')
        try:
            output=ctx.require('compiler-driver-protocol',[str(source/'run.sh'),env_program,
                               'GAMBOPT='+ctx.env['GAMBOPT'],'gxi','-:p1','-e',expression],
                               source/'src',min(30,ctx.remaining()))
        finally:ctx.env.clear();ctx.env.update(bindings)
        modules=list(outbox.glob('*.module-completed.json'))
        if 'COMPILED-COMPILER-PROTOCOL-PASS'not in output or len(modules)!=1:
            raise ValueError('compiled service has no real module completion')
        value=json.loads(modules[0].read_text())
        if value[0]!=key or value[3]!='std/time/timeout' or not value[5]:
            raise ValueError('compiled service completion differs from its real input')
        record=dict(signature=signature,sourceProgram={str(driver):digest(driver),str(support):digest(support)},
                    outputs=outputs,object=str(obj),producer=producer,protocol=ctx.commands[-1],
                    protocolModule=value,runtimeAdmitted=False)
        from gambit_smp.research_kernel import retain_run_record
        journal=ctx.receipt['journal'];header=json.loads(Path(journal['path']).read_text())
        ref=retain_run_record(ctx.root,ctx.directory/'compiler-driver-observed.json',journal['scope'],
            dict(schema='gerbil-compiler-service-observation',header=journal,runId=header['runId'],service=record,runtimeAdmitted=False),header['inputs'])
        record.update(completion=ref,completionRun=str(Path(journal['path']).parent));write(manifest,record)
    else:record=previous
    datum=[key,_git_blob(driver),_git_blob(support),record['object'],_git_blob(record['object'])]
    ready.write_text(_scheme_product_data(datum)+'\n')
    return dict(reused=valid,object=record['object'],sourceProgram=record['sourceProgram'],
                completion=record['completion'],runtimeAdmitted=False)
