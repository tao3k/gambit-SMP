#ifdef ___LINKER_INFO
; File: "callbackrelocation.c", produced by Gambit v4.9.8
(
409008
(C)
"callbackrelocation"
("callbackrelocation")
()
(("callbackrelocation"))
( #|*/"*/"symbols|#
"callbackrelocation"
"callbackrelocation#"
"callbackrelocation#0"
) #|*/"*/"symbols|#
( #|*/"*/"keywords|#
) #|*/"*/"keywords|#
( #|*/"*/"globals-s-d|#
"callbackrelocation#"
"callbackrelocation#0"
"remember-address!"
) #|*/"*/"globals-s-d|#
( #|*/"*/"globals-s-nd|#
"callback-return-relocation"
) #|*/"*/"globals-s-nd|#
( #|*/"*/"globals-ns|#
"##c-return-on-other-processor-hook-set!"
"##current-processor-id"
"##gc"
"##thread-migrate-to!"
"="
"make-vector"
) #|*/"*/"globals-ns|#
( #|*/"*/"meta-info|#
) #|*/"*/"meta-info|#
)
#else
#define ___VERSION 409008
#define ___MODULE_NAME "callbackrelocation"
#define ___LINKER_ID ___LNK_callbackrelocation
#define ___MH_PROC ___H_callbackrelocation
#define ___SCRIPT_LINE 0
#define ___SYMCOUNT 3
#define ___GLOCOUNT 10
#define ___SUPCOUNT 4
#define ___SUBCOUNT 3
#define ___LBLCOUNT 22
#define ___MODDESCR ___REF_SUB(0)
#include "gambit.h"

___NEED_SYM(___S_callbackrelocation)
___NEED_SYM(___S_callbackrelocation_23_)
___NEED_SYM(___S_callbackrelocation_23_0)

