"""Project and verify Family 6 declarations using the Research receipt contracts."""

import hashlib
from pathlib import Path

from gambit_smp.framework import digest, relative
from gambit_smp.recipes import fields, read_json, source_path
from gambit_smp.rest_observation import RULES, validate_options


PROBE_DECLARATION = 'evidence/fixtures/dev-family6-engineering/rest-probes.json'
FAMILY6_REST_RECIPE = 'family6-rest-6-9'
OBSERVATION_PROVIDER = 'gambit.observation-identity'
REST_RUNTIME_PROVIDERS = frozenset({
    'gambit.completed-runtime', 'gambit.runtime-import', OBSERVATION_PROVIDER,
})


def rest_probe_steps(runtime_step, *, root, moving=False):
    """Bind the task's probe declaration to a typed runtime provider."""
    declaration = read_json(source_path(root, PROBE_DECLARATION))
    fields(declaration, ('schema', 'steps'))
    if declaration['schema'] != 'family6-rest-probes.v1' or not isinstance(declaration['steps'], list):
        raise ValueError('unsupported Family 6 probe declaration')
    steps = []
    ids = set()
    cases = set()
    case_ids = set()
    for step in declaration['steps']:
        fields(step, ('id', 'capability', 'budgetSeconds', 'arguments'))
        if (step['capability'] != 'gambit.executable-test' or not isinstance(step['id'], str)
                or not step['id'] or step['id'] in ids):
            raise ValueError('unique executable-test step required in Family 6 probe declaration')
        ids.add(step['id'])
        args = step['arguments']
        options = args['restObservation']
        validate_options(options, {RULES})
        case = options['case']
        case_key = (case['checklist'], case['spelling'], case['situation'])
        if case_key in cases or case['id'] in case_ids:
            raise ValueError('duplicate Family 6 probe case')
        cases.add(case_key)
        case_ids.add(case['id'])
        if moving and case['checklist'] != 8:
            continue
        steps.append(dict(step, dependsOn=[runtime_step], arguments=dict(
            args, runtime=dict(step=runtime_step, output='runtime'),
            identity=dict(step=runtime_step, output='identity'))))
    return steps


def rest_execution_summary(out, receipt, child):
    from gambit_smp.rest_observation import bound_read, moving_coverage, rest_cut_coverage
    result = {}
    rest, rest_errors = [], {}
    for step in child.get('steps', []):
        try:
            observation = bound_read(out / 'run', step)
        except (OSError, ValueError, KeyError, TypeError) as error:
            if 'case' not in step.get('arguments', {}).get('restObservation', {}):
                raise
            rest_errors[step['id']] = str(error)
            continue
        if observation is not None:
            rest.append(observation)
    if rest:
        result['restObservations'] = rest
        if coverage := moving_coverage(rest, child['steps']):
            result['movingRestCoverage'] = coverage
    coverage = rest_cut_coverage(rest, child.get('steps', []), planned=child.get('plannedSteps'),
                                 read_errors=rest_errors)
    if coverage:
        result['restCutCoverage'] = coverage
    if any(case['checklist'] in (6, 7, 9) for group in coverage for case in group['cases']):
        result['item10StartCheck'] = item10_start_check(out, receipt, child, coverage, rest)
    return result


