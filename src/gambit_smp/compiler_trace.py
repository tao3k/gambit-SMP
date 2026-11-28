"""Read compiler observations from the existing receipt-bound emission stream."""

import hashlib
import json
import re
import shlex
import sys
from pathlib import Path

from gambit_smp.framework import relative


_PREFIX = 'GAMBIT-COMPILER-TRACE\tv1\t'
_IDENTIFIER = re.compile(r'[a-z][a-z0-9-]{0,63}')
_LEGACY = {
    'compiler-main': 'compiler-main',
    'phase read-source': 'read-source',
    'phase expand': 'wrap-program',
    'phase parse': 'parse',
    'phase normalize': 'normalize',
}


class _MacroCacheTrace:
    """Join source-site observations, without selecting a repair or retry."""
    fields = {'cache-root': 'cacheId', 'previous-cache': 'previousCacheId',
              'prior-builds': 'priorBuilds', 'build-cells': 'cells',
              'shared-cells': 'sharedCells', 'novel-cells': 'novelCells',
              'shared-tail': 'tailId', 'tail-owner': 'tailOwnerBuild',
              'prefix-cells': 'prefixCells', 'owner-mismatches': 'ownerMismatches',
              'within-build-revisits': 'withinBuildRevisits'}

    def __init__(self):
        self.builds = {}
        self.generations = []
        self.heads = {}
        self.names = []

    def observe(self, event):
        kind, a, b, line = (event[k] for k in ('kind', 'first', 'second', 'line'))
        if kind == 'generation-name':
            self.names.append(dict(headId=a, name=event['site'], line=line))
        elif kind.startswith('generation-'):
            if kind not in ('generation-prepend', 'generation-switch', 'generation-same'):
                raise ValueError('unknown macro generation observation')
            if (kind == 'generation-same') != (a == b):
                raise ValueError('macro generation identity mismatch')
            self.generations.append(dict(kind=kind, oldHeadId=a, headId=b, line=line,
                                         phase=event.get('observedPhase', 'unobserved')))
        elif kind == 'build':
            if b <= 0 or b in self.builds:
                raise ValueError('macro build identity repeated')
            history = self.heads.setdefault(a, [])
            self.builds[b] = dict(buildId=b, headId=a, line=line, published=False,
                                 previousBuildId=history[-1] if history else None,
                                 phase=event.get('observedPhase', 'unobserved'))
            history.append(b)
        elif kind in self.fields or kind == 'published':
            if a not in self.builds:
                raise ValueError('macro build detail has no start')
            row = self.builds[a]
            if row['published']:
                raise ValueError('macro build detail followed publication')
            if kind == 'published':
                if b != 1 or any(key not in row for key in self.fields.values()):
                    raise ValueError('incomplete macro publication summary')
                if row['cells'] != row['sharedCells'] + row['novelCells'] + row['withinBuildRevisits']:
                    raise ValueError('macro cell accounting mismatch')
                previous = self.builds.get(row['previousBuildId'])
                expected = 0 if previous is None else previous['priorBuilds'] + 1
                if row['priorBuilds'] != expected:
                    raise ValueError('macro head history mismatch')
                if previous and row['previousCacheId'] != previous['cacheId']:
                    raise ValueError('macro cache-root history mismatch')
                if row['sharedCells']:
                    if (not row['tailId'] or row['tailOwnerBuild'] not in self.builds
                            or row['tailOwnerBuild'] >= a
                            or row['prefixCells'] + row['sharedCells'] > row['cells']
                            or row['ownerMismatches'] > row['sharedCells']):
                        raise ValueError('macro shared-tail evidence mismatch')
                elif any(row[key] for key in ('tailId','tailOwnerBuild','prefixCells','ownerMismatches')):
                    raise ValueError('macro tail recorded without shared cells')
                row['published'] = True
                row['completedLine'] = line
                row['sharedSuffix'] = bool(row['sharedCells'] and not row['withinBuildRevisits']
                    and not row['ownerMismatches']
                    and row['prefixCells'] + row['sharedCells'] == row['cells'])
                row['classification'] = (
                    'same-key-after-incomplete' if previous and not previous['published'] else
                    'same-key-same-cache-rebuild' if previous and row['cacheId'] == row['previousCacheId'] else
                    'same-key-new-cache-rebuild' if previous else
                    'new-key-shared-tail' if row['sharedCells'] else 'new-key-independent')
            else:
                key = self.fields[kind]
                if key in row:
                    raise ValueError('macro build detail repeated')
                row[key] = b

    def result(self):
        builds = list(self.builds.values())
        completed = [row for row in builds if row['published']]
        classes = {}
        for row in completed:
            key = row['classification']
            bucket = classes.setdefault(key, dict(builds=0, cells=0, sharedCells=0))
            bucket['builds'] += 1
            bucket['cells'] += row['cells']
            bucket['sharedCells'] += row['sharedCells']
        generations = {}
        for row in self.generations:
            generations.setdefault(row['headId'], []).append(row)
        for row in builds:
            row['generationLines'] = [g['line'] for g in generations.get(row['headId'], [])]
        names = {}
        for row in self.names:
            names.setdefault(row['headId'], {})[row['name']] = True
        for row in builds:
            row['headNames'] = list(names.get(row['headId'], {}))
        return dict(builds=builds, generations=self.generations, names=self.names, classifications=classes,
                    startedBuilds=len(builds), completedBuilds=len(completed),
                    incompleteBuilds=len(builds)-len(completed),
                    sharedSuffixBuilds=sum(row['sharedSuffix'] for row in completed),
                    buildsWithObservedGeneration=sum(bool(row['generationLines']) for row in completed),
                    idScope='One receipt-bound stream; weak-key identities, never pointer addresses.',
                    coverage='Only traversed cells and observed setter transitions; absence is not a universal cache/GC proof.')


