"""Work items own task roots; a process role never creates another work item."""
import json
import os
from pathlib import Path


def execution_boundary(root, task=None):
    task = task or os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task:
        return None
    return admit(root, task).get('executionBoundary')


def admit_adapter(root, task, command):
    """Legacy adapters cannot bypass a scoped task's declarative executor."""
    inherited = os.environ.get('GAMBIT_SMP_TASK_ID')
    if inherited and inherited != task and execution_boundary(root, inherited) is not None:
        raise ValueError('a dependency cannot switch the inherited work-item owner')
    if execution_boundary(root, task) is not None and command not in {'research', 'agent'}:
        raise ValueError('scoped work-item actions require the research capability graph; legacy adapters are not admitted')


def context_task(ctx):
    inherited = os.environ.get('GAMBIT_SMP_TASK_ID')
    declared = ctx.env.get('GAMBIT_SMP_TASK_ID')
    if inherited and declared and inherited != declared and execution_boundary(ctx.root, inherited) is not None:
        raise ValueError('an execution environment cannot switch the inherited work-item owner')
    return inherited or declared


def admit_command(root, task, argv):
    """Restricted work items enter the existing declarative executor only.

    A Python/shell maintenance driver is not a capability or component grant.
    This is a framework admission boundary, not an OS sandbox.
    """
    if execution_boundary(root, task) is None:
        return
    expected = Path(root) / '.venv/bin/gambit-smp'
    if (not argv or Path(argv[0]).resolve() != expected.resolve()
            or len(argv) < 3 or argv[1] != 'research'):
        raise ValueError('work-item boundary requires the declarative research CLI; inline Python/shell drivers are not admitted')
    from gambit_smp.research_kernel import argument_parser
    args = argument_parser().parse_args(argv[2:])
    if args.seal is not None or (args.read is not None and args.out is None and not args.portable_seal):
        # Existing framework preparation/read lifecycle; neither executes a
        # Recipe nor turns an observation into runtime acceptance.
        return
    if args.run is None:
        raise ValueError('work-item execution requires a declared research Recipe')
    from gambit_smp.recipes import load, discover
    if '/' not in args.run and not args.run.endswith('.recipe.json'):
        path = discover(Path(root)).get(args.run)
        if path is None:
            raise ValueError('unknown declared research Recipe')
    else:
        path = Path(args.run)
        if not path.is_absolute():
            path = Path(root) / path
    recipe, steps = load(Path(root), path)
    check_recipe_boundary(root, recipe, steps, task=task)


def check_recipe_boundary(root, recipe, steps, *, task=None):
    boundary = execution_boundary(root, task)
    if boundary is None:
        return None
    if set(boundary) != {'model', 'part'}:
        raise ValueError('model-owned execution boundary reference required')
    if not {'docs/work-items.json', 'evidence/dsl/work-item-boundary.ss',
            'tests/recipes/framework-contracts/work-item-boundary-entry.json'} <= set(recipe['inputs']):
        raise ValueError('work-item boundary requires its declared ASCENT rule closure')
    gates = [s for s in steps if s['capability'] == 'research.audit'
             and s['arguments'].get('boundary') is True]
    if len(gates) != 1:
        raise ValueError('exactly one SysML/ASCENT work-item boundary gate required')
    gate = gates[0]
    ref = gate['arguments']['projection']
    by_id = {s['id']: s for s in steps}
    projection = by_id.get(ref['step'])
    if (projection is None or projection['capability'] != 'sysml.project'
            or projection['id'] not in gate['dependsOn']
            or ref['output'] != 'projection'
            or projection['arguments'].get('part') != boundary['part']
            or boundary['model'] not in projection['arguments']['models']
            or boundary['model'] not in recipe['inputs']):
        raise ValueError('boundary must use its registered native SysML projection')
    for step in steps:
        if not isinstance(step.get('component'), str) or not step['component']:
            raise ValueError('each scoped capability requires an explicit component')
        if step['id'] in {gate['id'], projection['id']}:
            continue
        # Every action, including a formal action, waits for the same decision.
        ancestors, pending = set(), list(step['dependsOn'])
        while pending:
            name = pending.pop()
            if name in ancestors:
                continue
            ancestors.add(name)
            pending.extend(by_id[name]['dependsOn'])
        if gate['id'] not in ancestors:
            raise ValueError('work-item boundary must dominate every research action')
    from gambit_smp.framework import digest
    return {'task': task or os.environ['GAMBIT_SMP_TASK_ID'],
            'gate': gate['id'], 'projection': projection['id'],
            'registrationSha256': digest(Path(root)/'docs/work-items.json')}


