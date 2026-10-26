import io
import tarfile
import unittest
import json
from pathlib import Path
from tempfile import TemporaryDirectory

from gambit_smp.branch_evidence import (archive_sources, source_manifest,
    unit_inventory, bind_case, case_verdict, progress)


class BranchEvidenceTests(unittest.TestCase):
    def setUp(self):
        self.plan = dict(branch="modern-c", revision="commit-a", tree="tree-a",
                         sourceManifestSha256="source-a", profileSha256="profile-a",
                         cases={"original-gsi": {}}, requirements=["Complete GSI inventory"])
        self.producer = {key: self.plan[key] for key in
                         ("revision", "tree", "sourceManifestSha256", "profileSha256")}
        self.producer.update(sourceOverlay=False, artifacts={"gsi/gsi": "binary-a"})
        self.process = dict(exit=0, timeout=False, parentReaped=True, processGroupQuiescent=True)

    def test_dirty_overlay_cannot_become_branch_evidence(self):
        self.producer["sourceOverlay"] = True
        with self.assertRaises(ValueError):
            bind_case(self.plan, "original-gsi", self.producer)

    def test_different_revision_or_binary_cannot_reuse_case(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, self.process, contract_complete=True)
        for key in ("revision", "profileSha256"):
            changed = dict(self.producer, **{key: "different"})
            with self.assertRaises(ValueError):
                progress(self.plan, changed, {"original-gsi": result})
        changed = dict(self.producer, artifacts={"gsi/gsi": "binary-b"})
        with self.assertRaises(ValueError):
            progress(self.plan, changed, {"original-gsi": result})

    def test_exit_zero_without_complete_inventory_is_not_pass(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        self.assertEqual(case_verdict(binding, self.process, contract_complete=False)["status"], "FAIL")

    def test_unknown_exit_retains_unresolved_status(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        self.assertEqual(case_verdict(binding, dict(self.process, exit=None),
                                      contract_complete=True)["status"], "UNRESOLVED")

    def test_pass_does_not_import_patch_count_or_close_semantic_requirement(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, self.process, contract_complete=True)
        state = progress(self.plan, self.producer, {"original-gsi": result})
        self.assertEqual(state["cases"]["original-gsi"], "PASS")
        self.assertEqual(state["requirements"]["Complete GSI inventory"], "UNESTABLISHED")
        self.assertIsNone(state["aggregateProgress"])
        self.assertFalse(state["inheritedPatchCredit"])

    def test_archive_and_inventory_bind_bytes_without_another_checkout(self):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            for name in ("tests/unit-tests/a.scm", "tests/unit-tests/#.scm",
                         "tests/unit-tests/a_stress.scm"):
                entry = tarfile.TarInfo(name); entry.size = 2
                archive.addfile(entry, io.BytesIO(b"()"))
        manifest = source_manifest(archive_sources(stream.getvalue()))
        self.assertEqual(unit_inventory(manifest), ["tests/unit-tests/a.scm"])
        self.assertEqual(unit_inventory(manifest, stress=True), ["tests/unit-tests/a_stress.scm"])

    def test_archive_rejects_path_escape(self):
        stream = io.BytesIO()
        with tarfile.open(fileobj=stream, mode="w") as archive:
            entry = tarfile.TarInfo("../outside"); entry.size = 1
            archive.addfile(entry, io.BytesIO(b"x"))
        with self.assertRaises(ValueError):
            archive_sources(stream.getvalue())

    def test_forged_pass_cannot_override_a_failed_process(self):
        binding = bind_case(self.plan, "original-gsi", self.producer)
        result = case_verdict(binding, dict(self.process, exit=2), contract_complete=False)
        result["status"] = "PASS"
        with self.assertRaises(ValueError):
            progress(self.plan, self.producer, {"original-gsi": result})

    def test_failed_build_checkpoint_admits_only_declared_broken_links(self):
        from gambit_smp.workspace import checkpoint_build_source
        with TemporaryDirectory() as directory:
            parent = Path(directory)
            source = parent / "source"
            (source / "bin").mkdir(parents=True)
            (source / "bin/gsc-script").symlink_to("../gsc/gsc")
            state = parent / "source-state.json"
            state.write_text(json.dumps(dict(inputs={"bin/gsc-script": {}}, observed={})))
            with self.assertRaises(ValueError):
                checkpoint_build_source(source)
            checkpoint_build_source(source, broken_links={"bin/gsc-script": "../gsc/gsc"},
                                    phase="failed-bootstrap")
            self.assertEqual(json.loads(state.read_text())["phase"], "failed-bootstrap")
            (source / "bin/unknown").symlink_to("../unknown")
            with self.assertRaises(ValueError):
                checkpoint_build_source(source, broken_links={"bin/gsc-script": "../gsc/gsc"})
