"""Unit tests for Families 8-12 offline cryptographic auditors and coverage gates."""

from __future__ import annotations

import copy
import unittest

from gambit_smp.families_8_12_audit import (
    ALL_TWELVE_FAMILIES,
    FAMILY_REQUIRED_TARGETS,
    GERBIL_STAGES,
    MAX_RSS_BYTES,
    audit_gc_ffi_family,
    audit_gerbil_family,
    audit_lifecycle_family,
    audit_registry_family,
    audit_release_family,
    verify_dynamic_o1_abi_closure,
    verify_family_formal_models,
    verify_p02_source_anchors,
    verify_v12_architectural_anchors,
)
from gambit_smp.framework import ROOT
from gambit_smp.suite_coverage import (
    require_gc_ffi_smp_evidence,
    require_gerbil_smp_evidence,
    require_lifecycle_smp_evidence,
    require_registry_smp_evidence,
    require_release_smp_evidence,
)

PROFILE = "884fa4a48e7550e2e9e1ddc62ec575927b37a5d81716d45d4a5684731d6b7f69"
PRODUCER_V11 = {
    "gsiSha256": "1" * 64,
    "gscSha256": "2" * 64,
    "libgambitSha256": "3" * 64,
    "gambitHeaderSha256": "4" * 64,
    "gambuildCSha256": "5" * 64,
}
PRODUCER_V10 = {
    "gsiSha256": "a" * 64,
    "gscSha256": "b" * 64,
    "libgambitSha256": "c" * 64,
    "gambitHeaderSha256": "d" * 64,
    "gambuildCSha256": "e" * 64,
}


def _target_rows(family: str) -> list[dict]:
    return [
        {
            "target": t,
            "passed": True,
            "exit": 0,
            "timeout": False,
            "seconds": 1.25,
            "peakRssBytes": 64 * 1024 * 1024,
            "parentReaped": True,
            "processGroupQuiescent": True,
        }
        for t in FAMILY_REQUIRED_TARGETS[family]
    ]


