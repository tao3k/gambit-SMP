"""Model-owned flow contracts, projected by the existing OpenSysML SDK owner.

No process runner, model cache, layout file or runtime permission lives here.
Schema types are interpreted; component members and edges are discovered from
resolved SDK symbols, never supplied as a second Python inventory.
"""
import hashlib
import json
from pathlib import Path
import re


def _sha(value):
    return hashlib.sha256(value).hexdigest()


def _identity(value):
    return _sha(json.dumps(value, sort_keys=True, separators=(',', ':'), allow_nan=False).encode())


def _name(value):
    if not isinstance(value, str) or not re.fullmatch(r'[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*', value):
        raise ValueError('literal qualified SysML symbol required')
    return value


def _scalars(model, symbol):
    instance = model.instantiate(symbol.id)
    values = {attribute.name: instance[attribute.name] for attribute in symbol.attributes()}
    if any(type(value) not in (str, int, bool) for value in values.values()):
        raise ValueError('resolved scalar flow attributes required: ' + symbol.id)
    return values


def _parts(symbol):
    return [child for child in symbol.children() if child.kind.lower() == 'partusage']


def _flow_parts(model, root, namespace):
    """Follow native, model-declared package modules without a Python inventory.

    Public SysML imports retain the entry namespace's qualified lookup paths.
    Module declarations only organize source ownership; they grant no proof or
    runtime authority and never become a second component/obligation list.
    """
    active, expanded = set(), set()

    def visit(package):
        if package.id in active:
            raise ValueError('cyclic flow module assembly')
        if package.id in expanded:
            raise ValueError('duplicate flow module assembly')
        active.add(package.id)
        for symbol in _parts(package):
            facts = symbol.type_facts
            if facts and facts.resolved_id == namespace + '::ModelModule':
                target = _name(_scalars(model, symbol).get('namespace'))
                module = model.find(target)
                if module is None or module.kind.lower() != 'package':
                    raise ValueError('flow module needs a resolved native package')
                yield from visit(module)
            else:
                yield symbol
        active.remove(package.id)
        expanded.add(package.id)

    yield from visit(root)


def project_flow(model, namespace, metadata):
    """Read one opt-in flow schema from the already parsed, diagnostic-free model."""
    _name(namespace)
    if metadata.get('projectionKind') != 'flow-contract':
        raise ValueError('model must opt into the flow-contract schema')
    root = model.find(namespace)
    if root is None:
        raise ValueError('flow namespace missing')
    groups = {name: [] for name in ('components', 'questions', 'external', 'dependencies',
                                   'externalDependencies', 'flows', 'uses', 'views',
                                   'workstreams', 'assignments', 'workDependencies',
                                   'progressAxes', 'sourceSites', 'adapters', 'adapterClauses',
                                   'inventoryScopes', 'accessFamilies', 'sourceCases', 'caseDependencies',
                                   'handoffProtocols','handoffReceipts','handoffPoints','handoffUses',
                                   'supportFactors')}
    # These are grammar roles, not model members or dependency inventories.
    roles = {'Component': 'components', 'Question': 'questions', 'ImportedNeed': 'external',
             'Dependency': 'dependencies', 'ExternalDependency': 'externalDependencies',
             'Flow': 'flows', 'Use': 'uses', 'View': 'views',
             'Workstream': 'workstreams', 'Assignment': 'assignments',
             'WorkDependency': 'workDependencies', 'ProgressAxis': 'progressAxes',
             'SourceSite': 'sourceSites', 'AdapterContract': 'adapters',
             'AdapterClause': 'adapterClauses', 'InventoryScope': 'inventoryScopes',
             'AccessFamily': 'accessFamilies', 'SourceCase': 'sourceCases',
             'CaseDependency': 'caseDependencies', 'HandoffProtocol':'handoffProtocols',
             'HandoffReceipt':'handoffReceipts', 'HandoffPoint':'handoffPoints', 'HandoffUse':'handoffUses',
             'SupportFactor':'supportFactors'}
    endpoints = {'Dependency': ('dependent', 'prerequisite'),
                 'ExternalDependency': ('dependent', 'prerequisite'),
                 'Flow': ('producer', 'consumer'), 'Use': ('component', 'question'),
                 'Assignment': ('question', 'workstream'),
                 'WorkDependency': ('dependent', 'prerequisite'), 'SourceSite': ('question',),
                 'AdapterContract': ('question',), 'AdapterClause': ('adapter','site'),
                 'InventoryScope': ('adapter',), 'AccessFamily': ('adapter','site'),
                 'SourceCase': ('clause','entrySite','exitSite'),
                 'CaseDependency': ('dependent','prerequisite'), 'HandoffProtocol':('adapter',),
                 'HandoffReceipt':('protocol',), 'HandoffPoint':('protocol','site','clause'),
                 'HandoffUse':('point','receipt'), 'SupportFactor':('component','requiredFor')}
    for symbol in _flow_parts(model, root, namespace):
        facts = symbol.type_facts
        resolved = facts.resolved_id if facts else ''
        if not resolved.startswith(namespace + '::'):
            raise ValueError('flow member needs a resolved local schema type: ' + symbol.id)
        kind = resolved.removeprefix(namespace + '::')
        if kind not in roles:
            raise ValueError('unhandled flow schema type: ' + resolved)
        values = _scalars(model, symbol)
        for field in endpoints.get(kind, ()):
            values[field] = model.eval(symbol.id + '.' + field + '.id')
        groups[roles[kind]].append(values)
    policy = model.find(_name(metadata.get('verificationPolicy')))
    if policy is None:
        raise ValueError('model-owned verification policy missing')
    responsibilities = [_scalars(model, symbol) for symbol in _parts(policy)]
    ready = _name(metadata.get('readinessQuestion'))
    readiness = model.eval(namespace + '::' + ready + '.id')
    flow = dict(metadata=metadata, **groups, responsibilities=responsibilities,
                readiness=readiness)
    validate_flow(flow)
    # Presentation uses the same native endpoints; the proof graph and runtime
    # data/control flow are distinct. Cycles are forbidden only in prerequisites.
    return flow


