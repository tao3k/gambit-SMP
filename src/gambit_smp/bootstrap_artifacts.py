"""Completed outputs never alias the next destructive build's working tree."""
import json
import hashlib
import os
import re
import shutil
from pathlib import Path

from gambit_smp.framework import digest


def preserve(source, destination):
    """Publish only a complete byte/mode/link-equivalent independent tree.

    APFS copy-on-write is an optimization; a hardlink is never a valid mutable
    copy. A failed staging tree grants no completed-output authority.
    """
    from gambit_smp.artifact_storage import transfer_tree
    from gambit_smp.recipes import tree_identity
    source, destination = Path(source), Path(destination)
    src, dst = source.resolve(), destination.resolve()
    if (source.is_symlink() or destination.is_symlink() or src == dst
            or src.is_relative_to(dst) or dst.is_relative_to(src)):
        raise ValueError('independent disjoint preservation roots required')
    before = tree_identity(source)
    receipt = destination.parent / 'preservation.json'
    if destination.exists():
        if (not receipt.is_file() or json.loads(receipt.read_text()).get('identity') != before
                or tree_identity(destination) != before):
            raise ValueError('unfinished or changed preserved artifact')
        for name in before:
            a, b = source / name, destination / name
            if a.is_file() and not a.is_symlink() and os.path.samefile(a, b):
                raise ValueError('preserved artifact cannot share mutable file inodes')
        return dict(reused=True, exactIdentity=True, sourceUnchanged=True,
                    purpose='completed-output-preservation')
    storage = transfer_tree(source, destination)
    if tree_identity(source) != before or tree_identity(destination) != before:
        raise ValueError('completed artifact changed during preservation')
    from gambit_smp.workspace import write
    write(receipt, dict(identity=before, sourceUnchanged=True, completed=True))
    return dict(storage, sourceUnchanged=True, exactIdentity=True,
                atomicPublication=True, purpose='completed-output-preservation')


def private_activation(ctx):
    """An admitted producer instance, never a caller-chosen output directory.

    Immutable output identity remains content based. A writable constructor's
    identity additionally binds its durable producer, so a later admitted
    operation cannot alias the constructor changed by an earlier operation.
    Native-build history admission and original budgets remain independent.
    """
    journal = getattr(ctx, 'receipt', {}).get('journal')
    if journal is None:
        return None
    header_path = Path(journal['path'])
    if (header_path.is_symlink() or digest(header_path) != journal['sha256']
            or not header_path.resolve().is_relative_to(ctx.root.resolve())
            or ctx.directory.parent.resolve() != (header_path.parent / 'run').resolve()):
        raise ValueError('private constructor requires its bound producer header')
    from gambit_smp.recipes import read_json
    header = read_json(header_path)
    engine = ctx.receipt.get('engine')
    if (not isinstance(engine, dict) or not isinstance(engine.get('engineId'), str)
            or re.fullmatch(r'[0-9a-f]{64}', engine['engineId']) is None
            or header.get('schema') != 'research-run-header.v1'
            or not isinstance(header.get('runId'), str)
            or re.fullmatch(r'[0-9a-f]{32}', header['runId']) is None
            or header.get('executionCompleted') is not False
            or header.get('engineId') != engine['engineId']
            or header.get('recipe') != ctx.receipt.get('recipe')
            or ctx.directory.name not in {step['id'] for step in header.get('declaration', {}).get('steps', [])}):
        raise ValueError('private constructor producer identity differs')
    ctx.bind([header_path])
    return dict(producerSha256=journal['sha256'], step=ctx.directory.name)


def derived_source(ctx, source, role, *, activation=None):
    """A stable registered build generation, never an attempt-local fixture."""
    from gambit_smp.workspace import build_output
    from gambit_smp.recipes import tree_identity
    config = json.loads((source.parent / 'configuration.json').read_text())
    incoming = tree_identity(source)
    ctx.lease_workspace(source, incoming)
    key = hashlib.sha256(json.dumps(incoming, sort_keys=True).encode()).hexdigest()
    derivation = dict(role=role, inputSha256=key)
    if activation is not None:
        derivation['activation'] = activation
    build = build_output(ctx.root, 'gambit-core', compiler=config['compiler'], flags=config['flags'],
                         derivation=derivation)
    derived = json.loads((build / 'configuration.json').read_text())
    if any(derived[name] != config[name]
           for name in ('compiler', 'compilerSha256', 'flags', 'environment')):
        raise ValueError('completed input configuration differs from current build environment')
    ctx.bind([source.parent / 'configuration.json', build / 'configuration.json'])
    return build / 'source', incoming