___NEED_GLO(___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
___NEED_GLO(___G__23__23_current_2d_processor_2d_id)
___NEED_GLO(___G__23__23_gc)
___NEED_GLO(___G__23__23_thread_2d_migrate_2d_to_21_)
___NEED_GLO(___G__3d_)
___NEED_GLO(___G_callback_2d_return_2d_relocation)
___NEED_GLO(___G_callbackrelocation_23_)
___NEED_GLO(___G_callbackrelocation_23_0)
___NEED_GLO(___G_make_2d_vector)
___NEED_GLO(___G_remember_2d_address_21_)

___BEGIN_SYM
___DEF_SYM(0,___S_callbackrelocation,"callbackrelocation")
___DEF_SYM(1,___S_callbackrelocation_23_,"callbackrelocation#")
___DEF_SYM(2,___S_callbackrelocation_23_0,"callbackrelocation#0")
___END_SYM

#define ___SYM_callbackrelocation ___SYM(0,___S_callbackrelocation)
#define ___SYM_callbackrelocation_23_ ___SYM(1,___S_callbackrelocation_23_)
#define ___SYM_callbackrelocation_23_0 ___SYM(2,___S_callbackrelocation_23_0)

___BEGIN_GLO
___DEF_GLO(0,"callback-return-relocation")
___DEF_GLO(1,"callbackrelocation#")
___DEF_GLO(2,"callbackrelocation#0")
___DEF_GLO(3,"remember-address!")
___DEF_GLO(4,"##c-return-on-other-processor-hook-set!")

___DEF_GLO(5,"##current-processor-id")
___DEF_GLO(6,"##gc")
___DEF_GLO(7,"##thread-migrate-to!")
___DEF_GLO(8,"=")
___DEF_GLO(9,"make-vector")
___END_GLO

#define ___GLO_callback_2d_return_2d_relocation ___GLO(0,___G_callback_2d_return_2d_relocation)
#define ___PRM_callback_2d_return_2d_relocation ___PRM(0,___G_callback_2d_return_2d_relocation)
#define ___GLO_callbackrelocation_23_ ___GLO(1,___G_callbackrelocation_23_)
#define ___PRM_callbackrelocation_23_ ___PRM(1,___G_callbackrelocation_23_)
#define ___GLO_callbackrelocation_23_0 ___GLO(2,___G_callbackrelocation_23_0)
#define ___PRM_callbackrelocation_23_0 ___PRM(2,___G_callbackrelocation_23_0)
#define ___GLO_remember_2d_address_21_ ___GLO(3,___G_remember_2d_address_21_)
#define ___PRM_remember_2d_address_21_ ___PRM(3,___G_remember_2d_address_21_)
#define ___GLO__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_ ___GLO(4,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
#define ___PRM__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_ ___PRM(4,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
#define ___GLO__23__23_current_2d_processor_2d_id ___GLO(5,___G__23__23_current_2d_processor_2d_id)
#define ___PRM__23__23_current_2d_processor_2d_id ___PRM(5,___G__23__23_current_2d_processor_2d_id)
#define ___GLO__23__23_gc ___GLO(6,___G__23__23_gc)
#define ___PRM__23__23_gc ___PRM(6,___G__23__23_gc)
#define ___GLO__23__23_thread_2d_migrate_2d_to_21_ ___GLO(7,___G__23__23_thread_2d_migrate_2d_to_21_)
#define ___PRM__23__23_thread_2d_migrate_2d_to_21_ ___PRM(7,___G__23__23_thread_2d_migrate_2d_to_21_)
#define ___GLO__3d_ ___GLO(8,___G__3d_)
#define ___PRM__3d_ ___PRM(8,___G__3d_)
#define ___GLO_make_2d_vector ___GLO(9,___G_make_2d_vector)
#define ___PRM_make_2d_vector ___PRM(9,___G_make_2d_vector)

___DEF_SUB_VEC(___X0,6UL)
               ___VEC1(___REF_SUB(1))
               ___VEC1(___REF_SUB(2))
               ___VEC1(___REF_NUL)
               ___VEC1(___REF_FIX(1))
               ___VEC1(___REF_PRC(1))
               ___VEC1(___REF_FAL)
               ___VEC0
___DEF_SUB_VEC(___X1,1UL)
               ___VEC1(___REF_SYM(0,___S_callbackrelocation))
               ___VEC0
___DEF_SUB_VEC(___X2,0UL)
               ___VEC0

___BEGIN_SUB
 ___DEF_SUB(___X0)
,___DEF_SUB(___X1)
,___DEF_SUB(___X2)
___END_SUB


#define ___C_LBL_callback_return_relocation 6

static unsigned long long callback_raw_before = 0;
unsigned long long callback_payload_before(void) { return callback_raw_before; }
 ___SCMOBJ callback_return_relocation ___P((int ___arg1,int ___arg2),(___arg1,___arg2)
int ___arg1;
int ___arg2;)
{
#define ___NARGS 2
___BEGIN_SFUN_SCMOBJ(___MLBL(___C_LBL_callback_return_relocation))
___BEGIN_SFUN_ARG(1,___ARG1)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___BEGIN_SFUN_ARG(2,___ARG2)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___BEGIN_SFUN_BODY
___SFUN_ARG(1,___ARG1)
___SFUN_ARG(2,___ARG2)
___SFUN_CALL_SCMOBJ
___SFUN_SET_RESULT_SCMOBJ
___END_SFUN_BODY
___END_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___END_SFUN_ARG(2)
___END_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___END_SFUN_ARG(1)
___SFUN_ERROR_SCMOBJ
___SFUN_SET_RESULT_SCMOBJ
___END_SFUN_SCMOBJ
return ___result;
#undef ___NARGS
}

#define ___CFUN_SELECT(inl,ool)ool
#define ___NARGS 1
___BEGIN_CFUN_VOID(___callbackrelocation_23_0)
#define ___ARG1 ___CFUN_ARG(1)
___BEGIN_CFUN_ARG_SCMOBJ(1)
#define ___arg1 ___ARG1
___BEGIN_CFUN_BODY
#undef ___AT_END
#define ___return goto ___return_callbackrelocation_23_0
callback_raw_before = (unsigned long long)___arg1;
___return_callbackrelocation_23_0:;
#undef ___return
#ifndef ___AT_END
#define ___AT_END
#endif
___CFUN_SET_RESULT_VOID
___END_CFUN_BODY
#undef ___arg1
___END_CFUN_ARG_SCMOBJ(1)
#undef ___ARG1
___CFUN_ERROR_VOID
___END_CFUN_VOID
#undef ___NARGS
#undef ___CFUN_SELECT


#undef ___MD_ALL
#define ___MD_ALL ___D_HEAP ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R4
#undef ___MR_ALL
#define ___MR_ALL ___R_HEAP ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R4
#undef ___MW_ALL
#define ___MW_ALL ___W_HEAP ___W_FP ___W_R0 ___W_R1 ___W_R2 ___W_R4
___BEGIN_M_COD
___BEGIN_M_HLBL
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callbackrelocation_23_)
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callbackrelocation_23_0)
___DEF_M_HLBL(___L1_callbackrelocation_23_0)
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L1_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L2_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L3_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L4_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L5_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L6_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L7_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L8_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L9_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L10_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L11_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L12_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L13_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L14_callback_2d_return_2d_relocation)
___DEF_M_HLBL(___L15_callback_2d_return_2d_relocation)
___END_M_HLBL

