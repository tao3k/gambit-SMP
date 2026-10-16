"""JSON field transport to caller-declared Scheme observation contracts."""
import json
from pathlib import Path

from gambit_smp.framework import digest, relative

DSL = "evidence/dsl/observation-contract.ss"
QUERIES = ("MissingCase", "UnknownCase", "DuplicateCase", "MissingField", "WrongField", "ExtraField")


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=True, allow_nan=False)


def project(root, declaration, observations):
    root = Path(root).resolve()
    path = relative(root, declaration)
    sha = digest(path)
    document = json.loads(path.read_text())
    if digest(path) != sha:
        raise ValueError("observation declaration changed during loading")
    if (set(document) != {"schema", "keyFields", "fields", "cases"}
            or document["schema"] != "ascent.observation-contract.v1"
            or not isinstance(document["keyFields"], list) or not document["keyFields"]
            or len(set(document["keyFields"])) != len(document["keyFields"])
            or not all(type(k) is str for k in document["keyFields"])
            or not isinstance(document["fields"], list) or not document["fields"]
            or len(set(document["fields"])) != len(document["fields"])
            or not all(type(k) is str for k in document["fields"])
            or not set(document["keyFields"]) <= set(document["fields"])
            or not isinstance(document["cases"], list) or not document["cases"]):
        raise ValueError("explicit nonempty observation contract required")
    keys = document["keyFields"]
    facts = {name: [] for name in ("RequiredCase", "RequiredField", "ObservedCase", "ObservedField")}
    def key(row):
        if not isinstance(row, dict) or any(k not in row for k in keys):
            raise ValueError("observation key fields required")
        return encoded([row[k] for k in keys])
    declared = set()
    for row in document["cases"]:
        if set(row) != set(document["fields"]):
            raise ValueError("complete declared field inventory required")
        name = key(row)
        if name in declared:
            raise ValueError("duplicate declared observation identity")
        declared.add(name)
        facts["RequiredCase"].append([name])
        facts["RequiredField"].extend([name, field, encoded(value)] for field, value in row.items())
    if not isinstance(observations, list):
        raise ValueError("complete observation row inventory required")
    for number, row in enumerate(observations):
        name = key(row)
        facts["ObservedCase"].append([name, number])
        facts["ObservedField"].extend([name, number, field, encoded(row[field])]
                                     for field in document["fields"] if field in row)
    return facts, {str(path): sha}


def evaluate(root, declaration, observations, *, engine=None):
    from gambit_smp.ascent_program import load_evidence_catalog, query
    root = Path(root).resolve()
    facts, inputs = project(root, declaration, observations)
    catalog = load_evidence_catalog(root / DSL, constructor="make-observation-contract", trusted=True)
    inputs.update(catalog["sourceInputs"])
    explanation = {}
    answers = query(facts, catalog, {name: name for name in QUERIES}, engine=engine,
                    metrics=explanation, reuse_program=True)
    if any(digest(Path(p)) != sha for p, sha in inputs.items()):
        raise ValueError("observation contract source changed")
    return answers, inputs, explanation


def bind_execution(root, name, steps):
    """Resolve exact pointers in the executing Recipe's prior step receipts."""
    from gambit_smp.native_review import pointer
    from gambit_smp.recipes import source_path
    root = Path(root).resolve()
    path = source_path(root, name)
    sha = digest(path)
    document = json.loads(path.read_text())
    if digest(path) != sha:
        raise ValueError("execution observation binding changed during loading")
    if (set(document) != {"schema", "contract", "rows"}
            or document["schema"] != "ascent.execution-observation-binding.v1"
            or not isinstance(document["contract"], str)
            or not isinstance(document["rows"], list)):
        raise ValueError("typed complete execution observation binding required")
    by_id = {step["id"]: step for step in steps if step["capability"] != "evidence.evaluate"}
    def cell(value):
        if isinstance(value, dict):
            if (set(value) != {"step", "pointer"} or value["step"] not in by_id
                    or not isinstance(value["pointer"], str)):
                raise ValueError("exact prior-step observation pointer required")
            return pointer(by_id[value["step"]], value["pointer"])
        if type(value) not in (str, int, bool):
            raise ValueError("typed binding literal or step pointer required")
        return value
    if any(not isinstance(row, dict) for row in document["rows"]):
        raise ValueError("observation binding rows required")
    rows = [{key: cell(value) for key, value in row.items()} for row in document["rows"]]
    declaration = source_path(root, document["contract"])
    projected, inputs = project(root, declaration.relative_to(root).as_posix(), rows)
    inputs[str(path)] = sha
    return projected, inputs
