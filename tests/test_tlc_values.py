import unittest

from gambit_smp.tlc_values import value, shape, merge_shapes
from gambit_smp.quint_backend import counterexample


class ValueTests(unittest.TestCase):
    def test_integer_sets_are_typed_canonical_and_cardinality_independent(self):
        self.assertEqual({"$integerSet": [-1, 0, 2]}, value("{2, -1, 0}"))
        self.assertEqual({"$integerSet": []}, value("{}"))
        self.assertEqual(merge_shapes(shape(value("[members |-> {}]")),
                                      shape(value("[members |-> {0, 1}]"))),
                         shape(value("[members |-> {0, 1}]")))
        self.assertNotEqual(shape(value("{}")), shape(value("<<>>")))

    def test_records_and_tuples(self):
        self.assertEqual({"active": [True, False], "child": {"n": -2}},
                         value("[ active |-> <<TRUE, FALSE>>, child |-> [n |-> -2] ]"))

    def test_string_states_use_strict_scalar_parsing(self):
        self.assertEqual({"policy": "join-only", "edge": ["published", "done"]},
                         value('[policy |-> "join-only", edge |-> <<"published", "done">>]'))
        self.assertEqual('quote" and slash\\', value(r'"quote\" and slash\\"'))
        self.assertEqual(shape(value('"published"')), shape(value('"done"')))
        self.assertNotEqual(shape(value('"1"')), shape(value('1')))

    def test_integer_intervals_are_compact_sets(self):
        self.assertEqual({"$integerRange": [3, 3]}, value("3..3"))
        self.assertEqual({"$integerRange": [-2, 1000000000000]}, value("-2..1000000000000"))
        self.assertEqual(shape(value("3..3")), shape(value("{3}")))
        self.assertNotEqual(shape(value("3..3")), shape(value("<<3, 3>>")))

    def test_string_sets_are_canonical_with_decoded_duplicate_detection(self):
        self.assertEqual({"$stringSet": ["a", "b"]}, value('{"b", "a"}'))
        for text in ('{"a", "a"}', r'{"a", "\u0061"}', '{"a", 1}', '{1, "a"}'):
            with self.subTest(text=text), self.assertRaises(ValueError):
                value(text)

    def test_empty_sets_do_not_erase_trace_element_types(self):
        def trace(sets):
            return "\n".join(f"State {n}: <step>\ns = [resources |-> {members}]\n"
                             for n, members in enumerate(sets, 1)) + "\n"
        for sets in (('{}', '{"mutex"}', '{}', '{"queue"}'), ('{}', '{1}', '{}', '2..3')):
            self.assertEqual(len(sets), len(counterexample(trace(sets))["states"]))
        for sets in (('{}', '{1}', '{}', '{"mutex"}'), ('{"mutex"}', '{}', '{1}'),
                     ('{}', '<<>>'), ('{1}', 'TRUE')):
            with self.subTest(sets=sets), self.assertRaises(ValueError):
                counterexample(trace(sets))

    def test_unsupported_duplicate_truncated_or_trailing_data_rejected(self):
        for text in ('"unterminated', r'"invalid\x20"', '"raw\nnewline"',
                     '"done" garbage', '3.."4"', '3..', '3..4..5', '{1..3}',
                     "{TRUE}", "{1, TRUE}", "{1, 1}", "{1,}",
                     "{1", "{{1}}", "{1;2}", "[x |-> 1, x |-> 2]",
                     "[x |-> ]", "<<1", "FALSE TRUE", "[x |-> 1] garbage",
                     "<<1; 2>>", "[x |-> unknown]", ""):
            with self.subTest(text=text), self.assertRaises(ValueError):
                value(text)


if __name__ == "__main__":
    unittest.main()
