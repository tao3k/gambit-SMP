"""Timing transport tests, not native performance evidence."""
import json
import tempfile
import unittest
from pathlib import Path

from gambit_smp.latency_observation import summarize, validate_options


class LatencyObservationTests(unittest.TestCase):
    def setUp(self):
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        self.directory = Path(tmp.name)
        self.options = {"path": "samples.jsonl", "minimumSamples": 100,
                        "percentiles": [55, 99]}
        self.header = {"schema": "native-latency-samples.v1", "cpuCapacity": 8,
                       "groups": [{"population": 2, "owners": 2, "rounds": 50}]}
        self.rows = [{"population": 2, "owner": i // 50 + 1, "round": i % 50,
                      "nanoseconds": i + 1} for i in range(100)]

    def write(self):
        (self.directory / "samples.jsonl").write_text(
            "\n".join(json.dumps(row) for row in [self.header, *self.rows]) + "\n")

    def test_nearest_rank_and_exact_denominator_without_admission(self):
        self.write()
        result = summarize(self.directory, self.options, 8, 1)
        group = result["groups"][0]
        self.assertEqual(100, group["samples"])
        self.assertEqual({"55": 55, "99": 99}, group["percentilesNanoseconds"])
        self.assertFalse(result["runtimeAdmitted"])
        self.assertFalse(result["performanceAdmitted"])
        self.assertEqual(64, len(result["rawSha256"]))

    def test_entire_omitted_population_cannot_hide_in_the_header(self):
        self.options["populationPlan"] = {"reservedPositions": 2,
            "minimumPopulation": 2, "minimumProcessorsPerOwner": 2}
        self.write()
        with self.assertRaisesRegex(ValueError, "complete population plan"):
            summarize(self.directory, self.options, 8, 1)
        self.header["groups"].append({"population": 3, "owners": 3, "rounds": 34})
        self.rows += [{"population": 3, "owner": owner, "round": round,
                       "nanoseconds": 10} for owner in range(1, 4) for round in range(34)]
        self.write()
        result = summarize(self.directory, self.options, 8, 1)
        self.assertEqual([2, 3], [g["population"] for g in result["groups"]])
        self.header["groups"][1]["owners"] = 2
        self.header["groups"][1]["rounds"] = 50
        self.write()
        with self.assertRaisesRegex(ValueError, "complete population plan"):
            summarize(self.directory, self.options, 8, 1)

    def test_population_plan_dimensions_are_not_fixed_host_counts(self):
        plan = {"reservedPositions": 2, "minimumPopulation": 2, "minimumProcessorsPerOwner": 2}
        for key in plan:
            for invalid in (0, -1, True, "2"):
                with self.subTest(key=key, value=invalid), self.assertRaises(ValueError):
                    validate_options({**self.options, "populationPlan": {**plan, key: invalid}})

    def test_incomplete_duplicate_and_invalid_samples_rejected(self):
        original = [dict(row) for row in self.rows]
        for kind in ("missing", "duplicate", "negative", "zero", "duration", "fraction", "owner", "population"):
            with self.subTest(kind=kind):
                self.rows = [dict(row) for row in original]
                if kind == "missing":
                    self.rows.pop()
                elif kind == "duplicate":
                    self.rows[-1] = dict(self.rows[0])
                elif kind == "owner":
                    self.rows[0]["owner"] = 3
                elif kind == "population":
                    self.rows[0]["population"] = 7
                else:
                    self.rows[0]["nanoseconds"] = {"negative": -1, "zero": 0,
                        "duration": 1000000001, "fraction": 1.5}[kind]
                self.write()
                with self.assertRaises(ValueError):
                    summarize(self.directory, self.options, 8, 1)

    def test_host_sample_floor_and_path_boundary(self):
        self.write()
        with self.assertRaises(ValueError):
            summarize(self.directory, self.options, 12, 1)
        for path in ("../samples.jsonl", "/tmp/samples.jsonl", "samples.json"):
            with self.assertRaises(ValueError):
                validate_options({**self.options, "path": path})
        for floor in (True, 99, 0):
            with self.assertRaises(ValueError):
                validate_options({**self.options, "minimumSamples": floor})
        with self.assertRaises(ValueError):
            summarize(self.directory, {**self.options, "minimumSamples": 1000}, 8, 1)

    def test_symlink_and_duplicate_populations_rejected(self):
        self.write()
        target = self.directory / "target.jsonl"
        (self.directory / "samples.jsonl").rename(target)
        (self.directory / "samples.jsonl").symlink_to(target)
        with self.assertRaises(ValueError):
            summarize(self.directory, self.options, 8, 1)
        (self.directory / "samples.jsonl").unlink()
        self.header["groups"].append(dict(self.header["groups"][0]))
        self.write()
        with self.assertRaises(ValueError):
            summarize(self.directory, self.options, 8, 1)
