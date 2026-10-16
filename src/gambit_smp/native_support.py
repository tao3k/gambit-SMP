"""Lossless positive-program transport into the existing native proof store.

No rule is authored or evaluated here. Unsupported wire clauses remain gaps;
the Scheme store admits, computes and checks every published support fragment.
"""
from copy import deepcopy
from contextlib import contextmanager

from gambit_smp.ascent_program import assemble

_stores = {}


def candidate_transport(program, relation):
    declarations = {row["name"]: row for row in program["relations"]}
    candidate = ["candidate"]
    candidate.extend(["relation", row["name"], len(row["columns"])]
                     for row in program["relations"] if not row["source"])

    def atom(value):
        if value.get("not") or "mode" in value:
            raise ValueError("positive atom support only; negation/operators require upstream proof capability")
        return [value["relation"], *["?" + term["var"] if "var" in term else term["const"]
                                     for term in value["terms"]]]

    for rule in program["rules"]:
        if len(rule["head"]) != 1:
            raise ValueError("multi-head support transport is unsupported")
        candidate.append(["rule", atom(rule["head"][0]), *map(atom, rule["body"])])
    candidate.extend([["query", relation, *["?q" + str(index) for index in
                         range(len(declarations[relation]["columns"]))]],
                      ["limits", "unlimited", "unlimited", "unlimited"]])
    return candidate


def close_support(engine):
    store = _stores.pop(engine, None)
    if store is not None:
        store.close()


@contextmanager
def retained_support(engine):
    from ascent.evidence import ComputationalEvidence
    store = _stores.get(engine)
    if store is None:
        store = _stores[engine] = ComputationalEvidence(engine)
    try:
        yield store
    except Exception:
        close_support(engine)
        raise


def observe(engine, facts, catalog, requests, *, generation=0):
    """Observe requested native conclusions; never turn unsupported into proof."""
    from ascent.evidence import identity
    from ascent import EngineError
    packets = []
    rejection = None
    if not isinstance(requests, dict) or not requests:
        return packets
    with retained_support(engine) as store:
        for relation, requested in sorted(requests.items()):
            if not requested:
                continue
            if (any(key in catalog for key in ("sourceTexts", "nativeEvidence", "nativeComponents"))
                    and catalog.get("projection", {}).get("status") != "supported"):
                packets.append({"schema": "native-computational-observation.v1", "relation": relation,
                    "requested": [list(row) for row in requested], "status": "unsupported",
                    "reason": "native DSL lacks a lossless finite proof projection",
                    "ruleSourceInputs": catalog["sourceInputs"], "observations": [], "supportNodes": [],
                    "executionAuthorized": False, "runtimeAdmitted": False})
                continue
            raw = assemble(facts, catalog, {relation: relation}, engine=engine)
            program = raw
            source = {"identity": identity([row for row in program["relations"] if row["source"]]),
                      "generation": generation,
                      "relations": [[row["name"], len(row["columns"]), row["rows"]]
                                    for row in program["relations"] if row["source"]]}
            entry = {"schema": "native-computational-observation.v1", "relation": relation,
                     "requested": [list(row) for row in requested], "programSha256": identity(raw),
                     "source": source, "ruleSourceInputs": catalog.get("sourceInputs", {}),
                     "executionAuthorized": False, "runtimeAdmitted": False}
            try:
                candidate = candidate_transport(program, relation)
            except ValueError as error:
                entry.update(status="unsupported", reason=str(error), observations=[], supportNodes=[])
                packets.append(entry)
                continue
            entry["candidate"] = candidate
            if rejection is None:
                try:
                    resolved = store.resolve(source, candidate)
                except EngineError as error:
                    rejection = str(error)
                    close_support(engine)
            if rejection is not None:
                entry.update(status="unknown", reason="native proof request rejected",
                             nativeError=rejection, observations=[], supportNodes=[])
                packets.append(entry)
                continue
            entry["nativeResolution"] = resolved
            if resolved["status"] != "verified":
                entry.update(status="unknown", observations=[], supportNodes=[])
                packets.append(entry)
                continue
            entry.update(status="observed", observations=[], supportNodes=[])
            nodes = {}
            atoms = [[relation, *row] for row in requested]
            for offset in range(0, len(atoms), 32):
                packet = store.observe(source, candidate, resolved["handle"], atoms[offset:offset + 32], support=True)
                if "scope" in entry and entry["scope"] != packet.get("scope"):
                    raise ValueError("mixed computational observation scopes")
                entry["scope"] = packet.get("scope")
                entry["observations"].extend(packet["observations"])
                for node in packet.get("supportNodes", []):
                    if node["id"] in nodes and nodes[node["id"]] != node:
                        raise ValueError("conflicting native support node")
                    nodes[node["id"]] = node
            entry["supportNodes"] = list(nodes.values())
            # The typed Library packet already carries the original scalar values.
            # Preserve its conclusion; there is no retired symbol-codec translation.
            for observation in entry["observations"]:
                native_atom = observation["conclusion"].get("atom")
                if native_atom:
                    observation["displayAtom"] = deepcopy(native_atom)
            packets.append(entry)
    return packets


def validate(packet):
    """Validate packet shape and ancestor closure, not source authenticity."""
    if (packet.get("schema") != "native-computational-observation.v1"
            or packet.get("runtimeAdmitted") is not False
            or packet.get("executionAuthorized") is not False):
        raise ValueError("invalid computational observation boundary")
    nodes = {row["id"]: row for row in packet["supportNodes"]}
    if len(nodes) != len(packet["supportNodes"]):
        raise ValueError("duplicate native support node")
    if packet["status"] != "observed":
        if nodes or packet["observations"]:
            raise ValueError("unsupported observation cannot contain native proof")
        return
    scope = packet["scope"]
    if (not isinstance(scope, dict) or scope["source-identity"] != packet["source"]["identity"]
            or scope["generation"] != packet["source"]["generation"]
            or dict(packet["nativeResolution"]["scope"]) != scope):
        raise ValueError("native observation scope mismatch")
    for node in nodes.values():
        if not set(node["parents"]) <= set(nodes):
            raise ValueError("native support is not ancestor-closed")
    visiting, visited = set(), set()
    def visit(key):
        if key in visiting:
            raise ValueError("cyclic native support")
        if key in visited:
            return
        visiting.add(key)
        for parent in nodes[key]["parents"]:
            visit(parent)
        visiting.remove(key)
        visited.add(key)
    for key in nodes:
        visit(key)
    for observation in packet["observations"]:
        conclusion = observation["conclusion"]
        roots = observation.get("support", {}).get("roots", [])
        if conclusion["status"] == "verified":
            if not roots or not set(roots) <= set(nodes) or roots != conclusion["support-nodes"]:
                raise ValueError("verified conclusion has no matching native roots")
            if any(nodes[key]["atom"] != conclusion["atom"] for key in roots):
                raise ValueError("native root does not prove its conclusion")
        elif roots:
            raise ValueError("unknown or absent conclusion cannot contain positive proof")
    if [row["displayAtom"][1:] for row in packet["observations"]] != packet["requested"]:
        raise ValueError("native observations differ from requested conclusions")
