"""Formal/source research only. Native SysML owns architecture and proof metadata."""
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
        _science.STEM = 'chunk-capacity-charge'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitChunkCapacityCharge'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/chunk_capacity_charge.qnt'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [('source', 24, 'key path needle obligation'), ('call', 9, 'key callerName callee siteCount effect'), ('charge', 7, 'key mechanism bound excluded status'), ('receipt', 5, 'key issuer condition failure gap'), ('memory', 5, 'key ordering obligation gap'), ('gain', 6, 'key avoided added condition'), ('contract', 11, 'fromNode toNode custody'), ('obligation', 6, 'key status scope gap'), ('binding', 12, 'actionName lemma targetStep simulation'), ('proof', 12, 'key lemma scope'), ('seam', 3, 'producer.moduleId consumer.moduleId contract modelNeed')]
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
        raw = _study_fields(_science.ROOT, None, 'chunk-capacity-charge', field_expressions, ordered=True, models=['dev'])
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
        lines = ['#+TITLE: Chunk Capacity Charges — Source Closure and Net Benefit Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitChunkCapacityCharge', ':STATUS: conditional-formal-model; native-and-C11-open', ':END:']
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

    def caller_audit(_science, p, snapshots):
        sv = snapshots['vendor/gambit/lib/mem.c']
        text = (_science.ROOT / sv['path']).read_text()
        mask = re.compile('/\\*.*?\\*/|//[^\\n]*|"(?:\\\\.|[^"\\\\])*"|\\\'(?:\\\\.|[^\\\'\\\\])*\\\'', re.S)
        clean = mask.sub(lambda m: ''.join(('\n' if x == '\n' else ' ' for x in m.group())), text)
        decls = list(re.finditer('^.*?\\b(\\w+)\\s*\\n\\s+___P\\(', clean, re.M))
        actual = []
        rows = []
        for f in sorted({v['callee'] for v in p['call']}):
            for hit in re.finditer('\\b' + re.escape(f) + '\\s*\\(', clean):
                owner = [d for d in decls if d.start() < hit.start()]
                assert owner, f
                actual.append(dict(callee=f, caller=owner[-1].group(1), line=text[:hit.start()].count('\n') + 1))
        expected = {(v['callerName'], v['callee']) for v in p['call']}
        assert {(v['caller'], v['callee']) for v in actual} == expected, (actual, expected)
        for v in p['call']:
            matches = [x for x in actual if (x['caller'], x['callee']) == (v['callerName'], v['callee'])]
            assert len(matches) == int(v['siteCount']), v
            rows.append([v['key'], v['callerName'], v['callee'], v['siteCount'], sv['sha256']])
        _science.save(_study_workspace('CACHE') / 'caller-audit.json', dict(status='pass-lexical-snapshot', snapshot=sv, rows=rows, sites=actual, effectivePreprocessedCallGraph=False))
        return rows

    def formal_files(_science):
        return [_science.EMITTER, _science.QNT] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['CapacityChargeAst', 'CapacityCharge', 'CapacityChargeComposition', 'NodePoolAst', 'NodePool']]

    def formals(_science):
        e = _science.context.library('chunk_capacity_charge_projection')
        cfg = e.SPEC
        ir = json.loads((_study_workspace('CACHE') / 'chunk_capacity_charge.json').read_text())
        ast, rc = e.generate(ir, cfg['module'], cfg['fields'], cfg['actions'], cfg['namespace'])
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/CapacityChargeAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'typed-projection.json', dict(**rc, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'chunk_capacity_charge.json'), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/CapacityChargeAst.lean'))))
        controls = {}
        for case in ['wrong-state-binding', 'wrong-field-kind', 'missing-step', 'unsupported-expression', 'nonliteral-multiplication']:
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
            if case == 'nonliteral-multiplication':

                def visit(x):
                    if isinstance(x, dict):
                        if x.get('opcode') == 'imul':
                            x['args'] = [copy.deepcopy(ds['safe']['expr']['args'][0]['args'][0])] * 2
                            return True
                        return any((visit(v) for v in x.values()))
                    if isinstance(x, list):
                        return any((visit(v) for v in x))
                    return False
                assert visit(ds['safe']['expr'])
            try:
                e.generate(bad, cfg['module'], cfg['fields'], cfg['actions'], cfg['namespace'])
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError('accepted ' + case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        old = _science.context.library('chunk_node_pool_projection')
        oldir = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-node-pool/chunk_node_pool.json'
        targetAst, tr = old.generate(json.loads(oldir.read_text()))
        assert targetAst == (_science.ROOT / (_science.BASE + 'models/lean/NodePoolAst.lean')).read_text()
        parent = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-node-pool/input.json').read_text())
        for n in ['NodePoolAst', 'NodePool']:
            f = _science.BASE + 'models/lean/' + n + '.lean'
            assert _science.sha(_science.ROOT / f) == parent['sourceBindings'][f], f
        _science.save(_study_workspace('CACHE') / 'target-projection.json', dict(**tr, typedIrSha256=_science.sha(oldir), targetAstSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/NodePoolAst.lean'))))
        if '--reuse-formal' in _science.context.arguments:
            checkpoint = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            for f, v in checkpoint['sourceBindings'].items():
                assert _science.sha(_science.ROOT / f) == v, f
            for f, v in checkpoint['logs'].items():
                assert _science.sha(_science.ROOT / f) == v, f
        else:
            tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 12 and tests.count('ControlTest passed') == 5
            _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '83', '--verbosity', '1'], policy=_science.process_profile)
            for n in ['CapacityChargeAst', 'CapacityCharge', 'NodePoolAst', 'NodePool', 'CapacityChargeComposition']:
                f = _study_workspace('CACHE') / (n + '.lean')
                original = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
                assert not re.search('\\bsorry\\b|\\baxiom\\s', original.read_text())
                if '--reuse-compiled' in _science.context.arguments:
                    assert f.read_bytes() == original.read_bytes() and (_study_workspace('CACHE') / (n + '.olean')).is_file(), n
                    assert 'error:' not in (_study_workspace('CACHE') / (n + '.stdout')).read_text(), n
                else:
                    _study_write_bytes(f, original.read_bytes())
                    _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
            neg = _study_workspace('CACHE') / 'negative-birth'
            neg.mkdir(exist_ok=True)
            bad = ast.replace('starts:=(q.starts+(1))', 'starts:=(q.starts+(2))')
            assert bad != ast
            f = neg / 'CapacityChargeAst.lean'
            _study_write_text(f, bad)
            _science.context.command('negative-birth-ast', ['lean', '-o', str(neg / 'CapacityChargeAst.olean'), str(f)], policy=_science.process_profile)
            try:
                _science.context.command('negative-birth-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', str(_science.ROOT / (_science.BASE + 'models/lean/CapacityCharge.lean'))], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-birth-proof.stdout').read_text()
            else:
                raise AssertionError('bad birth proved')
            neg = _study_workspace('CACHE') / 'negative-composition'
            neg.mkdir(exist_ok=True)
            orig = (_science.ROOT / (_science.BASE + 'models/lean/CapacityChargeComposition.lean')).read_text()
            bad = orig.replace('p.issued=q.starts', 'p.issued=q.starts+1')
            assert bad != orig
            f = neg / 'CapacityChargeComposition.lean'
            _study_write_text(f, bad)
            try:
                _science.context.command('negative-composition', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(f)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-composition.stdout').read_text()
            else:
                raise AssertionError('bad composition proved')
            _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sourceBindings={f: _science.sha(_science.ROOT / f) for f in _science.formal_files()}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and any((k in f.name for k in ['CapacityCharge', 'NodePool', 'quint-', 'negative-']))}))
        actions = [[cfg['module'] + '.' + x] for x in cfg['actions']]
        targets = [['chunk_node_pool.' + x] for x in old.SPEC['actions'] + ['stutter']]
        lemmas = [[n + '.' + x] for n in ['CapacityCharge', 'CapacityChargeComposition'] for x in re.findall('^\\s*theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        return (actions, targets, lemmas)

    def ascend(_science, p, w, actions, targets, lemmas, calls):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        binds = [[v['actionName'], v['lemma']] for v in p['binding']]
        refs = [[v['actionName'], v['targetStep'], v['simulation']] for v in p['binding']]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in w]
        cs = [[v['key'], v['lemma']] for v in p['proof']]
        queries = ['checked', 'blocked', 'candidate', 'linked', 'observed', 'compositionLinked', 'refinementLinked', 'callLinked']
        cases = ['current', 'synthetic-all', 'stale-hash', 'wrong-scope', 'missing-source', 'missing-platform', 'missing-action', 'missing-lemma', 'missing-target', 'missing-child-proof', 'missing-witness', 'wrong-caller', 'wrong-site-count', 'wrong-source-digest', 'missing-composition']
        engine = _science.h.Engine()
        results = {}
        try:
            ss = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert ss.run(queries=queries)['complete']
            for case in cases:
                rc = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction', 'restricted-projection']]
                if case == 'stale-hash':
                    rc[0][3] = 'stale'
                if case == 'wrong-scope':
                    rc[0][4] = 'unproved-global-native'
                for label, n in [('missing-source', 'CC-source'), ('missing-platform', 'CC-platform'), ('missing-composition', 'CC-composition')]:
                    if case == label:
                        rc = [v for v in rc if v[1] != n]
                ac = [v for v in actions if case != 'missing-action' or v != ['chunk_capacity_charge.advanceVisit']]
                ls = [v for v in lemmas if (case != 'missing-lemma' or v != ['CapacityCharge.exactBirthCount']) and (case != 'missing-child-proof' or v != ['CapacityChargeComposition.thresholdChild'])]
                ts = [v for v in targets if case != 'missing-target' or v != ['chunk_node_pool.reserve']]
                obs = copy.deepcopy(calls)
                if case == 'wrong-caller':
                    obs[0][1] = 'not-a-caller'
                if case == 'wrong-site-count':
                    obs[0][3] = '99'
                if case == 'wrong-source-digest':
                    obs[0][4] = 'stale'
                ss.replace(dict(scenario=[[case]], need=needs, receipt=rc, binding=binds, actionName=ac, lemmaName=ls, witness=ws, observation=ws[1:] if case == 'missing-witness' else ws, compositionNeed=cs, refinementNeed=refs, targetActionName=ts, callNeed=calls, callObservation=obs))
                result = ss.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            assert results['synthetic-all']['candidate']
            for c in cases:
                if c != 'synthetic-all':
                    assert not results[c]['candidate'], c
            a = results['current']
            assert {v[1] for v in a['blocked']} == {'CC-source', 'CC-platform'}
            assert [len(a[k]) for k in ['linked', 'refinementLinked', 'compositionLinked', 'callLinked']] == [12, 12, 12, 9]
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-node-pool/input.json'
        parentHash = _science.sha(parent)
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for v in snapshots.values():
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
        calls = _science.caller_audit(p, snapshots)
        shutil.copyfile(_study_workspace('CACHE') / 'caller-audit.json', _study_workspace('OUT') / 'caller-audit.json')
        if '--reuse-formal' not in _science.context.arguments:
            _science.context.command('typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'chunk_capacity_charge.json')], policy=_science.process_profile)
        ac, ts, ls = _science.formals()
        _science.ascend(p, w, ac, ts, ls, calls)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        org = org.replace('(missing nil))', '(missing nil) (external-missing nil))')
        org = org.replace('(unless (file-exists-p target) (push (list file target) missing))', '(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "chunk[-_]capacity[-_]charge\\\\|CapacityCharge" target))) (push (list file target) external-missing) (push (list file target) missing)))')
        org = org.replace('missing=%S; no Babel executed" (length files) links missing', 'missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert _science.sha(parent) == parentHash
        drift = [dict(path=f, analyzed=v['sha256'], live=_science.sha(_science.ROOT / f)) for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']]
        scopeDrift = [dict(path=f, checked=d, live=_science.sha(_science.ROOT / f)) for f, d in scope.items() if _science.sha(_science.ROOT / f) != d]
        checks = dict(status='conditional-charge-product-induction-pass', sysmlInputs=len(scope), sourceAnchors=len(w), literalCallClasses=len(calls), qntActions=len(ac), qntHistories=12, negativeQntControls=5, samples=500, maxSteps=200, leanTheorems=len(ls), allStepInduction=True, guardedPoolProductProved=True, phaseCarryProved=True, projectionControls=5, negativeLeanControls=2, ascentScenarios=15, actualCandidate=False, sourceQualified=False, c11Refinement=False, sourceLeaseInjection=False, defaultProfileAdmitted=False, realCapacityReceiptIssuer=False, fairnessProved=False, parserVerified=False, emitterVerified=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[], liveSourceDrift=drift, concurrentScopeDrift=scopeDrift)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        files = set(_science.formal_files()) | {_science.MODEL, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_chunk_node_pool_projection.py', 'src/gambit_smp/scientific_chunk_transport_ledger_projection.py'} | {v['path'] for v in snapshots.values()}
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceSnapshots=snapshots, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name not in ['artifacts.json', 'final-audit.json']})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Lexical masking preserves source offsets; no claim of full C parsing.
# Validate actual previous typed AST, not only filenames or hand-written target names.
