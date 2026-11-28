import unittest

from gambit_smp.research_kernel import validate_graph


class SysmlQuintGraphTests(unittest.TestCase):
    def test_source_model_graph_accepts_exact_quint_and_rejects_native_execution(self):
        steps = [{'capability': 'sysml.project'}, {'capability': 'quint.parse'},
                 {'capability': 'quint.test'}, {'capability': 'evidence.evaluate', 'arguments': {}}]
        validate_graph({'inputs': []}, steps)
        with self.assertRaisesRegex(ValueError, 'locked source producer'):
            validate_graph({'inputs': []}, steps[:-1] +
                           [{'capability': 'native.test'}, steps[-1]])


if __name__ == '__main__':
    unittest.main()