def validate_flow(flow):
    """Reject ambiguous identities, missing endpoints and duplicate proof ownership."""
    def indexed(rows, label):
        result = {}
        for row in rows:
            identity = row.get('id')
            if not isinstance(identity, str) or not identity or identity in result:
                raise ValueError('unique ' + label + ' identities required')
            result[identity] = row
        return result
    components = indexed(flow['components'], 'component')
    questions = indexed(flow['questions'], 'question')
    external = indexed(flow['external'], 'inherited question')
    owners = indexed(flow['responsibilities'], 'verification owner')
    if not components or not questions or set(questions) & set(external):
        raise ValueError('complete disjoint flow/question inventory required')
    for factor in indexed(flow.get('supportFactors', []), 'support factor').values():
        if factor.get('component') not in components or factor.get('requiredFor') not in questions:
            raise ValueError('support factor must bind actual component/question')
        if factor.get('owner') not in owners or factor.get('domain') not in owners[factor['owner']]['domains'].split(';'):
            raise ValueError('support factor owner/domain mismatch')
        for field in ('authority', 'artifact', 'scope', 'boundary'):
            if not isinstance(factor.get(field), str) or not factor[field]:
                raise ValueError('support factor needs complete provenance and scope')
        for name in [factor['artifact'], *factor.get('dependencies', '').split(';')]:
            if name and (Path(name).is_absolute() or '..' in Path(name).parts or '.cache' in Path(name).parts):
                raise ValueError('repository-owned support factor input required')
    semantic = set()
    for question in questions.values():
        key = question.get('semanticKey')
        if not isinstance(key, str) or not key or key in semantic:
            raise ValueError('one owner per semantic question; aliases cannot duplicate it')
        semantic.add(key)
        owner = owners.get(question.get('owner'), {})
        if question.get('domain') not in owner.get('domains', '').split(';'):
            raise ValueError('verification owner/domain mismatch')
        for field in ('artifact', 'symbols', 'question', 'boundary'):
            if not isinstance(question.get(field), str) or not question[field]:
                raise ValueError('complete question scope required')
        path = Path(question['artifact'])
        if path.is_absolute() or '..' in path.parts or '.cache' in path.parts:
            raise ValueError('repository-owned question source required')
    if not isinstance(flow['metadata'].get('designId'), str) or not flow['metadata']['designId']:
        raise ValueError('model-owned design identity required')
    ready = questions.get(flow['readiness'])
    if not ready or ready['domain'] != 'native':
        raise ValueError('readiness must reference an actual native question')
    graph = {identity: set() for identity in questions}
    seen = set()
    for group, targets in (('dependencies', questions), ('externalDependencies', external)):
        for edge in flow[group]:
            a, b = edge.get('dependent'), edge.get('prerequisite')
            if a not in questions or b not in targets or (a, b) in seen:
                raise ValueError('dangling or duplicate prerequisite')
            seen.add((a, b))
            if group == 'dependencies':
                graph[a].add(b)
    visiting, done = set(), set()
    def visit(identity):
        if identity in visiting:
            raise ValueError('cyclic assurance prerequisites')
        if identity in done:
            return
        visiting.add(identity)
        for dependency in graph[identity]:
            visit(dependency)
        visiting.remove(identity)
        done.add(identity)
    for identity in graph:
        visit(identity)
    uses, used_components = set(), set()
    for use in flow['uses']:
        pair = (use.get('component'), use.get('question'))
        if pair[0] not in components or pair[1] not in questions or pair in uses:
            raise ValueError('dangling or duplicate component obligation')
        uses.add(pair); used_components.add(pair[0])
    if {question for _, question in uses} != set(questions) or used_components != set(components):
        raise ValueError('every component/question needs an explicit typed use')
    for edge in flow['flows']:
        if edge.get('producer') not in components or edge.get('consumer') not in components:
            raise ValueError('dangling runtime flow endpoint')
        if not isinstance(edge.get('contract'), str) or not edge['contract']:
            raise ValueError('runtime flow needs its rely/guarantee contract')
    view_kinds, view_paths = set(), set()
    suffixes = {'org':'.org', 'd2':'.d2', 'svg':'.svg', 'receipt':'.json'}
    for view in flow['views']:
        kind, name = view.get('kind'), view.get('path')
        if kind not in suffixes or kind in view_kinds or not isinstance(name, str):
            raise ValueError('unique supported model-owned views required')
        path = Path(name)
        if (path.is_absolute() or '..' in path.parts or '.cache' in path.parts
                or path.suffix != suffixes[kind] or name in view_paths
                or not name.startswith(('dev/', 'evidence/'))):
            raise ValueError('canonical repository view output required')
        view_kinds.add(kind); view_paths.add(name)
    if not {'org','d2'} <= view_kinds:
        raise ValueError('flow must declare its Org and D2 consumers')
    from gambit_smp.sysml_organization import validate_organization
    validate_organization(flow)
    from gambit_smp.sysml_adapters import validate_adapters
    validate_adapters(flow)
    # No model value can turn a structural projection into native authority.
    if flow['metadata'].get('nativeAdmitted') is not False or type(flow['metadata'].get('progressDelta')) is not int or flow['metadata']['progressDelta'] != 0:
        raise ValueError('flow projection cannot grant runtime admission or progress')


