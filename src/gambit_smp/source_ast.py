"""Source-bound Python syntax facts for the existing Evidence engine.

No execution loop, policy, call-graph completeness or control-flow proof lives
here. Only unshadowed module definitions/imports resolve lexically. Attribute
dispatch, rebound names and dynamic calls remain explicit unresolved facts.
"""
import ast
import hashlib
import json


def extract(path, data, *, module, expected_sha256):
    digest = hashlib.sha256(data).hexdigest()
    if digest != expected_sha256:
        raise ValueError("AST source digest mismatch: " + path)
    tree = ast.parse(data, filename=path)
    result = dict(ast_source=[[path, digest]], ast_function=[], ast_call=[], ast_keyword=[])
    scopes = []

    def bindings(body, prefix):
        definitions, assigned, seen = {}, set(), set()

        def define(name, target, *, same_import=False):
            if name in seen and not (same_import and definitions.get(name) == target):
                assigned.add(name)
            seen.add(name)
            definitions[name] = target

        class Bindings(ast.NodeVisitor):
            def visit_FunctionDef(self, node):
                define(node.name, prefix + '.' + node.name)

            visit_AsyncFunctionDef = visit_FunctionDef

            def visit_ClassDef(self, node):
                assigned.add(node.name)

            def visit_Name(self, node):
                if isinstance(node.ctx, (ast.Store, ast.Del)):
                    assigned.add(node.id)

            def visit_Import(self, node):
                for item in node.names:
                    define(item.asname or item.name.split('.')[0], item.name if item.asname else item.name.split('.')[0], same_import=True)

            def visit_ImportFrom(self, node):
                for item in node.names:
                    if node.level or item.name == '*':
                        assigned.add(item.asname or item.name)
                    else:
                        define(item.asname or item.name, (node.module or '') + '.' + item.name, same_import=True)

            def visit_ExceptHandler(self, node):
                if node.name:
                    assigned.add(node.name)
                self.generic_visit(node)

            def visit_MatchAs(self, node):
                if node.name:
                    assigned.add(node.name)
                self.generic_visit(node)

            visit_MatchStar = visit_MatchAs

            def visit_MatchMapping(self, node):
                if node.rest:
                    assigned.add(node.rest)
                self.generic_visit(node)

            # Comprehension targets are in their own scope. Conservatively
            # refuse lexical resolution throughout that expression instead.
            def visit_Lambda(self, node):
                pass

        visitor = Bindings()
        for node in body:
            visitor.visit(node)
        return {name: value for name, value in definitions.items() if name not in assigned}, assigned

    def resolve(node):
        if isinstance(node, ast.Name):
            for known, blocked in reversed(scopes):
                if '*' in blocked or node.id in blocked:
                    return None
                if node.id in known:
                    return known[node.id]
        if isinstance(node, ast.Attribute):
            base = resolve(node.value)
            if base is not None:
                return base + '.' + node.attr
        return None

    class Facts(ast.NodeVisitor):
        owner = module
        expression_scope = 0

        def visit_FunctionDef(self, node):
            previous = self.owner
            previous_expression_scope = self.expression_scope
            owner = previous + '.' + node.name
            result['ast_function'].append([path, owner, node.lineno, node.end_lineno])
            # Defaults/decorators execute in the enclosing scope.
            for expr in [*node.decorator_list, *node.args.defaults,
                         *(value for value in node.args.kw_defaults if value is not None)]:
                self.visit(expr)
            known, blocked = bindings(node.body, owner)
            args = [*node.args.posonlyargs, *node.args.args, *node.args.kwonlyargs]
            args += [arg for arg in (node.args.vararg, node.args.kwarg) if arg is not None]
            blocked.update(arg.arg for arg in args)
            # global/nonlocal bindings need control-flow/name analysis beyond
            # this extractor; never infer their targets.
            for child in ast.walk(node):
                if isinstance(child, (ast.Global, ast.Nonlocal)):
                    blocked.update(child.names)
            scopes.append((known, blocked))
            self.owner = owner
            # A method's defaults/decorators execute in the class body, but
            # its function body has ordinary lexical scope. Class attributes
            # are not an enclosing scope for names used inside that body.
            self.expression_scope = 0
            for child in node.body:
                self.visit(child)
            self.expression_scope = previous_expression_scope
            self.owner = previous
            scopes.pop()

        visit_AsyncFunctionDef = visit_FunctionDef

        def visit_ClassDef(self, node):
            # Class bodies/method lookup have different binding rules.
            previous = self.owner
            self.owner = previous + '.' + node.name
            self.expression_scope += 1
            self.generic_visit(node)
            self.expression_scope -= 1
            self.owner = previous

        def visit_Lambda(self, node):
            self.expression_scope += 1
            self.generic_visit(node)
            self.expression_scope -= 1

        visit_ListComp = visit_Lambda
        visit_SetComp = visit_Lambda
        visit_DictComp = visit_Lambda
        visit_GeneratorExp = visit_Lambda

        def visit_Call(self, node):
            target = None if self.expression_scope else resolve(node.func)
            spelling = ast.unparse(node.func)
            site = f'{path}:{node.lineno}:{node.col_offset}'
            result['ast_call'].append([path, self.owner, site, target or spelling,
                                       'lexical' if target else 'unresolved', node.lineno])
            for keyword in node.keywords:
                result['ast_keyword'].append([site, keyword.arg or '**',
                    ast.dump(keyword.value, annotate_fields=True, include_attributes=False)])
            self.generic_visit(node)

    scopes.append(bindings(tree.body, module))
    Facts().visit(tree)
    return result