def private_copy(ctx, source, role):
    from gambit_smp.recipes import tree_identity
    from gambit_smp.artifact_storage import transfer_tree
    activation = private_activation(ctx)
    destination, incoming = derived_source(ctx, source, role, activation=activation)
    if destination.exists():
        if tree_identity(destination) != incoming:
            raise ValueError('private build generation changed; explicit recovery required')
        storage = dict(reused=True, exactIdentity=True)
    else:
        storage = transfer_tree(source, destination)
    if tree_identity(source) != incoming or tree_identity(destination) != incoming:
        raise ValueError('private input copy drift')
    ctx.lease_workspace(destination, incoming)
    return destination, dict(storage, constructorActivation=activation,
                             inputIdentityUnchanged=True, priorGenerationRewritten=False)


def incremental_consumer(ctx, source, *, mutable=()):
    """One task-owned development tree, not one writable tree per run.

    The completed generation origin selects the stable workspace. Existing
    incremental-source custody owns all later updates and interrupted states.
    Only explicit independent controls use private_copy; no implicit clean or
    replacement copy repairs a failed development tree.
    """
    from gambit_smp.workspace import sync_build_source, paths, task_output, write
    from gambit_smp.artifact_storage import transfer_tree
    from gambit_smp.recipes import tree_identity
    _, cache, _ = paths(ctx.root, os.environ['GAMBIT_SMP_TASK_ID'])
    route = task_output(ctx.root, cache / 'cohort/native-development-workspace.json')
    if route.is_symlink():
        raise ValueError('development workspace routing cannot be an alias')
    origin = dict(source=str(source.relative_to(ctx.root)), identity=tree_identity(source))
    previous = json.loads(route.read_text()) if route.exists() else None
    if previous is not None and previous.get('origin') != origin:
        raise ValueError('development origin changed; explicit fixed-workspace rebase required')
    destination, incoming = derived_source(ctx, source, 'working-consumer')
    if previous is not None and previous.get('workspace') != str(destination.relative_to(ctx.root)):
        raise ValueError('development workspace routing changed; no replacement tree permitted')
    if previous is None:
        route.parent.mkdir(parents=True, exist_ok=True)
        write(route, dict(origin=origin, workspace=str(destination.relative_to(ctx.root))))
    ctx.bind([route])
    initial = not (destination.parent / 'source-state.json').exists()
    changes = sync_build_source(ctx.root, destination.parent, source,
        inventory=incoming, mutable=mutable,
        initial_transfer=(lambda: transfer_tree(source, destination, dirs_exist_ok=True))
          if initial else None)
    ctx.lease_workspace(destination, tree_identity(destination))
    return destination, dict(initialImport=initial, sourceCopies=int(initial),
        stableWorkspace=True, delta=changes, automaticClean=False)


