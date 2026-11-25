"""Bounded source correspondence in the existing Recipe execution lifecycle.

These adapters do not parse the C ABI, execute Make, or admit runtime results.
SysML owns the declarations; Recipe owns inputs, budgets and artifact ordering.
"""
import json
import re
from pathlib import Path
import sys

if __name__ == '__main__':
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from gambit_smp.framework import digest
from gambit_smp.source_capabilities import source_file, modular_header_includes


SERVICE_ENTRY = 'tests/recipes/framework-contracts/service-entry.json'
SERVICE_RULES = 'evidence/dsl/sysml-service.ss'


def sdk_inventory(binary, lock):
    """Connected-model SDK profile; downloads/signing/actions are not admitted.

    Isolated workers use -S and can import only these byte-bound distributions
    and the stdlib. A new undeclared import fails instead of using host packages.
    """
    import importlib.metadata
    import tomllib
    from opensysml.binary import release_asset_name, pinned_digest
    binary = Path(binary).resolve(strict=True)
    if sys.platform != 'darwin' or release_asset_name() != 'sysml-grpc-darwin-arm64':
        raise ValueError('this reviewed service-stop profile requires Darwin arm64')
    locked = {(p['name'], p['version']) for p in tomllib.loads(lock.read_text())['package']}
    versions, originals = {}, {}
    for name in ('opensysml', 'grpcio', 'protobuf', 'typing-extensions'):
        distribution = importlib.metadata.distribution(name)
        if (name, distribution.version) not in locked:
            raise ValueError('SDK distribution differs from the project lock: ' + name)
        versions[name] = distribution.version
        for item in distribution.files or ():
            if '..' in item.parts or '__pycache__' in item.parts or item.suffix == '.pyc':
                continue
            path = Path(distribution.locate_file(item))
            if path.is_symlink() or not path.is_file():
                raise ValueError('regular SDK runtime resource required')
            originals[path.resolve()] = 'python/' + item.as_posix()
    version = 'v' + versions['opensysml']
    expected = pinned_digest(version, release_asset_name())
    if not expected or digest(binary) != expected or not binary.stat().st_mode & 0o111:
        raise ValueError('official pinned OpenSysML service binary required')
    originals[binary] = 'tools/sysml-grpc'
    originals[lock] = 'policy/python-runtime.lock'
    provider = dict(profile='connected-model-projection', sdkVersion=versions['opensysml'],
                    serviceVersion=version, binary='tools/sysml-grpc', binarySha256=expected,
                    packages=versions, executableFiles=['tools/sysml-grpc'],
                    runtimeFiles={role: digest(path) for path, role in originals.items()})
    return originals, provider


def sealed_sdk(engine):
    from gambit_smp.research_kernel import execution_identity
    manifest = execution_identity(engine)
    provider = manifest.get('sysmlProvider')
    if not provider or provider.get('profile') != 'connected-model-projection':
        raise FileNotFoundError('sealed OpenSysML SDK/service provider unavailable')
    if any(manifest['files'].get(name) != sha for name, sha in provider['runtimeFiles'].items()):
        raise ValueError('OpenSysML provider identity differs from engine resources')
    if provider.get('executableFiles') != [provider['binary']] or not (engine/provider['binary']).stat().st_mode & 0o111:
        raise ValueError('sealed service executable role differs')
    return manifest, provider


def validate_project(args, inputs):
    from gambit_smp.recipes import fields
    fields(args, ('models',), ('part', 'parts', 'baseline', 'selection'))
    if sum(name in args for name in ('part','parts','selection'))!=1:
        raise ValueError('exactly one part, parts or declared selection required')
    models = args['models']
    if (not isinstance(models, list) or not models or len(models) != len(set(models))
            or any(name not in inputs or not name.endswith(('.sysml','.kerml')) for name in models)):
        raise ValueError('declared unique SysML model inputs required')
    if 'selection' in args:
        if args['selection'] not in inputs or not args['selection'].endswith('.json') or 'baseline' in args:
            raise ValueError('declared selection JSON carries its independent reference')
        if not {SERVICE_ENTRY,SERVICE_RULES}<=set(inputs):
            raise ValueError('declared SDK service admission rules required')
        return
    selection = [args['part']] if 'part' in args else args['parts']
    if (not isinstance(selection, list) or not 1 <= len(selection) <= 32
            or any(not isinstance(part, str) or not re.fullmatch(r'[A-Za-z_]\w*(?:::[A-Za-z_]\w*)*', part) for part in selection)
            or len(selection) != len(set(selection)) or 'baseline' in args and 'parts' in args):
        raise ValueError('qualified unique SysML parts required; frontend baseline requires one part')
    if not {SERVICE_ENTRY, SERVICE_RULES} <= set(inputs):
        raise ValueError('declared SDK service admission rules required')
    if 'baseline' in args and (args['baseline'] not in inputs or not args['baseline'].endswith('.json')):
        raise ValueError('declared immutable frontend oracle required')


def validate_service(address):
    if not isinstance(address, str) or not re.fullmatch(r'127\.0\.0\.1:[0-9]{1,5}', address):
        raise ValueError('local managed OpenSysML service address required')
    if not 0 < int(address.rpartition(':')[2]) < 65536:
        raise ValueError('valid OpenSysML service port required')


