"""Source-bound LLVM concurrency observations through the existing Recipe lane.

GenMC receives explicitly compiled LLVM, not a shell command or an ambient C
compiler. A bounded/random run, an empty exploration and a verifier error do
not establish complete verification. All results retain their declared scope.
"""
import hashlib
import json
from pathlib import Path
import re


MODELS = {'sc', 'tso', 'ra', 'rc11', 'imm', 'arm8'}
BUILTIN_FAILURES = {'Non-atomic race', 'Unordered writes', 'Malloc-free race',
                    'Attempt to free non-allocated memory', 'Double-free error',
                    'Attempt to read from uninitialized memory',
                    'Attempt to access non-allocated memory', 'Attempt to access freed memory'}


def runtime_inventory(declaration):
    from gambit_smp.framework import digest
    if (not isinstance(declaration, dict) or set(declaration) !=
            {'schema', 'binaries', 'directories', 'libraries'} or
            declaration['schema'] != 'genmc-runtime.v1'):
        raise ValueError('explicit GenMC compiler/header runtime declaration required')
    if set(declaration['binaries']) != {'genmc', 'clang'}:
        raise ValueError('explicit GenMC and Clang providers required')
    if set(declaration['directories']) != {'genmc-headers', 'clang-headers'}:
        raise ValueError('explicit GenMC model and Clang builtin header directories required')
    paths, members = {}, {}
    for name, value in declaration['binaries'].items():
        path = Path(value).resolve(strict=True)
        if not path.is_file() or not path.stat().st_mode & 0o111:
            raise ValueError('executable GenMC/Clang provider required')
        paths['genmc-bin:' + name] = path
    for name, value in declaration['directories'].items():
        root = Path(value).resolve(strict=True)
        if not root.is_dir():
            raise ValueError('GenMC compiler/header directory unavailable')
        files = sorted(p for p in root.rglob('*') if p.is_file())
        if not files or any(not p.resolve().is_relative_to(root) for p in root.rglob('*') if p.is_symlink()):
            raise ValueError('nonempty self-contained GenMC header directory required')
        members[name] = [p.relative_to(root).as_posix() for p in files]
        for path in files:
            paths['genmc-file:' + str(path)] = path
    libraries = declaration['libraries']
    if not isinstance(libraries, list) or not libraries or len(libraries) != len(set(libraries)):
        raise ValueError('explicit native compiler/checker library inputs required; OS remains external')
    for value in libraries:
        path = Path(value).resolve(strict=True)
        if not path.is_file():
            raise ValueError('declared GenMC library unavailable')
        paths['genmc-lib:' + str(path)] = path
    return paths, dict(declaration=declaration, members=members,
        inputDigests={str(p): digest(p) for p in paths.values()},
        scope='Declared compiler, checker, model/builtin headers and native libraries; host OS is external.')


def validate(args, inputs):
    from gambit_smp.cbmc_capabilities import validate as validate_c
    from gambit_smp.recipes import fields
    fields(args, ('contract', 'branch', 'interface', 'harness', 'function', 'sources',
                  'projections', 'scope', 'assumptions', 'assertions', 'memoryModel', 'target', 'exploration'),
           ('defines',))
    keys = ('contract', 'branch', 'interface', 'harness', 'function', 'sources',
            'projections', 'scope', 'assumptions', 'assertions')
    validate_c({**{k: args[k] for k in keys}, 'unwind': 1}, inputs, require_projections=False)
    if args['memoryModel'] not in MODELS:
        raise ValueError('explicit memory model required; empty assertion inventory selects builtin safety only')
    if not isinstance(args['target'], str) or not re.fullmatch(r'[a-zA-Z0-9_.-]+', args['target']):
        raise ValueError('explicit compiler target triple required')
    defines = args.get('defines', [])
    if (not isinstance(defines, list) or len(defines) != len(set(defines)) or any(
            not isinstance(d, str) or not re.fullmatch(r'[A-Za-z_]\w*(?:=-?[0-9]+)?', d)
            or d.split('=')[0] in {'NDEBUG', '__OPTIMIZE__'} for d in defines)):
        raise ValueError('declared scalar defines must preserve assertions')
    e = args['exploration']
    fields(e, ('mode',), ('bound', 'boundType', 'unroll', 'randomBudget', 'seed'))
    if e['mode'] not in {'verify', 'random', 'estimate'}:
        raise ValueError('explicit GenMC exploration mode required')
    if ('bound' in e) != ('boundType' in e) or e.get('boundType', 'context') not in {'context', 'round'}:
        raise ValueError('bound and boundType must be declared together')
    for key in ('bound', 'unroll', 'randomBudget', 'seed'):
        if key in e and (type(e[key]) is not int or e[key] < 0 or key in {'unroll', 'randomBudget'} and e[key] == 0):
            raise ValueError('nonnegative explicit exploration values required')
    if ('randomBudget' in e) != (e['mode'] == 'random'):
        raise ValueError('random exploration requires its explicit sample budget')


