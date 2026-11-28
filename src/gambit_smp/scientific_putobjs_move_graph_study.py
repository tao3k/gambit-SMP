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
        _science.GROUPS = [('source', 21, ['key', 'path', 'needle', 'limit']), ('obligation', 7, ['key', 'status', 'condition']), ('route', 28, ['actionName', 'lemma', 'source', 'obligation']), ('gain', 5, ['key', 'saved', 'added', 'condition', 'status']), ('issuer', 4, ['key', 'source', 'signature', 'gap']), ('consumer', 5, ['key', 'source', 'access', 'lifetime', 'limit']), ('edge', 10, ['fromNode', 'toNode', 'contract']), ('refinement', 10, ['key', 'lemma', 'source', 'premise'])]
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
        model = _science.BASE / 'models/sysml/putobjs-move-graph.sysml'
        qnt = _science.BASE / 'models/quint/putobjs_move_graph.qnt'
        ast = _science.BASE / 'models/lean/PutObjsMoveGraphAst.lean'
        proof = _science.BASE / 'models/lean/PutObjsMoveGraph.lean'
        projector = _science.ROOT / 'src/gambit_smp/scientific_putobjs_move_graph_projection.py'
        dsl = _science.ROOT / 'dev/modeling/ascent/putobjs-move-graph.rules.scm'
        parent = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/putobjs-custody/input.json'
        stepProofs = [_science.BASE / 'models/lean' / (n + '.lean') for n in ['PutObjsMoveGraphStepsA', 'PutObjsMoveGraphStepsB', 'PutObjsMoveGraphStepsC', 'PutObjsMoveGraphStepsD']]
        bound = [*stepProofs, model, qnt, ast, proof, projector, dsl, Path(str(_science.context.root / 'src/gambit_smp/scientific_putobjs_move_graph_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']
        bindings = {_science.rel(f): _science.sha(f) for f in bound}
        keys = [(g, i, f, 'GambitPutObjsMoveGraph::' + g + str(i) + '.' + f) for g, n, fs in _science.GROUPS for i in range(n) for f in fs]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'putobjs-move-graph', field_expressions, ordered=True, models=[str(model)])
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
        meta = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/thread-cache-tail/thread-alloc-source.json'
        capture = json.loads(meta.read_text())
        assert capture['requestedCommit'] == 'cbf86d62348d6b052e1961b4df995960fb21545f'
        f = _science.ROOT / capture['capturePath']
        data = f.read_bytes()
        assert _science.sha(f) == capture['sha256'] and len(data) == capture['treeEntry']['size']
        assert hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\x00' + data).hexdigest() == capture['treeEntry']['sha']
        bindings[_science.rel(meta)] = _science.sha(meta)
        bindings[_science.rel(f)] = _science.sha(f)
        header = (_science.ROOT / 'evidence/research/source-references/tcl/cbf86d62348d6b052e1961b4df995960fb21545f/generic/tclInt.h').read_text()
        assert re.search('^#  define ALLOC_NOBJHIGH 1200$', header, re.M)
        assert re.search('^#define NOBJALLOC\\s+800$', data.decode(), re.M)
        cases = []
        for n in [0, 1, 1199, 1200]:
            route = 'direct' if 1 <= n < 1200 else 'helper'
            after = n + 1
            moved = 800 if route == 'helper' and after > 1200 else 0
            cases.append(dict(before=n, route=route, after=after - moved, sharedTransfer=moved, keepWalk=after - moved if moved else 0))
        _science.save(_study_workspace('CACHE') / 'source-threshold-arithmetic.json', dict(cases=cases, nativeExecution=False, linkedListShapeIsPremise=True))
        paper = _science.ROOT / 'evidence/research/source-references/feeley-sfp/8bb2fae8ae4b54d3a86206596f90e9cf73da39846af0f39244a476074cf81ed4.txt'
        assert _science.sha(paper) == paper.stem
        bindings[_science.rel(paper)] = _science.sha(paper)
        previous = json.loads(parent.read_text())
        parent_ast = _science.BASE / 'models/lean/PutObjsCustodyAst.lean'
        assert _science.sha(parent_ast) == previous['sourceBindings'][_science.rel(parent_ast)]
        assert _science.sha(_science.LEAN) == previous['leanBinarySha256']
        bindings[_science.rel(parent_ast)] = _science.sha(parent_ast)
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        pr = _science.context.library('putobjs_move_graph_projection')
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
        for name in ['PutObjsCustodyAst', 'PutObjsMoveGraphAst', 'PutObjsMoveGraphStepsA', 'PutObjsMoveGraphStepsB', 'PutObjsMoveGraphStepsC', 'PutObjsMoveGraphStepsD', 'PutObjsMoveGraph']:
            source = _science.BASE / 'models/lean' / (name + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', source.read_text())
            _science.context.command('lean-' + name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(source)], policy=_science.process_profile)
        actions = pr.SPEC['actions']
        lemmas = ['PutObjsMoveGraph.' + n for n in re.findall('^theorem (\\w+)', '\n'.join((f.read_text() for f in [*stepProofs, proof])), re.M)]
        assert len(p['route']) == len(actions)
        assert {r['actionName'] for r in p['route']} == set(actions)
        assert all((r['lemma'] in lemmas for r in p['route']))
        _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        negatives = {'initial-no-fix': ([], 'fixProducerLastGuard witness'), 'unlocked-no-borrow': (['knownProducerUnlock'], 'borrowOldTailGuard witness'), 'unknown-held-no-consumer': (['unknownStillHeld'], 'acquireConsumerGuard witness'), 'unknown-released-no-fix': (['unknownReleased'], 'fixProducerLastGuard witness'), 'unknown-no-close': (['unknownReleased'], 'closeSourceAdmissionGuard witness'), 'locked-no-detach': (['knownProducerUnlock', 'acquireConsumer', 'selectMove800', 'loadMoveHead', 'creditDestination', 'debitShared'], 'detachSharedHeadGuard witness'), 'no-pop-before-move': (['knownProducerUnlock', 'acquireConsumer'], 'loadPopHeadGuard witness'), 'no-premature-return': (['knownProducerUnlock'], 'returnTailGuard witness')}
        for case, (seq, goal) in negatives.items():
            expr = 'initial'
            defs = ['initial']
            guard_checks = []
            for a in seq:
                guard_checks.append('example : ' + a + 'Guard (' + expr + ') := by simp [' + ','.join([a + 'Guard'] + defs) + ']')
                expr = a + 'Next (' + expr + ')'
                defs.append(a + 'Next')
            simp = ','.join(['Safe', 'witness'] + defs + [a + 'Guard' for a in actions])
            text = 'import PutObjsMoveGraph\nopen PutObjsMoveGraphAst\ndef witness : State := ' + expr + '\n' + '\n'.join(guard_checks) + '\nexample : Safe witness := by simp [' + simp + ']\nexample : ¬ (' + goal + ') := by simp [' + simp + ']\n'
            f = _study_workspace('CACHE') / (case + '-original.lean')
            _study_write_text(f, text)
            _science.context.command(case + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], policy=_science.process_profile)
            f = _study_workspace('CACHE') / (case + '-negative.lean')
            _study_write_text(f, text + 'example : ' + goal + ' := by simp [' + simp + ']\n')
            result = _science.context.command(case + '-negative', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], expected=1, policy=_science.process_profile)
            assert result.count('error:') == 1
        for case in ['wrong-tail-edge', 'wrong-shared-head']:
            edge = '(fun n => if n=1201 then 0 else rawNext initial n)' if case == 'wrong-tail-edge' else 'rawNext initial'
            head = '402' if case == 'wrong-tail-edge' else '0'
            txt = 'import PutObjsMoveGraph\nopen PutObjsMoveGraphAst PutObjsMoveGraph\ndef badGraph : Graph := ⟨' + edge + ',' + head + ',0,1201⟩\n'
            txt += 'example : ¬ Encodes badGraph initial := by\n intro h\n simp only [Encodes] at h\n rcases h with ⟨ha,hb,hrest,hh,hd,hp⟩\n'
            txt += ' simp [badGraph,initial] at hb\n' if case == 'wrong-tail-edge' else ' simp [badGraph,initial] at hh\n'
            f = _study_workspace('CACHE') / (case + '-original.lean')
            _study_write_text(f, txt)
            _science.context.command(case + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], policy=_science.process_profile)
            f = _study_workspace('CACHE') / (case + '-negative.lean')
            _study_write_text(f, txt + 'example : Encodes badGraph initial := by simp [Encodes,badGraph,initial]\n')
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
            for case in ['current', 'synthetic-all', 'stale-source', 'missing-lemma', 'wrong-issuer', 'wrong-route', 'unlock-is-completion', 'address-is-identity', 'missing-edge-lemma', 'wrong-edge-source']:
                seen = copy.deepcopy(src)
                ls = [[l] for l in lemmas]
                issuers = rows('issuer')
                routes = rows('route')
                consumers = rows('consumer')
                qualified = rows('obligation')
                graphs = rows('refinement')
                if case == 'current':
                    qualified = [r for r in qualified if r[1] != 'unresolved']
                if case == 'stale-source':
                    seen[0][2] = 'stale'
                if case == 'missing-lemma':
                    ls.remove(['PutObjsMoveGraph.publishReceiptPreserves'])
                if case == 'wrong-issuer':
                    issuers[0][2] = 'claim success itself protects all earlier metadata loads'
                if case == 'wrong-route':
                    routes[0][1] = 'PutObjsMoveGraph.publishReceiptPreserves'
                if case == 'unlock-is-completion':
                    issuers[0][2] = 'shared unlock itself proves local lastPtr and receipt completed'
                if case == 'address-is-identity':
                    consumers[4][2] = 'same raw address authorizes prior incarnation receipt'
                if case == 'missing-edge-lemma':
                    ls.remove(['PutObjsMoveGraph.physicalWalk'])
                if case == 'wrong-edge-source':
                    graphs[0][2] = 'prior'
                session.replace(dict(sourceNeed=src, sourceSeen=seen, obligation=rows('obligation'), qualified=qualified, actionName=[[a] for a in actions], lemmaName=ls, routeNeed=rows('route'), routeSeen=routes, issuerNeed=rows('issuer'), issuerSeen=issuers, consumerNeed=rows('consumer'), consumerSeen=consumers, graphNeed=rows('refinement'), graphSeen=graphs))
                result = session.run(queries=['blocked', 'candidate', 'routeLinked', 'issuerLinked', 'consumerLinked', 'graphLinked'])
                assert result['complete']
                results[case] = result['relations']
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticIsNotNativeEvidence=True))
        assert [k for k, r in results.items() if r['candidate']] == ['synthetic-all']
        lines = ['#+TITLE: PutObjs / MoveObjs — pointer graph, source lease and retirement matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitPutObjsMoveGraph', ':END:', 'Safety-model closure does not certify native caller coverage, C23 execution or performance.']
        for group in ['gain', 'consumer', 'issuer', 'refinement', 'obligation', 'route', 'source']:
            fs = list(p[group][0])
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(row[f]).replace('|', ' / ') for f in fs)) + ' |' for row in p[group]]
        matrix = _science.BASE / 'putobjs-move-graph-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        d2 = _science.BASE / 'diagrams/putobjs-move-graph.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 PutObjs / MoveObjs graph and opaque tail"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), fields=len(pr.SPEC['fields']), actions=len(actions), histories=11, samples=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, guardedActualParentJoin=True, fullProductSimulation=False, typedIrNegativeControls=len(controls), reachableAdmissionCounterexamples=len(negatives), ascentScenarios=len(results), externalReaderClosure=False, domainReaderClosure=False, faultRecoveryImplemented=False, normalLandingIsPremise=True, rawRouteClosureIsPremise=True, loadedTclQualified=False, c23Refinement=False, nativeAdmission=False, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False, nativePathsRetired=0, deterministicLateGuardControls=5, moveLoopLinks=799, moveTailLinkReads=1, allocationReturns=800, selectedTotalNextLinkReads=2001, modelInvariants=73, graphRefinementLemmas=10, graphRepresentationNegativeControls=2, unresolved=[r['key'] for r in p['obligation'] if r['status'] == 'unresolved'])
        _science.save(_study_workspace('OUT') / 'checks.json', dict(checks, validationComplete=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        org = org.replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/putobjs-move-graph-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/putobjs-move-graph-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for f in [_science.BASE / 'putobjs-move-graph-design.org', matrix, _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', d2, d2.with_suffix('.svg')]:
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
# Representation negatives: wrong boundary edge and wrong graph header.