def api_values(connection, documents, part):
    """One official SDK call path for every source checkout and model part."""
    if any(not isinstance(document, (list, tuple)) or len(document) != 2
           or any(not isinstance(cell, str) for cell in document) for document in documents):
        raise ValueError('typed model name/content pairs required')
    documents = [tuple(document) for document in documents]
    model = connection.parse_sources(documents, strict=True, strict_conformance=True)
    model.raise_for_errors()
    def values_for(name):
        symbol = model.find(name)
        if symbol is None:
            raise ValueError('declared contract part not found')
        names = [child.name for child in symbol.children() if child.kind.lower() == 'attributeusage']
        instance = model.instantiate(name)
        values = {field: instance[field] for field in names}
        if not values or any(type(value) not in (str, bool, int) for value in values.values()):
            raise ValueError('complete scalar model parameters required; unset/error values cannot pass')
        return values
    values = {name: values_for(name) for name in part} if isinstance(part, list) else values_for(part)
    result = dict(schema='sysml-source-contract-projection', values=values,
                  modelHash=model.hash, runtimeAdmitted=False)
    if isinstance(part, str) and values.get('projectionKind') == 'flow-contract':
        from gambit_smp.sysml_flow import project_flow, _identity
        if model.diagnostics:
            raise ValueError('flow projection requires a diagnostic-free model')
        result['flow'] = project_flow(model, part, values)
        result['flowSha256'] = _identity(result['flow'])
        result['modelInputs'] = {name:digest_bytes(content.encode()) for name,content in documents}
    return result


def typed_equal(left,right):
    # Python equality conflates bool/int and int/float; transport equivalence
    # requires exact scalar kinds as well as keys, order and values.
    return json.dumps(left,sort_keys=True,separators=(',',':'),allow_nan=False)==json.dumps(
        right,sort_keys=True,separators=(',',':'),allow_nan=False)


def selection_contract(plan):
    from gambit_smp.recipes import fields
    fields(plan,('schema','queries','listGroups','modelInputs','expected'))
    if plan['schema']!='sysml-field-selection' or not isinstance(plan['queries'],list) or not plan['queries']:
        raise ValueError('complete field selection required')
    keys=set()
    for row in plan['queries']:
        fields(row,('path','expression','kind'))
        if (not isinstance(row['path'],list) or len(row['path'])!=3 or
            any(not isinstance(x,str) or not x or '/' in x for x in row['path']) or
            not isinstance(row['expression'],str) or not re.fullmatch(r'[A-Za-z_]\w*(?:::[A-Za-z_]\w*)+(?:\.[A-Za-z_]\w*)*',row['expression']) or
            row['kind'] not in ('string','integer','boolean')):
            raise ValueError('literal qualified field paths and exact scalar kinds required')
        key=tuple(row['path'])
        if key in keys:raise ValueError('duplicate selection output path')
        keys.add(key)
    if (not isinstance(plan['listGroups'],list) or len(plan['listGroups'])!=len(set(plan['listGroups'])) or
        not set(plan['listGroups'])<={key[0] for key in keys} or
        not isinstance(plan['modelInputs'],dict) or not plan['modelInputs']):
        raise ValueError('complete layout and exact model identities required')


def selected_values(plan,values):
    selection_contract(plan)
    if len(values)!=len(plan['queries']):raise ValueError('complete ordered field values required')
    result={};kinds={'string':str,'integer':int,'boolean':bool}
    for row,value in zip(plan['queries'],values,strict=True):
        if type(value) is not kinds[row['kind']]:raise ValueError('selected field type differs: '+row['expression'])
        group,index,field=row['path'];result.setdefault(group,{}).setdefault(index,{})[field]=value
    for group in plan['listGroups']:
        indexes=list(result[group])
        if indexes!=[str(i) for i in range(len(indexes))]:raise ValueError('ordered contiguous list indexes required')
        result[group]=list(result[group].values())
    return result


def api_selection(connection,documents,plan):
    selection_contract(plan)
    if {name:digest_bytes(content.encode()) for name,content in documents}!=plan['modelInputs']:
        raise ValueError('selection model source closure differs')
    model=connection.parse_sources([tuple(row) for row in documents],strict=True,strict_conformance=True)
    model.raise_for_errors()
    if getattr(model,'diagnostics',()):
        raise ValueError('selected projection diagnostic delivery is not qualified')
    values=[model.eval(row['expression']) for row in plan['queries']]
    result=selected_values(plan,values)
    if not typed_equal(result,plan['expected']):raise ValueError('typed projection differs from independent CLI reference')
    return dict(schema='sysml-source-contract-projection',values=result,orderedValues=values,
        modelHash=model.hash,modelInputs=plan['modelInputs'],runtimeAdmitted=False,
        selectionSha256=digest_bytes(json.dumps(plan,sort_keys=True,separators=(',',':')).encode()),
        diagnostics=[],equivalence=dict(matched=True,kind='ordered-fields-and-layout'))


from gambit_smp.model_binding import api_binding
from gambit_smp.sysml_flow import api_flow, drive_flow, formal_plan


def api_structure(connection, documents):
    model = connection.parse_sources([tuple(row) for row in documents], strict=True, strict_conformance=True)
    model.raise_for_errors()
    if model.diagnostics:
        raise ValueError('structural export requires a diagnostic-free model')
    elements = json.loads(str(model.to_api_json()))
    if (not isinstance(elements, list) or not elements
            or any(not isinstance(row, dict) or '@id' not in row for row in elements)
            or len({row['@id'] for row in elements}) != len(elements)):
        raise ValueError('complete structural export with unique identities required')
    return dict(schema='sysml-structure-projection', elements=elements,
                values={'elementCount':len(elements)}, modelHash=model.hash, runtimeAdmitted=False,
                modelInputs={name:digest_bytes(content.encode()) for name,content in documents})


