"""Gerbil build: dynamic products."""

from concurrent.futures import ThreadPoolExecutor, as_completed
from gambit_smp.framework import digest, relative, available_processors
from pathlib import Path
import hashlib
import json
import time

from gambit_smp.gerbil_build.batches import _withdraw_stdlib_batch
from gambit_smp.gerbil_build.policy import _compiler_jobs, _native_jobs

def _native_dynamic_plan(source, value):
    """Admit only the producer's closed, noninteractive GSC dynamic-module role.

    A plan is not a completion receipt. Validate every member before starting
    any native consumer; never infer commands from directory contents.
    """
    source = Path(source).resolve()
    if (not isinstance(value, dict) or set(value) != {'schema', 'commands'}
            or value['schema'] != 'gerbil-native-compile-plan'
            or not isinstance(value['commands'], list) or not value['commands']):
        raise ValueError('complete native compile plan required')
    records, outputs, intermediates = [], set(), set()
    for row in value['commands']:
        if not isinstance(row, dict) or set(row) != {'program', 'argv', 'source', 'cwd', 'environment'}:
            raise ValueError('complete native command context required')
        argv, env = row['argv'], row['environment']
        if (row['program'] != str(source/'build/bin/gsc')
                or not isinstance(argv, list) or not argv
                or any(type(v) is not str or '\0' in v for v in argv)
                or not isinstance(env, dict) or not env
                or any(type(k) is not str or type(v) is not str or not k or '=' in k
                       or '\0' in k or '\0' in v for k, v in env.items())
                or type(row['source']) is not str or type(row['cwd']) is not str):
            raise ValueError('native argv/environment/compiler identity differs')
        path, cwd = Path(row['source']), Path(row['cwd'])
        if (not path.is_absolute() or not cwd.is_absolute() or path.resolve() != path
                or cwd.resolve() != cwd or cwd != source/'src/std'
                or not path.is_relative_to(source) or path.suffix != '.scm'
                or not path.is_file() or argv[-1] != str(path)):
            raise ValueError('native input/cwd outside the declared source role')
        output_dir, explicit_output, explicit_target = path.parent, False, False
        index = 0
        while index < len(argv)-1:
            flag = argv[index]
            if flag not in {'-o', '-e', '-cc-options', '-ld-options', '-debug-source', '-track-scheme', '-target'}:
                raise ValueError('unsupported native module option: '+flag)
            if flag in {'-debug-source', '-track-scheme'}:
                index += 1
                continue
            if index+1 >= len(argv)-1:
                raise ValueError('native module option has no argument')
            if flag == '-target':
                if explicit_target or argv[index+1] != 'C':
                    raise ValueError('native module requires one C target')
                explicit_target = True
            if flag == '-o':
                if explicit_output:
                    raise ValueError('duplicate native output directory')
                explicit_output = True
                output_dir = Path(argv[index+1])
                if (not output_dir.is_absolute() or output_dir.resolve() != output_dir
                        or not output_dir.is_relative_to(source/'build/lib/std')
                        or not output_dir.is_dir()):
                    raise ValueError('native output directory outside standard library')
            index += 2
        output = output_dir/(path.stem+'.o1')
        intermediate = path.with_suffix('.c')
        if (not output.is_relative_to(source/'build/lib/std')
                or output in outputs or output.exists() or output.is_symlink()):
            raise ValueError('native output has duplicate or unqualified custody')
        if (intermediate in intermediates or intermediate.is_symlink()
                or (intermediate.exists() and (not intermediate.is_file()
                                               or intermediate.stat().st_nlink != 1))):
            raise ValueError('native C intermediate has duplicate or aliased custody')
        outputs.add(output)
        intermediates.add(intermediate)
        records.append(dict(row, output=str(output), intermediateC=str(intermediate),
                            sourceSha256=digest(path)))
    return records


