"""Real Scheme correlation of scheduler ownership and collective observations."""
import unittest

from gambit_smp.ascent_program import engine_api, load_evidence_catalog, query
from gambit_smp.framework import ROOT


class SchedulerWaitEvidenceTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.catalog = load_evidence_catalog(
            ROOT / "evidence/research/exit-drain-mutex-lock-order/wait-contract.ss",
            constructor="make-scheduler-wait-evidence", trusted=True)

    def read(self, **updates):
        facts = dict(question=[["tfib"]],
                     wait_observation=[["tfib", "producer", "sample", "lock", "waiter", "owner", 7]],
                     owner_observation=[["producer", "sample", "lock", "owner", "owned-lock-record"]],
                     phase_observation=[["producer", "sample", "owner", 7, "collective-await"]],
                     required_participant=[["producer", "sample", 7, "waiter"]],
                     participation=[], coherent_sample=[["producer", "sample", "source-bound-observation"]],
                     held_lock=[["producer", "sample", "owner", "lock", "scheduler-ticket"]],
                     held_inventory=[["producer", "sample", "waiter", 0, "waiter-census"],
                                     ["producer", "sample", "owner", 1, "owner-census"]])
        facts.update(updates)
        with engine_api() as (engine, _):
            return query(facts, self.catalog, {name: name for name in
                         ("correlated_wait", "pending_participation", "missing")}, engine=engine)

    def test_correlated_pending_is_not_a_deadlock_verdict(self):
        result = self.read()
        self.assertEqual(result["missing"], [])
        self.assertEqual(result["pending_participation"], [("tfib", 7, "waiter")])
        self.assertEqual(len(result["correlated_wait"]), 1)

    def test_cross_producer_or_owner_does_not_supply_ownership(self):
        for row in (["other", "sample", "lock", "owner", "record"],
                    ["producer", "sample", "lock", "other-owner", "record"]):
            with self.subTest(row=row):
                result = self.read(owner_observation=[row])
                self.assertEqual(result["correlated_wait"], [])
                self.assertIn(("tfib", "actual-owner"), result["missing"])

    def test_stale_phase_or_acknowledgement_does_not_close_current_epoch(self):
        phase = self.read(phase_observation=[["producer", "sample", "owner", 6, "collective-await"]])
        self.assertEqual(phase["correlated_wait"], [])
        ack = self.read(participation=[["producer", "sample", 6, "waiter"]])
        self.assertEqual(ack["pending_participation"], [("tfib", 7, "waiter")])
        current = self.read(participation=[["producer", "sample", 7, "waiter"]])
        self.assertEqual(current["pending_participation"], [])

    def test_post_gc_callback_is_not_collective_wait(self):
        result = self.read(phase_observation=[["producer", "sample", "owner", 7, "post-gc-callback"]])
        self.assertEqual(result["pending_participation"], [])
        self.assertEqual(len(result["correlated_wait"]), 1)

    def test_partial_rows_cannot_be_combined_into_a_complete_case(self):
        result = self.read(
            wait_observation=[["tfib", "producer", "first", "lock", "waiter", "owner", 7],
                              ["tfib", "producer", "second", "lock", "waiter", "owner", 7]],
            owner_observation=[["producer", "first", "lock", "owner", "record"]],
            phase_observation=[["producer", "second", "owner", 7, "collective-await"]],
            coherent_sample=[["producer", "first", "witness"]])
        self.assertEqual(result["correlated_wait"], [])
        self.assertIn(("tfib", "ambiguous-wait-identity"), result["missing"])

    def test_conflicting_holder_records_remain_counterevidence(self):
        result = self.read(owner_observation=[
            ["producer", "sample", "lock", "owner", "record"],
            ["producer", "sample", "lock", "other-owner", "record"]])
        self.assertEqual(result["correlated_wait"], [])
        self.assertIn(("tfib", "conflicting-holder-observations"), result["missing"])

    def test_explicit_empty_held_inventory_is_not_missing_inventory(self):
        self.assertEqual(self.read()["missing"], [])
        absent = self.read(held_inventory=[])
        self.assertEqual(absent["correlated_wait"], [])
        self.assertIn(("tfib", "caller-held-lock-inventory"), absent["missing"])
        self.assertIn(("tfib", "owner-held-lock-inventory"), absent["missing"])

    def test_census_mismatch_and_missing_owner_lock_do_not_close(self):
        mismatch = self.read(held_inventory=[
            ["producer", "sample", "waiter", 1, "waiter-census"],
            ["producer", "sample", "owner", 1, "owner-census"]])
        self.assertEqual(mismatch["correlated_wait"], [])
        no_owner_lock = self.read(held_lock=[], held_inventory=[
            ["producer", "sample", "waiter", 0, "waiter-census"],
            ["producer", "sample", "owner", 0, "owner-census"]])
        self.assertEqual(no_owner_lock["correlated_wait"], [])
        self.assertIn(("tfib", "owner-held-lock-inventory"), no_owner_lock["missing"])

    def test_missing_observation_stays_open_and_sample_label_is_not_a_witness(self):
        result = self.read(wait_observation=[], owner_observation=[], phase_observation=[], coherent_sample=[])
        self.assertEqual(set(result["missing"]), {
            ("tfib", "wait-identity"), ("tfib", "actual-owner"),
            ("tfib", "same-generation-gc-phase"), ("tfib", "coherent-observation-boundary"),
            ("tfib", "caller-held-lock-inventory"), ("tfib", "owner-held-lock-inventory")})
        self.assertEqual(result["correlated_wait"], [])
        unbound = self.read(coherent_sample=[])
        self.assertEqual(unbound["correlated_wait"], [])
        self.assertIn(("tfib", "coherent-observation-boundary"), unbound["missing"])

    def retirement(self, events=(), census=(), coherence=True):
        facts = {
            "retirement_question": [["tfib", "producer", "execution", "interval"]],
            "retirement_boundary": list(events), "retirement_census": list(census),
            "retirement_coherence": [["producer", "execution", "interval", "witness"]] if coherence else [],
        }
        with engine_api() as (engine, _):
            return query(facts, self.catalog, {name: name for name in
                         ("retirement_applicability", "conditional_retirement_hazard")}, engine=engine)

    def test_retirement_requires_execution_interval_correspondence(self):
        for event in ([], [["producer", "execution", "interval", "scheme-join", "witness"]],
                      [["other", "execution", "interval", "entered", "witness"]],
                      [["producer", "old-run", "interval", "entered", "witness"]],
                      [["producer", "execution", "old-interval", "entered", "witness"]]):
            with self.subTest(event=event):
                result = self.retirement(events=event)
                self.assertEqual(result["retirement_applicability"], [("tfib", "unknown")])
                self.assertEqual(result["conditional_retirement_hazard"], [])

    def test_actual_stress_failure_is_an_observation_not_closed_by_cohort_return(self):
        result = self.read(
            cohort_observation=[["producer", "retained-lock", "owner", "owner", "waiter",
                                 1, 1, "returned", "source-bound-observation"]],
            stress_observation=[["producer", "tfib_stress.scm", 0, 10, "signal",
                                 "source-bound-observation"]])
        self.assertIn(("tfib", "stress-not-closed-by-cohort"), result["missing"])

    def test_retirement_entry_is_not_a_callback_gc_or_signal_cause(self):
        events = [["producer", "execution", "interval", event, "witness"]
                  for event in ("entered", "signal-10", "join-exit-70", "inactivity")]
        result = self.retirement(events=events)
        self.assertEqual(result["retirement_applicability"], [("tfib", "entered")])
        self.assertEqual(result["conditional_retirement_hazard"], [])
        events.extend([["producer", "execution", "interval", event, "witness"]
                       for event in ("callback-gc", "withdrawn-or-joining-wait-cycle")])
        self.assertEqual(self.retirement(events=events)["conditional_retirement_hazard"], [("tfib",)])
        self.assertEqual(self.retirement(events=events, coherence=False)["retirement_applicability"],
                         [("tfib", "unknown")])

    def test_retirement_absence_needs_complete_census_and_conflicts_stay_visible(self):
        census = [["producer", "execution", "interval", 0, "witness"]]
        self.assertEqual(self.retirement(census=census)["retirement_applicability"],
                         [("tfib", "excluded-in-interval")])
        events = [["producer", "execution", "interval", "entered", "witness"]]
        result = self.retirement(events=events, census=census)
        self.assertEqual(result["retirement_applicability"], [("tfib", "conflicting-witnesses")])
        self.assertEqual(result["conditional_retirement_hazard"], [])


if __name__ == "__main__":
    unittest.main()
