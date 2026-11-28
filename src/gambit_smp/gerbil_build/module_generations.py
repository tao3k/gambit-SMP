"""Resume a closed generation of one managed module, never publish its SSI.

The Scheme producer closes all frontend writers before draining native jobs.
Only the quiescent Evidence consumer may retain that progress and issue a
continuation. This is not a general macro/eval cache or a module completion.
"""
from gambit_smp.gerbil_build.custody import _product_observation_directory


import json
import shutil
from pathlib import Path

from gambit_smp.framework import digest
from gambit_smp.gerbil_build.custody import _git_blob, _module_witnesses, _scheme_product_data


def _bundle_file(path, root):
    path = Path(path)
    return (path.is_relative_to(root) and path.is_file()
            and path.resolve() == path and path.stat().st_nlink == 1)


def prepare_generations(ctx, source, key, store, modules, files, keep, *, reuse_allowed):
    """Issue continuations only for the same closed source/dependency snapshot."""
    from gambit_smp.workspace import write
    source, store = Path(source), Path(store)
    directory = store/'generations'
    directory.mkdir(exist_ok=True)
    for marker in (store/'modules').rglob('*.ready.generation'):
        marker.unlink()
    records = {p.stem: json.loads(p.read_text()) for p in directory.glob('*.json')}
    witnesses = _module_witnesses(ctx.root, records,
        schema='gerbil-module-generation-observation', payload_key='moduleGeneration',
        checkpoints=getattr(ctx, 'compiler_execution_checkpoints', None))
    complete = {r['moduleId'] for r in modules.values()}
    valid, rejected = {}, {}
    for identity, record in records.items():
        if record['moduleId'] in complete:
            continue
        ref = record.get('completion', {})
        witness = tuple(ref.get(k) for k in ('path', 'sha256', 'observation', 'scope'))
        core = {k: v for k, v in record.items() if k not in ('completion', 'completionRun')}
        good = (reuse_allowed and record['context'] == key and witnesses.get(witness) == core
                and Path(record['cwd']) == source/'src/std'
                and all(files.matches(p, h) for p, h in record['identities'].items())
                and all(d == record['moduleId'] or not d.startswith('std/') or d in complete
                        for d in record['dependencies']))
        for row in record['files']:
            target, frozen = Path(row['path']), Path(row['frozen'])
            good = (good and target.is_relative_to(source/'build/lib')
                    and target.resolve() == target
                    and (not target.exists() or _bundle_file(target, source/'build/lib'))
                    and _bundle_file(frozen, directory)
                    and files.matches(frozen, row['sha256'])
                    and (target.suffix == '.ssi' or not target.exists()
                         or (_bundle_file(target, source/'build/lib')
                             and files.matches(target, row['sha256']))))
        if not good:
            rejected[identity] = 'generation snapshot, dependencies or immutable witness changed'
            continue
        value = record['data']
        # Only generated code is retained in the live build tree. SSI stays
        # private until the original publisher has joined every native job.
        for row in record['files']:
            target, frozen = Path(row['path']), Path(row['frozen'])
            if target.suffix != '.ssi':
                if not target.exists():
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(frozen, target)
                keep[str(target.relative_to(source))] = row['sha256']
        relative = Path(record['source']).relative_to(source)
        marker = store/'modules'/(str(relative)+'.ready.generation')
        marker.parent.mkdir(parents=True, exist_ok=True)
        marker.write_text(_scheme_product_data(value)+'\n')
        valid[identity] = dict(record, marker=str(marker), markerOid=_git_blob(marker))
    ctx.compiler_generation_records = valid
    write(ctx.directory/'admitted-module-generations.json', valid)
    report = dict(admitted=len(valid), rejected=rejected, moduleComplete=False,
                  publicInterfaceGranted=False, runtimeAdmitted=False)
    write(ctx.directory/'module-generation-admission.json', report)
    return report