def combine(sources):
    """Each input is (repository path, immutable bytes, import name)."""
    result = dict(ast_source=[], ast_function=[], ast_call=[], ast_keyword=[])
    for path, data, module in sources:
        facts = extract(path, data, module=module,
                        expected_sha256=hashlib.sha256(data).hexdigest())
        for key, rows in facts.items():
            result[key].extend(rows)
    if len({row[0] for row in result['ast_source']}) != len(result['ast_source']):
        raise ValueError('duplicate AST source path')
    return result


def project(sources, owners):
    """Select declared function scopes, retaining unresolved dispatch in them."""
    result = combine(sources)
    result['ast_function'] = [row for row in result['ast_function'] if row[1] in owners]
    result['ast_call'] = [row for row in result['ast_call'] if row[1] in owners]
    sites = {row[2] for row in result['ast_call']}
    result['ast_keyword'] = [row for row in result['ast_keyword'] if row[0] in sites]
    return result


def view(root, contract):
    """Produce an ordinary Evidence view using existing source journal custody.

    The caller owns the reviewed obligation list. AST facts are computed, never
    accepted from that list. Live references and immutable journal references
    are both required, so an old snapshot cannot qualify a changed checkout.
    This function neither registers a view nor grants execution authority.
    """
    from gambit_smp.recipes import source_path
    from gambit_smp.source_identity import retain_sources
    sources = [(row['path'], source_path(root, row['path']).read_bytes(), row['module'])
               for row in contract['sources']]
    facts = project(sources, set(contract['owners']))
    identities = retain_sources(root, {path: data for path, data, _ in sources})
    references = []
    facts['source_binding'] = []
    for path, digest in facts['ast_source']:
        pinned, live = 'snapshot:' + path, 'checkout:' + path
        facts['source_binding'].append([path, pinned, live])
        references += [dict(id=pinned, path=path, sha256=digest, pointer=None, identity=identities[path]),
                       dict(id=live, path=path, sha256=digest, pointer=None)]
    facts.update(reference={'references': True}, required_call=contract['required_call'],
                 component=contract['component'], obligation=contract['obligation'],
                 required_receipt=contract['required_receipt'], observed_receipt=[],
                 dispatch_binding=contract.get('dispatch_binding',[]),execution_edge=[])
    return dict(schema='ascent.evidence-view.v1', id=contract['id'],
        manifest='evidence/scenarios/darwin-acceleration/components.json',
        entry='source-chain', constructor='make-darwin-source-chain', facts=facts,
        queries={name: name for name in ('source_current', 'matched_call', 'missing_call',
            'unresolved_call', 'unclosed', 'observed_call', 'clue', 'factor', 'link', 'inventory')},
        references=references)


