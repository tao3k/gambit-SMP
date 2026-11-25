"""Fresh-run custody and fail-closed research artifact delivery.

This boundary does not certify arbitrary subprocess side effects or proof truth.
It validates declared native outputs and prevents Python writes to source/cache
history. A completed execution record is never a model or runtime admission.
"""
from contextlib import contextmanager
from contextvars import ContextVar
import hashlib
import ast
import os
import shutil
import sys
from pathlib import Path
if __name__ == "__main__":
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from gambit_smp.task_processes import run as run_process
import json
import re
import uuid

from gambit_smp.research_publication import POLICY, classify
from gambit_smp.storage_policy import StoragePolicyError, study_writes

_execution = ContextVar('research_flow_execution', default=None)
_approved_command = ContextVar('scientific_approved_command', default=None)
_scientific_cache = ContextVar('scientific_source_check_cache', default=None)


def study_workspace(name):
    """Read the existing owner context; never mutate a caller/helper namespace."""
    if name not in {'CACHE','OUT','EVIDENCE'}:
        raise ValueError('declared workspace role required')
    state=_execution.get()
    if state is None or state.get('active') is not True:
        raise StoragePolicyError('workspace reads require a current study owner')
    return state['work' if name=='CACHE' else 'results']


def projected_fields(root, run, component, keys, *, ordered=False, models=None):
    """Consume an existing typed capability artifact; never launch a projector.

    The caller passes its input explicitly. There is no cache search, stdout
    decoding, auto-sealing, provider fallback or new execution lifecycle.
    """
    from gambit_smp.recipes import read_json,source_path
    from gambit_smp.contract_capabilities import typed_equal,selection_contract,selected_values
    root=Path(root).resolve();state=_execution.get()
    if run is not None or state is None or state.get('active') is not True or state['root']!=root:
        raise EvidenceUnavailable('scientific projection requires its current Recipe owner')
    context=state['context'];reference=state['projection']
    if context.root.resolve()!=root:raise EvidenceUnavailable('scientific owner changed checkout')
    parent=next((step for step in context.receipt['steps'] if step['id']==reference['step']),None)
    if parent is None or parent.get('outcome')!='PASS' or parent['capability']!='sysml.project' or 'selection' not in parent['arguments']:
        raise EvidenceUnavailable('complete declared typed selection dependency required')
    descriptor=parent['outputs'][reference['output']]
    path=context.artifact(reference,'sysml-source-contract')
    if sha(path)!=descriptor['sha256']:raise EvidenceUnavailable('typed projection artifact changed')
    result=read_json(path);plan_path=source_path(root,parent['arguments']['selection'])
    plan=read_json(plan_path);selection_contract(plan);plan_before=sha(plan_path)
    models_paths=[source_path(root,name) for name in plan['modelInputs']]
    if any(sha(model)!=plan['modelInputs'][str(model.relative_to(root))] for model in models_paths):
        raise EvidenceUnavailable('typed projection source changed')
    context.bind([plan_path,*models_paths])
    rows=[row for row in plan['queries'] if row['path'][0].startswith(component+':')]
    expected=[] if ordered else [([group,index,field],expression) for group,index,field,expression in keys]
    actual=[([row['path'][0][len(component)+1:],*row['path'][1:]],row['expression']) for row in rows]
    if not ordered and (not rows or not typed_equal(actual,expected)):
        raise EvidenceUnavailable('caller field order or identity differs')
    plan_identity=hashlib.sha256(json.dumps(plan,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    if (result.get('schema')!='sysml-source-contract-projection' or result.get('runtimeAdmitted') is not False
            or result.get('selectionSha256')!=plan_identity or result.get('modelInputs')!=plan['modelInputs']
            or result.get('diagnostics')!=[] or result.get('equivalence')!={'matched':True,'kind':'ordered-fields-and-layout'}
            or not typed_equal(result.get('values'),plan['expected'])):
        raise EvidenceUnavailable('typed values differ from the reviewed field plan')
    try:ordered_layout=selected_values(plan,result.get('orderedValues',[]))
    except (TypeError,ValueError,KeyError) as error:raise EvidenceUnavailable('incomplete ordered typed values') from error
    if not typed_equal(ordered_layout,result['values']):raise EvidenceUnavailable('ordered field layout differs')
    values={name[len(component)+1:]:value for name,value in result['values'].items() if name.startswith(component+':')}
    if ordered:
        table={}
        for row,value in zip(plan['queries'],result['orderedValues'],strict=True):
            expression=row['expression']
            if expression in table and not typed_equal(table[expression],value):
                raise EvidenceUnavailable('conflicting values for one qualified field')
            table[expression]=value
        if not isinstance(keys,list) or not keys or any(not isinstance(key,str) or key not in table for key in keys):
            raise EvidenceUnavailable('complete declared literal field sequence required')
        requested=[]
        for model in models or []:
            model_path=Path(model);model_path=model_path if model_path.is_absolute() else root/model_path
            model_path=model_path.resolve()
            if not model_path.is_relative_to(root):raise EvidenceUnavailable('foreign model scope')
            name=str(model_path.relative_to(root))
            if model_path.is_dir():
                members=sorted(str(p.relative_to(root)) for p in model_path.rglob('*') if p.suffix in {'.sysml','.kerml'} and p.is_file())
                if not members:raise EvidenceUnavailable('empty model scope')
                requested.extend(members)
            else:requested.append(name)
        if any(name not in result['modelInputs'] for name in requested):
            raise EvidenceUnavailable('requested source scope missing from typed producer')
        values=dict(schema='sysml-ordered-field-delivery',orderedValues=[table[key] for key in keys],
                    expressions=list(keys),modelInputs=result['modelInputs'],requestedModels=requested,
                    diagnostics=result['diagnostics'],
                    producerStep=reference['step'],projectionSha256=descriptor['sha256'],
                    runtimeAdmitted=False)
    if sha(path)!=descriptor['sha256'] or plan_before!=sha(plan_path) or not state.get('active'):
        raise EvidenceUnavailable('projection or owner changed during delivery')
    producer=dict(step=reference['step'],projectionSha256=descriptor['sha256'],selectionSha256=plan_identity)
    if producer not in state['projectionInputs']:state['projectionInputs'].append(producer)

    return values if ordered else (values,dict(result['modelInputs']))


class EvidenceUnavailable(ValueError):
    pass


class SourceViewDrift(ValueError):
    pass


def _write(path, data):
    path = Path(path)
    state = _execution.get()
    if state is None or state.get('active') is not True:
        raise StoragePolicyError('research helper writes require an owned study_execution')
    if state:
        resolved = path.resolve()
        root, run = state['root'], state['run']
        if resolved.is_relative_to(root) and not resolved.is_relative_to(root/'.cache'):
            relative = str(resolved.relative_to(root))
            if classify(relative, len(data))['disposition'] != 'allow':
                raise StoragePolicyError('unclassified source output: '+relative)
            preview = run/'previews'/relative
            preview.parent.mkdir(parents=True, exist_ok=True)
            preview.write_bytes(data)
            if not resolved.is_file() or resolved.read_bytes() != data:
                raise SourceViewDrift('source view requires explicit review; preview: '+str(preview))
            state['unchangedViews'].append(relative)
            return len(data)
    return path.write_bytes(data)


def write_text(path, data, encoding=None, errors=None, newline=None):
    if not isinstance(data, str):
        raise TypeError('text required')
    text = data if newline is None else data.replace('\n', newline)
    _write(path, text.encode(encoding or 'utf-8', errors or 'strict'))
    return len(data)


def write_bytes(path, data):
    return _write(path, data)


def check_command(study, argv):
    """Reject unknown executables and declared native outputs outside the run.

    A known tool name is not OS-level containment. This necessary condition is
    reported separately from full native-writer closure.
    """
    if not isinstance(argv, (list, tuple)) or not argv:
        raise StoragePolicyError('research subprocess requires explicit argv')
    args = [str(v) for v in argv]
    while Path(args[0]).name == 'env':
        args = args[1:]
        while args and '=' in args[0] and not args[0].startswith('-'):
            args = args[1:]
        if not args:
            raise StoragePolicyError('missing executable after env')
    tool = Path(args[0]).name
    allowed = (POLICY['formalTools']+';'+POLICY['readOnlyTools']).split(';')
    if tool not in allowed:
        raise StoragePolicyError('unqualified research subprocess: '+tool)
    if tool == 'git':
        rest = args[1:]
        while rest and rest[0] in ('--no-optional-locks', '-C'):
            rest = rest[2:] if rest[0] == '-C' else rest[1:]
        if (not rest or rest[0] not in {'rev-parse', 'cat-file', 'show', 'status', 'diff', 'log',
                'ls-files', 'ls-tree', 'for-each-ref', 'merge-base', 'describe', 'check-ignore'}
                or any(arg in {'--textconv', '--ext-diff', '--filters'} for arg in rest)):
            raise StoragePolicyError('research Git command must be a declared read-only query')
    if tool == 'rg' and any(arg == '--pre' or arg.startswith('--pre=') for arg in args):
        raise StoragePolicyError('research search cannot delegate an unqualified preprocessor')
    targets = []
    for i, arg in enumerate(args[1:], 1):
        if arg in ('-o', '--out', '--output') and i+1 < len(args):
            targets.append(args[i+1])
        elif arg.startswith(('--out=', '--output=')):
            targets.append(arg.split('=', 1)[1])
    if tool == 'd2':
        if len(args) < 3:
            raise StoragePolicyError('D2 requires an explicit output in this run')
        targets.append(args[-1])
    for target in targets:
        path = Path(target)
        path = (path if path.is_absolute() else study['root']/path).resolve()
        if not path.is_relative_to(study['run']):
            raise StoragePolicyError('native output requires this run cache: '+str(path))


@contextmanager
def study_execution(context, *, projection, options=None, inputs=None):
    """Use the existing Recipe owner, deadline and receipt; allocate no runner."""
    if _execution.get() is not None:raise ValueError('nested scientific owners are not admitted')
    from types import SimpleNamespace
    allowed={'resume','reuse_formal','reuse_imports','reuse_compiled','reuse_positive','local_models'}
    options={} if options is None else dict(options)
    if set(options)-allowed or any(type(value) is not bool for value in options.values()):
        raise ValueError('declared scientific boolean options required')
    from types import MappingProxyType
    inputs={} if inputs is None else dict(inputs)
    if set(inputs)-{'typedIr'}:raise ValueError('undeclared scientific input role')
    for reference in inputs.values():context.artifact(reference,'quint-typed-ir')
    context.scientific_inputs=MappingProxyType(inputs)
    context.options=SimpleNamespace(**{name:options.get(name,False) for name in allowed})
    context.arguments=tuple('--'+name.replace('_','-') for name,value in options.items() if value)
    work=context.directory/'work';results=context.directory/'results'
    work.mkdir(exist_ok=False);results.mkdir(exist_ok=False)
    state=dict(root=context.root.resolve(),run=context.directory,work=work,results=results,active=True,
               context=context,projection=projection,projectionInputs=[],unchangedViews=[])
    record=dict(state='running',runtimeAdmitted=False,evidenceAccepted=False)
    context.receipt.setdefault('scientific',{})[context.directory.name]=record
    context.scientific_active=True
    token=_execution.set(state)
    try:
        services=POLICY['studyServiceWrites'].split(';')
        from gambit_smp.task_processes import recorder
        process_owner=recorder()
        if process_owner is not None:
            birth_root=process_owner.spawn_root.resolve()
            if (process_owner.root!=context.root.resolve() or birth_root.name!='process-starts'
                    or not birth_root.is_relative_to(context.root.resolve()/'.cache/tasks')
                    or not context.out.resolve().is_relative_to(birth_root.parent)):
                raise EvidenceUnavailable('scientific process journal belongs to another task owner')
            services.append(birth_root.relative_to(context.root.resolve()).as_posix()+'/')
        record['serviceDirectories']=list(services)
        from gambit_smp.evidence_capabilities import _evaluation_owner
        if _evaluation_owner is not None:
            owner=_evaluation_owner
            if (owner.closed or owner.engine!=Path(context.receipt['engine']['path']).resolve()
                    or not owner.directory.resolve().is_relative_to(context.out.resolve())):
                raise EvidenceUnavailable('scientific evaluator belongs to another Recipe owner')
            services.append(owner.directory.resolve().relative_to(context.root.resolve()).as_posix()+'/')
        journal=None
        if context.receipt.get('journal'):
            header=Path(context.receipt['journal']['path']).resolve()
            if header.parent!=context.out.parent.resolve():raise EvidenceUnavailable('foreign scientific process journal')
            journal=header.parent
        with study_writes(context.root,context.directory,services,journal=journal):
            try:yield state
            except (FileNotFoundError,EvidenceUnavailable) as error:
                record.update(state='unavailable',reason=str(error));raise EvidenceUnavailable(str(error)) from error
            except BaseException as error:
                record.update(state='failed',reason=type(error).__name__+': '+str(error));raise
            else:record['state']='completed'
            finally:
                record.update(projectionInputs=state['projectionInputs'],sourceViewsUnchanged=state['unchangedViews'])
    finally:
        context.scientific_active=False
        context.scientific_inputs=MappingProxyType({})
        state['active']=False;_execution.reset(token)


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def scientific_tree(source):
    """Normalize private instance binding for the finite migration inverse.

    This is a source correspondence, not a proof of arbitrary Python execution.
    The exact candidate bytes and independent predecessor AST are both fenced.
    """
    class Normalize(ast.NodeTransformer):
        def visit_Attribute(self, node):
            if isinstance(node.value, ast.Name) and node.value.id == '_science':
                return ast.copy_location(ast.Name('main' if node.attr=='analyze' else node.attr, node.ctx), node)
            return self.generic_visit(node)
        def visit_Call(self,node):
            target=ast.unparse(node.func)
            if target=='_science.context.command':
                node.func=ast.Name('run',ast.Load())
                node.keywords=[k for k in node.keywords if k.arg!='policy']
            elif target in {'_science.context.process','_science.context.output'}:
                node.func=ast.Attribute(ast.Name('subprocess',ast.Load()),
                    'run' if target.endswith('.process') else 'check_output',ast.Load())
                node.keywords=[k for k in node.keywords if k.arg!='name']
            return self.generic_visit(node)
        def visit_FunctionDef(self, node):
            if node.args.args and node.args.args[0].arg == '_science':
                node.args.args.pop(0)
                if node.name == 'analyze': node.name = 'main'
                if (node.args.args and node.args.args[-1].arg == 'projection_run'
                        and len(node.args.defaults) == 1
                        and isinstance(node.args.defaults[0], ast.Constant)
                        and node.args.defaults[0].value is None):
                    node.args.defaults = []
            return self.generic_visit(node)
    return Normalize().visit(ast.parse(source))


def ast_identity(tree):
    return hashlib.sha256(ast.dump(tree, include_attributes=False).encode()).hexdigest()


def scientific_pool(tree):
    """Memoize canonical subtree dumps inside one check, never across sources."""
    dumps={};pool={}
    def canonical(value):
        if isinstance(value,list):return '['+', '.join(canonical(v) for v in value)+']'
        if not isinstance(value,ast.AST):return repr(value)
        key=id(value)
        if key not in dumps:
            fields=[];kind=type(value)
            for name,item in ast.iter_fields(value):
                if item is None and getattr(kind,name,...) is None:continue
                if item==[] and getattr(getattr(kind,'_field_types',{}).get(name,object),'__origin__',...) is list:continue
                fields.append(name+'='+canonical(item))
            dumps[key]=kind.__name__+'('+', '.join(fields)+')'
            pool[hashlib.sha256(dumps[key].encode()).hexdigest()]=value
        return dumps[key]
    canonical(tree)
    return pool


def scientific_predecessor(root, record, phase='source'):
    """Reconstruct retired syntax as inert data from current library subtrees.

    No old source is loaded or executed. Removed transport nodes are a sparse
    inverse; retained algorithms refer to exact normalized candidate subtrees.
    """
    from gambit_smp.recipes import source_path
    path=source_path(root,record['library'])
    if sha(path)!=record['afterSha256']:
        raise ValueError('scientific library source drift: '+record['library'])
    cache=_scientific_cache.get()
    key=(str(path.resolve()),record['afterSha256'])
    pool=None if cache is None else cache.get(key)
    if pool is None:
        tree=scientific_tree(path.read_text())
        pool_by_hash=scientific_pool(tree)
        pool=[pool_by_hash[key] for key in sorted(pool_by_hash)]
        if cache is not None:cache[key]=pool
    def restore(value):
        if isinstance(value,list):return [restore(item) for item in value]
        if not isinstance(value,dict):return value
        if set(value)=={'ref'}:
            import copy
            if type(value['ref']) is not int or not 0<=value['ref']<len(pool):
                raise ValueError('missing scientific subtree')
            return copy.deepcopy(pool[value['ref']])
        if set(value)!={'node','fields'} or not hasattr(ast,value['node']):
            raise ValueError('invalid inert AST inverse')
        kind=getattr(ast,value['node'])
        if not isinstance(kind,type) or not issubclass(kind,ast.AST):
            raise ValueError('non-AST inverse node')
        return kind(**{key:restore(item) for key,item in value['fields'].items()})
    restored=restore(record['inverse'][phase])
    if ast_identity(restored)!=record['beforeAstSha256'][phase]:
        raise ValueError('independent scientific predecessor differs')
    return ast.fix_missing_locations(restored)


def check_scientific_migration(root, fixture):
    """Check the entire cohort, not a caller-selected subset."""
    from gambit_smp.scientific_catalog import ENTRIES, LIBRARIES
    if (fixture.get('schema')!='scientific-library-migration'
            or len(fixture.get('files',[]))!=221):
        raise ValueError('complete scientific library cohort required')
    ids=set();entries=set();commands=0;algorithms=0;retired_functions=0
    for record in fixture['files']:
        identifier=record['id']
        if identifier in ids:raise ValueError('duplicate scientific library')
        ids.add(identifier)
        if (Path(root)/record['predecessor']).exists():
            raise ValueError('retired scientific source survived')
        predecessor=scientific_predecessor(root,record)
        current=ast.parse((Path(root)/record['library']).read_text())
        compile(current,record['library'],'exec')
        if 'clueIntegration' in record:
            # Preserve the independently reconstructed migration baseline and
            # all scientific assertions across the separately reviewed transport change.
            reviewed=scientific_predecessor(root,record,'clue-before')
            preserved,removed=scientific_algorithm_correspondence(predecessor,reviewed)
            review=record['clueIntegration']
            before=[ast_identity(n) for n in ast.walk(scientific_tree(ast.unparse(reviewed))) if isinstance(n,ast.Assert)]
            after=[ast_identity(n) for n in ast.walk(scientific_tree(ast.unparse(current))) if isinstance(n,ast.Assert)]
            if (record['id'] not in {'formal_study','logical_cursor_study','reader_span_study','package_development_benchmark_study'}
                    or review.get('wholeStudyAdmitted') is not False
                    or after!=review['currentAssertions']
                    or [v for v in before if v not in review['retiredAssertions']]!=after):
                raise ValueError('scientific assertions changed across clue integration')
        else:
            preserved,removed=scientific_algorithm_correspondence(predecessor,current)
        algorithms+=preserved;retired_functions+=removed
        debt=execution_debt(current)['factors']
        if any(debt.get(key) for key in ('native-process','dynamic-loader','model-stdout','mutable-workspace')):
            raise ValueError('retired execution mechanism survived: '+identifier)
        if any(isinstance(n,ast.Attribute) and n.attr in {'CACHE','OUT','EVIDENCE'} for n in ast.walk(current)):
            raise ValueError('private legacy cache hint or helper workspace survived')
        if any(isinstance(n,ast.If) and '__name__' in ast.unparse(n.test) for n in ast.walk(current)):
            raise ValueError('standalone scientific runner survived')
        if record['entry']:
            entries.add(identifier)
            if not hasattr(LIBRARIES[identifier],'analyze'):
                raise ValueError('scientific entry method missing')
        commands+=record['nativeCalls']
    if ids!=set(LIBRARIES) or entries!=set(ENTRIES) or len(entries)!=133:
        raise ValueError('closed scientific catalog differs from reviewed cohort')
    return dict(entries=len(entries),libraries=len(ids),sourceInverseMatched=True,
                nativeCallSites=commands,scientificFunctions=algorithms,
                transportFunctionsRetired=retired_functions,
                standaloneRunners=0,dynamicHelpers=0,
                wholeStudyAdmitted=False,runtimeAdmitted=False,
                scope='finite-source-correspondence-and-transport-refusal')


def scientific_algorithm_correspondence(predecessor,current):
    """Retained function/control structure and numeric scientific parameters.

    This independent projection supplements the sparse inverse. Removed native
    and loader functions have a checked syntactic role, not just a missing name.
    String/heap/OS semantics still require the stated source-refinement premises.
    """
    from collections import deque
    roles={}
    def transport(node):
        if not isinstance(node,ast.FunctionDef):return False
        if id(node) in roles:return roles[id(node)]
        potential_factory=(not node.args.args and len(node.body)>1 and isinstance(node.body[-1],ast.Return)
                           and isinstance(node.body[-1].value,ast.Name))
        if node.name not in {'run','load','module','load_module','loadmod','loadbase'} and not potential_factory:
            roles[id(node)]=False;return False
        calls=[ast.unparse(c.func) for c in ast.walk(node) if isinstance(c,ast.Call)]
        native=node.name=='run' and any(c.startswith('subprocess.') for c in calls)
        forward=(node.name=='run' and len(node.body)==1 and isinstance(node.body[0],ast.Return)
                 and isinstance(node.body[0].value,ast.Call) and isinstance(node.body[0].value.func,ast.Attribute)
                 and node.body[0].value.func.attr=='run')
        loader=(node.name in {'load','module','load_module','loadmod','loadbase'} and node.args.args
                and any(c.endswith('spec_from_file_location') for c in calls))
        factory=(potential_factory
                 and any(isinstance(s,ast.Assign) and isinstance(s.value,ast.Call)
                         and ast.unparse(s.value.func).endswith('module_from_spec')
                         and any(isinstance(t,ast.Name) and t.id==node.body[-1].value.id for t in s.targets)
                         for s in node.body))
        roles[id(node)]=bool(native or forward or loader or factory)
        return roles[id(node)]
    controls=(ast.If,ast.For,ast.While,ast.Try,ast.Assert,ast.Return,ast.Raise,ast.Break,ast.Continue,ast.Match)
    def signature(node):
        pending=deque([node]);flow=[];numbers=[]
        while pending:
            current=pending.popleft()
            if transport(current):continue
            if isinstance(current,controls):flow.append(type(current).__name__)
            if isinstance(current,ast.Constant) and type(current.value) in (int,float,bool):
                numbers.append((type(current.value).__name__,current.value))
            pending.extend(ast.iter_child_nodes(current))
        return flow,numbers
    klass=next(n for n in current.body if isinstance(n,ast.ClassDef) and n.name=='ScientificLibrary')
    methods={n.name:n for n in klass.body if isinstance(n,ast.FunctionDef) and n.name!='__init__'}
    checked=0;expected=set()
    for function in (n for n in predecessor.body if isinstance(n,ast.FunctionDef)):
        if transport(function):continue
        name='analyze' if function.name=='main' else function.name;expected.add(name)
        if name not in methods or signature(function)!=signature(methods[name]):
            raise ValueError('scientific function/control/number drift: '+function.name)
        checked+=1
    # Nine former guards carried the scientific construction directly. Only
    # their CLI parsing is transport; their actual body is checked too.
    if 'analyze' in methods and 'analyze' not in expected:
        guards=[n for n in predecessor.body if isinstance(n,ast.If) and '__name__' in ast.unparse(n.test)]
        if len(guards)!=1:raise ValueError('unexpected scientific analyze method')
        owned=next(n for n in guards[0].body if isinstance(n,ast.With))
        body=[]
        for statement in owned.body:
            if isinstance(statement,ast.Expr) and isinstance(statement.value,ast.Call) and ast.unparse(statement.value.func).endswith('add_argument'):continue
            if isinstance(statement,ast.Assign) and isinstance(statement.value,ast.Call) and ast.unparse(statement.value.func).endswith(('ArgumentParser','parse_args')):continue
            body.append(statement)
        synthetic=ast.Module(body=body,type_ignores=[])
        if signature(synthetic)!=signature(ast.Module(body=methods['analyze'].body,type_ignores=[])):
            raise ValueError('scientific former-guard control/number drift')
        checked+=1;expected.add('analyze')
    if set(methods)!=expected:raise ValueError('unreviewed scientific method set')
    return checked,sum(transport(node) for node in ast.walk(predecessor))


def execute_scientific(args,context):
    """Run a library under the existing Recipe owner and its typed dependency."""
    from gambit_smp.scientific_catalog import ENTRIES
    identifier=args['study']
    if identifier not in ENTRIES:raise ValueError('unknown scientific entry')
    from gambit_smp.recipes import read_json,source_path
    catalog=read_json(context.artifact(args['catalog'],'sysml-source-contract'))
    values=catalog.get('values',{}).get('ScientificStudies::catalog')
    source=source_path(context.root,'src/gambit_smp/scientific_catalog.py')
    if values is None or source.read_text()!=scientific_catalog_source(values):
        raise EvidenceUnavailable('native scientific catalog differs from the sealed library graph')
    context.bind([source,source_path(context.root,'dev/modeling/models/sysml/scientific-studies.sysml')])
    # A process/evidence receipt is not substituted for a missing selection.
    context.artifact(args['projection'],'sysml-source-contract')
    with study_execution(context,projection=args['projection'],options=args.get('options'),
                         inputs={'typedIr':args['typedIr']} if 'typedIr' in args else None):
        library=context.library(identifier)
        library.analyze()
        context.remaining()
    result=dict(study=identifier,completed=True,wholeStudyAdmitted=False,
                evidenceAccepted=False,runtimeAdmitted=False,
                scope='scientific-library-execution-under-recipe-owner')
    output=context.directory/'observation.json'
    output.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=context.publish('observation','research-audit-observation',output))


def scientific_catalog_source(values):
    """Pure view of the native ScientificStudies::catalog part."""
    from gambit_smp.recipes import fields
    fields(values,('libraryIds','entryIds','libraryCount','entryCount'))
    libraries=values['libraryIds'].split(';');entries=values['entryIds'].split(';')
    if (type(values['libraryCount']) is not int or type(values['entryCount']) is not int
            or len(libraries)!=values['libraryCount'] or len(entries)!=values['entryCount']
            or len(set(libraries))!=len(libraries) or len(set(entries))!=len(entries)
            or not set(entries)<=set(libraries)
            or any(not re.fullmatch(r'[a-z][a-z0-9_]*',name) for name in libraries)):
        raise ValueError('closed unique scientific catalog required')
    lines=['"""Closed scientific libraries. Derived from ScientificStudies; no path loading."""']
    lines+=['from gambit_smp.scientific_'+name+' import ScientificLibrary as '+name for name in libraries]
    lines+=['','LIBRARIES = {']+[f'    {name!r}: {name},' for name in libraries]
    lines+=['}','ENTRIES = {']+[f'    {name!r}: LIBRARIES[{name!r}],' for name in entries]+['}','']
    return '\n'.join(lines)


def execution_debt(tree):
    """Syntax-backed migration factors; never infer arbitrary alias closure."""
    factors={name:[] for name in ('native-process','dynamic-loader','model-stdout',
        'mutable-workspace','workspace-hint','workspace-context','legacy-workspace-read',
        'historical-cache','formal-command','view-publication')}
    context_bound=any(isinstance(n,ast.ImportFrom) and n.module=='gambit_smp.research_flow'
        and any(a.name=='study_workspace' for a in n.names) for n in tree.body)
    dependencies=set()
    for node in ast.walk(tree):
        if isinstance(node,ast.Call):
            call=ast.unparse(node.func)
            if call in {'subprocess.run','subprocess.Popen','subprocess.check_output','run','h.run'}:
                factors['native-process'].append(node.lineno)
            if call.endswith(('spec_from_file_location','exec_module')):
                factors['dynamic-loader'].append(node.lineno)
            if call.endswith(('startswith',)) and any(isinstance(a,ast.Constant) and a.value=='  = ' for a in node.args):
                factors['model-stdout'].append(node.lineno)
            if call in {'_study_write_text','_study_write_bytes'}:
                factors['view-publication'].append(node.lineno)
            if call=='_study_workspace':factors['workspace-context'].append(node.lineno)
        if isinstance(node,ast.Attribute) and isinstance(node.ctx,ast.Load) and node.attr in {'CACHE','OUT','EVIDENCE'}:
            factors['legacy-workspace-read'].append(node.lineno)
        if isinstance(node,(ast.Assign,ast.AnnAssign)):
            targets=node.targets if isinstance(node,ast.Assign) else [node.target]
            if any(isinstance(t,ast.Attribute) and t.attr in {'CACHE','OUT','EVIDENCE'}
                   and not(isinstance(t.value,ast.Name) and t.value.id=='_science') for t in targets):
                factors['mutable-workspace'].append(node.lineno)
            if any(isinstance(t,ast.Name) and t.id in {'CACHE','OUT','EVIDENCE'} for t in targets):
                factors['workspace-hint' if context_bound and node in tree.body else 'mutable-workspace'].append(node.lineno)
        if isinstance(node,ast.Constant) and isinstance(node.value,str):
            if 'legacy-evidence/' in node.value:factors['historical-cache'].append(node.lineno)
            if node.value in {'lean','quint'}:factors['formal-command'].append(node.lineno)
            if node.value.startswith('dev/modeling/tools/') and node.value.endswith('.py'):
                dependencies.add(node.value)
    return dict(factors={key:sorted(set(value)) for key,value in factors.items() if value},
                literalDependencies=sorted(dependencies),closure='syntax-only; dynamic targets remain unresolved')


def check_workspace_migration(root, fixture):
    """Finite source equivalence to reviewed pre-migration AST identities."""
    if fixture.get('schema')!='workspace-context-migration' or len(fixture['files'])!=123:
        raise ValueError('complete reviewed workspace cohort required')
    names=set();reads=0;removed=0
    cohort=json.loads((Path(root)/'tests/fixtures/sysml-api/stdout-cohort-migration.json').read_text())
    transports={row['path']:row for row in cohort['files']}
    records=scientific_records(root)
    class Restore(ast.NodeTransformer):
        def visit_Call(self,node):
            nonlocal reads
            if isinstance(node.func,ast.Name) and node.func.id=='_study_workspace':
                if (len(node.args)!=1 or node.keywords or not isinstance(node.args[0],ast.Constant)
                        or node.args[0].value not in {'CACHE','OUT','EVIDENCE'}):
                    raise ValueError('undeclared workspace role')
                reads+=1
                return ast.copy_location(ast.Name(node.args[0].value,ast.Load()),node)
            return self.generic_visit(node)
    for record in fixture['files']:
        name=record['path']
        if name in names or not name.startswith('dev/modeling/tools/') or not name.endswith('.py'):
            raise ValueError('unique owned workspace source required')
        names.add(name)
        from gambit_smp.recipes import source_path
        if source_path_exists(root,name):
            source=source_path(root,name).read_text()
            if name in transports:source=restore_stdout_source(source,transports[name])
            tree=ast.parse(source)
        else:
            tree=scientific_predecessor(root,records[name],'stdout-before' if name in transports else 'source')
        tree=restore_field_selection(tree,record)
        imports=[n for n in tree.body if isinstance(n,ast.ImportFrom) and n.module=='gambit_smp.research_flow'
            and any(a.name=='study_workspace' and a.asname=='_study_workspace' for a in n.names)]
        if len(imports)!=1:raise ValueError('one existing workspace binding required')
        tree.body=[n for n in tree.body if n not in imports]
        count=reads;tree=Restore().visit(tree)
        if reads-count!=record['readCount'] or hashlib.sha256(ast.dump(tree,include_attributes=False).encode()).hexdigest()!=record['normalizedAstSha256']:
            raise ValueError('workspace cohort algorithm drift: '+name)
        removed+=len(record['removedBindings'])
    return dict(files=len(names),workspaceReads=reads,helperRebindingsRemoved=removed,
        fieldSelectionHandoffs=sum('fieldSelectionMigration' in r for r in fixture['files']),
        algorithmsPreserved=True,scope='inverse-substitution-under-live-owner; not whole-study or native acceptance')


def restore_stdout_source(source, record):
    """Invert a reviewed transport edit; retired text is never executed."""
    digest=lambda text:hashlib.sha256(text.encode()).hexdigest()
    if digest(source)!=record['afterSha256']:
        raise ValueError('typed transport source drift: '+record['path'])
    for edit in sorted(record['edits'],key=lambda row:row['start'],reverse=True):
        if source[edit['start']:edit['end']]!=edit['after']:
            raise ValueError('transport edit identity differs')
        source=source[:edit['start']]+edit['before']+source[edit['end']:]
    if digest(source)!=record['beforeSha256']:
        raise ValueError('independent original transport source differs')
    return source


def source_path_exists(root,name):
    return (Path(root)/name).is_file()


def scientific_records(root):
    from gambit_smp.recipes import read_json,source_path
    fixture=read_json(source_path(root,'tests/fixtures/sysml-api/scientific-cohort-migration.json'))
    records={row['predecessor']:row for row in fixture['files']}
    if len(records)!=221:raise ValueError('complete scientific predecessor mapping required')
    return records


def check_stdout_migration(root, fixture):
    """Complete finite source cohort; no cached success or native inference."""
    decoder_paths=fixture.get('decoderSourcePaths',[])
    source_paths=fixture.get('sourcePaths',[])
    if (fixture.get('schema')!='sysml-stdout-cohort-migration' or len(decoder_paths)!=102
            or len(set(decoder_paths))!=102 or len(fixture['files'])<102
            or len(source_paths)!=len(set(source_paths)) or len(source_paths)!=len(fixture['files'])):
        raise ValueError('complete 101-entry and shared-library migration required')
    names=set();scientific=scientific_records(root)
    for row in fixture['files']:
        name=row['path']
        if name in names or not name.startswith('dev/modeling/tools/') or not name.endswith('.py'):
            raise ValueError('unique owned typed consumer required')
        names.add(name)
        if source_path_exists(root,name):
            source=(Path(root)/name).read_text();restored=restore_stdout_source(source,row)
            after,before=ast.parse(source),ast.parse(restored)
        else:
            proof=scientific[name]
            if proof['beforeSha256']!=row['afterSha256'] or proof.get('transportBeforeSha256')!=row['beforeSha256']:
                raise ValueError('scientific/stdout source join differs')
            after=scientific_predecessor(root,proof)
            before=scientific_predecessor(root,proof,'stdout-before')
        for tree,key in ((after,'afterAstSha256'),(before,'beforeAstSha256')):
            if ast_identity(tree)!=row[key]:
                raise ValueError('transport AST identity differs')
        if execution_debt(after)['factors'].get('model-stdout'):
            raise ValueError('production model stdout decoder survived')
    if sum(row['directRequests'] for row in fixture['files'])!=98 or sum(row['recoveryBranchesRemoved'] for row in fixture['files'])!=5:
        raise ValueError('complete direct and recovery-path inventory required')
    if not set(decoder_paths)<=names or set(source_paths)!=names:
        raise ValueError('decoder or dependent consumer source cohort missing')
    return dict(guardedDecodersRetired=101,sharedDecodersRetired=1,directTypedRequests=98,
                recoveryBranchesRetired=5,sourceFiles=len(names),sourceInverseMatched=True,wholeStudyAdmitted=False)


def restore_field_selection(tree, record):
    """Compose the reviewed transport replacement with workspace equivalence.

    Retired source snippets are parsed as inert test data, never executed.
    Scientific main bodies must match after reversing only the explicit input.
    """
    change=record.get('fieldSelectionMigration')
    if change is None:return tree
    def identity(node):return hashlib.sha256(ast.dump(node,include_attributes=False).encode()).hexdigest()
    imports=[n for n in tree.body if isinstance(n,ast.ImportFrom) and n.module=='gambit_smp.research_flow'
             and any(a.name=='projected_fields' and a.asname=='_study_fields' for a in n.names)]
    if len(imports)!=1:raise ValueError('direct typed artifact consumer required')
    tree.body=[n for n in tree.body if n not in imports]
    for index,node in enumerate(tree.body):
        if isinstance(node,ast.FunctionDef) and node.name=='project':
            if identity(node)!=change['projectAfterSha256']:raise ValueError('selected projector handoff drift')
            tree.body[index]=ast.parse(change['projectBefore']).body[0]
        elif isinstance(node,ast.FunctionDef) and node.name=='main':
            if identity(node)!=change['mainAfterSha256'] or node.args.args[-1].arg!='projection_run':
                raise ValueError('scientific caller handoff drift')
            node.args.args.pop()
            calls=0
            for call in ast.walk(node):
                if isinstance(call,ast.Call) and isinstance(call.func,ast.Name) and call.func.id=='project':
                    if len(call.args)!=1 or not isinstance(call.args[0],ast.Name) or call.args[0].id!='projection_run' or call.keywords:
                        raise ValueError('explicit projection input required')
                    call.args=[];calls+=1
            if calls!=1 or identity(node)!=change['mainBeforeSha256']:raise ValueError('scientific algorithm or controls changed')
        elif isinstance(node,ast.If) and '__name__' in ast.unparse(node.test):
            if identity(node)!=change['guardAfterSha256']:raise ValueError('selected input entry drift')
            tree.body[index]=ast.parse(change['guardBefore']).body[0]
    return tree


def inventory(root):
    root = Path(root).resolve()
    generators = set(POLICY['sourceGeneratorFiles'].split(';'))
    from gambit_smp.scientific_catalog import LIBRARIES
    library_sources={'src/gambit_smp/scientific_'+name+'.py' for name in LIBRARIES}
    files, accesses, violations = [], [], []
    for prefix in ['dev/modeling/tools', 'src/gambit_smp']:
        for path in sorted((root/prefix).glob('*.py')):
            name = str(path.relative_to(root))
            raw = path.read_bytes()
            tree = ast.parse(raw, filename=name)
            guards = [node for node in tree.body if isinstance(node, ast.If)
                      and '__name__' in ast.unparse(node.test)]
            study = ((prefix.startswith('dev/') or path.name.startswith('scientific_'))
                     and path.name!='scientific_catalog.py' and name not in generators)
            if prefix.startswith('dev/') and name not in generators:
                violations.append(dict(path=name,reason='retired research tool path; use the closed scientific catalog'))
            if path.name.startswith('scientific_') and path.name!='scientific_catalog.py' and name not in library_sources:
                violations.append(dict(path=name,reason='scientific library is outside the native catalog'))
            guarded = bool(guards) and '_study_execution' in ast.unparse(guards[-1])
            role = ('source-generator' if name in generators else
                    'guarded-study' if study and guards else
                    'scientific-library' if study and path.name.startswith('scientific_') else
                    'study-library' if study else 'framework')
            if study and guards and not guarded:
                violations.append(dict(path=name, reason='unguarded research entry'))
            file = dict(path=name, sha256=hashlib.sha256(raw).hexdigest(), role=role, guarded=guarded)
            if study:
                file['executionDebt']=execution_debt(tree)
                if file['executionDebt']['factors'].get('mutable-workspace'):
                    violations.append(dict(path=name,reason='global workspace rebinding is retired'))
            files.append(file)
            for node in ast.walk(tree):
                if (isinstance(node, ast.BinOp) and isinstance(node.op, ast.Div)
                        and isinstance(node.left, ast.BinOp) and isinstance(node.left.right, ast.Constant)
                        and node.left.right.value == 'evidence/research'):
                    violations.append(dict(path=name, line=node.lineno, reason='old dynamic evidence base'))
                if not isinstance(node, ast.Call):
                    continue
                function = ast.unparse(node.func)
                leaf = function.rsplit('.', 1)[-1]
                access = None
                if leaf in {'read_text', 'read_bytes', 'source_path', 'read_json', 'digest', 'sha'}:
                    access = 'read'
                elif leaf in {'write_text', 'write_bytes', '_study_write_text', '_study_write_bytes', 'save', 'copyfile', 'copytree', 'copy2', 'open'}:
                    access = 'write-or-declared-access'
                if not access:
                    continue
                accesses.append(dict(source=name, line=node.lineno, access=access,
                    expression=ast.unparse(node), boundary=role,
                    staticResolution='syntax-only-dynamic-targets-not-silently-closed'))
                if study and leaf in {'write_text', 'write_bytes'}:
                    violations.append(dict(path=name, line=node.lineno, reason='unmediated study write'))
                if (study and leaf in {'read_text', 'read_bytes'} and isinstance(node.func, ast.Attribute)
                        and isinstance(node.func.value, ast.BinOp)
                        and isinstance(node.func.value.left, ast.Name) and node.func.value.left.id == 'CACHE'
                        and isinstance(node.func.value.right, ast.Constant)
                        and node.func.value.right.value in POLICY['authorInputNames'].split(';')):
                    violations.append(dict(path=name, line=node.lineno, reason='maintained recipe hidden in cache'))
    # Declared Recipe input lists are necessary source closure, not native success.
    inputs, unavailable_recipes = [], []
    # Git links ship a source identity, not the submodule's dirty worktree or
    # initialized files. A cold checkout must report that prerequisite absent.
    gitlinks = {}
    if (root/'.git').exists():
        indexed = run_process(['git', 'ls-files', '--stage', '-z'], cwd=root, capture_output=True, check=True, timeout=60).stdout
        for entry in indexed.split(b'\0'):
            if entry:
                meta, name = entry.split(b'\t', 1)
                mode, oid, stage = meta.decode().split()
                if mode == '160000' and stage == '0':
                    gitlinks[name.decode()] = oid
    for path in sorted((root/'tests/recipes').rglob('*.recipe.json')):
        document = json.loads(path.read_text())
        absent_external = []
        for name in document.get('inputs', []):
            target = root/name
            external = next((link for link in gitlinks if name.startswith(link+'/')), None)
            allowed = external is not None or classify(name, target.stat().st_size if target.is_file() else 0)['disposition'] == 'allow'
            state = 'matched' if target.is_file() else 'missing'
            row = dict(id=f'{path.relative_to(root)}:{name}', path=name, mode='required-source',
                       state=state, identity='exact' if state == 'matched' else 'absent', sourceAllowed=allowed)
            if external:
                row.update(sourceKind='external-gitlink-worktree', gitlink=external,
                           gitlinkRevision=gitlinks[external], immutableWorktreeClaim=False)
                if state == 'missing':
                    absent_external.append(name)
            inputs.append(row)
            if not allowed or state != 'matched' and not external:
                violations.append(dict(path=str(path.relative_to(root)), input=name, reason='missing or unversioned required source'))
        from gambit_smp.recipes import load as load_recipe
        if absent_external:
            unavailable_recipes.append(dict(path=str(path.relative_to(root)), missing=absent_external,
                outcome='unavailable', executable=False, runtimeAdmitted=False))
            # Confirm the real loader refuses these inputs; never substitute
            # the original checkout or cached source bytes.
            try:
                load_recipe(root, path)
            except (ValueError, OSError, KeyError):
                continue
            violations.append(dict(path=str(path.relative_to(root)), reason='loader admitted missing external source'))
            continue
        try:
            load_recipe(root, path)
        except (ValueError, OSError, KeyError) as error:
            violations.append(dict(path=str(path.relative_to(root)), reason='recipe contract: '+str(error)))
    from gambit_smp.evidence_views import registry
    names, registry_inputs = registry(root)
    for name in names:
        path = root/name
        if not path.is_file() or classify(name, path.stat().st_size)['disposition'] != 'allow':
            violations.append(dict(path=name, reason='registered declaration is not maintained source'))
            continue
        document = json.loads(path.read_text())
        from gambit_smp.source_identity import read_git_sources
        git_refs=[ref for ref in document['references'] if ref.get('identity',{}).get('kind')=='git']
        try:
            git_bytes=dict(zip((ref['id'] for ref in git_refs),
                read_git_sources(root,[ref['identity'] for ref in git_refs])))
        except ValueError as error:
            violations.append(dict(path=name,reason='invalid source identity batch: '+str(error)))
            git_bytes={ref['id']:None for ref in git_refs}
        for ref in document['references']:
            target = root/ref['path']
            if 'identity' in ref:
                from gambit_smp.source_identity import reference_bytes, SourceUnavailable
                try:
                    if ref['id'] in git_bytes:
                        data=git_bytes[ref['id']]
                        actual=hashlib.sha256(data).hexdigest() if data is not None else None
                    else:
                        actual = hashlib.sha256(reference_bytes(root, ref)).hexdigest()
                except (SourceUnavailable, FileNotFoundError):
                    actual = None
                except ValueError as error:
                    violations.append(dict(path=name, reference=ref['id'], reason='invalid source identity: '+str(error)))
                    actual = None
            else:
                actual = sha(target) if target.is_file() else None
            state = 'matched' if actual == ref['sha256'] else 'missing' if actual is None else 'changed'
            inputs.append(dict(id=name+':'+ref['id'], path=ref['path'], mode='historical-evidence',
                state=state, identity='exact' if state == 'matched' else 'absent-or-mismatch', sourceAllowed=False))
    return dict(files=files, accesses=accesses, inputs=inputs, violations=violations,
        unavailableRecipes=unavailable_recipes,
        requiredInputsAvailable=all(row['state'] == 'matched' for row in inputs if row['mode'] == 'required-source'),
        sourceBindings={f['path']: f['sha256'] for f in files},
        boundary='enumerated Python syntax + guarded study writes + declared source inputs; not full native or semantic closure')


def materialize(root, destination):
    """Export proposed source bytes, with a separate index, no cache/venv/state.

    Includes admitted unstaged/new source because this is a review checkout of
    pending changes, not a claim about committed HEAD. Submodules stay Git links.
    """
    root, destination = Path(root).resolve(), Path(destination).resolve()
    if destination.exists():
        raise ValueError('fresh checkout destination required')
    destination.mkdir(parents=True)
    indexed = run_process(['git', 'ls-files', '--stage', '-z'], cwd=root, capture_output=True, check=True, timeout=60).stdout
    candidates, links = set(), []
    for entry in indexed.split(b'\0'):
        if not entry:
            continue
        meta, name = entry.split(b'\t', 1)
        mode, oid, stage = meta.decode().split()
        if stage != '0':
            raise ValueError('unmerged source cannot be exported')
        if mode == '160000':
            links.append((mode, oid, name.decode()))
        else:
            candidates.add(name.decode())
    candidates.update(name for name in run_process(
        ['git', 'ls-files', '--others', '--exclude-standard', '-z'], cwd=root, capture_output=True, check=True, timeout=60).stdout.decode().split('\0') if name)
    copied = []
    original = {}
    for name in sorted(candidates):
        path = root/name
        if not path.is_file():
            continue
        if path.is_symlink() or classify(name, path.stat().st_size)['disposition'] != 'allow':
            raise ValueError('unadmitted source candidate: '+name)
        target = destination/name
        original[name] = sha(path)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        if sha(target) != original[name]:
            raise ValueError('source changed during export: '+name)
        copied.append(name)
    if any(sha(root/name) != value for name,value in original.items()):
        raise ValueError('source changed during checkout export')
    run_process(['git', 'init', '-q', str(destination)], check=True)
    run_process(['git', 'add', '-f', '--pathspec-from-file=-', '--pathspec-file-nul'],
                   cwd=destination, input='\0'.join(copied).encode()+b'\0', check=True)
    for mode, oid, name in links:
        run_process(['git', 'update-index', '--add', '--cacheinfo', mode, oid, name], cwd=destination, check=True)
    if any((destination/name).exists() for name in ['.cache', '.state', '.venv', '.data']):
        raise ValueError('clean checkout accidentally copied local execution state')
    return dict(files=len(copied), gitLinks=len(links), sourceBindings={name:sha(destination/name) for name in copied},
                committedHeadClaim=False, copiedCache=False, submodulesInitialized=False,
                snapshotConsistency='hash-fenced; not an atomic filesystem snapshot or build reuse credential')


def clean_smoke(root, destination):
    """Exercise maintained entrypoints using only the exported checkout data."""
    root, destination = Path(root).resolve(), Path(destination).resolve()
    export = materialize(root, destination)
    (destination.parent/'source-export.json').write_text(json.dumps(export, indent=2)+'\n')
    env = {k:v for k,v in os.environ.items() if not k.startswith(('GAMBIT_SMP_', 'GIT_'))}
    env.update(GAMBIT_SMP_ROOT=str(destination), PYTHONDONTWRITEBYTECODE='1')
    target=destination.parent/'cold-result.json'
    if target.exists():raise ValueError('fresh cold result path required')
    # Execute the exported shared module, not a generated Python program.
    result = run_process([sys.executable, '-I', '-B',
        str(destination/'src/gambit_smp/research_flow.py'), '--cold-check', str(target)],
        cwd=destination, env=env, capture_output=True, text=True, timeout=60)
    (destination.parent/'clean-stdout.log').write_text(result.stdout)
    (destination.parent/'clean-stderr.log').write_text(result.stderr)
    if result.returncode:
        raise ValueError('clean checkout smoke failed: '+result.stderr[-5000:])
    from gambit_smp.recipes import read_json
    smoke=read_json(target)
    if smoke.get('schema') != 'research-cold-check' or smoke.get('root') != str(destination):
        raise ValueError('cold result belongs to another source checkout')
    return dict(export=export, smoke=smoke,
                interpreter=sys.executable, libraryBoundary='installed Python/ASCENT; no source/cache fallback',
                nativeBuildRun=False)




def flow_facts(rows, writers, executions):
    return dict(input=[[r['id'],r['path'],r['mode']] for r in rows],
        observation=[[r['id'],r['state'],r['identity']] for r in rows],
        sourceClass=[[r['id'],'yes' if r['sourceAllowed'] else 'no'] for r in rows],
        writer=writers, execution=executions)


def check_retirement_inventory(config, files):
    names=sorted(row['path'] for row in files if row['role']=='guarded-study')
    identity=hashlib.sha256(('\n'.join(names)+'\n').encode()).hexdigest()
    if len(names)!=config['remainingStudyCount'] or identity!=config['remainingStudyInventorySha256']:
        raise ValueError('remaining study entries changed; explicit SysML migration review required')
    return dict(entries=len(names),inventorySha256=identity)


def check_stdout_inventory(config, files):
    names=sorted(row['path'] for row in files
        if row.get('executionDebt',{}).get('factors',{}).get('model-stdout'))
    identity=hashlib.sha256(('\n'.join(names)+'\n').encode()).hexdigest()
    if len(names)!=config['remainingStdoutDecoderCount'] or identity!=config['remainingStdoutInventorySha256']:
        raise ValueError('stdout decoder cohort changed; explicit typed migration review required')
    return dict(entries=len(names),inventorySha256=identity)


def check_field_evolution(root, review):
    """Review source evolution without re-signing the independent value oracle."""
    import copy,difflib
    from gambit_smp.recipes import read_json,source_path
    from gambit_smp.contract_capabilities import selection_contract
    canonical=lambda value:hashlib.sha256(json.dumps(value,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    plan=read_json(source_path(root,review['selection']));selection_contract(plan)
    if (review.get('schema')!='sysml-field-source-evolution' or len(plan['queries'])!=809
            or canonical(plan['queries'])!=review['queriesSha256']
            or canonical(plan['expected'])!=review['expectedSha256']):
        raise ValueError('independent 809-field oracle changed')
    prior=copy.deepcopy(plan);prior['modelInputs']=review['priorModelInputs']
    if canonical(prior)!=review['priorPlanSha256']:
        raise ValueError('independent prior field plan changed')
    actual=sorted(str(path.relative_to(root)) for path in (root/'dev').rglob('*')
                  if path.is_file() and path.suffix in {'.sysml','.kerml'})
    if actual!=sorted(plan['modelInputs']):raise ValueError('field plan omits current model closure')
    if sorted(set(plan['modelInputs'])-set(prior['modelInputs']))!=review['addedModels']:
        raise ValueError('unreviewed added field model')
    changed={name for name,before in prior['modelInputs'].items() if plan['modelInputs'].get(name)!=before}
    if changed!={row['path'] for row in review['changed']} or len(changed)!=len(review['changed']):
        raise ValueError('incomplete changed field source inventory')
    for row in review['changed']:
        name=row['path'];current=source_path(root,name).read_text()
        diff=''.join(difflib.unified_diff(row['before'].splitlines(True),current.splitlines(True),fromfile=name,tofile=name))
        if (hashlib.sha256(row['before'].encode()).hexdigest()!=row['beforeSha256']
                or row['beforeSha256']!=prior['modelInputs'][name]
                or row['afterSha256']!=plan['modelInputs'][name] or row['reviewedDiff']!=diff
                or hashlib.sha256(diff.encode()).hexdigest()!=row['reviewedDiffSha256']):
            raise ValueError('unreviewed field source evolution: '+name)
    if any(sha(source_path(root,name))!=value for name,value in plan['modelInputs'].items()):
        raise ValueError('current field source drift')
    return dict(fields=809,models=len(actual),changedModels=len(changed),addedModels=len(review['addedModels']),
                independentExpectedUnchanged=True,runtimeAdmitted=False)


def audit_contract(args, ctx):
    """Complete source-policy audit in the existing bounded capability owner."""
    from gambit_smp.recipes import read_json, source_path
    from gambit_smp.evidence_capabilities import evaluate_observations, dsl_sources, dsl_entry
    from gambit_smp.research_publication import publication_views, publication_facts, audit_index, _rules
    projection=ctx.artifact(args['projection'], 'sysml-source-contract')
    document=read_json(projection)
    if document.get('schema') != 'sysml-source-contract-projection' or document.get('runtimeAdmitted') is not False:
        raise ValueError('non-runtime typed SysML bundle required')
    parts=document['values']; prefix='GambitResearchStorage::'
    if set(parts) != {prefix+'policy',prefix+'artifactFlow',prefix+'audit','ScientificStudies::catalog',*(prefix+'category'+str(i) for i in range(6))}:
        raise ValueError('complete policy/category/flow/audit part inventory required')
    config=parts[prefix+'audit']
    if any(not isinstance(config.get(key),str) for key in
           ('oracle','publicationEntry','flowEntry','workspaceMigrationInput','stdoutMigrationInput','scientificMigrationInput','scientificCatalogModel','clueControlsInput','fieldEvolutionInput')):
        raise ValueError('audit oracle and native rules must be declared inputs')
    names=[config['oracle'],config['publicationEntry'],config['flowEntry'],config['workspaceMigrationInput'],config['stdoutMigrationInput'],config['scientificMigrationInput'],config['scientificCatalogModel'],config['clueControlsInput'],config['fieldEvolutionInput']]
    if not set(names) <= set(ctx.receipt['declaredInputs']):
        raise ValueError('audit oracle and native DSL entries must be declared inputs')
    paths=[projection, *(source_path(ctx.root,name) for name in names)]
    for name in (config['publicationEntry'],config['flowEntry']):
        entry=dsl_entry(read_json(source_path(ctx.root,name)))
        paths.extend(dsl_sources(entry,ctx.root))
    model=source_path(ctx.root,'dev/modeling/models/sysml/research-storage.sysml')
    paths.append(model);ctx.bind(paths)
    oracle=read_json(source_path(ctx.root,config['oracle']))
    if oracle.get('schema') != 'research-policy-equivalence' or len(oracle['publicationCases']) != 21 or len(oracle['flowCases']) != 7:
        raise ValueError('complete independently reviewed 21/7 regression oracle required')
    retired=set(config['retiredEntries'].split(';'))
    expected_policy=dict(oracle['parts'][prefix+'policy'])
    legacy=set(expected_policy['sourceGeneratorFiles'].split(';'))
    if not retired <= legacy or not retired or any((ctx.root/name).exists() for name in retired):
        raise ValueError('retired standalone execution entries still exist or were not legacy generators')
    expected_policy['sourceGeneratorFiles']=';'.join(name for name in oracle['parts'][prefix+'policy']['sourceGeneratorFiles'].split(';') if name not in retired)
    policy=parts[prefix+'policy']
    if policy != expected_policy:
        raise ValueError('policy differs from independent oracle beyond explicit runner retirement')
    categories=[parts[prefix+'category'+str(i)] for i in range(6)]
    if any(row != oracle['parts'][prefix+'category'+str(i)] for i,row in enumerate(categories)):
        raise ValueError('artifact classes differ from independent oracle')
    flow=parts[prefix+'artifactFlow']
    if any(flow.get(key) != value for key,value in oracle['parts'][prefix+'artifactFlow'].items()):
        raise ValueError('flow safety policy differs from independent oracle')
    views=publication_views(policy,categories,sha(model),(ctx.root/'.gitignore').read_text())
    mismatched=[]
    for name,text in views.items():
        target=ctx.root/name;ctx.bind([target])
        preview=ctx.directory/'views'/name
        preview.parent.mkdir(parents=True,exist_ok=True);preview.write_text(text)
        if target.read_text() != text:mismatched.append(name)
    if mismatched and not args.get('preview',False):
        raise ValueError('derived policy views differ; explicit preview/review required: '+repr(mismatched))
    if not mismatched and (policy != POLICY or sha(model) != _rules.POLICY_SHA256):
        raise ValueError('loaded classifier and projected native policy differ')
    publication=evaluate_observations(ctx,[],publication_facts(oracle['publicationCases'],categories),
        {'gitAllowed':'gitAllowed','gitRejected':'gitRejected'},'publication-controls',dsl=config['publicationEntry'])
    def canonical(answers):return {key:sorted(value) for key,value in answers.items()}
    if canonical(publication) != canonical(oracle['publicationExpected']):
        raise ValueError('publication controls differ from independent legacy execution')
    queries={name:name for name in ('ready','unavailable','blocked','accepted','unresolved','writerAdmitted','writerBlocked')}
    control_rows=[];expected={name:[] for name in queries}
    for number,case in enumerate(oracle['flowCases']):
        identifier='control-'+str(number)
        control_rows.append(dict(case['input'],id=identifier))
        for relation,rows in case['expected'].items():
            expected[relation].extend([[identifier if cell=='case' else cell for cell in row] for row in rows])
    expected={key:sorted(map(list,{tuple(row) for row in rows})) for key,rows in expected.items()}
    controls=evaluate_observations(ctx,[],flow_facts(control_rows,[['unscoped','guarded','legacy-cache']],
        [['unknown','completed','unresolved'],['missing','unavailable','verified']]),queries,
        'flow-controls',dsl=config['flowEntry'])
    if canonical(controls) != canonical(expected):
        raise ValueError('flow controls differ from independent legacy execution')
    ctx.remaining()
    report=inventory(ctx.root)
    (ctx.directory/'inventory.json').write_text(json.dumps(report,indent=2)+'\n')
    if report['violations']:raise ValueError('source inventory violations: '+repr(report['violations'][:10]))
    retirement=check_retirement_inventory(config,report['files'])
    stdout=check_stdout_inventory(config,report['files'])
    scanned=[ctx.root/name for name in report['sourceBindings']]
    if any(sha(ctx.root/name) != value for name,value in report['sourceBindings'].items()):
        raise ValueError('source changed after inventory read')
    ctx.bind(scanned)
    catalog=source_path(ctx.root,'src/gambit_smp/scientific_catalog.py');ctx.bind([catalog])
    if catalog.read_text()!=scientific_catalog_source(parts['ScientificStudies::catalog']):
        raise ValueError('native SysML scientific catalog and static source differ')
    transport_fixture=read_json(source_path(ctx.root,config['stdoutMigrationInput']))
    token=_scientific_cache.set({})
    try:
        scientific=check_scientific_migration(ctx.root,read_json(source_path(ctx.root,config['scientificMigrationInput'])))
        workspace=check_workspace_migration(ctx.root,read_json(source_path(ctx.root,config['workspaceMigrationInput'])))
        transport=check_stdout_migration(ctx.root,transport_fixture)
    finally:_scientific_cache.reset(token)
    required_libraries=[];observed_libraries=[]
    for case in ('actual','missing','drift','runner','foreign','contradictory'):
        ids=[case+':'+name for name in parts['ScientificStudies::catalog']['libraryIds'].split(';')]
        required_libraries.extend([[name] for name in ids])
        observed_libraries.extend([[name,'matched','typed','recipe','absent'] for name in ids
                                  if not(case=='missing' and name==ids[0])])
        if case=='drift':observed_libraries[-1][1]='changed'
        if case=='runner':observed_libraries[-1][4]='present'
        if case=='foreign':observed_libraries.append([case+':foreign','matched','typed','recipe','absent'])
        if case=='contradictory':observed_libraries.append([ids[0],'changed','typed','recipe','absent'])
    duties=[['quint.observe','finite-observation'],['quint.verify','exhaustive-check'],['lean.check','inductive-kernel']]
    formal_expected=[['actual:'+name,role] for name,role in duties]+[['wrong:'+name,role] for name,role in duties]
    formal_observed=[['actual:'+name,role] for name,role in duties]+[['wrong:'+name,'interchangeable-model'] for name,_ in duties]
    linked=evaluate_observations(ctx,[],dict(libraryRequired=required_libraries,libraryObserved=observed_libraries,
        formalDuty=formal_expected,formalObserved=formal_observed,
        writer=[['cap-good','capability-library','recipe-owned'],['cap-bad','capability-library','fresh-run']]),
        {'checked':'libraryChecked','blocked':'libraryBlocked','formalBlocked':'formalBlocked',
         'writerAdmitted':'writerAdmitted','writerBlocked':'writerBlocked'},
        'scientific-controls',dsl=config['flowEntry'])
    if (len([row for row in linked['checked'] if row[0].startswith('actual:')])!=scientific['libraries']
            or any(row[0].startswith('actual:') for row in linked['blocked'])
            or {row[0].split(':',1)[0] for row in linked['blocked']}!={'missing','drift','runner','foreign','contradictory'}
            or sorted(linked['formalBlocked'])!=sorted([['wrong:'+name] for name,_ in duties])
            or linked['writerAdmitted']!=[['cap-good']] or linked['writerBlocked']!=[['cap-bad']]):
        raise ValueError('scientific cohort or exclusive formal-duty negative control failed')
    required=[];observed=[]
    for case in ('actual','missing','stale','decoder','foreign','contradictory'):
        ids=[case+':'+row['path'] for row in transport_fixture['files']]
        required.extend([[name] for name in ids])
        observed.extend([[name,'matched','matched','absent'] for name in ids if not(case=='missing' and name==ids[0])])
        if case=='stale':observed[-len(ids)][2]='changed'
        if case=='decoder':observed[-len(ids)][3]='present'
        if case=='foreign':observed.append([case+':foreign','matched','matched','absent'])
        if case=='contradictory':observed.append([ids[0],'matched','changed','absent'])
    answers=evaluate_observations(ctx,[],dict(transportRequired=required,transportObserved=observed),
        {'checked':'transportChecked','blocked':'transportBlocked'},'transport-controls',dsl=config['flowEntry'])
    if (len([row for row in answers['checked'] if row[0].startswith('actual:')])!=len(transport_fixture['files'])
            or any(row[0].startswith('actual:') for row in answers['blocked'])
            or {row[0].split(':',1)[0] for row in answers['blocked']}!={'missing','stale','decoder','foreign','contradictory'}):
        raise ValueError('transport source admission or refusal controls failed')
    writer_roles={'guarded-study':('guarded','fresh-run'),
                  'source-generator':('source-generator','explicit-publication'),
                  'scientific-library':('capability-library','recipe-owned')}
    writers=[[row['path'],*writer_roles[row['role']]]
        for row in report['files'] if row['role'] in writer_roles]
    if sum(row[1]=='capability-library' for row in writers)!=scientific['libraries']:
        raise ValueError('scientific writer set differs from the checked library catalog')
    actual=evaluate_observations(ctx,[],flow_facts(report['inputs'],writers,[['all-native-effects','completed','unresolved']]),
        queries,'actual-flow',dsl=config['flowEntry'])
    if actual['blocked'] or actual['writerBlocked'] or actual['accepted']:
        raise ValueError('source/writer admission failed or unknown effects were accepted')
    evolution=read_json(source_path(ctx.root,config['fieldEvolutionInput']))
    fields_reviewed=check_field_evolution(ctx.root,evolution)
    ctx.bind([source_path(ctx.root,evolution['selection']), *[source_path(ctx.root,name) for name in read_json(source_path(ctx.root,evolution['selection']))['modelInputs']]])
    index=audit_index(ctx.root,deadline=ctx.deadline)
    if index['violations']:raise ValueError('publication index violations: '+repr(index['violations'][:10]))
    current={path.resolve() for prefix in ('dev/modeling/tools','src/gambit_smp') for path in (ctx.root/prefix).glob('*.py')}
    if current != {path.resolve() for path in scanned}:
        raise ValueError('source inventory membership changed during audit')
    ctx.bind([*paths,*scanned]);ctx.remaining()
    result=dict(publicationVerified=True,flowVerified=True,viewsMatched=not mismatched,
        previewOnly=bool(mismatched),publicationCases=21,flowCases=7,gitCandidatesChecked=index['gitCandidatesChecked'],
        requiredInputsAvailable=report['requiredInputsAvailable'],unavailableEvidence=len(actual['unavailable']),
        nativeWriterClosure=False,evidenceAccepted=False,runtimeAdmitted=False,retiredEntries=sorted(retired),
        remainingStudyInventory=retirement,scientificMigration=scientific,scientificControls=linked,
        fieldEvolution=fields_reviewed,
        scientificWriters=len([row for row in writers if row[1]=='capability-library']),
        remainingStdoutInventory=stdout,stdoutMigration=transport,stdoutCohortVerified=True,
        workspaceMigration=workspace,workspaceAlgorithmsPreserved=workspace['algorithmsPreserved'],
        scope='finite-policy-and-source-flow-checks-only')
    output=ctx.directory/'audit.json';output.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=ctx.publish('observation','research-audit-observation',output))


def cold_check(root):
    """Read-only source checkout acceptance; unavailable evidence stays false."""
    import gambit_smp
    root=Path(root).resolve()
    if not Path(gambit_smp.__file__).resolve().is_relative_to(root):
        raise ValueError('cold checkout imported the caller implementation')
    report=inventory(root)
    if report['violations']:raise ValueError('cold source violations: '+repr(report['violations'][:5]))
    brief=gambit_smp.repository_clues(root,bindings=[])['brief'];coverage=brief['evidenceCoverage']
    if not coverage['unavailableViews'] or coverage['complete'] is not False:
        raise ValueError('missing evidence was not preserved as unavailable')
    if brief['runtimeAdmitted'] is not False or brief['executionAuthorized'] is not False:
        raise ValueError('source-only checkout gained runtime admission')
    from gambit_smp.contract_capabilities import sealed_sdk
    try:sealed_sdk(root/'.cache/unavailable-service-provider')
    except FileNotFoundError:pass
    else:raise ValueError('missing sealed provider was admitted')
    origins=[Path(module.__file__).resolve() for name,module in sys.modules.items()
        if name.startswith('gambit_smp') and getattr(module,'__file__',None)]
    if not all(path.is_relative_to(root) for path in origins):
        raise ValueError('cold source module escaped the exported checkout')
    return dict(schema='research-cold-check',root=str(root),sourceViolations=0,evidenceCoverage=coverage,runtimeAdmitted=False,executionAuthorized=False,
        requiredInputsAvailable=report['requiredInputsAvailable'],unavailableRecipes=report['unavailableRecipes'],
        serviceProviderAvailable=False,projectModules=len(origins),code=str(gambit_smp.__file__))


def recovery_reference(row, reference):
    """Retire a path edge without changing its historical content or duty."""
    resolution=row.get('storageResolution',{})
    identity=resolution.get('identity',{})
    original=row['referenceSpec']
    expected={**original,'identity':identity}
    repository='vendor/gambit' if row['path'].startswith('vendor/gambit/') else '.'
    name=row['path'][len('vendor/gambit/'):] if repository!='.' else row['path']
    if (reference!=expected or row['sha256']!=original['sha256']
            or identity.get('kind')!='git' or identity.get('sha256')!=row['sha256']
            or identity.get('repository')!=repository or identity.get('path')!=name
            or not re.fullmatch(r'[0-9a-f]{40}',identity.get('revision',''))
            or not re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}',identity.get('blob',''))
            or set(resolution)!={'identity','originalReferencePreserved','liveCacheEdgeRetired','executionProvenance'}
            or resolution['originalReferencePreserved'] is not True
            or resolution['liveCacheEdgeRetired'] is not True
            or resolution['executionProvenance'] is not False):
        raise ValueError('historical obligation or immutable storage changed: '+row['id'])
    return identity


def evidence_recovery(args,ctx):
    """Audit every pinned obligation without restoring historical storage."""
    from gambit_smp.recipes import read_json,source_path
    from gambit_smp.source_identity import reference_bytes,SourceUnavailable
    from gambit_smp.evidence_capabilities import evaluate_observations
    projection=ctx.artifact(args['projection'],'sysml-source-contract')
    cfg=read_json(projection)['values']['ScientificStudies::recovery']
    plan_path=source_path(ctx.root,cfg['plan'])
    if cfg['plan'] not in ctx.receipt['declaredInputs']:raise ValueError('declared recovery ledger required')
    plan=read_json(plan_path);rows=plan['rows']
    if (plan.get('schema')!='evidence-recovery-plan' or len(rows)!=cfg['referenceCount']
            or len({row['id'] for row in rows})!=cfg['referenceCount']):
        raise ValueError('complete independent235-reference ledger required')
    ctx.bind([projection,plan_path]);observations=[]
    from gambit_smp.source_identity import read_git_sources
    identities=[recovery_reference(row,{**row['referenceSpec'],'identity':row.get('storageResolution',{}).get('identity',{})}) for row in rows]
    ctx.remaining()
    bodies=read_git_sources(ctx.root,identities)
    historical={json.dumps(identity,sort_keys=True):body for identity,body in zip(identities,bodies)}
    ctx.remaining()
    documents={};catalogs={};claim_records=0
    from gambit_smp.ascent_program import load_component_catalog
    for row in rows:
        name=row['view'];path=source_path(ctx.root,name)
        if name not in ctx.receipt['declaredInputs']:raise ValueError('complete declared view-consumer closure required')
        if name not in documents:
            documents[name]=read_json(path);ctx.bind([path])
            definition=documents[name];key=(definition['manifest'],definition['entry'])
            if key not in catalogs:
                manifest=source_path(ctx.root,key[0])
                if key[0] not in ctx.receipt['declaredInputs']:raise ValueError('declared consumer component manifest required')
                ctx.remaining()
                catalog=load_component_catalog(manifest,entry=key[1],constructor=definition['constructor'],trusted=True)
                bound=[Path(value) for value in catalog['sourceInputs']]
                engine=Path(ctx.receipt['engine']['path']).resolve()
                for dependency in bound:
                    if dependency.is_relative_to(engine):continue
                    if str(dependency.relative_to(ctx.root)) not in ctx.receipt['declaredInputs']:
                        raise ValueError('complete maintained consumer code inputs required')
                ctx.bind(bound)
                catalogs[key]=dict(manifest=key[0],entry=key[1],
                    components=[r['id'] for r in catalog['nativeComponents']['manifest']['components']],
                    sourceInputs=catalog['sourceInputs'],currentFactsAdmitted=False)
        document=documents[name]
        reference=next((item for item in document['references'] if item['id']==row['reference']),None)
        if row['id']!=name+':'+row['reference']:
            raise ValueError('historical obligation or consumer changed: '+row['id'])
        identity=recovery_reference(row,reference)
        declaration=row['consumer'].get('sourceDeclaration')
        if declaration:
            if declaration not in ctx.receipt['declaredInputs']:
                raise ValueError('declared reference-producing source required')
            producer_path=source_path(ctx.root,declaration);ctx.bind([producer_path])
            producer=read_json(producer_path)
            produced=next((r for r in producer['references'] if r['id']==row['reference']),None)
            if (producer.get('output')!=name or produced is None
                    or produced['source'].get('identity')!=identity
                    or produced['source'].get('sha256')!=row['sha256']):
                raise ValueError('reference producer would restore a retired path dependency')
        if document['entry']!=row['consumer']['entry'] or document['constructor']!=row['consumer']['constructor']:
            raise ValueError('recovery consumer identity changed')
        ctx.remaining()
        key=json.dumps(identity,sort_keys=True)
        raw=historical[key]
        state='missing' if raw is None else 'historical-exact' if hashlib.sha256(raw).hexdigest()==row['sha256'] else 'changed'
        if raw is not None and row['producer'].get('recordClaims'):
            from gambit_smp.native_review import pointer
            record=json.loads(raw)
            for claim in row['producer']['recordClaims']:
                if claim.get('attestedExecution') is not False or pointer(record,claim['pointer'])!=claim['value']:
                    raise ValueError('historical producer declaration changed')
            claim_records+=1
        if row['producer']['status']=='git-source' and (row['group']!='source-contract' or row['producer']['sourceOwners']!=[identity]):
            raise ValueError('immutable source owner cannot attest a generated execution')
        if row['historicalObligationRetired'] is not False or row['currentAdmission'] is not False:
            raise ValueError('historical obligation cannot be erased or promoted by a recovery plan')
        observations.append(dict(id=row['id'],group=row['group'],state=state,
            producer=row['producer']['status'],action=row['requiredAction'],currentAdmission=False))
    if len(catalogs)!=cfg['consumerClosures']:raise ValueError('consumer closure inventory changed')
    facts=dict(recoveryRequired=[[r['id'],r['group']] for r in rows],
        recoveryObserved=[[r['id'],r['state'],'historical',r['group'],r['producer']] for r in observations],
        storageRequired=[[r['id']] for r in rows],
        storageObserved=[[r['id'],'git','same-content','same-duty','no-cache'] for r in rows])
    facts['storageRequired'] += [['storage-missing-control'],['storage-content-control'],['storage-duty-control']]
    facts['storageObserved'] += [['storage-content-control','git','changed-content','same-duty','no-cache'],
                                 ['storage-duty-control','git','same-content','changed-duty','no-cache']]
    facts['recoveryRequired'] += [['missing-control','native-result'],['scope-control','formal-result'],['wrong-duty-control','native-result']]
    facts['recoveryObserved'] += [['scope-control','historical-exact','current','formal-result','source-bound'],
                                  ['wrong-duty-control','fresh-checked','current','formal-result','source-bound']]
    answers=evaluate_observations(ctx,[],facts,dict(pending='recoveryPending',qualified='recoveryQualified',retired='storageRetired',storagePending='storagePending'),
        'recovery-admission',dsl='tests/recipes/framework-contracts/flow-entry.json')
    if (answers['qualified'] or len(answers['pending'])!=cfg['referenceCount']+3
            or len(answers['retired'])!=cfg['referenceCount'] or len(answers['storagePending'])!=3):
        raise ValueError('recovery missing/scope refusal failed')
    from collections import Counter
    result=dict(references=len(rows),paths=len({r['path'] for r in rows}),views=len(documents),
        consumerCodeClosures=list(catalogs.values()),consumerCodeLinked=True,
        groups=dict(Counter(r['group'] for r in rows)),states=dict(Counter(r['state'] for r in observations)),
        producerClaims=dict(Counter(r['producer'] for r in observations)),historicalInputsRestored=0,
        retiredCacheEdges=len(rows),verifiedRecordClaimReferences=claim_records,originalExecutionAttested=False,
        currentAdmission=False,runtimeAdmitted=False,observations=observations)
    path=ctx.directory/'recovery.json';path.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=ctx.publish('observation','research-audit-observation',path))