def source_core_checkpoint_read(ctx, reference):
    """Authenticate a quiescent failed/successful Make observation, not PASS.

    The workspace state is a locator. The committed step observation binds
    the checkpoint bytes and its command; neither a cohort path nor a mutable
    JSON file can grant reuse by itself.
    """
    from gambit_smp.framework import relative
    from gambit_smp.reasoning_history import read_execution_checkpoint
    run = relative(ctx.root, reference['run'])
    records = read_execution_checkpoint(ctx.root, run)['records']
    rows = [record['payload']['step'] for record in records
            if record['payload'].get('schema') == 'research-step-observation.v1'
            and record['payload']['step']['id'] == reference['step']]
    if len(rows) != 1:
        raise ValueError('source-core checkpoint has no unique committed stage')
    path = relative(ctx.root, reference['path'])
    if not path.is_relative_to(run / 'run'):
        raise ValueError('source-core checkpoint escapes its recorded run')
    name = str(path.relative_to(run / 'run'))
    row = rows[0]
    if (row.get('capability') != 'gambit.source-core'
            or row.get('artifacts', {}).get(name) != reference['sha256']
            or digest(path) != reference['sha256']):
        raise ValueError('source-core checkpoint observation changed')
    value = json.loads(path.read_text())
    command = value['command']
    if (value.get('schema') != 'source-core-regeneration-checkpoint.v1'
            or value.get('writerSha256') != digest(Path(__file__))
            or command not in row.get('commands', []) or command.get('stage') != 'source-core'
            or command.get('exit') is None or command.get('timeout') is not False
            or command.get('parentReaped') is not True
            or command.get('processGroupQuiescent') is not True):
        raise ValueError('source-core checkpoint requires a known, quiescent Make completion')
    paths = [path]
    for name_key, sha_key in (('log', 'logSha256'), ('stdoutPath', 'stdoutSha256'),
                              ('stderrPath', 'stderrSha256')):
        if name_key in command:
            artifact = relative(run / 'run' / reference['step'], command[name_key])
            if digest(artifact) != command[sha_key]:
                raise ValueError('source-core parent command log changed')
            paths.append(artifact)
    for name, expected in value['evidence'].items():
        artifact = relative(ctx.root, name)
        if digest(artifact) != expected:
            raise ValueError('source-core retained origin changed: ' + name)
        if artifact.name == 'receipt.json':
            event = json.loads(artifact.read_text())
            for header, expected_header in event.get('headersAndSources', {}).items():
                if digest(Path(header)) != expected_header:
                    raise ValueError('source-core object include closure changed: ' + header)
                paths.append(Path(header))
        paths.append(artifact)
    ctx.bind(paths)
    return value


def source_core_inputs(tree, generated):
    """Native emission/configuration inputs, excluding generated C/products."""
    return {name: entry for name, entry in tree.items()
            if (Path(name).suffix in {'.scm', '.h', '.inc', '.in', '.ac', '.m4'}
                or Path(name).name in {'makefile', 'config.status', 'configure'}
                or (name.endswith('.c') and name not in generated))}


def source_core_output_origins(source, tree, generated, origins, compiler_sha):
    """Check retained output edges even when Make timestamps skip a recipe."""
    def event(kind, name):
        ref = origins.get(kind + ':' + name)
        if ref is None or digest(Path(ref['path'])) != ref['sha256']:
            raise ValueError('source-core missing or changed ' + kind + ' origin: ' + name)
        row = json.loads(Path(ref['path']).read_text())
        if row.get('kind') != kind or row.get('output') != name or row.get('exit') != 0:
            raise ValueError('source-core invalid output origin: ' + name)
        for path, expected in {**row.get('inputs', {}), **row.get('headersAndSources', {})}.items():
            if kind == 'index' and Path(path) == source / name:
                continue  # This archive is transformed by ranlib below.
            if digest(Path(path)) != expected:
                raise ValueError('source-core output dependency changed: ' + path)
        return row
    for name, entry in tree.items():
        path = Path(name)
        if len(path.parts) != 2 or path.parts[0] not in {'lib', 'gsi', 'gsc'} or 'sha256' not in entry:
            continue
        kind = ('emit' if name in generated else 'object' if path.suffix == '.o' else
                'index' if path.suffix == '.a' else 'link' if name in {'gsc/gsc', 'gsi/gsi'} else None)
        if kind is None:
            continue
        row = event(kind, name)
        if row['outputSha256'] != entry['sha256']:
            raise ValueError('source-core retained product differs from its origin: ' + name)
        if kind == 'emit' and row['tool']['sha256'] != compiler_sha:
            raise ValueError('source-core C belongs to another emitter: ' + name)
        if kind == 'index':
            archive = event('archive', name)
            if row['inputs'].get(str(source / name)) != archive['outputSha256']:
                raise ValueError('source-core archive/index edge differs: ' + name)