___BEGIN_M_SW

#undef ___PH_PROC
#define ___PH_PROC ___H_callbackrelocation_23_
#undef ___PH_LBL0
#define ___PH_LBL0 1
#undef ___PD_ALL
#define ___PD_ALL ___D_R0 ___D_R1
#undef ___PR_ALL
#define ___PR_ALL ___R_R0 ___R_R1
#undef ___PW_ALL
#define ___PW_ALL ___W_R1
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0_callbackrelocation_23_)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callbackrelocation_23_)
   ___IF_NARGS_EQ(0,___NOTHING)
   ___WRONG_NARGS(0,0,0,0)
___DEF_GLBL(___L_callbackrelocation_23_)
   ___SET_GLO(3,___G_remember_2d_address_21_,___PRC(3))
   ___SET_GLO(0,___G_callback_2d_return_2d_relocation,___PRC(6))
   ___SET_R1(___VOID)
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD

#undef ___PH_PROC
#define ___PH_PROC ___H_callbackrelocation_23_0
#undef ___PH_LBL0
#define ___PH_LBL0 3
#undef ___PD_ALL
#define ___PD_ALL ___D_FP ___D_R0 ___D_R1
#undef ___PR_ALL
#define ___PR_ALL ___R_FP ___R_R0 ___R_R1
#undef ___PW_ALL
#define ___PW_ALL ___W_FP ___W_R0
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0_callbackrelocation_23_0)
___DEF_P_HLBL(___L1_callbackrelocation_23_0)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callbackrelocation_23_0)
   ___IF_NARGS_EQ(1,___NOTHING)
   ___WRONG_NARGS(0,1,0,0)
___DEF_GLBL(___L_callbackrelocation_23_0)
   ___SET_STK(1,___R1)
   ___SET_STK(2,___R0)
   ___SET_R0(___LBL(1))
   ___ADJFP(8)
   ___CFUN_OOL(___callbackrelocation_23_0)
   ___JUMPRET(___R0)
___DEF_SLBL(1,___L1_callbackrelocation_23_0)
   ___ADJFP(-8)
   ___JUMPRET(___STK(2))
___END_P_SW
___END_P_COD

#undef ___PH_PROC
#define ___PH_PROC ___H_callback_2d_return_2d_relocation
#undef ___PH_LBL0
#define ___PH_LBL0 6
#undef ___PD_ALL
#define ___PD_ALL ___D_HEAP ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R4
#undef ___PR_ALL
#define ___PR_ALL ___R_HEAP ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R4
#undef ___PW_ALL
#define ___PW_ALL ___W_HEAP ___W_FP ___W_R0 ___W_R1 ___W_R2 ___W_R4
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L1_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L2_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L3_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L4_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L5_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L6_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L7_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L8_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L9_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L10_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L11_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L12_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L13_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L14_callback_2d_return_2d_relocation)
___DEF_P_HLBL(___L15_callback_2d_return_2d_relocation)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callback_2d_return_2d_relocation)
   ___IF_NARGS_EQ(2,___NOTHING)
   ___WRONG_NARGS(0,2,0,0)
___DEF_GLBL(___L_callback_2d_return_2d_relocation)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R1)
   ___SET_STK(3,___ALLOC_CLO(1UL))
   ___BEGIN_SETUP_CLO(1,___STK(3),11)
   ___ADD_CLO_ELEM(0,___R2)
   ___END_SETUP_CLO(1)
   ___SET_R1(___STK(3))
   ___ADJFP(8)
   ___CHECK_HEAP(1,4096)
___DEF_SLBL(1,___L1_callback_2d_return_2d_relocation)
   ___POLL(2)
