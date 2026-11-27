"""Regression tests for the additive modern GC / architecture paper manifest & lock."""

import json
from pathlib import Path
import unittest

from gambit_smp import paper_cache as papers


MANIFEST = papers.ROOT / "evidence/papers-modern-gc-architecture.json"
LOCK = papers.ROOT / "evidence/papers-modern-gc-architecture.lock.json"


class ModernGcPaperManifestTests(unittest.TestCase):
    def test_additive_manifest_and_lock_are_valid_and_disjoint_from_legacy(self):
        manifest = json.loads(MANIFEST.read_text())
        self.assertEqual("gambit-smp-papers.v1", manifest["schema"])
        listed = manifest["papers"]
        self.assertEqual(16, len(listed))
        pins = papers.paper_pins(LOCK, listed)
        self.assertEqual({p["id"] for p in listed}, set(pins))

        legacy_ids = set()
        for name in ("papers.json", "papers-audit-expansion.json"):
            for entry in json.loads((papers.ROOT / "evidence" / name).read_text())["papers"]:
                legacy_ids.add(entry["id"])
        self.assertEqual(set(), legacy_ids & set(pins))

    def test_every_note_records_gambit_correspondence_and_non_import_boundaries(self):
        lock_data = json.loads(LOCK.read_text())
        note_paths = sorted({entry["notes"] for entry in lock_data["papers"]})
        self.assertGreaterEqual(len(note_paths), 5)
        for rel in note_paths:
            path = papers.ROOT / rel
            self.assertTrue(path.is_file(), f"missing note {rel}")
            text = path.read_text()
            self.assertIn("Gambit", text, f"missing Gambit correspondence in {rel}")
            self.assertIn("Non-import boundaries", text, f"missing non-import boundaries in {rel}")
            self.assertIn("evidence/papers-modern-gc-architecture.lock.json", text)

    def test_cached_local_pdfs_match_lock_when_present(self):
        cache_dir = papers.ROOT / ".cache/papers"
        if not cache_dir.is_dir():
            self.skipTest("local paper cache not populated")
        manifest = json.loads(MANIFEST.read_text())["papers"]
        pins = papers.paper_pins(LOCK, manifest)
        checked = 0
        for paper in manifest:
            receipt_path = cache_dir / paper["id"] / "receipt.json"
            if receipt_path.is_file():
                receipt, status = papers.cache(
                    paper, cache_dir, refresh=False, expected_pdf=pins[paper["id"]]["pdfSha256"]
                )
                self.assertEqual("cached", status)
                self.assertEqual(pins[paper["id"]]["pdfSha256"], receipt["sha256"]["paper.pdf"])
                checked += 1
        self.assertEqual(len(manifest), checked)


if __name__ == "__main__":
    unittest.main()
