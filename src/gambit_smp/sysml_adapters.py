"""Whole source-adapter contracts and exact multi-file evidence subjects.

Bindings scope attestations; they cannot certify their semantic truth. No native
work, additional proof engine or source-location-to-closure rule is provided.
"""
import hashlib
from pathlib import Path

from gambit_smp.sysml_organization import _path, source_bindings


def validate_adapters(flow):
    adapters, clauses = flow.get('adapters', []), flow.get('adapterClauses', [])
    if not adapters:
        if clauses or any(flow.get(key) for key in ('inventoryScopes','accessFamilies','sourceCases','caseDependencies',
                                                   'handoffProtocols','handoffReceipts','handoffPoints','handoffUses')):
            raise ValueError('adapter clauses require whole adapter contracts')
        return
    questions = {row['id']:row for row in flow['questions']}
    sites = {row['id']:row for row in flow['sourceSites']}
    identities, owners = {}, set()
    fields = ('id','inputs','precondition','authorization','linearization','postcondition',
              'recovery','retirement','stateModel','dataModel','acceptance','rejection','benefit')
    for row in adapters:
        if any(not isinstance(row.get(field),str) or not row[field] for field in fields):
            raise ValueError('complete adapter contract required')
        question = questions.get(row.get('question'))
        if not question or question['owner'] != 'source' or question['id'] in owners or row['id'] in identities:
            raise ValueError('one whole adapter per source-owned question required')
        identities[row['id']] = row; owners.add(question['id'])
    if owners != {row['id'] for row in questions.values() if row['owner']=='source'}:
        raise ValueError('all source-owned questions require whole adapters')
    kinds = {'coverage','exclusion','publication','reentry','failure','validation'}
    found = {key:set() for key in identities}
    used = set()
    for row in clauses:
        adapter, site = identities.get(row.get('adapter')), sites.get(row.get('site'))
        if not adapter or not site or site['question'] != adapter['question']:
            raise ValueError('adapter clause needs its own actual source site')
        if any(not isinstance(row.get(field),str) or not row[field] for field in
               ('id','kind','rule','missing','acceptance')) or row['id'] in used:
            raise ValueError('unique complete adapter clauses required')
        if row['kind'] not in kinds:
            raise ValueError('unsupported adapter clause kind')
        used.add(row['id']); found[adapter['id']].add(row['kind'])
    if any(value != kinds for value in found.values()):
        raise ValueError('whole adapter needs coverage/exclusion/publication/reentry/failure/validation')
    from gambit_smp.sysml_inventory import validate_inventory
    validate_inventory(flow)
    from gambit_smp.sysml_refinement import validate_cases
    validate_cases(flow)
    from gambit_smp.sysml_handoff import validate_handoff
    validate_handoff(flow)


def adapter_bindings(root, projection):
    """Bind every clause to its full question footprint, not just a primary file.

The complete native-evaluated model flow is part of the subject. Source sites
are re-read, including all conditional matches and dirty bytes. Changing any
required input invalidates an old attestation. The reader is not an atomic
filesystem snapshot and does not prove completeness of the authored inventory.
"""
    from gambit_smp.sysml_flow import _identity
    flow = projection['flow']; validate_adapters(flow)
    root = Path(root).resolve(); sites = source_bindings(root,flow)
    questions = {row['id']:row for row in flow['questions']}
    result = []
    for adapter in flow.get('adapters', []):
        question = questions[adapter['question']]
        path = root/_path(question['artifact'])
        if path.resolve() != path or not path.is_file():
            raise ValueError('actual adapter primary source required')
        clauses = [row for row in flow['adapterClauses'] if row['adapter']==adapter['id']]
        sources = [row for row in sites if row['question']==question['id']]
        from gambit_smp.sysml_inventory import inspect_inventory
        inventory = inspect_inventory(root,flow,adapter['id'])
        cases = [row for row in flow.get('sourceCases',[]) if row['clause'] in {c['id'] for c in clauses}]
        from gambit_smp.sysml_handoff import protocol_views
        protocols = protocol_views(flow,adapter['id'])
        subject = dict(modelInputs=projection['modelInputs'], flowSha256=projection['flowSha256'],
                       contract=adapter, question=question, clauses=clauses, sites=sources,
                       inventorySha256=inventory['subjectSha256'],
                       sourceCases=cases,caseDependencies=flow.get('caseDependencies',[]),
                       protocols=protocols,
                       primarySha256=hashlib.sha256(path.read_bytes()).hexdigest())
        result.append(dict(adapter, clauses=clauses, sources=sources, inventory=inventory,sourceCases=cases,protocols=protocols,
                           subjectSha256=_identity(subject),semanticVerified=False))
    return result
