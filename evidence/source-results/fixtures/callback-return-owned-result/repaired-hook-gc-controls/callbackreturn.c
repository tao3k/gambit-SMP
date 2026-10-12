#ifdef ___LINKER_INFO
; File: "callbackreturn.c", produced by Gambit v4.9.8
(
409008
(C)
"callbackreturn"
("callbackreturn")
()
(("callbackreturn"))
( #|*/"*/"symbols|#
"callbackreturn"
"callbackreturn#"
) #|*/"*/"symbols|#
( #|*/"*/"keywords|#
) #|*/"*/"keywords|#
( #|*/"*/"globals-s-d|#
"callbackreturn#"
) #|*/"*/"globals-s-d|#
( #|*/"*/"globals-s-nd|#
"callback-return-string"
"callback-return-value"
) #|*/"*/"globals-s-nd|#
( #|*/"*/"globals-ns|#
"##c-return-on-other-processor-hook-set!"
"##current-processor-id"
"##gc"
"##make-string"
"##thread-migrate-to!"
"="
"make-string"
"vector"
"vector-ref"
) #|*/"*/"globals-ns|#
( #|*/"*/"meta-info|#
) #|*/"*/"meta-info|#
)
#else
#define ___VERSION 409008
#define ___MODULE_NAME "callbackreturn"
#define ___LINKER_ID ___LNK_callbackreturn
#define ___MH_PROC ___H_callbackreturn
#define ___SCRIPT_LINE 0
#define ___SYMCOUNT 2
#define ___GLOCOUNT 12
#define ___SUPCOUNT 3
#define ___SUBCOUNT 3
#define ___LBLCOUNT 35
#define ___MODDESCR ___REF_SUB(0)
#include "gambit.h"

___NEED_SYM(___S_callbackreturn)
___NEED_SYM(___S_callbackreturn_23_)

