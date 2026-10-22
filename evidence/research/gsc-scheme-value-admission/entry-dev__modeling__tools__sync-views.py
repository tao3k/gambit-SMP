#!/usr/bin/env python3
"""Derive documentation views from OpenSysML's structural API export only.
No runtime/model behavior/proof execution. Default mode checks for drift.
"""
from pathlib import Path
import argparse, hashlib, json, os, re, subprocess, sys, tomllib, textwrap
from gambit_smp.task_processes import run as process_run

ROOT = Path(__file__).resolve().parents[3]
TASK = ROOT / '.cache/tasks/sysml-contract-closure'
MODEL = ROOT / 'dev/organization.sysml'
RELATIONS = ROOT / 'dev/architecture/runtime/interfaces/models/sysml/model-relations.sysml'

def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def file_link(source, target, label):
    path, sep, search = target.partition('::')
    return '[[file:' + os.path.relpath(ROOT / path, (ROOT / source).parent) + (sep + search if sep else '') + '][' + label + ']]'
def split(value): return [s.strip() for s in value.split(';') if s.strip()]
def generated(source, kind, content):
    return '#+BEGIN: sysml-view :kind ' + kind + ' :source ' + os.path.relpath(source, ROOT / 'dev') + '\n' + content.rstrip() + '\n#+END:\n'
def replace_block(text, key, block):
    pattern = r'(?ms)^#\+BEGIN: sysml-view :kind ' + re.escape(key) + r'\b.*?^#\+END:[ \t]*\n?'
    if re.search(pattern, text): return re.sub(pattern, lambda _: block, text)
    return text.rstrip() + '\n\n' + block

