"""Offline caller attribution and two-package admission; no native builds."""
from gambit_smp.research_flow import projected_fields as _study_fields
from gambit_smp.research_flow import study_workspace as _study_workspace
from gambit_smp.research_flow import write_text as _study_write_text
import copy
import hashlib
import json
import re
import shutil
from pathlib import Path
from ascent import Engine
from gambit_smp.storage_policy import EVIDENCE_CACHE_SUFFIXES

from gambit_smp.evidence_capabilities import evaluate_observations


def paired_elapsed_values(policy, observations):
    """Arithmetic over already authenticated observations, never admission.

    Policy is a projection of SysML. Receipt hashes here are identifiers, not
    authentication: the existing execution/artifact owner must bind their bytes,
    commands, source closure and output inventory before using the witnesses.
    No process launch, receipt search, retry, best-sample selection or defaults.
    """
    from gambit_smp.recipes import fields
    fields(policy, ('repositories', 'cases', 'coldCase', 'targetFactor',
                    'profile', 'compilers', 'requests'))

    def identity(value):
        if (not isinstance(value, str) or len(value) != 64
                or any(c not in '0123456789abcdef' for c in value)):
            raise ValueError('exact SHA256 observation identity required')
        return value

    def natural(value, name):
        if type(value) is not int or value <= 0:
            raise ValueError(name + ' must be a positive integer')
        return value

    repos, cases = policy['repositories'], policy['cases']
    if (not isinstance(repos, list) or set(repos) != {'mcp', 'poo'} or len(repos) != 2
            or not isinstance(cases, list) or len(cases) != 5
            or set(cases) != {'package-clean', 'leaf-edit', 'macro-edit',
                              'no-change', 'required-correctness'}
            or policy['coldCase'] != 'package-clean'):
        raise ValueError('both complete package inventories and all five cases required')
    factor = natural(policy['targetFactor'], 'targetFactor')
    if factor < 2:
        raise ValueError('targetFactor cannot weaken the twofold objective')
    identity(policy['profile'])
    fields(policy['compilers'], ('reference', 'candidate'))
    for compiler in policy['compilers'].values():
        identity(compiler)
    fields(policy['requests'], tuple(repos))
    for request in policy['requests'].values():
        fields(request, ('package', 'graph', 'inputs', 'budgetsNs'))
        identity(request['package']); identity(request['graph'])
        fields(request['inputs'], tuple(cases))
        fields(request['budgetsNs'], tuple(cases))
        for case in cases:
            identity(request['inputs'][case])
            natural(request['budgetsNs'][case], 'budgetNs')
    if not isinstance(observations, list):
        raise ValueError('explicit observations required')
    indexed, receipts = {}, set()
    for row in observations:
        fields(row, ('repo', 'arm', 'case', 'profile', 'compiler', 'package',
                     'graph', 'input', 'elapsedNs', 'receipt', 'exit', 'timeout',
                     'parentReaped', 'processGroupQuiescent', 'completeRequest',
                     'semanticPass', 'negativeControlsPass', 'preparationPass'))
        key = (row['repo'], row['arm'], row['case'])
        repo, arm, case = key
        if repo not in repos or arm not in policy['compilers'] or case not in cases:
            raise ValueError('observation outside the declared paired workload')
        if key in indexed:
            raise ValueError('duplicate pair cell; sample selection is forbidden')
        receipt = identity(row['receipt'])
        if receipt in receipts:
            raise ValueError('one receipt cannot represent multiple executions')
        receipts.add(receipt)
        request = policy['requests'][repo]
        expected = dict(profile=policy['profile'], compiler=policy['compilers'][arm],
                        package=request['package'], graph=request['graph'],
                        input=request['inputs'][case])
        if any(row[k] != value for k, value in expected.items()):
            raise ValueError('paired source/profile/request identity mismatch')
        elapsed = natural(row['elapsedNs'], 'elapsedNs')
        success = (type(row['exit']) is int and row['exit'] == 0
                   and row['timeout'] is False
                   and all(row[k] is True for k in ('parentReaped',
                       'processGroupQuiescent', 'completeRequest', 'semanticPass',
                       'negativeControlsPass', 'preparationPass'))
                   and elapsed <= request['budgetsNs'][case])
        indexed[key] = (row, success)
    missing = [list((repo, arm, case)) for repo in repos
               for arm in policy['compilers'] for case in cases
               if (repo, arm, case) not in indexed]
    censored = [list(key) for key, (_, passed) in indexed.items() if not passed]
    result = dict(valueScope='conditional-paired-elapsed-arithmetic', missing=missing,
                  censored=censored, pairedValuesComplete=not missing and not censored,
                  observedCells=[dict(repo=key[0], arm=key[1], case=key[2],
                      elapsedNs=row['elapsedNs'], receipt=row['receipt'], complete=passed)
                      for key, (row, passed) in indexed.items()],
                  repositories=[], targetReached=False, nativeAdmitted=False,
                  mergeAllowed=False)
    if not result['pairedValuesComplete']:
        return result
    for repo in repos:
        values = []
        for case in cases:
            before = indexed[(repo, 'reference', case)][0]['elapsedNs']
            after = indexed[(repo, 'candidate', case)][0]['elapsedNs']
            values.append(dict(case=case, referenceNs=before, candidateNs=after,
                               netSavedNs=before-after, nonRegression=after <= before,
                               targetReached=factor*after <= before))
        cold = next(row for row in values if row['case'] == policy['coldCase'])
        result['repositories'].append(dict(repo=repo, cases=values,
            coldTargetReached=cold['targetReached'],
            allCasesNonRegressing=all(row['nonRegression'] for row in values)))
    result['targetReached'] = all(row['coldTargetReached'] and row['allCasesNonRegressing']
                                  for row in result['repositories'])
    return result


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
        _science.Engine = Engine
        _science.EVIDENCE_CACHE_SUFFIXES = EVIDENCE_CACHE_SUFFIXES
        _science.ROOT = _science.context.root
        _science.BASE = _science.ROOT / 'dev/architecture/toolchain'
        _science.MODEL = _science.BASE / 'models/sysml/package-development-benchmark.sysml'
        _science.QNT = _science.BASE / 'models/quint/package_benchmark_admission.qnt'
        _science.LEAN = _science.BASE / 'models/lean/PackageBenchmarkAdmission.lean'
        _science.RULES = _science.ROOT / 'dev/modeling/ascent/package-development-benchmark.rules.scm'
        _science.LEAN_BIN = '/Users/guangtao/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean'
        _science.GROUPS = [('component', 5, ['key', 'boundary', 'owns', 'inputContract', 'outputContract', 'oldAuthority', 'retirement', 'retained', 'added', 'evidenceRole']), ('use', 18, ['component.key', 'obligation.key', 'obligation.primary', 'obligation.semantic', 'obligation.evidenceStatus', 'purpose']), ('edge', 9, ['fromNode', 'toNode', 'contract']), ('responsibility', 10, ['key', 'primary', 'semantic', 'domain', 'evidenceStatus', 'catalogue.id', 'catalogue.domains', 'question', 'model', 'obligation', 'handoff', 'excludes']), ('repository', 2, ['key', 'root', 'head', 'graph', 'command', 'capacity', 'cache', 'correctness', 'currentStatus']), ('route', 12, ['key', 'sourcePath', 'needle', 'evidencePath', 'evidenceNeedle', 'established', 'unresolved', 'claimClass', 'removable', 'retained', 'overhead', 'retirement', 'qntTest', 'lemma', 'qntPath', 'leanPath'])]
        _science.process_profile = {'cap': 60, 'stream': 'stdout', 'failure': 'runtime', 'failParameter': False, 'expectedParameter': False}

    def sha(_science, path):
        return hashlib.sha256(path.read_bytes()).hexdigest()

    def save(_science, path, value):
        _study_write_text(path, json.dumps(value, indent=2) + '\n')

    def analyze(_science):
        _study_workspace('CACHE').mkdir(parents=True, exist_ok=True)
        _study_workspace('OUT').mkdir(parents=True, exist_ok=True)
        helper = _science.context.library('size_family_hold_balance_study')
        previous = json.loads((_science.ROOT / '.cache/tasks/future-frame-commit/runs/research/darwin-turbo/mcp-baseline/sysml-check.json').read_text())
        files = sorted(set(previous['sourceBindings']) | {str(_science.MODEL.relative_to(_science.ROOT)), 'dev/modeling/models/sysml/verification-responsibilities.sysml'})
        bindings = {name: _science.sha(_science.ROOT / name) for name in files}
        for name in [_science.RULES, Path(str(_science.context.root / 'src/gambit_smp/scientific_package_development_benchmark_study.py')), _science.QNT, _science.LEAN]:
            bindings[str(name.relative_to(_science.ROOT))] = _science.sha(name)
        queries = [(g, i, f) for g, n, fields in _science.GROUPS for i in range(n) for f in fields]
        values = []
        for start in range(0, len(queries), 100):
            field_expressions = []
            for group, i, field in queries[start:start + 100]:
                field_expressions.append(f'GambitPackageDevelopment::{group}{i}.{field}')
            raw = _study_fields(_science.ROOT, None, 'package-development-benchmark', field_expressions, ordered=True, models=files)
            chunk = raw['orderedValues']
            assert len(chunk) == len(queries[start:start + 100])
            values.extend(chunk)
        rows = {}
        for (group, i, field), value in zip(queries, values, strict=True):
            rows.setdefault(group, {}).setdefault(i, {})[field] = value
        projection = {g: list(rows[g].values()) for g, _, _ in _science.GROUPS}
        _science.save(_study_workspace('OUT') / 'projection.json', projection)
        responsibilities = projection['responsibility']
        assert len({r['obligation'] for r in responsibilities}) == 10
        assert len({r['semantic'] for r in responsibilities}) == 10
        assert all((r['primary'] == r['catalogue.id'] and r['domain'] in r['catalogue.domains'].split(';') for r in responsibilities))
        assert {r['primary'] for r in responsibilities} == {'quint', 'lean', 'source', 'native'}
        for r in responsibilities:
            assert (_science.ROOT / r['model']).is_file()
            bindings[r['model']] = _science.sha(_science.ROOT / r['model'])
        prior_path = _science.ROOT / '.cache/tasks/future-frame-commit/runs/research/c23-development/input.json'
        prior = json.loads(prior_path.read_text())
        cost_path = 'dev/architecture/toolchain/models/lean/DevelopmentBenefit.lean'
        assert _science.sha(_science.ROOT / cost_path) == prior['sourceBindings'][cost_path]
        bindings[cost_path] = _science.sha(_science.ROOT / cost_path)
        bindings[str(prior_path.relative_to(_science.ROOT))] = _science.sha(prior_path)
        for row in projection['route']:
            for path, needle in [('sourcePath', 'needle'), ('evidencePath', 'evidenceNeedle')]:
                p = _science.ROOT / row[path]
                assert row[needle] in p.read_text(), (row['key'], path)
                bindings[row[path]] = _science.sha(p)
            assert re.search('\\brun ' + row['qntTest'] + '\\s*=', _science.QNT.read_text())
            assert re.search('^theorem ' + row['lemma'] + '\\b', _science.LEAN.read_text(), re.M)
        for row in projection['repository']:
            repo = _science.ROOT / row['root']
            assert _science.context.output(['git', '-C', str(repo), 'rev-parse', 'HEAD'], text=True, name='source-96').strip() == row['head']
            assert not _science.context.output(['git', '-C', str(repo), 'status', '--porcelain'], text=True, name='source-97').strip()
            for file in ['build.ss', 'gerbil.pkg']:
                bindings[row['root'] + '/' + file] = _science.sha(repo / file)
        bindings['../gerbil-poo/Justfile'] = _science.sha(_science.ROOT / '../gerbil-poo/Justfile')
        bindings['../gerbil-poo/t/build-spec.ss'] = _science.sha(_science.ROOT / '../gerbil-poo/t/build-spec.ss')
        _science.context.command('qnt-type', ['quint', 'typecheck', str(_science.QNT), '--out', str(_study_workspace('CACHE') / 'typed-ir.json')], policy=helper.process_profile)
        _science.context.command('qnt-histories', ['quint', 'test', str(_science.QNT), '--backend', 'typescript', '--match', 'Test$', '--max-samples', '1', '--seed', '953'], policy=helper.process_profile)
        _science.context.command('qnt-samples', ['quint', 'run', str(_science.QNT), '--backend', 'typescript', '--init', 'init', '--step', 'step', '--invariant', 'safe', '--max-samples', '500', '--max-steps', '80', '--seed', '953', '--verbosity', '1'], policy=helper.process_profile)
        assert not re.search('\\bsorry\\b|\\baxiom\\s', _science.LEAN.read_text())
        _science.context.command('lean', [_science.LEAN_BIN, str(_science.LEAN)], policy=helper.process_profile)
        ownership_policy = _science.ROOT / 'dev/modeling/ascent/obligation-ownership.rules.scm'
        bindings[str(ownership_policy.relative_to(_science.ROOT))] = _science.sha(ownership_policy)
        obligations = [[r['key'], r['semantic'], r['primary'], r['model'], _science.sha(_science.ROOT / r['model']), 'conditional-package-research'] for r in responsibilities]
        observed_proofs = [[r[0], r[2], r[3], r[4], r[5]] for r in obligations if next((o for o in responsibilities if o['key'] == r[0]))['evidenceStatus'] == 'conditional-checked']
        ownership = {}
        for case in ['current', 'dual-owner', 'renamed-overlap', 'wrong-owner-evidence', 'wrong-domain', 'all-complete-fixture']:
            os = copy.deepcopy(obligations)
            es = copy.deepcopy(observed_proofs)
            if case == 'dual-owner':
                extra = os[0].copy()
                extra[2] = 'lean'
                os.append(extra)
            if case == 'renamed-overlap':
                extra = os[2].copy()
                extra[0] += '-alias'
                os.append(extra)
            if case == 'wrong-owner-evidence':
                es[2][1] = 'quint'
            if case == 'wrong-domain':
                os[2][2] = 'quint'
            if case == 'all-complete-fixture':
                es = [[r[0], r[2], r[3], r[4], r[5]] for r in os]
            selector = '(define-evidence (query) (sources clue factor binding) (outputs question verificationChecked verificationMissing verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch verificationReady verificationComponentGap) (include clue-selection-schema)\n' + ownership_policy.read_text()
            tables = {'verificationObligation': ('id semantic owner artifact digest scope', os), 'verificationDomain': ('owner domain', sorted({(r['catalogue.id'], d) for r in responsibilities for d in r['catalogue.domains'].split(';')})), 'verificationKeyDomain': ('semantic domain', [[r['semantic'], r['domain']] for r in responsibilities]), 'verificationObservation': ('id owner artifact digest scope', es), 'verificationUse': ('component obligation', [[u['component.key'], u['obligation.key']] for u in projection['use']]), 'verificationCandidate': ('id', [['package-development']])}
            for name, (columns, values) in tables.items():
                declaration = '(relation ' + name + ' (' + columns + '))'
                facts = '(relation ' + name + ' (' + columns + ') (' + ''.join(('(' + ' '.join((json.dumps(v) for v in row)) + ')' for row in values)) + '))'
                assert declaration in selector
                selector = selector.replace(declaration, facts)
            selector += ')'
            _study_write_text(_study_workspace('OUT') / ('ownership-' + case + '.scm'), selector)
            selector = selector.replace('(include clue-selection-schema)', '(relation clue (id digest claim polarity role source)) (relation factor (id digest name value)) (relation binding (name value))')
            result = evaluate_observations(_science.context, [], {},
                {name: name for name in 'question verificationChecked verificationMissing verificationOwnerConflict verificationSemanticOverlap verificationRoleMismatch verificationReady verificationComponentGap'.split()},
                'ownership-' + case, dsl=dict(source=selector, constructor='query', arguments=[]))
            assoc = result
            ownership[case] = result
            if case == 'current':
                assert len(assoc['verificationChecked']) == 5 and len(assoc['verificationMissing']) == 5
                assert not assoc['verificationOwnerConflict'] and (not assoc['verificationSemanticOverlap']) and (not assoc['verificationRoleMismatch'])
            if case == 'dual-owner':
                assert assoc['verificationOwnerConflict']
            if case == 'renamed-overlap':
                assert assoc['verificationSemanticOverlap']
            if case == 'wrong-domain':
                assert assoc['verificationRoleMismatch']
            if case == 'wrong-owner-evidence':
                assert len(assoc['verificationChecked']) == 4
            assert bool(assoc['verificationReady']) == (case == 'all-complete-fixture')
        _science.save(_study_workspace('OUT') / 'ownership.json', ownership)
        routes = [[r[k] for k in ['key', 'sourcePath', 'evidencePath', 'qntPath', 'qntTest', 'leanPath', 'lemma', 'claimClass']] for r in projection['route']]
        artifacts = [[p, h] for p, h in bindings.items()]
        proofs = [[r[k] for k in ['qntPath', 'qntTest', 'leanPath', 'lemma']] for r in projection['route']]
        needs = [[r['key'], r['head'], r['graph'], 'pinned-sdk', 'explicit-host-budget', 'package-clean-owned-policy', 'complete-request'] for r in projection['repository']]
        cases = [[r[0], case] for r in needs for case in ['package-clean', 'leaf-edit', 'macro-edit', 'no-change', 'required-correctness']]
        pairs = [[r[0], 'baseline:' + r[0], 'candidate:' + r[0]] for r in needs]
        rejected = [['header-early-branch', projection['route'][6]['evidencePath']], ['header-cast-reduction', projection['route'][5]['evidencePath']]]
        scenarios = ['current', 'complete-fixture', 'one-repository-only', 'wrong-head', 'wrong-sdk', 'wrong-graph', 'unset-capacity', 'wrong-cache', 'wrong-clock', 'timeout', 'missing-correctness', 'macro-miss-untested', 'noop-untested', 'regression', 'unmatched-candidate', 'source-drift', 'missing-proof', 'wrong-caller', 'discard-counterevidence']
        results = {}
        engine = Engine()
        try:
            session = engine.open_sources(_science.RULES.read_text())
            assert session.run(queries=['routeGap'])['complete']
            for case in scenarios:
                seen = copy.deepcopy(routes)
                art = copy.deepcopy(artifacts)
                proof = copy.deepcopy(proofs)
                observed = [r + ['yes', 'yes', 'no', 'yes'] for r in needs]
                case_seen = [r + ['matched-semantic-pass'] for r in cases]
                pair_seen = [r + ['same-work-full-context'] for r in pairs]
                performance = [[r[0], 'net-positive-or-required-nonregression'] for r in needs]
                if case == 'current':
                    observed = [needs[0][:4] + ['unset-source-default', *needs[0][5:]] + ['no', 'no', 'yes', 'no']]
                    case_seen = []
                    pair_seen = []
                    performance = []
                if case == 'one-repository-only':
                    observed = observed[:1]
                for name, index in [('wrong-head', 1), ('wrong-graph', 2), ('wrong-sdk', 3), ('unset-capacity', 4), ('wrong-cache', 5), ('wrong-clock', 6)]:
                    if case == name:
                        observed[0][index] = 'unmatched'
                if case == 'timeout':
                    observed[0][7:10] = ['no', 'no', 'yes']
                if case in ['missing-correctness', 'macro-miss-untested', 'noop-untested']:
                    kind = {'missing-correctness': 'required-correctness', 'macro-miss-untested': 'macro-edit', 'noop-untested': 'no-change'}[case]
                    case_seen = [r for r in case_seen if not (r[0] == 'mcp' and r[1] == kind)]
                if case == 'regression':
                    performance = performance[:1]
                if case == 'unmatched-candidate':
                    pair_seen[0][2] = 'another-candidate'
                if case == 'source-drift':
                    art = [[p, 'stale' if p == routes[0][1] else h] for p, h in art]
                if case == 'missing-proof':
                    proof = []
                if case == 'wrong-caller':
                    seen[2][1] = 'wrong-source'
                if case == 'discard-counterevidence':
                    seen[5][7] = 'new-package-win'
                session.replace(dict(artifactNeed=artifacts, artifactSeen=art, routeNeed=routes, routeSeen=seen, proofWitness=proof, benchmarkNeed=needs, benchmarkObserved=observed, caseNeed=cases, caseSeen=case_seen, candidatePairNeed=pairs, candidatePairSeen=pair_seen, performanceWitness=performance, requested=[['two-package-gate']], requiredRepository=[['two-package-gate', r[0]] for r in needs], priorRejection=rejected, proposedTrial=[['repeat-header-branch', 'header-early-branch'], ['repeat-header-casts', 'header-cast-reduction'], ['different-emitter-design', 'direct-literal-emitter']]))
                result = session.run(queries=['routeLinked', 'routeGap', 'baselineReady', 'baselineGap', 'candidateReady', 'missingRepository', 'optimizationAccepted', 'trialBlocked'])
                assert result['complete']
                results[case] = result['relations']
                assert len(result['relations']['trialBlocked']) == 2
                if case not in ['source-drift', 'missing-proof', 'wrong-caller', 'discard-counterevidence']:
                    assert len(result['relations']['routeLinked']) == 12
                else:
                    assert result['relations']['routeGap']
        finally:
            engine.close()
        assert not results['current']['baselineReady'] and (not results['current']['optimizationAccepted'])
        assert results['complete-fixture']['optimizationAccepted']
        for case in scenarios:
            if case != 'complete-fixture':
                assert not results[case]['optimizationAccepted'], case
        _science.save(_study_workspace('OUT') / 'ascent.json', dict(scenarios=results, syntheticFixturesAreNotNativeEvidence=True))
        lines = ['#+TITLE: Two-Package Development Attribution and Refactor Matrix', '#+SETUPFILE: ../../modeling/org/setup.org', '#+PROPERTY: header-args :eval never', '', '* RESEARCH Native SysML projection']
        for group, _, _ in _science.GROUPS:
            fields = list(projection[group][0])
            lines += ['', '** ' + group, '', '| ' + ' | '.join(fields) + ' |', '|' + '+'.join(('---' for _ in fields)) + '|']
            lines += ['| ' + ' | '.join((str(r[k]).replace('|', ' / ') for k in fields)) + ' |' for r in projection[group]]
        matrix = _science.BASE / 'package-development-benchmark-matrix.org'
        _study_write_text(matrix, '\n'.join(lines) + '\n')
        diagram = _science.BASE / 'diagrams/package-development-evidence.d2'
        _study_write_text(diagram, 'direction: right\n' + '\n'.join((json.dumps(r['evidencePath']) + ' -> ' + json.dumps(r['key']) + ': ' + json.dumps(r['claimClass']) + '\n' + json.dumps(r['key']) + ' -> ' + json.dumps(r['removable']) + ': ' + json.dumps(r['unresolved']) for r in projection['route'])) + '\n')
        _science.context.command('d2', ['d2', '--layout', 'elk', str(diagram), str(diagram.with_suffix('.svg'))], policy=helper.process_profile)
        architecture = _science.BASE / 'diagrams/package-development-benchmark.d2'
        _study_write_text(architecture, 'direction: right\n' + '\n'.join((json.dumps(e['fromNode']) + ' -> ' + json.dumps(e['toNode']) + ': ' + json.dumps(e['contract']) for e in projection['edge'])) + '\n')
        _science.context.command('architecture-d2', ['d2', '--layout', 'elk', str(architecture), str(architecture.with_suffix('.svg'))], policy=helper.process_profile)
        for f in [_science.BASE / 'package-development-benchmark.org', _science.BASE / 'index.org', _science.ROOT / 'dev/modeling/index.org', _science.ROOT / 'dev/modeling/verification-responsibilities.org', matrix, diagram, diagram.with_suffix('.svg'), architecture, architecture.with_suffix('.svg')]:
            bindings[str(f.relative_to(_science.ROOT))] = _science.sha(f)
        assert all((_science.sha(_science.ROOT / name) == digest for name, digest in bindings.items())), 'Input drift'
        raw_references = []
        for name, digest in bindings.items():
            if Path(name).suffix.casefold() in EVIDENCE_CACHE_SUFFIXES:
                raw_references.append(dict(path=name, sha256=digest, retention='existing raw owner; no evidence copy'))
                continue
            relative = Path('input-cut') / hashlib.sha256(name.encode()).hexdigest()[:16] / Path(name).name
            target = _study_workspace('OUT') / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(_science.ROOT / name, target)
            assert _science.sha(target) == digest
        _science.save(_study_workspace('OUT') / 'input.json', dict(sourceBindings=bindings, nativeSysmlClosure=files, leanBinarySha256=_science.sha(Path(_science.LEAN_BIN))))
        checks = dict(ownershipPolicyScenarios=6, formalPrimaryObligationsChecked=5, sourceNativeObligationsOpen=3, formalScopeExtensionsOpen=2, architectureComponents=5, componentObligationUses=18, primaryModelObligations=10, sharedBenefitLawsReused=23, noDuplicatedCostModel=True, nativeSysmlFiles=len(files), repositories=2, attributionRoutes=12, qntHistories=12, qntSamples=500, maxSteps=80, seed=953, leanLaws=6, ascentScenarios=len(scenarios), currentBaselinesAccepted=0, optimizedPackagesAccepted=0, nativeBenchmarksExecuted=0, platformDifferentialEstablished=False, sourceToBinarySealEstablished=False, timeoutExclusiveCostAttributionEstablished=False, modelScope='conditional evidence admission, not C/native scheduler refinement')
        _science.save(_study_workspace('OUT') / 'checks.json', checks)
        for p in _study_workspace('CACHE').glob('*'):
            if p.is_file():
                if p.suffix.casefold() in EVIDENCE_CACHE_SUFFIXES:
                    raw_references.append(dict(path=str(p.relative_to(_science.ROOT)), sha256=_science.sha(p), retention='task cache'))
                else:
                    shutil.copyfile(p, _study_workspace('OUT') / p.name)
        _science.save(_study_workspace('OUT') / 'raw-artifact-references.json', raw_references)
        print(json.dumps(checks, indent=2))

# Preserved scientific source notes (in original order).
# Route checks also gate a candidate: source/proof association failures cannot pass.
# The DSL's positive control and every adversarial admission must be explicit.
