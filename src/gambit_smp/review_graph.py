"""Render ASCENT conclusions with their evidence and catalog provenance."""
import hashlib
import json
from pathlib import Path
import subprocess

from gambit_smp.reasoning_history import canonical, fingerprint
from gambit_smp.review_inputs import PROOF_OBSERVATIONS, proof_observations


CATALOGS = {
    "gambit-smp-model-cases.v1": ("cases", "id", "model"),
    "gambit-protocol-extensions.v1": ("cases", "id", "model"),
    "gambit-smp-report-catalog.v1": ("reports", "number", "report"),
    "gambit-smp-papers.v1": ("papers", "id", "paper"),
    "gambit-local-native-failures.v1": ("failures", "id", "failure"),
    "gambit-research-audit.v1": ("issues", "id", "observation"),
    "gambit-model-raw-log-attestations.v1": ("receipts", "model", "model"),
}


def checkout(root, paths):
    """Separate committed bytes from staged, modified and local-only inputs."""
    root = Path(root).resolve()
    def git(*args, input=None):
        return subprocess.run(["git", *args], cwd=root, input=input,
                              capture_output=True, check=True, timeout=10).stdout
    head = git("rev-parse", "HEAD").decode().strip()
    indexed = set(git("ls-files", "-z").decode().split("\0"))
    committed = set(git("ls-tree", "-r", "--name-only", "-z", "HEAD").decode().split("\0"))
    changed = set(git("diff", "--name-only", "-z", "HEAD", "--").decode().split("\0"))
    links = {}
    for record in git("ls-tree", "-r", "-z", "HEAD").decode().split("\0"):
        if not record:
            continue
        metadata, name = record.split("\t", 1)
        mode, kind, revision = metadata.split(" ")
        if mode == "160000" and kind == "commit":
            links[name] = revision
    committed_links = dict(links)
    # Newly staged submodules are repositories too, but are not durable at HEAD.
    for record in git("ls-files", "--stage", "-z").decode().split("\0"):
        if not record:
            continue
        metadata, name = record.split("\t", 1)
        mode, revision, stage = metadata.split(" ")
        if mode == "160000" and stage == "0":
            links.setdefault(name, revision)
    nested_paths = {name: [path for path in paths if path.startswith(name + "/")]
                    for name in links}
    outer_paths = set(paths) - {path for values in nested_paths.values() for path in values}
    ignored_result = subprocess.run(["git", "check-ignore", "--stdin", "-z"], cwd=root,
        input=("\0".join(sorted(outer_paths)).encode() + b"\0") if outer_paths else b"",
        capture_output=True, timeout=10)
    if ignored_result.returncode not in (0, 1):
        raise ValueError("cannot classify graph input Git status")
    ignored = set(ignored_result.stdout.decode().split("\0"))
    statuses = {}
    for path in outer_paths:
        status = ("tracked-modified" if path in changed else "committed-unchanged") if path in committed else (
            "staged-new" if path in indexed else "ignored-local" if path in ignored else "untracked")
        statuses[path] = {"gitStatus": status,
                          "durableAtHead": status == "committed-unchanged" and not (root / path).is_symlink()}
    submodules = {}
    for name, values in nested_paths.items():
        if not values:
            continue
        nested = checkout(root / name, {path[len(name) + 1:] for path in values})
        pinned = (name in committed_links and nested["head"] == committed_links[name]
                  and name not in changed)
        submodules[name] = {"root": nested["root"], "head": nested["head"],
                            "pinnedRevision": links[name], "matchesParentHead": pinned,
                            "submodules": nested["submodules"]}
        for path in values:
            status = dict(nested["files"][path[len(name) + 1:]])
            status.update(submodulePath=name, submodulePinnedRevision=links[name],
                          repositoryRoot=nested["root"], repositoryHead=nested["head"])
            status["durableAtHead"] = status["durableAtHead"] and pinned
            statuses[path] = status
    return {"root": str(root), "head": head, "submodules": submodules,
            "branch": git("branch", "--show-current").decode().strip(),
            "files": statuses}