___NEED_GLO(___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
___NEED_GLO(___G__23__23_current_2d_processor_2d_id)
___NEED_GLO(___G__23__23_gc)
___NEED_GLO(___G__23__23_make_2d_string)
___NEED_GLO(___G__23__23_thread_2d_migrate_2d_to_21_)
___NEED_GLO(___G__3d_)
___NEED_GLO(___G_callback_2d_return_2d_string)
___NEED_GLO(___G_callback_2d_return_2d_value)
___NEED_GLO(___G_callbackreturn_23_)
___NEED_GLO(___G_make_2d_string)
___NEED_GLO(___G_vector)
___NEED_GLO(___G_vector_2d_ref)

___BEGIN_SYM
___DEF_SYM(0,___S_callbackreturn,"callbackreturn")
___DEF_SYM(1,___S_callbackreturn_23_,"callbackreturn#")
___END_SYM

#define ___SYM_callbackreturn ___SYM(0,___S_callbackreturn)
#define ___SYM_callbackreturn_23_ ___SYM(1,___S_callbackreturn_23_)

___BEGIN_GLO
___DEF_GLO(0,"callback-return-string")
___DEF_GLO(1,"callback-return-value")
___DEF_GLO(2,"callbackreturn#")
___DEF_GLO(3,"##c-return-on-other-processor-hook-set!")

___DEF_GLO(4,"##current-processor-id")
___DEF_GLO(5,"##gc")
___DEF_GLO(6,"##make-string")
___DEF_GLO(7,"##thread-migrate-to!")
___DEF_GLO(8,"=")
___DEF_GLO(9,"make-string")
___DEF_GLO(10,"vector")
___DEF_GLO(11,"vector-ref")
___END_GLO

#define ___GLO_callback_2d_return_2d_string ___GLO(0,___G_callback_2d_return_2d_string)
#define ___PRM_callback_2d_return_2d_string ___PRM(0,___G_callback_2d_return_2d_string)
#define ___GLO_callback_2d_return_2d_value ___GLO(1,___G_callback_2d_return_2d_value)
#define ___PRM_callback_2d_return_2d_value ___PRM(1,___G_callback_2d_return_2d_value)
#define ___GLO_callbackreturn_23_ ___GLO(2,___G_callbackreturn_23_)
#define ___PRM_callbackreturn_23_ ___PRM(2,___G_callbackreturn_23_)
#define ___GLO__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_ ___GLO(3,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
#define ___PRM__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_ ___PRM(3,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
#define ___GLO__23__23_current_2d_processor_2d_id ___GLO(4,___G__23__23_current_2d_processor_2d_id)
#define ___PRM__23__23_current_2d_processor_2d_id ___PRM(4,___G__23__23_current_2d_processor_2d_id)
#define ___GLO__23__23_gc ___GLO(5,___G__23__23_gc)
#define ___PRM__23__23_gc ___PRM(5,___G__23__23_gc)
#define ___GLO__23__23_make_2d_string ___GLO(6,___G__23__23_make_2d_string)
#define ___PRM__23__23_make_2d_string ___PRM(6,___G__23__23_make_2d_string)
#define ___GLO__23__23_thread_2d_migrate_2d_to_21_ ___GLO(7,___G__23__23_thread_2d_migrate_2d_to_21_)
#define ___PRM__23__23_thread_2d_migrate_2d_to_21_ ___PRM(7,___G__23__23_thread_2d_migrate_2d_to_21_)
#define ___GLO__3d_ ___GLO(8,___G__3d_)
#define ___PRM__3d_ ___PRM(8,___G__3d_)
#define ___GLO_make_2d_string ___GLO(9,___G_make_2d_string)
#define ___PRM_make_2d_string ___PRM(9,___G_make_2d_string)
#define ___GLO_vector ___GLO(10,___G_vector)
#define ___PRM_vector ___PRM(10,___G_vector)
#define ___GLO_vector_2d_ref ___GLO(11,___G_vector_2d_ref)
#define ___PRM_vector_2d_ref ___PRM(11,___G_vector_2d_ref)

___DEF_SUB_VEC(___X0,6UL)
               ___VEC1(___REF_SUB(1))
               ___VEC1(___REF_SUB(2))
               ___VEC1(___REF_NUL)
               ___VEC1(___REF_FIX(1))
               ___VEC1(___REF_PRC(1))
               ___VEC1(___REF_FAL)
               ___VEC0
___DEF_SUB_VEC(___X1,1UL)
               ___VEC1(___REF_SYM(0,___S_callbackreturn))
               ___VEC0
___DEF_SUB_VEC(___X2,0UL)
               ___VEC0

___BEGIN_SUB
 ___DEF_SUB(___X0)
,___DEF_SUB(___X1)
,___DEF_SUB(___X2)
___END_SUB


#define ___C_LBL_callback_return_value 3
#define ___C_LBL_callback_return_string 21

 int callback_return_value ___P((int ___arg1,int ___arg2,int ___arg3),(___arg1,___arg2,___arg3)
int ___arg1;
int ___arg2;
int ___arg3;)
{
#define ___NARGS 3
___BEGIN_SFUN(___MLBL(___C_LBL_callback_return_value),int ___result)
___BEGIN_SFUN_ARG(1,___ARG1)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___BEGIN_SFUN_ARG(2,___ARG2)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___BEGIN_SFUN_ARG(3,___ARG3)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg3,___ARG3,3)
___BEGIN_SFUN_BODY
___SFUN_ARG(1,___ARG1)
___SFUN_ARG(2,___ARG2)
___SFUN_ARG(3,___ARG3)
___SFUN_CALL
___BEGIN_SFUN_SCMOBJ_TO_INT(___SFUN_RESULT,___result)
___SFUN_SET_RESULT
___END_SFUN_SCMOBJ_TO_INT(___SFUN_RESULT,___result)
___END_SFUN_BODY
___END_SFUN_INT_TO_SCMOBJ(___arg3,___ARG3,3)
___END_SFUN_ARG(3)
___END_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___END_SFUN_ARG(2)
___END_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___END_SFUN_ARG(1)
___SFUN_ERROR
___BEGIN_SFUN_SCMOBJ_TO_INT(___SFUN_RESULT,___result)
___SFUN_SET_RESULT
___END_SFUN_SCMOBJ_TO_INT(___SFUN_RESULT,___result)
___END_SFUN
return ___result;
#undef ___NARGS
}

 char* callback_return_string ___P((int ___arg1,int ___arg2),(___arg1,___arg2)
int ___arg1;
int ___arg2;)
{
#define ___NARGS 2
___BEGIN_SFUN(___MLBL(___C_LBL_callback_return_string),char* ___result)
___BEGIN_SFUN_ARG(1,___ARG1)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___BEGIN_SFUN_ARG(2,___ARG2)
___BEGIN_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___BEGIN_SFUN_BODY
___SFUN_ARG(1,___ARG1)
___SFUN_ARG(2,___ARG2)
___SFUN_CALL
___BEGIN_SFUN_SCMOBJ_TO_CHARSTRING(___SFUN_RESULT,___result)
___SFUN_SET_RESULT
___END_SFUN_SCMOBJ_TO_CHARSTRING(___SFUN_RESULT,___result)
___END_SFUN_BODY
___END_SFUN_INT_TO_SCMOBJ(___arg2,___ARG2,2)
___END_SFUN_ARG(2)
___END_SFUN_INT_TO_SCMOBJ(___arg1,___ARG1,1)
___END_SFUN_ARG(1)
___SFUN_ERROR
___BEGIN_SFUN_SCMOBJ_TO_CHARSTRING(___SFUN_RESULT,___result)
___SFUN_SET_RESULT
___END_SFUN_SCMOBJ_TO_CHARSTRING(___SFUN_RESULT,___result)
___END_SFUN
return ___result;
#undef ___NARGS
}


