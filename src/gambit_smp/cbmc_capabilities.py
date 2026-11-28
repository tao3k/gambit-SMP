"""Source-byte projections and bounded C checks in the existing Recipe owner.

The selected C text is never translated or repaired. Harnesses declare their
environment summaries and proof scope. Solver failures are retained findings,
not successful verification or runtime admission.
"""
import hashlib
import json
from pathlib import Path
import re


def project(data, selection):
    """Select one unique, explicitly delimited maintained C region verbatim."""
    begin, end = selection['begin'], selection['end']
    if data.count(begin) != 1 or (end != '<EOF>' and data.count(end) != 1):
        raise ValueError('C projection delimiters must each identify one source cut')
    first = data.index(begin)
    last = len(data) if end == '<EOF>' else data.index(end)
    if last <= first:
        raise ValueError('C projection cuts are reversed')
    return data[first:last], first, last


def solver_arguments(kind, provider=None):
    """CBMC 6.11 takes an executable here and supplies its SMT2 arguments."""
    if kind == 'sat':
        return []
    if kind != 'z3' or not provider:
        raise ValueError('explicit Z3 executable required')
    return ['--z3', '--external-smt2-solver', provider]


def report(raw, code, timeout):
    """A completed nonempty property inventory is necessary even for UNSAT."""
    if timeout:
        return dict(verdict='INCONCLUSIVE', reason='timeout', properties=[])
    try:
        events = json.loads(raw)
        if not isinstance(events, list):
            raise ValueError('JSON event list required')
        results = [event['result'] for event in events if 'result' in event]
        statuses = [event['cProverStatus'] for event in events if 'cProverStatus' in event]
        if len(results) != 1 or not results[0] or len(statuses) != 1:
            raise ValueError('complete nonempty CBMC property report required')
        rows = results[0]
        ids = [row['property'] for row in rows]
        if len(ids) != len(set(ids)):
            raise ValueError('duplicate property identity')
        failed = [row for row in rows if row['status'] == 'FAILURE']
        if any(row['status'] not in {'SUCCESS', 'FAILURE'} for row in rows):
            # A fatal C obligation may leave later properties UNKNOWN. Preserve
            # their identities and the observed failure traces without claiming
            # a complete source counterexample or a successful proof campaign.
            return dict(verdict='INCONCLUSIVE', reason='unresolved CBMC properties',
                        properties=rows,
                        failedProperties=[row['property'] for row in failed],
                        unresolvedProperties=[row['property'] for row in rows
                                              if row['status'] not in {'SUCCESS', 'FAILURE'}])
        if any('.no-body.' in row['property'] for row in failed):
            return dict(verdict='INCONCLUSIVE', reason='missing C callee implementation',
                        properties=rows, failedProperties=[row['property'] for row in failed])
        substantive = [row for row in failed if 'unwind' not in row['property'].lower()]
        if any(not isinstance(row.get('trace'), list) or not row['trace'] for row in substantive):
            raise ValueError('counterexample trace required')
        verdict = ('VERIFIED' if code == 0 and statuses == ['success'] and not failed else
                   'COUNTEREXAMPLE' if code == 10 and statuses == ['failure'] and substantive else
                   'INCONCLUSIVE' if code == 10 and statuses == ['failure'] and failed else None)
        if verdict is None:
            raise ValueError('CBMC exit, status and property results disagree')
        return dict(verdict=verdict, properties=rows, failedProperties=[row['property'] for row in failed])
    except (ValueError, KeyError, TypeError) as error:
        return dict(verdict='INCONCLUSIVE', reason=str(error), properties=[])


