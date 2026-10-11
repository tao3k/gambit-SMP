import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import MagicMock, patch

from gambit_smp import paper_cache as papers


class PaperCacheTests(unittest.TestCase):
    paper = {"id": "test-paper", "title": "Test", "url": "https://example.org/p.pdf"}

    def test_hit_never_downloads_and_checks_both_digests(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test") as fetch, \
                 patch.object(papers, "extract", return_value=b"Test\f"):
                receipt, status = papers.cache(self.paper, root)
                self.assertEqual("downloaded", status)
                self.assertEqual(1, receipt["pages"])
                self.assertEqual("cached", papers.cache(self.paper, root)[1])
                fetch.assert_called_once()
                (root / "test-paper/paper.md").write_text("corrupted")
                with self.assertRaisesRegex(ValueError, "integrity mismatch"):
                    papers.cache(self.paper, root)
                fetch.assert_called_once()

    def test_locked_identity_cannot_change_on_refresh(self):
        data = b"%PDF-1.4 test"
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=data), \
                 patch.object(papers, "extract", return_value=b"Test\f"):
                papers.cache(self.paper, root, expected_pdf=papers.sha(data))
            with patch.object(papers, "download", return_value=b"%PDF-1.4 changed"), \
                 patch.object(papers, "extract") as extract:
                with self.assertRaisesRegex(ValueError, "differs from tracked pin"):
                    papers.cache(self.paper, root, refresh=True, expected_pdf=papers.sha(data))
                extract.assert_not_called()
            self.assertEqual(data, (root / "test-paper/paper.pdf").read_bytes())

    def test_cached_pdf_must_match_pin(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test"), \
                 patch.object(papers, "extract", return_value=b"Test\f"):
                papers.cache(self.paper, root)
            with self.assertRaisesRegex(ValueError, "cached PDF differs"):
                papers.cache(self.paper, root, expected_pdf="0" * 64)

    def test_new_cache_uses_markdown_not_txt(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test"), \
                 patch.object(papers, "extract", return_value=b"One\fTwo\f"):
                receipt, _ = papers.cache(self.paper, root)
            self.assertEqual("gambit-smp-paper-cache.v2", receipt["schema"])
            self.assertIn("paper.md", receipt["sha256"])
            self.assertNotIn("paper.txt", receipt["sha256"])
            self.assertFalse((root / "test-paper/paper.txt").exists())
            self.assertIn("# Test", (root / "test-paper/paper.md").read_text())

    def test_all_repository_papers_have_pinned_sources_and_notes(self):
        import json
        listed = []
        for name in ("papers.json", "papers-audit-expansion.json"):
            listed.extend(json.loads((papers.ROOT / "evidence" / name).read_text())["papers"])
        pins = papers.paper_pins(papers.LOCK, listed)
        self.assertEqual({paper["id"] for paper in listed}, set(pins))
        for changed in (dict(self.paper, url="https://example.org/new.pdf"), self.paper):
            with self.assertRaisesRegex(ValueError, "missing or differs"):
                papers.paper_pins(papers.LOCK, [changed])

    def test_notes_cannot_live_in_cache_or_escape_docs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            (root / ".data").mkdir()
            cached = root / ".data/paper.md"
            cached.write_text("cache, not a research record\n")
            (root / "docs/cache-link.md").symlink_to(cached)
            lock = root / "lock.json"
            for name in (".data/paper.md", "docs/../.data/paper.md", "docs/cache-link.md"):
                with self.subTest(notes=name):
                    lock.write_text(json.dumps({"schema": "gambit-smp-paper-lock.v1",
                        "papers": [dict(self.paper, pdfSha256="0" * 64, notes=name)]}))
                    with self.assertRaisesRegex(ValueError, "Markdown/Org"):
                        papers.paper_pins(lock, [self.paper], root=root)

    def test_markdown_and_org_notes_in_docs_are_allowed(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "docs").mkdir()
            lock = root / "lock.json"
            for suffix in ("md", "org"):
                name = "docs/paper." + suffix
                (root / name).write_text("reviewed protocol notes\n")
                lock.write_text(json.dumps({"schema": "gambit-smp-paper-lock.v1",
                    "papers": [dict(self.paper, pdfSha256="0" * 64, notes=name)]}))
                self.assertIn(self.paper["id"], papers.paper_pins(lock, [self.paper], root=root))

    def test_source_identity_change_is_not_silent_refresh(self):
        with tempfile.TemporaryDirectory() as directory:
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test"), \
                 patch.object(papers, "extract", return_value=b"Test\f"):
                papers.cache(self.paper, Path(directory))
                changed = dict(self.paper, url="https://example.org/new.pdf")
                with self.assertRaisesRegex(ValueError, "identity/integrity mismatch"):
                    papers.cache(changed, Path(directory))

    def test_extraction_failure_leaves_no_published_cache(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test"), \
                 patch.object(papers, "extract", side_effect=ValueError("invalid PDF")):
                with self.assertRaises(ValueError):
                    papers.cache(self.paper, root)
            self.assertEqual([], list(root.iterdir()))

    def test_unsafe_identifier_and_source_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for changed in (dict(self.paper, id="../escape"),
                            dict(self.paper, url="http://example.org/p.pdf")):
                with self.assertRaises(ValueError):
                    papers.cache(changed, Path(directory))

    def test_download_rejects_invalid_pdf_size_and_insecure_redirect(self):
        for url, data in (("https://example.org/p.pdf", b"<html>not PDF"),
                          ("https://example.org/p.pdf", b"%PDF-" + b"x" * papers.MAX_BYTES),
                          ("http://example.org/p.pdf", b"%PDF-test")):
            response = MagicMock()
            response.geturl.return_value = url
            response.read.return_value = data
            with patch.object(papers, "urlopen") as opener:
                opener.return_value.__enter__.return_value = response
                with self.assertRaises(ValueError):
                    papers.download(self.paper["url"])

    def test_ocr_is_explicit_and_receipt_marks_provenance(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(papers, "download", return_value=b"%PDF-1.4 test"), \
                 patch.object(papers, "extract", side_effect=papers.EmptyText("scanned")), \
                 patch.object(papers, "ocr_scanned", return_value=b"OCR page\f") as ocr:
                with self.assertRaises(papers.EmptyText):
                    papers.cache(self.paper, root)
                ocr.assert_not_called()
                receipt, _ = papers.cache(self.paper, root, allow_ocr=True)
                self.assertIn("OCR needs visual verification", receipt["extractor"])
                self.assertEqual(1, receipt["pages"])
                self.assertEqual("cached", papers.cache(self.paper, root)[1])
                ocr.assert_called_once()

    def test_ocr_rejects_unbounded_page_counts(self):
        for text in ("Pages: 0\n", "Pages: 17\n", "unknown"):
            with patch.object(papers.subprocess, "run") as run:
                run.return_value.stdout = text
                with self.assertRaisesRegex(ValueError, "page count"):
                    papers.ocr_scanned(Path("paper.pdf"))
                run.assert_called_once()


if __name__ == "__main__":
    unittest.main()