def api_flow(connection, documents, namespace):
    """Use the same SDK parsing and opt-in path as ordinary sysml.project parts."""
    from gambit_smp.contract_capabilities import api_values
    result = api_values(connection, documents, namespace)
    if 'flow' not in result:
        raise ValueError('requested model is not a flow contract')
    return result


def support_bindings(root, projection):
    """Bind existing-owner supporting factors without issuing observations."""
    root = Path(root).resolve()
    rows = []
    source_subjects = None
    for factor in projection['flow'].get('supportFactors', []):
        names = [factor['artifact'], *filter(None, factor.get('dependencies', '').split(';'))]
        inputs = {}
        for name in names:
            path = root/name
            if path.resolve() != path or not path.is_file():
                raise ValueError('actual repository support input required: ' + name)
            inputs[name] = _sha(path.read_bytes())
        if factor['owner'] == 'source' and source_subjects is None:
            from gambit_smp.sysml_adapters import adapter_bindings
            source_subjects = {row['id']:row['subjectSha256']
                               for row in adapter_bindings(root, projection)}
        subject = _identity(dict(factor=factor, inputs=inputs,
                                 models=projection.get('modelInputs', {}),
                                 adapters=source_subjects if factor['owner']=='source' else {}))
        rows.append(dict(factor, inputs=inputs, subjectSha256=subject))
    return rows


