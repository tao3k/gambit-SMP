#!/usr/bin/env python3
"""Scoped source/formal research. Native SysML evaluates routing; no runtime tests."""
import copy
import hashlib
import importlib.util
import json
import os
import re
import shutil
import subprocess
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
STEM = 'storage-index-transactions'
BASE = 'dev/refactoring/modern-c/'
CACHE = ROOT / '.cache/tasks' / STEM
OUT = ROOT / 'evidence/research' / STEM
LEAN = os.environ.get('CARRIER_LEAN', '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean')


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def save(p, value):
    Path(p).write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


def run(name, argv, fail=False):
    save(CACHE / (name + '.command.json'), argv)
    try:
        p = subprocess.run(argv, cwd=ROOT, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired as e:
        save(CACHE / (name + '.timeout.json'), dict(timeout=60, argv=argv))
        raise RuntimeError(name + ': timeout; no pass receipt') from e
    (CACHE / (name + '.stdout')).write_text(p.stdout)
    (CACHE / (name + '.stderr')).write_text(p.stderr)
    if p.returncode:
        save(CACHE / (name + '.failure.json'), dict(exit=p.returncode, argv=argv))
    if fail:
        assert p.returncode != 0, name
    else:
        assert p.returncode == 0, (name, p.stdout[-2000:], p.stderr[-2000:])
    return p.stdout


def projection():
    path = ROOT / ('dev/modeling/tools/' + STEM + '-projection.py')
    spec = importlib.util.spec_from_file_location('storage_projection', path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def formal():
    m = projection()
    qnt = BASE + 'models/quint/storage_index_transactions.qnt'
    run('typecheck', ['quint', 'typecheck', qnt, '--out', str(CACHE / 'typed-ir.json')])
    ir = json.loads((CACHE / 'typed-ir.json').read_text())
    ast, receipt = m.generate(ir)
    (ROOT / (BASE + 'models/lean/StorageIndexAst.lean')).write_text(ast)
    save(CACHE / 'projection.json', dict(**receipt, irSha256=sha(CACHE / 'typed-ir.json'),
         astSha256=hashlib.sha256(ast.encode()).hexdigest(), scope='restricted typed IR; native product refinement open'))
    controls = {}
    for label in ['binding', 'field', 'roster', 'expression']:
        bad = copy.deepcopy(ir)
        ds = {d['name']: d for d in bad['modules'][0]['declarations']}
        if label == 'binding': bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
        if label == 'field': ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
        if label == 'roster': ds['step']['expr']['args'].pop(0)
        if label == 'expression': ds['safe']['expr']['opcode'] = 'unsupported'
        try:
            m.generate(bad)
        except (AssertionError, KeyError):
            controls[label] = 'rejected'
        else:
            raise AssertionError(label)
    save(CACHE / 'projection-controls.json', controls)
    lemmas = []
    for n in ['StorageIndexAst', 'StorageIndex', 'StorageIndexAlgebra']:
        source = ROOT / (BASE + 'models/lean/' + n + '.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s', source.read_text())
        target = CACHE / (n + '.lean')
        target.write_bytes(source.read_bytes())
        run(n, ['env', 'LEAN_PATH=' + str(CACHE), LEAN, '-o', str(CACHE / (n + '.olean')), str(target)])
        lemmas += [[n + '.' + v] for v in re.findall(r'^theorem (\w+)', source.read_text(), re.M)]
    histories = run('histories', ['quint', 'test', qnt, '--match', 'Test$'])
    assert histories.count('ok ') == 3
    run('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe',
                   '--max-samples', '500', '--max-steps', '100', '--seed', '461', '--verbosity', '1'])
    mutants = [
        ('ignore-pending', 'def reserveBGuard', '(((q.a=(0)) ∨ (q.a=(5))) ∨ (q.adjacent=(1)))', 'True',
         '{initial with a:=1, aLease:=1, aGeneration:=1, revision:=1, bSnapshot:=1, bSnapshotGeneration:=1}', 'reserveB', None),
        ('unknown-drain', 'def drainAGuard', '(q.aKnown=(1))', 'True',
         '{initial with a:=3, aLease:=1, aGeneration:=1, aRoot:=1}', 'drainA', None),
        ('revoke-drops-lease', 'def revokeANext', 'a:=(3)', 'a:=(3), aLease:=0',
         '{initial with a:=2, aLease:=1, aGeneration:=1, aRoot:=1}', 'revokeA', None),
        ('generation-reused', 'def reuseNext', 'generation:=(q.generation+(1))', 'generation:=q.generation',
         '{initial with opened:=0}', 'reuse', '(reuseNext witness).generation > witness.generation'),
    ]
    for label, decl, before, after, state, action, goal in mutants:
        d = CACHE / ('negative-' + label)
        d.mkdir(exist_ok=True)
        mutated = '\n'.join(v.replace(before, after) if v.startswith(decl) else v for v in ast.splitlines()) + '\n'
        assert mutated != ast, label
        (d / 'StorageIndexAst.lean').write_text(mutated)
        run(label + '-ast', [LEAN, '-o', str(d / 'StorageIndexAst.olean'), str(d / 'StorageIndexAst.lean')])
        goal = goal or 'Safe (' + action + 'Next witness)'
        script = ('import StorageIndexAst\nopen StorageIndexAst\ndef witness : State := ' + state +
                  '\nexample : Safe witness := by simp [Safe,witness,initial]' +
                  '\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]' +
                  '\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]' +
                  '\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n')
        (d / 'Control.lean').write_text(script)
        out = run(label + '-control', ['env', 'LEAN_PATH=' + str(d) + ':' + str(CACHE), LEAN, str(d / 'Control.lean')], fail=True)
        assert out.count('error:') == 1 and 'Control.lean:7:' in out and 'false' in out.lower(), out
    return [[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']], lemmas


def native_model():
    cfg = json.loads((CACHE / 'config.json').read_text())
    keys = [(g, i, f, 'GambitStorageIndexTransactions::' + g + str(i) + '.' + f)
            for g, n, fs in cfg for i in range(n) for f in fs.split()]
    args = ['sysml', '-strict', '-no-record-cache', '-validate', '-json']
    for *_, expr in keys: args += ['-e', expr]
    raw = json.loads(run('sysml-scoped', args + [BASE + 'models/sysml/' + STEM + '.sysml']))
    assert raw['exit'] == 0 and not raw.get('errors')
    assert not any(d['severity'] == 'error' for d in (raw.get('diagnostics') or []))
    vals = [json.loads(v[4:]) for v in raw['output'] if v.startswith('  = ')]
    assert len(vals) == len(keys)
    p = {}
    for (g, i, f, _), v in zip(keys, vals, strict=True): p.setdefault(g, {}).setdefault(i, {})[f] = v
    p = {g: list(v.values()) for g, v in p.items()}
    save(CACHE / 'native-queries.json', keys)
    save(CACHE / 'sysml-projection.json', p)
    return p


def main():
    from ascent import Engine
    CACHE.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    p = native_model()
    source = []
    for v in p['source']:
        data = (ROOT / v['path']).read_text()
        assert v['needle'] in data
        source.append([v['key'], v['path'], sha(ROOT / v['path']), v['needle']])
    save(CACHE / 'source-witnesses.json', [dict(key=k, path=f, sha256=h, needle=n,
         lines=[data.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(n), data)])
         for k, f, h, n in source for data in [(ROOT / f).read_text()]])
    actions, lemmas = formal()
    assert all([v['lemma']] in lemmas for v in p['proof'])
    needs = [[v['key'], v['kind'], v['path'], sha(ROOT / v['path']), v['scope']] for v in p['need']]
    routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
    engine = Engine()
    results = {}
    try:
        s = engine.open_sources((ROOT / ('dev/modeling/ascent/' + STEM + '.rules.scm')).read_text())
        assert s.run(queries=['blocked'])['complete']
        for case in ['current', 'synthetic-all', 'wrong-owner', 'missing-action', 'missing-lemma', 'stale-source', 'wrong-scope', 'missing-route', 'missing-algebra', 'missing-formal']:
            receipts = [[case, n, path, h, sc] for n, kind, path, h, sc in needs
                        if case != 'current' or kind in ['formal', 'bridge']]
            if case == 'wrong-scope': receipts[0][-1] = 'native-performance'
            if case == 'missing-formal': receipts = [v for v in receipts if v[1] != 'ST-formal']
            obs = copy.deepcopy(source)
            if case == 'stale-source': obs[0][2] = 'stale'
            ro = copy.deepcopy(routes)
            if case == 'wrong-owner': ro[0][0] = 'wrong'
            if case == 'missing-route': ro.pop(0)
            ln = [v for v in lemmas if (case != 'missing-lemma' or v != ['StorageIndex.stepPreserves'])
                  and (case != 'missing-algebra' or v != ['StorageIndexAlgebra.checkedInsert'])]
            s.replace(dict(scenario=[[case]], need=needs, needOwner=[[v['key'], v['owner.componentId']] for v in p['need']],
                           receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']],
                           actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=ln,
                           sourceNeed=source, sourceObservation=obs, routeNeed=routes, routeObservation=ro,
                           proofNeed=[[v['key'], v['lemma']] for v in p['proof']] + [['all-step', 'StorageIndex.stepPreserves']],
                           issuerNeed=[], issuerObservation=[]))
            r = s.run(queries=['candidate', 'blocked', 'routeLinked', 'proofLinked'])
            assert r['complete']
            results[case] = r['relations']
    finally:
        engine.close()
    assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
    gaps = sorted(v[1] for v in results['current']['blocked'])
    assert len(gaps) == 6 and len(results['current']['routeLinked']) == len(routes)
    save(CACHE / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
    matrix = ['#+TITLE: Unified Storage Index — Benefits, Costs and Closure',
              '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never',
              '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: storage-index-matrix',
              ':AUTHORITY: GambitStorageIndexTransactions', ':END:',
              'Rows below are evaluated from SysML. Formal routes locate proposed replacements; they do not assert existing native implementation.']
    for g in ['gain', 'memory', 'need', 'route', 'proof', 'source']:
        fields = list(p[g][0])
        matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join('---' for _ in fields) + '|']
        matrix += ['| ' + ' | '.join(v[f] for f in fields) + ' |' for v in p[g]]
    matrix += ['', '** Closure observation', '', '| Obligation | Status |', '|---+---|']
    matrix += ['| ' + v['key'] + ' | ' + ('unresolved native integration' if v['key'] in gaps else 'scoped conditional formal receipt') + ' |' for v in p['need']]
    (ROOT / (BASE + STEM + '-matrix.org')).write_text('\n'.join(matrix) + '\n')
    graph = ['direction: down', 'title: "C23 unified storage index: reserve, publish, drain and settle"']
    for v in p['contract']:
        graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 40)))
    d2 = BASE + 'diagrams/' + STEM + '.d2'
    (ROOT / d2).write_text('\n'.join(graph) + '\n')
    run('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'])
    run('d2-png', ['d2', '--layout', 'elk', d2, str(CACHE / 'diagram.png')])
    checks = dict(languageBaseline='C23', qntActions=len(actions), qntHistories=3, qntSamples=500,
                  qntMaxSteps=100, seedArgument=461, leanTheorems=len(lemmas), allStepInduction=True,
                  genericIntervalInsertProof=True, fixedOperationIds=2, maximumStorageGenerations=2,
                  typedIrControls=4, concreteCounterexamples=4, sourceAnchors=len(source),
                  componentSourceActionRoutes=len(routes), ascentScenarios=len(results), blockers=gaps,
                  actualCandidate=False, sysmlScope='self-contained native package; not whole DEV',
                  arbitraryConcurrentIndexRefinement=False, c23RefinementProved=False,
                  gcRootPayloadProductProved=False, replayRecordReclamationProved=False,
                  nativePathsRetired=0, nativeTestsRun=False, runtimeImplementation=False, performanceTestsRun=False)
    save(CACHE / 'checks.json', checks)
    # Hash binding includes every current modular composition input, without preprocessing.
    parent = ROOT / 'evidence/research/registry-slot-issuance/input.json'
    parent_data = json.loads(parent.read_text())
    composition = parent_data['compositionInputs']
    assert all(sha(ROOT / f) == h for f, h in composition.items()), 'parent composition drift'
    paths = set(v[1] for v in source)
    paths |= {BASE + STEM + '-design.org', BASE + STEM + '-matrix.org', BASE + 'index.org',
              BASE + 'models/sysml/' + STEM + '.sysml', BASE + 'models/quint/storage_index_transactions.qnt',
              d2, d2[:-3] + '.svg', 'dev/modeling/ascent/' + STEM + '.rules.scm',
              'dev/modeling/tools/' + STEM + '-study.py', 'dev/modeling/tools/' + STEM + '-projection.py',
              'dev/modeling/tools/chunk-capacity-charge-projection.py',
              '.cache/tasks/' + STEM + '/config.json'}
    paths |= {BASE + 'models/lean/' + n + '.lean' for n in ['StorageIndexAst', 'StorageIndex', 'StorageIndexAlgebra']}
    data = dict(head=run('head', ['git', 'rev-parse', 'HEAD']).strip(),
                branch=run('branch', ['git', 'branch', '--show-current']).strip(),
                parentPath=str(parent.relative_to(ROOT)), parentInputSha256=sha(parent),
                sourceBindings={f: sha(ROOT / f) for f in sorted(paths)}, compositionInputs=composition)
    for k, f, h, n in source: assert sha(ROOT / f) == h, k
    save(CACHE / 'input.json', data)
    def copy_receipts():
        for f in CACHE.iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']: shutil.copyfile(f, OUT / f.name)
    copy_receipts()
    # Make the linked manifest exist before the native Org link audit; refresh it
    # after the audit logs and retained controls have also been copied below.
    save(OUT / 'artifacts.json', {str(f.relative_to(ROOT)): sha(f) for f in OUT.rglob('*') if f.is_file() and f.name != 'artifacts.json'})
    org = (ROOT / 'evidence/research/iter-compiler-service/check-org.el').read_text()
    for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', BASE + STEM + '-design.org'),
                 ('dev/architecture/toolchain/iter-compiler-service-matrix.org', BASE + STEM + '-matrix.org'),
                 ('dev/architecture/toolchain/index.org', BASE + 'index.org')]: org = org.replace(a, b)
    (CACHE / 'check-org.el').write_text(org)
    run('org-check', ['emacs', '--batch', '-Q', '--load', str(CACHE / 'check-org.el')])
    assert all(sha(ROOT / f) == h for f, h in data['sourceBindings'].items()), 'input drift'
    data['logs'] = {str(f.relative_to(ROOT)): sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout', '.stderr']}
    save(CACHE / 'input.json', data)
    copy_receipts()
    for d in list(CACHE.glob('negative-*')) + list(CACHE.glob('retained-*-failure')):
        if d.is_dir(): shutil.copytree(d, OUT / d.name, dirs_exist_ok=True)
    save(OUT / 'artifacts.json', {str(f.relative_to(ROOT)): sha(f) for f in OUT.rglob('*') if f.is_file() and f.name != 'artifacts.json'})
    print(json.dumps(checks))


if __name__ == '__main__':
    main()
