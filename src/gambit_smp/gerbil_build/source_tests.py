"""Gerbil build: source tests."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import shutil


def generation_control(ctx, source, runtime):
    """Exercise the actual helper, original job queue and real GSC consumer.

    Only the tiny emitter and first native-start failure are controlled seams.
    This lifecycle check does not replace actual Gerbil module acceptance.
    """
    from gambit_smp.gerbil_build.custody import AdmissionFiles
    from gambit_smp.gerbil_build.module_generations import prepare_generations, retain_generations
    from gambit_smp.workspace import write
    source, runtime = Path(source), Path(runtime)
    fixture = ctx.root/'tests/fixtures/module-generation.ss'
    ctx.bind([fixture])
    view = ctx.directory/'generation-control'
    unit = view/'source'
    src = unit/'src/std/unit.ss'
    scm = unit/'build/lib/std/unit.scm'
    interface = scm.with_suffix('.ssi')
    compiler = unit/'build/bin/gsc'
    for path in (src, scm, compiler):
        path.parent.mkdir(parents=True, exist_ok=True)
    src.write_text('(def answer 42)\n')
    compiler.symlink_to(runtime/'gsc/gsc')
    store = view/'products'
    (store/'modules').mkdir(parents=True)
    saved = dict(ctx.env)
    checks = []
    try:
        ctx.env.update(GERBIL_COMPILE_CONTEXT='generation-control', GERBIL_COMPILE_PRODUCTS=str(store),
            GERBIL_COMPILE_REUSE='0', GERBIL_GIT=str(ctx.tools['git']))
        for mode, marker in [('capture', 'GENERATION-CAPTURE-WITHHELD'),
                             ('resume', 'GENERATION-RESUME-PUBLISHED'),
                             ('source-guard', 'GENERATION-SOURCE-GUARD-WITHHELD')]:
            outbox = view/mode
            outbox.mkdir()
            ctx.env.update(GERBIL_COMPILE_ATTEMPT=str(outbox))
            arguments = [mode, str(source/'src/gerbil/compiler/driver.ss'), str(unit/'build'),
                         str(src), str(scm), str(interface), str(compiler)]
            expression = ('(import '+json.dumps(str(fixture), ensure_ascii=False)+') '
                          '(generation-control '+' '.join(json.dumps(x, ensure_ascii=False)
                                                          for x in arguments)+')')
            text = ctx.require('generation-'+mode,
                [str(source/'run.sh'), 'gxi', '-:p1', '-e', expression], unit/'src/std', 30)
            if marker not in text:
                raise ValueError('generation control omitted '+marker)
            prepared = ('generation-control', {'reuseAllowed': True}, store, outbox)
            producer = ctx.commands[-1]
            if mode == 'capture':
                retained = retain_generations(ctx, unit, prepared, producer)
                if retained['closed'] != ['std/unit'] or interface.exists():
                    raise ValueError('failed native start lost private generation ownership')
                admission = prepare_generations(ctx, unit, 'generation-control', store,
                    {}, AdmissionFiles(), {}, reuse_allowed=True)
                if admission['admitted'] != 1:
                    raise ValueError('closed generation was not admitted')
            else:
                used = retain_generations(ctx, unit, prepared, producer)
                if used['resumed'] != ['std/unit']:
                    raise ValueError('actual helper did not consume its continuation')
                if mode == 'source-guard' and 'module completion lacks stable source/identity' not in text:
                    raise ValueError('source guard control failed for a different reason')
            checks.append(dict(mode=mode, marker=marker, parentReaped=producer['parentReaped'],
                               processGroupQuiescent=producer['processGroupQuiescent']))
            if mode == 'resume':
                output = ctx.require('generation-native-consumer',
                    [str(runtime/'gsi/gsi'), '-:p1', '-f', str(scm.with_suffix('.o1'))], unit/'src/std', 30)
                if 'GENERATION-NATIVE-CONSUMER-PASS' not in output:
                    raise ValueError('generation native output was not consumed')
        result = dict(complete=True, checks=checks, realGscConsumer=True,
                      nativeFailureInjectedBeforeLaunch=True, publicInterfaceOnlyAfterNative=True,
                      sourceGuardAfterNativeBeforePublication=True, runtimeAdmitted=False,
                      scope='Actual helper lifecycle with a controlled emitter; not complete Gerbil or general macro/eval admission.')
        write(ctx.directory/'generation-control.json', result)
        return result
    finally:
        ctx.env.clear()
        ctx.env.update(saved)


def _test_source_check(profile,path,ctx):
    """Use the public MCP checkers through the existing Gerbil test owner."""
    from gambit_smp.native_capabilities import fields
    fields(profile,('kind','compilerHome','compilerSha256','packageRoot','source','phase'),('fixtures','module','loadPaths','cwd','initializeGambitSharp','invokeGsc','interfaceSource','bootstrapHome','consumerSource'))
    if profile['phase'] not in ('before','after','compile','module','syntax'):
        raise ValueError('explicit source-edit checkpoint required')
    if (profile['phase']=='compile') != ('fixtures' in profile):
        raise ValueError('compile check requires an explicit fixture source')
    if (profile['phase'] in ('module','syntax')) != ('loadPaths' in profile):
        raise ValueError('module observation requires an explicit logical load path')
    if (profile['phase'] in ('module','syntax')) != ('cwd' in profile):
        raise ValueError('module observation requires an explicit working directory')
    if type(profile.get('initializeGambitSharp',False)) is not bool or (
            'initializeGambitSharp' in profile and profile['phase'] not in ('module','syntax')):
        raise ValueError('Gambit bootstrap initialization is a module observation only')
    if type(profile.get('invokeGsc',False)) is not bool or (
            'invokeGsc' in profile and profile['phase']!='module'):
        raise ValueError('native module emission requires an explicit module observation')
    if 'interfaceSource' in profile and (profile['phase']!='module' or
            profile.get('module')!='gerbil/compiler/driver' or profile.get('invokeGsc') is not True):
        raise ValueError('official facade requires native driver emission')
    if 'bootstrapHome' in profile and profile['phase']!='syntax':
        raise ValueError('bootstrap source view is a syntax observation only')
    if 'consumerSource' in profile and (profile['phase']!='module' or profile.get('invokeGsc') is not True):
        raise ValueError('native source consumer requires completed module emission')
    namespace=profile.get('module','source-check')
    if not __import__('re').fullmatch(r'[A-Za-z_][A-Za-z0-9_./-]*',namespace):
        raise ValueError('literal official module name required')
    home=Path(profile['compilerHome']).resolve(strict=True)
    source=(ctx.root/profile['source']).resolve(strict=True)
    package=(ctx.root/profile['packageRoot']).resolve(strict=True)
    if digest(home/'bin/gerbil')!=profile['compilerSha256']:
        raise ValueError('source checker compiler identity drift')
    import os
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    store=ctx.root/'.cache/tasks'/task if task else None
    if store is None or not all(item.is_relative_to(store) for item in (source,package)):
        raise ValueError('source checking requires same-task read-only inputs')
    package_metadata=[]
    for parent in source.parents:
        if not parent.is_relative_to(store):break
        metadata=parent/'gerbil.pkg'
        if metadata.is_file():package_metadata.append(metadata)
    compiler_inputs=[item for name in ('bin','lib','include')
                     for item in (home/name).rglob('*') if item.is_file()]
    checker_inputs=[item for item in (package/'.gerbil/lib/gerbil-mcp').rglob('*') if item.is_file()]
    if not checker_inputs and profile['phase'] not in ('module','syntax'):raise ValueError('compiled MCP checker closure is missing')
    load_paths=[];load_inputs=[]
    if profile['phase'] in ('module','syntax'):
        module_cwd=(ctx.root/profile['cwd']).resolve(strict=True)
        if not module_cwd.is_relative_to(store) or not module_cwd.is_dir():
            raise ValueError('module working directory must belong to the same task')
        if not isinstance(profile['loadPaths'],list) or not profile['loadPaths']:
            raise ValueError('nonempty ordered load paths required')
        for item in profile['loadPaths']:
            directory=(ctx.root/item).resolve(strict=True)
            if not directory.is_relative_to(store) or not directory.is_dir():
                raise ValueError('module load path must belong to the same task')
            if ':' in str(directory):raise ValueError('unrepresentable logical load path')
            load_paths.append(directory)
            load_inputs.extend(p for p in directory.rglob('*') if p.is_file())
    interface=(ctx.root/profile['interfaceSource']).resolve(strict=True) if 'interfaceSource' in profile else None
    if interface is not None and (not interface.is_relative_to(store) or interface.name!='compiler.ss'):
        raise ValueError('same-task official facade source required')
    ctx.bind(list(dict.fromkeys([path,source,*([interface] if interface else []),*package_metadata,*compiler_inputs,*checker_inputs,*load_inputs])))
    consumer=(ctx.root/profile['consumerSource']).resolve(strict=True) if 'consumerSource' in profile else None
    if consumer is not None:
        if not consumer.is_relative_to(store):raise ValueError('same-task source consumer required')
        ctx.bind([consumer])
    saved=dict(ctx.env)
    ctx.env.update(GERBIL_HOME=str(home),GERBIL_PATH=str(package/'.gerbil'),
        GERBIL_LOADPATH=str(package/'.gerbil/lib'),
        GERBIL_MCP_GXI_PATH=str(home/'bin/gxi'),GERBIL_MCP_GXC_PATH=str(home/'bin/gxc'),
        PATH=str(home/'bin')+':/opt/homebrew/bin:/usr/bin:/bin',
        GAMBOPT=f'~~={home},~~bin={home}/bin,~~lib={home}/lib,~~include={home}/include')
    # Include the complete file in a real module; reading its first form would
    # silently omit most definitions and their macro context.
    code='(module '+namespace+' (include '+json.dumps(str(source))+'))'
    setup=('(import :gerbil-mcp/mcp/registry :gerbil-mcp/tools/check-balance '
           ':gerbil-mcp/tools/check-syntax) (register-check-balance!) '
           '(register-check-syntax!)')
    checks=[('gerbil_check_balance','(hash ("file_path" '+json.dumps(str(source))+'))')]
    if profile['phase']!='before':
        checks.append(('gerbil_check_syntax','(hash ("code" '+json.dumps(code)+'))'))
    if profile['phase'] in ('module','syntax'):checks=[]  # Read-only target-compiler observation, not an edit checkpoint.
    observations=[]
    try:
        if profile['phase'] in ('module','syntax'):
            ctx.env.update(GERBIL_LOADPATH=':'.join(map(str,load_paths)),
                GERBIL_BUILD_PREFIX=str(home),GERBIL_GSC=str(home/'bin/gsc'),
                GERBIL_PATH=str(ctx.directory/'module-package-path'),
                GERBIL_SOURCE=str(package/'src'),
                LD_LIBRARY_PATH=str(home/'lib'),DYLD_LIBRARY_PATH=str(home/'lib'),
                DYLD_FALLBACK_LIBRARY_PATH=str(home/'lib'))
            if profile['phase']=='syntax':
                # Explicit checkout-local fallback after an MCP environment
                # failure. Expand the complete source in its real macro context.
                launcher=package/'run.sh'
                if home != package/'build' or not launcher.is_file():
                    raise ValueError('syntax fallback requires the matching checkout build')
                ctx.bind([launcher])
                entry='gxi'
                if 'bootstrapHome' in profile:
                    bootstrap=(ctx.root/profile['bootstrapHome']).resolve(strict=True)
                    if bootstrap != package/'bootstrap' or not (bootstrap/'bin/boot-gxi').is_file():
                        raise ValueError('matching official bootstrap home required')
                    ctx.env.update(GERBIL_HOME=str(bootstrap),GERBIL_STAGE0=str(bootstrap),
                        GERBIL_GSI=str(bootstrap/'bin/gsi'))
                    entry=str(bootstrap/'bin/boot-gxi')
                    ctx.bind([p for p in bootstrap.rglob('*') if p.is_file()])
                search=('(set-load-path! \'('+ ' '.join(json.dumps(str(p)) for p in load_paths)+')) '
                        if 'bootstrapHome' in profile else
                        '(add-load-path! '+ ' '.join(json.dumps(str(p)) for p in load_paths)+') ')
                expression=(search+'(import :gerbil/compiler) '
                    '(eval \'(begin-foreign (include '+json.dumps(str(home/'lib/_gambit#.scm'))+'))) '
                    '(parameterize ((gx#current-compilation-target \'C)) '
                    '(gx#import-module '+json.dumps(str(source))+' #t #f)) '
                    '(displayln "CHECKOUT-SYNTAX-OK")')
                ctx.require('checkout-source-syntax',[str(launcher),entry,'-e',expression],package,180)
                if 'CHECKOUT-SYNTAX-OK' not in ctx.last_stdout.splitlines():
                    raise ValueError('checkout source expansion marker missing')
                observations.append(dict(tool='run.sh gxi / gx#import-module',
                    sourceSha256=digest(source),passed=True,scope='module expansion only'))
                output=ctx.directory/'source-checks.json'
                output.write_text(json.dumps(dict(source=str(source),phase='syntax',
                    checks=observations,compilerAdmitted=False,packageAdmitted=False),indent=2)+'\n')
                return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))
            output_dir=ctx.directory/'scheme';output_dir.mkdir()
            # One public driver entry for both controls; initialization is the
            # only variable. gxc-compile-file delegates to this same driver.
            initialization=('(eval \'(begin-foreign (include '+
                json.dumps(str(home/'lib/_gambit#.scm'))+'))) '
                if profile.get('initializeGambitSharp',False) else '')
            expression=('(import :gerbil/compiler) '+initialization+
                '(compile-module '+json.dumps(str(source))+
                ' (list invoke-gsc: '+('#t' if profile.get('invokeGsc',False) else '#f')+
                ' keep-scm: #t optimize: #t debug: #t '
                'generate-ssxi: #t target: \'C output-dir: '+json.dumps(str(output_dir))+'))')
            if interface is not None:
                expression+=('(compile-module '+json.dumps(str(interface))+
                    ' (list invoke-gsc: #t keep-scm: #t optimize: #t debug: #t '
                    'generate-ssxi: #t target: \'C output-dir: '+json.dumps(str(output_dir))+'))')
            argv=[str(home/'bin/gxi'),'-e',expression]
            tool=':gerbil/compiler compile-module'
            ctx.require('official-compiler-module',argv,module_cwd,180)
            if profile.get('invokeGsc',False) and not (output_dir/(namespace+'.o1')).is_file():
                raise ValueError('native module emission did not deliver its loader')
            if not (output_dir/(namespace+'.ssi')).is_file():
                raise ValueError('compiler output module differs from the declared namespace')
            if interface is not None and not all((output_dir/('gerbil/compiler'+ext)).is_file()
                                                 for ext in ('.ssi','.o1')):
                raise ValueError('official facade products missing')
            observations.append(dict(tool=tool,sourceSha256=digest(source),passed=True,
                scope='target module emission only; incomplete prefix is not compiler/package admission'))
            if consumer is not None:
                ctx.env['GERBIL_LOADPATH']=str(output_dir)+':'+ctx.env['GERBIL_LOADPATH']
                ctx.require('official-module-consumer',[home/'bin/gxi',consumer],module_cwd,60)
                if 'OFFICIAL-MODULE-CONSUMER-OK' not in ctx.last_stdout.splitlines():
                    raise ValueError('declared native module consumer did not complete')
                observations.append(dict(tool='declared native module consumer',sourceSha256=digest(source),
                    consumerSha256=digest(consumer),passed=True,scope='module behavior only; not package admission'))
        for name,argument in checks:
            expression=(setup+' (let (result (call-tool '+json.dumps(name)+' '+argument+')) '
                '(displayln (tool-result-text result)) (exit (if (tool-result-error? result) 1 0)))')
            ctx.require(name,[str(home/'bin/gxi'),'-e',expression],ctx.directory,60)
            observations.append(dict(tool=name,sourceSha256=digest(source),passed=True))
        if profile['phase']=='compile':
            fixtures=(ctx.root/profile['fixtures']).resolve(strict=True)
            files=[fixtures/name for name in ('gerbil.pkg','leaf.ss','consumer.ss')]
            check=fixtures/'check.ss'
            ctx.bind([*files,check])
            inputs=ctx.directory/'library-source';inputs.mkdir()
            for item in files:shutil.copy2(item,inputs/item.name)
            for phase,args in [('scheme',['-S','-s']),('native',[])]:
                output_dir=ctx.directory/phase;output_dir.mkdir()
                ctx.require('official-gxc-'+phase,[str(home/'bin/gxc'),*args,
                    '-d',str(output_dir),str(source)],ctx.directory,180)
                expected=[output_dir/(namespace+'.ssi')]
                if phase=='native':expected.append(output_dir/(namespace+'.o1'))
                if not all(item.is_file() for item in expected):
                    raise ValueError('compiler output module differs from the declared namespace')
            # Compile and load the changed official namespace, not an unrelated
            # host std/make implementation or a Python imitation of the graph.
            lib=ctx.directory/'library'
            ctx.env['GERBIL_LOADPATH']=str(lib)+':'+str(ctx.directory/'native')+':'+ctx.env['GERBIL_LOADPATH']
            ctx.require('official-make-library',[str(home/'bin/gxi'),str(check),str(inputs),str(ctx.directory)],
                        ctx.directory,180)
            if ('OFFICIAL-COMPILER-HANDOFF-OK' not in ctx.last_stdout.splitlines()
                    or 'GERBIL_LOADPATH cannot represent a path containing a colon' not in ctx.last_stdout
                    or 'Private compiler would add a disabled default load path' not in ctx.last_stdout):
                raise ValueError('official compiler consumer marker missing')
            observations.append(dict(tool='gxc / :std/make',sourceSha256=digest(source),passed=True,
                                     scope='two-module component, not stdlib or package admission'))
    finally:
        ctx.env.clear();ctx.env.update(saved)
    output=ctx.directory/'source-checks.json'
    output.write_text(json.dumps(dict(source=str(source),phase=profile['phase'],
        expectedModule=namespace,loadPaths=list(map(str,load_paths)),
        nativeModuleEmission=profile.get('invokeGsc',False),
        interfaceSource=str(interface) if interface is not None else None,
        compilerHome=str(home),packageRoot=str(package),
        moduleProducts=({str(p):digest(p) for p in output_dir.rglob('*') if p.is_file()}
                        if profile['phase']=='module' else {}),
        packageMetadata={str(p):digest(p) for p in package_metadata},
        checks=observations,compilerSha256=profile['compilerSha256'],
        checkerInputsSha256=hashlib.sha256(json.dumps({str(p.relative_to(package)):digest(p)
            for p in checker_inputs},sort_keys=True).encode()).hexdigest(),
        compilerAdmitted=False,packageAdmitted=False),indent=2)+'\n')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))


def check_compilation_resources(ctx, source):
    """Check the actual Make admission edges, including no false invalidation."""
    import os
    from gambit_smp.workspace import write
    start = '# BEGIN generated compilation resource admission.\n'
    end = '# END generated compilation resource admission.\n'
    blocks = []
    texts = [(source/name).read_text() for name in ('lib/makefile.in', 'gsc/makefile.in')]
    if not any(start in text for text in texts):
        return None
    for relative, variable in (('lib/makefile.in', 'MODULES_O_IN_COMPILE_ORDER'),
                               ('gsc/makefile.in', 'LIBRARY_OBJECTS_IN_COMPILE_ORDER')):
        text = (source/relative).read_text()
        if start not in text:
            raise ValueError('incomplete generated compilation admission')
        if (text.count(start) != 1 or text.count(end) != 1
                or 'gambit_generated_objects := $('+variable+')' not in text):
            raise ValueError('generated object resource inventory differs')
        blocks.append(text[text.index(start):text.index(end)+len(end)])
    if blocks[0] != blocks[1] or 'gsc-phase3: | lib-phase3' not in (source/'makefile.in').read_text():
        raise ValueError('generated compilation lanes are not composed')
    directory = ctx.directory/'compilation-resources'
    directory.mkdir()
    header = '.DEFAULT_GOAL := all\ngambit_generated_objects := a.o b.o c.o\nall: c.o b.o a.o normal.o\n'
    recipes = ('a.o:\n\t@echo a > a.o\n'
               'b.o:\n\t@test -f a.o\n\t@echo b > b.o\n'
               'c.o:\n\t@test -f b.o\n\t@echo c > c.o\n'
               'normal.o:\n\t@echo normal > normal.o\n')
    make = shutil.which('make', path=ctx.env['PATH'])
    if not make:
        raise ValueError('native Make resource control unavailable')
    ctx.bind([Path(make).resolve()])
    jobs = ctx.env['GERBIL_BUILD_CORES']
    for mode in ('darwin', 'linux'):
        view = directory/mode
        view.mkdir()
        (view/'makefile').write_text(header+blocks[0].replace('@target_os@', mode)+recipes)
        code, _, timeout, _ = ctx.run('compilation-resource-'+mode, [make, '-j'+jobs], view, 10)
        if timeout or (mode == 'darwin' and code != 0) or (mode == 'linux' and code == 0):
            raise ValueError('generated compilation resource positive/negative control failed')
        if mode == 'linux':
            if code != 2:
                raise ValueError('resource negative control did not fail at the expected Make boundary')
            ctx.commands[-1].update(negativeControl=True, expectedExit=2)
    view = directory/'darwin'
    # Make the predecessor newer without creating future timestamps.
    stamp = (view/'a.o').stat().st_mtime_ns
    for i, name in enumerate(('b.o', 'c.o'), 1):
        os.utime(view/name, ns=(stamp-i*1000000000, stamp-i*1000000000))
    before = {name: (view/name).stat().st_mtime_ns for name in ('b.o', 'c.o', 'normal.o')}
    ctx.require('compilation-resource-incremental', [make, '-j'+jobs], view, 10)
    (view/'a.o').unlink()
    ctx.require('compilation-resource-recreate', [make, '-j'+jobs], view, 10)
    if before != {name: (view/name).stat().st_mtime_ns for name in before}:
        raise ValueError('resource order introduced false native invalidation')
    result = dict(generatedLane='exclusive', jobserverCapacity=int(jobs),
        nativeMakeControlsPassed=True, incrementalInvalidation=False,
        memoryUpperBoundProved=False, packageReady=False)
    write(ctx.directory/'compilation-resources.json', result)
    return result



def tools_build_source(ctx, entry, retained, store):
    """Bind the official tools entry and its real source-check predecessor."""
    from gambit_smp.native_capabilities import fields
    fields(entry,('source','sha256','syntax','shellSource','shellSha256'))
    tools_build=(ctx.root/entry['source']).resolve(strict=True)
    shell=(ctx.root/entry['shellSource']).resolve(strict=True)
    checked=retained('tools-build-syntax','gerbil-test-observations',entry['syntax'])
    if (not all(p.is_relative_to(store) for p in (tools_build,shell)) or tools_build.name!='build.ss'
            or shell.name!='build.sh' or digest(tools_build)!=entry['sha256'] or digest(shell)!=entry['shellSha256']
            or checked.get('source')!=str(tools_build) or checked.get('phase') not in ('after','syntax')
            or not checked.get('checks') or any(c.get('passed') is not True or c.get('sourceSha256')!=digest(tools_build)
                                              for c in checked['checks'])):
        raise ValueError('matching tools product source/syntax required')
    ctx.bind([tools_build,shell])
    return tools_build,shell