def project(args, ctx):
    """Only the sealed Python SDK path; the CLI/stdout projector is retired."""
    import uuid
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import content_id
    if 'attributes' in args or 'service' in args:
        raise ValueError('stdout projection and external-service execution are retired')
    if 'engine' not in ctx.receipt:
        raise FileNotFoundError('sealed OpenSysML SDK/service provider unavailable')
    engine = Path(ctx.receipt['engine']['path']).resolve(strict=True)
    manifest, provider = sealed_sdk(engine)
    paths = [source_file(ctx.root, name) for name in args['models']]
    for name, role in [(SERVICE_ENTRY, 'policy/sysml-service.entry.json'), (SERVICE_RULES, 'policy/sysml-service.ss')]:
        path = source_file(ctx.root, name)
        if digest(path) != manifest['files'].get(role):
            raise ValueError('SDK admission policy differs from seal')
        paths.append(path)
    ctx.bind([engine/'engine.json', *paths])
    for name in ('sdk-request.json', 'sdk-result.json', 'sdk-lifecycle.json', 'sdk-client.json'):
        if (ctx.directory/name).exists():
            raise ValueError('fresh SDK request directory required')
    remaining = ctx.remaining()
    if remaining <= 8:
        raise TimeoutError('SDK stage has no remaining service/client/cleanup budget')
    request = ctx.directory/'sdk-request.json'
    nonce = uuid.uuid4().hex
    data = dict(engine=str(engine), engineId=manifest['engineId'],
        part=args.get('part', args.get('parts')), nonce=nonce, deadline=ctx.deadline-2,
        documents=[(str(source_file(ctx.root, name)), source_file(ctx.root, name).read_text()) for name in args['models']])
    if 'selection' in args:
        plan=source_file(ctx.root,args['selection']);ctx.bind([plan])
        data['selection']=read_json(plan);selection_contract(data['selection'])
        data['documents']=[(name,source_file(ctx.root,name).read_text()) for name in args['models']]
    if args.get('format') == 'api-json':
        data['format'] = 'api-json'
        data['documents'] = [(name, source_file(ctx.root,name).read_text()) for name in args['models']]
    if 'baseline' in args:
        oracle = source_file(ctx.root, args['baseline'])
        ctx.bind([oracle])
        data.update(reference=read_json(oracle), referenceSha256=digest(oracle))
    request.write_text(json.dumps(data)+'\n')
    ctx.bind([request])
    try:
        ctx.require('sysml-sdk', [sys.executable, '-I', '-S', '-B',
            engine/'python/gambit_smp/contract_capabilities.py', '--sdk-owner', request],
            ctx.root, remaining-2)
    except Exception:
        lifecycle = ctx.directory/'sdk-lifecycle.json'
        if lifecycle.is_file() and read_json(lifecycle).get('clientTimeout') is True:
            raise TimeoutError('SDK client exhausted its original stage budget')
        raise
    lifecycle = ctx.directory/'sdk-lifecycle.json'
    state = read_json(lifecycle)
    result = read_json(ctx.directory/'sdk-result.json')
    schema = 'sysml-structure-projection' if args.get('format') == 'api-json' else 'sysml-source-contract-projection'
    if (result.get('schema') != schema or result.get('runtimeAdmitted') is not False
            or result.get('nonce') != nonce or state.get('nonce') != nonce
            or result.get('providerId') != content_id(provider)
            or result.get('serverVersion') != provider['serviceVersion']):
        raise ValueError('typed request-bound SDK response required')
    if 'baseline' in args and result.get('equivalence') != {'matched': True, 'referenceSha256':data['referenceSha256']}:
        raise ValueError('frontend equivalence receipt missing or changed')
    if args.get('format')=='api-json' and result.get('modelInputs') != {name:digest_bytes(content.encode()) for name,content in data['documents']}:
        raise ValueError('structural model input identity differs')
    if 'selection' in data:
        plan=data['selection']
        expected=digest_bytes(json.dumps(plan,sort_keys=True,separators=(',',':')).encode())
        if (result.get('selectionSha256')!=expected or result.get('modelInputs')!=plan['modelInputs']
                or not typed_equal(result.get('values'),plan['expected'])
                or not typed_equal(selected_values(plan,result.get('orderedValues',[])),result['values'])
                or result.get('equivalence')!={'matched':True,'kind':'ordered-fields-and-layout'}):
            raise ValueError('complete request-bound field selection result required')
    from gambit_smp.evidence_capabilities import evaluate_observations
    row = [ctx.directory.name, content_id(provider), state['providerId'], nonce, state['nonce'],
           state['phase'], state['clientExit'], state['serviceReaped'], state['clientReaped'],
           state['controlledStop'], state['forcedStop'], state['binaryStable'], children_bound(state), state['serviceExit']]
    ctx.bind([lifecycle, ctx.directory/'sdk-result.json'])
    answers = evaluate_observations(ctx, [], {'sdk_observation': [row]},
        {'qualified':'sdk_qualified', 'denied':'sdk_denied'}, 'sdk-admission', dsl=SERVICE_ENTRY)
    if answers != {'qualified': [[ctx.directory.name]], 'denied': []}:
        raise ValueError('SDK service lifecycle/identity was not qualified')
    sealed_sdk(engine)
    ctx.remaining()
    kind = 'sysml-structural-model' if args.get('format') == 'api-json' else 'sysml-source-contract'
    return dict(outputs=ctx.publish('projection', kind, ctx.directory/'sdk-result.json'),
                attributeCount=(len(data['selection']['queries']) if 'selection' in data else
                                sum(len(fields) for fields in result['values'].values())
                                if 'parts' in args else len(result['values'])),
                partCount=(len({row['expression'].split('.')[0] for row in data['selection']['queries']})
                           if 'selection' in data else len(args['parts']) if 'parts' in args else 1), runtimeAdmitted=False,
                backend='sealed-opensysml-python-api', serviceQualification=answers,
                serviceLifecycle=state, equivalence=result.get('equivalence'))