___DEF_SLBL(2,___L2_callback_2d_return_2d_relocation)
   ___SET_R0(___LBL(3))
   ___JUMPGLOSAFE(___SET_NARGS(1),4,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
___DEF_SLBL(3,___L3_callback_2d_return_2d_relocation)
   ___IF(___NOT(___EQP(___GLO_make_2d_vector,___PRM_make_2d_vector)))
   ___GOTO(___L25_callback_2d_return_2d_relocation)
   ___END_IF
   ___MAKEVECTORSMALL2(___FIX(32L),___FIX(42L))
   ___SET_R1(___GET_SMALL_ALLOC)
   ___CHECK_HEAP(4,4096)
___DEF_SLBL(4,___L4_callback_2d_return_2d_relocation)
   ___GOTO(___L16_callback_2d_return_2d_relocation)
___DEF_SLBL(5,___L5_callback_2d_return_2d_relocation)
___DEF_GLBL(___L16_callback_2d_return_2d_relocation)
   ___SET_STK(-5,___R1)
   ___SET_R0(___LBL(6))
   ___JUMPGLOSAFE(___SET_NARGS(1),3,___G_remember_2d_address_21_)
___DEF_SLBL(6,___L6_callback_2d_return_2d_relocation)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L24_callback_2d_return_2d_relocation)
   ___END_IF
   ___IF(___NOT(___FIXNUMP(___STK(-6))))
   ___GOTO(___L24_callback_2d_return_2d_relocation)
   ___END_IF
   ___IF(___FIXEQ(___STK(-6),___FIX(1L)))
   ___GOTO(___L17_callback_2d_return_2d_relocation)
   ___END_IF
   ___GOTO(___L20_callback_2d_return_2d_relocation)
___DEF_SLBL(7,___L7_callback_2d_return_2d_relocation)
   ___IF(___NOT(___NOTFALSEP(___R1)))
   ___GOTO(___L20_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L17_callback_2d_return_2d_relocation)
   ___IF(___NOT(___EQP(___GLO__23__23_current_2d_processor_2d_id,___PRM__23__23_current_2d_processor_2d_id)))
   ___GOTO(___L23_callback_2d_return_2d_relocation)
   ___END_IF
   ___SET_R1(___CURRENTPROCESSORID)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L22_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L18_callback_2d_return_2d_relocation)
   ___IF(___NOT(___FIXNUMP(___R1)))
   ___GOTO(___L22_callback_2d_return_2d_relocation)
   ___END_IF
   ___IF(___NOT(___FIXEQ(___R1,___FIX(0L))))
   ___GOTO(___L21_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L19_callback_2d_return_2d_relocation)
   ___SET_R1(___FIX(1L))
   ___SET_R0(___LBL(8))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(8,___L8_callback_2d_return_2d_relocation)
___DEF_GLBL(___L20_callback_2d_return_2d_relocation)
   ___SET_R1(___STK(-5))
   ___ADJFP(-8)
   ___JUMPRET(___STK(1))
___DEF_SLBL(9,___L9_callback_2d_return_2d_relocation)
   ___IF(___NOTFALSEP(___R1))
   ___GOTO(___L19_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L21_callback_2d_return_2d_relocation)
   ___SET_R1(___FIX(0L))
   ___SET_R0(___LBL(8))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(10,___L10_callback_2d_return_2d_relocation)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L18_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L22_callback_2d_return_2d_relocation)
   ___SET_R2(___FIX(0L))
   ___SET_R0(___LBL(9))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L23_callback_2d_return_2d_relocation)
   ___SET_R0(___LBL(10))
   ___JUMPGLOSAFE(___SET_NARGS(0),5,___G__23__23_current_2d_processor_2d_id)
___DEF_GLBL(___L24_callback_2d_return_2d_relocation)
   ___SET_R1(___STK(-6))
   ___SET_R2(___FIX(1L))
   ___SET_R0(___LBL(7))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L25_callback_2d_return_2d_relocation)
   ___SET_R2(___FIX(42L))
   ___SET_R1(___FIX(32L))
   ___SET_R0(___LBL(5))
   ___JUMPGLOSAFE(___SET_NARGS(2),9,___G_make_2d_vector)
