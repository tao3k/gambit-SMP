"""Diagnostic measurements, not a native runtime acceptance campaign."""
import copy
import json
import os
from pathlib import Path
import unittest

from gambit_smp.ascent_program import assemble, evaluate, engine_api
from ascent_engine import EngineError
from ascent_engine.derivations import EvidenceChain
from ascent_engine.evidence import ComputationalEvidence


RULES = """(ascent-fragment
  (relation edge ((x symbol?) (y symbol?)))
  (relation blocked ((x symbol?)))
  (relation unrelated ((x symbol?)))
  (relation path ((x symbol?) (y symbol?)))
  (relation usable ((x symbol?) (y symbol?)))
  ((path X Y) <-- (edge X Y))
  ((path X Y) <-- (edge X Z) (path Z Y))
  ((usable X Y) <-- (path X Y) (not (blocked Y))))"""
FACTS = {"edge": [["a", "b"], ["b", "c"]], "blocked": [], "unrelated": []}


class UtilizationAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, cls.identities = cls.context.__enter__()
        cls.calls, cls.observations = [], {}
        cls.original_request = cls.engine.request

        def record(request):
            result = cls.original_request(request)
            cls.calls.append({"operation": request["operation"],
                              "handle": request.get("handle", result.get("handle") if isinstance(result, dict) else None),
                              "timeoutNanoseconds": request.get("timeoutNanoseconds")})
            return result

        cls.engine.request = record
        cls.describe = cls.engine.request({"operation": "describe"})
        cls.catalog = cls.engine.read_rules(RULES)

    @classmethod
    def tearDownClass(cls):
        cls.engine.request = cls.original_request
        cls.context.__exit__(None, None, None)
        if os.environ.get("ASCENT_AUDIT_OBSERVATIONS"):
            Path(os.environ["ASCENT_AUDIT_OBSERVATIONS"]).write_text(json.dumps({
                "describe": cls.describe, "identities": cls.identities,
                "observations": cls.observations, "successfulNativeCalls": cls.calls,
                "runtimeAdmitted": False, "executionAuthorized": False}, indent=2) + "\n")

    def program(self, facts=None):
        value = assemble(facts or FACTS, self.catalog, {"path": "path", "usable": "usable"})
        # Keep a deliberately unused source to measure conservative invalidation.
        value["relations"].append({"name": "unrelated", "source": True,
                                    "columns": [{"kind": "symbol"}],
                                    "rows": copy.deepcopy((facts or FACTS)["unrelated"])})
        return value

    def test_adapter_retains_native_sessions_between_calls(self):
        from gambit_smp.ascent_program import close_queries
        close_queries(self.engine)
        counts, results, metrics = [], [], []
        for _ in range(2):
            start = len(self.calls)
            result, metric = evaluate(self.engine, FACTS, self.catalog, {"answer": "usable"})
            results.append(result)
            metrics.append(metric)
            counts.append(sum(row["operation"] == "open" for row in self.calls[start:]))
        self.assertEqual(results[0], results[1])
        self.assertGreater(counts[0], 0)
        self.assertEqual(counts[1], 0)
        self.assertTrue(all(metric["retainedOwner"] for metric in metrics))
        self.assertEqual(metrics[0]["sourceGeneration"], metrics[1]["sourceGeneration"])
        self.assertEqual(metrics[1]["investigationRound"], metrics[0]["investigationRound"] + 1)
        self.assertGreater(metrics[1]["reusedComponents"], 0)
        self.assertGreater(metrics[1]["repeatReusedComponents"], 0)
        self.observations["adapterCalls"] = {"opensPerCall": counts, "metrics": metrics,
                                            "crossCallReuseEstablished": True}

    def test_retained_chain_reuses_shared_component_across_distinct_queries(self):
        program = self.program()
        with EvidenceChain(self.engine, [r for r in program["relations"] if r["source"]]) as chain:
            first = chain.query({**program, "queries": ["path"]})
            second = chain.query({**program, "queries": ["usable"]})
            self.assertEqual([["a", "b"], ["a", "c"], ["b", "c"]],
                             sorted(second["result"]["relations"]["usable"]))
            self.assertGreater(len(second["reusedComponents"]), 0)
            self.observations["distinctQueries"] = {
                "firstFresh": len(first["freshComponents"]),
                "secondFresh": len(second["freshComponents"]),
                "secondReused": len(second["reusedComponents"])}

    def test_source_withdrawal_invalidates_references_and_retracts_answers(self):
        program = self.program()
        with EvidenceChain(self.engine, [r for r in program["relations"] if r["source"]]) as chain:
            before = chain.query(program)
            after_program = self.program({**FACTS, "edge": [["a", "b"]]})
            chain.replace([r for r in after_program["relations"] if r["source"]])
            with self.assertRaises(ValueError):
                chain.answer(before["resultReference"], "usable")
            after = chain.query(after_program)
            self.assertEqual([["a", "b"]], after["result"]["relations"]["usable"])
            self.assertEqual([], after["reusedComponents"])
            self.observations["withdrawal"] = {
                "before": before["result"]["relations"], "after": after["result"]["relations"],
                "oldReferenceRejected": True, "reused": len(after["reusedComponents"])}

    def test_unrelated_source_update_invalidates_all_component_certificates(self):
        program = self.program()
        with EvidenceChain(self.engine, [r for r in program["relations"] if r["source"]]) as chain:
            before = chain.query(program)
            changed_program = self.program({**FACTS, "unrelated": [["new"]]})
            chain.replace([r for r in changed_program["relations"] if r["source"]])
            after = chain.query(changed_program)
            self.assertEqual(before["result"], after["result"])
            self.assertEqual([], after["reusedComponents"])
            self.assertEqual(len(before["freshComponents"]), len(after["freshComponents"]))
            self.observations["unrelatedUpdate"] = {
                "answersUnchanged": True, "allComponentsFreshAgain": True,
                "fresh": len(after["freshComponents"]), "minimalInvalidationEstablished": False}

    def test_invalid_replacement_preserves_previous_completed_source(self):
        program = self.program()
        with EvidenceChain(self.engine, [r for r in program["relations"] if r["source"]]) as chain:
            before = chain.query(program)
            invalid = copy.deepcopy(chain.sources)
            next(r for r in invalid if r["name"] == "edge")["rows"] = [[True, "b"]]
            with self.assertRaises(EngineError) as failure:
                chain.replace(invalid)
            after = chain.query(program)
            self.assertEqual(before["sourceIdentity"], after["sourceIdentity"])
            self.assertEqual(before["result"], after["result"])
            self.observations["invalidReplacement"] = {
                "error": str(failure.exception), "previousSourceAndAnswersPreserved": True}

    def test_native_zero_budget_is_not_a_fresh_complete_result(self):
        program = self.program()
        with self.engine.open(program) as session:
            fresh = session.run(0)
            completed = session.run()
            retained = session.run(0)
            self.assertFalse(fresh["complete"])
            self.assertTrue(completed["complete"])
            self.assertTrue(retained["complete"])
            self.assertEqual(completed["relations"], retained["relations"])
            self.observations["zeroBudget"] = {"freshComplete": fresh["complete"],
                "completedComplete": completed["complete"], "retainedComplete": retained["complete"]}

    def test_loaded_native_support_store_has_bound_positive_ancestors(self):
        candidate = ["candidate", ["relation", "path", 2],
                     ["rule", ["path", "?x", "?y"], ["edge", "?x", "?y"]],
                     ["rule", ["path", "?x", "?z"], ["path", "?x", "?y"], ["edge", "?y", "?z"]],
                     ["query", "path", "?x", "?y"], ["limits", 32, 64, 64]]
        source = {"identity": "utilization-audit", "generation": 0,
                  "relations": [["edge", 2, [[0, 1], [1, 2]]]]}
        with ComputationalEvidence(self.engine) as store:
            resolved = store.resolve(source, candidate)
            self.assertEqual("verified", resolved["status"])
            observation = store.observe(source, candidate, resolved["handle"], [["path", 0, 2]], support=True)
            nodes = observation["supportNodes"]
            self.assertTrue(nodes)
            self.assertTrue(any(n["ruleLabel"] and n["parents"] for n in nodes))
            changed = copy.deepcopy(source)
            changed["relations"][0][2] = [[0, 1]]
            stale = store.fact(changed, candidate, resolved["handle"], ["path", 0, 2])
            self.assertEqual("unknown", stale["status"])
            self.observations["positiveSupport"] = {"resolved": resolved,
                "observation": observation, "changedSourceOldHandle": stale, "stats": store.stats(),
                "scope": "Positive atom-only synthetic graph; not generic negation or retry-policy proof"}

    def test_inert_reader_rejects_unexposed_aggregate_syntax(self):
        source = """(ascent-fragment
          (relation item ((x integer?)))
          (relation total ((n integer?)))
          ((total N) <-- (aggregate (N) count (item X))))"""
        with self.assertRaises(EngineError) as failure:
            self.engine.read_rules(source)
        self.observations["readerAggregate"] = {"rejected": True, "error": str(failure.exception),
            "nativeWireReducers": self.describe.get("clauseOperators", {}).get("reduce", [])}


if __name__ == "__main__":
    unittest.main()
