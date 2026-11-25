"""Receipt-bound native rest cuts. Measurements are not an allocator model.

Python checks typed word/address measurements; native ASCENT joins the required
contracts and exposes counterevidence and missing premises. Neither layer grants
execution, Family A admission, or Family 6 acceptance.
"""
import hashlib
import json
from pathlib import Path
import re
import stat
import struct
import sys

from gambit_smp.framework import ROOT, digest, relative
from gambit_smp.recipes import fields, read_json, source_path


RULES = 'dev/modeling/ascent/rest-native-observation.rules.ss'
REST_REPORT = 'family6-rest-observation.v1'
REST_CONTEST_REPORT = 'family6-rest-observation.v2'
HEADER = struct.Struct('<8Q')
RECORD = struct.Struct('<16Q')
MAGIC = int.from_bytes(b'F6REST01', 'little')
KINDS = ('case-begin case-end heap-span stack-span argument-span preflight store pop snapshot '
         'pin source-read successor unpin roots root-value gc-begin gc-end reload saved-fp '
         'return-fp ready deliver lock capacity claim refuse unlock backing demand root-repaired '
         'body lock-request fp-adjust native-begin native-cut grant break-link section-view section-published '
         'watched-demand parent reload-installed retry-grant tail exit group-open group-enter '
         'group-backing group-demand group-saved group-unwound group-grant group-store '
         'group-adjust group-commit group-retired group-heap-grant').split()
SOURCES = ('lib/rest-observation.h', 'lib/_mem/rest-observation.inc',
           'lib/mem.c', 'lib/_mem/rc-allocation.inc', 'lib/_mem/heap-sections.inc',
           'lib/_mem/allocation-limits.inc', 'lib/_mem/collection-round.inc',
           'lib/_mem/rc-roots.inc',
           'lib/_mem/copy-reservations.inc', 'include/_gambit/stack_operations.h.in',
           'include/_gambit/object_access.h.in',
           'include/_gambit/runtime_protocols.h.in')
NATIVE_CUT_SOURCES = ('lib/_kernel.scm', 'lib/mem.h', 'lib/_mem/section-claim.inc',
                      'lib/_mem/memory-lifecycle.inc', 'include/_gambit/module_generation.h.in')
OBLIGATIONS = {
    6: ('physical-intervals', 'whole-snapshot', 'refusal-effects', 'exact-or-short', 'grant-before-store'),
    7: ('cross-break-custody', 'pin-balanced', 'successor-before-release',
        'last-old-source-read-before-release'),
    8: ('complete-root-window', 'moving-gc-repair', 'reload-before-delivery',
        'root-aliases-and-label', 'handler-spelling', 'parent-owner-epoch',
        'retry-coordinates', 'renewed-grant-before-effects', 'single-delivery'),
    9: ('real-contention', 'locked-capacity-claim', 'unique-last-section', 'loser-preserves-winner',
        'winner-post-unlock-publication', 'winner-renewed-grant'),
}
ROUTES = {
    6: ('lib/_mem/rc-allocation.inc:rest_interval_fits', 'inspect-full-footprint-and-first-effect'),
    7: ('lib/_mem/heap-sections.inc:___rest_caller_chain', 'inspect-pin-successor-and-last-source-use'),
    8: ('lib/_mem/rc-allocation.inc:___rest_span_reload', 'inspect-root-repair-and-retry-coordinates'),
    9: ('lib/_mem/heap-sections.inc:___rest_extend_interval', 'inspect-locked-check-claim-and-loser-exit'),
}
CUT_ROUTES = {
    'handler-spelling': ('lib/_kernel.scm', 'inspect-ordinary-keyword-and-dsssl-handler-mode'),
    'parent-owner-epoch': ('lib/_mem/collection-round.inc', 'compare-frozen-and-restored-parent-owner'),
    'renewed-grant-before-effects': ('lib/_mem/rc-allocation.inc:___rest_grant_fits',
                                     'compare-installed-roots-and-first-construction-effect'),
    'single-delivery': ('lib/_kernel.scm', 'compare-ready-delivery-tail-and-body'),
    'exact-or-short': (
        'lib/_kernel.scm', 'compare-full-preflight-with-physical-tail-and-refusal-cut'),
    'refusal-effects': (
        'lib/_kernel.scm', 'inspect-first-effect-before-terminal-refusal'),
    'last-old-source-read-before-release': (
        ROUTES[7][0], 'inspect-actual-break-link-and-last-pinned-read'),
    'real-contention': (
        'lib/_kernel.scm', 'check-two-post-reload-physical-shortages-before-claim'),
    'unique-last-section': (
        ROUTES[9][0], 'compare-both-locked-admission-bounds-with-loser-refusal'),
    'winner-post-unlock-publication': (
        ROUTES[9][0], 'compare-locked-claim-with-post-unlock-heap-view'),
    'winner-renewed-grant': (
        'lib/_mem/rc-allocation.inc:___rest_grant_fits', 'check-same-attempt-reload-and-full-grant'),
}
QUERIES = {name: 'rest_' + name for name in ('violation', 'missing', 'observed_cut', 'repair_target')}
SHA = re.compile('[0-9a-f]{64}')
RECIPE_SITUATIONS = {6: ('short', 'exact'), 7: ('cross-break',), 8: ('moving-gc',), 9: ('race',)}


def validate_options(options, inputs):
    if 'case' in options:
        fields(options, ('case', 'capacity', 'rules'))
        case = options['case']
        fields(case, ('id', 'checklist', 'spelling', 'situation'))
        if (type(case['id']) is not int or not 0 < case['id'] < 2**64
                or type(case['checklist']) is not int
                or case['situation'] not in RECIPE_SITUATIONS.get(case['checklist'], ())
                or not isinstance(case['spelling'], str) or case['spelling'] not in REST_FORMS
                or (case['checklist'] in (7, 9) and case['spelling'] != 'ordinary')
                or type(options['capacity']) is not int or not 1 <= options['capacity'] <= 1000000):
            raise ValueError('runtime-derived rest observations require one bounded native case')
    else:
        fields(options, ('contract', 'rules'))
        if (not isinstance(options['contract'], str)
            or options['contract'] not in inputs or not options['contract'].endswith('.json')):
            raise ValueError('declared native rest contract required')
    if options['rules'] != RULES or options['rules'] not in inputs:
        raise ValueError('declared maintained ASCENT rules required')


def required_sources(cases, *, handler_form=None):
    if any(c.get('checklist') in (7, 8, 9) for c in cases):
        return (*SOURCES, *NATIVE_CUT_SOURCES, 'lib/_mem/continuation-roots.inc')
    if handler_form is not None or any(c.get('checklist') == 6 and c.get('situation') == 'short' for c in cases):
        return (*SOURCES, *NATIVE_CUT_SOURCES)
    return SOURCES


def validate_contract(contract):
    fields(contract, ('schema', 'gsiSha256', 'sourceFiles', 'capacity', 'cases'), ('handlerForm',))
    if contract['schema'] != 'family6-rest-observation-contract.v1':
        raise ValueError('native rest observation contract version required')
    if (type(contract['capacity']) is not int or not 1 <= contract['capacity'] <= 1000000
            or not isinstance(contract['gsiSha256'], str) or not SHA.fullmatch(contract['gsiSha256'])):
        raise ValueError('bounded trace capacity and exact GSI digest required')
    sources = contract['sourceFiles']
    if (not isinstance(sources, dict) or not set(SOURCES) <= set(sources)
            or any(not isinstance(p, str) or Path(p).is_absolute() or '..' in Path(p).parts
                   or not isinstance(s, str) or not SHA.fullmatch(s) for p, s in sources.items())):
        raise ValueError('complete native observer/source binding required')
    if not isinstance(contract['cases'], list) or not 1 <= len(contract['cases']) <= 4096:
        raise ValueError('nonempty bounded native case inventory required')
    ids = set()
    for case in contract['cases']:
        fields(case, ('id', 'checklist', 'spelling', 'situation'))
        n = case['checklist']
        if (type(case['id']) is not int or not 0 < case['id'] < 2**64 or case['id'] in ids
                or type(n) is not int or n not in OBLIGATIONS
                or case['spelling'] not in ('ordinary', 'optional', 'keyword')
                or case['situation'] not in {6: ('exact', 'short', 'invalid'), 7: ('cross-break',),
                                             8: ('moving-gc',), 9: ('race',)}[n]):
            raise ValueError('unique native case with a checklist-specific situation required')
        ids.add(case['id'])
    if not set(required_sources(contract['cases'], handler_form=contract.get('handlerForm'))) <= sources.keys():
        raise ValueError('complete native rest cut sources required')
    if 'handlerForm' in contract and (len(contract['cases']) != 1 or
            contract['cases'][0]['checklist'] != 6 or
            contract['handlerForm'] != REST_FORMS[contract['cases'][0]['spelling']]):
        raise ValueError('native boundary must attest its declared handler form')
    return contract


