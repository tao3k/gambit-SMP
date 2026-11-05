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
import sys
import textwrap
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
STEM = 'rc-storage-lifecycle'
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
        save(CACHE / (name + '.timeout.json'), dict(timeout=60, argv=argv, partialOutputAvailable=e.stdout is not None))
        if e.stdout is not None: (CACHE/(name+'.partial.stdout')).write_bytes(e.stdout if isinstance(e.stdout,bytes) else e.stdout.encode())
        if e.stderr is not None: (CACHE/(name+'.partial.stderr')).write_bytes(e.stderr if isinstance(e.stderr,bytes) else e.stderr.encode())
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
    modules = ['RcStorageAst','RcStorageAllocation','RcStorageRootAdmission','RcStorageReferences','RcStoragePublication','RcStorageAccess','RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership','RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal','RcStorageCleanup','RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse','RcStorage','RcStorageBoundary']
    formal_paths = [BASE+'models/quint/rc_storage_lifecycle.qnt','dev/modeling/tools/rc-storage-lifecycle-projection.py','dev/modeling/tools/chunk-capacity-charge-projection.py'] + [BASE+'models/lean/'+n+'.lean' for n in modules]
    def names():
        return [['RcStorageBoundary.'+v if n=='RcStorageBoundary' else 'RcStorage.'+v] for n in modules if n!='RcStorageAst' for v in re.findall(r'^theorem (\w+)',(ROOT/(BASE+'models/lean/'+n+'.lean')).read_text(),re.M)]
    if '--reuse-formal' in sys.argv:
        cp = json.loads((CACHE/'formal-checkpoint.json').read_text())
        assert cp['sources'] == {f:sha(ROOT/f) for f in formal_paths}
        assert all(sha(ROOT/f)==h for f,h in cp['logs'].items())
        return [[m.SPEC['module']+'.'+a] for a in m.SPEC['actions']], names()
    qnt = BASE + 'models/quint/rc_storage_lifecycle.qnt'
    run('typecheck', ['quint', 'typecheck', qnt, '--out', str(CACHE / 'typed-ir.json')])
    ir = json.loads((CACHE / 'typed-ir.json').read_text())
    ast, receipt = m.generate(ir)
    (ROOT / (BASE + 'models/lean/RcStorageAst.lean')).write_text(ast)
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
    for n in ['RcStorageAst', 'RcStorageAllocation', 'RcStorageRootAdmission', 'RcStorageReferences', 'RcStoragePublication', 'RcStorageAccess', 'RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership', 'RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal', 'RcStorageCleanup', 'RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse', 'RcStorage', 'RcStorageBoundary']:
        source = ROOT / (BASE + 'models/lean/' + n + '.lean')
        assert not re.search(r'\bsorry\b|\baxiom\s', source.read_text())
        target = CACHE / (n + '.lean')
        target.write_bytes(source.read_bytes())
        checkpoint = CACHE/(n+'.compiled.json')
        def dependencies(module, seen=None):
            seen = set() if seen is None else seen
            src = ROOT/(BASE+'models/lean/'+module+'.lean')
            if src in seen: return {}
            seen.add(src)
            ds = {str(src.relative_to(ROOT)):sha(src)}
            for imported in re.findall(r'^import (RcStorage\w*)$',src.read_text(),re.M): ds.update(dependencies(imported,seen))
            return ds
        deps = dependencies(n)
        if '--reuse-compiled' in sys.argv and checkpoint.exists():
            prior = json.loads(checkpoint.read_text())
            assert {f:prior['inputs'][f] for f in deps}==deps and prior['olean']==sha(CACHE/(n+'.olean'))
            assert all(sha(ROOT/f)==h for f,h in prior['logs'].items())
        else:
            run(n, ['env', 'LEAN_PATH=' + str(CACHE), LEAN, '-o', str(CACHE / (n + '.olean')), str(target)])
            save(checkpoint,dict(inputs=deps,olean=sha(CACHE/(n+'.olean')),logs={str((CACHE/(n+x)).relative_to(ROOT)):sha(CACHE/(n+x)) for x in ['.stdout','.stderr']}))
        lemmas += [[('RcStorageBoundary' if n=='RcStorageBoundary' else 'RcStorage') + '.' + v] for v in re.findall(r'^theorem (\w+)', source.read_text(), re.M)]
    histories = run('histories', ['quint', 'test', qnt, '--match', 'Test$'])
    assert histories.count('ok ') == 7
    run('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe',
                   '--max-samples', '500', '--max-steps', '100', '--seed', '463', '--verbosity', '1'])
    mutants = [
        ('premature-free', 'def finishFreeGuard', '(q.phase=(7))', '(q.phase=(2))',
         '{initial with phase:=2, operation:=1, owned:=1, base:=1, sourceHold:=1, owner:=1, keyGeneration:=1, checked:=1}', 'finishFree', None),
        ('unknown-commit', 'def unpublishGuard', '(q.known=(1))', 'True',
         '{initial with phase:=5, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, keyGeneration:=1, index:=3, committed:=1, effects:=1, checked:=1}', 'unpublish', None),
        ('context-exit', 'def exitContextGuard', '((q.owner=(2)) ∨ ((q.owned=(0)) ∧ (q.sourceHold=(0))))', 'True',
         '{initial with phase:=4, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, contextClosing:=1, keyGeneration:=1, index:=2, committed:=1, base:=1, checked:=1}', 'exitContext', None),
        ('generation-reused', 'def reuseAddressNext', 'generation:=(q.generation+(1))', 'generation:=q.generation',
         '{initial with phase:=8, operation:=1, index:=4, known:=1, frees:=1, keyGeneration:=1, checked:=1, grace:=1, effects:=1, owner:=1}', 'reuseAddress', '(reuseAddressNext witness).generation > witness.generation'),
    ]
    for label, decl, before, after, state, action, goal in mutants:
        d = CACHE / ('negative-' + label)
        d.mkdir(exist_ok=True)
        mutated = '\n'.join(v.replace(before, after) if v.startswith(decl) else v for v in ast.splitlines()) + '\n'
        assert mutated != ast, label
        (d / 'RcStorageAst.lean').write_text(mutated)
        run(label + '-ast', [LEAN, '-o', str(d / 'RcStorageAst.olean'), str(d / 'RcStorageAst.lean')])
        goal = goal or 'Safe (' + action + 'Next witness)'
        script = ('import RcStorageAst\nopen RcStorageAst\ndef witness : State := ' + state +
                  '\nexample : Safe witness := by simp [Safe,witness,initial]' +
                  '\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]' +
                  '\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]' +
                  '\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n')
        (d / 'Control.lean').write_text(script)
        out = run(label + '-control', ['env', 'LEAN_PATH=' + str(d) + ':' + str(CACHE), LEAN, str(d / 'Control.lean')], fail=True)
        assert out.count('error:') == 1 and 'Control.lean:7:' in out and 'false' in out.lower(), out
    save(CACHE/'formal-checkpoint.json',dict(sources={f:sha(ROOT/f) for f in formal_paths},logs={str(f.relative_to(ROOT)):sha(f) for f in CACHE.iterdir() if f.suffix in ['.stdout','.stderr'] and f.stem not in ['sysml-scoped','d2-svg','d2-png','org-check','head','branch']}))
    return [[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']], lemmas


def native_model():
    cfg = json.loads((CACHE / 'config.json').read_text())
    keys = [(g, i, f, 'GambitRcStorageLifecycle::' + g + str(i) + '.' + f)
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
    rc_path = 'vendor/gambit/lib/_mem/rc-allocation.inc'
    rc = (ROOT / rc_path).read_text()
    private = rc.split('___EXP_FUNC(void*,___alloc_rc_no_register)', 1)[1].split('___EXP_FUNC(void,___register_rc)', 1)[0]
    assert 'h->refcount = 1;' in private and 'h->data = ___FAL;' in private
    assert 'h->prev' not in private and 'h->next' not in private
    save(CACHE / 'private-allocation-slice.json', dict(path=rc_path, sha256=sha(ROOT / rc_path),
         startLine=rc[:rc.index('___EXP_FUNC(void*,___alloc_rc_no_register)')].count('\n')+1,
         refcountAndFalseDataInitialized=True, listLinksInitialized=False,
         scope='bounded lexical function body; not complete C or allocator semantics'))
    corpus = ['vendor/gambit/lib', 'vendor/gambit/include', 'vendor/gambit/examples']
    globs = ['-g','*.c','-g','*.inc','-g','*.h','-g','*.h.in','-g','*.scm']
    paths = run('rc-caller-files', ['rg','--files']+corpus+globs).splitlines()
    caller_inputs = {f:sha(ROOT/f) for f in paths}
    run('rc-caller-sites', ['rg','-n','--no-heading',r'___alloc_rc_no_register|___register_rc|___alloc_rc\b|___release_rc\b|___addref_rc\b|___refcount_rc\b|cleanup_rc']+corpus+globs)
    save(CACHE / 'rc-caller-inventory.json', dict(inputs=caller_inputs, scope=corpus,
         includesTemplatesAndGeneratedHeaders=True, completeLiteralEnumeration=True,
         completeIndirectAndOutOfTreeCallerClosure=False))
    actions, lemmas = formal()
    assert all([v['lemma']] in lemmas for v in p['proof'])
    needs = [[v['key'], v['kind'], v['path'], sha(ROOT / v['path']), v['scope']] for v in p['need']]
    routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
    engine = Engine()
    results = {}
    try:
        s = engine.open_sources((ROOT / ('dev/modeling/ascent/' + STEM + '.rules.scm')).read_text())
        assert s.run(queries=['blocked'])['complete']
        for case in ['current', 'synthetic-all', 'wrong-owner', 'missing-action', 'missing-lemma', 'stale-source', 'wrong-scope', 'missing-route', 'missing-algebra', 'missing-formal', 'wrong-issuer']:
            receipts = [[case, n, path, h, sc] for n, kind, path, h, sc in needs
                        if case != 'current' or kind in ['formal', 'bridge']]
            if case == 'wrong-scope': receipts[0][-1] = 'native-performance'
            if case == 'missing-formal': receipts = [v for v in receipts if v[1] != 'RC-formal']
            obs = copy.deepcopy(source)
            if case == 'stale-source': obs[0][2] = 'stale'
            ro = copy.deepcopy(routes)
            if case == 'wrong-owner': ro[0][0] = 'wrong'
            if case == 'missing-route': ro.pop(0)
            ln = [v for v in lemmas if (case != 'missing-lemma' or v != ['RcStorage.stepPreserves'])
                  and (case != 'missing-algebra' or v != ['RcStorageBoundary.addressOnlyCannotSeparate'])]
            issuer_observation = [[v[k] for k in ['key','proposedIssuer','actualSource','status','responsibility']] for v in p['issuer']]
            if case == 'wrong-issuer': issuer_observation[0][2] = 'fabricated existing StorageId signer'
            s.replace(dict(scenario=[[case]], need=needs, needOwner=[[v['key'], v['owner.componentId']] for v in p['need']],
                           receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']],
                           actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=ln,
                           sourceNeed=source, sourceObservation=obs, routeNeed=routes, routeObservation=ro,
                           proofNeed=[[v['key'], v['lemma']] for v in p['proof']] + [['all-step', 'RcStorage.stepPreserves']],
                           issuerNeed=[[v[k] for k in ['key','proposedIssuer','actualSource','status','responsibility']] for v in p['issuer']], issuerObservation=issuer_observation))
            r = s.run(queries=['candidate', 'blocked', 'routeLinked', 'proofLinked'])
            assert r['complete']
            results[case] = r['relations']
    finally:
        engine.close()
    assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
    gaps = sorted(v[1] for v in results['current']['blocked'])
    assert len(gaps) == 6 and len(results['current']['routeLinked']) == len(routes)
    save(CACHE / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
    matrix = ['#+TITLE: RC Allocation and Storage Index — Benefits, Costs and Closure',
              '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never',
              '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: storage-index-matrix',
              ':AUTHORITY: GambitRcStorageLifecycle', ':END:',
              'Rows below are evaluated from SysML. Formal routes locate proposed replacements; they do not assert existing native implementation.']
    for g in ['gain', 'memory', 'issuer', 'need', 'route', 'proof', 'source']:
        fields = list(p[g][0])
        matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join('---' for _ in fields) + '|']
        matrix += ['| ' + ' | '.join(v[f] for f in fields) + ' |' for v in p[g]]
    matrix += ['', '** Closure observation', '', '| Obligation | Status |', '|---+---|']
    matrix += ['| ' + v['key'] + ' | ' + ('unresolved native integration' if v['key'] in gaps else 'scoped conditional formal receipt') + ' |' for v in p['need']]
    (ROOT / (BASE + STEM + '-matrix.org')).write_text('\n'.join(matrix) + '\n')
    graph = ['direction: down', 'title: "C23 RC lifecycle: allocation, root admission, custody and physical release"']
    for v in p['contract']:
        graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 40)))
    d2 = BASE + 'diagrams/' + STEM + '.d2'
    (ROOT / d2).write_text('\n'.join(graph) + '\n')
    run('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'])
    run('d2-png', ['d2', '--layout', 'elk', d2, str(CACHE / 'diagram.png')])
    checks = dict(languageBaseline='C23', qntActions=len(actions), qntHistories=7, qntSamples=500,
                  qntMaxSteps=100, seedArgument=463, leanTheorems=len(lemmas), allStepInduction=True,
                  genericBoundaryProof=True, allocationCohorts=1, maximumOperations=2, maximumStorageGenerations=2,
                  typedIrControls=4, concreteCounterexamples=4, sourceAnchors=len(source), issuerRoles=len(p['issuer']),
                  componentSourceActionRoutes=len(routes), ascentScenarios=len(results), blockers=gaps,
                  actualCandidate=False, sysmlScope='self-contained native package; not whole DEV',
                  arbitraryConcurrentIndexRefinement=False, c23RefinementProved=False, addressOnlyDiscriminationImpossible=True, realStorageIdIssuerQualified=False, completeRawCallerClosure=False,
                  gcRootPayloadProductProved=False, replayRecordReclamationProved=False,
                  nativePathsRetired=0, nativeTestsRun=False, runtimeImplementation=False, performanceTestsRun=False)
    save(CACHE / 'checks.json', checks)
    # Hash binding includes every current modular composition input, without preprocessing.
    parent = ROOT / 'evidence/research/storage-index-transactions/input.json'
    parent_data = json.loads(parent.read_text())
    composition = parent_data['compositionInputs']
    assert all(sha(ROOT / f) == h for f, h in composition.items()), 'parent composition drift'
    paths = set(v[1] for v in source)
    paths |= {BASE + STEM + '-design.org', BASE + STEM + '-matrix.org', BASE + 'index.org',
              BASE + 'models/sysml/' + STEM + '.sysml', BASE + 'models/quint/rc_storage_lifecycle.qnt',
              d2, d2[:-3] + '.svg', 'dev/modeling/ascent/' + STEM + '.rules.scm',
              'dev/modeling/tools/' + STEM + '-study.py', 'dev/modeling/tools/' + STEM + '-projection.py',
              'dev/modeling/tools/chunk-capacity-charge-projection.py',
              '.cache/tasks/' + STEM + '/config.json'}
    paths |= {BASE + 'models/lean/' + n + '.lean' for n in ['RcStorageAst', 'RcStorageAllocation', 'RcStorageRootAdmission', 'RcStorageReferences', 'RcStoragePublication', 'RcStorageAccess', 'RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership', 'RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal', 'RcStorageCleanup', 'RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse', 'RcStorage', 'RcStorageBoundary']}
    data = dict(head=run('head', ['git', 'rev-parse', 'HEAD']).strip(),
                branch=run('branch', ['git', 'branch', '--show-current']).strip(),
                parentPath=str(parent.relative_to(ROOT)), parentInputSha256=sha(parent),
                sourceBindings={f: sha(ROOT / f) for f in sorted(paths)}, compositionInputs=composition,
                literalCallerInputs=caller_inputs)
    assert all(sha(ROOT/f)==h for f,h in caller_inputs.items()), 'caller source drift'
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
