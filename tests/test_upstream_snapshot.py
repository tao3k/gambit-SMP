from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from gambit_smp import upstream_snapshot as upstream


class SnapshotTests(unittest.TestCase):
    def test_issue_snapshot_rejects_pr_and_issue_drift(self):
        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(upstream, "api", return_value={"pull_request": {}}):
            with self.assertRaisesRegex(ValueError, "not a PR"):
                upstream.issue_snapshot(792, Path(temporary))
        with tempfile.TemporaryDirectory() as temporary, \
             patch.object(upstream, "api", return_value={"updated_at": "old"}), \
             patch.object(upstream, "pages", return_value=[]), \
             patch.object(upstream.subprocess, "check_output", return_value=b'{"updated_at":"new"}'):
            with self.assertRaisesRegex(ValueError, "issue changed"):
                upstream.issue_snapshot(792, Path(temporary))

    def test_file_cache_existence_does_not_bind_a_changed_head(self):
        row = {"head": "head", "base": "base"}
        files = [{"file": "lib/mem.c", "blobSha": "blob"}]
        saved = dict(row, files=files)
        self.assertTrue(upstream.footprint_bound(row, files, saved))
        self.assertFalse(upstream.footprint_bound(dict(row, head="new"), files, saved))
        self.assertFalse(upstream.footprint_bound(row, [], saved))
        self.assertFalse(upstream.footprint_bound(row, files, None))

    def test_discovery_retains_exclusions_and_bounty_links(self):
        def fake_api(endpoint, cache, name):
            if name.startswith("pull-index"):
                return [{"number": 1052, "title": "continuation ownership", "body": "",
                         "head": {"sha": "head"}, "base": {"sha": "base"}, "html_url": "url",
                         "state": "open", "created_at": "2026-01-01T00:00:00Z",
                         "updated_at": "2026-02-01T00:00:00Z"},
                        {"number": 1053, "title": "unrelated", "body": "", "head": {"sha": "h"},
                         "base": {"sha": "b"}, "html_url": "u", "state": "open",
                         "created_at": "2026-02-01T00:00:00Z", "updated_at": "2026-02-01T00:00:00Z"}]
            if name == "bounty":
                return {"body": "See #1052 and https://github.com/gambit/gambit/pull/989"}
            return []
        with tempfile.TemporaryDirectory() as directory, patch.object(upstream, "api", side_effect=fake_api):
            result = upstream.discovery(Path(directory))
        self.assertTrue(result["completeCreatedWindow"])
        self.assertEqual([989, 1052], result["bountyLinkedNumbers"])
        self.assertEqual("requires-human-triage", result["pulls"][0]["disposition"])
        self.assertEqual("no-discovery-signal", result["pulls"][1]["disposition"])

    def test_pagination_bound_is_not_a_complete_snapshot(self):
        with patch.object(upstream, "api", return_value=[{}] * 100):
            with self.assertRaisesRegex(ValueError, "pagination bound"):
                upstream.pages("endpoint", Path("unused"), "name", max_pages=1)

    def test_changed_pr_head_and_missing_files_are_rejected(self):
        metadata = {"head": {"sha": "head"}, "base": {"sha": "base"},
                    "updated_at": "time", "changed_files": 1}
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(upstream, "api", return_value=metadata), \
             patch.object(upstream, "pages", return_value=[]), \
             patch.object(upstream.subprocess, "check_output", return_value=b'{"head":{"sha":"new"},"base":{"sha":"base"},"updated_at":"time"}'):
            with self.assertRaisesRegex(ValueError, "changed during snapshot"):
                upstream.snapshot(1, Path(directory))
        import json
        with tempfile.TemporaryDirectory() as directory, \
             patch.object(upstream, "api", return_value=metadata), \
             patch.object(upstream, "pages", return_value=[]), \
             patch.object(upstream.subprocess, "check_output", return_value=json.dumps(metadata).encode()):
            with self.assertRaisesRegex(ValueError, "file inventory"):
                upstream.snapshot(1, Path(directory))


if __name__ == "__main__":
    unittest.main()
