"""Exact historical fixture assertions; not a current evidence admission API."""
import json
from pathlib import Path

from gambit_smp.framework import ROOT, digest


def historical_observation(test, fixture, root=ROOT):
    root = root.resolve()

    def local(name):
        path = Path(name)
        test.assertFalse(path.is_absolute(), name)
        test.assertNotIn("..", path.parts, name)
        test.assertNotIn(".data", path.parts, name)
        resolved = (root / path).resolve()
        test.assertTrue(resolved.is_relative_to(root), name)
        return resolved

    index = json.loads(local("evidence/source-results/fixture-history/inputs.json").read_text())
    test.assertEqual("gambit-historical-fixture-inputs.v1", index["schema"])
    test.assertIs(False, index["runtimeAdmitted"])
    row = index["fixtures"][fixture]
    path = local(f"evidence/source-results/fixtures/{fixture}/observation.json")
    test.assertEqual(row["observationSha256"], digest(path), "original observation changed")
    summary = json.loads(path.read_text())
    test.assertIs(False, summary["runtimeAdmitted"])
    test.assertTrue(set(row["archives"]).issubset(summary["inputs"]))
    for name, expected in summary["inputs"].items():
        # Only the fixed, individually recovered historical inputs are remapped.
        archived = row["archives"].get(name, name)
        source = local(archived)
        history = Path("evidence/source-results/fixture-history")
        if not source.is_file() and Path(archived).is_relative_to(history):
            source = local(str(Path("tests/fixtures/fixture-history") /
                               Path(archived).relative_to(history)))
        test.assertEqual(expected, digest(source), name)
    return summary