#undef ___MD_ALL
#define ___MD_ALL ___D_HEAP ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R3 ___D_R4
#undef ___MR_ALL
#define ___MR_ALL ___R_HEAP ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R3 ___R_R4
#undef ___MW_ALL
#define ___MW_ALL ___W_HEAP ___W_FP ___W_R0 ___W_R1 ___W_R2 ___W_R3 ___W_R4
___BEGIN_M_COD
___BEGIN_M_HLBL
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callbackreturn_23_)
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callback_2d_return_2d_value)
___DEF_M_HLBL(___L1_callback_2d_return_2d_value)
___DEF_M_HLBL(___L2_callback_2d_return_2d_value)
___DEF_M_HLBL(___L3_callback_2d_return_2d_value)
___DEF_M_HLBL(___L4_callback_2d_return_2d_value)
___DEF_M_HLBL(___L5_callback_2d_return_2d_value)
___DEF_M_HLBL(___L6_callback_2d_return_2d_value)
___DEF_M_HLBL(___L7_callback_2d_return_2d_value)
___DEF_M_HLBL(___L8_callback_2d_return_2d_value)
___DEF_M_HLBL(___L9_callback_2d_return_2d_value)
___DEF_M_HLBL(___L10_callback_2d_return_2d_value)
___DEF_M_HLBL(___L11_callback_2d_return_2d_value)
___DEF_M_HLBL(___L12_callback_2d_return_2d_value)
___DEF_M_HLBL(___L13_callback_2d_return_2d_value)
___DEF_M_HLBL(___L14_callback_2d_return_2d_value)
___DEF_M_HLBL(___L15_callback_2d_return_2d_value)
___DEF_M_HLBL(___L16_callback_2d_return_2d_value)
___DEF_M_HLBL_INTRO
___DEF_M_HLBL(___L0_callback_2d_return_2d_string)
___DEF_M_HLBL(___L1_callback_2d_return_2d_string)
___DEF_M_HLBL(___L2_callback_2d_return_2d_string)
___DEF_M_HLBL(___L3_callback_2d_return_2d_string)
___DEF_M_HLBL(___L4_callback_2d_return_2d_string)
___DEF_M_HLBL(___L5_callback_2d_return_2d_string)
___DEF_M_HLBL(___L6_callback_2d_return_2d_string)
___DEF_M_HLBL(___L7_callback_2d_return_2d_string)
___DEF_M_HLBL(___L8_callback_2d_return_2d_string)
___DEF_M_HLBL(___L9_callback_2d_return_2d_string)
___DEF_M_HLBL(___L10_callback_2d_return_2d_string)
___DEF_M_HLBL(___L11_callback_2d_return_2d_string)
___DEF_M_HLBL(___L12_callback_2d_return_2d_string)
___DEF_M_HLBL(___L13_callback_2d_return_2d_string)
___END_M_HLBL

___BEGIN_M_SW

#undef ___PH_PROC
#define ___PH_PROC ___H_callbackreturn_23_
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
___DEF_P_HLBL(___L0_callbackreturn_23_)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callbackreturn_23_)
   ___IF_NARGS_EQ(0,___NOTHING)
   ___WRONG_NARGS(0,0,0,0)
