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
        _science.STEM = 'force-maintenance-fidelity'
        _science.PKG = 'GambitForceMaintenanceFidelity'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.QNT = _science.BASE + 'models/quint/force_maintenance.qnt'
        _science.LEAN = _science.BASE + 'models/lean/ForceMaintenanceFidelity.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('route', 10, 'key sourcePath needle obligation'), ('contract', 6, 'key owner actionName invariant gap'), ('obligation', 7, 'key status scope counterexample'), ('gain', 5, 'key avoided added condition'), ('binding', 3, 'key qntAction leanLemma refinement')]
        _science.process_profile = _science.h.process_profile

    def project(_science, projection_run=None):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        p, scope = _study_fields(_science.ROOT, projection_run, 'force-maintenance-fidelity', keys)
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files=scope, excluded={}))
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return p

    def views(_science, p):
        lines = ['#+TITLE: Force Transfer, Maintenance and Fidelity Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: force-maintenance-fidelity-matrix', ':AUTHORITY: GambitForceMaintenanceFidelity', ':STATUS: conditional-models-only; source-and-platform-open', ':END:']
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
        graph += ['c0 -> c1', 'c0 -> c2', 'c2 -> c3', 'c3 -> c4', 'c5 -> c4: extraction is not source proof']
        for i, v in enumerate(p['obligation']):
            graph += [f'o{i}: ' + json.dumps(v['key'] + '\n' + v['status'])]
        graph += ['c1 -> o1', 'c4 -> o2', 'c5 -> o0', 'o0 -> o3', 'o3 -> o4', 'o2 -> o5', 'o5 -> o6']
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
            queries = ['candidate', 'blocked', 'checked', 'linked', 'observed']
            assert s.run(queries=queries)['complete']
            for case in ['current', 'stale-digest', 'wrong-scope', 'missing-parent', 'missing-action', 'wrong-lemma', 'missing-source', 'synthetic-all']:
                rec = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    rec = [x[:3] + ['stale'] + x[4:] if x[1] == 'FM-I' else x for x in rec]
                if case == 'wrong-scope':
                    rec = [x[:4] + ['all-extraction-verified'] if x[1] == 'FM-I' else x for x in rec]
                if case == 'missing-parent':
                    rec = [x for x in rec if x[1] != 'RO-S']
                bs = [x.copy() for x in bindings]
                if case == 'wrong-lemma':
                    bs[0][2] = 'nonexistentLemma'
                ac = [x for x in actions if case != 'missing-action' or x[0] != 'reserve']
                obs = rows[1:] if case == 'missing-source' else rows
                s.replace(dict(scenario=[[case]], need=needs, receipt=rec, binding=bs, modelAction=ac, modelLemma=lemmas, witness=rows, observation=obs))
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

    def analyze(_science, projection_run=None):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/reti-ofd-semantics/input.json'
        ph = _science.sha(parent)
        p = _science.project(projection_run)
        _science.views(p)
        witnesses = []
        for v in p['route']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text
            witnesses.append(dict(**v, sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        _science.context.command('quint-typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 10 and tests.count('ControlTest passed') == 4
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '300', '--max-steps', '160', '--seed', '31', '--verbosity', '1'], policy=_science.process_profile)
        lean = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in lean and 'axiom ' not in lean
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascend(p)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {v['sourcePath'] for v in p['route']} | {_science.MODEL, _science.DESIGN, _science.MATRIX, _science.QNT, _science.LEAN, _science.RULES, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_map_expression_projection.py'}
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['sourcePath']) == v['sha256']
        assert _science.sha(parent) == ph
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sourceRoutes=10, qntHistories=10, negativeControls=4, sampledRuns=300, maxSteps=160, leanTheorems=len(re.findall('^theorem ', lean, re.M)), ascentScenarios=8, formalBindings=3, sourceQualified=False, jsonBindingExtractionVerified=False, fullActionExtractionVerified=False, qntToLeanFullSimulation=False, c11Refinement=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInputSha256=ph, parentFrozen=True, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
