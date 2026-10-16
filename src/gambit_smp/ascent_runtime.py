"""Installed PyO3 artifact and complete build-input identity transport."""
import importlib
import importlib.metadata
import base64
import json
import hashlib
from pathlib import Path
import tomllib
import platform
import sys

from gambit_smp.framework import ROOT, digest


LIBRARY_LOCK = "evidence/ascent-library.lock.json"


def publication_artifact(publication, target=None):
    target = target or sys.platform + '-' + platform.machine().lower()
    if 'platform' not in publication:
        return publication
    if target == publication['platform']:
        return publication
    artifacts = publication.get('artifacts', {})
    if target not in artifacts:
        raise ValueError('ASCENT publication has no locked artifact for ' + target)
    return dict(publication, **artifacts[target])


def validate_publication(publication, declared, build, extension_sha):
    """Compare a trusted host's wheel lock, not a fabricated VCS installation."""
    sources = build["sourceInputs"]
    artifact = publication_artifact(publication)
    source_sha = hashlib.sha256(json.dumps(sources, sort_keys=True,
                                          separators=(",", ":")).encode()).hexdigest()
    if (publication.get("schema") != "ascent-library-wheel-lock.v1"
            or any(publication.get(left) != declared.get(right) for left, right in (
                ("repository", "git"), ("revision", "rev"), ("subdirectory", "subdirectory")))
            or not declared.get("rev") or not declared.get("git")
            or artifact.get("extensionSha256") != extension_sha
            or publication.get("sourceInputsSha256") != source_sha
            or publication.get("sourceInputCount") != len(sources)):
        raise ValueError("ASCENT wheel differs from its published source/artifact lock")
    return publication


def require_packaged_runtime(build, package_root):
    """Reject build-machine resources; never repair them with caller SDK paths."""
    package_root = Path(package_root).resolve(strict=True)
    resources = build.get("runtimeInputs")
    if not isinstance(resources, dict) or not resources:
        raise ValueError("ASCENT package omits its runtime resource inventory")
    packaged = build.get("packageInputs")
    mapping = build.get("runtimePackagePaths")
    if packaged and (not isinstance(mapping, dict) or set(mapping) != set(resources)):
        raise ValueError("ASCENT runtime/package inventory keys disagree")
    for name, expected in resources.items():
        path = Path(name)
        if (not path.is_absolute() or ".." in path.parts or path.is_symlink()
                or not path.resolve(strict=True).is_relative_to(package_root)):
            raise ValueError("ASCENT package depends on an external runtime resource: " + name
                             + "; fix Library packaging, not downstream SDK configuration")
        if packaged:
            relative = Path(mapping[name])
            if (relative.is_absolute() or ".." in relative.parts
                    or package_root / relative != path.resolve(strict=True)
                    or packaged.get(mapping[name]) != expected):
                raise ValueError("ASCENT runtime/package resource binding mismatch: " + name)
        if digest(path) != expected:
            raise ValueError("packaged ASCENT runtime resource mismatch: " + name)