def validate_check(args, inputs):
    from gambit_smp.recipes import fields
    from gambit_smp.native_capabilities import reference
    fields(args, ("projection",), ("readSources",))
    reference(args["projection"])
    if 'readSources' in args:
        names=args['readSources']
        if (not isinstance(names,list) or not names or len(names)!=len(set(names))
                or any(not isinstance(name,str) or name not in inputs
                       or not name.startswith('src/gambit_smp/') or not name.endswith('.py') for name in names)):
            raise ValueError('explicit declared framework Python sources for read-only AST inspection required')


def check_graph(step, by_id, registry):
    ref = step["arguments"]["projection"]
    if (ref["step"] not in step["dependsOn"] or ref["output"] != "projection"
            or by_id[ref["step"]]["capability"] != "sysml.project"):
        raise ValueError("source contract requires its dependent typed SysML projection")


def header_observation(values, texts):
    dispatcher = values["dispatcher"]
    modules = json.loads(values["modules"])
    if not isinstance(modules, list) or not modules or len(modules) != len(set(modules)):
        raise ValueError("complete unique module order required")
    if list(modular_header_includes(texts[dispatcher], dispatcher)) != modules:
        raise ValueError("modular dispatcher include closure changed")
    if set(texts) != {dispatcher, *modules} or values["owner"] not in modules:
        raise ValueError("exact dispatcher/module source inventory required")
    start, end = values["begin"], values["endDelimiter"]
    owners = [name for name, text in texts.items() if start in text]
    if owners != [values["owner"]]:
        raise ValueError("unique declaration owner required")
    text = texts[values["owner"]]
    if text.count(start) != 1 or text.count(end) != 1:
        raise ValueError("unique declaration boundaries required")
    begin = text.index(start)
    finish = text.index(end) + len(end)
    if finish <= begin:
        raise ValueError("ordered declaration boundaries required")
    body = text[begin:finish]
    tokens = json.loads(values["tokens"])
    if not isinstance(tokens, list) or not tokens or any(
            not isinstance(t, str) or not re.fullmatch(r"[A-Za-z_]\w*", t)
            or not re.search(r"\b" + re.escape(t) + r"\b", body) for t in tokens):
        raise ValueError("declared member tokens missing")
    return {"owner": values["owner"], "firstLine": text[:begin].count("\n") + 1,
            "lastLine": text[:finish].count("\n") + 1, "moduleCount": len(modules),
            "claim": "textual-declaration-correspondence-not-C-ABI"}


def make_observation(values, texts):
    from gambit_smp.upstream_tests import target_headers
    prior = json.loads(texts[values["priorContract"]])
    baseline, current = texts[values["priorTemplate"]], texts[values["template"]]
    if (prior.get("schema") != "upstream-make-test-contract.v1"
            or prior["template"]["sha256"] != digest_bytes(baseline.encode())):
        raise ValueError("pinned prior Make contract correspondence required")
    changes = json.loads(values["changedHeaders"])
    additions = json.loads(values["addedHeaders"])
    defects = json.loads(values["priorHeaderDefects"])
    def names(text):
        return {name for line in text.splitlines() if ':' in line and not line.startswith((' ', '\t', '#'))
                for name in line.partition(':')[0].split() if re.fullmatch(r'[a-z][a-z0-9-]*', name)}
    old_names, new_names = names(baseline), names(current)
    if (not isinstance(changes, dict) or not isinstance(additions, dict)
            or set(changes) - old_names or set(additions) & old_names):
        raise ValueError("disjoint explicit Make contract delta required")
    actual_changes = {name: target_headers(current.splitlines(), name) for name in old_names
                      if target_headers(current.splitlines(), name) != target_headers(baseline.splitlines(), name)}
    actual_defects = {}
    for name, row in prior["targets"].items():
        old_headers = target_headers(baseline.splitlines(), name)
        if old_headers != row["headers"]:
            actual_defects[name] = old_headers
    if actual_defects != defects:
        raise ValueError("prior Make contract defect inventory differs")
    if actual_changes != changes or any(not headers for headers in actual_changes.values()):
        raise ValueError("Make target delta differs; removed targets cannot pass")
    for name, headers in additions.items():
        if (target_headers(baseline.splitlines(), name) or not headers
                or target_headers(current.splitlines(), name) != headers):
            raise ValueError("added Make target source correspondence changed")
    if old_names - new_names or new_names - old_names != set(additions):
        raise ValueError("complete added/removed literal Make target inventory required")
    # This is a reviewed migration delta, not a replacement execution contract.
    # Unchanged suite selection/modes remain owned by the prior sealed policy.
    result = {"changedTargets": sorted(changes), "addedTargets": sorted(additions),
            "literalTargetCount": len(new_names), "priorLiteralTargetCount": len(old_names),
            "priorTargetCount": len(prior["targets"]), "unitModes": prior["unitModes"],
            "priorHeaderDefects": defects, "priorContractUsable": not defects,
            "executionContractReplaced": False, "claim": "source-delta-not-Make-execution"}
    if 'executionContract' in values:
        from gambit_smp.upstream_tests import validate_scope_definition
        contract = json.loads(texts[values['executionContract']])
        if contract['template']['sha256'] != digest_bytes(current.encode()):
            raise ValueError('new Make execution template identity differs')
        validate_scope_definition(contract, current)
        for name, sha in contract['execution']['sourceInputs'].items():
            logical = values['sourcePrefix'] + '/' + name
            if logical not in texts or digest_bytes(texts[logical].encode()) != sha:
                raise ValueError('new Make execution source input missing or changed: ' + name)
        result.update(executionContractSourceValidated=True, executionTargetCount=len(contract['targets']),
                      configuredFileChecked=False)
    return result