def rest_campaign_evidence(root, reference, *, diagnose_cases=False):
    """Read and revalidate the sealed rest receipt selected by the campaign."""
    from gambit_smp.recipes import decode_json
    from gambit_smp.research_kernel import bound_child_receipt, manifest_paths

    out = relative(root, reference['run'])
    receipt_path = out/'receipt.json'
    raw = receipt_path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != reference['receiptSha256']:
        raise ValueError('item 10 rest receipt identity changed')
    receipt = decode_json(raw)
    if receipt.get('schema') != 'sealed-research-run.v1' or receipt.get('root') != str(root.resolve()):
        raise ValueError('item 10 requires a sealed Research receipt from this repository')
    child = bound_child_receipt(out, receipt)
    summary = rest_execution_summary(out, receipt, child)
    check = summary.get('item10StartCheck')
    if not check or not check['canStart']:
        if diagnose_cases and check:
            rows = {row['id'] for row in child['steps']}
            absent = [row['id'] for row in child.get('plannedSteps', [])
                      if 'case' in row['arguments'].get('restObservation', {}) and row['id'] not in rows]
            if absent:
                raise FileNotFoundError('missing Family A case receipts: ' + ', '.join(absent))
            for group in summary.get('restCutCoverage', []):
                for case in group['cases']:
                    if reason := case.get('receiptError') or case.get('firstFailedObligation') or case.get('stepReason'):
                        raise ValueError(f"Family A {case['step']}: {reason}")
            missing = sorted({case['step'] for group in summary.get('restCutCoverage', [])
                              for case in group['cases'] if case['disposition'] == 'missing'})
            if missing and len(summary['restCutCoverage']) == 1:
                raise FileNotFoundError('missing verified Family A observations: ' + ', '.join(missing))
        raise ValueError(check['reason'] if check else 'item 10 requires the combined rest Recipe')
    engine = manifest_paths(Path(receipt['engine']))
    if engine['engineId'] != receipt['engineId']:
        raise ValueError('item 10 rest engine seal changed')
    for name, sha in receipt['inputs'].items():
        if digest(relative(root, name)) != sha:
            raise ValueError('item 10 rest input changed: ' + name)
    if digest(receipt_path) != reference['receiptSha256'] or digest(out/'run/receipt.json') != receipt['childReceiptSha256']:
        raise ValueError('item 10 rest receipts changed during validation')
    return dict(check, restRun=reference['run'], restReceiptSha256=reference['receiptSha256']), child


def rest_check_recipe(root, recipe, runtime_step, *, moving=False):
    """Project one checked runtime provider into the selected native cuts."""
    from copy import deepcopy
    from gambit_smp.recipes import validate_recipe

    by_id = {row['id']: row for row in recipe['steps']}
    provider = by_id.get(runtime_step)
    if (provider is None or recipe.get('workspacePolicy') != 'in-place'
            or provider['capability'] not in REST_RUNTIME_PROVIDERS):
        raise ValueError('rest checks require a checked in-place runtime provider')
    inputs = []
    if provider['capability'] == OBSERVATION_PROVIDER:
        if provider['dependsOn']:
            raise ValueError('observation runtime must declare its GSI directly')
        steps = deepcopy([provider])
    else:
        source_ref = provider['arguments']['source']
        source = by_id[source_ref['step']]
        if (provider['dependsOn'] != [source['id']] or source_ref['output'] != 'source'
                or source['capability'] != 'gambit.materialize' or source['dependsOn']
                or 'buildWorkspace' in source['arguments']):
            raise ValueError('rest checks require the import’s locked source without build ancestry')
        lock = source['arguments']['sourceLock']
        patch = read_json(source_path(root, lock))['patch']
        if patch not in recipe['inputs']:
            raise ValueError('runtime import must declare its source lock patch')
        inputs.extend([lock, patch])
        inputs.extend(source['arguments'][key] for key in ('cacheReceipt', 'workspaceState')
                      if key in source['arguments'])
        provider_input = 'archive' if provider['capability'] == 'gambit.runtime-import' else 'producer'
        inputs.append(provider['arguments'][provider_input])
        steps = deepcopy([source, provider])
    evidence_entry = 'tests/recipes/framework-contracts/evidence-entry.json'
    inputs.extend([PROBE_DECLARATION, RULES, evidence_entry, 'evidence/dsl/observation-contract.ss'])

    probes = rest_probe_steps(runtime_step, moving=moving, root=root)
    steps.extend(probes)
    inputs.extend(probe['arguments']['program'] for probe in probes)
    steps.append(dict(id='moving-rest-evidence' if moving else 'rest-cuts-evidence',
                      capability='evidence.evaluate',
                      dependsOn=[step['id'] for step in steps], budgetSeconds=30,
                      arguments=dict(dsl=evidence_entry, queries={'missing_step': 'missing_step'},
                                     expected={'missing_step': []})))
    result = dict(schema="evidence-recipe.v2", id='family6-moving-rest' if moving else FAMILY6_REST_RECIPE,
                  workspacePolicy='in-place',
                  scope=('Item 8 moving-GC observations for three rest spellings on one checked runtime.'
                         if moving else 'Item 6–9 native rest observations on one checked runtime.'),
                  inputs=list(dict.fromkeys(inputs)), steps=steps)
    if moving:
        result['budgetSeconds'] = 300
    else:
        result['timeoutPolicy'] = dict(mode='per-stage', overheadSeconds=30)
    validate_recipe(root, result)
    if 'timeoutPolicy' in result:
        result.pop('budgetSeconds')  # The loader derives this from the declared stage limits.
    return result


