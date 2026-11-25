"""Native-model research orchestration; no compiler/runtime implementation."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_bytes as _study_write_bytes, write_text as _study_write_text
import hashlib
import json
import textwrap
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
        _science.textwrap = textwrap
        _science.Path = Path
        _science.Engine = Engine
        _science.ROOT = _science.context.root
        _science.STEM = 'alias-workspace-reconstruction'
        _science.PACKAGE = 'AliasWorkspaceReconstruction'
        _science.MODEL = f'dev/architecture/toolchain/models/sysml/{_science.STEM}.sysml'
        _science.DESIGN = f'dev/architecture/toolchain/{_science.STEM}-design.org'
        _science.MATRIX = f'dev/architecture/toolchain/{_science.STEM}-matrix.org'
        _science.DIAGRAM = f'dev/architecture/toolchain/diagrams/{_science.STEM}.d2'
        _science.RULES = f'dev/modeling/ascent/{_science.STEM}.rules.scm'
        _science.QNT = 'models/build/alias_workspace_reconstruction.qnt'
        _science.LEAN = 'models/build/AliasWorkspaceReconstruction.lean'
        _science.PARAM = 'models/build/alias_workspace_parameters.qnt'
        _science.GROUPS = [('provider', 8, 'key captured semantics anchor'), ('alias', 6, 'key anchor path rebuild gap'), ('phase', 6, 'key precondition actionContract failureCustody'), ('fidelity', 4, 'key baseline reconstruction unresolved'), ('gain', 4, 'key removed added positiveCondition'), ('refinement', 4, 'key qntScope leanScope sourceDuty'), ('gate', 7, 'key qualified condition')]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, p):
        return hashlib.sha256(Path(p).read_bytes()).hexdigest()

    def save(_science, p, v):
        _study_write_text(Path(p), json.dumps(v, indent=2, ensure_ascii=False) + '\n')

    def project(_science):
        keys = []
        for group, count, schema in _science.GROUPS:
            keys += [(group, str(i), f, f'{_science.PACKAGE}::{group}{i}.{f}') for i in range(count) for f in schema.split()]
        for key in ['workspaceCount', 'actualAdmitted']:
            keys.append(('scalar', '', key, f'{_science.PACKAGE}::{key}'))
        for slot in ['history', 'induction', 'source', 'platform']:
            keys += [('need', slot, f, f'{_science.PACKAGE}::{slot}.{f}') for f in ['obligationId', 'kind', 'subjectPath', 'subjectScope', 'owner.componentId']]
        for i in range(4):
            keys += [('dependency', str(i), f, f'{_science.PACKAGE}::dependency{i}.{f}') for f in ['dependent.obligationId', 'prerequisite.obligationId']]
        field_expressions = []
        for _, _, _, expr in keys:
            field_expressions.append(expr)
        native = _study_fields(_science.ROOT, None, 'alias-workspace-reconstruction', field_expressions, ordered=True, models=['dev'])
        vals = native['orderedValues']
        assert len(vals) == len(keys)
        p = {}
        for (group, i, f, _), v in zip(keys, vals, strict=True):
            p.setdefault(group, {}).setdefault(i, {})[f] = v
        for group, _, _ in _science.GROUPS:
            p[group] = list(p[group].values())
        _science.save(_study_workspace('CACHE') / 'native-queries.json', keys)
        _science.save(_study_workspace('CACHE') / 'projection.json', p)
        return (p, native)

    def views(_science, p):
        _study_write_text(_science.ROOT / _science.PARAM, '// Native SysML projection.\nmodule alias_workspace_parameters {\n pure val WorkspaceCount = ' + str(p['scalar']['']['workspaceCount']) + '\n}\n')
        lines = ['#+TITLE: Alias Closure and Workspace Reconstruction Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Canonical native SysML projection', ':PROPERTIES:', ':CUSTOM_ID: alias-workspace-matrix', ':AUTHORITY: AliasWorkspaceReconstruction', ':STATUS: conditional-models-source-open', ':END:', '', 'Local formal checks are separate from host registration and native/source qualification.']
        graph = ['direction: down']
        for group in ['alias', 'phase', 'fidelity', 'gain']:
            graph += [group + ': ' + json.dumps(group.capitalize() + ' / native SysML contracts') + ' {', ' grid-columns: 2']
            for i, v in enumerate(p[group]):
                text = v['path'] if group == 'alias' else v['actionContract'] if group == 'phase' else v['reconstruction'] if group == 'fidelity' else v['positiveCondition']
                graph += [' n' + str(i) + ': ' + json.dumps(v['key'] + '\n' + textwrap.fill(text, 52))]
            graph += ['}']
        graph += ['provider: ' + json.dumps('Scheme-generated qualified recipe families\n' + textwrap.fill(', '.join((v['key'] for v in p['provider'])), 58)), 'proof: "SysML AR-H/I/S/E -> local ASCENT -> QNT / Lean; source, host registration, native gates OPEN"', 'alias -> provider', 'provider -> phase', 'phase -> fidelity', 'fidelity -> proof', 'proof -> gain']
        _study_write_text(_science.ROOT / _science.DIAGRAM, '\n'.join(graph) + '\n')
        for group, _, schema in _science.GROUPS:
            fs = schema.split()
            lines += ['', '** ' + group.capitalize(), '', '| ' + ' | '.join(fs) + ' |', '|' + '+'.join(('---' for _ in fs)) + '|']
            lines += ['| ' + ' | '.join((str(v[f]) for f in fs)) + ' |' for v in p[group]]
        _study_write_text(_science.ROOT / _science.MATRIX, '\n'.join(lines) + '\n')

    def ascent(_science, p):
        needs = [[v['obligationId'], v['kind'], v['subjectPath'], _science.sha(_science.ROOT / v['subjectPath']), v['subjectScope']] for v in p['need'].values()]
        deps = [[v['dependent.obligationId'], v['prerequisite.obligationId']] for v in p['dependency'].values()]
        results = {}
        native = Engine()
        try:
            session = native.open_sources((_science.ROOT / _science.RULES).read_text())
            queries = ['checked', 'missing', 'route', 'blocked', 'candidate']
            assert session.run(queries=queries)['complete']
            for case in ['current', 'missing-qnt', 'stale-subject', 'wrong-scope', 'synthetic-all', 'unknown-provider']:
                all_checked = case in {'synthetic-all', 'unknown-provider'}
                receipts = [[case, n, path, digest, scope] for n, kind, path, digest, scope in needs if all_checked or kind in {'interleaving', 'induction'}]
                if case == 'missing-qnt':
                    receipts = [x for x in receipts if x[1] != 'AR-H']
                if case == 'stale-subject':
                    receipts = [x[:3] + ['stale'] + x[4:] if x[1] == 'AR-H' else x for x in receipts]
                if case == 'wrong-scope':
                    receipts = [x[:4] + ['wrong'] if x[1] == 'AR-I' else x for x in receipts]
                gates = [[case, v['key'], str(all_checked and (not (case == 'unknown-provider' and v['key'] == 'provider-semantics'))).lower()] for v in p['gate']]
                inputs = dict(scenario=[[case]], need=needs, method=[['interleaving', 'quint'], ['induction', 'lean'], ['source-refinement', 'source-audit'], ['environment-refinement', 'platform']], receipt=receipts, dependency=deps, external=[[case, 'TS-S', str(all_checked).lower()]], gate=gates)
                session.replace(inputs)
                v = session.run(queries=queries)
                assert v['complete']
                results[case] = v['relations']
            assert len(results['current']['checked']) == 2 and len(results['current']['missing']) == 2 and (len(results['current']['route']) == 4)
            for case in ['missing-qnt', 'stale-subject', 'wrong-scope']:
                assert len(results[case]['checked']) == 1
            assert len(results['synthetic-all']['candidate']) == 1
            assert all((not v['candidate'] for k, v in results.items() if k != 'synthetic-all'))
        finally:
            native.close()
        _science.save(_study_workspace('CACHE') / 'ascent-model-results.json', dict(results=results, hostAttested=False, repositoryRegistered=False))

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('EVIDENCE').mkdir(parents=True, exist_ok=True)
        p, native = _science.project()
        _science.views(p)
        sources = ['vendor/gambit/gsc/' + v for v in ['_back.scm', '_gvm.scm', '_prims.scm', '_t-c-1.scm', '_t-c-2.scm', '_front.scm']]
        sources += ['../gerbil-gambit-bootstrap-audit/src/' + v for v in ['gerbil/compiler/base.ss', 'gerbil/compiler/driver.ss', 'gerbil/compiler/compile.ss', 'std/iter/macros.ss', 'std/iter/api.ss', 'std/iter.ss', 'std/string/misc.ss', 'std/sync/wg.ss']]
        checks = [(sources[0], '(default-label-info targ nb-parms closed?)'), (sources[1], '(lambda (env args) proc-obj)'), (sources[1], '(eq? (vector-ref x 0) proc-obj-tag)'), (sources[2], '(lambda (env args) (if (not (safe? env)) spec proc))'), (sources[3], "(c-intf-decls-set! c-intf '())"), (sources[4], '(let ((proc (proc-obj-inline prim)))')]
        for path, frag in checks:
            assert frag in (_science.ROOT / path).read_text(), (path, frag)
        q = (_science.ROOT / _science.QNT).read_text()
        l = (_science.ROOT / _science.LEAN).read_text()
        for v in p['refinement']:
            assert all(('action ' + n + '(' in q or 'action ' + n + '=' in q for n in v['qntScope'].split(';')))
            assert all(('theorem ' + n + ' ' in l for n in v['leanScope'].split(';')))
        _science.save(_study_workspace('CACHE') / 'source-census.json', dict(checks=checks, files={s: _science.sha(_science.ROOT / s) for s in sources}, aliasClosure='open', nativeTests=False))
        tests = _science.context.command('quint-tests', ['quint', 'test', _science.QNT, '--match', 'Test$'], policy=_science.process_profile)
        assert tests.count('ok ') == 16 and tests.count('ControlTest passed') == 6
        _science.context.command('quint-samples', ['quint', 'run', _science.QNT, '--init', 'init', '--invariant', 'safe', '--max-samples', '100', '--max-steps', '80', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('quint-unknown', ['quint', 'run', _science.QNT, '--init', 'initUnknownRecipe', '--invariant', 'safe', '--max-samples', '100', '--max-steps', '80', '--seed', '17', '--verbosity', '1'], policy=_science.process_profile)
        _science.context.command('lean', ['lean', _science.LEAN], policy=_science.process_profile)
        _science.ascent(p)
        _science.context.command('d2-svg', ['d2', _science.DIAGRAM, _science.DIAGRAM[:-3] + '.svg'], policy=_science.process_profile)
        _science.context.command('d2-png', ['d2', _science.DIAGRAM, str(_study_workspace('CACHE') / 'diagram.png')], policy=_science.process_profile)
        org = (_science.ROOT / '.cache/research/legacy-evidence/evidence/research/iter-compiler-service/check-org.el').read_text().replace('iter-compiler-service-design.org', _science.STEM + '-design.org').replace('iter-compiler-service-matrix.org', _science.STEM + '-matrix.org')
        _science.save(_study_workspace('EVIDENCE') / 'checks.json', dict(status='pending-local-checks', runtimeAdmitted=False))
        _study_write_text(_study_workspace('CACHE') / 'check-org.el', org)
        _science.context.command('org', ['emacs', '--batch', '-Q', '--load', str(_study_workspace('CACHE') / 'check-org.el')], policy=_science.process_profile)
        parent = _science.ROOT / '.cache/research/legacy-evidence/evidence/research/target-stage-sealing/local-input.json'
        bindings = json.loads(parent.read_text())['sourceBindings']
        assert all((_science.sha(_science.ROOT / path) == h for path, h in bindings.items())), 'Parent drift'
        artifacts = [_science.MODEL, _science.DESIGN, _science.MATRIX, _science.DIAGRAM, _science.RULES, _science.QNT, _science.LEAN, _science.PARAM, _science.context.library_source((_science.STEM + '-study.py').removesuffix('.py').replace('-', '_'))]
        for path in artifacts + sources:
            bindings[path] = _science.sha(_science.ROOT / path)
        _science.save(_study_workspace('CACHE') / 'input.json', dict(sourceBindings=bindings, parentLocalInputSha256=_science.sha(parent), parentHostRegistered=False, sysmlSha256=_science.sha(_study_workspace('CACHE') / 'projection.json'), logs={str(path.relative_to(_science.ROOT)): _science.sha(path) for path in _study_workspace('CACHE').iterdir() if path.suffix in {'.stdout', '.stderr'}}))
        checks = dict(status='conditional-local-models-pass', qntHistories=16, negativeControls=6, sampledRuns=200, maxSteps=80, leanBoundaryLemmas=8, ascentLocalScenarios=6, gatesOpen=7, aliasClosure='open', sourceRefinement='open', hostRegistration='unresolved inherited attestation failure; not retried', runtimeAdmitted=False, nativeTestsRun=False, performanceTestsRun=False)
        _science.save(_study_workspace('CACHE') / 'checks.json', checks)
        for path in _study_workspace('CACHE').iterdir():
            if path.is_file() and path.suffix not in {'.png', '.stdout', '.stderr', '.txt', '.log'}:
                _study_write_bytes(_study_workspace('EVIDENCE') / path.name, path.read_bytes())
        _science.save(_study_workspace('EVIDENCE') / 'artifacts.json', {str(p.relative_to(_science.ROOT)): _science.sha(p) for p in _study_workspace('EVIDENCE').iterdir() if p.is_file() and p.name != 'artifacts.json'})
        print(json.dumps(checks))
