"""Work items own task roots; a process role never creates another work item."""
import json
from pathlib import Path


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
