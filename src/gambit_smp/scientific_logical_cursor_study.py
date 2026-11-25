"""Scoped research checks: Python -> native SysML -> ASCENT -> QNT/Lean.

No runtime compilation/execution. No shell, jq, SysML parser or Scheme parser.
The retained ancestor projection and policy are evidence inputs, not new authority.
"""
from __future__ import annotations
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import hashlib
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
        _science.hashlib = hashlib
        _science.json = json
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.TASK = 'logical-cursor-contract'
        _science.PARENT = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/ebnf-cursor-handoff'
        _science.MODEL = 'dev/architecture/toolchain/models/sysml/logical-cursor.sysml'
        _science.DESIGN = 'dev/architecture/toolchain/logical-cursor-design.org'
        _science.MATRIX = 'dev/architecture/toolchain/logical-cursor-matrix.org'
        _science.DIAGRAM = 'dev/architecture/toolchain/diagrams/logical-cursor.d2'
        _science.RULES = 'dev/modeling/ascent/logical-cursor.rules.scm'
        _science.QNT = 'models/build/logical_cursor.qnt'
        _science.PARAMETERS = 'models/build/logical_cursor_parameters.qnt'
        _science.LEAN = 'models/build/LogicalCursor.lean'
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, path: Path) -> str:
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def save(_science, path: Path, value: object) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        _study_write_text(path, json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    def native_projection(_science) -> dict:
        queries = [tuple(line.split('\t')) for line in (_science.PARENT / 'queries.tsv').read_text().splitlines()]
        for group, count, fields in [('facet', 6, 'key semantic anchor rule'), ('gate', 6, 'key qualified rule'), ('retirement', 3, 'key anchor condition avoided added')]:
            for n in range(count):
                for field in fields.split():
                    queries.append((f'logical.{group}.{n}.{field}', f'LogicalCursor::{group}{n}.{field}'))
        for field in ['actualAdmitted', 'fixtureChars']:
            queries.append((f'logical.{field}', f'LogicalCursor::{field}'))
        for slot in ['history', 'induction', 'source', 'platform']:
            for field in 'obligationId kind subjectPath subjectScope premise owner.componentId'.split():
                queries.append((f'needs.logical-{slot}.{field}', f'LogicalCursor::{slot}.{field}'))
        for n in range(4):
            for field in 'dependent.owner.componentId dependent.obligationId prerequisite.owner.componentId prerequisite.obligationId'.split():
                queries.append((f'dependencies.logical-{n}.{field}', f'LogicalCursor::dependency{n}.{field}'))
        field_expressions = []
        for _, expression in queries:
            field_expressions.append(expression)
        result = _study_fields(_science.ROOT, None, 'logical-cursor', field_expressions, ordered=True, models=['dev'])
        values = result['orderedValues']
        assert len(values) == len(queries)
        projection = {}
        for (key, _), value in zip(queries, values, strict=True):
            target = projection
            parts = key.split('.')
            for part in parts[:-1]:
                target = target.setdefault(part, {})
            target[parts[-1]] = value
        for group in ['facet', 'gate', 'retirement']:
            projection['logical'][group] = list(projection['logical'][group].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', projection)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', queries)
        return projection

    def views(_science, p: dict) -> None:
        _study_write_text(_science.ROOT / _science.PARAMETERS, f"// Derived only from native LogicalCursor scalar evaluation.\nmodule logical_cursor_parameters {{\n  pure val FixtureChars = {p['fixtureChars']}\n}}\n")
        lines = ['#+TITLE: Logical Cursor Closure and Net-Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: logical-cursor-matrix', ':AUTHORITY: LogicalCursor', ':END:', '', 'Generated by the Python study runner. All gates remain source/native-open.', '', '| Facet | Semantics | Source | Contract |', '|---+---+---+---|']
        lines.extend((f"| {x['key']} | {x['semantic']} | {x['anchor']} | {x['rule']} |" for x in p['facet']))
        lines.extend(['', '** Admission / closure', '', '| Gate | Qualified | Remaining obligation |', '|---+---+---|'])
        lines.extend((f"| {x['key']} | {str(x['qualified']).lower()} | {x['rule']} |" for x in p['gate']))
        lines.extend(['', '** Net benefit and retirement', '', '| Path | Retirement condition | Avoided work / value | Added cost |', '|---+---+---+---|'])
        lines.extend((f"| {x['key']} | {x['condition']} | {x['avoided']} | {x['added']} |" for x in p['retirement']))
        lines.extend(['', 'Modern C and Zig both require the listed semantic/native supports. No uniquely Zig net gain is established.', 'The constructor saving is the same source-call upper bound retained in the prior study; do not double count it.', ''])
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines))
        lines = ['# Native SysML containment/qualification projection; no invented execution ordering.', 'direction: down', 'domain: ' + json.dumps('LogicalCursor\nScheme semantics / modern C lifetime support'), 'gates: ' + json.dumps('Source/native qualification\nAll six gates remain open'), 'models: ' + json.dumps('LC-H QNT / LC-I Lean\nLC-S simulation / LC-E native adapter'), 'ascent: ' + json.dumps('ASCENT\nScoped receipts + dependency frontier'), 'domain -> models', 'models -> ascent', 'ascent -> gates']
        for n, facet in enumerate(p['facet']):
            lines.extend([f'f{n}: ' + json.dumps(facet['key'] + '\n' + facet['semantic']), f'domain -> f{n}'])
        for n, retirement in enumerate(p['retirement']):
            lines.extend([f'r{n}: ' + json.dumps(retirement['key'] + '\nConditional retirement'), f'gates -> r{n}'])
        _study_write_text(_science.ROOT / _science.DIAGRAM, '\n'.join(lines) + '\n')

    def fact(_science, relation: str, values: list[str]) -> str:
        return ' (fact (' + relation + ' ' + ' '.join((json.dumps(x, ensure_ascii=False) for x in values)) + '))'

    def chunks(_science, rows: list, count: int):
        return (rows[i:i + count] for i in range(0, len(rows), count))

    def inference(_science, projection: dict) -> dict:
        previous = json.loads((_science.PARENT / 'input.json').read_text())
        old = {(n['component'], n['obligationId']): n for n in previous['needs']}
        methods = list(projection['methods'].values())
        needs = []
        for need in projection['needs'].values():
            n = dict(need, component=need['owner']['componentId'], digest=_science.sha(_science.ROOT / need['subjectPath']))
            if (n['component'], n['obligationId']) in old:
                retained = old[n['component'], n['obligationId']]
                assert all((n[k] == retained[k] for k in ['subjectPath', 'subjectScope', 'digest'])), 'Ancestor identity drift'
            needs.append(n)
        dependencies = [dict(component=d['dependent']['owner']['componentId'], obligation=d['dependent']['obligationId'], prerequisiteComponent=d['prerequisite']['owner']['componentId'], prerequisite=d['prerequisite']['obligationId']) for d in projection['dependencies'].values()]
        policy = (_science.PARENT / 'planner-policy.ss').read_text()
        assert hashlib.sha256(policy.encode()).hexdigest() == '2df360ae4ecc6e1ce2fd407d75f3522a750466e054b53aa434573c54c00e235c'
        _study_write_text(_study_workspace('CACHE') / 'planner-policy.ss', policy)
        artifacts = {n['subjectPath'] for n in needs} | {_science.MODEL, _science.RULES, _science.PARAMETERS, _science.DIAGRAM, _science.MATRIX, 'src/gambit_smp/scientific_logical_cursor_study.py'}
        bindings = {name: _science.sha(_science.ROOT / name) for name in sorted(artifacts)}
        source_names = ['std/text/parser/base.ss', 'std/text/parser/ebnf/lexer.ss', 'std/text/parser/ebnf/stream.ss', 'std/text/parser/ebnf/lang-reader.ss', 'std/text/parser/ebnf/deflexer.ss', 'std/text/parser/ebnf/defparser.ss', 'gerbil/runtime/syntax.ss', 'gerbil/expander/module.ss']
        for name in source_names:
            path = '../gerbil-gambit-bootstrap-audit/src/' + name
            bindings[path] = _science.sha(_science.ROOT / path)
        for path in ['vendor/gambit/lib/_thread.scm', 'vendor/gambit/lib/_io.scm']:
            bindings[path] = _science.sha(_science.ROOT / path)
        _science.save(_study_workspace('CACHE') / 'source-bindings.json', bindings)
        bundle = _science.sha(_study_workspace('CACHE') / 'source-bindings.json')
        native_hash = _science.sha(_study_workspace('CACHE') / 'projection.json')
        dsl_hash = hashlib.sha256(policy.encode()).hexdigest()
        claim = _science.TASK + ':' + bundle
        bind_pairs = [['target-model-bundle-sha256', bundle], ['native-output-sha256', native_hash], ['planner-dsl-sha256', dsl_hash]]
        inherited = {row[2] for row in json.loads((_science.PARENT / 'current.json').read_text())['locallyChecked']}
        outputs = 'logicalFacet logicalMissing logicalRepair logicalBlocked logicalCandidate'
        policy = policy.rstrip().removesuffix(')').replace('sharedContract sourceRoute)', 'sharedContract sourceRoute ' + outputs + ')')
        results = {}
        for scenario in ['current', 'wrong-scope', 'stale-subject', 'missing-qnt', 'all-scoped-control', 'synthetic-gates', 'missing-lifetime']:
            forms = [policy, (_science.ROOT / _science.RULES).read_text()]
            local_facts = dict(clue=[[claim, bundle, claim, 'support', 'hypothesis', _science.MODEL]],
                factor=[[claim, bundle, key, value] for key, value in bind_pairs], binding=bind_pairs)
            forms += [_science.fact('componentFact', [c['componentId'], claim, 'LogicalCursor:native-projection']) for c in projection['components'].values()]
            for component in sorted({n['component'] for n in needs}):
                for group in _science.chunks([n for n in needs if n['component'] == component], 3):
                    if len(group) == 3:
                        forms.append(_science.fact('needTripleFact', [component] + [v for n in group for v in [n['obligationId'], n['kind'], n['premise'], n['subjectPath'], n['subjectScope']]]))
                    else:
                        forms += [_science.fact('needFact', [component, n['obligationId'], n['kind'], n['premise'], n['subjectPath'], n['subjectScope']]) for n in group]
            forms += [_science.fact('methodFact', [m['kind'], m['method'], m['requiredCheck']]) for m in methods]
            for group in _science.chunks(dependencies, 1):
                d = group[0]
                forms.append(_science.fact('dependencyFact', [d['component'], d['obligation'], d['prerequisiteComponent'], d['prerequisite']]))
            forms.append(_science.fact('scenarioFact', [scenario, 'inference-control' if scenario != 'current' else 'scoped-formal-receipts']))
            subjects = sorted({(n['subjectPath'], n['digest']) for n in needs})
            for group in _science.chunks(subjects, 7):
                forms += [_science.fact('availableSubjectSeptFact', [scenario] + [v for pair in group for v in pair])] if len(group) == 7 else [_science.fact('availableSubjectFact', [scenario, *pair]) for pair in group]
            receipts = []
            for n in needs:
                if scenario != 'all-scoped-control' and n['obligationId'] not in inherited | {'LC-H', 'LC-I'}:
                    continue
                if scenario == 'missing-qnt' and n['obligationId'] == 'LC-H':
                    continue
                m = next((m for m in methods if m['kind'] == n['kind']))
                receipts.append([n['component'], n['obligationId'], m['method'], n['subjectPath'], 'stale-control' if scenario == 'stale-subject' and n['obligationId'] == 'LC-H' else n['digest'], m['requiredCheck'], 'wrong-control' if scenario == 'wrong-scope' and n['obligationId'] == 'LC-I' else n['subjectScope']])
            for group in _science.chunks(receipts, 2):
                forms.append(_science.fact('receiptPairFact', [scenario, 'pass'] + group[0] + group[1]) if len(group) == 2 else _science.fact('receiptFact', [scenario] + group[0] + ['pass']))
            for facet in projection['logical']['facet']:
                forms.append(_science.fact('logicalFacetFact', [facet['key'], facet['semantic'], facet['anchor']]))
            for gate in projection['logical']['gate']:
                qualified = scenario in {'synthetic-gates', 'missing-lifetime'} and (not (scenario == 'missing-lifetime' and gate['key'] == 'continuation-lifetime'))
                forms.append(_science.fact('logicalGateFact', [scenario, gate['key'], str(qualified or gate['qualified']).lower()]))
            forms.append(_science.fact('logicalSourceFact', [scenario, str(scenario in {'synthetic-gates', 'missing-lifetime'}).lower()]))
            selector = '\n'.join(forms + [')'])
            _study_write_text(_study_workspace('CACHE') / f'{scenario}.ss', selector)
            selector = selector.replace('(include clue-selection-schema)', '(relation clue (id digest claim polarity role source)) (relation factor (id digest name value)) (relation binding (name value))')
            result = evaluate_observations(_science.context, [], local_facts,
                {name: name for name in 'question modelRequired qualifiedSlice locallyChecked assuranceReady componentReady componentFrontier missingModel pendingCheck nextAction openPremise unmetDependency dependencyCycle unroutedNeed danglingDependency unboundDependency sharedContract sourceRoute'.split() + outputs.split()}, 'inference-' + scenario,
                dsl=dict(source=selector, constructor='query', arguments=[]))
            _science.save(_study_workspace('CACHE') / (scenario + '.json'), result)
            results[scenario] = result
        current = results['current']
        expected = sorted(([n['component'], n['obligationId'], m['method'], m['requiredCheck'], n['subjectPath'], n['subjectScope'], n['premise']] for n in needs for m in methods if m['kind'] == n['kind']))
        assert sorted((row[1:] for row in current['modelRequired'])) == expected
        assert len(current['locallyChecked']) == 14 and len(current['componentFrontier']) == 26
        assert not current['componentReady'] and len(current['logicalMissing']) == 6
        assert len(current['logicalRepair']) == 1 and (not current['logicalCandidate'])
        for scenario in ['wrong-scope', 'stale-subject', 'missing-qnt']:
            assert len(results[scenario]['locallyChecked']) == 13
        assert len(results['all-scoped-control']['locallyChecked']) == 40
        assert not results['all-scoped-control']['logicalCandidate']
        assert len(results['synthetic-gates']['logicalCandidate']) == 1
        assert not results['missing-lifetime']['logicalCandidate']
        _science.save(_study_workspace('CACHE') / 'input.json', dict(needs=needs, dependencies=dependencies, sourceBindings=bindings, nativeHash=native_hash, dslHash=dsl_hash, bundle=bundle, inheritedReceipts=sorted(inherited)))
        return dict(needs=len(needs), dependencies=len(dependencies), local=14, frontier=26, componentsClosed=0, scenarios=len(results), gatesOpen=6, runtimeAdmitted=False)

    def analyze(_science) -> None:
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('EVIDENCE').mkdir(parents=True, exist_ok=True)
        _science.save(_study_workspace('EVIDENCE') / 'checks.json', {'status': 'pending', 'runtimeAdmitted': False})
        p = _science.native_projection()
        _science.views(p['logical'])
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        _science.context.command('quint-invariant', ['quint', 'run', _science.QNT, '--invariant', 'safe', '--max-samples', '100', '--max-steps', '80', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.context.command('d2-svg', ['d2', _science.DIAGRAM, _science.DIAGRAM.removesuffix('.d2') + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.DIAGRAM, str(_study_workspace('CACHE') / 'logical-cursor.png')], policy=_science.process_profile)
        files = [_science.DESIGN, _science.MATRIX, 'dev/architecture/toolchain/index.org']
        org = '(require \'org)\n(require \'org-element)\n(setq enable-local-variables nil)\n(let ((files \'FILES) (links 0) (missing nil))\n (dolist (file files)\n  (with-temp-buffer\n   (setq buffer-file-name (expand-file-name file))\n   (setq default-directory (file-name-directory buffer-file-name))\n   (insert-file-contents buffer-file-name)\n   (org-mode)\n   (org-element-map (org-element-parse-buffer) \'link\n    (lambda (link)\n     (when (equal (org-element-property :type link) "file")\n      (setq links (1+ links))\n      (let ((target (expand-file-name (org-element-property :path link))))\n       (unless (file-exists-p target) (push (list file target) missing))))))))\n (princ (format "Org parsed: %d files; %d links; missing=%S; no Babel executed" (length files) links missing))\n (when missing (kill-emacs 1)))\n'.replace('FILES', '(' + ' '.join((json.dumps(f) for f in files)) + ')')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        summary = _science.inference(p)
        assert tests.count('ok ') == 16 and tests.count('ControlTest passed') == 8
        diagnostics = json.loads((_study_workspace('CACHE') / 'projection.json').read_text()).get('diagnostics', [])
        _science.save(_study_workspace('CACHE') / 'checks.json', dict(status='conditional-model-checks-pass', **summary, qntHistories=16, qntPositive=8, qntNegativeControls=8, sampledRuns=100, maxSteps=80, seed=17, leanKernels=7, sourceRefinement='open', nativeTestsRun=False, performanceTestsRun=False, pythonOrchestration=True, shellPipeline=False, jqPipeline=False, nativeSysmlFields=len(json.loads((_study_workspace('CACHE') / 'native-queries.json').read_text())), retainedSysmlWarnings=[d for d in diagnostics if d.get('severity') == 'warning']))
        for path in _study_workspace('CACHE').iterdir():
            if path.is_file() and path.suffix != '.png':
                _study_write_bytes(_study_workspace('EVIDENCE') / path.name, path.read_bytes())
        retained = {str(path.relative_to(_science.ROOT)): _science.sha(path) for path in _study_workspace('EVIDENCE').iterdir() if path.is_file() and path.name != 'artifacts.json'}
        _science.save(_study_workspace('EVIDENCE') / 'artifacts.json', retained)
        print(json.dumps(json.loads((_study_workspace('EVIDENCE') / 'checks.json').read_text())))

# Preserved scientific source notes (in original order).
# Re-evaluate retained native expressions, not a hand-translated SysML model.
# Numeric path components are handled as dictionary keys until final conversion.
# Bind the actual source bytes, not only the design document that cites them.
# Place a pending receipt before Org file-link validation; replace only after checks.
# Native render is a documentation check, never a runtime/native program test.
# Use Org's actual parser. Python orchestrates; it does not parse Org markup.
