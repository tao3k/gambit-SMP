"""Source artifacts and byte provenance, independent of research mechanisms.

Projection establishes byte origin, never protocol equivalence or refinement.
Protocol assertions belong to the declared model, native fixture, or rule source.
"""
import hashlib
import json
from pathlib import Path
import re
import shutil

from gambit_smp.framework import digest, relative


SHA256 = re.compile(r"[0-9a-f]{64}\Z")
TREE = {"source-tree", "configured-tree"}
OVERLAY_INPUT = TREE | {"compilation-workspace"}


def fields(value, required, optional=()):
    from gambit_smp.recipes import fields as check
    check(value, required, optional)


def local_name(value):
    if (not isinstance(value, str) or not value or Path(value).is_absolute()
            or any(part in {"..", ".", ".git", "__pycache__"} for part in value.split("/"))
            or "\\" in value or ":" in value):
        raise ValueError("canonical artifact-relative file name required")
    return value


def sha(value):
    if not isinstance(value, str) or not SHA256.fullmatch(value):
        raise ValueError("explicit SHA-256 required")


def validate_source_lock(lock):
    """Validate byte identity, not a mechanism-specific source file allowlist."""
    if (not isinstance(lock, dict) or lock.get("schema") != "gambit-runtime-source-lock.v1"
            or not isinstance(lock.get("revision"), str)
            or not re.fullmatch(r"[0-9a-f]{40}", lock["revision"])
            or lock.get("submodule") != "vendor/gambit"
            or lock.get("repository") != "https://git.cons.io/mighty-gerbils/gambit.git"
            or lock.get("runtimeAdmitted") is not False
            or lock.get("releaseAdmitted") is not False):
        raise ValueError("non-admitting pinned source lock required")
    sha(lock.get("patchSha256"))
    inventory = lock.get("files")
    if not isinstance(inventory, dict) or not inventory:
        raise ValueError("nonempty source file identity map required")
    for name, row in inventory.items():
        source_name(name)
        fields(row, ("baseSha256", "candidateSha256"))
        # Null means the path must be absent in the pinned archive, not empty.
        if row["baseSha256"] is not None:
            sha(row["baseSha256"])
        sha(row["candidateSha256"])


def source_name(name):
    local_name(name)
    if (any(not part or part.casefold() in {".data", ".cache", "cache", ".venv", ".git", "__pycache__"}
            for part in name.split("/")) or any(ord(char) < 32 for char in name)
            or name == "materialization.json"):
        raise ValueError("canonical non-Cache source file required")
    return name


def source_file(root, name):
    source_name(name)
    path = root
    for part in name.split("/"):
        path = path / part
        if path.is_symlink():
            raise ValueError("source file cannot traverse a symlink")
    if not path.is_file():
        raise ValueError("existing regular source file required")
    return path


def verify_source_base(root, name, row):
    """Distinguish an absent new path from an existing empty source file."""
    source_name(name)
    path = Path(root)
    for part in name.split("/"):
        path = path / part
        if path.is_symlink():
            raise ValueError("source file cannot traverse a symlink")
        if path.exists() and path != Path(root) / name and not path.is_dir():
            raise ValueError("source parent must be a directory")
    if row["baseSha256"] is None:
        if path.exists():
            raise ValueError("new source path must be absent from pinned archive")
    elif digest(source_file(root, name)) != row["baseSha256"]:
        raise ValueError("archived base source differs from lock")


def reference(value):
    from gambit_smp.native_capabilities import reference as check
    check(value)


def project_bytes(data, ranges):
    """Check an explicit byte projection; this makes no semantic locality claim."""
    if not isinstance(ranges, list) or not ranges:
        raise ValueError("explicit byte-range inventory required")
    end, pieces = 0, []
    for span in ranges:
        fields(span, ("start", "end", "sha256"))
        if (type(span["start"]) is not int or type(span["end"]) is not int
                or not end <= span["start"] < span["end"] <= len(data)):
            raise ValueError("ordered disjoint positive byte spans within source required")
        sha(span["sha256"])
        piece = data[span["start"]:span["end"]]
        if hashlib.sha256(piece).hexdigest() != span["sha256"]:
            raise ValueError("projection span byte identity mismatch")
        pieces.append(piece)
        end = span["end"]
    return b"\n".join(pieces)


def validate_overlay(args, inputs):
    fields(args, ("source", "patch", "files", "role"))
    reference(args["source"])
    if args["patch"] not in inputs or not args["patch"].endswith(".patch"):
        raise ValueError("declared source overlay required")
    if args["role"] not in {"candidate", "negative-control"}:
        raise ValueError("explicit overlay role required")
    if not isinstance(args["files"], dict) or not args["files"]:
        raise ValueError("exact overlay file identity map required")
    for name, row in args["files"].items():
        local_name(name)
        fields(row, ("before", "after"))
        sha(row["before"])
        sha(row["after"])