def recorded_dispatches(data):
    """Read actual Python entry observations from checked terminal receipts.

    Missing fields in historical receipts produce no dispatch witness. Source
    and engine correspondence is checked independently by native Evidence.
    """
    recorded_products(data)
    rows=[]
    for product in json.loads(data)['products'].values():
        receipt=json.loads(product['receiptBytes'])
        edge=receipt.get('dispatch')
        if edge is None:
            continue
        if (set(edge)!={'caller','callee','callerSha256','calleeSha256','callerLine'}
                or type(edge['callerLine']) is not int or edge['callerLine']<=0
                or any(type(edge[k]) is not str or not edge[k] for k in ('caller','callee'))
                or any(len(edge[k])!=64 or any(ch not in '0123456789abcdef' for ch in edge[k])
                       for k in ('callerSha256','calleeSha256'))):
            raise ValueError('incomplete Python dispatch observation')
        rows.append([edge['caller'],edge['callee'],edge['callerSha256'],edge['calleeSha256'],
                     receipt['stage'],product['receiptSha256']])
    return rows


def recorded_products(data):
    """Import embedded terminal process receipts, not current output readiness.

    Later phases can change the same output paths. An earlier manifest is
    historical product evidence, never authority to reuse those paths now.
    Returns transport facts only; process authenticity remains the supervisor
    journal's boundary. A caller must retain and bind these exact ledger bytes.
    """
    ledger = json.loads(data)
    if ledger.get('schema') != 'gerbil-ci-stage-products':
        raise ValueError('stage product ledger required')
    key = ledger['inputsSha256']
    rows = []
    for phase, product in ledger['products'].items():
        raw = product['receiptBytes'].encode()
        sha = hashlib.sha256(raw).hexdigest()
        receipt = json.loads(raw)
        command = ledger['completed'].get(phase)
        if (sha != product['receiptSha256'] or product['inputsSha256'] != key
                or not product['outputs'] or command != product['command']
                or not isinstance(command, dict)
                or any(receipt.get(k) != v for k, v in command.items())
                or receipt.get('schema') != 'recipe-process-observation.v1'
                or receipt.get('stage') != 'gerbil-' + phase
                or receipt.get('state') != 'OBSERVED'
                or receipt.get('completionObserved') is not True
                or type(receipt.get('exit')) is not int or receipt['exit'] != 0
                or receipt.get('timeout') is not False
                or receipt.get('parentReaped') is not True
                or receipt.get('processGroupQuiescent') is not True):
            raise ValueError('unbound or nonterminal stage product: ' + phase)
        rows.append([phase, sha, key])
    return rows


def audit(values, sources, ctx):
    """Existing source.contract executor; no independent runner or subprocess."""
    from gambit_smp.evidence_capabilities import evaluate_observations
    contract = json.loads(sources[values['astContract']])
    expected = {row['path'] for row in contract['sources']} | {
        values['astContract'], values['evidenceEntry'], values['evidenceSource'],
        'src/gambit_smp/source_ast.py'}
    if set(sources) != expected:
        raise ValueError('exact AST source and extractor inventory required')
    document = view(ctx.root, contract)
    if any(dict(document['facts']['ast_source'])[row['path']] !=
           hashlib.sha256(sources[row['path']]).hexdigest() for row in contract['sources']):
        raise ValueError('AST view differs from bound source contract')
    # Pass the native engine the already checked snapshot/live byte facts.
    facts = dict(document['facts'])
    facts['reference'] = [[ref['id'], ref['path'], ref['sha256']] for ref in document['references']]
    answers = evaluate_observations(ctx, [], facts, document['queries'],
        'python-ast-evidence', dsl=values['evidenceEntry'])
    return dict(view=document, answers=answers,
        astBoundary='Syntactic lexical binding only; unresolved dynamic dispatch retained',
        runtimeAdmitted=False, packageSpeedup=None)