def rest_campaign_recipe(root, run, *, gate2_receipt=None):
    """Bind the original ordered campaign to the provider in its prerequisite receipt."""
    from copy import deepcopy
    from gambit_smp.ordered_stress_audit import RECIPE_TEMPLATE
    from gambit_smp.recipes import load, validate_recipe

    run = run.resolve()
    reference = dict(run=run.relative_to(root.resolve()).as_posix(), receiptSha256=digest(run/'receipt.json'))
    check, child = rest_campaign_evidence(root, reference)
    template = root/RECIPE_TEMPLATE
    recipe, _ = load(root, template)
    source, provider, stress = recipe['steps'][:3]
    old_lock = source['arguments']['sourceLock']
    retired = {old_lock, read_json(root/old_lock)['patch'], provider['arguments']['producer']}
    planned = {step['id']: step for step in child['plannedSteps']}
    new_provider = deepcopy(planned[check['provider']])
    if new_provider['capability'] == OBSERVATION_PROVIDER:
        new_provider['arguments']['retainedRuntime'] = dict(reference, step=check['provider'])
        new_provider['id'] = provider['id']
        new_provider['dependsOn'] = []
        recipe['steps'] = [new_provider, *recipe['steps'][2:]]
        for step in recipe['steps']:
            if step['id'] == 'verdict':
                step['dependsOn'] = [row['id'] for row in recipe['steps'] if row['id'] != 'verdict']
    else:
        new_source = deepcopy(planned[new_provider['arguments']['source']['step']])
        new_source['id'] = source['id']
        new_provider['id'] = provider['id']
        new_provider['dependsOn'] = [source['id']]
        new_provider['arguments']['source']['step'] = source['id']
        recipe['steps'][:2] = [new_source, new_provider]
    recipe['inputs'] = list(dict.fromkeys([*(name for name in recipe['inputs'] if name not in retired),
                                         *child['declaredInputs'], PROBE_DECLARATION]))
    stress['arguments']['orderedStress']['restEvidence'] = reference
    if gate2_receipt is not None:
        source_path(root, gate2_receipt)
        stress['arguments']['orderedStress']['gate2Receipt'] = gate2_receipt
        if gate2_receipt not in recipe['inputs']:
            recipe['inputs'].append(gate2_receipt)
    validate_recipe(root, recipe)
    return recipe