def inventory(*, sealed_root=None, verify=True):
    from ascent.build import runtime_identity

    if sealed_root is not None:
        sealed_root = Path(sealed_root).resolve(strict=True)
    build = runtime_identity()
    if sealed_root is not None:
        frozen = json.loads((sealed_root / "ascent-build.json").read_text())
        if frozen.get("packageInputs"):
            if any(build.get(key) != frozen.get(key) for key in ("schema", "sourceInputs", "packageInputs", "rayon")):
                raise ValueError("loaded ASCENT package differs from its sealed build")
            expected_runtime = {str(Path(importlib.import_module("ascent").__file__).resolve().parent / relative):
                                frozen["runtimeInputs"][original]
                                for original, relative in frozen["runtimePackagePaths"].items()}
            if build.get("runtimeInputs") != expected_runtime:
                raise ValueError("loaded ASCENT runtime is outside its sealed package")
            build = frozen
    if build.get("schema") != "ascent.rust-build.v1" or build.get("rayon") is not True:
        raise ValueError("Rust ASCENT with Rayon and compiled source identities required")
    if not build.get("sourceInputs") or not build.get("runtimeInputs"):
        raise ValueError("complete compiled ASCENT inputs required")
    files = {name: Path(importlib.import_module(name).__file__).resolve(strict=True)
             for name in ("ascent", "ascent._core")}
    distribution = importlib.metadata.distribution("gerbil-ascent")
    extension_sha = None
    installed_inputs = {}
    for entry in distribution.files or ():
        if str(entry) == "ascent/" + files["ascent._core"].name and entry.hash and entry.hash.mode == "sha256":
            extension_sha = base64.urlsafe_b64decode(entry.hash.value + "===").hex()
        if ".dist-info" in str(entry):
            files["distribution:" + entry.name] = Path(distribution.locate_file(entry)).resolve(strict=True)
        elif entry.hash and entry.hash.mode == "sha256":
            relative = Path(entry)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError("invalid installed ASCENT wheel resource path")
            path = Path(distribution.locate_file(entry))
            if path.is_symlink() or not path.resolve(strict=True).is_relative_to(files["ascent"].parent.parent):
                raise ValueError("installed ASCENT wheel resource escaped its distribution")
            expected = base64.urlsafe_b64decode(entry.hash.value + "===").hex()
            if verify and digest(path) != expected:
                raise ValueError("installed ASCENT wheel resource differs from its RECORD")
            installed_inputs[str(entry)] = expected
            files["package:" + str(entry)] = path.resolve(strict=True)
    if "distribution:direct_url.json" not in files:
        raise ValueError("ASCENT installation provenance required")
    if extension_sha is None or len(extension_sha) != 64 or (
            verify and digest(files["ascent._core"]) != extension_sha):
        raise ValueError("installed ASCENT extension does not match its RECORD")
    publication = (sealed_root / "ascent-publication.json" if sealed_root is not None else ROOT / LIBRARY_LOCK)
    declared = tomllib.loads((ROOT / "pyproject.toml").read_text())["tool"]["uv"]["sources"]["gerbil-ascent"]
    validate_publication(json.loads(publication.read_text()), declared, build, extension_sha)
    files["publication:library"] = publication
    if sealed_root is None:
        configured = build.get("sourceRoot")
        if not configured:
            raise ValueError("ASCENT Library must provide its packaged source inventory")
        source_root = Path(configured).resolve(strict=True)
        if not source_root.is_relative_to(files["ascent"].parent):
            raise ValueError("ASCENT source inventory is outside its installed package")
    else:
        source_root = Path(sealed_root) / "provider-source"
    for name, expected in build["sourceInputs"].items():
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts:
            raise ValueError("invalid compiled ASCENT source path")
        path = source_root / relative
        if path.is_symlink() or not path.resolve(strict=True).is_relative_to(source_root):
            raise ValueError("ASCENT source alias escaped its source root")
        if verify and digest(path) != expected:
            raise ValueError("compiled ASCENT source mismatch: " + name)
        files["source:" + name] = path
    mapping = (json.loads((Path(sealed_root) / "ascent-runtime.json").read_text())
               if sealed_root is not None else None)
    for name, expected in build["runtimeInputs"].items():
        path = Path(name)
        if not path.is_absolute() or ".." in path.parts:
            raise ValueError("invalid compiled ASCENT runtime path")
        if sealed_root is not None:
            # The seal maps each original resource path without collapsing it.
            path = Path(sealed_root) / mapping[name]
            if not path.resolve(strict=True).is_relative_to(Path(sealed_root)):
                raise ValueError("ASCENT runtime escaped its seal")
        if path.is_symlink() or (verify and digest(path) != expected):
            raise ValueError("compiled ASCENT runtime mismatch: " + name)
        files["runtime:" + name] = path
    return files, dict(build, extensionSha256=extension_sha,
                       sourceRoot=str(source_root),
                       installedInputs=installed_inputs)
