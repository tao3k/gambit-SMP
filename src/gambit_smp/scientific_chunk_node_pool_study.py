"""Design/formal evidence orchestration only. Native SysML owns model metadata."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil, textwrap

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.textwrap = textwrap
        _science.ROOT = _science.context.root
        _science.STEM = 'chunk-node-pool'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitChunkNodePool'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/chunk_node_pool.qnt'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [('source', 20, 'key path needle obligation'), ('capacity', 5, 'key bound premise counterexample status'), ('progress', 5, 'key mechanism condition gap'), ('receipt', 4, 'key issuer prerequisite revocation gap'), ('memory', 5, 'key ordering obligation gap'), ('gain', 8, 'key avoided added condition'), ('contract', 10, 'fromNode toNode custody'), ('obligation', 7, 'key status scope gap'), ('binding', 17, 'actionName lemma targetStep simulation'), ('proof', 15, 'key lemma scope'), ('seam', 3, 'producer.moduleId consumer.moduleId contract modelNeed')]
        _science.SLOTS = ['history', 'induction', 'composition', 'projection', 'source', 'platform']
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        keys += [('need', s, f, f'{_science.PKG}::{s}.{f}') for s in _science.SLOTS for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        scope = {p: _science.sha(_science.ROOT / p) for p in sorted(_science.context.command('sysml-inputs', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())}
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', scope)
        field_expressions = []
        for *_, e in keys:
            field_expressions.append(e)
        raw = _study_fields(_science.ROOT, None, 'chunk-node-pool', field_expressions, ordered=True, models=['dev'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in _science.GROUPS:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return (p, scope)

    def views(_science, p):

        def cell(s):
            return str(s).replace('\n', '\\n').replace('|', '\\vert{}')
        lines = ['#+TITLE: Independent Chunk Node Pool — Capacity and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitChunkNodePool', ':STATUS: conditional-formal-model; native-and-C11-open', ':END:']
        for g, _, schema in _science.GROUPS:
            fs = schema.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((cell(v[f]) for f in fs)) + ' |' for v in p[g]]
        lines += ['', '** Scoped proof routing', '', '| ID | kind | path | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for n in sorted({v[f] for v in p['contract'] for f in ['fromNode', 'toNode']}):
            graph += [json.dumps(n) + ': ' + json.dumps(n)]
        for v in p['contract']:
            graph += [json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 24))]
        graph += ['proof: ' + json.dumps('SysML -> ASCENT -> QNT / Lean\nConditional model; native / C11 OPEN')]
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def formals(_science):
        e = _science.context.library('chunk_node_pool_projection')
        ir = json.loads((_study_workspace('CACHE') / 'chunk_node_pool.json').read_text())
        ast, rc = e.generate(ir)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/NodePoolAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'typed-projection.json', dict(**rc, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'chunk_node_pool.json'), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/NodePoolAst.lean'))))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if case == 'wrong-state-binding':
                bad['table'][str(rc['stateReferences'][0][0])]['id'] = -1
            if case == 'wrong-field-kind':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if case == 'missing-step':
                ds['step']['expr']['args'].pop(0)
            if case == 'unsupported-expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                e.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError('projection accepted ' + case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        actions = [[e.SPEC['module'] + '.' + x] for x in e.SPEC['actions']]
        imported = ['WeakAdmissionAst', 'WeakAdmission', 'DelayedLedgerAst', 'DelayedLedger', 'MarkerTransportAst', 'MarkerTransport', 'TransportComposition']
        files = [_science.EMITTER, 'src/gambit_smp/scientific_chunk_transport_ledger_projection.py', _science.QNT] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['NodePoolAst', 'NodePool', 'NodePoolComposition'] + imported]
        if '--reuse-formal' in _science.context.arguments:
            old = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            for f, d in old['sourceBindings'].items():
                assert _science.sha(_science.ROOT / f) == d, f
            for f, d in old['logs'].items():
                assert _science.sha(_science.ROOT / f) == d, f
        else:
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 10 and tests.count('ControlTest passed') == 4
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '73', '--verbosity', '1'], policy=_science.process_profile)
            for n in ['NodePoolAst', 'NodePool'] + imported + ['NodePoolComposition']:
                f = _study_workspace('CACHE') / (n + '.lean')
                if '--reuse-compiled' in _science.context.arguments:
                    assert f.read_bytes() == (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_bytes(), n
                else:
                    _study_write_bytes(f, (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_bytes())
                assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
                if '--reuse-compiled' in _science.context.arguments:
                    assert (_study_workspace('CACHE') / (n + '.olean')).is_file(), n
                    assert 'error:' not in (_study_workspace('CACHE') / (n + '.stdout')).read_text(), n
                else:
                    _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
            neg = _study_workspace('CACHE') / 'negative-reserve'
            neg.mkdir(exist_ok=True)
            bad = ast.replace('issued:=(q.issued+(1))', 'issued:=(q.issued+(2))')
            assert bad != ast
            f = neg / 'NodePoolAst.lean'
            _study_write_text(f, bad)
            _science.context.command('negative-reserve-ast', ['lean', '-o', str(neg / 'NodePoolAst.olean'), str(f)], policy=_science.process_profile)
            try:
                _science.context.command('negative-reserve-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', str(_science.ROOT / (_science.BASE + 'models/lean/NodePool.lean'))], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-reserve-proof.stdout').read_text()
            else:
                raise AssertionError('bad reserve proved')
            neg = _study_workspace('CACHE') / 'negative-composition'
            neg.mkdir(exist_ok=True)
            original = (_science.ROOT / (_science.BASE + 'models/lean/NodePoolComposition.lean')).read_text()
            bad = original.replace('active:=q.debt', 'active:=q.debt+1')
            assert bad != original
            f = neg / 'NodePoolComposition.lean'
            _study_write_text(f, bad)
            try:
                _science.context.command('negative-composition', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(f)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-composition.stdout').read_text()
            else:
                raise AssertionError('bad composition proved')
            _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sourceBindings={f: _science.sha(_science.ROOT / f) for f in files}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and any((k in f.name for k in ['NodePool', 'WeakAdmission', 'DelayedLedger', 'MarkerTransport', 'TransportComposition', 'quint-', 'negative-']))}))
        old = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-transport-ledger/input.json').read_text())
        for n in imported:
            f = _science.BASE + 'models/lean/' + n + '.lean'
            assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f] if f in old['sourceBindings'] else _science.sha(_science.ROOT / f) == json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/frame-chunk-weak-producers/input.json').read_text())['sourceBindings'][f]
        target = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/frame-chunk-weak-producers/weak_producer_admission.json').read_text())
        targets = [[target['modules'][0]['name'] + '.' + d['name']] for d in target['modules'][0]['declarations'] if d.get('qualifier') == 'action'] + [['weak_producer_admission.stutter']]
        lemmas = []
        for n in ['NodePool', 'NodePoolComposition']:
            lemmas += [[n + '.' + x] for x in re.findall('^\\s*theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        return (e, actions, targets, lemmas, files)

    def ascend(_science, p, witness, actions, targets, lemmas):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        binds = [[v['actionName'], v['lemma']] for v in p['binding']]
        refs = [[v['actionName'], v['targetStep'], v['simulation']] for v in p['binding']]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witness]
        cs = [[v['key'], v['lemma']] for v in p['proof']]
        queries = ['checked', 'blocked', 'candidate', 'linked', 'observed', 'compositionLinked', 'refinementLinked']
        cases = ['current', 'synthetic-all', 'stale-hash', 'wrong-scope', 'missing-source', 'missing-platform', 'missing-action', 'missing-lemma', 'missing-target', 'missing-simulation', 'missing-witness', 'missing-capacity-proof', 'missing-induction']
        engine = _science.h.Engine()
        results = {}
        try:
            ss = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert ss.run(queries=queries)['complete']
            for c in cases:
                rc = [[c, n, path, d, scope] for n, k, path, d, scope in needs if c != 'current' or k in ['interleaving', 'induction', 'restricted-projection']]
                if c == 'stale-hash':
                    rc[0][3] = 'stale'
                if c == 'wrong-scope':
                    rc[0][4] = 'wider-native-scope'
                for case, need in [('missing-source', 'NP-source'), ('missing-platform', 'NP-platform'), ('missing-induction', 'NP-induction')]:
                    if c == case:
                        rc = [v for v in rc if v[1] != need]
                ac = [v for v in actions if c != 'missing-action' or v != ['chunk_node_pool.reserve']]
                ls = [v for v in lemmas if (c != 'missing-lemma' or v != ['NodePool.reservePreserves']) and (c != 'missing-simulation' or v != ['NodePoolComposition.reserveSimulates']) and (c != 'missing-capacity-proof' or v != ['NodePool.permittedReserveHasSpace'])]
                ts = [v for v in targets if c != 'missing-target' or v != ['weak_producer_admission.deriveChild']]
                ss.replace(dict(scenario=[[c]], need=needs, receipt=rc, binding=binds, actionName=ac, lemmaName=ls, witness=ws, observation=ws[1:] if c == 'missing-witness' else ws, compositionNeed=cs, refinementNeed=refs, targetActionName=ts))
                res = ss.run(queries=queries)
                assert res['complete']
                results[c] = res['relations']
            assert len(results['synthetic-all']['candidate']) == 1
            for c in cases:
                if c != 'synthetic-all':
                    assert not results[c]['candidate'], c
            assert {v[1] for v in results['current']['blocked']} == {'NP-source', 'NP-platform'}
            assert len(results['current']['refinementLinked']) == 17 and len(results['current']['linked']) == 17 and (len(results['current']['compositionLinked']) == 15)
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-transport-ledger/input.json'
        parentHash = _science.sha(parent)
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snapshots.items():
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        p, scope = _science.project()
        _science.views(p)
        w = []
        for v in p['source']:
            sv = snapshots[v['path']]
            t = (_science.ROOT / sv['path']).read_text()
            assert v['needle'] in t, v['key']
            w.append(dict(**v, snapshotPath=sv['path'], sha256=sv['sha256'], lines=[t[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), t)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', w)
        _science.save(_study_workspace('OUT') / 'source-witnesses.json', w)
        if '--reuse-formal' not in _science.context.arguments:
            _science.context.command('typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'chunk_node_pool.json')], policy=_science.process_profile)
        e, ac, ts, ls, formalFiles = _science.formals()
        _science.ascend(p, w, ac, ts, ls)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        org = org.replace('(missing nil))', '(missing nil) (external-missing nil))')
        org = org.replace('(unless (file-exists-p target) (push (list file target) missing))', '(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "chunk[-_]node[-_]pool\\\\|NodePool" target))) (push (list file target) external-missing) (push (list file target) missing)))')
        org = org.replace('missing=%S; no Babel executed" (length files) links missing', 'missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
        _science.save(_study_workspace('OUT') / 'input.json', dict(status='validation-in-progress', sourceSnapshots=snapshots, sourceWitnessesSha256=_science.sha(_study_workspace('CACHE') / 'source-witnesses.json'), parentInputSha256=parentHash))
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert _science.sha(parent) == parentHash
        scopeDrift = [dict(path=f, checked=d, live=_science.sha(_science.ROOT / f)) for f, d in scope.items() if _science.sha(_science.ROOT / f) != d]
        drift = [dict(path=f, analyzed=v['sha256'], live=_science.sha(_science.ROOT / f)) for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']]
        checks = dict(status='conditional-pool-model-induction-pass', sourceAnchors=len(w), sysmlInputs=len(scope), qntActions=len(ac), qntHistories=10, negativeQntControls=4, samples=500, maxSteps=200, leanTheorems=len(ls), allStepInduction=True, weakStepSimulations=17, compositionProofs=15, projectionControls=4, negativeLeanControls=2, ascentScenarios=13, actualCandidate=False, sourceQualified=False, c11Refinement=False, sourceCapacityInjection=False, sourceProducerClosure=False, sourceReclaimIssuer=False, fairnessProved=False, parserVerified=False, emitterVerified=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[], liveSourceDrift=drift, concurrentScopeDrift=scopeDrift)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        files = set(formalFiles) | {_science.MODEL, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py'} | {v['path'] for v in snapshots.values()}
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceSnapshots=snapshots, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name not in ['artifacts.json', 'final-audit.json']})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Verify imported AST and proof identities against frozen predecessor input.
# The shared index can have incomplete concurrent study links; report them separately.
# Whole-scope validation receipt stays bound to its checked digests amid concurrent edits.
