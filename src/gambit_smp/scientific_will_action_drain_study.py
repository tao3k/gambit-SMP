"""Source/formal evidence only. Native SysML owns research routing. No native tests."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.ROOT = _science.context.root
        _science.STEM = 'will-action-drain'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitWillActionDrain'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def formal(_science):
        e = _science.context.library('will_action_drain_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        formalPaths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['WillDrainAst', 'WillDrain']]
        if '--reuse-formal' in _science.context.arguments:
            checkpoint = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == checkpoint['sources']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in checkpoint['logs'].items()))
            lemmas = [['WillDrain.' + n] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/WillDrain.lean')).read_text(), re.M)]
            return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, rc = e.generate(ir)
        path = _science.BASE + 'models/lean/WillDrainAst.lean'
        _study_write_text(_science.ROOT / path, ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**rc, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / path), scope='restricted typed IR; JSON parser and projection trusted; C23 source simulation open'))
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
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        for n in ['WillDrainAst', 'WillDrain']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
        tests = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 11
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '257', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-issue'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(q.weak=(0))', 'True') if line.startswith('def issueGuard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'WillDrainAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'WillDrainAst.olean'), str(neg / 'WillDrainAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/WillDrain.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('weak-pending issue guard accepted')
        lemmas = [['WillDrain.' + n] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/WillDrain.lean')).read_text(), re.M)]
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formalPaths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in ['typecheck', 'WillDrainAst', 'WillDrain', 'histories', 'samples', 'negative-ast', 'negative-proof']}))
        return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/will-action-drain/config.json').read_text())
        snap = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == _science.sha(_science.ROOT / v['path']) == v['sha256'], f
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/callback-carry-closure/input.json'
        parentHash = _science.sha(parent)
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=cfg['groups'], SLOTS=cfg['slots']).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=cfg['groups'], MATRIX=_science.BASE + _science.STEM + '-matrix.org', D2=_science.BASE + 'diagrams/' + _science.STEM + '.d2').items():
            setattr(view, k, v)
        view.views(p)
        matrix = _science.ROOT / (_science.BASE + _science.STEM + '-matrix.org')
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Will Creator, Restoration Custody and Retirement Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-root-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / roots / exceptions / C23 OPEN'))
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / snap[v['path']]['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap[v['path']]['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        generated = (_science.ROOT / snap['vendor/gambit/lib/_kernel.c']['path']).read_text()
        start = generated.index('#define ___PH_PROC ___H__23__23_will_2d_execute_21_')
        end = generated.index('#undef ___PH_PROC', start)
        body = generated[start:end]
        ordered = ['___SET_R2(___WILLTESTATOR(___R1))', '___SET_R3(___WILLACTION(___R1))', '___WILLTESTATORSET(___R1,___FAL)', '___WILLACTIONSET(___R1,___FAL)', '___SET_R1(___R2)', '___POLL(1)', '___JUMPGENNOTSAFE(___SET_NARGS(1),___R3)']
        positions = [body.index(v) for v in ordered]
        assert positions == sorted(positions)
        _science.save(_study_workspace('CACHE') / 'action-artifact-slice.json', dict(path='vendor/gambit/lib/_kernel.c', sha256=snap['vendor/gambit/lib/_kernel.c']['sha256'], startLine=generated[:start].count('\n') + 1, endLine=generated[:end].count('\n') + 1, orderedTokens=ordered, positions=positions, configurationMatched=False, scope='lexical artifact order; generated roots and source/configuration match unresolved'))
        inventoryFiles = sorted(set((_science.ROOT / 'vendor/gambit/gsc').rglob('*.scm')) | set((_science.ROOT / 'vendor/gambit/lib').rglob('*.scm')))
        inventoryInputs = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in inventoryFiles}
        matches = []
        for f in inventoryFiles:
            path = str(f.relative_to(_science.ROOT))
            corpus = 'gsc-tests' if '/gsc/tests/' in path else 'gsc-core' if '/gsc/' in path else 'runtime-core' if f.parent == _science.ROOT / 'vendor/gambit/lib' else 'runtime-library-or-fixture'
            for lineNo, line in enumerate(f.read_bytes().decode('utf-8', 'surrogateescape').splitlines(), 1):
                if not any((token in line for token in ['make-will', 'make-final-will', 'will-action-set!', 'will-testator-set!'])):
                    continue
                matches.append(dict(path=path, corpus=corpus, line=lineNo, text=line.strip(), comment=line.lstrip().startswith(';'), applicationLooking=bool(re.search('\\((?:##make-will|make-will|##make-final-will)(?:\\s|\\))', line)), definition='define-prim' in line or '(define (' in line))
        _science.save(_study_workspace('CACHE') / 'creator-inventory.json', dict(inputs=inventoryInputs, matches=matches, encoding='UTF8 with byte-preserving surrogateescape; raw hashes bind original fixtures', scope='recursive Scheme lexical inventory; no verified parser or indirect/native call closure; core/specifications/optional libraries/tests distinguished'))
        actions, lemmas = _science.formal()
        for v in p['proof']:
            assert [v['lemma']] in lemmas, v
        needs = [[v[k] for k in ['obligationId', 'kind', 'subjectPath']] + [_science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        owners = [[v['obligationId'], v['owner.componentId']] for v in p['need'].values()]
        sources = [[v[k] for k in ['key', 'path', 'sha256', 'needle']] for v in witnesses]
        creators = [[v[k] for k in ['key', 'producer', 'captures', 'writes', 'reachability', 'retirement']] for v in p['creator']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        proofs = [[v['key'], v['lemma']] for v in p['proof']]
        results = {}
        cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-creator', 'missing-formal', 'wrong-scope', 'wrong-owner', 'missing-weak-route']
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, path, digest, sc] for n, k, path, digest, sc in needs if case != 'current' or n == 'WD-formal']
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'WD-formal']
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                obs = copy.deepcopy(sources)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                co = copy.deepcopy(creators)
                if case == 'wrong-creator':
                    co[3][4] = 'proved-default-core-startup-without-evidence'
                ro = copy.deepcopy(routes)
                if case == 'wrong-owner':
                    ro[0][0] = 'execution'
                if case == 'missing-weak-route':
                    ro = [r for r in ro if r[1] != 'will_action_drain.makeExecutable']
                session.replace(dict(scenario=[[case]], need=needs, needOwner=owners, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-lemma' or v != ['WillDrain.stepPreserves']], sourceNeed=sources, sourceObservation=obs, creatorNeed=creators, creatorObservation=co, routeNeed=routes, routeObservation=ro, proofNeed=proofs))
                r = session.run(queries=['blocked', 'candidate', 'linked', 'sourceLinked', 'creatorLinked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        assert [k for k in cases if results[k]['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 6, gaps
        assert len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT))], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-will-drain-safety-pass-actual-retirement-denied', languageBaseline='C23', sourceSnapshots=len(snap), sourceAnchors=len(witnesses), creatorClasses=len(creators), componentSourceActionRoutes=len(routes), inventoryFiles=len(inventoryInputs), qntActions=len(actions), qntHistories=11, qntSamples=500, seed=257, leanTheorems=len(lemmas), allStepInduction=True, typedIrControls=4, negativeIssueControl=True, ascentScenarios=len(cases), actualCandidate=False, firstNativeRetirement=False, secondNativeRetirement=False, defaultSessionEffectfulWillWitness=False, compiledRootMapQualified=False, currentProducerConsumerMatched=False, eventualDrainProved=False, c23RefinementProved=False, blockers=gaps, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for old, new in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(old, new)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == v['sha256'], f
        assert _science.sha(parent) == parentHash
        for f, digest in inventoryInputs.items():
            assert _science.sha(_science.ROOT / f) == digest, ('inventory drift', f)
        for f, digest in scope.items():
            assert _science.sha(_science.ROOT / f) == digest, ('sysml drift', f)
        own = [_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/will_action_drain.qnt', _science.BASE + 'models/lean/WillDrainAst.lean', _science.BASE + 'models/lean/WillDrain.lean', _science.BASE + 'index.org', _science.BASE + 'language-baseline-design.org', _science.BASE + 'callback-carry-closure-design.org', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT)), 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', str((_study_workspace('CACHE') / 'config.json').relative_to(_science.ROOT)), str((_study_workspace('CACHE') / 'source-snapshots.json').relative_to(_science.ROOT))] + [v['path'] for v in snap.values()]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=parentHash, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snap, sysmlInputs=scope, lexicalInputs=inventoryInputs))

        def copy_receipts():
            for f in _study_workspace('CACHE').iterdir():
                if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                    shutil.copyfile(f, _study_workspace('OUT') / f.name)
        copy_receipts()
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        data = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
        data['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', data)
        copy_receipts()
        shutil.copytree(_study_workspace('CACHE') / 'negative-issue', _study_workspace('OUT') / 'negative-issue', dirs_exist_ok=True)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Bounded artifact procedure slice; no assertion that its generation matches current source.
# Native Org parser and link audit, without Babel evaluation.