def retain_generations(ctx, source, prepared, producer):
    """Retain actual producer progress after its physical writers have stopped."""
    from gambit_smp.workspace import write
    from gambit_smp.research_kernel import retain_run_record, content_id
    from gambit_smp.gerbil_build.custody import _module_arguments_supported
    if producer.get('parentReaped') is not True or producer.get('processGroupQuiescent') is not True:
        raise ValueError('generation custody requires producer quiescence')
    key, context, store, outbox = prepared
    source, store = Path(source).resolve(), Path(store)
    directory = store/'generations'
    directory.mkdir(exist_ok=True)
    closed = []
    for path in sorted(outbox.glob('*.module-generated.json')):
        identity = path.name.removesuffix('.module-generated.json')
        if (outbox/(identity+'.module-completed.json')).exists():
            continue  # Complete programs, rather than their prefix, own reuse.
        value = json.loads(path.read_text())
        request = json.loads((outbox/(identity+'.module-request.json')).read_text())
        if len(value) != 10 or value[:3] != request or value[0] != key or value[8] is not True:
            raise ValueError('generation lacks its actual source request')
        _, src, oid, module_id, deps, native, outputs, dependency_files, _, cwd = value
        if (not _bundle_file(src, source/'src/std') or _git_blob(Path(src)) != oid
                or Path(cwd) != source/'src/std' or not native or not outputs):
            raise ValueError('generation source/cwd/owned work changed')
        if not context.get('reuseAllowed', False):
            continue
        identities = {src: digest(Path(src))}
        for dep, expected in dependency_files:
            if not Path(dep).is_file() or _git_blob(Path(dep)) != expected:
                raise ValueError('generation dependency changed before settlement')
            identities[dep] = digest(Path(dep))
        destinations = [row[0] for row in outputs]
        if (len(set(destinations)) != len(destinations)
                or len({row[1] for row in outputs}) != len(outputs)
                or str(source/'build/lib'/(module_id+'.ssi')) not in destinations):
            raise ValueError('generation has no unique owned interface')
        emitted = set(destinations)
        if (len({row[2] for row in native}) != len(native)
                or any(program != str(source/'build/bin/gsc') or not argv or argv[-1] != inp
               or inp not in emitted or not _module_arguments_supported(argv, context)
               for program, argv, inp in native)):
            raise ValueError('generation native requests escape the managed C role')
        snapshot = directory/content_id(value)
        snapshot.mkdir(exist_ok=True)
        if snapshot.resolve() != snapshot:
            raise ValueError('generation snapshot directory has an alias')
        frozen, files = [], []
        for final, physical, expected in outputs:
            target, actual = Path(final), Path(physical)
            # Publication renames the private SSI before the module completion
            # record is written. A stopped producer can lose that final record.
            # Recover identical generation bytes only; neither this prefix nor
            # an existing public interface grants native/module completion.
            moved_interface = (target.suffix == '.ssi' and actual.parent == outbox
                               and not actual.exists() and not actual.is_symlink())
            if moved_interface:
                actual = target
            if (not target.is_relative_to(source/'build/lib') or target.resolve() != target
                    or target.suffix not in ('.scm', '.ssi', '.ssxi', '.ss', '.init')
                    or (target.suffix == '.init'
                        and target != source/'build/lib'/(module_id+'.init'))
                    or not _bundle_file(actual, ctx.root) or _git_blob(actual) != expected
                    or (target.suffix != '.ssi' and target != actual)
                    or (target.suffix == '.ssi' and actual.parent != outbox and not moved_interface)):
                raise ValueError('generation output lacks closed writer custody')
            saved = snapshot/target.relative_to(source/'build/lib')
            saved.parent.mkdir(parents=True, exist_ok=True)
            if saved.exists():
                if not _bundle_file(saved, directory) or digest(saved) != digest(actual):
                    raise ValueError('immutable generation snapshot differs')
            else:
                shutil.copy2(actual, saved)
            files.append(dict(path=str(target), frozen=str(saved), sha256=digest(saved),
                              recoveredPublishedBytes=moved_interface))
            frozen.append([str(target), str(saved), expected])
        data = [*value[:6], frozen, *value[7:]]
        record = dict(context=key, source=src, moduleId=module_id, dependencies=deps,
                      cwd=cwd, identities=identities, files=files, data=data,
                      moduleComplete=False, runtimeAdmitted=False,
                      boundary='Resume this closed managed generation only; not a standalone macro/eval cache or permission to publish SSI.')
        journal = ctx.receipt['journal']
        header = json.loads(Path(journal['path']).read_text())
        ref = retain_run_record(ctx.root, _product_observation_directory(ctx,outbox)/(identity+'.generation-observed.json'), journal['scope'],
            dict(schema='gerbil-module-generation-observation', header=journal,
                 runId=header['runId'], moduleGeneration=record, runtimeAdmitted=False), header['inputs'])
        record.update(completion=ref, completionRun=str(Path(journal['path']).parent))
        write(directory/(identity+'.json'), record)
        closed.append(module_id)
    used = []
    for path in sorted(outbox.glob('*.generation-used.json')):
        identity = path.name.removesuffix('.generation-used.json')
        record = getattr(ctx, 'compiler_generation_records', {}).get(identity)
        value = json.loads(path.read_text())
        if (record is None or value != [key, record['source'], record['data'][2], record['markerOid']]):
            raise ValueError('generation replay has no admitted continuation')
        used.append(record['moduleId'])
    report = dict(closed=closed, resumed=used, avoidedFrontendInvocations=len(used),
                  moduleComplete=False, publicInterfaceGranted=False, runtimeAdmitted=False)
    write(ctx.directory/'module-generation-observations.json', report)
    return report
