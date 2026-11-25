"""Design/formal orchestration; native SysML owns architecture metadata. No runtime execution."""
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
        _science.STEM = 'advantage-architecture'
        _science.PKG = 'GambitAdvantageArchitecture'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.QNT = _science.BASE + 'models/quint/advantage_architecture.qnt'
        _science.LEAN = _science.BASE + 'models/lean/AdvantageArchitecture.lean'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.GROUPS = [('owner', 9, 'module.moduleId module.ownerPath module.owns module.provides module.excludes'), ('decision', 6, 'decision.decisionId decision.owner.moduleId decision.replacement decision.retirement decision.interleaving.obligationId decision.interleaving.subjectPath decision.interleaving.subjectScope decision.induction.obligationId decision.induction.subjectPath decision.induction.subjectScope'), ('advantage', 4, 'key paper section basis frameDesign control gcSmp build refutation'), ('contract', 12, 'key seam.interfaceId seam.producerId seam.consumerId actionName guardName lemmaName sourcePath sourceNeedle premise retirement benefit added gap'), ('use', 23, 'advantage.key contract.key obligation'), ('benefit', 6, 'key avoided added condition evidence'), ('open', 7, 'key qualified subjectPath scope reason')]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2, ensure_ascii=False) + '\n')

    def project(_science):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PKG}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(5):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        field_expressions = []
        for *_, expr in keys:
            field_expressions.append(expr)
        files = sorted(_science.context.command('sysml-files', ['rg', '--files', 'dev', '-g', '*.sysml', '-g', '*.kerml'], policy=_science.process_profile).splitlines())
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files={f: _science.sha(_science.ROOT / f) for f in files}, excluded={}, scope='whole DEV native load'))
        native = _study_fields(_science.ROOT, None, 'advantage-architecture', field_expressions, ordered=True, models=['dev'])
        vals = native['orderedValues']
        assert len(keys) == len(vals)
        p = {}
        for (g, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(g, {}).setdefault(i, {})[f] = v
        for g, _, _ in _science.GROUPS:
            p[g] = list(p[g].values())
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return p

    def views(_science, p):
        lines = ['#+TITLE: Gambit Advantage Architecture — Benefit and Closure Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: advantage-architecture-matrix', ':AUTHORITY: GambitAdvantageArchitecture', ':STATUS: finite-protocols-pass; whole-source-and-platform-open', ':END:', '', 'Native SysML owns these rows; all modern-C responsibilities reference existing owners.']
        for group, _, schema in _science.GROUPS:
            fields = schema.split()
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fields)) + ' |' for v in p[group]]
        lines += ['', '** Exact scoped model subjects', '', '| id | kind | subject | scope |', '|---+---+---+---|']
        lines += ['| ' + ' | '.join((v[f] for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope'])) + ' |' for v in p['need'].values()]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: right', 'title: "Gambit modern C: one semantic contract across control, GC/SMP and builds"']
        for v in p['owner']:
            key = v['module.moduleId']
            graph.append(json.dumps(key) + ': ' + json.dumps(key + '\n' + textwrap.fill(v['module.provides'], 45)))
        seen = set()
        for v in p['contract']:
            edge = (v['seam.producerId'], v['seam.consumerId'], v['seam.interfaceId'])
            if edge not in seen:
                graph.append(json.dumps(edge[0]) + ' -> ' + json.dumps(edge[1]) + ': ' + json.dumps(edge[2]))
                seen.add(edge)
        graph += ['proof: "SysML -> ASCENT -> QNT / Lean\\nFinite / conditional checks; whole source and native OPEN"', '"build" -> proof']
        for i, v in enumerate(p['advantage']):
            graph += [f'idea{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['refutation'], 48)), f'idea{i} -> proof']
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def ascend(_science, p, witnesses):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        whole = []
        for v in p['decision']:
            for kind in ['interleaving', 'induction']:
                path = v['decision.' + kind + '.subjectPath']
                whole.append([v['decision.' + kind + '.obligationId'], path, _science.sha(_science.ROOT / path), v['decision.' + kind + '.subjectScope']])
        for v in p['dependency'].values():
            if v['prerequisite.obligationId'] not in [n[0] for n in needs]:
                path = v['prerequisite.subjectPath']
                whole.append([v['prerequisite.obligationId'], path, _science.sha(_science.ROOT / path), v['prerequisite.subjectScope']])
        assert len(whole) == 14 and len(set((x[0] for x in whole))) == 14
        owners = [[v['module.moduleId'], v['module.ownerPath']] for v in p['owner']]
        papers = [[v['key'], v['paper'], v['section']] for v in p['advantage']]
        uses = [[v['advantage.key'], v['contract.key'], v['obligation']] for v in p['use']]
        assert len(uses) == len(set((tuple(v) for v in uses)))
        contracts = [[v[k] for k in ['key', 'seam.interfaceId', 'seam.producerId', 'seam.consumerId', 'actionName', 'guardName', 'lemmaName', 'sourcePath']] + [_science.sha(_science.ROOT / v['sourcePath']), v['sourceNeedle']] for v in p['contract']]
        steps = [[v['actionName'], v['guardName'], v['lemmaName']] for v in p['contract']]
        queries = ['candidate', 'blocked', 'checked', 'route', 'ownerok', 'paperok', 'contractok', 'useok', 'wholeok']
        cases = ['current', 'stale-hash', 'wrong-scope', 'missing-contract', 'wrong-guard', 'wrong-source', 'missing-owner', 'missing-use', 'missing-whole', 'scope-widening', 'missing-paper', 'synthetic-all']
        engine = Engine()
        results = {}
        try:
            sess = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            assert sess.run(queries=queries)['complete']
            for case in cases:
                full = case != 'current'
                receipts = [[case, n, path, h, scope] for n, k, path, h, scope in needs if full or k in ['interleaving', 'induction']]
                if case == 'stale-hash':
                    receipts = [v[:3] + ['stale'] + v[4:] if v[1] == 'AA-H' else v for v in receipts]
                if case == 'wrong-scope':
                    receipts = [v[:4] + ['wider-scope'] if v[1] == 'AA-I' else v for v in receipts]
                wholereceipts = [[case] + v for i, v in enumerate(whole) if full and (not (case == 'missing-whole' and i == 0))]
                if case == 'scope-widening':
                    wholereceipts = [v[:4] + ['local-fragment-only'] if i == 0 else v for i, v in enumerate(wholereceipts)]
                cb = [v.copy() for i, v in enumerate(contracts) if not (case == 'missing-contract' and i == 0)]
                if case == 'wrong-guard':
                    cb[0][5] = 'wrong-guard'
                if case == 'wrong-source':
                    cb[0][8] = 'wrong-source-digest'
                sess.replace(dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source-audit'], ['environment-refinement', 'platform']], receipt=receipts, gate=[[case, v['key'], str(full).lower()] for v in p['open']], ownerneed=owners, ownerbinding=[v for i, v in enumerate(owners) if not (case == 'missing-owner' and i == 0)], contractneed=contracts, contractbinding=cb, modelstep=steps, sourcewitness=[[v['path'], v['sha256'], v['needle']] for v in witnesses], paperneed=papers, paperbinding=[v for i, v in enumerate(papers) if not (case == 'missing-paper' and i == 0)], useneed=uses, usebinding=[v for i, v in enumerate(uses) if not (case == 'missing-use' and i == 0)], wholeneed=whole, wholereceipt=wholereceipts))
                res = sess.run(queries=queries)
                assert res['complete']
                results[case] = res['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', dict(results=results, whole=whole))
            assert len(results['current']['checked']) == 2 and len(results['current']['route']) == 4
            assert len(results['current']['contractok']) == 12 and len(results['current']['useok']) == 23
            assert len(results['current']['ownerok']) == 9 and len(results['current']['paperok']) == 4
            assert len(results['missing-use']['useok']) == 22
            assert len(results['scope-widening']['wholeok']) == 13 and len(results['missing-whole']['wholeok']) == 13
            assert not results['current']['wholeok']
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, wholeRequired=whole, syntheticIsNotRealEvidence=True, repositoryRegistered=False, nativeAdmitted=False))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parents = ['.cache/research/legacy-evidence/evidence/research/marker-alias-revocation/input.json', '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/input.json']
        parenthash = {f: _science.sha(_science.ROOT / f) for f in parents}
        frozen = {}
        for f in parents:
            old = json.loads((_science.ROOT / f).read_text()).get('sourceBindings', {})
            frozen[f] = [dict(path=k, oldSha256=h, currentSha256=_science.sha(_science.ROOT / k)) for k, h in old.items() if _science.sha(_science.ROOT / k) != h]
        _science.save(_study_workspace('CACHE') / 'parent-drift.json', dict(parents=parenthash, drift=frozen, inheritedSourceQualified=False, parentsNeverRewritten=True))
        p = _science.project()
        _science.views(p)
        q = (_science.ROOT / _science.QNT).read_text()
        l = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in l and 'axiom ' not in l
        witnesses = []
        for v in p['contract']:
            path = v['sourcePath']
            text = (_science.ROOT / path).read_text()
            needle = v['sourceNeedle']
            assert needle in text, (v['key'], path, needle)
            action = re.search('action\\s+' + v['actionName'] + '(?:\\([^\\n]*?\\))?=all\\{(.*?)(?=\\n action|\\n run|\\n})', q, re.S)
            assert action and v['guardName'] in action.group(1).split("s'=", 1)[0], v['key']
            assert 'theorem ' + v['lemmaName'] + ' ' in l, v['key']
            witnesses.append(dict(key=v['key'], path=path, sha256=_science.sha(_science.ROOT / path), needle=needle, line=text[:text.index(needle)].count('\n') + 1, action=v['actionName'], guard=v['guardName'], lemma=v['lemmaName'], sourceSimulationProved=False))
        _science.save(_study_workspace('CACHE') / 'source-contract-witnesses.json', witnesses)
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 23 and tests.count('ControlTest passed') == 11, tests
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '300', '--max-steps', '160', '--seed', '23', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascend(p, witnesses)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(status='pending-final-receipt', runtimeAdmitted=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text()
        org = org.replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        sources = {v['sourcePath'] for v in p['contract']}
        sources.update(['vendor/gambit/gsc/_back.scm', 'vendor/gambit/gsc/_t-c-2.scm', 'vendor/gambit/gsc/_t-c-3.scm', 'vendor/gambit/lib/gambit/list/list.scm', 'vendor/gambit/lib/_std.c', 'vendor/gambit/lib/_io.scm', '../gerbil-gambit-bootstrap-audit/src/std/make.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/macros.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter/api.ss', '../gerbil-gambit-bootstrap-audit/src/std/iter.ss', '../gerbil-gambit-bootstrap-audit/src/std/string/misc.ss', '../gerbil-gambit-bootstrap-audit/src/std/sync/wg.ss'])
        sources.update([_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.QNT, _science.LEAN, _science.RULES, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.BASE + 'index.org', _science.BASE + 'modernization-target.org', _science.BASE + 'map-multishot-composition.org', _science.BASE + 'models/sysml/modernization-target.sysml', _science.BASE + 'models/sysml/map-multishot-composition.sysml', 'dev/architecture/runtime/models/sysml/composition.sysml', 'dev/architecture/toolchain/models/sysml/iter-compiler-service.sysml', 'dev/architecture/toolchain/models/sysml/marker-alias-revocation.sysml'])
        for v in p['decision']:
            sources.update([v['decision.interleaving.subjectPath'], v['decision.induction.subjectPath']])
        for f, h in parenthash.items():
            assert _science.sha(_science.ROOT / f) == h, f
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['path']) == v['sha256'], v['path']
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, h in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == h, f
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), sysmlExcluded=0, canonicalOwners=9, canonicalInterfaces=9, existingDecisions=6, advantages=4, advantageUses=23, sourceContractBindings=12, benefitRows=6, qntHistories=23, negativeControls=11, sampledRuns=300, maxSteps=160, leanTheorems=len(re.findall('^theorem ', l, re.M)), ascentScenarios=12, wholeCompositionRequiredScopes=14, wholeCompositionQualifiedScopes=0, openScopes=7, fullQntLeanSimulation=False, sourceSimulation=False, c11Refinement=False, nativeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(sources)}, parentInputs=parenthash, parentDrift=frozen, inheritedSourceQualified=False, logs={str(x.relative_to(_science.ROOT)): _science.sha(x) for x in _study_workspace('CACHE').iterdir() if x.suffix in {'.stdout', '.stderr'}}))
        for x in _study_workspace('CACHE').iterdir():
            if x.is_file() and x.suffix in {'.json', '.el'}:
                _study_write_bytes(_study_workspace('OUT') / x.name, x.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(x.relative_to(_science.ROOT)): _science.sha(x) for x in _study_workspace('OUT').iterdir() if x.is_file() and x.name != 'artifacts.json'})
        print(json.dumps(checks))

# Preserved scientific source notes (in original order).
# Cross-module diagram uses only canonical interface endpoints and native model rows.
