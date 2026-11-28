"""Unit tests for Family 7 Compiled-Host Translation Validator and 5 negative controls."""

from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from gambit_smp.compiled_host_validator import (
    run_mutated_host_negative_controls,
    validate_compiled_c,
    validate_compiled_module_files,
)

ROOT = Path(__file__).resolve().parents[1]

VALID_V9_EMITTED_C = """
#define ___LBLCOUNT 42
#include "gambit.h"

___BEGIN_M_HLBL
___DEF_LBL_INTRO(___H_tfib_2d_sample,___REF_SYM(0,___S_tfib_2d_sample),___REF_FAL,6,0)
,___DEF_LBL_PROC_AT(___H_tfib_2d_sample,1,-1,1)
,___DEF_LBL_RET_AT(___H_tfib_2d_sample,___IFD(___RETI,0,0,0x3fL),2)
,___DEF_LBL_RET_AT(___H_tfib_2d_sample,___IFD(___RETN,5,0,0x3L),3)
,___DEF_LBL_RET_AT(___H_tfib_2d_sample,___IFD(___RETI,1,4,0x3f1L),4)
,___DEF_LBL_RET_AT(___H_tfib_2d_sample,___IFD(___RETI,0,0,0x3fL),5)
___END_M_HLBL

#define ___PH_PROC ___H_busy_2d_sleep
___BEGIN_P_COD
___BEGIN_P_SW
___DEF_SLBL(0,___L0_busy_2d_sleep)
   ___IF(___FIXGT(___R1,___FIX(0L)))
   ___GOTO(___L1_busy_2d_sleep)
   ___END_IF
   ___JUMPRET(___R0)
___DEF_GLBL(___L1_busy_2d_sleep)
   ___SET_R1(___FIXSUBP(___R1,___FIX(1L)))
   ___POLL(2)
___DEF_SLBL(2,___L2_busy_2d_sleep)
   ___GOTO(___L0_busy_2d_sleep)
___END_P_SW
___END_P_COD

#define ___PH_PROC ___H_alloc_2d_join_2d_closure
___BEGIN_P_COD
___NEED_HEAP
___BEGIN_P_SW
___DEF_SLBL(1,___L1_alloc_2d_join)
   ___GATE2_OPEN(___ps,"alloc-join",4,___LBL(4),___fp)
___DEF_SLBL(4,___L4_alloc_2d_join)
   ___GATE2_ENTER(___ps,"alloc-join",4,___LBL(4),___fp)
   if(!___group_demand_enter(___ps,&___hp,&___fp,2,9,___LBL(4),&___demand_attempt)){___ps->temp1=___LBL(4);___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}
   ___SET_STK(1,___ALLOC_CLO(4UL))
   ___SET_R2(___CONS(___R1,___R2))
   ___ADJFP(2)
   ___group_demand_commit(___ps,___LBL(4),___demand_attempt);
   ___CHECK_HEAP(5,4096)
___DEF_SLBL(5,___L5_alloc_2d_join)
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD
"""


