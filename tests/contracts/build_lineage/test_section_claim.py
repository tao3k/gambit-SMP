"""Real Make checks of the maintained claim-layout dependency and distribution."""
import os
from pathlib import Path
import shutil
import tempfile
import time
import unittest

from gambit_smp.task_processes import run


ROOT = Path(__file__).resolve().parents[3]


def assignment(text, name):
    lines = iter(text.splitlines())
    for line in lines:
        if line.startswith(name + ' ='):
            result = [line]
            while result[-1].endswith('\\'):
                result.append(next(lines))
            return '\n'.join(result)
    raise AssertionError('Missing maintained Make assignment: ' + name)


@unittest.skipUnless(shutil.which('make'), 'Make is required')
class SectionClaimDependencyTests(unittest.TestCase):
    def test_layout_change_invalidates_object_and_is_distributed(self):
        text = (ROOT/'vendor/gambit/lib/makefile.in').read_text()
        memory = assignment(text, 'MEMORY_SOURCES')
        normal = assignment(text, 'NORMAL_SOURCES')
        rule = next(line for line in text.splitlines() if line.startswith('mem@obj@:'))
        with tempfile.TemporaryDirectory() as temporary:
            source = Path(temporary)
            # Use the maintained dependency rule and source inventories. The
            # object is a timestamp fixture: no Gambit C or core is compiled.
            driver = '\n'.join([memory, normal, rule.replace('@obj@', '.o'), '\t@touch $@',
                                'sources:', "\t@printf '%s\\n' $(NORMAL_SOURCES) > source-list", ''])
            (source/'makefile').write_text(driver)
            names = set(memory.replace('\\\n', ' ').split('=', 1)[1].split())
            names.update(token for token in rule.split(':', 1)[1].split()
                         if not token.startswith('$'))
            old = time.time() - 120
            for name in names:
                path = source/name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture\n')
                os.utime(path, (old, old))
            obj = source/'mem.o'
            obj.write_text('existing object\n')
            os.utime(obj, (old + 30, old + 30))

            def make(*args):
                return run(['make', '-r', *args], cwd=source,
                           capture_output=True, text=True, timeout=10)

            current = make('-q', 'mem.o')
            self.assertEqual(current.returncode, 0, current.stdout + current.stderr)
            layout = source/'_mem/section-claim.inc'
            self.assertTrue(layout.is_file(), 'Claim layout must be an actual prerequisite')
            os.utime(layout, (old + 60, old + 60))
            changed = make('-q', 'mem.o')
            self.assertEqual(changed.returncode, 1, changed.stdout + changed.stderr)
            listed = make('sources')
            self.assertEqual(listed.returncode, 0, listed.stdout + listed.stderr)
            self.assertIn('_mem/section-claim.inc', (source/'source-list').read_text().splitlines())

            # Negative control: the previous inventory leaves exactly this
            # changed include invisible to Make and the distribution list.
            (source/'makefile').write_text(driver.replace('_mem/section-claim.inc ', ''))
            missing = make('-q', 'mem.o')
            self.assertEqual(missing.returncode, 0, missing.stdout + missing.stderr)
            listed = make('sources')
            self.assertEqual(listed.returncode, 0, listed.stdout + listed.stderr)
            self.assertNotIn('_mem/section-claim.inc', (source/'source-list').read_text().splitlines())