def require_boundary_context(ctx):
    task = context_task(ctx)
    current = execution_boundary(ctx.root, task)
    boundary = ctx.receipt.get('workItemBoundary')
    if current is None and boundary is None:
        return None
    if current is None:
        raise ValueError('work-item boundary registration was withdrawn during execution')
    steps = getattr(ctx, 'planned_steps', ())
    if not boundary or not steps:
        raise ValueError('unstructured ExecutionContext has no work-item boundary grant')
    if boundary['task'] != task:
        raise ValueError('work-item boundary belongs to another task')
    from gambit_smp.framework import digest
    if boundary['registrationSha256'] != digest(Path(ctx.root)/'docs/work-items.json'):
        raise ValueError('work-item boundary registration changed during execution')
    if ctx.directory.name in {boundary['gate'], boundary['projection']}:
        return None
    if ctx.outcomes.get(boundary['gate']) != 'PASS':
        raise ValueError('work-item boundary decision is missing or denied')
    result = json.loads(ctx.artifact({'step': boundary['gate'], 'output': 'observation'},
                                    'research-audit-observation').read_text())
    if result.get('scopeAdmitted') is not True or result.get('task') != boundary['task']:
        raise ValueError('work-item boundary receipt does not grant this task')
    return result['policy']


def evaluate_boundary(args, ctx):
    """Project model ownership; ASCENT alone decides the finite action graph."""
    from gambit_smp.evidence_capabilities import evaluate_observations
    from gambit_smp.workspace import write
    task = context_task(ctx)
    boundary = execution_boundary(ctx.root, task)
    if boundary is None:
        raise ValueError('registered work-item execution boundary required')
    projection = json.loads(ctx.artifact(args['projection'], 'sysml-source-contract').read_text())
    policy = projection['values']
    if policy.get('taskId') != task or policy.get('scopeId') != admit(ctx.root, task)['scope']:
        raise ValueError('SysML scope differs from its registered work item')
    required = {'taskId', 'scopeId', 'ownedComponents', 'externalOwners',
                'allowedCapabilities', 'readOnlyCapabilities', 'mutableSourcePaths', 'baselineRevision',
                'modelOwners'}
    if (not required <= set(policy) or set(policy)-required-{'sourceDeltaReceipts','sourcePolicy','runtimeMode'}
            or any(type(v) is not str or not v for v in policy.values())):
        raise ValueError('complete typed execution-boundary policy required')
    if policy.get('sourcePolicy','published-support') not in ('direct','published-support'):
        raise ValueError('closed source execution policy required')
    if policy.get('runtimeMode','build-concurrency') not in ('build-concurrency','native-smp'):
        raise ValueError('closed runtime scope required')
    split = lambda name: policy[name].split(';')
    if not set(split('readOnlyCapabilities')) <= set(split('allowedCapabilities')):
        raise ValueError('read-only capability must be part of the model allowlist')
    owners = [[c, task] for c in split('ownedComponents')]
    owners += [row.split('=', 1) for row in split('externalOwners')]
    if any(len(row) != 2 or not all(row) for row in owners) or len({r[0] for r in owners}) != len(owners):
        raise ValueError('unique explicit component ownership required')
    actions = [[s['id'], task, s['component'], s['capability']] for s in ctx.planned_steps
               if s['id'] not in {ctx.receipt['workItemBoundary']['gate'], ctx.receipt['workItemBoundary']['projection']}]
    model_owners = [row.split('=', 1) for row in split('modelOwners')]
    if any(len(row) != 2 or not all(row) for row in model_owners):
        raise ValueError('explicit formal source ownership required')
    subjects = []
    for step in ctx.planned_steps:
        if step['id'] not in {a[0] for a in actions}:
            continue
        if step['capability'] in {'lean.check', 'quint.observe'}:
            sources = [arg for arg in step['arguments']['argv'] if arg.endswith(('.lean', '.qnt'))]
            sources += [row['source'] for row in step['arguments'].get('modules', [])]
            if not sources:
                sources = ['unmapped-formal-source']
            for source in sources:
                matches = [owner for prefix, owner in model_owners if source.startswith(prefix)]
                if len(matches) != 1:
                    raise ValueError('formal source has missing or ambiguous component ownership: ' + source)
                subjects.append([step['id'], matches[0]])
        else:
            subjects.append([step['id'], step['component']])
    facts = {'scope_owner': owners, 'scope_action': actions,
             'scope_subject': subjects,
             'scope_allow': [[task, c] for c in split('allowedCapabilities')],
             'scope_read': [[task, c] for c in split('readOnlyCapabilities')],
             'scope_blocked_by': [[task, c] for c, owner in owners if owner != task]}
    result = evaluate_observations(ctx, [], facts,
        {'Denied': 'scope_denied', 'Permitted': 'scope_permitted'}, 'work-item-scope',
        dsl='tests/recipes/framework-contracts/work-item-boundary-entry.json')
    if result.get('Denied') != [] or sorted(result.get('Permitted', [])) != sorted([[a[0]] for a in actions]):
        raise ValueError('ASCENT denied an unowned component or capability; dependency failure grants no authority')
    target = ctx.directory / 'observation.json'
    write(target, dict(task=task, policy=policy, scopeAdmitted=True, runtimeAdmitted=False,
                       facts=facts, decision=result))
    return {'outputs': ctx.publish('observation', 'research-audit-observation', target)}


