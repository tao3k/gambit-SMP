"""Native-stage requests consume an explicit completed generation artifact.

This is not a freshness issuer for arbitrary effectful Scheme compilation.
Compiler-service upgrades and changed Scheme inputs require a generation demand.
"""
from pathlib import Path
import json
import shutil
import re
import hashlib
import time
from gambit_smp.framework import digest

NATIVE_ASSIGNMENTS=frozenset(('C_COMPILER','C_PREPROC','FLAGS_OBJ','FLAGS_DYN','FLAGS_LIB',
    'FLAGS_EXE','FLAGS_OPT','FLAGS_OPT_RTS','DEFS','DEFS_OBJ','DEFS_DYN','DEFS_LIB','DEFS_EXE',
    'GAMBITLIB_DEFS','LIBS'))


def native_assignment(line):
    m=re.match(r'^([A-Z_]+)\s*(?:\?=|=)(.*)$',line)
    return m if m and m[1] in NATIVE_ASSIGNMENTS else None


def native_recipe(line):
    return (line.startswith('\t${C_COMPILER} ') and not line.rstrip().endswith('\\')
            and not any(c in line for c in (';', '&', '|', '`', '$(', 'gsc-boot')))


def native_parameter_projection(source):
    result={}
    for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
        values={key:'' for key in NATIVE_ASSIGNMENTS};recipes=[]
        for line in (source/name).read_text().splitlines():
            m=native_assignment(line)
            if m: values[m[1]]=m[2] if m[2].strip() else ''
            if native_recipe(line):recipes.append(line)
        result[name]=dict(bindings=values,recipes=recipes)
    return result