def validate_project(args, inputs):
    fields(args, ("source", "files"))
    reference(args["source"])
    if not isinstance(args["files"], list) or not 1 <= len(args["files"]) <= 128:
        raise ValueError("bounded explicit compilation workspace inventory required")
    targets = set()
    for row in args["files"]:
        fields(row, ("target", "origin", "sha256"), ("ranges",))
        local_name(row["target"])
        if row["target"] in targets or row["target"] == "provenance.json":
            raise ValueError("unique non-reserved projection target required")
        targets.add(row["target"])
        fields(row["origin"], ("kind", "path"))
        local_name(row["origin"]["path"])
        if row["origin"]["kind"] == "research-asset":
            if row["origin"]["path"] not in inputs or "ranges" in row:
                raise ValueError("research assets must be whole declared files")
        elif row["origin"]["kind"] == "source-artifact":
            if "ranges" in row:
                ranges = row["ranges"]
                if not isinstance(ranges, list) or not ranges or len(ranges) > 128:
                    raise ValueError("bounded byte-range inventory required")
                end = 0
                for span in ranges:
                    fields(span, ("start", "end", "sha256"))
                    if (type(span["start"]) is not int or type(span["end"]) is not int
                            or not end <= span["start"] < span["end"]):
                        raise ValueError("ordered disjoint positive byte spans required")
                    end = span["end"]
                    sha(span["sha256"])
        else:
            raise ValueError("projection cannot consume an external producer or receipt")
        sha(row["sha256"])


def validate_binding(args, inputs):
    fields(args, ("workspace",))
    reference(args["workspace"])


def validate_workspace_build(args, inputs):
    fields(args, ("workspace", "binding", "translationUnit", "standard", "optimization", "pthread", "target"),
           ("defines",))
    reference(args["workspace"])
    reference(args["binding"])
    local_name(args["translationUnit"])
    if not args["translationUnit"].endswith(".c"):
        raise ValueError("workspace C translation unit required")
    from gambit_smp.native_capabilities import validate_c
    translated = {key: value for key, value in args.items() if key not in {"workspace", "binding", "translationUnit"}}
    translated.update(sources=[args["translationUnit"]], headers=[])
    validate_c(translated, [args["translationUnit"]])


def graph(step, by_id, registry):
    contracts = {
        "source.overlay": {"source": OVERLAY_INPUT},
        "source.project": {"source": TREE},
        "source.bind": {"workspace": {"compilation-workspace"}},
        "native.workspace-build": {"workspace": {"compilation-workspace"}, "binding": {"source-binding"}},
    }
    for name, kinds in contracts[step["capability"]].items():
        ref = step["arguments"][name]
        producer = by_id.get(ref["step"])
        if producer is None or ref["step"] not in step["dependsOn"]:
            raise ValueError("source artifact requires its explicit producer dependency")
        if dict(registry[producer["capability"]].outputs).get(ref["output"]) not in kinds:
            raise ValueError("source artifact type mismatch")
    if step["capability"] == "native.workspace-build":
        args = step["arguments"]
        binding = by_id[args["binding"]["step"]]
        if binding["arguments"]["workspace"] != args["workspace"]:
            raise ValueError("binding must describe this exact workspace producer")


def overlay(args, ctx):
    from gambit_smp.recipes import source_path
    source = ctx.artifact(args["source"], OVERLAY_INPUT)
    target = ctx.directory / "source"
    from gambit_smp.artifact_storage import transfer_tree
    transfer_tree(source, target)
    for name, row in args["files"].items():
        if digest(relative(target, name)) != row["before"]:
            raise ValueError("overlay baseline differs from its byte contract")
    patch = source_path(ctx.root, args["patch"])
    command = [ctx.tools["git"], "--git-dir=/dev/null", "apply"]
    stats = ctx.require("overlay-inventory", [*command, "--numstat", "-z", patch], target, 10)
    names = []
    for record in stats.split("\0"):
        if record:
            added, removed, name = record.split("\t", 2)
            if not added.isdecimal() or not removed.isdecimal() or name not in args["files"] or name in names:
                raise ValueError("overlay exceeds its exact existing-file contract")
            names.append(name)
    if set(names) != set(args["files"]):
        raise ValueError("overlay inventory differs from declared changes")
    ctx.require("overlay-check", [*command, "--whitespace=error", "--check", patch], target, 10)
    ctx.require("overlay-apply", [*command, "--whitespace=error", patch], target, 10)
    for name, row in args["files"].items():
        if digest(relative(target, name)) != row["after"]:
            raise ValueError("overlay result differs from its byte contract")
    result = ctx.publish("source", "source-tree", target)
    result["source"]["derivation"] = {"producer": args["source"], "patchSha256": digest(patch), "role": args["role"]}
    return {"outputs": result, "claim": "byte-checked-overlay-not-source-refinement"}


