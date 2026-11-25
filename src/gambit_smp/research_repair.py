"""Model-selected hosted diagnostics backed by the research checkpoint journal."""

from pathlib import Path
import hashlib
import os

from gambit_smp.compiler_trace import add_compiler_trace_facts, module_compiler_trace
from gambit_smp.framework import ROOT, digest, relative
from gambit_smp.recipes import decode_json, fields, read_json


MODULE = 'gambit.regenerate-module'
FAILURES = frozenset({'DENY', 'FAIL', 'TIMEOUT'})


def _project(facts):
    from gambit_smp.ascent_program import load_component_catalog, query
    # A retained ASCENT session carries omitted sources forward. An absent or
    # unverified stream must explicitly withdraw the previous compiler facts.
    facts = {'compiler_event': [], 'compiler_boundary': [], **facts}
    catalog = load_component_catalog(ROOT / 'evidence/dsl/components.json',
        entry='checkpoint-state', constructor='make-repair-loop', trusted=True)
    names = ('localized', 'evidence_gap', 'eligible', 'blocked', 'verified', 'probe_observed',
             'predecessor_delta', 'compiler_frontier', 'compiler_signal', 'compiler_unreturned_signal')
    relations = {name: [list(row) for row in rows]
                 for name, rows in query(facts, catalog, {name: name for name in names}).items()}
    bindings = catalog['sourceInputs']
    if any(digest(Path(path)) != sha for path, sha in bindings.items()):
        raise ValueError('repair rules changed during inference')
    return dict(backend='ASCENT', facts=facts, relations=relations, sourceInputs=bindings,
                executionAuthorized=False, runtimeAdmitted=False)


def _bound_bytes(root, name, sha):
    if not sha:
        raise ValueError('repair evidence requires a recorded digest')
    data = relative(root, name).read_bytes()
    if hashlib.sha256(data).hexdigest() != sha:
        raise ValueError('repair evidence changed: ' + name)
    return data


def _hosted(step):
    args = step['arguments']
    return step['capability'] == MODULE and args.get('syntaxCheck') is True and 'bootstrapHost' in args


def _cuts(root, run, child):
    from gambit_smp.research_kernel import native_failure_diagnostics
    facts = {name: [] for name in ('failed_cut', 'command_end', 'command_log', 'diagnostic_location')}
    cuts = []
    for step in child['steps']:
        if step['capability'] != MODULE or step.get('outcome') not in FAILURES:
            continue
        name = step['id']
        logs = native_failure_diagnostics(run / 'run', [step])
        command = step.get('commands', [])[-1:]
        phase = command[0]['stage'] if command else 'preflight'
        facts['failed_cut'].append([name, phase])
        for row in command:
            facts['command_end'].append([name, phase, str(row.get('exit')),
                                         'timeout' if row.get('timeout') else 'returned'])
        for row in logs:
            if row['status'] != 'RECEIPT_BOUND':
                continue
            ref = (run / 'run' / name / row['log']).relative_to(root).as_posix()
            facts['command_log'].append([name, row['command'], ref])
            facts['diagnostic_location'].extend(
                [name, row['command'], ref, str(message['line'])] for message in row['diagnostics'])
        cut = dict(step=name, module=step['arguments']['module'], phase=phase,
                   outcome=step['outcome'], diagnostics=logs)
        trace = module_compiler_trace(run / 'run', step)
        if trace is not None:
            cut['compilerTrace'] = trace
            if trace['status'] == 'RECEIPT_BOUND':
                ref = (run / 'run' / trace['reference']).relative_to(root).as_posix()
                add_compiler_trace_facts(facts, trace, ref)
        cuts.append(cut)
    return cuts, facts


def _terminal(root, run, receipt):
    from gambit_smp.reasoning_history import read_execution_checkpoint
    prefix = read_execution_checkpoint(root, run)
    records = prefix['records']
    if not records:
        raise ValueError('repair requires a committed execution checkpoint')
    header, terminal = records[0]['payload'], records[-1]['payload']
    if (receipt.get('schema') != 'sealed-research-run.v1'
            or header['schema'] != 'research-run-header.v1'
            or terminal['schema'] != 'research-terminal-observation.v1'
            or header['recipe'] != receipt['recipe'] or header['engineId'] != receipt['engineId']
            or header['inputs'] != receipt['inputs']
            or terminal['outer'] != receipt or receipt.get('root') != str(root)
            or receipt.get('parentReaped') is not True or receipt.get('processGroupQuiescent') is not True):
        raise ValueError('repair requires the bound, quiescent terminal execution')
    return header, terminal['child'], prefix['prefixIdentity']