class CompiledHostValidatorTests(unittest.TestCase):
    def test_valid_v9_emitted_c_passes_all_checks(self):
        report = validate_compiled_c(VALID_V9_EMITTED_C, module_name="tfib_sample.c")
        self.assertTrue(report["passed"], report["violations"])
        self.assertEqual(report["labelCount"], 42)
        self.assertTrue(report["rssGuardSafe"])
        self.assertEqual(report["descriptorCount"], 4)
        self.assertEqual(report["procedureCount"], 2)
        self.assertEqual(report["writeGroupCount"], 1)
        self.assertEqual(report["cyclicLoopCount"], 1)
        self.assertEqual(report["zeroAllocTightLoopCount"], 1)

    def test_five_mutated_host_negative_controls_all_rejected(self):
        result = run_mutated_host_negative_controls(VALID_V9_EMITTED_C)
        self.assertEqual(result["total"], 5)
        self.assertTrue(result["passed"], result["controls"])
        for ctrl in result["controls"]:
            self.assertTrue(ctrl["rejected"], ctrl)
            self.assertTrue(ctrl["passed"], ctrl)

    def test_rejects_label_count_at_or_above_6000_rss_guard(self):
        large = VALID_V9_EMITTED_C.replace("#define ___LBLCOUNT 42", "#define ___LBLCOUNT 6000", 1)
        report = validate_compiled_c(large, module_name="huge.c")
        self.assertFalse(report["passed"])
        self.assertFalse(report["rssGuardSafe"])
        self.assertIn("label-count-exceeds-rss-guard", {v["code"] for v in report["violations"]})

    def test_rejects_insufficient_stack_demand_and_uncommitted_group(self):
        short_stack = VALID_V9_EMITTED_C.replace(
            "___group_demand_enter(___ps,&___hp,&___fp,2,9,",
            "___group_demand_enter(___ps,&___hp,&___fp,1,9,",
            1,
        )
        r_stack = validate_compiled_c(short_stack)
        self.assertFalse(r_stack["passed"])
        self.assertIn("insufficient-stack-demand", {v["code"] for v in r_stack["violations"]})

        uncommitted = VALID_V9_EMITTED_C.replace(
            "___group_demand_commit(___ps,___LBL(4),___demand_attempt);",
            "/* omitted commit */",
            1,
        )
        r_uncommit = validate_compiled_c(uncommitted)
        self.assertFalse(r_uncommit["passed"])
        self.assertIn("uncommitted-write-group", {v["code"] for v in r_uncommit["violations"]})

    def test_rejects_mismatched_check_heap_return_label(self):
        bad_lbl = VALID_V9_EMITTED_C.replace("___CHECK_HEAP(5,4096)", "___CHECK_HEAP(99,4096)", 1)
        report = validate_compiled_c(bad_lbl)
        self.assertFalse(report["passed"])
        self.assertIn("missing-safepoint-reload-or-label-mismatch", {v["code"] for v in report["violations"]})

    def test_file_validator_binds_c_and_o1_digests(self):
        with TemporaryDirectory() as td:
            c_path = Path(td) / "sample.c"
            o1_path = Path(td) / "sample.o1"
            c_path.write_text(VALID_V9_EMITTED_C)
            o1_path.write_bytes(b"\xcf\xfa\xed\xfecompiled-macho-bundle")
            report = validate_compiled_module_files(c_path, o1_path)
            self.assertTrue(report["passed"])
            self.assertEqual(len(report["cSha256"]), 64)
            self.assertEqual(len(report["o1Sha256"]), 64)

    def test_real_vendor_thread_c_descriptors_and_loops_validate(self):
        thread_c = ROOT / "vendor/gambit/lib/_thread.c"
        report = validate_compiled_c(
            thread_c.read_text(errors="replace"),
            module_name="_thread.c",
            require_demand_protocol=False,
        )
        self.assertTrue(report["rssGuardSafe"])
        self.assertGreater(report["descriptorCount"], 100)
        desc_viols = [v for v in report["violations"] if v["code"] == "invalid-frame-descriptor"]
        self.assertEqual(desc_viols, [])

    def test_typed_allocation_macros_are_enforced(self):
        macro_cases = [
            ("___BEGIN_ALLOC_STRING(16)", 3),
            ("___BEGIN_ALLOC_U8VECTOR(16)", 3),
            ("___BEGIN_ALLOC_S16VECTOR(8)", 3),
            ("___BEGIN_ALLOC_F32VECTOR(4)", 3),
            ("___BEGIN_ALLOC_F64VECTOR(4)", 5),
            ("___BEGIN_ALLOC_STRUCTURE(3)", 4),
            ("___BEGIN_ALLOC_VALUES(3)", 4),
            ("___BEGIN_ALLOC_LIST(2,___R1)", 3),
            ("___ADD_LIST_ELEM(1,___R2)", 3),
            ("___SET_R1(___BOX(___R1))", 2),
            ("___BEGIN_ALLOC_SUBTYPED(hd)", 1),
        ]
        for stmt, expected_words in macro_cases:
            with self.subTest(stmt=stmt):
                # Unguarded allocation must be rejected
                unguarded = f"""
#define ___LBLCOUNT 10
#define ___PH_PROC ___H_alloc_case
#define ___PR_ALL ___R_HEAP
___BEGIN_P_COD
___BEGIN_P_SW
___DEF_SLBL(0,___L0_alloc)
   {stmt}
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD
"""
                r_bad = validate_compiled_c(unguarded)
                self.assertFalse(r_bad["passed"], stmt)
                self.assertIn("unguarded-heap-write", {v["code"] for v in r_bad["violations"]})

                # Guarded with exact H passes; H-1 fails
                def _guarded(h_words: int) -> str:
                    return f"""
#define ___LBLCOUNT 10
#define ___PH_PROC ___H_alloc_case
#define ___PR_ALL ___R_HEAP
___BEGIN_P_COD
___BEGIN_P_SW
___DEF_SLBL(1,___L1_alloc)
   if(!___group_demand_enter(___ps,&___hp,&___fp,0,{h_words},___LBL(1),&___demand_attempt)){{___ps->temp1=___LBL(1);___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}}
   {stmt}
   ___group_demand_commit(___ps,___LBL(1),___demand_attempt);
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD
"""

                r_ok = validate_compiled_c(_guarded(expected_words))
                self.assertTrue(r_ok["passed"], (stmt, r_ok["violations"]))
                r_short = validate_compiled_c(_guarded(expected_words - 1))
                self.assertFalse(r_short["passed"], stmt)
                self.assertIn("insufficient-heap-demand", {v["code"] for v in r_short["violations"]})

    def test_branch_aware_if_else_merges_stack_and_catches_escape(self):
        # Mutually exclusive ___IF / ___ELSE branches each using 2 stack words fit in S=2
        branch_ok = """
#define ___LBLCOUNT 12
#define ___PH_PROC ___H_branch_ok
#define ___PR_ALL ___R_HEAP
___BEGIN_P_COD
___BEGIN_P_SW
___DEF_SLBL(1,___L1_branch)
   if(!___group_demand_enter(___ps,&___hp,&___fp,2,3,___LBL(1),&___demand_attempt)){___ps->temp1=___LBL(1);___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}
   ___IF(___EQP(___R1,___FAL))
   ___SET_STK(1,___R1)
   ___ADJFP(2)
   ___SET_R2(___CONS(___R1,___R2))
   ___ELSE
   ___SET_STK(1,___R2)
   ___ADJFP(2)
   ___SET_R2(___CONS(___R2,___R1))
   ___END_IF
   ___group_demand_commit(___ps,___LBL(1),___demand_attempt);
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD
"""
        r_ok = validate_compiled_c(branch_ok)
        self.assertTrue(r_ok["passed"], r_ok["violations"])

        # Escaping a write group via ___GOTO before commit must be rejected
        branch_escape = """
#define ___LBLCOUNT 12
#define ___PH_PROC ___H_branch_escape
#define ___PR_ALL ___R_HEAP
___BEGIN_P_COD
___BEGIN_P_SW
___DEF_SLBL(1,___L1_branch)
   if(!___group_demand_enter(___ps,&___hp,&___fp,1,3,___LBL(1),&___demand_attempt)){___ps->temp1=___LBL(1);___JUMPEXTPRM(___NOTHING,___ps->handler_stack_limit);}
   ___IF(___EQP(___R1,___FAL))
   ___GOTO(___L2_out)
   ___END_IF
   ___SET_R2(___CONS(___R1,___R2))
   ___group_demand_commit(___ps,___LBL(1),___demand_attempt);
___DEF_GLBL(___L2_out)
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD
"""
        r_esc = validate_compiled_c(branch_escape)
        self.assertFalse(r_esc["passed"])
        self.assertIn("uncommitted-write-group-escape", {v["code"] for v in r_esc["violations"]})

    def test_source_bound_cbmc_harness_stays_synced_with_vendor_headers(self):
        harness = (ROOT / "tests/contracts/modern-c/compiled-host/source-bound-macro-equiv/harness.c").read_text()
        sync_specs = [
            ("vendor/gambit/include/_gambit/object_access.h.in", 31, 44, "object_access"),
            ("vendor/gambit/include/_gambit/runtime_protocols.h.in", 1438, 1456, "runtime_protocols_commit"),
            ("vendor/gambit/include/_gambit/runtime_protocols.h.in", 1472, 1482, "runtime_protocols_gate2"),
        ]
        for rel, start, end, tag in sync_specs:
            with self.subTest(tag=tag):
                begin_marker = f"/* BEGIN_SYNC: {rel}:{start}-{end} */\n"
                end_marker = f"\n/* END_SYNC: {tag} */"
                self.assertIn(begin_marker, harness)
                body = harness.split(begin_marker, 1)[1].split(end_marker, 1)[0]
                vendor_lines = (ROOT / rel).read_text().splitlines()[start - 1 : end]
                self.assertEqual(body.splitlines(), vendor_lines,
                                 f"CBMC harness drifted from {rel}:{start}-{end}")


if __name__ == "__main__":
    unittest.main()