def _retain_failed_native_c(ctx, index, row, command, existed_before):
    """Preserve observations; a retained C file is not a successful product."""
    from gambit_smp.workspace import write
    path = Path(row['intermediateC'])
    directory = ctx.directory/'failed-native'/str(index)
    directory.mkdir(parents=True, exist_ok=False)
    receipt = dict(source=row['source'], sourceSha256=row['sourceSha256'],
        command=command, intermediateC=str(path), existedBefore=existed_before,
        retained=False, freshCProved=False, completeCProved=False, productAdmitted=False)
    if (command.get('parentReaped') is True and command.get('processGroupQuiescent') is True
            and path.is_file() and not path.is_symlink()):
        raw = path.read_bytes()
        sha = hashlib.sha256(raw).hexdigest()
        if digest(path) != sha:
            raise ValueError('failed native C changed during retention')
        target = directory/path.name
        target.write_bytes(raw)
        target.chmod(0o444)
        receipt.update(retained=True, archive=str(target), sha256=sha,
                       freshCProved=not existed_before,
                       sourceStable=digest(Path(row['source'])) == row['sourceSha256'])
    write(directory/'receipt.json', receipt)
    return receipt


def _module_read_reports(source, planned, expanded):
    """Join actual before/after reader ownership, not report-file existence."""
    source = Path(source).resolve()
    def decode(value, phase):
        if (not isinstance(value, dict) or set(value) != {'schema', 'phase', 'products', 'completionAliases'}
                or value['schema'] != 'gerbil-module-read-products' or value['phase'] != phase
                or not isinstance(value['products'], list) or not value['products']
                or not isinstance(value['completionAliases'], list)):
            raise ValueError('complete module-read phase report required')
        rows = {}
        for row in value['products']:
            if not isinstance(row, list) or len(row) != 5 or any(type(v) is not str for v in row):
                raise ValueError('module-read ownership fields missing')
            path, state, identity, body, context = row
            file = Path(path)
            if (not file.is_absolute() or file.resolve() != file or not file.is_file()
                    or not file.is_relative_to(source/'src/std') or file.suffix not in {'.ss', '.ssi'}
                    or path in rows or body != 'absent' or context != 'absent'
                    or state not in ({'unread'} if phase == 'planned' else {'unread', 'transferred'})
                    or (state == 'unread' and identity != '')
                    or (state == 'transferred' and not identity)):
                raise ValueError('module-read state/path/root ownership is not closed')
            rows[path] = row
        aliases = value['completionAliases']
        if (any(type(alias) is not str for alias in aliases) or len(set(aliases)) != len(aliases)
                or not set(rows) <= set(aliases)):
            raise ValueError('module-read source/interface ownership incomplete')
        for alias in aliases:
            path = Path(alias)
            if (not path.is_absolute() or path.resolve() != path
                    or not (path.is_relative_to(source/'src/std')
                            or path.is_relative_to(source/'build/lib/std'))):
                raise ValueError('module-read completion alias outside the library')
        return rows, set(aliases)
    before, aliases_before = decode(planned, 'planned')
    after, aliases_after = decode(expanded, 'expanded')
    if before.keys() != after.keys() or aliases_before != aliases_after:
        raise ValueError('module-read phase changed its registered owner set')
    identities = [row[2] for row in after.values() if row[1] == 'transferred']
    if len(identities) != len(set(identities)):
        raise ValueError('duplicate actual module identity in read products')
    return dict(registered=len(before), planningReads=0, transferred=len(identities),
                preexistingContextHits=len(before)-len(identities), completionAliases=len(aliases_before),
                codeAndEvalPromiseRetired=False, sourceRefinementAdmitted=False)


