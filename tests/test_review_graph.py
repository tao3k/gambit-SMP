import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.framework import digest
from gambit_smp.reasoning_history import fingerprint
from gambit_smp.review_graph import build, checkout, mermaid, validate
from gambit_smp.review_inputs import PROOF_OBSERVATIONS, proof_observations


class ReviewGraphTests(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        contents = {
            "models/gambit/cases.json": {"schema": "gambit-smp-model-cases.v1", "cases": [
                {"id": "parent", "modelReceipt": "evidence/parent.json"}, {"id": "child"}]},
            "models/gambit/report_catalog.json": {"schema": "gambit-smp-report-catalog.v1", "reports": [{"number": 7}]},
            "evidence/papers.json": {"schema": "gambit-smp-papers.v1", "papers": [{"id": "paper", "url": "https://example.org/paper"}]},
            "evidence/native-failures.json": {"schema": "gambit-local-native-failures.v1", "failures": [{"id": "failure", "receipt": "evidence/failure.json"}]},
            "evidence/research-audit.json": {"schema": "gambit-research-audit.v1", "issues": [{"id": "issue", "evidence": [{"path": "evidence/parent.json"}]}]},
            "evidence/parent.json": {}, "evidence/child.json": {}, "evidence/failure.json": {},
        }
        for name, value in contents.items():
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(json.dumps(value))
        source = self.root / "runtime/lib/mem.c"
        source.parent.mkdir(parents=True)
        source.write_text("source\n")
        (self.root / "evidence/parent-fixed.log").write_text("checked output\n")
        context = self.root / "evidence/protocol.json"
        context.write_text(json.dumps({"schema": "gambit-protocol-extensions.v1",
            "contextInputs": {"runtime/lib/mem.c": digest(source)}, "cases": [{"id": "parent"}]}))
        self.inputs = {str(path.relative_to(self.root)): digest(path) for path in self.root.rglob("*") if path.is_file()}
        self.current = {"validated-catalog": fingerprint(self.inputs), **self.inputs}
        self.facts = {"Passed": [["parent:receipt", "finite-model:parent"],
                                 ["child:receipt", "finite-model:child"],
                                 ["audit:issue", "recorded-observation:issue"]],
                      "CurrentInput": list(self.current.items()),
                      "ClaimDepends": [["finite-model:parent", "finite-model:child"],
                                       ["finite-model:parent", "native-obligation:source"]],
                      "ReceiptDepends": [["audit:issue", "parent:receipt"]]}
        self.rows = {"Need": [["task:parent", "finite-model:parent"], ["task:parent", "finite-model:child"],
                              ["task:parent", "native-obligation:source"]],
                     "Missing": [["task:parent", "finite-model:child"], ["task:parent", "native-obligation:source"]],
                     "Reusable": [["parent:receipt", "finite-model:parent"], ["audit:issue", "recorded-observation:issue"]],
                     "Established": [["finite-model:parent", "parent:receipt"], ["recorded-observation:issue", "audit:issue"]],
                     "Unusable": [["child:receipt", "stale-or-missing-input"]],
                     "ReceiptPath": [["audit:issue", "parent:receipt"]],
                     "Denial": [["task:parent", "missing-premise"]], "CausalEvidence": []}
        self.bindings = {
            "parent:receipt": {"path": "evidence/parent.json", "binding": "recorded", "depends": [],
                "inputs": {name: self.inputs[name] for name in ("evidence/parent.json", "evidence/parent-fixed.log", "runtime/lib/mem.c")},
                "checks": [{"variant": "fixed", "invariant": "safe", "artifacts": {"log": "evidence/parent-fixed.log"}}]},
            "child:receipt": {"path": "evidence/child.json", "binding": "recorded", "depends": [],
                              "inputs": {"evidence/child.json": "old"}},
            "audit:issue": {"path": "evidence/research-audit.json", "binding": "recorded", "depends": ["parent:receipt"],
                            "inputs": {"evidence/research-audit.json": self.inputs["evidence/research-audit.json"]}}}
        self.source = {"pr_model": [[7, "parent"]], "model_context_pr": [["parent", 7]],
                       "model_paper": [["parent", "paper", "3.5"]], "audit_model": [["issue", "parent"]],
                       "local_failure_model": [["failure", "parent"]],
                       "protocol_source": [["parent", "lib/mem.c:scan"]]}
        self.git = {"root": str(self.root), "head": "fixture-head", "branch": "fixture",
                    "files": {path: {"gitStatus": "untracked", "durableAtHead": False} for path in self.inputs}}

    def graph(self):
        return build(self.root, "parent", self.facts, self.rows, self.bindings, self.source,
                     self.inputs, {"extension": "fixture"}, git_state=self.git)

    def test_catalog_entries_logs_and_source_identity_form_explicit_links(self):
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        self.assertTrue(any(node["kind"] == "catalog-entry" and node["catalogPath"] == "models/gambit/cases.json"
                            and node["pointer"] == "/cases/0" for node in nodes.values()))
        source_edges = [edge for edge in graph["edges"] if edge["relation"] == "context-file"]
        self.assertEqual(1, len(source_edges))
        self.assertEqual("runtime/lib/mem.c", nodes[source_edges[0]["target"]]["path"])
        self.assertTrue(source_edges[0]["matchesCurrent"])
        self.assertFalse(source_edges[0]["sourceRefinementEstablished"])
        self.assertTrue(any(edge["relation"] == "checked-log" and nodes[edge["target"]]["path"] == "evidence/parent-fixed.log"
                            for edge in graph["edges"]))
        self.assertTrue(any(edge["relation"] == "requires-receipt" for edge in graph["edges"]))
        self.assertFalse(graph["frameworkValidated"])
        self.assertFalse(graph["executionAuthorized"])

    def test_invalid_receipt_and_declared_dependencies_do_not_become_support(self):
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        supports = [nodes[edge["source"]]["key"] for edge in graph["edges"] if edge["relation"] == "supports-in-snapshot"]
        self.assertNotIn("child:receipt", supports)
        self.assertEqual("invalidated", next(node["status"] for node in nodes.values() if node["key"] == "child:receipt"))
        self.assertTrue(any(edge["relation"] == "requires-claim" for edge in graph["edges"]))
        self.assertFalse(any(edge["relation"] == "reviewed-causal-evidence" for edge in graph["edges"]))

    def test_reflection_references_do_not_admit_requirements(self):
        path = self.root / "evidence/research-audit.json"
        audit = json.loads(path.read_text())
        audit["issues"][0]["reflection"] = {"schema": "gambit-evidence-reflection.v1",
            "references": [{"id": "local", "kind": "observation", "path": "evidence/parent.json",
                            "locator": "component", "scope": "not native GC"}],
            "requirements": [{"id": "payload", "status": "partial", "gap": "stubbed payload",
                              "conditions": ["Trace real payload"], "references": ["local"]}]}
        path.write_text(json.dumps(audit))
        self.inputs["evidence/research-audit.json"] = digest(path)
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        requirement = next(node for node in nodes.values() if node["kind"] == "requirement")
        self.assertFalse(requirement["fullChainEstablished"])
        self.assertTrue(any(edge["relation"] == "context-reference" for edge in graph["edges"]))
        self.assertFalse(any(edge["relation"] == "supports-in-snapshot" and
                             requirement["id"] in (edge["source"], edge["target"])
                             for edge in graph["edges"]))
        self.inputs.pop("evidence/parent.json")
        with self.assertRaisesRegex(ValueError, "unbound reflection"):
            self.graph()

    def test_graph_rejects_tampering_and_unknown_endpoints(self):
        graph = self.graph()
        graph["edges"][0]["target"] = "missing"
        with self.assertRaisesRegex(ValueError, "identity mismatch"):
            validate(graph)
        graph["graphSha256"] = fingerprint({key: value for key, value in graph.items() if key != "graphSha256"})
        with self.assertRaisesRegex(ValueError, "unknown endpoint"):
            validate(graph)

    def test_graph_is_deterministic_and_overview_contains_the_target(self):
        first = self.graph()
        self.facts["Passed"].reverse()
        self.assertEqual(first, self.graph())
        self.assertIn("finite-model:parent", mermaid(first))
        self.assertIn("requires-claim", mermaid(first))

    def test_changed_catalog_bytes_cannot_be_exported(self):
        (self.root / "models/gambit/cases.json").write_text("{}")
        with self.assertRaisesRegex(ValueError, "catalog changed"):
            self.graph()

    def add_partial_proof(self):
        directory = self.root / "evidence/partial"
        directory.mkdir()
        log = directory / "check.log"
        log.write_text("archived portable log\n")
        receipt = directory / "receipt.json"
        receipt.write_text(json.dumps({"accepted": False, "runtimeAdmitted": False,
            "releaseAdmitted": False, "temporalProved": False,
            "protocolIrSha256": "missing-ir-digest", "generatorContract": None, "modelInputs": {},
            "results": [{"step": "countOrRetry", "kind": "preservation", "exit": 0, "timeout": False,
                         "obligationProved": True, "log": "check.log", "logSha256": "raw-log-digest"}]}))
        archive = {"schema": "gambit-model-attempt-archive.v1", "archiveOnly": True,
                   "accepted": False, "runtimeAdmitted": False, "releaseAdmitted": False,
                   "files": {"receipt.json": {"rawSha256": digest(receipt), "portableSha256": digest(receipt)},
                             "check.log": {"rawSha256": "raw-log-digest", "portableSha256": digest(log)}}}
        (directory / "archive.json").write_text(json.dumps(archive))
        (self.root / PROOF_OBSERVATIONS).write_text(json.dumps({
            "schema": "gambit-induction-observations.v1", "protocolModel": "parent",
            "overallAccepted": False, "observations": [{"id": "partial", "kind": "transition-preservation",
                "receipt": "evidence/partial/receipt.json", "receiptSha256": digest(receipt),
                "obligationProved": True}]}))
        _, inputs = proof_observations(self.root)
        self.inputs.update(inputs)
        self.current.update(inputs)
        self.facts["CurrentInput"] = list(self.current.items())
        return directory

    def test_partial_proof_graph_is_recorded_only_with_missing_ir_and_portable_log(self):
        self.add_partial_proof()
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        observed = next(node for node in nodes.values() if node.get("domain") == "partial-proof")
        self.assertTrue(observed["obligationProvedReported"])
        self.assertFalse(observed["accepted"] or observed["runtimeAdmitted"] or observed["temporalProved"])
        self.assertEqual("recorded-only", observed["status"])
        self.assertTrue(any(edge["relation"] == "missing-recorded-artifact" for edge in graph["edges"]))
        self.assertTrue(any(node["kind"] == "catalog-entry" and node.get("pointer") == "/observations/0"
                            for node in nodes.values()))
        proof_nodes = {node["id"] for node in nodes.values() if node.get("domain") == "partial-proof" or
                       node["kind"] == "reported-model-check"}
        self.assertFalse(any(edge["source"] in proof_nodes and edge["relation"] == "supports-in-snapshot"
                             for edge in graph["edges"]))

    def test_partial_proof_transport_rejects_drift_admission_and_unbound_logs(self):
        directory = self.add_partial_proof()
        log = directory / "check.log"
        log.write_text("changed\n")
        with self.assertRaisesRegex(ValueError, "artifact drift"):
            proof_observations(self.root)
        log.write_text("archived portable log\n")
        path = directory / "archive.json"
        archive = json.loads(path.read_text())
        archive["files"]["check.log"]["rawSha256"] = "wrong"
        path.write_text(json.dumps(archive))
        with self.assertRaisesRegex(ValueError, "check artifact identity"):
            proof_observations(self.root)
        catalog = self.root / PROOF_OBSERVATIONS
        data = json.loads(catalog.read_text())
        data["overallAccepted"] = True
        catalog.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "non-admitted"):
            proof_observations(self.root)

    def test_partial_proof_row_layer_overrides_catalog_and_binds_current_bytes(self):
        self.add_partial_proof()
        catalog = self.root / PROOF_OBSERVATIONS
        data = json.loads(catalog.read_text())
        layers = ("models/gambit/safety.qnt", "models/gambit/ranking.qnt")
        for name in layers:
            (self.root / name).write_text(name)
        data["proofLayer"] = layers[0]
        catalog.write_text(json.dumps(data))
        bound, _ = proof_observations(self.root)
        self.assertEqual(layers[0], bound["boundObservations"][0]["proofLayer"])
        data["observations"][0]["proofLayer"] = layers[1]
        catalog.write_text(json.dumps(data))
        _, inputs = proof_observations(self.root)
        self.inputs.update(inputs)
        self.current.update(inputs)
        self.facts["CurrentInput"] = list(self.current.items())
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        edges = [edge for edge in graph["edges"] if edge["relation"] == "current-proof-layer"]
        self.assertEqual([layers[1]], [nodes[edge["target"]]["key"] for edge in edges])
        (self.root / layers[1]).write_text("changed current ranking model")
        with self.assertRaisesRegex(ValueError, "partial proof inputs changed"):
            self.graph()

    def test_git_status_does_not_call_local_or_dirty_inputs_committed(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "tracked").write_text("original\n")
            (root / ".gitignore").write_text("local\n")
            for command in (["git", "init", "-q"], ["git", "add", "tracked", ".gitignore"],
                            ["git", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.org", "commit", "-qm", "fixture"]):
                subprocess.run(command, cwd=root, capture_output=True, check=True)
            (root / "tracked").write_text("changed\n")
            (root / "local").write_text("ignored\n")
            (root / "untracked").write_text("new\n")
            state = checkout(root, {"tracked", "local", "untracked", ".gitignore"})
            self.assertEqual("tracked-modified", state["files"]["tracked"]["gitStatus"])
            self.assertEqual("ignored-local", state["files"]["local"]["gitStatus"])
            self.assertEqual("untracked", state["files"]["untracked"]["gitStatus"])
            self.assertTrue(state["files"][".gitignore"]["durableAtHead"])
            self.assertFalse(state["files"]["tracked"]["durableAtHead"])

    def test_submodule_inputs_bind_child_repository_and_parent_pin(self):
        with TemporaryDirectory() as directory:
            upstream = Path(directory) / "upstream"
            root = Path(directory) / "parent"
            upstream.mkdir()
            root.mkdir()
            def git(cwd, *args):
                return subprocess.run(["git", *args], cwd=cwd, capture_output=True, check=True)
            git(upstream, "init", "-q")
            (upstream / "tracked source").write_text("original\n")
            git(upstream, "add", "tracked source")
            git(upstream, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.org",
                "commit", "-qm", "child")
            git(root, "init", "-q")
            git(root, "-c", "protocol.file.allow=always", "submodule", "add", str(upstream), "vendor/child")
            git(root, "-c", "user.name=Fixture", "-c", "user.email=fixture@example.org",
                "commit", "-qm", "parent")
            name = "vendor/child/tracked source"
            state = checkout(root, {name})
            self.assertTrue(state["files"][name]["durableAtHead"])
            self.assertEqual(state["submodules"]["vendor/child"]["pinnedRevision"],
                             state["files"][name]["repositoryHead"])
            (root / name).write_text("changed\n")
            state = checkout(root, {name})
            self.assertEqual("tracked-modified", state["files"][name]["gitStatus"])
            self.assertFalse(state["files"][name]["durableAtHead"])
            self.assertFalse(state["submodules"]["vendor/child"]["matchesParentHead"])
            git(root / "vendor/child", "add", "tracked source")
            git(root / "vendor/child", "-c", "user.name=Fixture", "-c", "user.email=fixture@example.org",
                "commit", "-qm", "new unpinned child")
            state = checkout(root, {name})
            self.assertEqual("committed-unchanged", state["files"][name]["gitStatus"])
            self.assertFalse(state["files"][name]["durableAtHead"])
            self.assertNotEqual(state["submodules"]["vendor/child"]["pinnedRevision"],
                                state["files"][name]["repositoryHead"])

    def test_partial_proof_notes_are_bound_with_row_override_and_no_cache_path(self):
        self.add_partial_proof()
        (self.root / "docs").mkdir()
        for name in ("safety.md", "source.md"):
            (self.root / "docs" / name).write_text(name)
        catalog = self.root / PROOF_OBSERVATIONS
        data = json.loads(catalog.read_text())
        data["notes"] = "docs/safety.md"
        catalog.write_text(json.dumps(data))
        bound, _ = proof_observations(self.root)
        self.assertEqual("docs/safety.md", bound["boundObservations"][0]["notes"])
        data["observations"][0]["notes"] = "docs/source.md"
        catalog.write_text(json.dumps(data))
        _, inputs = proof_observations(self.root)
        self.inputs.update(inputs)
        graph = self.graph()
        nodes = {node["id"]: node for node in graph["nodes"]}
        edges = [edge for edge in graph["edges"] if edge["relation"] == "review-notes"]
        self.assertEqual(["docs/source.md"], [nodes[edge["target"]]["key"] for edge in edges])
        self.assertFalse(edges[0]["sourceRefinementEstablished"])
        (self.root / "docs/source.md").write_text("changed native obligations")
        with self.assertRaisesRegex(ValueError, "partial proof inputs changed"):
            self.graph()
        data["observations"][0]["notes"] = ".data/source.md"
        catalog.write_text(json.dumps(data))
        with self.assertRaisesRegex(ValueError, "repository documentation"):
            proof_observations(self.root)
        data["observations"][0]["notes"] = "docs/cache.md"
        catalog.write_text(json.dumps(data))
        (self.root / ".data").mkdir()
        (self.root / ".data/source.md").write_text("local receipt")
        (self.root / "docs/cache.md").symlink_to(self.root / ".data/source.md")
        with self.assertRaisesRegex(ValueError, "resolve into a cache"):
            proof_observations(self.root)


if __name__ == "__main__":
    unittest.main()
