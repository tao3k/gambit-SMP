"""Optional source-bound WP observations in the existing Recipe owner.

Unproved goals and successful smoke proofs are not C counterexamples. The
complete goal inventory, raw output and declared proof premises remain data
for caller-owned investigation, never native admission or a repair schedule.
"""
import hashlib
import json
from pathlib import Path
import re
import shlex


def runtime_inventory(declaration):
    """Bind explicitly selected binaries, package data and Why3 configuration."""
    from gambit_smp.framework import digest
    if (not isinstance(declaration, dict) or set(declaration) !=
            {'schema', 'binaries', 'directories', 'why3Config'} or
            declaration['schema'] != 'frama-c-wp-runtime.v1'):
        raise ValueError('explicit WP runtime declaration required')
    bins = declaration['binaries']
    if not isinstance(bins, dict) or not {'frama-c', 'why3', 'alt-ergo'} <= bins.keys():
        raise ValueError('explicit Frama-C, Why3 and prover binaries required')
    paths = {}
    for name, value in bins.items():
        path = Path(value).resolve(strict=True)
        if not re.fullmatch(r'[a-z][a-z0-9-]*', name) or not path.is_file() or not path.stat().st_mode & 0o111:
            raise ValueError('named executable WP provider required')
        paths['wp-bin:' + name] = path
    roots = declaration['directories']
    if not isinstance(roots, dict) or not {'frama-c-lib', 'frama-c-share', 'why3-lib', 'why3-share'} <= roots.keys():
        raise ValueError('explicit Frama-C/Why3 package data directories required')
    members, directory_links = {}, {}
    for name, value in roots.items():
        root = Path(value).resolve(strict=True)
        if not root.is_dir():
            raise ValueError('WP runtime directory missing: ' + name)
        directory_links[name] = {}
        for path in root.rglob('*'):
            if path.is_symlink() and path.is_dir():
                if not path.resolve().is_relative_to(root):
                    raise ValueError('WP package symlink escapes its declared directory')
                directory_links[name][path.relative_to(root).as_posix()] = str(path.resolve())
        files = sorted(p for p in root.rglob('*') if p.is_file())
        if not files:
            raise ValueError('empty WP runtime directory: ' + name)
        members[name] = [p.relative_to(root).as_posix() for p in files]
        for path in files:
            if not path.resolve().is_relative_to(root):
                raise ValueError('WP package symlink escapes its declared directory')
            paths['wp-file:' + str(path)] = path
    config = Path(declaration['why3Config']).resolve(strict=True)
    if not config.is_file():
        raise ValueError('explicit Why3 configuration file required')
    paths['wp-config'] = config
    # A configured prover command/driver is part of the runtime closure too;
    # merely hashing a config which names an unbound executable is insufficient.
    for match in re.finditer(r'^\s*(command(?:_steps)?|driver)\s*=\s*(.+)$',
                             config.read_text(), re.MULTILINE):
        key, value = match.groups()
        value = json.loads(value)
        if key.startswith('command'):
            words = shlex.split(value)
            if (not words or not Path(words[0]).is_absolute() or
                    Path(words[0]).resolve() not in {p for k, p in paths.items() if k.startswith('wp-bin:')} or
                    any(c in value for c in (';', '|', '&', '<', '>', '`', '$', '\n'))):
                raise ValueError('Why3 command must name an explicitly bound prover')
        else:
            driver = Path(value)
            if not driver.is_absolute() or driver.resolve() not in {p.resolve() for p in paths.values()}:
                raise ValueError('Why3 driver must belong to the declared runtime closure')
    return paths, dict(declaration=declaration, members=members, directoryLinks=directory_links,
        inputDigests={str(p): digest(p) for p in paths.values()},
        scope='Declared binaries and package data; host OS remains an external premise.')