def source_core_working(ctx, reference):
    """One checked working generation per typed frozen seed, no cohort alias."""
    from gambit_smp.recipes import tree_identity
    from gambit_smp.workspace import sync_build_source, build_source_links
    from gambit_smp.artifact_storage import transfer_tree
    seed = ctx.artifact(reference, 'seed-runtime')
    config = json.loads((seed.parent / 'configuration.json').read_text())
    if digest(Path(ctx.tools['gcc'])) != config['compilerSha256']:
        raise ValueError('source-core consumer compiler differs from the frozen seed')
    source, incoming = derived_source(ctx, seed, 'working-source-core')
    state_path = source.parent / 'source-state.json'
    state = json.loads(state_path.read_text()) if state_path.is_file() else {}
    generated = sorted(name for name in incoming if len(Path(name).parts) == 2
                       and Path(name).parts[0] in {'lib', 'gsi', 'gsc'}
                       and Path(name).name.startswith('_') and name.endswith('.c'))
    origin = dict(seedWorkspace=str(seed.relative_to(ctx.root)), seedIdentity=incoming,
                  compilerSha256=digest(seed / 'gsc/gsc'),
                  configurationSha256=digest(seed.parent / 'configuration.json'))
    links = build_source_links(ctx.root, source.parent, state)
    previous = None
    if state:
        if not source.is_dir():
            raise ValueError('source-core working directory is missing')
        if state.get('pending'):
            raise ValueError('unbound source-core delta remains; explicit checkpoint recovery required')
        actual = tree_identity(source, broken_links=links or None)
        ctx.lease_workspace(source, actual, **({'broken_links': links} if links else {}))
        pointer = state.get('regeneration', {}).get('checkpoint')
        if pointer is None:
            raise ValueError('unbound source-core work remains; explicit checkpoint recovery required')
        if source_core_inputs(actual, generated) != source_core_inputs(incoming, generated):
            raise ValueError('source-core source/configuration input drift')
        previous = source_core_checkpoint_read(ctx, pointer)
        if (previous['origin'] != origin or previous['tree'] != actual
                or previous['workspace'] != str(source.relative_to(ctx.root))
                or previous['generatedSources'] != generated
                or not (source / 'gsc-boot').is_file()
                or digest(source / 'gsc-boot') != origin['compilerSha256']):
            raise ValueError('source-core seed, inputs or retained products changed; no clean/reseed fallback')
        source_core_output_origins(source, actual, generated, previous.get('origins', {}), origin['compilerSha256'])
    else:
        if source.exists() and tree_identity(source, broken_links=links or None):
            raise ValueError('unbound source-core directory; no automatic replacement')
        source.mkdir(exist_ok=True)
        actual = tree_identity(source, broken_links=links or None)
        ctx.lease_workspace(source, actual, **({'broken_links': links} if links else {}))
    mutable = sorted({*(name for name in incoming if name in generated or Path(name).suffix in {'.o', '.a'}),
                      'gsc/gsc', 'gsi/gsi', 'gsc-boot'})
    delta = sync_build_source(ctx.root, source.parent, seed, inventory=incoming, mutable=mutable,
        initial_transfer=(lambda: transfer_tree(seed, source, dirs_exist_ok=True)) if not state else None,
        preserve_retained=bool(previous))
    # sync_build_source must also reconcile the previous owner and all child
    # sessions before this generation can be mutated by the new attempt.
    if previous and tree_identity(source, broken_links=links or None) != actual:
        raise ValueError('source-core synchronization would replace retained products')
    return source, dict(origin=origin, generatedSources=generated,
                        previous=previous, brokenLinks=links, sourceDelta=delta)