___DEF_GLBL(___L_callbackreturn_23_)
   ___SET_GLO(1,___G_callback_2d_return_2d_value,___PRC(3))
   ___SET_GLO(0,___G_callback_2d_return_2d_string,___PRC(21))
   ___SET_R1(___VOID)
   ___JUMPRET(___R0)
___END_P_SW
___END_P_COD

#undef ___PH_PROC
#define ___PH_PROC ___H_callback_2d_return_2d_value
#undef ___PH_LBL0
#define ___PH_LBL0 3
#undef ___PD_ALL
#define ___PD_ALL ___D_HEAP ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R3 ___D_R4
#undef ___PR_ALL
#define ___PR_ALL ___R_HEAP ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R3 ___R_R4
#undef ___PW_ALL
#define ___PW_ALL ___W_HEAP ___W_FP ___W_R0 ___W_R1 ___W_R2 ___W_R3 ___W_R4
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0_callback_2d_return_2d_value)
___DEF_P_HLBL(___L1_callback_2d_return_2d_value)
___DEF_P_HLBL(___L2_callback_2d_return_2d_value)
___DEF_P_HLBL(___L3_callback_2d_return_2d_value)
___DEF_P_HLBL(___L4_callback_2d_return_2d_value)
___DEF_P_HLBL(___L5_callback_2d_return_2d_value)
___DEF_P_HLBL(___L6_callback_2d_return_2d_value)
___DEF_P_HLBL(___L7_callback_2d_return_2d_value)
___DEF_P_HLBL(___L8_callback_2d_return_2d_value)
___DEF_P_HLBL(___L9_callback_2d_return_2d_value)
___DEF_P_HLBL(___L10_callback_2d_return_2d_value)
___DEF_P_HLBL(___L11_callback_2d_return_2d_value)
___DEF_P_HLBL(___L12_callback_2d_return_2d_value)
___DEF_P_HLBL(___L13_callback_2d_return_2d_value)
___DEF_P_HLBL(___L14_callback_2d_return_2d_value)
___DEF_P_HLBL(___L15_callback_2d_return_2d_value)
___DEF_P_HLBL(___L16_callback_2d_return_2d_value)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callback_2d_return_2d_value)
   ___IF_NARGS_EQ(3,___NOTHING)
   ___WRONG_NARGS(0,3,0,0)
___DEF_GLBL(___L_callback_2d_return_2d_value)
   ___IF(___NOT(___EQP(___GLO_vector,___PRM_vector)))
   ___GOTO(___L37_callback_2d_return_2d_value)
   ___END_IF
   ___BEGIN_ALLOC_VECTOR(1UL)
   ___ADD_VECTOR_ELEM(0,___R3)
   ___END_ALLOC_VECTOR(1)
   ___SET_R3(___GET_VECTOR(1))
   ___CHECK_HEAP(1,4096)
___DEF_SLBL(1,___L1_callback_2d_return_2d_value)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L17_callback_2d_return_2d_value)
   ___END_IF
   ___GOTO(___L36_callback_2d_return_2d_value)
___DEF_SLBL(2,___L2_callback_2d_return_2d_value)
   ___SET_R3(___R1)
   ___SET_R2(___STK(-5))
   ___SET_R1(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L36_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L17_callback_2d_return_2d_value)
   ___IF(___NOT(___FIXNUMP(___R1)))
   ___GOTO(___L36_callback_2d_return_2d_value)
   ___END_IF
   ___IF(___NOT(___FIXEQ(___R1,___FIX(1L))))
   ___GOTO(___L29_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L18_callback_2d_return_2d_value)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R2)
   ___SET_STK(3,___R3)
   ___ADJFP(3)
   ___IF(___NOT(___EQP(___GLO__23__23_current_2d_processor_2d_id,___PRM__23__23_current_2d_processor_2d_id)))
   ___GOTO(___L35_callback_2d_return_2d_value)
   ___END_IF
   ___SET_R1(___CURRENTPROCESSORID)
   ___SET_STK(0,___R3)
   ___SET_STK(-1,___R2)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L34_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L19_callback_2d_return_2d_value)
   ___IF(___NOT(___FIXNUMP(___R1)))
   ___GOTO(___L34_callback_2d_return_2d_value)
   ___END_IF
   ___IF(___NOT(___FIXEQ(___R1,___FIX(0L))))
   ___GOTO(___L32_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L20_callback_2d_return_2d_value)
   ___SET_R1(___FIX(1L))
___DEF_GLBL(___L21_callback_2d_return_2d_value)
   ___ADJFP(5)
   ___POLL(3)
