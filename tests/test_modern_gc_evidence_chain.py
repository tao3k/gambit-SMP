"""End-to-end integrity and traceability tests for the Modern GC amplification evidence chain."""

import hashlib
import json
from pathlib import Path
import re
import unittest

from gambit_smp import paper_cache as papers


ROOT = papers.ROOT
CHAIN_PATH = ROOT / "dev/modeling/inputs/papers-modern-gc-amplification.json"
RECEIPT_PATH = ROOT / "evidence/modern-gc-amplification-verification-receipt.json"
MANIFEST_PATH = ROOT / "evidence/papers-modern-gc-architecture.json"
LOCK_PATH = ROOT / "evidence/papers-modern-gc-architecture.lock.json"
SYSML_PATH = ROOT / "dev/refactoring/modern-c/models/sysml/modern-gc-amplification.sysml"
QUINT_PATH = ROOT / "dev/refactoring/modern-c/models/quint/v2/modern_gc_amplification_v2.qnt"
LEAN_PATH = ROOT / "dev/refactoring/modern-c/models/lean/ModernGcAmplificationRefinement.lean"
CBMC_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/modern_gc_amplification_pso.c"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ModernGcEvidenceChainTests(unittest.TestCase):
    def test_chain_covers_every_locked_paper_with_matching_sha_and_notes(self):
        chain = json.loads(CHAIN_PATH.read_text())
        self.assertEqual("gambit-smp-paper-evidence-chain.v1", chain["schema"])

        manifest = json.loads(MANIFEST_PATH.read_text())["papers"]
        pins = papers.paper_pins(LOCK_PATH, manifest)

        chain_ids = [entry["id"] for entry in chain["lockedPapers"]]
        self.assertEqual(len(set(chain_ids)), len(chain_ids))
        self.assertEqual(set(pins), set(chain_ids))

        for entry in chain["lockedPapers"]:
            pin = pins[entry["id"]]
            self.assertEqual(pin["pdfSha256"], entry["pdfSha256"])
            self.assertEqual(pin["notes"], entry["notes"])
            self.assertEqual("chapter_complete", entry["readStatus"])
            self.assertTrue((ROOT / entry["notes"]).is_file())
            self.assertTrue(entry["adopted"].strip())
            self.assertTrue(entry["non_import"].strip())
            self.assertTrue(entry["native_acceptance_gate"].strip())

    def test_all_referenced_formal_symbols_and_vendor_anchors_exist(self):
        chain = json.loads(CHAIN_PATH.read_text())
        sysml_text = SYSML_PATH.read_text()
        quint_text = QUINT_PATH.read_text()
        lean_text = LEAN_PATH.read_text()
        cbmc_text = CBMC_PATH.read_text()

        # Zero sorry in Lean proof file
        self.assertIsNone(re.search(r"\bsorry\b", lean_text))

        # SysML admission gate must explicitly keep Amp-1 gated until Phase A/B/C stabilizes
        self.assertIn("requirement def AmpWaveAdmissionLaw", sysml_text)
        self.assertIn("attribute :>> phaseABCStabilized = false;", sysml_text)
        self.assertIn("attribute :>> amp1ImplementationAdmitted = false;", sysml_text)

        for entry in chain["lockedPapers"]:
            for req in entry["sysml_requirements"]:
                self.assertRegex(
                    sysml_text,
                    rf"\brequirement\s+def\s+{re.escape(req)}\b",
                    f"missing SysML requirement {req} referenced by {entry['id']}",
                )
            for qrun in entry["quint_obligations"]:
                self.assertRegex(
                    quint_text,
                    rf"\brun\s+{re.escape(qrun)}\b",
                    f"missing Quint run {qrun} referenced by {entry['id']}",
                )
            for thm in entry["lean_theorems"]:
                self.assertRegex(
                    lean_text,
                    rf"\btheorem\s+{re.escape(thm)}\b",
                    f"missing Lean theorem {thm} referenced by {entry['id']}",
                )
            for macro in entry["cbmc_contracts"]:
                self.assertRegex(
                    cbmc_text,
                    rf"\b{re.escape(macro)}\b",
                    f"missing CBMC mutant macro {macro} referenced by {entry['id']}",
                )
            for anchor in entry["vendor_anchors"]:
                self.assertTrue(
                    (ROOT / anchor).is_file(),
                    f"missing vendor anchor {anchor} referenced by {entry['id']}",
                )

    def test_verification_receipt_digests_match_live_files_and_preserve_honesty_boundaries(self):
        receipt = json.loads(RECEIPT_PATH.read_text())
        self.assertEqual("gambit-smp-amplification-verification-receipt.v1", receipt["schema"])

        # Honesty boundaries: formal checks and micro-benchmarks NEVER grant native/release admission
        self.assertFalse(receipt["admissionBoundaries"]["nativeRuntimeAdmitted"])
        self.assertFalse(receipt["admissionBoundaries"]["releaseAdmitted"])
        self.assertFalse(receipt["admissionBoundaries"]["phaseABCPrerequisiteSatisfied"])
        self.assertFalse(receipt["admissionBoundaries"]["amp1ImplementationAdmitted"])

        # Every tracked artifact SHA-256 digest in the receipt must match the file on disk
        artifacts = receipt["artifactSha256"]
        self.assertGreaterEqual(len(artifacts), 15)
        for rel_path, expected_sha in artifacts.items():
            full_path = ROOT / rel_path
            self.assertTrue(full_path.is_file(), f"receipt artifact missing: {rel_path}")
            self.assertRegex(expected_sha, r"^[0-9a-f]{64}$")
            self.assertEqual(
                expected_sha,
                sha256_file(full_path),
                f"SHA-256 drift detected for {rel_path}; regenerate receipt after edits",
            )

        # Every PDF digest in receipt matches the additive lock
        lock_pins = {p["id"]: p["pdfSha256"] for p in json.loads(LOCK_PATH.read_text())["papers"]}
        self.assertEqual(lock_pins, receipt["lockedPdfSha256"])

    def test_non_pdf_backlog_disjoint_from_locked_papers_and_legacy_lock(self):
        chain = json.loads(CHAIN_PATH.read_text())
        locked_ids = {p["id"] for p in chain["lockedPapers"]}
        legacy_ids = {p["id"] for p in json.loads((ROOT / "evidence/papers.lock.json").read_text())["papers"]}
        backlog_ids = {p["id"] for p in chain["remainingNonPdfBacklog"]}

        self.assertEqual(set(), locked_ids & legacy_ids)
        self.assertEqual(set(), locked_ids & backlog_ids)
        self.assertEqual(set(), legacy_ids & backlog_ids)
        for item in chain["remainingNonPdfBacklog"]:
            self.assertIn(
                item["status"],
                ("metadata_only_paywalled", "metadata_only_tls_unreachable", "external_html_spec"),
            )


if __name__ == "__main__":
    unittest.main()