def observation_mechanism(path, record):
    """Classify recorded evidence, not a filename's native/formal credit."""
    schemas={
        'gambit-native-diagnostic-observation.v1':'native-execution',
        'gambit-stack-write-boundary-observation.v1':'native-execution',
        'gambit-smp.result-bearing-root-progress-observation.v1':'native-execution',
        'gambit-bootstrap-input-drift-observation.v1':'native-execution',
        'gambit-smp.diagnostic-native-observation.v1':'native-execution',
        'gambit-diagnostic-native-observation.v1':'native-execution',
        'gambit-smp.bounded-native-observation.v1':'native-execution',
        'gambit-native-object-source-mapping.v1':'image-mapping',
        'gambit-object-source-mapping.v1':'image-mapping',
        'gambit-smp.selected-section-observation.v1':'conditional-model',
        'gambit-smp.model-composition-observation.v1':'conditional-model',
        'gambit-smp.incident-abi-classification.v1':'conditional-model',
        'gambit-configured-incident-values.v1':'conditional-model',
        'gambit-smp.conditional-frame-composition.v1':'conditional-model',
        'gambit-source-candidate-object-observation.v1':'object-codegen',
        'gambit-codegen-observation.v1':'object-codegen',
        'structure-independent-model-audit.v1':'bounded-model'}
    if record is None and path.endswith('.s'):return 'object-codegen'
    if (path.endswith('cumulative-reapply.json') and isinstance(record,dict)
            and {'files','sourceLockSha256','patchSha256','status'}<=set(record)):
        return 'source-reapply'
    if isinstance(record,dict) and record.get('researchTrack')=='current-repair':
        if any(name.endswith('RepairConsumerInterfaces.lean') for name in record.get('inputs',{})):
            return 'lean-proof'
    if not isinstance(record,dict) or record.get('schema') not in schemas:
        raise ValueError('unknown observation producer schema: '+path)
    return schemas[record['schema']]


