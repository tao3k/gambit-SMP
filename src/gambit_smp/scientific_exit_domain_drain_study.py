"""Research artifacts only: native SysML -> ASCENT / typed QNT IR -> Lean."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy
import hashlib
import json
import re
import shutil
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.shutil = shutil
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.BASE = _science.ROOT / 'dev/refactoring/modern-c'
        _science.LEAN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.GROUPS = [['source', 19, ['key', 'path', 'needle', 'limit']], ['obligation', 8, ['key', 'status', 'condition']], ['route', 36, ['actionName', 'lemma', 'source', 'obligation']], ['gain', 5, ['key', 'saved', 'added', 'condition', 'status']], ['issuer', 5, ['key', 'source', 'signature', 'gap']], ['consumer', 5, ['key', 'source', 'access', 'lifetime', 'limit']], ['writer', 6, ['key', 'source', 'access', 'closure', 'limit']], ['refinement', 8, ['key', 'lemma', 'source', 'premise']], ['edge', 12, ['fromNode', 'toNode', 'contract']]]
        _science.helper = _science.context.library('size_family_hold_balance_study')
        _science.process_profile = _science.helper.process_profile

    def sha(_science, path):
        return hashlib.sha256(Path(path).read_bytes()).hexdigest()

    def rel(_science, path):
        return str(Path(path).relative_to(_science.ROOT))

    def save(_science, path, value):
        _study_write_text(Path(path), json.dumps(value, indent=2) + '\n')

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        model = _science.BASE / 'models/sysml/exit-domain-drain.sysml'
        qnt = _science.BASE / 'models/quint/exit_domain_drain.qnt'
        ast = _science.BASE / 'models/lean/ExitDomainDrainAst.lean'
        proof = _science.BASE / 'models/lean/ExitDomainDrain.lean'
        projector = _science.ROOT / 'src/gambit_smp/scientific_exit_domain_drain_projection.py'
        dsl = _science.ROOT / 'dev/modeling/ascent/exit-domain-drain.rules.scm'
        parent = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/runtime-tls-ready/input.json'
        stepProofs = [_science.BASE / 'models/lean' / (n + '.lean') for n in ['ExitDomainDrainRegistration', 'ExitDomainDrainDispatch', 'ExitDomainDrainRetirement']]
        bound = [*stepProofs, model, qnt, ast, proof, projector, dsl, Path(str(_science.context.root / 'src/gambit_smp/scientific_exit_domain_drain_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']
        bindings = {_science.rel(f): _science.sha(f) for f in bound}
        keys = [(g, i, f, 'GambitExitDomainDrain::' + g + str(i) + '.' + f) for g, n, fs in _science.GROUPS for i in range(n) for f in fs]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'exit-domain-drain', field_expressions, ordered=True, models=[str(model)])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        projection = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            projection.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rows.values()) for g, rows in projection.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        sources = []
        for row in p['source']:
            f = _science.ROOT / row['path']
            text = f.read_text()
            assert row['needle'] in text, row
            digest = _science.sha(f)
            bindings[row['path']] = digest
            _study_write_text(_study_workspace('CACHE') / ('source-' + digest + '.txt'), text)
            sources.append(dict(**row, sha256=digest, lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', sources)
        ledger = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/tcl-source-borrow/pinned-tcl-sources.json'
        pinned = json.loads(ledger.read_text())
        bindings[_science.rel(ledger)] = _science.sha(ledger)
        assert pinned['commit'] == 'cbf86d62348d6b052e1961b4df995960fb21545f'
        verified = []
        for row in pinned['records']:
            f = _science.ROOT / row['capturePath']
            data = f.read_bytes()
            assert _science.sha(f) == row['sha256']
            blob = hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\x00' + data).hexdigest()
            assert blob == row['gitBlobSha1']
            bindings[_science.rel(f)] = _science.sha(f)
            verified.append(dict(path=_science.rel(f), sha256=_science.sha(f), gitBlobSha1=blob))
        _science.save(_study_workspace('CACHE') / 'pinned-tcl-verification.json', dict(commit=pinned['commit'], records=verified, loadedBinaryQualified=False))
        paper = _science.ROOT / 'evidence/research/source-references/feeley-sfp/8bb2fae8ae4b54d3a86206596f90e9cf73da39846af0f39244a476074cf81ed4.txt'
        assert _science.sha(paper) == paper.stem
        bindings[_science.rel(paper)] = _science.sha(paper)
        previous = json.loads(parent.read_text())
        parent_ast = _science.BASE / 'models/lean/RuntimeTlsReadyAst.lean'
        assert _science.sha(parent_ast) == previous['sourceBindings'][_science.rel(parent_ast)]
        assert _science.sha(_science.LEAN) == previous['leanBinarySha256']
        bindings[_science.rel(parent_ast)] = _science.sha(parent_ast)
        parent_art = json.loads((parent.parent / 'artifacts.json').read_text())
        reused = []
        name = 'RuntimeTlsReadyAst'
        source = _science.BASE / 'models/lean' / (name + '.lean')
        obj = parent.parent / (name + '.olean')
        assert _science.sha(source) == previous['sourceBindings'][_science.rel(source)] and _science.sha(obj) == parent_art[_science.rel(obj)]
        bindings[_science.rel(source)] = _science.sha(source)
        bindings[_science.rel(obj)] = _science.sha(obj)
        shutil.copyfile(obj, _study_workspace('CACHE') / (name + '.olean'))
        reused.append(dict(module=name, sourceSha256=_science.sha(source), objectSha256=_science.sha(obj)))
        _science.save(_study_workspace('CACHE') / 'prior-lean-reuse.json', dict(leanBinarySha256=_science.sha(_science.LEAN), modules=reused, sourceChecked=True, objectManifestChecked=True))
        ledger = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/runtime-tls-ready/platform-sources.json'
        platform = json.loads(ledger.read_text())
        bindings[_science.rel(ledger)] = _science.sha(ledger)
        assert platform['commit'] == 'cbf86d62348d6b052e1961b4df995960fb21545f'
        for rec in platform['records']:
            f = _science.ROOT / rec['path']
            data = f.read_bytes()
            e = rec['treeEntry']
            assert _science.sha(f) == rec['sha256'] and len(data) == e['size']
            assert hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\x00' + data).hexdigest() == e['sha']
            bindings[_science.rel(f)] = _science.sha(f)
        event = (_science.ROOT / 'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclEvent.c').read_text()
        f = event[event.index('\nFinalizeThread('):event.index('\nTclInExit(')]
        order = ['tsdPtr->firstExitPtr = exitPtr->nextPtr;', 'exitPtr->proc(exitPtr->clientData);', 'ckfree(exitPtr);', 'TclFinalizeIOSubsystem();', 'TclFinalizeThreadData(quick);']
        positions = [f.index(x) for x in order]
        assert positions == sorted(positions)
        delete = event[event.index('\nTcl_DeleteThreadExitHandler('):event.index('\nTcl_SetExitProc(')]
        assert 'TCL_TSD_INIT(&dataKey)' in delete
        storage = (_science.ROOT / 'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclThreadStorage.c').read_text()
        lookup = storage[storage.index('\nTclThreadStorageKeyGet('):storage.index('\nTclThreadStorageKeySet(')]
        assert 'TSDTableCreate();' not in lookup and 'TclpThreadGetGlobalTSD(tsdGlobal.key)' in lookup
        _science.save(_study_workspace('CACHE') / 'source-order.json', dict(threadPopCallFreeTailOrder=order, absentDeleteUsesCreatingAccessor=True, pureLookupDoesNotCreateTable=True, fullCallerClosure=False, nativeExecution=False))
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        pr = _science.context.library('exit_domain_drain_projection')
        generated, receipt = pr.generate(ir)
        assert ast.read_text() == generated
        controls = {}
        for case in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
            if case == 'binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if case == 'field':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if case == 'roster':
                ds['step']['expr']['args'].pop(0)
            if case == 'expression':
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                pr.generate(bad)
            except (AssertionError, KeyError):
                controls[case] = 'rejected'
            else:
                raise AssertionError(case)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, controls=controls, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json')))
        for name in ['ExitDomainDrainAst', 'ExitDomainDrainRegistration', 'ExitDomainDrainDispatch', 'ExitDomainDrainRetirement', 'ExitDomainDrain']:
            source = _science.BASE / 'models/lean' / (name + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', source.read_text())
            _science.context.command('lean-' + name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(source)], policy=_science.process_profile)
        actions = pr.SPEC['actions']
        lemmas = ['ExitDomainDrain.' + n for n in re.findall('^theorem (\\w+)', '\n'.join((f.read_text() for f in [*stepProofs, proof])), re.M)]
        assert len(p['route']) == len(actions)
        assert {r['actionName'] for r in p['route']} == set(actions)
        assert all((r['lemma'] in lemmas for r in p['route']))
        _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        negatives = {'inflight-not-empty': (['seedRegistrationA', 'beginDrain', 'popA'], 'beginSubsystemTailGuard witness'), 'reentry-not-drain': (['seedRegistrationA', 'beginDrain', 'popA', 'reentrantFinalizeJoin'], 'detachTableSlotGuard witness'), 'return-not-free': (['seedRegistrationA', 'beginDrain', 'popA', 'returnA'], 'beginSubsystemTailGuard witness'), 'free-unknown': (['seedRegistrationA', 'beginDrain', 'popA', 'returnA', 'freeNodeAUnknown'], 'beginSubsystemTailGuard witness'), 'callback-unknown': (['seedRegistrationA', 'beginDrain', 'popA', 'callbackUnknownA'], 'beginSubsystemTailGuard witness'), 'unpublished-child': (['seedRegistrationA', 'beginDrain', 'popA', 'reserveChildB', 'publicationAbsentUnknown', 'returnA', 'freeNodeAKnown'], 'beginSubsystemTailGuard witness'), 'tail-not-done': (['beginDrain', 'beginSubsystemTail'], 'closeProducersGuard witness'), 'lookup-in-flight': (['beginDrain', 'beginSubsystemTail', 'finishSubsystemTail', 'acquireLookup', 'closeProducers', 'attestNoTsdDependencies'], 'detachTableSlotGuard witness')}
        for case, (seq, goal) in negatives.items():
            expr = 'initial'
            defs = ['initial']
            guard_checks = []
            for a in seq:
                guard_checks.append('example : ' + a + 'Guard (' + expr + ') := by simp [' + ','.join([a + 'Guard'] + defs) + ']')
                expr = a + 'Next (' + expr + ')'
                defs.append(a + 'Next')
            simp = ','.join(['Safe', 'witness'] + defs + [a + 'Guard' for a in actions])
            text = 'import ExitDomainDrain\nopen ExitDomainDrainAst\ndef witness : State := ' + expr + '\n' + '\n'.join(guard_checks) + '\nexample : Safe witness := by simp [' + simp + ']\nexample : ¬ (' + goal + ') := by simp [' + simp + ']\n'
            f = _study_workspace('CACHE') / (case + '-original.lean')
            _study_write_text(f, text)
            _science.context.command(case + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], policy=_science.process_profile)
            f = _study_workspace('CACHE') / (case + '-negative.lean')
            _study_write_text(f, text + 'example : ' + goal + ' := by simp [' + simp + ']\n')
            result = _science.context.command(case + '-negative', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], expected=1, policy=_science.process_profile)
            assert result.count('error:') == 1
        forged = {'freed-with-lookup': '{initial with phase:=4,admission:=0,keyGate:=0,lookupPin:=1,tailDone:=1,deps:=1}', 'key-without-roster': '{initial with phase:=6,admission:=0,keyGate:=0,tailDone:=1,deps:=1,key:=0}'}
        for case, state in forged.items():
            txt = 'import ExitDomainDrain\nopen ExitDomainDrainAst\ndef badState : State := ' + state + '\nexample : ¬ Safe badState := by simp [Safe,badState,initial]\n'
            f = _study_workspace('CACHE') / (case + '-original.lean')
            _study_write_text(f, txt)
            _science.context.command(case + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], policy=_science.process_profile)
            f = _study_workspace('CACHE') / (case + '-negative.lean')
            _study_write_text(f, txt + 'example : Safe badState := by simp [Safe,badState,initial]\n')
            result = _science.context.command(case + '-negative', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], expected=1, policy=_science.process_profile)
            assert result.count('error:') == 1

        def rows(group):
            return [list(row.values()) for row in p[group]]
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in sources]
        results = {}
        engine = Engine()
        try:
            session = engine.open_sources(dsl.read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'stale-source', 'missing-lemma', 'wrong-issuer', 'wrong-route', 'pair-is-identity', 'callback-is-resource', 'missing-edge-lemma', 'wrong-edge-source', 'cache-is-roster', 'volatile-is-acquire']:
                seen = copy.deepcopy(src)
                ls = [[l] for l in lemmas]
                issuers = rows('issuer')
                routes = rows('route')
                consumers = rows('consumer')
                qualified = rows('obligation')
                graphs = rows('refinement')
                writers = rows('writer')
                if case == 'current':
                    qualified = [r for r in qualified if r[1] != 'unresolved']
                if case == 'stale-source':
                    seen[0][2] = 'stale'
                if case == 'missing-lemma':
                    ls.remove(['ExitDomainDrain.seedRegistrationAPreserves'])
                if case == 'wrong-issuer':
                    issuers[0][2] = 'registration return is a global retirement receipt'
                if case == 'wrong-route':
                    routes[0][1] = 'ExitDomainDrain.returnAPreserves'
                if case == 'pair-is-identity':
                    issuers[0][2] = 'deduplicate all registrations by proc and clientData'
                if case == 'callback-is-resource':
                    issuers[2][2] = 'void callback return proves native resource closure'
                if case == 'missing-edge-lemma':
                    ls.remove(['ExitDomainDrain.drainedHasNoInFlight'])
                if case == 'wrong-edge-source':
                    graphs[0][2] = 'prior'
                if case == 'cache-is-roster':
                    consumers[3][2] = 'cache list includes every noncreating key lookup'
                if case == 'volatile-is-acquire':
                    issuers[4][2] = 'volatile flag proves all owner acquires'
                session.replace(dict(sourceNeed=src, sourceSeen=seen, obligation=rows('obligation'), qualified=qualified, actionName=[[a] for a in actions], lemmaName=ls, routeNeed=rows('route'), routeSeen=routes, issuerNeed=rows('issuer'), issuerSeen=issuers, consumerNeed=rows('consumer'), consumerSeen=consumers, graphNeed=rows('refinement'), graphSeen=graphs, writerNeed=rows('writer'), writerSeen=writers))
                result = session.run(queries=['blocked', 'candidate', 'routeLinked', 'issuerLinked', 'consumerLinked', 'graphLinked', 'writerLinked'])
                assert result['complete']
                results[case] = result['relations']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticIsNotNativeEvidence=True))
        assert [k for k, r in results.items() if r['candidate']] == ['synthetic-all']
        lines = ['#+TITLE: Exit-domain drain — registration, callback, data and key matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitExitDomainDrain', ':END:', 'Safety-model closure does not certify native caller coverage, C23 execution or performance.']
        for group in ['gain', 'consumer', 'issuer', 'writer', 'refinement', 'obligation', 'route', 'source']:
            fs = list(p[group][0])
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(row[f]).replace('|', ' / ') for f in fs)) + ' |' for row in p[group]]
        matrix = _science.BASE / 'exit-domain-drain-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        d2 = _science.BASE / 'diagrams/exit-domain-drain.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 exit-domain producers, data drain and key retirement"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), fields=len(pr.SPEC['fields']), actions=len(actions), histories=17, samples=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, guardedActualParentJoin=True, fullProductSimulation=False, typedIrNegativeControls=len(controls), reachableAdmissionCounterexamples=len(negatives), ascentScenarios=len(results), externalReaderClosure=False, domainReaderClosure=False, faultRecoveryImplemented=False, normalLandingIsPremise=True, rawRouteClosureIsPremise=True, loadedTclQualified=False, c23Refinement=False, nativeAdmission=False, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False, nativePathsRetired=0, deterministicLateGuardControls=7, modelInvariants=45, contractRefinementLemmas=8, forgedStateNegativeControls=2, verifiedPriorLeanModules=len(reused), globalReaderClosure=False, unresolved=[r['key'] for r in p['obligation'] if r['status'] == 'unresolved'])
        _science.save(_study_workspace('OUT') / 'checks.json', dict(checks, validationComplete=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        org = org.replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/exit-domain-drain-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/exit-domain-drain-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for f in [_science.BASE / 'exit-domain-drain-design.org', matrix, _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', d2, d2.with_suffix('.svg')]:
            bindings[_science.rel(f)] = _science.sha(f)
        assert all((_science.sha(_science.ROOT / f) == h for f, h in bindings.items()))
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), parentInputSha256=_science.sha(parent), runtimeClaim=False))
        checks['validationComplete'] = True
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                target = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                target.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, target)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Local retained paper;
# No native program execution; immutable missing-source read is recorded separately.
# Bind the actual previous provider AST; do not substitute a toy provider model.
# Forged state controls are distinct from reachable guard counterexamples.