def report(raw, code, timeout, stdout):
    """Interpret WP 33's top-level goal report, including reversed smoke logic."""
    if timeout:
        return dict(verdict='INCONCLUSIVE', reason='timeout', properties=[])
    try:
        goals = json.loads(raw)
        if not isinstance(goals, list) or not goals:
            raise ValueError('nonempty complete WP goal report required')
        ids = [g['goal'] for g in goals]
        if len(ids) != len(set(ids)):
            raise ValueError('duplicate WP goal identity')
        properties, smoke = [], []
        statuses = {'none', 'valid', 'failed', 'unknown', 'stepout', 'timeout'}
        for goal in goals:
            if (goal['verdict'] not in statuses or type(goal['smoke']) is not bool or
                    type(goal['passed']) is not bool or
                    goal['passed'] != ((goal['verdict'] != 'valid') if goal['smoke'] else (goal['verdict'] == 'valid'))):
                raise ValueError('WP goal verdict and smoke interpretation disagree')
            row = dict(property=goal['goal'], description=goal['property'],
                status=('SMOKE_WARNING' if goal['smoke'] and goal['verdict'] == 'valid' else
                        'SMOKE_UNPROVED' if goal['smoke'] else
                        'SUCCESS' if goal['verdict'] == 'valid' else 'UNKNOWN'),
                sourceLocation={k: goal[k] for k in ('file', 'line', 'function') if k in goal},
                wpVerdict=goal['verdict'], smoke=goal['smoke'], provers=goal.get('provers', []))
            properties.append(row)
            if goal['smoke']:
                smoke.append(row)
        normal = [p for p in properties if not p['smoke']]
        warnings = [p['property'] for p in smoke if p['status'] == 'SMOKE_WARNING']
        tool_failures = [p['property'] for p in properties if p['wpVerdict'] == 'failed']
        scheduled = re.findall(r'^\[wp\]\s+(\d+) goals? scheduled\s*$', stdout, re.MULTILINE)
        complete = len(scheduled) == 1 and int(scheduled[0]) == len(goals)
        verified = (code == 0 and normal and all(p['status'] == 'SUCCESS' for p in normal)
                    and smoke and not warnings and not tool_failures and complete)
        return dict(verdict='VERIFIED' if verified else 'INCONCLUSIVE', properties=properties,
            reason=('smoke proof found an unreachable context' if warnings else
                    'all normal goals proved; smoke tests found no unreachable context' if verified else
                    'unproved, missing smoke goals or incomplete WP execution'),
            contextWarnings=warnings, smokeStatus='WARNING' if warnings else 'NO_SMOKE_PROOF',
            preconditionSmokeWarnings=[p['property'] for p in smoke
                if p['status'] == 'SMOKE_WARNING' and p['description'].endswith('_requires')],
            toolFailedGoals=tool_failures,
            scheduledGoals=int(scheduled[0]) if len(scheduled) == 1 else None,
            goalInventoryComplete=complete,
            premiseConsistencyProved=False)
    except (ValueError, KeyError, TypeError) as error:
        return dict(verdict='INCONCLUSIVE', reason=str(error), properties=[])