def observation_producers(args,ctx):
    """Join original producer links and fresh evidence without replaying patches."""
    from collections import Counter
    from gambit_smp.recipes import read_json,source_path
    from gambit_smp.source_identity import read_git_sources
    from gambit_smp.native_review import pointer
    from gambit_smp.evidence_capabilities import evaluate_observations
    projection=ctx.artifact(args['projection'],'sysml-source-contract')
    cfg=read_json(projection)['values']['ScientificStudies::observationProducers']
    if cfg['plan'] not in ctx.receipt['declaredInputs']:raise ValueError('declared observation plan required')
    ledger_path=source_path(ctx.root,cfg['plan']);ledger=read_json(ledger_path);plan=ledger['observationProducerPlan']
    rows=[r for r in ledger['rows'] if r['producer']['status']=='unresolved' and r['group'] in ('native-result','formal-result')]
    ids=[r['id'] for r in rows]
    if (len(ids)!=cfg['referenceCount'] or ids!=plan['cohortIds']
            or hashlib.sha256(('\n'.join(sorted(ids))+'\n').encode()).hexdigest()!=cfg['cohortSha256']):
        raise ValueError('complete independent50-observation cohort required')
    records=plan['records'];links=plan['links'];ctx.bind([projection,ledger_path]);ctx.remaining()
    entries=list(records.values())+[link for link in links.values() if link['identity'] is not None]
    data=read_git_sources(ctx.root,[e['identity'] for e in entries])
    if any(body is None for body in data):raise EvidenceUnavailable('declared original Git evidence unavailable')
    raw_by_path=dict(zip(records,data[:len(records)]));decoded={}
    for name,raw in raw_by_path.items():
        try:record=json.loads(raw)
        except (ValueError,UnicodeError):record=None
        if observation_mechanism(name,record)!=records[name]['mechanism']:
            raise ValueError('observation mechanism changed')
        decoded[name]=record
    assembly='evidence/codegen/ticket-acquire/ticket_acquire_codegen.s'
    codegen=decoded['evidence/codegen/ticket-acquire/receipt.json']
    if hashlib.sha256(raw_by_path[assembly]).hexdigest()!=codegen['artifact']['sha256']:
        raise ValueError('recorded compiler artifact detached from original receipt')
    link_bodies=iter(data[len(records):]);link_states={}
    for key,link in links.items():
        if link['identity'] is None:link_states[key]='unavailable';continue
        raw=next(link_bodies)
        link_states[key]=('unpinned-declaration' if link['expectedSha256'] is None else
                          'matched' if hashlib.sha256(raw).hexdigest()==link['expectedSha256'] else 'digest-mismatch')
    edge_states=Counter()
    for name,entry in records.items():
        for edge in entry['producerLinks']:
            value=pointer(decoded[name],edge['pointer'])
            link=links[edge['key']]
            expected=link['path']
            if edge.get('receiptCandidate'):
                expected=value if value.endswith('receipt.json') else value.rstrip('/')+'/receipt.json'
            if expected!=link['path'] or not edge.get('receiptCandidate') and value!=link['path']:
                raise ValueError('producer link no longer names the original record')
            edge_states[link_states[edge['key']]]+=1
    source_basis={}
    for name,expected in plan['sourceBasis'].items():
        if name not in ctx.receipt['declaredInputs']:raise ValueError('declared current C23 source required')
        path=source_path(ctx.root,name);ctx.bind([path]);source_basis[name]=sha(path)
        if source_basis[name]!=expected:raise ValueError('current C23 source basis drift')
    if '-std=c23' not in source_path(ctx.root,cfg['c23Configure']).read_text():
        raise ValueError('mandatory C23 source policy absent')
    historical_model=decoded['evidence/model-results/processor-interrupt-collective-wait/structure-independent-audit-01/receipt.json']
    if (plan['formalCommands']!=[stage['argv'][1:] for stage in historical_model['stages']]
            or sha(source_path(ctx.root,plan['formalModel']))!=historical_model['inputs'][plan['formalModel']]):
        raise ValueError('original model semantics, commands or resource limits changed')
    if set(args['observations'])!={*(f'q{i}' for i in range(7)),'lean'}:raise ValueError('complete original formal command family required')
    formal_outputs=[]
    for index,argv in enumerate(plan['formalCommands']):
        ref=args['observations']['q'+str(index)]
        step=next(s for s in ctx.receipt['steps'] if s['id']==ref['step'])
        artifact=ctx.artifact(ref,'quint-observation');observed=read_json(artifact);ctx.bind([artifact])
        if step['arguments']!={'argv':argv} or observed['exhaustive'] is not False:
            raise ValueError('original formal controls, bounds or seed changed')
        if observed['sourceSha256']!=sha(source_path(ctx.root,plan['formalModel'])):
            raise ValueError('formal producer belongs to another model')
        formal_outputs.append(observed)
    if len(re.findall(r'^\s*ok ',formal_outputs[1]['stdout'],re.M))!=cfg['histories']:
        raise ValueError('actual formal histories were not all executed')
    lean_ref=args['observations']['lean'];lean_path=ctx.artifact(lean_ref,'lean-check-observation')
    lean=read_json(lean_path);ctx.bind([lean_path])
    lean_step=next(step for step in ctx.receipt['steps'] if step['id']==lean_ref['step'])
    old_lean=decoded['evidence/model-results/current-repair-consumer-interfaces/lean-return-tail/receipt.json']
    axiom_lines=lambda text:[line.strip() for line in text.splitlines()
        if line.startswith("'GambitSMP.RepairConsumerInterfaces.") and 'axioms' in line]
    axiom_profile=axiom_lines(lean['stdout'])
    if (lean_step['arguments']!={'argv':[plan['leanSource']],'modules':plan['leanModules']}
            or lean.get('compilerCompleted') is not True or lean.get('ambientImportsUsed') is not False
            or lean['sourceSha256']!=old_lean['inputs'][plan['leanSource']]
            or len(lean.get('dependencies',[]))!=len(plan['leanModules'])
            or len(axiom_profile)!=cfg['leanTheorems'] or axiom_profile!=axiom_lines(old_lean['stdout'])):
        raise ValueError('complete unchanged Lean theorem/import closure required')
    for dependency in lean['dependencies']:
        expected=(dependency['identity']['sha256'] if 'identity' in dependency else old_lean['inputs'][dependency['source']])
        if dependency['sourceSha256']!=expected:
            raise ValueError('original Lean imported semantics changed')
    if any(module['identity']['revision']!=plan['leanDependencyRevision'] for module in plan['leanModules'] if 'identity' in module):
        raise ValueError('pinned Lean source library revision changed')
    if source_path(ctx.root,'models/gambit/lean/lean-toolchain').read_text().strip()!=plan['leanToolchain']:
        raise ValueError('declared Lean toolchain changed')
    required=[];observed=[];historical=[];mechanisms=Counter()
    for row in rows:
        entry=records[row['path']];mechanism=entry['mechanism'];mechanisms[mechanism]+=1
        if row['storageResolution']['identity']!=entry['identity']:
            raise ValueError('producer record detached from original reference')
        if mechanism in cfg['nativeMechanisms'].split(';'):
            duty='native-c23';mode='reacquire'
        elif mechanism in ('bounded-model','lean-proof'):
            duty='quint-bounded' if mechanism=='bounded-model' else 'lean-semantic';mode='reacquire'
        else:duty='historical';mode='history'
        required.append([row['id'],duty,mode])
        if mode=='history':historical.append([row['id']])
        if mechanism=='bounded-model':observed.append([row['id'],'quint-bounded','PASS','current','quint-observation'])
        if mechanism=='lean-proof':observed.append([row['id'],'lean-semantic','PASS','current','lean-check-observation'])
    if (mechanisms['native-execution']!=cfg['nativeExecutions'] or mechanisms['object-codegen']!=cfg['objectCodegen']
            or sum(row['group']=='native-result' for row in rows)!=cfg['nativeReferences']):
        raise ValueError('native observation duty population changed')
    controls=[['missing-control','native-c23','reacquire'],['history-control','native-c23','reacquire'],
              ['typecheck-control','quint-bounded','reacquire'],['formal-native-control','native-c23','reacquire'],
              ['source-native-control','native-c23','reacquire'],['lean-import-control','lean-semantic','reacquire']]
    required+=controls
    observed += [['history-control','native-c23','PASS','historical','native-runtime'],
                 ['typecheck-control','quint-bounded','TYPECHECK','current','quint-observation'],
                 ['formal-native-control','native-c23','PASS','current','quint-observation'],
                 ['source-native-control','native-c23','PASS','current','source-contract-observation']]
    facts=dict(producerRequired=required,producerObserved=observed,producerHistory=historical,
               producerKind=[['native-c23','native-runtime'],['quint-bounded','quint-observation'],['lean-semantic','lean-check-observation']])
    answers=evaluate_observations(ctx,[],facts,dict(closed='producerClosed',pending='producerPending',history='producerHistorical'),
        'observation-producers',dsl='tests/recipes/framework-contracts/flow-entry.json')
    if (len(answers['closed'])!=cfg['freshBoundedFormal']+cfg['freshLeanProof'] or len(answers['history'])!=cfg['historicalOnly']
            or len(answers['pending'])!=cfg['currentNativeNeeds']+cfg['leanPending']+len(controls)):
        raise ValueError('producer duty or missing/wrong-scope controls failed')
    result=dict(references=len(rows),records=len(records),nativeReferences=cfg['nativeReferences'],formalReferences=cfg['formalReferences'],mechanisms=dict(mechanisms),
        producerLinks=dict(Counter(link_states.values())),producerLinkEdges=dict(edge_states),sourceBasis=source_basis,
        sourceCensusOnly=True,historicalOnly=len(answers['history']),nativeCurrentPending=cfg['currentNativeNeeds'],formalCurrentQualified=len(answers['closed']),leanCurrentPending=cfg['leanPending'],
        leanTheorems=cfg['leanTheorems'],leanAxiomProfile=axiom_profile,leanSourceDependencies=len(lean['dependencies']),ambientLeanImportsUsed=False,
        histories=cfg['histories'],sampleInitializers=5,samples=100,steps=10,seed=42,negativeControls=len(controls),
        originalExecutionAttested=False,runtimeAdmitted=False,sourceRefinementAdmitted=False)
    path=ctx.directory/'observation-producers.json';path.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=ctx.publish('observation','research-audit-observation',path))