class Families8To12AuditTests(unittest.TestCase):
    def test_live_manifests_and_p02_anchors_pass(self):
        for fam in ("registry", "lifecycle", "gc-ffi", "gerbil", "release"):
            res = verify_family_formal_models(ROOT, fam)
            self.assertTrue(res["passed"], f"{fam} gaps: {res['gaps']}")
            self.assertGreaterEqual(res["verifiedModels"], 5)
        p02 = verify_p02_source_anchors(ROOT)
        self.assertTrue(p02["passed"], f"P0-2 gaps: {p02['gaps']}")
        abi = verify_dynamic_o1_abi_closure(ROOT)
        self.assertTrue(abi["passed"], f"Dynamic .o1 ABI gaps: {abi['gaps']}")
        self.assertGreaterEqual(abi["impFuncCount"], 300)
        self.assertEqual(abi["bareLeaks"], [])
        v12 = verify_v12_architectural_anchors(ROOT)
        self.assertTrue(v12["passed"], f"v12 architectural anchor gaps: {v12['gaps']}")

    def test_registry_audit_positive_and_negatives(self):
        formal = verify_family_formal_models(ROOT, "registry")
        receipt = {
            "schema": "family8-registry-receipt.v1",
            "family": "registry",
            "manifestSha256": formal["manifestSha256"],
            "profileSha256": PROFILE,
            "producer": dict(PRODUCER_V11),
            "producerIntact": True,
            "peakRssBytes": 128 * 1024 * 1024,
            "targets": _target_rows("registry"),
        }
        verdict = require_registry_smp_evidence(ROOT, receipt)
        self.assertTrue(verdict["passed"])

        # Missing target rejected
        missing = copy.deepcopy(receipt)
        missing["targets"].pop()
        self.assertFalse(audit_registry_family(ROOT, missing)["passed"])
        with self.assertRaises(ValueError):
            require_registry_smp_evidence(ROOT, missing)

        # >= 8 GiB RSS rejected
        over_rss = copy.deepcopy(receipt)
        over_rss["targets"][0]["peakRssBytes"] = MAX_RSS_BYTES
        self.assertFalse(audit_registry_family(ROOT, over_rss)["passed"])

        # Non-quiescent child rejected
        leaked = copy.deepcopy(receipt)
        leaked["targets"][0]["processGroupQuiescent"] = False
        self.assertFalse(audit_registry_family(ROOT, leaked)["passed"])

    def test_lifecycle_audit_positive_and_negatives(self):
        formal = verify_family_formal_models(ROOT, "lifecycle")
        receipt = {
            "schema": "family9-lifecycle-receipt.v1",
            "family": "lifecycle",
            "manifestSha256": formal["manifestSha256"],
            "profileSha256": PROFILE,
            "producer": dict(PRODUCER_V11),
            "producerIntact": True,
            "peakRssBytes": 128 * 1024 * 1024,
            "startupFaultModesVerified": 10,
            "targets": _target_rows("lifecycle"),
        }
        self.assertTrue(require_lifecycle_smp_evidence(ROOT, receipt)["passed"])

        # Incomplete fault modes rejected
        short_faults = copy.deepcopy(receipt)
        short_faults["startupFaultModesVerified"] = 9
        self.assertFalse(audit_lifecycle_family(ROOT, short_faults)["passed"])

    def test_gc_ffi_audit_positive_and_negatives(self):
        formal = verify_family_formal_models(ROOT, "gc-ffi")
        receipt = {
            "schema": "family10-gc-ffi-receipt.v1",
            "family": "gc-ffi",
            "manifestSha256": formal["manifestSha256"],
            "profileSha256": PROFILE,
            "producer": dict(PRODUCER_V11),
            "producerIntact": True,
            "peakRssBytes": 256 * 1024 * 1024,
            "targets": _target_rows("gc-ffi"),
        }
        self.assertTrue(require_gc_ffi_smp_evidence(ROOT, receipt)["passed"])

        # Drifted manifest SHA rejected
        bad_manifest = copy.deepcopy(receipt)
        bad_manifest["manifestSha256"] = "0" * 64
        self.assertFalse(audit_gc_ffi_family(ROOT, bad_manifest)["passed"])

    def test_gerbil_audit_rejects_mixed_abi_and_partial_stages(self):
        formal = verify_family_formal_models(ROOT, "gerbil")
        receipt = {
            "schema": "family11-gerbil-receipt.v1",
            "family": "gerbil",
            "manifestSha256": formal["manifestSha256"],
            "profileSha256": PROFILE,
            "producer": dict(PRODUCER_V11),
            "runtimeProfile": {"multipleThreadedVms": True, "multipleVms": True, "smp": True},
            "stages": [
                {
                    "stage": s,
                    "producer": dict(PRODUCER_V11),
                    "passed": True,
                    "exit": 0,
                    "timeout": False,
                    "peakRssBytes": 512 * 1024 * 1024,
                }
                for s in GERBIL_STAGES
            ],
        }
        self.assertTrue(require_gerbil_smp_evidence(ROOT, receipt)["passed"])

        # Mixed producer/ABI on one stage strictly rejected
        mixed = copy.deepcopy(receipt)
        mixed["stages"][4]["producer"] = dict(PRODUCER_V10)
        v_mixed = audit_gerbil_family(ROOT, mixed)
        self.assertFalse(v_mixed["passed"])
        self.assertTrue(v_mixed["mixedProducerDetected"])
        self.assertEqual(v_mixed["status"], "MIXED_ABI_REJECTED")

        # Partial stage build stays SCOPED_PARTIAL and never promotes Family 11
        partial = copy.deepcopy(receipt)
        partial["stages"] = partial["stages"][:3]
        v_partial = audit_gerbil_family(ROOT, partial)
        self.assertFalse(v_partial["passed"])
        self.assertEqual(v_partial["status"], "SCOPED_PARTIAL")
        with self.assertRaises(ValueError):
            require_gerbil_smp_evidence(ROOT, partial)

    def test_release_audit_refuses_cross_source_splicing_and_dropped_censors(self):
        formal = verify_family_formal_models(ROOT, "release")
        receipt = {
            "schema": "family12-release-receipt.v1",
            "family": "release",
            "manifestSha256": formal["manifestSha256"],
            "profileSha256": PROFILE,
            "targetSourceTree": "tree-v11-unified",
            "pairedCohort": {
                "baseline": {"profileSha256": PROFILE, "producer": dict(PRODUCER_V10)},
                "candidate": {"profileSha256": PROFILE, "producer": dict(PRODUCER_V11)},
                "rawCensoredEvents": 0,
                "retainedCensoredEvents": 0,
                "workloads": [
                    {
                        "name": "binding-4096-requests",
                        "baseline": {"completedWork": 4096, "medianMs": 3.13, "peakRssBytes": 64 * 1024 * 1024},
                        "candidate": {"completedWork": 4096, "medianMs": 2.95, "peakRssBytes": 64 * 1024 * 1024},
                    }
                ],
            },
            "familyLedger": {
                fam: {
                    "sourceTree": "tree-v11-unified",
                    "profileSha256": PROFILE,
                    "passed": True,
                    "vetoActive": False,
                    "peakRssBytes": 7 * 1024 * 1024 * 1024,
                }
                for fam in ALL_TWELVE_FAMILIES
            },
        }
        v_ok = require_release_smp_evidence(ROOT, receipt)
        self.assertTrue(v_ok["wholeRuntimeAdmitted"])
        self.assertTrue(v_ok["pairedCohortPassed"])

        # Cross-source splicing (Families 1-5 on earlier tree) MUST NOT admit 12/12
        spliced = copy.deepcopy(receipt)
        spliced["familyLedger"]["gsi"]["sourceTree"] = "tree-v5-earlier"
        v_spliced = audit_release_family(ROOT, spliced)
        self.assertTrue(v_spliced["pairedCohortPassed"])
        self.assertFalse(v_spliced["wholeRuntimeAdmitted"])
        self.assertTrue(v_spliced["crossSourceDetected"])

        # Dropped censor fails paired cohort
        dropped = copy.deepcopy(receipt)
        dropped["pairedCohort"]["rawCensoredEvents"] = 2
        dropped["pairedCohort"]["retainedCensoredEvents"] = 1
        v_dropped = audit_release_family(ROOT, dropped)
        self.assertFalse(v_dropped["pairedCohortPassed"])
        self.assertFalse(v_dropped["wholeRuntimeAdmitted"])

        # Active same-source veto blocks 12/12
        vetoed = copy.deepcopy(receipt)
        vetoed["familyLedger"]["stress-gsi"]["vetoActive"] = True
        self.assertFalse(audit_release_family(ROOT, vetoed)["wholeRuntimeAdmitted"])

    def test_run_audited_command_kills_live_memory_leak(self):
        import sys
        from gambit_smp.families_8_12_audit import run_audited_command

        rec = run_audited_command(
            [
                sys.executable,
                "-c",
                "import time; chunks=[]; [chunks.append(bytearray(8*1024*1024)) or time.sleep(0.05) for _ in range(40)]",
            ],
            cwd=ROOT,
            timeout=15,
            max_rss_bytes=64 * 1024 * 1024,
            max_footprint_bytes=64 * 1024 * 1024,
            poll_interval=0.05,
        )
        self.assertFalse(rec["passed"])
        self.assertFalse(rec["timeout"])
        self.assertTrue(rec["rssLimitExceeded"] or rec["footprintLimitExceeded"])
        self.assertTrue(rec["processGroupQuiescent"])
        self.assertLess(rec["seconds"], 8.0)


if __name__ == "__main__":
    unittest.main()
