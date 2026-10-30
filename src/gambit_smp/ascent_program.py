"""Identity-bound native ASCENT programs; no legacy rule-text frontend."""
from contextlib import contextmanager, nullcontext
from contextvars import ContextVar
from functools import lru_cache
import atexit
import copy
import json
import hashlib
from pathlib import Path
import os
import threading
import time
import uuid
import fcntl
import stat
import sys

from gambit_smp.framework import ROOT, digest

INERT_RULE_CONTRACT = "inert-relational-subset.v1"

_loaded_identity = None
_retained_engine = None
_retained_owner = None
_query_owners = {}
_verified_api = ContextVar("verified_sealed_api", default=None)
_active_api = ContextVar("active_api_observation", default=None)
_construction_slot = ContextVar("source_session_construction_slot", default=None)
_construction_owner = ContextVar("source_session_construction_owner", default=None)


@contextmanager
def session_construction_slot(path, deadline):
    """Coordinate cold source construction; never replace the Library loader."""
    if _construction_slot.get() is not None:
        raise ValueError("session construction slots cannot be nested")
    if not isinstance(deadline, (int, float)) or not 0 < deadline < float("inf"):
        raise ValueError("finite construction deadline required")
    token = _construction_slot.set((Path(path), deadline))
    try:
        yield
    finally:
        _construction_slot.reset(token)


def construction_slot():
    return _construction_slot.get()


@contextmanager
def construction_admission(*, deadline=None):
    slot = construction_slot()
    if slot is None:
        yield
        return
    path, original_deadline = slot
    deadline = original_deadline if deadline is None else deadline
    if type(deadline) not in (int, float) or not 0 < deadline < float("inf"):
        raise ValueError("finite construction deadline required")
    identity = (os.getpid(), threading.get_ident(), path, deadline)
    if _construction_owner.get() == identity:
        if time.monotonic() >= deadline:
            raise TimeoutError("session construction admission deadline exhausted")
        yield
        return
    fd = os.open(path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_NONBLOCK, 0o600)
    try:
        if not stat.S_ISREG(os.fstat(fd).st_mode):
            raise ValueError("regular session construction lock required")
        while True:
            if time.monotonic() >= deadline:
                raise TimeoutError("session construction admission deadline exhausted")
            try:
                fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                break
            except BlockingIOError:
                time.sleep(min(.01, max(0, deadline - time.monotonic())))
        if time.monotonic() >= deadline:
            raise TimeoutError("session construction admission deadline exhausted")
        token = _construction_owner.set(identity)
        try:
            yield
        finally:
            _construction_owner.reset(token)
    finally:
        os.close(fd)


@contextmanager
def sealed_api_boundary(engine):
    """Delegate nested API checks to full byte checks around this request only."""
    from gambit_smp.research_kernel import execution_identity
    engine = Path(engine).resolve(strict=True)
    manifest = execution_identity(engine)
    token = _verified_api.set((engine, manifest))
    try:
        yield manifest
    finally:
        _verified_api.reset(token)
        if execution_identity(engine)["engineId"] != manifest["engineId"]:
            raise ValueError("ASCENT seal changed during API boundary")




def _api_inventory():
    admission = construction_admission() if _loaded_identity is None else nullcontext()
    with admission:
        boundary = _verified_api.get()
    if boundary is not None:
        root, manifest = boundary
        # Cache only a projection of bytes checked by this request's full seal
        # boundary, never a filesystem-validation verdict or query result.
        files, build, identity = _bound_api_inventory(root, manifest["engineId"])
        return dict(files), copy.deepcopy(build), identity
    import importlib
    import importlib.metadata
    from ascent.build import runtime_identity
    from gambit_smp.ascent_runtime import inventory
    distribution = importlib.metadata.distribution("gerbil-ascent")
    entries = tuple(str(entry) for entry in distribution.files or ())
    metadata = tuple((name, str(distribution.locate_file(name)),
                      digest(Path(distribution.locate_file(name))))
                     for name in entries if ".dist-info" in name)
    origins = tuple(str(Path(importlib.import_module(name).__file__).resolve(strict=True))
                    for name in ("ascent", "ascent._core"))
    files, build, identity = _installed_api_inventory(
        inventory, runtime_identity, origins, entries, metadata)
    _check_inventory_paths(files.values())
    return dict(files), copy.deepcopy(build), identity


