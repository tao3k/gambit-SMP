"""Matched hashing benchmark, explicitly not a GC/runtime speed claim."""
import hashlib
import json
from pathlib import Path
import shutil
import statistics
import tempfile
import time
import unittest

from gambit_smp.framework import ROOT
from gambit_smp import recipes


class LeasedIdentityPerformance(unittest.TestCase):
    def test_same_bytes_same_identity_and_final_sha_three_pairs(self):
        from ascent.build import runtime_identity
        from gambit_smp.artifact_storage import cache_path
        store = cache_path(ROOT, "fixtures")
        store.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(prefix="leased-hash-pair-", dir=store) as directory:
            target = Path(directory).resolve() / "source"
            source = Path(runtime_identity()["sourceRoot"]).resolve(strict=True)
            shutil.copytree(source, target)
            expected = recipes._tree_identity_uncached(target)
            baseline, candidate = [], []
            for pair in range(3):
                for optimized in ((False, True) if pair % 2 == 0 else (True, False)):
                    context = recipes.ExecutionContext(ROOT, target, target, {},
                        time.monotonic() + 15, {}, {}, {})
                    start = time.monotonic()
                    context.lease_workspace(target, expected)
                    try:
                        for _ in range(5):
                            result = (recipes.tree_identity(target) if optimized else
                                      recipes._tree_identity_uncached(target))
                            self.assertEqual(result, expected)
                        if optimized:
                            context.leased_tree_checks.verify()
                            self.assertEqual(context.leased_tree_checks.full_reads, 1)
                            self.assertEqual(context.leased_tree_checks.reused, 5)
                            self.assertEqual(context.leased_tree_checks.final_reads, 1)
                        else:
                            self.assertEqual(recipes._tree_identity_uncached(target), expected)
                        (candidate if optimized else baseline).append(time.monotonic() - start)
                    finally:
                        context.workspace_leases.close()
            self.assertEqual(recipes._tree_identity_uncached(target), expected)
            print(json.dumps({"scope": "identity transport only; not GC or FFI performance",
                "inputIdentity": hashlib.sha256(json.dumps(expected, sort_keys=True).encode()).hexdigest(),
                "files": sum("sha256" in row for row in expected.values()),
                "sameInputAndAnswers": True, "pairs": 3, "lookupsPerPair": 5,
                "fullFinalShaBothModes": True, "baselineSeconds": baseline,
                "candidateSeconds": candidate,
                "baselineMedian": statistics.median(baseline),
                "candidateMedian": statistics.median(candidate)}))


if __name__ == "__main__":
    unittest.main()