def validate(args, inputs, *, require_projections=True):
    from gambit_smp.recipes import fields, SYMBOL, IDENTIFIER
    fields(args, ('contract', 'branch', 'interface', 'harness', 'function', 'sources',
                  'projections', 'unwind', 'scope', 'assumptions', 'assertions'),
           ('options', 'sampleAfterSeconds', 'verbosity', 'requires', 'paths', 'solver', 'witnesses'))
    witnesses = args.get('witnesses', [])
    if (not isinstance(witnesses, list) or len(witnesses) != len(set(witnesses)) or
            any(not isinstance(w, str) or w not in args['assertions'] for w in witnesses)):
        raise ValueError('reachability witnesses must name declared deliberate assertions')
    if args.get('solver', 'sat') not in {'sat', 'z3'}:
        raise ValueError('explicit supported CBMC decision procedure required')
    if 'paths' in args and args['paths'] not in {'fifo', 'lifo'}:
        raise ValueError('explicit CBMC path-exploration strategy required')
    if 'sampleAfterSeconds' in args and (type(args['sampleAfterSeconds']) not in (int, float)
            or not 0 < args['sampleAfterSeconds'] <= 30):
        raise ValueError('positive bounded verifier sampling delay required')
    if 'verbosity' in args and (type(args['verbosity']) is not int or not 0 <= args['verbosity'] <= 10):
        raise ValueError('CBMC verbosity must be in 0..10')
    requirements = args.get('requires', [])
    if (not isinstance(requirements, list) or len(requirements) != len(set(requirements)) or
            any(not isinstance(name, str) or not IDENTIFIER.fullmatch(name) for name in requirements)):
        raise ValueError('unique prerequisite C verification step identities required')
    options = args.get('options', [])
    if (not isinstance(options, list) or len(options) != len(set(options)) or
            any(value not in {'--no-array-field-sensitivity', '--drop-unused-functions',
                              '--slice-formula', '--reachability-slice-fb',
                              '--arrays-uf-always'} for value in options)):
        raise ValueError('declared semantics-preserving CBMC representation options required')
    if (not isinstance(args['assertions'], list) or
            any(not isinstance(value, str) or not value.strip() for value in args['assertions']) or
            len(args['assertions']) != len(set(args['assertions']))):
        raise ValueError('explicit unique C assertion inventory required')
    if (not isinstance(args['contract'], str) or
            not re.fullmatch(r'[a-z][a-z0-9-]*(/[a-z][a-z0-9-]*)*', args['contract']) or
            not isinstance(args['branch'], str) or not re.fullmatch(r'[a-z][a-z0-9-]*', args['branch']) or
            not isinstance(args['interface'], str) or not args['interface'].strip()):
        raise ValueError('explicit canonical interface, contract and branch identities required')
    if args['harness'] != f"tests/contracts/{args['contract']}/{args['branch']}/harness.c":
        raise ValueError('C harness must belong to its declared contract/branch')
    if args['harness'] not in inputs or not args['harness'].endswith('.c'):
        raise ValueError('declared C harness required')
    if not isinstance(args['function'], str) or not SYMBOL.fullmatch(args['function']):
        raise ValueError('explicit C entry function required')
    if type(args['unwind']) is not int or not 1 <= args['unwind'] <= 256:
        raise ValueError('explicit positive bounded unwinding required')
    if not isinstance(args['scope'], str) or not args['scope'].strip():
        raise ValueError('explicit C property scope required')
    if not isinstance(args['assumptions'], list) or not args['assumptions'] or not all(
            isinstance(value, str) and value.strip() for value in args['assumptions']):
        raise ValueError('explicit environment and ABI assumptions required')
    sources = args['sources']
    if not isinstance(sources, list) or not sources or len(set(sources)) != len(sources) or any(
            name not in inputs for name in sources) or args['harness'] not in sources:
        raise ValueError('unique declared complete C input inventory required')
    if not isinstance(args['projections'], list) or require_projections and not args['projections']:
        raise ValueError('explicit source projections required')
    targets = set()
    for cut in args['projections']:
        fields(cut, ('source', 'target', 'begin', 'end'))
        if cut['source'] not in sources or not re.fullmatch(r'[a-z][a-z0-9-]*\.inc', cut['target']):
            raise ValueError('declared C cut and local projection filename required')
        if cut['target'] in targets or any(not isinstance(cut[k], str) or not cut[k] for k in ('begin', 'end')):
            raise ValueError('unique nonempty C projection required')
        targets.add(cut['target'])


def reachability(result, witnesses):
    """A deliberate assertion failure witnesses reachability, never a repair.

    Qualification requires every other checked obligation to succeed. A trace
    after an unresolved/failed memory check remains an unqualified observation.
    """
    rows = result['properties']
    ordinary = [p for p in rows if p.get('description') not in witnesses]
    safe = (result['verdict'] in {'COUNTEREXAMPLE', 'VERIFIED'} and
            bool(ordinary) and all(p['status'] == 'SUCCESS' for p in ordinary))
    observations = []
    for name in witnesses:
        matches = [p for p in rows if p.get('description') == name]
        reached = (len(matches) == 1 and matches[0]['status'] == 'FAILURE' and
                   bool(matches[0].get('trace')))
        qualified = reached and safe and result['verdict'] == 'COUNTEREXAMPLE'
        observations.append(dict(name=name, status='REACHED' if qualified else
                                 'UNQUALIFIED_TRACE' if reached else 'UNRESOLVED',
                                 property=matches[0]['property'] if len(matches) == 1 else None))
    return {**result, 'verdict': 'REACHABILITY', 'analysisKind': 'reachability',
            'witnesses': observations, 'safetyProvedForOtherObligations': safe,
            'underlyingVerdict': result['verdict']}


