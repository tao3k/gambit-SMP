"""CI transport contracts; these controls grant no SMP or remote-green credit."""
import re
import unittest
from gambit_smp.framework import ROOT


class ToolIdentityTests(unittest.TestCase):
    def test_sealed_producer_and_consumers_use_the_same_python_patch(self):
        install = (ROOT / '.github/actions/framework/action.yml').read_text()
        workflow = (ROOT / '.github/workflows/gambit.yml').read_text()
        selected = re.findall(r"python-version: '([^']+)'", install)
        self.assertEqual(1, len(selected))
        self.assertRegex(selected[0], r'^3\.14\.[0-9]+$')
        self.assertEqual(selected, re.findall(r"python-version: '([^']+)'", workflow))
        self.assertIn('uv sync --locked --python "$(command -v python)"', install)

    def test_formal_archive_cache_keeps_both_hash_checks_and_original_download_cap(self):
        workflow = (ROOT / '.github/workflows/verify.yml').read_text()
        archive_sha = '93fef2f381d30465eff906a2d6afa3358cb2c9adf6a8aad3bec0ded4f45432bb'
        jar_sha = '880c0b2b72354816f12e9a9755829f2907071e9a181ffea1937954c23d54739d'
        self.assertIn('key: apalache-0.62.1-' + archive_sha, workflow)
        self.assertIn('--connect-timeout 10 --max-time 15 ', workflow)
        self.assertIn(archive_sha + '  $archive.pending', workflow)
        self.assertIn('mv "$archive.pending" "$archive"', workflow)
        self.assertIn(jar_sha, workflow)
        self.assertIn('sha256sum --check --status', workflow)