def report(text, code, timeout, exploration, assertions, graph):
    counts = re.findall(r'^Number of complete executions explored:\s*(\d+)(?:\s*\((\d+) exceeded bound\))?\s*$', text, re.M)
    blocked = re.findall(r'^Number of blocked executions seen:\s*(\d+)\s*$', text, re.M)
    result = dict(verdict='INCONCLUSIVE', properties=[], exploredExecutions=None,
                  exploration=exploration, exhaustive=False, warnings=re.findall(r'^.*(?:WARNING|Warning|warning):.*$', text, re.M))
    if timeout:
        return dict(result, reason='timeout')
    if len(counts) != 1 or len(blocked) > 1:
        return dict(result, reason='missing or ambiguous execution summary')
    result.update(exploredExecutions=int(counts[0][0]), blockedExecutions=int(blocked[0]) if blocked else 0,
                  boundExceeded=int(counts[0][1] or 0))
    errors = re.findall(r'Assertion violation:\s*([^\n]+)', text)
    if (code == 42 and ('*** Verification unsuccesful' in text or '*** Random exploration unsuccessful' in text) and graph
            and 'digraph' in graph and len(errors) == 1):
        failed = errors[0].strip()
        if failed not in assertions:
            return dict(result, reason='undeclared assertion failure; inspect raw trace')
        result.update(verdict='COUNTEREXAMPLE', reason='first safety assertion violation, not complete exploration',
            properties=[dict(property='genmc.assertion.' + str(i+1), description=a,
                             status='FAILURE' if a == failed else 'UNKNOWN',
                             trace=[dict(rawReport='genmc.log', errorGraph='error.dot')] if a == failed else [])
                        for i, a in enumerate(assertions)])
        return result
    native_errors = re.findall(r'^Error:\s*(.+?)!\s*$', text, re.M)
    if (code == 42 and '*** Verification unsuccesful' in text and graph and 'digraph' in graph
            and not errors and len(native_errors) == 1 and native_errors[0] in BUILTIN_FAILURES):
        return dict(result, verdict='COUNTEREXAMPLE', reason='first builtin safety violation; later properties are unestablished',
            properties=[dict(property='genmc.safety', description=native_errors[0], status='FAILURE',
                             trace=[dict(rawReport='genmc.log', errorGraph='error.dot')])])
    complete = ('*** Verification complete.' in text and 'No errors were detected.' in text)
    sampled = ('*** Random exploration complete.' in text and 'No errors were detected.' in text)
    if code != 0 or errors or not (complete or sampled) or result['exploredExecutions'] <= 0:
        return dict(result, reason='checker did not complete a nonempty error-free exploration')
    if any(re.search(r'unsupported|unroll|external function|unknown', w, re.I) for w in result['warnings']):
        return dict(result, reason='checker warning leaves support or exploration incomplete')
    bounded = any(k in exploration for k in ('bound', 'unroll')) or result['boundExceeded'] > 0
    verdict = ('VERIFIED' if complete and exploration['mode'] == 'verify' and not bounded else
               'BOUNDED' if complete else 'SAMPLED')
    properties = [dict(property='genmc.assertion.' + str(i+1), description=a,
                       status='SUCCESS' if verdict == 'VERIFIED' else 'UNKNOWN')
                  for i, a in enumerate(assertions)]
    if not assertions:
        properties = [dict(property='genmc.safety', description='GenMC builtin race/memory safety',
                           status='SUCCESS' if verdict == 'VERIFIED' else 'UNKNOWN')]
    return dict(result, verdict=verdict, exhaustive=verdict == 'VERIFIED',
                reason='Declared finite data-deterministic program and selected memory model only; no native admission.',
                properties=properties)