def flow_facts(root, projection):
    """Bind model-owned needs to actual files, producing no positive observations."""
    root = Path(root).resolve()
    if projection.get('runtimeAdmitted') is not False or 'flow' not in projection:
        raise ValueError('SDK flow projection required')
    flow = projection['flow']
    validate_flow(flow)
    if projection.get('flowSha256') != _identity(flow):
        raise ValueError('flow changed after native SDK projection')
    for name, expected in projection['modelInputs'].items():
        path = Path(name)
        if path.is_absolute() or '..' in path.parts or not (root/path).is_file() or _sha((root/path).read_bytes()) != expected:
            raise ValueError('current model source identity required')
    def subject(name):
        path = Path(name); actual = root/path
        if path.is_absolute() or '..' in path.parts or '.cache' in path.parts or actual.resolve() != actual or not actual.is_file():
            raise ValueError('actual repository subject required: ' + name)
        return _sha(actual.read_bytes())
    questions, external = flow['questions'], flow['external']
    design = flow['metadata']['designId']
    facts = dict(verificationCandidate=[[design]],
        verificationObligation=[[x['id'], x['semanticKey'], x['owner'], x['artifact'], subject(x['artifact']), x['symbols']] for x in questions],
        verificationDomain=[[x['id'], domain] for x in flow['responsibilities'] for domain in x['domains'].split(';')],
        verificationKeyDomain=[[x['semanticKey'], x['domain']] for x in questions],
        verificationUse=[[x['component'], x['question']] for x in flow['uses']],
        verificationObservation=[], shDesign=[[design]],
        shExecutionQuestion=[[flow['readiness']]], shNeed=[[x['id']] for x in questions],
        shDependency=[[x['dependent'], x['prerequisite']] for x in flow['dependencies']],
        shExternal=[[x['id'], x['authority'], x['artifact'], subject(x['artifact']), x['authority']] for x in external],
        shExternalDependency=[[x['dependent'], x['prerequisite']] for x in flow['externalDependencies']],
        shExternalReceipt=[])
    from gambit_smp.sysml_organization import organization_facts
    facts.update(organization_facts(root, flow))
    from gambit_smp.sysml_adapters import adapter_bindings
    bindings = adapter_bindings(root, projection)
    facts.update(shAdapter=[[row['id'],row['question'],row['subjectSha256']] for row in bindings],
                 shAdapterClause=[[clause['id'],row['id'],clause['kind']]
                                  for row in bindings for clause in row['clauses']],
                 shInventoryFamily=[[family['id'],row['id']]
                                    for row in bindings for family in row['inventory']['families']],
                 shSourceCase=[[case['id'],row['id'],case['clause']]
                               for row in bindings for case in row['sourceCases']],
                 shCaseDependency=[[edge['dependent'],edge['prerequisite']]
                                   for edge in flow.get('caseDependencies',[])],
                 shHandoffPoint=[[point['id'],protocol['id'],point['clause']]
                                 for row in bindings for protocol in row['protocols'] for point in protocol['points']],
                 shAdapterReceipt=[])
    facts['shSupport'] = [[row['id'], row['requiredFor'], row['owner'],
                           row['subjectSha256'], row['scope']]
                          for row in support_bindings(root, projection)]
    facts['shSupportReceipt'] = []
    return facts


def assess_flow(root, projection, observations=(), inherited_receipts=(), adapter_receipts=(), support_receipts=()):
    """Run existing ASCENT ownership/composition rules over a fresh bound flow.

    Observations are the existing protocol tuples supplied by scoped tool/source
    observers. This function does not certify their semantic truth or execute
    any native workload. With no observations the frontier is wholly open.
    """
    from gambit_smp.ascent_program import load_catalog, query
    root = Path(root)
    facts = flow_facts(root, projection)
    facts['verificationObservation'] = [list(row) for row in observations]
    facts['shExternalReceipt'] = [list(row) for row in inherited_receipts]
    facts['shAdapterReceipt'] = [list(row) for row in adapter_receipts]
    facts['shSupportReceipt'] = [list(row) for row in support_receipts]
    catalog = load_catalog(root/'dev/modeling/ascent/obligation-ownership.rules.scm',
                           root/'dev/modeling/ascent/shared-heap-smp.rules.scm')
    catalog['sourceTexts'] = ['(ascent-fragment\n' + source + '\n)' for source in catalog['sourceTexts']]
    names = ('verificationChecked', 'verificationMissing', 'verificationOwnerConflict',
             'verificationSemanticOverlap', 'verificationRoleMismatch', 'shCheckedLocal',
             'shOpen', 'shExternalChecked', 'shCycle', 'shNativeReady',
             'shSourceLocated', 'shSourceGap', 'shMappedQuestion', 'shWorkOpen',
             'shAdapterClauseChecked', 'shAdapterClauseOpen', 'shAdapterClosed',
             'shInventoryReviewOpen', 'shSourceCaseOpen','shHandoffPointOpen','shHandoffProtocolOpen',
             'shSupportChecked','shSupportOpen')
    answers = query(facts, catalog, {name: name for name in names})
    return {name: [list(row) for row in values] for name, values in answers.items()}


