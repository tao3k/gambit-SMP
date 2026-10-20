"""Exact JSON/reference transport for caller-owned declarative Evidence views."""
import json
from pathlib import Path

from gambit_smp.framework import digest


class ReferenceUnavailable(ValueError):
    """Byte observations, never a substitute for the view's declared facts."""

    def __init__(self, document, inputs, references):
        self.document, self.inputs, self.references = document, inputs, references
        super().__init__("Evidence view reference changed or missing: "
                         + ", ".join(row["path"] for row in references))


def registry(root):
    from gambit_smp.recipes import source_path
    path = Path(root) / "evidence/views.json"
    if not path.exists():
        return [], {}
    document = json.loads(path.read_text())
    if (not {"schema", "views"} <= set(document)
            or set(document) - {"schema", "views", "historical", "selection", "availability"}
            or document["schema"] != "ascent.evidence-views.v1"
            or not isinstance(document["views"], list)
            or any(type(name) is not str for name in document["views"])
            or len(set(document["views"])) != len(document["views"])):
        raise ValueError("unique explicit Evidence view registry required")
    inputs = {str(path.resolve()): digest(path)}
    for key in ("selection", "availability"):
        if key not in document:
            continue
        selection = document[key]
        if (not isinstance(selection, dict) or set(selection) != {"source", "constructor"}
                or any(not isinstance(value, str) or not value for value in selection.values())):
            raise ValueError("Evidence selection requires a Scheme source and constructor")
        source = source_path(Path(root), selection["source"])
        inputs[str(source)] = digest(source)
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
    registry_path = root / "evidence/views.json"
    if registry_path.is_file():
        registered = json.loads(registry_path.read_text())
        for row in registered.get("historical", []):
            if row["path"] == name:
                if digest(path) != row["sha256"]:
                    raise ValueError("historical Evidence view changed: " + name)
                raise ValueError("historical Evidence view is not current: " + name)
    document = json.loads(path.read_text())
    if (set(document) != {"schema", "id", "manifest", "entry", "constructor", "facts", "queries", "references"}
            or document["schema"] != "ascent.evidence-view.v1"):
        raise ValueError("typed Evidence view required")
    references, inputs, unavailable = {}, {str(path): digest(path)}, []
    for ref in document["references"]:
        if (not {"id", "path", "sha256", "pointer"} <= set(ref)
                or set(ref) - {"id", "path", "sha256", "pointer", "origin"}
                or ref["id"] in references):
            raise ValueError("unique exact view reference required")
        if (not isinstance(ref["id"], str) or not ref["id"]
                or not isinstance(ref["sha256"], str) or len(ref["sha256"]) != 64
                or any(c not in "0123456789abcdef" for c in ref["sha256"])):
            raise ValueError("exact reference identity and SHA-256 required")
        origin = ref.get("origin", "repository")
        if origin == "repository":
            from gambit_smp.framework import relative
            from gambit_smp.recipes import CACHE_PARTS
            original = relative(root, ref["path"])
            if any(part.casefold() in CACHE_PARTS for part in (
                    *Path(ref["path"]).parts, *original.relative_to(root).parts)):
                raise ValueError("view references must not be Cache aliases")
        elif origin == "observed-artifact":
            # Direct read-only observations are not Recipe source inputs or
            # aliases for a pinned vendor file. They never confer admission.
            from gambit_smp.framework import relative
            original = relative(root, ref["path"])
        else:
            raise ValueError("explicit view reference origin required")
        if original.exists() and not original.is_file():
            raise ValueError("regular Evidence reference required")
        actual = digest(original) if original.is_file() else None
        inputs[str(original)] = actual
        if actual != ref["sha256"]:
            unavailable.append(dict(id=ref["id"], path=ref["path"],
                expected=ref["sha256"], observed=actual,
                reason="missing" if actual is None else "changed"))
            references[ref["id"]] = None
        else:
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
    facts = {}
    for relation, rows in document["facts"].items():
        if isinstance(rows, dict):
            if set(rows) != {"references"} or rows["references"] is not True:
                raise ValueError("explicit checked-reference metadata binding required")
            facts[relation] = [[ref["id"], ref["path"], ref["sha256"]]
                               for ref in document["references"]]
        else:
            facts[relation] = [[cell(value) for value in row] for row in rows]
    catalog = load_component_catalog(source_path(root, document["manifest"]),
        entry=document["entry"], constructor=document["constructor"], trusted=True)
    inputs.update(catalog["sourceInputs"])
    if any((digest(Path(p)) if Path(p).is_file() else None) != sha for p, sha in inputs.items()):
        raise ValueError("Evidence view changed during loading")
    if unavailable:
        raise ReferenceUnavailable(document, inputs, unavailable)
    return document, facts, catalog, inputs


def evaluate(root, name, engine):
    from gambit_smp.ascent_program import evaluate as query
    document, facts, catalog, inputs = load(root, name)
    answers, explanation = query(engine, facts, catalog, document["queries"])
    if any(digest(Path(p)) != sha for p, sha in inputs.items()):
        raise ValueError("Evidence view changed during inference")
    return {"id": document["id"], "path": name, "inputs": inputs,
            "facts": facts,
            "queries": document["queries"], "answers": answers,
            "explanation": explanation, "executionAuthorized": False,
            "runtimeAdmitted": False, "scope": "caller-declared recorded-only view"}