def digest_bytes(raw):
    import hashlib
    return hashlib.sha256(raw).hexdigest()


def check(args, ctx):
    from gambit_smp.recipes import read_json
    path = ctx.artifact(args["projection"], "sysml-source-contract")
    projection = read_json(path)
    if projection.get("schema") != "sysml-source-contract-projection":
        raise ValueError("typed source contract projection required")
    values = projection["values"]
    identities = json.loads(values["identities"])
    if not isinstance(identities, dict) or not identities:
        raise ValueError("explicit complete source identity inventory required")
    if not set(identities) <= set(ctx.receipt["declaredInputs"]):
        raise ValueError("all projected sources must be declared Recipe inputs")
    bindings = getattr(ctx, 'source_bindings', {})
    def bound_source(name):
        prefix = values.get('sourcePrefix')
        if prefix in bindings and name.startswith(prefix + '/'):
            return source_file(bindings[prefix], name[len(prefix) + 1:])
        return source_file(ctx.root, name)
    paths = {name: bound_source(name) for name in identities}
    ctx.bind([path, *paths.values()])
    raw = {name: p.read_bytes() for name, p in paths.items()}
    if any(digest_bytes(raw[name]) != sha for name, sha in identities.items()):
        raise ValueError("source contract byte identity drift")
    texts = ({name: data.decode("utf-8") for name, data in raw.items()}
             if values["kind"] != "linked-image-cuts" else {})
    ctx.remaining()
    if values["kind"] == "modular-header":
        observed = header_observation(values, texts)
    elif values["kind"] == "python-ast":
        from gambit_smp.source_ast import audit
        if set(args.get('readSources',[])) != {name for name in identities if name.endswith('.py')}:
            raise ValueError('AST read-only source role differs from typed inventory')
        observed = audit(values, raw, ctx)
    elif values["kind"] == "linked-image-cuts":
        from gambit_smp.image_contract import audit
        observed = audit(values, raw, ctx)
    elif values["kind"] == "make-delta":
        expected = {values["priorContract"], values["priorTemplate"], values["template"]}
        if 'executionContract' in values:
            contract = json.loads(texts[values['executionContract']])
            expected |= {values['executionContract'], *(values['sourcePrefix'] + '/' + name
                           for name in contract['execution']['sourceInputs'])}
        if set(texts) != expected:
            raise ValueError("exact Make source inventory required")
        observed = make_observation(values, texts)
    else:
        raise ValueError("unsupported source contract kind")
    ctx.bind([path, *paths.values()])
    ctx.remaining()
    output = ctx.directory / "source-contract.json"
    result = {"kind": values["kind"], "status": "matched", "observed": observed,
              "sourceInputs": identities, "runtimeAdmitted": False}
    output.write_text(json.dumps(result, indent=2) + "\n")
    return {**result, "outputs": ctx.publish("observation", "source-contract-observation", output)}


def children_bound(state):
    births = state.get('births', {})
    service, client = state.get('serviceToken'), state.get('clientToken')
    return bool(service and client and service != client and set(births) == {service, client}
                and births[service].get('process', {}).get('pid') == state.get('servicePid')
                and births[client].get('process', {}).get('pid', 0) > 0)


def frontend_equivalence(connection, data, current):
    """Replay the curated exact old input; compare complete owned field sets."""
    reference = data['reference']
    if (reference['schema'] != 'sysml-frontend-equivalence'
            or digest_bytes(reference['source'].encode()) != reference['modelSha256']):
        raise ValueError('frontend oracle input identity differs')
    expected = reference['parts'][data['part']]
    replay = api_values(connection, [(reference['model'], reference['source'])], data['part'])
    if not typed_equal(replay['values'],expected) or not typed_equal(current['values'],expected):
        raise ValueError('complete frontend field set differs from the independent oracle')
    return dict(matched=True, referenceSha256=data['referenceSha256'])


def structural_equivalence(data, current):
    reference=data['reference']
    if reference.get('schema')!='sysml-structural-reference':
        raise ValueError('independent structural oracle required')
    canonical=json.dumps(sorted(current['elements'],key=lambda row:row['@id']),
        sort_keys=True,separators=(',',':'),ensure_ascii=True).encode()
    if (current['modelInputs']!=reference['modelInputs'] or len(current['elements'])!=reference['elementCount']
            or digest_bytes(canonical)!=reference['elementGraphSha256']):
        raise ValueError('structural API graph differs from independent native oracle')
    return dict(matched=True,referenceSha256=data['referenceSha256'])


