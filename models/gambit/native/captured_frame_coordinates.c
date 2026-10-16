/* Configured-header coordinate check, not execution of the actual collector. */
#include "gambit.h"
#include <stdio.h>

_Static_assert(sizeof(___WORD) == 8, "model word width");
_Static_assert(___REFERENCE_TO_BODY == 1, "model header reference bias");
_Static_assert(___FRAME_EXTRA_SLOTS == 1 && ___FRAME_RA == 0, "model RA slot");
_Static_assert(___FRAME_RESERVE == 3 && ___FRAME_ALIGN == 4, "model alignment");
_Static_assert(___FRAME_STACK_RA == 0 && ___BREAK_FRAME_NEXT == 1, "model stack coordinates");
_Static_assert(___END_OF_CONT_MARKER == -36, "model continuation end marker");

static int check(int fs0, int link0, int fs1, int link1)
{
  ___WORD stack[192], heap[64];
  ___WORD *top0 = stack + 8;
  ___WORD *top1 = top0 + ___FRAME_SPACE(fs0);
  ___WORD *base0 = top1;
  ___WORD *base1 = top1 + ___FRAME_SPACE(fs1);
  ___WORD *body0 = heap + 1;
  ___WORD *body1 = body0 + fs0 + 2;
  ___WORD *heapBase0 = body0 + fs0 + 1;
  ___WORD *heapBase1 = body1 + fs1 + 1;
  ___WORD ra0 = 1001, ra1 = 2001, handler = 3001;
  for (unsigned i = 0; i < sizeof(stack) / sizeof(stack[0]); i++) stack[i] = -256;
  for (unsigned i = 0; i < sizeof(heap) / sizeof(heap[0]); i++) heap[i] = -256;
  top0[0] = ra0;
  ___FP_SET_STK(base0, link0 + 1, ra1)
  ___FP_SET_STK(base1, link1 + 1, handler)
  ___FP_SET_STK(base1, -___BREAK_FRAME_NEXT, ___END_OF_CONT_MARKER)

  body0[___FRAME_RA] = top0[0];
  for (int i = fs0; i > 0; i--) body0[fs0 + 1 - i] = ___FP_STK(base0, i);
  ___FP_SET_STK(base0, -___FRAME_STACK_RA, ___FP_STK(base0, link0 + 1))
  ___FP_SET_STK(heapBase0, link0 + 1, (___WORD)top1)
  ___FP_SET_STK(base0, link0 + 1, ___TAG(body0 - ___REFERENCE_TO_BODY, ___tFIXNUM))
  if (top1[0] != ra1) return 1;

  body1[___FRAME_RA] = top1[0];
  for (int i = fs1; i > 0; i--) body1[fs1 + 1 - i] = ___FP_STK(base1, i);
  ___FP_SET_STK(heapBase1, link1 + 1, ___END_OF_CONT_MARKER)
  ___FP_SET_STK(heapBase0, link0 + 1, ___TAG(body1 - ___REFERENCE_TO_BODY, ___tFIXNUM))
  if (body0[___FRAME_RA] != ra0 || body1[___FRAME_RA] != ra1) return 2;

  ___WORD raw = ___FP_STK(heapBase0, link0 + 1);
  ___WORD typed = ___TAG(___UNTAG_AS(raw, ___tFIXNUM), ___tFRAME);
  ___WORD *next = ___BODY_AS(typed, ___tFRAME);
  if (next != body1 || next[___FRAME_RA] != ra1) return 3;
  if (___FP_STK(heapBase1, link1 + 1) != ___END_OF_CONT_MARKER) return 4;
  /* No valid link write may alias either heap RA slot. */
  if (body0 + fs0 - link0 <= body0 || body1 + fs1 - link1 <= body1) return 5;
  return 0;
}

int main(void)
{
  for (int fs0 = 1; fs0 <= 16; fs0++)
    for (int link0 = 0; link0 < fs0; link0++)
      for (int fs1 = 1; fs1 <= 16; fs1++)
        for (int link1 = 0; link1 < fs1; link1++) {
          int result = check(fs0, link0, fs1, link1);
          if (result) return result;
        }
  puts("CAPTURED-FRAME-COORDINATES-OK 18496");
  return 0;
}
