"""Darwin configured bindings and call/origin lease research: native SysML, ASCENT, QNT and Lean; no runtime work."""
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
        model = _science.BASE / 'models/sysml/darwin-target-lease.sysml'
        qnt = _science.BASE / 'models/quint/darwin_target_lease.qnt'
        projector = _science.ROOT / 'src/gambit_smp/scientific_darwin_target_lease_projection.py'
        proof = _science.BASE / 'models/lean/TargetLease.lean'
        astFile = _science.BASE / 'models/lean/TargetLeaseAst.lean'
        dsl = _science.ROOT / 'dev/modeling/ascent/darwin-target-lease.rules.scm'
        startFiles = [model, qnt, projector, proof, astFile, dsl, Path(str(_science.context.root / 'src/gambit_smp/scientific_darwin_target_lease_study.py')), _science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', _science.ROOT / 'src/gambit_smp/scientific_size_family_hold_balance_study.py']
        bindings = {_science.rel(f): _science.sha(f) for f in startFiles}
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/future-frame-commit/darwin-target/config.json').read_text())
        keys = [(g, i, f, 'GambitDarwinTargetLease::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs]
        field_expressions = []
        for *_, e in keys:
            field_expressions.append(e)
        raw = _study_fields(_science.ROOT, None, 'darwin-target-lease', field_expressions, ordered=True, models=[str(model)])
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
        configured = []
        cohortSeen = []
        bindingSeen = []
        for name, path in [('vendor', 'vendor/gambit'), ('retained', '../ci-source-patch-check/src/gambit')]:
            root = _science.ROOT / path
            config = (root / 'include/config.h').read_text()
            driver = (root / 'bin/gambuild-C.unix').read_text()
            status = (root / 'config.status').read_text()
            header = (root / 'include/gambit.h').read_text()
            make = (root / 'lib/makefile').read_text()
            cs = re.search('^ac_cs_config=(.*)$', status, re.M).group(1)
            compiler = re.search('^C_COMPILER="([^"$]*)"$', driver, re.M).group(1)
            smp = re.findall("'--(enable|disable)-smp'", cs)
            vms = re.findall("'--(enable|disable)-multiple-vms'", cs)
            assert len(smp) == len(vms) == 1
            assert '#define ___CAN_IMPORT_CLIB_DYNAMICALLY' in config and '/* #undef ___CAN_IMPORT_DYNAMICALLY */' in config
            assert '/* #undef ___DEBUG_LOG */' in config and '/* #undef ___DEBUG_ALLOC_MEM */' in config
            assert '#define HAVE_WAITPID 1' in config and '-D___LIBRARY' in make
            assert '#ifdef ___DYNAMIC' in header and '#define ___BIND_LATE' in header and ('#define ___EXT(f)(___GSTATE->f)' in header)
            c = [name, name + '-status', compiler, smp[0] + 'd', vms[0] + 'd', 'configured-source-only']
            assert c in [list(r.values()) for r in p['cohort']]
            cohortSeen.append(c)
            for row in p['binding']:
                if row['cohort'] != name:
                    continue
                defs = re.search('^DEFS_' + ('DYN' if row['mode'] == 'DYN' else 'OBJ') + '="([^"$]*)"$', driver, re.M).group(1).split()
                dynamic = '-D___DYNAMIC' in defs
                seen = dict(row, dynamic='yes' if dynamic else 'no', extRoute='GSTATE-slot' if dynamic else 'direct-runtime-symbol', debugLog='disabled-default', debugAlloc='disabled-default', signature='alloc(size)/free(ptr)')
                assert seen == row
                bindingSeen.append(list(seen.values()))
            configured.append(dict(cohort=name, compiler=compiler, smp=smp[0] + 'd', multipleVMs=vms[0] + 'd', literalDefaultOnly=True, noOverridesQualified=False, loadedImageQualified=False, files={_science.rel(root / f): _science.sha(root / f) for f in ['include/config.h', 'include/gambit.h', 'config.status', 'bin/gambuild-C.unix', 'lib/makefile']}))
        expected = {'config.status': '3ec142dbeeecad9aee1bab1e0517b30390bf0c640ec8d1cbd11632b0307eee83', 'bin/gambuild-C.unix': '58a8f5938c1ae03b25c9af28d103ea41bf8cc87315bc4417109e6ea9af3f9f60', 'include/gambit.h': 'c54139a48c7456b07e772077e5318f4f7dde12ccc392a8ec1d66cbc811fb5c58'}
        for f, h in expected.items():
            assert _science.sha(_science.ROOT / '../ci-source-patch-check/src/gambit' / f) == h
        assert _science.sha(_science.ROOT / 'vendor/gambit/lib/os_base.c') == _science.sha(_science.ROOT / '../ci-source-patch-check/src/gambit/lib/os_base.c')
        _science.save(_study_workspace('CACHE') / 'configured-binding-reduction.json', dict(cohorts=configured, bindingRows=bindingSeen, retainedDigestsMatch=True, allocatorSourceByteIdentical=True, preprocessorExecuted=False, loadedProviderProof=False))
        _science.save(_study_workspace('CACHE') / 'candidate-artifacts.json', [dict(path=str(Path(path) / f), present=(_science.ROOT / path / f).is_file(), qualified=False) for path in ['vendor/gambit', '../ci-source-patch-check/src/gambit'] for f in ['gsi/gsi', 'lib/libgambit.a', 'lib/libgambit.dylib']])
        _science.context.command('typecheck', ['quint', 'typecheck', str(qnt), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        pr = _science.context.library('darwin_target_lease_projection')
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
        parent = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/native-prefix'
        pi = json.loads((parent / 'input.json').read_text())
        pa = json.loads((parent / 'artifacts.json').read_text())
        parentBound = {}
        assert _science.sha(_science.LEAN) == pi['leanBinarySha256']
        closure = ['AtomicOwnerAst', 'NativeScopeAst', 'NativeScope', 'NativeEntryAst', 'NativeEntry', 'NativePrefixAst', 'NativePrefix']
        for n in closure:
            f = _science.BASE / 'models/lean' / (n + '.lean')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
            o = parent / (n + '.olean')
            assert _science.sha(o) == pa[_science.rel(o)]
            shutil.copyfile(o, _study_workspace('CACHE') / o.name)
            parentBound[_science.rel(f)] = dict(sourceSha256=_science.sha(f), objectSha256=_science.sha(o))
        for name in ['native_scope_writers', 'future_atomic_owner', 'native_entry_admission', 'native_prefix_permission']:
            f = _science.BASE / 'models/quint' / (name + '.qnt')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
        for name in ['native-scope-writers', 'future-atomic-owner', 'native-entry-admission', 'native-prefix-permission']:
            f = _science.ROOT / 'dev/modeling/tools' / (name + '-projection.py')
            assert _science.sha(f) == pi['sourceBindings'][_science.rel(f)]
            bindings[_science.rel(f)] = _science.sha(f)
        assert _science.sha(_science.ROOT / 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py') == pi['sourceBindings']['src/gambit_smp/scientific_chunk_capacity_charge_projection.py']
        _science.save(_study_workspace('CACHE') / 'parent-proof-reuse.json', dict(bound=parentBound, parentInputSha256=_science.sha(parent / 'input.json'), leanBinarySha256=_science.sha(_science.LEAN), scopedAcquisitionJoinOnly=True, fullProductSimulation=False))
        for n in ['TargetLeaseAst', 'TargetLease']:
            f = _science.BASE / 'models/lean' / (n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', f.read_text())
            _science.context.command('lean-' + n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(f)], policy=_science.process_profile)
        lemmas = ['TargetLease.' + n for n in re.findall('^theorem (\\w+)', proof.read_text(), re.M)]
        for row in p['component']:
            assert all((a in actions for a in row['actionSlice'].split('/'))) and row['proof'] in lemmas
        histories = re.findall('^run (\\w+Test)=', qnt.read_text(), re.M)
        t = _science.context.command('histories', ['quint', 'test', str(qnt), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=_science.process_profile)
        assert t.count('ok ') == len(histories)
        _science.context.command('samples', ['quint', 'run', str(qnt), '--backend', 'typescript', '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=_science.process_profile)
        allocated = ['publishPlain', 'acquireOuter', 'beginMalloc', 'obtainPointer', 'recordSuccess', 'releaseOuter']
        freeStarted = allocated + ['closeOrdinary', 'publishReplacement', 'beginOriginFree']
        prefixes = {'acquire-after-close': (['publishPlain', 'closeOrdinary'], 'acquireOuterGuard witness'), 'origin-after-call-is-not-drained': (allocated + ['closeOrdinary'], 'retireOldBundleGuard witness'), 'reader-close-is-not-drain': (['publishPlain', 'acquireOuter', 'closeOrdinary'], 'retireOldBundleGuard witness'), 'nested-close-is-not-drain': (['publishAdmittedHooks', 'acquireOuter', 'enterNested', 'closeOrdinary'], 'retireOldBundleGuard witness'), 'unknown-before-record-no-recovery': (['publishAdmittedHooks', 'acquireOuter', 'beginMalloc', 'obtainPointer', 'loseBeforeCapture'], 'recoverRecordedGuard witness'), 'effect-is-not-free-receipt': (freeStarted + ['applyFree', 'loseFreeReturn'], 'reconcileFreeGuard witness'), 'unknown-free-keeps-maintenance': (freeStarted + ['applyFree', 'loseFreeReturn'], 'releaseMaintenanceGuard witness'), 'new-current-is-not-origin-free': (freeStarted, '(witness.freeFamily=witness.current)'), 'unknown-origin-keeps-provider': (['publishAdmittedHooks', 'acquireOuter', 'beginMalloc', 'obtainPointer', 'loseBeforeCapture', 'closeOrdinary'], 'retireOldBundleGuard witness')}
        for name, (seq, goal) in prefixes.items():
            e = 'initial'
            defs = ['initial']
            gs = []
            for a in seq:
                gs += ['example : ' + a + 'Guard (' + e + ') := by simp [' + ','.join([a + 'Guard'] + defs) + ']']
                e = a + 'Next (' + e + ')'
                defs += [a + 'Next']
            simp = ','.join(['Safe', 'witness'] + defs + [n + 'Guard' for n in actions])
            text = 'import TargetLease\nopen TargetLeaseAst TargetLease\ndef witness : State := ' + e + '\n' + '\n'.join(gs) + '\nexample : Safe witness := by simp [' + simp + ']\nexample : ¬ (' + goal + ') := by simp [' + simp + ']\n'
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
        cases = ['current', 'synthetic-all', 'mixed-cohort', 'dynamic-is-direct', 'debug-default-logs', 'gstate-pins-libc', 'module-refcount-is-stream-drain', 'free-uses-current', 'free-effect-is-receipt', 'close-drops-call', 'abi-cast-is-atomic', 'missing-prefix-join', 'missing-lemma', 'stale-source']
        try:
            session = engine.open_sources(dsl.read_text())
            assert session.run(queries=['blocked'])['complete']
            for case in cases:
                so = copy.deepcopy(src)
                cs = copy.deepcopy(cohortSeen)
                bs = copy.deepcopy(bindingSeen)
                wr = rows('writer')
                iss = rows('issuer')
                jo = rows('join')
                co = rows('component')
                mem = rows('memory')
                ls = [[l] for l in lemmas]
                qualified = rows('obligation')
                if case == 'current':
                    qualified = [r for r in qualified if r[1] != 'unresolved']
                if case == 'mixed-cohort':
                    cs[0][3] = 'enabled'
                if case == 'dynamic-is-direct':
                    bs = [r[:5] + ['direct-runtime-symbol'] + r[6:] if r[2] == 'DYN' else r for r in bs]
                if case == 'debug-default-logs':
                    bs[0][7] = 'enabled'
                if case == 'gstate-pins-libc':
                    iss[1][3] = 'GSTATE generation alone freezes imported malloc/free'
                if case == 'module-refcount-is-stream-drain':
                    wr[2][4] = 'base refcount certifies all in-flight vfprintf users drained'
                if case == 'free-uses-current':
                    mem[4][2] = 'free through whatever provider is currently installed'
                if case == 'free-effect-is-receipt':
                    jo[3][3] = 'physical effect ghost is a runtime backend receipt'
                if case == 'close-drops-call':
                    mem[1][2] = 'close clears all pre-existing call counts'
                if case == 'abi-cast-is-atomic':
                    mem[5][2] = 'cast ordinary GSTATE pointer fields into atomic storage'
                if case == 'missing-prefix-join':
                    jo = jo[2:]
                if case == 'missing-lemma':
                    ls = [r for r in ls if r != ['TargetLease.acquireOuterPreserves']]
                if case == 'stale-source':
                    so[0][2] = 'stale-config-hash'
                session.replace(dict(sourceNeed=src, sourceSeen=so, obligation=rows('obligation'), qualified=qualified, actionName=[[n] for n in actions], lemmaName=ls, routeNeed=rows('route'), routeSeen=rows('route'), cohortNeed=rows('cohort'), cohortSeen=cs, bindingNeed=rows('binding'), bindingSeen=bs, writerNeed=rows('writer'), writerSeen=wr, issuerNeed=rows('issuer'), issuerSeen=iss, joinNeed=rows('join'), joinSeen=jo, componentNeed=rows('component'), componentSeen=co, memoryNeed=rows('memory'), memorySeen=mem))
                result = session.run(queries=['blocked', 'candidate', 'routeLinked', 'cohortLinked', 'bindingLinked', 'writerLinked', 'issuerLinked', 'joinLinked', 'componentLinked', 'memoryLinked'])
                assert result['complete']
                results[case] = result['relations']
        finally:
            engine.close()
        assert [c for c, r in results.items() if r['candidate']] == ['synthetic-all']
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticIsNotNativeEvidence=True))
        matrix = ['#+TITLE: Darwin targets — configured binding, invocation/origin leases and return', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':AUTHORITY: GambitDarwinTargetLease', ':END:', 'Configured source reductions and abstract lease safety are distinct from loaded provider qualification.']
        for group in ['component', 'cohort', 'binding', 'writer', 'issuer', 'obligation', 'memory', 'gain', 'join', 'route', 'source']:
            fs = list(p[group][0])
            matrix += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|'] + ['| ' + ' | '.join((str(r[f]).replace('|', ' / ') for f in fs)) + ' |' for r in p[group]]
        _study_write_text(_science.BASE / 'darwin-target-lease-matrix.org', '\n'.join(matrix) + '\n')
        d2 = _science.BASE / 'diagrams/darwin-target-lease.d2'
        _study_write_text(d2, 'direction: down\ntitle: "C23 Darwin targets: call leases, allocation origins and retirement"\n' + '\n'.join((json.dumps(r['fromNode']) + ' -> ' + json.dumps(r['toNode']) + ': ' + json.dumps(r['contract']) for r in p['edge'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(d2), str(d2.with_suffix('.svg'))], policy=_science.process_profile)
        checks = dict(sourceAnchors=len(sources), configuredCohorts=len(configured), bindingCases=len(bindingSeen), writerClasses=len(p['writer']), components=len(p['component']), jointIssuers=len(p['issuer']), qntFields=len(pr.SPEC['fields']), qntActions=len(actions), histories=len(histories), samples=500, maxSteps=80, seed=953, leanTheorems=len(lemmas), stepInduction=True, actualPrefixGrantJoins=True, fullProductSimulation=False, typedIrNegativeControls=len(controls), admissionCounterexamples=len(prefixes), ascentScenarios=len(cases), nativeAdmission=False, loadedProviderQualified=False, selectedDefaultsOnly=True, rawWriterClosure=False, allocationCaptureIsPremise=True, freeBackendReceiptIsPremise=True, originOutlivesCall=True, nativePathsRetired=0, runtimeImplementation=False, nativeTests=False, nativeCompilerOrPreprocessorRun=False, performanceTests=False, unresolved=[r['key'] for r in p['obligation'] if r['status'] == 'unresolved'])
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(checks, validationComplete=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', 'dev/refactoring/modern-c/darwin-target-lease-design.org').replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', 'dev/refactoring/modern-c/darwin-target-lease-matrix.org').replace('dev/architecture/toolchain/index.org', 'dev/refactoring/modern-c/index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        checks['validationComplete'] = True
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for f in [_science.BASE / 'darwin-target-lease-design.org', _science.BASE / 'darwin-target-lease-matrix.org', _science.BASE / 'index.org', _science.BASE / 'runtime-blueprint.org', _science.BASE / 'native-prefix-permission-design.org', d2, d2.with_suffix('.svg'), _study_workspace('CACHE') / 'config.json']:
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
# Bounded literal default reduction only: no sourcing/eval, shell decoding,
# compiler/preprocessor, loader or target executable is invoked.
# These retained digests were independently recorded in the prior Darwin ledger.