def managed_projection(data, provider, directory):
    """Capability owner: birth -> listen -> bounded RPC child -> stop -> reap.

    Every child uses the existing durable task registry. An incomplete reap
    leaves UNKNOWN custody there; neither a result file nor an exit-zero alone
    authorizes publication. Cleanup consumes the original deadline.
    """
    import os
    import selectors
    import subprocess
    import time
    import uuid
    from gambit_smp import task_processes
    from gambit_smp.workspace import write
    from gambit_smp.research_kernel import content_id
    deadline = data['deadline']
    binary = Path(data['engine'])/provider['binary']
    state = dict(phase='planned', nonce=data['nonce'], providerId=content_id(provider),
        clientExit=-1, serviceExit=None, serviceReaped=False, clientReaped=False,
        controlledStop=False, forcedStop=False, binaryStable=False, clientTimeout=False,
        custody='task-process-registry', births={})
    record = directory/'sdk-lifecycle.json'
    def retain():
        write(record, state)
    def observe(event, token, fields):
        if event == 'started':
            state['births'][token] = fields['birth']
    retain()
    service = None
    env = {'PATH': os.defpath, 'PYTHONDONTWRITEBYTECODE': '1', 'OPENSYSML_RECORD_CACHE': '0',
           'GAMBIT_SMP_ROOT': os.environ.get('GAMBIT_SMP_ROOT', os.environ.get('GAMBIT_SMP_TASK_ROOT', ''))}
    with (directory/'sdk-service.stderr').open('wb') as log:
        try:
            if digest(binary) != provider['binarySha256']:
                raise ValueError('service binary changed before launch')
            if deadline-time.monotonic() <= 5:
                raise TimeoutError('no original budget remains for service cleanup')
            state['serviceToken'], state['clientToken'] = uuid.uuid4().hex, uuid.uuid4().hex
            service = task_processes.spawn([str(binary), '-port', '0', '-health-port', '0',
                '-report-address', '-exit-with-parent'], stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                stderr=log, env=env, observer=observe, spawn_token=state['serviceToken'],
                launch_deadline=deadline-5)
            state.update(phase='starting', servicePid=service.pid)
            retain()
            with selectors.DefaultSelector() as poll:
                poll.register(service.stdout, selectors.EVENT_READ)
                if not poll.select(max(0, min(10, deadline-time.monotonic()-5))):
                    raise TimeoutError('service did not report an address within its original budget')
            address = service.stdout.readline().decode('utf-8', 'strict').strip()
            validate_service(address)
            state.update(phase='listening', address=address)
            retain()
            client = directory/'sdk-client.json'
            client.write_text(json.dumps(dict(data, service=address))+'\n')
            client_budget = deadline-time.monotonic()-5
            if client_budget <= 0:
                raise TimeoutError('no original budget remains for the SDK client')
            try:
                completed = task_processes.run([sys.executable, '-I', '-S', '-B', str(Path(__file__)),
                    '--sdk-client', str(client)], capture_output=True, timeout=client_budget, env=env,
                    observer=observe, spawn_token=state['clientToken'])
            except subprocess.TimeoutExpired:
                # Only the bounded run transport guarantees client cleanup;
                # a service-start timeout is not a client reap observation.
                state.update(clientTimeout=True, clientReaped=True)
                raise
            (directory/'sdk-client.stdout').write_bytes(completed.stdout)
            (directory/'sdk-client.stderr').write_bytes(completed.stderr)
            state.update(phase='client-complete', clientExit=completed.returncode, clientReaped=True)
            if completed.returncode:
                raise ValueError('SDK client failed; see sdk-client.stderr')
            if not (directory/'sdk-result.json').is_file():
                raise ValueError('SDK client did not deliver a result')
        except subprocess.TimeoutExpired as error:
            state.update(error=str(error))
        except BaseException as error:
            state.update(errorType=type(error).__name__, error=str(error))
        finally:
            state['phase'] = 'stopping'
            retain()
            if service is not None:
                try:
                    state['controlledStop'] = service.poll() is None
                    service.stdin.close()
                    if service.poll() is None:
                        service.terminate()
                    service.wait(timeout=max(.001, min(4, deadline-time.monotonic())))
                    state.update(serviceExit=service.returncode, serviceReaped=True)
                except BaseException as error:
                    state.update(forcedStop=True, stopError=str(error))
                    try:
                        service.kill()
                        service.wait(timeout=max(.001, min(1, deadline-time.monotonic())))
                        state.update(serviceExit=service.returncode, serviceReaped=True)
                    except BaseException as pending:
                        state['retainedReason'] = str(pending)
                finally:
                    service.stdout.close()
            state['binaryStable'] = digest(binary) == provider['binarySha256']
            state['phase'] = 'closed' if state['serviceReaped'] and state['clientReaped'] else 'retained'
            retain()
    import signal
    return 0 if (not state.get('error') and state['serviceReaped'] and state['clientReaped']
                 and state['serviceExit'] in (0, -signal.SIGTERM)
                 and state['controlledStop'] and not state['forcedStop'] and state['binaryStable']) else 2