def current_binding_witness(args,ctx):
    """Current typed IR through the existing scientific algorithms and compiler."""
    import copy
    from gambit_smp.recipes import read_json,source_path
    projection=ctx.artifact(args['projection'],'sysml-source-contract')
    cfg=read_json(projection)['values']['ScientificStudies::currentBinding']
    ir_path=ctx.artifact(args['typedIr'],'quint-typed-ir')
    producer=next(row for row in ctx.receipt['steps'] if row['id']==args['typedIr']['step'])
    source=source_path(ctx.root,cfg['source'])
    if producer.get('typedSource')!=cfg['source'] or producer.get('typedSourceSha256')!=sha(source):
        raise EvidenceUnavailable('typed IR source provenance differs from current contract')
    histories_path=ctx.artifact(args['histories'],'quint-observation')
    histories=read_json(histories_path)
    if (histories.get('operation')!='test' or histories.get('source')!=cfg['source']
            or histories.get('sourceSha256')!=sha(source) or histories['stdout'].count('ok ')!=cfg['histories']
            or histories['stdout'].count('ControlTest passed')!=cfg['controls']):
        raise EvidenceUnavailable('current named histories did not all execute')
    lean_sources=[source_path(ctx.root,name) for name in cfg['leanSources'].split(';')]
    if any(str(p.relative_to(ctx.root)) not in ctx.receipt['declaredInputs'] for p in lean_sources):
        raise ValueError('complete maintained Lean dependency closure required')
    ctx.bind([projection,ir_path,source,histories_path,*lean_sources])
    with study_execution(ctx,projection=args['projection'],inputs={'typedIr':args['typedIr']}):
        checker=ctx.library('typed_binding_witness')
        ir=checker.read_json(ir_path.read_text());witness=checker.check(ir)
        if len(witness['references'])!=cfg['referenceCount']:raise ValueError('binding coverage changed')
        controls=[]
        for mutation in ('missing-reference','wrong-target','wrong-stage'):
            bad=copy.deepcopy(ir)
            if mutation=='wrong-stage':bad['stage']='parsing'
            else:
                key=str(witness['references'][0]['occurrence'])
                if mutation=='missing-reference':del bad['table'][key]
                else:bad['table'][key]['id']=-1
            try:checker.check(bad)
            except checker.Refusal:controls.append(mutation)
            else:raise ValueError('binding negative control accepted: '+mutation)
        projector=ctx.library('map_expression_projection')
        lean_text,projection_receipt=projector.generate(ir,sha(source))
        generated=ctx.directory/'work/MapExpressionAst.lean';generated.write_text(lean_text)
        work=generated.parent;env={**ctx.env,'LEAN_PATH':str(work)}
        policy=dict(cap=60,stream='stdout',failure='runtime',failParameter=False,expectedParameter=False)
        for path in lean_sources:
            ctx.command('lean-'+path.stem,['lean','-o',str(work/(path.stem+'.olean')),str(path)],policy=policy,env=env)
        ctx.command('lean-generated',['lean',str(generated)],policy=policy,env=env)
        missing=dict(args['typedIr']);missing['output']='absent'
        try:ctx.artifact(missing,'quint-typed-ir')
        except (KeyError,ValueError):controls.append('missing-artifact')
        else:raise ValueError('missing typed IR accepted')
    ctx.bind([ir_path,source,*lean_sources]);ctx.remaining()
    result=dict(currentBindingChecked=True,source=cfg['source'],sourceSha256=sha(source),
        typedIrSha256=sha(ir_path),generatedLeanSha256=sha(generated),references=len(witness['references']),
        actions=len(projection_receipt['actions']),histories=cfg['histories'],historyNegativeControls=cfg['controls'],negativeControls=controls,
        historicalInputsRead=False,parserProved=False,sourceRefinementAdmitted=False,runtimeAdmitted=False)
    path=ctx.directory/'current-binding.json';path.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=ctx.publish('observation','research-audit-observation',path))


