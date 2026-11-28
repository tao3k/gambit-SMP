"""Byte-binding controls; this fixture is not a simulated runtime or a GSI."""
import hashlib
import json
import os
from pathlib import Path
import struct
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from gambit_smp.image_contract import inspect, macho, direct_edge, audit


def fixture():
    pc = 0x100001000
    words = (0xf9006be0, 0x94000001, 0xaa0003e0, 0xf9006be1)
    commands = struct.pack('<II16sQQQQiiII', 0x19, 152, b'__TEXT', pc, 16, 208, 16, 5, 5, 1, 0)
    commands += struct.pack('<16s16sQQIIIIIIII', b'__text', b'__TEXT', pc, 16, 208, 2, 0, 0, 0, 0, 0, 0)
    commands += struct.pack('<6I', 2, 24, 224, 1, 240, 8)
    raw = struct.pack('<8I', 0xfeedfacf, 0x100000c, 0, 2, 2, len(commands), 0, 0)
    raw += commands + struct.pack('<4I', *words) + struct.pack('<IBBHQ', 1, 0x0f, 1, 0, pc) + b'\0_entry\0'
    profile = dict(schema='gambit.linked-image-cuts.v1', image='fixture.image',
        imageSha256=hashlib.sha256(raw).hexdigest(), scope='structural test only',
        witnesses=[dict(id='entry', symbol='_entry', start=hex(pc), words=[f'{w:08x}' for w in words], purpose='test byte binding')],
        edges=[dict(id='call', **{'from':hex(pc+4), 'to':hex(pc+8), 'kind':'call'})],
        slots=[dict(id='address', save=hex(pc), overwrite=hex(pc+12), offset=208, call=hex(pc+4), **{'return':hex(pc+8)})],
        assumptions=['Normal ABI and no escaped caller-stack alias; no execution or root authority.'])
    return profile, raw


class ImageCutsTests(unittest.TestCase):
    def test_bound_bytes_edges_and_address_only_slot(self):
        profile, raw = fixture()
        result = inspect(profile, raw)
        self.assertEqual(result['slots'][0]['status'], 'ABI-conditional-readable-address')
        self.assertFalse(result['slots'][0]['isGCRoot'])
        self.assertFalse(result['slots'][0]['oldPointeeDereferenceAuthorized'])
        self.assertFalse(result['executionLaunched'])
        self.assertEqual(result['sourceCorrespondence'], 'UNESTABLISHED')

    def test_changed_image_or_reviewed_bytes_refused(self):
        profile, raw = fixture()
        with self.assertRaisesRegex(ValueError, 'identity'):
            inspect(profile, raw[:-1] + b'x')
        profile['witnesses'][0]['words'][2] = 'd503201f'
        with self.assertRaisesRegex(ValueError, 'instruction bytes'):
            inspect(profile, raw)

    def test_wrong_edge_or_incomplete_interval_refused(self):
        profile, raw = fixture()
        profile['edges'][0]['to'] = '0x10000100c'
        with self.assertRaisesRegex(ValueError, 'direct edge'):
            inspect(profile, raw)
        profile, raw = fixture()
        profile['witnesses'][0]['words'].pop()
        with self.assertRaisesRegex(ValueError, 'complete reviewed bytes'):
            inspect(profile, raw)

    def test_early_overwrite_refused_even_with_matching_new_image_hash(self):
        profile, raw = fixture()
        raw = raw[:216] + struct.pack('<I', 0xf9006be2) + raw[220:]
        profile['imageSha256'] = hashlib.sha256(raw).hexdigest()
        profile['witnesses'][0]['words'][2] = 'f9006be2'
        with self.assertRaisesRegex(ValueError, 'overwritten before'):
            inspect(profile, raw)

    def test_wrong_architecture_and_truncated_inventory_refused(self):
        _, raw = fixture()
        with self.assertRaisesRegex(ValueError, 'ARM64'):
            macho(raw[:4] + struct.pack('<I', 7) + raw[8:])
        with self.assertRaises(ValueError):
            macho(raw[:40])

    def test_backward_branch_sign_extension(self):
        self.assertEqual(direct_edge(0x1000, 0x17ffffff), ('branch', 0xffc))

    def test_snapshot_role_is_bound_read_only_to_the_selected_task(self):
        profile, raw = fixture()
        with tempfile.TemporaryDirectory() as temporary, patch.dict(os.environ, GAMBIT_SMP_TASK_ID='image-case'):
            root = Path(temporary).resolve()
            name = '.cache/tasks/image-case/fixture.image'
            path = root/name
            path.parent.mkdir(parents=True)
            path.write_bytes(raw)
            path.chmod(0o444)
            profile['image'] = name
            bindings = []
            ctx = SimpleNamespace(root=root, bind=lambda paths: bindings.extend(paths), remaining=lambda: 20)
            result = audit(dict(profile='profile.json'), {'profile.json': json.dumps(profile).encode()}, ctx)
            self.assertEqual(result['imageArtifact'], name)
            self.assertEqual(bindings, [path, path])
            path.chmod(0o644)
            with self.assertRaisesRegex(ValueError, 'non-executable'):
                audit(dict(profile='profile.json'), {'profile.json': json.dumps(profile).encode()}, ctx)

    def test_other_task_and_parent_components_are_not_artifact_roles(self):
        profile, _ = fixture()
        ctx = SimpleNamespace(root=Path('/unused'))
        with patch.dict(os.environ, GAMBIT_SMP_TASK_ID='image-case'):
            for name in ('.cache/tasks/another-case/image', '.cache/tasks/image-case/../another-case/image'):
                profile['image'] = name
                with self.assertRaisesRegex(ValueError, 'selected task'):
                    audit(dict(profile='profile.json'), {'profile.json': json.dumps(profile).encode()}, ctx)


if __name__ == '__main__':
    unittest.main()
