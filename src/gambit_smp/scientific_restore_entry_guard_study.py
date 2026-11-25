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
        _science.STEM = 'restore-entry-guard'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.PKG = 'GambitRestoreEntryGuard'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.save = _science.h.save
        _science.sha = _science.h.sha
        _science.process_profile = _science.h.process_profile

    def formal(_science):
        e = _science.context.library('restore_entry_guard_projection')
        cfg = e.SPEC
        qnt = _science.BASE + 'models/quint/' + cfg['module'] + '.qnt'
        parentReceipt = json.loads((_science.ROOT / '.cache/research/legacy-evidence/evidence/research/ticket-capability-retirement/input.json').read_text())
        for name in ['TicketCapabilityAst', 'TicketIdentityAlgebra']:
            source = _science.BASE + 'models/lean/' + name + '.lean'
            assert _science.sha(_science.ROOT / source) == parentReceipt['sourceBindings'][source], source
            target = _study_workspace('CACHE') / (name + '.lean')
            _study_write_bytes(target, (_science.ROOT / source).read_bytes())
            if '--reuse-formal' not in _science.context.arguments:
                _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(target)], policy=_science.process_profile)
        formalPaths = [qnt, _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in ['RestoreEntryAst', 'RestoreEntry', 'RestoreGuardAlgebra', 'TicketCapabilityAst', 'TicketIdentityAlgebra']]
        if '--reuse-formal' in _science.context.arguments:
            checkpoint = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert {f: _science.sha(_science.ROOT / f) for f in formalPaths} == checkpoint['sources']
            assert all((_science.sha(_science.ROOT / f) == d for f, d in checkpoint['logs'].items()))
            lemmas = [[ns + '.' + n] for ns in ['RestoreEntry', 'RestoreGuardAlgebra'] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + ns + '.lean')).read_text(), re.M)]
            return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, rc = e.generate(ir)
        path = _science.BASE + 'models/lean/RestoreEntryAst.lean'
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
        for n in ['RestoreEntryAst', 'RestoreEntry', 'RestoreGuardAlgebra']:
            src = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', src.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, src.read_bytes())
            _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
        tests = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 13
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '311', '--verbosity', '1'], policy=_science.process_profile)
        neg = _study_workspace('CACHE') / 'negative-exit'
        neg.mkdir(exist_ok=True)
        bad = '\n'.join((line.replace('(¬(q.markerLive1=true))', 'True') if line.startswith('def observeExit1Guard') else line for line in ast.splitlines())) + '\n'
        assert bad != ast
        _study_write_text(neg / 'RestoreEntryAst.lean', bad)
        _science.context.command('negative-ast', ['lean', '-o', str(neg / 'RestoreEntryAst.olean'), str(neg / 'RestoreEntryAst.lean')], policy=_science.process_profile)
        try:
            _science.context.command('negative-proof', ['env', 'LEAN_PATH=' + str(neg) + ':' + str(_study_workspace('CACHE')), 'lean', _science.BASE + 'models/lean/RestoreEntry.lean'], policy=_science.process_profile)
        except RuntimeError:
            assert 'error:' in (_study_workspace('CACHE') / 'negative-proof.stdout').read_text()
        else:
            raise AssertionError('foreign completion with live marker accepted')
        lemmas = [[ns + '.' + n] for ns in ['RestoreEntry', 'RestoreGuardAlgebra'] for n in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + ns + '.lean')).read_text(), re.M)]
        for name, old, new in [('negative-witness-key', 'w.id=guard.id ∧ w.restored=true ∧ w.markerClosed=true', 'w.restored=true ∧ w.markerClosed=true'), ('negative-ambient', 'if key=w.id then accept (records key) w else records key', 'accept (records key) {w with id:=key}')]:
            algebra = (_science.ROOT / (_science.BASE + 'models/lean/RestoreGuardAlgebra.lean')).read_text()
            bad = algebra.replace(old, new)
            assert bad != algebra
            target = _study_workspace('CACHE') / (name + '.lean')
            _study_write_text(target, bad)
            try:
                _science.context.command(name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), 'lean', str(target)], policy=_science.process_profile)
            except RuntimeError:
                assert 'error:' in (_study_workspace('CACHE') / (name + '.stdout')).read_text()
            else:
                raise AssertionError('guard identity mutation proved ' + name)
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formalPaths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem in ['typecheck', 'RestoreEntryAst', 'RestoreEntry', 'RestoreGuardAlgebra', 'histories', 'samples', 'negative-ast', 'negative-proof', 'negative-witness-key', 'negative-ambient', 'TicketCapabilityAst', 'TicketIdentityAlgebra']}))
        return ([[cfg['module'] + '.' + n] for n in cfg['actions']], lemmas)

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/restore-entry-guard/config.json').read_text())
        snap = json.loads((_study_workspace('CACHE') / 'source-snapshots.json').read_text())
        for f, v in snap.items():
            assert _science.sha(_science.ROOT / f) == _science.sha(_science.ROOT / v['path']) == v['sha256'], f
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/ticket-capability-retirement/input.json'
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
        _study_write_text(matrix, matrix.read_text().replace('Copy Producer Envelope — FrameSpec and Source Budget Matrix', 'Restore Entry and Stable Completion Guard Matrix').replace('GambitCopyProducerEnvelope', _science.PKG).replace('source-and-C11-open', 'source-root-exception-C23-platform-open'))
        d2 = _science.ROOT / (_science.BASE + 'diagrams/' + _science.STEM + '.d2')
        _study_write_text(d2, d2.read_text().replace('legal-input and C11 OPEN', 'source / roots / exceptions / C23 OPEN'))
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / snap[v['path']]['path']).read_text()
            assert v['needle'] in text, v
            witnesses.append(dict(**v, sha256=snap[v['path']]['sha256'], lines=[text[:m.start()].count('\n') + 1 for m in re.finditer(re.escape(v['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        slices = []
        specs = [('vendor/gambit/lib/c_intf.c', '___SCMOBJ ___make_sfun_stack_marker_from_root', '___EXP_FUNC(___SCMOBJ,___make_sfun_stack_marker)', 'proc_or_false = *proc_root;'), ('vendor/gambit/include/gambit.h', '#define ___CONTINUATION_GRAFT_NO_WINDING', '#define ___JUMP_CONTINUATION_GRAFT_NO_WINDING2', '___SET_FP'), ('vendor/gambit/include/gambit.h', '#define ___THREAD_RESTORE', '#define ___JUMP_THREAD_RESTORE2', '___CURRENTTHREADSET'), ('vendor/gambit/lib/_thread.scm', '(define-prim (##continuation-unwind-wind src dst continue)', '(define-prim (##continuation-graft-aux', '((macro-dynwind-before dst))')]
        for path, begin, end, call in specs:
            text = (_science.ROOT / snap[path]['path']).read_text()
            for i, hit in enumerate(re.finditer(re.escape(begin), text)):
                stop = text.index(end, hit.end())
                body = text[hit.start():stop]
                assert call in body
                slices.append(dict(path=path, sha256=snap[path]['sha256'], occurrence=i, startLine=text[:hit.start()].count('\n') + 1, endLine=text[:stop].count('\n') + 1, call=call, scope='bounded lexical slice; source/ABI/authority correspondence open'))
        _science.save(_study_workspace('CACHE') / 'source-call-slices.json', slices)
        inventoryInputs = {f: v['sha256'] for f, v in snap.items()}
        matches = []
        for path, v in snap.items():
            for lineNo, line in enumerate((_science.ROOT / v['path']).read_text().splitlines(), 1):
                if any((t in line for t in ['thread-restore', 'continuation-return-no-winding', 'continuation-graft-no-winding', '___SFUN_', '___BEGIN_TRY', '___END_TRY', 'stack_marker'])):
                    matches.append(dict(path=path, line=lineNo, text=line.strip()))
        _science.save(_study_workspace('CACHE') / 'source-token-inventory.json', dict(inputs=inventoryInputs, matches=matches, scope='selected source snapshots only; aliases and caller closure unproved'))
        actions, lemmas = _science.formal()
        for v in p['proof']:
            assert [v['lemma']] in lemmas, v
        needs = [[v[k] for k in ['obligationId', 'kind', 'subjectPath']] + [_science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        owners = [[v['obligationId'], v['owner.componentId']] for v in p['need'].values()]
        sources = [[v[k] for k in ['key', 'path', 'sha256', 'needle']] for v in witnesses]
        issuers = [[v[k] for k in ['key', 'proposedIssuer', 'actualSource', 'status', 'responsibility']] for v in p['issuer']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        proofs = [[v['key'], v['lemma']] for v in p['proof']]
        results = {}
        cases = ['current', 'synthetic-all', 'stale-source', 'missing-action', 'missing-lemma', 'wrong-issuer', 'missing-formal', 'wrong-scope', 'wrong-owner', 'missing-intent-route', 'missing-projection']
        engine = _science.h.Engine()
        try:
            session = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                receipts = [[case, n, path, digest, sc] for n, k, path, digest, sc in needs if case != 'current' or n in ['RE-formal', 'RE-algebra']]
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'RE-formal']
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                obs = copy.deepcopy(sources)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                io = copy.deepcopy(issuers)
                if case == 'wrong-issuer':
                    io[4][2] = 'existing-global-last-alias-signer-without-evidence'
                ro = copy.deepcopy(routes)
                if case == 'wrong-owner':
                    ro[0][0] = 'roots'
                if case == 'missing-intent-route':
                    ro = [r for r in ro if r[1] != 'restore_entry_guard.schedulerResume0']
                session.replace(dict(scenario=[[case]], need=needs, needOwner=owners, receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=[v for v in lemmas if (case != 'missing-lemma' or v != ['RestoreEntry.stepPreserves']) and (case != 'missing-projection' or v != ['RestoreGuardAlgebra.otherGuardUntouched'])], sourceNeed=sources, sourceObservation=obs, issuerNeed=issuers, issuerObservation=io, routeNeed=routes, routeObservation=ro, proofNeed=proofs))
                r = session.run(queries=['blocked', 'candidate', 'linked', 'sourceLinked', 'issuerLinked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-scenario-diagnostics.json', results)
        assert [k for k in cases if results[k]['candidate']] == ['synthetic-all'], [k for k in cases if results[k]['candidate']]
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 5, gaps
        assert len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT))], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', str(d2.relative_to(_science.ROOT)), str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(status='conditional-intent-and-guard-safety-pass-native-retirement-denied', languageBaseline='C23', sourceSnapshots=len(snap), sourceAnchors=len(witnesses), issuerRoles=len(issuers), sourceCallSlices=len(slices), componentSourceActionRoutes=len(routes), qntActions=len(actions), qntHistories=13, qntSamples=500, seed=311, leanTheorems=len(lemmas), allStepInduction=True, typedIrControls=4, negativeProofControls=3, ascentScenarios=len(cases), concreteTicketIds=2, genericKeyedAlgebra=True, fullUnboundedProductRefinement=False, actualCandidate=False, firstNativeRetirement=False, secondNativeRetirement=False, realIssuerClosure=False, genericSchemeLastAliasSigner=False, compiledRootMapQualified=False, eventualCompletionProved=False, crashRecoveryProved=False, c23RefinementProved=False, blockers=gaps, nativeTestsRun=False, performanceTestsRun=False)
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
        own = [_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/restore_entry_guard.qnt', _science.BASE + 'models/lean/RestoreEntryAst.lean', _science.BASE + 'models/lean/RestoreEntry.lean', _science.BASE + 'index.org', _science.BASE + 'language-baseline-design.org', _science.BASE + 'ticket-capability-retirement-design.org', _science.BASE + 'models/lean/RestoreGuardAlgebra.lean', _science.BASE + 'models/lean/TicketIdentityAlgebra.lean', _science.BASE + 'models/lean/TicketCapabilityAst.lean', str(d2.relative_to(_science.ROOT)), str(d2.with_suffix('.svg').relative_to(_science.ROOT)), 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', 'src/gambit_smp/scientific_default_lease_admission_study.py', 'src/gambit_smp/scientific_copy_producer_envelope_study.py', 'src/gambit_smp/scientific_advantage_architecture_study.py', str((_study_workspace('CACHE') / 'config.json').relative_to(_science.ROOT)), str((_study_workspace('CACHE') / 'source-snapshots.json').relative_to(_science.ROOT))] + [v['path'] for v in snap.values()]
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
        shutil.copytree(_study_workspace('CACHE') / 'negative-exit', _study_workspace('OUT') / 'negative-exit', dirs_exist_ok=True)
        for f in _study_workspace('CACHE').glob('negative-*.lean'):
            shutil.copyfile(f, _study_workspace('OUT') / f.name)
        for d in _study_workspace('CACHE').glob('retained-*-failure'):
            shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Exact bounded slices; lexical call ordering is not full source simulation.
# Native Org parser and link audit, without Babel evaluation.
