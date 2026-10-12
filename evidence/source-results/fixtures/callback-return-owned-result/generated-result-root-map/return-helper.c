#define ___PH_PROC ___H__23__23_c_2d_return_2d_on_2d_other_2d_processor
#undef ___PH_LBL0
#define ___PH_LBL0 398
#undef ___PD_ALL
#define ___PD_ALL ___D_FP ___D_R0 ___D_R1 ___D_R2 ___D_R4
#undef ___PR_ALL
#define ___PR_ALL ___R_FP ___R_R0 ___R_R1 ___R_R2 ___R_R4
#undef ___PW_ALL
#define ___PW_ALL ___W_FP ___W_R0 ___W_R1 ___W_R4
___BEGIN_P_COD
___BEGIN_P_HLBL
___DEF_P_HLBL_INTRO
___DEF_P_HLBL(___L0__23__23_c_2d_return_2d_on_2d_other_2d_processor)
___DEF_P_HLBL(___L1__23__23_c_2d_return_2d_on_2d_other_2d_processor)
___END_P_HLBL
___BEGIN_P_SW
___DEF_SLBL(0,___L0__23__23_c_2d_return_2d_on_2d_other_2d_processor)
   ___IF_NARGS_EQ(2,___NOTHING)
   ___WRONG_NARGS(0,2,0,0)
___DEF_GLBL(___L__23__23_c_2d_return_2d_on_2d_other_2d_processor)
   ___SET_STK(1,___GLO__23__23_c_2d_return_2d_on_2d_other_2d_processor_2d_hook)
   ___ADJFP(1)
   ___IF(___NOT(___PROCEDUREP(___STK(0))))
   ___GOTO(___L2__23__23_c_2d_return_2d_on_2d_other_2d_processor)
   ___END_IF
   ___SET_STK(1,___R0)
   ___SET_STK(2,___R2)
   ___SET_R0(___LBL(1))
   ___ADJFP(7)
   ___JUMPGENNOTSAFE(___SET_NARGS(1),___STK(-7))
___DEF_SLBL(1,___L1__23__23_c_2d_return_2d_on_2d_other_2d_processor)
   ___SET_R1(___STK(-5))
   ___ADJFP(-8)
   ___JUMPRET(___STK(2))
___DEF_GLBL(___L2__23__23_c_2d_return_2d_on_2d_other_2d_processor)
   ___ADJFP(-1)
   ___JUMPINT(___SET_NARGS(0),___PRC(392),___L__23__23_raise_2d_wrong_2d_processor_2d_c_2d_return_2d_exception)
___END_P_SW
___END_P_COD
