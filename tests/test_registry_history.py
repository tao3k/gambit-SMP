import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.framework import digest
from gambit_smp.registry_history import validate
from gambit_smp.reflection import validate as validate_reflection


class RegistryHistoryTests(unittest.TestCase):
    def setUp(self):
        temporary = TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.root = Path(temporary.name)
        self.save("parent.json", {"schema": "registry.v1", "items": [["a", "a.json"]]})
        self.save("registered.json", {"schema": "registry.v1", "items": [["a", "a.json"], ["b", "b.json"]]})
        self.save("current.json", {"schema": "registry.v1", "items": [["a", "a.json"], ["b", "b.json"], ["c", "c.json"]]})
        self.save("claim.json", {"claim": {"path": "current.json", "sha256": digest(self.root / "registered.json")}})
        self.manifest = {
            "schema": "gambit-evidence-history.v1", "registrySchema": "registry.v1",
            "collection": "items", "identityPointer": [0],
            "snapshots": [dict(self.descriptor("parent.json"), id="parent"),
                          dict(self.descriptor("registered.json"), id="registered", additions=[["b", "b.json"]])],
            "current": {"path": "current.json", "requiredAdditions": [["c", "c.json"]]},
            "bindings": [{"snapshot": "registered", "artifact": self.descriptor("claim.json"),
                          "pointer": ["claim"], "recordedPath": "current.json"}],
        }

    def save(self, name, value):
        (self.root / name).write_text(json.dumps(value))

    def descriptor(self, name):
        return {"path": name, "sha256": digest(self.root / name)}

    def check(self):
        self.save("history.json", self.manifest)
        return validate(self.root, "history.json")

    def test_complete_chain_binds_current_and_historical_bytes(self):
        result = self.check()
        self.assertEqual(set(result), {"history.json", "parent.json", "registered.json", "current.json", "claim.json"})
        for name, sha in result.items():
            self.assertEqual(sha, digest(self.root / name))

    def test_future_append_is_valid_but_changes_current_input(self):
        before = self.check()
        current = json.loads((self.root / "current.json").read_text())
        current["items"].append(["d", "d.json"])
        self.save("current.json", current)
        after = self.check()
        self.assertNotEqual(before["current.json"], after["current.json"])
        self.assertEqual(before["claim.json"], after["claim.json"])

    def test_historical_bytes_cannot_change_even_with_same_items(self):
        with (self.root / "registered.json").open("a") as stream:
            stream.write(" ")
        with self.assertRaisesRegex(ValueError, "stale history"):
            self.check()

    def test_current_deletion_reorder_and_replacement_are_rejected(self):
        for rows in ([["a", "a.json"], ["c", "c.json"]],
                     [["b", "b.json"], ["a", "a.json"], ["c", "c.json"]],
                     [["a", "changed.json"], ["b", "b.json"], ["c", "c.json"]]):
            with self.subTest(rows=rows):
                self.save("current.json", {"schema": "registry.v1", "items": rows})
                with self.assertRaisesRegex(ValueError, "lost or reordered"):
                    self.check()

    def test_changed_history_cannot_be_hidden_by_new_snapshot_hash(self):
        self.save("registered.json", {"schema": "registry.v1", "items": [["b", "b.json"], ["a", "a.json"]]})
        self.manifest["snapshots"][1].update(self.descriptor("registered.json"))
        with self.assertRaisesRegex(ValueError, "strictly extend"):
            self.check()

    def test_declared_transition_must_match_exact_additions(self):
        self.manifest["snapshots"][1]["additions"] = [["wrong", "b.json"]]
        with self.assertRaisesRegex(ValueError, "declared transition"):
            self.check()

    def test_python_boolean_integer_equality_cannot_hide_item_replacement(self):
        for name in ("parent.json", "registered.json"):
            saved = json.loads((self.root / name).read_text())
            saved["items"][0][1] = 1
            self.save(name, saved)
        for snapshot in self.manifest["snapshots"]:
            snapshot.update(self.descriptor(snapshot["path"]))
        self.save("claim.json", {"claim": {"path": "current.json", "sha256": digest(self.root / "registered.json")}})
        self.manifest["bindings"][0]["artifact"] = self.descriptor("claim.json")
        current = json.loads((self.root / "current.json").read_text())
        current["items"][0][1] = True
        self.save("current.json", current)
        with self.assertRaisesRegex(ValueError, "lost or reordered"):
            self.check()

    def test_duplicate_item_identity_is_rejected(self):
        saved = json.loads((self.root / "current.json").read_text())
        saved["items"].append(["c", "different-receipt.json"])
        self.save("current.json", saved)
        with self.assertRaisesRegex(ValueError, "duplicate history item"):
            self.check()

    def test_current_hash_cannot_replace_historical_claim(self):
        self.save("claim.json", {"claim": {"path": "current.json", "sha256": digest(self.root / "current.json")}})
        self.manifest["bindings"][0]["artifact"] = self.descriptor("claim.json")
        with self.assertRaisesRegex(ValueError, "immutable version"):
            self.check()

    def test_stale_claim_artifact_is_rejected(self):
        self.save("claim.json", {"claim": {"path": "current.json", "sha256": "0" * 64}})
        with self.assertRaisesRegex(ValueError, "stale history"):
            self.check()

    def test_unknown_version_and_invalid_selectors_are_rejected(self):
        original = copy.deepcopy(self.manifest)
        for change in ({"snapshot": "absent"}, {"pointer": ["missing"]},
                       {"pointer": ["claim", True]}, {"pointer": "/claim"}):
            self.manifest = copy.deepcopy(original)
            self.manifest["bindings"][0].update(change)
            with self.subTest(change=change), self.assertRaises(ValueError):
                self.check()

    def test_current_cannot_pin_historical_hash(self):
        self.manifest["current"]["sha256"] = digest(self.root / "current.json")
        with self.assertRaisesRegex(ValueError, "must not pin"):
            self.check()

    def test_cache_alias_and_external_paths_are_rejected(self):
        (self.root / ".data").mkdir()
        self.save(".data/snapshot.json", json.loads((self.root / "parent.json").read_text()))
        (self.root / "alias.json").symlink_to(self.root / ".data/snapshot.json")
        for name in (".data/snapshot.json", "alias.json", "../parent.json", str(self.root / "parent.json")):
            self.manifest["snapshots"][0]["path"] = name
            with self.subTest(name=name), self.assertRaises(ValueError):
                self.check()

    def test_duplicate_version_and_snapshot_alias_are_rejected(self):
        self.manifest["snapshots"][1]["id"] = "parent"
        with self.assertRaisesRegex(ValueError, "history version"):
            self.check()
        self.manifest["snapshots"][1]["id"] = "registered"
        (self.root / "alias.json").symlink_to(self.root / "parent.json")
        self.manifest["snapshots"][1].update(self.descriptor("alias.json"))
        with self.assertRaisesRegex(ValueError, "distinct files"):
            self.check()

    def test_registry_schema_mismatch_is_rejected(self):
        self.save("current.json", {"schema": "registry.v2", "items": [["a", "a.json"]]})
        with self.assertRaisesRegex(ValueError, "schema mismatch"):
            self.check()

    def test_reflection_uses_same_contract_and_never_closes_requirements(self):
        self.check()
        reference = {"id": "history", "kind": "limitation", "path": "history.json",
                     "locator": "version chain", "scope": "not runtime proof",
                     "history": self.descriptor("history.json")}
        reflection = {"schema": "gambit-evidence-reflection.v1", "references": [reference],
                      "requirements": [{"id": "native", "status": "open", "gap": "not run",
                                        "conditions": ["native acceptance"], "references": ["history"]}]}
        bound = validate_reflection(self.root, reflection)
        self.assertIn("current.json", bound)
        self.save("current.json", {"schema": "registry.v1", "items": [["a", "a.json"]]})
        with self.assertRaises(ValueError):
            validate_reflection(self.root, reflection)
        self.save("current.json", {"schema": "registry.v1", "items": [["a", "a.json"], ["b", "b.json"], ["c", "c.json"]]})
        reflection["requirements"][0]["status"] = "closed"
        with self.assertRaisesRegex(ValueError, "cannot admit a closed"):
            validate_reflection(self.root, reflection)