def _check_inventory_paths(paths, *, checked=None):
    """Check every path component once per boundary, without following aliases."""
    if checked is None:checked = set()
    for path in set(paths):
        if not path.is_absolute() or '..' in path.parts:
            raise ValueError("installed ASCENT inventory path became an alias")
        pending = []
        component = path
        while component not in checked:
            pending.append(component)
            parent = component.parent
            if parent == component:
                break
            component = parent
        for component in reversed(pending):
            if stat.S_ISLNK(component.lstat().st_mode):
                raise ValueError("installed ASCENT inventory path became an alias")
            checked.add(component)


@lru_cache(maxsize=2)
def _installed_api_inventory(inventory, runtime_identity, origins, entries, metadata):
    # RECORD/metadata bytes select a projection. The caller
    # still hashes every projected source/resource at entry and exit.
    files, build = inventory(sealed_root=None, verify=False)
    return files, build, hashlib.sha256(json.dumps(build, sort_keys=True).encode()).hexdigest()


@lru_cache(maxsize=2)
def _bound_api_inventory(root, engine_id):
    from gambit_smp.ascent_runtime import inventory
    files, build = inventory(sealed_root=root, verify=False)
    boundary = _verified_api.get()
    if boundary is None or boundary[0] != root or boundary[1]["engineId"] != engine_id:
        raise ValueError("ASCENT inventory projection requires its checked seal boundary")
    _sealed_api_identities(files, root, boundary[1])
    return files, build, hashlib.sha256(json.dumps(build, sort_keys=True).encode()).hexdigest()


def artifact_paths():
    return _api_inventory()[0]


def _file_identities(files):
    """Hash every distinct path per boundary; aliases retain separate bindings."""
    observed = {path: digest(path) for path in set(files.values())}
    return {name: observed[path] for name, path in files.items()}


def _sealed_api_identities(files, root, manifest):
    """Project paths from this request's no-follow, fully hashed inventory."""
    identities = {}
    for name, path in files.items():
        # The boundary rejects symlinks at every directory level and hashes all
        # files before/after execution. Re-resolving each ancestor adds no
        # authority; lexical aliases must still never match a manifest entry.
        if not path.is_absolute() or ".." in path.parts:
            raise ValueError("ASCENT API escaped its verified seal")
        try:
            relative = path.relative_to(root).as_posix()
        except ValueError:
            raise ValueError("ASCENT API escaped its verified seal") from None
        if relative not in manifest["files"]:
            raise ValueError("ASCENT API escaped its verified seal")
        identities[name] = manifest["files"][relative]
    return identities


@contextmanager
def engine_api(*, engine=None, retain=False):
    """Context manager yielding (engine, backend_identity), not a direct tuple.

    The engine is valid inside the with block. The receipt-bound C ABI and its
    implementation identities are checked before/after; owned handles close on
    exit unless retain=True. This does not admit a native runtime result.
    """
    engine, identities, files, owned, boundary = _api_entry(engine, retain)
    parent = _active_api.get()
    owner = (os.getpid(), threading.get_ident())
    nested = (parent is not None and parent["owner"] == owner
              and parent["boundary"] is boundary and parent["files"] == files
              and parent["identities"] == identities)
    token = _active_api.set(dict(owner=owner, boundary=boundary,
                                files=dict(files), identities=dict(identities)))
    try:
        yield engine, identities
    except BaseException:
        if owned:
            close_queries(engine)
        raise
    finally:
        try:
            if owned and not retain:
                try:
                    close_queries(engine)
                finally:
                    engine.close()
            if boundary is None and not nested:
                current_files = artifact_paths()
                if current_files != files or _file_identities(files) != identities:
                    if owned:
                        close_queries(engine)
                    raise ValueError("ASCENT implementation changed during audit")
        finally:
            _active_api.reset(token)


