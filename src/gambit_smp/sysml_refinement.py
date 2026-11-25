"""Typed source arguments and their premises; not another temporal model.

Arguments are authored source reviews, never automatically verified by locating
anchors. They consume existing adapter clauses rather than inventing parallel
Quint/Lean obligations or a second source-attestation protocol.
"""


def validate_cases(flow):
    clauses = {row['id']:row for row in flow.get('adapterClauses',[])}
    adapters = {row['id']:row for row in flow.get('adapters',[])}
    sites = {row['id']:row for row in flow.get('sourceSites',[])}
    cases = {}
    for row in flow.get('sourceCases',[]):
        if any(not isinstance(row.get(field),str) or not row[field] for field in
               ('id','precondition','argument','conclusion','missing','acceptance','formalBoundary','counterexample')):
            raise ValueError('complete guarded source argument required')
        if row['id'] in cases or row.get('clause') not in clauses:
            raise ValueError('unique source case and existing adapter clause required')
        adapter = adapters[clauses[row['clause']]['adapter']]
        for field in ('entrySite','exitSite'):
            site = sites.get(row.get(field))
            if not site or site['question'] != adapter['question']:
                raise ValueError('source argument endpoints must belong to its adapter')
        cases[row['id']] = row
    graph = {key:set() for key in cases}
    for edge in flow.get('caseDependencies',[]):
        a,b = edge.get('dependent'),edge.get('prerequisite')
        if a not in cases or b not in cases or b in graph[a]:
            raise ValueError('actual nonduplicate source premise endpoints required')
        if not isinstance(edge.get('condition'),str) or not edge['condition']:
            raise ValueError('source handoff needs an explicit premise')
        # Cross-adapter dependencies already have a separately owned question graph.
        if clauses[cases[a]['clause']]['adapter'] != clauses[cases[b]['clause']]['adapter']:
            raise ValueError('source cases cannot bypass adapter responsibility boundaries')
        graph[a].add(b)
    done,pending = set(),set()
    def visit(key):
        if key in pending:
            raise ValueError('cyclic source refinement premises')
        if key in done:
            return
        pending.add(key)
        for prerequisite in graph[key]:
            visit(prerequisite)
        pending.remove(key);done.add(key)
    for key in graph:
        visit(key)