def inspect_source(data, out):
    """The operator facade dispatches here inside the same immutable module."""
    import os
    import time
    from gambit_smp.recipes import ExecutionContext, read_json
    root = Path(data['root'])
    receipt = data['receipt']
    arguments = data['arguments']
    projection = out/'projection'
    projection.mkdir()
    context = ExecutionContext(root, out, projection, os.environ,
        min(data['deadline'], time.monotonic()+40), {}, receipt, {})
    try:
        result = project(arguments, context)
        receipt['steps'].append(dict(id='projection', outcome='PASS', **result))
        declaration = read_json(projection/'sdk-result.json')['values']
        prefix = declaration.get('sourcePrefix')
        if not isinstance(prefix, str) or not prefix:
            raise ValueError('SysML contract must declare its logical sourcePrefix')
        receipt['declaredInputs'] += list(json.loads(declaration['identities']))
        directory = out/'check'
        directory.mkdir()
        checker = ExecutionContext(root, out, directory, os.environ,
            min(data['deadline'], time.monotonic()+10), {}, receipt, {})
        checker.source_bindings = {prefix: Path(receipt['sourceRoot'])}
        result = check(dict(projection=dict(step='projection', output='projection')), checker)
        receipt.update(outcome='MATCHED', observation=result,
            claim='source-inspection-not-sealed-evidence-admission')
    except Exception as error:
        receipt.update(outcome='DENY', reason=str(error), errorType=type(error).__name__)
    receipt['commands'] = context.commands
    (out/'inspection.json').write_text(json.dumps(receipt, indent=2)+'\n')
    return 0 if receipt['outcome'] == 'MATCHED' else 2