def native_observer_argv(argv, directory, *, work_source=None, work_ld_options=''):
    """Wrap only a configured compiled-GSC command with the sealed observer."""
    if (len(argv) < 4 or not argv[1].startswith('-:') or '-c' not in argv
            or '-e' in argv or '-f' not in argv):
        raise ValueError('native phase observation requires the configured GSC compile command')
    source = Path(__file__).with_name('compiler_observer.scm')
    raw = source.read_bytes()
    target = Path(directory) / 'compiler-observer.scm'
    with target.open('xb') as stream:
        stream.write(raw)
    target.chmod(0o444)
    original = ['gsc', *argv[2:]]
    work = None
    setup = ''
    if work_source is not None:
        if sys.platform == 'darwin':
            work_ld_options += ' -Wl,-bundle_loader,' + shlex.quote(argv[0])
        work_source = Path(work_source).resolve(strict=True)
        resource = source.with_name('compiler_work.scm').read_bytes()
        work_path = Path(directory) / 'compiler-work.scm'
        with work_path.open('xb') as stream:
            stream.write(resource)
        work_path.chmod(0o444)
        inputs = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in
                  (work_source/'lib/_eval.scm', work_source/'gsc/_env.scm',
                   work_source/'lib/gambit#.scm', work_source/'lib/_gambit#.scm')}
        module_source = Path(directory) / 'compiler-work-native.scm'
        module_binary = Path(directory) / 'compiler-work-native.o1'
        setup = ('(load ' + json.dumps(str(work_path)) + ') (f6-work-write '
                 + ' '.join(json.dumps(p) for p in inputs) + ' '
                 + json.dumps(str(work_path)) + ' ' + json.dumps(str(target)) + ' '
                 + json.dumps(str(module_source)) + ') '
                 '(set! f6-observe-enabled? #f) '
                 '(if (not (compile-file ' + json.dumps(str(module_source))
                 + ' output: ' + json.dumps(str(module_binary))
                 + ' options: (quote (keep-temp)) ld-options: ' + json.dumps(work_ld_options)
                 + ')) (error "native work observer compilation failed")) '
                 '(load ' + json.dumps(str(module_binary)) + ') '
                 '(set! f6-observe-enabled? #t) ')
        work = dict(path=str(work_path), sha256=hashlib.sha256(resource).hexdigest(),
                    sourceInputs=inputs, mode='source-instantiated-diagnostic-not-native-performance',
                    nativeSource=str(module_source), nativeModule=str(module_binary),
                    ldOptions=work_ld_options,
                    units='actual injected visits/comparisons/probes; alias probes are not alias comparisons')
    expression = ('(begin (load ' + json.dumps(str(target)) + ') ' + setup +
        '(##processed-command-line-set! (list ' + ' '.join(json.dumps(x) for x in original) + ')) '
        '(##script-command-line-set! #f) (##main-gsi/gsc))')
    return [argv[0], argv[1], '-f', '-e', expression], dict(
        path=str(target), sha256=hashlib.sha256(raw).hexdigest(),
        sourceSha256=hashlib.sha256(raw).hexdigest(), originalArgv=argv,
        work=work, mode='compiled-gsc-startup-observer-not-production-equivalence')


