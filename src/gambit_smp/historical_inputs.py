"""Bind immutable historical inputs; never substitute tools or built artifacts."""
from pathlib import Path

from gambit_smp.framework import digest

SCHEMA = "historical-source-inputs.v1"


def recorded_source_input(root, receipt_path, original, name):
    """A review's observed source is historical input, not a new build output.

    The outer receipt authenticates the exact child observation before its
    observed-input map can supply an identity absent from declared inputs.
    """
    declared = original['inputs'].get(name)
    if declared is not None:
        return declared
    from gambit_smp.recipes import read_json
    child_path = receipt_path.parent / 'run/receipt.json'
    if (original.get('schema') != 'sealed-research-run.v1'
            or not child_path.is_file()
            or digest(child_path) != original.get('childReceiptSha256')):
        raise ValueError('authenticated child source observation required')
    child = read_json(child_path)
    values = {step.get('observedInputs', {}).get(str(root / name))
              for step in child['steps']}
    values.discard(None)
    if len(values) != 1:
        raise ValueError('unique original observed source input required')
    return values.pop()


def bindings(root, receipt_path, archive):
    from gambit_smp.recipes import CACHE_PARTS, fields, read_json, source_path
    from gambit_smp.framework import relative
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
        # A deleted experiment remains a valid historical input identity.
        # Its replacement is the exact archived bytes, never a current output.
        original_path=relative(root,name)
        if any(part.casefold() in CACHE_PARTS for part in
               (*Path(name).parts,*original_path.relative_to(root).parts)):
            raise ValueError('historical originals cannot be Cache aliases')
        parts = Path(name).parts
        vendor_source = (parts[:2] == ('vendor', 'gambit') and Path(name).suffix in
                         {'.m4', '.scm', '.c', '.h', '.inc', '.in'})
        model_source = (parts[0] == 'dev' and Path(name).suffix in
                        {'.sysml', '.qnt', '.lean', '.scm', '.org', '.d2'})
        if parts[0] not in {"evidence", "models", "patches", "src", "docs"} and not vendor_source and not model_source:
            raise ValueError("only versioned source inputs can have historical bindings")
        if name in mapping or recorded_source_input(root, receipt_path, original, name) != row["sha256"]:
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
