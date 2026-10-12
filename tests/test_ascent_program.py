import unittest

from gambit_smp.ascent_program import evaluate, load_catalog, engine_api


class NativeAuditTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.context = engine_api()
        cls.engine, cls.identities = cls.context.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.context.__exit__(None, None, None)

    def test_recursive_negation_and_retained_component_reuse(self):
        catalog = self.engine.read_rules("""(ascent-fragment
          (relation edge ((from symbol?) (to symbol?)))
          (relation bad ((value symbol?)))
          (relation path ((from symbol?) (to symbol?)))
          (relation usable ((from symbol?) (to symbol?)))
          ((path X Y) <-- (edge X Y))
          ((path X Y) <-- (edge X Z) (path Z Y))
          ((usable X Y) <-- (path X Y) (not (bad Y))))""")
        answers, metrics = evaluate(self.engine,
            {"edge": [["a", "b"], ["b", "c"]], "bad": [["c"]]}, catalog,
            {"all": "path", "safe": "usable"})
        self.assertEqual(answers["all"], [("a", "b"), ("a", "c"), ("b", "c")])
        self.assertEqual(answers["safe"], [("a", "b")])
        self.assertEqual(metrics["freshComponents"], metrics["repeatReusedComponents"])

    def test_actual_full_audit_default_and_managed_engine_agree(self):
        from gambit_smp import research_audit as audit
        from gambit_smp.protocol_evidence import facts as protocol_facts
        from gambit_smp.protocol_source_audit import facts as source_facts
        base = audit.index.export()
        facts, inputs = audit.load_audit(audit.ROOT, base)
        inputs.update(base["inputs"])
        audit.reusable_receipts(audit.ROOT, base, facts, inputs)
        for collect in (protocol_facts, source_facts):
            extra, bound = collect(audit.ROOT)
            facts.update(extra)
            inputs.update(bound)
        expected = audit.query(base, facts, audit.ROOT)
        metrics = {}
        actual = audit.query(base, facts, audit.ROOT, engine=self.engine, metrics=metrics)
        self.assertEqual(expected, actual)
        self.assertTrue(metrics["retainedOwner"])
        audit.query(base, facts, audit.ROOT, engine=self.engine, metrics=metrics)
        self.assertTrue(metrics["nativeResultReused"])
        self.assertTrue(all(audit.digest(audit.local(audit.ROOT, name)) == sha for name, sha in inputs.items()))

    def test_retry_denials_and_review_only_match_for_all_boolean_inputs(self):
        from itertools import product
        from gambit_smp import research_audit as audit
        facts = {name: [] for name in audit.ARITIES}
        flags = ("retry_delta", "retry_budget_expanded", "retry_scope_mismatch",
                 "retry_hypothesis", "retry_unbound")
        expected_denials, expected_review = [], []
        for index, values in enumerate(product((False, True), repeat=len(flags))):
            route = str(index)
            facts["retry_route"].append([route])
            for flag, enabled in zip(flags, values):
                if enabled:
                    facts[flag].append([route])
            delta, budget, scope, hypothesis, unbound = values
            reasons = [reason for condition, reason in (
                (not delta, "unchanged-tested-inputs"), (budget, "budget-expanded"),
                (scope, "failure-scope-mismatch"), (not hypothesis, "missing-causal-hypothesis"),
                (unbound, "unreviewed-artifact-identity")) if condition]
            expected_denials.extend((route, reason) for reason in reasons)
            if not reasons:
                expected_review.append((route,))
        result, _ = evaluate(self.engine, facts,
            load_catalog(audit.ROOT / "evidence/research-rules.ss"),
            {"deny": "retry_denied", "review": "retry_review_required"})
        self.assertEqual(sorted(expected_denials), result["deny"])
        self.assertEqual(expected_review, result["review"])


if __name__ == "__main__":
    unittest.main()
