import unittest

from gambit_smp.framework import ROOT
from gambit_smp.native_review import failure_modes, failure_campaign_files
from gambit_smp.recipes import read_json


class FailureScopeTests(unittest.TestCase):
    def test_actual_recorded_campaigns_have_closed_nonstress_inventories(self):
        for filename in ("native-upstream-all-compiled-019-parallel-deny.json",
                         "native-upstream-all-compiled-020-balanced-deny.json",
                         "native-upstream-compiled-atomic-023-deny.json"):
            receipt = read_json(ROOT / "evidence/model-results" / filename)
            files = failure_campaign_files(receipt)
            self.assertEqual(receipt["filesPerMode"], len(files))
            self.assertFalse(any(name.endswith("_stress.scm") for name in files))

    def test_malformed_or_unknown_campaign_is_not_closed(self):
        import copy
        valid = {"schema":"gambit-upstream-suite.v1", "status":"DENY",
                 "selectedFiles":["control.scm"], "filesPerMode":1,
                 "sourceFiles":{"unit-tests/control.scm":"a"*64}}
        self.assertEqual(["control.scm"], failure_campaign_files(valid))
        extra = copy.deepcopy(valid)
        extra["sourceFiles"] = {}
        extra["extraFixtures"] = {"control.scm":{"sha256":"b"*64,"testedSha256":"a"*64}}
        self.assertEqual(["control.scm"], failure_campaign_files(extra))
        for change in ({"schema":"unknown"}, {"selectedFiles":[]}, {"filesPerMode":2},
                       {"sourceFiles":{}}, {"selectedFiles":["../control.scm"]},
                       {"selectedFiles":["control.scm","control.scm"],"filesPerMode":2}):
            receipt = copy.deepcopy(valid)
            receipt.update(change)
            self.assertIsNone(failure_campaign_files(receipt))

    def test_summary_mode_is_not_an_unrelated_compiled_failure(self):
        receipt = read_json(ROOT / "evidence/model-results/native-upstream-all-interpreted-018-deny.json")
        self.assertEqual({"gsi"}, failure_modes(receipt))

    def test_compiler_phase_is_not_an_interpreter_failure(self):
        receipt = read_json(ROOT / "evidence/model-results/native-compiler-cost-num-021-deny.json")
        self.assertEqual({"gsc"}, failure_modes(receipt))

    def test_results_preserve_only_actual_failed_modes(self):
        self.assertEqual({"gsc"}, failure_modes({"results": [
            {"mode": "gsi", "accepted": True}, {"mode": "gsc", "accepted": False}]}))

    def test_unknown_or_unbound_mode_remains_conservative(self):
        for receipt in ({}, {"mode": "gsi"},
                        {"schema": "unknown", "status": "DENY", "mode": "gsi"},
                        {"results": [{"mode": "gsi", "accepted": True}]},
                        {"results": [{"mode": "gsc", "accepted": False},
                                     {"accepted": False}]},
                        {"results": [{"mode": "gsi", "accepted": 0}]}):
            self.assertEqual(set(), failure_modes(receipt))

    def test_compiler_claim_needs_actual_diagnostic_failure(self):
        for diagnostic, accepted, name in ((False, False, "scheme-to-c"),
                                          (True, True, "scheme-to-c"),
                                          (True, False, "unknown")):
            self.assertEqual(set(), failure_modes({"schema": "gambit-compiler-cost.v1",
                "diagnosticOnly": diagnostic, "stages": [{"name": name, "accepted": accepted}]}))


class FailureCampaignPolicyTests(unittest.TestCase):
    def evaluate(self, *, category="budget", scope="tests/run-unit-tests.scm", closed=True, overlap=False):
        from gambit_smp.ascent_program import load_catalog, query
        facts = {"retry_marker":[[True]], "known_failure":[["opaque-campaign","gsc"]],
                 "selected_failure":[["opaque-campaign"]], "failure_category":[["opaque-campaign",category]],
                 "failure_scope":[["opaque-campaign",scope]],
                 "current_campaign_file":[["stress.scm"]],
                 "failure_campaign_closed":[["opaque-campaign"]] if closed else [],
                 "failure_campaign_file":[["opaque-campaign", "stress.scm" if overlap else "unit.scm"]]}
        return query(facts,load_catalog(ROOT/"evidence/research/suite-review-rules.ss"),
                     {"selected":"selected_known_failure", "disjoint":"failure_campaign_disjoint"})

    def test_only_closed_disjoint_runner_budget_is_excluded(self):
        self.assertEqual({"selected":[],"disjoint":[("opaque-campaign","gsc")]},self.evaluate())
        for change in ({"category":"assertion"}, {"category":"crash"}, {"closed":False},
                       {"overlap":True}, {"scope":"lib/mem.c"}):
            with self.subTest(change=change):
                self.assertEqual({"selected":[("opaque-campaign","gsc")],"disjoint":[]},self.evaluate(**change))


if __name__ == "__main__":
    unittest.main()
