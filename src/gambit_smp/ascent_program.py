"""Identity-bound native ASCENT programs; no legacy rule-text frontend."""
from contextlib import contextmanager
import atexit
import copy
import importlib
import json
from pathlib import Path
import platform
import os
import threading

from gambit_smp.framework import digest

_loaded_identity = None
_retained_engine = None
_retained_owner = None


def artifact_paths():
    extension = Path(importlib.import_module("_ascent_cffi").__file__).resolve()
    files = {"extension": extension, "library": extension.parent / (
        "libascent.dylib" if platform.system() == "Darwin" else "libascent.so"),
        "buildReceipt": extension.parent / "receipt.json"}
    build = json.loads(files["buildReceipt"].read_text())
    for name in build.get("syntaxResources", {}):
        path = Path(name)
        if path.is_absolute() or ".." in path.parts:
            raise ValueError("invalid native syntax resource path")
        files["syntax:" + name] = extension.parent / "syntax" / path
    for name in ("ascent_engine", "ascent_engine.derivations", "ascent_engine.evidence",
                 "ascent_engine.datalog_symbols",
                 "ascent_engine.operators", "ascent_engine.review"):
        files[name] = Path(importlib.import_module(name).__file__)
    return files


@contextmanager
def engine_api(*, engine=None, retain=False):
    """Require the real compiled API and bind its implementation before/after."""
    from ascent_engine import Engine
    global _loaded_identity, _retained_engine, _retained_owner
    if type(retain) is not bool:
        raise ValueError("retain must be a boolean")
    files = artifact_paths()
    identities = {name: digest(path) for name, path in files.items()}
    build = json.loads(files["buildReceipt"].read_text())
    if (build.get("schema") != "ascent.cffi-api-build.v1"
            or build.get("extensionSha256") != identities["extension"]
            or build.get("librarySha256") != identities["library"]
            or any(identities["syntax:" + name] != sha for name, sha in build.get("syntaxResources", {}).items())):
        raise ValueError("ASCENT API artifacts do not match build receipt")
    if _loaded_identity is not None and identities != _loaded_identity:
        if retain and _retained_owner == (os.getpid(), threading.get_ident()):
            close_retained_queries()
        raise ValueError("ASCENT implementation changed in the loaded process")
    # Gambit shutdown is terminal. Binding atexit owns process teardown;
    # individual queries close their EvidenceChain sessions, not the runtime.
    owned = engine is None
    if owned:
        if retain:
            if _retained_engine is None:
                _retained_engine = Engine()
                _retained_owner = (os.getpid(), threading.get_ident())
                atexit.register(_close_retained_at_exit)
            engine = _retained_engine
        else:
            engine = Engine()
    engine.request({"operation": "describe"})
    _loaded_identity = identities
    try:
        yield engine, identities
    except BaseException:
        if owned:
            close_queries(engine)
        raise
    finally:
        if owned and not retain:
            close_queries(engine)
        if any(digest(path) != identities[name] for name, path in files.items()):
            if owned:
                close_queries(engine)
            raise ValueError("ASCENT implementation changed during audit")


def close_retained_queries():
    """Release default-call sessions explicitly, without shutting down Gambit."""
    if _retained_engine is not None:
        close_queries(_retained_engine)


def _close_retained_at_exit():
    if (_retained_engine is not None and not _retained_engine.closed
            and _retained_owner == (os.getpid(), threading.get_ident())):
        close_retained_queries()


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


def load_module_catalog(module, constructor, arguments, *, inputs):
    """Bind a compiled native module entry, without parsing Scheme in Python.

    Inputs are the host's source/build identity inventory. The native API's
    checked resource receipt separately binds the actually loaded module.
    This is execution context, not proof admission or host authorization.
    """
    paths = [Path(path).resolve() for path in inputs]
    if not paths:
        raise ValueError("native Evidence module identity inventory required")
    return {"nativeModule": {"module": module, "constructor": constructor,
                             "arguments": copy.deepcopy(arguments)},
            "sourceInputs": {str(path): digest(path) for path in paths}}


