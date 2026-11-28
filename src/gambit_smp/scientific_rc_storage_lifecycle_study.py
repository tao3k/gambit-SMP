"""Scoped source/formal research. Native SysML evaluates routing; no runtime tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import copy
import hashlib
import json
import os
import re
import shutil
import textwrap
from pathlib import Path

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.copy = copy
        _science.hashlib = hashlib
        _science.json = json
        _science.os = os
        _science.re = re
        _science.shutil = shutil
        _science.textwrap = textwrap
        _science.Path = Path
        _science.ROOT = _science.context.root
        _science.STEM = 'rc-storage-lifecycle'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.LEAN = os.environ.get('CARRIER_LEAN', '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean')
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'assertion', 'failParameter': True, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, value):
        _study_write_text(Path(p), json.dumps(value, indent=2, ensure_ascii=False) + '\n')

    def formal(_science):
        m = _science.context.library('rc_storage_lifecycle_projection')
        modules = ['RcStorageAst', 'RcStorageAllocation', 'RcStorageRootAdmission', 'RcStorageReferences', 'RcStoragePublication', 'RcStorageAccess', 'RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership', 'RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal', 'RcStorageCleanup', 'RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse', 'RcStorage', 'RcStorageBoundary']
        formal_paths = [_science.BASE + 'models/quint/rc_storage_lifecycle.qnt', 'src/gambit_smp/scientific_rc_storage_lifecycle_projection.py', 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py'] + [_science.BASE + 'models/lean/' + n + '.lean' for n in modules]

        def names():
            return [['RcStorageBoundary.' + v if n == 'RcStorageBoundary' else 'RcStorage.' + v] for n in modules if n != 'RcStorageAst' for v in re.findall('^theorem (\\w+)', (_science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')).read_text(), re.M)]
        if '--reuse-formal' in _science.context.arguments:
            cp = json.loads((_study_workspace('CACHE') / 'formal-checkpoint.json').read_text())
            assert cp['sources'] == {f: _science.sha(_science.ROOT / f) for f in formal_paths}
            assert all((_science.sha(_science.ROOT / f) == h for f, h in cp['logs'].items()))
            return ([[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']], names())
        qnt = _science.BASE + 'models/quint/rc_storage_lifecycle.qnt'
        _science.context.command('typecheck', ['quint', 'typecheck', qnt, '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=_science.process_profile)
        ir = json.loads((_study_workspace('CACHE') / 'typed-ir.json').read_text())
        ast, receipt = m.generate(ir)
        _study_write_text(_science.ROOT / (_science.BASE + 'models/lean/RcStorageAst.lean'), ast)
        _science.save(_study_workspace('CACHE') / 'projection.json', dict(**receipt, irSha256=_science.sha(_study_workspace('CACHE') / 'typed-ir.json'), astSha256=hashlib.sha256(ast.encode()).hexdigest(), scope='restricted typed IR; native product refinement open'))
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
                ds['safe']['expr']['opcode'] = 'unsupported'
            try:
                m.generate(bad)
            except (AssertionError, KeyError):
                controls[label] = 'rejected'
            else:
                raise AssertionError(label)
        _science.save(_study_workspace('CACHE') / 'projection-controls.json', controls)
        lemmas = []
        for n in ['RcStorageAst', 'RcStorageAllocation', 'RcStorageRootAdmission', 'RcStorageReferences', 'RcStoragePublication', 'RcStorageAccess', 'RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership', 'RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal', 'RcStorageCleanup', 'RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse', 'RcStorage', 'RcStorageBoundary']:
            source = _science.ROOT / (_science.BASE + 'models/lean/' + n + '.lean')
            assert not re.search('\\bsorry\\b|\\baxiom\\s', source.read_text())
            target = _study_workspace('CACHE') / (n + '.lean')
            _study_write_bytes(target, source.read_bytes())
            checkpoint = _study_workspace('CACHE') / (n + '.compiled.json')

            def dependencies(module, seen=None):
                seen = set() if seen is None else seen
                src = _science.ROOT / (_science.BASE + 'models/lean/' + module + '.lean')
                if src in seen:
                    return {}
                seen.add(src)
                ds = {str(src.relative_to(_science.ROOT)): _science.sha(src)}
                for imported in re.findall('^import (RcStorage\\w*)$', src.read_text(), re.M):
                    ds.update(dependencies(imported, seen))
                return ds
            deps = dependencies(n)
            if '--reuse-compiled' in _science.context.arguments and checkpoint.exists():
                prior = json.loads(checkpoint.read_text())
                assert {f: prior['inputs'][f] for f in deps} == deps and prior['olean'] == _science.sha(_study_workspace('CACHE') / (n + '.olean'))
                assert all((_science.sha(_science.ROOT / f) == h for f, h in prior['logs'].items()))
            else:
                _science.context.command(n, ['env', 'LEAN_PATH=' + str(_study_workspace('CACHE')), _science.LEAN, '-o', str(_study_workspace('CACHE') / (n + '.olean')), str(target)], policy=_science.process_profile)
                _science.save(checkpoint, dict(inputs=deps, olean=_science.sha(_study_workspace('CACHE') / (n + '.olean')), logs={str((_study_workspace('CACHE') / (n + x)).relative_to(_science.ROOT)): _science.sha(_study_workspace('CACHE') / (n + x)) for x in ['.stdout', '.stderr']}))
            lemmas += [[('RcStorageBoundary' if n == 'RcStorageBoundary' else 'RcStorage') + '.' + v] for v in re.findall('^theorem (\\w+)', source.read_text(), re.M)]
        histories = _science.context.command('histories', ['quint', 'test', qnt, '--match', 'Test$'], policy=_science.process_profile)
        assert histories.count('ok ') == 7
        _science.context.command('samples', ['quint', 'run', qnt, '--init', 'init', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '100', '--seed', '463', '--verbosity', '1'], policy=_science.process_profile)
        mutants = [('premature-free', 'def finishFreeGuard', '(q.phase=(7))', '(q.phase=(2))', '{initial with phase:=2, operation:=1, owned:=1, base:=1, sourceHold:=1, owner:=1, keyGeneration:=1, checked:=1}', 'finishFree', None), ('unknown-commit', 'def unpublishGuard', '(q.known=(1))', 'True', '{initial with phase:=5, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, keyGeneration:=1, index:=3, committed:=1, effects:=1, checked:=1}', 'unpublish', None), ('context-exit', 'def exitContextGuard', '((q.owner=(2)) ∨ ((q.owned=(0)) ∧ (q.sourceHold=(0))))', 'True', '{initial with phase:=4, operation:=1, owned:=1, root:=1, sourceHold:=1, owner:=1, contextClosing:=1, keyGeneration:=1, index:=2, committed:=1, base:=1, checked:=1}', 'exitContext', None), ('generation-reused', 'def reuseAddressNext', 'generation:=(q.generation+(1))', 'generation:=q.generation', '{initial with phase:=8, operation:=1, index:=4, known:=1, frees:=1, keyGeneration:=1, checked:=1, grace:=1, effects:=1, owner:=1}', 'reuseAddress', '(reuseAddressNext witness).generation > witness.generation')]
        for label, decl, before, after, state, action, goal in mutants:
            d = _study_workspace('CACHE') / ('negative-' + label)
            d.mkdir(exist_ok=True)
            mutated = '\n'.join((v.replace(before, after) if v.startswith(decl) else v for v in ast.splitlines())) + '\n'
            assert mutated != ast, label
            _study_write_text(d / 'RcStorageAst.lean', mutated)
            _science.context.command(label + '-ast', [_science.LEAN, '-o', str(d / 'RcStorageAst.olean'), str(d / 'RcStorageAst.lean')], policy=_science.process_profile)
            goal = goal or 'Safe (' + action + 'Next witness)'
            script = 'import RcStorageAst\nopen RcStorageAst\ndef witness : State := ' + state + '\nexample : Safe witness := by simp [Safe,witness,initial]' + '\nexample : ' + action + 'Guard witness := by simp [' + action + 'Guard,witness,initial]' + '\nexample : ¬ (' + goal + ') := by simp [Safe,' + action + 'Next,witness,initial]' + '\nexample : ' + goal + ' := by simp [Safe,' + action + 'Next,witness,initial]\n'
            _study_write_text(d / 'Control.lean', script)
            out = _science.context.command(label + '-control', ['env', 'LEAN_PATH=' + str(d) + ':' + str(_study_workspace('CACHE')), _science.LEAN, str(d / 'Control.lean')], fail=True, policy=_science.process_profile)
            assert out.count('error:') == 1 and 'Control.lean:7:' in out and ('false' in out.lower()), out
        _science.save(_study_workspace('CACHE') / 'formal-checkpoint.json', dict(sources={f: _science.sha(_science.ROOT / f) for f in formal_paths}, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr'] and f.stem not in ['sysml-scoped', 'd2-svg', 'd2-png', 'org-check', 'head', 'branch']}))
        return ([[m.SPEC['module'] + '.' + a] for a in m.SPEC['actions']], lemmas)

    def native_model(_science):
        cfg = json.loads((_science.ROOT / 'dev/modeling/inputs/rc-storage-lifecycle/config.json').read_text())
        keys = [(g, i, f, 'GambitRcStorageLifecycle::' + g + str(i) + '.' + f) for g, n, fs in cfg for i in range(n) for f in fs.split()]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        raw = _study_fields(_science.ROOT, None, 'rc-storage-lifecycle', field_expressions, ordered=True, models=[_science.BASE + 'models/sysml/' + _science.STEM + '.sysml'])
        vals = raw['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        p = {g: list(v.values()) for g, v in p.items()}
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        return p

    def analyze(_science):
        from ascent import Engine
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        p = _science.native_model()
        source = []
        for v in p['source']:
            data = (_science.ROOT / v['path']).read_text()
            assert v['needle'] in data
            source.append([v['key'], v['path'], _science.sha(_science.ROOT / v['path']), v['needle']])
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', [dict(key=k, path=f, sha256=h, needle=n, lines=[data.count('\n', 0, m.start()) + 1 for m in re.finditer(re.escape(n), data)]) for k, f, h, n in source for data in [(_science.ROOT / f).read_text()]])
        rc_path = 'vendor/gambit/lib/_mem/rc-allocation.inc'
        rc = (_science.ROOT / rc_path).read_text()
        private = rc.split('___EXP_FUNC(void*,___alloc_rc_no_register)', 1)[1].split('___EXP_FUNC(void,___register_rc)', 1)[0]
        assert 'h->refcount = 1;' in private and 'h->data = ___FAL;' in private
        assert 'h->prev' not in private and 'h->next' not in private
        _science.save(_study_workspace('CACHE') / 'private-allocation-slice.json', dict(path=rc_path, sha256=_science.sha(_science.ROOT / rc_path), startLine=rc[:rc.index('___EXP_FUNC(void*,___alloc_rc_no_register)')].count('\n') + 1, refcountAndFalseDataInitialized=True, listLinksInitialized=False, scope='bounded lexical function body; not complete C or allocator semantics'))
        corpus = ['vendor/gambit/lib', 'vendor/gambit/include', 'vendor/gambit/examples']
        globs = ['-g', '*.c', '-g', '*.inc', '-g', '*.h', '-g', '*.h.in', '-g', '*.scm']
        paths = _science.context.command('rc-caller-files', ['rg', '--files'] + corpus + globs, policy=_science.process_profile).splitlines()
        caller_inputs = {f: _science.sha(_science.ROOT / f) for f in paths}
        _science.context.command('rc-caller-sites', ['rg', '-n', '--no-heading', '___alloc_rc_no_register|___register_rc|___alloc_rc\\b|___release_rc\\b|___addref_rc\\b|___refcount_rc\\b|cleanup_rc'] + corpus + globs, policy=_science.process_profile)
        _science.save(_study_workspace('CACHE') / 'rc-caller-inventory.json', dict(inputs=caller_inputs, scope=corpus, includesTemplatesAndGeneratedHeaders=True, completeLiteralEnumeration=True, completeIndirectAndOutOfTreeCallerClosure=False))
        actions, lemmas = _science.formal()
        assert all(([v['lemma']] in lemmas for v in p['proof']))
        needs = [[v['key'], v['kind'], v['path'], _science.sha(_science.ROOT / v['path']), v['scope']] for v in p['need']]
        routes = [[v[k] for k in ['component', 'actionName', 'lemma', 'producerAnchor', 'obligationId']] for v in p['route']]
        engine = Engine()
        results = {}
        try:
            s = engine.open_sources((_science.ROOT / ('dev/modeling/ascent/' + _science.STEM + '.rules.scm')).read_text())
            assert s.run(queries=['blocked'])['complete']
            for case in ['current', 'synthetic-all', 'wrong-owner', 'missing-action', 'missing-lemma', 'stale-source', 'wrong-scope', 'missing-route', 'missing-algebra', 'missing-formal', 'wrong-issuer']:
                receipts = [[case, n, path, h, sc] for n, kind, path, h, sc in needs if case != 'current' or kind in ['formal', 'bridge']]
                if case == 'wrong-scope':
                    receipts[0][-1] = 'native-performance'
                if case == 'missing-formal':
                    receipts = [v for v in receipts if v[1] != 'RC-formal']
                obs = copy.deepcopy(source)
                if case == 'stale-source':
                    obs[0][2] = 'stale'
                ro = copy.deepcopy(routes)
                if case == 'wrong-owner':
                    ro[0][0] = 'wrong'
                if case == 'missing-route':
                    ro.pop(0)
                ln = [v for v in lemmas if (case != 'missing-lemma' or v != ['RcStorage.stepPreserves']) and (case != 'missing-algebra' or v != ['RcStorageBoundary.addressOnlyCannotSeparate'])]
                issuer_observation = [[v[k] for k in ['key', 'proposedIssuer', 'actualSource', 'status', 'responsibility']] for v in p['issuer']]
                if case == 'wrong-issuer':
                    issuer_observation[0][2] = 'fabricated existing StorageId signer'
                s.replace(dict(scenario=[[case]], need=needs, needOwner=[[v['key'], v['owner.componentId']] for v in p['need']], receipt=receipts, binding=[[v['actionName'], v['lemma']] for v in p['binding']], actionName=actions[1:] if case == 'missing-action' else actions, lemmaName=ln, sourceNeed=source, sourceObservation=obs, routeNeed=routes, routeObservation=ro, proofNeed=[[v['key'], v['lemma']] for v in p['proof']] + [['all-step', 'RcStorage.stepPreserves']], issuerNeed=[[v[k] for k in ['key', 'proposedIssuer', 'actualSource', 'status', 'responsibility']] for v in p['issuer']], issuerObservation=issuer_observation))
                r = s.run(queries=['candidate', 'blocked', 'routeLinked', 'proofLinked'])
                assert r['complete']
                results[case] = r['relations']
        finally:
            engine.close()
        assert [k for k, v in results.items() if v['candidate']] == ['synthetic-all']
        gaps = sorted((v[1] for v in results['current']['blocked']))
        assert len(gaps) == 6 and len(results['current']['routeLinked']) == len(routes)
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticNotEvidence=True))
        matrix = ['#+TITLE: RC Allocation and Storage Index — Benefits, Costs and Closure', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: storage-index-matrix', ':AUTHORITY: GambitRcStorageLifecycle', ':END:', 'Rows below are evaluated from SysML. Formal routes locate proposed replacements; they do not assert existing native implementation.']
        for g in ['gain', 'memory', 'issuer', 'need', 'route', 'proof', 'source']:
            fields = list(p[g][0])
            matrix += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            matrix += ['| ' + ' | '.join((v[f] for f in fields)) + ' |' for v in p[g]]
        matrix += ['', '** Closure observation', '', '| Obligation | Status |', '|---+---|']
        matrix += ['| ' + v['key'] + ' | ' + ('unresolved native integration' if v['key'] in gaps else 'scoped conditional formal receipt') + ' |' for v in p['need']]
        _study_write_text(_science.ROOT / (_science.BASE + _science.STEM + '-matrix.org'), '\n'.join(matrix) + '\n')
        graph = ['direction: down', 'title: "C23 RC lifecycle: allocation, root admission, custody and physical release"']
        for v in p['contract']:
            graph.append(json.dumps(v['fromNode']) + ' -> ' + json.dumps(v['toNode']) + ': ' + json.dumps(textwrap.fill(v['custody'], 40)))
        d2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _study_write_text(_science.ROOT / d2, '\n'.join(graph) + '\n')
        _science.context.command('d2-svg', ['d2', '--layout', 'elk', d2, d2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', '--layout', 'elk', d2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        checks = dict(languageBaseline='C23', qntActions=len(actions), qntHistories=7, qntSamples=500, qntMaxSteps=100, seedArgument=463, leanTheorems=len(lemmas), allStepInduction=True, genericBoundaryProof=True, allocationCohorts=1, maximumOperations=2, maximumStorageGenerations=2, typedIrControls=4, concreteCounterexamples=4, sourceAnchors=len(source), issuerRoles=len(p['issuer']), componentSourceActionRoutes=len(routes), ascentScenarios=len(results), blockers=gaps, actualCandidate=False, sysmlScope='self-contained native package; not whole DEV', arbitraryConcurrentIndexRefinement=False, c23RefinementProved=False, addressOnlyDiscriminationImpossible=True, realStorageIdIssuerQualified=False, completeRawCallerClosure=False, gcRootPayloadProductProved=False, replayRecordReclamationProved=False, nativePathsRetired=0, nativeTestsRun=False, runtimeImplementation=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/storage-index-transactions/input.json'
        parent_data = json.loads(parent.read_text())
        composition = parent_data['compositionInputs']
        assert all((_science.sha(_science.ROOT / f) == h for f, h in composition.items())), 'parent composition drift'
        paths = set((v[1] for v in source))
        paths |= {_science.BASE + _science.STEM + '-design.org', _science.BASE + _science.STEM + '-matrix.org', _science.BASE + 'index.org', _science.BASE + 'models/sysml/' + _science.STEM + '.sysml', _science.BASE + 'models/quint/rc_storage_lifecycle.qnt', d2, d2[:-3] + '.svg', 'dev/modeling/ascent/' + _science.STEM + '.rules.scm', _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.context.library_source((_science.STEM + '-projection.py').removesuffix('.py').replace('-', '_')), 'src/gambit_smp/scientific_chunk_capacity_charge_projection.py', '.cache/tasks/' + _science.STEM + '/config.json'}
        paths |= {_science.BASE + 'models/lean/' + n + '.lean' for n in ['RcStorageAst', 'RcStorageAllocation', 'RcStorageRootAdmission', 'RcStorageReferences', 'RcStoragePublication', 'RcStorageAccess', 'RcStorageCloseEntry', 'RcStorageRequestCleanup', 'RcStorageHandoffVM', 'RcStorageExitContext', 'RcStorageContextOwnership', 'RcStorageSettleEffects', 'RcStorageAbortPrivate', 'RcStorageUnpublish', 'RcStorageScanGrace', 'RcStorageStartFree', 'RcStorageWithdrawal', 'RcStorageCleanup', 'RcStorageFinishFree', 'RcStorageLoseFreeOutcome', 'RcStorageReuseAddress', 'RcStorageQueryOld', 'RcStorageRejectOldRelease', 'RcStorageReuse', 'RcStorage', 'RcStorageBoundary']}
        data = dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), parentPath=str(parent.relative_to(_science.ROOT)), parentInputSha256=_science.sha(parent), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(paths)}, compositionInputs=composition, literalCallerInputs=caller_inputs)
        assert all((_science.sha(_science.ROOT / f) == h for f, h in caller_inputs.items())), 'caller source drift'
        for k, f, h, n in source:
            assert _science.sha(_science.ROOT / f) == h, k
        _science.save(_study_workspace('CACHE') / 'input.json', data)

        def copy_receipts():
            for f in _study_workspace('CACHE').iterdir():
                if f.is_file() and f.suffix in ['.json', '.stdout', '.stderr']:
                    shutil.copyfile(f, _study_workspace('OUT') / f.name)
        copy_receipts()
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        for a, b in [('dev/architecture/toolchain/iter-compiler-service-design.org', _science.BASE + _science.STEM + '-design.org'), ('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.BASE + _science.STEM + '-matrix.org'), ('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')]:
            org = org.replace(a, b)
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org-check', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        assert all((_science.sha(_science.ROOT / f) == h for f, h in data['sourceBindings'].items())), 'input drift'
        data['logs'] = {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in ['.stdout', '.stderr']}
        _science.save(_study_workspace('CACHE') / 'input.json', data)
        copy_receipts()
        for d in list(_study_workspace('CACHE').glob('negative-*')) + list(_study_workspace('CACHE').glob('retained-*-failure')):
            if d.is_dir():
                shutil.copytree(d, _study_workspace('OUT') / d.name, dirs_exist_ok=True)
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').rglob('*') if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
