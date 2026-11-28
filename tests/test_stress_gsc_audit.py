"""Unit tests for Family 7 (stress-gsc) manifest, Link 4/5 verification, and suite validation."""

import copy
import hashlib
import json
from pathlib import Path
import unittest

from gambit_smp.native_capabilities import validate_suite
from gambit_smp.rest_observation import runtime_identity_bytes
from gambit_smp.stress_gsc_audit import (
    MAX_COMPILER_RSS_BYTES,
    REQUIRED_STRESS_FILES,
    STRESS_GSC_MANIFEST,
    verify_compiled_host_receipt,
    verify_formal_models_link,
)
from gambit_smp.stress_gsc_link4 import (
    _parse_time_rss_bytes,
    classify_undefined_gambit_symbols,
)

ROOT = Path(__file__).resolve().parents[1]


def _sample_candidate():
    return {
        "schema": "gambit-recipe-runtime-identity.v1",
        "binarySha256": "1" * 64,
        "gscSha256": "2" * 64,
        "sourceFiles": {"include/gambit.h": "3" * 64},
    }


def _sample_link4_receipt(candidate):
    return {
        "schema": "family7-compiled-host-validation.v1",
        "passed": True,
        "producer": {
            "gsiSha256": candidate["binarySha256"],
            "gscSha256": candidate["gscSha256"],
            "runtimeIdentitySha256": hashlib.sha256(runtime_identity_bytes(candidate)).hexdigest(),
        },
        "peakCompilerRssBytes": 256 * 1024 * 1024,
        "modules": [
            {
                "target": target,
                "passed": True,
                "rssGuardSafe": True,
                "labelCount": 180,
                "violationCount": 0,
                "sourceSha256": "a" * 64,
                "cSha256": "b" * 64,
                "o1Sha256": "c" * 64,
                "dlopenExecutionPassed": True,
            }
            for target in REQUIRED_STRESS_FILES
        ],
        "negativeControls": {
            "total": 5,
            "passed": True,
            "controls": [
                {"id": f"neg-{i}", "rejected": True, "passed": True}
                for i in range(1, 6)
            ],
        },
        "nativeControls": {
            "passed": True,
            "shortageGcReloadWriteCommitPassed": True,
            "crossModuleInterruptUnwindPassed": True,
            "oneWordShortRefusalPassed": True,
        },
    }