def load_evidence_catalog(*paths, constructor=None, arguments=(), trusted=False, limits=None):
    """Bind scenario DSL; imports, scope and expansion belong to the Library."""
    if trusted is not True:
        raise ValueError("trusted host Scheme execution must be explicitly authorized")
    paths = tuple(Path(path).resolve() for path in paths)
    if not paths:
        raise ValueError("native module source inventory required")
    inputs = {str(path): digest(path) for path in paths}
    source = '\n'.join(path.read_text() for path in paths)
    if any(digest(path) != inputs[str(path)] for path in paths):
        raise ValueError("native module source changed during loading")
    return {"nativeEvidence": {"constructor": constructor,
            "arguments": copy.deepcopy(list(arguments)), "source": source, "trusted": True,
            "factLimits": {} if limits is None else limits.wire()},
            "sourceInputs": inputs}


def load_component_catalog(manifest_path, *, entry, constructor=None, arguments=(),
                           trusted=False, limits=None):
    """Bind separate assets; dependency selection and linking remain in Scheme."""
    if trusted is not True:
        raise ValueError("trusted host Scheme execution must be explicitly authorized")
    manifest_path = Path(manifest_path).resolve()
    inputs = {str(manifest_path): digest(manifest_path)}
    manifest = json.loads(manifest_path.read_text())
    sources = {}
    for component in manifest["components"]:
        name = component["source"]
        relative = Path(name)
        if relative.is_absolute() or ".." in relative.parts or relative.suffix != ".ss":
            raise ValueError("invalid Evidence component asset path")
        path = (manifest_path.parent / relative).resolve()
        path.relative_to(manifest_path.parent)
        inputs[str(path)] = digest(path)
        sources[name] = path.read_text()
    if any(digest(Path(path)) != sha for path, sha in inputs.items()):
        raise ValueError("Evidence component assets changed during loading")
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
        actual = load_evidence_catalog(*sources, trusted=spec["trusted"])
        if actual["sourceInputs"] != sources or actual["nativeEvidence"]["source"] != spec["source"]:
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
                yield owner, {"name": "ascent-cffi-api", "inputs": identities,
                              "sourceInputs": dict(sources),
                              "entry": "trusted-evidence-definitions.v1",
                              "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
            finally:
                check()


@contextmanager
def modules(module):
    """Agentic AI access to upstream objects, without a Catalog tier.

    Native constructors, closures, plans and sessions remain owned by Scheme.
    The host binds all compiled source identities; results and explanations
    are observations, not permissions or source-refinement certificates.
    """
    with engine_api() as (engine, identities):
        build = engine.build_receipt or {}
        producer = build.get("producerBuild", build)
        linked = producer.get("linkedSchemeSources", {})
        if module.lstrip(":") not in linked:
            raise ValueError("native module is not bound to the compiled producer")
        sources = {str(Path(entry["path"]).resolve()): entry["sha256"] for entry in linked.values()}
        def check():
            if any(digest(Path(path)) != sha for path, sha in sources.items()):
                raise ValueError("native module source changed after its compiled producer")
        check()
        with engine.module(module) as owner:
            try:
                yield owner, {"name": "ascent-cffi-api", "inputs": identities,
                              "compiledSources": sources,
                              "entry": "trusted-native-module-calls.v1",
                              "runtimeAdmitted": False, "sourceRefinementAdmitted": False}
            finally:
                check()


def assemble(facts, catalog, queries):
    """Select a complete dependency slice and attach typed source rows."""
    if any(key in catalog for key in ("sourceTexts", "nativeModule", "nativeEvidence", "nativeComponents")):
        projection = catalog.get("projection", {})
        if projection.get("status") != "supported":
            raise ValueError("native DSL lacks a lossless finite proof projection")
        catalog = dict(projection["program"], sourceInputs=catalog["sourceInputs"])
        catalog.pop("queries", None)
    if (not isinstance(catalog, dict) or not {"relations", "rules"} <= set(catalog)
            or set(catalog) - {"relations", "rules", "sourceInputs"}):
        raise ValueError("native ASCENT catalog object required; rule text is unsupported")
    declarations = {row["name"]: row for row in catalog["relations"]}
    if len(declarations) != len(catalog["relations"]):
        raise ValueError("duplicate relation declaration")
    if not queries or any(not isinstance(name, str) or name not in declarations
                          for name in queries.values()):
        raise ValueError("queries must name declared native ASCENT relations")
    definitions = {}
    for index, rule in enumerate(catalog["rules"]):
        if set(rule) != {"head", "body"} or not rule["head"] or not rule["body"]:
            raise ValueError("native ASCENT head/body rule required")
        for head in rule["head"]:
            name = head["relation"]
            if name not in declarations or declarations[name]["source"]:
                raise ValueError("rule head must name a derived relation")
            definitions.setdefault(name, []).append(index)
    pending, used, selected = list(queries.values()), set(), set()
    while pending:
        name = pending.pop()
        if name in used:
            continue
        if name not in declarations:
            raise ValueError("undeclared native ASCENT dependency: " + name)
        used.add(name)
        for index in definitions.get(name, []):
            selected.add(index)
            rule = catalog["rules"][index]
            pending.extend(clause["relation"] for clause in rule["head"] + rule["body"]
                           if "relation" in clause)
        if not declarations[name]["source"] and name not in definitions:
            raise ValueError("derived relation has no rule: " + name)
    relations = []
    kinds = {"symbol": str, "integer": int, "boolean": bool}
    for name in sorted(used):
        relation = copy.deepcopy(declarations[name])
        if relation["source"] and name not in facts:
            raise ValueError("undeclared source facts: " + name)
        if not relation["source"] and facts.get(name):
            raise ValueError("derived relation cannot contain source facts: " + name)
        rows = facts.get(name, []) if relation["source"] else []
        columns = relation["columns"]
        if any(len(row) != len(columns) or any(type(value) is not kinds[column["kind"]]
               for value, column in zip(row, columns)) for row in rows):
            raise ValueError("source row violates native relation type: " + name)
        relation["rows"] = [list(row) for row in rows]
        relations.append(relation)
    return {"relations": relations, "rules": [copy.deepcopy(catalog["rules"][index])
            for index in sorted(selected)], "queries": sorted(set(queries.values()))}


class QueryOwner:
    """Bounded process/thread owner for one rule generation and source snapshot."""
    def __init__(self, engine, facts, catalog):
        from ascent_engine.derivations import EvidenceChain
        from ascent_engine.datalog_symbols import encode
        self.engine, self.catalog = engine, copy.deepcopy(catalog)
        self.pid, self.thread = os.getpid(), threading.get_ident()
        self.closed, self.rounds, self.generation = False, 0, 0
        self.sources = self._sources(facts)
        encoded, _ = encode({"relations": self.sources, "rules": [], "queries": []})
        self.chain = EvidenceChain(engine, encoded["relations"])

    def _check(self):
        if self.closed or self.pid != os.getpid() or self.thread != threading.get_ident():
            raise ValueError("closed or foreign ASCENT query owner")

    def _sources(self, facts):
        names = {row["name"]: row["name"] for row in self.catalog["relations"] if row["source"]}
        # Missing unrelated sources are empty, but assemble still rejects a missing
        # required source in each actual query before this owner is consumed.
        rows = {name: facts.get(name, []) for name in names}
        return assemble(rows, self.catalog, names)["relations"]

    def evaluate(self, facts, queries):
        from ascent_engine.datalog_symbols import encode
        self._check()
        selected = assemble(facts, self.catalog, queries)
        sources = self._sources(facts)
        encoded, _ = encode({"relations": sources, "rules": [], "queries": []})
        if sources != self.sources:
            self.chain.replace(encoded["relations"])
            self.sources = sources
            self.generation += 1
        selected["relations"] = sources + [row for row in selected["relations"] if not row["source"]]
        program, symbols = encode(selected)
        result = self.chain.query(program)
        repeated = self.chain.query(program)
        self.rounds += 1
        return result, repeated, symbols

    def close(self):
        if not self.closed:
            self._check()
            self.chain.close()
            self.closed = True

    def __enter__(self):
        self._check()
        return self

    def __exit__(self, *exc):
        self.close()


class SourceQueryOwner:
    """Retain the actual upstream DSL program/session across query subsets."""
    def __init__(self, engine, facts, catalog):
        entry = ("open-components" if "nativeComponents" in catalog else
                 "open-evidence" if "nativeEvidence" in catalog else
                 "open-module" if "nativeModule" in catalog else "open-sources")
        if entry not in engine.request({"operation": "describe"}).get("operations", []):
            raise ValueError("installed ASCENT engine lacks the upstream native DSL entry")
        self.engine, self.catalog = engine, catalog
        self.pid, self.thread = os.getpid(), threading.get_ident()
        self.closed, self.rounds, self.generation = False, 0, 0
        self.last_result = None
        if entry == "open-components":
            from ascent_engine import FactLimits
            declaration = catalog["nativeComponents"]
            self.session = engine.evidence_components(declaration["manifest"], declaration["sources"],
                declaration["entry"], declaration["constructor"], *declaration["arguments"],
                trusted=declaration["trusted"], limits=FactLimits(**declaration.get("factLimits", {})))
        elif entry == "open-evidence":
            from ascent_engine import FactLimits
            declaration = catalog["nativeEvidence"]
            self.session = engine.evidence(declaration["source"], declaration["constructor"],
                *declaration["arguments"], trusted=declaration["trusted"],
                limits=FactLimits(**declaration.get("factLimits", {})))
        elif entry == "open-module":
            declaration = catalog["nativeModule"]
            receipt = getattr(engine, "build_receipt", None) or {}
            producer = receipt.get("producerBuild", receipt)
            bound = producer.get("linkedSchemeSources", {}).get(declaration["module"].lstrip(":"))
            if (not bound or catalog["sourceInputs"].get(str(Path(bound["path"]).resolve())) != bound["sha256"]):
                raise ValueError("native Evidence module source does not match the compiled producer")
            self.session = engine.open_module(declaration["module"], declaration["constructor"],
                                              *declaration["arguments"])
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

    def _sources(self, facts):
        declarations = {row["name"]: row for row in self.session.descriptors}
        if any(name in declarations and not declarations[name]["source"] and rows
               for name, rows in facts.items()):
            raise ValueError("derived relation cannot contain source facts")
        if any(key in self.catalog for key in ("nativeModule", "nativeEvidence", "nativeComponents")):
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
        if sources != self.sources:
            self.session.replace(sources)
            self.sources = sources
            self.generation += 1
        result = self.session.run(timeout_nanoseconds, queries=sorted(set(queries.values())))
        if self.last_result is not None:
            self.last_result.close()
        self.last_result = self.session.result(result) if "resultHandle" in result else None
        if not result["complete"]:
            raise ValueError("native ASCENT investigation deadline incomplete")
        self.rounds += 1
        if result.get("scalarProjection", "supported") == "supported":
            answers = {label: sorted((tuple(row) for row in result["relations"][name]),
                       key=lambda row: tuple((type(value).__name__, value) for value in row))
                       for label, name in queries.items()}
        else:
            answers = {label: self.last_result.rows(name) for label, name in queries.items()}
        from ascent_engine.evidence import identity
        declaration = self.catalog.get("nativeComponents", self.catalog.get("nativeEvidence", self.catalog.get("nativeModule")))
        source_identity = ({"module": declaration,
                            "inputs": self.catalog["sourceInputs"], "updates": self.sources}
                           if declaration else self.sources)
        return answers, {"sourceIdentity": identity(source_identity),
                         "sourceGeneration": result["sourceGeneration"],
                         "investigationRound": self.rounds, "retainedOwner": True,
                         "nativeResultReused": result["nativeResultReused"],
                         "nativeRunIndex": result["runIndex"],
                         "nativeEvaluationPath": result["evaluationPath"],
                         "nativeReusedRelations": result["reusedRelations"],
                         "nativeActiveRuleCount": result["activeRuleCount"],
                         "nativeResultHandle": result.get("resultHandle"),
                         "nativeSessionHandle": self.session.handle,
                         "nativeFactLimits": self.session.fact_limits,
                         "resultEncoding": result.get("scalarProjection", "supported"),
                         "proofProjection": self.session.projection["status"],
                         "ruleSyntax": ("ascent.evidence-components.v1" if "nativeComponents" in self.catalog else
                                        "trusted-host-scheme.v1" if "nativeEvidence" in self.catalog else
                                        "trusted-native-evidence-module.v1" if "nativeModule" in self.catalog
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


def close_queries(engine):
    """Release retained sessions, never shut down the process runtime."""
    owners = getattr(engine, "_gambit_query_owners", {})
    for owner in list(owners.values()):
        owner.close()
    owners.clear()
    from gambit_smp.native_support import close_support
    close_support(engine)


def evaluate(engine, facts, catalog, queries, *, timeout_nanoseconds=1000000000):
    from ascent_engine.evidence import identity
    native_text = any(key in catalog for key in ("sourceTexts", "nativeModule", "nativeEvidence", "nativeComponents"))
    entry_key = ("nativeComponents" if "nativeComponents" in catalog else
                 "nativeEvidence" if "nativeEvidence" in catalog else
                 "nativeModule" if "nativeModule" in catalog else "sourceTexts")
    key = identity({name: catalog[name] for name in (entry_key, "sourceInputs")}) if native_text else identity(catalog)
    owners = getattr(engine, "_gambit_query_owners", None)
    if owners is None:
        owners = engine._gambit_query_owners = {}
    if key not in owners:
        if len(owners) >= 4:
            owners.pop(next(iter(owners))).close()
        owners[key] = (SourceQueryOwner if native_text else QueryOwner)(engine, facts, catalog)
    owner = owners[key]
    owners.pop(key)
    owners[key] = owner
    try:
        if native_text:
            catalog["projection"] = copy.deepcopy(owner.session.projection)
            catalog["relations"] = copy.deepcopy(owner.session.descriptors)
            return owner.evaluate(facts, queries, timeout_nanoseconds)
        result, repeated, symbols = owner.evaluate(facts, queries)
    except Exception:
        owners.pop(key).close()
        raise
    if result["result"] != repeated["result"] or not result["result"].get("complete"):
        raise ValueError("ASCENT audit did not return a stable complete result")
    def decode(value):
        if isinstance(value, str):
            if value not in symbols:
                raise ValueError("unknown native ASCENT symbol")
            return symbols[value]
        return value
    answers = {label: sorted((tuple(decode(value) for value in row)
               for row in result["result"]["relations"][name]),
               key=lambda row: tuple((type(value).__name__, value) for value in row))
               for label, name in queries.items()}
    return answers, {"sourceIdentity": result["sourceIdentity"],
                     "pathIdentity": result["pathIdentity"],
                     "freshComponents": len(result["freshComponents"]),
                     "reusedComponents": len(result["reusedComponents"]),
                     "investigationRound": owner.rounds,
                     "sourceGeneration": owner.generation,
                     "retainedOwner": True,
                     "repeatReusedComponents": len(repeated["reusedComponents"]),
                     "repeatPurpose": "stability-control-not-investigation-work-saved",
                     "ruleSyntax": "inert-relational-subset.v1",
                     "ruleSourceInputs": catalog.get("sourceInputs", {}),
                     "transportSyntax": "ascent-native-wire.v1"}


def query(facts, catalog, queries, *, engine=None, metrics=None):
    """One production inference path. Missing native artifacts never fall back."""
    if engine is None:
        with engine_api(retain=True) as (selected, identities):
            answers, observed = evaluate(selected, facts, catalog, queries)
        observed.update(name="ascent-cffi-api", inputs=identities)
    else:
        answers, observed = evaluate(engine, facts, catalog, queries)
        observed.update(name="ascent-cffi-api", externallyManaged=True)
    if metrics is not None:
        metrics.update(observed)
    return answers