def source_core_checkpoint_write(ctx, source, working, lineage):
    from gambit_smp.recipes import tree_identity
    from gambit_smp.workspace import checkpoint_build_source, write, build_source_links
    from gambit_smp import make_lineage
    command = next(row for row in reversed(ctx.commands) if row['stage'] == 'source-core')
    if (command.get('exit') is None or command.get('timeout') is not False
            or command.get('parentReaped') is not True or command.get('processGroupQuiescent') is not True):
        raise ValueError('incomplete source-core cannot publish reusable outputs')
    prior = working['previous'] or {}
    origins = dict(prior.get('origins', {}))
    evidence = dict(prior.get('evidence', {}))
    for path in sorted(lineage.rglob('receipt.json')):
        row = json.loads(path.read_text())
        if row.get('kind') not in {'emit', 'object', 'archive', 'index', 'link'}:
            continue
        origins[row['kind'] + ':' + row['output']] = dict(path=str(path), sha256=digest(path))
    for path in [lineage / 'inputs.json', lineage / 'emitter-1/gsc-boot',
                 lineage / 'emitter-1/identity.json',
                 *[Path(value['path']) for value in origins.values()]]:
        evidence[str(path.relative_to(ctx.root))] = digest(path)
    # Every retained generated C needs a real successful emission edge. A
    # skipped old file, even with identical bytes, is not a new origin.
    for name in working['generatedSources']:
        if (source / name).is_file():
            make_lineage.completed_action(lineage, 1, 'emit', name, digest(source / name))
    state = json.loads((source.parent / 'source-state.json').read_text())
    links = build_source_links(ctx.root, source.parent, state)
    tree = tree_identity(source, broken_links=links or None)
    if source_core_inputs(tree, working['generatedSources']) != source_core_inputs(
            working['origin']['seedIdentity'], working['generatedSources']):
        raise ValueError('source-core cannot checkpoint changed native inputs')
    source_core_output_origins(source, tree, working['generatedSources'], origins,
                               working['origin']['compilerSha256'])
    path = ctx.directory / 'regeneration-checkpoint.json'
    value = dict(schema='source-core-regeneration-checkpoint.v1', writerSha256=digest(Path(__file__)),
                 origin=working['origin'], generatedSources=working['generatedSources'],
                 workspace=str(source.relative_to(ctx.root)),
                 command=command, tree=tree, origins=origins, evidence=evidence,
                 regeneration={k: v for k, v in state.get('regeneration', {}).items() if k != 'checkpoint'},
                 emitterLoader=json.loads((lineage / 'emitter-1/identity.json').read_text())['loader'],
                 runtimeAdmitted=False, familyAdmitted=False)
    write(path, value)
    regeneration = dict(state.get('regeneration', {}),
        generatedSources=working['generatedSources'],
        bootstrapCompilerSha256=working['origin']['compilerSha256'],
        checkpoint=dict(run=str(ctx.out.parent.relative_to(ctx.root)), step=ctx.directory.name,
                        path=str(path.relative_to(ctx.root)), sha256=digest(path)))
    checkpoint_build_source(source, broken_links=links or None, regeneration=regeneration)
    from gambit_smp.task_dependencies import adopt
    adopt(ctx.root, os.environ['GAMBIT_SMP_TASK_ID'], [str(ctx.out.parent.relative_to(ctx.root))])
    return value


def freeze(ctx, source, role):
    destination, incoming = derived_source(ctx, source, role)
    storage = preserve(source, destination)
    ctx.lease_workspace(destination, incoming)
    receipt = destination.parent / 'preservation.json'
    ctx.bind([receipt])
    storage = dict(storage, sourceWorkspace=str(source.relative_to(ctx.root)),
                   preservedWorkspace=str(destination.relative_to(ctx.root)),
                   identitySha256=hashlib.sha256(json.dumps(incoming, sort_keys=True).encode()).hexdigest(),
                   preservationReceipt=dict(path=str(receipt.relative_to(ctx.root)), sha256=digest(receipt)))
    return destination, storage


def _checked_host_receipt(path, expected, failure):
    """Decode the same receipt bytes whose producer digest was checked."""
    try:
        raw = path.read_bytes()
    except OSError as error:
        raise ValueError(failure) from error
    if hashlib.sha256(raw).hexdigest() != expected:
        raise ValueError(failure)
    try:
        record = json.loads(raw)
    except (ValueError, UnicodeError) as error:
        raise ValueError(failure) from error
    if not isinstance(record, dict):
        raise ValueError(failure)
    return record