def project(args, ctx):
    from gambit_smp.recipes import source_path, tree_identity
    source = ctx.artifact(args["source"], TREE)
    workspace = ctx.directory / "workspace"
    workspace.mkdir()
    records = []
    for row in args["files"]:
        origin = row["origin"]
        path = (relative(source, origin["path"]) if origin["kind"] == "source-artifact"
                else source_path(ctx.root, origin["path"]))
        data = path.read_bytes()
        if hashlib.sha256(data).hexdigest() != row["sha256"]:
            raise ValueError("projection origin differs from reviewed byte identity")
        content = data
        if "ranges" in row:
            content = project_bytes(data, row["ranges"])
        target = relative(workspace, row["target"])
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(content)
        records.append({**row, "outputSha256": digest(target)})
        ctx.remaining()
    provenance = {"schema": "source-byte-provenance.v1", "source": args["source"],
                  "sourceTreeIdentity": tree_identity(source), "files": records,
                  "claim": "byte-origin-only", "sourceRefinementAdmitted": False}
    (workspace / "provenance.json").write_text(json.dumps(provenance, sort_keys=True, indent=2) + "\n")
    return {"outputs": ctx.publish("workspace", "compilation-workspace", workspace),
            "claim": "source-derived-workspace-not-runtime-equivalence"}


def bind(args, ctx):
    from gambit_smp.recipes import read_json
    workspace = ctx.artifact(args["workspace"], "compilation-workspace")
    provenance = read_json(workspace / "provenance.json")
    if (provenance.get("schema") != "source-byte-provenance.v1"
            or provenance.get("sourceRefinementAdmitted") is not False):
        raise ValueError("mechanical byte provenance required")
    source = ctx.artifact(provenance["source"], TREE)
    files = {}
    for row in provenance["files"]:
        target = relative(workspace, row["target"])
        origin = row["origin"]
        path = (relative(source, origin["path"]) if origin["kind"] == "source-artifact"
                else relative(ctx.root, origin["path"]))
        data = path.read_bytes()
        expected = project_bytes(data, row["ranges"]) if "ranges" in row else data
        if digest(path) != row["sha256"] or target.read_bytes() != expected or digest(target) != row["outputSha256"]:
            raise ValueError("source/workspace byte correspondence drift")
        files[row["target"]] = row["outputSha256"]
    files["provenance.json"] = digest(workspace / "provenance.json")
    binding = {"schema": "source-workspace-binding.v1", "workspace": args["workspace"],
               "files": files, "source": provenance["source"], "claim": "byte-origin-only",
               "sourceFiles": [row["target"] for row in provenance["files"] if row["origin"]["kind"] == "source-artifact"],
               "sourceRefinementAdmitted": False}
    target = ctx.directory / "binding.json"
    target.write_text(json.dumps(binding, sort_keys=True, indent=2) + "\n")
    return {"outputs": ctx.publish("binding", "source-binding", target), "claim": "byte-origin-only"}


def workspace_build(args, ctx):
    from gambit_smp.native_capabilities import compile_workspace
    from gambit_smp.recipes import read_json
    workspace = ctx.artifact(args["workspace"], "compilation-workspace")
    binding = read_json(ctx.artifact(args["binding"], "source-binding"))
    if binding.get("workspace") != args["workspace"] or binding.get("sourceRefinementAdmitted") is not False:
        raise ValueError("matching non-refinement workspace binding required")
    if set(path.relative_to(workspace).as_posix() for path in workspace.rglob('*') if path.is_file()) != set(binding['files']):
        raise ValueError('workspace inventory differs from binding')
    for name, expected in binding['files'].items():
        if digest(relative(workspace, name)) != expected:
            raise ValueError('workspace binding drift')
    copied = ctx.directory / "inputs"
    # A bound projection is not another complete Gambit source/runtime tree.
    shutil.copytree(workspace, copied)
    if set(path.relative_to(copied).as_posix() for path in copied.rglob("*") if path.is_file()) != set(binding["files"]):
        raise ValueError("workspace inventory differs from binding")
    for name, expected in binding["files"].items():
        if digest(relative(copied, name)) != expected:
            raise ValueError("workspace binding drift")
    if args["translationUnit"] not in binding["files"]:
        raise ValueError("translation unit omitted from workspace binding")
    return compile_workspace(args, ctx, copied, relative(copied, args["translationUnit"]), binding["files"],
                             required_origins=binding["sourceFiles"])


def capabilities(Capability):
    entries = {
        "source.overlay": (validate_overlay, overlay, (("source", "source-tree"),)),
        "source.project": (validate_project, project, (("workspace", "compilation-workspace"),)),
        "source.bind": (validate_binding, bind, (("binding", "source-binding"),)),
        "native.workspace-build": (validate_workspace_build, workspace_build,
                                   (("executable", "native-executable"), ("object", "native-object"))),
    }
    return {name: Capability(validate, executor=executor, graph=graph, outputs=outputs)
            for name, (validate, executor, outputs) in entries.items()}
