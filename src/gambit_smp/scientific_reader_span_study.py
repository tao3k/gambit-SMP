"""Research-only native SysML/ASCENT/QNT/Lean checks, orchestrated in Python."""
from __future__ import annotations
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
from collections import defaultdict
import json
from pathlib import Path

from gambit_smp.evidence_capabilities import evaluate_observations

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.defaultdict = defaultdict
        _science.json = json
        _science.Path = Path
        _science.HERE = Path(str(_science.context.root / 'src/gambit_smp/scientific_reader_span_study.py')).resolve().parent
        _science.support = _science.context.library('logical_cursor_study')
        _science.ROOT = _science.context.root
        _science.TASK = 'reader-span-custody'
        _science.PARENT = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/logical-cursor-contract'
        _science.save = _science.support.save
        _science.sha = _science.support.sha
        _science.fact = _science.support.fact
        _science.chunks = _science.support.chunks
        _science.MODEL = 'dev/architecture/toolchain/models/sysml/reader-span-custody.sysml'
        _science.DESIGN = 'dev/architecture/toolchain/reader-span-custody-design.org'
        _science.MATRIX = 'dev/architecture/toolchain/reader-span-custody-matrix.org'
        _science.DIAGRAM = 'dev/architecture/toolchain/diagrams/reader-span-custody.d2'
        _science.RULES = 'dev/modeling/ascent/reader-span-custody.rules.scm'
        _science.QNT = 'models/build/reader_span_custody.qnt'
        _science.LEAN = 'models/build/ReaderSpanCustody.lean'
        _science.PARAM = 'models/build/reader_span_parameters.qnt'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def run(_science, name, argv):
        try:
            return _science.support.run(name, argv)
        except RuntimeError:
            import hashlib
            diagnostic = dict(argv=argv, stdout=(_study_workspace('CACHE') / f'{name}.stdout').read_text(), stderr=(_study_workspace('CACHE') / f'{name}.stderr').read_text())
            key = hashlib.sha256(json.dumps(diagnostic, sort_keys=True).encode()).hexdigest()[:16]
            _science.save(_study_workspace('CACHE') / f'{name}.retained-failure-{key}.json', diagnostic)
            raise

    def projection(_science):
        queries = json.loads((_science.PARENT / 'native-queries.json').read_text())
        for group, count, fields in [('producer', 8, 'key anchor custodian interval interruption'), ('reader', 5, 'key lineNumber bodyCatch consumer failure'), ('reset', 2, 'key lineNumber nextStep condition'), ('gate', 5, 'key qualified condition'), ('gain', 3, 'key avoided added threshold')]:
            queries += [(f'span.{group}.{n}.{field}', f'ReaderSpanCustody::{group}{n}.{field}') for n in range(count) for field in fields.split()]
        for field in ['fixtureCharacters', 'actualAdmitted']:
            queries.append((f'span.{field}', f'ReaderSpanCustody::{field}'))
        for slot in ['history', 'induction', 'source', 'platform']:
            queries += [(f'needs.span-{slot}.{field}', f'ReaderSpanCustody::{slot}.{field}') for field in 'obligationId kind subjectPath subjectScope premise owner.componentId'.split()]
        for n in range(4):
            queries += [(f'dependencies.span-{n}.{field}', f'ReaderSpanCustody::dependency{n}.{field}') for field in 'dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId'.split()]
        field_expressions = []
        for _, expression in queries:
            field_expressions.append(expression)
        native = _study_fields(_science.ROOT, None, 'reader-span', field_expressions, ordered=True, models=['dev'])
        values = native['orderedValues']
        assert len(values) == len(queries)
        p = {}
        for (key, _), value in zip(queries, values, strict=True):
            node = p
            fields = key.split('.')
            for field in fields[:-1]:
                node = node.setdefault(field, {})
            node[fields[-1]] = value
        for field in ['producer', 'reader', 'reset', 'gate', 'gain']:
            p['span'][field] = list(p['span'][field].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', queries)
        return (p, native)

    def source_census(_science, p):
        name = '../gerbil-gambit-bootstrap-audit/src/std/text/parser/ebnf/lang-reader.ss'
        lines = (_science.ROOT / name).read_text().splitlines()
        actual = [i + 1 for i, line in enumerate(lines) if '(read-syntax port)' in line]
        assert actual == [r['lineNumber'] for r in p['reader']]
        assert actual == [23, 99, 123, 166, 238]
        for reset, spelling in zip(p['reset'], ['(lex-parser port)', '(lex-lexer port)'], strict=True):
            assert spelling in lines[reset['lineNumber'] - 1]
        bypasses = {'peek-char': [90, 105], 'read-char': [96, 111, 120], 'read-line': [114]}
        for operator, expected in bypasses.items():
            found = [i + 1 for i, line in enumerate(lines) if f'({operator} port)' in line]
            assert found == expected
        assert '(read-section-head port)' in lines[73] and '(with-catch raise-e' in lines[75]
        _science.save(_study_workspace('CACHE') / 'source-census.json', dict(source=name, sha256=_science.sha(_science.ROOT / name), datumSites=actual, rawHeaderSites=bypasses, resetSites=[r['lineNumber'] for r in p['reset']], headerBeforeBodyCatch=True, semanticAliasClosure='open'))

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.PARAM, f"// Derived from native ReaderSpanCustody values.\nmodule reader_span_parameters {{\n  pure val FixtureCharacters = {p['fixtureCharacters']}\n  pure val BodyCatch = List(" + ','.join((str(r['bodyCatch']).lower() for r in p['reader'])) + ')\n}\n')
        lines = ['#+TITLE: Reader Span Custody and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: reader-span-matrix', ':AUTHORITY: ReaderSpanCustody', ':END:', '', 'Derived with Python from native SysML evaluation. Source/native refinement remains open.', '', '| Producer | Actual source | Custodian | Interval | Interruption |', '|---+---+---+---+---|']
        lines += [f"| {v['key']} | {v['anchor']} | {v['custodian']} | {v['interval']} | {v['interruption']} |" for v in p['producer']]
        lines += ['', '** Reader and reset paths', '', '| Entry | Source line | Body catch | Consumer | Failure |', '|---+---+---+---+---|']
        lines += [f"| {v['key']} | {v['lineNumber']} | {v['bodyCatch']} | {v['consumer']} | {v['failure']} |" for v in p['reader']]
        lines += ['', '| Reset | Line | Next observation | Retirement condition |', '|---+---+---+---|']
        lines += [f"| {v['key']} | {v['lineNumber']} | {v['nextStep']} | {v['condition']} |" for v in p['reset']]
        lines += ['', '** Open gates', '', '| Gate | Qualified | Remaining condition |', '|---+---+---|']
        lines += [f"| {v['key']} | {v['qualified']} | {v['condition']} |" for v in p['gate']]
        lines += ['', '** Net work / modern C baseline', '', '| Mechanism | Avoided work | Added work | Positive threshold / limit |', '|---+---+---+---|']
        lines += [f"| {v['key']} | {v['avoided']} | {v['added']} | {v['threshold']} |" for v in p['gain']]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['# Native SysML producer/caller containment and proof projection; not an execution schedule.', 'direction: down', 'domain: ' + json.dumps('ReaderSpanCustody\nModern C / Scheme semantic ownership'), 'contracts: "Canonical source contracts (containment view)" {', '  grid-columns: 1', 'producers: "Eight real producer boundaries" {', '  grid-columns: 2']
        graph += [f'  p{n}: ' + json.dumps(v['key'] + '\n' + v['custodian']) for n, v in enumerate(p['producer'])]
        graph += ['}', 'readers: "Five datum entries + six header I/O bypasses" {', '  grid-columns: 3']
        graph += [f'  r{n}: ' + json.dumps(v['key'] + '\n' + ('body catch' if v['bodyCatch'] else 'outside body catch')) for n, v in enumerate(p['reader'])]
        graph += ['}', 'resets: "Two reset paths with distinct consumers" {', '  grid-columns: 2']
        graph += [f'  x{n}: ' + json.dumps(v['key'] + '\n' + v['nextStep']) for n, v in enumerate(p['reset'])]
        graph += ['}', '}', 'models: ' + json.dumps('RS-H QNT / RS-I Lean\nRS-S source / RS-E native obligations'), 'ascent: ' + json.dumps('ASCENT\nScoped receipts + LC-S dependency'), 'gate: "Five source/native gates remain open"', 'domain -> contracts', 'contracts -> models', 'models -> ascent', 'ascent -> gate']
        _study_write_text(_science.ROOT / _science.DIAGRAM, '\n'.join(graph) + '\n')

    def inference(_science, p):
        parent = json.loads((_science.PARENT / 'input.json').read_text())
        old = {(n['component'], n['obligationId']): n for n in parent['needs']}
        needs = [dict(n, component=n['owner']['componentId'], digest=_science.sha(_science.ROOT / n['subjectPath'])) for n in p['needs'].values()]
        for n in needs:
            if (n['component'], n['obligationId']) in old:
                previous = old[n['component'], n['obligationId']]
                assert all((n[k] == previous[k] for k in ['subjectPath', 'subjectScope', 'digest']))
        deps = [dict(component=d['dependent']['owner']['componentId'], obligation=d['dependent']['obligationId'], prerequisiteComponent=d['prerequisite']['owner']['componentId'], prerequisite=d['prerequisite']['obligationId']) for d in p['dependencies'].values()]
        methods = list(p['methods'].values())
        bindings = dict(parent['sourceBindings'])
        for name in list(bindings):
            assert _science.sha(_science.ROOT / name) == bindings[name], f'Retained input drift: {name}'
        for name in [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.DIAGRAM, _science.RULES, _science.QNT, _science.LEAN, _science.PARAM, 'src/gambit_smp/scientific_reader_span_study.py']:
            bindings[name] = _science.sha(_science.ROOT / name)
        _science.save(_study_workspace('CACHE') / 'source-bindings.json', bindings)
        policy = (_science.PARENT / 'planner-policy.ss').read_text()
        _study_write_text(_study_workspace('CACHE') / 'planner-policy.ss', policy)
        bundle = _science.sha(_study_workspace('CACHE') / 'source-bindings.json')
        native_hash = _science.sha(_study_workspace('CACHE') / 'projection.json')
        dsl_hash = _science.sha(_study_workspace('CACHE') / 'planner-policy.ss')
        claim = _science.TASK + ':' + bundle
        bind_pairs = [['target-model-bundle-sha256', bundle], ['native-output-sha256', native_hash], ['planner-dsl-sha256', dsl_hash]]
        parent_result = json.loads((_science.PARENT / 'current.json').read_text())['brief']['association']
        inherited = {row[2] for row in parent_result['locallyChecked']}
        outputs = 'spanCustody spanExceptionRoute spanMissing spanBlocked spanCandidate'
        policy = policy.rstrip().removesuffix(')').replace('sharedContract sourceRoute)', 'sharedContract sourceRoute ' + outputs + ')')
        results = {}
        for scenario in ['current', 'wrong-scope', 'stale-subject', 'missing-qnt', 'all-scoped-control', 'synthetic-gates', 'missing-isolation']:
            forms = [policy, (_science.ROOT / _science.RULES).read_text()]
            forms += [_science.fact('componentFact', [c['componentId'], claim, 'ReaderSpanCustody:native-projection']) for c in p['components'].values()]
            groups = defaultdict(list)
            for n in needs:
                groups[n['component']].append(n)
            for component, ns in groups.items():
                for group in _science.chunks(ns, 3):
                    rows = [[n['obligationId'], n['kind'], n['premise'], n['subjectPath'], n['subjectScope']] for n in group]
                    forms += [_science.fact('needTripleFact', [component] + sum(rows, []))] if len(group) == 3 else [_science.fact('needFact', [component] + row) for row in rows]
            forms += [_science.fact('methodFact', [m['kind'], m['method'], m['requiredCheck']]) for m in methods]
            groups = defaultdict(list)
            for d in deps:
                groups[d['component'], d['obligation']].append([d['prerequisiteComponent'], d['prerequisite']])
            for key, rows in groups.items():
                for group in _science.chunks(rows, 3):
                    forms += [_science.fact('dependencyTripleFact', list(key) + sum(group, []))] if len(group) == 3 else [_science.fact('dependencyFact', list(key) + row) for row in group]
            forms.append(_science.fact('scenarioFact', [scenario, 'conditional-model-evidence' if scenario == 'current' else 'inference-control']))
            for group in _science.chunks(sorted({(n['subjectPath'], n['digest']) for n in needs}), 7):
                forms += [_science.fact('availableSubjectSeptFact', [scenario] + [v for row in group for v in row])] if len(group) == 7 else [_science.fact('availableSubjectFact', [scenario, *row]) for row in group]
            receipts = []
            for n in needs:
                if scenario != 'all-scoped-control' and n['obligationId'] not in inherited | {'RS-H', 'RS-I'}:
                    continue
                if scenario == 'missing-qnt' and n['obligationId'] == 'RS-H':
                    continue
                m = next((m for m in methods if m['kind'] == n['kind']))
                receipts.append([n['component'], n['obligationId'], m['method'], n['subjectPath'], 'stale' if scenario == 'stale-subject' and n['obligationId'] == 'RS-H' else n['digest'], m['requiredCheck'], 'wrong' if scenario == 'wrong-scope' and n['obligationId'] == 'RS-I' else n['subjectScope']])
            for group in _science.chunks(receipts, 2):
                forms.append(_science.fact('receiptPairFact', [scenario, 'pass'] + sum(group, [])) if len(group) == 2 else _science.fact('receiptFact', [scenario] + group[0] + ['pass']))
            forms += [_science.fact('spanProducerFact', [v['key'], v['anchor'], v['custodian']]) for v in p['span']['producer']]
            forms += [_science.fact('spanReaderFact', [v['key'], str(v['bodyCatch']).lower(), v['consumer']]) for v in p['span']['reader']]
            for gate in p['span']['gate']:
                qualified = scenario in {'synthetic-gates', 'missing-isolation'} and (not (scenario == 'missing-isolation' and gate['key'] == 'mutable-source-isolation'))
                forms.append(_science.fact('spanGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
            forms.append(_science.fact('spanSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-isolation'}).lower()]))
            selector = '\n'.join(forms + [')'])
            _study_write_text(_study_workspace('CACHE') / f'{scenario}.ss', selector)
            local_facts = dict(clue=[[claim, bundle, claim, 'support', 'hypothesis', _science.MODEL]],
                factor=[[claim, bundle, key, value] for key, value in bind_pairs], binding=bind_pairs)
            selector = selector.replace('(include clue-selection-schema)', '(relation clue (id digest claim polarity role source)) (relation factor (id digest name value)) (relation binding (name value))')
            result = evaluate_observations(_science.context, [], local_facts,
                {name: name for name in 'question modelRequired qualifiedSlice locallyChecked assuranceReady componentReady componentFrontier missingModel pendingCheck nextAction openPremise unmetDependency dependencyCycle unroutedNeed danglingDependency unboundDependency sharedContract sourceRoute'.split() + outputs.split()}, 'inference-' + scenario,
                dsl=dict(source=selector, constructor='query', arguments=[]))
            _science.save(_study_workspace('CACHE') / f'{scenario}.json', result)
            results[scenario] = result
        c = results['current']
        expected = sorted(([n['component'], n['obligationId'], m['method'], m['requiredCheck'], n['subjectPath'], n['subjectScope'], n['premise']] for n in needs for m in methods if m['kind'] == n['kind']))
        assert sorted((row[1:] for row in c['modelRequired'])) == expected
        assert len(c['locallyChecked']) == 16 and len(c['componentFrontier']) == 28
        assert len(c['spanCustody']) == 8 and len(c['spanExceptionRoute']) == 5
        assert sorted(c['spanCustody']) == sorted((['current', v['key'], v['anchor'], v['custodian']] for v in p['span']['producer']))
        assert sorted(c['spanExceptionRoute']) == sorted((['current', v['key'], 'body-parseerror-only' if v['bodyCatch'] else 'outside-body-catch', v['consumer']] for v in p['span']['reader']))
        assert not c['danglingDependency'] and (not c['unboundDependency']) and (not c['dependencyCycle'])
        assert len(c['spanMissing']) == 5 and (not c['componentReady']) and (not c['spanCandidate'])
        for s in ['wrong-scope', 'stale-subject', 'missing-qnt']:
            assert len(results[s]['locallyChecked']) == 15
        assert len(results['all-scoped-control']['locallyChecked']) == 44 and (not results['all-scoped-control']['spanCandidate'])
        assert len(results['synthetic-gates']['spanCandidate']) == 1 and (not results['missing-isolation']['spanCandidate'])
        _science.save(_study_workspace('CACHE') / 'input.json', dict(needs=needs, dependencies=deps, sourceBindings=bindings, bundle=bundle, nativeHash=native_hash, dslHash=dsl_hash, inheritedReceipts=sorted(inherited)))
        return dict(needs=44, dependencies=43, local=16, frontier=28, componentsClosed=0, scenarios=7, gatesOpen=5)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('EVIDENCE').mkdir(parents=True, exist_ok=True)
        _science.save(_study_workspace('EVIDENCE') / 'checks.json', {'status': 'pending', 'runtimeAdmitted': False})
        p, native = _science.projection()
        cohort = {name: _science.context.command('head-' + name, ['git', '-C', path, 'rev-parse', 'HEAD'], policy=_science.process_profile).strip() for name, path in [('research', '.'), ('gerbil', '../gerbil-gambit-bootstrap-audit'), ('gambit', 'vendor/gambit')]}
        _science.save(_study_workspace('CACHE') / 'source-cohort.json', cohort)
        _science.source_census(p['span'])
        _science.views(p['span'])
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 21 and tests.count('ControlTest passed') == 10
        for init in ['init', 'initHeader']:
            _science.context.command('quint-' + init, ['quint', 'run', _science.QNT, '--init', init, '--invariant', 'safe', '--max-samples', '100', '--max-steps', '80', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.context.command('d2-svg', ['d2', _science.DIAGRAM, _science.DIAGRAM.removesuffix('.d2') + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.DIAGRAM, str(_study_workspace('CACHE') / 'reader-span-custody.png')], policy=_science.process_profile)
        org = (_science.PARENT / 'check-org.el').read_text().replace(_science.support.DESIGN, _science.DESIGN).replace(_science.support.MATRIX, _science.MATRIX)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        summary = _science.inference(p)
        _science.save(_study_workspace('CACHE') / 'checks.json', dict(status='conditional-model-checks-pass', **summary, qntHistories=21, qntPositive=11, qntNegativeControls=10, sampledRuns=200, maxSteps=80, requestedSeed=17, leanKernels=7, nativeSysmlFields=len(json.loads((_study_workspace('CACHE') / 'native-queries.json').read_text())), retainedSysmlWarnings=[d for d in native.get('diagnostics', []) if d.get('severity') == 'warning'], sourceRefinement='open', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False, pythonOrchestration=True, shellPipeline=False, jqPipeline=False))
        for path in _study_workspace('CACHE').iterdir():
            if path.is_file() and path.suffix != '.png':
                _study_write_bytes(_study_workspace('EVIDENCE') / path.name, path.read_bytes())
        _science.save(_study_workspace('EVIDENCE') / 'artifacts.json', {str(path.relative_to(_science.ROOT)): _science.sha(path) for path in _study_workspace('EVIDENCE').iterdir() if path.is_file() and path.name != 'artifacts.json'})
        print(json.dumps({k: v for k, v in json.loads((_study_workspace('CACHE') / 'checks.json').read_text()).items() if k != 'retainedSysmlWarnings'}))

# Preserved scientific source notes (in original order).
# Distinguish errors with empty stdout by hashing stderr and argv too.
# Exact bounded sites, not a parser or whole-repository alias proof.
# Replaying a refused duplicate is safe only if the later native joins
# still recover every exact bundle/native/policy-bound modelRequired row.
