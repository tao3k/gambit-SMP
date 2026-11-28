"""Python transport for native SysML and source-bound research-model evidence.

No language/runtime implementation; no shell, jq or SysML/Scheme parser.
Study metadata describe projection schemas, not a second architecture model.
"""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
from collections import defaultdict
import hashlib
import json
from pathlib import Path
import traceback

from gambit_smp.evidence_capabilities import evaluate_observations

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_workspace = _study_workspace
        _science._study_fields = _study_fields
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.defaultdict = defaultdict
        _science.hashlib = hashlib
        _science.json = json
        _science.Path = Path
        _science.traceback = traceback
        _science.ROOT = _science.context.root
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, path):
        return hashlib.sha256(Path(path).read_bytes()).hexdigest()

    def save(_science, path, value):
        _study_write_text(Path(path), json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    def fact(_science, name, row):
        return ' (fact (' + name + ' ' + ' '.join((json.dumps(v) for v in row)) + '))'

    def chunks(_science, rows, n):
        return [rows[i:i + n] for i in range(0, len(rows), n)]

    def execute(_science, s, resume=False):
        cache = _study_workspace('CACHE')
        evidence = _study_workspace('OUT')
        parent = _science.ROOT / '.cache/tasks' / s.parent / 'runs/research'
        cache.mkdir(parents=True, exist_ok=True)
        evidence.mkdir(parents=True, exist_ok=True)
        queries = json.loads((parent / 'native-queries.json').read_text())
        for group, count, fields in s.groups:
            queries += [(f'detail.{group}.{n}.{field}', f'{s.package}::{group}{n}.{field}') for n in range(count) for field in fields.split()]
        queries += [(f'detail.{field}', f'{s.package}::{field}') for field in s.scalars]
        for slot in ['history', 'induction', 'source', 'platform']:
            queries += [(f'needs.{s.prefix}-{slot}.{field}', f'{s.package}::{slot}.{field}') for field in 'obligationId kind subjectPath subjectScope premise owner.componentId'.split()]
        for n in range(4):
            queries += [(f'dependencies.{s.prefix}-{n}.{field}', f'{s.package}::dependency{n}.{field}') for field in 'dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId'.split()]
        field_expressions = []
        for _, expression in queries:
            field_expressions.append(expression)
        native = _study_fields(_science.ROOT, None, 'formal', field_expressions, ordered=True, models=['dev'])
        values = native['orderedValues']
        assert len(values) == len(queries)
        p = {}
        for (key, _), value in zip(queries, values, strict=True):
            node = p
            parts = key.split('.')
            for field in parts[:-1]:
                node = node.setdefault(field, {})
            node[parts[-1]] = value
        for group, _, _ in s.groups:
            p['detail'][group] = list(p['detail'][group].values())
        _science.save(cache / 'projection.json', p)
        _science.save(cache / 'native-queries.json', queries)
        s.views(p['detail'])
        s.source_checks(cache)
        commands = {'quint-tests': ['quint', 'test', s.qnt, '--match', 'Test$'], 'lean': ['lean', s.lean]}
        for initial in s.inits:
            commands['quint-' + initial] = ['quint', 'run', s.qnt, '--init', initial, '--invariant', 'safe', '--max-samples', '100', '--max-steps', '80', '--seed', '17', '--verbosity', '1']
        formal_subjects = {name: _science.sha(_science.ROOT / name) for name in [s.model, s.qnt, s.lean, s.param]}
        if resume:
            receipt = json.loads((cache / 'formal-receipt.json').read_text())
            assert receipt['subjects'] == formal_subjects and receipt['commands'] == commands
            assert all((_science.sha(cache / name) == h for name, h in receipt['logs'].items()))
        else:
            for name, command in commands.items():
                result = _science.context.command(name, command, policy=_science.process_profile)
                if name == 'quint-tests':
                    assert result.count('ok ') == s.histories and result.count('ControlTest passed') == s.controls
            _science.save(cache / 'formal-receipt.json', dict(subjects=formal_subjects, commands=commands, logs={name + '.stdout': _science.sha(cache / (name + '.stdout')) for name in commands}))
        _science.context.command('d2-svg', ['d2', s.diagram, s.diagram[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', s.diagram, str(cache / 'diagram.png')], policy=_science.process_profile)
        org = (parent / 'check-org.el').read_text().replace(s.parent_design, s.design).replace(s.parent_matrix, s.matrix)
        _study_write_text(cache / 'check-org.el', org)
        _science.save(evidence / 'checks.json', dict(status='pending', runtimeAdmitted=False))
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(cache / 'check-org.el')], policy=_science.process_profile)
        old = json.loads((parent / 'input.json').read_text())
        needs = [dict(n, component=n['owner']['componentId'], digest=_science.sha(_science.ROOT / n['subjectPath'])) for n in p['needs'].values()]
        indexed = {(n['component'], n['obligationId']): n for n in needs}
        for n in old['needs']:
            assert all((indexed[n['component'], n['obligationId']][k] == n[k] for k in ['subjectPath', 'subjectScope', 'digest']))
        dependencies = [dict(component=d['dependent']['owner']['componentId'], obligation=d['dependent']['obligationId'], prerequisiteComponent=d['prerequisite']['owner']['componentId'], prerequisite=d['prerequisite']['obligationId']) for d in p['dependencies'].values()]
        bindings = dict(old['sourceBindings'])
        assert all((_science.sha(_science.ROOT / path) == digest for path, digest in bindings.items())), 'Ancestor input drift'
        for path in s.artifacts + s.sources:
            bindings[path] = _science.sha(_science.ROOT / path)
        _science.save(cache / 'source-bindings.json', bindings)
        policy = (parent / 'planner-policy.ss').read_text()
        _study_write_text(cache / 'planner-policy.ss', policy)
        bundle = _science.sha(cache / 'source-bindings.json')
        nh = _science.sha(cache / 'projection.json')
        dh = _science.sha(cache / 'planner-policy.ss')
        claim = s.task + ':' + bundle
        bind_pairs = [['target-model-bundle-sha256', bundle], ['native-output-sha256', nh], ['planner-dsl-sha256', dh]]
        prior = json.loads((parent / 'current.json').read_text())['brief']['association']
        checked = {row[2] for row in prior['locallyChecked']} | {s.prefix + '-H', s.prefix + '-I'}
        methods = list(p['methods'].values())
        policy = policy.rstrip().removesuffix(')').replace('sharedContract sourceRoute)', 'sharedContract sourceRoute ' + s.outputs + ')')
        results = {}
        for scenario in ['current', 'wrong-scope', 'stale-subject', 'missing-qnt', 'all-scoped-control', 'synthetic-gates', 'missing-release']:
            forms = [policy, (_science.ROOT / s.rules).read_text()]
            local_facts = dict(clue=[[claim, bundle, claim, 'support', 'hypothesis', s.model]],
                factor=[[claim, bundle, key, value] for key, value in bind_pairs], binding=bind_pairs)
            forms += [_science.fact('componentFact', [c['componentId'], claim, s.package + ':native-projection']) for c in p['components'].values()]
            grouped = defaultdict(list)
            for n in needs:
                grouped[n['component']].append([n['obligationId'], n['kind'], n['premise'], n['subjectPath'], n['subjectScope']])
            for component, rows in grouped.items():
                for g in _science.chunks(rows, 3):
                    forms += [_science.fact('needTripleFact', [component] + sum(g, []))] if len(g) == 3 else [_science.fact('needFact', [component] + row) for row in g]
            forms += [_science.fact('methodFact', [m['kind'], m['method'], m['requiredCheck']]) for m in methods]
            grouped = defaultdict(list)
            for d in dependencies:
                grouped[d['component'], d['obligation']].append([d['prerequisiteComponent'], d['prerequisite']])
            for key, rows in grouped.items():
                for g in _science.chunks(rows, 3):
                    forms += [_science.fact('dependencyTripleFact', list(key) + sum(g, []))] if len(g) == 3 else [_science.fact('dependencyFact', list(key) + row) for row in g]
            forms.append(_science.fact('scenarioFact', [scenario, 'conditional-model-receipts' if scenario == 'current' else 'inference-control']))
            for g in _science.chunks(sorted({(n['subjectPath'], n['digest']) for n in needs}), 7):
                forms += [_science.fact('availableSubjectSeptFact', [scenario] + [v for row in g for v in row])] if len(g) == 7 else [_science.fact('availableSubjectFact', [scenario, *row]) for row in g]
            rows = []
            for n in needs:
                if scenario != 'all-scoped-control' and n['obligationId'] not in checked or (scenario == 'missing-qnt' and n['obligationId'] == s.prefix + '-H'):
                    continue
                m = next((m for m in methods if m['kind'] == n['kind']))
                rows.append([n['component'], n['obligationId'], m['method'], n['subjectPath'], 'stale' if scenario == 'stale-subject' and n['obligationId'] == s.prefix + '-H' else n['digest'], m['requiredCheck'], 'wrong' if scenario == 'wrong-scope' and n['obligationId'] == s.prefix + '-I' else n['subjectScope']])
            for g in _science.chunks(rows, 2):
                forms.append(_science.fact('receiptPairFact', [scenario, 'pass'] + sum(g, [])) if len(g) == 2 else _science.fact('receiptFact', [scenario] + g[0] + ['pass']))
            forms += s.facts(p['detail'], scenario)
            selector = '\n'.join(forms + [')'])
            _study_write_text(cache / (scenario + '.ss'), selector)
            selector = selector.replace('(include clue-selection-schema)', '(relation clue (id digest claim polarity role source)) (relation factor (id digest name value)) (relation binding (name value))')
            result = evaluate_observations(_science.context, [], local_facts,
                {name: name for name in 'question modelRequired qualifiedSlice locallyChecked assuranceReady componentReady componentFrontier missingModel pendingCheck nextAction openPremise unmetDependency dependencyCycle unroutedNeed danglingDependency unboundDependency sharedContract sourceRoute'.split() + s.outputs.split()}, 'inference-' + scenario,
                dsl=dict(source=selector, constructor='query', arguments=[]))
            _science.save(cache / (scenario + '.json'), result)
            results[scenario] = result
        c = results['current']
        expected = sorted(([n['component'], n['obligationId'], m['method'], m['requiredCheck'], n['subjectPath'], n['subjectScope'], n['premise']] for n in needs for m in methods if m['kind'] == n['kind']))
        assert sorted((row[1:] for row in c['modelRequired'])) == expected
        assert len(c['locallyChecked']) == len(checked) and len(c['componentFrontier']) == len(needs) - len(checked)
        assert not c['componentReady'] and (not c['danglingDependency']) and (not c['unboundDependency']) and (not c['dependencyCycle'])
        for scenario in ['wrong-scope', 'stale-subject', 'missing-qnt']:
            assert len(results[scenario]['locallyChecked']) == len(checked) - 1
        assert len(results['all-scoped-control']['locallyChecked']) == len(needs)
        s.check_inference(p['detail'], results)
        assert all((_science.sha(_science.ROOT / path) == digest for path, digest in bindings.items())), 'Inputs changed during study'
        _science.save(cache / 'input.json', dict(needs=needs, dependencies=dependencies, sourceBindings=bindings, bundle=bundle, nativeHash=nh, dslHash=dh))
        _science.save(cache / 'checks.json', dict(status='conditional-model-checks-pass', needs=len(needs), dependencies=len(dependencies), local=len(checked), frontier=len(needs) - len(checked), componentsClosed=0, gatesOpen=len(p['detail']['gate']), qntHistories=s.histories, qntNegativeControls=s.controls, leanKernels=s.kernels, sampledRuns=100 * len(s.inits), maxSteps=80, requestedSeed=17, nativeSysmlFields=len(queries), scenarios=len(results), formalToolsResumed=resume, sourceRefinement='open', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False, retainedSysmlWarnings=[d for d in native.get('diagnostics', []) if d['severity'] == 'warning']))
        for path in cache.iterdir():
            if path.is_file() and path.suffix != '.png':
                _study_write_bytes(evidence / path.name, path.read_bytes())
        _science.save(evidence / 'artifacts.json', {str(path.relative_to(_science.ROOT)): _science.sha(path) for path in evidence.iterdir() if path.is_file() and path.name != 'artifacts.json'})
        print(json.dumps({k: v for k, v in json.loads((cache / 'checks.json').read_text()).items() if k != 'retainedSysmlWarnings'}))

# Preserved scientific source notes (in original order).
# Link target exists during validation; it carries no successful result yet.
# Exact bundle/native/policy joins below must still recover every need.
