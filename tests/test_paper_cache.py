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
                (root / "test-paper/paper.txt").write_text("corrupted")
                with self.assertRaisesRegex(ValueError, "integrity mismatch"):
                    papers.cache(self.paper, root)
                fetch.assert_called_once()

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
