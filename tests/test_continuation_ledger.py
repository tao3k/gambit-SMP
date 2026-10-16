"""Durable refinement of reservation/settlement, not native retry permission."""
import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
import tempfile
import unittest

from gambit_smp.framework import available_processors, digest
from gambit_smp.recipe_continuation import (
    check_reservation, checkpoint_allowance, continuation_request, initialize_budget_ledger,
    inspect_budget_ledger, reserve_budget, settle_budget,
)


class ContinuationLedgerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        evidence = self.root / "evidence"
        evidence.mkdir()
        self.lock = evidence / "source.lock.json"
        self.lock.write_text('{"source":"fixed"}')
        original = evidence / "original.json"
        original.write_text(json.dumps({"schema": "sealed-research-run.v1", "outcome": "DENY",
            "wholeSeconds": 10, "budgetSeconds": 60, "parentReaped": True, "processGroupQuiescent": True}))
        self.receipts = [(original, digest(original))]
        self.ledger = initialize_budget_ledger(self.root, 60, self.receipts)

    def request(self, name, cap):
        recipe = self.root / "evidence" / (name + ".json")
        recipe.write_text(json.dumps({"budgetSeconds": cap}))
        return continuation_request(self.root, 60, self.receipts, "evidence/source.lock.json",
                                    recipe.relative_to(self.root).as_posix())

    def settle(self, reservation, cap, cost, **changes):
        path = self.root / "evidence" / (reservation["attempt"] + "-result.json")
        record = {"schema": "sealed-research-run.v1", "outcome": "DENY", "wholeSeconds": cost,
                  "budgetSeconds": cap, "parentReaped": True, "processGroupQuiescent": True,
                  "budgetReservation": reservation}
        record.update(changes)
        path.write_text(json.dumps(record))
        return settle_budget(self.root, reservation, path, digest(path))

    def test_competing_reservations_cannot_double_spend(self):
        first = reserve_budget(self.root, self.ledger, self.request("first", 30), "first")
        with self.assertRaisesRegex(ValueError, "shared budget insufficient"):
            reserve_budget(self.root, self.ledger, self.request("second", 30), "second")
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["remainingSeconds"], 20)
        self.assertEqual(first["attempt"], "first")

    def test_checkpoint_requires_charged_parent_and_own_live_hold(self):
        producer = reserve_budget(self.root, self.ledger, self.request("producer", 20), "producer")
        self.settle(producer, 20, 6)
        sha = digest(self.root / "evidence/producer-result.json")
        request = self.request("consumer", 30)
        consumer = reserve_budget(self.root, self.ledger, request, "consumer")
        result = checkpoint_allowance(self.root, self.ledger, producer, sha, consumer, request)
        self.assertEqual(result["remainingSeconds"], 30)
        self.assertEqual(result["producerChargedSeconds"], 6)
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["spentSeconds"], 16)
        with self.assertRaises(ValueError):
            checkpoint_allowance(self.root, self.ledger, producer, "0" * 64, consumer, request)
        with self.assertRaisesRegex(ValueError, "share the original"):
            checkpoint_allowance(self.root, {**self.ledger, "sha256": "0" * 64}, producer,
                                 sha, consumer, request)
        self.settle(consumer, 30, 1)
        with self.assertRaises(ValueError):
            checkpoint_allowance(self.root, self.ledger, producer, sha, consumer, request)

    def test_unsettled_producer_cannot_supply_free_checkpoint(self):
        producer = reserve_budget(self.root, self.ledger, self.request("producer", 10), "producer")
        request = self.request("consumer", 20)
        consumer = reserve_budget(self.root, self.ledger, request, "consumer")
        with self.assertRaisesRegex(ValueError, "expenditure"):
            checkpoint_allowance(self.root, self.ledger, producer, "0" * 64, consumer, request)

    def test_unrelated_settlement_does_not_invalidate_own_allowance(self):
        producer = reserve_budget(self.root, self.ledger, self.request("producer", 10), "producer")
        self.settle(producer, 10, 2)
        sha = digest(self.root / "evidence/producer-result.json")
        request = self.request("consumer", 20)
        consumer = reserve_budget(self.root, self.ledger, request, "consumer")
        before = checkpoint_allowance(self.root, self.ledger, producer, sha, consumer, request)
        other = reserve_budget(self.root, self.ledger, self.request("other", 10), "other")
        self.settle(other, 10, 3)
        self.assertEqual(before, checkpoint_allowance(self.root, self.ledger, producer, sha, consumer, request))

    def test_actual_host_adaptive_contention_grants_only_one_large_hold(self):
        workers = available_processors()
        requests = [("parallel-" + str(index), self.request("parallel-" + str(index), 30))
                    for index in range(max(2, workers))]

        def attempt(item):
            name, request = item
            try:
                return reserve_budget(self.root, self.ledger, request, name)
            except ValueError:
                return None

        with ThreadPoolExecutor(max_workers=workers) as pool:
            results = list(pool.map(attempt, requests))
        self.assertEqual(sum(result is not None for result in results), 1)
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["heldSeconds"], 30)

    def test_observed_overrun_is_charged_and_stops_new_reservations(self):
        first = reserve_budget(self.root, self.ledger, self.request("first", 20), "first")
        self.settle(first, 20, 21)
        state = inspect_budget_ledger(self.root, self.ledger)
        self.assertEqual(state["spentSeconds"], 31)
        self.assertTrue(state["budgetBreached"])
        with self.assertRaisesRegex(ValueError, "overrun"):
            reserve_budget(self.root, self.ledger, self.request("second", 1), "second")

    def test_failure_charged_before_hold_is_released(self):
        request = self.request("first", 30)
        first = reserve_budget(self.root, self.ledger, request, "first")
        check_reservation(self.root, first, request)
        self.settle(first, 30, 12)
        state = inspect_budget_ledger(self.root, self.ledger)
        self.assertEqual((state["spentSeconds"], state["heldSeconds"], state["remainingSeconds"]), (22, 0, 38))
        with self.assertRaisesRegex(ValueError, "settled"):
            check_reservation(self.root, first, request)

    def test_interrupted_reservation_stays_held_on_new_read(self):
        reserve_budget(self.root, self.ledger, self.request("first", 50), "first")
        # Reading a fresh ledger handle models process restart; no liveness guess.
        reference = dict(self.ledger)
        self.assertEqual(inspect_budget_ledger(self.root, reference)["pending"], 1)
        with self.assertRaisesRegex(ValueError, "shared budget insufficient"):
            reserve_budget(self.root, reference, self.request("second", 1), "second")

    def test_duplicate_attempt_and_settlement_are_denied(self):
        request = self.request("first", 20)
        first = reserve_budget(self.root, self.ledger, request, "first")
        with self.assertRaisesRegex(ValueError, "already reserved"):
            reserve_budget(self.root, self.ledger, request, "first")
        self.settle(first, 20, 5)
        with self.assertRaisesRegex(ValueError, "reservation missing"):
            self.settle(first, 20, 5)
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["spentSeconds"], 15)

    def test_nonquiescent_and_wrong_cap_cannot_release_hold(self):
        first = reserve_budget(self.root, self.ledger, self.request("first", 20), "first")
        with self.assertRaisesRegex(ValueError, "quiescent"):
            self.settle(first, 20, 5, processGroupQuiescent=False)
        with self.assertRaisesRegex(ValueError, "cap changed"):
            self.settle(first, 21, 5)
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["heldSeconds"], 20)

    def test_multiple_holds_and_independent_settlement(self):
        first = reserve_budget(self.root, self.ledger, self.request("first", 30), "first")
        second = reserve_budget(self.root, self.ledger, self.request("second", 20), "second")
        self.settle(second, 20, 7, outcome="PASS")
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["heldSeconds"], 30)
        self.settle(first, 30, 10)
        self.assertEqual(inspect_budget_ledger(self.root, self.ledger)["spentSeconds"], 27)

    def test_original_genesis_cannot_be_reset(self):
        with self.assertRaises(FileExistsError):
            initialize_budget_ledger(self.root, 60, self.receipts)

    def test_mutated_event_is_rejected(self):
        first = reserve_budget(self.root, self.ledger, self.request("first", 20), "first")
        path = (self.root / self.ledger["path"]).parent / (first["token"] + ".json")
        path.write_text("{}")
        with self.assertRaisesRegex(ValueError, "bytes changed"):
            inspect_budget_ledger(self.root, self.ledger)
