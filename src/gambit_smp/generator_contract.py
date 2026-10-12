"""Fail-closed Cartesian-generator conformance audit over public Quint IR.

This is a small syntactic proof rule, not a general solver. Its trusted rule is
that independent oneOf(D_i) choices cover the Cartesian product of the D_i.
The initializer's pure filters must be identical to the invariant's filters.
"""
import json


def app(opcode, *args):
    return {"kind": "app", "opcode": opcode, "args": list(args)}


def name(value):
    return {"kind": "name", "name": value}


def canonical(node, substitutions=None):
    substitutions = substitutions or {}
    kind = node["kind"]
    if kind == "name":
        return name(substitutions.get(node["name"], node["name"]))
    if kind in ("str", "int", "bool"):
        return {"kind": kind, "value": node["value"]}
    if kind == "app":
        return app(node["opcode"], *(canonical(arg, substitutions) for arg in node["args"]))
    raise ValueError("unsupported generator expression: " + kind)


def conjuncts(node):
    if node.get("kind") == "app" and node.get("opcode") in ("and", "actionAll"):
        return [item for arg in node["args"] for item in conjuncts(arg)]
    return [node]


def signatures(nodes):
    result = [json.dumps(canonical(node), sort_keys=True) for node in nodes]
    if len(set(result)) != len(result):
        raise ValueError("duplicate predicate in generator contract")
    return sorted(result)


def audit(ir, module, initializer, invariant, *, state="s", state_type="State", shape="shape"):
    if ir.get("stage") != "parsing" or ir.get("errors"):
        raise ValueError("successful public Quint parse required")
    modules = [item for item in ir["modules"] if item["name"] == module]
    if len(modules) != 1:
        raise ValueError("one exact proof module required")
    declarations = {item["name"]: item for item in modules[0]["declarations"] if "name" in item}
    global_declarations = {}
    for item in ir["modules"]:
        for declaration in item["declarations"]:
            if "name" in declaration:
                global_declarations.setdefault(declaration["name"], []).append(declaration)

    def unique(identifier):
        matches = global_declarations.get(identifier, [])
        if len(matches) != 1:
            raise ValueError("ambiguous or missing declaration: " + identifier)
        return matches[0]

    def finite_domain(node, resolving=()):
        kind, opcode = node["kind"], node.get("opcode")
        if kind == "name":
            identifier = node["name"]
            declaration = unique(identifier)
            if identifier in resolving or declaration.get("qualifier") != "pureval":
                raise ValueError("domain must be closed and independent: " + identifier)
            finite_domain(declaration["expr"], resolving + (identifier,))
        elif kind == "app" and opcode == "Set":
            if not node["args"] or any(arg["kind"] not in ("str", "int", "bool") for arg in node["args"]):
                raise ValueError("finite literal domain required")
        elif kind == "app" and opcode == "to":
            def integer(arg):
                if arg["kind"] == "int":
                    return arg["value"]
                if arg.get("opcode") == "iuminus" and len(arg["args"]) == 1 and arg["args"][0]["kind"] == "int":
                    return -arg["args"][0]["value"]
                raise ValueError("literal integer bounds required")
            if len(node["args"]) != 2 or integer(node["args"][0]) > integer(node["args"][1]):
                raise ValueError("nonempty integer range required")
        elif kind == "app" and opcode in ("setOfMaps", "powerset"):
            if len(node["args"]) != (2 if opcode == "setOfMaps" else 1):
                raise ValueError("invalid finite domain arity")
            for arg in node["args"]:
                finite_domain(arg, resolving)
        else:
            raise ValueError("unsupported finite domain")

    action = declarations[initializer]
    if action.get("qualifier") != "action":
        raise ValueError("action initializer required")
    node, choices = action["expr"], {}
    while node.get("kind") == "let" and node["opdef"].get("qualifier") == "nondet":
        binding = node["opdef"]
        expr = binding["expr"]
        if binding["name"] in choices or expr.get("opcode") != "oneOf" or len(expr["args"]) != 1:
            raise ValueError("independent oneOf choices required")
        domain = canonical(expr["args"][0])
        finite_domain(domain)
        choices[binding["name"]] = domain
        node = node["expr"]
    if node.get("kind") != "let" or node["opdef"].get("qualifier") != "val":
        raise ValueError("one candidate record required")
    candidate = node["opdef"]
    record = candidate["expr"]
    if record.get("opcode") != "Rec" or len(record["args"]) % 2:
        raise ValueError("literal candidate record required")
    expected, fields, used = [], [], []
    for key, value in zip(record["args"][::2], record["args"][1::2]):
        if key["kind"] != "str" or key["value"] in fields:
            raise ValueError("distinct literal record fields required")
        fields.append(key["value"])
        field = app("field", name(state), canonical(key))
        if value["kind"] == "name" and value["name"] in choices:
            used.append(value["name"])
            expected.append(app("in", field, choices[value["name"]]))
        elif value["kind"] in ("str", "int", "bool"):
            expected.append(app("eq", field, canonical(value)))
        else:
            raise ValueError("record field must be an independent choice or literal")
    if len(used) != len(set(used)) or set(used) != set(choices):
        raise ValueError("choice-to-field correspondence must be bijective")
    state_definition = unique(state_type)["type"]
    variable = unique(state)
    if variable.get("kind") != "var" or variable.get("typeAnnotation", {}).get("name") != state_type:
        raise ValueError("state variable must use the audited record type")
    if (state_definition["kind"] != "rec" or state_definition["fields"]["other"]["kind"] != "empty" or
            set(fields) != {item["fieldName"] for item in state_definition["fields"]["fields"]}):
        raise ValueError("candidate must cover the entire closed state record")
    if signatures(conjuncts(declarations[shape]["expr"])) != signatures(expected):
        raise ValueError("generated domains differ from invariant shape")
    tail = conjuncts(node["expr"])
    assignments = [item for item in tail if item.get("opcode") == "assign"]
    if len(assignments) != 1 or canonical(assignments[0]) != app("assign", name(state), name(candidate["name"])):
        raise ValueError("exactly one whole-record assignment required")
    filters = [item for item in tail if item.get("opcode") != "assign"]
    for predicate in filters:
        if (predicate.get("kind") != "app" or
                unique(predicate["opcode"]).get("qualifier") != "puredef" or
                [canonical(arg) for arg in predicate["args"]] != [name(candidate["name"])]):
            raise ValueError("pure candidate-only filters required")
    invariant_parts = conjuncts(declarations[invariant]["expr"])
    shape_parts = [item for item in invariant_parts if canonical(item) == name(shape)]
    invariant_filters = [item for item in invariant_parts if canonical(item) != name(shape)]
    translated = [canonical(item, {candidate["name"]: state}) for item in filters]
    if len(shape_parts) != 1 or signatures(invariant_filters) != signatures(translated):
        raise ValueError("initializer and invariant filters differ")
    return {"schema": "quint-cartesian-generator-contract.v1", "contractVerified": True,
            "stateFields": fields, "independentChoices": len(choices),
            "trustedRule": "independent-finite-cartesian-choices-and-identical-pure-filters",
            "solverCoverageProved": False, "runtimeAdmitted": False}
