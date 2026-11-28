"""Native SysML + source/formal research. Never builds or runs Gambit."""
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy, json, re, shutil
from pathlib import Path

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
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'module-spec-handle-migration'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitModuleSpecHandleMigration'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.EMITTER = _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_'))
        _science.GROUPS = [['source', 53, 'key path needle obligation'], ['inventory', 6, 'key path pattern count scope'], ['consumer', 8, 'key callers custody gap'], ['claim', 7, 'key mechanism condition result gap'], ['memory', 5, 'key publication consumer gap'], ['gain', 6, 'key avoided added condition'], ['member', 7, 'key fields producer lifetime migration'], ['contract', 17, 'fromNode toNode custody'], ['binding', 30, 'actionName lemma scope'], ['proof', 10, 'key lemma'], ['migration', 6, 'key producerAnchor consumerAnchor actionName lemma'], ['seam', 4, 'producer.componentId consumer.componentId contract actionName lemma']]
        _science.SLOTS = ['history', 'induction', 'composition', 'projection', 'source', 'platform']
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/image-membership-enrollment/input.json'
        parentDigest = _science.sha(parent)
        snapshots = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for v in snapshots.values():
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        adapter = _science.context.library('default_lease_admission_study')
        for k, v in dict(CACHE=_study_workspace('CACHE'), OUT=_study_workspace('OUT'), PKG=_science.PKG, GROUPS=_science.GROUPS, SLOTS=_science.SLOTS).items():
            setattr(adapter, k, v)
        p, scope = adapter.project()
        view = _science.context.library('copy_producer_envelope_study')
        for k, v in dict(ROOT=_science.ROOT, GROUPS=_science.GROUPS, MATRIX=_science.MATRIX, D2=_science.D2).items():
            setattr(view, k, v)
        view.views(p)
        f = _science.ROOT / _science.MATRIX
        _study_write_text(f, f.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'ModuleSpec, Controlled ModuleHandle and Net Benefit Matrix').replace('GambitCopyProducerEnvelope', _science.PKG))
        witnesses = []
        for v in p['source']:
            snap = snapshots[v['path']]
            text = (_science.ROOT / snap['path']).read_text()
            assert v['needle'] in text, v['key']
            witnesses.append(dict(**v, snapshotPath=snap['path'], sha256=snap['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('OUT') / 'source-witnesses.json', witnesses)
        inventory = []
        for v in p['inventory']:
            sv = snapshots[v['path']]
            text = (_science.ROOT / sv['path']).read_text()
            hits = list(re.finditer(v['pattern'], text, re.M))
            assert len(hits) == int(v['count']), v
            inventory.append([v['key'], v['path'], str(len(hits)), sv['sha256'], v['scope']])
        _science.save(_study_workspace('CACHE') / 'writer-inventory.json', inventory)
        _science.save(_study_workspace('OUT') / 'writer-inventory.json', inventory)
        emitter = _science.context.library('module_spec_handle_migration_projection')
        cfg = emitter.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        _science.context.command('qnt-typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / (cfg['module'] + '.json'))], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / (cfg['module'] + '.json')).read_text())
        ast, rc = emitter.generate(ir)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/ModuleHandleAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'projection-receipt.json', dict(**rc, irSha256=_science.sha(_study_workspace('CACHE') / (cfg['module'] + '.json')), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/ModuleHandleAst.lean'))))
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
                emitter.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        prior = json.loads(parent.read_text())
        oldCache = _science.ROOT / '.cache/tasks/image-membership-enrollment'
        imported = []
        for f, d in prior['sourceBindings'].items():
            if '/models/lean/' not in f:
                continue
            assert _science.sha(_science.ROOT / f) == d, f
            n = Path(f).name
            cached = oldCache / n
            obj = cached.with_suffix('.olean')
            assert cached.read_bytes() == (_science.ROOT / f).read_bytes() and obj.is_file(), n
            shutil.copyfile(cached, _study_workspace('CACHE') / n)
            shutil.copyfile(obj, _study_workspace('CACHE') / obj.name)
            imported.append(f)
        _science.save(_study_workspace('CACHE') / 'imported-proof-bindings.json', {f: _science.sha(_science.ROOT / f) for f in imported})
        formalPaths = ['dev/refactoring/modern-c/models/quint/module_spec_handle.qnt', 'dev/refactoring/modern-c/models/lean/ModuleHandleAst.lean', 'dev/refactoring/modern-c/models/lean/ModuleHandle.lean', 'dev/refactoring/modern-c/models/lean/ModuleHandleComposition.lean', 'src/gambit_smp/scientific_module_spec_handle_migration_projection.py', 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + imported
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == cp['sourceBindings']
            for f, d in cp['logs'].items():
                assert _science.sha(_science.ROOT / f) == d, f
        else:
            for n in ['ModuleHandleAst', 'ModuleHandle', 'ModuleHandleComposition']:
                original = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
                assert not re.search('\\bsorry\\b|\\baxiom\\s', original.read_text())
                f = _study_workspace('CACHE') / (n + '.lean')
                _study_write_bytes(f, original.read_bytes())
                _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
            tests = _science.context.command('qnt-histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
            assert tests.count('ok ') == 17 and tests.count('ControlTest passed') == 7
            _science.context.command('qnt-samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '131', '--verbosity', '1'], policy=_science.process_profile)
            neg = _study_workspace('CACHE') / 'negative-issue'
            neg.mkdir(exist_ok=True)
            bad = '\n'.join((l.replace('(¬(q.raw=true))', 'True') if l.startswith('def issueGuard') else l for l in ast.splitlines())) + '\n'
            assert bad != ast
            _study_write_text(neg / 'ModuleHandleAst.lean', bad)
            _science.context.command('negative-ast', ['lean', '-o', str(neg / 'ModuleHandleAst.olean'), str(neg / 'ModuleHandleAst.lean')], policy=_science.process_profile)
            try:
                _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/ModuleHandle.lean'], policy=_science.process_profile)
            except RuntimeError:
                assert 'error' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
            else:
                raise AssertionError('mutant proof accepted')
        actions = [['module_spec_handle.' + a] for a in cfg['actions']]
        lemmas = [[n + '.' + v] for n in ['ModuleHandle', 'ModuleHandleComposition'] for v in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        ws = [[v['key'], v['path'], v['sha256'], v['needle']] for v in witnesses]
        bridges = [['prior-global-retirement-contract', str(parent.relative_to(_science.ROOT)), parentDigest, 'ModuleHandleComposition.rawMigrationBlocksPriorPermit']]
        cases = ['current', 'synthetic-all', 'stale-digest', 'wrong-scope', 'missing-action', 'missing-proof', 'missing-anchor', 'wrong-parent', 'missing-seam', 'wrong-inventory', 'missing-migration', 'wrong-migration-producer']
        seams = [[v[f] for f in ['producer.componentId', 'consumer.componentId', 'contract', 'actionName', 'lemma']] for v in p['seam']]
        migrations = [[v[f] for f in ['key', 'producerAnchor', 'consumerAnchor', 'actionName', 'lemma']] for v in p['migration']]
        results = {}
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, f, d, s] for n, k, f, d, s in needs if case != 'current' or k in ['induction', 'interleaving', 'restricted-projection']]
                if case == 'stale-digest':
                    receipts[0][3] = 'stale'
                if case == 'wrong-scope':
                    receipts[0][4] = 'native-pass'
                bridge = copy.deepcopy(bridges)
                if case == 'wrong-parent':
                    bridge[0][2] = 'stale'
                observedInventory = copy.deepcopy(inventory)
                if case == 'wrong-inventory':
                    observedInventory[0][2] = '999'
                migrationObservation = copy.deepcopy(migrations)
                if case == 'missing-migration':
                    migrationObservation = migrationObservation[1:]
                if case == 'wrong-migration-producer':
                    migrationObservation[0][1] = 'missing-producer'
                session.replace(dict(migrationNeed=migrations, migrationObservation=migrationObservation, scenario=[[case]], need=needs, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if case != 'missing-proof' or v != ['ModuleHandleComposition.rawMigrationBlocksPriorPermit']], witness=ws, observation=ws[1:] if case == 'missing-anchor' else ws, compositionNeed=[[v['key'], v['lemma']] for v in p['proof']], refinementNeed=[], targetActionName=[], bridgeNeed=bridges, bridgeObservation=bridge, inventoryNeed=inventory, inventoryObservation=observedInventory, seamNeed=seams, seamObservation=seams[1:] if case == 'missing-seam' else seams))
                result = session.run(queries=['blocked', 'candidate', 'linked', 'compositionLinked', 'observed', 'bridgeLinked', 'seamLinked', 'inventoryLinked', 'migrationLinked'])
                assert result['complete']
                results[case] = result['relations']
            assert {v[1] for v in results['current']['blocked']} == {'MH-source', 'MH-platform'}
            assert [len(results['current'][k]) for k in ['linked', 'compositionLinked', 'observed', 'bridgeLinked']] == [30, 10, 53, 1]
            assert len(results['current']['seamLinked']) == 4
            assert len(results['current']['inventoryLinked']) == 6
            assert len(results['current']['migrationLinked']) == 6
            assert [c for c in cases if results[c]['candidate']] == ['synthetic-all']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-formal-pass', sourceSnapshots=len(snapshots), sourceAnchors=len(witnesses), qntActions=len(actions), qntHistories=17, negativeHistories=7, samples=500, sampleSeed=131, leanTheorems=len(lemmas), allStepInduction=True, declaredUnionAndPriorRawDenial=True, projectionControls=len(controls), negativeLeanControls=1, ascentScenarios=len(cases), actualCandidate=False, migrationLinks=6, emissionCorrespondence=False, completeNativeManifest=False, nativeRootHandoff=False, nestedContinuationOperationIdentity=False, sourceAliasClosure=False, allOriginProductRefinement=False, nativeC11Refinement=False, totalFallbackProved=False, nativeTestsRun=False, performanceTestsRun=False, liveSourceDrift=[f for f, v in snapshots.items() if _science.sha(_science.ROOT / f) != v['sha256']])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        own = [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.RULES, _science.EMITTER, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), qnt] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['ModuleHandleAst', 'ModuleHandle', 'ModuleHandleComposition']]
        own += [_science.BASE + 'index.org', 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py']
        own += imported + [v['path'] for v in snapshots.values()]
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), parentInputSha256=parentDigest, sourceBindings={f: _science.sha(_science.ROOT / f) for f in own}, sourceSnapshots=snapshots, sysmlInputs=scope, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                shutil.copyfile(f, _study_workspace('OUT') / f.name)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
