"""Exact JSON/reference transport for caller-owned declarative Evidence views."""
import json
from pathlib import Path

from gambit_smp.framework import digest


def registry(root):
    from gambit_smp.recipes import source_path
    path = Path(root) / "evidence/views.json"
    if not path.exists():
        return [], {}
    document = json.loads(path.read_text())
    if (set(document) not in ({"schema", "views"}, {"schema", "views", "historical"})
            or document["schema"] != "ascent.evidence-views.v1"
            or not isinstance(document["views"], list)
            or any(type(name) is not str for name in document["views"])
            or len(set(document["views"])) != len(document["views"])):
        raise ValueError("unique explicit Evidence view registry required")
    inputs = {str(path.resolve()): digest(path)}
    historical = document.get("historical", [])
    if (not isinstance(historical, list)
            or any(not isinstance(row, dict) or set(row) != {"path", "sha256"}
                   or type(row["path"]) is not str or type(row["sha256"]) is not str
                   for row in historical)
            or len({row["path"] for row in historical}) != len(historical)
            or set(document["views"]) & {row["path"] for row in historical}):
        raise ValueError("historical views must be distinct from current views")
    for row in historical:
        source = source_path(Path(root), row["path"])
        if digest(source) != row["sha256"]:
            raise ValueError("historical Evidence view changed: " + row["path"])
        inputs[str(source)] = row["sha256"]
    return document["views"], inputs


def load(root, name):
    from gambit_smp.recipes import source_path
    from gambit_smp.native_review import pointer
    from gambit_smp.ascent_program import load_component_catalog
    root = Path(root).resolve()
    path = source_path(root, name)
    document = json.loads(path.read_text())
    if (set(document) != {"schema", "id", "manifest", "entry", "constructor", "facts", "queries", "references"}
            or document["schema"] != "ascent.evidence-view.v1"):
        raise ValueError("typed Evidence view required")
    references, inputs = {}, {str(path): digest(path)}
    for ref in document["references"]:
        if (not {"id", "path", "sha256", "pointer"} <= set(ref)
                or set(ref) - {"id", "path", "sha256", "pointer", "origin"}
                or ref["id"] in references):
            raise ValueError("unique exact view reference required")
        origin = ref.get("origin", "repository")
        if origin == "repository":
            original = source_path(root, ref["path"])
        elif origin == "observed-artifact":
            # Direct read-only observations are not Recipe source inputs or
            # aliases for a pinned vendor file. They never confer admission.
            from gambit_smp.framework import relative
            original = relative(root, ref["path"])
            if not original.is_file():
                raise ValueError("regular observed artifact required")
        else:
            raise ValueError("explicit view reference origin required")
        if digest(original) != ref["sha256"]:
            raise ValueError("Evidence view reference changed: " + ref["path"])
        inputs[str(original)] = ref["sha256"]
        references[ref["id"]] = (ref["sha256"] if ref["pointer"] is None else
                                  pointer(json.loads(original.read_text()), ref["pointer"]))
    def cell(value):
        if isinstance(value, dict):
            if set(value) != {"reference"} or value["reference"] not in references:
                raise ValueError("exact view cell reference required")
            return references[value["reference"]]
        if type(value) not in (str, bool, int, float):
            raise ValueError("scalar view cell or exact reference required")
        return value
    facts = {relation: [[cell(value) for value in row] for row in rows]
             for relation, rows in document["facts"].items()}
    catalog = load_component_catalog(source_path(root, document["manifest"]),
        entry=document["entry"], constructor=document["constructor"], trusted=True)
    inputs.update(catalog["sourceInputs"])
    if any(digest(Path(p)) != sha for p, sha in inputs.items()):
        raise ValueError("Evidence view changed during loading")
    return document, facts, catalog, inputs


def evaluate(root, name, engine):
    from gambit_smp.ascent_program import evaluate as query
    document, facts, catalog, inputs = load(root, name)
    answers, explanation = query(engine, facts, catalog, document["queries"])
    if any(digest(Path(p)) != sha for p, sha in inputs.items()):
        raise ValueError("Evidence view changed during inference")
    return {"id": document["id"], "path": name, "inputs": inputs,
            "queries": document["queries"], "answers": answers,
            "explanation": explanation, "executionAuthorized": False,
            "runtimeAdmitted": False, "scope": "caller-declared recorded-only view"}
