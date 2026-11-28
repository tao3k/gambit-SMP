"""Gerbil build: consumer tests."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json

from gambit_smp.gerbil_build.cli_tests import _test_cli_startup
from gambit_smp.gerbil_build.frame_tests import _test_gvm_host_layout
from gambit_smp.gerbil_build.package import execute_package, observe_runtime
from gambit_smp.gerbil_build.phase_tests import _test_compilation_phase
from gambit_smp.gerbil_build.policy import CI_ENVIRONMENT_KEYS
from gambit_smp.gerbil_build.source_tests import _test_source_check

def validate_test(args, inputs):
    from gambit_smp.native_capabilities import fields, reference
    if 'sourceLock' in args:
        fields(args,('sourceLock',),('stackSampleAfterSeconds','startupProbe','startupFirstLoad','startupExecutableTool','startupCompilerServices','startupPackageFailure'))
        if 'startupCompilerServices' in args and (args['startupCompilerServices'] is not True
                or args.get('startupProbe') is not True
                or args.get('startupFirstLoad') or args.get('startupExecutableTool')):
            raise ValueError('compiler service observations require exclusive diagnostic mode')
        if 'startupPackageFailure' in args and (args['startupPackageFailure'] is not True
                or args.get('startupProbe') is not True
                or any(key in args for key in ('startupFirstLoad','startupExecutableTool','startupCompilerServices','stackSampleAfterSeconds'))):
            raise ValueError('package failure observation requires exclusive diagnostic mode')
        delay=args.get('stackSampleAfterSeconds')
        if delay is not None and (type(delay) not in (int,float) or not 0<delay<=10):
            raise ValueError('bounded clean-entry stack observation required')
        if 'startupFirstLoad' in args and (args['startupFirstLoad'] is not True or args.get('startupProbe') is not True):
            raise ValueError('first-load debugger is a diagnostic probe only')
        if 'startupExecutableTool' in args and (args['startupExecutableTool'] is not True
                or args.get('startupProbe') is not True or args.get('startupFirstLoad') is True):
            raise ValueError('executable construction requires its exclusive diagnostic probe')
        if 'startupProbe' in args and args['startupProbe'] is not True:
            raise ValueError('startup probe must be explicitly diagnostic')
        if args['sourceLock'] not in inputs:
            raise ValueError('installed reference must have a declared source profile')
        return
    fields(args, ('build',), ('packages','phaseFixture','makeSource','checkerProfile'));reference(args['build'])
    phase_fields={'phaseFixture','makeSource','checkerProfile'}
    if phase_fields & args.keys():
        if not phase_fields <= args.keys() or 'packages' in args:
            raise ValueError('phase validation requires its complete source and checker inputs')
        for key in ('phaseFixture','checkerProfile'):
            if args[key] not in inputs:
                raise ValueError('declared phase validation input required: '+key)
    if 'packages' in args and args['packages'] is not True:
        raise ValueError('package acceptance requires both original packages')


def test(args, ctx):
    """The upstream default recursive gxtest selection, over the actual build."""
    from gambit_smp.recipes import read_json, tree_identity
    from gambit_smp.workspace import task_output, checkpoint_build_source
    if ctx.receipt.get('workspacePolicy') != 'in-place':
        raise ValueError('Gerbil tests require the managed build workspace')
    if 'sourceLock' in args:
        return _test_installed_reference(args,ctx)
    proof = read_json(ctx.artifact(args['build'],'gerbil-build-observations'))
    if 'phaseFixture' in args:
        return _test_compilation_phase(args,proof,ctx)
    if args.get('packages') is True:
        return _test_completed_packages(proof,ctx)
    if proof.get('throughStage') != 'tools' or proof.get('toolsReady') is not True:
        raise ValueError('full upstream tests require completed tools, not a compiler-core query')
    source = Path(proof['workspace']).resolve(strict=True)
    from gambit_smp.artifact_storage import fixture_root
    fixture_root(ctx.root,source)
    if task_output(ctx.root,source) != source:
        raise ValueError('Gerbil test workspace belongs to another owner')
    current = tree_identity(source)
    if (hashlib.sha256(json.dumps(current,sort_keys=True).encode()).hexdigest() != proof.get('workspaceIdentitySha256')
            or digest(source.parent/'configuration.json') != proof.get('configurationSha256')
            or digest(source/'build/bin/gerbil') != proof['executableSha256']):
        raise ValueError('Gerbil build changed before its full test selection')
    ctx.lease_workspace(source,current)
    files = sorted(str(path.relative_to(source/'src')) for path in (source/'src').rglob('*-test.ss') if path.is_file())
    if not files:raise ValueError('full Gerbil source test inventory is empty')
    def payloads():
        if any(digest(source/name) != sha for name,sha in proof['runtimePayloads'].items()):
            raise ValueError('same-producer Gambit payload changed during Gerbil tests')
    payloads()
    ctx.env.update(GERBIL_PREFIX=str(source.parent/'prefix'),GERBIL_HOME=str(source/'build'),
                   GERBIL_PATH=str(source.parent/'user'))
    observation=dict(testFiles=files,workspace=str(source),outcome='PENDING',runtimeAdmitted=False)
    output=ctx.directory/'gerbil-tests.json'
    output.write_text(json.dumps(observation,indent=2)+'\n')
    code,log,timeout,seconds=ctx.run('gerbil-tests',
        [ctx.tools['sh'],'./build.sh','env','gxtest','./...'],source/'src',ctx.remaining())
    completed = (code == 0 and not timeout and ctx.last_stdout.rstrip().splitlines()[-1:] == ['OK']
                 and ctx.commands[-1].get('parentReaped') is True
                 and ctx.commands[-1].get('processGroupQuiescent') is True)
    observation.update(exit=code,timeout=timeout,seconds=seconds,
        parentReaped=ctx.commands[-1].get('parentReaped'),
        processGroupQuiescent=ctx.commands[-1].get('processGroupQuiescent'),
        outcome='PASS' if completed else 'DENY')
    output.write_text(json.dumps(observation,indent=2)+'\n')
    payloads()
    if (observation['outcome'] != 'PASS' or observation['parentReaped'] is not True
            or observation['processGroupQuiescent'] is not True):
        raise ValueError('full upstream Gerbil tests did not complete successfully; see actual streams')
    checkpoint_build_source(source,phase='ready')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output),observation=observation)


def _test_completed_packages(proof,ctx,*,diagnostic_after_seconds=None):
    """Consume one completed compiler image through the shared original package executor."""
    if proof.get('constructionPassed') is not True or proof.get('packageReady') is not True:
        raise ValueError('both packages require completed CI compiler construction')
    environment=proof.get('packageEnvironment')
    if (not isinstance(environment,dict) or set(environment)!=CI_ENVIRONMENT_KEYS
            or any(type(value) is not str for value in environment.values())):
        raise ValueError('completed compiler lacks its closed package environment; refuse guessed PATH')
    saved=dict(ctx.env)
    results = {}
    try:
        ctx.env.update(environment)
        for kind in ('mcp', 'poo'):
            results[kind] = execute_package(ctx, Path(proof['compilerHome']),
                Path(proof['packageSources'][kind]), kind=kind, budgets=proof['packageBudgets'],
                diagnostic_after_seconds=diagnostic_after_seconds)
    finally:
        ctx.env.clear();ctx.env.update(saved)
    output = ctx.directory/'package-results.json'
    passed = all(row.get('wholePackagePassed') is True for row in results.values())
    output.write_text(json.dumps(dict(packages=results, bothPackagesPassed=passed,
        packageSpeedup=None, mergeAllowed=False), indent=2)+'\n')
    if not passed:
        raise ValueError('original MCP/POO clean/build/tests did not both pass')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))


def _test_installed_reference(args,ctx):
    """Use the same package executor for an explicitly identified host control.

    This never manufactures a source-build or target-compiler receipt.
    """
    from gambit_smp.recipes import source_path,read_json
    from gambit_smp.native_capabilities import fields
    path=source_path(ctx.root,args['sourceLock']);profile=read_json(path)
    if profile.get('kind')=='gerbil-phase-check':
        package_mode=profile.get('packages') is True
        if package_mode:fields(profile,('kind','compiler','packages'))
        else:fields(profile,('kind','compiler','phaseFixture','makeSource','checkerProfile'),('environmentProfile',))
        from gambit_smp.recipes import artifact_path
        descriptor=profile['compiler']
        if descriptor.get('type') not in ('gerbil-build-observations','gerbil-test-observations') or 'origin' not in descriptor:
            raise ValueError('phase check requires a committed typed compiler artifact')
        proof_path=artifact_path(ctx.directory,descriptor,root=ctx.root)
        if digest(proof_path)!=descriptor.get('sha256'):
            raise ValueError('retained core observation drift')
        ctx.bind([path,proof_path])
        from gambit_smp.reasoning_history import read_execution_checkpoint
        origin=descriptor['origin']
        producer=(ctx.root/origin['run']).resolve(strict=True)
        original=[r['payload']['step'] for r in read_execution_checkpoint(ctx.root,producer)['records']
                  if r['payload'].get('schema')=='research-step-observation.v1'
                  and r['payload']['step']['id']==origin['step']]
        if len(original)!=1:raise ValueError('one committed compiler producer required')
        proof=read_json(proof_path)
        if package_mode:
            if descriptor['type']!='gerbil-build-observations' or original[0].get('outcome')!='PASS':
                raise ValueError('package phase requires its passed source compiler producer')
            return _test_completed_packages(proof,ctx,diagnostic_after_seconds=args.get('stackSampleAfterSeconds'))
        proof['producerInputBindings']=original[0].get('observedInputs',{})
        return _test_compilation_phase(profile,proof,ctx)
    if profile.get('kind')=='gerbil-cli-startup-check':
        return _test_cli_startup(profile,path,ctx,
            diagnostic_after_seconds=args.get('stackSampleAfterSeconds'))
    if profile.get('kind')=='gerbil-source-check':
        return _test_source_check(profile,path,ctx)
    if profile.get('kind')=='gerbil-gvm-host-check':
        return _test_gvm_host_layout(profile,path,ctx)
    path_reference=profile.get('pathReference') is True
    if path_reference:
        fields(profile,('kind','pathReference','packageSources','packageBudgets'),('environment',))
        if args.get('startupProbe') and not args.get('startupCompilerServices'):
            raise ValueError('current-PATH reference is an original package control only')
    else:
        fields(profile,('kind','compilerHome','compilerSha256','packageSources','packageBudgets'),('environment','qualification','failedRun'))
    if (profile['kind']!='installed-gerbil-reference'
            or set(profile['packageSources'])!={'mcp','poo'}
            or profile['packageBudgets']!=dict(clean=30,build=300,test=300)):
        raise ValueError('complete installed package control with unchanged budgets required')
    launchers={}
    path_identity=None
    if path_reference:
        import shutil
        environment=profile.get('environment',{})
        if (not isinstance(environment,dict)
                or set(environment)-(CI_ENVIRONMENT_KEYS|{'COMPILER_PATH','LIBRARY_PATH'})
                or any(type(value) is not str for value in environment.values())):
            raise ValueError('closed current-PATH reference environment required')
        search=environment.get('PATH',ctx.env.get('PATH',''))
        for name in ('gerbil','gxi','gxc'):
            entry=shutil.which(name,path=search)
            if entry is None:raise ValueError('current-PATH Gerbil launcher missing: '+name)
            target=Path(entry).resolve(strict=True)
            launchers[name]=dict(path=entry,resolved=str(target),sha256=digest(target))
        ctx.bind([path,*[Path(row['resolved']) for row in launchers.values()]])
        identity=ctx.directory/'current-path-runtime.json'
        saved=dict(ctx.env)
        try:
            ctx.env.update(environment)
            path_identity=observe_runtime(ctx,launchers['gxi']['path'],identity,
                stage='current-path-runtime-identity')
        finally:
            ctx.env.clear();ctx.env.update(saved)
        home=Path(path_identity['home']).resolve(strict=True)
        if Path(path_identity['bin']).resolve(strict=True)!=home/'bin':
            raise ValueError('launcher runtime home/bin identity mismatch')
        # Read the selected runtime's own home; PATH gsc can be Ghostscript.
        profile={**profile,'compilerHome':str(home),'compilerSha256':digest(home/'bin/gerbil')}
    else:
        home=Path(profile['compilerHome']).resolve(strict=True)
    if digest(home/'bin/gerbil')!=profile['compilerSha256']:
        raise ValueError('installed reference compiler identity drift')
    ctx.bind([path,home/'bin/gerbil'])
    qualification=profile.get('qualification')
    if qualification is not None:
        from gambit_smp.recipes import artifact_path,tree_identity
        if qualification.get('type')!='gerbil-test-observations' or 'origin' not in qualification:
            raise ValueError('committed CLI qualification required')
        qualified_path=artifact_path(ctx.directory,qualification,root=ctx.root)
        if digest(qualified_path)!=qualification.get('sha256'):
            raise ValueError('CLI qualification receipt drift')
        qualified=read_json(qualified_path)
        if (qualified.get('phasePassed') is not True or qualified.get('diagnosticOnly') is True
                or qualified.get('compilerHome')!=str(home)
                or qualified.get('compilerSha256')!=profile['compilerSha256']):
            raise ValueError('CLI qualification does not match installed compiler')
        roles=('runtimeWithoutCore','runtimeAbsentSearchRoot','runtime-executable-rejection','unsupported-interface-fallback',
                     'shadow-provider-fallback','optionalBindings','interpreter','compiler',
                     'executor','executor-single-permit','coldLibrary','coldLibraryConsumer',
                     'objectClosure','objectClosureConsumer','object-closure-rejection',
                     'sharedRuntimeObjects','sharedFirst','sharedSecond')
        if 'gxtest' in qualified.get('toolSourceSha256',{}) or 'gxtest' in qualified.get('nativeToolProducts',{}):
            roles+=('embeddedTest','embedded-test-rejection')
        # Shell syntax is a constructor witness enforced by
        # retained_cli_constructor; the unchanged tree is checked below.
        # These roles are fresh behavioral controls, never replayed ones.
        for role in roles:
            command=qualified.get('stages',{}).get(role,{})
            negative=role in ('runtime-executable-rejection','unsupported-interface-fallback','shadow-provider-fallback','object-closure-rejection','embedded-test-rejection')
            expected_exit=command.get('expectedExit') if negative else 0
            allowed_negative=(42,) if role=='embedded-test-rejection' else (1,70)
            if (command.get('timeout') is not False or command.get('exit')!=expected_exit
                    or (negative and (expected_exit not in allowed_negative or command.get('negativeControl') is not True))
                    or any(command.get(key) is not True for key in ('parentReaped','processGroupQuiescent'))):
                raise ValueError('required managed CLI control missing: '+role)
        if qualified['stages']['runtimeWithoutCore'].get('argv')!=[str(home/'bin/gerbil'),'help','clean']:
            raise ValueError('CLI qualification did not exercise the literal command')
        if str(qualified.get('buildCores'))!=profile.get('environment',{}).get('GERBIL_BUILD_CORES'):
            raise ValueError('qualified compiler build capacity differs from package profile')
        identity=hashlib.sha256(json.dumps(tree_identity(home.parent),sort_keys=True).encode()).hexdigest()
        if identity!=qualified.get('sourceTreeSha256'):
            raise ValueError('qualified compiler tree changed')
        ctx.bind([qualified_path])
    environment=profile.get('environment',{})
    if (not isinstance(environment,dict) or set(environment)-(CI_ENVIRONMENT_KEYS|{'COMPILER_PATH','LIBRARY_PATH'})
            or any(type(v) is not str for v in environment.values())):
        raise ValueError('closed installed reference build environment required')
    if args.get('startupPackageFailure') is True:
        from gambit_smp.gerbil_build.package import observe_package_failure
        return observe_package_failure(ctx,profile,home)
    if 'failedRun' in profile:raise ValueError('failed run belongs to diagnostic mode only')
    if args.get('startupCompilerServices'):
        from gambit_smp.gerbil_build.package import observe_compiler_services
        return observe_compiler_services(ctx, profile, home, launchers, path_identity)
    if args.get('startupProbe') is True:
        # A fixed read-only discriminator for a byte-identified candidate.
        # It cannot start a package build or publish a target compiler.
        saved=dict(ctx.env)
        rows={}
        if args.get('startupExecutableTool') is True:
            if args.get('startupFirstLoad') is True:
                raise ValueError('static construction and debugger observation are distinct controls')
            from gambit_smp.artifact_storage import transfer_tree
            from gambit_smp.workspace import build_output
            from gambit_smp.recipes import tree_identity
            original=home.parent
            if not (original/'src/tools/gxpkg.ss').is_file():
                raise ValueError('same-source package manager producer required')
            before=tree_identity(original)
            view=build_output(ctx.root,'gerbil',compiler=ctx.tools['gcc'],
                flags=['official-executable-gxpkg',profile['compilerSha256'],str(ctx.directory)])/'source'
            transfer_tree(original,view)
            ctx.lease_workspace(view,tree_identity(view))
            home=view/'build'
            ctx.bind([original/'src/tools/gxpkg.ss'])
        try:
            ctx.env.update(environment)
            ctx.env.update(GERBIL_HOME=str(home),GERBIL_BUILD_PREFIX=str(home),
                GERBIL_LOADPATH=str(home/'lib'),GERBIL_PATH=str(ctx.directory/'user'),
                PATH=str(home/'bin')+':'+ctx.env['PATH'],
                GAMBOPT=f'~~bin={home}/bin,~~lib={home}/lib,~~include={home}/include')
            expression=("(write (gerbil-home)) (newline) "
                "(write (gx#core-resolve-library-module-path ':gerbil/tools/gxpkg)) (newline) "
                "(write (__find-library-module \"gerbil/tools/gxpkg\")) (newline) "
                "(write ((##global-var-ref (##make-global-var 'gerbil/main#compiled-tool-main)) "
                "':gerbil/tools/gxpkg)) (newline)")
            probes=[('runtime-version',[str(home/'bin/gerbil'),'--version'],10),
                    ('actual-binding-projection',[str(home/'bin/gxi'),'-e',expression],60),
                    ('runtime-help',[str(home/'bin/gerbil'),'help','clean'],30)]
            if args.get('startupExecutableTool') is True:
                ctx.env.update(GERBIL_SOURCE=str(view/'src'),GERBIL_PREFIX=str(home),
                    GERBIL_GSC=str(home/'bin/gsc'),GERBIL_GCC=str(ctx.tools['gcc']))
                product=ctx.directory/'gxpkg'
                code,_,timeout,_=ctx.run('official-executable-gxpkg-build',
                    [str(home/'bin/gxc'),'-O','-exe','-o',str(product),
                     str(view/'src/tools/gxpkg.ss')],view/'src',180)
                rows['executable-build']=dict(ctx.commands[-1],stdout=ctx.last_stdout,stderr=ctx.last_stderr)
                if timeout or code or not product.is_file():
                    raise ValueError('official gxpkg executable construction did not complete')
                if tree_identity(original)!=before:
                    raise ValueError('diagnostic static construction changed the retained source')
                probes=[('executable-runtime-help',[str(product),'help','clean'],30)]
            if args.get('startupFirstLoad') is True:
                import platform
                resolver=Path('/usr/bin/xcrun');ctx.bind([resolver])
                debugger=Path(ctx.require('startup-debugger-path',
                    [str(resolver),'--find','lldb'],ctx.root,10).strip()).resolve(strict=True)
                ctx.bind([debugger])
                register='x0' if platform.machine()=='arm64' else 'rdi'
                commands=['breakpoint set --name ___dynamic_load','run',
                    'breakpoint disable 1','process handle SIGALRM --stop false --notify false --pass true',
                    'breakpoint set --name dlopen','continue']
                # Fixed event count and original30s observation budget. Return
                # stops are raw evidence, never startup or timing admission.
                for index in range(32):
                    commands += ['memory read --format s --count 1 $'+register,
                        'breakpoint disable 2','thread step-out',
                        'register read '+register,'frame info','breakpoint enable 2']
                    if index<31:commands.append('continue')
                commands += ['breakpoint disable 2','script import threading; probe_process=lldb.debugger.GetSelectedTarget().GetProcess(); probe_timer=threading.Timer(5.0, probe_process.SendAsyncInterrupt); probe_timer.start()',
                    'continue','script probe_timer.cancel()','thread backtrace all','process kill']
                probes=[('first-dynamic-load',[str(debugger),'--batch',
                    *[item for command in commands for item in ('-o',command)],
                    '-k','thread backtrace all','-k','register read x0 x1 x2',
                    '-k','process kill','--',str(home/'bin/gerbil'),'help','clean'],30)]
            for role,argv,cap in probes:
                code,_,timeout,seconds=ctx.run(role,argv,ctx.directory,cap)
                rows[role]=dict(ctx.commands[-1],stdout=ctx.last_stdout,stderr=ctx.last_stderr)
        finally:
            ctx.env.clear();ctx.env.update(saved)
        output=ctx.directory/'startup-probe.json'
        output.write_text(json.dumps(dict(compilerHome=str(home),compilerSha256=digest(home/'bin/gerbil'),
            observations=rows,diagnosticOnly=True,targetCompilerAdmitted=False,
            wholePackagePassed=False,packageSpeedup=None),indent=2)+'\n')
        return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))
    delay=args.get('stackSampleAfterSeconds')
    if delay is not None and (type(delay) not in (int,float) or not 0<delay<=10):
        raise ValueError('bounded clean-entry stack observation required')
    saved=dict(ctx.env) if environment else None
    if environment:ctx.env.update(environment)
    try:
        results={kind:execute_package(ctx,home,(ctx.root/name).resolve(strict=True),
                    kind=kind,budgets=profile['packageBudgets'],diagnostic_after_seconds=delay,
                    launchers=launchers,expected_smp=False if qualification is not None else None,
                    runtime_home=path_identity['home'] if path_identity is not None else None)
                 for kind,name in profile['packageSources'].items()}
    finally:
        if saved is not None:ctx.env.clear();ctx.env.update(saved)
    result=dict(compilerOrigin='installed-reference',compilerHome=str(home),
        compilerSha256=profile['compilerSha256'],packages=results,
        bothPackagesPassed=all(row.get('wholePackagePassed') is True for row in results.values()),
        targetCompilerAdmitted=False,packageSpeedup=None,mergeAllowed=False,
        cliQualification=qualification,managedCliQualified=qualification is not None,
        pathLaunchers=launchers,pathRuntimeIdentity=path_identity)
    output=ctx.directory/'package-results.json';output.write_text(json.dumps(result,indent=2)+'\n')
    if not result['bothPackagesPassed']:
        raise ValueError('original installed-reference package controls did not both pass')
    return dict(outputs=ctx.publish('observations','gerbil-test-observations',output))
