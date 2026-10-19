"""Unverified rule fixtures for retired Evidence views.

This module is test-only. It never supplies inputs to review or action APIs.
"""
import json
from pathlib import Path

from gambit_smp.ascent_program import load_component_catalog
from gambit_smp.framework import digest
from gambit_smp.native_review import pointer
from gambit_smp.recipes import source_path


def projection(root, name):
    root = Path(root).resolve()
    view = source_path(root, name)
    document = json.loads(view.read_text())
    registry = json.loads((root / "evidence/views.json").read_text())
    historical = {row["path"]: row["sha256"] for row in registry.get("historical", [])}
    if historical.get(name) != digest(view):
        raise ValueError("retired view identity required")
    captures = json.loads((root / "tests/fixtures/historical-view-pointers.json").read_text())
    captured = captures.get(name, {})
    if captured and captured["viewSha256"] != digest(view):
        raise ValueError("historical pointer fixture changed view identity")
    values = {}
    declared = {str(view): digest(view)}
    for ref in document["references"]:
        relative = Path(ref["path"])
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("historical reference escapes repository")
        path = root / relative
        archive = captured.get("sources", {}).get(ref["id"])
        if archive is not None:
            path = source_path(root, archive)
        declared[str(path)] = ref["sha256"]
        if path.is_file():
            if digest(path) != ref["sha256"]:
                raise ValueError("historical reference changed: " + ref["path"])
            value = ref["sha256"] if ref["pointer"] is None else pointer(
                json.loads(path.read_text()), ref["pointer"])
        elif ref["pointer"] is None:
            value = ref["sha256"]
        else:
            value = captured.get("pointers", {}).get(ref["id"])
            if value is None:
                raise ValueError("historical pointer capture missing: " + ref["id"])
        values[ref["id"]] = value

    def cell(value):
        if isinstance(value, dict):
            if set(value) != {"reference"} or value["reference"] not in values:
                raise ValueError("unknown historical reference")
            return values[value["reference"]]
        return value

    facts = {relation: [[cell(value) for value in row] for row in rows]
             for relation, rows in document["facts"].items()}
    catalog = load_component_catalog(source_path(root, document["manifest"]),
        entry=document["entry"], constructor=document["constructor"], trusted=True)
    return document, facts, catalog, declared
