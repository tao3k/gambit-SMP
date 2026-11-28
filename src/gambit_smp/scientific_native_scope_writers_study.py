"""NativeScope source-bound architecture and formal research; no native execution."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy, hashlib, json, re, shutil
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
        _science.helper = _science.context.library('size_family_hold_balance_study')
        _science.process_profile = _science.helper.process_profile

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2) + '\n')

    def rel(_science, p):
        return str(Path(p).relative_to(_science.ROOT))

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        startFiles = [_science.BASE / 'models/sysml/native-scope-writers.sysml', _science.BASE / 'models/quint/native_scope_writers.qnt', _science.BASE / 'models/lean/NativeScopeAst.lean', _science.BASE / 'models/lean/NativeScope.lean', Path(str(_science.context.root / 'src/gambit_smp/scientific_native_scope_writers_study.py')), _science.ROOT / 'dev/modeling/ascent/native-scope-writers.rules.scm']
        formalStart = {_science.rel(f): _science.sha(f) for f in startFiles}
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/future-frame-commit/native-scope/config.json').read_text())
        keys = [(g, i, f, 'GambitNativeScopeWriters::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs]
        model = _science.BASE / 'models/sysml/native-scope-writers.sysml'
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'native-scope-writers', field_expressions, ordered=True, models=[str(model)])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rs.values()) for g, rs in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        bindings = {}
        witness = []
        for row in p['source']:
            file = _science.ROOT / row['path']
            text = file.read_text()
            assert row['needle'] in text
            h = _science.sha(file)
            bindings[row['path']] = h
            snap = _study_workspace('CACHE') / ('source-' + h + '.txt')
            _study_write_text(snap, text)
            witness.append(dict(**row, sha256=h, lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witness)
        qnt = _science.BASE / 'models/quint/native_scope_writers.qnt'
        projector = _science.ROOT / 'src/gambit_smp/scientific_native_scope_writers_projection.py'
        pr = _science.context.library('native_scope_writers_projection')
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = pr.generate(ir)
        assert (_science.BASE / 'models/lean/NativeScopeAst.lean').read_text() == ast
        controls = {}
        for label in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {x['name']: x for x in bad['modules'][0]['declarations']}
            if label == 'binding':
                bad['table'][str(receipt['stateReferences'][0][0])]['id'] = -1
            if label == 'field':
                ds['State']['type']['fields']['fields'][0]['fieldType']['kind'] = 'bool'
            if label == 'roster':
                ds['step']['expr']['args'].pop(0)
            if label == 'expression':
                ds['safe']['expr']['opcode'] = 'not-qualified'
            try:
                pr.generate(bad)
            except (AssertionError, KeyError):
                controls[label] = 'rejected'
            else:
                raise AssertionError(label)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, controls=controls, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(_science.BASE / 'models/lean/NativeScopeAst.lean')))
        parentQnt = _science.BASE / 'models/quint/future_atomic_owner.qnt'
        parentProjector = _science.ROOT / 'src/gambit_smp/scientific_future_atomic_owner_projection.py'
        _science.context.command('parent-typecheck', ['quint', 'typecheck', str(parentQnt), '--out', str(_study_workspace('CACHE') / 'owner-typed-ir.json')], policy=_science.process_profile)
        parentAst, parentReceipt = _science.context.library('future_atomic_owner_projection').generate(json.loads((_study_workspace('CACHE') / 'owner-typed-ir.json').read_text()))
        assert parentAst == (_science.BASE / 'models/lean/AtomicOwnerAst.lean').read_text()
        _science.save(_study_workspace('CACHE') / 'owner-projection.json', dict(**parentReceipt, typedIrSha256=_science.sha(_study_workspace('CACHE') / 'owner-typed-ir.json')))
        bindings.update({_science.rel(f): _science.sha(f) for f in [parentQnt, parentProjector]})
        for name in ['AtomicOwnerAst', 'NativeScopeAst', 'NativeScope']:
            f = _science.BASE / 'models/lean' / (name + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
            _science.context.command('lean-' + name, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (name + '.olean')), str(f)], policy=_science.process_profile)
            bindings[_science.rel(f)] = _science.sha(f)
        text = _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
        assert text.count('ok ') == 5
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        prefixes = {'unknown-before-record': (['issue', 'beginWrite', 'loseResponse', 'closeAdmission'], 'recoverRecordedGuard witness'), 'retire-before-drain': (['issue', 'beginWrite', 'loseResponse', 'closeAdmission'], 'retireGuard witness'), 'target-before-acquire': (['issue', 'prepareMigration'], 'issueTargetGuard witness'), 'raw-writer-escape': (['issue', 'rawInterference'], 'CanUse witness'), 'reuse-outer-view': (['issue', 'beginWrite', 'publishRelease', 'recordOutcome', 'deliverOutcome', 'acquire0', 'enterNested', 'leaveNested'], '(witness.view=1)'), 'stale-delivery-is-new-completion': (['issue', 'beginWrite', 'recordOutcome', 'deliverOutcome', 'prepareMigration', 'targetAcquire', 'issueTarget', 'beginWrite', 'rejectStaleDelivery'], '(witness.pending=0)')}
        actions = pr.SPEC['actions']
        lemmas = ['NativeScope.' + n for n in re.findall('^\\s*theorem (\\w+)', (_science.BASE / 'models/lean/NativeScope.lean').read_text(), re.M)]
        for key, (seq, goal) in prefixes.items():
            expr = 'initial'
            defs = ['initial']
            gs = []
            for a in seq:
                gs.append('example : ' + a + 'Guard (' + expr + ') := by simp [' + ','.join([a + 'Guard'] + defs) + ']')
                expr = a + 'Next (' + expr + ')'
                defs.append(a + 'Next')
            expand = ','.join(['CanUse', 'Safe'] + [n + 'Guard' for n in actions] + defs)
            base = 'import NativeScope\nopen NativeScopeAst NativeScope\ndef witness : State := ' + expr + '\n' + '\n'.join(gs) + '\nexample : Safe witness := by simp [' + expand + ',witness]\nexample : ¬ (' + goal + ') := by simp [' + expand + ',witness]\n'
            original = _study_workspace('CACHE') / (key + '-original.lean')
            _study_write_text(original, base)
            _science.context.command(key + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(original)], policy=_science.process_profile)
            bad = _study_workspace('CACHE') / (key + '-negative.lean')
            _study_write_text(bad, base + 'example : ' + goal + ' := by simp [' + expand + ',witness]\n')
            out = _science.context.command(key + '-negative', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(bad)], expected=1, policy=_science.process_profile)
            assert out.count('error:') == 1

        def rows(g):
            return [list(r.values()) for r in p[g]]
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in witness]
        results = {}
        engine = Engine()
        try:
            session = engine.open_sources((_science.ROOT / 'dev/modeling/ascent/native-scope-writers.rules.scm').read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'missing-writer', 'wrong-storage-domain', 'forged-issuer', 'missing-proof', 'stale-source', 'numeric-only-rf', 'wrong-memory-order']:
                source = copy.deepcopy(src)
                writers = rows('writer')
                issuers = rows('issuer')
                routes = rows('route')
                ls = [[x] for x in lemmas]
                obs = rows('obligation')
                mem = rows('memory')
                if case == 'current':
                    obs = [r for r in obs if r[1] != 'unresolved']
                if case == 'missing-writer':
                    writers = writers[:-1]
                if case == 'wrong-storage-domain':
                    writers[2][2] = 'task control word'
                if case == 'forged-issuer':
                    issuers[3][3] = 'TLS address is a scope'
                if case == 'missing-proof':
                    ls = [r for r in ls if r != ['NativeScope.issuePreserves']]
                if case == 'stale-source':
                    source[0][2] = 'stale'
                if case == 'wrong-memory-order':
                    mem[2][1] = 'relaxed failure grants acquire view'
                if case == 'numeric-only-rf':
                    obs = [r for r in obs if r[0] != 'rf-witness']
                session.replace(dict(sourceNeed=src, sourceSeen=source, actionName=[[a] for a in actions], lemmaName=ls, routeNeed=rows('route'), routeSeen=routes, writerNeed=rows('writer'), writerSeen=writers, issuerNeed=rows('issuer'), issuerSeen=issuers, obligation=rows('obligation'), qualified=obs, memoryNeed=rows('memory'), memorySeen=mem))
                result = session.run(queries=['blocked', 'candidate', 'routeLinked', 'writerLinked', 'issuerLinked', 'memoryLinked'])
                assert result['complete']
                results[case] = result['relations']
        finally:
            engine.close()
        assert [c for c, r in results.items() if r['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotNativeEvidence=True))
        matrix = ['#+TITLE: NativeScope issuance and closed native writers — evidence and net return', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitNativeScopeWriters', ':END:', 'These rows are generated by the native SysML evaluator. Conditional formal closure is not runtime admission.']
        for g in ['issuer', 'writer', 'obligation', 'memory', 'gain', 'route', 'source']:
            fs = list(p[g][0])
            matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((str(r[f]).replace('|', ' / ') for f in fs)) + ' |' for r in p[g]]
        _study_write_text(_science.BASE / 'native-scope-writers-matrix.org', '\n'.join(matrix) + '\n')
        d2 = _science.BASE / 'diagrams/native-scope-writers.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 NativeScope: real entry cuts, writer closure and retained unknowns"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        files = [model, qnt, projector, Path(str(_science.context.root / 'src/gambit_smp/scientific_native_scope_writers_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py', _science.ROOT / 'dev/modeling/ascent/native-scope-writers.rules.scm', _science.BASE / 'native-scope-writers-design.org', _science.BASE / 'native-scope-writers-matrix.org', _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', _science.BASE / 'future-frame-commit-design.org', d2, d2.with_suffix('.svg'), _study_workspace('CACHE') / 'config.json']
        bindings.update({_science.rel(f): _science.sha(f) for f in files})
        assert all((_science.sha(_science.ROOT / f) == h for f, h in formalStart.items()))
        assert all((_science.sha(_science.ROOT / f) == h for f, h in bindings.items()))
        checks = dict(sourceAnchors=len(src), issuerRows=len(p['issuer']), writerClasses=len(p['writer']), memoryContracts=len(p['memory']), qntFields=len(pr.SPEC['fields']), qntActions=len(actions), histories=5, samples=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, typedIrNegativeControls=len(controls), admissionCounterexamples=len(prefixes), ascentScenarios=len(results), nativeAdmission=False, fullProductSimulation=False, actualReadsFromProof=False, rootCoverageIsPremise=True, nativePathsRetired=0, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False, unresolved=[r['key'] for r in p['obligation'] if r['status'] == 'unresolved'])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), parentOwnerAstSha256=_science.sha(_science.BASE / 'models/lean/AtomicOwnerAst.lean')))
        _science.save(_study_workspace('OUT') / 'checks.json', dict(checks, validationComplete=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        org = org.replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/native-scope-writers-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/native-scope-writers-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        checks['validationComplete'] = True
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                t = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                t.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, t)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Recheck the real parent AST against current typed QNT, not an old filename.
# Compile the actual prior owner AST, not an unbound copy of its field names.
# Separate admissibility counterexamples. Each original reachable prefix is
# checked before intentionally demanding a false admission premise.
