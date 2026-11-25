"""Typed output observations, not durable copies or reconstructions of logs.

Historical results remain recorded after cache collection. Their applicability
still requires the original receipt, model, source and protocol checks.
"""
import hashlib
import json
import math
import re
from copy import deepcopy
from functools import lru_cache
from pathlib import Path

from gambit_smp.quint_backend import admitted_model, counterexample, summarize

TRANSCRIPT_SUFFIXES = frozenset({'.log', '.stdout', '.stderr'})
REGISTRY = 'evidence/published-inputs.json'


class ObservationUnavailable(ValueError):
    pass


def observe(data):
    text = data.decode('utf-8', errors='replace')
    result = dict(schema='gambit.output-observation.v1',
                  sha256=hashlib.sha256(data).hexdigest(), bytes=len(data),
                  tlc=dict(completed=admitted_model(0, text, False, False),
                           invariantViolated=admitted_model(1, text, False, True),
                           temporalComplete='Finished checking temporal properties' in text,
                           states=summarize(text)),
                  suite=dict(completions=[int(n) for n in re.findall(r'^PASSED ALL (\d+) UNIT TESTS$', text, re.MULTILINE)],
                             failed='*** FAILED' in text))
    if result['tlc']['invariantViolated']:
        try:
            trace = counterexample(text)
            result['counterexample'] = dict(stateCount=len(trace['states']),
                statesSha256=hashlib.sha256(json.dumps(trace['states'], sort_keys=True).encode()).hexdigest())
        except ValueError: pass
    result['diagnosticCodes'] = sorted(set(re.findall(r'\bQNT\d+\b', text)))
    result['traceStateIndices'] = sorted({int(n) for n in re.findall(r'\[State (\d+)\]', text)})
    try:
        structured = json.loads(text)
        if (isinstance(structured, dict)
                and all(re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', key) for key in structured)
                and all(type(v) in (bool, int, float) and (not isinstance(v, float) or math.isfinite(v))
                        for v in structured.values())):
            result['structured'] = structured
    except ValueError: pass
    result['terminalTags'] = {tag: text.splitlines().count(tag)
                              for tag in set(re.findall(r'^[A-Z][A-Z0-9_-]+$', text, re.MULTILINE))}
    result['lineCount'] = len(text.splitlines())
    result['endsWithNewline'] = data.endswith(b'\n')
    result['buildPhases'] = {str(phase): text.splitlines().count(f'*** making phase{phase}')
                             for phase in range(1, 5)}
    result['bootstrapBeforeCore'] = ('make bootstrap' in text and 'make core' in text
                                    and text.index('make bootstrap') < text.index('make core'))
    result['linkerSymbols'] = sorted(set(re.findall(r'\b___LNK_[A-Za-z0-9_]+', text)))
    numbers = {}
    for key, value in re.findall(r'\b([A-Za-z][A-Za-z0-9_]*)=(-?\d+)(?![.\w])', text):
        numbers.setdefault(key, set()).add(int(value))
    result['diagnosticNumbers'] = {key: sorted(values) for key, values in sorted(numbers.items())}
    result['passedQuintTests'] = re.findall(r'\bok ([A-Za-z_][A-Za-z0-9_]*) passed\b', text)
    result['failures'] = dict(signals=[[name, int(hi), int(lo)] for name, hi, lo in
        re.findall(r'^\*\*\* FAILED (.+) WITH EXIT CODE HI=(\d+) LO=(\d+)$', text, re.MULTILINE)],
        assertions=re.findall(r'^"unit-tests/([^"\n]+)"@[^\n]*: FAILED ', text, re.MULTILINE))
    if 'probe.o1' in text:
        from gambit_smp.native_archive import compiler_invocation
        try: result['compilerInvocation'] = compiler_invocation(text)
        except ValueError: pass
    return result


@lru_cache(maxsize=4)
def _registry(raw):
    saved = json.loads(raw)
    if saved.get('schema') != 'published-evidence-inputs.v1':
        raise ValueError('registered publication inputs required')
    return saved.get('observations', {})


@lru_cache(maxsize=4)
def _origins(raw):
    result = {}
    for identity, observation in _registry(raw).items():
        if identity != observation.get('sha256'):
            raise ValueError('output observation content identity differs')
        for name in observation.get('origins', []):
            result.setdefault(name, []).append(identity)
    return result


def validate(observation, expected=None):
    fields = {'schema', 'sha256', 'bytes', 'tlc', 'suite', 'counterexample',
              'diagnosticCodes', 'traceStateIndices', 'structured', 'terminalTags',
              'lineCount', 'endsWithNewline', 'failures', 'compilerInvocation', 'origins',
              'buildPhases', 'bootstrapBeforeCore', 'linkerSymbols', 'diagnosticNumbers',
              'passedQuintTests'}
    if (not isinstance(observation, dict) or observation.get('schema') != 'gambit.output-observation.v1'
            or set(observation) - fields
            or type(observation.get('bytes')) is not int or observation['bytes'] < 0
            or not isinstance(observation.get('sha256'), str)
            or len(observation['sha256']) != 64
            or any(c not in '0123456789abcdef' for c in observation['sha256'])
            or expected is not None and observation['sha256'] != expected):
        raise ValueError('exact recorded output observation required')
    tlc = observation.get('tlc')
    if (not isinstance(tlc, dict)
            or set(tlc) != {'completed', 'invariantViolated', 'temporalComplete', 'states'}
            or any(type(tlc[k]) is not bool for k in ('completed', 'invariantViolated', 'temporalComplete'))
            or not isinstance(tlc['states'], dict)
            or tlc['states'] and (set(tlc['states']) != {'generated', 'distinct', 'queued'}
                or any(type(n) is not int or n < 0 for n in tlc['states'].values()))):
        raise ValueError('typed checker output properties required')
    structured = observation.get('structured', {})
    if (not isinstance(structured, dict)
            or any(not isinstance(k, str) or re.fullmatch(r'[A-Za-z][A-Za-z0-9_]*', k) is None
                   for k in structured)
            or any(type(v) not in (bool, int, float) or isinstance(v, float) and not math.isfinite(v)
                   for v in structured.values())):
        raise ValueError('typed numeric output properties required')
    return observation


def recorded(root, path, expected=None, *, outputs=None):
    """Read an explicit observation; never synthesize log text or a PASS."""
    root = Path(root).resolve()
    path = Path(path).resolve()
    if outputs is not None and path.name in outputs:
        return validate(outputs[path.name], expected)
    registry = root / REGISTRY
    if registry.is_file() and path.is_relative_to(root):
        raw = registry.read_bytes()
        items = _registry(raw)
        identities = _origins(raw).get(path.relative_to(root).as_posix(), [])
        identity = expected if expected in items else identities[0] if len(identities) == 1 else None
        item = items.get(identity)
        if item is not None:
            return deepcopy(validate(item, expected))
    # Producer-local/cache observations may be captured before publication.
    if path.is_file():
        return validate(observe(path.read_bytes()), expected)
    raise ObservationUnavailable('recorded output observation missing: ' + str(path))


def check_model(observation, row, *, temporal=None, decoded=False):
    validate(observation, row.get('logSha256'))
    tlc = observation['tlc']
    negative = row['variant'] == 'old'
    accepted = (type(row.get('exit')) is int and row.get('timeout') is False
                and (row['exit'] != 0 and tlc['invariantViolated'] if negative else
                     row['exit'] == 0 and tlc['completed'] and tlc['states'].get('queued') == 0))
    if not accepted:
        raise ValueError('recorded checker output does not support result')
    if row.get('states') and any(tlc['states'].get(k) != v for k, v in row['states'].items()):
        raise ValueError('recorded checker state count differs')
    if temporal and (negative or row.get('temporal') != temporal or not tlc['temporalComplete']):
        raise ValueError('complete temporal observation required')
    if decoded and negative and observation.get('counterexample', {}).get('stateCount', 0) < 2:
        raise ValueError('decoded counterexample observation required')
    return observation


def binding(root, path, expected):
    """Bind durable observations, never disposable cache availability."""
    root = Path(root).resolve(); path = Path(path).resolve()
    registry = root / REGISTRY
    if registry.is_file() and path.is_relative_to(root):
        raw = registry.read_bytes()
        if expected in _registry(raw):
            recorded(root, path, expected)
            return {REGISTRY: hashlib.sha256(raw).hexdigest()}
    if not path.is_file() or hashlib.sha256(path.read_bytes()).hexdigest() != expected:
        raise ValueError('output observation identity mismatch: ' + str(path))
    return {str(path.relative_to(root)): expected}