def contract_from_identity(identity, cases, *, capacity, handler_form=None):
    """Construct declared probe data; never scan, compile, dispatch or admit."""
    if identity.get('schema') != 'gambit-recipe-runtime-identity.v1':
        raise ValueError('existing native runtime identity required')
    sources = required_sources(cases, handler_form=handler_form)
    missing = set(sources)-set(identity.get('sourceFiles', {}))
    if missing:
        raise ValueError('native producer lacks observation sources: '+', '.join(sorted(missing)))
    return validate_contract(dict(schema='family6-rest-observation-contract.v1',
        gsiSha256=identity['binarySha256'], sourceFiles={p: identity['sourceFiles'][p] for p in sources},
        cases=cases, capacity=capacity,
        **({'handlerForm': handler_form} if handler_form is not None else {})))


def create_trace(path, capacity):
    with Path(path).open('xb') as stream:
        stream.write(HEADER.pack(MAGIC, 1, capacity, 0, 0, 0, 16, 0))
        stream.truncate(HEADER.size + RECORD.size * capacity)
    info = Path(path).stat()
    return [info.st_dev, info.st_ino]


def decode_trace(raw):
    if len(raw) < HEADER.size:
        raise ValueError('truncated native rest header')
    magic, version, capacity, reserved, dropped, closed, width, padding = HEADER.unpack_from(raw)
    if (magic != MAGIC or version != 1 or not 1 <= capacity <= 1000000
            or width != 16 or padding or closed not in (0, 1)
            or len(raw) != HEADER.size + RECORD.size * capacity
            or reserved > capacity or (dropped and reserved != capacity)):
        raise ValueError('native rest geometry, version, or overflow accounting changed')
    events, holes = [], []
    for i in range(min(reserved, capacity)):
        row = RECORD.unpack_from(raw, HEADER.size + RECORD.size * i)
        if row[0] == 0:
            holes.append(i + 1)
            continue
        if row[0] != i + 1 or not 1 <= row[1] <= len(KINDS) or row[15] or not row[2]:
            raise ValueError('invalid native rest commit, kind, case, or reserved field')
        events.append(dict(seq=row[0], kind=KINDS[row[1] - 1], case=row[2], actor=row[3],
                           activation=row[4], attempt=row[5], epoch=row[6], values=list(row[7:15])))
    if any(raw[HEADER.size+RECORD.size*reserved:]):
        raise ValueError('native rest writer modified unreserved records')
    return dict(events=events, reserved=reserved, dropped=dropped, holes=holes,
                closed=bool(closed), complete=bool(closed and not dropped and not holes),
                digest=hashlib.sha256(raw).hexdigest())


