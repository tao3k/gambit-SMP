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


def freeze(ctx, source, role):
    destination, incoming = derived_source(ctx, source, role)
    storage = preserve(source, destination)
    ctx.lease_workspace(destination, incoming)
    ctx.bind([destination.parent / 'preservation.json'])
    return destination, storage


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
    proof = spec['qualification'].get('sourceReceipt', {})
    receipt = relative(root, proof.get('path', ''))
    if digest(receipt) != proof.get('sha256') or spec['qualification'].get('targetRuntimeLinked') is not False:
        raise ValueError('bootstrap host qualification drift')
    outer = read_json(receipt)
    child_path = receipt.parent / 'run/receipt.json'
    if (outer.get('outcome') != 'PASS' or outer.get('timeout') is not False
            or outer.get('parentReaped') is not True or outer.get('processGroupQuiescent') is not True
            or digest(child_path) != outer.get('childReceiptSha256')):
        raise ValueError('completed host producer receipt required')
    child = read_json(child_path)
    bootstrap = next((r for r in child['steps'] if r.get('capability') == 'gambit.bootstrap'
                      and r.get('outcome') == 'PASS' and r.get('fullTwoPassBootstrapEstablished') is True
                      and r.get('phaseCounts') == dict(phase1=2,phase2=2,phase3=2,phase4=2)), None)
    if bootstrap is None:
        raise ValueError('host compiler requires complete two-pass producer')
    artifact = bootstrap['outputs']['identity']
    identity_path = relative(receipt.parent / 'run', artifact['path'])
    if digest(identity_path) != artifact['sha256']:
        raise ValueError('host compiler identity drift')
    identity = read_json(identity_path)
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
