import json
from pathlib import Path
import unittest
import hashlib

from gambit_smp import source_unit
from gambit_smp import source_binding


class SourceUnitTests(unittest.TestCase):
    def test_checked_setup_extraction_rejects_boundary_drift(self):
        source = "\n\n".join((
            "___HIDDEN void cleanup_os_and_mem_pstate\ncleanup body",
            "___HIDDEN ___SCMOBJ setup_os_and_mem_pstate\nsetup body",
            "___HIDDEN void cleanup_os_and_mem_vmstate\n",
            "___HIDDEN ___SCMOBJ setup_interrupts_pstate\ninterrupt setup body",
            "___EXP_FUNC(void,___raise_procedural_interrupt_pstate)\n",
            "___HIDDEN void cleanup_interrupts_pstate\ninterrupt cleanup body",
            "___HIDDEN void setup_processor_scmobj_pstate\n",
            "___HIDDEN ___SCMOBJ setup_sync_op_pstate\nsync setup body",
            "#endif\n\n\n___EXP_FUNC(void,___cleanup_pstate)\n",
            "___HIDDEN void cleanup_failed_pstate\nfailed cleanup body",
            "___EXP_FUNC(___SCMOBJ,___setup_pstate)\ncaller body",
            "___EXP_FUNC(void,___cleanup_vmstate)\n",
        ))
        block = source_unit.pstate_setup_functions(source)
        for text in ("cleanup body", "interrupt setup body", "interrupt cleanup body",
                     "sync setup body", "failed cleanup body", "caller body"):
            self.assertIn(text, block)
        for invalid in (source + source, source.replace("___HIDDEN void cleanup_failed_pstate", "changed")):
            with self.assertRaises(ValueError):
                source_unit.pstate_setup_functions(invalid)

    def test_os_memory_helper_extraction_is_exact_and_rejects_boundary_drift(self):
        start = "___HIDDEN void cleanup_os_and_mem_pstate\n"
        setup = "___HIDDEN ___SCMOBJ setup_os_and_mem_pstate\n"
        end = "\n\n___HIDDEN void cleanup_os_and_mem_vmstate\n"
        source = start + "cleanup body\n" + setup + "setup body" + end
        self.assertEqual(start + "cleanup body\n" + setup + "setup body\n",
                         source_unit.pstate_os_mem_functions(source))
        for invalid in (source + source, end + start + setup,
                        source.replace(setup, "changed")):
            with self.assertRaises(ValueError):
                source_unit.pstate_os_mem_functions(invalid)

    def test_continuation_publication_extraction_rejects_changed_guard(self):
        block = ("          if (alloc_heap_ptr >= alloc_heap_chunk_limit)\n"
                 "            {\n"
                 "              alloc_heap_ptr = alloc;\n"
                 "              end_heap_chunk (___ps);\n"
                 "              start_heap_chunk (___ps);\n"
                 "              alloc = alloc_heap_ptr;\n"
                 "            }")
        source = ("___HIDDEN void mark_captured_continuation\n"
                  "*alloc++ = ___MAKE_HD_WORDS(words, ___sFRAME);\n" + block +
                  "\n\n___HIDDEN void mark_frame\n")
        self.assertEqual(block + "\n", source_unit.continuation_chunk_block(source))
        for invalid in (source + source, source.replace("if (alloc_heap_ptr", "if (alloc"),
                        source.replace("___sFRAME", "changed")):
            with self.assertRaises(ValueError):
                source_unit.continuation_chunk_block(invalid)

    def test_sync_resource_extraction_keeps_functions_but_not_outer_smp_guard(self):
        setup = "___HIDDEN void setup_sync_op_pstate\nsetup body"
        cleanup = "___EXP_FUNC(void,___cleanup_pstate)\ncleanup body"
        source = ("#ifndef ___SINGLE_THREADED_VMS\n" + setup + "\n\n#endif\n\n\n" +
                  cleanup + "\n\n___EXP_FUNC(___SCMOBJ,___setup_pstate)\nrest")
        self.assertEqual(setup + "\n\n" + cleanup + "\n",
                         source_unit.sync_resource_functions(source))
        for invalid in (source + source, source.replace("___setup_pstate", "changed")):
            with self.assertRaises(ValueError):
                source_unit.sync_resource_functions(invalid)

    def test_checked_negation_binding_allows_exact_branch_only(self):
        original = b"prefix\n? (var=___FIXNEGP(x),1) \\\nsuffix\n"
        expected = b"prefix\n? ___FIXNEGP_NOTFALSEP(var,x) \\\nsuffix\n"
        self.assertEqual(hashlib.sha256(expected).hexdigest(), source_binding.checked_negate_header_hash(original))
        for source in (b"unrelated", original + original):
            with self.assertRaises(ValueError):
                source_binding.checked_negate_header_hash(source)
    def test_mark_mock_macro_projection_rejects_different_representation(self):
        from gambit_smp.check_gambit import ROOT
        receipt = json.loads((ROOT / "evidence/model-results/mark-array-source-unit.json").read_text())
        macros = receipt["representation"]["selectedMacros"]
        text = "\n".join("#define " + name + " " + value for name, value in macros.items())
        self.assertEqual(macros, source_unit.mark_representation(text))
        for invalid in (text.replace("#define ___TB 3", "#define ___TB 2"),
                        text.replace("#define ___REFERENCE_TO_BODY 1", "#define ___REFERENCE_TO_BODY -1"),
                        text + "\n#define ___USE_HANDLES 1"):
            with self.assertRaises(ValueError):
                source_unit.mark_representation(invalid)

    def test_mark_extractor_rejects_missing_duplicate_and_reversed_boundaries(self):
        start = "#ifdef ENABLE_CONSISTENCY_CHECKS\n\n#define mark_array(start,n) mark_array_debug (start,n,__LINE__)\n"
        end = "\n\n___HIDDEN void mark_captured_continuation\n"
        source = start + "body" + end
        self.assertEqual(start + "body\n", source_unit.mark_function(source))
        for invalid in (source + source, source.replace("mark_captured_continuation", "changed"), end + start):
            with self.assertRaises(ValueError):
                source_unit.mark_function(invalid)

    def test_distinct_aliases_and_self_cycle_do_not_reproduce_duplicate_slot_forwarding(self):
        self.assertEqual(1, source_unit.mark_expected(0)["sameReference"])
        self.assertEqual(0, source_unit.mark_expected(0)["destinationForwarded"])
        self.assertEqual(1, source_unit.mark_expected(1)["destinationForwarded"])
        self.assertEqual(0, source_unit.mark_expected(2)["allocatedWords"])
        self.assertEqual(1, source_unit.mark_expected(3)["selfRelocated"])
        self.assertEqual(1, source_unit.mark_expected(4)["destinationForwarded"])
        with self.assertRaises(ValueError):
            source_unit.mark_expected(5)

    def test_shutdown_extractor_disambiguates_forward_declaration(self):
        start = "void execute_sync_op_loop\n   ___P((___PSD\n         ___sync_op_struct *sop_ptr,\n         ___BOOL first_iter),\n        (___PSV\n"
        function = start + "body\n"
        source = "void execute_sync_op_loop\nprototype;\n" + function + "\nvoid service_sync_op\nother"
        self.assertEqual(function, source_unit.shutdown_function(source))
        for invalid in (source + source, source.replace("service_sync_op", "changed")):
            with self.assertRaises(ValueError):
                source_unit.shutdown_function(invalid)

    def test_shutdown_variants_are_one_condition_changes(self):
        original = "if (id == 0 && ___err != ___FIX(___NO_ERR))"
        variants = source_unit.shutdown_variants(original)
        self.assertEqual(original, variants["baseline"])
        self.assertEqual(original, variants["pr793"].replace(" && ___GSTATE->setup_state != 2", ""))
        self.assertEqual(original, variants["catcher-only"].replace(" && ___ps->catcher != NULL", ""))
        for invalid in ("changed", original + original):
            with self.assertRaises(ValueError):
                source_unit.shutdown_variants(invalid)

    def test_shutdown_outcomes_distinguish_cleanup_from_conditional_gap(self):
        self.assertEqual(1, source_unit.shutdown_expected("baseline", 1)["invalid"])
        self.assertEqual(0, source_unit.shutdown_expected("pr793", 1)["throws"])
        self.assertEqual(1, source_unit.shutdown_expected("pr793", 2)["invalid"])
        for variant in ("baseline", "pr793", "catcher-only"):
            self.assertEqual(1, source_unit.shutdown_expected(variant, 0)["throws"])
            self.assertEqual(0, source_unit.shutdown_expected(variant, 4)["throws"])
            self.assertEqual(3, source_unit.shutdown_expected(variant, 7)["rounds"])
            self.assertEqual(42, source_unit.shutdown_expected(variant, 7)["error"])

    def test_scan_termination_negative_is_detached_publisher_not_source_claim(self):
        from gambit_smp.check_gambit import MODELS, digest
        trace = json.loads((MODELS / "counterexamples/gc_scan_termination.json").read_text())
        self.assertEqual(digest(MODELS / "gc_scan_termination.qnt"), trace["modelSha256"])
        self.assertFalse(trace["states"][0]["sourceProtocol"])
        violates = lambda s: s["done"] and (s["count"] != 0 or s["queue"] != 0 or s["pending"])
        self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
        self.assertTrue(violates(trace["states"][-1]))

    def test_exact_source_boundaries_fail_closed(self):
        source = "___SCMOBJ ___vm_resize_pstate\nbody\n\nvoid execute_sync_op\nother"
        self.assertEqual("___SCMOBJ ___vm_resize_pstate\nbody\n", source_unit.resize_function(source))
        for invalid in (source + source, source.replace("execute_sync_op", "changed")):
            with self.assertRaises(ValueError):
                source_unit.resize_function(invalid)

    def test_rollback_binding_rejects_wrong_processor_or_late_target_reset(self):
        source = ("___SCMOBJ ___vm_resize_pstate\nwhile (--i >= initial) "
                  "___cleanup_pstate (___PSTATE_FROM_PROCESSOR_ID(i,___vms));"
                  "___vms->mem.target_processor_count_ = initial; BARRIER(); return err;"
                  "\n\nvoid execute_sync_op\n")
        self.assertEqual("passed", source_binding.vm_resize_rollback(source)["vmResizeRollbackSourceBinding"])
        for invalid in (source.replace("___PSTATE_FROM_PROCESSOR_ID(i,___vms)", "ps"),
                        source.replace("___vms->mem.target_processor_count_ = initial; BARRIER();",
                                       "BARRIER(); ___vms->mem.target_processor_count_ = initial;")):
            with self.assertRaises(ValueError):
                source_binding.vm_resize_rollback(invalid)

    def test_frozen_rollback_controls_bind_to_model_and_separate_faults(self):
        from gambit_smp.check_gambit import MODELS, digest
        model_hash = digest(MODELS / "vm_resize_rollback.qnt")
        for invariant in ("cleanupSafe", "targetSafe"):
            trace = json.loads((MODELS / "counterexamples" /
                                ("vm_resize_rollback-" + invariant + ".json")).read_text())
            self.assertEqual(model_hash, trace["modelSha256"])
            self.assertEqual(invariant, trace["invariant"])
            violates = (lambda s: s["invalidCleanup"]) if invariant == "cleanupSafe" else (
                        lambda s: s["phase"] == 2 and s["target"] != s["active"])
            self.assertFalse(any(violates(s) for s in trace["states"][:-1]))
            self.assertTrue(violates(trace["states"][-1]))
            self.assertEqual(invariant == "targetSafe", trace["states"][0]["cleanupRepair"])


if __name__ == "__main__":
    unittest.main()
