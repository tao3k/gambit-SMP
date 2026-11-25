"""Scoped source/formal research. Native SysML evaluates routing; no runtime tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy
import hashlib
import json
import os
import re
import shutil
import textwrap
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.os = os
        _science.re = re
        _science.shutil = shutil
        _science.textwrap = textwrap
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'storage-index-transactions'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.LEAN = os.environ.get('CARRIER_LEAN', '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean')
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'assertion', 'failParameter': True, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, value):
        _study_write_text(Path(p), json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    def formal(_science):
        m = _science.context.library('storage_index_transactions_projection')
        qnt = _science.BASE + 'models/quint/storage_index_transactions.qnt'
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = m.generate(ir)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/StorageIndexAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=hashlib.sha256(ast.encode()).hexdigest(), scope='restricted typed IR; native product refinement open'))
        controls = {}
        for label in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if label == 'binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if label == 'field':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if label == 'roster':
                ds['step']['expr']['args'].pop(0)
            if label == 'expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                m.generate(bad)
            except (AssertionError, KeyError):
                controls[label] = 'rejected'
            else:
                raise AssertionError(label)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        lemmas = []
        for n in ['StorageIndexAst', 'StorageIndex', 'StorageIndexAlgebra']:
            source = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', source.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, source.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
            lemmas += [[n + '.' + v] for v in re.findall('^theorem (\\w+)', source.read_text(), re.M)]
        histories = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert histories.count('ok ') == 3
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '461', '--verbosity', '1'], policy=_science.process_profile)
        mutants = [('ignore-pending', 'def reserveBGuard', '(((q.a=(0)) ∨ (q.a=(5))) ∨ (q.adjacent=(1)))', 'True', '{initial with a:=1, aLease:=1, aGeneration:=1, revision:=1, bSnapshot:=1, bSnapshotGeneration:=1}', 'reserveB', None), ('unknown-drain', 'def drainAGuard', '(q.aKnown=(1))', 'True', '{initial with a:=3, aLease:=1, aGeneration:=1, aRoot:=1}', 'drainA', None), ('revoke-drops-lease', 'def revokeANext', 'a:=(3)', 'a:=(3), aLease:=0', '{initial with a:=2, aLease:=1, aGeneration:=1, aRoot:=1}', 'revokeA', None), ('generation-reused', 'def reuseNext', 'generation:=(q.generation+(1))', 'generation:=q.generation', '{initial with opened:=0}', 'reuse', '(reuseNext witness).generation > witness.generation')]
        for label, decl, before, after, state, action, goal in mutants:
            d = _study_workspace('CACHE') / ('negative-' + label)
            d.mkdir(exist_ok=True)
            mutated = '\n'.join((v.replace(before, after) if v.startswith(decl) else v for v in ast.splitlines())) + '\n'
            assert mutated != ast, label
            _study_write_text(d / 'StorageIndexAst.lean', mutated)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(d / 'StorageIndexAst.olean'), str(d / 'StorageIndexAst.lean')], policy=_science.process_profile)
            goal = goal or 'Safe (' + action + 'Next witness)'
            script = 'import StorageIndexAst\nopen StorageIndexAst\ndef witness : State := ' + state + '\nexample : Safe witness := by simp [Safe,witness,initial]' + '\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]' + '\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]' + '\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            _study_write_text(d / 'Control.lean', script)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(d) + ':' + str(_study_workspace('CACHE')), _science.LEAN, str(d / 'Control.lean')], fail=True, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:7:' in out and ('false' in out.lower()), out
        return ([[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']], lemmas)

    def native_model(_science):
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/storage-index-transactions/config.json').read_text())
        keys = [(g, i, f, 'GambitStorageIndexTransactions::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'storage-index-transactions', field_expressions, ordered=True, models=[_science.BASE + 'models/sysml/' + _science.STEM + '.sysml'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(v.values()) for g, v in p.items()}
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        return p

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        p = _science.native_model()
        source = []
        for v in p['source']:
            data = (_science.ROOT / v['path']).read_text()
            assert v['needle'] in data
            source.append([v['key'], v['path'], _science.sha(_science.ROOT / v['path']), v['needle']])
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', [dict(key=k, path=f, sha256=h, needle=n, lines=[data.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(n), data)]) for k, f, h, n in source for data in [(_science.ROOT / f).read_text()]])
        actions, lemmas = _science.formal()
        assert all(([v['lemma']] in lemmas for v in p['proof']))
        needs = [[v['key'], v['kind'], v['path'], _science.sha(_science.ROOT / v['path']), v['scope']] for v in p['need']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        engine = Engine()
        results = {}
        try:
            s = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert s.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'wrong-owner', 'missing-action', 'missing-lemma', 'stale-source', 'wrong-scope', 'missing-route', 'missing-algebra', 'missing-formal']:
                receipts = [[case, n, path, h, sc] for n, kind, path, h, sc in needs if case != 'current' or kind in ['formal', 'bridge']]
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'ST-formal']
                obs = copy.deepcopy(source)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                ro = copy.deepcopy(routes)
                if case == 'wrong-owner':
                    ro[0][0] = 'wrong'
                if case == 'missing-route':
                    ro.pop(0)
                ln = [v for v in lemmas if (case != 'missing-lemma' or v != ['StorageIndex.stepPreserves']) and (case != 'missing-algebra' or v != ['StorageIndexAlgebra.checkedInsert'])]
                s.replace(dict(scenario=[[case]], need=needs, needOwner=[[v['key'], v['owner.componentId']] for v in p['need']], receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=ln, sourceNeed=source, sourceObservation=obs, routeNeed=routes, routeObservation=ro, proofNeed=[[v['key'], v['lemma']] for v in p['proof']] + [['all-step', 'StorageIndex.stepPreserves']], issuerNeed=[], issuerObservation=[]))
                r = s.run(queries=['candidate', 'blocked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 6 and len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        matrix = ['#+TITLE: Unified Storage Index — Benefits, Costs and Closure', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: storage-index-matrix', ':AUTHORITY: GambitStorageIndexTransactions', ':END:', 'Rows below are evaluated from SysML. Formal routes locate proposed replacements; they do not assert existing native implementation.']
        for g in ['gain', 'memory', 'need', 'route', 'proof', 'source']:
            fields = list(p[g][0])
            matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            matrix += ['| ' + ' | '.join((v[f] for f in fields)) + ' |' for v in p[g]]
        matrix += ['', '** Closure observation', '', '| Obligation | Status |', '|---+---|']
        matrix += ['| ' + v['key'] + ' | ' + ('unresolved native integration' if v['key'] in gaps else 'scoped conditional formal receipt') + ' |' for v in p['need']]
        _study_write_text(_science.ROOT / (_science.BASE + _science.STEM + '-matrix.org'), '\n'.join(matrix) + '\n')
        graph = ['direction: down', 'title: "C23 unified storage index: reserve, publish, drain and settle"']
        for v in p['contract']:
            graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 40)))
        d2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _study_write_text(_science.ROOT / d2, '\n'.join(graph) + '\n')
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', d2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(languageBaseline='C23', qntActions=len(actions), qntHistories=3, qntSamples=500, qntMaxSteps=100, seedArgument=461, leanTheorems=len(lemmas), allStepInduction=True, genericIntervalInsertProof=True, fixedOperationIds=2, maximumStorageGenerations=2, typedIrControls=4, concreteCounterexamples=4, sourceAnchors=len(source), componentSourceActionRoutes=len(routes), ascentScenarios=len(results), blockers=gaps, actualCandidate=False, sysmlScope='self-contained native package; not whole DEV', arbitraryConcurrentIndexRefinement=False, c23RefinementProved=False, gcRootPayloadProductProved=False, replayRecordReclamationProved=False, nativePathsRetired=0, nativeTestsRun=False, runtimeImplementation=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/registry-slot-issuance/input.json'
        parent_data = json.loads(parent.read_text())
        composition = parent_data['compositionInputs']
        assert all((_science.sha(_science.ROOT / f) == h for f, h in composition.items())), 'parent composition drift'
        paths = set((v[1] for v in source))
        paths |= {_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'index.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/storage_index_transactions.qnt', d2, d2[:-3] + '.svg', 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', '.cache/tasks/' + _science.STEM + '/config.json'}
        paths |= {_science.BASE + 'models/lean/' + n + '.lean' for n in ['StorageIndexAst', 'StorageIndex', 'StorageIndexAlgebra']}
        data = dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=_science.sha(parent), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(paths)}, compositionInputs=composition)
        for k, f, h, n in source:
            assert _science.sha(_science.ROOT / f) == h, k
        _science.save(_study_workspace('CACHE') / 'input.json', data)

        def copy_receipts():
            for f in _study_workspace('CACHE').iterdir():
                if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                    shutil.copyfile(f, _study_workspace('OUT') / f.name)
        copy_receipts()
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(a, b)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert all((_science.sha(_science.ROOT / f) == h for f, h in data['sourceBindings'].items())), 'input drift'
        data['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', data)
        copy_receipts()
        for d in list(_study_workspace('CACHE').glob('negative-*')) + list(_study_workspace('CACHE').glob('retained-*-failure')):
            if d.is_dir():
                shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
