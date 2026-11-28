"""End-to-end integrity and traceability tests for the Modern GC amplification evidence chain."""

import hashlib
import json
from pathlib import Path
import re
import unittest

from gambit_smp import paper_cache as papers


ROOT = papers.ROOT
CHAIN_PATH = ROOT / "dev/modeling/inputs/papers-modern-gc-amplification.json"
RECEIPT_PATH = ROOT / "evidence/modern-gc-amplification-verification-receipt.json"
MANIFEST_PATH = ROOT / "evidence/papers-modern-gc-architecture.json"
LOCK_PATH = ROOT / "evidence/papers-modern-gc-architecture.lock.json"
SYSML_PATH = ROOT / "dev/refactoring/modern-c/models/sysml/modern-gc-amplification.sysml"
SYSML_DEEP_PATH = ROOT / "dev/refactoring/modern-c/models/sysml/amp-algorithms-and-adversarial-contracts.sysml"
SYSML_AMP4_PATH = ROOT / "dev/refactoring/modern-c/models/sysml/amp4-pacing-refc-and-amp1-cut.sysml"
QUINT_PATH = ROOT / "dev/refactoring/modern-c/models/quint/v2/modern_gc_amplification_v2.qnt"
QUINT_DEEP_PATH = ROOT / "dev/refactoring/modern-c/models/quint/v2/amp_deep_protocols_v2.qnt"
QUINT_AMP4_PATH = ROOT / "dev/refactoring/modern-c/models/quint/v2/amp4_pacing_refc_and_lbo_v2.qnt"
LEAN_PATH = ROOT / "dev/refactoring/modern-c/models/lean/ModernGcAmplificationRefinement.lean"
LEAN_DEEP_PATH = ROOT / "dev/refactoring/modern-c/models/lean/AmpDeepAlgorithmsRefinement.lean"
LEAN_AMP4_PATH = ROOT / "dev/refactoring/modern-c/models/lean/Amp4PacingAndRefcRefinement.lean"
CBMC_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/modern_gc_amplification_pso.c"
CBMC_DEEP_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/amp_chase_lev_and_radix_pso.c"
CBMC_AMP4_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/amp4_refc_and_pacing_pso.c"
CBMC_WAVE7_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/wave7_futex_barrier_and_static_gen_pso.c"
CBMC_WAVE8_PATH = ROOT / "dev/refactoring/modern-c/models/cbmc/wave8_segqueue_and_sync_barrier_pso.c"
MATRIX_ORG_PATH = ROOT / "dev/refactoring/modern-c/amp1-amp4-adversarial-verification-matrix.org"
BLUEPRINT_ORG_PATH = ROOT / "dev/refactoring/modern-c/amp1-c23-integration-blueprint.org"
ALGO_TEST_PATH = ROOT / "tests/test_amplification_algorithms.py"


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class ModernGcEvidenceChainTests(unittest.TestCase):
    def test_chain_covers_every_locked_paper_with_matching_sha_and_notes(self):
        chain = json.loads(CHAIN_PATH.read_text())
        self.assertEqual("gambit-smp-paper-evidence-chain.v1", chain["schema"])

        manifest = json.loads(MANIFEST_PATH.read_text())["papers"]
        pins = papers.paper_pins(LOCK_PATH, manifest)

        chain_ids = [entry["id"] for entry in chain["lockedPapers"]]
        self.assertEqual(len(set(chain_ids)), len(chain_ids))
        self.assertEqual(set(pins), set(chain_ids))

        for entry in chain["lockedPapers"]:
            pin = pins[entry["id"]]
            self.assertEqual(pin["pdfSha256"], entry["pdfSha256"])
            self.assertEqual(pin["notes"], entry["notes"])
            self.assertEqual("chapter_complete", entry["readStatus"])
            self.assertTrue((ROOT / entry["notes"]).is_file())
            self.assertTrue(entry["adopted"].strip())
            self.assertTrue(entry["non_import"].strip())
            self.assertTrue(entry["native_acceptance_gate"].strip())

    def test_all_referenced_formal_symbols_and_vendor_anchors_exist(self):
        chain = json.loads(CHAIN_PATH.read_text())
        sysml_text = SYSML_PATH.read_text()
        quint_text = QUINT_PATH.read_text()
        lean_text = LEAN_PATH.read_text()
        cbmc_text = CBMC_PATH.read_text()

        # Zero sorry in Lean proof file
        self.assertIsNone(re.search(r"\bsorry\b", lean_text))

        # SysML admission gate tracks Phase A/B/C merge (c1d51213) and Amp-1 native implementation
        self.assertIn("requirement def AmpWaveAdmissionLaw", sysml_text)
        self.assertIn("attribute :>> phaseABCStabilized = true;", sysml_text)
        self.assertIn("attribute :>> amp1ImplementationAdmitted = true;", sysml_text)

        for entry in chain["lockedPapers"]:
            for req in entry["sysml_requirements"]:
                self.assertRegex(
                    sysml_text,
                    rf"\brequirement\s+def\s+{re.escape(req)}\b",
                    f"missing SysML requirement {req} referenced by {entry['id']}",
                )
            for qrun in entry["quint_obligations"]:
                self.assertRegex(
                    quint_text,
                    rf"\brun\s+{re.escape(qrun)}\b",
                    f"missing Quint run {qrun} referenced by {entry['id']}",
                )
            for thm in entry["lean_theorems"]:
                self.assertRegex(
                    lean_text,
                    rf"\btheorem\s+{re.escape(thm)}\b",
                    f"missing Lean theorem {thm} referenced by {entry['id']}",
                )
            for macro in entry["cbmc_contracts"]:
                self.assertRegex(
                    cbmc_text,
                    rf"\b{re.escape(macro)}\b",
                    f"missing CBMC mutant macro {macro} referenced by {entry['id']}",
                )
            for anchor in entry["vendor_anchors"]:
                self.assertTrue(
                    (ROOT / anchor).is_file(),
                    f"missing vendor anchor {anchor} referenced by {entry['id']}",
                )

    def test_verification_receipt_digests_match_live_files_and_preserve_honesty_boundaries(self):
        receipt = json.loads(RECEIPT_PATH.read_text())
        self.assertEqual("gambit-smp-amplification-verification-receipt.v1", receipt["schema"])

        # Honesty boundaries: Phase A/B/C merged & Amp-1 native Cuts 1A-1C verified on core PBT/LBO,
        # while full nativeRuntimeAdmitted and releaseAdmitted remain strictly false until full TSan/Gerbil/END_OF_CONT closure
        self.assertFalse(receipt["admissionBoundaries"]["nativeRuntimeAdmitted"])
        self.assertFalse(receipt["admissionBoundaries"]["releaseAdmitted"])
        self.assertTrue(receipt["admissionBoundaries"]["phaseABCPrerequisiteSatisfied"])
        self.assertTrue(receipt["admissionBoundaries"]["amp1ImplementationAdmitted"])
        self.assertEqual(36, receipt["verificationResults"]["nativeAmp1RuntimeVerification"]["coreGcAndSrfi230Pbt"]["passed"])
        self.assertEqual(36, receipt["verificationResults"]["nativeAmp2RuntimeVerification"]["coreGcAndSrfi230Pbt"]["passed"])
        self.assertEqual(36, receipt["verificationResults"]["nativeAmp3RuntimeVerification"]["coreGcAndSrfi230Pbt"]["passed"])
        self.assertEqual(50, receipt["verificationResults"]["nativeAmp3RuntimeVerification"]["c14P8ZeroCrashStress"]["v5Passed"])
        self.assertEqual(20, receipt["verificationResults"]["nativeAmp3RuntimeVerification"]["c14P8ZeroCrashStress"]["v6FinalPassed"])
        self.assertEqual(36, receipt["verificationResults"]["nativeAmp4RuntimeVerification"]["coreGcAndSrfi230Pbt"]["passed"])
        self.assertEqual(20, receipt["verificationResults"]["nativeAmp4RuntimeVerification"]["c14P8ZeroCrashStress"]["passed"])
        self.assertEqual(6, receipt["verificationResults"]["nativeAmp4RuntimeVerification"]["adversarialVerify"]["passed"])

        # Wave 5 native runtime hardening, TSan/ASan+UBSan qualification, and 104/104 unified matrix
        w5 = receipt["verificationResults"]["nativeRuntimeHardeningAndSanitizerQualification"]
        self.assertEqual(10, w5["nativeClangTsan"]["passed"])
        self.assertEqual(0, w5["nativeClangTsan"]["totalWarnings"])
        self.assertEqual(10, w5["nativeClangAsanUbsan"]["passed"])
        self.assertEqual(0, w5["nativeClangAsanUbsan"]["totalAsanErrors"])
        self.assertEqual(0, w5["nativeClangAsanUbsan"]["totalUbsanErrors"])
        self.assertEqual(104, w5["unifiedMulticoreMatrix"]["totalPassed"])
        self.assertEqual(104, w5["unifiedMulticoreMatrix"]["totalCases"])

        # Wave 6 remembered-set parallelism, gc_is_dest race fix, 11/11 TSan/ASan, 108/108 matrix, and Gerbil v0.19 SMP build+audit
        w6 = receipt["verificationResults"]["wave6RememberedSetAndGerbilQualification"]
        self.assertEqual(11, w6["nativeClangTsan"]["passed"])
        self.assertEqual(0, w6["nativeClangTsan"]["totalWarnings"])
        self.assertEqual(11, w6["nativeClangAsanUbsan"]["passed"])
        self.assertEqual(0, w6["nativeClangAsanUbsan"]["totalAsanErrors"])
        self.assertEqual(0, w6["nativeClangAsanUbsan"]["totalUbsanErrors"])
        self.assertEqual(108, w6["unifiedMulticoreMatrix"]["totalPassed"])
        self.assertEqual(108, w6["unifiedMulticoreMatrix"]["totalCases"])
        self.assertEqual(8, w6["gerbilV019SmpQualification"]["buildStagesPassed"])
        self.assertEqual(8, w6["gerbilV019SmpQualification"]["buildStagesTotal"])
        self.assertTrue(w6["gerbilV019SmpQualification"]["originalGerbilSourceUnchanged"])
        self.assertEqual(45, w6["gerbilV019SmpQualification"]["smpQualification"]["p4Passed"])
        self.assertEqual(45, w6["gerbilV019SmpQualification"]["smpQualification"]["p12Passed"])
        self.assertEqual(0, w6["gerbilV019SmpQualification"]["smpSpecificFailures"])

        # Every tracked artifact SHA-256 digest in the receipt must match the file on disk
        artifacts = receipt["artifactSha256"]
        self.assertGreaterEqual(len(artifacts), 15)
        for rel_path, expected_sha in artifacts.items():
            full_path = ROOT / rel_path
            self.assertTrue(full_path.is_file(), f"receipt artifact missing: {rel_path}")
            self.assertRegex(expected_sha, r"^[0-9a-f]{64}$")
            self.assertEqual(
                expected_sha,
                sha256_file(full_path),
                f"SHA-256 drift detected for {rel_path}; regenerate receipt after edits",
            )

        # Every PDF digest in receipt matches the additive lock
        lock_pins = {p["id"]: p["pdfSha256"] for p in json.loads(LOCK_PATH.read_text())["papers"]}
        self.assertEqual(lock_pins, receipt["lockedPdfSha256"])

    def test_non_pdf_backlog_disjoint_from_locked_papers_and_legacy_lock(self):
        chain = json.loads(CHAIN_PATH.read_text())
        locked_ids = {p["id"] for p in chain["lockedPapers"]}
        legacy_ids = {p["id"] for p in json.loads((ROOT / "evidence/papers.lock.json").read_text())["papers"]}
        backlog_ids = {p["id"] for p in chain["remainingNonPdfBacklog"]}

        self.assertEqual(set(), locked_ids & legacy_ids)
        self.assertEqual(set(), locked_ids & backlog_ids)
        self.assertEqual(set(), legacy_ids & backlog_ids)
        for item in chain["remainingNonPdfBacklog"]:
            self.assertIn(
                item["status"],
                ("metadata_only_paywalled", "metadata_only_tls_unreachable", "external_html_spec"),
            )

    def test_round2_deep_adversarial_models_and_matrix_symbols_exist(self):
        sysml_deep = SYSML_DEEP_PATH.read_text()
        quint_deep = QUINT_DEEP_PATH.read_text()
        lean_deep = LEAN_DEEP_PATH.read_text()
        cbmc_deep = CBMC_DEEP_PATH.read_text()
        matrix_org = MATRIX_ORG_PATH.read_text()
        algo_tests = ALGO_TEST_PATH.read_text()

        # Zero sorry in upgraded Lean 4 N-heap & deep proofs file
        self.assertIsNone(re.search(r"\bsorry\b", lean_deep))

        # Round-2 SysML v2 package & all 6 deep requirement defs
        self.assertIn("package GambitAmpAlgorithmsAndAdversarial", sysml_deep)
        for req in (
            "LocalEscapeBlackAllocAndEqIdentityLaw",
            "RadixDirectoryPublishAndQuiescentRetireLaw",
            "PrefetchRingAddrmapTerminationLaw",
            "ChaseLevWeakMemoryFenceLaw",
            "StaticGenDirtyBarrierAndOverflowImmixLaw",
            "MemBalancerAdversarialBurstSafetyLaw",
        ):
            self.assertRegex(sysml_deep, rf"\brequirement\s+def\s+{re.escape(req)}\b")
            self.assertIn(req, matrix_org)

        # Round-2 Quint V2 deep protocol runs (1 happy path + 8 mutation-killers)
        for qrun in (
            "happyPathDeepProtocolsTest",
            "mutant1LocalPromoteUnmarkedDuringSatbTest",
            "mutant2DuplicateLocalRootBreaksEqTest",
            "mutant3EscapeBudgetExhaustedWithoutFallbackTest",
            "mutant4RadixPublishWithoutInitTest",
            "mutant5RetireMsectionWhileReaderActiveTest",
            "mutant6MarkTerminatesWithNonEmptyAddrmapOrRingTest",
            "mutant7StaticMutationWithoutDirtyBarrierTest",
            "mutant8OverflowOverwritesLiveOrPinnedLineTest",
        ):
            self.assertRegex(quint_deep, rf"\brun\s+{re.escape(qrun)}\b")

        # Round-2 Lean 4 unbounded N-heap + deep protocol theorems
        for thm in (
            "membalancer_n_heap_cauchy_schwarz_optimality",
            "mark_work_conservation_stack_to_ring",
            "mark_work_conservation_stack_to_addrmap",
            "mark_termination_requires_all_three_empty",
            "local_promote_preserves_satb_black",
            "forwarding_preserves_scheme_eq_identity",
            "radix_two_level_index_bijection",
            "static_dirty_barrier_preserves_nonstatic_child",
            "immix_overflow_disjoint_from_recycled_live",
        ):
            self.assertRegex(lean_deep, rf"\btheorem\s+{re.escape(thm)}\b")

        # Round-2 CBMC PSO 5 weak-memory mutants
        for macro in (
            "MUTANT_CHASE_LEV_DROP_PUSH_RELEASE",
            "MUTANT_CHASE_LEV_DROP_TAKE_FENCE",
            "MUTANT_CHASE_LEV_DROP_STEAL_FENCE",
            "MUTANT_RADIX_DROP_PUBLISH_FENCE",
            "MUTANT_LOCAL_PROMOTE_UNMARKED_SATB",
        ):
            self.assertIn(macro, cbmc_deep)
            self.assertIn(macro, matrix_org)

        # All 8 executable algorithm verifiers/fuzzers referenced in the matrix exist
        for fn in (
            "test_membalancer_8proc_adversarial_pareto",
            "test_ocaml5_prefetch_ring_and_addrmap_completeness",
            "test_immix_multihole_and_overflow_allocator",
            "test_lxr_satb_and_line_epoch_adversarial_fuzzer",
            "test_stack_watermark_with_multishot_callcc_fuzzer",
            "test_escape_forwarding_preserves_eq_identity",
            "test_radix_two_level_bijection_and_retire",
            "test_static_gen_dirty_barrier_fuzzer",
        ):
            self.assertRegex(algo_tests, rf"\bdef\s+{re.escape(fn)}\b")
            self.assertIn(fn, matrix_org)

    def test_round3_amp1_cut_amp4_formal_and_c23_symbols_exist(self):
        sysml_amp4 = SYSML_AMP4_PATH.read_text()
        quint_amp4 = QUINT_AMP4_PATH.read_text()
        lean_amp4 = LEAN_AMP4_PATH.read_text()
        cbmc_amp4 = CBMC_AMP4_PATH.read_text()
        blueprint = BLUEPRINT_ORG_PATH.read_text()

        # Zero sorry in Amp-4 Lean 4 proof module
        self.assertIsNone(re.search(r"\bsorry\b", lean_amp4))

        # Round-3 SysML v2 package & all 4 requirement defs
        self.assertIn("package GambitAmp4PacingRefcAndAmp1Cut", sysml_amp4)
        for req in (
            "Amp1DropInC23CutLaw",
            "OffHeapImmutableRefcBinaryLaw",
            "GlobalMajorPacingAndPhantomBytesLaw",
            "LboMulticoreAdmissionGateLaw",
        ):
            self.assertRegex(sysml_amp4, rf"\brequirement\s+def\s+{re.escape(req)}\b")

        # Round-3 Quint V2 Amp-4 runs (1 happy path + 6 mutation-killers)
        for qrun in (
            "happyPathAmp4PacingAndRefcTest",
            "mutant1RefcFreeWhileReaderAliveTest",
            "mutant2MutableBinarySharedOffHeapTest",
            "mutant3RefcDropWithoutReleaseFenceTest",
            "mutant4AllocExceedsLimitWithoutWorkSliceTest",
            "mutant5PhantomBytesIgnoredOomTest",
            "mutant6PacingCounterNonAtomicDriftTest",
        ):
            self.assertRegex(quint_amp4, rf"\brun\s+{re.escape(qrun)}\b")

        # Round-3 Lean 4 Amp-4 theorems
        for thm in (
            "refc_positive_blocks_free",
            "refc_zero_implies_unique_last_drop",
            "immutable_tag_required_for_offheap_share",
            "pacing_step_preserves_invariant",
            "pacing_rate_guarantees_mark_completion_before_limit",
            "phantom_bytes_included_prevents_hidden_rss_overflow",
            "ignoring_phantom_bytes_permits_arbitrary_rss_overflow",
            "lbo_pareto_dominance_transitive",
            "lbo_pareto_dominance_asymmetric",
        ):
            self.assertRegex(lean_amp4, rf"\btheorem\s+{re.escape(thm)}\b")

        # Round-3 CBMC PSO 4 weak-memory mutants
        for macro in (
            "MUTANT_REFC_DROP_WITHOUT_RELEASE",
            "MUTANT_REFC_FREE_WITHOUT_ACQUIRE",
            "MUTANT_REFC_MUTATE_SHARED_BINARY",
            "MUTANT_PACING_NONATOMIC_WORK_PUBLISH",
        ):
            self.assertIn(macro, cbmc_amp4)
            self.assertIn(macro, blueprint)

        # Native Amp-4 runtime C23 anchors exist in vendor/gambit
        refc_src = (ROOT / "vendor/gambit/lib/_mem/refc-binary.inc").read_text()
        cm_src = (ROOT / "vendor/gambit/lib/_mem/concurrent-major.inc").read_text()
        for sym in (
            "___gc_register_phantom_bytes",
            "___gc_refc_bin_create",
            "___gc_refc_bin_share",
            "___gc_refc_bin_freeze",
            "___gc_refc_bin_release",
            "___gc_refc_bin_wrap",
            "___REFC_BIN_FLAG_IMMUTABLE",
        ):
            self.assertIn(sym, refc_src)
        for sym in (
            "gc_major_pace_alloc_words",
            "gc_pacing_sample_mutator",
            "gc_pacing_on_major_gc",
            "___gc_pacing_stats",
        ):
            self.assertIn(sym, cm_src)

        # Wave 5 native C23 TSan/UBSan hardening anchors exist in vendor/gambit
        stk_ops = (ROOT / "vendor/gambit/include/_gambit/stack_operations.h.in").read_text()
        self.assertIn("fp[-___CAST(___SSIZE_T,(fpo))]", stk_ops)
        gvm_ops = (ROOT / "vendor/gambit/include/_gambit/gvm_operations.h.in").read_text()
        self.assertIn("#define ___VECTORREF(v,i)___WORD_LOAD_RELAXED(", gvm_ops)
        setup_src = (ROOT / "vendor/gambit/lib/setup.c").read_text()
        self.assertIn("__atomic_compare_exchange_n (&___GSTATE->setup_params.debug_settings", setup_src)
        rc_alloc = (ROOT / "vendor/gambit/lib/_mem/rc-allocation.inc").read_text()
        self.assertIn("___WORD_STORE_RELAXED(&___rest_before_collect_pops", rc_alloc)
        parallel_src = (ROOT / "vendor/gambit/lib/gambit/parallel/parallel.scm").read_text()
        self.assertIn("(atomic-fxbox-set! (macro-work-stealing-deque-bottom q) (##fx+ b 1) 'release)", parallel_src)

        # Wave 6 remembered-set card-map, value-aware write barrier, and gc_is_dest Release-Acquire anchors
        cfg_src = (ROOT / "vendor/gambit/lib/_mem/configuration.inc").read_text()
        self.assertIn("___STILL_FLAG_CARD_MAP", cfg_src)
        self.assertIn("still_card_bitmap_words", cfg_src)
        gen_src = (ROOT / "vendor/gambit/lib/_mem/generational.inc").read_text()
        self.assertIn("___gc_write_barrier_slow_val", gen_src)
        self.assertIn("scan_mature_still_card_strip", gen_src)
        self.assertIn("__atomic_load_n(&sec->gc_is_dest, __ATOMIC_ACQUIRE)", gen_src)
        hs_src = (ROOT / "vendor/gambit/lib/_mem/heap-sections.inc").read_text()
        self.assertIn("__atomic_store_n(&section->gc_is_dest, new_dest, __ATOMIC_RELEASE)", hs_src)
        cr_src = (ROOT / "vendor/gambit/lib/_mem/copy-reservations.inc").read_text()
        self.assertIn("__atomic_load_n(&section->gc_is_dest, __ATOMIC_ACQUIRE)", cr_src)
        cp_src = (ROOT / "vendor/gambit/lib/_mem/copy-planning.inc").read_text()
        self.assertIn("fast_minor_pre_nb", cp_src)

        # Wave 7 CBMC PSO weak-memory mutants + native OS futex, spare pool, and GEN_STATIC anchors
        cbmc_w7 = CBMC_WAVE7_PATH.read_text()
        for macro in (
            "MUTANT_FUTEX_DROP_WAKE_FENCE",
            "MUTANT_FUTEX_DROP_WAITER_SEQ_CST",
            "MUTANT_STATIC_CLEAR_DIRTY_WITH_NONSTATIC_REF",
            "MUTANT_STATIC_SKIP_MATURE_WRITE_BARRIER",
        ):
            self.assertIn(macro, cbmc_w7)
            self.assertIn(macro, blueprint)

        life_h = (ROOT / "vendor/gambit/lib/lifecycle.h").read_text()
        self.assertIn("___gc_futex_wait_u32", life_h)
        self.assertIn("___gc_futex_wake_all_u32", life_h)
        ms_h = (ROOT / "vendor/gambit/include/_gambit/memory_state.h.in").read_text()
        for sym in (
            "major_static_gen",
            "major_survive_count",
            "static_major_dirty",
            "msection_spare_head_",
            "nb_msections_static_",
            "major_static_skipped_sections_",
        ):
            self.assertIn(sym, ms_h)
        mv_src = (ROOT / "vendor/gambit/lib/_mem/movable-sections.inc").read_text()
        for sym in ("msection_spare_pool_pop", "msection_spare_pool_push", "msection_spare_pool_purge", "MADV_FREE_REUSABLE"):
            self.assertIn(sym, mv_src)
        obj_src = (ROOT / "vendor/gambit/lib/_mem/object-scanning.inc").read_text()
        self.assertIn("has_reached_gc_hash_tables", obj_src)
        for sym in ("major_scan_dirty_static_section", "major_initial_mark_seed_static_dirty_parallel"):
            self.assertIn(sym, cm_src)

        receipt = json.loads(RECEIPT_PATH.read_text())
        w7 = receipt["verificationResults"]["wave7FutexBarrierZeroMmapAndStaticGen"]
        self.assertEqual(w7["cbmcWave7PsoSafe"]["status"], "VERIFICATION_SUCCESSFUL")
        self.assertEqual(w7["cbmcWave7PsoMutants"]["killed"], 4)
        self.assertEqual(w7["runtimeTsanQualification"]["passed"], 12)
        self.assertEqual(w7["runtimeTsanQualification"]["totalTsanWarnings"], 0)
        self.assertEqual(w7["runtimeAsanUbsanQualification"]["passed"], 12)
        self.assertEqual(w7["runtimeAsanUbsanQualification"]["totalAsanErrors"], 0)
        self.assertEqual(w7["runtimeAsanUbsanQualification"]["totalUbsanErrors"], 0)
        self.assertEqual(w7["unifiedMulticoreMatrixAndStress"]["passed"], 112)

        # Wave 8 CBMC PSO weak-memory mutants + native lock-free concurrent, futex sync, anti-convoy ticketlock, and C23 atomic header anchors
        cbmc_w8 = CBMC_WAVE8_PATH.read_text()
        for macro in (
            "MUTANT_SEGQ_DROP_SLOT_RELEASE",
            "MUTANT_SEGQ_DROP_NEXT_RELEASE",
            "MUTANT_SYNCBAR_DROP_WAKE_FENCE",
            "MUTANT_SYNCBAR_DROP_PAYLOAD_RELEASE",
        ):
            self.assertIn(macro, cbmc_w8)
            self.assertIn(macro, blueprint)

        ps_h = (ROOT / "vendor/gambit/include/_gambit/processor_state.h.in").read_text()
        for sym in ("sync_futex_seq", "sync_futex_waiters"):
            self.assertIn(sym, ps_h)
            self.assertIn(sym, setup_src)
        self.assertIn("sync_bar_out_sop", life_h)
        self.assertIn("sync_bar_waiters", life_h)
        self.assertIn("sync_bar_out_sop[slot]", setup_src)
        self.assertIn("___GC_MSECTION_SPARE_MAX", mv_src)
        self.assertIn("___GC_MSECTION_SPARE_MIN", mv_src)
        obj_acc = (ROOT / "vendor/gambit/include/_gambit/object_access.h.in").read_text()
        self.assertIn("___WORD_STORE_RELAXED(&___hp[0],___MAKE_HD_WORDS(n,___sVECTOR))", obj_acc)
        conc_src = (ROOT / "vendor/gambit/lib/gambit/concurrent/concurrent.scm").read_text()
        for sym in ("%lfq-enq-fast!", "%lfq-deq-fast!", "%ct-fast-fixnum-ref", "%ws-pop-raw!", "%ws-steal-raw!"):
            self.assertIn(sym, conc_src)

        w8 = receipt["verificationResults"]["wave8LockFreeConcurrentAndSyncFutex"]
        self.assertEqual(w8["cbmcWave8PsoSafe"]["status"], "VERIFICATION_SUCCESSFUL")
        self.assertEqual(w8["cbmcWave8PsoMutants"]["killed"], 4)
        self.assertEqual(w8["runtimeTsanQualification"]["passed"], 13)
        self.assertEqual(w8["runtimeTsanQualification"]["totalTsanWarnings"], 0)
        self.assertEqual(w8["runtimeAsanUbsanQualification"]["passed"], 13)
        self.assertEqual(w8["runtimeAsanUbsanQualification"]["totalAsanErrors"], 0)
        self.assertEqual(w8["runtimeAsanUbsanQualification"]["totalUbsanErrors"], 0)
        self.assertEqual(w8["unifiedMulticoreMatrixAndStress"]["passed"], 116)
        self.assertFalse(receipt["admissionBoundaries"]["nativeRuntimeAdmitted"])
        self.assertFalse(receipt["admissionBoundaries"]["releaseAdmitted"])


if __name__ == "__main__":
    unittest.main()