def _api_entry(engine, retain):
    """Finish the checked official initialization phase before caller execution."""
    from ascent import Engine
    global _loaded_identity, _retained_engine, _retained_owner
    if type(retain) is not bool:
        raise ValueError("retain must be a boolean")
    files, build, receipt_sha = _api_inventory()
    boundary = _verified_api.get()
    if boundary is None:
        active = _active_api.get()
        # This call's outer boundary rehashes at exit, including exceptional
        # exits. No verdict survives that request, thread or process lifetime.
        if (active is not None and active["owner"] == (os.getpid(), threading.get_ident())
                and active["boundary"] is None and active["files"] == files):
            identities = dict(active["identities"])
        else:
            identities = _file_identities(files)
    else:
        root, manifest = boundary
        identities = _sealed_api_identities(files, root, manifest)
    if build.get("schema") != "ascent.rust-build.v1" or not build.get("rayon"):
        raise ValueError("Rust ASCENT build identity required")
    if identities.get("ascent._core") != build.get("extensionSha256"):
        raise ValueError("installed ASCENT extension does not match its RECORD")
    for prefix, expected in (("source:", build["sourceInputs"]), ("runtime:", build["runtimeInputs"])):
        if any(identities.get(prefix + path) != sha for path, sha in expected.items()):
            raise ValueError("ASCENT compiled inputs do not match the installed artifact")
    if any(identities.get("package:" + path) != sha for path, sha in build["installedInputs"].items()):
        raise ValueError("ASCENT installed wheel inputs do not match their RECORD")
    if _loaded_identity is not None and identities != _loaded_identity:
        if retain and _retained_owner == (os.getpid(), threading.get_ident()):
            close_retained_queries()
        changed = sorted(name for name in identities.keys() | _loaded_identity.keys()
                         if identities.get(name) != _loaded_identity.get(name))
        raise ValueError("ASCENT implementation changed in the loaded process: " + ", ".join(changed))
    owned = engine is None
    # Never hold a permit across the caller's body: it can wait on a sealed
    # child that needs its own initialization or source-construction permit.
    admission = construction_admission() if owned and _loaded_identity is None else nullcontext()
    with admission:
        if owned:
            if retain:
                if _retained_engine is None:
                    _retained_engine = Engine(backend="rust")
                    _retained_owner = (os.getpid(), threading.get_ident())
                    atexit.register(_close_retained_at_exit)
                engine = _retained_engine
            else:
                engine = Engine(backend="rust")
        engine.describe()
    _loaded_identity = identities
    return engine, identities, files, owned, boundary


def close_retained_queries():
    """Release default-call sessions while retaining their explicitly owned Engine."""
    if _retained_engine is not None:
        close_queries(_retained_engine)


def _close_retained_at_exit():
    if (_retained_engine is not None and not _retained_engine.closed
            and _retained_owner == (os.getpid(), threading.get_ident())):
        try:
            close_retained_queries()
        finally:
            _retained_engine.close()


def load_catalog(*paths):
    """Bind DSL text; only the upstream native session lowers its syntax."""
    paths = tuple(Path(path).resolve() for path in paths)
    if not paths:
        raise ValueError("native DSL source required")
    inputs = {str(path): digest(path) for path in paths}
    texts = [path.read_text() for path in paths]
    if any(digest(path) != inputs[str(path)] for path in paths):
        raise ValueError("native ASCENT rule sources changed during loading")
    return {"sourceTexts": texts, "sourceInputs": inputs}


def load_inert_catalog(*paths):
    """Explicit checked rule contract; never downgrade executable DSL text."""
    catalog = load_catalog(*paths)
    catalog["inertRuleTexts"] = catalog.pop("sourceTexts")
    return catalog


def load_evidence_catalog(*paths, constructor=None, arguments=(), trusted=False, limits=None):
    """Bind scenario DSL; imports, scope and expansion belong to the Library."""
    if trusted is not True:
        raise ValueError("trusted Evidence DSL execution must be explicitly authorized")
    paths = tuple(Path(path).resolve() for path in paths)
    if not paths:
        raise ValueError("native module source inventory required")
    inputs = {str(path): digest(path) for path in paths}
    source = '\n'.join(path.read_bytes().decode('utf-8') for path in paths)
    if any(digest(path) != inputs[str(path)] for path in paths):
        raise ValueError("native module source changed during loading")
    return {"nativeEvidence": {"constructor": constructor,
            "arguments": copy.deepcopy(list(arguments)), "source": source, "trusted": True,
            "factLimits": {} if limits is None else limits.wire()},
            "sourceInputs": inputs, "definitionSources": [str(path) for path in paths]}


