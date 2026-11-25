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
        _science.STEM = 'darwin-force-binding'
        _science.PKG = 'GambitDarwinForceBinding'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.QNT = _science.BASE + 'models/quint/darwin_force_binding.qnt'
        _science.LEAN = _science.BASE + 'models/lean/DarwinForceBinding.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('route', 11, 'key sourcePath needle obligation'), ('contract', 6, 'key owner actionName invariant gap'), ('obligation', 7, 'key status scope counterexample'), ('gain', 5, 'key avoided added condition'), ('binding', 3, 'key qntAction leanLemma refinement'), ('flow', 12, 'fromNode toNode reason')]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        files = sorted(_science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}))
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        native = _study_fields(_science.ROOT, None, 'darwin-force-binding', field_expressions, ordered=True, models=['dev'])
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
        lines = ['#+TITLE: Force Transfer, Maintenance and Fidelity Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: darwin-force-binding-matrix', ':AUTHORITY: GambitDarwinForceBinding', ':STATUS: conditional-models-only; source-and-platform-open', ':END:']
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
            queries = ['candidate', 'blocked', 'checked', 'linked', 'observed', 'route']
            assert s.run(queries=queries)['complete']
            for case in ['current', 'stale-digest', 'wrong-scope', 'missing-parent', 'missing-action', 'wrong-lemma', 'missing-source', 'synthetic-all']:
                rec = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    rec = [x[:3] + ['stale'] + x[4:] if x[1] == 'DF-I' else x for x in rec]
                if case == 'wrong-scope':
                    rec = [x[:4] + ['all-extraction-verified'] if x[1] == 'DF-I' else x for x in rec]
                if case == 'missing-parent':
                    rec = [x for x in rec if x[1] != 'FM-S']
                bs = [x.copy() for x in bindings]
                if case == 'wrong-lemma':
                    bs[0][2] = 'nonexistentLemma'
                ac = [x for x in actions if case != 'missing-action' or x[0] != 'childReserve']
                obs = rows[1:] if case == 'missing-source' else rows
                s.replace(dict(scenario=[[case]], method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source'], ['environment-refinement', 'platform']], need=needs, receipt=rec, binding=bs, modelAction=ac, modelLemma=lemmas, witness=rows, observation=obs))
                result = s.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 2 and len(results['current']['linked']) == 3
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceRefinement=False))

    def binding_evidence(_science):
        import copy
        checker = _science.context.library('typed_binding_witness')
        irpath = _science.ROOT / _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix()
        raw = irpath.read_text()
        ir = checker.read_json(raw)
        w = checker.check(ir)
        _science.save(_study_workspace('CACHE') / 'binding-witness.json', dict(**w, inputSha256=_science.sha(irpath)))
        refusals = []
        for name in ['missing-reference', 'wrong-target', 'wrong-scope', 'wrong-type', 'wrong-body', 'wrong-annotation', 'duplicate-id', 'duplicate-name', 'unsupported-node', 'nonfinite-json', 'duplicate-json-key']:
            bad = copy.deepcopy(ir)
            if name == 'missing-reference':
                del bad['table']['172']
            if name == 'wrong-target':
                bad['table']['172']['id'] = 65
            if name == 'wrong-scope':
                bad['table']['172']['depth'] = 1
            if name == 'wrong-type':
                bad['types']['172']['type'] = {'kind': 'bool'}
            if name == 'wrong-body':
                bad['table']['172']['name'] = 'another'
            if name == 'wrong-annotation':
                bad['table']['172']['typeAnnotation'] = {'kind': 'const', 'name': 'Other'}
            if name == 'duplicate-id':
                bad['modules'][0]['declarations'].append(copy.deepcopy(bad['modules'][0]['declarations'][0]))
            if name == 'duplicate-name':
                bad['modules'][0]['declarations'].append({'id': 99999, 'kind': 'def', 'name': 'capture', 'expr': {'id': 100000, 'kind': 'bool', 'value': True}})
            if name == 'unsupported-node':
                next((d for d in bad['modules'][0]['declarations'] if d.get('name') == 'safe'))['expr']['kind'] = 'lambda'
            try:
                if name == 'nonfinite-json':
                    checker.read_json('{"v":NaN}')
                elif name == 'duplicate-json-key':
                    checker.read_json('{"table":{},"table":{}}')
                else:
                    checker.check(bad)
            except checker.Refusal as e:
                refusals.append(dict(case=name, reason=str(e)))
            else:
                raise AssertionError('accepted negative ' + name)
        assert len(refusals) == 11
        _science.save(_study_workspace('CACHE') / 'binding-refusals.json', dict(cases=refusals, notParserProof=True))
        projector = _science.context.library('map_expression_projection')
        ast, _ = projector.generate(ir, _science.sha(_science.ROOT / 'dev/refactoring/modern-c/models/quint/map_frame_abi.qnt'))
        assert ast == (_science.ROOT / 'dev/refactoring/modern-c/models/lean/MapExpressionAst.lean').read_text()
        _science.save(_study_workspace('CACHE') / 'ast-correspondence.json', dict(equalToFrozenAst=True, astSha256=__import__('hashlib').sha256(ast.encode()).hexdigest(), extractorVerified=False, decoderVerified=False))

    def profile_evidence(_science):
        paths = ['../ci-source-patch-check/src/gambit/include/gambit.h', '../ci-source-patch-check/src/gambit/include/config.h', '../ci-source-patch-check/src/gambit/lib/setup.h', '../ci-source-patch-check/src/gambit/lib/setup.c', '../ci-source-patch-check/src/gambit/lib/_kernel.c', '../ci-source-patch-check/src/gambit/config.status', '../ci-source-patch-check/src/gambit/bin/gambuild-C.unix']
        expected = {paths[0]: 'c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58', paths[5]: '3ec142dbeeecad9aee1bab1e0517b30390bf0c640ec8d1cbd11632b0307eee83', paths[6]: '58a8f5938c1ae03b25c9af28d103ea41bf8cc87315bc4417109e6ea9af3f9f60'}
        for p, d in expected.items():
            assert _science.sha(_science.ROOT / p) == d, p
        _science.save(_study_workspace('CACHE') / 'darwin-profile.json', dict(files={p: _science.sha(_science.ROOT / p) for p in paths}, matchesPriorThreeDigests=True, actualUnitInvocationBound=False, loadedBinaryBound=False, sourceTreeEqualsVendor=False, noCompilerOrPreprocessorRun=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/force-maintenance-fidelity/input.json'
        ph = _science.sha(parent)
        p = _science.project()
        _science.views(p)
        _science.binding_evidence()
        _science.profile_evidence()
        witnesses = []
        for v in p['route']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text
            witnesses.append(dict(**v, sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        lean = (_science.ROOT / _science.LEAN).read_text()
        reuse = '--reuse-formal' in _science.context.arguments
        if reuse:
            old = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
            for f in [_science.QNT, _science.LEAN]:
                assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f], f
            for f, d in old['logs'].items():
                if any((k in f for k in ['quint-', 'lean.', 'negative-binding-certificate'])):
                    assert _science.sha(_science.ROOT / f) == d, f
        else:
            _science.context.command('quint-typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 10 and tests.count('ControlTest passed') == 4
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '300', '--max-steps', '160', '--seed', '31', '--verbosity', '1'], policy=_science.process_profile)
            lean = (_science.ROOT / _science.LEAN).read_text()
            assert 'sorry' not in lean and 'axiom ' not in lean
            _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
            mutant = lean.replace('if resolve r.occurrence = some target then', 'if True then')
            assert mutant != lean
            _study_write_text(_study_workspace('CACHE') / 'WrongBinding.lean', mutant)
            try:
                _science.context.command('negative-binding-certificate', ['lean', str(_study_workspace('CACHE') / 'WrongBinding.lean')], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-binding-certificate.stdout').read_text()
            else:
                raise AssertionError('identity-blind extraction certified')
        _science.ascend(p)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {v['sourcePath'] for v in p['route']} | {_science.MODEL, _science.DESIGN, _science.MATRIX, _science.QNT, _science.LEAN, _science.RULES, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_map_expression_projection.py', 'src/gambit_smp/scientific_typed_binding_witness.py', 'dev/refactoring/modern-c/models/quint/map_frame_abi.qnt', _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix(), 'dev/refactoring/modern-c/models/lean/MapExpressionAst.lean', '../ci-source-patch-check/src/gambit/config.status', '../ci-source-patch-check/src/gambit/include/config.h', '../ci-source-patch-check/src/gambit/lib/setup.c', 'vendor/gambit/include/gambit.h.in', 'vendor/gambit/lib/setup.h'}
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['sourcePath']) == v['sha256']
        assert _science.sha(parent) == ph
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sourceRoutes=11, qntHistories=10, negativeControls=4, sampledRuns=300, maxSteps=160, leanTheorems=len(re.findall('^theorem ', lean, re.M)), ascentScenarios=8, formalBindings=3, negativeLeanCertificates=1, formalChecksReused=reuse, sourceQualified=False, bindingWitnessReferences=91, bindingRefusals=11, jsonBindingExtractionVerified=False, fullActionExtractionVerified=False, qntToLeanFullSimulation=False, c11Refinement=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInputSha256=ph, parentFrozen=True, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el', '.lean'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