def derive():
    TASK.mkdir(parents=True, exist_ok=True)
    files = sorted(str(p.relative_to(ROOT)) for p in (ROOT/'dev').rglob('*.sysml'))
    diagnostic_cmd=['sysml','-strict','-no-record-cache','-validate','-json',*files]
    diagnostics=process_run(diagnostic_cmd,cwd=ROOT,capture_output=True,text=True,timeout=60)
    (TASK/'view-diagnostics.stdout.json').write_text(diagnostics.stdout)
    (TASK/'view-diagnostics.stderr.txt').write_text(diagnostics.stderr)
    diagnostic_result=json.loads(diagnostics.stdout)
    if diagnostics.returncode or diagnostic_result.get('diagnostics') or diagnostic_result.get('errors'):
        raise ValueError('OpenSysML structural diagnostics failed; export alone is not validation')
    api = TASK / 'views.api.json'
    cmd = ['sysml', '-strict', '-no-record-cache', '-convert', 'api-json', '-o', str(api), *files]
    run = process_run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=60)
    (TASK/'view-export.stdout.txt').write_text(run.stdout)
    (TASK/'view-export.stderr.txt').write_text(run.stderr)
    if run.returncode: raise ValueError('OpenSysML structural export failed; see retained diagnostics')
    elements = json.loads(api.read_text()); by = {x['@id']: x for x in elements}
    if len(by) != len(elements): raise ValueError('Duplicate exported element identity')
    def attrs(element):
        values = {}
        for ref in element.get('ownedFeature', []):
            feature = by[ref['@id']]
            if feature['@type'] != 'AttributeUsage' or 'value' not in feature: continue
            original = by[feature['redefines']['@id']] if 'redefines' in feature else feature
            value = by[feature['value']['@id']]
            if value['@type'] != 'LiteralString': raise ValueError('Unsupported metadata value: '+feature['@id'])
            key = original['declaredName']
            if key in values: raise ValueError('Repeated metadata field '+key)
            values[key] = value['value']
        return values
    def typed(element, name):
        return element.get('@type') == 'PartUsage' and any(by[t['@id']].get('qualifiedName') == name for t in element.get('type', []))
    areas = [(x,attrs(x)) for x in elements if typed(x,'GambitDevelopmentOrganization::Area')]
    research_lanes = [(x,attrs(x)) for x in elements if typed(x,'GambitDevelopmentOrganization::ResearchLane')]
    refactoring_pressures = [(x,attrs(x)) for x in elements if typed(x,'GambitRefactoring::RefactoringPressure')]
    chain_groups={key:[(x,attrs(x)) for x in elements if typed(x,name)] for key,name in {
        'nodes':'GambitToolchain::SourceChainNode','deltas':'GambitToolchain::SourceChainDelta',
        'phases':'GambitToolchain::SourcePhaseCut','sources':'GambitToolchain::SourceChainFact',
        'population':'GambitToolchain::GenerationTarget','correctness':'GambitToolchain::BuildCorrectnessContract',
        'readBoundaries':'GambitToolchain::GscReadBoundary',
        'issueConditions':'GambitToolchain::SnapshotIssueCondition',
        'refinementSteps':'GambitToolchain::BuildRefinementStep',
        'capabilityGates':'GambitToolchain::GscCapabilityGate',
        'outputObservations':'GambitToolchain::GscOutputObservation',
        'fidelityObligations':'GambitToolchain::GscFidelityObligation',
        'formalSets':'GambitAssuranceRelations::FormalModelSet',
        'reasoning':'GambitAssuranceRelations::ReasoningProjection',
        'modelUses':'GambitAssuranceRelations::ComponentModelUse'}.items()}
    blueprint_groups={key:[(x,attrs(x)) for x in elements if typed(x,name)] for key,name in {
        'modules':'GambitRuntimeComposition::BlueprintModule',
        'interfaces':'GambitRuntimeComposition::BlueprintInterface',
        'runtimeSources':'GambitRuntimeComposition::BlueprintSource',
        'migrationStages':'GambitRefactoring::MigrationStage',
        'benefitCases':'GambitRefactoring::BenefitCase',
        'buildNodes':'GambitToolchain::BuildArtifactNode',
        'buildDeltas':'GambitToolchain::BuildDeltaCase',
        'buildSources':'GambitToolchain::BuildSource'}.items()}
    contracts = [(x,attrs(x)) for x in elements if typed(x,'GambitRuntimeModelRelations::ContractBinding')]
    obligations = [(x,attrs(x)) for x in elements if typed(x,'GambitRuntimeModelRelations::ProofObligation')]
    support = [(x,attrs(x)) for x in elements if typed(x,'GambitCollectionCompletion::SupportingModel')]
    anchors = [(x,attrs(x)) for x in elements if typed(x,'GambitCollectionCompletion::SourceAnchor')]
    lifecycle = [(x,attrs(x)) for x in elements if typed(x,'GambitCollectionCompletion::PhaseTransition')]
    producers = [(x,attrs(x)) for x in elements if typed(x,'GambitProducerCustody::ProducerFamily')]
    custody = [(x,attrs(x)) for x in elements if typed(x,'GambitProducerCustody::CustodyEdge')]
    census = [(x,attrs(x)) for x in elements if typed(x,'GambitProducerCustody::CensusScope')]
    refinements = [(x,attrs(x)) for x in elements if typed(x,'GambitAtomicRefinement::RefinementStep')]
    proof_targets = [(x,attrs(x)) for x in elements if typed(x,'GambitAtomicRefinement::ProofTarget')]
    projection_edges = [(x,attrs(x)) for x in elements if typed(x,'GambitAtomicRefinement::ProjectionEdge')]
    discovery_domains = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::StateDomain')]
    discovery_actions = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::ActionContract')]
    discovery_scenarios = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::ScenarioContract')]
    discovery_cases = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::PreservationCase')]
    discovery_sources = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::SourceFact')]
    discovery_diagrams = [(x,attrs(x)) for x in elements if typed(x,'GambitChildDiscovery::DiagramEdge')]
    copy_routes = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::CopyRoute')]
    copy_failures = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::FailureCut')]
    copy_cases = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::PreservationCase')]
    copy_sources = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::SourceFact')]
    copy_diagrams = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::DiagramEdge')]
    copy_action_bindings = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::ActionBinding')]
    lifetime_steps = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::LifetimeStep')]
    receipt_rules = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::ReceiptRule')]
    lifetime_counterexamples = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::LifetimeCounterexample')]
    migration_cuts = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::MigrationCut')]
    restore_fields = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::RestoreField')]
    migration_steps = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::MigrationAtomicStep')]
    migration_races = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::MigrationRace')]
    pair_labels = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::PairResumeLabel')]
    pair_steps = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::PairAtomicStep')]
    pair_races = [(x,attrs(x)) for x in elements if typed(x,'GambitCopyHandoff::PairRace')]
    investigations = [(x,attrs(x)) for x in elements if typed(x,'GambitResearch::RepairInvestigation')]
    for _,value in investigations:
        for key in ('gateDefinition','failureEvidence','sourceMechanism','quintSource','leanSource'):
            if not (ROOT/value[key]).is_file():raise ValueError('Missing research binding '+value[key])
        for key,source in [('quintSymbol','quintSource'),('leanSymbol','leanSource')]:
            declaration=r'\bdef\s+' if key=='quintSymbol' else r'\btheorem\s+'
            if not re.search(declaration+re.escape(value[key])+r'\b',(ROOT/value[source]).read_text()):
                raise ValueError('Missing research model symbol '+value[key])
    areas.sort(key=lambda x:x[0]['sysx:sourceLine']); contracts.sort(key=lambda x:x[0]['sysx:sourceLine']); obligations.sort(key=lambda x:x[0]['sysx:sourceLine'])
    if not areas or not contracts or not obligations: raise ValueError('Incomplete canonical metadata export')
    area_by_path={v['relativePath']:(x,v) for x,v in areas}; contract_by_element={x['@id']:v for x,v in contracts}
    if len(area_by_path)!=len(areas): raise ValueError('Duplicate semantic owner directory')
    for _,v in areas:
        if not (ROOT/v['relativePath']).is_dir(): raise ValueError('Missing owner directory '+v['relativePath'])
        for k in ['orgEntry','structureModel','d2View','quintIndex','leanIndex']:
            if k in v and not (ROOT/v[k]).is_file(): raise ValueError('Missing model-owned view '+v[k])
    for _,v in contracts:
        if v['ownerPath'] not in area_by_path: raise ValueError('Undeclared semantic owner')
        for owner in split(v['participantPaths']):
            if owner not in area_by_path:raise ValueError('Undeclared participant '+owner)
    contract_ids={v['contractId'] for _,v in contracts}
    if len(contract_ids)!=len(contracts):raise ValueError('Duplicate contract identity')
    obligation_ids=set()
    for _,value in obligations:
        if value['obligationId'] in obligation_ids:raise ValueError('Duplicate obligation identity')
        obligation_ids.add(value['obligationId'])
        if value['responsibleModule'] not in area_by_path:raise ValueError('Unowned proof obligation')
        if value['contractId'] not in contract_ids | {'ALL'}:raise ValueError('Unknown obligation contract')
        if not (ROOT/value['evidenceSource']).is_file():raise ValueError('Missing obligation evidence source')
    for _,value in contracts:
        for key in ['structureModel','quintSource','leanSource','argumentOrg','evidenceReport','inputManifest']:
            path,sep,anchor=value[key].partition('::')
            if not path:continue
            target=ROOT/path
            if not target.is_file():raise ValueError('Missing contract artifact '+path)
            if sep and anchor.startswith('#') and not re.search(r'(?mi)^:CUSTOM_ID:\s*'+re.escape(anchor[1:])+r'\s*$',target.read_text()):raise ValueError('Missing argument anchor '+value[key])
    for _,value in support:
        if value['contractId'] not in contract_ids:raise ValueError('Unknown supporting model contract')
        if value['kind'] not in ['quint','lean']:raise ValueError('Unsupported model kind')
        body=(ROOT/value['path']).read_text()
        pattern=r'(?:action|val|temporal|def)' if value['kind']=='quint' else 'theorem'
        for symbol in split(value['symbols']):
            if not re.search(r'\b'+pattern+r'\s+'+re.escape(symbol)+r'\b',body):raise ValueError('Missing supplementary symbol '+symbol)
    for _,value in anchors:
        source=ROOT/value['path'];length=len(source.read_text().splitlines())
        if not 0 < int(value['firstLine']) <= int(value['lastLine']) <= length:raise ValueError('Invalid source anchor range')
    producer_ranges={}
    for _,value in producers:
        length=len((ROOT/value['path']).read_text().splitlines())
        ranges=[]
        for span in split(value['ranges']):
            lo,hi=map(int,span.split('-'))
            if not 0 < lo <= hi <= length:raise ValueError('Invalid producer range '+value['familyId'])
            ranges.append((lo,hi))
        producer_ranges[value['familyId']]=ranges
    if not producers or len(producer_ranges)!=len(producers):raise ValueError('Missing or duplicate producer family')
    for _,value in custody:
        if value['obligationId'] not in obligation_ids:raise ValueError('Unbound custody obligation')
    quint_body=(ROOT/'models/gambit/gc_work_closure.qnt').read_text()
    for _,value in refinements:
        length=len((ROOT/value['path']).read_text().splitlines())
        if not 0 < int(value['firstLine']) <= int(value['lastLine']) <= length:raise ValueError('Invalid refinement source range')
        if value['obligationId'] not in obligation_ids:raise ValueError('Unowned refinement step')
        for action in split(value['currentAction']):
            if action!='none' and not re.search(r'\baction\s+'+re.escape(action)+r'\b',quint_body):raise ValueError('Missing current QNT action '+action)
    for _,value in proof_targets:
        if value['obligationId'] not in obligation_ids:raise ValueError('Unowned proof target')
        # Disposition belongs to the shared obligation, never a second registry.
        if 'disposition' in value:raise ValueError('Proof target must inherit its obligation disposition')
    action_ids=[v['actionId'] for _,v in discovery_actions]
    if not action_ids or len(action_ids)!=len(set(action_ids)):raise ValueError('Missing or duplicate child-discovery action')
    for group in [discovery_domains,discovery_actions,discovery_scenarios,discovery_cases]:
        for _,value in group:
            if value['obligationId'] not in obligation_ids:raise ValueError('Unowned child-discovery metadata')
            if 'disposition' in value:raise ValueError('Child-discovery status must come from shared obligation')
    for _,value in discovery_scenarios:
        if value['kind'] not in ['legacy-negative','design-negative','positive']:raise ValueError('Unknown discovery scenario class')
        name=value['currentInitializer']
        if name!='none' and not re.search(r'\baction\s+'+re.escape(name)+r'\b',quint_body):raise ValueError('Missing retained QNT initializer '+name)
    for _,value in discovery_cases:
        if not set(split(value['actionIds']))<=set(action_ids):raise ValueError('Unbound discovery preservation action')
    for _,value in discovery_sources:
        length=len((ROOT/value['path']).read_text().splitlines())
        if not 0<int(value['firstLine'])<=int(value['lastLine'])<=length:raise ValueError('Invalid child-discovery source range')
    for _,value in discovery_diagrams:
        if value['actionId']!='none' and value['actionId'] not in action_ids:raise ValueError('Unbound discovery diagram action')
        if not re.fullmatch(r'[a-z][a-z-]*',value['diagramId']):raise ValueError('Invalid discovery diagram name')
    for group in [copy_routes,copy_failures,copy_cases,lifetime_steps,receipt_rules,lifetime_counterexamples,migration_cuts,restore_fields,migration_steps,migration_races,pair_labels,pair_steps,pair_races]:
        for _,value in group:
            if value['obligationId'] not in obligation_ids:raise ValueError('Unowned copy-handoff metadata')
            if 'disposition' in value:raise ValueError('Copy-handoff status must inherit shared obligation')
    for _,value in lifetime_counterexamples:
        if value['classification'] not in ['design-negative','reachability-unresolved']:raise ValueError('Unknown lifecycle counterexample class')
    for _,value in migration_races:
        if value['classification']!='design-negative':raise ValueError('Unknown migration race class')
    for group,key in [(migration_cuts,'cutId'),(restore_fields,'fieldId'),(migration_steps,'stepId'),(migration_races,'scenarioId')]:
        ids=[v[key] for _,v in group]
        if len(ids)!=len(set(ids)):raise ValueError('Duplicate migration metadata identity')
    for group,key in [(pair_labels,'labelId'),(pair_steps,'stepId'),(pair_races,'scenarioId')]:
        ids=[v[key] for _,v in group]
        if len(ids)!=len(set(ids)):raise ValueError('Duplicate PAIR metadata identity')
    pair_enum_names={x['declaredName'] for x in elements if x.get('@type')=='EnumerationUsage' and x.get('qualifiedName','').startswith('GambitCopyHandoff::PairResumeTag::')}
    if pair_enum_names!={v['labelId'] for _,v in pair_labels}:raise ValueError('PAIR tag metadata differs from owned enumeration')
    pair_diagram_states={v[k] for _,v in copy_diagrams if v['diagramId']=='pair-resume' for k in ['fromState','toState']}
    if not pair_diagram_states<=pair_enum_names:raise ValueError('PAIR diagram has unowned resume tag')
    for _,value in pair_labels:
        length=len((ROOT/value['sourcePath']).read_text().splitlines())
        if not 0<int(value['firstLine'])<=int(value['lastLine'])<=length:raise ValueError('Invalid PAIR label source range')
    for _,value in pair_races:
        if value['classification']!='design-negative':raise ValueError('Unknown PAIR counterexample class')
    for _,value in copy_sources:
        length=len((ROOT/value['path']).read_text().splitlines())
        if not 0<int(value['firstLine'])<=int(value['lastLine'])<=length:raise ValueError('Invalid copy-handoff source range')
    for _,value in copy_diagrams:
        if not re.fullmatch(r'[a-z][a-z-]*',value['diagramId']):raise ValueError('Invalid copy-handoff diagram name')
    for _,value in copy_action_bindings:
        if value['actionId'] not in action_ids:raise ValueError('Missing copy handoff action definition')
    callsites=[]
    for _,scope in census:
        body=(ROOT/scope['path']).read_text()
        # Lexical source evidence, never a preprocessed/indirect callgraph.
        # Blanking preserves source offsets and line identity in C files.
        tokenized=re.sub(r'/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'',
                         lambda m:re.sub(r'[^\n]',' ',m[0]),body,flags=re.S)
        for symbol in split(scope['symbols']):
            for match in re.finditer(r'\b'+re.escape(symbol)+r'\b',tokenized):
                line=tokenized.count('\n',0,match.start())+1
                text=body.splitlines()[line-1]
                kind='macro-definition' if re.match(r'\s*#\s*define\s+'+re.escape(symbol)+r'\b',text) else 'call-like' if re.match(r'\s*\(',tokenized[match.end():]) else 'identifier-reference'
                families=[v['familyId'] for _,v in producers if v['path']==scope['path'] and any(lo<=line<=hi for lo,hi in producer_ranges[v['familyId']])]
                if kind=='call-like' and not families:raise ValueError('Unmapped lexical call-like site '+scope['path']+':'+str(line))
                callsites.append({'path':scope['path'],'line':line,'symbol':symbol,'kind':kind,'families':families})
    dependencies=[]
    for x in elements:
        if x['@type']!='Dependency' or x.get('owningNamespace',{}).get('@id')!='GambitRuntimeModelRelations__relations':continue
        clients=x.get('client',[]);suppliers=x.get('supplier',[])
        if len(clients)!=1 or len(suppliers)!=1:raise ValueError('Unsupported dependency cardinality')
        dependencies.append({'id':x['declaredName'],'consumer':contract_by_element[clients[0]['@id']]['contractId'],'prerequisite':contract_by_element[suppliers[0]['@id']]['contractId']})
    # Dependency cycle check is about this phase-scoped metadata DAG, not native wait freedom.
    pending={v['contractId']:set() for _,v in contracts}
    for e in dependencies:pending[e['consumer']].add(e['prerequisite'])
    order=[]
    while pending:
        ready=sorted(k for k,v in pending.items() if not v)
        if not ready:raise ValueError('Cycle in phase-scoped contract dependency metadata')
        order+=ready
        for key in ready:pending.pop(key)
        for need in pending.values():need.difference_update(ready)
    effective={v['contractId']:v['compositionStatus'] for _,v in contracts}
    for contract_id in order:
        blocked=[edge['prerequisite'] for edge in dependencies if edge['consumer']==contract_id and effective[edge['prerequisite']].startswith('blocked')]
        if blocked:effective[contract_id]='blocked-by-dependency: '+', '.join(sorted(blocked))
    for _,value in contracts:value['dependencyStatus']=effective[value['contractId']]
    outputs={}
    def closed_dag(group,identity):
        rows={v[identity]:v for _,v in group}
        if len(rows)!=len(group):raise ValueError('Duplicate blueprint graph identity')
        pending={key:set(split(v['dependsOn'])) for key,v in rows.items()}
        if any(not deps<=rows.keys() for deps in pending.values()):raise ValueError('Unknown blueprint dependency')
        order=[]
        while pending:
            ready=sorted(k for k,deps in pending.items() if not deps)
            if not ready:raise ValueError('Cyclic blueprint migration/artifact dependency')
            order+=ready
            for key in ready:del pending[key]
            for deps in pending.values():deps.difference_update(ready)
        return order
    stage_order=closed_dag(blueprint_groups['migrationStages'],'stageId')
    build_order=closed_dag(blueprint_groups['buildNodes'],'nodeId')
    chain_order=closed_dag(chain_groups['nodes'],'nodeId')
    sets={v['modelSetId']:v for _,v in chain_groups['formalSets']}
    if len(chain_groups['reasoning'])!=1:raise ValueError('One canonical reasoning projection required')
    reasoning_projection=chain_groups['reasoning'][0][1]
    if len(sets)!=len(chain_groups['formalSets']):raise ValueError('Duplicate formal model set')
    resolved_model_uses=[]
    for _,v in chain_groups['modelUses']:
        if v['ownerPath'] not in area_by_path or not set(split(v['obligationIds']))<=obligation_ids:raise ValueError('Unowned component/model use')
        if v['bindingKind']=='runtime-binding':
            matches=[c for _,c in contracts if c['contractId']==v['bindingId']]
            if len(matches)!=1:raise ValueError('Unknown runtime model binding')
            binding=matches[0]
        elif v['bindingKind']=='model-set':binding=sets[v['bindingId']]
        else:raise ValueError('Unsupported component/model binding kind')
        resolved_model_uses.append(dict(v,quintSource=binding['quintSource'],quintSymbols=binding['quintSymbols'],leanSource=binding['leanSource'],leanSymbols=binding['leanSymbols'],evidenceReport=binding['evidenceReport']))
    if len({v['componentId'] for v in resolved_model_uses})!=len(resolved_model_uses):raise ValueError('Duplicate model component')
    for _,v in chain_groups['formalSets']:
        if v['ownerPath'] not in area_by_path:raise ValueError('Unowned formal set')
        if not (ROOT/v['evidenceReport']).is_file():raise ValueError('Missing scoped formal receipt')
        for method,kind in [('quint',r'(?:action|val|temporal|def)'),('lean','theorem')]:
            body=(ROOT/v[method+'Source']).read_text()
            for symbol in split(v[method+'Symbols']):
                if not re.search(r'\b'+kind+r'\s+'+re.escape(symbol)+r'\b',body):raise ValueError('Unbound component/model symbol '+symbol)
    chain_sources=[]
    for group in ['nodes','sources','population','correctness','readBoundaries','issueConditions','refinementSteps','capabilityGates','outputObservations','fidelityObligations']:
        for _,v in chain_groups[group]:
            p=ROOT/v['sourcePath'];length=len(p.read_text().splitlines())
            for extent in split(v['sourceRanges']):
                ends=list(map(int,extent.split('-')))
                if not 1<=ends[0]<=ends[-1]<=length:raise ValueError('Invalid chain source range '+extent)
            chain_sources.append(dict(v,sha256=sha(p)))
    # Compare authored SysML population with the literal template inventory.
    # This is correspondence validation, not a build planner or source executor.
    template=(ROOT/'vendor/gambit/gsc/makefile.in').read_text()
    def literal_modules(name):
        found=re.search(r'(?m)^'+name+r' = ((?:.*\\\n)*.*)',template)
        if not found:raise ValueError('Missing Make inventory '+name)
        return found.group(1).replace('\\\n',' ').split()
    actual=literal_modules('LIBRARY_MODULES')+literal_modules('EXECUTABLE_MODULES')
    population=[v for _,v in chain_groups['population']]
    if [v['moduleName'] for v in population]!=actual or len(actual)!=34:
        raise ValueError('SysML generation population differs from source template')
    if [int(v['populationNode']) for v in population]!=list(range(34)):
        raise ValueError('Population indices must preserve Make module order')
    if [v['role'] for v in population]!=['library']*33+['executable']:
        raise ValueError('Source module roles disagree')
    read_ids={v['readId'] for _,v in chain_groups['readBoundaries']}
    if len(read_ids)!=len(chain_groups['readBoundaries']):raise ValueError('Duplicate read boundary')
    # Source call/expansion graphs may recurse; do not confuse them with an action DAG.
    for _,v in chain_groups['readBoundaries']:
        if not set(split(v['calls']))<=read_ids:raise ValueError('Unbound read caller edge')
    for group,identity in [('capabilityGates','capabilityId'),('outputObservations','observationId'),('fidelityObligations','fidelityId')]:
        if len({v[identity] for _,v in chain_groups[group]})!=len(chain_groups[group]):raise ValueError('Duplicate capability/observation contract')
    issue_order=closed_dag(chain_groups['issueConditions'],'conditionId')
    if len({v['stepId'] for _,v in chain_groups['refinementSteps']})!=len(chain_groups['refinementSteps']):raise ValueError('Duplicate refinement step')
    for group in ['readBoundaries','issueConditions','refinementSteps','capabilityGates','outputObservations','fidelityObligations']:
        for _,v in chain_groups[group]:
            if v['obligationId'] not in obligation_ids:raise ValueError('Unbound read/refinement obligation')
    lean_body=(ROOT/'models/build/IncrementalBuild.lean').read_text()
    for _,v in chain_groups['refinementSteps']:
        for symbol in split(v['leanSupport']):
            if not re.search(r'\btheorem\s+'+re.escape(symbol)+r'\b',lean_body):raise ValueError('Unbound refinement theorem '+symbol)
    closed_dag(chain_groups['fidelityObligations'],'fidelityId')
    for _,v in chain_groups['fidelityObligations']:
        for method,kind in [('lean','theorem'),('quint',r'(?:def|val)')]:
            body=(ROOT/('models/build/IncrementalBuild.lean' if method=='lean' else 'models/build/incremental_build.qnt')).read_text()
            for symbol in split(v[method+'Support']):
                if not re.search(r'\b'+kind+r'\s+'+re.escape(symbol)+r'\b',body):raise ValueError('Unbound fidelity support '+symbol)
    correctness_order=closed_dag(chain_groups['correctness'],'contractId')
    for _,v in chain_groups['correctness']:
        if v['obligationId'] not in obligation_ids:raise ValueError('Unbound build correctness obligation')
    chain_model=ROOT/'dev/architecture/toolchain/models/sysml/architecture.sysml'
    assurance_model=ROOT/'dev/modeling/models/sysml/assurance.sysml'
    def chain_table(f,group,columns,kind,model):
        table='#+NAME: '+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in chain_groups[group]:table+='| '+' | '.join(file_link(f,v[key],v[key]) if key.endswith('Source') or key=='sourcePath' else v[key] for key,label in columns)+' |\n'
        return generated(model,kind,table)
    f='dev/architecture/toolchain/source-chain-map.org'
    body=chain_table(f,'nodes',[(k,l) for k,l in [('nodeId','Node'),('dependsOn','Requires'),('product','Real product'),('sourcePath','Source'),('sourceRanges','Ranges'),('quintNode','QNT index'),('inputCut','Input cut'),('limit','Limit')]],'source-chain-nodes',chain_model)
    body+='\n** Three source delta cases\n'+chain_table(f,'deltas',[(k,l) for k,l in [('caseId','Case'),('change','Change'),('currentPath','Current path'),('proposedWork','Proposed work'),('mathematicalCount','Scoped mathematical count'),('limit','Boundary'),('obligationId','Open obligation')]],'source-chain-deltas',chain_model)
    body+='\n** Phase split and retirement\n'+chain_table(f,'phases',[(k,l) for k,l in [('phaseId','Phase'),('currentRole','Current role'),('proposedCut','Proposed cut'),('admission','Admission'),('mustRetain','Keep'),('retirement','Retirement')]],'source-chain-phases',chain_model)
    source_rows='| Fact | Source | Observation | Limit |\n|---+---+---+---|\n'
    for _,v in chain_groups['sources']:
        links='; '.join(file_link(f,v['sourcePath']+'::'+x.split('-')[0],v['sourcePath']+':'+x) for x in split(v['sourceRanges']))
        source_rows+='| '+v['factId']+' | '+links+' | '+v['observation']+' | '+v['limit']+' |\n'
    outputs[f]='#+TITLE: GSC Source Chain, Delta Propagation and Phase Retirement\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* Canonical source-chain projection\n:PROPERTIES:\n:CUSTOM_ID: gsc-source-chain-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: source-and-conditional-algorithm-design\n:END:\n\nThe ten-node mathematical cohort selects two real library modules. Remaining library/executable objects are fixed environment inputs only in that model; the macro case is not a full source refinement. Counts are abstract executions, not measured builds or speedups.\n\n'+body+'\n** Source facts\n'+generated(chain_model,'source-chain-facts',source_rows)
    lines=['# Derived from GambitToolchain SourceChainNode; representative two-unit cohort. Make variables displayed by name.','direction: down']
    for _,v in chain_groups['nodes']:
        display=re.sub(r'\$\(([^)]+)\)',r'Make variable \1',v['product'])
        lines.append('c_'+v['nodeId']+': '+json.dumps(v['nodeId']+'\n'+textwrap.fill(display,30)))
    for _,v in chain_groups['nodes']:
        for dep in split(v['dependsOn']):lines.append('c_'+dep+' -> c_'+v['nodeId'])
    outputs['dev/architecture/toolchain/diagrams/source-chain.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/toolchain/correctness-map.org'
    body=chain_table(f,'population',[(k,l) for k,l in [('populationNode','Generation index'),('moduleName','Scheme / C stem'),('role','Role'),('selectedNode','Ten-node view'),('inputCut','Required input boundary'),('projectionBoundary','Downstream boundary')]],'gsc-generation-population',chain_model)
    body+='\n** Correctness, counterexamples and closure matrix\n'+chain_table(f,'correctness',[(k,l) for k,l in [('contractId','Contract'),('dependsOn','Requires'),('mechanism','Mechanism'),('sourcePath','Source'),('sourceRanges','Ranges'),('quintSymbols','QNT'),('leanSymbols','Lean conditional support'),('openPremise','Unproved premise'),('counterexample','Counterexample sketch'),('obligationId','Parent obligation'),('status','Status')]],'build-correctness-contracts',chain_model)
    body+='\n** Benefits, added work and retirement matrix\n'+chain_table(f,'correctness',[(k,l) for k,l in [('contractId','Contract'),('benefit','Conditional benefit'),('addedCost','Required added support'),('retirement','Retirement condition'),('paperURL','Research source')]],'build-correctness-benefits',chain_model)
    outputs[f]='#+TITLE: GSC Population, Correctness and Benefit Matrices\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* SysML-owned correctness projection\n:PROPERTIES:\n:CUSTOM_ID: build-correctness-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: conditional-design-and-source-inventory\n:END:\n\n34 generation targets, 34 corresponding compilation actions and six composition actions form a 74-action slice. This is neither the whole bootstrap nor an executed workload. The ten-node protocol omits 31 library pairs and the executable pair. Its safety is not a full-population theorem.\n\n'+body
    lines=['# Derived correctness contracts and explicit population boundary; not behavioral execution.','direction: down',
        'inputs: "34 Scheme-to-C + 34 C-to-object actions"',
        'composite: "6 composition actions / total slice 74"',
        'selected: "Ten-node two-library protocol\\n31 library pairs + executable pair external"',
        'proof: "Conditional Lean algebra\\nQNT typechecking only; simulation OPEN"',
        'ascent: "ASCENT source-bound hypotheses\\nNo native or proof admission"',
        'inputs -> composite: "ordered dependency vectors"',
        'composite -> selected: "boundary assumptions required"']
    for _,v in chain_groups['correctness']:
        ident=v['contractId'].replace('-','_')
        lines.append(ident+': '+json.dumps(v['contractId']+'\n'+textwrap.fill(v['mechanism'],45)+'\n'+v['status']))
        for dep in split(v['dependsOn']):lines.append(dep.replace('-','_')+' -> '+ident)
    lines+=['selected -> B_POPULATION','B_POPULATION -> proof','B_CLOSURE -> proof','B_SNAPSHOT -> proof','B_CUTOFF -> proof','proof -> ascent: "exact artifacts + remaining premises"']
    outputs['dev/architecture/toolchain/diagrams/build-correctness.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/toolchain/read-snapshot-map.org'
    body=chain_table(f,'readBoundaries',[(k,l) for k,l in [('readId','Boundary'),('calls','Calls / feeds'),('sourcePath','Source'),('sourceRanges','Ranges'),('caller','Actual caller'),('observation','Observed semantics'),('existingSupport','Reuse'),('missingClosure','Remaining closure gap'),('managedChange','Necessary change'),('obligationId','Obligation')]],'gsc-real-read-boundaries',chain_model)
    body+='\n** Snapshot credential issue conditions\n'+chain_table(f,'issueConditions',[(k,l) for k,l in [('conditionId','Condition'),('dependsOn','Requires'),('credential','Proposed credential'),('issueGuard','Issue guard'),('failureCustody','Failure custody'),('proofTarget','Proof obligation'),('sourcePath','Source anchor'),('sourceRanges','Ranges')]],'gsc-snapshot-issue-conditions',chain_model)
    body+='\n** Concrete to selected-model refinement obligations\n'+chain_table(f,'refinementSteps',[(k,l) for k,l in [('stepId','Step'),('concreteEvent','Concrete event'),('abstractEvent','Abstract event'),('relationPremise','Relation premise'),('leanSupport','Checked support'),('openProof','Unproved source obligation'),('costEffect','Work boundary'),('sourcePath','Source'),('sourceRanges','Ranges')]],'gsc-build-refinement-steps',chain_model)
    body+='\n** Modern-C support and benefit matrix\n'+chain_table(f,'issueConditions',[(k,l) for k,l in [('conditionId','Condition'),('addedSupport','Added necessary support'),('retirement','Retirement condition'),('benefitBoundary','Benefit / refutation')]],'gsc-snapshot-benefits',chain_model)
    outputs[f]='#+TITLE: GSC Read Closure, Snapshot Issuance and Refinement Matrices\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* SysML-owned read and proof boundary\n:PROPERTIES:\n:CUSTOM_ID: gsc-read-snapshot-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: source-slice-conditional-theory\n:END:\n\nThese source boundaries are an investigated slice, not an exhaustive boot-producer effect census. Credentials are proposed contracts; none is issued by current source. Finite graph theorems do not supply actual compiler-oracle adequacy.\n\n'+body
    lines=['# Derived from GscReadBoundary and SnapshotIssueCondition; callbacks and native effects remain open.','direction: down']
    for _,v in chain_groups['readBoundaries']:
        ident=v['readId'].replace('-','_')
        lines.append(ident+': '+json.dumps(v['readId']+'\n'+textwrap.fill(v['caller'],34)))
        for target in split(v['calls']):lines.append(ident+' -> '+target.replace('-','_'))
    lines+=['effects: "Unmediated macro / reader / native effects\\nReusable closure NOT established"','R_HOST -> effects','R_READLOOP -> effects','R_OPEN -> effects',
        'image: "I-IMAGE + I-PRODUCER\\nCoherent source/tool/context image"',
        'catalog: "I-CATALOG\\nValidated generated groups + leases"',
        'trace: "I-MEDIATION + I-TRACE\\nClosed finite read trace; source proof OPEN"',
        'admit: "I-SEAL + I-ADMIT\\nComplete group, serialized revoke/commit"',
        'replay: "I-REPLAY\\nSame answers + same producer/context"',
        'effects -> trace: "must mediate / constrain / reject"','image -> trace','catalog -> trace','trace -> admit','trace -> replay','replay -> admit']
    outputs['dev/architecture/toolchain/diagrams/read-snapshot.d2']='\n'.join(lines)+'\n'
    lines=['# Derived from BuildRefinementStep; mapping is conditional, not native acceptance.','direction: down',
        'full: "74 action source slice\\n34 generation + 34 compilation + 6 composition"',
        'boundary: "64 omitted actions / 64 module boundary edges\\nOrdered views + readiness + real credits"',
        'selected: "Ten-node protocol\\nExact selected graph; integer oracle adequacy OPEN"',
        'full -> boundary','boundary -> selected: "relation requires boundary receipts"']
    for _,v in chain_groups['refinementSteps']:
        ident=v['stepId'].replace('-','_')
        lines.append(ident+': '+json.dumps(v['stepId']+'\n'+textwrap.fill(v['abstractEvent'],42)))
    lines += ['selected -> P_INITIAL','P_INITIAL -> P_READY','P_READY -> P_START','P_START -> P_FINISH','P_FINISH -> P_PUBLISH','P_PUBLISH -> P_REVOKE','P_READY -> P_OMITTED','P_OMITTED -> P_SHARED_MACRO']
    lines+=['proof: "Lean: adaptive replay + graph / ready / budget facts\\nActual step simulation and receipt issuer remain OPEN"','P_INITIAL -> proof','P_READY -> proof','P_START -> proof','P_PUBLISH -> proof',
        'macro: "Shared macro: old input receipts invalid\\nEqual validated outputs may recertify safety\\nOmitted work remains charged"','P_SHARED_MACRO -> macro','boundary -> macro',
        'ascent: "ASCENT exact-source hypotheses\\nNo observation / proof / execution promotion"','proof -> ascent','macro -> ascent']
    outputs['dev/architecture/toolchain/diagrams/build-refinement.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/toolchain/capability-observation-map.org'
    body=chain_table(f,'capabilityGates',[(k,l) for k,l in [('capabilityId','Capability'),('sourcePath','Source'),('sourceRanges','Ranges'),('actualCaller','Actual caller'),('capability','Effect / phase'),('admitCondition','Necessary admission'),('refuseCondition','Refuse reusable credential when'),('remainingClosure','Remaining closure'),('supportAndBenefit','Reuse / support / benefit')]],'gsc-capability-closure-gates',chain_model)
    body+='\n** Output observations and concrete safety reflection\n'+chain_table(f,'outputObservations',[(k,l) for k,l in [('observationId','Observation'),('sourcePath','Source'),('sourceRanges','Ranges'),('consumer','Consumer'),('requiredValue','Complete value'),('modelCorrespondence','QNT correspondence'),('fidelityObligation','Fidelity/reflection obligation'),('refuseEquality','Invalid equality shortcut'),('benefitBoundary','Benefit boundary')]],'gsc-output-observation-reflection',chain_model)
    outputs[f]='#+TITLE: GSC Capability Admission, Output Fidelity and Benefit Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* SysML-owned capability and observation contracts\n:PROPERTIES:\n:CUSTOM_ID: gsc-capability-observation-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: source-slice-conditional-contracts\n:END:\n\nCallsites below establish concrete entrances and selected edges, not the complete dynamic procedure or native provider universe. Refusal means no reusable managed credential; no language feature is removed. Structured QNT observations are a new contract specification, not a real parser or output oracle.\n\n'+body
    lines=['# Derived from GscCapabilityGate / GscOutputObservation; no runtime admission.','direction: down',
      'macro: "Macro closure -> eval -> module requirements / code execution"',
      'reader: "Character / sharp / comment callbacks\\nSharp-dot requires feature AND actual flag"',
      'native: "Port buffer -> c-lambda -> C device provider\\nPOSIX/file/backend identity must be bound"',
      'gate: "Capability admission\\nSame context + mediated nested trace + settled ownership"',
      'refuse: "REFUSE reusable credential\\nUnknown callback/provider, bypass, live handle, partial outcome"',
      'output: "Successful staged group\\nExact C bytes + accepted full Scheme linker record"',
      'observe: "Typed role/schema/context observation\\nOpaque structured token; fidelity still OPEN"',
      'legacy: "Original ten-node integer/addition scenario\\nNo real GSC oracle transfer"',
      'reflection: "Concrete clean-result / currentness / capability reflection\\nFull budget, work and progress separately"',
      'ascent: "ASCENT source-bound hypotheses\\nNo native or proof admission"',
      'macro -> gate','reader -> gate','native -> gate','gate -> refuse: "coverage or custody unknown"','gate -> output: "only after every necessary witness"',
      'output -> observe','legacy -> observe: "scenario cannot supply fidelity"','observe -> reflection','reflection -> ascent']
    outputs['dev/architecture/toolchain/diagrams/capability-observation.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/toolchain/output-fidelity-map.org'
    body=chain_table(f,'fidelityObligations',[(k,l) for k,l in [('fidelityId','Obligation'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Real boundary'),('encodingRule','Encoding / domain'),('cleanControl','Clean control'),('failureMapping','Failure mapping'),('reflectionDuty','Remaining proof'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean support'),('quintSupport','QNT support'),('dependsOn','Depends on')]],'gsc-fidelity-reflection-obligations',chain_model)
    outputs[f]='#+TITLE: GSC Output Fidelity, Clean-Origin and Failure Reflection Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* Source-bound obligations\n:PROPERTIES:\n:CUSTOM_ID: gsc-output-fidelity-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: source-and-conditional-theory\n:END:\n\nThe dependency graph orders research/proof prerequisites, not an observed execution trace. Existing distribution artifacts do not establish a current clean origin. No real parser, runtime adapter or producer qualification is claimed.\n\n'+body
    lines=['# Derived L-duty view; D-duty prerequisites and boundary edges are in recursive-codec.d2.','direction: down']
    for _,v in chain_groups['fidelityObligations']:
        if not v['fidelityId'].startswith('L-'):continue
        ident=v['fidelityId'].replace('-','_')
        lines.append(ident+': '+json.dumps(v['fidelityId']+'\n'+textwrap.fill(v['diagramLabel'],32)))
        for dependency in split(v['dependsOn']):
            if dependency.startswith('L-'):lines.append(dependency.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/output-fidelity.d2']='\n'.join(lines)+'\n'
    recursive_duties=[v for _,v in chain_groups['fidelityObligations'] if v['fidelityId'].startswith('D-')]
    f='dev/architecture/toolchain/recursive-codec-map.org'
    columns=[('fidelityId','Duty'),('sourcePath','Source'),('sourceRanges','Ranges'),('concreteBoundary','Actual boundary'),('encodingRule','Admission / syntax'),('cleanControl','Clean-context obligation'),('failureMapping','Failure / refusal'),('reflectionDuty','Proof boundary'),('benefitBoundary','Benefit / cost'),('leanSupport','Lean'),('quintSupport','QNT')]
    body='#+NAME: recursive-datum-duty-matrix\n| '+' | '.join(label for _,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
    for v in recursive_duties:body+='| '+' | '.join(file_link(f,v[key],v[key]) if key=='sourcePath' else v[key] for key,_ in columns)+' |\n'
    outputs[f]='#+TITLE: Recursive Datum Wire and Actual Scheme Domain Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* Source and proof boundary\n:PROPERTIES:\n:CUSTOM_ID: gsc-recursive-codec-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: mathematical-wire-closed-actual-domain-open\n:END:\n\nThe recursive framing theorem concerns a mathematical tree. Scheme value identity, scalar semantics, reader/writer fidelity, real consumers and resource costs remain separate duties.\n\n'+generated(chain_model,'gsc-recursive-datum-domain',body)
    lines=['# Derived focused proof-prerequisite graph; no runtime parser qualification.','direction: down']
    for v in recursive_duties:
        ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\n'+textwrap.fill(v['diagramLabel'],34)))
        for dep in split(v['dependsOn']):lines.append(dep.replace('-','_')+' -> '+ident)
    for _,v in chain_groups['fidelityObligations']:
        deps=[dep for dep in split(v['dependsOn']) if dep.startswith('D-')]
        if v['fidelityId'].startswith('L-') and deps:
            ident=v['fidelityId'].replace('-','_');lines.append(ident+': '+json.dumps(v['fidelityId']+'\n'+textwrap.fill(v['diagramLabel'],34)))
            for dep in deps:lines.append(dep.replace('-','_')+' -> '+ident)
    outputs['dev/architecture/toolchain/diagrams/recursive-codec.d2']='\n'.join(lines)+'\n'
    f='dev/modeling/component-model-map.org'
    rows='#+NAME: component-formal-models\n| Component / owner | Required model | QNT source / symbols | Lean source / symbols | State / event projection | Missing premises / obligation |\n|---+---+---+---+---+---|\n'
    for v in resolved_model_uses:
        report=file_link(f,v['evidenceReport'],'scoped receipt') if v['evidenceReport'] else 'no separate scoped report'
        rows+='| '+v['componentId']+'; '+v['ownerPath']+' | '+v['requiredModel']+'; '+report+' | '+file_link(f,v['quintSource'],'QNT')+'; '+v['quintSymbols']+' | '+file_link(f,v['leanSource'],'Lean')+'; '+v['leanSymbols']+' | '+v['stateProjection']+'; '+v['eventProjection']+' | '+v['openPremises']+'; '+v['obligationIds']+' |\n'
    outputs[f]='#+TITLE: Component to QNT, Lean and ASCENT Correspondence\n#+SETUPFILE: org/setup.org\n\n* SysML-owned component/model associations\n:PROPERTIES:\n:CUSTOM_ID: component-model-map\n:AUTHORITY: GambitAssuranceRelations\n:EVIDENCE_CLASS: source-bound-open-correspondence\n:END:\n\nExisting runtime source/symbol pairs resolve through the unique runtime binding, not repeated paths in a second registry. Build components share one formal set. A parsed model, checked conditional theorem, ASCENT join and runtime refinement are separate evidence.\n\n'+generated(assurance_model,'component-models',rows)
    lines=['# Derived from GambitAssuranceRelations component references; exact artifacts in Org map.','direction: right','sysml: "SysML component/model contracts"','ascent: '+json.dumps('ASCENT source/proof/gap joins\nHypotheses; no admission authority')]
    for v in resolved_model_uses:
        ident=v['componentId'].replace('-','_');target=v['bindingId'].replace('-','_')
        lines += ['c_'+ident+': '+json.dumps(v['componentId']), 'm_'+target+': '+json.dumps(v['bindingId']+'\nQNT + Lean, scoped premises'), 'sysml -> c_'+ident, 'c_'+ident+' -> m_'+target]
    lines.append('sysml -> ascent: "derived source-hash facts"')
    outputs['dev/modeling/diagrams/component-models.d2']='\n'.join(dict.fromkeys(lines))+'\n'
    # Existing Scheme/ASCENT entry point: only explicit association hypotheses.
    # A source hash is a provenance witness, never proof of the source's claim.
    program=['(define-evidence (query)',' (sources) (outputs clue factor)',
        ' (relation association (id claim owner binding source))',
        ' (relation artifact (binding language path digest))',
        ' (relation contractFactor (binding name value))',
        ' (relation fidelityDuty (binding identity gap failure))',
        ' (relation associationDigest (source digest bundle))',
        ' (relation clue (id claim polarity source))',' (relation factor (id name value))']
    association_inputs={str(p.relative_to(ROOT)):sha(p) for p in [assurance_model,RELATIONS,chain_model]}
    for source in chain_sources:association_inputs[source['sourcePath']]=source['sha256']
    for v in resolved_model_uses:
        for path in [v['quintSource'],v['leanSource'],v['evidenceReport']]:
            if path:association_inputs[path]=sha(ROOT/path)
    association_bundle=hashlib.sha256(json.dumps(association_inputs,sort_keys=True).encode()).hexdigest()
    program.append(' (fact (associationDigest '+' '.join(json.dumps(x) for x in [str(assurance_model.relative_to(ROOT)),sha(assurance_model),association_bundle])+'))')
    artifact_facts=set();contract_facts=set()
    for v in resolved_model_uses:
        component_id=v['componentId'];ident=component_id+':'+association_bundle;claim='component-model:'+ident
        program.append(' (fact (association '+' '.join(json.dumps(x) for x in [ident,claim,v['ownerPath'],v['bindingId'],str(assurance_model.relative_to(ROOT))])+'))')
        for method in ['quint','lean']:artifact_facts.add((v['bindingId'],method,v[method+'Source'],sha(ROOT/v[method+'Source'])))
        report_factors=[('formal-receipt',v['evidenceReport']),('formal-receipt-sha256',sha(ROOT/v['evidenceReport']))] if v['evidenceReport'] else [('formal-receipt-status','unavailable-for-this-binding')]
        if v['bindingKind']=='model-set':report_factors += [('source-chain-model',str(chain_model.relative_to(ROOT))),('source-chain-model-sha256',sha(chain_model))]
        if v['bindingKind']=='model-set':
            report_factors += [('generation-target-count','34'),('gsc-slice-action-count','74'),('source-refinement-status','open')]
            for _,read in chain_groups['readBoundaries']:
                report_factors += [('read-boundary',read['readId']),('read-gap',read['readId']+':'+read['missingClosure'])]
            for _,condition in chain_groups['issueConditions']:
                report_factors += [('snapshot-condition',condition['conditionId']),('snapshot-issue-guard',condition['conditionId']+':'+condition['issueGuard']),('snapshot-proof-gap',condition['conditionId']+':'+condition['proofTarget'])]
            for _,step in chain_groups['refinementSteps']:
                report_factors += [('refinement-step',step['stepId']),('refinement-premise',step['stepId']+':'+step['relationPremise']),('refinement-proof-gap',step['stepId']+':'+step['openProof'])]
            for _,cap in chain_groups['capabilityGates']:
                report_factors += [('capability-gate',cap['capabilityId']),('capability-admission',cap['capabilityId']+':'+cap['admitCondition']),('capability-refusal',cap['capabilityId']+':'+cap['refuseCondition'])]
            for _,obs in chain_groups['outputObservations']:
                report_factors += [('output-observation',obs['observationId']),('observation-fidelity',obs['observationId']+':'+obs['fidelityObligation']),('observation-equality-refusal',obs['observationId']+':'+obs['refuseEquality'])]
            for _,contract in chain_groups['correctness']:
                report_factors += [('correctness-contract',contract['contractId']),('correctness-status',contract['contractId']+':'+contract['status']),('correctness-open-premise',contract['contractId']+':'+contract['openPremise'])]
        if v['bindingKind']=='model-set':
            # Shared design factors are materialized once per canonical binding;
            # the existing Scheme relation joins them to component hypotheses.
            contract_facts.update((v['bindingId'],name,value) for name,value in report_factors)
            report_factors=[]
        for name,value in [('component-id',component_id),('evidence-class','design-association-not-refinement'),('open-premise',v['openPremises'])]+report_factors+[('obligation-id',x) for x in split(v['obligationIds'])]:
            program.append(' (fact (factor '+' '.join(json.dumps(x) for x in [ident,name,value])+'))')
    duty_binding=next(v['modelSetId'] for _,v in chain_groups['formalSets'] if v['ownerPath']==str(chain_model.parents[2].relative_to(ROOT)))
    for _,duty in chain_groups['fidelityObligations']:
        row=[duty_binding,duty['fidelityId'],duty['fidelityId']+':'+duty['reflectionDuty'],duty['fidelityId']+':'+duty['failureMapping']]
        program.append(' (fact (fidelityDuty '+' '.join(json.dumps(x) for x in row)+'))')
    for row in sorted(contract_facts):program.append(' (fact (contractFactor '+' '.join(json.dumps(x) for x in row)+'))')
    for row in sorted(artifact_facts):program.append(' (fact (artifact '+' '.join(json.dumps(x) for x in row)+'))')
    program += [' ((clue I C (lit "support") S) <-- (association I C _ _ S))',
        ' ((factor I N V) <-- (association I _ _ M _) (contractFactor M N V))',
        ' ((factor I (lit "association-source-sha256") H) <-- (association I _ _ _ S) (associationDigest S H _))',
        ' ((factor I (lit "association-bundle-sha256") B) <-- (association I _ _ _ S) (associationDigest S _ B))',
        ' ((factor I (lit "fidelity-obligation") X) <-- (association I _ _ M _) (fidelityDuty M X _ _))',
        ' ((factor I (lit "fidelity-proof-gap") G) <-- (association I _ _ M _) (fidelityDuty M _ G _))',
        ' ((factor I (lit "fidelity-failure-map") F) <-- (association I _ _ M _) (fidelityDuty M _ _ F))',
        ' ((factor I (lit "quint-model") P) <-- (association I _ _ M _) (artifact M (lit "quint") P _))',
        ' ((factor I (lit "lean-model") P) <-- (association I _ _ M _) (artifact M (lit "lean") P _))',
        ' ((factor I (lit "model-source-sha256") D) <-- (association I _ _ M _) (artifact M _ _ D)))']
    selector='\n'.join(program)+'\n'
    if reasoning_projection['sourceModel']!=str(assurance_model.relative_to(ROOT)):raise ValueError('Unexpected reasoning authority')
    outputs[reasoning_projection['selectorPath']]=selector
    outputs[reasoning_projection['requestPath']]='((selector '+json.dumps(selector)+') (constructor "query"))\n'
    pressure_ids={v['painId'] for _,v in refactoring_pressures}
    modules={v['moduleId']:v for _,v in blueprint_groups['modules']}
    if len(modules)!=len(blueprint_groups['modules']):raise ValueError('Duplicate blueprint module')
    if len({v['interfaceId'] for _,v in blueprint_groups['interfaces']})!=len(blueprint_groups['interfaces']):raise ValueError('Duplicate blueprint interface')
    for v in modules.values():
        if v['ownerPath'] not in area_by_path or not set(split(v['painIds']))<=pressure_ids:raise ValueError('Unowned blueprint module/pressure')
        if not (ROOT/v['structureModel']).is_file():raise ValueError('Missing blueprint owner model')
    for _,v in blueprint_groups['interfaces']:
        if v['producerId'] not in modules or v['consumerId'] not in modules:raise ValueError('Unknown interface endpoint')
        for symbol in split(v['existingContracts']):
            if symbol not in contract_ids and not any(x.get('qualifiedName')==symbol and x['@type']=='RequirementDefinition' for x in elements):raise ValueError('Unknown existing blueprint contract '+symbol)
    if len(blueprint_groups['benefitCases'])!=len(pressure_ids) or {v['painId'] for _,v in blueprint_groups['benefitCases']}!=pressure_ids:raise ValueError('Incomplete/duplicated blueprint benefit coverage')
    for _,v in blueprint_groups['benefitCases']:
        if not set(split(v['stageIds']))<=set(stage_order) or not set(split(v['obligationIds']))<=obligation_ids:raise ValueError('Unbound benefit stage/obligation')
    for _,v in blueprint_groups['migrationStages']:
        if v['ownerPath'] not in area_by_path:raise ValueError('Unknown migration owner')
    blueprint_sources=[]
    for key in ['runtimeSources','buildSources']:
        for _,v in blueprint_groups[key]:
            source=ROOT/v['sourcePath']
            if not source.is_file():raise ValueError('Missing blueprint source '+v['sourcePath'])
            count=len(source.read_text().splitlines())
            for extent in split(v['sourceRanges']):
                ends=[int(x) for x in extent.split('-')]
                if not 1<=ends[0]<=ends[-1]<=count:raise ValueError('Invalid blueprint range '+extent)
            blueprint_sources.append(dict(v,sha256=sha(source)))
    def blueprint_table(f,group,columns,kind,source):
        table='#+NAME: '+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in blueprint_groups[group]:table+='| '+' | '.join(file_link(f,v[key],v[key]) if key in ['ownerPath','structureModel'] and key=='structureModel' else v[key] for key,label in columns)+' |\n'
        return generated(ROOT/source,kind,table)
    runtime_model='dev/architecture/runtime/models/sysml/composition.sysml';adoption_model='dev/refactoring/models/sysml/adoption.sysml';toolchain_model='dev/architecture/toolchain/models/sysml/architecture.sysml'
    f='dev/architecture/runtime/blueprint-map.org'
    body=blueprint_table(f,'modules',[(k,l) for k,l in [('moduleId','Module'),('label','Responsibility'),('ownerPath','Owner'),('owns','Owns'),('provides','Provides'),('excludes','Boundary'),('painIds','Pressures'),('structureModel','Owner model')]],'runtime-blueprint-modules',runtime_model)
    body+='\n** Shared contracts\n'+blueprint_table(f,'interfaces',[(k,l) for k,l in [('interfaceId','Interface'),('producerId','Producer'),('consumerId','Consumer'),('payload','Payload'),('orderedContract','Ordering'),('failureCustody','Failure custody'),('existingContracts','Existing predicates / bindings'),('disposition','Disposition')]],'runtime-blueprint-interfaces',runtime_model)
    def source_table(f,key,source,kind):
        table='| Fact | Source | Observation | Limit |\n|---+---+---+---|\n'
        for _,v in blueprint_groups[key]:
            refs='; '.join(file_link(f,v['sourcePath']+'::'+x.split('-')[0],v['sourcePath']+':'+x) for x in split(v['sourceRanges']))
            table+='| '+v['factId']+' | '+refs+' | '+v['observation']+' | '+v['limit']+' |\n'
        return generated(ROOT/source,kind,table)
    body+='\n** Source evidence\n'+source_table(f,'runtimeSources',runtime_model,'runtime-blueprint-sources')
    outputs[f]='#+TITLE: Runtime Blueprint Ownership and Shared Contract Map\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* Canonical composition projection\n:PROPERTIES:\n:CUSTOM_ID: runtime-blueprint-map\n:AUTHORITY: GambitRuntimeComposition\n:EVIDENCE_CLASS: derived-source-and-open-design\n:END:\n\nModule IDs describe responsibilities; separate IDs do not require separate allocations, OS threads or directories. Contract edges express producer-consumer obligations, not a complete native call graph. Existing bindings keep their original scope; all new composition is open.\n\n'+body
    lines=['# Derived from GambitRuntimeComposition module and interface metadata.','direction: right']
    for ident,v in modules.items():lines.append(ident+': '+json.dumps(v['label']))
    for _,v in blueprint_groups['interfaces']:lines.append(v['producerId']+' -> '+v['consumerId']+': '+json.dumps(v['interfaceId']))
    outputs['dev/architecture/runtime/diagrams/blueprint.d2']='\n'.join(lines)+'\n'
    f='dev/refactoring/modern-c/blueprint-matrix.org'
    body=blueprint_table(f,'benefitCases',[(k,l) for k,l in [('painId','Pressure'),('stageIds','Migration nodes'),('removedWork','Eliminated work'),('addedCost','Added cost'),('positiveCondition','Positive condition / measure'),('refutation','Refutation'),('obligationIds','Open obligations')]],'modern-c-blueprint-benefits',adoption_model)
    body+='\n** Migration dependency and retirement\n'+blueprint_table(f,'migrationStages',[(k,l) for k,l in [('stageId','Stage'),('dependsOn','Requires'),('deliverable','Deliverable'),('gate','Admission'),('ownerPath','Owner'),('retirement','Old responsibility retirement')]],'modern-c-blueprint-migration',adoption_model)
    outputs[f]='#+TITLE: Modern C Blueprint Benefit and Retirement Matrix\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* SysML-owned benefit and migration design\n:PROPERTIES:\n:CUSTOM_ID: modern-c-blueprint-matrix\n:AUTHORITY: GambitRefactoring\n:EVIDENCE_CLASS: derived-theoretical-conditions\n:END:\n\nEvery original pressure has one benefit case. Benefits are conditional work/cost arguments; none is a measured speedup or accepted retirement. The migration DAG is validated as a graph, not executed as a build or runtime plan.\n\n'+body
    lines=['# Derived from GambitRefactoring MigrationStage metadata. Nodes are design/qualification prerequisites.','direction: down']
    for _,v in blueprint_groups['migrationStages']:lines.append(v['stageId']+': '+json.dumps(v['stageId']+'\n'+textwrap.fill(v['deliverable'],38)))
    for _,v in blueprint_groups['migrationStages']:
        for dep in split(v['dependsOn']):lines.append(dep+' -> '+v['stageId'])
    outputs['dev/refactoring/modern-c/diagrams/migration.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/toolchain/build-map.org'
    body=blueprint_table(f,'buildNodes',[(k,l) for k,l in [('nodeId','Node'),('dependsOn','Dependencies'),('product','Product'),('keyInputs','Relevant inputs'),('reuseRule','Reuse rule'),('boundary','Boundary')]],'incremental-build-artifacts',toolchain_model)
    body+='\n** Delta acceptance cases\n'+blueprint_table(f,'buildDeltas',[(k,l) for k,l in [('caseId','Case'),('change','Change'),('expectedWork','Expected work'),('limit','Limit')]],'incremental-build-deltas',toolchain_model)
    body+='\n** Existing support and source evidence\n'+source_table(f,'buildSources',toolchain_model,'incremental-build-sources')
    outputs[f]='#+TITLE: Incremental and Parallel Build Contract Map\n#+SETUPFILE: ../../modeling/org/setup.org\n\n* Toolchain-owned projection\n:PROPERTIES:\n:CUSTOM_ID: incremental-build-map\n:AUTHORITY: GambitToolchain\n:EVIDENCE_CLASS: derived-design-and-source\n:END:\n\nSemantic unit boundaries belong to Scheme producers. This graph defines artifact dependency and publication contracts, not a newly implemented scheduler or cache. Existing parallel executors and valid dependency edges must be reused.\n\n'+body
    lines=['# Derived from GambitToolchain BuildArtifactNode metadata. Artifact families; instantiate real per-product edges.','direction: down']
    for _,v in blueprint_groups['buildNodes']:lines.append('n_'+v['nodeId']+': '+json.dumps(textwrap.fill(v['product'],32)))
    for _,v in blueprint_groups['buildNodes']:
        for dep in split(v['dependsOn']):lines.append('n_'+dep+' -> n_'+v['nodeId'])
    outputs['dev/architecture/toolchain/diagrams/incremental-build.d2']='\n'.join(lines)+'\n'
    # Responsibility and motivation views are model-owned; prose arguments and
    # native qualification remain separate. No second layout configuration.
    for _,v in research_lanes:
        if v['ownerPath'] not in area_by_path:raise ValueError('Unknown research lane owner '+v['ownerPath'])
    for _,v in refactoring_pressures:
        if 'dev/'+v['responsibleModule'] not in area_by_path:raise ValueError('Unknown pressure owner '+v['responsibleModule'])
        if not (ROOT/v['sourcePath']).is_file():raise ValueError('Missing refactoring evidence '+v['sourcePath'])
    f='dev/research-lanes.org'
    table='#+NAME: research-responsibility-lanes\n| Lane | Admission | Owner | Responsibility |\n|---+---+---+---|\n'
    for _,v in research_lanes:
        table+='| '+v['label']+' | '+v['admission']+' | '+file_link(f,v['ownerPath']+'/index.org',v['ownerPath'])+' | '+v['responsibility']+' |\n'
    outputs[f]='#+TITLE: Modernization Research Responsibilities\n#+SETUPFILE: modeling/org/setup.org\n\n* SysML-owned research lanes\n:PROPERTIES:\n:CUSTOM_ID: research-lanes\n:AUTHORITY: GambitDevelopmentOrganization\n:EVIDENCE_CLASS: derived-organization\n:END:\n\nModern C is mandatory. C++ is outside this research. A language-independent contract is not a Zig-only gain.\n\n'+generated(MODEL,'research-lanes',table)
    f='dev/refactoring/pressure-map.org'
    columns=[('painId','Identity'),('problem','Problem'),('structuralCoupling','Coupling'),('repairLimit','Local repair limit'),('replacement','Structural replacement'),('retirement','Retirement condition'),('responsibleModule','Owner')]
    table='#+NAME: refactoring-pressure-matrix\n| '+' | '.join(label for _,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
    evidence='#+NAME: refactoring-pressure-evidence\n| Identity | Local source / ranges | Public report | Evidence boundary |\n|---+---+---+---|\n'
    benefit='#+NAME: refactoring-benefit-measures\n| Identity | Measures to qualify | Necessary new costs |\n|---+---+---|\n'
    for _,v in refactoring_pressures:
        table+='| '+' | '.join(v[key] for key,_ in columns)+' |\n'
        links='; '.join(file_link(f,v['sourcePath']+'::'+a.split('-')[0],v['sourcePath']+':'+a) for a in split(v['sourceRanges']))
        public=('[[%s][historical reference]]'%v['publicReference']) if v['publicReference'] else 'No public-result premise'
        evidence+='| '+v['painId']+' | '+links+' | '+public+' | '+v['evidenceBoundary']+' |\n'
        benefit+='| '+v['painId']+' | '+v['benefitMeasures']+' | '+v['newCosts']+' |\n'
    adoption=ROOT/'dev/refactoring/models/sysml/adoption.sysml'
    outputs[f]='#+TITLE: Refactoring Pressure, Replacement and Benefit Matrix\n#+SETUPFILE: ../modeling/org/setup.org\n\n* Source-bound motivation; no native acceptance\n:PROPERTIES:\n:CUSTOM_ID: refactoring-pressure-map\n:AUTHORITY: GambitRefactoring\n:EVIDENCE_CLASS: derived-source-and-design\n:END:\n\nRows are research pressures, not eight proved current bugs. Current repairs and historical reports retain their own source and acceptance scope.\n\n'+generated(adoption,'refactoring-pressure',table)+'\n** Evidence boundaries\n'+generated(adoption,'refactoring-pressure-evidence',evidence)+'\n** Benefit and added cost\n'+generated(adoption,'refactoring-pressure-benefit',benefit)
    lines=['# Derived from RefactoringPressure metadata in adoption.sysml. Necessary replacement, not acceptance.','direction: right']
    for _,v in refactoring_pressures:
        node=v['painId']
        lines += [node+': '+json.dumps(v['problem'])+' {', '  coupling: '+json.dumps(textwrap.fill(v['structuralCoupling'],38)), '  replacement: '+json.dumps(textwrap.fill(v['replacement'],38)), '  retirement: '+json.dumps(textwrap.fill(v['retirement'],38)), '  coupling -> replacement: "change mechanism"', '  replacement -> retirement: "qualify before retiring"', '}']
    outputs['dev/refactoring/diagrams/pressure.d2']='\n'.join(lines)+'\n'
    research_view='| Investigation | Source / failure | Mechanism question | Formal correspondence | Disposition |\n|---+---+---+---+---|\n'
    for _,v in investigations:
        research_view+='| '+v['investigationId']+' | '+file_link('dev/research/index.org',v['sourceMechanism'],'source')+'; '+file_link('dev/research/index.org',v['failureEvidence'],'retained failure')+' | '+v['competingHypotheses']+' | '+file_link('dev/research/index.org',v['quintSource'],v['quintSymbol'])+'; '+file_link('dev/research/index.org',v['leanSource'],v['leanSymbol'])+' | '+v['disposition']+' |\n'
    outputs['dev/research/index.org']=replace_block((ROOT/'dev/research/index.org').read_text(),'repair-investigations',generated(ROOT/'dev/research/models/sysml/architecture.sysml','repair-investigations',research_view))
    root='dev/index.org';text=(ROOT/root).read_text()
    table='#+NAME: development-organization\n| Layer | Purpose | Entry |\n|---+---+---|\n'
    for _,v in areas:
        if v['relativePath'].count('/')==1:table+='| '+Path(v['relativePath']).name+' | '+v['purpose']+' | '+file_link(root,v['orgEntry'],'Org entry')+' |\n'
    block=generated(MODEL,'organization',table)
    if '#+BEGIN: sysml-view :kind organization' in text:text=replace_block(text,'organization',block)
    else:text=re.sub(r'(?ms)^#\+NAME: development-organization\n.*?(?=^\*\* Organization and traceability)',lambda _:block+'\n',text)
    outputs[root]=text
    f='dev/modeling/organization-map.org'
    table='| Owner | Purpose | Org | SysML | D2 | Quint | Lean |\n|---+---+---+---+---+---+---|\n'
    for _,v in areas:
        cells=[v['relativePath'],v['purpose']]+[file_link(f,v[k],k) if k in v else 'shared owner / not applicable' for k in ['orgEntry','structureModel','d2View','quintIndex','leanIndex']]
        table+='| '+' | '.join(cells)+' |\n'
    outputs[f]='#+TITLE: SysML-Owned Organization Map\n#+SETUPFILE: org/setup.org\n\n* Derived organization and model ownership\n:PROPERTIES:\n:CUSTOM_ID: organization-map\n:AUTHORITY: GambitDevelopmentOrganization\n:EVIDENCE_CLASS: derived-structural-view\n:END:\n\nDo not edit this generated view. Edit the owning SysML model. Empty artifact cells do not imply missing runtime proof.\n\n'+generated(MODEL,'full-organization',table)
    f='dev/modeling/correspondence.org';text=(ROOT/f).read_text();table='#+NAME: correspondence-summary\n| Contract | Owner / phase | Quint | Lean | Evidence class | Composition |\n|---+---+---+---+---+---|\n'
    for _,v in contracts:
        table+='| '+v['contractId']+' | '+v['ownerPath']+'; '+v['phaseScope']+' | '+file_link(f,v['quintSource'],Path(v['quintSource']).stem)+' | '+file_link(f,v['leanSource'],Path(v['leanSource']).stem)+' | '+v['resultClass']+' | '+v['dependencyStatus']+' |\n'
    block=generated(RELATIONS,'contracts',table)
    if '#+BEGIN: sysml-view :kind contracts' in text:text=replace_block(text,'contracts',block)
    else:text=re.sub(r'(?ms)^#\+NAME: correspondence-summary\n.*?(?=^\*\* OPEN ROOT-HANDOFF)',lambda _:block+'\n',text)
    # Existing detailed arguments remain authored Org; metadata lives in SysML.
    for x,v in contracts:
        start=text.index('** OPEN '+v['contractId']);end=text.index(':END:',start)
        block=text[start:end]
        block=re.sub(r'(?m)^:(?:OWNER|PRODUCER|CONSUMER):.*\n','',block)
        block=re.sub(r'(?m)^:MODEL_ELEMENT:.*\n','',block)
        text=text[:start]+block+':MODEL_ELEMENT: '+x['qualifiedName']+'\n'+text[end:]
    outputs[f]=text
    f='dev/architecture/runtime/interfaces/index.org';text=(ROOT/f).read_text()
    table='#+NAME: runtime-interface-ledger\n| Contract | Owner | Producer | Consumer | Composition |\n|---+---+---+---+---|\n'
    for _,v in contracts:table+='| '+v['contractId']+' | '+v['ownerPath']+' | '+v['producer']+' | '+v['consumer']+' | '+v['dependencyStatus']+' |\n'
    block=generated(RELATIONS,'interface-contracts',table)
    if '#+BEGIN: sysml-view :kind interface-contracts' in text:text=replace_block(text,'interface-contracts',block)
    else:text=re.sub(r'(?ms)^#\+NAME: runtime-interface-ledger\n.*?(?=^[-*])',lambda _:block+'\n',text,count=1)
    outputs[f]=text
    f='dev/modeling/proof-obligations.org'
    table='| Obligation | Contract / owner | Proposition | Evidence / disposition | Still required |\n|---+---+---+---+---|\n'
    for _,v in obligations:table+='| '+v['obligationId']+' | '+v['contractId']+'; '+v['responsibleModule']+' | '+v['proposition']+' | '+v['evidenceClass']+'; '+v['disposition']+' | '+v['missingPremise']+' |\n'
    deps='| Consumer | Prerequisite | Typed SysML dependency |\n|---+---+---|\n'+''.join('| '+x['consumer']+' | '+x['prerequisite']+' | ~'+x['id']+'~ |\n' for x in dependencies)
    outputs[f]='#+TITLE: GC and Control Proof Obligations\n#+SETUPFILE: org/setup.org\n\n* Derived obligation and dependency ledger\n:PROPERTIES:\n:CUSTOM_ID: proof-obligations\n:AUTHORITY: GambitRuntimeModelRelations\n:EVIDENCE_CLASS: derived-obligation-metadata\n:END:\n\nSource observations are limited facts. The prior direct finish/rescan claim is withdrawn for its bound guarded source. Conditional proof reports do not discharge their premises; no combined runtime contract is closed. Dispositions describe evidence, not SysML satisfaction.\n\n'+generated(RELATIONS,'obligations',table)+'\n** Phase-scoped dependencies\nArrows are consumer to prerequisite. Topological order: '+', '.join(order)+'. This is not a proof that native wait cycles are absent. Inventory creation precedes root sealing; traversal/resolution follows admission.\n\n'+generated(RELATIONS,'dependencies',deps)
    for _,area in areas:
        for method,field in [('quint','quintIndex'),('lean','leanIndex')]:
            if field not in area:continue
            f=area[field];old=(ROOT/f).read_text();identity=re.search(r'(?m)^:ID:\s*(.*)$',old)[1]
            table='| Contract | Source | Exact symbols | Scope / premises | Composition status |\n|---+---+---+---+---|\n'
            for _,v in contracts:
                if area['relativePath'] not in split(v['participantPaths']):continue
                key=method+'Source';sym=method+'Symbols';table+='| '+v['contractId']+' | '+file_link(f,v[key],Path(v[key]).name)+' | '+v[sym]+' | '+((v['quintInitializer']+' / '+v['quintStep']+' / '+v['quintCohort']+' / '+v['quintParameters']) if method=='quint' else 'Conditional theorem premises remain source obligations')+' | '+v['dependencyStatus']+' |\n'
            for _,supplement in support:
                if supplement['kind']!=method:continue
                binding=next(v for _,v in contracts if v['contractId']==supplement['contractId'])
                if area['relativePath'] not in split(binding['participantPaths']):continue
                table+='| '+supplement['contractId']+' supporting slice | '+file_link(f,supplement['path'],Path(supplement['path']).name)+' | '+supplement['symbols']+' | '+supplement['scope']+' | no fresh formal admission |\n'
            outputs[f]='#+TITLE: '+Path(area['relativePath']).name.title()+' '+method.title()+' Model Index\n#+SETUPFILE: '+os.path.relpath(ROOT/'dev/modeling/org/setup.org',(ROOT/f).parent)+'\n\n* Model source ownership\n:PROPERTIES:\n:ID: '+identity+'\n:CUSTOM_ID: '+Path(area['relativePath']).name+'-'+method+'\n:AUTHORITY: GambitRuntimeModelRelations\n:EVIDENCE_CLASS: derived-source-index\n:END:\n\nAuthoritative QNT/Lean source remains under repository models/. No copied formal implementation and no proof rerun.\n\n'+generated(RELATIONS,'module-'+method,table)+'\n'+file_link(f,'dev/modeling/correspondence.org','Exact projections and counterexamples')+'\n'+file_link(f,'dev/modeling/proof-obligations.org','Obligations and dependencies')+'\n'
    # D2 uses the same exported ownership and typed dependency edges.
    lines=['# Generated from dev/organization.sysml; do not edit.','direction: down','development: dev {','  grid-columns: 2']
    children={}
    for element,value in areas:children.setdefault(element.get('owningNamespace',{}).get('@id'),[]).append((element,value))
    def emit_area(element,value,depth):
        indent='  '*depth;key='area'+str(areas.index((element,value)))
        own_children=children.get(element['@id'],[])
        if not own_children:return [indent+key+': '+json.dumps(Path(value['relativePath']).name)]
        body=[indent+key+': '+json.dumps(Path(value['relativePath']).name)+' {',indent+'  grid-columns: 2']
        for child,child_value in own_children:body+=emit_area(child,child_value,depth+1)
        return body+[indent+'}']
    for element,value in areas:
        if element.get('owningNamespace',{}).get('@id') not in {x['@id'] for x,_ in areas}:lines+=emit_area(element,value,1)
    lines+=['}']
    outputs['dev/organization.d2']='\n'.join(lines)+'\n'
    lines=['# Generated from canonical runtime model relations; do not edit.','direction: down']
    node={v['contractId']:'c'+str(i) for i,(_,v) in enumerate(contracts)}
    for _,v in contracts:
        key=node[v['contractId']];lines.append(key+': '+json.dumps(v['contractId']+'\n'+v['dependencyStatus']))
        lines.append(key+'.style.fill: '+json.dumps('#FFD9D9' if 'blocked' in v['dependencyStatus'] else '#E6EEF8'))
    for edge in dependencies:lines.append(node[edge['consumer']]+' -> '+node[edge['prerequisite']]+': requires')
    outputs['dev/architecture/runtime/interfaces/diagrams/relations.d2']='\n'.join(lines)+'\n'
    f='dev/architecture/runtime/interfaces/completion-model-map.org'
    source_table='| Source fact | Anchor | Established source behavior | Limit |\n|---+---+---+---|\n'
    for _,value in anchors:
        source_table+='| '+value['sourceId']+' | '+file_link(f,value['path']+'::'+value['firstLine'],value['path']+':'+value['firstLine'])+' | '+value['fact']+' | '+value['limit']+' |\n'
    transition_table='| From | To | Guard / custody | Evidence boundary |\n|---+---+---+---|\n'
    for _,value in lifecycle:transition_table+='| '+value['fromState']+' | '+value['toState']+' | '+value['guard']+' | '+value['evidenceBoundary']+' |\n'
    completion_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/collection-completion.sysml'
    outputs[f]='#+TITLE: Collection Completion Model Source Map\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* Derived source facts and proposed phase transitions\n:PROPERTIES:\n:CUSTOM_ID: completion-model-map\n:AUTHORITY: GambitCollectionCompletion\n:EVIDENCE_CLASS: derived-source-and-design-map\n:END:\n\nSource observations and proposed transitions have different evidence boundaries. No runtime or formal behavior is executed by this view.\n\n'+generated(completion_model,'completion-source-map',source_table)+'\n** Proposed lifecycle\n'+generated(completion_model,'completion-lifecycle',transition_table)
    lines=['# Generated from the collection completion SysML lifecycle metadata.','direction: down']
    states=[]
    for _,value in lifecycle:
        for state in [value['fromState'],value['toState']]:
            if state not in states:states.append(state)
    for state in states:
        lines.append(state+': '+json.dumps(re.sub(r'(?<=[a-z])(?=[A-Z])',' ',state)))
        if state in ['ProtocolViolation','RetainedFailure']:lines.append(state+'.style.fill: "#FFE1D6"')
        elif state in ['StrongDrained','WeakDrained','CollectionComplete','TargetPermit']:lines.append(state+'.style.fill: "#E2EFF7"')
    for _,value in lifecycle:lines.append(value['fromState']+' -> '+value['toState']+': '+json.dumps(textwrap.fill(value['guard'], width=32)))
    outputs['dev/architecture/runtime/interfaces/diagrams/completion-custody.d2']='\n'.join(lines)+'\n'
    producer_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/producer-custody.sysml'
    f='dev/architecture/runtime/interfaces/producer-custody-map.org'
    table='#+NAME: producer-family-census\n| Family / phase | Source ranges | Entry and derived work | Closing cut | Coverage limit |\n|---+---+---+---+---|\n'
    for _,v in producers:
        links='; '.join(file_link(f,v['path']+'::'+a.split('-')[0],a) for a in split(v['ranges']))
        table+='| '+v['familyId']+' / '+v['phase']+' | '+links+' | '+v['entryPath']+'; '+v['derivedWork']+' | '+v['closingCut']+' | '+v['coverageLimit']+' |\n'
    edges='#+NAME: custody-transfer-edges\n| Edge / stages | Commit requirement | Failure custody | Obligation |\n|---+---+---+---|\n'
    for _,v in custody:edges+='| '+v['edgeId']+': '+v['fromState']+' -> '+v['toState']+' | '+v['commitRule']+' | '+v['failureCustody']+' | '+v['obligationId']+' |\n'
    sites='#+NAME: lexical-producer-callsites\n| Source | Symbol | Lexical classification | Families |\n|---+---+---+---|\n'
    for v in sorted(callsites,key=lambda x:(x['path'],x['line'],x['symbol'])):sites+='| '+file_link(f,v['path']+'::'+str(v['line']),v['path']+':'+str(v['line']))+' | ~'+v['symbol']+'~ | '+v['kind']+' | '+('; '.join(v['families']) or 'declaration/reference outside selected body')+' |\n'
    outputs[f]='#+TITLE: Producer Census and Custody Transfer Map\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned producer and transfer inventory\n:PROPERTIES:\n:CUSTOM_ID: producer-custody-map\n:AUTHORITY: GambitProducerCustody\n:EVIDENCE_CLASS: derived-source-census-and-design\n:END:\n\nAll tables derive from owned SysML metadata. Lexical occurrences retain conditional branches; they do not establish macro expansion, generated module, indirect callback or writer closure. Identifier references are not asserted to be runtime calls.\n\n'+generated(producer_model,'producer-families',table)+'\n** Parent-child custody\n'+generated(producer_model,'custody-edges',edges)+'\n** Bounded source census\n'+generated(producer_model,'producer-callsites',sites)
    lines=['# Generated from producer-custody.sysml; edge IDs resolve to full rules in producer-custody-map.org.','direction: down']
    for group in ['scan','native']:
        edges_in_group=[v for _,v in custody if (v['edgeId'].startswith('Native'))==(group=='native')]
        lines.append(group+': '+json.dumps('Native resource custody' if group=='native' else 'Tracing work custody')+' {')
        states=list(dict.fromkeys(state for v in edges_in_group for state in [v['fromState'],v['toState']]))
        for state in states:lines.append('  '+state+': '+json.dumps(re.sub(r'(?<=[a-z])(?=[A-Z])',' ',state)))
        for v in edges_in_group:lines.append('  '+v['fromState']+' -> '+v['toState']+': '+json.dumps(v['edgeId']+'\n'+v['obligationId']))
        lines.append('}')
    outputs['dev/architecture/runtime/interfaces/diagrams/producer-custody.d2']='\n'.join(lines)+'\n'
    refinement_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/atomic-refinement.sysml'
    f='dev/architecture/runtime/interfaces/atomic-refinement-map.org'
    table='#+NAME: native-to-quint-projection\n| Source step | Native operation and custody | Current QNT action | Planned projection / class | Missing premise / obligation |\n|---+---+---+---+---|\n'
    for _,v in refinements:
        table+='| '+v['stepId']+'; '+file_link(f,v['path']+'::'+v['firstLine'],v['path']+':'+v['firstLine']+'-'+v['lastLine'])+' | '+v['nativeOperation']+'; '+v['custody']+' | '+v['currentAction']+' | '+v['plannedAction']+'; '+v['projectionClass']+' | '+v['missingPremise']+'; '+v['obligationId']+' |\n'
    proof='#+NAME: lean-refinement-targets\n| Target / obligation | Proposition | Required premises | Existing support / inherited disposition |\n|---+---+---+---|\n'
    by_obligation={v['obligationId']:v for _,v in obligations}
    for _,v in proof_targets:proof+='| '+v['targetId']+'; '+v['obligationId']+' | '+v['proposition']+' | '+v['premises']+' | '+v['existingSupport']+'; '+by_obligation[v['obligationId']]['disposition']+' |\n'
    edge_table='#+NAME: atomic-projection-fragments\n| Edge / stages | Abstract effect | Evidence boundary |\n|---+---+---|\n'
    for _,v in projection_edges:edge_table+='| '+v['edgeId']+': '+v['fromState']+' -> '+v['toState']+' | '+v['abstractEffect']+' | '+v['evidenceClass']+' |\n'
    outputs[f]='#+TITLE: Native Custody to QNT Refinement Map\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned source projection and Lean proof targets\n:PROPERTIES:\n:CUSTOM_ID: atomic-refinement-map\n:AUTHORITY: GambitAtomicRefinement\n:EVIDENCE_CLASS: derived-refinement-plan\n:END:\n\nCurrent action names are checked against unchanged gc_work_closure.qnt. Planned names are design proposals, not implemented or checked QNT actions. Proof dispositions are inherited from the shared obligation ledger.\n\n'+generated(refinement_model,'atomic-source-projection',table)+'\n** Lean proof frontier\n'+generated(refinement_model,'atomic-lean-targets',proof)+'\n** Concurrent projection fragments\nEdge IDs in D2 resolve to the complete rules below; fragments do not form a single global automaton.\n\n'+generated(refinement_model,'atomic-projection-edges',edge_table)
    lines=['# Generated projection fragments; concurrent parent/child custody is not a single global automaton.','# Edge IDs resolve to complete effects/boundaries in atomic-refinement-map.org.','direction: down']
    states=list(dict.fromkeys(state for _,v in projection_edges for state in [v['fromState'],v['toState']]))
    for state in states:
        lines.append(state+': '+json.dumps(re.sub(r'(?<=[a-z])(?=[A-Z])',' ',state)))
        if state in ['RetainedFailure','LateRetained']:lines.append(state+'.style.fill: "#FFE1D6"')
    for _,v in projection_edges:lines.append(v['fromState']+' -> '+v['toState']+': '+json.dumps(v['edgeId']))
    outputs['dev/architecture/runtime/interfaces/diagrams/atomic-refinement.d2']='\n'.join(lines)+'\n'
    discovery_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/child-discovery.sysml'
    f='dev/architecture/runtime/interfaces/child-discovery-map.org'
    tables=[]
    for kind,heading,columns,group in [
        ('domains','State domains',[('domainId','Domain'),('identityScope','Identity'),('stateFields','Fields'),('invariant','Invariant'),('obligationId','Obligation')],discovery_domains),
        ('actions','Action contracts',[('actionId','Action'),('guard','Guard'),('updateRule','Update'),('accounting','Accounting'),('frameRule','Frame rule'),('obligationId','Obligation')],discovery_actions),
        ('scenarios','Retained and proposed scenarios',[('caseId','Scenario'),('kind','Class'),('currentInitializer','Current initializer'),('history','History'),('requiredOutcome','Required outcome'),('evidenceBoundary','Boundary'),('obligationId','Obligation')],discovery_scenarios),
        ('preservation','Lean preservation cases',[('caseId','Case'),('actionIds','Actions'),('guardPremises','Premises'),('establishedAfter','Postcondition'),('obligationId','Obligation')],discovery_cases)]:
        table='#+NAME: child-discovery-'+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in group:table+='| '+' | '.join(v[key] for key,label in columns)+' |\n'
        tables.append('** '+heading+'\n'+generated(discovery_model,'child-'+kind,table))
    table='#+NAME: child-discovery-source-facts\n| Fact | Source | Behavior | Limit |\n|---+---+---+---|\n'
    for _,v in discovery_sources:table+='| '+v['sourceId']+' | '+file_link(f,v['path']+'::'+v['firstLine'],v['path']+':'+v['firstLine']+'-'+v['lastLine'])+' | '+v['fact']+' | '+v['limit']+' |\n'
    outputs[f]='#+TITLE: Child Discovery State, Guard and Preservation Map\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned discovery and fragment contracts\n:PROPERTIES:\n:CUSTOM_ID: child-discovery-map\n:AUTHORITY: GambitChildDiscovery\n:EVIDENCE_CLASS: derived-action-design\n:END:\n\nAction contracts and scenarios are unimplemented design. Existing initializer names are checked against the unchanged QNT; no new execution result is asserted. Obligation dispositions are inherited through the shared closure matrix.\n\n'+'\n'.join(tables)+'\n** Source facts\n'+generated(discovery_model,'child-sources',table)
    for diagram_id in dict.fromkeys(v['diagramId'] for _,v in discovery_diagrams):
        rows=[v for _,v in discovery_diagrams if v['diagramId']==diagram_id]
        lines=['# Generated entirely from child-discovery.sysml diagram edges; guards in child-discovery-map.org.','direction: down']
        for group_id in dict.fromkeys(v['groupId'] for v in rows):
            members=[v for v in rows if v['groupId']==group_id]
            if len({v['groupLabel'] for v in members})!=1:raise ValueError('Conflicting discovery diagram group label')
            if group_id:lines.append(group_id+': '+json.dumps(members[0]['groupLabel'])+' {')
            indent='  ' if group_id else ''
            states=list(dict.fromkeys(s for v in members for s in [v['fromState'],v['toState']]))
            nodes={s:'n'+str(i) for i,s in enumerate(states)}
            for s,node in nodes.items():lines.append(indent+node+': '+json.dumps(s))
            for v in members:lines.append(indent+nodes[v['fromState']]+' -> '+nodes[v['toState']]+': '+json.dumps(textwrap.fill(v['label'],width=25)))
            if group_id:lines.append('}')
        outputs['dev/architecture/runtime/interfaces/diagrams/'+diagram_id+'.d2']='\n'.join(lines)+'\n'
    copy_model=ROOT/'dev/architecture/runtime/interfaces/models/sysml/copy-handoff.sysml'
    f='dev/architecture/runtime/interfaces/copy-handoff-map.org';tables=[]
    for kind,heading,columns,group in [
        ('routes','Partial-order routes',[('routeId','Route'),('scope','Scope'),('orderedCuts','Cuts'),('acceptance','Acceptance'),('failureCustodian','Failure custodian'),('obligationId','Obligation')],copy_routes),
        ('failures','Failure cuts',[('failureId','Failure'),('cut','Cut'),('custody','Retained custody'),('forbidden','Forbidden shortcut'),('boundary','Evidence boundary'),('obligationId','Obligation')],copy_failures),
        ('preservation','Lean preservation premises',[('caseId','Case'),('premises','Premises'),('preserved','Postcondition'),('existingSupport','Existing support / gap'),('obligationId','Obligation')],copy_cases)]:
        table='#+NAME: copy-handoff-'+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in group:table+='| '+' | '.join(v[key] for key,label in columns)+' |\n'
        tables.append('** '+heading+'\n'+generated(copy_model,'copy-'+kind,table))
    table='#+NAME: copy-handoff-source-facts\n| Fact | Source | Behavior | Limit |\n|---+---+---+---|\n'
    for _,v in copy_sources:table+='| '+v['sourceId']+' | '+file_link(f,v['path']+'::'+v['firstLine'],v['path']+':'+v['firstLine']+'-'+v['lastLine'])+' | '+v['fact']+' | '+v['limit']+' |\n'
    outputs[f]='#+TITLE: Copy Handoff Routes, Failure Custody and Preservation\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned copy and fragment transfer map\n:PROPERTIES:\n:CUSTOM_ID: copy-handoff-map\n:AUTHORITY: GambitCopyHandoff\n:EVIDENCE_CLASS: derived-partial-order-design\n:END:\n\nRoutes are scoped to copy/batch identity; they are not one mandatory global function sequence. Source facts do not establish worker-loss recovery or native visibility. Full amended action guards remain in child-discovery-map.org; dispositions stay in the shared obligation ledger.\n\n'+'\n'.join(tables)+'\n** Source evidence\n'+generated(copy_model,'copy-sources',table)
    lifetime_file='dev/architecture/runtime/interfaces/custody-lifetime-map.org';lifetime_tables=[]
    for kind,heading,columns,group in [
        ('steps','Lifecycle transitions',[('stepId','Step'),('fromState','From'),('toState','To'),('guard','Guard'),('custody','Custodian'),('taskFrame','Frame'),('obligationId','Obligation')],lifetime_steps),
        ('receipts','Receipt currency',[('ruleId','Rule'),('cut','Cut'),('validity','Validity'),('limit','Boundary'),('obligationId','Obligation')],receipt_rules),
        ('counterexamples','Unexecuted counterexample histories',[('scenarioId','History ID'),('classification','Class'),('history','History'),('failure','Failure'),('requiredGuard','Required guard'),('obligationId','Obligation')],lifetime_counterexamples)]:
        table='#+NAME: custody-lifetime-'+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in group:table+='| '+' | '.join(v[key] for key,label in columns)+' |\n'
        lifetime_tables.append('** '+heading+'\n'+generated(copy_model,'lifetime-'+kind,table))
    outputs[lifetime_file]='#+TITLE: Private Cursor and Tail Custody Lifecycle\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned lifecycle and receipt map\n:PROPERTIES:\n:CUSTOM_ID: custody-lifetime-map\n:AUTHORITY: GambitCopyHandoff\n:EVIDENCE_CLASS: derived-lifecycle-design\n:END:\n\nStatus belongs only to the shared obligation ledger. Histories are proposed controls, not newly executed model traces or established native reachability.\n\n'+'\n'.join(lifetime_tables)
    migration_file='dev/architecture/runtime/interfaces/migration-cut-map.org';migration_tables=[]
    for kind,heading,columns,group in [
        ('cuts','Candidate cut admission',[('cutId','Cut'),('sourceCut','Source boundary'),('admission','Admission'),('guard','Guard'),('restoreBoundary','Restore boundary'),('obligationId','Obligation')],migration_cuts),
        ('fields','Restore inventory',[('fieldId','State family'),('content','Content'),('invariant','Invariant'),('scope','Scope'),('obligationId','Obligation')],restore_fields),
        ('steps','Proposed QNT atomic steps',[('stepId','Step'),('guard','Guard'),('updates','Updates'),('taskFrame','Frame'),('sourceMapping','Source mapping / gap'),('obligationId','Obligation')],migration_steps),
        ('races','Unexecuted race histories',[('scenarioId','History'),('classification','Class'),('history','Steps'),('failure','Failure'),('requiredGuard','Required guard'),('obligationId','Obligation')],migration_races)]:
        table='#+NAME: migration-cut-'+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in group:table+='| '+' | '.join(v[key] for key,label in columns)+' |\n'
        migration_tables.append('** '+heading+'\n'+generated(copy_model,'migration-'+kind,table))
    outputs[migration_file]='#+TITLE: Migration Cuts, Restore State and Atomic Steps\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned migration refinement map\n:PROPERTIES:\n:CUSTOM_ID: migration-cut-map\n:AUTHORITY: GambitCopyHandoff\n:EVIDENCE_CLASS: derived-migration-design\n:END:\n\nCandidate admission is not native qualification. Atomic steps are specifications, not implemented QNT or C primitives. Status remains in the shared obligation ledger.\n\n'+'\n'.join(migration_tables)
    pair_file='dev/architecture/runtime/interfaces/pair-resume-map.org';pair_tables=[]
    for kind,heading,columns,group in [
        ('labels','Source-grounded resume labels',[('labelId','Label'),('knownState','Established local state'),('nextAction','Next action'),('retainedDebt','Retained responsibility'),('obligationId','Obligation')],pair_labels),
        ('steps','Proposed QNT atomic steps',[('stepId','Step'),('guard','Guard'),('updates','Updates'),('taskFrame','Frame'),('obligationId','Obligation')],pair_steps),
        ('races','Unexecuted counterexamples',[('scenarioId','History'),('classification','Class'),('history','Steps'),('failure','Failure'),('requiredGuard','Required guard'),('obligationId','Obligation')],pair_races)]:
        table='#+NAME: pair-resume-'+kind+'\n| '+' | '.join(label for key,label in columns)+' |\n|'+ '+'.join('---' for _ in columns)+'|\n'
        for _,v in group:
            values=[v[key] for key,label in columns]
            if kind=='labels':values[0]=file_link(pair_file,v['sourcePath']+'::'+v['firstLine'],v['labelId']+' '+v['firstLine']+'-'+v['lastLine'])
            table+='| '+' | '.join(values)+' |\n'
        pair_tables.append('** '+heading+'\n'+generated(copy_model,'pair-'+kind,table))
    outputs[pair_file]='#+TITLE: PAIR Scan Resume Labels, Steps and Counterexamples\n#+SETUPFILE: ../../../modeling/org/setup.org\n\n* SysML-owned PAIR scan continuation map\n:PROPERTIES:\n:CUSTOM_ID: pair-resume-map\n:AUTHORITY: GambitCopyHandoff\n:EVIDENCE_CLASS: derived-pair-design\n:END:\n\nNames denote proposed resume tags over real source cuts. Only again is an existing C label here; no native migration support or new model execution is asserted. Shared ledger owns dispositions.\n\n'+'\n'.join(pair_tables)
    for diagram_id in dict.fromkeys(v['diagramId'] for _,v in copy_diagrams):
        rows=[v for _,v in copy_diagrams if v['diagramId']==diagram_id]
        states=list(dict.fromkeys(state for v in rows for state in [v['fromState'],v['toState']]))
        nodes={state:'s'+str(i) for i,state in enumerate(states)}
        lines=['# Generated from copy-handoff.sysml; route and failure guards in copy-handoff-map.org.','direction: down']
        for state,node in nodes.items():
            lines.append(node+': '+json.dumps(textwrap.fill(state,width=26)))
            if 'Retained' in state:lines.append(node+'.style.fill: "#FFE1D6"')
        for v in rows:lines.append(nodes[v['fromState']]+' -> '+nodes[v['toState']]+': '+json.dumps(textwrap.fill(v['label'],width=24)))
        outputs['dev/architecture/runtime/interfaces/diagrams/'+diagram_id+'.d2']='\n'.join(lines)+'\n'
    # Derive formal source bindings, including the transitive local import closure.
    sources={};external={};pending=[v[m+'Source'] for _,v in contracts for m in ['quint','lean']]+[v['path'] for _,v in support]+[v[m+'Source'] for v in sets.values() for m in ['quint','lean']]
    while pending:
        name=pending.pop()
        if name in sources:continue
        p=ROOT/name;body=p.read_text();deps=[]
        if p.suffix=='.qnt':
            deps=[str((p.parent/(v+'.qnt')).resolve().relative_to(ROOT)) for v in re.findall(r'\bfrom\s+"([^"]+)"',body)]
        else:
            for imp in re.findall(r'(?m)^import\s+([A-Za-z0-9_.]+)',body):
                local=p.parent/(imp.replace('.','/')+'.lean')
                if local.exists():deps.append(str(local.relative_to(ROOT)))
                else:external.setdefault(name,[]).append(imp)
        sources[name]={'sha256':sha(p),'localImports':sorted(set(deps)),'evidenceClass':'source-identity-only'};pending+=deps
    for _,v in contracts:
        for method,kind in [('quint',r'(?:action|val|temporal|def)'),('lean','theorem')]:
            body=(ROOT/v[method+'Source']).read_text()
            for sym in split(v[method+'Symbols'])+([v['quintInitializer'],v['quintStep'],v['quintProperty']]+([v['temporalProperty']] if v['temporalProperty'] else []) if method=='quint' else []):
                if not re.search(r'\b'+kind+r'\s+'+re.escape(sym)+r'\b',body):raise ValueError('Missing bound symbol '+sym)
    resolved_requirements={}
    for _,contract in contracts:
        refs=[]
        for symbol in split(contract['structuralSymbols']):
            matches=[x for x in elements if x['@type']=='RequirementDefinition' and x.get('declaredName')==symbol]
            if len(matches)!=1:raise ValueError('Missing/ambiguous structural predicate '+symbol)
            refs.append(matches[0]['qualifiedName'])
        resolved_requirements[contract['contractId']]=refs
    declaration='models/gambit/lean/lakefile.toml';cfg=tomllib.loads((ROOT/declaration).read_text());dep=next(x for x in cfg['require'] if x['name']=='LeanPoo')
    report_audits=[]
    for name in sorted({v['inputManifest'] for _,v in contracts if v['inputManifest']}):
        manifest=json.loads((ROOT/name).read_text());rows=[]
        facts_path=ROOT/str(Path(name).with_name(Path(name).name.replace('.manifest.json','-facts.json')))
        facts=json.loads(facts_path.read_text())['facts']
        report_sources=[]
        for report in sorted({v['evidenceReport'] for _,v in contracts if v['inputManifest']==name and v['evidenceReport']}):
            declarations=[row for row in facts['source'] if row[1]==report]
            if len(declarations)!=1:raise ValueError('Missing/ambiguous historical report binding '+report)
            expected=declarations[0][2]
            report_sources.append({'path':report,'factsPath':str(facts_path.relative_to(ROOT)),'factsSha256':sha(facts_path),'expectedSha256':expected,'currentSha256':sha(ROOT/report),'matches':expected==sha(ROOT/report)})
        for path,expected in manifest['contextInputs'].items():
            p=ROOT/path;rows.append({'path':path,'expectedSha256':expected,'currentSha256':sha(p) if p.exists() else None})
        report_audits.append({'manifest':name,'manifestSha256':sha(ROOT/name),'reportSources':report_sources,'contextInputs':rows,'selectedCoverage':[{'contractId':v['contractId'],'quintRootBound':v['quintSource'] in manifest['contextInputs'],'leanRootBound':v['leanSource'] in manifest['contextInputs'],'reportScope':v['reportScope']} for _,v in contracts if v['inputManifest']==name],'allContextInputsMatch':all(v['expectedSha256']==v['currentSha256'] for v in rows),'admission':'historical-report-source-identity-only-not-composition'})
    result={'authority':'Derived from SysML organization and owned model relation metadata; not a layout source','canonicalSourceBindings':{str(MODEL.relative_to(ROOT)):sha(MODEL),str(RELATIONS.relative_to(ROOT)):sha(RELATIONS)},'modelSourceBindings':{name:sha(ROOT/name) for name in files},'resolvedStructuralRequirements':resolved_requirements,'relations':[v for _,v in contracts],'supportingModels':[v for _,v in support],'sourceAnchors':[dict(v,sha256=sha(ROOT/v['path'])) for _,v in anchors],'lifecycle':[v for _,v in lifecycle],'dependencies':dependencies,'obligations':[v for _,v in obligations],'sources':sources,'externalImports':external,'historicalReportAudits':report_audits,'externalDependencyDeclaration':{'file':declaration,'sha256':sha(ROOT/declaration),'package':'LeanPoo','declaredRevision':dep['rev'],'externalSourceInspected':False,'environmentClosure':'unresolved'},'execution':{'quint':False,'lean':False,'native':False},'refinementStatus':'not-mechanized; prior trace withdrawn; producer/phase/permit refinement open'}
    result.update({'producerFamilies':[dict(v,sha256=sha(ROOT/v['path'])) for _,v in producers], 'custodyEdges':[v for _,v in custody], 'producerCensusScopes':[v for _,v in census], 'lexicalProducerOccurrences':callsites})
    result.update({'refinementSteps':[dict(v,sha256=sha(ROOT/v['path'])) for _,v in refinements], 'refinementProofTargets':[dict(v,disposition=by_obligation[v['obligationId']]['disposition']) for _,v in proof_targets], 'projectionEdges':[v for _,v in projection_edges]})
    result['childDiscovery']={'stateDomains':[v for _,v in discovery_domains],'actionContracts':[v for _,v in discovery_actions],'scenarios':[v for _,v in discovery_scenarios],'preservationCases':[v for _,v in discovery_cases],'sourceFacts':[dict(v,sha256=sha(ROOT/v['path'])) for _,v in discovery_sources],'diagramEdges':[v for _,v in discovery_diagrams],'execution':'design-only; QNT/Lean unchanged and unexecuted'}
    result['copyHandoff']={'routes':[v for _,v in copy_routes],'failureCuts':[v for _,v in copy_failures],'preservationCases':[v for _,v in copy_cases],'sourceFacts':[dict(v,sha256=sha(ROOT/v['path'])) for _,v in copy_sources],'diagramEdges':[v for _,v in copy_diagrams],'lifetimeSteps':[v for _,v in lifetime_steps],'receiptRules':[v for _,v in receipt_rules],'lifetimeCounterexamples':[v for _,v in lifetime_counterexamples],'migrationCuts':[v for _,v in migration_cuts],'restoreFields':[v for _,v in restore_fields],'migrationAtomicSteps':[v for _,v in migration_steps],'migrationRaces':[v for _,v in migration_races],'pairResumeLabels':[dict(v,sha256=sha(ROOT/v['sourcePath'])) for _,v in pair_labels],'pairAtomicSteps':[v for _,v in pair_steps],'pairRaces':[v for _,v in pair_races],'amendedActionIds':[v['actionId'] for _,v in copy_action_bindings],'execution':'design-only; no QNT/Lean or native execution'}
    result['repairInvestigations']=[dict(v,sourceHashes={v[k]:sha(ROOT/v[k]) for k in ('gateDefinition','failureEvidence','sourceMechanism','quintSource','leanSource')}) for _,v in investigations]
    result['modernizationRationale']={'researchLanes':[v for _,v in research_lanes],'pressures':[dict(v,sourceSha256=sha(ROOT/v['sourcePath'])) for _,v in refactoring_pressures],'status':'design-only; source pressure is not a proved current bug or accepted replacement','cxxConsidered':False,'runtimePathsRetired':0}
    result['runtimeBlueprint']={key:[v for _,v in group] for key,group in blueprint_groups.items()}
    result['runtimeBlueprint'].update({'sourceBindings':blueprint_sources,'migrationOrder':stage_order,'buildOrder':build_order,'status':'design-only; all composed/native/benefit obligations open','runtimePathsRetired':0})
    result['sourceChain']={key:[v for _,v in group] for key,group in chain_groups.items() if key not in ['formalSets','modelUses','reasoning']}
    result['sourceChain'].update({'sourceBindings':chain_sources,'topologicalOrder':chain_order,'correctnessOrder':correctness_order,'snapshotIssueOrder':issue_order,'populationCounts':{'generation':34,'compilation':34,'composition':6,'sliceActions':74},'status':'source-specific design; no native execution'})
    result['componentModels']={'formalSets':list(sets.values()),'uses':resolved_model_uses,'reasoningProjection':reasoning_projection,'ascentSelector':reasoning_projection['selectorPath'],'ascentRequest':reasoning_projection['requestPath'],'associationBundle':association_bundle,'associationInputs':association_inputs,'status':'conditional formal support; source refinement and progress open'}
    outputs['dev/modeling/formal-bindings.json']=json.dumps(result,indent=2)+'\n'
    return outputs,{'diagnosticArgv':diagnostic_cmd,'diagnosticSha256':sha(TASK/'view-diagnostics.stdout.json'),'exportArgv':cmd,'apiExportSha256':sha(api),'areas':len(areas),'contracts':len(contracts),'dependencies':len(dependencies),'obligations':len(obligations),'formalSources':len(sources),'producerFamilies':len(producers),'custodyEdges':len(custody),'lexicalOccurrences':len(callsites),'refinementSteps':len(refinements),'refinementProofTargets':len(proof_targets),'projectionEdges':len(projection_edges),'topologicalOrder':order,'canonicalInputs':result['canonicalSourceBindings']}

def main():
    global TASK
    parser=argparse.ArgumentParser(description=__doc__);group=parser.add_mutually_exclusive_group();group.add_argument('--write',action='store_true');group.add_argument('--check',action='store_true');parser.add_argument('--task',default='sysml-contract-closure');args=parser.parse_args()
    if not re.fullmatch(r'[a-z0-9][a-z0-9-]*',args.task):parser.error('task must be a local task name')
    TASK=ROOT/'.cache/tasks'/args.task
    if os.environ.get('GAMBIT_SMP_TASK_ID'):
        from gambit_smp.workspace import task_output
        TASK=task_output(ROOT,'.cache/sysml-repair-views')
    outputs,receipt=derive();drift=[]
    for name,body in outputs.items():
        p=ROOT/name
        if not p.exists() or p.read_text()!=body:
            drift.append(name)
            if args.write:p.parent.mkdir(parents=True,exist_ok=True);p.write_text(body)
    receipt.update({'mode':'write' if args.write else 'check','drift':drift,'outputBindings':{name:hashlib.sha256(body.encode()).hexdigest() for name,body in outputs.items()},'behaviorOrProverExecuted':False})
    (TASK/('sync-write.json' if args.write else 'sync-check.json')).write_text(json.dumps(receipt,indent=2)+'\n')
    print(json.dumps({k:receipt[k] for k in ['mode','areas','contracts','dependencies','obligations','formalSources','drift']}))
    return 0 if args.write or not drift else 1
if __name__=='__main__':sys.exit(main())