def build(root, model, facts, rows, bindings, source_facts, inputs, engine_inputs,
          validation=None, git_state=None, catalog_rows=None, engine_artifacts=None,
          native_observations=(), campaigns=(), evidence_views=()):
    """Transport native decisions; catalog links never synthesize proof edges."""
    candidate = "task:" + model
    needs = {claim for name, claim in rows["Need"] if name == candidate}
    models = {claim.removeprefix("finite-model:") for claim in needs
              if claim.startswith("finite-model:")}
    receipts = {receipt for receipt, claim in facts["Passed"] if claim in needs}
    issues = {issue for issue, name in source_facts.get("audit_model", []) if name in models}
    failures = {failure for failure, name in source_facts.get("local_failure_model", [])
                if name in models}
    reports = {number for number, name in source_facts.get("pr_model", []) if name in models}
    reports.update(number for name, number in source_facts.get("model_context_pr", []) if name in models)
    reports.update(number for name, number, *_ in source_facts.get("protocol_report", []) if name in models)
    catalog_rows = catalog_rows or {}
    reports.update(child for parent, child in catalog_rows.get("dependency_closure", []) if parent in reports)
    papers = {paper for name, paper, *_ in source_facts.get("model_paper", []) +
              source_facts.get("protocol_paper", []) if name in models}
    receipts.update("audit:" + issue for issue in issues)
    receipts.update(dependency for receipt, dependency in rows["ReceiptPath"] if receipt in receipts)
    validation = validation or {"status": "not-supplied", "frameworkValidated": False}
    paths = set(inputs) | set(validation.get("testFiles", [])) | {
        path for receipt in receipts for path in bindings.get(receipt, {}).get("inputs", {})}
    git_state = git_state or checkout(root, paths)
    current = dict(facts["CurrentInput"])
    reusable = {tuple(row) for row in rows["Reusable"]}
    established = {claim for claim, _ in rows["Established"]}
    missing = {claim for name, claim in rows["Missing"] if name == candidate}
    unusable = {}
    for receipt, reason in rows["Unusable"]:
        unusable.setdefault(receipt, []).append(reason)
    nodes, edges, contexts = {}, {}, {}

    def node(kind, key, **fields):
        identity = fingerprint([kind, key])
        value = {"id": identity, "kind": kind, "key": key, **fields}
        if identity in nodes:
            for field, content in value.items():
                if field in nodes[identity] and nodes[identity][field] != content:
                    raise ValueError("conflicting graph node: " + kind + ":" + str(key))
            nodes[identity].update(value)
        else:
            nodes[identity] = value
        return identity

    def edge(source, relation, target, **fields):
        value = {"source": source, "relation": relation, "target": target, **fields}
        edges[canonical(value)] = value

    def file(path):
        return node("file", path, path=path, sha256=current.get(path, inputs.get(path,
                    validation.get("testCurrentHashes", {}).get(path))),
                    **git_state["files"].get(path, {"gitStatus": "unbound", "durableAtHead": False}))

    def claim(name):
        return node("claim", name, domain=name.partition(":")[0],
                    status="missing" if name in missing else "established" if name in established else "open")

    snapshot = node("snapshot", current["validated-catalog"],
                    status="current-revalidated", executionAuthorized=False)
    task = node("task", model, executionAuthorized=False)
    edge(task, "reviewed-at", snapshot)
    for name in sorted(needs):
        edge(task, "needs", claim(name), derivedBy="ASCENT:Need")
    for parent, child in facts["ClaimDepends"]:
        if parent in needs:
            edge(claim(parent), "requires-claim", claim(child), relationSource="ClaimDepends")
    for receipt, name in facts["Passed"]:
        if receipt not in receipts:
            continue
        spec = bindings.get(receipt, {})
        status = "unverified" if spec.get("rawLogEvidencePending") else (
            "invalidated" if receipt in unusable else "reusable" if (receipt, name) in reusable else "open")
        rid = node("receipt", receipt, status=status, binding=spec.get("binding", "catalog-fallback"),
                   path=spec.get("path"), reasons=sorted(set(unusable.get(receipt, []))))
        edge(rid, "records-claim", claim(name), relationSource="Passed")
        if status == "reusable":
            edge(rid, "supports-in-snapshot", claim(name), derivedBy="ASCENT:Reusable")
        if spec.get("path"):
            edge(rid, "stored-in", file(spec["path"]))
        for path, expected in sorted(spec.get("inputs", {}).items()):
            edge(rid, "requires-input", file(path), expectedSha256=expected,
                 matchesCurrent=current.get(path) == expected, relationSource="ReceiptInput")
        for index, check in enumerate(spec.get("checks", [])):
            cid = node("model-check", [receipt, index], status="revalidated" if status == "reusable" else status,
                       **{key: value for key, value in check.items() if key != "artifacts"})
            edge(rid, "contains-check", cid)
            for kind, path in check["artifacts"].items():
                edge(cid, "checked-" + kind, file(path))
    for receipt, dependency in facts["ReceiptDepends"]:
        if receipt in receipts:
            edge(node("receipt", receipt), "requires-receipt", node("receipt", dependency),
                 relationSource="ReceiptDepends")
    if PROOF_OBSERVATIONS in inputs:
        proof_catalog, proof_inputs = proof_observations(Path(root))
        if any(inputs.get(path) != sha for path, sha in proof_inputs.items()):
            raise ValueError("partial proof inputs changed during graph export")
        if proof_catalog["protocolModel"] in models:
            catalog = node("catalog", PROOF_OBSERVATIONS, schema=proof_catalog["schema"],
                           sha256=inputs[PROOF_OBSERVATIONS], overallAccepted=False)
            edge(catalog, "stored-in", file(PROOF_OBSERVATIONS))
            edge(snapshot, "catalog-source", catalog)
            for observed in proof_catalog["boundObservations"]:
                row, saved = observed["row"], observed["receipt"]
                pointer = "/observations/" + str(observed["index"])
                eid = node("catalog-entry", [PROOF_OBSERVATIONS, pointer],
                           catalogPath=PROOF_OBSERVATIONS, pointer=pointer,
                           entryKind="partial-proof", entryKey=row["id"])
                oid = node("recorded-observation", [PROOF_OBSERVATIONS, pointer],
                           domain="partial-proof", observationKind=row["kind"],
                           status="recorded-only", obligationProvedReported=row["obligationProved"],
                           finding=row.get("finding"), accepted=False, runtimeAdmitted=False,
                           temporalProved=False, releaseAdmitted=False,
                           scope=saved.get("scope"), boundary=proof_catalog.get("boundary"),
                           generatorCoverageProved=saved.get("generatorCoverageProved", False))
                edge(catalog, "contains-entry", eid)
                edge(eid, "describes", claim("finite-model:" + proof_catalog["protocolModel"]))
                edge(eid, "records-observation", oid)
                edge(oid, "recorded-receipt", file(row["receipt"]), expectedSha256=row["receiptSha256"])
                edge(oid, "recorded-archive", file(observed["archivePath"]))
                if observed.get("notes"):
                    edge(oid, "review-notes", file(observed["notes"]),
                         sourceRefinementEstablished=False)
                if observed.get("proofLayer"):
                    edge(oid, "current-proof-layer", file(observed["proofLayer"]),
                         sourceRefinementEstablished=False)
                for name, artifact in observed["artifacts"].items():
                    edge(oid, "archived-artifact", file(artifact["path"]),
                         rawSha256=artifact["rawSha256"], portableSha256=artifact["portableSha256"])
                    if name.endswith(".qnt"):
                        path = "models/gambit/" + name
                        edge(file(artifact["path"]), "historical-model-snapshot", file(path),
                             matchesCurrent=inputs.get(path) == artifact["rawSha256"],
                             sourceRefinementEstablished=False)
                for index, check in enumerate(observed["checks"]):
                    cid = node("reported-model-check", [row["receipt"], index],
                               status="recorded-only", checkKind=check.get("kind"),
                               **{key: check[key] for key in (
                                   "step", "exit", "timeout", "seconds", "obligationProved",
                                   "counterexample", "timeoutBudgetSeconds") if key in check})
                    edge(oid, "records-check", cid)
                    for field in ("log", "trace"):
                        if field in check:
                            edge(cid, "recorded-" + field, file(observed["artifacts"][check[field]]["path"]))
                for gap in observed["artifactGaps"]:
                    edge(oid, "missing-recorded-artifact", file(gap["path"]),
                         expectedSha256=gap["expectedSha256"])
    selected = {"model": models, "report": reports, "paper": papers,
                "failure": failures, "observation": issues}
    for path, expected in sorted(inputs.items()):
        if not path.endswith(".json") or not Path(path).parts or Path(path).parts[0] not in ("evidence", "models"):
            continue
        content = (Path(root) / path).read_bytes()
        if hashlib.sha256(content).hexdigest() != expected:
            raise ValueError("catalog changed during graph export: " + path)
        saved = json.loads(content)
        descriptor = CATALOGS.get(saved.get("schema"))
        if descriptor is None:
            continue
        field, key, kind = descriptor
        relevant = [(index, entry) for index, entry in enumerate(saved[field]) if entry[key] in selected[kind]]
        if not relevant:
            continue
        catalog = node("catalog", path, schema=saved["schema"], sha256=expected,
                       sourceRevision=saved.get("sourceRevision"))
        edge(catalog, "stored-in", file(path))
        edge(snapshot, "catalog-source", catalog)
        for index, entry in relevant:
            pointer = "/" + field + "/" + str(index)
            eid = node("catalog-entry", [path, pointer], catalogPath=path, pointer=pointer,
                       entryKind=kind, entryKey=entry[key])
            edge(catalog, "contains-entry", eid)
            target = claim("finite-model:" + entry[key]) if kind == "model" else node(kind, entry[key])
            edge(eid, "describes", target)
            if "modelReceipt" in entry:
                edge(eid, "declares-receipt-file", file(entry["modelReceipt"]))
            if kind == "model":
                contexts.setdefault(entry[key], {}).update(saved.get("contextInputs", {}))
                if entry.get("native"):
                    edge(eid, "declares-native-fixture", file("models/gambit/native/" + entry["native"]))
                for field, domain in (("sourceUnitObservations", "source-unit"), ("nativeObservations", "native-record")):
                    for index, observation in enumerate(entry.get(field, [])):
                        oid = node("recorded-observation", [path, pointer, field, index],
                                   domain=domain, observationKind=observation["kind"], runtimeAdmitted=False)
                        edge(eid, "records-observation", oid)
                        for artifact in ("receipt", "log"):
                            edge(oid, "recorded-" + artifact, file(observation[artifact]))
            if kind == "report" and "snapshot" in entry:
                edge(target, "report-snapshot", file(entry["snapshot"]))
            for artifact in entry.get("evidence", []):
                if isinstance(artifact, dict) and "path" in artifact:
                    edge(eid, "references-evidence", file(artifact["path"]), expectedSha256=artifact.get("sha256"))
            if kind == "paper":
                nodes[target].update(url=entry.get("url"))
            if kind == "observation":
                edge(target, "recorded-by", node("receipt", "audit:" + entry[key]))
                if "reflection" in entry:
                    from gambit_smp.reflection import validate as validate_reflection
                    reflection = entry["reflection"]
                    bound = validate_reflection(root, reflection)
                    if any(inputs.get(path) != sha for path, sha in bound.items()):
                        raise ValueError("unbound reflection reference")
                    rid = node("reflection", entry[key], fullChainEstablished=False)
                    edge(eid, "has-reflection", rid)
                    references = {}
                    for reference in reflection["references"]:
                        ref = node("reference", [entry[key], reference["id"]],
                                   referenceKind=reference["kind"], locator=reference["locator"],
                                   scope=reference["scope"], proofAdmission=False)
                        references[reference["id"]] = ref
                        edge(rid, "lists-reference", ref)
                        edge(ref, "reference-artifact", file(reference["path"]),
                             expectedSha256=bound[reference["path"]])
                        for artifact in reference.get("artifacts", []):
                            edge(ref, "reference-artifact", file(artifact["path"]),
                                 expectedSha256=artifact["sha256"])
                    for requirement in reflection["requirements"]:
                        req = node("requirement", [entry[key], requirement["id"]],
                                   status=requirement["status"], gap=requirement["gap"],
                                   fullChainEstablished=False)
                        edge(rid, "has-open-requirement", req)
                        for index, condition in enumerate(requirement["conditions"]):
                            cid = node("acceptance-condition", [entry[key], requirement["id"], index],
                                       text=condition, acceptanceStatus="unverified")
                            edge(req, "requires-condition", cid)
                        for reference in requirement["references"]:
                            edge(req, "context-reference", references[reference], proofAdmission=False)
            if kind == "failure":
                for artifact in ("receipt", "log"):
                    if artifact in entry:
                        edge(target, "recorded-" + artifact, file(entry[artifact]))
            if kind == "model" and "receiptSha256" in entry:
                qualified = entry[key] + ":" + entry["receiptSha256"]
                edge(eid, "attests-receipt", node("receipt", qualified))
    for relation in ("source_obligation", "protocol_source"):
        for name, location in source_facts.get(relation, []):
            if name in models:
                source_path = location.partition(":")[0]
                matches = [path for path in contexts.get(name, {}) if path == source_path or path.endswith("/" + source_path)]
                sid = node("source-location", [name, location], location=location,
                           binding="unique-context-file" if len(matches) == 1 else "ambiguous" if matches else "unbound")
                edge(claim("finite-model:" + name), "source-reference", sid,
                     relationSource=relation)
                for path in matches:
                    edge(sid, "context-file", file(path), expectedSha256=contexts[name][path],
                         matchesCurrent=current.get(path, inputs.get(path)) == contexts[name][path],
                         sourceRefinementEstablished=False)
    for relation in ("model_paper", "protocol_paper"):
        for name, paper, *section in source_facts.get(relation, []):
            if name in models:
                edge(claim("finite-model:" + name), "paper-context", node("paper", paper),
                     section=section, relationSource=relation)
    for relation in ("pr_model", "model_context_pr", "protocol_report"):
        for row in source_facts.get(relation, []):
            number, name = row[:2] if relation == "pr_model" else (row[1], row[0])
            if name in models:
                edge(node("report", number), "reported-model-context", claim("finite-model:" + name),
                     relationSource=relation)
    for failure, name in source_facts.get("local_failure_model", []):
        if name in models:
            edge(node("failure", failure), "reported-for-model", claim("finite-model:" + name),
                 causalEvidence=False)
    for parent, child in source_facts.get("dependency", []):
        if parent in reports:
            edge(node("report", parent), "declares-report-dependency", node("report", child),
                 relationSource="dependency")
    for parent, child in catalog_rows.get("dependency_closure", []):
        if parent in reports:
            edge(node("report", parent), "report-dependency-path", node("report", child),
                 derivedBy="ASCENT:dependency_closure")
    for name, reason in rows["Denial"]:
        if name == candidate or name in failures:
            edge(task if name == candidate else node("failure", name), "denied-by",
                 node("denial", [name, reason], reason=reason), derivedBy="ASCENT:Denial")
    for name, failure, receipt in rows["CausalEvidence"]:
        if name == candidate or name in failures:
            edge(task if name == candidate else node("failure", name), "reviewed-causal-evidence",
                 node("receipt", receipt), failure=failure, derivedBy="ASCENT:CausalEvidence")
    vid = node("validation", validation.get("receiptSha256", "not-supplied"), **validation)
    edge(vid, "validates-framework-snapshot", snapshot,
         verified=validation.get("frameworkValidated") is True)
    for path in validation.get("testFiles", []):
        edge(vid, "tested-module", file(path), expectedSha256=validation["testInputHashes"][path],
             matchesCurrent=validation.get("testCurrentHashes", {}).get(path) == validation["testInputHashes"][path])
    backend = node("backend", fingerprint(engine_inputs), name="ascent-rust", inputs=engine_inputs)
    edge(snapshot, "inferred-by", backend)
    for name, artifact in sorted((engine_artifacts or {}).items()):
        edge(backend, "loaded-artifact", node("backend-artifact", name, **artifact))
    from gambit_smp.native_support import validate as validate_observation
    for packet in native_observations:
        validate_observation(packet)
        pid = fingerprint(packet)
        observed = node("computational-observation", pid, status=packet["status"],
                        relation=packet["relation"], reason=packet.get("reason"),
                        domain="finite-native-computation", runtimeAdmitted=False)
        edge(observed, "observed-in-snapshot", snapshot)
        edge(observed, "computed-by", backend)
        for path, sha in packet["ruleSourceInputs"].items():
            path = str(Path(path).relative_to(root)) if Path(path).is_absolute() else path
            if inputs.get(path) != sha:
                raise ValueError("native support rule input is not bound by graph")
            edge(observed, "uses-rule-source", file(path), expectedSha256=sha)
        native_nodes = {}
        for support in packet["supportNodes"]:
            native_nodes[support["id"]] = node("computational-support", [pid, support["id"]],
                packetSha256=pid, nativeId=support["id"], nativeKind=support["kind"],
                atom=support["atom"], ruleLabel=support["ruleLabel"],
                nativeParents=support["parents"], scope=packet["scope"],
                domain="finite-native-computation", runtimeAdmitted=False)
        for support in packet["supportNodes"]:
            for parent in support["parents"]:
                edge(native_nodes[support["id"]], "native-parent", native_nodes[parent])
        for index, observation in enumerate(packet["observations"]):
            conclusion = observation["conclusion"]
            cid = node("computational-conclusion", [pid, index],
                       atom=observation["displayAtom"], nativeAtom=conclusion["atom"],
                       status=conclusion["status"], scope=packet["scope"],
                       packetSha256=pid, runtimeAdmitted=False)
            edge(observed, "contains-native-conclusion", cid)
            for key in observation.get("support", {}).get("roots", []):
                edge(cid, "native-support-root", native_nodes[key])
            values = observation["displayAtom"]
            if values[0] == "Need" and values[1] == candidate:
                edge(cid, "explains-relation-row", claim(values[2]), nativeRelation="Need")
    for packet in campaigns:
        from gambit_smp.campaign_evidence import validate as validate_campaign
        validate_campaign(packet)
        campaign = node("native-campaign", packet["id"], packetSha256=packet["packetSha256"],
            identityStatus=packet["identityStatus"], nativeOutcome=packet["nativeOutcome"],
            retryDecision=packet["retry"]["decision"] if packet["retry"] else None,
            nativeAnswers=packet["nativeAnswers"], runtimeAdmitted=False, executionAuthorized=False)
        edge(task, "observes-native-campaign", campaign)
        edge(campaign, "campaign-receipt", file(packet["receipt"]["path"]),
             expectedSha256=packet["receipt"]["sha256"])
        for descriptor in packet["artifacts"].values():
            edge(campaign, "campaign-artifact", file(descriptor["path"]), expectedSha256=descriptor["sha256"])
        for _, failure in packet["nativeAnswers"]["CampaignKnownFailure"]:
            edge(campaign, "campaign-known-failure", node("failure", failure))
        for _, failure, premise in packet["nativeAnswers"]["CampaignOpenPremise"]:
            edge(campaign, "campaign-open-premise", claim(premise), failure=failure)
        for index, command in enumerate(packet["commands"]):
            observed = node("native-command", [packet["id"], index], observation=command,
                exit=command["exit"], timeout=command["timeout"],
                parentReaped=command.get("parentReaped"), processGroupQuiescent=command.get("processGroupQuiescent"),
                runtimeAdmitted=False)
            edge(campaign, "recorded-native-command", observed)
    for view in evidence_views:
        vid = node("evidence-view", view["id"], path=view["path"],
                   executionAuthorized=False, runtimeAdmitted=False, scope=view["scope"])
        edge(task, "observes-evidence-view", vid)
        edge(vid, "inferred-by", backend)
        for path, sha in view["inputs"].items():
            relative = str(Path(path).relative_to(root))
            if inputs.get(relative) != sha:
                raise ValueError("Evidence view input is not bound by graph")
            edge(vid, "uses-view-input", file(relative), expectedSha256=sha)
        for query, values in view["answers"].items():
            for row in values:
                observed = node("evidence-view-row", [view["id"], query, list(row)],
                                query=query, relation=view["queries"][query], value=list(row),
                                runtimeAdmitted=False, executionAuthorized=False)
                edge(vid, "records-derived-row", observed, derivedBy="ASCENT:" + view["queries"][query])
    output = {"schema": "gambit-agent-evidence-graph.v1", "task": model,
              "snapshot": current["validated-catalog"], "checkout": {key: value for key, value in git_state.items() if key != "files"},
              "nodes": sorted(nodes.values(), key=lambda value: value["id"]),
              "edges": [edges[key] for key in sorted(edges)],
              "frameworkValidated": validation.get("frameworkValidated") is True,
              "executionAuthorized": False, "runtimeAdmitted": False,
              "authority": {"inference": "ASCENT", "inputAuthentication": "research host",
                            "executionAdmission": "suite preflight"},
              "catalogCoverage": {name: len(values) for name, values in sorted(catalog_rows.items())},
              "nativeObservations": list(native_observations), "nativeCampaigns": list(campaigns)}
    output["graphSha256"] = fingerprint(output)
    validate(output)
    return output


