import unittest
import json

from gambit_smp import quint_capabilities, recipes


class QuintCapabilityTests(unittest.TestCase):
    def test_bounded_counterexample_is_not_an_exit_only_negative_control(self):
        from gambit_smp.quint_backend import interpret_simulation
        record = lambda flag: dict(kind='app', opcode='Rec', args=[
            dict(kind='str', value='alive'), dict(kind='bool', value=flag)])
        result = dict(stage='running', status='violation', errors=[],
                      trace=[record(True), record(False)])
        accepted, trace = interpret_simulation(1, json.dumps(result), False, negative=True)
        self.assertTrue(accepted)
        self.assertEqual(trace['states'], [{'alive': True}, {'alive': False}])
        for changed, code, timed in [({**result, 'stage': 'parsing'}, 1, False),
                ({**result, 'errors': ['parse error']}, 1, False),
                ({**result, 'trace': []}, 1, False), (result, -9, False),
                (result, 1, True), ({**result, 'status': 'ok'}, 1, False)]:
            self.assertEqual(interpret_simulation(code, json.dumps(changed), timed, negative=True),
                             (False, None))
        result['trace'][1]['args'][1]['value'] = 'false'
        self.assertEqual(interpret_simulation(1, json.dumps(result), False, negative=True), (False, None))

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