___DEF_SLBL(3,___L3_callback_2d_return_2d_value)
   ___SET_R0(___LBL(4))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(4,___L4_callback_2d_return_2d_value)
   ___SET_R3(___STK(-5))
   ___SET_R2(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L22_callback_2d_return_2d_value)
   ___END_IF
   ___GOTO(___L30_callback_2d_return_2d_value)
___DEF_SLBL(5,___L5_callback_2d_return_2d_value)
   ___IF(___NOTFALSEP(___R1))
   ___GOTO(___L31_callback_2d_return_2d_value)
   ___END_IF
   ___SET_R3(___STK(-5))
   ___SET_R2(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L30_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L22_callback_2d_return_2d_value)
   ___IF(___NOT(___FIXNUMP(___R2)))
   ___GOTO(___L30_callback_2d_return_2d_value)
   ___END_IF
   ___IF(___NOT(___FIXEQ(___R2,___FIX(1L))))
   ___GOTO(___L28_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L23_callback_2d_return_2d_value)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R3)
   ___ADJFP(8)
   ___POLL(6)
___DEF_SLBL(6,___L6_callback_2d_return_2d_value)
   ___SET_R0(___LBL(7))
   ___JUMPGLOSAFE(___SET_NARGS(0),5,___G__23__23_gc)
___DEF_SLBL(7,___L7_callback_2d_return_2d_value)
   ___SET_R3(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___IF(___EQP(___GLO_vector_2d_ref,___PRM_vector_2d_ref))
   ___GOTO(___L24_callback_2d_return_2d_value)
   ___END_IF
   ___GOTO(___L25_callback_2d_return_2d_value)
___DEF_SLBL(8,___L8_callback_2d_return_2d_value)
   ___IF(___NOTFALSEP(___R1))
   ___GOTO(___L27_callback_2d_return_2d_value)
   ___END_IF
   ___SET_R3(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___IF(___NOT(___EQP(___GLO_vector_2d_ref,___PRM_vector_2d_ref)))
   ___GOTO(___L25_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L24_callback_2d_return_2d_value)
   ___IF(___NOT(___VECTORP(___R3)))
   ___GOTO(___L25_callback_2d_return_2d_value)
   ___END_IF
   ___IF(___VECTORINBOUNDSP(___R3,___FIX(0L)))
   ___GOTO(___L26_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L25_callback_2d_return_2d_value)
   ___SET_R1(___R3)
   ___SET_R2(___FIX(0L))
   ___POLL(9)
___DEF_SLBL(9,___L9_callback_2d_return_2d_value)
   ___JUMPGLOSAFE(___SET_NARGS(2),11,___G_vector_2d_ref)
___DEF_GLBL(___L26_callback_2d_return_2d_value)
   ___SET_R1(___VECTORREF(___R3,___FIX(0L)))
   ___JUMPRET(___R0)
___DEF_GLBL(___L27_callback_2d_return_2d_value)
   ___SET_R3(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___GOTO(___L23_callback_2d_return_2d_value)
___DEF_GLBL(___L28_callback_2d_return_2d_value)
   ___IF(___EQP(___GLO_vector_2d_ref,___PRM_vector_2d_ref))
   ___GOTO(___L24_callback_2d_return_2d_value)
   ___END_IF
   ___GOTO(___L25_callback_2d_return_2d_value)
___DEF_GLBL(___L29_callback_2d_return_2d_value)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L22_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L30_callback_2d_return_2d_value)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R3)
   ___SET_R1(___R2)
   ___SET_R2(___FIX(1L))
   ___ADJFP(8)
   ___POLL(10)
___DEF_SLBL(10,___L10_callback_2d_return_2d_value)
   ___SET_R0(___LBL(8))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L31_callback_2d_return_2d_value)
   ___SET_R3(___STK(-5))
   ___SET_R2(___STK(-6))
   ___SET_R0(___STK(-7))
   ___ADJFP(-8)
   ___GOTO(___L18_callback_2d_return_2d_value)
___DEF_SLBL(11,___L11_callback_2d_return_2d_value)
   ___IF(___NOTFALSEP(___R1))
   ___GOTO(___L33_callback_2d_return_2d_value)
   ___END_IF
   ___ADJFP(-5)