def validate(graph):
    if graph.get("schema") != "gambit-agent-evidence-graph.v1":
        raise ValueError("unknown Agent graph schema")
    content = {key: value for key, value in graph.items() if key != "graphSha256"}
    if graph.get("graphSha256") != fingerprint(content):
        raise ValueError("Agent graph identity mismatch")
    nodes = {node["id"]: node for node in graph["nodes"]}
    if len(nodes) != len(graph["nodes"]):
        raise ValueError("duplicate Agent graph node")
    for kind in ("task", "snapshot", "validation", "backend"):
        if sum(node["kind"] == kind for node in nodes.values()) != 1:
            raise ValueError("Agent graph requires one " + kind + " node")
    for edge in graph["edges"]:
        if edge["source"] not in nodes or edge["target"] not in nodes:
            raise ValueError("Agent graph edge has an unknown endpoint")
        if edge["relation"] == "supports-in-snapshot" and nodes[edge["source"]].get("status") != "reusable":
            raise ValueError("unusable receipt cannot support an Agent claim")
    from gambit_smp.native_support import validate as validate_observation
    for packet in graph.get("nativeObservations", []):
        validate_observation(packet)
    from gambit_smp.campaign_evidence import validate as validate_campaign
    for packet in graph.get("nativeCampaigns", []):
        validate_campaign(packet)
    for node in nodes.values():
        if node["kind"] == "computational-support":
            parents = {nodes[e["target"]].get("nativeId") for e in graph["edges"]
                       if e["source"] == node["id"] and e["relation"] == "native-parent"}
            if parents != set(node["nativeParents"]):
                raise ValueError("graph omitted native parent links")
    if graph.get("executionAuthorized") is not False or graph.get("runtimeAdmitted") is not False:
        raise ValueError("Agent graph cannot grant execution admission")
    validation = next(node for node in nodes.values() if node["kind"] == "validation")
    if graph["frameworkValidated"] != (validation.get("frameworkValidated") is True):
        raise ValueError("Agent graph validation status mismatch")


def mermaid(graph):
    """Small task overview; the JSON graph retains every scoped relationship."""
    target = "finite-model:" + graph["task"]
    nodes = {node["id"]: node for node in graph["nodes"]}
    target_ids = {identity for identity, node in nodes.items() if node["kind"] == "claim" and node["key"] == target}
    selected = [edge for edge in graph["edges"] if
                (edge["source"] in target_ids or edge["target"] in target_ids) and
                edge["relation"] in ("needs", "requires-claim", "supports-in-snapshot", "records-claim")]
    ids = sorted({edge[field] for edge in selected for field in ("source", "target")})
    aliases = {identity: "n" + str(index) for index, identity in enumerate(ids)}
    lines = ["flowchart LR"]
    for identity in ids:
        node = nodes[identity]
        label = str(node["key"]) + " (" + node.get("status", node["kind"]) + ")"
        label = label.replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;").replace(">", "&gt;")
        lines.append('  ' + aliases[identity] + '["' + label + '"]')
    for edge in selected:
        lines.append("  " + aliases[edge["source"]] + " -->|" + edge["relation"] + "| " + aliases[edge["target"]])
    return "\n".join(lines) + "\n"
