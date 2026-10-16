"""Bind immutable historical inputs; never substitute tools or built artifacts."""
from pathlib import Path

from gambit_smp.framework import digest

SCHEMA = "historical-source-inputs.v1"


def bindings(root, receipt_path, archive):
    from gambit_smp.recipes import fields, read_json, source_path
    root = root.resolve()
    document = source_path(root, archive)
    record = read_json(document)
    fields(record, ("schema", "receiptSha256", "inputs"))
    if (record["schema"] != SCHEMA or record["receiptSha256"] != digest(receipt_path)
            or not isinstance(record["inputs"], list) or not record["inputs"]):
        raise ValueError("exact historical receipt and nonempty source archive required")
    original = read_json(receipt_path)
    mapping, paths = {}, [document]
    for row in record["inputs"]:
        fields(row, ("original", "sha256", "archive"))
        name = row["original"]
        source_path(root, name)
        if Path(name).parts[0] not in {"evidence", "models", "patches", "src", "docs"}:
            raise ValueError("only versioned source inputs can have historical bindings")
        if name in mapping or original["inputs"].get(name) != row["sha256"]:
            raise ValueError("unique original receipt input required")
        target = source_path(root, row["archive"])
        if (not target.is_relative_to(root / "evidence/source-results")
                or (root / row["archive"]).is_symlink() or digest(target) != row["sha256"]):
            raise ValueError("exact versioned historical source bytes required")
        mapping[name] = target
        paths.append(target)
    return {str(root / name): target for name, target in mapping.items()}, paths


def match(expected, mapping):
    return all(digest(mapping.get(name, Path(name))) == sha for name, sha in expected.items())