___DEF_SLBL(11,___L11_callback_2d_return_2d_relocation)
   ___IF_NARGS_EQ(1,___NOTHING)
   ___WRONG_NARGS(11,1,0,0)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R4)
   ___ADJFP(8)
   ___POLL(12)
___DEF_SLBL(12,___L12_callback_2d_return_2d_relocation)
   ___SET_R0(___LBL(13))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(13,___L13_callback_2d_return_2d_relocation)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L29_callback_2d_return_2d_relocation)
   ___END_IF
   ___SET_R0(___CLO(___STK(-6),1))
   ___IF(___NOT(___FIXNUMP(___R0)))
   ___GOTO(___L29_callback_2d_return_2d_relocation)
   ___END_IF
   ___SET_R0(___CLO(___STK(-6),1))
   ___IF(___NOT(___FIXEQ(___R0,___FIX(1L))))
   ___GOTO(___L27_callback_2d_return_2d_relocation)
   ___END_IF
   ___ADJFP(-4)
   ___GOTO(___L26_callback_2d_return_2d_relocation)
___DEF_SLBL(14,___L14_callback_2d_return_2d_relocation)
   ___IF(___NOT(___NOTFALSEP(___R1)))
   ___GOTO(___L28_callback_2d_return_2d_relocation)
   ___END_IF
___DEF_GLBL(___L26_callback_2d_return_2d_relocation)
   ___SET_R0(___STK(-3))
   ___POLL(15)
___DEF_SLBL(15,___L15_callback_2d_return_2d_relocation)
   ___ADJFP(-4)
   ___JUMPGLOSAFE(___SET_NARGS(0),6,___G__23__23_gc)
___DEF_GLBL(___L27_callback_2d_return_2d_relocation)
   ___ADJFP(-4)
___DEF_GLBL(___L28_callback_2d_return_2d_relocation)
   ___SET_R1(___VOID)
   ___ADJFP(-4)
   ___JUMPRET(___STK(1))
___DEF_GLBL(___L29_callback_2d_return_2d_relocation)
   ___SET_R1(___CLO(___STK(-6),1))
   ___SET_R2(___FIX(1L))
   ___SET_R0(___LBL(14))
   ___ADJFP(-4)
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___END_P_SW
___END_P_COD

___END_M_SW
___END_M_COD

___BEGIN_LBL
 ___DEF_LBL_INTRO(___H_callbackrelocation_23_,___REF_SYM(1,___S_callbackrelocation_23_),___REF_FAL,1,0)
,___DEF_LBL_PROC(___H_callbackrelocation_23_,0,-1)
,___DEF_LBL_INTRO(___H_callbackrelocation_23_0,___REF_SYM(2,___S_callbackrelocation_23_0),___REF_FAL,2,0)
,___DEF_LBL_PROC(___H_callbackrelocation_23_0,1,-1)
,___DEF_LBL_RET(___H_callbackrelocation_23_0,___IFD(___RETN,2,1,0x3L))
,___DEF_LBL_INTRO(___H_callback_2d_return_2d_relocation,___REF_FAL,___REF_FAL,16,callback_return_relocation)
,___DEF_LBL_PROC(___H_callback_2d_return_2d_relocation,2,-1)
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x5L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x5L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x5L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x5L))
,___DEF_LBL_PROC(___H_callback_2d_return_2d_relocation,1,1)
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETN,1,0,0x1L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_relocation,___IFD(___RETI,4,4,0x3f0L))
___END_LBL

___BEGIN_MOD_PRM
___DEF_MOD_PRM(1,___G_callbackrelocation_23_,1)
___DEF_MOD_PRM(2,___G_callbackrelocation_23_0,3)
___END_MOD_PRM

___BEGIN_MOD_C_INIT
___END_MOD_C_INIT

___BEGIN_MOD_GLO
___DEF_MOD_GLO(1,___G_callbackrelocation_23_,1)
___DEF_MOD_GLO(2,___G_callbackrelocation_23_0,3)
___END_MOD_GLO

___BEGIN_MOD_SYM_KEY
___DEF_MOD_SYM(0,___S_callbackrelocation,"callbackrelocation")
___DEF_MOD_SYM(1,___S_callbackrelocation_23_,"callbackrelocation#")
___DEF_MOD_SYM(2,___S_callbackrelocation_23_0,"callbackrelocation#0")
___END_MOD_SYM_KEY

#endif