def snapshot_sources(args, context):
    """Shared verbatim C inputs; compiler/checker semantics remain separate."""
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path
    sources = [source_path(context.root, name) for name in args['sources']]
    context.bind(sources)
    work = context.directory / 'work'
    work.mkdir()
    snapshots = {}
    for name, source in zip(args['sources'], sources):
        data = source.read_bytes()
        if digest(source) != hashlib.sha256(data).hexdigest():
            raise ValueError('C input changed during snapshot')
        target = work / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        snapshots[name] = data
    cuts = []
    for cut in args['projections']:
        text = snapshots[cut['source']].decode('utf-8')
        selected, first, last = project(text, cut)
        line = text.count('\n', 0, first) + 1
        target = work / cut['target']
        target.write_text('#line ' + str(line) + ' ' + json.dumps(cut['source']) + '\n' + selected + '\n')
        cuts.append(dict(cut, firstCharacter=first, pastCharacter=last, sourceLine=line,
                         selectedSha256=hashlib.sha256(selected.encode()).hexdigest(),
                         sourceSha256=hashlib.sha256(snapshots[cut['source']]).hexdigest()))
    return work, snapshots, cuts


def prepare_source(args, context, capability, *, comments=False):
    """Snapshot exact C cuts and preprocess only declared includes."""
    from gambit_smp.research_flow import _approved_command
    work, snapshots, cuts = snapshot_sources(args, context)
    backend_query = [context.tools['gcc'], '-print-prog-name=cc1']
    token = _approved_command.set(tuple(backend_query))
    try:
        bcode, _, btimeout, _ = context.run('compiler-backend', backend_query, work,
                                           context.remaining(), capability=capability)
    finally:
        _approved_command.reset(token)
    backend = Path(context.last_stdout.strip())
    if bcode != 0 or btimeout or not backend.is_absolute() or not backend.is_file():
        raise ValueError('explicit compiler preprocessing backend required')
    context.bind([backend])
    # Preprocess with the sealed compiler, then give CBMC an already expanded
    # .i file. No PATH-selected compiler or undeclared include can supply bytes.
    preprocess = [context.tools['gcc'], '-E', *(['-CC'] if comments else []), '-nostdinc', '-std=c11',
                  '-I', str(work), str(work / args['harness'])]
    token = _approved_command.set(tuple(preprocess))
    try:
        pcode, _, ptimeout, _ = context.run('preprocess', preprocess, work,
                                           context.remaining(), capability=capability)
    finally:
        _approved_command.reset(token)
    if pcode != 0 or ptimeout:
        raise ValueError('C source projection did not preprocess; raw diagnostic retained')
    expanded = context.last_stdout
    allowed = {str(work / name) for name in snapshots} | set(snapshots)
    allowed.update(str(work / cut['target']) for cut in args['projections'])
    for name in re.findall(r'^#\s+\d+\s+"([^"]+)"', expanded, re.MULTILINE):
        if not name.startswith('<') and name not in allowed:
            raise ValueError('undeclared C preprocessor input: ' + name)
    translation = work / 'translation.i'
    translation.write_text(expanded)
    return translation, snapshots, cuts, backend


