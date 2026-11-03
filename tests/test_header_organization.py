"""Representation controls; linked native consumers remain separate evidence."""
from pathlib import Path
import tempfile
import unittest
from gambit_smp.header_organization import manifest, reconstruct


class HeaderOrganizationTests(unittest.TestCase):
    def test_order_is_semantic(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root/'include/_gambit').mkdir(parents=True)
            (root/'include/gambit.h.in').write_text('#include "_gambit/b.h.in"\n#include "_gambit/a.h.in"\n')
            (root/'include/_gambit/a.h.in').write_bytes(b'last\n')
            (root/'include/_gambit/b.h.in').write_bytes(b'first\n')
            self.assertEqual(reconstruct(root)[1], b'first\nlast\n')

    def test_refuses_duplicate_escape_and_implicit_payload(self):
        for raw in (b'', b'#include "../a.h.in"\n', b'#define X 1\n',
                    b'#include "_gambit/a.h.in"\n#include "_gambit/a.h.in"\n'):
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                manifest(raw)

    def test_missing_fragment_is_not_empty(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root/'include').mkdir()
            (root/'include/gambit.h.in').write_text('#include "_gambit/a.h.in"\n')
            with self.assertRaises(ValueError):
                reconstruct(root)


if __name__ == '__main__':
    unittest.main()


class HeaderSubmissionControls(unittest.TestCase):
    def test_semantic_change_cannot_use_organization_whitespace_exemption(self):
        from gambit_smp.header_organization import validate
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root/'include/_gambit').mkdir(parents=True)
            (root/'include/gambit.h.in').write_text('#include "_gambit/a.h.in"\n')
            (root/'include/_gambit/a.h.in').write_bytes(b'changed\n')
            with self.assertRaisesRegex(ValueError, 'baseline bytes'):
                validate(root, b'original\n')

    def test_organization_requires_native_kind(self):
        from types import SimpleNamespace
        from gambit_smp.header_organization import submission_contract
        with self.assertRaisesRegex(ValueError, 'qualification required'):
            submission_contract(SimpleNamespace(native={}), [])

    def test_organization_cannot_omit_direct_consumer(self):
        from types import SimpleNamespace
        from gambit_smp.header_organization import submission_contract
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root/'include/_gambit').mkdir(parents=True)
            (root/'include/gambit.h.in').write_text('#include "_gambit/a.h.in"\n')
            (root/'include/_gambit/a.h.in').write_bytes(b'original\n')
            target='include/gambit.h:include/_gambit/a.h.in'
            for name in ('configure.ac','configure','include/makefile.in'):
                (root/name).write_text('HEADER_TEMPLATES = _gambit/a.h.in\nHEADER_CONFIG = '+target+'\n')
            submission=SimpleNamespace(native={'qualificationKind':'header-organization'},workspace=root,base='base',git=lambda *args:b'original\n')
            with self.assertRaisesRegex(ValueError, 'complete header consumer cut'):
                submission_contract(submission, ['include/gambit.h.in'])


class FrameworkWorkingScope(unittest.TestCase):
    def test_selected_working_drift_blocks_but_unrelated_work_stays_owned(self):
        from tests.test_revision_submission import RevisionSubmissionFixture
        fixture = RevisionSubmissionFixture()
        fixture.setUp()
        try:
            fixture.root = fixture.repo
            fixture.native['qualificationKind'] = 'framework-support'
            fixture.native['canonicalSources'].pop('b.c')
            submission = fixture.submission()
            submission.prepare(['a.c', 'runtime'], fixture.profile)
            submission.model_inputs = {}
            (fixture.repo/'b.c').write_text('concurrent unrelated working version\n')
            submission.check_custody()
            self.assertEqual((fixture.repo/'b.c').read_text(), 'concurrent unrelated working version\n')
            (fixture.repo/'a.c').write_text('changed selected source\n')
            with self.assertRaisesRegex(ValueError, 'concurrent working changes'):
                submission.check_custody()
        finally:
            fixture.doCleanups()
