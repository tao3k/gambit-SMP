"""Gerbil build: phase tests."""

from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import json
import shutil

from gambit_smp.gerbil_build.custody import _current, _is_native_product
from gambit_smp.gerbil_build.policy import CI_ENVIRONMENT_KEYS
from gambit_smp.gerbil_build.source_tests import _test_source_check

def _test_compilation_phase(args,proof,ctx):
    """Validate the changed make against an actual same-source stage1 driver."""
    from gambit_smp.recipes import read_json, tree_identity
    bootstrap_mode=(proof.get('nativeModuleEmission') is True and
                    proof.get('expectedModule')=='gerbil/compiler/driver' and
                    proof.get('interfaceSource') is not None)
    libraries=[]
    if bootstrap_mode:
        source=Path(proof['packageRoot']).resolve(strict=True)
        home=Path(proof['compilerHome']).resolve(strict=True)
        products=proof.get('moduleProducts',{})
        if not products or any(not Path(p).is_file() or digest(Path(p))!=sha
                               for p,sha in products.items()):
            raise ValueError('native driver interface output drift')
        candidates=[Path(p) for p in products if p.endswith('/gerbil/compiler/driver.ssi')]
        if len(candidates)!=1:raise ValueError('one official driver interface required')
        library=candidates[0].parents[2]
        if not all(str(library/name) in products for name in (
                'gerbil/compiler/driver.ssi','gerbil/compiler/driver.o1',
                'gerbil/compiler.ssi','gerbil/compiler.o1')):
            raise ValueError('official compiler facade closure is incomplete')
        bindings={p:sha for p,sha in proof.get('producerInputBindings',{}).items()
                  if Path(p).is_relative_to(home)}
        if not bindings or any(not Path(p).is_file() or digest(Path(p))!=sha
                               for p,sha in bindings.items()):
            raise ValueError('native compiler ABI input drift')
        ctx.bind(list(map(Path,bindings)))
        # Stage0 has executable bootstrap modules but not the full stage1 SSI
        # graph. Admit only the completed gerbil core subtree, never the failed
        # stdlib's unrelated SSI/SCM files at the same prefix.
        core_view=ctx.directory/'core-library';core_view.mkdir()
        (core_view/'gerbil').symlink_to(home/'lib/gerbil',target_is_directory=True)
        libraries=[library,core_view]
        ctx.bind(list(map(Path,products)))
    else:
        if (proof.get('compilerCoreReady') is not True or
                proof.get('phaseConstructionPassed') is not True or
                proof.get('throughStage')!='stage1' or proof.get('packageReady') is not False):
            raise ValueError('phase validation requires a completed scoped CI core')
        source=Path(proof['source']).resolve(strict=True)
        home=Path(proof['compilerHome']).resolve(strict=True)
        ledger_path=Path(proof['stages']['build']['progressArtifact']).resolve(strict=True)
        if digest(ledger_path)!=proof['stages']['build']['progressSha256']:
            raise ValueError('completed core stage ledger drift')
        ledger=read_json(ledger_path)
        core=ledger.get('products',{}).get('stage1',{})
        if (ledger.get('throughStage')!='stage1' or
                not _current(source,core,core.get('inputsSha256'),stage='stage1',root=ctx.root)):
            raise ValueError('completed core output identity or custody drift')
        ctx.bind([ledger_path])
    if home != source/'build':raise ValueError('phase compiler differs from its owned checkout')
    make=(ctx.root/args['makeSource']).resolve(strict=True)
    fixture=(ctx.root/args['phaseFixture']).resolve(strict=True)
    checker_path=(ctx.root/args['checkerProfile']).resolve(strict=True)
    checker=read_json(checker_path)
    checker.update(source=str(make),phase='before')
    # MCP checks structure in its original ABI; no old compiler exports are used.
    _test_source_check(checker,checker_path,ctx)
    shutil.copy2(ctx.directory/'source-checks.json',ctx.directory/'mcp-balance-check.json')
    profile=dict(kind='gerbil-source-check',compilerHome=str(home),
        compilerSha256=digest(home/'bin/gerbil'),packageRoot=str(source),
        source=str(make),module='std/make',phase='syntax',
        loadPaths=[*map(str,libraries),str(home/'lib'),str(source/'src')],cwd=str(source))
    if bootstrap_mode:
        profile.update(bootstrapHome=str(source/'bootstrap'),
            loadPaths=[*map(str,libraries),str(source/'bootstrap/lib'),str(source/'src')])
    _test_source_check(profile,checker_path,ctx)
    ctx.bind([make,fixture,*[fixture.parent/name for name in ('leaf.ss','consumer.ss','gerbil.pkg')]])
    private=ctx.directory/'phase-inputs';private.mkdir()
    for name in ('leaf.ss','consumer.ss','gerbil.pkg'):
        shutil.copy2(fixture.parent/name,private/name)
    # Match stock std/build.ss source bootstrap. Optimized native make needs
    # its stdlib SSXI dependency closure; constructing it before those providers
    # is not an admissible bootstrap step. Full stdlib owns that later check.
    support=ctx.directory/'make-source';(support/'std').mkdir(parents=True)
    shutil.copy2(make,support/'std/make.ss')
    shutil.copy2(make.parent/'gerbil.pkg',support/'std/gerbil.pkg')
    ctx.bind([make.parent/'gerbil.pkg'])
    saved=dict(ctx.env)
    environment=proof.get('packageEnvironment')
    if bootstrap_mode:
        environment_path=(ctx.root/args['environmentProfile']).resolve(strict=True)
        environment=read_json(environment_path)['environment']
        ctx.bind([environment_path])
    if not isinstance(environment,dict) or set(environment)!=CI_ENVIRONMENT_KEYS:
        raise ValueError('scoped compiler lacks its closed construction environment')
    try:
        ctx.env.update(environment)
        ctx.env.update(GERBIL_HOME=str(home),GERBIL_BUILD_PREFIX=str(home),
            GERBIL_SOURCE=str(source/'src'),GERBIL_PATH=str(ctx.directory/'user'),
            GERBIL_GSC=str(home/'bin/gsc'),GERBIL_GCC=str(ctx.tools['gcc']),
            GERBIL_LOADPATH=str(support)+':'+str(home/'lib')+':'+str(source/'src'),
            PATH=str(home/'bin')+':'+ctx.env['PATH'],
            GAMBOPT=f'~~bin={home}/bin,~~lib={home}/lib,~~include={home}/include',
            DYLD_LIBRARY_PATH=str(home/'lib'),LD_LIBRARY_PATH=str(home/'lib'),
            DYLD_FALLBACK_LIBRARY_PATH=str(home/'lib'))
        if bootstrap_mode:
            bootstrap=source/'bootstrap'
            private_bin=ctx.directory/'bootstrap-bin';private_bin.mkdir()
            for name,target in [('gxi',bootstrap/'bin/boot-gxi'),('gxc',bootstrap/'bin/boot-gxi'),
                                ('gsc',home/'bin/gsc'),('gambuild-C',home/'bin/gambuild-C')]:
                (private_bin/name).symlink_to(target)
            # Executable aliases reuse the official bootstrap shim; no wrapper
            # script or builtin-registry mutation is introduced.
            ctx.env.update(GERBIL_HOME=str(bootstrap),GERBIL_STAGE0=str(bootstrap),
                GERBIL_GSI=str(bootstrap/'bin/gsi'),GERBIL_GXC=str(private_bin/'gxc'),
                GAMBOPT=f'~~bin={private_bin},~~lib={home}/lib,~~include={home}/include',
                GERBIL_LOADPATH=':'.join(map(str,[support,*libraries,bootstrap/'lib',source/'src'])))
            ctx.bind([p for p in bootstrap.rglob('*') if p.is_file()])
            entry=str(private_bin/'gxi')
        else:
            entry=str(home/'bin/gxi')
        output=ctx.directory/'phase-output';output.mkdir()
        # Exercise the real stdlib entry before a full build. The deliberately
        # missing srcdir must reach make-settings, not fail keyword dispatch at
        # build-std. No native product is expected from this negative control.
        stdlib_entry=make.parent/'build-std.ss'
        if not stdlib_entry.is_file():raise ValueError('actual stdlib entry source is missing')
        ctx.bind([p for p in make.parent.rglob('*') if p.is_file() and p.suffix in ('.ss','.scm')])
        expression=('(gx#import-module '+json.dumps(str(stdlib_entry))+' #t #t) '
            '(eval \'(std/build-std#build srcdir: #f libdir: '+json.dumps(str(output))+
            ' debug: #t target: \'C))')
        code,text,timeout,_=ctx.run('stdlib-entry-argument-control',
            [entry,'-e',expression],source/'src/std',30)
        negative=ctx.commands[-1]
        if (code!=70 or timeout or 'srcdir must be specified' not in text
                or 'Unexpected keyword argument' in text
                or any(negative.get(k) is not True for k in ('parentReaped','processGroupQuiescent'))):
            raise ValueError('stdlib entry did not preserve keyword forwarding to make-settings')
        negative.update(expectedExit=70,negativeControl=True)
        markers={'build':'OFFICIAL-PHASE-BUILD-OK','controls':'OFFICIAL-PHASE-NEGATIVE-OK 6',
                 'consume':'OFFICIAL-PHASE-CONSUMER-OK'}
        snapshots={}
        for mode in ('build','controls','consume'):
            before=tree_identity(output) if mode=='controls' else None
            argv=[entry,str(fixture),mode,str(private),str(output)]
            if bootstrap_mode:
                expression=('(eval \'(begin-foreign (include '+json.dumps(str(home/'lib/_gambit#.scm'))+'))) '
                    '(parameterize ((gx#current-compilation-target \'C)) '
                    '(load '+json.dumps(str(fixture))+') '
                    '(eval \'(main '+json.dumps(mode)+' '+json.dumps(str(private))+' '+json.dumps(str(output))+')))')
                argv=[entry,'-e',expression]
            ctx.require('official-phase-'+mode,argv,source,240)
            if markers[mode] not in ctx.last_stdout.splitlines():
                raise ValueError('actual phase control marker missing: '+mode)
            if mode=='controls' and tree_identity(output)!=before:
                # Expected negative files are retained, but they may not alter
                # any previously delivered file or create another native image.
                after=tree_identity(output)
                if any(after.get(k)!=v for k,v in before.items()) or any(
                        _is_native_product(k) for k in after.keys()-before.keys()):
                    raise ValueError('negative handoff changed native products')
            snapshots[mode]=dict(marker=markers[mode],command=ctx.commands[-1])
        observation=ctx.directory/'phase-validation.json'
        observation.write_text(json.dumps(dict(phasePassed=True,compilerCoreReady=not bootstrap_mode,
            entryKind='official-bootstrap' if bootstrap_mode else 'stage1-bach',
            entryPath=entry,entrySha256=digest(Path(entry).resolve(strict=True)),
            makeSourceExecuted=True,makeNativeAdmitted=False,
            makeSourceSha256=digest(make),compilerSha256=digest(home/'bin/gerbil'),
            controls=snapshots,stdlibEntryArgumentControl=negative,packageReady=False,bothPackagesPassed=False,
            packageSpeedup=None,mergeAllowed=False),indent=2)+'\n')
        return dict(outputs=ctx.publish('observations','gerbil-test-observations',observation))
    finally:
        ctx.env.clear();ctx.env.update(saved)