def _verify_definition_sources(catalog):
    """Bind exact definition bytes; additional observation inputs are not code."""
    if "nativeEvidence" not in catalog:
        return
    paths = catalog.get("definitionSources")
    if (not isinstance(paths, list) or not paths
            or any(not isinstance(path, str) or path not in catalog["sourceInputs"] for path in paths)
            or len(set(paths)) != len(paths)):
        raise ValueError("definition source inventory omits a bound source")
    if any(str(Path(path).resolve(strict=True)) != path for path in paths):
        raise ValueError("definition source alias is not a bound path")
    if any(digest(Path(path)) != catalog['sourceInputs'][path] for path in paths):
        raise ValueError("native ASCENT DSL source generation changed")
    source = '\n'.join(Path(path).read_bytes().decode('utf-8') for path in paths)
    if source != catalog["nativeEvidence"]["source"]:
        raise ValueError("definition bytes differ from their bound sources")


def input_attestations(root, inputs):
    """Name checked inputs by their actual repository or installed owner.

    Package assets already belong to the verified API inventory; their labels
    must survive moving the project without pretending they are project files.
    Every other input must remain inside this repository. No external fallback.
    """
    root = Path(root).resolve(strict=True)
    active = _active_api.get()
    if active is not None and active['owner'] == (os.getpid(), threading.get_ident()):
        # The same API owner checks this inventory at both lifetime boundaries.
        files = active['files']
    else:
        files, _, _ = _api_inventory()
    installed = {path: name for name, path in files.items() if name.startswith('package:')}
    result = {}
    for name, expected in inputs.items():
        path = Path(name).resolve(strict=True)
        if digest(path) != expected:
            raise ValueError('attestation source changed')
        if path in installed:
            label = installed[path]
        else:
            try:
                label = path.relative_to(root).as_posix()
            except ValueError:
                raise ValueError('attestation input has no declared owner') from None
        if label in result and result[label] != expected:
            raise ValueError('attestation input label collision')
        result[label] = expected
    return result


def component_asset(manifest_path, name):
    """Resolve a registered asset; selection and Scheme parsing stay native."""
    if name.startswith("package:"):
        files, _, _ = _api_inventory()
        if name not in files:
            raise ValueError("Evidence component is absent from the installed Library inventory: " + name)
        return files[name]
    relative = Path(name)
    if relative.is_absolute() or ".." in relative.parts or relative.suffix != ".ss":
        raise ValueError("invalid Evidence component asset path")
    parent = Path(manifest_path).resolve().parent
    path = (parent / relative).resolve()
    path.relative_to(parent)
    return path


def load_component_catalog(manifest_path, *, entry, constructor=None, arguments=(),
                           trusted=False, limits=None):
    """Bind separate assets; dependency selection and linking remain in Rust."""
    if trusted is not True:
        raise ValueError("trusted Evidence DSL execution must be explicitly authorized")
    manifest_path = Path(manifest_path).resolve()
    inputs = {str(manifest_path): digest(manifest_path)}
    manifest = json.loads(manifest_path.read_text())
    sources, paths = {}, {}
    for component in manifest["components"]:
        name = component["source"]
        path = component_asset(manifest_path, name)
        inputs[str(path)] = digest(path)
        sources[name] = path.read_text()
        paths[name] = str(path)
    if any(digest(Path(path)) != sha for path, sha in inputs.items()):
        raise ValueError("Evidence component assets changed during loading")
    # The existing native Module selects and validates its dependency closure.
    # Python only transports that selection; it must not implement a second linker.
    with engine_api(retain=True) as (engine, _):
        with engine.components(manifest, sources, entry, trusted=True) as module:
            selected = set(module.components)
    components = [component for component in manifest["components"] if component["id"] in selected]
    # Declaration order is part of the native read contract across processes.
    names = list(dict.fromkeys(component["source"] for component in components))
    manifest = {**manifest, "components": components}
    sources = {name: sources[name] for name in names}
    inputs = {str(manifest_path): inputs[str(manifest_path)],
              **{paths[name]: inputs[paths[name]] for name in names}}
    return {"nativeComponents": {"manifest": manifest, "sources": sources,
            "entry": entry, "constructor": constructor, "arguments": copy.deepcopy(list(arguments)),
            "trusted": True, "factLimits": {} if limits is None else limits.wire()},
            "sourceInputs": inputs}