def capabilities(Capability):
    def validate_structure(args, inputs):
        from gambit_smp.recipes import fields
        fields(args, ('models',), ('baseline',))
        if (not isinstance(args['models'],list) or not args['models'] or len(args['models'])!=len(set(args['models']))
                or any(name not in inputs or not name.endswith(('.sysml','.kerml')) for name in args['models'])
                or not {SERVICE_ENTRY,SERVICE_RULES} <= set(inputs)):
            raise ValueError('declared unique structural models and service policy required')
        if 'baseline' in args and args['baseline'] not in inputs:
            raise ValueError('declared independent structural oracle required')
    def structure(args, ctx):
        return project(dict(args,format='api-json'),ctx)
    def validate_views(args, inputs):
        from gambit_smp.recipes import fields
        from gambit_smp.native_capabilities import reference
        fields(args, ('projection','prepared'), ('preview',))
        reference(args['projection']);reference(args['prepared'])
        if 'preview' in args and type(args['preview']) is not bool:
            raise ValueError('explicit view preview boolean required')
    def view_graph(step, by_id, registry):
        ref=step['arguments']['projection']
        if ref['step'] not in step['dependsOn'] or by_id[ref['step']]['capability']!='sysml.structure' or ref['output']!='projection':
            raise ValueError('structural model dependency required')
        prepared=step['arguments']['prepared']
        if prepared['step'] not in step['dependsOn'] or by_id[prepared['step']]['capability']!='architecture.preflight' or prepared['output']!='observation':
            raise ValueError('view preflight dependency required')
    def validate_preflight(args,inputs):
        from gambit_smp.recipes import fields
        fields(args,())
    def preflight(args,ctx):
        from gambit_smp.architecture_views import prepare_views
        return prepare_views(args,ctx)
    def views(args,ctx):
        from gambit_smp.architecture_views import check_views
        return check_views(args,ctx)
    def validate_audit(args, inputs):
        from gambit_smp.recipes import fields
        from gambit_smp.native_capabilities import reference
        fields(args, ('projection',), ('preview','study','options','catalog','controls','typedIr','histories','observations','boundary'))
        reference(args['projection'])
        if 'boundary' in args and (set(args) != {'projection','boundary'} or args['boundary'] is not True):
            raise ValueError('work-item boundary has exclusive typed projection inputs')
        if 'observations' in args:
            if (set(args)!={'projection','observations'} or not isinstance(args['observations'],dict)
                    or not args['observations'] or any(not isinstance(key,str) or not re.fullmatch(r'[A-Za-z][A-Za-z0-9_-]*',key) for key in args['observations'])):
                raise ValueError('explicit typed observation cohort required')
            for value in args['observations'].values():reference(value)
        if 'typedIr' in args:reference(args['typedIr'])
        if 'histories' in args:reference(args['histories'])
        if 'controls' in args:
            reference(args['controls'])
            if set(args)!={'projection','controls'}:raise ValueError('inference replay has exclusive typed inputs')
        if 'study' in args:
            from gambit_smp.scientific_catalog import ENTRIES
            if not isinstance(args['study'],str) or args['study'] not in ENTRIES:
                raise ValueError('declared scientific study identifier required')
            if 'catalog' not in args:raise ValueError('native scientific catalog dependency required')
            reference(args['catalog'])
            if 'preview' in args:raise ValueError('study execution cannot publish policy previews')
            options=args.get('options',{})
            fields(options,(),('resume','reuse_formal','reuse_imports','reuse_compiled','reuse_positive','local_models'))
            if any(type(value) is not bool for value in options.values()):
                raise ValueError('scientific options must be explicit booleans')
        elif 'options' in args or 'catalog' in args:raise ValueError('scientific inputs require a declared study')
        if 'preview' in args and type(args['preview']) is not bool:
            raise ValueError('explicit preview boolean required')
    def audit(args, ctx):
        if args.get('boundary') is True:
            from gambit_smp.work_items import evaluate_boundary
            return evaluate_boundary(args, ctx)
        if 'typedIr' in args and 'study' not in args:
            from gambit_smp.research_flow import current_binding_witness
            return current_binding_witness(args,ctx)
        if 'controls' in args:
            from gambit_smp.research_flow import replay_clue_controls
            return replay_clue_controls(args,ctx)
        if 'study' in args:
            from gambit_smp.research_flow import execute_scientific
            return execute_scientific(args,ctx)
        from gambit_smp.recipes import read_json
        values=read_json(ctx.artifact(args['projection'],'sysml-source-contract'))['values']
        if 'ScientificStudies::observationProducers' in values:
            from gambit_smp.research_flow import observation_producers
            return observation_producers(args,ctx)
        if 'ScientificStudies::recovery' in values:
            from gambit_smp.research_flow import evidence_recovery
            return evidence_recovery(args,ctx)
        from gambit_smp.research_flow import audit_contract
        return audit_contract(args, ctx)
    def audit_graph(step,by_id,registry):
        check_graph(step,by_id,registry)
        for ref in step['arguments'].get('observations',{}).values():
            parent=by_id.get(ref['step'])
            if (ref['step'] not in step['dependsOn'] or parent is None
                    or parent['capability'] not in {'quint.observe','lean.check','source.contract'} or ref['output']!='observation'):
                raise ValueError('observation cohort requires declared typed producers')
        if 'typedIr' in step['arguments']:
            ref=step['arguments']['typedIr'];parent=by_id.get(ref['step'])
            if ref['step'] not in step['dependsOn'] or parent is None or parent['capability']!='quint.observe' or parent['arguments'].get('typed') is not True or ref['output']!='typed':
                raise ValueError('current typed IR requires its declared fresh producer')
        if 'histories' in step['arguments']:
            ref=step['arguments']['histories'];parent=by_id.get(ref['step'])
            if ref['step'] not in step['dependsOn'] or parent is None or parent['capability']!='quint.observe' or parent['arguments']['argv'][0]!='test' or ref['output']!='observation':
                raise ValueError('current histories require their declared test producer')
        if 'controls' in step['arguments']:
            ref=step['arguments']['controls']
            parent=by_id.get(ref['step'])
            if ref['step'] not in step['dependsOn'] or parent is None or parent['capability']!='research.audit' or ref['output']!='observation' or 'controls' in parent['arguments']:
                raise ValueError('inference replay requires its declared source-audit producer')
        if 'study' not in step['arguments']:return
        ref=step['arguments']['catalog'];parent=by_id.get(ref['step'])
        if (ref['step'] not in step['dependsOn'] or ref['output']!='projection' or parent is None
                or parent['capability']!='sysml.project'
                or 'ScientificStudies::catalog' not in parent['arguments'].get('parts',[parent['arguments'].get('part')])):
            raise ValueError('scientific study requires the dependent native catalog projection')
    return {"architecture.preflight": Capability(validate_preflight,executor=preflight,
                                         outputs=(("observation","architecture-view-inputs"),)),
            "sysml.structure": Capability(validate_structure, executor=structure,
                                         outputs=(("projection","sysml-structural-model"),)),
            "architecture.views": Capability(validate_views, executor=views, graph=view_graph,
                                         outputs=(("observation","architecture-view-observation"),)),
            "sysml.project": Capability(validate_project, executor=project,
                                        outputs=(("projection", "sysml-source-contract"),)),
            "research.audit": Capability(validate_audit, executor=audit, graph=audit_graph,
                                        outputs=(("observation", "research-audit-observation"),)),
            "source.contract": Capability(validate_check, executor=check, graph=check_graph,
                                          outputs=(("observation", "source-contract-observation"),))}


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] not in {'--sdk-owner', '--sdk-client', '--source-inspect'}:
        raise SystemExit('Internal capability worker; use gambit-smp')
    from gambit_smp.recipes import read_json
    from gambit_smp.research_kernel import content_id
    request = Path(sys.argv[2]).resolve(strict=True)
    data = read_json(request)
    from gambit_smp.task_processes import recorder
    if recorder() is None:
        raise SystemExit('SDK workers require current inherited task custody')
    engine = Path(__file__).resolve().parents[2]
    manifest, provider = sealed_sdk(engine)
    if data['engine'] != str(engine) or data['engineId'] != manifest['engineId']:
        raise SystemExit('SDK request belongs to another seal')
    if sys.argv[1] == '--source-inspect':
        raise SystemExit(inspect_source(data, request.parent))
    if sys.argv[1] == '--sdk-owner':
        raise SystemExit(managed_projection(data, provider, request.parent))
    import opensysml
    validate_service(data['service'])
    with opensysml.connect(data['service'], auto_start=False, version=provider['serviceVersion'],
                          require_capabilities=['parse_sources', 'strict_conformance']+(['convert'] if data.get('format')=='api-json' else [])) as connection:
        result = (api_structure(connection,data['documents']) if data.get('format')=='api-json' else
                  api_selection(connection,data['documents'],data['selection']) if 'selection' in data else
                  api_values(connection, data['documents'], data['part']))
        if 'reference' in data:
            result['equivalence'] = (structural_equivalence(data,result) if data.get('format')=='api-json'
                                     else frontend_equivalence(connection, data, result))
        result['serverVersion'] = connection.server_info().version
    result.update(nonce=data['nonce'], providerId=content_id(provider), serviceCustody='managed')
    (request.parent/'sdk-result.json').write_text(json.dumps(result, indent=2)+'\n')