def module_compiler_trace(run, step):
    """Read native or hosted module traces without inferring instrumentation."""
    if step['capability'] != 'gambit.regenerate-module' or step.get('reused'):
        return None
    commands = [row for row in step.get('commands', []) if row['stage'] == 'regenerate-module']
    if len(commands) != 1:
        return None
    command, = commands
    trace = command_compiler_trace(run, step['id'], step['arguments']['module'], command)
    observation = step.get('observation', {})
    if 'phaseObserver' in observation:
        trace['observer'] = observation['phaseObserver']
        trace['diagnosticCNotReusable'] = observation.get('diagnosticCNotReusable', False)
        trace['producerMeaning'] = observation.get('mode', 'compiled-native-phase-diagnostic')
    return trace


def command_compiler_trace(run, step_id, module, command):
    """Project a captured command; its caller retains the real execution kind."""
    step = dict(id=step_id, arguments=dict(module=module))
    streams = [name for name in ('stdout', 'stderr') if name + 'Path' in command] or ['log']
    traces = [_stream_trace(run, step, command, stream) for stream in streams]
    unverified = next((trace for trace in traces if trace['status'] != 'RECEIPT_BOUND'), None)
    if unverified:
        return dict(unverified, observationStatus='UNVERIFIED_STREAM')
    observed = [trace for trace in traces if trace['events']]
    selected = observed[0] if observed else traces[0]
    protocol = [trace for trace in observed if trace.get('protocolRecords', 0)]
    if len(protocol) == 1 and all(trace is protocol[0] or all(
            event['kind'] == 'legacy-enter' for event in trace['events']) for trace in observed):
        return dict(protocol[0], auxiliaryStreams=[trace for trace in traces if trace is not protocol[0]],
                    observationStatus='PHASE_EVENTS_PRESENT',
                    frontierScope='selected-stream-only', crossStreamOrderEstablished=False)
    if len(observed) > 1:
        # Separate pipes do not establish a total event order. Keep their
        # evidence readable without inventing one combined frontier.
        return dict(selected, events=[], frontier=None, firstObservedException=None, streams=traces,
                    observationStatus='MULTIPLE_PHASE_STREAMS',
                    crossStreamOrderEstablished=False)
    return dict(selected, observationStatus=('PHASE_EVENTS_PRESENT' if observed
                                            else 'NO_PHASE_EVENTS'))


def _stream_trace(run, step, command, stream):
    path_key = stream + 'Path' if stream != 'log' else 'log'
    sha = command.get(stream + 'Sha256')
    result = dict(step=step['id'], module=step['arguments']['module'], stream=stream,
                  sha256=sha, events=[], captureComplete=command.get('streamCaptureComplete'),
                  runtimeAdmitted=False)
    try:
        ref = step['id'] + '/' + command[path_key]
        raw = relative(run, ref).read_bytes()
        if hashlib.sha256(raw).hexdigest() != sha:
            raise ValueError('compiler emission stream identity changed')
    except (OSError, ValueError, KeyError, TypeError) as error:
        return dict(result, status='UNVERIFIED', reason=str(error))

    frontier = None
    first_exception = None
    malformed = 0
    work = {}
    elapsed = {}
    protocol_records = 0
    timed_calls = {}
    macro = _MacroCacheTrace()
    for number, line in enumerate(raw.decode('utf-8', errors='replace').split('\n')[:-1], 1):
        if line.startswith(_PREFIX):
            parts = line[len(_PREFIX):].split('\t')
            if (len(parts) != 5 or not all(_IDENTIFIER.fullmatch(x) for x in parts[:2])
                    or not all(re.fullmatch(r'[0-9]{1,18}', x) for x in parts[2:4])
                    or not parts[4] or len(parts[4]) > 512):
                malformed += 1
                continue
            phase, kind, first, second, site = parts
            protocol_records += 1
            event = dict(line=number, phase=phase, kind=kind, site=site,
                         first=int(first), second=int(second))
            if phase == 'macro-cache':
                active = next(reversed(timed_calls), None)
                event['observedPhase'] = active[0] if active else 'unobserved'
                try:
                    macro.observe(event)
                except ValueError as error:
                    return dict(result, status='UNVERIFIED', reason=str(error))
            if kind == 'enter':
                timed_calls[(phase, site, event['first'])] = number
            if phase == 'frontend-work' and kind == 'count':
                previous = work.get(site)
                if previous and event['first'] < previous['value']:
                    return dict(result, status='UNVERIFIED', reason='cumulative work counter regressed')
                if site not in work and len(work) >= 64:
                    malformed += 1
                    continue
                work[site] = dict(value=event['first'], line=number)
            if kind == 'elapsed-ns':
                if timed_calls.pop((phase, site, event['second']), None) is None:
                    return dict(result, status='UNVERIFIED', reason='elapsed measurement has no unique matching call')
                if phase not in elapsed and len(elapsed) >= 64:
                    malformed += 1
                    continue
                row = elapsed.setdefault(phase, dict(completedCalls=0, inclusiveNanoseconds=0, line=number))
                row['completedCalls'] += 1
                row['inclusiveNanoseconds'] += event['first']
                row['line'] = number
        elif line in _LEGACY or line.startswith(';; emit-proc '):
            phase = _LEGACY.get(line, 'c-scan')
            if phase == 'c-scan' and frontier and frontier['phase'] == 'c-scan':
                continue
            event = dict(line=number, phase=phase, kind='legacy-enter', site=line[:512],
                         first=0, second=0)
        else:
            continue
        if event['kind'] in ('enter', 'return', 'legacy-enter'):
            frontier = event
        if event['kind'] == 'raise' and first_exception is None:
            first_exception = event
        if len(result['events']) < 512:
            result['events'].append(event)
        else:
            result['eventsTruncated'] = True
    return dict(result, status='RECEIPT_BOUND', reference=ref, frontier=frontier,
                firstObservedException=first_exception, malformedRecords=malformed,
                protocolRecords=protocol_records, workCounters=work, phaseElapsed=elapsed,
                macroCache=macro.result(),
                timingScope='completed wrapper calls; inclusive, monotonic; diagnostic overhead included',
                counterScope=('last observed cumulative source-instantiated diagnostic snapshot, '
                              'not necessarily terminal totals; first graph nodes are per sourcify call; '
                              'alias probes are not alias comparisons'))


