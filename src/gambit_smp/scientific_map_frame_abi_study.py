"""Research/formal orchestration only. Native SysML remains canonical metadata."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import json, re, textwrap

class ScientificLibrary:

    def __init__(_science, context):
        _science.context = context
        _science._study_fields = _study_fields
        _science._study_workspace = _study_workspace
        _science._study_write_bytes = _study_write_bytes
        _science._study_write_text = _study_write_text
        _science.json = json
        _science.re = re
        _science.textwrap = textwrap
        _science.ROOT = _science.context.root
        _science.STEM = 'map-frame-abi'
        _science.PKG = 'GambitMapFrameAbi'
        _science.BASE = 'dev/refactoring/modern-c/'
        _science.MODEL = _science.BASE + 'models/sysml/' + _science.STEM + '.sysml'
        _science.DESIGN = _science.BASE + _science.STEM + '-design.org'
        _science.MATRIX = _science.BASE + _science.STEM + '-matrix.org'
        _science.QNT = _science.BASE + 'models/quint/map_frame_abi.qnt'
        _science.LEAN = _science.BASE + 'models/lean/MapFrameAbi.lean'
        _science.D2 = _science.BASE + 'diagrams/' + _science.STEM + '.d2'
        _science.RULES = 'dev/modeling/ascent/' + _science.STEM + '.rules.scm'
        _science.HELPER = 'src/gambit_smp/scientific_advantage_architecture_study.py'
        _science.h = _science.context.library('advantage_architecture_study')
        _science.sha = _science.h.sha
        _science.save = _science.h.save
        _science.GROUPS = [('owner', 9, 'moduleId ownerPath owns'), ('source', 11, 'key sourcePath sourceNeedle consumer obligation actionName guardName lemmaName boundary'), ('witness', 2, 'key sourcePath labelIndex storedFs linkSlot mask liveSlots useSite'), ('impact', 5, 'key trigger semantic native runtime retirement'), ('refine', 8, 'key qualified lemma premise gap'), ('gain', 4, 'key avoided added condition'), ('gate', 7, 'key qualified duty'), ('field', 20, 'qntField leanField representation'), ('event', 11, 'actionName guardName lemmaName')]
        _science.process_profile = _science.h.process_profile

    def project(_science, projection_run=None):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PKG}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PKG}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PKG}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId', 'prerequisite.subjectPath', 'prerequisite.subjectScope']]
        p, scope = _study_fields(_science.ROOT, projection_run, 'map-frame-abi', keys)
        _science.save(_study_workspace('CACHE') / 'sysml-input-scope.json', dict(files=scope, excluded={}))
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        return p

    def views(_science, p):
        lines = ['#+TITLE: Real map FrameSpec, ABI and Refinement Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+LANGUAGE: en', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: map-frame-abi-matrix', ':AUTHORITY: GambitMapFrameAbi', ':STATUS: stored-source; mirror-laws-checked; QNT-encoding-and-source-open', ':END:']
        for g, _, schema in _science.GROUPS:
            fields = schema.split()
            lines += ['', '** ' + g.capitalize(), '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fields)) + ' |' for v in p[g]]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')
        graph = ['direction: down', 'title: "map FrameSpec: source consumers, old-cohort lifetime and build impact"']
        for i, v in enumerate(p['source']):
            graph += [f's{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['obligation'], 55))]
        for a, b in [(0, 1), (1, 2), (2, 3), (3, 4), (3, 5), (3, 7), (5, 6), (6, 4), (7, 10), (2, 8), (8, 7), (9, 4), (9, 5)]:
            graph.append(f's{a} -> s{b}')
        graph += ['proof: "SysML -> ASCENT -> QNT / Lean\\nFlat/nested mirror simulation: proved\\nQNT encoding + source + C11/native: OPEN"', 's4 -> proof', 's7 -> proof', 's8 -> proof']
        for i, v in enumerate(p['impact']):
            graph += [f'abi{i}: ' + json.dumps(v['key'] + '\n' + textwrap.fill(v['retirement'], 48)), f's8 -> abi{i}']
        _study_write_text(_science.ROOT / _science.D2, '\n'.join(graph) + '\n')

    def ascend(_science, p, witnesses):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        ext = [v for v in p['dependency'].values() if v['prerequisite.obligationId'] == 'AA-S'][0]
        parent = [[ext['prerequisite.obligationId'], ext['prerequisite.subjectPath'], _science.sha(_science.ROOT / ext['prerequisite.subjectPath']), ext['prerequisite.subjectScope']]]
        rows = [[v['key'], v['sourcePath'], _science.sha(_science.ROOT / v['sourcePath']), v['sourceNeedle'], v['actionName'], v['guardName'], v['lemmaName']] for v in p['source']]
        steps = [[v['actionName'], v['guardName'], v['lemmaName']] for v in p['event']]
        refs = [[v['key'], v['lemma']] for v in p['refine']]
        cases = ['current', 'stale-digest', 'wrong-scope', 'missing-source', 'wrong-guard', 'missing-parent', 'widened-mirror', 'missing-refinement', 'synthetic-all']
        engine = _science.h.Engine()
        results = {}
        try:
            session = engine.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['route', 'checked', 'blocked', 'candidate', 'sourceok', 'refineok', 'externalok']
            assert session.run(queries=queries)['complete']
            for case in cases:
                full = case != 'current'
                receipts = [[case, n, path, digest, scope] for n, k, path, digest, scope in needs if full or k in ['interleaving', 'induction']]
                if case == 'stale-digest':
                    receipts = [r[:3] + ['stale'] + r[4:] if r[1] == 'MF-H' else r for r in receipts]
                if case == 'wrong-scope':
                    receipts = [r[:4] + ['wrong-scope'] if r[1] == 'MF-I' else r for r in receipts]
                bindings = [v.copy() for i, v in enumerate(rows) if not (case == 'missing-source' and i == 0)]
                if case == 'wrong-guard':
                    bindings[0][5] = 'wrong-guard'
                rr = [[case, v['key'], v['lemma']] for v in p['refine'] if (full or v['qualified']) and (not (case == 'missing-refinement' and v['key'] == 'steps'))]
                if case == 'widened-mirror':
                    rr = [r[:2] + ['forwardSimulation'] if r[1] == 'qnt-encoding' else r for r in rr]
                session.replace(dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source'], ['environment-refinement', 'platform']], receipt=receipts, gate=[[case, v['key'], str(full).lower()] for v in p['gate']], sourceneed=rows, sourcebinding=bindings, modelstep=steps, refinement=refs, refined=rr, externalneed=parent, externalreceipt=[[case] + v for v in parent if full and case != 'missing-parent']))
                result = session.run(queries=queries)
                assert result['complete']
                results[case] = result['relations']
            _science.save(_study_workspace('CACHE') / 'ascent-attempt-results.json', results)
            assert len(results['current']['checked']) == 2 and len(results['current']['sourceok']) == 11
            assert len(results['current']['refineok']) == 6 and len(results['widened-mirror']['refineok']) == 7
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            engine.close()
        _science.save(_study_workspace('CACHE') / 'ascent-results.json', dict(results=results, syntheticIsNotRealReceipt=True, mirrorProofIsNotQntEncoding=True, repositoryRegistered=False))

    def analyze(_science, projection_run=None):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/advantage-architecture/input.json'
        parenthash = _science.sha(parent)
        old = json.loads(parent.read_text())['sourceBindings']
        drift = [dict(path=f, oldSha256=d, currentSha256=_science.sha(_science.ROOT / f)) for f, d in old.items() if _science.sha(_science.ROOT / f) != d]
        _science.save(_study_workspace('CACHE') / 'parent-drift.json', dict(drift=drift, parentFrozen=True, inheritedSourceQualified=False))
        p = _science.project(projection_run)
        _science.views(p)
        q = (_science.ROOT / _science.QNT).read_text()
        l = (_science.ROOT / _science.LEAN).read_text()
        assert 'sorry' not in l and 'axiom ' not in l
        witnesses = []
        for v in p['source']:
            text = (_science.ROOT / v['sourcePath']).read_text()
            assert v['sourceNeedle'] in text, v['key']
            witnesses.append(dict(key=v['key'], path=v['sourcePath'], sha256=_science.sha(_science.ROOT / v['sourcePath']), needle=v['sourceNeedle'], line=text[:text.index(v['sourceNeedle'])].count('\n') + 1))
        for v in p['event']:
            match = re.search('action ' + v['actionName'] + '=all\\{(.*?)(?=\\n action|\\n run|\\n})', q, re.S)
            assert match and v['guardName'] in match.group(1).split("s'=", 1)[0], v
            assert 'theorem ' + v['lemmaName'] + ' ' in l
        for v in p['refine']:
            if v['qualified']:
                assert 'theorem ' + v['lemma'] + ' ' in l
        _science.save(_study_workspace('CACHE') / 'source-witnesses.json', witnesses)
        c = (_science.ROOT / 'vendor/gambit/lib/_std.c').read_text()
        block = c.split(',___DEF_LBL_INTRO(___H_map,', 1)[1].split(',___DEF_LBL_INTRO', 1)[0]
        rows = re.findall('DEF_LBL_RET\\(___H_map,___IFD\\((___RET[INT]),(\\d+),(\\d+),(0x[0-9a-f]+)L\\)\\)', block)
        assert len(rows) == 22
        for v in p['witness']:
            kind, fs, link, mask = rows[v['labelIndex'] - 1]
            assert kind == '___RETN' and int(fs) == v['storedFs'] and (int(link) == v['linkSlot']) and (int(mask, 16) == v['mask']), v
        _science.save(_study_workspace('CACHE') / 'stored-map-descriptors.json', dict(rows=rows, normalWitnesses=p['witness'], currentGeneratedProvenance=False, matchedNativeObject=False))
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 12 and tests.count('ControlTest passed') == 6
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '300', '--max-steps', '160', '--seed', '29', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascend(p, witnesses)
        _science.context.command('d2-svg', ['d2', _science.D2, _science.D2[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.D2, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        _science.save(_study_workspace('OUT') / 'checks.json', dict(status='pending', nativeAdmitted=False))
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('dev/architecture/toolchain/iter-compiler-service-design.org', _science.DESIGN).replace('dev/architecture/toolchain/iter-compiler-service-matrix.org', _science.MATRIX).replace('dev/architecture/toolchain/index.org', _science.BASE + 'index.org')
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        files = {v['sourcePath'] for v in p['source']} | {_science.MODEL, _science.DESIGN, _science.MATRIX, _science.D2, _science.D2[:-3] + '.svg', _science.QNT, _science.LEAN, _science.RULES, _science.HELPER, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_')), _science.BASE + 'index.org', _science.BASE + 'advantage-architecture-design.org', _science.BASE + 'models/sysml/advantage-architecture.sysml', 'dev/architecture/runtime/models/sysml/composition.sysml', 'vendor/gambit/lib/gambit/list/list.scm', 'vendor/gambit/gsc/_front.scm', 'vendor/gambit/gsc/_back.scm', 'vendor/gambit/lib/_kernel.scm'}
        assert _science.sha(parent) == parenthash
        for v in witnesses:
            assert _science.sha(_science.ROOT / v['path']) == v['sha256']
        scope = json.loads((_study_workspace('CACHE') / 'sysml-input-scope.json').read_text())
        for f, d in scope['files'].items():
            assert _science.sha(_science.ROOT / f) == d, f
        checks = dict(status='conditional-local-models-pass', wholeDevSysmlInputs=len(scope['files']), excluded=0, sourceLinks=11, storedReturnDescriptors=22, normalWitnesses=2, stateFieldMappings=20, namedActions=11, leanEventCases=12, qntHistories=12, negativeControls=6, sampledRuns=300, maxSteps=160, leanTheorems=len(re.findall('^theorem ', l, re.M)), ascentScenarios=9, mirrorRefinementScopes=6, openLargerRefinementScopes=2, openSourcePlatformGates=7, fullQntLeanEncoding=False, sourceSimulation=False, c11Refinement=False, parentSourceQualified=False, nativeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False, hostRegistration='inherited unresolved; not retried')
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(head=_science.context.command('head', ['git', 'rev-parse', 'HEAD'], policy=_science.process_profile).strip(), branch=_science.context.command('branch', ['git', 'branch', '--show-current'], policy=_science.process_profile).strip(), sourceBindings={f: _science.sha(_science.ROOT / f) for f in sorted(files)}, parentInput=str(parent.relative_to(_science.ROOT)), parentInputSha256=parenthash, parentFrozen=True, parentDrift=drift, inheritedSourceQualified=False, logs={str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('CACHE').iterdir() if f.suffix in {'.stdout', '.stderr'}}))
        for f in _study_workspace('CACHE').iterdir():
            if f.is_file() and f.suffix in {'.json', '.el'}:
                _study_write_bytes(_study_workspace('OUT') / f.name, f.read_bytes())
        _science.save(_study_workspace('OUT') / 'artifacts.json', {str(f.relative_to(_science.ROOT)): _science.sha(f) for f in _study_workspace('OUT').iterdir() if f.is_file() and f.name != 'artifacts.json'})
        print(json.dumps(checks))
