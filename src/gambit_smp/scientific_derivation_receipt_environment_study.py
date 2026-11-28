"""Formal architecture study only: native SysML, ASCENT, Quint and Lean; no runtime tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import json, re

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.re = re
        _science.ROOT = _science.context.root
        _science.STEM = 'derivation-receipt-environment'
        _science.PKG = 'GambitDerivationReceiptEnvironment'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.QNT = _science.BASE + 'models/quint/derivation_receipt_environment.qnt'
        _science.LEAN = _science.BASE + 'models/lean/DerivationReceiptEnvironment.lean'
        _science.AST = _science.BASE + 'models/lean/DerivationReceiptAst.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('route', 12, 'key sourcePath needle obligation'), ('contract', 6, 'key owner accountable.moduleId counterpart.moduleId actionName invariant gap'), ('obligation', 7, 'key status scope counterexample'), ('gain', 5, 'key avoided added condition'), ('binding', 3, 'key qntAction leanLemma refinement guardLemma updateLemma'), ('flow', 12, 'fromNode toNode reason')]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        for slot in ['history', 'induction', 'expression', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(5):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        files = sorted(_science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}))
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        native = _study_fields(_science.ROOT, None, 'derivation-receipt-environment', field_expressions, ordered=True, models=['dev'])
        vals = native['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in _science.GROUPS:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return p

    def views(_science, p):
        lines = ['#+TITLE: Force Transfer, Maintenance and Fidelity Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: derivation-receipt-environment-matrix', ':AUTHORITY: GambitDerivationReceiptEnvironment', ':STATUS: conditional-models-only; source-and-platform-open', ':END:']
        for g, _, fs in _science.GROUPS:
            fs = fs.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Model admission scopes', '', '| ID | kind | subject | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for i, v in enumerate(p['contract']):
            graph += [f'c{i}: ' + json.dumps(v['key'] + '\n' + v['invariant'])]
        for i, v in enumerate(p['obligation']):
            graph += [f'o{i}: ' + json.dumps(v['key'] + '\n' + v['status'])]
        valid = {f'c{i}' for i in range(len(p['contract']))} | {f'o{i}' for i in range(len(p['obligation']))}
        for v in p['flow']:
            assert v['fromNode'] in valid and v['toNode'] in valid
            graph.append(v['fromNode'] + ' -> ' + v['toNode'] + ': ' + json.dumps(v['reason']))
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def ascend(_science, p):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        parent = p['dependency']['3']
        needs.append([parent['prerequisite.obligationId'], 'source-refinement', parent['prerequisite.subjectPath'], _science.sha(_science.ROOT / parent['prerequisite.subjectPath']), parent['prerequisite.subjectScope']])
        rows = [[v['key'], v['sourcePath'], _science.sha(_science.ROOT / v['sourcePath']), v['needle']] for v in p['route']]
        bindings = [[v['key'], v['qntAction'], v['leanLemma']] for v in p['binding']]
        actions = [[x] for x in re.findall('^ action (\\w+)', (_science.ROOT / _science.QNT).read_text(), re.M)]
        lemmas = [[x] for x in re.findall('^theorem (\\w+)', (_science.ROOT / _science.LEAN).read_text(), re.M)]
        results = {}
        engine = _science.h.Engine()
        try:
            s = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['candidate', 'blocked', 'checked', 'linked', 'observed', 'route', 'bridgeLinked']
            assert s.run(queries=queries)['complete']
            for case in ['current', 'stale-digest', 'wrong-scope', 'missing-parent', 'missing-action', 'wrong-lemma', 'missing-source', 'missing-expression', 'missing-certificate', 'synthetic-all']:
                rec = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    rec = [x[:3] + ['stale'] + x[4:] if x[1] == 'DR-I' else x for x in rec]
                if case == 'wrong-scope':
                    rec = [x[:4] + ['all-extraction-verified'] if x[1] == 'DR-I' else x for x in rec]
                if case == 'missing-expression':
                    rec = [x for x in rec if x[1] != 'DR-X']
                if case == 'missing-parent':
                    rec = [x for x in rec if x[1] != 'DF-S']
                bs = [x.copy() for x in bindings]
                if case == 'wrong-lemma':
                    bs[0][2] = 'nonexistentLemma'
                ac = [x for x in actions if case != 'missing-action' or x[0] != 'reserveChild']
                obs = rows[1:] if case == 'missing-source' else rows
                cb = [[v['key'], v['guardLemma'], v['updateLemma']] for v in p['binding']]
                certs = [[x] for x in re.findall('^theorem (\\w+)', (_science.ROOT / _science.AST).read_text(), re.M) if case != 'missing-certificate' or x != 'publishNextMeaning']
                s.replace(dict(scenario=[[case]], method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source'], ['environment-refinement', 'platform']], need=needs, receipt=rec, bridgeBinding=cb, certificateLemma=certs, binding=bs, modelAction=ac, modelLemma=lemmas, witness=rows, observation=obs))
                result = s.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 3 and len(results['current']['linked']) == 3 and (len(results['current']['bridgeLinked']) == 3)
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceRefinement=False))

    def extraction_evidence(_science):
        import copy
        checker = _science.context.library('typed_binding_witness')
        irpath = _science.ROOT / _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix()
        old = checker.read_json(irpath.read_text())
        w = checker.check(old)
        refs = w['references']
        _science.save(_study_workspace('CACHE') / 'binding-witness.json', dict(**w, inputSha256=_science.sha(irpath)))
        projector = _science.context.library('derivation_receipt_projection')
        ir = checker.read_json((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast = projector.generate(ir, refs)
        _study_write_text(_science.ROOT / _science.AST, ast)
        line = next((x for x in ast.splitlines() if x.startswith('def actualRows')))
        pairs = [(int(k), int(v)) for k, v in re.findall('\\((\\d+),(\\d+)\\)', line)]
        expected = [(v['occurrence'], v['target']) for v in refs]
        assert pairs == expected
        controls = {'drop': pairs[1:], 'wrong-target': [(pairs[0][0], pairs[0][1] + 1)] + pairs[1:], 'reorder': list(reversed(pairs))}
        assert all((v != expected for v in controls.values()))
        _science.save(_study_workspace('CACHE') / 'row-projection-controls.json', dict(rejected=list(controls), exactOrderedWitness=True, reorderIsManifestMismatchNotSemanticCounterexample=True))
        _science.save(_study_workspace('CACHE') / 'expression-projection.json', dict(actions=['reserveChild', 'publish', 'finishChild'], typedIrSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / _science.AST), references=len(refs), parserVerified=False, projectorVerified=False))
        return ast

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/darwin-force-binding/input.json'
        ph = _science.sha(parent)
        p = _science.project()
        _science.views(p)
        witnesses = []
        for v in p['route']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text
            witnesses.append(dict(**v, sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        lean = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in lean and 'axiom ' not in lean
        reuse = '--reuse-formal' in _science.context.arguments
        if reuse:
            old = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
            for f in [_science.QNT, _science.LEAN, _science.AST, 'src/gambit_smp/scientific_derivation_receipt_projection.py', 'src/gambit_smp/scientific_typed_binding_witness.py', _science.BASE + 'models/lean/DarwinForceBinding.lean']:
                assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f], f
            for f, d in old['logs'].items():
                if any((k in f for k in ['quint-', 'DerivationReceipt', 'DarwinForceBinding.', 'negative-guard', 'delivery-gap-control'])):
                    assert _science.sha(_science.ROOT / f) == d, f
            ast = _science.extraction_evidence()
            assert _science.sha(_science.ROOT / _science.AST) == old['sourceBindings'][_science.AST]
        else:
            _science.context.command('quint-typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
            ast = _science.extraction_evidence()
            if (_study_workspace('CACHE') / 'DeliveryGap.qnt').exists():
                try:
                    _science.context.command('delivery-gap-control', ['quint', 'test', str(_study_workspace('CACHE') / 'DeliveryGap.qnt'), '--match', 'pendingGapControlTest'], policy=_science.process_profile)
                except RuntimeError:
                    assert 'failed' in ((_study_workspace('CACHE') / 'delivery-gap-control.stdout').read_text() + (_study_workspace('CACHE') / 'delivery-gap-control.stderr').read_text()).lower()
                else:
                    raise AssertionError('old delivery gap unexpectedly passed')
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 14 and tests.count('ControlTest passed') == 5
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '37', '--verbosity', '1'], policy=_science.process_profile)
            for name, path in [('DarwinForceBinding', _science.BASE + 'models/lean/DarwinForceBinding.lean'), ('DerivationReceiptEnvironment', _science.LEAN), ('DerivationReceiptAst', _science.AST)]:
                src = _study_workspace('CACHE') / (name + '.lean')
                _study_write_bytes(src, (_science.ROOT / path).read_bytes())
                _science.context.command(name, ['env', f"LEAN_PATH={_study_workspace('CACHE')}", 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(src)], policy=_science.process_profile)
            mutant = '\n'.join((line.replace('<', '≤') if line.startswith('def irReserveGuard') else line for line in ast.splitlines())) + '\n'
            assert mutant != ast
            _study_write_text(_study_workspace('CACHE') / 'WrongGuard.lean', mutant)
            try:
                _science.context.command('negative-guard-certificate', ['env', f"LEAN_PATH={_study_workspace('CACHE')}", 'lean', str(_study_workspace('CACHE') / 'WrongGuard.lean')], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-guard-certificate.stdout').read_text()
            else:
                raise AssertionError('wrong projected guard certified')
        _science.ascend(p)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {v['sourcePath'] for v in p['route']} | {_science.AST, 'src/gambit_smp/scientific_derivation_receipt_projection.py', _science.BASE + 'models/lean/DarwinForceBinding.lean', _science.MODEL, _science.DESIGN, _science.MATRIX, _science.QNT, _science.LEAN, _science.RULES, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_map_expression_projection.py', 'src/gambit_smp/scientific_typed_binding_witness.py', 'dev/refactoring/modern-c/models/quint/map_frame_abi.qnt', _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix(), 'dev/refactoring/modern-c/models/lean/MapExpressionAst.lean', 'vendor/gambit/include/gambit.h.in', 'vendor/gambit/lib/setup.h'}
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['sourcePath']) == v['sha256']
        assert _science.sha(parent) == ph
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sourceRoutes=12, qntHistories=14, negativeControls=5, sampledRuns=500, maxSteps=200, leanTheorems=len(re.findall('^theorem ', lean, re.M)), ascentScenarios=10, formalBindings=3, negativeLeanCertificates=1, astTheorems=len(re.findall('^theorem ', ast, re.M)), formalChecksReused=reuse, sourceQualified=False, bindingWitnessReferences=91, rowProjectionRefusals=3, jsonBindingExtractionVerified=False, fullActionExtractionVerified=False, qntToLeanFullSimulation=False, c11Refinement=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInputSha256=ph, parentFrozen=True, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el', '.lean', '.qnt'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