def check(args, context):
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path
    from gambit_smp.research_flow import EvidenceUnavailable, _approved_command
    binary = context.tools.get('cbmc')
    if not binary:
        raise EvidenceUnavailable('explicit sealed CBMC provider required; no runtime tool resolution')
    sources = [source_path(context.root, name) for name in args['sources']]
    context.bind(sources)
    prerequisites = []
    for step in args.get('requires', []):
        path = context.artifact(dict(step=step, output='verification'), 'c-bounded-verification')
        proof = json.loads(path.read_text())
        if proof['verdict'] != 'VERIFIED':
            raise ValueError('required storage contract is not verified: ' + step)
        for name, sha in proof['inputDigests'].items():
            if digest(source_path(context.root, name)) != sha:
                raise ValueError('required C contract source changed: ' + name)
        prerequisites.append(dict(step=step, path=str(path), sha256=digest(path),
                                  contract=proof['contract'], branch=proof['branch']))
    translation, snapshots, cuts, backend = prepare_source(args, context, 'c.cbmc')
    work = translation.parent
    argv = [binary, str(translation),
            '--function', args['function'], '--64', '--unwind', str(args['unwind']),
            '--unwinding-assertions', '--bounds-check', '--pointer-check',
            '--pointer-overflow-check', '--signed-overflow-check', '--unsigned-overflow-check',
            '--conversion-check', '--div-by-zero-check', '--undefined-shift-check',
            *args.get('options', []),
            *(['--paths', args['paths']] if 'paths' in args else []),
            *(['--verbosity', str(args['verbosity'])] if 'verbosity' in args else []),
            '--trace', '--json-ui']
    solver = dict(kind=args.get('solver', 'sat'))
    if solver['kind'] == 'z3':
        provider = context.tools.get('z3')
        if not provider:
            raise EvidenceUnavailable('explicit sealed Z3 provider required')
        context.bind([Path(provider)])
        solver.update(path=provider, sha256=digest(Path(provider)))
        argv += solver_arguments('z3', provider)
    diagnostic = None
    if 'sampleAfterSeconds' in args:
        sampler = context.tools.get('darwinSample')
        if not sampler:
            raise EvidenceUnavailable('sealed verifier stack sampler unavailable')
        context.bind([Path(sampler)])
        diagnostic = dict(tool=sampler, toolSha256=digest(Path(sampler)),
                          directory=str(context.directory), afterSeconds=args['sampleAfterSeconds'])
    token = _approved_command.set(tuple(argv))
    try:
        code, output, timeout, seconds = context.run('cbmc', argv, work, context.remaining(),
                                                    capability='c.cbmc', diagnostic=diagnostic)
    finally:
        _approved_command.reset(token)
    raw = context.directory / 'cbmc.json'
    output = context.last_stdout if context.last_stdout is not None else output
    raw.write_text(output)
    result = report(output, code, timeout)
    missing = sorted(set(args['assertions']) - {
        prop.get('description') for prop in result['properties']})
    if missing:
        result.setdefault('reason', 'missing declared C assertions')
        result.update(verdict='INCONCLUSIVE', missingAssertions=missing)
    process = context.commands[-1]
    if (process.get('parentReaped') is not True or process.get('processGroupQuiescent') is not True
            or process.get('streamCaptureComplete') is not True):
        result = dict(verdict='INCONCLUSIVE', reason='verifier process custody incomplete', properties=[])
    if args.get('witnesses'):
        result = reachability(result, args['witnesses'])
    # A solver counterexample is a completed observation, never a proof pass.
    if code == 10 and result['properties']:
        process['expectedExit'] = 10
    context.bind(sources)
    result.update(contract=args['contract'], branch=args['branch'], interface=args['interface'],
        scope=args['scope'], assumptions=args['assumptions'], projections=cuts,
        inputDigests={name: hashlib.sha256(data).hexdigest() for name, data in snapshots.items()},
        tool=dict(path=binary, sha256=digest(Path(binary))), exit=code, timeout=timeout,
        preprocessorBackend=dict(path=str(backend), sha256=digest(backend)),
        seconds=seconds, unwind=args['unwind'], architecture='LP64',
        options=args.get('options', []),
        paths=args.get('paths'),
        solver=solver,
        prerequisites=prerequisites,
        rawReport='cbmc.json', runtimeAdmitted=False, sourceRefinementAdmitted=False)
    path = context.directory / 'verification.json'
    path.write_text(json.dumps(result, indent=2) + '\n')
    # Diagnostic records survive an incomplete checker invocation. The verdict
    # relation, rather than Recipe PASS, determines proof/counterexample status.
    return dict(cVerification=result,
                outputs=context.publish('verification', 'c-bounded-verification', path))


def capabilities(Capability):
    def graph(step, by_id, registry):
        for name in step['arguments'].get('requires', []):
            if (name not in step['dependsOn'] or name not in by_id or
                    by_id[name]['capability'] != 'c.cbmc'):
                raise ValueError('declared producer dependency required for a C contract premise')
    return {'c.cbmc': Capability(validate, executor=check, graph=graph,
                                outputs=(('verification', 'c-bounded-verification'),))}