@contextmanager
def definitions(catalog, *, engine=None):
    """Own general scenario values without requiring a table or proof projection.

    The same individually bound assets used by queries enter the Library's
    ordinary DSL/component loader. Source and implementation identities are
    checked before and after the owner lifetime, including exceptional exits.
    """
    catalog = copy.deepcopy(catalog)
    sources = catalog.get("sourceInputs", {})
    if not sources or sum(key in catalog for key in ("nativeEvidence", "nativeComponents")) != 1:
        raise ValueError("bound Evidence definitions or components required")

    def check():
        if any(digest(Path(path)) != sha for path, sha in sources.items()):
            raise ValueError("Evidence definitions changed during their owner lifetime")

    check()
    _verify_definition_sources(catalog)
    if "nativeComponents" in catalog:
        spec = catalog["nativeComponents"]
        manifests = [path for path in sources if Path(path).suffix == ".json"]
        if len(manifests) != 1:
            raise ValueError("one bound Evidence component manifest required")
        actual = load_component_catalog(manifests[0], entry=spec["entry"], trusted=spec["trusted"])
        if (actual["sourceInputs"] != sources
                or actual["nativeComponents"]["manifest"] != spec["manifest"]
                or actual["nativeComponents"]["sources"] != spec["sources"]):
            raise ValueError("Evidence component bytes differ from their bound sources")
    else:
        spec = catalog["nativeEvidence"]
        actual = load_evidence_catalog(*catalog["definitionSources"], trusted=spec["trusted"])
        if (any(sources.get(path) != sha for path, sha in actual["sourceInputs"].items())
                or actual["nativeEvidence"]["source"] != spec["source"]):
            raise ValueError("Evidence definition bytes differ from their bound sources")
    with engine_api(engine=engine) as (selected, identities):
        if "nativeComponents" in catalog:
            spec = catalog["nativeComponents"]
            owner = selected.components(spec["manifest"], spec["sources"], spec["entry"],
                                        trusted=spec["trusted"])
        else:
            spec = catalog["nativeEvidence"]
            owner = selected.dsl(spec["source"], trusted=spec["trusted"])
        with owner:
            try:
                yield owner, {"name": "ascent-rust", "inputs": identities,
                              "sourceInputs": dict(sources),
                              "entry": "trusted-evidence-definitions.v1",
                              "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
            finally:
                check()


def build_sources(build, *, sealed_engine=None):
    """Resolve every actual build input, independently of language/module names."""
    from gambit_smp.ascent_runtime import inventory
    boundary = _verified_api.get()
    root = Path(sealed_engine).resolve(strict=True) if sealed_engine is not None else (
        boundary[0] if boundary is not None else None)
    if root is not None:
        from gambit_smp.research_kernel import manifest_paths
        manifest = manifest_paths(root)
        actual = json.loads((root / "ascent-build.json").read_text())
        sources = {}
        for name, sha in actual["sourceInputs"].items():
            relative = Path(name)
            if relative.is_absolute() or ".." in relative.parts:
                raise ValueError("invalid build source path")
            target = "provider-source/" + relative.as_posix()
            if manifest["files"].get(target) != sha:
                raise ValueError("sealed compiled source is not an exact build input")
            sources[name] = {"path": str(root / target), "sha256": sha}
    else:
        _, actual = inventory()
        sources = {name: {"path": str(Path(actual["sourceRoot"]) / name), "sha256": sha}
                   for name, sha in actual["sourceInputs"].items()}
    if (build.get("schema") != "ascent.rust-build.v1"
            or build.get("sourceInputs") != actual["sourceInputs"]
            or build.get("runtimeInputs") != actual["runtimeInputs"]):
        raise ValueError("compiled Rust provider source identity mismatch")
    if any(digest(Path(entry["path"])) != entry["sha256"] for entry in sources.values()):
        raise ValueError("build source changed after binding")
    return sources


def assemble(facts, catalog, queries, *, engine=None):
    """Transport complete inputs to Scheme's authority-preserving proof slice."""
    if any(key in catalog for key in ("sourceTexts", "inertRuleTexts", "nativeEvidence", "nativeComponents")):
        projection = catalog.get("projection", {})
        if projection.get("status") != "supported":
            raise ValueError("native DSL lacks a lossless finite proof projection")
        catalog = dict(projection["program"], sourceInputs=catalog["sourceInputs"])
        catalog.pop("queries", None)
    if (not isinstance(catalog, dict) or not {"relations", "rules"} <= set(catalog)
            or set(catalog) - {"relations", "rules", "sourceInputs"}):
        raise ValueError("native ASCENT catalog object required; rule text is unsupported")
    from ascent import EngineError
    def request(active):
        try:
            from ascent.derivations import slice_program
            return slice_program({"relations": catalog["relations"], "rules": catalog["rules"]},
                                 facts, list(queries.values()))
        except EngineError as error:
            raise ValueError(str(error)) from error
    if engine is not None:
        return request(engine)
    with engine_api(retain=True) as (active, _):
        return request(active)


class SourceQueryOwner:
    """Retain the actual upstream DSL program/session across query subsets."""
    def __init__(self, engine, facts, catalog):
        _verify_definition_sources(catalog)
        entry = ("open-components" if "nativeComponents" in catalog else
                 "open-evidence" if "nativeEvidence" in catalog else
                 "open-rule-sources" if "inertRuleTexts" in catalog else "open-sources")
        if not callable(getattr(engine, "describe", None)):
            raise ValueError("installed ASCENT engine lacks the upstream native DSL entry")
        description = engine.describe()
        if entry not in description.get("operations", []):
            raise ValueError("installed ASCENT engine lacks the upstream native DSL entry")
        if entry == "open-rule-sources" and description.get("ruleTextContract") != INERT_RULE_CONTRACT:
            raise ValueError("installed ASCENT inert rule contract mismatch")
        self.engine, self.catalog = engine, catalog
        self.pid, self.thread = os.getpid(), threading.get_ident()
        self.owner_token = uuid.uuid4().hex
        self.closed, self.rounds, self.generation = False, 0, 0
        self.context_changed = False
        self.last_result = None
        self.result_handle = None
        if entry == "open-components":
            from ascent import FactLimits
            declaration = catalog["nativeComponents"]
            with engine.components(declaration["manifest"], declaration["sources"],
                                   declaration["entry"], trusted=declaration["trusted"]) as module:
                with module.call(declaration["constructor"], *declaration["arguments"]) as value:
                    self.session = value.open_session(limits=FactLimits(**declaration.get("factLimits", {})))
        elif entry == "open-evidence":
            from ascent import FactLimits
            declaration = catalog["nativeEvidence"]
            self.session = engine.evidence(declaration["source"], declaration["constructor"],
                *declaration["arguments"], trusted=declaration["trusted"],
                limits=FactLimits(**declaration.get("factLimits", {})))
        elif entry == "open-rule-sources":
            self.session = engine.open_rule_sources(*catalog["inertRuleTexts"])
        else:
            self.session = engine.open_sources(*catalog["sourceTexts"])
        try:
            self._check()
            catalog["projection"] = copy.deepcopy(self.session.projection)
            catalog["relations"] = copy.deepcopy(self.session.descriptors)
            self.sources = self._sources(facts)
            initial = self.session.run(queries=[])
            if "resultHandle" in initial:
                self.session.result(initial).close()
            if not initial["complete"]:
                raise ValueError("native ASCENT initial deadline incomplete")
            if self.sources:
                self.session.replace(self.sources)
        except Exception:
            self.session.close()
            raise

    def _check(self):
        if self.closed or self.pid != os.getpid() or self.thread != threading.get_ident():
            raise ValueError("closed or foreign ASCENT query owner")
        if any(digest(Path(path)) != sha for path, sha in self.catalog["sourceInputs"].items()):
            raise ValueError("native ASCENT DSL source generation changed")

    def bind_source_context(self, catalog):
        """Reuse only byte-identical source programs, never their old bindings."""
        if self.closed or self.pid != os.getpid() or self.thread != threading.get_ident():
            raise ValueError("closed or foreign ASCENT query owner")
        _verify_definition_sources(catalog)
        entry = next((key for key in ("sourceTexts", "inertRuleTexts", "nativeEvidence", "nativeComponents")
                      if key in catalog), None)
        if entry not in catalog or catalog[entry] != self.catalog.get(entry):
            raise ValueError("source program changed during context binding")
        if any(digest(Path(path)) != sha for path, sha in catalog["sourceInputs"].items()):
            raise ValueError("native ASCENT DSL source generation changed")
        if catalog["sourceInputs"] != self.catalog["sourceInputs"]:
            self.catalog = catalog
            self.context_changed = True

    def _sources(self, facts):
        declarations = {row["name"]: row for row in self.session.descriptors}
        if any(name in declarations and not declarations[name]["source"] and rows
               for name, rows in facts.items()):
            raise ValueError("derived relation cannot contain source facts")
        if any(key in self.catalog for key in ("nativeEvidence", "nativeComponents")):
            sources = copy.deepcopy(getattr(self, "sources", {}))
            sources.update({name: copy.deepcopy(rows) for name, rows in facts.items()
                            if name in declarations and declarations[name]["source"]})
            return sources
        return {name: copy.deepcopy(facts.get(name, [])) for name, row in declarations.items()
                if row["source"]}

    def evaluate(self, facts, queries, timeout_nanoseconds):
        self._check()
        if not queries or any(name not in self.session.queries for name in queries.values()):
            raise ValueError("queries must name declared native ASCENT relations")
        sources = self._sources(facts)
        rebound = self.context_changed
        if sources != self.sources or rebound:
            self.session.replace(sources)
            self.sources = sources
            self.generation += 1
            self.context_changed = False
        result = self.session.run(timeout_nanoseconds, queries=sorted(set(queries.values())))
        if self.last_result is not None:
            self.last_result.close()
        self.last_result = self.session.result(result) if "resultHandle" in result else None
        self.result_handle = result.get("resultHandle")
        if not result["complete"]:
            raise ValueError("native ASCENT investigation deadline incomplete")
        self.rounds += 1
        if result.get("scalarProjection", "supported") == "supported":
            answers = {label: sorted((tuple(row) for row in result["relations"][name]),
                       key=lambda row: tuple((type(value).__name__, value) for value in row))
                       for label, name in queries.items()}
        else:
            answers = {label: self.last_result.rows(name) for label, name in queries.items()}
        from ascent.evidence import identity
        declaration = self.catalog.get("nativeComponents", self.catalog.get("nativeEvidence"))
        source_identity = ({"module": declaration,
                            "inputs": self.catalog["sourceInputs"], "updates": self.sources}
                           if declaration else self.sources)
        return answers, {"sourceIdentity": identity(source_identity),
                         "sourceGeneration": result["sourceGeneration"],
                         "investigationRound": self.rounds, "retainedOwner": True,
                         "sourceContextRebound": rebound,
                         "nativeResultReused": result["nativeResultReused"],
                         "nativeRunIndex": result["runIndex"],
                         "nativeEvaluationPath": result["evaluationPath"],
                         "nativeReusedRelations": result["reusedRelations"],
                         "nativeActiveRuleCount": result["activeRuleCount"],
                         "nativeResultHandle": result.get("resultHandle"),
                         "sessionOwner": self.owner_token,
                         "sessionOwnerScope": "consumer-process-lifetime-token; not a native handle or authority",
                         "nativeFactLimits": self.session.fact_limits,
                         "resultEncoding": result.get("scalarProjection", "supported"),
                         "proofProjection": self.session.projection["status"],
                         "ruleSyntax": ("ascent.evidence-components.v1" if "nativeComponents" in self.catalog else
                                        "trusted-evidence-dsl.v1" if "nativeEvidence" in self.catalog else
                                        INERT_RULE_CONTRACT if "inertRuleTexts" in self.catalog
                                        else "upstream-ascent-dsl.v1"),
                         "ruleSourceInputs": dict(self.catalog["sourceInputs"]),
                         "transportSyntax": "native-source-session.v1"}

    def close(self):
        if not self.closed:
            # Withdrawal must remain possible after the source file changed.
            if self.pid != os.getpid() or self.thread != threading.get_ident():
                raise ValueError("foreign ASCENT query owner")
            if self.last_result is not None:
                self.last_result.close()
            self.session.close()
            self.closed = True


def result_explanation(engine, owner_token, result_handle, relation):
    """Return the typed explanation owner only for this live retained result."""
    for owner in _query_owners.get(engine, {}).values():
        if owner.owner_token == owner_token and owner.result_handle == result_handle:
            owner._check()
            if owner.last_result is None or owner.last_result.closed:
                break
            return owner.last_result.explanation(relation)
    raise ValueError("closed or foreign ASCENT result owner")


def close_queries(engine):
    """Release retained sessions, never shut down the process runtime."""
    owners = _query_owners.pop(engine, {})
    for owner in list(owners.values()):
        owner.close()
    owners.clear()
    support = sys.modules.get("gambit_smp.native_support")
    if support is not None:
        support.close_support(engine)


def evaluate(engine, facts, catalog, queries, *, timeout_nanoseconds=1000000000, reuse_program=False):
    from ascent.evidence import identity
    entries = [key for key in ("sourceTexts", "inertRuleTexts", "nativeEvidence", "nativeComponents") if key in catalog]
    if len(entries) != 1 or not catalog.get("sourceInputs"):
        raise ValueError("one source-bound Library entry required; decoded rule dictionaries are not an execution entry")
    entry_key = ("nativeComponents" if "nativeComponents" in catalog else
                 "nativeEvidence" if "nativeEvidence" in catalog else
                 "inertRuleTexts" if "inertRuleTexts" in catalog else "sourceTexts")
    if type(reuse_program) is not bool:
        raise ValueError("reuse_program must be a boolean")
    reuse_source = reuse_program and entry_key in {"sourceTexts", "inertRuleTexts", "nativeEvidence", "nativeComponents"}
    text_entry = entry_key in {"sourceTexts", "inertRuleTexts"}
    key = (identity({entry_key: catalog[entry_key], "reuseSourceProgram": True})
           if reuse_source and not text_entry else
           identity({entry_key: catalog[entry_key],
                     "sourceDigests": sorted(catalog["sourceInputs"].values()),
                     "reuseSourceProgram": True}) if reuse_source else
           identity({name: catalog[name] for name in (entry_key, "sourceInputs")}))
    owners = _query_owners.setdefault(engine, {})
    if key not in owners:
        if len(owners) >= 4:
            owners.pop(next(iter(owners))).close()
        owners[key] = SourceQueryOwner(engine, facts, catalog)
    owner = owners[key]
    owners.pop(key)
    owners[key] = owner
    try:
        if reuse_source:
            owner.bind_source_context(catalog)
        catalog["projection"] = copy.deepcopy(owner.session.projection)
        catalog["relations"] = copy.deepcopy(owner.session.descriptors)
        return owner.evaluate(facts, queries, timeout_nanoseconds)
    except Exception:
        owners.pop(key).close()
        raise


def query(facts, catalog, queries, *, engine=None, metrics=None, reuse_program=False):
    """One production inference path. Missing native artifacts never fall back."""
    if engine is None:
        with engine_api(retain=True) as (selected, identities):
            answers, observed = evaluate(selected, facts, catalog, queries, reuse_program=reuse_program)
        observed.update(name="ascent-rust", inputs=identities)
    else:
        answers, observed = evaluate(engine, facts, catalog, queries, reuse_program=reuse_program)
        observed.update(name="ascent-rust", externallyManaged=True)
    if metrics is not None:
        metrics.update(observed)
    return answers