def validate(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.cbmc_capabilities import validate as validate_c
    fields(args, ('contract', 'branch', 'interface', 'harness', 'function', 'sources',
                  'projections', 'scope', 'assumptions', 'obligations',
                  'machdep', 'model', 'provers', 'proverSeconds'), ('debug', 'messageKeys', 'counterexamples'))
    keys = ('contract', 'branch', 'interface', 'harness', 'function', 'sources',
            'projections', 'scope', 'assumptions')
    validate_c({**{k: args[k] for k in keys}, 'unwind': 1, 'assertions': args['obligations']}, inputs)
    for key in ('machdep', 'model'):
        if not isinstance(args[key], str) or not re.fullmatch(r'[A-Za-z0-9_+,-]+', args[key]):
            raise ValueError('explicit WP machine/memory model required')
    if (not isinstance(args['provers'], list) or not args['provers'] or
            any(not isinstance(p, str) or not re.fullmatch(r'[A-Za-z0-9_.:-]+', p) for p in args['provers'])):
        raise ValueError('explicit WP prover selection required')
    if type(args['proverSeconds']) is not int or not 1 <= args['proverSeconds'] <= 60:
        raise ValueError('bounded per-goal prover budget required')
    if type(args.get('debug', 0)) is not int or not 0 <= args.get('debug', 0) <= 3:
        raise ValueError('bounded WP diagnostic level required')
    if (not isinstance(args.get('messageKeys', []), list) or any(
            not isinstance(key, str) or not re.fullmatch(r'[A-Za-z0-9_:*,-]+', key)
            for key in args.get('messageKeys', []))):
        raise ValueError('explicit WP diagnostic categories required')
    if type(args.get('counterexamples', False)) is not bool:
        raise ValueError('explicit WP countermodel request required')


def check(args, context):
    from gambit_smp.cbmc_capabilities import prepare_source
    from gambit_smp.framework import digest
    from gambit_smp.research_flow import EvidenceUnavailable, _approved_command
    runtime = context.receipt.get('wpRuntime')
    if runtime is None:
        raise EvidenceUnavailable('explicit sealed WP runtime required')
    paths, current = runtime_inventory(runtime['declaration'])
    if current != runtime:
        raise EvidenceUnavailable('WP runtime directory membership or bytes changed')
    translation, snapshots, cuts, backend = prepare_source(args, context, 'c.frama-c', comments=True)
    work = translation.parent
    toolbin = work / 'provider-bin'
    toolbin.mkdir()
    for key, path in paths.items():
        if key.startswith('wp-bin:'):
            (toolbin / key.removeprefix('wp-bin:')).symlink_to(path)
    report_path = context.directory / 'wp.json'
    context.bind(list(paths.values()))
    # Configure before selecting: prover identifiers may be resolved eagerly
    # while parameters are parsed and must not retain an ambient version.
    argv = ['/usr/bin/env', 'PATH=' + str(toolbin),
        *(['OCAMLRUNPARAM=b'] if args.get('debug') else []),
        str(paths['wp-bin:frama-c']),
        '-wp-no-why3-detect', '-wp-why3-config', str(paths['wp-config']),
        '-machdep', args['machdep'],
        '-wp', '-wp-fct', args['function'], '-wp-model', args['model'],
        '-wp-rte', '-wp-smoke-tests', '-wp-smoke-timeout', str(args['proverSeconds']),
        '-wp-timeout', str(args['proverSeconds']), '-wp-prover', ','.join(args['provers']),
        '-wp-cache', 'none', '-wp-session', str(work / 'wp-session'),
        *(['-wp-debug', str(args['debug'])] if args.get('debug') else []),
        *(['-wp-msg-key', ','.join(args['messageKeys'])] if args.get('messageKeys') else []),
        *(['-wp-counter-examples'] if args.get('counterexamples') else []),
        '-wp-report-json', str(report_path), str(translation)]
    token = _approved_command.set(tuple(argv))
    try:
        code, _, timeout, seconds = context.run('wp', argv, work, context.remaining(), capability='c.frama-c')
    finally:
        _approved_command.reset(token)
    result = report(report_path.read_text() if report_path.is_file() else '', code, timeout, context.last_stdout)
    missing = [name for name in args['obligations'] if not any(
        name == p['description'] or p['description'].endswith('_' + name)
        for p in result['properties'] if not p['smoke'])]
    if missing:
        result.update(verdict='INCONCLUSIVE', missingObligations=missing)
    process = context.commands[-1]
    if any(process.get(k) is not True for k in ('parentReaped', 'processGroupQuiescent', 'streamCaptureComplete')):
        result.update(verdict='INCONCLUSIVE', reason='WP process custody incomplete')
    _, after = runtime_inventory(runtime['declaration'])
    if after != runtime:
        result.update(verdict='INCONCLUSIVE', reason='WP runtime changed during verification')
    context.bind(list(paths.values()))
    from gambit_smp.recipes import source_path
    context.bind([source_path(context.root, name) for name in args['sources']])
    result.update(contract=args['contract'], branch=args['branch'], interface=args['interface'],
        scope=args['scope'], assumptions=args['assumptions'], projections=cuts,
        inputDigests={n: hashlib.sha256(data).hexdigest() for n, data in snapshots.items()},
        tool=dict(path=str(paths['wp-bin:frama-c']), sha256=digest(paths['wp-bin:frama-c'])),
        runtimeBinding=dict(engine=context.receipt['engine'],
            manifestSha256=digest(Path(context.receipt['engine']['path']) / 'engine.json'),
            inputCount=len(runtime['inputDigests'])),
        machdep=args['machdep'], model=args['model'],
        provers=args['provers'], exit=code, timeout=timeout, seconds=seconds,
        rawReport='wp.json', preprocessorBackend=dict(path=str(backend), sha256=digest(backend)),
        runtimeAdmitted=False, sourceRefinementAdmitted=False)
    target = context.directory / 'verification.json'
    target.write_text(json.dumps(result, indent=2) + '\n')
    return dict(cVerification=result,
                outputs=context.publish('verification', 'c-wp-verification', target))


def capabilities(Capability):
    return {'c.frama-c': Capability(validate, executor=check,
                                   outputs=(('verification', 'c-wp-verification'),))}