def _history(root, run, receipt):
    header, recorded_child, prefix = _terminal(root, run, receipt)
    child = decode_json(_bound_bytes(run, 'run/receipt.json', receipt.get('childReceiptSha256')))
    if (child != recorded_child or child.get('inputsStable') is not True
            or child.get('schema') != 'evidence-recipe-run.v1' or child.get('recipe') != receipt['recipe']):
        raise ValueError('repair requires stable child evidence from the committed execution')
    return header, child, prefix


def repair_context(root, run, receipt):
    """Expose diagnostic facts and the exact parent a model may select."""
    child = decode_json(_bound_bytes(run, 'run/receipt.json', receipt.get('childReceiptSha256')))
    cuts, facts = _cuts(root, run, child)
    from gambit_smp.rest_observation import bound_read
    rest = [observation for step in child['steps']
            if (observation := bound_read(run / 'run', step)) is not None]
    if rest and not cuts:
        return dict(run=str(run), restObservations=rest, executionAuthorized=False,
            runtimeAdmitted=False,
            claim='native-rest-contract-diagnostics-model-selects-next-action')
    if not cuts:
        return None
    _, _, prefix = _history(root, run, receipt)
    return dict(baselinePrefix=prefix, run=str(run), cuts=cuts, inference=_project(facts),
                **({'restObservations': rest} if rest else {}),
                executionAuthorized=False)


def _source_chain(rows, step):
    by_id = {row['id']: row for row in rows}
    configured = by_id[step['arguments']['source']['step']]
    materialized = by_id[configured['arguments']['source']['step']]
    if (configured['capability'] != 'gambit.configure'
            or materialized['capability'] != 'gambit.materialize'):
        raise ValueError('repair requires the hosted module source chain')
    return materialized


def _preparation_failures(run, child, target):
    """Expose failed ancestors as observations without interpreting their commands."""
    from gambit_smp.research_kernel import native_failure_diagnostics
    if target.get('outcome') != 'BLOCKED' or target.get('commands') or target.get('outputs'):
        return []
    by_id = {row['id']: row for row in child['steps']}
    pending = list(target['dependsOn'])
    ancestors = set()
    while pending:
        name = pending.pop()
        if name not in ancestors:
            ancestors.add(name)
            pending.extend(by_id[name]['dependsOn'])
    return [dict(step=row['id'], outcome=row['outcome'], reason=row.get('reason'),
                 diagnostics=native_failure_diagnostics(run / 'run', [row]))
            for row in child['steps'] if row['id'] in ancestors and row.get('outcome') in FAILURES]


def _configuration_inputs(steps, target, inputs):
    configure = next(row for row in steps if row['id'] == target['arguments']['source']['step'])
    return {field: inputs[value] for field, value in configure['arguments'].items()
            if isinstance(value, str) and value in inputs}


def _optional_evidence(root, name, sha):
    try:
        return _bound_bytes(root, name, sha)
    except (OSError, ValueError):
        return None


def _candidate_delta(root, run, baseline, baseline_inputs, steps, old_step, target, inputs, manifest):
    old_material = _source_chain(baseline['steps'], old_step)
    new_material = _source_chain(steps, target)
    lock_name = new_material['arguments']['sourceLock']
    lock = decode_json(_bound_bytes(root, lock_name, inputs[lock_name]))
    from gambit_smp.source_capabilities import validate_source_lock
    validate_source_lock(lock)
    if inputs.get(lock['patch']) != lock['patchSha256']:
        raise ValueError('repair requires the declared source patch bound by its lock')
    revision = next((row for row in old_material['commands'] if row['stage'] == 'locked-revision'), None)
    old_tree = old_material['outputs']['source']['identity']
    changes = [['source-file', name] for name, identity in sorted(lock['files'].items())
               if old_tree.get(name, {}).get('sha256') != identity['candidateSha256']]
    if revision is not None:
        old_revision = _optional_evidence(run / 'run' / old_material['id'], revision['stdoutPath'],
                                          revision['stdoutSha256'])
        if old_revision is not None and old_revision.strip() != lock['revision'].encode():
            changes.append(['source-revision', lock['revision']])
    old_name = old_step['id'] + '/observation.json'
    raw = _optional_evidence(run / 'run', old_name, old_step['artifacts'].get(old_name))
    observed = decode_json(raw) if raw is not None else {}
    spec_name = target['arguments']['bootstrapHost']
    host = decode_json(_bound_bytes(root, spec_name, inputs[spec_name]))
    fields(host, ('schema', 'kind', 'executable', 'sha256', 'qualification'))
    executable = relative(root, host['executable'])
    if (host['schema'] != 'gambit-bootstrap-host' or host['kind'] != 'interpreted-gsc'
            or not os.access(executable, os.X_OK) or digest(executable) != host['sha256']):
        raise ValueError('repair interpreter does not match the declared host')
    if observed.get('hostSha256') and host['sha256'] != observed['hostSha256']:
        changes.append(['interpreter', host['sha256']])
    module = target['arguments']['module']
    if module != old_step['arguments']['module']:
        changes.append(['module', module])
    if observed.get('gccSha256') and observed['gccSha256'] != manifest['hostTools']['gcc']['sha256']:
        changes.append(['syntax-compiler', manifest['hostTools']['gcc']['sha256']])
    configuration = _configuration_inputs(steps, target, inputs)
    old_configuration = _configuration_inputs(baseline['steps'], old_step, baseline_inputs)
    changes.extend(['configuration', field] for field in sorted(configuration.keys() | old_configuration.keys())
                   if configuration.get(field) != old_configuration.get(field))
    return changes, dict(sourceLockSha256=inputs[lock_name], patch=lock['patch'], patchSha256=lock['patchSha256'],
                         hostSha256=host['sha256'], module=module, configurationInputs=configuration)


