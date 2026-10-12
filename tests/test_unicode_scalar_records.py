import unittest

from gambit_smp.unicode_scalar_records import RECORD, validate_shard, validate


def record(code, flags=0, digit=255, mapping=None):
    value = code if mapping is None else mapping
    return RECORD.pack(code, flags, digit, value, value, value, value)


class UnicodeScalarRecordTests(unittest.TestCase):
    def test_exact_records_and_surrogate_gap(self):
        self.assertEqual(validate_shard(record(0) + record(1), 0, 2), 2)
        self.assertEqual(validate_shard(record(0xD7FF) + record(0xE000), 0xD7FF, 0xE001), 2)
        self.assertEqual(validate_shard(b"", 0xD900, 0xDF00), 0)

    def test_truncation_omission_duplicate_and_reordering_are_rejected(self):
        for data in (record(0)[:-1], b"", record(1), record(0) + record(0), record(1) + record(0)):
            with self.assertRaises(ValueError):
                validate_shard(data, 0, 2)

    def test_untyped_fields_and_nonscalar_mappings_are_rejected(self):
        for data in (record(0, flags=32), record(0, digit=10), record(0, mapping=0xD800),
                     record(0, mapping=0x110000)):
            with self.assertRaises(ValueError):
                validate_shard(data, 0, 1)

    def test_missing_shards_and_invalid_population_are_rejected(self):
        for count in (0, -1, True):
            with self.assertRaises(ValueError):
                validate({}, count)
        with self.assertRaises(ValueError):
            validate({"0.bin": b""}, 2)


if __name__ == "__main__":
    unittest.main()
