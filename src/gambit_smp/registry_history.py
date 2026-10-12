"""Ordered registry provenance; validation never admits runtime correctness."""
import hashlib
import json
from pathlib import Path

from gambit_smp.framework import digest

SCHEMA = "gambit-evidence-history.v1"
CACHE_PARTS = {".data", ".cache", ".git", ".venv", "__pycache__"}


def validate(root, manifest_name):
    root = root.resolve()
    inputs, paths = {}, {}

    def read(name, expected=None):
        if not isinstance(name, str) or not name:
            raise ValueError("history needs a durable relative path")
        path = Path(name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError("history needs a durable relative path")
        resolved = (root / path).resolve()
        try:
            local = resolved.relative_to(root)
        except ValueError as error:
            raise ValueError("history path escapes repository") from error
        if (any(part.casefold() in CACHE_PARTS for part in (*path.parts, *local.parts))
                or not resolved.is_file()):
            raise ValueError("history cannot bind a cache alias or missing file")
        data = resolved.read_bytes()
        actual = hashlib.sha256(data).hexdigest()
        if expected is not None and actual != expected:
            raise ValueError("stale history artifact: " + name)
        if name in inputs and inputs[name] != actual:
            raise ValueError("history input changed while reading")
        inputs[name], paths[name] = actual, resolved
        return json.loads(data)

    def descriptor(row):
        if (not isinstance(row, dict) or not isinstance(row.get("sha256"), str)
                or len(row["sha256"]) != 64
                or any(c not in "0123456789abcdef" for c in row["sha256"])):
            raise ValueError("immutable history descriptor needs SHA-256")
        return read(row["path"], row["sha256"])

    def select(value, pointer):
        if not isinstance(pointer, list):
            raise ValueError("history selector must be a typed key/index path")
        try:
            for key in pointer:
                if isinstance(value, list) and type(key) is int and 0 <= key < len(value):
                    value = value[key]
                elif isinstance(value, dict) and isinstance(key, str):
                    value = value[key]
                else:
                    raise ValueError("invalid history selector")
        except (KeyError, IndexError) as error:
            raise ValueError("missing history selector") from error
        return value

    manifest = read(manifest_name)
    if manifest.get("schema") != SCHEMA:
        raise ValueError("unknown history schema")
    collection = manifest.get("collection")
    registry_schema = manifest.get("registrySchema")
    if not isinstance(collection, str) or not collection or not isinstance(registry_schema, str):
        raise ValueError("history needs an explicit registry schema and collection")
    identity_pointer = manifest.get("identityPointer")

    def encoded(values):
        return [json.dumps(value, sort_keys=True, allow_nan=False) for value in values]

    def rows(saved):
        if not isinstance(saved, dict) or saved.get("schema") != registry_schema:
            raise ValueError("history registry schema mismatch")
        values = saved.get(collection)
        if not isinstance(values, list) or not values:
            raise ValueError("history collection must be nonempty")
        identities = [json.dumps(select(value, identity_pointer), sort_keys=True) for value in values]
        if len(set(identities)) != len(identities):
            raise ValueError("duplicate history item identity")
        return values

    snapshots = manifest.get("snapshots")
    if not isinstance(snapshots, list) or not snapshots:
        raise ValueError("history needs immutable snapshots")
    versions, previous, resolved_snapshots = {}, None, set()
    for snapshot in snapshots:
        if not isinstance(snapshot, dict):
            raise ValueError("history snapshot must be a descriptor")
        sid = snapshot.get("id")
        if not isinstance(sid, str) or not sid or sid in versions:
            raise ValueError("duplicate or invalid history version")
        values = rows(descriptor(snapshot))
        resolved = paths[snapshot["path"]]
        if resolved in resolved_snapshots:
            raise ValueError("history snapshots must be distinct files")
        resolved_snapshots.add(resolved)
        if previous is not None:
            if encoded(values[:len(previous)]) != encoded(previous) or len(values) <= len(previous):
                raise ValueError("history version must strictly extend its predecessor")
            additions = snapshot.get("additions")
            if not isinstance(additions, list) or encoded(values[len(previous):]) != encoded(additions):
                raise ValueError("history additions differ from declared transition")
        elif "additions" in snapshot:
            raise ValueError("initial history snapshot has no predecessor additions")
        versions[sid], previous = snapshot, values
    current = manifest.get("current")
    if not isinstance(current, dict) or set(current) != {"path", "requiredAdditions"}:
        raise ValueError("current history descriptor must not pin a historical hash")
    values = rows(read(current["path"]))
    if paths[current["path"]] in resolved_snapshots:
        raise ValueError("current registry cannot alias a historical snapshot")
    additions = current["requiredAdditions"]
    if not isinstance(additions, list) or not additions:
        raise ValueError("current history needs explicit required additions")
    prefix = previous + additions
    if encoded(values[:len(prefix)]) != encoded(prefix):
        raise ValueError("current registry lost or reordered its required history")
    bindings = manifest.get("bindings")
    if not isinstance(bindings, list) or not bindings:
        raise ValueError("history needs explicit historical evidence bindings")
    for binding in bindings:
        if not isinstance(binding, dict):
            raise ValueError("historical binding must be a descriptor")
        snapshot = versions.get(binding.get("snapshot"))
        if snapshot is None:
            raise ValueError("historical binding names an unknown snapshot")
        artifact = binding["artifact"]
        recorded = select(descriptor(artifact), binding.get("pointer"))
        if paths[artifact["path"]] == paths[current["path"]]:
            raise ValueError("historical evidence cannot alias the current registry")
        if recorded != {"path": binding.get("recordedPath"), "sha256": snapshot["sha256"]}:
            raise ValueError("historical claim does not bind its immutable version")
    for name, expected in inputs.items():
        if digest(paths[name]) != expected:
            raise ValueError("history input changed during validation")
    return inputs
