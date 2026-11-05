"""Scoped completion never changes a producer or substitutes a score for tests."""
import copy
from pathlib import Path
from unittest.mock import patch
import unittest

from gambit_smp.smp_completion import complete_mvp, validate_mvp_completion


class SmpCompletionTests(unittest.TestCase):
    def setUp(self):
        self.root, self.workspace = Path("/root"), Path("/workspace")
        self.generated = {f"lib/unit-{i}.c": "a" * 64 for i in range(51)}
        self.producer = dict(
            complete=False, producerComplete=True, generatedProductsPublished=False,
            baseRevision="base", targetTree="tree", canonicalSources={"lib/a.scm": "b" * 64},
            artifacts={"gsc/gsc": "c" * 64}, generatedArtifacts=self.generated,
            phaseCounts={f"phase{i}": 2 for i in range(1, 5)},
            heapRaised=False, waitExtended=False, wholeLimitSeconds=600)
        self.accepted = dict(
            closed=["bootstrap", "gsi", "gsc"], passed=3, sourceTree="tree",
            profileSha256="d" * 64, receipts={
                "bootstrap": dict(path="bootstrap", sha256="bootstrap-hash"),
                "gsi": dict(path="gsi", sha256="gsi-hash"),
                "gsc": dict(path="gsc", sha256="gsc-hash")})
        self.bootstrap = dict(
            producerSha256="producer-hash", phaseCounts=self.producer["phaseCounts"],
            artifacts=self.producer["artifacts"])
        ref = dict(step="runtime", output="runtime")
        request = dict(runtime=ref, identity=ref, mode="gsc", regime="whole-parallel",
                       selection=["."], expectedFiles=["case.scm"], sharedAssertions=True)
        self.gsc = dict(wholeBudgetSeconds=300, jobs=5, counters={"PASS": 408},
                        caseObservations=[dict(status="PASS") for _ in range(408)],
                        suiteRequest=request, validationInputs={"code.py": "a" * 64})
        self.data = {
            "producer": self.producer, "acceptance": dict(mvpAdmitted=True),
            "bootstrap": self.bootstrap, "gsc": self.gsc}
        self.references = {name: dict(path=name, sha256=name + "-hash") for name in self.data}

    def load(self, root, path, expected=None):
        return self.data[str(path)], self.references[str(path)]

    def finalize(self):
        with patch("gambit_smp.smp_completion.digest", return_value="a" * 64):
            return complete_mvp(self.root, self.workspace, "producer", "acceptance")

    def test_completed_mvp_keeps_monolithic_and_publication_flags(self):
        before = copy.deepcopy(self.producer)
        with (patch("gambit_smp.smp_completion._load_smp_evidence", side_effect=self.load),
              patch("gambit_smp.smp_completion.accepted_smp_progress", return_value=self.accepted),
              patch("gambit_smp.smp_completion.authenticate_distribution_predecessor") as physical,
              patch("gambit_smp.smp_completion.generated_inventory", return_value=self.generated)):
            result = self.finalize()
            self.assertTrue(result["complete"])
            self.assertFalse(result["producerEnvelope"]["complete"])
            self.assertFalse(result["producerEnvelope"]["generatedProductsPublished"])
            self.assertFalse(result["generatedProductsPublished"])
            self.assertTrue(result["generatedProductsReady"])
            self.assertEqual(self.producer, before)
            physical.assert_called_once_with(self.workspace, self.producer)
            with patch("gambit_smp.smp_completion.digest", return_value="a" * 64):
                validate_mvp_completion(self.root, self.workspace, result)
            for changed in (dict(generatedProductsPublished=True),
                            dict(profileSha256="wrong"), dict(generatedProductsReady=False)):
                with self.assertRaisesRegex(ValueError, "differs"), patch(
                        "gambit_smp.smp_completion.digest", return_value="a" * 64):
                    validate_mvp_completion(self.root, self.workspace, {**result, **changed})

    def test_flag_only_wrapper_is_not_a_typed_completion(self):
        with self.assertRaisesRegex(ValueError, "typed first-three"):
            validate_mvp_completion(self.root, self.workspace, {**self.producer, "complete": True})

    def test_missing_family_or_partial_original_campaign_refuses(self):
        with (patch("gambit_smp.smp_completion._load_smp_evidence", side_effect=self.load),
              patch("gambit_smp.smp_completion.accepted_smp_progress", return_value=self.accepted),
              patch("gambit_smp.smp_completion.authenticate_distribution_predecessor"),
              patch("gambit_smp.smp_completion.generated_inventory", return_value=self.generated)):
            self.accepted["passed"] = 2
            with self.assertRaisesRegex(ValueError, "first-three-family"):
                self.finalize()
            self.accepted["passed"] = 3
            self.gsc["counters"] = {"PASS": 407, "UNRESOLVED": 1}
            with self.assertRaisesRegex(ValueError, "one complete original"):
                self.finalize()

    def test_changed_physical_cohort_or_wrong_producer_refuses(self):
        with (patch("gambit_smp.smp_completion._load_smp_evidence", side_effect=self.load),
              patch("gambit_smp.smp_completion.accepted_smp_progress", return_value=self.accepted),
              patch("gambit_smp.smp_completion.authenticate_distribution_predecessor"),
              patch("gambit_smp.smp_completion.generated_inventory", return_value={})):
            with self.assertRaisesRegex(ValueError, "current generated cohort"):
                self.finalize()
            self.bootstrap["producerSha256"] = "wrong"
            with self.assertRaisesRegex(ValueError, "actual accepted producer"):
                self.finalize()

    def test_resource_change_refuses_even_with_complete_families(self):
        with (patch("gambit_smp.smp_completion._load_smp_evidence", side_effect=self.load),
              patch("gambit_smp.smp_completion.accepted_smp_progress", return_value=self.accepted),
              patch("gambit_smp.smp_completion.authenticate_distribution_predecessor"),
              patch("gambit_smp.smp_completion.generated_inventory", return_value=self.generated)):
            for key, changed in (("heapRaised", True), ("waitExtended", True), ("wholeLimitSeconds", 601)):
                before = self.producer[key]
                self.producer[key] = changed
                with self.assertRaisesRegex(ValueError, "resource limits"):
                    self.finalize()
                self.producer[key] = before