def _measure(case, events, *, handler_form=None, legacy_contest=False):
    """Check actual measurements, keeping missing premises distinct from false."""
    checks = []
    by_kind = {}
    for e in events:
        by_kind.setdefault(e['kind'], []).append(e)

    def rows(kind):
        return by_kind.get(kind, [])

    def add(name, condition, evidence=(), detail=''):
        ids = sorted({e['seq'] for e in evidence})
        checks.append(dict(obligation=name, status='missing' if condition is None else
                           ('pass' if condition else 'fail'),
                           events=ids[:64], eventCount=len(ids),
                           eventSpan=[ids[0], ids[-1]] if ids else [], detail=detail))

    if case['checklist'] == 6:
        short = case['situation'] == 'short'
        native_boundary = handler_form is not None
        begin, cut = rows('native-begin'), rows('native-cut')
        sliced = (len(begin) == len(cut) == 1 and
                  begin[0]['actor'] == cut[0]['actor'] != 0 and begin[0]['seq'] < cut[0]['seq'])
        def inside(e):
            return sliced and begin[0]['seq'] < e['seq'] < cut[0]['seq']
        def same_actor(e):
            return bool(begin and e['actor'] == begin[0]['actor'])
        def during_candidate(e):
            return same_actor(e) and begin[0]['seq'] < e['seq'] and (not cut or inside(e))
        spans = {kind: [e for e in rows(kind) if not (short or native_boundary) or
                       same_actor(e) and e['seq'] > begin[0]['seq']]
                 for kind in ('heap-span', 'stack-span', 'argument-span')}
        first = {k: v[0] for k, v in spans.items() if v}
        valid = bool(len(first) == 3) and all(
            e['actor'] and e['values'][0] <= e['values'][2] <= e['values'][1]
            and all(value % 8 == 0 for value in e['values'][:3])
            for e in first.values())
        if valid and short:
            h = first['heap-span']['values']
            valid = h[1] <= h[3] and h[3] % 8 == 0
        add('physical-intervals', valid if len(first) == 3 else None, first.values())
        complete, equal, evidence, changed_words = True, True, [], []
        for region, kind in enumerate(('heap-span', 'stack-span', 'argument-span'), 1):
            span = first.get(kind)
            if span is None:
                complete = False
                continue
            lo, hi = span['values'][:2]
            # Heap soft and hard bounds are distinct; snapshot the full physical
            # interval, including the word that a soft-limit refusal protects.
            if region == 1:
                hi = span['values'][3]
            if hi < lo or (hi - lo) // 8 > 1000000:
                complete = False
                continue
            snapshots = [{}, {}]
            for e in rows('snapshot'):
                r, phase, address, value, base, count = e['values'][:6]
                if r != region or e['actor'] != span['actor']:
                    continue
                evidence.append(e)
                if (phase not in (0, 1) or base != lo or count != (hi-lo)//8
                        or not lo <= address < hi or address % 8 or address in snapshots[phase]
                        or (short or native_boundary) and
                        (not sliced or (not inside(e) if phase == 0 else e['seq'] <= cut[0]['seq']))):
                    complete = False
                else:
                    snapshots[phase][address] = value
            if len(snapshots[0]) != (hi-lo)//8 or snapshots[0].keys() != snapshots[1].keys():
                complete = False
            equal = equal and snapshots[0] == snapshots[1]
            changed = {address for address in snapshots[0].keys() & snapshots[1].keys()
                       if snapshots[0][address] != snapshots[1][address]}
            changed_words.extend(e for e in evidence if e['values'][0] == region and e['values'][2] in changed)
        add('whole-snapshot', complete if len(first) == 3 else None, evidence,
            'Every physical heap/stack/argument word must occur exactly once in each cut.')
        negative = case['situation'] in ('short', 'invalid')
        effects = [e for e in rows('store') + rows('pop') if inside(e) and same_actor(e)]
        recovery = [e for k in ('gc-begin', 'roots', 'lock-request', 'deliver', 'body') for e in rows(k)
                    if inside(e) and same_actor(e)]
        adjusts = [e for e in rows('fp-adjust') if inside(e) and same_actor(e) and e['values'][2]]
        arguments = spans['argument-span']
        cursor_same = (len(arguments) == 2 and arguments[0]['values'][:3] == arguments[1]['values'][:3]
                       and [e['values'][3] for e in arguments] == [0, 1] and
                       (not short or inside(arguments[0]) and sliced and
                        arguments[1]['seq'] > cut[0]['seq'] and
                        arguments[0]['values'][0] == arguments[0]['values'][2] == begin[0]['values'][1]))
        short_effects = effects + recovery + adjusts if short else effects
        same_coordinates = sliced and begin[0]['values'][:2] == cut[0]['values'][:2]
        no_effects = True
        if negative:
            no_effects = None
            if short_effects:
                no_effects = False
            elif complete and sliced:
                no_effects = equal and cursor_same and (not short or same_coordinates)
        add('refusal-effects', no_effects, [*short_effects, *arguments, *changed_words],
            'A snapshot equality alone cannot exclude write-and-restore; store/pop coverage is separate.')
        flights = [e for e in rows('preflight') if during_candidate(e)]
        demands = [e for e in rows('watched-demand') if during_candidate(e)]
        good = None
        if flights:
            p = flights[0]
            words, slots, grant, reason, hp, fp = p['values'][:6]
            heap, stack = first.get('heap-span'), first.get('stack-span')
            if case['situation'] == 'invalid':
                good = grant == 0 and reason == 2
            elif heap and stack:
                heap_left = (heap['values'][1]-hp)//8
                stack_left = (fp-stack['values'][0])//8
                if not negative:
                    good = (grant == 1 and heap_left >= words and stack_left >= slots
                            and (heap_left == words or stack_left == slots))
                    if native_boundary:
                        demand = demands[0]['values'] if demands else None
                        good = None if not demands or not sliced else (
                            len(demands) == len(flights) == 1 and not recovery and
                            demands[0]['seq'] < p['seq'] and
                            demand[:3] == [hp, fp, words] and begin[0]['values'][:2] == [hp, fp] and
                            words > 0 and all(demand[5:8]) and
                            words == demand[3]*demand[6]+demand[4]+demand[7] and
                            heap['values'][3]-hp == 8*(words+demand[5]) and
                            grant == 1 and reason == 0 and heap_left >= words and
                            stack_left >= slots and cut[0]['values'][2] == 0)
                elif len(demands) == 1:
                    dhp, dfp, total, pending, np, reserve, pair, vector = demands[0]['values']
                    hard_bytes = heap['values'][3]-hp
                    usable_tail = max(hard_bytes//8-reserve, 0)
                    geometry = (demands[0]['seq'] < p['seq'] and
                            (dhp, dfp, total) == (hp, fp, words) and begin[0]['values'][:2] == [hp, fp] and
                            words > 0 and pair > 0 and vector > 0 and
                            reserve > 0 and words == pending*pair+np+vector and
                            hard_bytes >= 0 and hard_bytes % 8 == 0 and
                            usable_tail == heap_left == words-1 and stack_left >= slots)
                    good = (geometry and len(flights) == 1 and grant == 0 and reason == 1 and
                            cut[0]['values'][:4] == [hp, fp, 9, pending]) if sliced else (
                                False if not geometry or grant == 1 else None)
                elif demands:
                    good = False
        if native_boundary and begin:
            if (begin[0]['values'][4] != handler_form or
                    sliced and cut[0]['values'][4] != handler_form):
                good = False
        add('exact-or-short', good, [*begin, *flights, *demands, *cut],
            'Short means actual cut 9 with one word missing after the physical reserve and no cursor change.')
        arg_end = arguments[0]['values'][1] if native_boundary and arguments else None
        def covered(e, p):
            hp, fp, address = p['values'][4], p['values'][5], e['values'][1]
            if arg_end is not None:
                if e['kind'] == 'pop':
                    return fp-8*p['values'][1] <= e['values'][0] < arg_end
                if e['values'][0]:
                    return fp-8*p['values'][1] <= address < arg_end
                return hp <= address < hp+8*p['values'][0]
            return hp <= address < hp+8*p['values'][0] or fp-8*p['values'][1] <= address < fp
        add('grant-before-store', all(any(p['seq'] < e['seq'] and p['actor'] == e['actor']
            and p['values'][2] == 1 and covered(e, p)
            for p in flights) for e in effects) if sliced and flights and (negative or effects) else None,
            [*flights, *effects])

    elif case['checklist'] == 7:
        _measure_custody(events, rows, add)

    elif case['checklist'] == 8:
        _measure_moving_rest(case, rows, add)

    elif case['checklist'] == 9:
        _measure_contest(events, rows, add, legacy=legacy_contest)
    return checks


def _attempt(event):
    return tuple(event[name] for name in ('actor', 'activation', 'attempt', 'epoch'))


def _has_attempt(event):
    return all(_attempt(event)[:3])


REST_FORMS = {'ordinary': 1, 'optional': 2, 'keyword': 3}


def _measure_moving_rest(case, rows, add):
    expected = REST_FORMS[case['spelling']]
    starts = [e for e in rows('parent') if e['values'][0] == 0]
    body_keys = {_attempt(e) for e in rows('body')}
    # Prefer the invocation whose actual callee marked entry. In a failed run
    # the handler's observed form still selects its diagnostic prefix.
    target = body_keys or {_attempt(e) for e in starts if e['values'][6] == expected}
    if not target:
        target = {_attempt(e) for e in starts}
    ambiguous = len(target) > 1
    key = next(iter(target)) if len(target) == 1 else None
    def scoped(kind):
        return [e for e in rows(kind) if key and _attempt(e) == key]
    def one(kind):
        selected = scoped(kind)
        return selected[0] if len(selected) == 1 else None

    parent = scoped('parent')
    actor = key[0] if key else None
    roots = one('roots')
    phases = [[e for e in parent if e['values'][0] == phase] for phase in range(4)]
    entered, frozen, restored, returns = phases
    spelling = None
    if ambiguous or entered:
        spelling = (not ambiguous and all(key) and all(e['values'][6] == expected for e in entered))
    add('handler-spelling', spelling, starts)

    rounds = []
    owner = coords = None
    if roots and entered and frozen and restored:
        owner = (len(entered) == len(frozen) == len(restored) and all(
            v['values'][1] == roots['values'][7] != 0 and v['values'][2] != 0 and
            v['values'][3] != 0 and v['values'][4] == actor for v in parent))
        for entry, before, after in zip(entered, frozen, restored):
            bv, av = before['values'], after['values']
            gc_b = [e for e in rows('gc-begin') if e['actor'] == actor and e['epoch'] == bv[6]
                    and entry['seq'] < e['seq'] < before['seq']]
            gc_e = [e for e in rows('gc-end') if e['actor'] == actor and e['epoch'] == av[6]
                    and before['seq'] < e['seq'] < after['seq']]
            if len(gc_b) != 1 or len(gc_e) != 1:
                owner = False
                continue
            b, e = gc_b[0], gc_e[0]
            owner = (owner and roots['seq'] < entry['seq'] and
                     entry['values'][1:6] == bv[1:6] and entry['values'][7] == bv[7] and
                     b['values'][:3] == [e['values'][0], bv[2], bv[7]] and
                     e['values'][1:4] == [av[2], 0, av[7]] and
                     b['epoch'] == e['epoch'] == bv[6] == av[6] != 0 and av[7] > bv[7] and
                     (not rounds or rounds[-1][2]['seq'] < entry['seq']))
            rounds.append((b, e, after))
        if returns:
            ret = returns[0]
            coords = (len(returns) == 1 and restored[-1]['seq'] < ret['seq'] and
                      restored[-1]['values'][1:2]+restored[-1]['values'][3:6] ==
                      ret['values'][1:2]+ret['values'][3:6] and
                      ret['values'][6] == roots['values'][2] and
                      restored[-1]['values'][2] == ret['values'][2]+8*ret['values'][6] and
                      restored[-1]['values'][7] == ret['values'][7])
    add('parent-owner-epoch', owner, parent + rows('gc-begin') + rows('gc-end'))

    raw, installed = scoped('reload'), scoped('reload-installed')
    root_values = scoped('root-value')
    full = movement = aliases = reload_order = None
    install = installed[-1] if installed else None
    if roots and raw and install and rounds:
        last_raw = raw[-1]
        count = roots['values'][1]
        phase0 = [e for e in root_values if e['values'][2] == 0]
        phase1 = [e for e in root_values if e['values'][2] == 1 and
                  last_raw['seq'] < e['seq'] < install['seq']]
        written = [e for e in root_values if e['values'][2] == 2 and
                   last_raw['seq'] < e['seq'] < install['seq']]
        n, k = roots['values'][2:4]
        full = (count == 2+n+k == last_raw['values'][4] and
                roots['values'][0] != 0 and roots['values'][5] != 0 and
                roots['values'][6] != 0 and last_raw['values'][1:4] == [n, install['values'][2], k] and
                install['values'][1] == n and install['values'][3] == k and
                (n == 0 or last_raw['values'][0] != 0) and (k == 0 or install['values'][2] != 0) and
                len(phase0) == len(phase1) == len(written) == count and
                all(roots['seq'] < e['seq'] < rounds[0][0]['seq'] for e in phase0) and
                all([e['values'][0] for e in values] == list(range(len(values)))
                    for values in (phase0, phase1, written)) and
                [e['values'][1] for e in written] == [e['values'][1] for e in phase1])
        if full:
            old = [e['values'][1] for e in phase0] + [roots['values'][4]]
            new = [e['values'][1] for e in phase1] + [last_raw['values'][5]]
            cells = [roots['values'][0]+8*i for i in range(count)] + [roots['values'][5]]
            by_cell = {}
            for event in rows('root-repaired'):
                if any(b['seq'] < event['seq'] < e['seq'] and
                       event['values'][3:6] == [roots['values'][6], b['values'][0], b['epoch']] and
                       event['epoch'] == e['values'][3] for b, e, _ in rounds):
                    by_cell.setdefault(event['values'][0], []).append(event)
            changes = []
            for cell, before, after in zip(cells, old, new):
                changes.append((before, after, by_cell.get(cell, [])))
            moved = any(a != b for a, b, _ in changes)
            movement = (all((h and h[0]['values'][1] == a and h[-1]['values'][2] == b and
                            all(l['values'][2] == r['values'][1] for l, r in zip(h, h[1:])))
                            if h or a != b else True for a, b, h in changes) if moved else None)
            aliases = (len(set(old)) == len(set(new)) == len(set(zip(old, new))) and
                       install['values'][4:7] == [new[-1], new[0], new[-2]])
        if returns:
            ret = returns[0]
            reload_order = (ret['seq'] < last_raw['seq'] < install['seq'] and
                            install['values'][0] == ret['values'][2] and
                            install['values'][7] == ret['values'][7] and
                            not any(e['actor'] == actor and restored[-1]['seq'] < e['seq'] < install['seq']
                                    for e in rows('gc-begin')))
    add('retry-coordinates', coords, parent + installed)
    add('complete-root-window', full, scoped('roots') + root_values + raw + installed)
    add('moving-gc-repair', movement, rows('gc-begin') + rows('root-repaired') + rows('gc-end'))
    add('root-aliases-and-label', aliases, scoped('roots') + root_values + raw + installed)

    ready, delivery, tail, body = (one(kind) for kind in ('ready', 'deliver', 'tail', 'body'))
    ordered = None
    if install and ready and delivery and tail and body:
        ordered = (reload_order is True and
                   install['seq'] < ready['seq'] < delivery['seq'] < tail['seq'] < body['seq'] and
                   not any(e['actor'] == actor and install['seq'] < e['seq'] < tail['seq']
                           for e in rows('gc-begin')))
    add('reload-before-delivery', ordered, raw + installed + scoped('ready') + scoped('body'))
    exits = scoped('exit')
    once = None
    if ambiguous or exits or any(len(scoped(k)) > 1 for k in ('ready', 'deliver', 'tail', 'body')):
        once = False
    elif ready and delivery and tail and body and install:
        once = (ready['seq'] < delivery['seq'] < tail['seq'] < body['seq'] and
                ready['values'][0] == delivery['values'][0] == tail['values'][1] and
                tail['values'][0] == install['values'][4] != 0)
    add('single-delivery', once, scoped('ready') + scoped('deliver') + scoped('tail') + scoped('body') + exits)

    grants = scoped('retry-grant')
    effects = []
    grant_ok = None
    if install and ready and restored:
        effects = sorted([e for kind in ('store', 'pop') for e in rows(kind)
                          if e['actor'] == actor and restored[-1]['seq'] < e['seq'] < ready['seq']],
                         key=lambda e: e['seq'])
        current = [e for e in grants if install['seq'] < e['seq'] < ready['seq']]
        if effects and not current:
            grant_ok = False
        if current and effects:
            g = current[-1]
            rnd, hp, soft, fp, lo, hi, words, slots = g['values']
            limit = hp+8*words
            grant_ok = (len(current) == 1 and g['seq'] < effects[0]['seq'] and
                        rnd == install['values'][7] and fp == install['values'][0] and
                        0 < hp < limit <= soft and 0 < lo <= fp-8*slots <= fp <= hi and
                        not any(e['actor'] == actor and install['seq'] < e['seq'] < ready['seq']
                                for e in rows('gc-begin')) and
                        any(e['kind'] == 'store' and e['values'][0] == 0 for e in effects) and
                        all((fp <= e['values'][0] < min(hi, fp+8*install['values'][1]))
                            if e['kind'] == 'pop' else
                            (fp-8*slots <= e['values'][1] < fp if e['values'][0] else
                             hp <= e['values'][1] < limit) for e in effects))
    add('renewed-grant-before-effects', grant_ok, installed + grants + effects + scoped('ready'))


def _measure_custody(events, rows, add):
    active, released = {}, {}
    pairs, pairing_errors, custody_errors = [], [], []
    crossings = [e for e in rows('successor') if e['values'][6] == 1]
    for e in events:
        kind, v = e['kind'], e['values']
        key = (*_attempt(e), v[0], v[1])
        if kind == 'pin':
            if key in active or not _has_attempt(e) or not v[0] or not v[2] or not 0 < v[4] < v[5]:
                pairing_errors.append(e)
                continue
            active[key] = dict(pin=e, read=None, link=None, successor=None)
            released.pop(key, None)
        elif kind in ('source-read', 'break-link'):
            state = active.get(key)
            if state is None:
                if kind == 'break-link' or key in released:
                    custody_errors.append(e)
                continue
            pin = state['pin']['values']
            if v[2] != pin[2] or not pin[4] <= v[3] < pin[5] or (v[3]-pin[4]) % 8:
                custody_errors.append(e)
            if kind == 'break-link':
                if (state['link'] is not None or state['successor'] is not None or
                        not all(v[4:7]) or v[7] != 8 or v[3] != v[5]+v[6]*v[7]):
                    custody_errors.append(e)
                state['link'] = e
            else:
                state['read'] = e
        elif kind == 'successor' and v[6] == 1:
            old = (*_attempt(e), v[4], v[5])
            state = active.get(old)
            if (state is None or state['successor'] is not None or
                    not all((v[0], v[2], v[3])) or old == key):
                custody_errors.append(e)
                continue
            link = state['link']
            if link is not None and link['values'][4] != v[3]:
                custody_errors.extend((link, e))
            state['successor'] = e
        elif kind == 'unpin':
            state = active.pop(key, None)
            if state is None:
                pairing_errors.append(e)
            elif state['successor'] is not None:
                if v[2] != 0:
                    custody_errors.append(e)
                pairs.append((state['pin'], state['read'], state['link'], state['successor'], e))
                released[key] = e
            elif v[2] == 0:
                # A handoff release with no observed successor is unsupported.
                released[key] = e
    witnesses = [e for pair in pairs for e in pair if e is not None]
    complete = bool(pairs and len(pairs) == len(crossings) and
                    all(read and link for _, read, link, _, _ in pairs))
    errors = pairing_errors + custody_errors
    add('pin-balanced', not active and not pairing_errors if rows('pin') or pairing_errors else None,
        [*rows('pin'), *rows('unpin'), *pairing_errors])
    add('cross-break-custody', False if errors else True if complete else None,
        [*witnesses, *crossings, *errors])
    add('successor-before-release', False if errors else True if complete else None,
        [*crossings, *rows('unpin'), *errors])
    add('last-old-source-read-before-release', False if errors else True if complete else None,
        [*witnesses, *errors],
        'Require an old-section frame read and its actual break-link read under the old pin.')


def _last_section(winner_lock, loser_lock, capacity, winner, loser, request):
    """Reconstruct the section bound used by the two locked decisions."""
    win_vm, _, assigned, total, cap_bytes, still, section_words, candidate = winner_lock
    lose_vm, _, after, lose_total, lose_cap, lose_still, lose_words, successor = loser_lock
    if not section_words or not lose_words:
        return None, 'Both locks must record the heap cap, still words, section size and next candidate.'
    guard = request['values'][5]
    if (win_vm != lose_vm or (total, cap_bytes, still, section_words) !=
            (lose_total, lose_cap, lose_still, lose_words) or not 0 <= assigned < after <= total
            or still >= 2**63 or section_words % 2 or section_words // 2 <= guard
            or not candidate or candidate != capacity[1] or successor != capacity[6]
            or bool(successor) != (after < total) or winner[2] != section_words // 2 - guard):
        return False, 'Locked pool, admission inputs, next candidate or fresh-section room disagree.'

    cap_words = cap_bytes // 8
    if cap_bytes and cap_words < still:
        return False, 'The heap cap is below the occupied still words.'
    ceiling = (cap_words - still) // section_words if cap_bytes else None
    limit = total if ceiling is None else min(total, ceiling)
    before_slots, after_slots = max(0, limit - assigned), max(0, limit - after)
    expected_refusal = 1 if ceiling is not None and after >= ceiling else 2
    detail = (f'Locked admission slots {before_slots} -> {after_slots}. '
              f'Loser refusal {loser[3]}, expected {expected_refusal}.')
    return (before_slots == 1 and after_slots == 0 and loser[3] == expected_refusal), detail


def _measure_contest(events, rows, add, *, legacy=False):
    requests, locks, claims = rows('lock-request'), rows('lock'), rows('claim')
    refusals, unlocks = rows('refuse'), rows('unlock')
    capacities, publications = rows('capacity'), rows('section-published')
    owned, locked_errors, request_views, latest_view = {}, [], {}, {}
    view_by_attempt = {}
    for e in events:
        kind, v, attempt = e['kind'], e['values'], _attempt(e)
        if kind == 'section-view':
            latest_view[attempt] = e
            view_by_attempt.setdefault(attempt, []).append(e)
        elif kind == 'lock-request':
            request_views[e['seq']] = latest_view.get(attempt)
        elif kind == 'lock':
            resource = (v[0], e['epoch'])
            if not v[0] or not _has_attempt(e) or resource in owned:
                locked_errors.append(e)
            owned[resource] = attempt
        elif kind in ('capacity', 'claim', 'refuse', 'unlock'):
            resource = (v[0], e['epoch'])
            if owned.get(resource) != attempt:
                locked_errors.append(e)
            if kind == 'unlock':
                owned.pop(resource, None)

    def legal(request, view):
        vm, processor, demand, hp, hard, guard, fp, _ = request['values']
        section, _, old_hp, soft, old_hard, old_fp, words, flags = view['values']
        return bool(_has_attempt(request) and vm and section and hp and soft and fp and demand and guard and
                    (hp, hard, fp, demand) == (old_hp, old_hard, old_fp, words) and flags == 6 and
                    hp <= hard and soft <= hard and max(soft-hp, 0) < 8*demand and
                    (hard-hp) % 8 == 0 and hard-hp < 8*(guard+demand))

    real = None
    request_attempts = {_attempt(e) for e in requests}
    views = [request_views[e['seq']] for e in requests]
    if len(requests) > 2 or len(requests) == 2 and (
            len({e['actor'] for e in requests}) != 2 or
            len({(e['values'][0], e['epoch']) for e in requests}) != 1 or
            requests[0]['values'][1] == requests[1]['values'][1]):
        real = False
    elif len(requests) == 2 and locks and claims:
        real = (request_attempts == {_attempt(e) for e in locks} and
                all(e['values'][0] == requests[0]['values'][0] for e in locks) and
                all(e['seq'] < claims[0]['seq'] for e in requests) and
                all(any(_attempt(r) == _attempt(lock) and r['seq'] < lock['seq']
                        for r in requests) for lock in locks))
        if real:
            real = all(legal(r, v) for r, v in zip(requests, views)) if all(views) else None
    add('real-contention', real, [*requests, *[v for v in views if v], *locks, *claims],
        'Two bound post-reload physical shortages must request the same VM/epoch before the claim.')

    locked = last = preserved = None
    last_detail = ''
    winner = None
    core = [*locks, *capacities, *claims, *refusals, *unlocks]
    if locked_errors or owned or any(len(group) > n for group, n in
            ((locks, 2), (capacities, 1), (claims, 1), (refusals, 1), (unlocks, 2))):
        locked = False
        if not legacy and len(claims) > 1:
            last = False
    elif (len(locks) == len(unlocks) == 2 and
          len(capacities) == len(claims) == len(refusals) == 1):
        winner, loser, capacity = claims[0], refusals[0], capacities[0]
        win_lock, lose_lock = locks
        win_unlock, lose_unlock = unlocks
        w, c, wl, l, ll = (e['values'] for e in (winner, capacity, win_lock, loser, lose_lock))
        locked = (_attempt(win_lock) == _attempt(capacity) == _attempt(winner) == _attempt(win_unlock) and
                  _attempt(lose_lock) == _attempt(loser) == _attempt(lose_unlock) and
                  win_lock['seq'] < capacity['seq'] < winner['seq'] < win_unlock['seq'] <
                  lose_lock['seq'] < loser['seq'] < lose_unlock['seq'] and
                  c[1] == w[1] == w[4] and bool(w[1]) and c[2] == w[3] and
                  c[4:6] == wl[1:3] and w[5] == wl[2]+1 and bool(w[6]) and c[7] == w[7] and
                  w[2] >= w[3] > 0 and l[1:3] == ll[1:3])
        preserved = w[4:6] == ll[1:3] == l[1:3]
        if len(requests) == 2 and real is not None:
            winner_request = next((r for r in requests if _attempt(r) == _attempt(winner)), None)
            loser_request = next((r for r in requests if _attempt(r) == _attempt(loser)), None)
            last = bool(real and locked and preserved and winner_request and loser_request and
                        c[2:4] == [winner_request['values'][2], winner_request['values'][6]] and
                        0 < loser_request['values'][2] <= w[2])
            if legacy:
                last = last and c[6] == 0 and wl[3] == w[5] == ll[2] == ll[3] and l[3] in (1, 2)
            elif last:
                if winner_request['values'][5] != loser_request['values'][5]:
                    last, last_detail = False, 'Contenders report different fresh-section guards.'
                else:
                    last, last_detail = _last_section(wl, ll, c, w, l, winner_request)
    add('locked-capacity-claim', locked, [*core, *locked_errors])
    add('unique-last-section', last, [*requests, *core], last_detail)
    add('loser-preserves-winner', preserved, [*claims, *locks, *refusals])

    published = renewed = None
    after_views = []
    if len(publications) > 1:
        published = False
    elif winner is not None and publications:
        publication = publications[0]
        v, w = publication['values'], winner['values']
        hp, soft, hard, demand, guard = v[3:8]
        request = next((r for r in requests if _attempt(r) == _attempt(winner)), None)
        if request is not None:
            published = (locked and _attempt(publication) == _attempt(winner) and
                         unlocks[0]['seq'] < publication['seq'] and
                         v[:4] == [w[0], w[1], w[7], w[6]] and demand == w[3] and guard == request['values'][5] and
                         0 < hp <= soft <= hard and (soft-hp) % 8 == (hard-hp) % 8 == 0 and
                         soft == min(hp+8*w[2], hard-8*guard) and soft-hp >= 8*demand)
            after_views = [e for e in view_by_attempt.get(_attempt(winner), [])
                           if publication['seq'] < e['seq']]
            if after_views:
                renewed = (published and after_views[0]['values'] ==
                           [v[1], v[2], hp, soft, hard, request['values'][6], demand, 7])
    add('winner-post-unlock-publication', published, [*claims, *unlocks, *publications])
    add('winner-renewed-grant', renewed, [*publications, *after_views[:1]])


def _select_case_events(contract, events):
    """Bind a one-case contract to the runtime case that holds the probe.

    The linked runtime numbers every rest entry from 1. Startup entries occupy
    the early numbers; the fixture's entry is the unique larger case.
    """
    inventory = {c['id']: c for c in contract['cases']}
    grouped = {}
    for event in events:
        grouped.setdefault(event['case'], []).append(event)
    if set(grouped) <= set(inventory):
        return {c: grouped.get(c, []) for c in inventory}, {}
    if len(contract['cases']) != 1 or not grouped:
        raise ValueError('native case outside the declared contract')
    ranked = sorted(grouped, key=lambda case: (len(grouped[case]), case))
    probe = ranked[-1]
    if len(ranked) > 1 and len(grouped[probe]) <= len(grouped[ranked[-2]]):
        raise ValueError('native case outside the declared contract')
    logical = contract['cases'][0]['id']
    return ({logical: grouped[probe]},
            {'runtimeCase': probe,
             'startupCases': [[case, len(rows)] for case, rows in sorted(grouped.items())
                              if case != probe]})


def project(contract, trace, command, *, legacy_contest=False):
    validate_contract(contract)
    by_case, binding = _select_case_events(contract, trace['events'])
    facts = {name: [] for name in ('rest_required', 'rest_check', 'rest_route')}
    # Measurements from different commands/streams must never fill each
    # other's missing premises, even on the same image and numeric case ID.
    # The decoder already bound all bytes. Do not serialize a million decoded
    # snapshot dictionaries merely to construct a relation identity.
    observation = hashlib.sha256(json.dumps([trace.get('digest', trace), command], sort_keys=True,
        separators=(',', ':')).encode()).hexdigest()
    cases = []
    terminal = (type(command.get('exit')) is int and command.get('exit') == 0 and command.get('timeout') is False
                and command.get('processGroupQuiescent') is True)
    for case in contract['cases']:
        events = by_case[case['id']]
        scope = [observation+':'+str(case['id']), contract['gsiSha256'], case['spelling']]
        begins = [e for e in events if e['kind'] == 'case-begin']
        ends = [e for e in events if e['kind'] == 'case-end']
        # The runtime can emit one trailing record after it marks the case
        # closed. That suffix is still this case; it is not another entry.
        suffix = events[events.index(ends[0]) + 1:] if len(ends) == 1 and ends[0] in events else events
        framed = (len(begins) == len(ends) == 1 and begins[0] == events[0]
                  and all(e['kind'] != 'case-begin' for e in suffix))
        checks = _measure(case, events, handler_form=contract.get('handlerForm'), legacy_contest=legacy_contest)
        if ({c['obligation'] for c in checks} != set(OBLIGATIONS[case['checklist']])
                or len(checks) != len(OBLIGATIONS[case['checklist']])):
            raise ValueError('native rest required obligation inventory changed')
        checks.append(dict(obligation='complete-transport', status='pass' if
                           trace['complete'] and terminal and framed else 'missing',
                           events=[e['seq'] for e in begins+ends],
                           detail='Closed lossless stream and natural quiescent command exit required.'))
        for check in checks:
            name = check['obligation']
            facts['rest_required'].append(scope + [name])
            if check['status'] != 'missing':
                facts['rest_check'].append(scope + [name, check['status'],
                    ':'.join(map(str, [*check.get('eventSpan', check['events']),
                                       check.get('eventCount', len(check['events']))]))])
            path, action = (ROUTES[9] if legacy_contest and name == 'unique-last-section'
                            else CUT_ROUTES.get(name, ROUTES[case['checklist']]))
            facts['rest_route'].append([name, path, action])
        failed = [c for c in checks if c['status'] == 'fail']
        failed.sort(key=lambda c: min(c['events'], default=2**64))
        for check in failed:
            ids = set(check['events'])
            check['witness'] = [e for e in events if e['seq'] in ids][:64]
        cases.append(dict(**case, checks=checks, firstFailedContract=failed[0] if failed else None,
                          **binding))
    for key in facts:
        facts[key] = [list(row) for row in dict.fromkeys(map(tuple, facts[key]))]
    facts['rest_route'].append(['runtime-identity', 'make-lineage/runtime-identity',
                                'inspect-image-source-and-loader-custody'])
    return dict(cases=cases, facts=facts, runtimeAdmitted=False, executionAuthorized=False,
                sourceRefinementAdmitted=False,
                claim='native-rest-observed-cut-not-Family-A-admission')


def _bound_contract(options, ctx, candidate, executable_sha):
    rules_path = source_path(ctx.root, options['rules'])
    if 'case' in options:
        ctx.bind([rules_path])
        contract = _recipe_contract(candidate, options)
    else:
        contract_path = source_path(ctx.root, options['contract'])
        ctx.bind([contract_path, rules_path])
        contract = validate_contract(read_json(contract_path))
    if executable_sha != candidate['binarySha256'] or executable_sha != contract['gsiSha256']:
        raise ValueError('native rest observations require this exact identity-bound GSI')
    if any(candidate['sourceFiles'].get(p) != sha for p, sha in contract['sourceFiles'].items()):
        raise ValueError('native rest observer/runtime source differs from the candidate identity')
    return contract, rules_path


def _recipe_contract(candidate, options):
    case = options['case']
    return contract_from_identity(candidate, [case], capacity=options['capacity'],
                                  handler_form=REST_FORMS[case['spelling']] if case['checklist'] == 6 else None)


def compiled_fixture(options, ctx, candidate, executable_sha):
    contract, _ = _bound_contract(options, ctx, candidate, executable_sha)
    return 'case' in options or any(case['checklist'] == 8 for case in contract['cases'])


def fixture_compile_arguments():
    # Darwin's module linker needs an explicit lookup policy for the
    # observer and runtime functions exported by the loaded GSI.
    link = ['-ld-options', '-Wl,-undefined,dynamic_lookup'] if sys.platform == 'darwin' else []
    return ['-f', '-dynamic', *link, '-o', 'fixture.o1', 'fixture.scm']


def fixture_identity(directory, commands):
    source, native = (directory/name for name in ('fixture.scm', 'fixture.o1'))
    compile_steps = [c for c in commands if c['stage'] == 'compile-rest-fixture']
    if (len(compile_steps) != 1 or compile_steps[0].get('exit') != 0 or
            compile_steps[0].get('timeout') is not False or
            compile_steps[0].get('processGroupQuiescent') is not True or
            compile_steps[0]['argv'][1:] not in (
                ['-f', '-dynamic', '-o', native.name, source.name],
                ['-f', '-dynamic', '-ld-options', '-Wl,-undefined,dynamic_lookup',
                 '-o', native.name, source.name]) or
            Path(compile_steps[0]['argv'][0]).parts[-2:] != ('gsc', 'gsc') or
            not all(p.is_file() and not p.is_symlink() for p in (source, native))):
        raise ValueError('native rest requires a bound compiled fixture module')
    return dict(sourceSha256=digest(source), moduleSha256=digest(native), compile=compile_steps[0])


def _fixture_consumer(command, fixture):
    argv = command.get('argv', [])
    return (len(argv) == 4 and Path(argv[0]).parts[-2:] == ('gsi', 'gsi') and
            Path(argv[0]).parents[1] == Path(fixture['compile']['argv'][0]).parents[1] and
            command.get('cwd') == fixture['compile'].get('cwd') and
            argv[2] == '-f' and Path(argv[3]).name == 'fixture.o1' and
            Path(argv[3]).parent == Path(command['cwd']))


def runtime_identity_bytes(candidate):
    return (json.dumps(candidate, sort_keys=True, indent=2)+'\n').encode('utf-8')


def prepare(options, ctx, candidate, executable_sha, runtime):
    contract, rules_path = _bound_contract(options, ctx, candidate, executable_sha)
    directory = ctx.directory
    path = directory/'rest-observation.bin'
    inode = create_trace(path, contract['capacity'])
    (directory/'rest-contract.json').write_text(json.dumps(contract, sort_keys=True, indent=2)+'\n')
    (directory/'rest-rules.scm').write_bytes(rules_path.read_bytes())
    (directory/'rest-runtime-identity.json').write_bytes(runtime_identity_bytes(candidate))
    ctx.env['GAMBIT_REST_OBSERVATION'] = str(path)
    if len(contract['cases']) == 1:
        case = contract['cases'][0]
        short = case['checklist'] == 6 and case['situation'] == 'short'
        if short or case['checklist'] in (7, 8, 9):
            ctx.env['GAMBIT_REST_OBSERVATION_CASE'] = str(case['id'])
        if short:
            ctx.env['GAMBIT_REST_OBSERVATION_WATCH'] = 'physical-one-short'
        if 'handlerForm' in contract:
            ctx.env['GAMBIT_REST_OBSERVATION_CASE'] = str(case['id'])
            ctx.env['GAMBIT_REST_OBSERVATION_FORM'] = str(contract['handlerForm'])
            if case['situation'] == 'exact':
                ctx.env['GAMBIT_REST_OBSERVATION_WATCH'] = 'physical-exact'
    return dict(contract=contract, options=options, inode=inode, executableSha256=executable_sha,
                candidate=candidate, runtime=runtime)


def _inferred_verdict(report):
    relations = report['inference'].get('relations')
    if relations is None:
        return 'INCONCLUSIVE'
    required = {tuple(r) for r in report['facts']['rest_required']}
    checks = [tuple(r) for r in report['facts']['rest_check'] if tuple(r[:4]) in required]
    failed = {(*r[:4], r[5]) for r in checks if r[4] == 'fail'}
    missing = required - {r[:4] for r in checks}
    scopes = {r[:3] for r in required}
    incomplete = {r[:3] for r in failed | missing}
    repair = {(*r, *route[1:]) for r in missing | {r[:4] for r in failed}
              for route in report['facts']['rest_route'] if route[0] == r[3]}
    actual = {key: {tuple(row) for row in relations[key]}
              for key in QUERIES}
    if actual != dict(violation=failed, missing=missing, observed_cut=scopes-incomplete,
                      repair_target=repair):
        raise ValueError('native rest ASCENT verdict disagrees with raw-bound obligations')
    return 'VIOLATED' if actual['violation'] else 'INCONCLUSIVE' if actual['missing'] else 'OBSERVED'


def finish(prepared, ctx):
    """Called in finally: a failed native producer still retains its evidence."""
    from gambit_smp.ascent_program import INERT_RULE_CONTRACT
    from gambit_smp.evidence_capabilities import evaluate_observations
    directory = ctx.directory
    path = directory/'rest-observation.bin'
    info = path.lstat()
    if not stat.S_ISREG(info.st_mode) or [info.st_dev, info.st_ino] != prepared['inode']:
        raise ValueError('native rest trace was replaced')
    raw = path.read_bytes()
    command = next((c for c in reversed(ctx.commands) if c['stage'] == 'run-executable'), {})
    trace = decode_trace(raw)
    if len(raw) != HEADER.size + prepared['contract']['capacity'] * RECORD.size:
        raise ValueError('native rest producer changed the declared trace capacity')
    report = project(prepared['contract'], trace, command)
    from gambit_smp.suite_primitives import check_runtime
    try:
        check_runtime(prepared['runtime'], prepared['candidate'])
        if 'case' in prepared['options'] or any(case['checklist'] == 8 for case in prepared['contract']['cases']):
            fixture = prepared.get('fixture')
            if (not fixture or fixture != fixture_identity(directory, ctx.commands) or
                    not _fixture_consumer(command, fixture)):
                raise ValueError('moving rest fixture producer or consumer changed')
        report['identityStatus'] = 'UNCHANGED'
    except (ValueError, OSError) as error:
        report['identityStatus'] = 'CHANGED'
        report['identityError'] = str(error)
    for case in report['cases']:
        scope = next(r[:3] for r in report['facts']['rest_required']
                     if r[0].endswith(':'+str(case['id'])))
        report['facts']['rest_required'].append(scope + ['runtime-identity'])
        report['facts']['rest_check'].append(scope + ['runtime-identity',
            'pass' if report['identityStatus'] == 'UNCHANGED' else 'fail', 'identity'])
    schema = REST_CONTEST_REPORT if any(case['checklist'] == 9 for case in report['cases']) else REST_REPORT
    report.update(schema=schema, traceSha256=hashlib.sha256(raw).hexdigest(),
                  contractSha256=digest(directory/'rest-contract.json'),
                  rulesSha256=digest(directory/'rest-rules.scm'),
                  runtimeIdentitySha256=digest(directory/'rest-runtime-identity.json'),
                  executableSha256=prepared['executableSha256'],
                  terminal={k: command.get(k) for k in ('exit', 'timeout', 'processGroupQuiescent')},
                  transport={k: trace[k] for k in ('reserved', 'dropped', 'holes', 'closed', 'complete')})
    if prepared.get('fixture') is not None:
        report['fixture'] = prepared['fixture']
    # First retain the raw-derived measurements. Inference failure/expiry must
    # not erase the first violated contract or consume a native retry.
    target = directory/'rest-observation.json'
    target.write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    try:
        active_rules = source_path(ctx.root, prepared['options']['rules'])
        if digest(active_rules) != report['rulesSha256']:
            raise ValueError('native rest inference rules changed after capture')
        report['inference'] = dict(backend='ASCENT', relations=evaluate_observations(ctx,
            [prepared['options']['rules']], report['facts'], QUERIES, 'rest-review',
            rules_contract=INERT_RULE_CONTRACT))
        if digest(active_rules) != report['rulesSha256']:
            raise ValueError('native rest inference rules changed during inference')
        verdict = _inferred_verdict(report)
    except Exception as error:
        report['inference'] = dict(status='NOT_ESTABLISHED', reason=str(error))
        verdict = 'INCONCLUSIVE'
    report['verdict'] = verdict
    target.write_text(json.dumps(report, sort_keys=True, indent=2)+'\n')
    return dict(report='rest-observation.json', sha256=digest(target), verdict=verdict,
                runtimeAdmitted=False, executionAuthorized=False)


def bound_read(run, step, *, _seen=None):
    """The normal aggregate reader verifies artifacts and rechecks measurements."""
    descriptor = step.get('restObservation')
    if descriptor is None:
        return None
    seen = set() if _seen is None else _seen
    key = (str(Path(run).resolve()), step['id'])
    if key in seen:
        raise ValueError('cyclic native rest observation origin')
    seen.add(key)
    if step.get('reused'):
        # Reuse carries originArtifacts/originCommands, not new execution files.
        # Follow the existing checkpoint's exact committed step, never invent a
        # new run or reinterpret historical measurements as fresh execution.
        from gambit_smp.step_checkpoint import content_id
        origin = step['reused']
        fields(origin, ('run', 'step', 'receipt'))
        directory = relative(ROOT, origin['run'])
        child = read_json(directory/'receipt.json')
        if child.get('schema') != 'evidence-recipe-run.v1':
            raise ValueError('native rest origin requires a Recipe receipt')
        matches = [row for row in child.get('steps', []) if row['id'] == origin['step']]
        if len(matches) != 1 or content_id(matches[0]) != origin['receipt']:
            raise ValueError('native rest origin step receipt changed')
        previous = matches[0]
        if (previous.get('outcome') != 'PASS' or step.get('outcome') != 'PASS'
                or descriptor.get('verdict') != 'OBSERVED' or
                any(step.get(k) != previous.get(k) for k in
                    ('id', 'capability', 'arguments', 'dependsOn', 'budgetSeconds', 'restObservation'))):
            raise ValueError('native rest origin contract differs from the consuming step')
        result = bound_read(directory, previous, _seen=seen)
        return dict(result, executionReused=True, executionLaunched=False,
                    reference=str(directory/result['reference']),
                    observationOrigin=dict(origin))
    directory = relative(Path(run), step['id'])

    def bound(name, expected=None):
        path = relative(directory, name)
        artifact = step['id']+'/'+name
        sha = step.get('artifacts', {}).get(artifact)
        if not sha or (expected is not None and sha != expected) or path.is_symlink() or digest(path) != sha:
            raise ValueError('native rest receipt artifact changed: '+artifact)
        return path

    path = bound('rest-observation.json', descriptor['sha256'])
    if descriptor.get('report') != path.name:
        raise ValueError('native rest report path changed')
    report = read_json(path)
    if (report.get('schema') not in (REST_REPORT, REST_CONTEST_REPORT) or
            report.get('identityStatus') not in ('UNCHANGED', 'CHANGED') or
            report.get('verdict') != descriptor.get('verdict')):
        raise ValueError('native rest observation schema or verdict changed')
    contract = read_json(bound('rest-contract.json', report['contractSha256']))
    raw = bound('rest-observation.bin', report['traceSha256']).read_bytes()
    bound('rest-rules.scm', report['rulesSha256'])
    identity = read_json(bound('rest-runtime-identity.json', report['runtimeIdentitySha256']))
    options = step.get('arguments', {}).get('restObservation', {})
    if 'case' in options and contract != _recipe_contract(identity, options):
        raise ValueError('retained rest contract differs from its recipe case')
    if (identity['binarySha256'] != contract['gsiSha256'] or
            any(identity['sourceFiles'].get(p) != sha for p, sha in contract['sourceFiles'].items())):
        raise ValueError('native rest source and runtime identity differ')
    command = next((c for c in reversed(step.get('commands', [])) if c['stage'] == 'run-executable'), {})
    if 'case' in options or any(case['checklist'] == 8 for case in contract['cases']):
        fixture = report.get('fixture')
        if not fixture or not _fixture_consumer(command, fixture):
            raise ValueError('moving rest receipt omits its compiled fixture binding')
        bound('fixture.scm', fixture['sourceSha256'])
        bound('fixture.o1', fixture['moduleSha256'])
        if fixture != fixture_identity(directory, step['commands']):
            raise ValueError('moving rest receipt compiler binding changed')
    expected_terminal = {k: command.get(k) for k in ('exit', 'timeout', 'processGroupQuiescent')}
    if report['terminal'] != expected_terminal or report['executableSha256'] != contract['gsiSha256']:
        raise ValueError('native rest terminal or image identity changed')
    trace = decode_trace(raw)
    if (len(raw) != HEADER.size+contract['capacity']*RECORD.size or
            report['transport'] != {k: trace[k] for k in ('reserved', 'dropped', 'holes', 'closed', 'complete')}):
        raise ValueError('native rest retained transport summary changed')
    legacy_contest = report['schema'] == REST_REPORT and any(case['checklist'] == 9 for case in contract['cases'])
    computed = project(contract, trace, command, legacy_contest=legacy_contest)
    for case in computed['cases']:
        scope = next(r[:3] for r in computed['facts']['rest_required']
                     if r[0].endswith(':'+str(case['id'])))
        computed['facts']['rest_required'].append(scope + ['runtime-identity'])
        computed['facts']['rest_check'].append(scope + ['runtime-identity',
            'pass' if report['identityStatus'] == 'UNCHANGED' else 'fail', 'identity'])
    if any(report.get(k) != v for k, v in computed.items()):
        raise ValueError('native rest raw stream and retained measurements disagree')
    if report['verdict'] != _inferred_verdict(report):
        raise ValueError('native rest report verdict differs from its ASCENT result')
    return dict(step=step['id'], status='RECEIPT_BOUND', reference=step['id']+'/'+path.name,
                **({'legacyContest': True} if legacy_contest else {}),
                **report)


def add_facts(target, observation):
    legacy_scopes = {tuple(row[:3]) for row in observation['facts']['rest_required']
                     if row[3] == 'unique-last-section'} if observation.get('legacyContest') else set()
    for name, rows in observation['facts'].items():
        if name == 'rest_check' and legacy_scopes:
            rows = [row for row in rows if row[3] != 'unique-last-section' or tuple(row[:3]) not in legacy_scopes]
        target.setdefault(name, []).extend(rows)


def moving_coverage(observations, steps):
    """Summarize already checked cuts; never infer coverage across images."""
    outcomes = {step['id']: step.get('outcome') for step in steps}
    groups = {}
    for report in observations:
        cases = [c for c in report['cases'] if c['checklist'] == 8]
        if not cases:
            continue
        key = report['executableSha256'], report['runtimeIdentitySha256']
        forms = groups.setdefault(key, {})
        if report['verdict'] == 'OBSERVED' and outcomes.get(report['step']) == 'PASS':
            for case in cases:
                forms.setdefault(case['spelling'], []).append(report['reference'])
    return [dict(executableSha256=image, runtimeIdentitySha256=identity,
                 observedSpellings=[form for form in REST_FORMS if form in forms],
                 missingSpellings=[form for form in REST_FORMS if form not in forms],
                 references=forms, allThreeObserved=REST_FORMS.keys() <= forms.keys(),
                 runtimeAdmitted=False)
            for (image, identity), forms in groups.items()]


def rest_cut_coverage(observations, steps, *, planned=None, read_errors=None):
    """Summarize declared rest cases by checklist item and runtime identity."""
    declared = {}
    outcomes = {step['id']: step for step in steps}
    for step in steps if planned is None else planned:
        case = step.get('arguments', {}).get('restObservation', {}).get('case')
        if case and case['checklist'] in RECIPE_SITUATIONS:
            declared[step['id']] = case
    if not declared:
        return []
    groups = {}
    for report in observations:
        name = report['step']
        if name in declared:
            key = report['executableSha256'], report['runtimeIdentitySha256']
            groups.setdefault(key, {})[name] = report
    coverage = []
    reported_steps = {report['step'] for report in observations}
    read_errors = read_errors or {}
    for (image, identity), reports in (groups or {(None, None): {}}).items():
        cases = []
        items = {}
        for name, case in declared.items():
            step = outcomes.get(name, {})
            outcome = step.get('outcome')
            report = reports.get(name)
            read_error = read_errors.get(name)
            status = report['verdict'] if report else 'MISSING'
            disposition = 'missing'
            details = {}
            if report:
                observed_case, = report['cases']
                details['reference'] = report['reference']
                details['missingObligations'] = [check['obligation'] for check in observed_case['checks']
                                                if check['status'] == 'missing']
                if first_failure := observed_case['firstFailedContract']:
                    details['firstFailedObligation'] = first_failure['obligation']
                terminal = report['terminal']
                if status == 'OBSERVED' and outcome == 'PASS':
                    disposition = 'passed'
                elif (status in ('VIOLATED', 'OBSERVED') or outcome in ('FAIL', 'TIMEOUT', 'STALE')
                      or first_failure is not None or report['identityStatus'] == 'CHANGED'
                      or terminal['exit'] not in (None, 0) or terminal['timeout'] is True
                      or terminal['processGroupQuiescent'] is False):
                    disposition = 'failed'
            elif read_error or (name not in reported_steps and outcome in ('DENY', 'FAIL', 'TIMEOUT', 'STALE')):
                disposition = 'failed'
                status = 'UNVERIFIED' if read_error else 'FAILED'
                if read_error:
                    details['receiptError'] = read_error
            if report and case['checklist'] == 9 and report.get('legacyContest'):
                details['missingObligations'] = list(dict.fromkeys(
                    [*details['missingObligations'], 'unique-last-section']))
                current_failures = [check['obligation'] for check in observed_case['checks']
                                    if check['status'] == 'fail' and check['obligation'] != 'unique-last-section']
                if current_failures:
                    details['firstFailedObligation'] = current_failures[0]
                elif (outcome not in ('FAIL', 'TIMEOUT', 'STALE') and report['identityStatus'] == 'UNCHANGED'
                      and terminal['exit'] == 0 and terminal['timeout'] is False
                      and terminal['processGroupQuiescent'] is True):
                    status, disposition = 'INCONCLUSIVE', 'missing'
                    details.pop('firstFailedObligation', None)
            if disposition != 'passed' and 'reason' in step:
                details['stepReason'] = step['reason']
            if status == 'OBSERVED' and outcome != 'PASS':
                status = 'INCONCLUSIVE'
            cases.append(dict(step=name, **case, status=status, disposition=disposition,
                              stepOutcome=outcome, **details))
            item = items.setdefault(case['checklist'], dict(checklist=case['checklist'],
                                                            passed=[], failed=[], missing=[]))
            item[disposition].append(name)
        coverage.append(dict(executableSha256=image, runtimeIdentitySha256=identity,
                             cases=cases, items=list(items.values()),
                             allCasesObserved=all(not item['failed'] and not item['missing'] for item in items.values()),
                             runtimeAdmitted=False))
    return coverage