def check(args, context):
    from gambit_smp.cbmc_capabilities import snapshot_sources
    from gambit_smp.framework import digest
    from gambit_smp.recipes import source_path
    from gambit_smp.research_flow import EvidenceUnavailable, _approved_command
    runtime = context.receipt.get('genmcRuntime')
    if runtime is None:
        raise EvidenceUnavailable('explicit sealed GenMC compiler/runtime required; no runtime PATH fallback')
    paths, current = runtime_inventory(runtime['declaration'])
    if current != runtime:
        raise EvidenceUnavailable('GenMC compiler/header membership or bytes changed')
    context.bind(paths.values())
    work, snapshots, cuts = snapshot_sources(args, context)
    clang = str(paths['genmc-bin:clang'])
    genmc = str(paths['genmc-bin:genmc'])
    headers = runtime['declaration']['directories']

    def execute(stage, argv):
        token = _approved_command.set(tuple(argv))
        try:
            return context.run(stage, argv, work, context.remaining(), capability='c.genmc')
        finally:
            _approved_command.reset(token)

    _, _, timed, _ = execute('genmc-version', [genmc, '--version'])
    version = context.last_stdout
    if timed or not re.search(r'GenMC v0\.20\.', version):
        raise EvidenceUnavailable('GenMC 0.20 report profile required; retain other versions as unsupported')
    code, _, timed, _ = execute('clang-version', [clang, '--version'])
    clang_version = context.last_stdout
    if code or timed:
        raise EvidenceUnavailable('sealed Clang version unavailable')
    checker_llvm = re.search(r'Built with LLVM (\d+)', version)
    frontend_llvm = re.search(r'clang version (\d+)', clang_version)
    if not checker_llvm or not frontend_llvm or checker_llvm[1] != frontend_llvm[1]:
        raise EvidenceUnavailable('GenMC and selected Clang LLVM major versions differ or are unknown')
    includes = ['-nostdinc', '-I', str(work), '-I', headers['genmc-headers'], '-I', headers['clang-headers']]
    common = ['--no-default-config', '--target=' + args['target'], '-std=c11', '-ffreestanding', *includes,
              *['-D' + d for d in args.get('defines', [])]]
    code, _, timed, _ = execute('preprocess', [clang, *common, '-E', str(work / args['harness'])])
    if code or timed:
        raise ValueError('GenMC source did not preprocess; raw diagnostic retained')
    expanded = context.last_stdout
    allowed = {str(work / name) for name in snapshots} | set(snapshots)
    allowed.update(str(work / cut['target']) for cut in args['projections'])
    allowed.update(str(p) for k, p in paths.items() if k.startswith('genmc-file:'))
    for name in re.findall(r'^#\s+\d+\s+"([^"]+)"', expanded, re.M):
        if not name.startswith('<') and name not in allowed and str(Path(name).resolve()) not in allowed:
            raise ValueError('undeclared GenMC preprocessor input: ' + name)
    translation = work / 'translation.i'
    translation.write_text(expanded)
    llvm = work / 'translation.ll'
    code, _, timed, _ = execute('compile-llvm', [clang, '--no-default-config', '--target=' + args['target'], '-ffreestanding',
        '-fno-discard-value-names', '-Xclang', '-disable-O0-optnone', '-g', '-O0',
        '-S', '-emit-llvm', '-x', 'cpp-output', str(translation), '-o', str(llvm)])
    if code or timed or not llvm.is_file():
        raise ValueError('GenMC LLVM compilation failed; raw diagnostic retained')
    missing = [a for a in args['assertions'] if a not in llvm.read_text()]
    e = args['exploration']
    argv = [genmc, '--' + args['memoryModel'], '--mode=' + e['mode'], '--disable-estimation',
            '--disable-mm-detector',
            '--program-entry-function=' + args['function'], '--print-error-trace',
            '--dump-error-graph=' + str(context.directory/'error.dot'),
            '--output-llvm-after=' + str(context.directory/'transformed.ll')]
    for key, option in (('bound', 'bound'), ('boundType', 'bound-type'), ('unroll', 'unroll'),
                        ('randomBudget', 'random-budget'), ('seed', 'schedule-seed')):
        if key in e:
            argv.append('--' + option + '=' + str(e[key]))
    argv.append(str(llvm))
    code, output, timed, seconds = execute('genmc', argv)
    process = context.commands[-1]
    streams = [context.directory/process[k] for k in ('stdoutPath', 'stderrPath') if k in process]
    text = '\n'.join(p.read_text(errors='replace') for p in streams) if streams else output
    (context.directory/'genmc.log').write_text(text)
    graph = context.directory/'error.dot'
    result = report(text, code, timed, e, args['assertions'], graph.read_text() if graph.is_file() else '')
    location = re.search(r'ERROR\s+([^\s:]+):(\d+)', text)
    if location:
        matching = [n for n in args['sources'] if Path(n).name == Path(location[1]).name]
        if len(matching) == 1:
            for prop in result['properties']:
                if prop['status'] == 'FAILURE':
                    prop['sourceLocation'] = dict(file=matching[0], line=location[2])
    if missing:
        result.update(verdict='INCONCLUSIVE', exhaustive=False, missingAssertions=missing,
                      reason='declared assertion absent from compiled LLVM input')
    if any(process.get(k) is not True for k in ('parentReaped', 'processGroupQuiescent', 'streamCaptureComplete')):
        result.update(verdict='INCONCLUSIVE', exhaustive=False, reason='incomplete verifier process custody')
    if code == 42 and result['verdict'] == 'COUNTEREXAMPLE':
        process['expectedExit'] = 42
    _, after = runtime_inventory(runtime['declaration'])
    if after != current:
        raise ValueError('GenMC compiler/runtime changed during observation')
    context.bind([source_path(context.root, n) for n in args['sources']])
    result.update(contract=args['contract'], branch=args['branch'], interface=args['interface'],
        scope=args['scope'], assumptions=args['assumptions'], projections=cuts,
        inputDigests={n: hashlib.sha256(b).hexdigest() for n, b in snapshots.items()},
        memoryModel=args['memoryModel'], target=args['target'], version=version, clangVersion=clang_version,
        compilerSha256=digest(Path(clang)), llvmSha256=digest(llvm), toolSha256=digest(Path(genmc)),
        rawReport='genmc.log',
        errorGraph=dict(path='error.dot', sha256=digest(graph)) if graph.is_file() else None,
        automaticMemoryModelDetection=False,
        exit=code, timeout=timed, seconds=seconds, runtimeAdmitted=False, sourceRefinementAdmitted=False)
    path = context.directory/'verification.json'
    path.write_text(json.dumps(result, indent=2) + '\n')
    return dict(cVerification=result, outputs=context.publish('verification', 'c-contract-verification', path))


def capabilities(Capability):
    return {'c.genmc': Capability(validate, executor=check,
                                 outputs=(('verification', 'c-contract-verification'),))}
