"""Generic source identity transport; no research admission or inference."""
import os
import json
from pathlib import Path
import tempfile
import time
import unittest
from unittest.mock import patch

from gambit_smp import recipes


class LeasedTreeChecksTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name).resolve()
        self.tree = self.root / ".data/fixtures/tree"
        self.tree.mkdir(parents=True)
        self.file = self.tree / "unit.c"
        self.file.write_text("int a;\n")
        self.identity = recipes.tree_identity(self.tree)

    def context(self):
        return recipes.ExecutionContext(self.root, self.root, self.root, {},
            time.monotonic() + 15, {}, {}, {})

    def test_scandir_stamp_preserves_complete_legacy_inventory(self):
        (self.tree / ".hidden").mkdir()
        (self.tree / ".hidden/item").write_text("hidden")
        (self.tree / "a").mkdir()
        (self.tree / "a/item").write_text("nested")
        (self.tree / "a-z").write_text("ordering")
        (self.tree / "internal-link").symlink_to("unit.c")
        def stamp(path):
            s = path.lstat()
            return (s.st_dev, s.st_ino, s.st_mode, s.st_nlink,
                    s.st_size, s.st_mtime_ns, s.st_ctime_ns)
        expected = (stamp(self.tree), tuple((p.relative_to(self.tree).as_posix(), stamp(p))
                                            for p in sorted(self.tree.rglob("*"))))
        self.assertEqual(recipes._tree_stamp(self.tree), expected)

    def test_inspection_binds_owner_teardown_and_rejects_receipt_tampering(self):
        out = self.root / "owner-observation"
        out.mkdir()
        tools = out / "tools.json"
        tools.write_text("{}")
        owner = out / "owner.json"
        body = {"exit": 0, "parentReaped": True, "forcedTermination": False,
                "terminalIdentityError": None, "engineId": "unit",
                "requests": [{"requestCompleted": True, "timeout": False}]}
        owner.write_text(json.dumps(body))
        receipt = {"schema": "evidence-recipe-run.v1", "recipe": "unit", "outcome": "PASS",
            "inputs": {}, "steps": [], "engine": {"engineId": "unit"},
            "toolInputs": {"path": "tools.json", "sha256": recipes.digest(tools)},
            "evaluationOwner": {"path": "owner.json", "sha256": recipes.digest(owner)}}
        (out / "receipt.json").write_text(json.dumps(receipt))
        self.assertEqual(recipes.inspect_run(out)["identityStatus"], "CURRENT")
        body["forcedTermination"] = True
        owner.write_text(json.dumps(body))
        self.assertEqual(recipes.inspect_run(out)["identityStatus"], "STALE")
        receipt["evaluationOwner"]["sha256"] = recipes.digest(owner)
        (out / "receipt.json").write_text(json.dumps(receipt))
        self.assertEqual(recipes.inspect_run(out)["identityStatus"], "STALE")

    def test_same_lease_reuses_but_final_reads_sha_and_does_not_leak(self):
        context = self.context()
        with patch.object(recipes, "digest", wraps=recipes.digest) as reads:
            context.lease_workspace(self.tree, self.identity)
            try:
                first = recipes.tree_identity(self.tree)
                first["unit.c"]["sha256"] = "bad"
                self.assertEqual(recipes.tree_identity(self.tree), self.identity)
                self.assertEqual(context.leased_tree_checks.reused, 2)
                self.assertEqual(reads.call_count, 1)
                context.leased_tree_checks.verify()
                self.assertEqual(reads.call_count, 2)
                costs = context.leased_tree_checks.costs()
                self.assertEqual((1, 2, 1), tuple(costs[n] for n in
                                 ('full_reads', 'reused', 'final_reads')))
                self.assertTrue(all(costs[n] >= 0 for n in
                                ('read_seconds', 'reuse_seconds', 'verify_seconds')))
            finally:
                context.workspace_leases.close()
            self.assertIsNone(recipes._leased_tree_checks.get())
            recipes.tree_identity(self.tree)
            self.assertEqual(reads.call_count, 3)

    def test_same_size_write_with_restored_mtime_invalidates(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            state = self.file.stat()
            self.file.write_text("int b;\n")
            os.utime(self.file, ns=(state.st_atime_ns, state.st_mtime_ns))
            changed = recipes.tree_identity(self.tree)
            self.assertNotEqual(changed, self.identity)
            self.assertEqual(context.leased_tree_checks.full_reads, 2)
            context.leased_tree_checks.verify()
        finally:
            context.workspace_leases.close()

    def test_post_read_write_is_rejected_by_final_verification(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            self.file.write_text("int changed;\n")
            with self.assertRaisesRegex(ValueError, "final verification"):
                context.leased_tree_checks.verify()
        finally:
            context.workspace_leases.close()

    def test_add_delete_mode_and_inode_are_inventory_changes(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            extra = self.tree / "header.h"
            extra.write_text("int a;\n")
            self.assertIn("header.h", recipes.tree_identity(self.tree))
            extra.unlink()
            self.assertNotIn("header.h", recipes.tree_identity(self.tree))
            self.file.chmod(0o600)
            self.assertEqual(recipes.tree_identity(self.tree)["unit.c"]["mode"], 0o600)
            self.file.unlink()
            self.file.write_text("int a;\n")
            recipes.tree_identity(self.tree)
            self.assertEqual(context.leased_tree_checks.full_reads, 5)
            context.leased_tree_checks.verify()
        finally:
            context.workspace_leases.close()

    def test_external_link_never_reuses_an_admitted_inventory(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            (self.tree / "escape").symlink_to(self.root)
            with self.assertRaisesRegex(ValueError, "external symlink"):
                recipes.tree_identity(self.tree)
        finally:
            context.workspace_leases.close()

    def test_new_context_and_nonleased_paths_never_share(self):
        for _ in range(2):
            context = self.context()
            context.lease_workspace(self.tree, self.identity)
            try:
                recipes.tree_identity(self.tree)
                recipes.tree_identity(self.root)
                self.assertEqual(context.leased_tree_checks.full_reads, 1)
                self.assertEqual(context.leased_tree_checks.reused, 1)
                context.leased_tree_checks.verify()
            finally:
                context.workspace_leases.close()

    def test_repeated_lease_reuses_lock_but_checks_requested_identity(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            self.assertEqual(context.lease_workspace(self.tree, self.identity), self.tree)
            self.assertEqual(len(context.leased_workspaces), 1)
            with self.assertRaisesRegex(ValueError, "held workspace state"):
                context.lease_workspace(self.tree, {})
            context.leased_tree_checks.verify()
        finally:
            context.workspace_leases.close()

    def test_recipe_scope_retains_lock_across_steps_but_never_next_recipe(self):
        from gambit_smp.artifact_storage import workspace_lease
        scope = recipes.WorkspaceValidationScope()
        try:
            for _ in range(2):
                context = recipes.ExecutionContext(self.root, self.root, self.root, {},
                    time.monotonic() + 15, {}, {}, {}, workspace_scope=scope)
                try:
                    context.lease_workspace(self.tree, self.identity)
                    self.assertEqual(recipes.tree_identity(self.tree), self.identity)
                    context.leased_tree_checks.verify()
                finally:
                    context.workspace_leases.close()
                self.assertIsNone(recipes._leased_tree_checks.get())
                with self.assertRaisesRegex(ValueError, "already leased"):
                    with workspace_lease(self.root, self.tree, self.identity):
                        pass
            self.assertEqual(scope.checks.full_reads, 1)
            self.assertEqual(scope.checks.final_reads, 2)
        finally:
            scope.close()
        with workspace_lease(self.root, self.tree, self.identity):
            pass
        self.assertFalse(scope.paths)
        self.assertFalse(scope.checks.checked)
        with self.assertRaisesRegex(ValueError, "closed workspace validation scope"):
            recipes.ExecutionContext(self.root, self.root, self.root, {},
                time.monotonic() + 15, {}, {}, {}, workspace_scope=scope)

    def test_runtime_checks_use_full_leased_inventory_and_reject_drift(self):
        from gambit_smp.suite_primitives import check_runtime
        for name in ("gsi/gsi", "gsc/gsc", "lib/libgambit.a"):
            path = self.tree / name
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(self.file.read_bytes())
        expected = recipes.tree_identity(self.tree)
        sha = expected["unit.c"]["sha256"]
        identity = {"sourceFiles": {"unit.c": sha}, "binarySha256": sha,
                    "gscSha256": sha, "librarySha256": sha}
        context = self.context()
        context.lease_workspace(self.tree, expected)
        try:
            with patch("gambit_smp.suite_primitives.digest", side_effect=AssertionError("duplicate read")):
                check_runtime(self.tree, identity)
                check_runtime(self.tree, identity)
                self.file.write_text("int changed;\n")
                with self.assertRaisesRegex(ValueError, "candidate input inventory"):
                    check_runtime(self.tree, identity)
        finally:
            context.workspace_leases.close()
        with patch("gambit_smp.suite_primitives.digest", wraps=recipes.digest) as reads:
            with self.assertRaisesRegex(ValueError, "candidate input inventory"):
                check_runtime(self.tree, identity)
            self.assertGreater(reads.call_count, 0)

    def test_mutation_before_repeated_lease_cannot_reuse_admission(self):
        context = self.context()
        context.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            self.file.write_text("int changed;\n")
            with self.assertRaisesRegex(ValueError, "held workspace state"):
                context.lease_workspace(self.tree, self.identity)
        finally:
            context.workspace_leases.close()

    def test_nested_context_restores_outer_scope(self):
        other = self.root / ".data/fixtures/other"
        other.mkdir()
        (other / "header.h").write_text("int b;\n")
        outer, inner = self.context(), self.context()
        outer.lease_workspace(self.tree, self.identity)
        try:
            recipes.tree_identity(self.tree)
            inner.lease_workspace(other, recipes.tree_identity(other))
            try:
                self.assertIs(recipes._leased_tree_checks.get(), inner.leased_tree_checks)
                recipes.tree_identity(other)
                inner.leased_tree_checks.verify()
            finally:
                inner.workspace_leases.close()
            self.assertIs(recipes._leased_tree_checks.get(), outer.leased_tree_checks)
            recipes.tree_identity(self.tree)
            self.assertEqual(outer.leased_tree_checks.reused, 2)
            outer.leased_tree_checks.verify()
        finally:
            outer.workspace_leases.close()


if __name__ == "__main__":
    unittest.main()