def flow_view(root, projection, observations=(), inherited_receipts=(), adapter_receipts=(), support_receipts=()):
    """Produce the same typed view input for Org and D2, with actual scope status."""
    answers = assess_flow(root, projection, observations, inherited_receipts, adapter_receipts, support_receipts)
    checked = {row[0] for row in answers['shCheckedLocal']}
    flow = projection['flow']
    result = dict(flow['metadata'])
    result['workOpen'] = answers['shWorkOpen']
    checked_support = {row[0] for row in answers['shSupportChecked']}
    result['supportFactors'] = [dict(row, checked=row['id'] in checked_support)
                               for row in support_bindings(root, projection)]
    for group in ('components', 'external', 'flows', 'views', 'workstreams',
                  'assignments', 'workDependencies', 'progressAxes', 'caseDependencies'):
        result[group] = flow[group]
    from gambit_smp.sysml_organization import source_bindings
    result['sourceSites'] = source_bindings(root, flow)
    from gambit_smp.sysml_adapters import adapter_bindings
    result['adapters'] = adapter_bindings(root, projection)
    closed_clauses = {row[0] for row in answers['shAdapterClauseChecked']}
    closed_adapters = {row[0] for row in answers['shAdapterClosed']}
    for adapter in result['adapters']:
        adapter['sourceClauseSetChecked'] = adapter['id'] in closed_adapters
        adapter['clauses'] = [dict(row,checked=row['id'] in closed_clauses) for row in adapter['clauses']]
    result['questions'] = [dict(row, checked=row['id'] in checked) for row in flow['questions']]
    result['dependencies'] = [[row['dependent'], row['prerequisite']] for row in flow['dependencies']]
    result['externalDependencies'] = [[row['dependent'], row['prerequisite']] for row in flow['externalDependencies']]
    return dict(schema='sysml-flow-view', projection=result, answers=answers,
                modelHash=projection['modelHash'], modelInputs=projection['modelInputs'],
                flowSha256=projection['flowSha256'], runtimeAdmitted=False)


def drive_flow(connection, root, documents, namespace, observations=(), inherited_receipts=(), adapter_receipts=(), support_receipts=()):
    """Fresh SDK -> validated flow -> ASCENT -> shared Org/D2 view input.

    A cached projection is never the entry point. The existing caller owns the
    SDK lifecycle and scoped tool observations; this does not add an executor.
    """
    projection = api_flow(connection, documents, namespace)
    view = flow_view(root, projection, observations, inherited_receipts, adapter_receipts, support_receipts)
    return dict(projection=projection, view=view, runtimeAdmitted=False)


def formal_plan(root, projection):
    """Derive conditional formal checks and output consumers from native types.

    This is a plan for existing tool capabilities, not a new executor. Source
    and native questions are returned as open work, never dispatched or marked
    passed merely because they have files.
    """
    flow_facts(root, projection)
    flow = projection['flow']
    checks, unresolved = [], []
    for question in flow['questions']:
        checker = question['owner']
        if checker in {'quint', 'lean'}:
            suffix = '.qnt' if checker == 'quint' else '.lean'
            if not question['artifact'].endswith(suffix):
                raise ValueError('formal owner/subject mismatch')
            checks.append(dict(id=question['id'], checker=checker,
                artifact=question['artifact'], scope=question['symbols'],
                prerequisites=[edge['prerequisite'] for edge in flow['dependencies']
                               if edge['dependent'] == question['id']],
                conditional=True))
        else:
            unresolved.append(question['id'])
    from gambit_smp.sysml_adapters import adapter_bindings
    reviews = [dict(adapter=row['id'], question=row['question'],
                    subjectSha256=row['subjectSha256'],
                    clauses=[clause['id'] for clause in row['clauses']],
                    sourceCases=[case['id'] for case in row['sourceCases']],
                    protocols=[dict(id=protocol['id'],points=[point['id'] for point in protocol['points']])
                               for protocol in row['protocols']],
                    method='source-refinement', conditional=True)
               for row in adapter_bindings(root, projection)]
    return dict(checks=checks, sourceReviews=reviews, open=unresolved, views=flow['views'],
                runtimeAdmitted=False, executionAuthorized=False)
