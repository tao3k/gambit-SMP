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
        _science.STEM = 'default-lease-admission'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitDefaultLeaseAdmission'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/default_section_leases.qnt'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.GROUPS = [['source', 35, 'key path needle obligation'], ['call', 28, 'key path callerName callee siteCount scope'], ['claim', 5, 'key mechanism condition result gap'], ['policy', 7, 'key sourcePath policyAction why migration'], ['receipt', 6, 'key issuer prerequisite failure gap'], ['memory', 5, 'key obligation reuse cost'], ['gain', 5, 'key avoided added condition'], ['contract', 14, 'fromNode toNode custody'], ['obligation', 6, 'key status scope gap'], ['binding', 30, 'actionName lemma scope'], ['proof', 16, 'key lemma scope'], ['seam', 4, 'producer.moduleId consumer.moduleId contract modelNeed'], ['bridge', 1, 'key targetStep lemma scope']]
        _science.SLOTS = ['leasesHistory', 'collectiveHistory', 'leasesInduction', 'collectiveInduction', 'composition', 'projection', 'source', 'platform']
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        keys += [('need', s, f, f'{_science.PKG}::{s}.{f}') for s in _science.SLOTS for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        scope = {p: _science.sha(_science.ROOT / p) for p in sorted(_science.context.command('sysml-inputs', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())}
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', scope)
        field_expressions = []
        for *_, e in keys:
            field_expressions.append(e)
        raw = _study_fields(_science.ROOT, None, 'default-lease-admission', field_expressions, ordered=True, models=['dev'])
        _science.save(_study_workspace('CACHE') / 'global-sysml-status.json', dict(status='pass', loaded=len(scope)))
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
        lines = ['#+TITLE: Default Section Leases — Physical Ownership and Collective Admission Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitDefaultLeaseAdmission', ':STATUS: conditional-formal-model; native-and-C11-open', ':END:']
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
        rows = []
        sites = []
        for path in sorted({v['path'] for v in p['call']}):
            sv = snapshots[path]
            text = (_science.ROOT / sv['path']).read_text()
            mask = re.compile('/\\*.*?\\*/|//[^\\n]*|"(?:\\\\.|[^"\\\\])*"|\\\'(?:\\\\.|[^\\\'\\\\])*\\\'', re.S)
            clean = mask.sub(lambda m: ''.join(('\n' if x == '\n' else ' ' for x in m.group())), text)
            decls = list(re.finditer('^.*?\\b(\\w+)\\s*\\n\\s+___P\\(', clean, re.M))
            need = [v for v in p['call'] if v['path'] == path]
            actual = []
            for f in sorted({v['callee'] for v in need}):
                for hit in re.finditer('\\b' + re.escape(f) + '\\s*\\(', clean):
                    owner = [d for d in decls if d.start() < hit.start()]
                    assert owner, f
                    actual.append(dict(path=path, callee=f, caller=owner[-1].group(1), line=text[:hit.start()].count('\n') + 1))
            assert {(v['caller'], v['callee']) for v in actual} == {(v['callerName'], v['callee']) for v in need}
            for v in need:
                count = sum((1 for x in actual if (x['caller'], x['callee']) == (v['callerName'], v['callee'])))
                assert count == int(v['siteCount']), v
                rows.append([v['key'], v['callerName'], v['callee'], v['siteCount'], sv['sha256']])
            sites += actual
        _science.save(_study_workspace('CACHE') / 'caller-audit.json', dict(status='pass-lexical-snapshot', rows=rows, sites=sites, effectivePreprocessedCallGraph=False))
        return rows

    def formal_files(_science, e):
        return [_science.EMITTER, 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/' + suffix for cfg in e.SPECS for suffix in ['quint/' + cfg['module'] + '.qnt', 'lean/' + cfg['namespace'] + '.lean', 'lean/' + cfg['proof'] + '.lean']] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['DefaultLeaseComposition', 'CapacityChargeAst', 'CapacityCharge']]

    def formals(_science):
        e = _science.context.library('default_lease_admission_projection')
        for cfg in e.SPECS:
            ir = json.loads((_study_workspace('CACHE') / (cfg['module'] + '.json')).read_text())
            ast, rc = e.generate(ir, cfg)
            _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/' + cfg['namespace'] + '.lean'), ast)
            _science.save(_study_workspace('CACHE') / (cfg['module'] + '-projection.json'), dict(**rc, typedIrSha256=_science.sha(_study_workspace('CACHE') / (cfg['module'] + '.json')), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/' + cfg['namespace'] + '.lean'))))
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
                    e.generate(bad, cfg)
                except (AssertionError, KeyError):
                    controls[case] = 'rejected'
                else:
                    raise AssertionError('accepted ' + case)
            _science.save(_study_workspace('CACHE') / (cfg['module'] + '-projection-controls.json'), controls)
        old = _science.context.library('chunk_capacity_charge_projection')
        cfg = old.SPEC
        oldir = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-capacity-charge/chunk_capacity_charge.json'
        ir = json.loads(oldir.read_text())
        a, rr = old.generate(ir, cfg['module'], cfg['fields'], cfg['actions'], cfg['namespace'])
        assert a == (_science.ROOT / (_science.BASE + 'models/lean/CapacityChargeAst.lean')).read_text()
        parent = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-capacity-charge/input.json').read_text())
        for n in ['CapacityChargeAst', 'CapacityCharge']:
            f = _science.BASE + 'models/lean/' + n + '.lean'
            assert _science.sha(_science.ROOT / f) == parent['sourceBindings'][f], f
        _science.save(_study_workspace('CACHE') / 'target-projection.json', dict(**rr, typedIrSha256=_science.sha(oldir), targetAstSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/CapacityChargeAst.lean'))))
        if '--reuse-formal' in _science.context.arguments:
            checkpoint = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            for f, d in checkpoint['sourceBindings'].items():
                assert _science.sha(_science.ROOT / f) == d, f
            for f, d in checkpoint['logs'].items():
                assert _science.sha(_science.ROOT / f) == d, f
        else:
            for cf, nt in zip(e.SPECS, [9, 10], strict=True):
                q = _science.BASE + 'models/quint/' + cf['module'] + '.qnt'
                test = _science.context.command(cf['module'] + '-tests', ['quint', 'test', q, '--match', 'Test$'], policy=_science.process_profile)
                assert test.count('ok ') == nt and test.count('ControlTest passed') == 4
                _science.context.command(cf['module'] + '-samples', ['quint', 'run', q, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '97', '--verbosity', '1'], policy=_science.process_profile)
            for n in ['SectionLeasesAst', 'SectionLeases', 'CapacityCollectiveAst', 'CapacityCollective', 'CapacityChargeAst', 'CapacityCharge', 'DefaultLeaseComposition']:
                f = _study_workspace('CACHE') / (n + '.lean')
                orig = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
                assert not re.search('\\bsorry\\b|\\baxiom\\s', orig.read_text())
                if '--reuse-compiled' in _science.context.arguments:
                    assert f.read_bytes() == orig.read_bytes() and (_study_workspace('CACHE') / (n + '.olean')).is_file() and ('error:' not in (_study_workspace('CACHE') / (n + '.stdout')).read_text()), n
                else:
                    _study_write_bytes(f, orig.read_bytes())
                    _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
            for cf in e.SPECS:
                ast = (_science.ROOT / (_science.BASE + 'models/lean/' + cf['namespace'] + '.lean')).read_text()
                neg = _study_workspace('CACHE') / ('negative-' + cf['proof'])
                neg.mkdir(exist_ok=True)
                if cf['proof'] == 'SectionLeases':
                    bad = '\n'.join((line.replace('owner4:=(0)', 'owner4:=(1)') if line.startswith('def fresh4worker0Next') else line for line in ast.splitlines())) + '\n'
                else:
                    bad = '\n'.join((line.replace('(q.ack1=true)', 'True') if line.startswith('def releaseGuard') else line for line in ast.splitlines())) + '\n'
                assert bad != ast
                f = neg / (cf['namespace'] + '.lean')
                _study_write_text(f, bad)
                _science.context.command('negative-' + cf['proof'] + '-ast', ['lean', '-o', str(neg / (cf['namespace'] + '.olean')), str(f)], policy=_science.process_profile)
                try:
                    _science.context.command('negative-' + cf['proof'] + '-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', str(_science.ROOT / (_science.BASE + 'models/lean/' + cf['proof'] + '.lean'))], policy=_science.process_profile)
                except RuntimeError:
                    assert 'error:' in (_study_workspace('CACHE') / ('negative-' + cf['proof'] + '-proof.stdout')).read_text()
                else:
                    raise AssertionError('mutant proved ' + cf['proof'])
            neg = _study_workspace('CACHE') / 'negative-composition'
            neg.mkdir(exist_ok=True)
            orig = (_science.ROOT / (_science.BASE + 'models/lean/DefaultLeaseComposition.lean')).read_text()
            bad = orig.replace('c.decision=1', 'c.decision=2')
            assert bad != orig
            f = neg / 'DefaultLeaseComposition.lean'
            _study_write_text(f, bad)
            try:
                _science.context.command('negative-composition', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(f)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-composition.stdout').read_text()
            else:
                raise AssertionError('bad collective product proved')
            _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sourceBindings={f: _science.sha(_science.ROOT / f) for f in _science.formal_files(e)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and any((k in f.name for k in ['SectionLeases', 'CapacityCollective', 'CapacityCharge', 'DefaultLeaseComposition', '-tests', '-samples', 'negative-']))}))
        acts = [[cf['module'] + '.' + a] for cf in e.SPECS for a in cf['actions']]
        targets = [['chunk_capacity_charge.' + a] for a in old.SPEC['actions'] + ['step', 'stutter']]
        lemmas = [[n + '.' + x] for n in ['SectionLeases', 'CapacityCollective', 'DefaultLeaseComposition'] for x in re.findall('^\\s*theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        return (e, acts, targets, lemmas)

    def ascend(_science, p, w, acts, targets, lemmas, calls):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        binds = [[v['actionName'], v['lemma']] for v in p['binding']]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in w]
        proofs = [[v['key'], v['lemma']] for v in p['proof']]
        bridges = [[v['key'], v['targetStep'], v['lemma']] for v in p['bridge']]
        queries = ['checked', 'blocked', 'candidate', 'linked', 'observed', 'compositionLinked', 'callLinked', 'bridgeLinked']
        cases = ['current', 'synthetic-all', 'stale-hash', 'wrong-scope', 'missing-source', 'missing-platform', 'missing-action', 'missing-restore-proof', 'missing-target', 'missing-collective-proof', 'missing-witness', 'wrong-caller', 'wrong-count', 'wrong-source-digest', 'missing-collective-receipt']
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
                    rc[0][4] = 'whole-native-closed'
                for label, n in [('missing-source', 'DL-source'), ('missing-platform', 'DL-platform'), ('missing-collective-receipt', 'DL-collectiveInduction')]:
                    if case == label:
                        rc = [v for v in rc if v[1] != n]
                ac = [v for v in acts if case != 'missing-action' or v != ['capacity_collective.release']]
                ls = [v for v in lemmas if (case != 'missing-restore-proof' or v != ['DefaultLeaseComposition.restoredStackSeparate']) and (case != 'missing-collective-proof' or v != ['CapacityCollective.flipRequiresAllAcknowledged'])]
                ts = [v for v in targets if case != 'missing-target' or v != ['chunk_capacity_charge.advanceVisit']]
                obs = copy.deepcopy(calls)
                if case == 'wrong-caller':
                    obs[0][1] = 'not-the-caller'
                if case == 'wrong-count':
                    obs[0][3] = '99'
                if case == 'wrong-source-digest':
                    obs[0][4] = 'stale'
                ss.replace(dict(scenario=[[case]], need=needs, receipt=rc, binding=binds, actionName=ac, lemmaName=ls, witness=ws, observation=ws[1:] if case == 'missing-witness' else ws, compositionNeed=proofs, refinementNeed=[], targetActionName=ts, callNeed=calls, callObservation=obs, bridgeNeed=bridges))
                result = ss.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            assert results['synthetic-all']['candidate']
            for c in cases:
                if c != 'synthetic-all':
                    assert not results[c]['candidate'], c
            a = results['current']
            assert {v[1] for v in a['blocked']} == {'DL-source', 'DL-platform'}
            assert [len(a[k]) for k in ['linked', 'compositionLinked', 'callLinked', 'bridgeLinked']] == [30, 16, 28, 1]
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/chunk-capacity-charge/input.json'
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
            e = _science.context.library('default_lease_admission_projection')
            for cf in e.SPECS:
                _science.context.command(cf['module'] + '-typecheck', ['quint', 'typecheck', _science.BASE + 'models/quint/' + cf['module'] + '.qnt', '--out', str(_study_workspace('CACHE') / (cf['module'] + '.json'))], policy=_science.process_profile)
        e, ac, ts, ls = _science.formals()
        _science.ascend(p, w, ac, ts, ls, calls)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        org = org.replace('(missing nil))', '(missing nil) (external-missing nil))')
        org = org.replace('(unless (file-exists-p target) (push (list file target) missing))', '(unless (file-exists-p target) (if (and (string-suffix-p "/index.org" file) (not (string-match-p "default[-_]lease[-_]admission\\\\|DefaultLease\\\\|SectionLeases\\\\|CapacityCollective" target))) (push (list file target) external-missing) (push (list file target) missing)))')
        org = org.replace('missing=%S; no Babel executed" (length files) links missing', 'missing=%S; concurrent-index-missing=%S; no Babel executed" (length files) links missing external-missing')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert _science.sha(parent) == parentHash
        drift = [dict(path=f, analyzed=v['sha256'], live=_science.sha(_science.ROOT / f)) for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']]
        scopeDrift = [dict(path=f, checked=d, live=_science.sha(_science.ROOT / f)) for f, d in scope.items() if _science.sha(_science.ROOT / f) != d]
        checks = dict(status='conditional-default-lease-collective-model-pass', sysmlInputs=len(scope), sourceAnchors=len(w), literalCallClasses=len(calls), qntModels=2, qntActions=len(ac), qntHistories=19, negativeQntControls=8, samplesPerModel=500, maxSteps=200, leanTheorems=len(ls), allStepInduction=True, guardedProductProved=True, generalCountBoundProved=True, conditionalIntervalGeometryProved=True, actualPriorChargeGuardBridged=True, projectionControls=8, negativeLeanControls=3, ascentScenarios=15, actualCandidate=False, sourceQualified=False, c11Refinement=False, legalSchemeRestoreCounterexample=False, sourceRestoreBound=False, arbitraryRosterRefinement=False, fullMultiContextChargeComposition=False, realCollectiveReceiptIssuer=False, fairnessProved=False, parserVerified=False, emitterVerified=False, nativeTestsRun=False, performanceTestsRun=False, runtimeFilesModifiedByStudy=[], liveSourceDrift=drift, concurrentScopeDrift=scopeDrift)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        files = set(_science.formal_files(e)) | {_science.MODEL, _science.RULES, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py'} | {v['path'] for v in snapshots.values()}
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentHash, parentFrozen=True, sourceSnapshots=snapshots, sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.el', '.lean']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name not in ['artifacts.json', 'final-audit.json']})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Re-extract exact old charge AST and bind its proof to the prior input.
