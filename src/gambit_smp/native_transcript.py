"""Decode a bounded flat-event protocol; Evidence rules decide conformance."""
import json
import re
import shlex

from gambit_smp.recipes import fields, source_path


def project(contract, output, population):
    fields(contract, ("schema", "segments"))
    if contract["schema"] != "flat-event-transcript.v1" or type(population) is not int or not 1 <= population <= 4096:
        raise ValueError("bounded flat-event transcript and population required")
    allowed = []
    index = 0
    for segment in contract["segments"]:
        fields(segment, ("repeat", "rows"))
        repeat = population if segment["repeat"] == "execution-processors" else segment["repeat"]
        if type(repeat) is not int or not 1 <= repeat <= 4096 or not segment["rows"]:
            raise ValueError("bounded positive transcript repetition required")
        for _ in range(repeat):
            for row in segment["rows"]:
                if not isinstance(row, list) or not 1 <= len(row) <= 32 or index >= 4096:
                    raise ValueError("bounded nonempty transcript row required")
                for column, spec in enumerate(row):
                    if isinstance(spec, str):
                        values = [spec]
                    elif spec == {"parameter": "execution-processors"}:
                        values = [str(population)]
                    elif spec == {"integers": "processor-ids"}:
                        values = list(map(str, range(population)))
                    else:
                        raise ValueError("literal or declared processor parameter required")
                    if any(not re.fullmatch(r"[^\s()\"'\\]+", value) for value in values):
                        raise ValueError("flat literal token required")
                    allowed.extend([index, column, value] for value in values)
                index += 1
    actual = []
    lines = output.splitlines()
    if not output.endswith("\n") or not 1 <= len(lines) <= 4096:
        raise ValueError("complete bounded newline-delimited transcript required")
    for index, line in enumerate(lines):
        if line.startswith("(") and line.endswith(")"):
            line = line[1:-1]
        if not line or any(char in line for char in "()\"'\\"):
            raise ValueError("only flat unquoted event records are supported")
        tokens = shlex.split(line, comments=False, posix=True)
        if not 1 <= len(tokens) <= 32:
            raise ValueError("bounded nonempty event record required")
        actual.extend([index, column, value] for column, value in enumerate(tokens))
    return {"allowed_token": allowed, "observed_token": actual}


def review(args, ctx, output, population):
    from gambit_smp.evidence_capabilities import evaluate_observations
    path = source_path(ctx.root, args["contract"])
    rules = source_path(ctx.root, args["rules"])
    ctx.bind([path, rules])
    projected = project(json.loads(path.read_text()), output, population)
    answers = evaluate_observations(ctx, [args["rules"]], projected,
        {"bad": "unexpected_token", "missing": "missing_cell"}, "transcript-review")
    if answers != {"bad": [], "missing": []}:
        raise ValueError("native transcript does not satisfy the declared Evidence contract")
    return {"contract": args["contract"], "rules": args["rules"],
            "observedTokens": len(projected["observed_token"]), "answers": answers,
            "claim": "exact-declared-event-transport-not-runtime-or-source-refinement"}
