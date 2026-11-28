"""Joint native entry research: native SysML, ASCENT, QNT and Lean; no runtime work."""
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
        model = _science.BASE / 'models/sysml/native-entry-admission.sysml'
        qnt = _science.BASE / 'models/quint/native_entry_admission.qnt'
        projector = _science.ROOT / 'src/gambit_smp/scientific_native_entry_admission_projection.py'
        proof = _science.BASE / 'models/lean/NativeEntry.lean'
        astFile = _science.BASE / 'models/lean/NativeEntryAst.lean'
        dsl = _science.ROOT / 'dev/modeling/ascent/native-entry-admission.rules.scm'
        startFiles = [model, qnt, projector, proof, astFile, dsl, Path(str(_science.context.root / 'src/gambit_smp/scientific_native_entry_admission_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']
        bindings = {_science.rel(f): _science.sha(f) for f in startFiles}
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/future-frame-commit/native-entry/config.json').read_text())
        keys = [(g, i, f, 'GambitNativeEntryAdmission::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs]
        field_expressions = []
        for *_, e in keys:
            field_expressions.append(e)
        raw = _study_fields(_science.ROOT, None, 'native-entry-admission', field_expressions, ordered=True, models=[str(model)])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(rs.values()) for g, rs in p.items()}
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        sources = []
        for row in p['source']:
            f = _science.ROOT / row['path']
            text = f.read_text()
            assert row['needle'] in text
            h = _science.sha(f)
            bindings[row['path']] = h
            _study_write_text(_study_workspace('CACHE') / ('source-' + h + '.txt'), text)
            sources.append(dict(**row, sha256=h, lines=[text.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(row['needle']), text)]))
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', sources)
        tcl = json.loads((_science.ROOT / 'evidence/research/source-references/tcl/source-bindings.json').read_text())
        tr = tcl['files']['generic/tclBasic.c']
        assert _science.sha(_science.ROOT / tr['capturePath']) == tr['sha256']
        bindings['evidence/research/source-references/tcl/source-bindings.json'] = _science.sha(_science.ROOT / 'evidence/research/source-references/tcl/source-bindings.json')
        _science.save(_study_workspace('CACHE') / 'tcl-source-profile.json', dict(commit=tcl['resolvedCommit'], sourceSha256=tr['sha256'], installedLibraryQualified=False))
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        pr = _science.context.library('native_entry_admission_projection')
        ast, receipt = pr.generate(ir)
        assert astFile.read_text() == ast
        actions = pr.SPEC['actions']
        controls = {}
        for label in ['binding', 'field', 'roster', 'expression']:
            bad = copy.deepcopy(ir)
            ds = {d['name']: d for d in bad['modules'][0]['declarations']}
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
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, controls=controls, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=_science.sha(astFile)))
        parent = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/native-scope'
        pi = json.loads((parent / 'input.json').read_text())
        pa = json.loads((parent / 'artifacts.json').read_text())
        parentBound = {}
        assert _science.sha(_science.LEAN) == pi['leanBinarySha256']
        closure = ['AtomicOwnerAst', 'NativeScopeAst', 'NativeScope']
        for n in closure:
            f = _science.BASE / 'models/lean' / (n + '.lean')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
            o = parent / (n + '.olean')
            assert _science.sha(o) == pa[_science.rel(o)]
            shutil.copyfile(o, _study_workspace('CACHE') / o.name)
            parentBound[_science.rel(f)] = dict(sourceSha256=_science.sha(f), objectSha256=_science.sha(o))
        for name in ['native_scope_writers', 'future_atomic_owner']:
            f = _science.BASE / 'models/quint' / (name + '.qnt')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
        for name in ['native-scope-writers', 'future-atomic-owner']:
            f = _science.ROOT / 'dev/modeling/tools' / (name + '-projection.py')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
        assert _science.sha(_science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py') == pi['sourceBindings']['src/gambit_smp/scientific_chunk_capacity_charge_projection.py']
        _science.save(_study_workspace('CACHE') / 'parent-proof-reuse.json', dict(bound=parentBound, parentInputSha256=_science.sha(parent / 'input.json'), leanBinarySha256=_science.sha(_science.LEAN), freshBoundaryOnly=True, fullProductSimulation=False))
        for n in ['NativeEntryAst', 'NativeEntry']:
            f = _science.BASE / 'models/lean' / (n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
            _science.context.command('lean-' + n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
        lemmas = ['NativeEntry.' + n for n in re.findall('^theorem (\\w+)', proof.read_text(), re.M)]
        for row in p['component'] + p['authority']:
            assert all((a in actions for a in row['actionSlice'].split('/'))) and row['proof'] in lemmas
        histories = re.findall('^run (\\w+Test)=', qnt.read_text(), re.M)
        t = _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
        assert t.count('ok ') == len(histories)
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        issued = ['pinSource', 'reserveCarrier', 'qualifyHost', 'publishCarrier', 'jointIssue']
        entered = issued + ['writeEntryState', 'allocateMarker']
        prefixes = {'issue-before-registration': (issued[:3], 'jointIssueGuard witness'), 'marker-before-issuer': (issued[:4], 'allocateMarkerGuard witness'), 'lost-registration-is-known': (issued[:4] + ['loseRegistrationAck'], 'jointIssueGuard witness'), 'freeze-keeps-old-transfer': (issued + ['certifyTransfer', 'freezeWriters'], 'releaseSourceGuard witness'), 'close-is-drain': (entered + ['enterNested', 'closeIngress'], 'retireCarrierGuard witness'), 'freeze-requires-no-borrow': (['pinSource', 'freezeWriters'], '(witness.sourcePin=0)'), 'unknown-is-failure': (entered + ['loseCompletion', 'closeIngress'], 'recoverRecordedGuard witness'), 'late-callback-after-close': (entered + ['closeIngress'], 'enterNestedGuard witness'), 'grace-before-scan-return': (entered + ['recordOutcome', 'settleKnown', 'closeIngress', 'freezeWriters', 'closeScanAdmission'], 'confirmGraceGuard witness')}
        for name, (seq, goal) in prefixes.items():
            e = 'initial'
            defs = ['initial']
            gs = []
            for a in seq:
                gs += ['example : ' + a + 'Guard (' + e + ') := by simp [' + ','.join([a + 'Guard'] + defs) + ']']
                e = a + 'Next (' + e + ')'
                defs += [a + 'Next']
            simp = ','.join(['Safe', 'witness'] + defs + [n + 'Guard' for n in actions])
            text = 'import NativeEntry\nopen NativeEntryAst NativeEntry\ndef witness : State := ' + e + '\n' + '\n'.join(gs) + '\nexample : Safe witness := by simp [' + simp + ']\nexample : ¬ (' + goal + ') := by simp [' + simp + ']\n'
            f = _study_workspace('CACHE') / (name + '-original.lean')
            _study_write_text(f, text)
            _science.context.command(name + '-original', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], policy=_science.process_profile)
            f = _study_workspace('CACHE') / (name + '-negative.lean')
            _study_write_text(f, text + 'example : ' + goal + ' := by simp [' + simp + ']\n')
            err = _science.context.command(name + '-negative', ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, str(f)], expected=1, policy=_science.process_profile)
            assert err.count('error:') == 1

        def rows(g):
            return [list(r.values()) for r in p[g]]
        src = [[r['key'], r['path'], r['sha256'], r['needle']] for r in sources]
        results = {}
        engine = Engine()
        cases = ['current', 'synthetic-all', 'pin-after-payload', 'borrow-drain-at-freeze', 'forged-registration-ack', 'missing-join', 'missing-lemma', 'stale-tcl-source', 'unknown-as-conversion-error', 'component-filename-only', 'relaxed-publish', 'preparation-is-execution']
        try:
            session = engine.open_sources(dsl.read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                so = copy.deepcopy(src)
                cu = rows('cut')
                iss = rows('issuer')
                jo = rows('join')
                mem = rows('memory')
                co = rows('component')
                au = rows('authority')
                ls = [[l] for l in lemmas]
                qualified = rows('obligation')
                if case == 'current':
                    qualified = [r for r in qualified if r[1] != 'unresolved']
                if case == 'pin-after-payload':
                    cu[4][2] = 'after data_rc load'
                if case == 'borrow-drain-at-freeze':
                    mem[3][2] = 'wait for all RC root borrows to return before collecting'
                if case == 'forged-registration-ack':
                    iss[3][3] = 'assume registration after timeout'
                if case == 'missing-join':
                    jo = jo[1:]
                if case == 'missing-lemma':
                    ls = [r for r in ls if r != ['NativeEntry.jointIssuePreserves']]
                if case == 'stale-tcl-source':
                    so = [r[:2] + ['wrong-installed-library-hash'] + r[3:] if r[0] == 'tcl-delete' else r for r in so]
                if case == 'unknown-as-conversion-error':
                    cu[6][4] = 'invoke Scheme conversion error callback for unknown admission'
                if case == 'component-filename-only':
                    co[2][3] = 'NativeEntry.fileExists'
                if case == 'preparation-is-execution':
                    au[0][3] = 'root preparation may execute Scheme before registration'
                if case == 'relaxed-publish':
                    mem[1][1] = 'relaxed store makes arbitrary readers acquire'
                session.replace(dict(sourceNeed=src, sourceSeen=so, obligation=rows('obligation'), qualified=qualified, actionName=[[n] for n in actions], lemmaName=ls, routeNeed=rows('route'), routeSeen=rows('route'), cutNeed=rows('cut'), cutSeen=cu, issuerNeed=rows('issuer'), issuerSeen=iss, joinNeed=rows('join'), joinSeen=jo, memoryNeed=rows('memory'), memorySeen=mem, componentNeed=rows('component'), componentSeen=co, authorityNeed=rows('authority'), authoritySeen=au))
                result = session.run(queries=['blocked', 'candidate', 'routeLinked', 'cutLinked', 'issuerLinked', 'joinLinked', 'memoryLinked', 'componentLinked', 'authorityLinked'])
                assert result['complete']
                results[case] = result['relations']
        finally:
            engine.close()
        assert [c for c, r in results.items() if r['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticIsNotNativeEvidence=True))
        matrix = ['#+TITLE: Native entry joint issuers — source cuts, closure and net return', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitNativeEntryAdmission', ':END:', 'Finite protocol safety and a fresh NativeScope step join are conditional. Native integration remains unresolved.']
        for group in ['component', 'authority', 'cut', 'issuer', 'obligation', 'memory', 'gain', 'join', 'route', 'source']:
            fs = list(p[group][0])
            matrix += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((str(r[f]).replace('|', ' / ') for f in fs)) + ' |' for r in p[group]]
        _study_write_text(_science.BASE / 'native-entry-admission-matrix.org', '\n'.join(matrix) + '\n')
        d2 = _science.BASE / 'diagrams/native-entry-admission.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 joint native entry: protect, publish, admit, drain"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), components=len(p['component']), entryCuts=len(p['cut']), authorityLevels=len(p['authority']), jointIssuers=len(p['issuer']), memoryContracts=len(p['memory']), qntFields=len(pr.SPEC['fields']), qntActions=len(actions), histories=len(histories), samples=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, freshNativeScopeStepJoin=True, fullProductSimulation=False, typedIrNegativeControls=len(controls), admissionCounterexamples=len(prefixes), ascentScenarios=len(cases), nativeAdmission=False, nativeEntryIssuerImplemented=False, actualReadsFromProof=False, sourceEligibilityIsPremise=True, scanEnrollmentIsAtomicPremise=True, installedTclQualified=False, nativePathsRetired=0, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False, unresolved=[r['key'] for r in p['obligation'] if r['status'] == 'unresolved'])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(checks, validationComplete=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/native-entry-admission-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/native-entry-admission-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        checks['validationComplete'] = True
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for f in [_science.BASE / 'native-entry-admission-design.org', _science.BASE / 'native-entry-admission-matrix.org', _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', _science.BASE / 'native-scope-writers-design.org', d2, d2.with_suffix('.svg'), _study_workspace('CACHE') / 'config.json']:
            bindings[_science.rel(f)] = _science.sha(f)
        assert all((_science.sha(_science.ROOT / f) == h for f, h in bindings.items()))
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, leanBinarySha256=_science.sha(_science.LEAN), parentInputSha256=_science.sha(parent / 'input.json'), runtimeClaim=False))
        for f in _study_workspace('CACHE').rglob('*'):
            if f.is_file():
                t = _study_workspace('OUT') / f.relative_to(_study_workspace('CACHE'))
                t.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(f, t)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {_science.rel(f): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# The Tcl source is a pinned capture, never a claim about the installed library.