if __name__ == '__main__':
    if len(sys.argv) != 3 or sys.argv[1] != '--cold-check':
        raise SystemExit('Internal source checkout check; use gambit-smp')
    target=Path(sys.argv[2])
    if target.exists():raise SystemExit('Fresh cold-check result required')
    target.write_text(json.dumps(cold_check(Path.cwd()),indent=2)+'\n')
    print('Cold source check completed; evidence availability is reported separately.')


def replay_clue_controls(args, ctx):
    """Consume a completed source audit; replay scientific inference separately."""
    from gambit_smp.recipes import read_json,source_path
    from gambit_smp.evidence_capabilities import evaluate_observations
    prior=ctx.artifact(args['controls'],'research-audit-observation')
    accepted=read_json(prior)
    if not (accepted.get('flowVerified') is True and accepted.get('stdoutCohortVerified') is True
            and accepted.get('runtimeAdmitted') is False):
        raise EvidenceUnavailable('completed source-flow audit required before inference replay')
    projection=ctx.artifact(args['projection'],'sysml-source-contract')
    document=read_json(projection)
    config=document['values']['GambitResearchStorage::audit']
    source=source_path(ctx.root,config['clueControlsInput'])
    if config['clueControlsInput'] not in ctx.receipt['declaredInputs']:
        raise ValueError('clue controls must be declared Recipe inputs')
    ctx.bind([prior,projection,source])
    controls=read_json(source_path(ctx.root,config['clueControlsInput']))
    cases=controls['cases']
    from collections import Counter
    if (controls.get('schema')!='scientific-clue-controls' or
            Counter(row['family'] for row in cases)!=Counter(formal=7,logical=7,reader=7,ownership=6)
            or len({(row['family'],row['case']) for row in cases})!=27):
        raise ValueError('complete four-caller clue controls required')
    replay=[]
    with study_execution(ctx,projection=args['projection']):
        for row in cases:
            if hashlib.sha256(row['selector'].encode()).hexdigest()!=row['selectorSha256']:
                raise ValueError('selected historical clue source changed')
            selector=row['selector'].replace('(include clue-selection-schema)',
                '(relation clue (id digest claim polarity role source)) (relation factor (id digest name value)) (relation binding (name value))')
            answers=evaluate_observations(ctx,[],row['facts'],{key:key for key in row['expected']},
                'clue-'+row['family']+'-'+row['case'],dsl=dict(source=selector,constructor='query',arguments=[]))
            canonical=lambda values: sorted(json.dumps(list(value),sort_keys=True) for value in values)
            if set(answers)!=set(row['expected']) or any(canonical(answers[key])!=canonical(row['expected'][key]) for key in answers):
                raise ValueError('clue inference differs from independent prior result: '+row['case'])
            replay.append([row['family'],row['case']])
    required=[[family+':'+case] for family,case in replay]
    observed=[[row[0],'equal','historical-inference'] for row in required]
    required += [['missing-clue-control'],['wrong-scope-clue-control'],['contradictory-clue-control']]
    observed += [['wrong-scope-clue-control','equal','current-runtime'],
                 ['contradictory-clue-control','equal','historical-inference'],
                 ['contradictory-clue-control','different','historical-inference']]
    clue_join=evaluate_observations(ctx,[],dict(clueRequired=required,clueObserved=observed),
        dict(checked='clueChecked',blocked='clueBlocked'),'clue-admission',dsl=config['flowEntry'])
    if (len(clue_join['checked'])!=27 or {row[0] for row in clue_join['blocked']}!=
            {'missing-clue-control','wrong-scope-clue-control','contradictory-clue-control'}):
        raise ValueError('clue scope/missing/conflict refusal failed')
    result=dict(clueReplayVerified=True,clueControls=replay,clueAdmission=clue_join,
        scope='historical-inference-equivalence-not-current-study-admission',
        wholeStudyAdmitted=False,runtimeAdmitted=False)
    output=ctx.directory/'clue-controls.json';output.write_text(json.dumps(result,indent=2)+'\n')
    return dict(result,outputs=ctx.publish('observation','research-audit-observation',output))