def review_repair(root, run, recipe, steps, inputs, manifest, plan_path, *, task):
    """Review a caller-authored experiment against an actual failed cut."""
    from gambit_smp.reasoning_history import build_start_analysis
    from gambit_smp.research_kernel import content_id, require_incremental_builds
    if not task or not run.is_relative_to(root / '.cache/tasks' / task):
        raise ValueError('repair prior must belong to the selected task')
    plan_path = relative(root, plan_path.resolve().relative_to(root).as_posix())
    raw = plan_path.read_bytes()
    plan = decode_json(raw)
    fields(plan, ('schema', 'baselinePrefix', 'failureStep', 'targetStep', 'intent', 'hypothesis'), ('failureRun',))
    if (plan['schema'] != 'research-repair-plan.v1' or plan['intent'] not in ('probe', 'repair')
            or any(not isinstance(value, str) or not value.strip() for value in plan.values())):
        raise ValueError('typed repair plan with a model hypothesis required')
    predecessor = read_json(run / 'receipt.json')
    failure_run = relative(root, plan['failureRun']) if 'failureRun' in plan else run
    if not failure_run.is_relative_to(root / '.cache/tasks' / task):
        raise ValueError('repair failure must belong to the selected task')
    receipt = predecessor if failure_run == run else read_json(failure_run / 'receipt.json')
    header, child, prefix = _history(root, failure_run, receipt)
    lineage = [str(run)]
    preparation = []
    predecessor_child = None
    previous_repair = {}
    if prefix != plan['baselinePrefix']:
        raise ValueError('repair plan selected another baseline checkpoint')
    if failure_run != run:
        predecessor_header, predecessor_child, _ = _terminal(root, run, predecessor)
        previous_repair = predecessor.get('repair', {})
        if (not previous_repair.get('identity')
                or previous_repair['identity'] != predecessor_header.get('repair', {}).get('identity')
                or previous_repair.get('failureRun') != str(failure_run)
                or previous_repair.get('plan', {}).get('baselinePrefix') != prefix
                or previous_repair.get('plan', {}).get('failureStep') != plan['failureStep']):
            raise ValueError('repair predecessor is outside the selected failure lineage')
        previous_target = previous_repair['plan']['targetStep']
        previous_steps = predecessor_header['declaration']['steps']
        previous_step = next((row for row in previous_steps if row['id'] == previous_target), None)
        if previous_step is None:
            raise ValueError('repair predecessor lacks the selected target declaration')
        previous_candidate = predecessor_header['repair']['candidate']
        if previous_candidate['inputs'] != predecessor['inputs']:
            raise ValueError('repair predecessor differs from its committed candidate inputs')
        if predecessor_child and predecessor_child.get('inputsStable') is True:
            recorded_target = next((row for row in predecessor_child['steps'] if row['id'] == previous_target), None)
            if recorded_target is not None:
                preparation = _preparation_failures(run, predecessor_child, recorded_target)
        lineage = [*previous_repair['lineage'], str(run)]
    cuts, facts = _cuts(root, failure_run, child)
    cut = next((row for row in cuts if row['step'] == plan['failureStep']), None)
    if cut is None:
        raise ValueError('repair plan must select a failed hosted module')
    target = next((row for row in steps if row['id'] == plan['targetStep']), None)
    if target is None or not _hosted(target):
        raise ValueError('repair target must be a hosted module with syntax verification')
    old_step = next(row for row in child['steps'] if row['id'] == cut['step'])
    build = build_start_analysis({'declaration': {'steps': steps}})
    violations = []
    if (any(reason == 'native-producer' for _, reason in build['relations']['build_obligation'])
            or any(key in recipe for key in ('continuationRequest', 'continuationLedger', 'buildMigration'))):
        violations.append(['diagnostic-scope'])
    old_recipe = header['declaration']
    ceilings = {}
    for row in old_recipe['steps']:
        kind = row['capability']
        ceilings[kind] = max(ceilings.get(kind, 0), row['budgetSeconds'])
    policy = recipe.get('timeoutPolicy')
    previous_policy = old_recipe.get('timeoutPolicy')
    compatible_policy = (policy == previous_policy or (
        policy is not None and previous_policy is not None
        and policy['mode'] == previous_policy['mode']
        and policy['overheadSeconds'] <= previous_policy['overheadSeconds']))
    widened = []
    budget_violation = False
    guard_child = predecessor_child if predecessor_child and predecessor_child.get('steps') else None
    if guard_child is None and failure_run != run:
        # An abandoned over-wide attempt may have no child receipt. The hang
        # guard still comes from the last attempt that actually timed out
        # while working, not from the 3600-second ceiling.
        for path in reversed(previous_repair.get('lineage') or []):
            older_run = Path(path)
            if older_run == run:
                continue
            try:
                _, older_child, _ = _terminal(root, older_run, read_json(older_run / 'receipt.json'))
            except (OSError, ValueError, KeyError, TypeError):
                continue
            if older_child and any(row.get('outcome') == 'TIMEOUT' for row in older_child.get('steps') or []):
                guard_child = older_child
                break
    if failure_run != run and guard_child is not None:
        from gambit_smp.recipes import hang_guard_widening
        try:
            # Raise only the stage that timed out while still loading.
            # 600 seconds is the working guard. 3600 is only the ceiling.
            # 295/300 stays untouched.
            widened = hang_guard_widening(predecessor, steps, child_steps=guard_child.get('steps'))
        except ValueError:
            budget_violation = True
    retained = []
    if not widened and guard_child is not None:
        match = next((row for row in guard_child.get('steps') or [] if row.get('id') == target['id']), None)
        # A source fix at the same already-raised guard is not a new expansion.
        if (isinstance(match, dict)
                and target['budgetSeconds'] == match.get('budgetSeconds')
                and target['budgetSeconds'] > old_step['budgetSeconds']):
            retained = [{'step': target['id'], 'from': old_step['budgetSeconds'],
                         'to': target['budgetSeconds']}]
    guard_steps = widened or retained
    widened_ids = {item['step'] for item in guard_steps}
    allowed_recipe = receipt['budgetSeconds'] + sum(item['to'] - item['from'] for item in guard_steps)
    if (budget_violation or not compatible_policy
            or recipe['budgetSeconds'] > allowed_recipe
            or (target['budgetSeconds'] > old_step['budgetSeconds'] and target['id'] not in widened_ids)
            or any(row['capability'] in ceilings and row['budgetSeconds'] > ceilings[row['capability']]
                   and row['id'] not in widened_ids for row in steps)):
        violations.append(['diagnostic-budget'])
    if plan['intent'] == 'repair' and target['arguments']['module'] != cut['module']:
        violations.append(['repair-requires-original-module'])
    changes, binding = [], {}
    if not violations:
        require_incremental_builds(recipe, steps)
        changes, binding = _candidate_delta(root, failure_run, child, receipt['inputs'], steps,
                                            old_step, target, inputs, manifest)
        facts['delta_checked'] = [[]]
    if failure_run != run and not violations:
        previous_bindings = {name: previous_candidate[name] for name in ('sourceLockSha256', 'hostSha256', 'module')}
        old_patch = predecessor['inputs'].get(binding['patch'])
        if old_patch:
            previous_bindings['patchSha256'] = old_patch
        previous_configuration = _configuration_inputs(previous_steps, previous_step, predecessor['inputs'])
        current_configuration = binding['configurationInputs']
        configuration_fields = sorted(previous_configuration.keys() | current_configuration.keys())
        facts['predecessor_input'] = [[name, value] for name, value in previous_bindings.items()]
        facts['candidate_input'] = [[name, binding[name]] for name in previous_bindings]
        for field in configuration_fields:
            facts['predecessor_input'].append(['configuration:' + field, previous_configuration.get(field, 'absent')])
            facts['candidate_input'].append(['configuration:' + field, current_configuration.get(field, 'absent')])
    facts['failed_cut'] = [[cut['step'], cut['phase']]]
    if guard_steps:
        facts['hang_guard_widened'] = [[item['step'], str(item['from']), str(item['to'])] for item in guard_steps]
    facts.update(proposed=[[plan['intent']]], causal_delta=changes, violation=violations)
    graph = build['facts']
    facts['repair_step'] = graph['step']
    facts['hosted_module'] = graph['hosted_module']
    products = {}
    for capability, kind in graph['capability_output']:
        products.setdefault(capability, []).append(kind)
    facts['repair_product'] = [[step, kind] for step, capability in graph['step']
                               for kind in products.get(capability, ())]
    analysis = _project(facts)
    selection = dict(plan=plan, planSha256=hashlib.sha256(raw).hexdigest(), prior=str(run),
                     failureRun=str(failure_run), lineage=lineage,
                     candidate=dict(recipe=recipe['id'], inputs=inputs, engineId=manifest['engineId'], **binding))
    if preparation:
        selection['predecessorPreparationFailures'] = preparation
    return dict(selection, identity=content_id(selection), failure=cut, inference=analysis,
                status='eligible' if analysis['relations']['eligible'] else 'blocked')


