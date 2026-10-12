import unittest

from gambit_smp.ascent_program import load_catalog
from gambit_smp import evidence_index as index
from gambit_smp import protocol_evidence as evidence
from gambit_smp import verify_protocols as verify


class VMConstructorContractTests(unittest.TestCase):
    def test_constructor_bundles_register_known_and_pending_layers(self):
        registered = dict(evidence.BUNDLES)
        for name in ("setup-outer-ownership-model", "pstate-vm-failure-handoff",
                     "vm-heap-partial-allocation",
                     "vm-list-constructor-visibility", "vm-spinlock-initialization",
                     "vm-list-c-memory-order", "pstate-spinlock-initialization",
                     "vm-list-reader-retirement", "thread-abandonment-completion"):
            self.assertIn("evidence/" + name + ".json", registered)
        registered_cases = {
            case["id"] for name in registered
            for case in verify.load_manifest(index.ROOT / name)["cases"]
        }
        self.assertIn("vm_mem_setup_transaction", registered_cases)
        self.assertIn("vm_activity_log_abort", registered_cases)
        handoff = verify.load_manifest(index.ROOT / "evidence/pstate-vm-failure-handoff.json")
        memory = verify.load_manifest(index.ROOT /
            "evidence/fixtures/pstate-log-owned-rollback/vm-memory-contract.json")
        self.assertIn("vm_mem_setup_transaction", handoff["cases"][0]["composes"])
        self.assertIn("vm_activity_log_abort", handoff["cases"][0]["composes"])
        self.assertNotIn("vm_activity_log_abort", handoff["cases"][0]["openObligations"])
        self.assertNotIn("pstate_vm_failure_handoff", memory["cases"][0]["composes"])
        self.assertIn("vm_heap_partial_allocation", memory["cases"][0]["composes"])
        self.assertNotIn("vm_heap_partial_allocation", memory["cases"][0]["openObligations"])
        self.assertIn("vm_spinlock_initialization", memory["cases"][0]["composes"])
        self.assertIn("vm_list_constructor_visibility", memory["cases"][0]["composes"])
        self.assertEqual(7, len(verify.model_checks(memory["cases"][0])))

    def test_partial_heap_and_log_abort_have_independent_failure_controls(self):
        allocation = verify.load_manifest(index.ROOT / "evidence/vm-heap-partial-allocation.json")
        log = verify.load_manifest(index.ROOT / "evidence/vm-activity-log-abort.json")
        allocation_checks = verify.model_checks(allocation["cases"][0])
        log_checks = verify.model_checks(log["cases"][0])
        self.assertIn(("old", "zeroDescriptorSafe", "initSkipZero"), allocation_checks)
        self.assertIn(("old", "descriptorLifetimeSafe", "initTableFirst"), allocation_checks)
        self.assertIn(("old", "cleanupReadSafe", "initOld"), log_checks)
        self.assertIn(("old", "destroySafe", "initDouble"), log_checks)
        for checks in (allocation_checks, log_checks):
            self.assertEqual(5, len(checks))
            self.assertEqual(len(checks), len(set(checks)))
            self.assertEqual(("fixed", "safe", "initFixed"), checks[-1])

    def test_source_characterization_controls_do_not_become_a_fixed_initializer(self):
        visibility = verify.load_manifest(index.ROOT / "evidence/vm-list-constructor-visibility.json")
        case = visibility["cases"][0]
        checks = verify.model_checks(case)
        self.assertEqual("characterization", case["mode"])
        self.assertEqual(4, len([row for row in checks if row[0] == "old"]))
        self.assertIn(("old", "reentrySafe", "initMutexHandler"), checks)
        self.assertEqual(("protocol", "guardSound", "init"), checks[-1])
        self.assertFalse(any(row[0] == "fixed" for row in checks))
        self.assertIn("vm_list_reader_retirement", case["openObligations"])
        no_controls = dict(case)
        no_controls.pop("oldInvariants")
        self.assertEqual([("protocol", "guardSound", "init")], verify.model_checks(no_controls))

    def test_memory_order_proof_does_not_discharge_source_or_retirement(self):
        memory = verify.load_manifest(index.ROOT / "evidence/vm-list-c-memory-order.json")
        case = memory["cases"][0]
        self.assertEqual(6, len(verify.model_checks(case)))
        self.assertIn("vm_list_atomic_access_correspondence", case["openObligations"])
        self.assertIn("vm_list_signal_safe_atomics", case["openObligations"])
        visibility = verify.load_manifest(index.ROOT / "evidence/vm-list-constructor-visibility.json")
        self.assertIn("vm_list_reader_retirement", visibility["cases"][0]["openObligations"])

    def test_processor_and_reader_lifetime_controls_are_distinct(self):
        processor = verify.load_manifest(index.ROOT / "evidence/pstate-spinlock-initialization.json")
        reader = verify.load_manifest(index.ROOT / "evidence/vm-list-reader-retirement.json")
        for manifest in (processor, reader):
            checks = verify.model_checks(manifest["cases"][0])
            self.assertEqual(5, len(checks))
            self.assertEqual(len(checks), len(set(checks)))
        self.assertIn("pstate_gc_quiescence_source", processor["cases"][0]["openObligations"])
        self.assertIn("vm_list_c_memory_order", reader["cases"][0]["composes"])
        self.assertIn("vm_list_callback_drain_source", reader["cases"][0]["openObligations"])

    def test_protocol_edges_join_contract_closure_without_native_admission(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["protocol_model"] = [["handoff", "a"], ["memory", "b"]]
        facts["protocol_composes"] = [["handoff", "memory"], ["memory", "allocation"]]
        facts["protocol_checked"] = [["handoff", "local-proof"]]
        facts["protocol_obligation"] = [["memory", "allocation-internals"]]
        rules = load_catalog(index.ROOT / "evidence/catalog.ss")
        result = index.query(facts, rules)
        self.assertEqual([("handoff", "allocation"), ("handoff", "memory"),
                          ("memory", "allocation")], result["model_contract_dependencies"])
        self.assertEqual(result["model_contract_dependencies"],
                         result["contract_dependencies_without_model_receipts"])
        facts["protocol_checked"].append(["memory", "bounded-proof"])
        result = index.query(facts, rules)
        self.assertEqual([("handoff", "allocation"), ("memory", "allocation")],
                         result["contract_dependencies_without_model_receipts"])
        self.assertEqual(3, len(result["contract_dependencies_without_native_adapters"]))
        self.assertEqual([("memory", "allocation-internals")], result["protocol_open_obligations"])
        self.assertEqual([("handoff", "memory", "allocation-internals")],
                         result["contract_dependencies_with_open_obligations"])
        facts["protocol_obligation"].append(["allocation", "unproved-storage-lifetime"])
        result = index.query(facts, rules)
        self.assertEqual([("handoff", "allocation", "unproved-storage-lifetime"),
                          ("handoff", "memory", "allocation-internals"),
                          ("memory", "allocation", "unproved-storage-lifetime")],
                         result["contract_dependencies_with_open_obligations"])
        self.assertNotIn("runtime_admitted", result)

    def test_gc_resize_composition_keeps_resource_and_source_gates_separate(self):
        manifest = verify.load_manifest(index.ROOT / "evidence/gc-resize-resource-retirement.json")
        case = manifest["cases"][0]
        checks = verify.model_checks(case)
        self.assertEqual([("old", "syncSafe", "initOld"),
                          ("old", "queueSafe", "initQueueOnly"),
                          ("old", "storageSafe", "initJoinOnly"),
                          ("fixed", "safe", "initFixed")], checks)
        self.assertEqual({"gc_work_closure", "sync_tree_retirement", "pstate_spinlock_initialization"},
                         set(case["composes"]))
        self.assertIn("gc_resize_join_error_ownership", case["openObligations"])
        self.assertIn("gc_resize_nested_gc_admission", case["openObligations"])
        self.assertEqual({"ghc-parallel-gc-2008", "hotspot-parallel-gc-2001"}, set(case["papers"]))

    def test_cross_layer_circular_premises_are_rejected(self):
        facts = {name: [] for name in index.export()["facts"]}
        facts["model_contract"] = [("base", "extension", "source-premise")]
        facts["protocol_composes"] = [("extension", "base")]
        with self.assertRaisesRegex(ValueError, "circular premises"):
            index.query(facts, load_catalog(index.ROOT / "evidence/catalog.ss"))
        facts["protocol_composes"] = [("extension", "leaf")]
        index.validate_contract_graph(facts)


if __name__ == "__main__":
    unittest.main()