def _stdlib_native_products(ctx, source, *, stage_budget_seconds, native_jobs=None):
    """Close the Scheme producer before bounded native consumption.

    One stdlib deadline covers both phases. No old output, partial plan or
    component pass qualifies a library; no native reuse is admitted here.
    """
    import copy
    from gambit_smp.workspace import write
    jobs = _native_jobs(native_jobs)
    if jobs is None:
        jobs = _compiler_jobs(ctx.env)
    deadline = time.monotonic()+min(stage_budget_seconds, ctx.remaining())
    def remaining():
        budget = min(ctx.remaining(), deadline-time.monotonic())
        if budget <= 0:
            raise TimeoutError('Gerbil stdlib stage budget exhausted')
        return budget
    _withdraw_stdlib_batch(ctx, source, {})
    plan_path = ctx.directory/'stdlib-native-plan.json'
    previous = ctx.env.get('GERBIL_NATIVE_PLAN')
    previous_read_report = ctx.env.get('GERBIL_MODULE_READ_REPORT')
    read_report = ctx.directory/'module-read' if ctx.env.get('GERBIL_MODULE_READ_PRODUCTS') else None
    if read_report is not None:
        ctx.env['GERBIL_MODULE_READ_REPORT'] = str(read_report)
    ctx.env['GERBIL_NATIVE_PLAN'] = str(plan_path)
    try:
        # The workspace supervisor owns the aggregate RSS budget, including
        # this observer and every registered producer/native process. A second
        # per-producer cap silently changes that contract (formerly 7 GiB).
        ctx.require('gerbil-stdlib-producer', [ctx.tools['sh'], './build.sh', 'stdlib'],
                    source/'src', remaining())
    finally:
        if previous is None:
            ctx.env.pop('GERBIL_NATIVE_PLAN', None)
        else:
            ctx.env['GERBIL_NATIVE_PLAN'] = previous
        if previous_read_report is None:
            ctx.env.pop('GERBIL_MODULE_READ_REPORT', None)
        else:
            ctx.env['GERBIL_MODULE_READ_REPORT'] = previous_read_report
    producer = ctx.commands[-1]
    if producer.get('parentReaped') is not True or producer.get('processGroupQuiescent') is not True:
        raise ValueError('native consumers require a retired Scheme producer')
    if read_report is not None:
        reports = [Path(str(read_report)+'-'+phase+'.json') for phase in ('planned', 'expanded')]
        read_admission = _module_read_reports(source, *(json.loads(path.read_text()) for path in reports))
        ctx.bind(reports)
        write(ctx.directory/'module-read-admission.json', read_admission)
    records = _native_dynamic_plan(source, json.loads(plan_path.read_text()))
    ctx.bind([plan_path, source/'build/bin/gsc', *(Path(row['source']) for row in records)])
    write(ctx.directory/'stdlib-native-admission.json', dict(
        commands=records, planSha256=digest(plan_path), producer=producer,
        generatingProcessRetired=True, nativeObjectReuse=False,
        sourceRefinementAdmitted=False, wholeStageBudgetSeconds=stage_budget_seconds,
        nativeWorkers=jobs, sourceWorkers=_compiler_jobs(ctx.env)))
    def consume(index, row):
        child = copy.copy(ctx)
        child.env = dict(row['environment'])
        stage = 'gerbil-stdlib-native-'+str(index)
        existed_before = Path(row['intermediateC']).exists()
        try:
            child.require(stage, [row['program'], *row['argv']], row['cwd'], remaining())
        except Exception as original:
            command = next((item for item in ctx.commands if item['stage'] == stage), None)
            if command is not None:
                try:
                    _retain_failed_native_c(ctx, index, row, command, existed_before)
                except Exception as retention:
                    raise ExceptionGroup('native failure and C retention failure',
                                         [original, retention]) from original
            raise
        command = next(item for item in ctx.commands if item['stage'] == stage)
        output, origin = Path(row['output']), Path(row['source'])
        if (command.get('parentReaped') is not True or command.get('processGroupQuiescent') is not True
                or not output.is_file() or output.is_symlink() or digest(origin) != row['sourceSha256']):
            raise ValueError('native module lacks terminal/input/output evidence')
        return dict(index=index, output=str(output), sha256=digest(output), command=command)
    completed, failure = [], None
    with ThreadPoolExecutor(max_workers=jobs) as pool:
        futures = [pool.submit(consume, index, row) for index, row in enumerate(records)]
        for future in as_completed(futures):
            try:
                completed.append(future.result())
            except Exception as error:
                if failure is None:
                    failure = error
                    # A failed member cannot qualify this library. Stop
                    # admitting queued work; the executor still drains jobs
                    # already running before returning the original failure.
                    for pending in futures:
                        pending.cancel()
    if failure is None and (any(digest(Path(row['source'])) != row['sourceSha256'] for row in records)
                            or any(digest(Path(row['output'])) != row['sha256'] for row in completed)):
        failure = ValueError('native product/input changed before library publication')
    observation = dict(requests=len(records), completed=sorted(completed, key=lambda row:row['index']),
        producerSeconds=producer['seconds'], nativeObjectReuse=False, nativeWorkers=jobs,
        fullLibraryComplete=failure is None, sourceRefinementAdmitted=False,
        packageSpeedupAdmitted=False)
    write(ctx.directory/'stdlib-native-products.json', observation)
    if failure is not None:
        raise failure
    return observation