class StressGscAuditTests(unittest.TestCase):
    def test_live_manifest_and_link5_formal_models_match_workspace(self):
        manifest = json.loads((ROOT / STRESS_GSC_MANIFEST).read_text())
        info = verify_formal_models_link(ROOT, manifest)
        self.assertEqual(info["verifiedModels"], 5)
        self.assertEqual(manifest["spec"]["mode"], "gsc")
        self.assertEqual(manifest["spec"]["maxCompilerRssGiB"], 8)
        self.assertEqual(sorted(c["target"] for c in manifest["cases"]), REQUIRED_STRESS_FILES)

    def test_verify_compiled_host_receipt_accepts_valid_and_rejects_faults(self):
        candidate = _sample_candidate()
        valid = _sample_link4_receipt(candidate)
        summary = verify_compiled_host_receipt(valid, candidate)
        self.assertEqual(summary["modules"], 4)
        self.assertEqual(summary["negativeControls"], 5)

        # Mismatched GSC producer digest
        bad_gsc = copy.deepcopy(valid)
        bad_gsc["producer"]["gscSha256"] = "9" * 64
        with self.assertRaisesRegex(ValueError, "different sealed gsc/gsi producer"):
            verify_compiled_host_receipt(bad_gsc, candidate)

        # RSS >= 8 GiB or silent-zero RSS rejected
        bad_rss = copy.deepcopy(valid)
        bad_rss["peakCompilerRssBytes"] = MAX_COMPILER_RSS_BYTES
        with self.assertRaisesRegex(ValueError, "8 GiB"):
            verify_compiled_host_receipt(bad_rss, candidate)

        zero_rss = copy.deepcopy(valid)
        zero_rss["peakCompilerRssBytes"] = 0
        with self.assertRaisesRegex(ValueError, ">0"):
            verify_compiled_host_receipt(zero_rss, candidate)

        # Leaked dynamic .o1 Gambit ABI symbol rejected when audited
        bad_sym = copy.deepcopy(valid)
        bad_sym["modules"][0]["dynamicAbiClean"] = False
        bad_sym["modules"][0]["undefinedGambitSymbols"] = ["___group_demand_enter"]
        with self.assertRaisesRegex(ValueError, "leaked undefined Gambit symbols"):
            verify_compiled_host_receipt(bad_sym, candidate)

        # Failed controlArtifacts TV or ABI check rejected
        bad_ctrl = copy.deepcopy(valid)
        bad_ctrl["nativeControls"]["controlArtifacts"] = {
            "shortage": {"cSha256": "a" * 64, "o1Sha256": "b" * 64, "tvPassed": True,
                         "dynamicAbiClean": True, "undefinedGambitSymbols": []},
            "interrupt": {"cSha256": "a" * 64, "o1Sha256": "b" * 64, "tvPassed": True,
                          "dynamicAbiClean": False, "undefinedGambitSymbols": ["___gate2_group_site"]},
            "oneWordShort": {"cSha256": "a" * 64, "o1Sha256": "b" * 64, "tvPassed": True,
                             "dynamicAbiClean": True, "undefinedGambitSymbols": []},
        }
        with self.assertRaisesRegex(ValueError, "failed TV or dynamic ABI"):
            verify_compiled_host_receipt(bad_ctrl, candidate)

        # Label count >= 6000 rejected
        bad_lbl = copy.deepcopy(valid)
        bad_lbl["modules"][0]["labelCount"] = 6000
        with self.assertRaisesRegex(ValueError, "translation validation failed"):
            verify_compiled_host_receipt(bad_lbl, candidate)

        # Missing negative control rejected
        bad_neg = copy.deepcopy(valid)
        bad_neg["negativeControls"]["controls"][0]["rejected"] = False
        with self.assertRaisesRegex(ValueError, "5 mutated-host"):
            verify_compiled_host_receipt(bad_neg, candidate)

        # Failed native .o1 control rejected
        bad_native = copy.deepcopy(valid)
        bad_native["nativeControls"]["oneWordShortRefusalPassed"] = False
        with self.assertRaisesRegex(ValueError, "native .o1 wire-trace"):
            verify_compiled_host_receipt(bad_native, candidate)

    def test_nm_undefined_symbol_classifier_and_cross_platform_rss_parser(self):
        mach_o_clean = "_memcpy\n___stack_chk_fail\n____stack_chk_guard\ndyld_stub_binder\n"
        self.assertEqual(classify_undefined_gambit_symbols(mach_o_clean, mach_o=True), [])

        mach_o_leaked = (
            "_memcpy\n"
            "____group_demand_enter\n"
            "____rest_observation_store_fast\n"
            "____stack_chk_fail\n"
        )
        self.assertEqual(
            classify_undefined_gambit_symbols(mach_o_leaked, mach_o=True),
            ["___group_demand_enter", "___rest_observation_store_fast"],
        )

        elf_leaked = "                 U memcpy\n                 U ___gate2_group_site\n"
        self.assertEqual(
            classify_undefined_gambit_symbols(elf_leaked, mach_o=False),
            ["___gate2_group_site"],
        )

        self.assertEqual(_parse_time_rss_bytes("  156876800  maximum resident set size\n"), 156876800)
        self.assertEqual(_parse_time_rss_bytes("\tMaximum resident set size (kbytes): 153200\n"), 153200 * 1024)
        self.assertEqual(_parse_time_rss_bytes("no rss metric here"), 0)

    def test_validate_suite_accepts_gsc_ordered_stress_with_compiled_host_receipt(self):
        args = {
            "runtime": {"step": "producer", "output": "runtime"},
            "identity": {"step": "producer", "output": "identity"},
            "mode": "gsc",
            "regime": "whole-parallel",
            "inventory": "stress",
            "selection": ["."],
            "expectedFiles": list(REQUIRED_STRESS_FILES),
            "orderedStress": {
                "manifest": STRESS_GSC_MANIFEST,
                "inputReceipt": "evidence/research/retained/modern-c/stress-gsi/dev-family6-receipt-audit.json",
                "profile": "evidence/research/retained/modern-c/activation-storage/qualified-existing-profile.json",
                "compiledHostReceipt": "evidence/fixtures/dev-family7-stress-gsc/link4-validation.json",
            },
        }
        inputs = {
            STRESS_GSC_MANIFEST,
            "evidence/research/retained/modern-c/stress-gsi/dev-family6-receipt-audit.json",
            "evidence/research/retained/modern-c/activation-storage/qualified-existing-profile.json",
            "evidence/fixtures/dev-family7-stress-gsc/link4-validation.json",
        }
        validate_suite(args, inputs)
        with self.assertRaises(ValueError):
            validate_suite(args, inputs - {"evidence/fixtures/dev-family7-stress-gsc/link4-validation.json"})


if __name__ == "__main__":
    unittest.main()
