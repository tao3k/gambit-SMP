"""Conservative definedness predicates for the reviewed Quint IR fragment.

This is a narrow syntactic rule, not a trusted general-purpose theorem prover.
Unsupported operations fail closed. Its generated predicates need typechecking,
source correspondence review and real checker controls before admission.
"""
import json

from gambit_smp.generator_contract import app, name
from gambit_smp.guard_projection import normalized, free_names, project

TRUE = {"kind": "bool", "value": True}
FALSE = {"kind": "bool", "value": False}


def safe_all(expressions):
    expressions = [node for node in expressions if node != TRUE]
    result = TRUE
    for node in reversed(expressions):
        result = node if result == TRUE else app("ite", node, result, FALSE)
    return result


class Definedness:
    def __init__(self, declarations):
        self.declarations = declarations
        self.serial = 0
        self.partial_operations = set()

    def substitute(self, node, replacements):
        """Capture-avoiding substitution, including helper lambda/let binders."""
        kind = node["kind"]
        if kind == "name":
            return normalized(replacements.get(node["name"], node))
        if kind in ("bool", "int", "str"):
            return normalized(node)
        if kind == "app":
            return app(node["opcode"], *(self.substitute(arg, replacements) for arg in node["args"]))
        if kind in ("lambda", "let"):
            parameters = node["params"] if kind == "lambda" else [node["opdef"]]
            updated = dict(replacements)
            names = []
            forbidden = free_names(node) | set(replacements)
            for value in replacements.values():
                forbidden |= free_names(value)
            for parameter in parameters:
                while True:
                    self.serial += 1
                    fresh = "__defined" + str(self.serial)
                    if fresh not in forbidden:
                        break
                names.append(fresh)
                forbidden.add(fresh)
                updated[parameter["name"]] = name(fresh)
            if kind == "lambda":
                return {"kind": "lambda", "qualifier": node["qualifier"],
                        "params": [{"name": fresh} for fresh in names],
                        "expr": self.substitute(node["expr"], updated)}
            binding = normalized(node["opdef"])
            binding.update(name=names[0], expr=self.substitute(binding["expr"], replacements))
            return {"kind": "let", "opdef": binding, "expr": self.substitute(node["expr"], updated)}
        raise ValueError("unsupported substitution expression: " + kind)

    def defined(self, node, bound=frozenset(), resolving=()):
        kind = node["kind"]
        if kind in ("bool", "int", "str"):
            return TRUE
        if kind == "name":
            identifier = node["name"]
            if identifier in bound:
                return TRUE
            declaration = self.declarations.get(identifier)
            if declaration is None:
                raise ValueError("unresolved definedness name: " + identifier)
            if declaration.get("kind") == "var":
                return TRUE
            if identifier in resolving or declaration.get("qualifier") not in ("val", "pureval"):
                raise ValueError("unsupported definedness value: " + identifier)
            return self.defined(declaration["expr"], bound, resolving + (identifier,))
        if kind == "let":
            binding = node["opdef"]
            if binding.get("qualifier") not in ("val", "pureval"):
                raise ValueError("unsupported definedness binding")
            body = self.defined(node["expr"], bound | {binding["name"]}, resolving)
            scoped = {"kind": "let", "opdef": normalized(binding), "expr": body}
            return safe_all([self.defined(binding["expr"], bound, resolving), scoped])
        if kind != "app":
            raise ValueError("unsupported definedness expression: " + kind)
        opcode, args = node["opcode"], node["args"]
        declaration = self.declarations.get(opcode)
        if declaration is not None:
            if opcode in resolving or declaration.get("qualifier") not in ("def", "puredef"):
                raise ValueError("unsupported definedness operator: " + opcode)
            function = declaration["expr"]
            if function.get("kind") != "lambda" or len(function["params"]) != len(args):
                raise ValueError("exact helper lambda application required")
            body = self.substitute(function["expr"],
                {param["name"]: arg for param, arg in zip(function["params"], args)})
            return safe_all([*(self.defined(arg, bound, resolving) for arg in args),
                self.defined(body, bound, resolving + (opcode,))])
        if opcode in ("filter", "forall", "exists", "mapBy"):
            if len(args) != 2 or args[1].get("kind") != "lambda" or len(args[1]["params"]) != 1:
                raise ValueError("one explicit collection lambda required")
            function = normalized(args[1])
            function["expr"] = self.defined(function["expr"],
                bound | {function["params"][0]["name"]}, resolving)
            return safe_all([self.defined(args[0], bound, resolving),
                             app("forall", normalized(args[0]), function)])
        if opcode == "ite":
            if len(args) != 3:
                raise ValueError("conditional arity differs")
            return safe_all([self.defined(args[0], bound, resolving), app("ite", normalized(args[0]),
                self.defined(args[1], bound, resolving), self.defined(args[2], bound, resolving))])
        operands = [self.defined(arg, bound, resolving) for arg in args]
        if opcode in ("get", "set"):
            if len(args) != (2 if opcode == "get" else 3):
                raise ValueError("map operation arity differs")
            self.partial_operations.add(opcode)
            return safe_all([*operands, app("contains", app("keys", normalized(args[0])), normalized(args[1]))])
        if opcode == "nth":
            if len(args) != 2:
                raise ValueError("list access arity differs")
            self.partial_operations.add(opcode)
            return safe_all([*operands, app("igte", normalized(args[1]), {"kind": "int", "value": 0}),
                app("ilt", normalized(args[1]), app("length", normalized(args[0])))])
        if opcode == "Map":
            keys = []
            for pair in args:
                if (pair.get("opcode") != "Tup" or len(pair["args"]) != 2 or
                        pair["args"][0]["kind"] not in ("bool", "int", "str")):
                    raise ValueError("only closed distinct literal Map keys supported")
                keys.append(json.dumps(normalized(pair["args"][0]), sort_keys=True))
            if len(keys) != len(set(keys)):
                raise ValueError("duplicate literal Map keys")
        elif opcode not in ("Set", "List", "Tup", "Rec", "field", "with", "eq", "neq", "not",
                "and", "or", "implies", "contains", "union", "exclude", "size", "iadd", "isub",
                "iuminus", "igt", "igte", "ilt", "ilte"):
            raise ValueError("unsupported definedness builtin: " + opcode)
        return safe_all(operands)

    def action(self, expression):
        project(expression)  # Require exactly one unchanged whole-state assignment.

        def walk(node, bound=frozenset()):
            if node.get("kind") == "let":
                binding = node["opdef"]
                body = walk(node["expr"], bound | {binding["name"]})
                if binding["qualifier"] == "nondet":
                    domain = binding["expr"]["args"][0]
                    return safe_all([self.defined(domain, bound), app("exists", normalized(domain), {
                        "kind": "lambda", "qualifier": "def", "params": [{"name": binding["name"]}],
                        "expr": body})])
                scoped = {"kind": "let", "opdef": normalized(binding), "expr": body}
                return safe_all([self.defined(binding["expr"], bound), scoped])
            if node.get("opcode") == "actionAll":
                return safe_all([walk(arg, bound) for arg in node["args"]])
            if node.get("opcode") == "assign":
                return self.defined(node["args"][1], bound)
            return safe_all([self.defined(node, bound), normalized(node)])

        return walk(expression)


def sufficient_projections(ir, actions, module="gc_recursive_queue_wait"):
    declarations = {item["name"]: item for item in next(
        item for item in ir["modules"] if item["name"] == module)["declarations"] if "name" in item}
    checker = Definedness(declarations)
    expressions = {action: checker.action(declarations[action]["expr"]) for action in actions}
    return expressions, sorted(checker.partial_operations)
