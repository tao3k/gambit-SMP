"""Byte-preserving Evidence navigation; no rule parsing or inference here."""
import json
from pathlib import Path

from gambit_smp.framework import digest


def encoded(value):
    return json.dumps(value, ensure_ascii=True, indent=2).encode() + b"\n"


def write(root, out, views, bound_inputs):
    from gambit_smp.evidence_views import load
    from gambit_smp.ascent_program import component_asset
    root, out = Path(root).resolve(), Path(out).resolve()
    artifacts, entries, seen = {}, [], set()

    def put(name, raw):
        path = out / name
        if name not in artifacts:
            path.parent.mkdir(parents=True, exist_ok=True)
            with path.open("xb") as stream:
                stream.write(raw)
            artifacts[name] = {"path": name, "sha256": digest(path)}
        elif path.read_bytes() != raw:
            raise ValueError("Evidence source address collision")
        return artifacts[name]

    def archive(path, expected):
        path = Path(path)
        relative = str(path.relative_to(root)) if path.is_relative_to(root) else str(path)
        if bound_inputs.get(relative) != expected or digest(path) != expected:
            raise ValueError("Evidence interface input is not bound by review: " + relative)
        raw = path.read_bytes()
        if digest(path) != expected:
            raise ValueError("Evidence interface input changed during archive")
        descriptor = put("sources/" + expected + path.suffix, raw)
        if descriptor["sha256"] != expected:
            raise ValueError("Evidence interface archive differs from source")
        return descriptor

    for index, view in enumerate(views):
        if view["id"] in seen:
            raise ValueError("duplicate Evidence interface view")
        seen.add(view["id"])
        document, facts, catalog, inputs = load(root, view["path"])
        if (inputs != view["inputs"] or document["id"] != view["id"]
                or document["queries"] != view["queries"]
                or set(view["answers"]) != set(document["queries"])):
            raise ValueError("Evidence interface differs from evaluated view")
        spec = catalog["nativeComponents"]
        manifest_path = root / document["manifest"]
        manifest = archive(manifest_path, inputs[str(manifest_path)])
        components = []
        for component in spec["manifest"]["components"]:
            path = component_asset(manifest_path, component["source"])
            retained = {"declaration": component, "source": archive(path, inputs[str(path)])}
            if component["source"].startswith("package:"):
                retained["input"] = str(path)
            components.append(retained)
        prefix = "views/" + str(index) + "/"
        entries.append({"id": view["id"], "view": view["path"],
            "definition": archive(root / view["path"], inputs[str(root / view["path"])]),
            "entry": document["entry"], "constructor": document["constructor"],
            "manifest": manifest, "components": components,
            "facts": put(prefix + "facts.json", encoded(facts)),
            "answers": put(prefix + "answers.json", encoded(view["answers"])),
            "queries": view["queries"], "bindings": inputs,
            "references": document["references"],
            "explanation": {"path": "review.json", "pointer": "/evidenceViews/" + str(index) + "/explanation"}})
        if any(digest(Path(path)) != sha for path, sha in inputs.items()):
            raise ValueError("Evidence interface inputs changed during publication")
    interface = {"schema": "ascent.agent-evidence.v1", "views": entries,
                 "completeViewInventory": True, "selection": "open-world-unordered",
                 "executionAuthorized": False, "runtimeAdmitted": False}
    put("evidence.json", encoded(interface))
    return artifacts


def read(out, artifacts, review):
    from gambit_smp.ascent_program import engine_api
    out = Path(out).resolve()
    if digest(out / "evidence.json") != artifacts["evidence.json"]["sha256"]:
        raise ValueError("Evidence interface index identity differs")
    interface = json.loads((out / "evidence.json").read_bytes())
    if (interface.get("schema") != "ascent.agent-evidence.v1"
            or interface.get("completeViewInventory") is not True
            or interface.get("selection") != "open-world-unordered"
            or interface.get("executionAuthorized") is not False
            or interface.get("runtimeAdmitted") is not False):
        raise ValueError("invalid Evidence interface contract")
    views = review.get("evidenceViews", [])
    if [v["id"] for v in interface["views"]] != [v["id"] for v in views]:
        raise ValueError("Evidence interface inventory differs from review")
    expected = {"review.json", "graph.json", "context.md", "graph.mmd", "evidence.json"}

    def take(descriptor):
        name = descriptor["path"]
        path = out / name
        relative = Path(name)
        if (relative.is_absolute() or ".." in relative.parts or path.is_symlink()
                or not path.resolve().is_relative_to(out)):
            raise ValueError("Evidence interface artifact path differs")
        if artifacts.get(name) != descriptor:
            raise ValueError("unbound Evidence interface artifact")
        if digest(path) != descriptor["sha256"]:
            raise ValueError("Evidence interface artifact identity differs")
        expected.add(name)
        raw = path.read_bytes()
        import hashlib
        if hashlib.sha256(raw).hexdigest() != descriptor["sha256"]:
            raise ValueError("Evidence interface artifact changed during reading")
        return raw

    for index, (entry, view) in enumerate(zip(interface["views"], views)):
        document = json.loads(take(entry["definition"]))
        manifest = json.loads(take(entry["manifest"]))
        if (entry["view"] != view["path"] or entry["bindings"] != view["inputs"]
                or entry["queries"] != view["queries"] or document["queries"] != view["queries"]
                or document["id"] != view["id"] or entry["entry"] != document["entry"]
                or entry["constructor"] != document["constructor"]
                or entry["references"] != document["references"]
                or json.loads(take(entry["answers"])) != json.loads(json.dumps(view["answers"]))
                or entry["explanation"] != {"path": "review.json", "pointer": "/evidenceViews/" + str(index) + "/explanation"}):
            raise ValueError("Evidence interface content differs from review")
        declarations = {item["id"]: item for item in manifest["components"]}
        provided, sources = set(), {}
        for component in entry["components"]:
            declaration = component["declaration"]
            if declaration["id"] in provided or declarations.get(declaration["id"]) != declaration:
                raise ValueError("Evidence interface component differs from registry")
            provided.add(declaration["id"])
            sources[declaration["source"]] = take(component["source"]).decode("utf-8")
        try:
            with engine_api(retain=True) as (engine, _):
                with engine.components(manifest, sources, entry["entry"], trusted=True) as module:
                    if not set(module.components) <= provided:
                        raise ValueError("selected source closure incomplete")
        except ValueError as error:
            raise ValueError(f"Evidence interface component inventory invalid: {error}") from error
        if json.loads(take(entry["facts"])) != view["facts"]:
            raise ValueError("Evidence interface facts differ from evaluated sources")
        root = Path(review["agentGraph"]["checkout"]["root"])
        bindings = entry["bindings"]
        original_manifest = root / document["manifest"]
        if (entry["manifest"]["sha256"] != bindings.get(str(original_manifest))
                or entry["definition"]["sha256"] != bindings.get(str(root / view["path"]))):
            raise ValueError("Evidence interface definition identity differs")
        for component in entry["components"]:
            take(component["source"])
            name = component["declaration"]["source"]
            original = component.get("input") if name.startswith("package:") else str(original_manifest.parent / name)
            if component["source"]["sha256"] != bindings.get(original):
                raise ValueError("Evidence interface rule identity differs")
    if expected != set(artifacts):
        raise ValueError("Evidence interface artifact inventory differs")
    return interface