def qualified_host(source, declaration, root):
    from gambit_smp.native_capabilities import current_compiler_inputs
    from gambit_smp.recipes import read_json
    from gambit_smp.framework import relative
    spec = read_json(declaration)
    if (spec.get('schema') != 'gambit-bootstrap-host'
            or spec.get('kind') != 'compiled-current-gsc'):
        raise ValueError('source-bound complete AOT compiler required')
    host = relative(root, spec['executable'])
    if not host.is_file() or not os.access(host, os.X_OK) or digest(host) != spec['sha256']:
        raise ValueError('bootstrap host bytes or executable mode changed')
    if spec['qualification'].get('compilerSourceInputs') != current_compiler_inputs(source):
        raise ValueError('bootstrap host generator graph differs')
    proof = spec['qualification'].get('sourceReceipt')
    if (not isinstance(proof, dict) or not isinstance(proof.get('path'), str)
            or not proof['path'] or not isinstance(proof.get('sha256'), str)):
        raise ValueError('completed host producer receipt required')
    if spec['qualification'].get('targetRuntimeLinked') is not False:
        raise ValueError('bootstrap host qualification drift')
    receipt = relative(root, proof['path'])
    outer = _checked_host_receipt(receipt, proof['sha256'], 'bootstrap host producer receipt drift')
    child_path = receipt.parent / 'run/receipt.json'
    if (outer.get('outcome') != 'PASS' or outer.get('timeout') is not False
            or outer.get('parentReaped') is not True or outer.get('processGroupQuiescent') is not True):
        raise ValueError('completed host producer receipt required')
    child = _checked_host_receipt(child_path, outer.get('childReceiptSha256'),
                                  'completed host producer receipt required')
    bootstrap = next((r for r in child['steps'] if r.get('capability') == 'gambit.bootstrap'
                      and r.get('outcome') == 'PASS' and r.get('fullTwoPassBootstrapEstablished') is True
                      and r.get('phaseCounts') == dict(phase1=2,phase2=2,phase3=2,phase4=2)), None)
    if bootstrap is None:
        raise ValueError('host compiler requires complete two-pass producer')
    artifact = bootstrap['outputs']['identity']
    identity_path = relative(receipt.parent / 'run', artifact['path'])
    identity = _checked_host_receipt(identity_path, artifact['sha256'], 'host compiler identity drift')
    if (identity['gscSha256'] != spec['sha256'] or any(
            identity['sourceFiles'].get(name) != sha
            for name, sha in spec['qualification']['compilerSourceInputs'].items())):
        raise ValueError('host compiler bytes or generator ancestry differs')
    return host, spec


def prepare(args, ctx):
    from gambit_smp.native_capabilities import clone, CONFIGURATION_OUTPUTS
    from gambit_smp.recipes import source_path
    if 'producer' in args:
        return reuse_prepared(args, ctx)
    source = clone(ctx, args['source'], 'configured-tree', private=True)
    declaration = source_path(ctx.root, args['bootstrapHost'])
    host, spec = qualified_host(source, declaration, ctx.root)
    old = ctx.root / spec['qualification']['sourceReceipt']['path']
    old_child = old.parent / 'run/receipt.json'
    records = json.loads(old_child.read_text())
    old_boot = next(r for r in records['steps'] if r.get('capability')=='gambit.bootstrap' and r.get('outcome')=='PASS')
    ctx.bind([declaration, host, old, old_child,
              old.parent / 'run' / old_boot['outputs']['identity']['path']])
    shutil.copy2(host, source / 'gsc-boot')
    source, preservation = freeze(ctx, source, 'completed-bootstrap-input')
    # No GSI, target library, or native runtime is invented by this constructor.
    identity = dict(schema='gambit-bootstrap-input-identity',
                    sourceFiles={p.relative_to(source).as_posix(): digest(p)
                                 for folder in ('lib', 'gsi', 'gsc', 'include')
                                 for p in (source / folder).rglob('*')
                                 if p.is_file() and p.suffix in {'.scm', '.c', '.h', '.in'}},
                    configuration={name: digest(source / name) for name in CONFIGURATION_OUTPUTS},
                    bootstrapCompilerSha256=spec['sha256'], runtimeAdmitted=False,
                    targetRuntimeEstablished=False)
    path = ctx.directory / 'identity.json'
    path.write_text(json.dumps(identity, indent=2) + '\n')
    check(source, identity)
    return dict(host=spec, preservation=preservation, claim='qualified-host-compiler-not-target-runtime',
                outputs={**ctx.publish('source', 'bootstrap-input', source),
                         **ctx.publish('identity', 'bootstrap-input-identity', path)})


