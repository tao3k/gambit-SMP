"""Strict parser for scalar/tuple/record and finite integer-set TLC values."""
import json
import re

TOKEN = re.compile(r'\s*("(?:[^"\\\x00-\x1f]|\\["\\/bfnrt]|\\u[0-9a-fA-F]{4})*"|\|->|<<|>>|\.\.|\[|\]|\{|\}|,|TRUE\b|FALSE\b|-?\d+\b|[A-Za-z_]\w*)')


def shape(data):
    if isinstance(data, dict):
        if set(data) in ({"$integerSet"}, {"$integerRange"}):
            return ("integer-set",)
        return tuple((key, shape(item)) for key, item in sorted(data.items()))
    if isinstance(data, list):
        return (list, tuple(shape(item) for item in data))
    return type(data)


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
        if token == "{":
            members = []
            if cursor < len(tokens) and tokens[cursor] == "}":
                take("}")
                return {"$integerSet": members}
            while True:
                member = take()
                if not re.fullmatch(r"-?\d+", member) or int(member) in members:
                    raise ValueError("invalid or duplicate integer-set member")
                members.append(int(member))
                separator = take()
                if separator == "}":
                    return {"$integerSet": sorted(members)}
                if separator != ",":
                    raise ValueError("malformed integer-set separator")
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