def item10_start_check(out, receipt, child, coverage, observations):
    """Check the complete rest inventory and its one runtime provider."""
    from gambit_smp.recipes import artifact_path, decode_json
    from gambit_smp.rest_observation import runtime_identity_bytes

    check = dict(checklist=10, canStart=False, requiredCases=11,
                 innerBudgetSeconds=295, wholeBudgetSeconds=300, runtimeAdmitted=False)
    if (receipt.get('recipe') != child.get('recipe')
            or receipt.get('outcome') != 'PASS' or child.get('outcome') != 'PASS'
            or child.get('inputsStable') is not True
            or receipt.get('parentReaped') is not True
            or receipt.get('processGroupQuiescent') is not True
            or receipt.get('timeout') is not False or receipt.get('exit') != 0
            or not receipt.get('engineId') or child.get('engine', {}).get('engineId') != receipt['engineId']):
        return dict(check, reason='complete sealed rest Recipe receipt required')
    planned = child.get('plannedSteps', [])
    providers = [step for step in planned if step['capability'] in REST_RUNTIME_PROVIDERS]
    if len(providers) != 1:
        return dict(check, reason='one checked runtime provider required')
    provider = providers[0]
    observed = provider['capability'] == OBSERVATION_PROVIDER
    if observed:
        if provider.get('dependsOn') or not provider['arguments'].get('gsiSha256'):
            return dict(check, reason='observation runtime requires its declared GSI')
    else:
        source_id = provider['arguments']['source']['step']
        sources = [step for step in planned if step['id'] == source_id]
        if (len(sources) != 1 or sources[0]['capability'] != 'gambit.materialize'
                or sources[0]['dependsOn'] or 'buildWorkspace' in sources[0]['arguments']
                or provider['dependsOn'] != [source_id]
                or provider['arguments']['source']['output'] != 'source'):
            return dict(check, reason='rest Recipe requires its locked import source')
    try:
        expected = rest_probe_steps(provider['id'], root=Path(receipt['root']))
    except (OSError, ValueError, KeyError, TypeError) as error:
        return dict(check, reason=f'Family 6 probe declaration: {error}')
    probes = [step for step in planned if step['capability'] == 'gambit.executable-test']
    terminal = [step for step in planned if step['capability'] == 'evidence.evaluate']

    def case_identity(step):
        args = step['arguments']
        options = args.get('restObservation', {})
        return dict(step, budgetSeconds=None,
                    arguments=dict(args, restObservation=dict(options, capacity=None)))

    if (len(expected) != check['requiredCases'] or len(probes) != len(expected)
            or {step['id']: case_identity(step) for step in probes}
               != {step['id']: case_identity(step) for step in expected}
            or len(planned) != len(expected) + (2 if observed else 3) or len(terminal) != 1
            or set(terminal[0]['dependsOn']) != {step['id'] for step in planned if step not in terminal}):
        return dict(check, reason='exact eleven-case rest Recipe required')
    rows = child.get('steps', [])
    completed = {row['id']: row for row in rows}
    if (len(rows) != len(planned) or len(completed) != len(planned)
            or any(completed.get(step['id'], {}).get('outcome') != 'PASS' or
                   any(completed[step['id']].get(key) != value for key, value in step.items()
                       if key != 'component')
                   for step in planned)):
        return dict(check, reason='all declared rest steps must pass')
    if len(coverage) != 1 or not coverage[0]['allCasesObserved'] or len(coverage[0]['cases']) != len(expected):
        return dict(check, reason='all eleven verified observations must share one runtime identity')
    reports = {report['step']: report for report in observations}
    inputs = receipt['inputs']
    if (RULES not in inputs or any(
            reports.get(step['id'], {}).get('rulesSha256') != inputs[RULES]
            or step['arguments']['program'] not in inputs
            or reports[step['id']].get('fixture', {}).get('sourceSha256') != inputs[step['arguments']['program']]
            for step in expected)):
        return dict(check, reason='rest reports differ from their sealed probe inputs')
    group = coverage[0]
    try:
        producer = completed[provider['id']]['outputs']
        identity = producer['identity']
        if identity['type'] != 'runtime-identity' or producer['runtime']['type'] != 'source-runtime':
            raise ValueError('typed imported runtime and identity required')
        path = artifact_path(out/'run', identity, root=Path(receipt['root']))
        raw = path.read_bytes()
        candidate = decode_json(raw)
        if (hashlib.sha256(raw).hexdigest() != identity['sha256']
                or candidate['schema'] != 'gambit-recipe-runtime-identity.v1'
                or candidate['binarySha256'] != group['executableSha256']
                or (observed and candidate['binarySha256'] != provider['arguments']['gsiSha256'])
                or hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest() != group['runtimeIdentitySha256']):
            raise ValueError('rest reports differ from their imported GSI identity')
    except (OSError, ValueError, KeyError, TypeError) as error:
        return dict(check, reason=str(error))
    return dict(check, canStart=True, executableSha256=group['executableSha256'],
                runtimeIdentitySha256=group['runtimeIdentitySha256'], provider=provider['id'],
                verifiedCases=len(expected), childReceiptSha256=receipt['childReceiptSha256'])