def reuse_prepared(args, ctx):
    """An authenticated completed compiler input, never the dirty scratch root."""
    from gambit_smp.recipes import source_path, read_json, artifact_path, tree_identity
    from gambit_smp.framework import relative
    reference_path=source_path(ctx.root,args['producer']); proof=read_json(reference_path)
    if set(proof) != {'run','outerSha256','step','profileSha256','stageEvidence'}:
        raise ValueError('exact compiler-input producer reference required')
    run=relative(ctx.root,proof['run']); outer_path=run/'receipt.json'
    outer=read_json(outer_path); child_path=run/'run/receipt.json'
    if (digest(outer_path)!=proof['outerSha256'] or not outer.get('parentReaped')
            or not outer.get('processGroupQuiescent')
            or digest(child_path)!=outer.get('childReceiptSha256')):
        raise ValueError('quiescent bound compiler-input producer required')
    child=read_json(child_path)
    from gambit_smp.step_checkpoint import observe_journal
    stage_proof, _, closure, generator = observe_journal(ctx.root, run, proof['step'])
    if stage_proof != proof['stageEvidence']:
        raise ValueError('compiler-input stage evidence drift')
    if digest(Path(ctx.tools['gcc'])) != generator['hostTools']['gcc']['sha256']:
        raise ValueError('compiler-input GNU toolchain differs')
    rows={r['id']:r for r in child['steps']}; old=rows[proof['step']]
    if (old.get('capability')!='gambit.bootstrap-input' or old.get('outcome')!='PASS'
            or old.get('claim')!='qualified-host-compiler-not-target-runtime'
            or old['outputs']['source']['type']!='bootstrap-input'
            or old['outputs']['identity']['type']!='bootstrap-input-identity'):
        raise ValueError('completed compiler-only artifact required')
    if any(closure[-1].get(k)!=old.get(k) for k in ('id','capability','outcome','arguments','outputs')):
        raise ValueError('compiler-input child and durable stage disagree')
    configured=rows[old['arguments']['source']['step']]
    if configured['capability']!='gambit.configure' or configured['outcome']!='PASS':
        raise ValueError('compiler input requires its configured source ancestry')
    profile=source_path(ctx.root,configured['arguments']['buildProfile'])
    if digest(profile)!=proof['profileSha256'] or outer['inputs'].get(str(profile.relative_to(ctx.root)))!=proof['profileSha256']:
        raise ValueError('compiler input profile drift')
    current=ctx.artifact(args['source'],'configured-tree')
    if tree_identity(current)!=configured['outputs']['source']['identity']:
        raise ValueError('configured source differs from compiler-input producer')
    declaration=source_path(ctx.root,args['bootstrapHost'])
    host,spec=qualified_host(current,declaration,ctx.root)
    saved=artifact_path(run/'run',old['outputs']['source'],root=ctx.root)
    identity_path=artifact_path(run/'run',old['outputs']['identity'],root=ctx.root)
    if (tree_identity(saved)!=old['outputs']['source']['identity']
            or digest(identity_path)!=old['outputs']['identity']['sha256']):
        raise ValueError('preserved compiler input drift')
    identity=read_json(identity_path);check(saved,identity)
    if identity['bootstrapCompilerSha256']!=spec['sha256']:
        raise ValueError('producer compiler differs from current qualified host')
    ctx.lease_workspace(saved,old['outputs']['source']['identity'])
    ctx.bind([reference_path,outer_path,child_path,identity_path,profile,declaration,host])
    target=ctx.directory/'identity.json';shutil.copy2(identity_path,target)
    return dict(host=spec,claim='qualified-host-compiler-not-target-runtime',
                reusedCompilerInput=dict(producer=proof,originalWholeSeconds=outer['wholeSeconds'],
                                         originalInputsStable=child.get('inputsStable'),
                                         stageRevalidated=True, historicalOutcomeChanged=False,
                                         noTargetPassInherited=True,dirtyScratchUsed=False),
                outputs={**ctx.publish('source','bootstrap-input',saved),
                         **ctx.publish('identity','bootstrap-input-identity',target)})


def check(source, identity):
    if (identity.get('schema') != 'gambit-bootstrap-input-identity'
            or identity.get('runtimeAdmitted') is not False
            or identity.get('targetRuntimeEstablished') is not False
            or any(k in identity for k in ('binarySha256', 'librarySha256', 'gscSha256'))):
        raise ValueError('compiler-only input cannot attest a target runtime')
    for group in ('sourceFiles', 'configuration'):
        if not identity.get(group):
            raise ValueError('complete bootstrap source/configuration inventory required')
        for name, sha in identity[group].items():
            if Path(name).is_absolute() or '..' in Path(name).parts or digest(source / name) != sha:
                raise ValueError('bootstrap input source/configuration drift')
    if digest(source / 'gsc-boot') != identity['bootstrapCompilerSha256']:
        raise ValueError('bootstrap input compiler drift')
