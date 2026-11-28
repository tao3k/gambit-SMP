"""Typed source handoff interfaces; no event executor or second temporal model.

Receipt roles denote evidence required at real call boundaries. A declaration
does not produce that evidence, grant authority, or create a runtime object.
"""


KINDS = {'install','park','producer','scan','observe','resume','retire'}
PURPOSES = {'parent-ack':'install','access-stopped':'park','producer-closed':'producer',
            'scan-status':'scan','observe-origin':'observe','reload-after-resume':'resume',
            'retire-storage':'retire'}


def validate_handoff(flow):
    adapters = {row['id']:row for row in flow.get('adapters',[])}
    sites = {row['id']:row for row in flow.get('sourceSites',[])}
    clauses = {row['id']:row for row in flow.get('adapterClauses',[])}
    def records(group, fields):
        result = {}
        for row in flow.get(group,[]):
            if any(not isinstance(row.get(field),str) or not row[field] for field in fields):
                raise ValueError('complete typed handoff record required: '+group)
            if row['id'] in result:
                raise ValueError('unique handoff identities required')
            result[row['id']]=row
        return result
    protocols = records('handoffProtocols',('id','key','joinRule','scope','valuePolicy','unknownRule','retirement','acceptance','nonGoals'))
    receipts = records('handoffReceipts',('id','kind','identity','condition','outcomes','permits','forbids','unknown'))
    points = records('handoffPoints',('id','caller','precondition','linearization','missing','unknown','acceptance'))
    for row in protocols.values():
        if row.get('adapter') not in adapters:
            raise ValueError('handoff protocol needs an actual adapter')
        kinds = [receipt['kind'] for receipt in receipts.values() if receipt.get('protocol')==row['id']]
        if len(kinds)!=len(KINDS) or set(kinds)!=KINDS:
            raise ValueError('whole handoff needs all distinct receipt roles')
    for row in receipts.values():
        if row.get('protocol') not in protocols or row['kind'] not in KINDS:
            raise ValueError('receipt needs its actual protocol and role')
    for row in points.values():
        protocol = protocols.get(row.get('protocol'))
        if not protocol:
            raise ValueError('point needs an actual handoff protocol')
        adapter = adapters[protocol['adapter']]; site = sites.get(row.get('site')); clause = clauses.get(row.get('clause'))
        if not site or site['question']!=adapter['question'] or not clause or clause['adapter']!=adapter['id']:
            raise ValueError('handoff point must use its real owned site and existing clause')
    used_points,used_receipts,seen = set(),set(),set()
    for row in flow.get('handoffUses',[]):
        point,receipt = points.get(row.get('point')),receipts.get(row.get('receipt'))
        if not point or not receipt or point['protocol']!=receipt['protocol']:
            raise ValueError('handoff use cannot escape its protocol')
        if PURPOSES.get(row.get('purpose'))!=receipt['kind'] or row.get('role') not in {'requires','establishes'}:
            raise ValueError('receipt role cannot authorize a different handoff decision')
        if not isinstance(row.get('condition'),str) or not row['condition']:
            raise ValueError('handoff use needs a guarded condition')
        key=(row['point'],row['receipt'],row['role'],row['purpose'])
        if key in seen:
            raise ValueError('duplicate handoff use')
        seen.add(key);used_points.add(row['point']);used_receipts.add(row['receipt'])
    if used_points!=set(points) or used_receipts!=set(receipts):
        raise ValueError('handoff cannot leave points or receipt roles unconnected')
    if any(not any(point['protocol']==key for point in points.values()) for key in protocols):
        raise ValueError('protocol requires real call boundaries')


def protocol_views(flow, adapter):
    result=[]
    for protocol in flow.get('handoffProtocols',[]):
        if protocol['adapter']!=adapter:
            continue
        points=[point for point in flow['handoffPoints'] if point['protocol']==protocol['id']]
        ids={point['id'] for point in points}
        result.append(dict(protocol,receipts=[row for row in flow['handoffReceipts'] if row['protocol']==protocol['id']],
                           points=points,uses=[row for row in flow['handoffUses'] if row['point'] in ids],semanticVerified=False))
    return result