___DEF_GLBL(___L32_callback_2d_return_2d_value)
   ___SET_R1(___FIX(0L))
   ___GOTO(___L21_callback_2d_return_2d_value)
___DEF_GLBL(___L33_callback_2d_return_2d_value)
   ___ADJFP(-5)
   ___GOTO(___L20_callback_2d_return_2d_value)
___DEF_SLBL(12,___L12_callback_2d_return_2d_value)
   ___ADJFP(-5)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L19_callback_2d_return_2d_value)
   ___END_IF
___DEF_GLBL(___L34_callback_2d_return_2d_value)
   ___SET_R2(___FIX(0L))
   ___ADJFP(5)
   ___POLL(13)
___DEF_SLBL(13,___L13_callback_2d_return_2d_value)
   ___SET_R0(___LBL(11))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L35_callback_2d_return_2d_value)
   ___ADJFP(5)
   ___POLL(14)
___DEF_SLBL(14,___L14_callback_2d_return_2d_value)
   ___SET_R0(___LBL(12))
   ___JUMPGLOSAFE(___SET_NARGS(0),4,___G__23__23_current_2d_processor_2d_id)
___DEF_GLBL(___L36_callback_2d_return_2d_value)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R2)
   ___SET_STK(3,___R3)
   ___SET_R2(___FIX(1L))
   ___ADJFP(8)
   ___POLL(15)
___DEF_SLBL(15,___L15_callback_2d_return_2d_value)
   ___SET_R0(___LBL(5))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L37_callback_2d_return_2d_value)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R1)
   ___SET_STK(3,___R2)
   ___SET_R1(___R3)
   ___ADJFP(8)
   ___POLL(16)
___DEF_SLBL(16,___L16_callback_2d_return_2d_value)
   ___SET_R0(___LBL(2))
   ___JUMPGLOSAFE(___SET_NARGS(1),10,___G_vector)
___END_P_SW
___END_P_COD

#undef ___PH_PROC
#define ___PH_PROC ___H_callback_2d_return_2d_string
#undef ___PH_LBL0
#define ___PH_LBL0 21
#undef ___PD_ALL
#define ___PD_ALL ___D_HEAP ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R4
#undef ___PR_ALL
#define ___PR_ALL ___R_HEAP ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R4
#undef ___PW_ALL
#define ___PW_ALL ___W_HEAP ___W_FP ___W_R0 ___W_R1 ___W_R2 ___W_R4
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0_callback_2d_return_2d_string)
___DEF_P_HLBL(___L1_callback_2d_return_2d_string)
___DEF_P_HLBL(___L2_callback_2d_return_2d_string)
___DEF_P_HLBL(___L3_callback_2d_return_2d_string)
___DEF_P_HLBL(___L4_callback_2d_return_2d_string)
___DEF_P_HLBL(___L5_callback_2d_return_2d_string)
___DEF_P_HLBL(___L6_callback_2d_return_2d_string)
___DEF_P_HLBL(___L7_callback_2d_return_2d_string)
___DEF_P_HLBL(___L8_callback_2d_return_2d_string)
___DEF_P_HLBL(___L9_callback_2d_return_2d_string)
___DEF_P_HLBL(___L10_callback_2d_return_2d_string)
___DEF_P_HLBL(___L11_callback_2d_return_2d_string)
___DEF_P_HLBL(___L12_callback_2d_return_2d_string)
___DEF_P_HLBL(___L13_callback_2d_return_2d_string)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0_callback_2d_return_2d_string)
   ___IF_NARGS_EQ(2,___NOTHING)
   ___WRONG_NARGS(0,2,0,0)
___DEF_GLBL(___L_callback_2d_return_2d_string)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R1)
   ___SET_STK(3,___ALLOC_CLO(1UL))
   ___BEGIN_SETUP_CLO(1,___STK(3),9)
   ___ADD_CLO_ELEM(0,___R2)
   ___END_SETUP_CLO(1)
   ___SET_R1(___STK(3))
   ___ADJFP(8)
   ___CHECK_HEAP(1,4096)
___DEF_SLBL(1,___L1_callback_2d_return_2d_string)
   ___POLL(2)
___DEF_SLBL(2,___L2_callback_2d_return_2d_string)
   ___SET_R0(___LBL(3))
   ___JUMPGLOSAFE(___SET_NARGS(1),3,___G__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook_2d_set_21_)
