"""Design/model orchestration only; native SysML is canonical. No native runtime tests."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import hashlib, json, re, textwrap
from pathlib import Path
from ascent import Engine

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.hashlib = hashlib
        _science.json = json
        _science.re = re
        _science.textwrap = textwrap
        _science.Path = Path
        _science.Engine = Engine
        _science.ROOT = _science.context.root
        _science.STEM = 'foreign-cleanup-closure'
        _science.PACKAGE = 'ForeignCleanupClosure'
        _science.BASE = 'dev/architecture/toolchain/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.DIAGRAM = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.QNT = 'models/build/foreign_cleanup_closure.qnt'
        _science.LEAN = 'models/build/ForeignCleanupClosure.lean'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.GROUPS = [('contract', 8, 'key anchor actionName lemmaName duty status'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified duty')]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2, ensure_ascii=False) + '\n')

    def project(_science):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PACKAGE}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for i in range(10):
            keys += [('edge', str(i), f, f'{_science.PACKAGE}::edge{i}.{f}') for f in ['dependent.key', 'prerequisite.key', 'reason']]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PACKAGE}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PACKAGE}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId']]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        native = _study_fields(_science.ROOT, None, 'foreign-cleanup-closure', field_expressions, ordered=True, models=['dev'])
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
        lines = ['#+TITLE: Foreign Cleanup Closure — Benefit and Admission Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: foreign-cleanup-closure-matrix', ':AUTHORITY: ForeignCleanupClosure', ':STATUS: conditional-models-source-open', ':END:', '', 'Derived by native SysML queries. Benefits are conditional work/capacity bounds, not timings.']
        for group, _, schema in _science.GROUPS:
            fields = schema.split()
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fields)) + ' |' for v in p[group]]
        lines += ['', '** Shared-contract dependencies', '', '| dependent | prerequisite | obligation |', '|---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['dependent.key', 'prerequisite.key', 'reason'])) + ' |' for v in p['edge'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down']
        for v in p['contract']:
            graph.append(json.dumps(v['key']) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['duty'], 52)))
        for edge in p['edge'].values():
            graph.append(json.dumps(edge['prerequisite.key']) + ' -> ' + json.dumps(edge['dependent.key']) + ': ' + json.dumps(textwrap.fill(edge['reason'], 32)))
        graph += ['proof: "SysML -> ASCENT -> QNT / Lean; source + platform OPEN"', '"vm-permit" -> proof']
        for i, v in enumerate(p['gain']):
            graph += [f'gain{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['condition'], 55)), f'proof -> gain{i}']
        _study_write_text(_science.ROOT / _science.DIAGRAM, '\n'.join(graph) + '\n')

    def ascend(_science, p, prior):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        deps = [[v['dependent.obligationId'], v['prerequisite.obligationId']] for v in p['dependency'].values()]
        contracts = p['contract']
        queries = ['checked', 'missing', 'route', 'blocked', 'candidate', 'aligned', 'prioraligned', 'componentmapped', 'edgealigned']
        engine = Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert session.run(queries=queries)['complete']
            for case in ['current', 'stale-subject', 'wrong-scope', 'missing-step', 'missing-component', 'missing-prior', 'parent-open', 'synthetic-all']:
                full = case not in ['current', 'stale-subject', 'wrong-scope']
                receipts = [[case, n, path, h, scope] for n, k, path, h, scope in needs if full or k in ['interleaving', 'induction']]
                if case == 'stale-subject':
                    receipts = [x[:3] + ['stale'] + x[4:] if x[1] == 'FCC-H' else x for x in receipts]
                if case == 'wrong-scope':
                    receipts = [x[:4] + ['wrong'] if x[1] == 'FCC-I' else x for x in receipts]
                steps = [[v['actionName'], v['lemmaName']] for v in contracts if not (case == 'missing-step' and v['key'] == 'derived-credit')]
                components = [[v['key'], v['anchor'], v['actionName'], v['lemmaName']] for v in contracts]
                priorrows = [[v['key'], v['path'], v['sha256'], v['invariant'], v['action'], v['lemma']] for v in prior]
                session.replace(dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source-audit'], ['environment-refinement', 'platform']], receipt=receipts, dependency=deps, external=[[case, 'SGC-S', str(full and case != 'parent-open').lower()]], gate=[[case, v['key'], str(full).lower()] for v in p['gate']], anchor=[[v['key'], v['anchor']] for v in contracts], binding=[[v['key'], v['actionName'], v['lemmaName'], v['anchor']] for v in contracts], modelstep=steps, component=components, componentbinding=[v for v in components if not (case == 'missing-component' and v[0] == 'storage-commit')], componentedge=[[v['dependent.key'], v['prerequisite.key'], v['reason']] for v in p['edge'].values()], prior=priorrows, priorbinding=[v for v in priorrows if not (case == 'missing-prior' and v[0] == 'old-roster')]))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            assert len(results['current']['checked']) == 2
            assert len(results['current']['aligned']) == 8 and len(results['current']['componentmapped']) == 8
            assert len(results['current']['prioraligned']) == 4
            assert len(results['current']['edgealigned']) == 10
            assert len(results['missing-component']['edgealigned']) < 10
            assert len(results['missing-step']['aligned']) == 7
            assert len(results['missing-component']['componentmapped']) == 7
            assert len(results['missing-prior']['prioraligned']) == 3
            for k in ['stale-subject', 'wrong-scope']:
                assert len(results[k]['checked']) == 1
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-model-results.json', dict(results=results, repositoryRegistered=False, hostAttested=False, syntheticNotRealReceipt=True))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/syncop-guard-custody/input.json'
        parenthash = _science.sha(parent)
        bindings = json.loads(parent.read_text())['sourceBindings']
        assert all((_science.sha(_science.ROOT / path) == h for path, h in bindings.items())), 'Frozen parent drift'
        p = _science.project()
        _science.views(p)
        q = (_science.ROOT / _science.QNT).read_text()
        l = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in l and 'axiom ' not in l
        for v in p['contract']:
            assert re.search('action\\s+' + v['actionName'] + '(?:\\(|=)', q)
            assert 'theorem ' + v['lemmaName'] + ' ' in l
        prior = []
        for key, path, inv, action, lemma in [('old-roster', 'models/build/syncop_guard_custody.qnt', 'safe', 'exitOwner', 'affinityBlocksExit'), ('release-right', 'models/gambit/release_producer_admission.qnt', 'safe', 'captureRoot', 'captureConserves'), ('still-authority', 'models/gambit/still_authority_handoff.qnt', 'safe', 'commitLost', 'commitPreservesScanner'), ('work-closure', 'models/gambit/gc_work_closure.qnt', 'terminationSafe', 'reserveChild', 'reserveConserves')]:
            assert re.search('(?:val|def)\\s+' + inv + '\\s*=', (_science.ROOT / path).read_text())
            prior.append(dict(key=key, path=path, invariant=inv, action=action, lemma=lemma, sha256=_science.sha(_science.ROOT / path), productSimulationProved=False, rerun=False))
        _science.save(_study_workspace('CACHE') / 'prior-model-alignment.json', prior)
        sources = ['vendor/gambit/lib/' + f for f in ['mem.c', 'c_intf.c', 'os_io.c', 'setup.c']] + ['vendor/gambit/doc/gambit.txi', 'vendor/gambit/examples/tcltk/tcltk.scm']
        counts = {}
        for name, pattern, path in [('hook-installations', '___device_cleanup_from_ptr', 'vendor/gambit/lib/os_io.c'), ('release-origins', 'release_fn \\(x\\)|___release_foreign|cleanup_rc|free_still_objs|free_unmarked_still_objs', 'vendor/gambit/lib'), ('device-effects', '___device_cleanup \\(|___device_release \\(|___device_select \\(|___device_remove_from_group \\(', 'vendor/gambit/lib/os_io.c')]:
            raw = _science.context.command(name, ['rg', '--json', '-g', '*.c', pattern, path], policy=_science.process_profile)
            matches = [json.loads(x)['data'] for x in raw.splitlines() if json.loads(x)['type'] == 'match']
            _science.save(_study_workspace('CACHE') / (name + '-census.json'), dict(matches=matches, scope=path, qualification='syntactic source witnesses; conditional branches and exported aliases not qualified'))
            counts[name] = len(matches)
        mem = (_science.ROOT / sources[0]).read_text()
        cint = (_science.ROOT / sources[1]).read_text()
        io = (_science.ROOT / sources[2]).read_text()
        release = cint[cint.index('___EXP_FUNC(___SCMOBJ,___release_foreign)'):cint.index('return ___FIX(___NO_ERR);', cint.index('___EXP_FUNC(___SCMOBJ,___release_foreign)'))]
        assert release.index('___FOREIGN_RELEASE_FN_FIELD(obj) =') < release.index('release_fn (ptr)')
        dev = io[io.index('___SCMOBJ ___device_cleanup\n'):io.index('___SCMOBJ ___device_cleanup_from_ptr')]
        assert dev.index('___device_remove_from_group') < dev.index('___DIRECTION_RD') < dev.index('___DIRECTION_WR') < dev.index('return ___device_release')
        native = io[io.index('___SCMOBJ ___device_release\n'):io.index('___SCMOBJ ___device_cleanup\n')]
        assert native.index('___device_release_virt') < native.index('___FREE_MEM(self)')
        cleanup = mem[mem.index('___HIDDEN void cleanup_rc'):mem.index('___EXP_FUNC(void*,___alloc_rc_no_register)')]
        assert 'refcount' not in cleanup and '___FREE_MEM(h);' in cleanup
        _science.save(_study_workspace('CACHE') / 'source-facts.json', dict(wrapperClearedBeforeHook=True, deviceDetachedBeforeDirectionalClose=True, nativeSelfFreedAfterVirtualErrorPossible=True, bulkRcIgnoresRefcount=True, counts=counts, effectClosure=False, actualDarwinProfileQualified=False, proposedProtocolImplemented=False))
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 24 and tests.count('ControlTest passed') == 12
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '200', '--max-steps', '80', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascend(p, prior)
        _science.context.command('d2-svg', ['d2', _science.DIAGRAM, _science.DIAGRAM[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.DIAGRAM, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(status='pending-local-checks', runtimeAdmitted=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('iter-compiler-service-design.org', _science.STEM + '-design.org').replace('iter-compiler-service-matrix.org', _science.STEM + '-matrix.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        for path in sources + [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.DIAGRAM, _science.DIAGRAM[:-3] + '.svg', _science.QNT, _science.LEAN, _science.RULES, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_'))] + [v['path'] for v in prior]:
            bindings[path] = _science.sha(_science.ROOT / path)
        assert _science.sha(parent) == parenthash
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, parentInputSha256=parenthash, parentFrozen=True, head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), dirtySourceIdentity='per-file SHA256', logs={str(p.relative_to(_science.ROOT)): _science.sha(p) for p in _study_workspace('CACHE').iterdir() if p.suffix in {'.stdout', '.stderr'}}))
        checks = dict(status='conditional-local-models-pass', qntHistories=24, negativeControls=12, sampledRuns=200, maxSteps=80, leanTheorems=len(re.findall('^theorem ', l, re.M)), ascentCases=8, componentBindings=8, contractDependencies=10, priorBindings=4, gatesOpen=7, sourceSimulation='open', cMemoryOrder='open', hostRegistration='inherited unresolved; not retried', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for path in _study_workspace('CACHE').iterdir():
            if path.is_file() and path.suffix in {'.json', '.el'}:
                _study_write_bytes(_study_workspace('OUT') / path.name, path.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(p.relative_to(_science.ROOT)): _science.sha(p) for p in _study_workspace('OUT').iterdir() if p.is_file() and p.name != 'artifacts.json'})
        print(json.dumps(checks))
