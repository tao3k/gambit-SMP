import unittest

from gambit_smp.research_kernel import check_generation_identity


class GenerationRemountTests(unittest.TestCase):
    def test_mount_number_may_change_without_replacing_inodes(self):
        devices = {}
        check_generation_identity([32, 100], [29, 100], devices)
        check_generation_identity([32, 101], [29, 101], devices)
        self.assertEqual({32: 29}, devices)

    def test_changed_inode_and_split_device_mapping_are_rejected(self):
        with self.assertRaises(ValueError):
            check_generation_identity([32, 100], [29, 101], {})
        devices = {}
        check_generation_identity([32, 100], [29, 100], devices)
        with self.assertRaises(ValueError):
            check_generation_identity([32, 101], [30, 101], devices)