def add_compiler_trace_facts(facts, trace, reference):
    if not trace or trace['status'] != 'RECEIPT_BOUND':
        return
    step = trace['step']
    for event in trace['events']:
        if event['kind'] in ('count', 'elapsed-ns') or event['phase'] == 'macro-cache':
            continue  # Full-stream aggregates below survive the display cap.
        facts.setdefault('compiler_event', []).append([
            step, event['phase'], event['kind'], event['site'], event['first'],
            event['second'], reference, event['line']])
    if trace['frontier'] is not None:
        event = trace['frontier']
        facts.setdefault('compiler_boundary', []).append([
            step, event['phase'], event['kind'], reference, event['line']])
    for metric, row in trace.get('workCounters', {}).items():
        facts.setdefault('compiler_event', []).append([
            step, 'frontend-work', 'count', metric, row['value'], 0, reference, row['line']])
    for phase, row in trace.get('phaseElapsed', {}).items():
        facts.setdefault('compiler_event', []).append([step, phase, 'elapsed-ns-total',
            'completed-wrapper-calls', row['inclusiveNanoseconds'], row['completedCalls'], reference, row['line']])
    macro = trace.get('macroCache', {})
    for row in macro.get('builds', []):
        if row['published']:
            facts.setdefault('compiler_event', []).append([step, 'macro-cache', row['classification'],
                'macro-list-table', row['buildId'], row['sharedCells'], reference, row['completedLine']])
            facts['compiler_event'].append([step, 'macro-cache', 'build-head',
                'macro-list-table', row['buildId'], row['headId'], reference, row['completedLine']])
            facts['compiler_event'].append([step, 'macro-cache', 'build-cache',
                'macro-list-table', row['buildId'], row['cacheId'], reference, row['completedLine']])
            facts['compiler_event'].append([step, 'macro-cache', 'build-phase',
                row['phase'], row['buildId'], 0, reference, row['completedLine']])
            if row['sharedCells']:
                facts['compiler_event'].append([step, 'macro-cache', 'shared-tail-owner',
                    'macro-list-table', row['buildId'], row['tailOwnerBuild'], reference, row['completedLine']])
    for row in macro.get('generations', []):
        facts.setdefault('compiler_event', []).append([step, 'macro-cache', row['kind'],
            'env-macros-set', row['oldHeadId'], row['headId'], reference, row['line']])
    for row in macro.get('names', []):
        facts.setdefault('compiler_event', []).append([step, 'macro-cache', 'generation-name',
            row['name'], row['headId'], 0, reference, row['line']])