___DEF_SLBL(3,___L3_callback_2d_return_2d_string)
   ___IF(___NOT(___EQP(___GLO_make_2d_string,___PRM_make_2d_string)))
   ___GOTO(___L23_callback_2d_return_2d_string)
   ___END_IF
   ___SET_R2(___CHR(120))
   ___SET_R1(___FIX(4096L))
   ___SET_R0(___LBL(4))
   ___JUMPPRM(___SET_NARGS(2),___PRM__23__23_make_2d_string)
___DEF_SLBL(4,___L4_callback_2d_return_2d_string)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L22_callback_2d_return_2d_string)
   ___END_IF
   ___IF(___NOT(___FIXNUMP(___STK(-6))))
   ___GOTO(___L22_callback_2d_return_2d_string)
   ___END_IF
   ___IF(___FIXEQ(___STK(-6),___FIX(1L)))
   ___GOTO(___L14_callback_2d_return_2d_string)
   ___END_IF
   ___GOTO(___L21_callback_2d_return_2d_string)
___DEF_SLBL(5,___L5_callback_2d_return_2d_string)
   ___IF(___NOT(___NOTFALSEP(___R1)))
   ___GOTO(___L20_callback_2d_return_2d_string)
   ___END_IF
   ___SET_R1(___STK(-5))
___DEF_GLBL(___L14_callback_2d_return_2d_string)
   ___SET_STK(-6,___R1)
   ___IF(___NOT(___EQP(___GLO__23__23_current_2d_processor_2d_id,___PRM__23__23_current_2d_processor_2d_id)))
   ___GOTO(___L19_callback_2d_return_2d_string)
   ___END_IF
   ___SET_R1(___CURRENTPROCESSORID)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L18_callback_2d_return_2d_string)
   ___END_IF
___DEF_GLBL(___L15_callback_2d_return_2d_string)
   ___IF(___NOT(___FIXNUMP(___R1)))
   ___GOTO(___L18_callback_2d_return_2d_string)
   ___END_IF
   ___IF(___NOT(___FIXEQ(___R1,___FIX(0L))))
   ___GOTO(___L17_callback_2d_return_2d_string)
   ___END_IF
___DEF_GLBL(___L16_callback_2d_return_2d_string)
   ___SET_R1(___FIX(1L))
   ___SET_R0(___LBL(6))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(6,___L6_callback_2d_return_2d_string)
   ___SET_R1(___STK(-6))
   ___ADJFP(-8)
   ___JUMPRET(___STK(1))
___DEF_SLBL(7,___L7_callback_2d_return_2d_string)
   ___IF(___NOTFALSEP(___R1))
   ___GOTO(___L16_callback_2d_return_2d_string)
   ___END_IF
___DEF_GLBL(___L17_callback_2d_return_2d_string)
   ___SET_R1(___FIX(0L))
   ___SET_R0(___LBL(6))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(8,___L8_callback_2d_return_2d_string)
   ___IF(___EQP(___GLO__3d_,___PRM__3d_))
   ___GOTO(___L15_callback_2d_return_2d_string)
   ___END_IF
___DEF_GLBL(___L18_callback_2d_return_2d_string)
   ___SET_R2(___FIX(0L))
   ___SET_R0(___LBL(7))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L19_callback_2d_return_2d_string)
   ___SET_R0(___LBL(8))
   ___JUMPGLOSAFE(___SET_NARGS(0),4,___G__23__23_current_2d_processor_2d_id)
___DEF_GLBL(___L20_callback_2d_return_2d_string)
   ___SET_R1(___STK(-5))
   ___ADJFP(-8)
   ___JUMPRET(___STK(1))
___DEF_GLBL(___L21_callback_2d_return_2d_string)
   ___ADJFP(-8)
   ___JUMPRET(___STK(1))
___DEF_GLBL(___L22_callback_2d_return_2d_string)
   ___SET_STK(-5,___R1)
   ___SET_R1(___STK(-6))
   ___SET_R2(___FIX(1L))
   ___SET_R0(___LBL(5))
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___DEF_GLBL(___L23_callback_2d_return_2d_string)
   ___SET_R2(___CHR(120))
   ___SET_R1(___FIX(4096L))
   ___SET_R0(___LBL(4))
   ___JUMPGLOSAFE(___SET_NARGS(2),9,___G_make_2d_string)
