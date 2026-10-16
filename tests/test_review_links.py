"""The real consumer DSL checks exact correspondence, not reusable labels."""
import copy
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.ascent_program import engine_api, evaluate, load_component_catalog
from gambit_smp.framework import ROOT, digest
from gambit_smp.review_links import load, ROOT_CLAIMS


class FailureClaimReceiptTests(unittest.TestCase):
    def test_transport_binds_exact_json_pointers_and_all_root_reviews(self):
        with TemporaryDirectory() as directory:
            root = Path(directory)

            def save(name, value):
                path = root / name
                path.write_text(json.dumps(value))
                return {"path": name, "sha256": digest(path), "pointer": ""}

            original = save("failed.json", {"accepted": False})
            reviews = {name: save(name + ".json", {
                "domain": "causal-review", "status": "reviewed", "claim": name,
                "candidateIdentity": "current", "failureReceipt": original,
                "premises": []}) for name in ROOT_CLAIMS}
            record = {"schema": "failure-causal-review.v1", "domain": "causal-review",
                      "status": "reviewed", "claim": "reviewed-causal-link:f",
                      "candidateIdentity": "current", "failure": "f",
                      "failureReceipt": original, "reviews": reviews}
            evidence = save("review.json", {"claims": [record]})
            evidence["pointer"] = "/claims/0"
            document = {"schema": "failure-claim-receipt-links.v1",
                        "failureInventorySha256": "inventory", "links": [{
                            "candidate": "c", "candidateIdentity": "current", "failure": "f",
                            "failureReceipt": original, "evidence": evidence}]}
            save("links.json", document)
            args = (root, "links.json", [["c", "scope", "current"]],
                    [{"id": "f", "receipt": "failed.json"}], "inventory")
            links, dependencies, specs, inputs = load(*args)
            self.assertEqual(1, len(links))
            self.assertEqual(3, len(dependencies))
            self.assertEqual(4, len(specs))
            self.assertEqual(6, len(inputs))
            for field, bad in (("candidateIdentity", "stale"), ("failure", "other"),
                               ("candidate", "other")):
                changed = copy.deepcopy(document)
                changed["links"][0][field] = bad
                save("links.json", changed)
                with self.assertRaises(ValueError):
                    load(*args)
            save("links.json", document)
            (root / "review.json").write_text("{}")
            with self.assertRaisesRegex(ValueError, "reference changed"):
                load(*args)

    def test_exact_link_and_negative_controls_with_source_withdrawal(self):
        facts = {
            "Cause": [], "ReceiptDepends": [], "ClaimDepends": [],
            "Candidate": [["candidate", "scope", "current"]],
            "Failure": [["failure", "scope", "previous", "failed.json"]],
            "Requires": [["candidate", "reviewed-causal-link:failure"]],
            "Passed": [["review", "reviewed-causal-link:failure"]],
            "ReceiptInput": [["review", "review.json", "review-sha"]],
            "CurrentInput": [["review.json", "review-sha"]],
            "FailureBinding": [["failure", "failed.json", "failure-sha"]],
            "FailureClaim": [["candidate", "failure", "current", "failed.json",
                              "failure-sha", "reviewed-causal-link:failure"]],
            "ReviewedLink": [["candidate", "failure", "current", "failed.json",
                              "failure-sha", "reviewed-causal-link:failure", "review"]],
        }
        catalog = load_component_catalog(ROOT / "evidence/dsl/components.json", entry="review",
                                         constructor="make-review", trusted=True)
        queries = {name: name for name in ("CausalEvidence", "Decision", "Unusable")}
        with engine_api() as (engine, _):
            good, first = evaluate(engine, facts, catalog, queries)
            self.assertEqual([("candidate", "failure", "review")], good["CausalEvidence"])
            self.assertEqual([("candidate", "REVIEW_REQUIRED")], good["Decision"])
            # Every correspondence dimension must match, even for an otherwise
            # reusable receipt. These labels are test data, not host approvals.
            for index in range(7):
                changed = copy.deepcopy(facts)
                changed["ReviewedLink"][0][index] = "unrelated"
                bad, _ = evaluate(engine, changed, catalog, queries)
                self.assertEqual([], bad["CausalEvidence"], index)
                self.assertEqual([("candidate", "DENY")], bad["Decision"], index)
            for extra in (
                {"ReviewedLink": [], "Cause": [["candidate", "failure", "review"]]},
                {"CurrentInput": []},
                {"ReceiptDepends": [["review", "missing"]]},
                {"ReceiptDepends": [["review", "review"]]},
                {"Passed": [["review", "finite-model:unrelated"]]},
            ):
                bad, _ = evaluate(engine, dict(facts, **extra), catalog, queries)
                self.assertEqual([], bad["CausalEvidence"])
                self.assertEqual([("candidate", "DENY")], bad["Decision"])
            restored, last = evaluate(engine, facts, catalog, queries)
            self.assertEqual(good, restored)
            self.assertEqual(first["sessionOwner"], last["sessionOwner"])
            self.assertGreater(last["sourceGeneration"], first["sourceGeneration"])
