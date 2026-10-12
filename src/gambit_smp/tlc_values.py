"""Strict TLC values, scalar sets and nonempty integer-keyed function maps."""
import json
import re

TOKEN = re.compile(r'\s*("(?:[^"\\\x00-\x1f]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*"|\|->|:>|@@|<<|>>|\.\.|\(|\)|\[|\]|\{|\}|,|TRUE\b|FALSE\b|-?\d+\b|[A-Za-z_]\w*)')


def shape(data):
    if isinstance(data, dict):
        if set(data) == {"$integerMap"}:
            entries = data["$integerMap"]
            item_shape = shape(entries[0][1])
            for _, item in entries[1:]:
                item_shape = merge_shapes(item_shape, shape(item))
            return ("map", int, item_shape)
        if set(data) == {"$integerRange"}:
            return ("set", int)
        if set(data) in ({"$integerSet"}, {"$stringSet"}):
            members = next(iter(data.values()))
            return ("set", type(members[0]) if members else None)
        return tuple((key, shape(item)) for key, item in sorted(data.items()))
    if isinstance(data, list):
        return (list, tuple(shape(item) for item in data))
    return type(data)


def merge_shapes(left, right):
    """Infer an empty set's element type without forgetting earlier states."""
    if left == right:
        return left
    if isinstance(left, tuple) and isinstance(right, tuple) and len(left) == len(right):
        if len(left) == 2 and left[0] == right[0] == "set":
            if left[1] is None:
                return right
            if right[1] is None:
                return left
        return tuple(merge_shapes(a, b) for a, b in zip(left, right))
    raise ValueError("inconsistent TLC state types")


def value(text):
    tokens = []
    position = 0
    while text[position:].strip():
        match = TOKEN.match(text, position)
        if match is None:
            raise ValueError("unsupported TLC value token")
        tokens.append(match.group(1))
        position = match.end()
    cursor = 0

    def take(expected=None):
        nonlocal cursor
        if cursor >= len(tokens) or (expected is not None and tokens[cursor] != expected):
            raise ValueError("truncated or malformed TLC value")
        token = tokens[cursor]
        cursor += 1
        return token

    def parse():
        token = take()
        if token.startswith('"'):
            return json.loads(token)
        if token in ("TRUE", "FALSE"):
            return token == "TRUE"
        if re.fullmatch(r"-?\d+", token):
            if cursor < len(tokens) and tokens[cursor] == "..":
                take("..")
                end = take()
                if not re.fullmatch(r"-?\d+", end):
                    raise ValueError("integer interval requires integer endpoints")
                # Preserve compact range syntax, without allocating its members.
                return {"$integerRange": [int(token), int(end)]}
            return int(token)
        if token == "(":
            entries = {}
            while True:
                key = take()
                if not re.fullmatch(r"-?\d+", key) or int(key) in entries:
                    raise ValueError("invalid or duplicate integer map key")
                take(":>")
                entries[int(key)] = parse()
                separator = take()
                if separator == ")":
                    result = {"$integerMap": sorted(entries.items())}
                    shape(result)  # Reject heterogeneous values, including nested ones.
                    return result
                if separator != "@@":
                    raise ValueError("malformed integer map separator")
        if token == "{":
            members = []
            if cursor < len(tokens) and tokens[cursor] == "}":
                take("}")
                return {"$integerSet": members}
            while True:
                token = take()
                if token.startswith('"'):
                    member = json.loads(token)
                elif re.fullmatch(r"-?\d+", token):
                    member = int(token)
                else:
                    raise ValueError("unsupported scalar-set member")
                if member in members or (members and type(member) is not type(members[0])):
                    raise ValueError("duplicate or mixed-type set member")
                members.append(member)
                separator = take()
                if separator == "}":
                    tag = "$integerSet" if type(member) is int else "$stringSet"
                    return {tag: sorted(members)}
                if separator != ",":
                    raise ValueError("malformed scalar-set separator")
        if token not in ("[", "<<"):
            raise ValueError("unsupported TLC value")
        close = "]" if token == "[" else ">>"
        result = {} if token == "[" else []
        if cursor < len(tokens) and tokens[cursor] == close:
            take(close)
            return result
        while True:
            if token == "[":
                key = take()
                if not re.fullmatch(r"[A-Za-z_]\w*", key) or key in result:
                    raise ValueError("invalid or duplicate TLC record field")
                take("|->")
                result[key] = parse()
            else:
                result.append(parse())
            separator = take()
            if separator == close:
                return result
            if separator != ",":
                raise ValueError("malformed TLC value separator")

    result = parse()
    if cursor != len(tokens):
        raise ValueError("trailing TLC value data")
    return result
