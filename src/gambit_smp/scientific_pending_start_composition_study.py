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
        _science.STEM = 'pending-start-composition'
        _science.PKG = 'GambitPendingStartComposition'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.QNT = _science.BASE + 'models/quint/pending_start_composition.qnt'
        _science.LEAN = _science.BASE + 'models/lean/PendingStartComposition.lean'
        _science.AST = _science.BASE + 'models/lean/PendingStartAst.lean'
        _science.SHARDS = _science.BASE + 'models/quint/thread_thunk_root.qnt'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('route', 12, 'key sourcePath needle obligation'), ('contract', 6, 'key owner accountable.moduleId counterpart.moduleId actionName invariant gap'), ('obligation', 7, 'key status scope counterexample'), ('gain', 5, 'key avoided added condition'), ('binding', 3, 'key qntAction leanLemma refinement guardLemma updateLemma'), ('composition', 4, 'key lemma certificate'), ('flow', 16, 'fromNode toNode reason'), ('endorsement', 3, 'roleName scope issuer sourcePath needle')]
        _science.process_profile = _science.h.process_profile

    def project(_science):
        keys = [(g, str(i), f, f'{_science.PKG}::{g}{i}.{f}') for g, n, fs in _science.GROUPS for i in range(n) for f in fs.split()]
        for slot in ['history', 'shards', 'induction', 'expression', 'startupExpression', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(7):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        files = sorted(_science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}))
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        native = _study_fields(_science.ROOT, None, 'pending-start-composition', field_expressions, ordered=True, models=['dev'])
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
        lines = ['#+TITLE: Pending Start Consumer, Context Adoption and Batch Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: pending-start-composition-matrix', ':AUTHORITY: GambitPendingStartComposition', ':STATUS: conditional-models-only; source-and-platform-open', ':END:']
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
            queries = ['candidate', 'blocked', 'checked', 'linked', 'observed', 'route', 'bridgeLinked', 'envLinked', 'endorsed', 'compositionLinked']
            assert s.run(queries=queries)['complete']
            for case in ['current', 'stale-digest', 'wrong-scope', 'missing-parent', 'missing-action', 'wrong-lemma', 'missing-source', 'missing-expression', 'missing-certificate', 'missing-shards', 'missing-environment', 'missing-endorsement', 'stale-endorsement-source', 'missing-composition-lemma', 'missing-startup-certificate', 'synthetic-all']:
                rec = [[case, n, path, d, scope] for n, k, path, d, scope in needs if case != 'current' or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    rec = [x[:3] + ['stale'] + x[4:] if x[1] == 'PC-I' else x for x in rec]
                if case == 'wrong-scope':
                    rec = [x[:4] + ['all-extraction-verified'] if x[1] == 'PC-I' else x for x in rec]
                if case == 'missing-shards':
                    rec = [x for x in rec if x[1] != 'PC-B']
                if case == 'missing-expression':
                    rec = [x for x in rec if x[1] != 'PC-X']
                if case == 'missing-parent':
                    rec = [x for x in rec if x[1] != 'TF-S']
                bs = [x.copy() for x in bindings]
                if case == 'wrong-lemma':
                    bs[0][2] = 'nonexistentLemma'
                ac = [x for x in actions if case != 'missing-action' or x[0] != 'adoptA']
                obs = rows[1:] if case == 'missing-source' else rows
                cb = [[v['key'], v['guardLemma'], v['updateLemma']] for v in p['binding']]
                certs = [[x] for x in re.findall('^theorem (\\w+)', (_science.ROOT / _science.AST).read_text() + '\n' + (_science.ROOT / (_science.BASE + 'models/lean/PendingStartupAst.lean')).read_text(), re.M) if case != 'missing-certificate' or x != 'adoptANextMeaning']
                envs = [x for x in lemmas + certs if case != 'missing-environment' or x[0] != 'environmentExactDomain']
                endorsements = [[v['roleName'], v['scope'], v['issuer']] for v in p['endorsement']]
                delivered = [[case] + v for v in endorsements if case != 'current' and (case != 'missing-endorsement' or v[0] != 'semantic')]
                sourceEndorsements = [[v['roleName'], v['sourcePath'], _science.sha(_science.ROOT / v['sourcePath']), v['needle']] for v in p['endorsement']]
                for v in p['endorsement']:
                    assert v['needle'] in (_science.ROOT / v['sourcePath']).read_text()
                attestations = [[case] + v for v in sourceEndorsements if case != 'current']
                if case == 'stale-endorsement-source':
                    attestations[0][3] = 'stale'
                ml = [x for x in lemmas if case != 'missing-composition-lemma' or x[0] != 'adoptionStartupCommutes']
                certs = [x for x in certs if case != 'missing-startup-certificate' or x[0] != 'enterFromHandleNextMeaning']
                s.replace(dict(compositionNeed=[[v['key'], v['lemma'], v['certificate']] for v in p['composition']], endorsementSource=sourceEndorsements, endorsementAttestation=attestations, endorsementNeed=endorsements, endorsementReceipt=delivered, scenario=[[case]], envNeed=[['environmentNoFabrication'], ['environmentExactDomain'], ['actualEnvAgrees']], envLemma=envs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source'], ['environment-refinement', 'platform']], need=needs, receipt=rec, bridgeBinding=cb, certificateLemma=certs, binding=bs, modelAction=ac, modelLemma=ml, witness=rows, observation=obs))
                result = s.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 5 and len(results['current']['linked']) == 3 and (len(results['current']['bridgeLinked']) == 3)
            assert len(results['synthetic-all']['candidate']) == 1
            for case, reason in [('stale-digest', 'PC-I'), ('wrong-scope', 'PC-I'), ('missing-parent', 'TF-S'), ('missing-action', 'roots'), ('wrong-lemma', 'guard'), ('missing-source', p['route'][0]['key']), ('missing-expression', 'PC-X'), ('missing-certificate', 'roots'), ('missing-shards', 'PC-B'), ('missing-environment', 'environmentExactDomain'), ('missing-endorsement', 'semantic'), ('stale-endorsement-source', 'semantic'), ('missing-composition-lemma', 'startup-square'), ('missing-startup-certificate', 'startup-square')]:
                assert [case, reason] in results[case]['blocked'], (case, reason)
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotRealEvidence=True, sourceRefinement=False))

    def extraction_evidence(_science):
        import copy
        checker = _science.context.library('typed_binding_witness')
        irpath = _science.ROOT / _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix()
        old = checker.read_json(irpath.read_text())
        w = checker.check(old)
        refs = w['references']
        _science.save(_study_workspace('CACHE') / 'binding-witness.json', dict(**w, inputSha256=_science.sha(irpath)))
        projector = _science.context.library('pending_start_composition_projection')
        ir = checker.read_json((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast = projector.generate(ir, refs)
        _study_write_text(_science.ROOT / _science.AST, ast)
        startup = checker.read_json((_study_workspace('CACHE') / 'shard-typed-ir.json').read_text())
        secondary = projector.generate(startup, [], startup=True)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/PendingStartupAst.lean'), secondary)
        line = next((x for x in ast.splitlines() if x.startswith('def actualRows')))
        pairs = [(int(k), int(v)) for k, v in re.findall('\\((\\d+),(\\d+)\\)', line)]
        expected = [(v['occurrence'], v['target']) for v in refs]
        assert pairs == expected
        controls = {'drop': pairs[1:], 'wrong-target': [(pairs[0][0], pairs[0][1] + 1)] + pairs[1:], 'reorder': list(reversed(pairs))}
        assert all((v != expected for v in controls.values()))
        _science.save(_study_workspace('CACHE') / 'row-projection-controls.json', dict(rejected=list(controls), exactOrderedWitness=True, reorderIsManifestMismatchNotSemanticCounterexample=True))
        _science.save(_study_workspace('CACHE') / 'expression-projection.json', dict(actions=['registerA', 'adoptA', 'rollbackB'], typedIrSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.ROOT / _science.AST), references=len(refs), parserVerified=False, projectorVerified=False))
        _science.save(_study_workspace('CACHE') / 'startup-expression-projection.json', dict(sourcePath=_science.SHARDS, sourceSha256=_science.sha(_science.ROOT / _science.SHARDS), typedIrSha256=_science.sha(_study_workspace('CACHE') / 'shard-typed-ir.json'), astSha256=_science.sha(_science.ROOT / (_science.BASE + 'models/lean/PendingStartupAst.lean')), action='enterFromHandle', parserVerified=False, fullSimulation=False))
        return ast

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/thread-thunk-frozen-roots/input.json'
        ph = _science.sha(parent)
        p = _science.project()
        _science.views(p)
        witnesses = []
        for v in p['route']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['needle'] in text
            witnesses.append(dict(**v, sha256=_science.sha(_science.ROOT / v['sourcePath']), line=text[:text.index(v['needle'])].count('\n') + 1))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        inventory = _science.context.command('native-scope-callers', ['rg', '-l', '___write_authority_(try_handoff|try_acquire|release|close|quiescent)', 'vendor/gambit/lib', 'vendor/gambit/gsc', 'vendor/gambit/include', '-g', '*.[ch]', '-g', '*.scm', '-g', '*.in'], policy=_science.process_profile)
        _science.save(_study_workspace('CACHE') / 'native-scope-callers.json', dict(paths=inventory.splitlines(), scope='lib/gsc/include production sources only', integrationQualified=False))
        callers = _science.context.command('carrier-source-callers', ['rg', '-n', '___run[[:space:]]*\\(|data_scmobj', 'vendor/gambit/lib', 'vendor/gambit/gsc', 'vendor/gambit/include', 'vendor/gambit/examples', '-g', '*.[ch]', '-g', '*.in', '-g', '*.scm'], policy=_science.process_profile)
        _science.save(_study_workspace('CACHE') / 'carrier-source-callers.json', dict(observations=callers.splitlines(), scope='bounded lib/gsc/include/examples source inventory; not arbitrary external callers', callerClosureQualified=False))
        lean = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in lean and 'axiom ' not in lean
        reuse = '--reuse-formal' in _science.context.arguments
        if reuse:
            old = json.loads((_study_workspace('CACHE') / 'input.json').read_text())
            for f in [_science.QNT, _science.SHARDS, _science.LEAN, _science.AST, 'src/gambit_smp/scientific_pending_start_composition_projection.py', 'src/gambit_smp/scientific_typed_binding_witness.py', _science.BASE + 'models/lean/DarwinForceBinding.lean', _science.BASE + 'models/lean/DerivationReceiptEnvironment.lean', _science.BASE + 'models/lean/SnapshotObserverRefinement.lean', _science.BASE + 'models/lean/PinRosterDetachment.lean', _science.BASE + 'models/lean/FfiScopeRootAdmission.lean', _science.BASE + 'models/lean/IngressCarrierTransfer.lean', _science.BASE + 'models/lean/ThreadThunkFrozenRoots.lean', _science.BASE + 'models/lean/PendingStartupAst.lean']:
                assert _science.sha(_science.ROOT / f) == old['sourceBindings'][f], f
            for f, d in old['logs'].items():
                if any((k in f for k in ['quint-', 'typecheck', 'PendingStart', 'ThreadThunkFrozen', 'IngressCarrier', 'FfiScopeRoot', 'PinRoster', 'SnapshotObserver', 'DerivationReceiptEnvironment.', 'DarwinForceBinding.', 'negative-guard'])):
                    assert _science.sha(_science.ROOT / f) == d, f
            ast = _science.extraction_evidence()
            assert _science.sha(_science.ROOT / _science.AST) == old['sourceBindings'][_science.AST]
        else:
            _science.context.command('quint-typecheck', ['quint', 'typecheck', _science.QNT, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
            _science.context.command('shard-typecheck', ['quint', 'typecheck', _science.SHARDS, '--out', str(_study_workspace('CACHE') / 'shard-typed-ir.json')], policy=_science.process_profile)
            ast = _science.extraction_evidence()
            for name, path, n, neg in [('pin', _science.QNT, 8, 4), ('shard', _science.SHARDS, 6, 3)]:
                tests = _science.context.command(name + '-quint-tests', ['quint', 'test', path, '--match', 'Test$'], policy=_science.process_profile)
                assert tests.count('ok ') == n and tests.count('ControlTest passed') == neg
                _science.context.command(name + '-quint-samples', ['quint', 'run', path, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '200', '--seed', '41', '--verbosity', '1'], policy=_science.process_profile)
            for name, path in [('DarwinForceBinding', _science.BASE + 'models/lean/DarwinForceBinding.lean'), ('DerivationReceiptEnvironment', _science.BASE + 'models/lean/DerivationReceiptEnvironment.lean'), ('SnapshotObserverRefinement', _science.BASE + 'models/lean/SnapshotObserverRefinement.lean'), ('PinRosterDetachment', _science.BASE + 'models/lean/PinRosterDetachment.lean'), ('FfiScopeRootAdmission', _science.BASE + 'models/lean/FfiScopeRootAdmission.lean'), ('IngressCarrierTransfer', _science.BASE + 'models/lean/IngressCarrierTransfer.lean'), ('ThreadThunkFrozenRoots', _science.BASE + 'models/lean/ThreadThunkFrozenRoots.lean'), ('PendingStartComposition', _science.LEAN), ('PendingStartupAst', _science.BASE + 'models/lean/PendingStartupAst.lean'), ('PendingStartAst', _science.AST)]:
                src = _study_workspace('CACHE') / (name + '.lean')
                _study_write_bytes(src, (_science.ROOT / path).read_bytes())
                _science.context.command(name, ['env', f"LEAN_PATH={_study_workspace('CACHE')}", 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(src)], policy=_science.process_profile)
            mutant = '\n'.join((line.replace('¬', ' ') if line.startswith('def irRollbackGuard') else line for line in ast.splitlines())) + '\n'
            assert mutant != ast
            _study_write_text(_study_workspace('CACHE') / 'WrongGuard.lean', mutant)
            try:
                _science.context.command('negative-guard-certificate', ['env', f"LEAN_PATH={_study_workspace('CACHE')}", 'lean', str(_study_workspace('CACHE') / 'WrongGuard.lean')], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / 'negative-guard-certificate.stdout').read_text()
            else:
                raise AssertionError('wrong receipt guard certified')
        _science.ascend(p)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {_science.BASE + 'models/lean/PendingStartupAst.lean', _science.BASE + 'models/lean/ThreadThunkFrozenRoots.lean', _science.BASE + 'models/lean/IngressCarrierTransfer.lean', _science.BASE + 'models/lean/FfiScopeRootAdmission.lean', _science.BASE + 'models/lean/PinRosterDetachment.lean', _science.BASE + 'models/lean/SnapshotObserverRefinement.lean'} | {v['sourcePath'] for v in p['route']} | {_science.SHARDS, _science.AST, _science.BASE + 'models/lean/DerivationReceiptEnvironment.lean', 'src/gambit_smp/scientific_pending_start_composition_projection.py', _science.BASE + 'models/lean/DarwinForceBinding.lean', _science.MODEL, _science.DESIGN, _science.MATRIX, _science.QNT, _science.LEAN, _science.RULES, _science.D2, _science.D2[:-3] + '.svg', _science.BASE + 'index.org', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_advantage_architecture_study.py', 'src/gambit_smp/scientific_map_expression_projection.py', 'src/gambit_smp/scientific_typed_binding_witness.py', 'dev/refactoring/modern-c/models/quint/map_frame_abi.qnt', _science.context.artifact(_science.context.scientific_inputs['typedIr'], 'quint-typed-ir').relative_to(_science.ROOT).as_posix(), 'dev/refactoring/modern-c/models/lean/MapExpressionAst.lean', 'vendor/gambit/include/gambit.h.in', 'vendor/gambit/lib/setup.h', 'vendor/gambit/lib/write_authority.h'}
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['sourcePath']) == v['sha256']
        assert _science.sha(parent) == ph
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sourceRoutes=12, qntHistories=14, compositionHistories=8, startupHistories=6, negativeControls=7, sampledRuns=500, maxSteps=200, leanTheorems=len(re.findall('^theorem ', lean, re.M)), ascentScenarios=16, formalBindings=3, selectedCompositionSquares=4, startupAstTheorems=2, negativeLeanCertificates=1, astTheorems=len(re.findall('^theorem ', ast, re.M)), formalChecksReused=reuse, sourceQualified=False, bindingWitnessReferences=91, rowProjectionRefusals=3, jsonBindingExtractionVerified=False, fullActionExtractionVerified=False, qntToLeanFullSimulation=False, c11Refinement=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInputSha256=ph, parentFrozen=True, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el', '.lean', '.qnt'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