def verify_repair(run, receipt, repair):
    """Classify the fresh observed attempt without upgrading producer credit."""
    result = dict(repair, status='inconclusive')
    if not receipt.get('childReceiptSha256'):
        return result
    try:
        child = decode_json(_bound_bytes(run, 'run/receipt.json', receipt['childReceiptSha256']))
        step = next(row for row in child['steps'] if row['id'] == repair['plan']['targetStep'])
        candidate = repair['candidate']
        if (child.get('inputsStable') is not True or receipt['outcome'] == 'STALE'
                or receipt['inputs'] != candidate['inputs'] or receipt['engineId'] != candidate['engineId']
                or receipt.get('parentReaped') is not True or receipt.get('processGroupQuiescent') is not True
                or step.get('reused') or step['arguments']['module'] != candidate['module']):
            return result
        preparation = _preparation_failures(run, child, step)
        if preparation:
            result['preparationFailures'] = preparation
            return result
        name = step['id'] + '/observation.json'
        observed = decode_json(_bound_bytes(run / 'run', name, step['artifacts'].get(name)))
        if (observed.get('inputsStable') is not True or observed.get('module') != candidate['module']
                or observed.get('hostSha256') != candidate['hostSha256']
                or observed.get('targetBinding', {}).get('sourceLockSha256') != candidate['sourceLockSha256']):
            return result
        facts = dict(repair['inference']['facts'])
        if step['outcome'] in FAILURES or step['outcome'] == 'PASS':
            facts['observed_cut'] = [[]]
        commands = {row['stage']: row for row in step.get('commands', [])}
        completed = all(commands.get(phase, {}).get('exit') == 0
                        and commands[phase].get('timeout') is False
                        and commands[phase].get('parentReaped') is True
                        and commands[phase].get('processGroupQuiescent') is True
                        for phase in ('regenerate-module', 'module-syntax-check'))
        if (receipt['outcome'] == step['outcome'] == 'PASS' and completed
                and observed.get('syntaxChecked') is True):
            generated = step['outputs']['generated']
            if (generated['type'] == 'c-source' and 'origin' not in generated and 'workspace' not in generated
                    and generated['sha256'] == observed.get('generatedSha256')
                    and _bound_bytes(run / 'run', generated['path'], generated['sha256'])):
                facts['verified_cut'] = [[]]
        verdict = _project(facts)
        if verdict['sourceInputs'] != repair['inference']['sourceInputs']:
            return result
        result.update(verification=verdict, outcome=step['outcome'],
                      observationSha256=step['artifacts'][name])
        if facts.get('verified_cut') and verdict['relations']['verified']:
            result['status'] = 'verified'
        elif facts.get('observed_cut') and verdict['relations']['probe_observed']:
            result['status'] = 'probe-observed'
        elif step['outcome'] in FAILURES:
            result['status'] = 'failed'
    except (OSError, ValueError, KeyError, TypeError, RuntimeError, StopIteration) as error:
        result['verificationError'] = str(error)
    return result


def retained_repair(root, run, receipt):
    recorded = receipt['repair']
    if not receipt.get('childReceiptSha256'):
        return dict(identity=recorded['identity'], status='inconclusive', executionAuthorized=False)
    _history(root, run, receipt)
    current = verify_repair(run, receipt, recorded)
    current['recordedStatus'] = recorded['status']
    return current