def admit_source_delta(ctx, source):
    """A scoped build cannot smuggle a GC/SMP rewrite in its input checkout."""
    policy = require_boundary_context(ctx)
    if policy is None:
        return
    from fnmatch import fnmatchcase
    baseline = policy['baselineRevision']
    import re
    if not re.fullmatch('[0-9a-f]{40}', baseline):
        raise ValueError('model-bound source baseline revision required')
    changed = ctx.require('scope-source-delta', [ctx.tools['git'], 'diff', '--name-only', '-z', baseline, '--'], source, 10)
    untracked = ctx.require('scope-source-untracked', [ctx.tools['git'], 'ls-files', '--others', '--exclude-standard', '-z'], source, 10)
    patterns = policy['mutableSourcePaths'].split(';')
    denied = [p for p in (changed + untracked).split('\0') if p and not any(fnmatchcase(p, pat) for pat in patterns)]
    # A narrowly admitted dependency repair is a specific old-blob/new-byte
    # pair, not permission to edit every runtime/GC function in that file.
    receipts = {}
    for row in filter(None,policy.get('sourceDeltaReceipts','').split(';')):
        match = re.fullmatch(r'([^=]+)=([0-9a-f]{40}):([0-9a-f]{64})',row)
        if match is None or match[1] in receipts:
            raise ValueError('exact unique source-delta receipt required')
        receipts[match[1]] = (match[2],match[3])
    from gambit_smp.framework import digest
    remaining = []
    for name in sorted(set(denied)):
        if name not in receipts:
            remaining.append(name);continue
        expected_blob,expected_bytes = receipts[name]
        blob = ctx.require('scope-source-blob-'+expected_blob,
            [ctx.tools['git'],'rev-parse',baseline+':'+name],source,10).strip()
        original = Path(source)/name
        if original.is_symlink():raise ValueError('source-delta receipt rejects aliases: '+name)
        path = original.resolve(strict=True)
        if (blob != expected_blob or not path.is_relative_to(Path(source).resolve())
                or digest(path) != expected_bytes):
            raise ValueError('source-delta receipt does not match exact repair: '+name)
        ctx.bind([path])
    denied = remaining
    if denied:
        raise ValueError('unowned source changes require their component owner, not a Darwin repair: ' + ', '.join(sorted(set(denied))))


def build_recovery_links(root, product):
    """Read a product's explicit generated-link cleanup boundary, not source policy."""
    import os
    task=os.environ.get('GAMBIT_SMP_TASK_ID')
    if not task:raise ValueError('build recovery requires task custody')
    links=admit(root,task,os.environ.get('GAMBIT_SMP_TASK_PROCESS')).get(
        'buildProducts',{}).get(product,{}).get('recoveryLinks',{})
    if not isinstance(links,dict):raise ValueError('registered recovery link map required')
    from gambit_smp.source_capabilities import source_name
    for name,target in links.items():
        source_name(name)
        if type(target) is not str or not target or '\0' in target or Path(target).is_absolute():
            raise ValueError('relative registered recovery link target required')
    return links


def admit(root,task,process=None):
    from gambit_smp.workspace import bounded,identifier
    root=Path(root).resolve();identifier(task)
    plan=bounded(root,'docs/work-items.json')
    if plan.exists():
        document=json.loads(plan.read_text())
        if document.get('schema')!='gambit-work-items.v1':raise ValueError('typed work-item plan required')
        items=document['items'];scopes=[item['scope'] for item in items.values()]
        if len(scopes)!=len(set(scopes)):raise ValueError('one task root per work-item scope')
        if task not in items:raise ValueError('task is not a registered work item; use an existing work-item process')
        item=items[task]
    else:
        # An unconfigured checkout bootstraps one work item, never arbitrary
        # concurrent role/provider/date aliases. More work items need a plan.
        policy=bounded(root,'.state/task-policy.json')
        default=json.loads(policy.read_text()).get('defaultTask') if policy.exists() else None
        active=[]
        for file in bounded(root,'.state/tasks').glob('*.json'):
            row=json.loads(file.read_text())
            if row.get('state')!='closed' and not row.get('retiredInto'):active.append(row['task'])
        if (default and task!=default) or any(name!=task for name in active):
            raise ValueError('checkout already has a work item; register an issue or use its process')
        item=dict(scope=task,processes={'audit':'maintenance','validation':'maintenance','evidence':'maintenance'})
    if process is not None:
        identifier(process)
        if process not in item.get('processes',{}):raise ValueError('process role is not registered for this work item')
        if item['processes'][process]!='maintenance':raise ValueError('independent process requires maintenance scope')
    return item