___DEF_SLBL(9,___L9_callback_2d_return_2d_string)
   ___IF_NARGS_EQ(1,___NOTHING)
   ___WRONG_NARGS(9,1,0,0)
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R4)
   ___ADJFP(8)
   ___POLL(10)
___DEF_SLBL(10,___L10_callback_2d_return_2d_string)
   ___SET_R0(___LBL(11))
   ___JUMPGLOSAFE(___SET_NARGS(1),7,___G__23__23_thread_2d_migrate_2d_to_21_)
___DEF_SLBL(11,___L11_callback_2d_return_2d_string)
   ___IF(___NOT(___EQP(___GLO__3d_,___PRM__3d_)))
   ___GOTO(___L27_callback_2d_return_2d_string)
   ___END_IF
   ___SET_R0(___CLO(___STK(-6),1))
   ___IF(___NOT(___FIXNUMP(___R0)))
   ___GOTO(___L27_callback_2d_return_2d_string)
   ___END_IF
   ___SET_R0(___CLO(___STK(-6),1))
   ___IF(___NOT(___FIXEQ(___R0,___FIX(1L))))
   ___GOTO(___L25_callback_2d_return_2d_string)
   ___END_IF
   ___ADJFP(-4)
   ___GOTO(___L24_callback_2d_return_2d_string)
___DEF_SLBL(12,___L12_callback_2d_return_2d_string)
   ___IF(___NOT(___NOTFALSEP(___R1)))
   ___GOTO(___L26_callback_2d_return_2d_string)
   ___END_IF
___DEF_GLBL(___L24_callback_2d_return_2d_string)
   ___SET_R0(___STK(-3))
   ___POLL(13)
___DEF_SLBL(13,___L13_callback_2d_return_2d_string)
   ___ADJFP(-4)
   ___JUMPGLOSAFE(___SET_NARGS(0),5,___G__23__23_gc)
___DEF_GLBL(___L25_callback_2d_return_2d_string)
   ___ADJFP(-4)
___DEF_GLBL(___L26_callback_2d_return_2d_string)
   ___SET_R1(___VOID)
   ___ADJFP(-4)
   ___JUMPRET(___STK(1))
___DEF_GLBL(___L27_callback_2d_return_2d_string)
   ___SET_R1(___CLO(___STK(-6),1))
   ___SET_R2(___FIX(1L))
   ___SET_R0(___LBL(12))
   ___ADJFP(-4)
   ___JUMPGLOSAFE(___SET_NARGS(2),8,___G__3d_)
___END_P_SW
___END_P_COD

___END_M_SW
___END_M_COD

___BEGIN_LBL
 ___DEF_LBL_INTRO(___H_callbackreturn_23_,___REF_SYM(1,___S_callbackreturn_23_),___REF_FAL,1,0)
,___DEF_LBL_PROC(___H_callbackreturn_23_,0,-1)
,___DEF_LBL_INTRO(___H_callback_2d_return_2d_value,___REF_FAL,___REF_FAL,17,callback_return_value)
,___DEF_LBL_PROC(___H_callback_2d_return_2d_value,3,-1)
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,0,0,0x3fL))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f07L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,0,0,0x3fL))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETN,5,0,0x7L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f07L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f07L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f07L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_value,___IFD(___RETI,8,0,0x3f07L))
,___DEF_LBL_INTRO(___H_callback_2d_return_2d_string,___REF_FAL,___REF_FAL,14,callback_return_string)
,___DEF_LBL_PROC(___H_callback_2d_return_2d_string,2,-1)
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x5L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_PROC(___H_callback_2d_return_2d_string,1,1)
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETI,8,0,0x3f03L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,5,0,0x3L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETN,1,0,0x1L))
,___DEF_LBL_RET(___H_callback_2d_return_2d_string,___IFD(___RETI,4,4,0x3f0L))
___END_LBL

___BEGIN_MOD_PRM
___DEF_MOD_PRM(2,___G_callbackreturn_23_,1)
___END_MOD_PRM

___BEGIN_MOD_C_INIT
___END_MOD_C_INIT

___BEGIN_MOD_GLO
___DEF_MOD_GLO(2,___G_callbackreturn_23_,1)
___END_MOD_GLO

___BEGIN_MOD_SYM_KEY
___DEF_MOD_SYM(0,___S_callbackreturn,"callbackreturn")
___DEF_MOD_SYM(1,___S_callbackreturn_23_,"callbackreturn#")
___END_MOD_SYM_KEY

#endif
