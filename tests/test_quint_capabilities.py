import unittest

from gambit_smp import quint_capabilities, recipes


class QuintCapabilityTests(unittest.TestCase):
    def setUp(self):
        self.args = {"source": "model.qnt", "parsed": "parse", "initializer": "initFixed",
                     "step": "step", "invariant": "checked", "negative": False}

    def test_declared_capability_is_closed_and_typed(self):
        quint_capabilities.validate(self.args, ["model.qnt"])
        self.assertEqual((("verification", "quint-verification"),), recipes.CAPABILITIES["quint.verify"].outputs)
        for mutation in ({"negative": 1}, {"initializer": "--help"}, {"handler": "custom"},
                         {"source": "cache.qnt"}, {"negative": True, "temporal": "progress"}):
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                quint_capabilities.validate({**self.args, **mutation}, ["model.qnt"])

    def test_matching_parse_dependency_is_required(self):
        step = {"arguments": self.args, "dependsOn": ["parse"]}
        parent = {"capability": "quint.parse", "arguments": {"source": "model.qnt"}}
        quint_capabilities.graph(step, {"parse": parent}, recipes.CAPABILITIES)
        for parents in ({}, {"parse": {**parent, "capability": "quint.test"}},
                        {"parse": {**parent, "arguments": {"source": "other.qnt"}}}):
            with self.subTest(parents=parents), self.assertRaises(ValueError):
                quint_capabilities.graph(step, parents, recipes.CAPABILITIES)