def native_object_context(source, configuration):
    """Command/header context of successfully built objects, not mutable entry state."""
    text=(source/'lib/makefile').read_text()
    membership=re.findall(
        r'^NORMAL_(?:C|CPP|H|O|O_PLUS|O_COMMA|O_IN_COMPILE_ORDER) = (?:[^\n]*\\\n)*[^\n]*$',
        text,re.M)
    # This value is expanded into native compiler definitions. A changed
    # configure command can change an object even when the template's DEFS
    # expression is byte-identical. Keep it out of generation-recipe filtering.
    configure_commands={name:[line for line in (source/name).read_text().splitlines()
                              if line.startswith('CONFIGURE_COMMAND = ')]
                        for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile')}
    return dict(parameters=native_parameter_projection(source),runtimeMembership=membership,
        configureCommands=configure_commands,
        headers={n:digest(source/n) for n in ('include/gambit.h','include/config.h')},
        tools=configuration['tools'],environment=configuration['environment'])


def generated_inventory(source):
    # Includes linker C with no paired .scm. Root runtime C is never generated.
    return {p.relative_to(source).as_posix(): digest(p)
            for folder in ('lib', 'gsi', 'gsc')
            for p in (source / folder).glob('_*.c')}


def generation_inputs(source):
    names = [p for folder in ('lib', 'gsi', 'gsc')
             for p in (source / folder).rglob('*.scm')]
    names += [source / 'gsc-boot']
    return {p.relative_to(source).as_posix(): digest(p) for p in names}


def relocated_native_line(line, relocations):
    """Normalize only literal native lists/rules, never Scheme commands/edges."""
    declaration = re.fullmatch(
        r'NORMAL_(?:C|H|O|O_PLUS|O_COMMA|O_IN_COMPILE_ORDER) = [\w. +,\\\n-]+', line)
    rule = re.fullmatch(r'[A-Za-z]\w*\.o:(?: [A-Za-z]\w*\.(?:c|h))+\n?', line)
    if not declaration and not rule:
        return line
    for old, row in relocations.items():
        previous, current = Path(old), Path(row['target'])
        if previous.parent == current.parent == Path('lib'):
            line = re.sub(r'(?<![\w])' + re.escape(current.stem)
                          + r'(?=\.(?:c|h|o)(?![\w]))', previous.stem, line)
    return line


def configure_replay_projection(line, source):
    """Remove only this owned cache location from replay-command metadata.

    All compiler/profile flags and command text remain significant. The cache
    selects retained probe observations; it is not a Scheme generator option.
    """
    if not line.startswith('CONFIGURE_COMMAND = ./configure '):
        return line
    prefix=str(source.parent.resolve()/'configure-cache-')
    pattern=r" '--cache-file="+re.escape(prefix)+r"[0-9a-f]{64}'"
    matches=list(re.finditer(pattern,line))
    if len(matches)!=1 or line.count('--cache-file=')!=1:
        return line
    return line[:matches[0].start()]+line[matches[0].end():]


def generation_recipe_projection(source, relocations=None):
    """Conservative selected-Make cut: only known native assignments/commands leave it.

    Unknown lines, module lists, preludes, dependencies and generator recipes
    remain significant. This is not a general Make interpreter or purity proof.
    """
    result={}
    for name in ('makefile','lib/makefile','gsi/makefile','gsc/makefile'):
        kept=[];continuation=False
        for line in (source/name).read_text().splitlines(keepends=True):
            if name=='makefile':
                line=configure_replay_projection(line,source)
            # The withdrawn experiment was only a root configure/distribution
            # prerequisite. No Scheme command or module dependency is omitted.
            if name == 'makefile' and (line.startswith('RCFILES = ')
                                      or line.startswith('makefile.in configure configure.ac ')
                                      or line.startswith('configure: configure.ac')):
                line=line.replace(' native-profile.m4','')
            if continuation:
                kept.append(line);continuation=line.rstrip().endswith('\\');continue
            if native_assignment(line) and not line.rstrip().endswith('\\'):
                continue
            if native_recipe(line):
                continue
            if name == 'lib/makefile' and relocations:
                line = relocated_native_line(line, relocations)
            kept.append(line)
            continuation=line.rstrip().endswith('\\')
        result[name]=hashlib.sha256(''.join(kept).encode()).hexdigest()
    return result


def current_scheme_matches(original, checkout):
    """A native request cannot quietly consume changed current Scheme sources.

    This checks source equality, not purity of arbitrary macros/native I/O.
    """
    def sources(root):
        return {p.relative_to(root).as_posix(): digest(p)
                for folder in ('lib', 'gsi', 'gsc')
                for p in (root / folder).rglob('*.scm')}
    if sources(original) != sources(checkout):
        raise ValueError('current Scheme sources differ; explicit generation demand required')


def invalidate_native_outputs(source, changed_configuration, *, parameters_changed=None):
    """Conservative argv/recipe invalidation never removes generated Scheme C."""
    changed=(any(name.endswith('makefile') for name in changed_configuration)
             if parameters_changed is None else parameters_changed)
    if not changed:
        return []
    paths=[p for folder in ('lib','gsi','gsc') for suffix in ('*.o','*.a')
           for p in (source/folder).glob(suffix)]
    # Keep completed launch programs as build seeds until Make replaces them.
    # Invalidated objects/archives force relinking; a failed build must not
    # destroy the only compiler or leave its launch aliases dangling. Their
    # presence does not admit the changed source/runtime identity.
    removed=[]
    for p in sorted(set(paths)):
        removed.append(p.relative_to(source).as_posix());p.unlink()
    return removed


def configuration_request(source, profile, tools, environment):
    """Selected task/configuration identity; native leaf bodies are not inputs.

    This does not issue a portable SDK/read-effect closure credential. SDK or
    system replacement requires explicit requalification of the task profile.
    """
    inputs = {p.relative_to(source).as_posix(): digest(p)
              for p in source.rglob('*') if p.is_file() and not p.is_symlink()
              and (p.suffix == '.in' or (p.suffix == '.m4' and p.name != 'aclocal.m4')
                   or p.name in {'configure.ac', 'acinclude.m4',
                   'config.guess', 'config.sub'})}
    return dict(inputs=inputs, profile=profile,
        tools={name:dict(path=str(path),sha256=digest(Path(path)))
               for name,path in tools.items()}, environment=dict(environment))


def copy_changed(origin, target):
    if target.is_file() and digest(origin) == digest(target):
        return False
    shutil.copyfile(origin, target)
    return True


def native_source_kind(name):
    """Only native source, never a Scheme generator or generated output."""
    path = Path(name)
    if path.is_absolute() or '..' in path.parts or path.as_posix() != name:
        raise ValueError('canonical native source path required')
    if (name.startswith('lib/') and path.suffix in {'.c', '.inc', '.h'}
            and not path.name.startswith('_') and path.name!='gambit.h'):
        return 'runtime-header' if path.suffix == '.h' else 'runtime-c'
    if name.startswith('include/_gambit/') and len(path.parts) == 3 and name.endswith('.h.in'):
        return 'native-header-template'
    if path.parent==Path('tests') and path.suffix=='.c':
        return 'test-c'
    raise ValueError('only runtime C and internal native header templates are native-stage inputs')


def native_header_invalidation(changed_configuration, changes):
    headers = [n for n in changed_configuration if n.startswith('include/') and n.endswith('.h')]
    declared = any(native_source_kind(n) == 'native-header-template' for n in changes)
    if headers and (headers != ['include/gambit.h'] or not declared):
        raise ValueError('native header output change requires declared internal template delta')
    return bool(headers)


def validate(args, inputs):
    from gambit_smp.native_capabilities import reference
    from gambit_smp.recipes import fields
    fields(args, ('runtime', 'identity', 'buildProfile', 'policy',
                  'nativeChanges', 'nativeDelta', 'generationDemand', 'generation', 'templates'))
    reference(args['runtime']); reference(args['identity'])
    reference(args['generation'])
    expected=['vendor/gambit/makefile.in']+['vendor/gambit/'+p+'/makefile.in' for p in ('lib','gsi','gsc')]
    optional={'vendor/gambit/include/makefile.in','vendor/gambit/tests/makefile.in',
              'vendor/gambit/include/gambit.h.in'}
    templates=args['templates']
    if (not isinstance(templates,list) or len(templates)!=len(set(templates))
            or templates[:len(expected)]!=expected
            or not set(templates[len(expected):])<=optional
            or any(p not in inputs for p in templates)):
        raise ValueError('complete declared native Make template set required')
    if args['generationDemand'] != 'reuse-explicit-artifact':
        raise ValueError('explicit generation demand required')
    if args['policy'] != 'vendor/gambit/configure.ac':
        raise ValueError('existing configure.ac is the only configuration producer')
    for key in ('buildProfile', 'policy', 'nativeDelta'):
        if args[key] not in inputs:
            raise ValueError('declared native service source required')
    if (not isinstance(args['nativeChanges'], list) or not args['nativeChanges']
            or len(set(args['nativeChanges'])) != len(args['nativeChanges'])):
        raise ValueError('nonempty unique native input delta required')
    for name in args['nativeChanges']:
        native_source_kind(name)


def native_relocations(delta):
    """Explicit bounded source moves; no aliases, arbitrary additions or cycles."""
    from gambit_smp.source_capabilities import fields, sha
    result=delta.get('relocations',{})
    if not isinstance(result,dict):
        raise ValueError('native relocations must be a map')
    targets=[]
    for old,row in result.items():
        fields(row,('target','sourceSha256'));sha(row['sourceSha256'])
        target=row['target']
        if (native_source_kind(old)!=native_source_kind(target)
                or Path(old).suffixes!=Path(target).suffixes
                or old in delta['files'] or target not in delta['files']):
            raise ValueError('native relocation must replace one same-kind declared leaf')
        targets.append(target)
    if len(targets)!=len(set(targets)):
        raise ValueError('native relocation targets must be unique')
    return result


def apply_native_delta(ctx, source, delta):
    """Validate the complete move before mutation; resume via the leased tree."""
    relocations=native_relocations(delta)
    targets={r['target']:old for old,r in relocations.items()}
    incoming={}
    for name,row in delta['files'].items():
        native_source_kind(name)
        path=ctx.root/'vendor/gambit'/name
        if not path.is_file() or path.is_symlink() or digest(path)!=row['candidateSha256']:
            raise ValueError('native leaf differs from its declared source lock')
        if native_source_kind(name)=='native-header-template' and '@' in path.read_text():
            raise ValueError('native header delta cannot change configure substitutions')
        target=source/name
        cursor=source
        for part in Path(name).parts:
            cursor=cursor/part
            if cursor.is_symlink():
                raise ValueError('native delta cannot traverse a symlink')
        if target.exists() and not target.is_file():
            raise ValueError('native delta requires a regular leaf')
        if not target.exists() and name not in targets:
            raise ValueError('native delta must replace an existing regular leaf')
        if name in targets:
            old=targets[name];previous=source/old
            if previous.exists():
                if (previous.is_symlink() or not previous.is_file() or target.exists()
                        or digest(previous)!=relocations[old]['sourceSha256']):
                    raise ValueError('source relocation predecessor differs or both names exist')
            elif not target.is_file():
                raise ValueError('source relocation has neither predecessor nor resumed target')
        incoming[name]=path
    observed={}
    for old,row in relocations.items():
        previous=source/old
        if previous.exists():
            observed[old]={'before':digest(previous),'after':None}
            previous.rename(source/row['target'])
    for name,path in incoming.items():
        old=source/name
        observed[name]={'before':digest(old),'after':digest(path)}
        ctx.bind([path]);copy_changed(path,old)
    return observed


def execute(args, ctx):
    result = None
    try:
        result = execute_owned(args, ctx)
        return result
    finally:
        source=getattr(ctx, 'native_development_source', None)
        if source is not None:
            started = time.monotonic()
            from gambit_smp.workspace import checkpoint_build_source
            checkpoint_build_source(source)
            if result is not None:
                result['costBreakdownSeconds']['sourceCheckpoint'] = time.monotonic() - started


def execute_owned(args, ctx):
    last = time.monotonic()
    costs = {}
    def mark(name):
        nonlocal last
        now = time.monotonic()
        costs[name] = now - last
        last = now
    from gambit_smp.recipes import read_json, source_path, tree_identity
    from gambit_smp.native_capabilities import compiler, identity
    from gambit_smp.suite_primitives import check_runtime
    from gambit_smp.bootstrap_artifacts import incremental_consumer
    from gambit_smp.build_profile import read_profile
    original = ctx.artifact(args['runtime'], 'source-runtime')
    check_runtime(original, read_json(ctx.artifact(args['identity'], 'runtime-identity')))
    current_scheme_matches(original, ctx.root / 'vendor/gambit')
    ctx.bind([p for folder in ('lib', 'gsi', 'gsc')
              for p in (ctx.root / 'vendor/gambit' / folder).rglob('*.scm')])
    original_tree = tree_identity(original)
    mark('originAndCurrentScheme')
    from gambit_smp.native_capabilities import configuration_output_names
    from gambit_smp.source_capabilities import validate_source_lock
    delta_path=source_path(ctx.root,args['nativeDelta']);delta=read_json(delta_path)
    validate_source_lock(delta);relocations=native_relocations(delta);ctx.bind([delta_path])
    if set(delta['files'])!=set(args['nativeChanges']):
        raise ValueError('native delta must match its complete locked input inventory')
    mutable=set(configuration_output_names(native_profile=True))
    mutable.update(args['nativeChanges'])
    mutable.update(relocations)
    mutable.update(('native-profile.m4','config.log','configure.ac'))
    mutable.update(name.removeprefix('vendor/gambit/') for name in args['templates'])
    mutable.update(p.relative_to(original).as_posix() for p in original.rglob('*')
                   if p.is_file() and (p.suffix in {'.o','.a'}
                       or 'autom4te.cache' in p.parts
                       or p.relative_to(original).as_posix() in {'gsi/gsi','gsc/gsc'}))
    source, workspace = incremental_consumer(ctx, original, mutable=sorted(mutable))
    ctx.native_development_source = source
    # Compare against the preceding build in this workspace, not the old seed.
    previous_context=read_json(source.parent/'source-state.json').get('nativeObjectContext')
    mark('workspaceReconciliation')
    generator = generation_inputs(source)
    generated = generated_inventory(source)
    product=read_json(ctx.artifact(args['generation'],'generation-manifest'))
    if product['generatedArtifacts'] != generated or product['generationInputs'] != generator:
        raise ValueError('explicit generation product does not match its consumer')
    if not generated:
        raise ValueError('complete generated-C artifact inventory required')
    mark('generationAdmission')
    paths = {key: source_path(ctx.root, args[key]) for key in ('buildProfile', 'policy')}
    ctx.bind(list(paths.values()))
    native_delta=apply_native_delta(ctx,source,delta)
    # Reconfigure through the existing configure.ac and Make templates.
    # Retain unchanged output
    # timestamps only after byte equality, never as evidence of content equality.
    config_names = ('makefile', 'lib/makefile', 'gsi/makefile', 'gsc/makefile',
                    'include/gambit.h', 'include/config.h','include/makefile','tests/makefile')
    configs = {name: ((source / name).read_bytes(), (source / name).stat())
               for name in config_names}
    copy_changed(paths['policy'], source / 'configure.ac')
    retired=[]
    for name in ('native-profile.m4','native-profile.scm'):
        path=source/name
        if path.exists():
            path.unlink();retired.append(name)
    for name in args['templates']:
        incoming=source_path(ctx.root,name);ctx.bind([incoming])
        copy_changed(incoming,source/name.removeprefix('vendor/gambit/'))
    profile = read_profile(paths['buildProfile'])
    compiler(ctx)
    ctx.env['CFLAGS'] = profile['cflags']
    from gambit_smp.native_capabilities import configure_owned_source
    request=configuration_request(source,profile,ctx.tools,ctx.env)
    reused_configuration=configure_owned_source(ctx,source,profile['flags'],managed=True,
                                               request_identity=request)
    if generation_recipe_projection(source,relocations) != product['generationRecipes']:
        raise ValueError('generation recipes or module dependencies changed; issue a generation demand')
    import os
    changed_config = []
    for name, (data, stat) in configs.items():
        p = source / name
        if p.read_bytes() == data:
            os.utime(p, ns=(stat.st_atime_ns, stat.st_mtime_ns))
        else:
            changed_config.append(name)
    header_invalidates = native_header_invalidation(changed_config,args['nativeChanges'])
    object_context=native_object_context(source,request)
    moved_now=any(row['after'] is None for row in native_delta.values())
    parameters_changed=(object_context!=previous_context or header_invalidates or moved_now)
    invalidated=invalidate_native_outputs(source,changed_config,parameters_changed=parameters_changed)
    mark('nativeInputsAndConfiguration')
    before_objects = {p.relative_to(source).as_posix(): digest(p)
                      for folder in ('lib', 'gsi', 'gsc') for p in (source / folder).glob('*.o')}
    make = ctx.tools['make']
    from gambit_smp.framework import available_processors
    from gambit_smp.gambit_build_primitives import build_capacity
    jobs = build_capacity(available_processors())['makeJobs']
    common = [make, '-j' + str(jobs), 'GAMBOPT=p1']
    targets = ['phase3', 'phase4']
    disabled = source / 'gsc-boot.native-stage-disabled'
    if args['generationDemand'] == 'reuse-explicit-artifact':
        # These Make templates have one Scheme generation entry: gsc-boot.
        # An accidental prerequisite reaching it must fail, never regenerate.
        (source / 'gsc-boot').rename(disabled)
        (source / 'gsc-boot').mkdir(mode=0o500)
    phase_logs = {}
    try:
        for phase in targets:
            phase_logs[phase] = ctx.require(phase, [*common, phase], source, ctx.remaining())
    finally:
        if disabled.exists():
            gate=source/'gsc-boot'
            if not gate.is_dir() or gate.is_symlink():
                raise ValueError('generation gate changed; pinned compiler remains in private custody')
            gate.rmdir()
            disabled.rename(source / 'gsc-boot')
    mark('objectsAndMake')
    after_generated = generated_inventory(source)
    if generation_inputs(source) != generator:
        raise ValueError('pinned generation inputs changed during native request')
    if after_generated != generated:
        differing = sorted(set(generated) ^ set(after_generated) |
                           {n for n in generated.keys() & after_generated.keys()
                            if generated[n] != after_generated[n]})
        raise ValueError('generated artifact differs from explicit input: ' + ','.join(differing))
    if tree_identity(original) != original_tree:
        raise ValueError('completed producer was changed')
    from gambit_smp.workspace import checkpoint_build_source
    checkpoint_build_source(source,nativeObjectContext=object_context)
    after_objects = {p.relative_to(source).as_posix(): digest(p)
                     for folder in ('lib', 'gsi', 'gsc') for p in (source / folder).glob('*.o')}
    mark('postMakeValidation')
    # Make's retained stdout separately determines executed compiler invocations;
    # identical object bytes alone do not establish avoided compilation work.
    result = dict(claim='explicit-native-stage-not-arbitrary-scheme-cache-freshness',
                  generationDemand=args['generationDemand'], nativeDelta=native_delta,
                  generationInputs=generator, generatedArtifacts=generated,
                  generationNativeRelocations=relocations,
                  generatedArtifactsStable=True, generationPhasesRequested=targets[:2]
                    if args['generationDemand'] == 'regenerate-control' else [],
                  generationEntryDisabledDuringNative=args['generationDemand']=='reuse-explicit-artifact',
                  generationGate='directory-denial' if args['generationDemand']=='reuse-explicit-artifact' else 'open-control',
                  observedNativeRecipeLines=[line for phase in targets
                    for line in phase_logs[phase].splitlines()
                    if line.strip().startswith(str(ctx.tools['gcc']) + ' ')],
                  observedGenerationRecipeLines=[line for phase in targets
                    for line in phase_logs[phase].splitlines()
                    if 'gsc-boot ' in line and (' -c ' in line or ' -link ' in line)],
                  changedConfiguration=changed_config, originalProducerUnchanged=True,
                  retiredExperimentFiles=retired,
                  nativeOutputsInvalidated=invalidated,
                  nativeParametersChanged=parameters_changed,
                  objectBytesChanged=sorted(n for n in after_objects
                    if before_objects.get(n) != after_objects[n]),
                  fullTwoPassBootstrapEstablished=False, runtimeAdmitted=False)
    retained,storage=source,dict(stableWorkspace=True,sourceCopies=workspace['sourceCopies'],
                                completedSnapshotCreated=False)
    outputs={**ctx.publish('runtime', 'source-runtime', retained), **identity(ctx, retained)}
    mark('publication')
    return dict(result, workspace=workspace, configurationReused=reused_configuration is not None,
                configurationAction=ctx.configuration_action,
                configurationProbesReused=ctx.configuration_action in {'reuse','config-status'},
                preservation=storage, costBreakdownSeconds=costs, outputs=outputs)
