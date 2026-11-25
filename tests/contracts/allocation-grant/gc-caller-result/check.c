/* Movable resume and a still reservation are separate results. */
#include "collector.h"

int main(void)
{
  int refunded = 0;
  long occupied = 100;

  /* Usable movable interval, positive still reservation already withdrawn. */
  if (___gc_caller_overflow(1, 1, 8, 0) != 1) return 1;
  /* Zero-word collection recovers when the movable interval is published. */
  if (___gc_caller_overflow(1, 1, 0, 0) != 0) return 2;
  /* Charged still request is granted. The C-allocation failure refunds once. */
  if (___gc_caller_overflow(0, 1, 8, 1) != 0) return 3;
  if (!___still_refund_once(&refunded, &occupied, 8)) return 4;
  if (occupied != 92 || refunded != 1) return 5;
  if (___still_refund_once(&refunded, &occupied, 8)) return 6;
  if (occupied != 92) return 7;
  /* Withdrawn reservation: the caller fails and does not refund. */
  refunded = 0;
  occupied = 100;
  if (___gc_caller_overflow(1, 1, 8, 0) == 0) return 8;
  if (refunded != 0 || occupied != 100) return 9;
  /* Zero-word caller without a published interval keeps the shared failure. */
  if (___gc_caller_overflow(1, 0, 0, 0) != 1) return 10;
  /* A shared refusal is not granted, even if a charge flag is also set. */
  if (___gc_caller_overflow(1, 1, 8, 1) != 1) return 11;
  return 0;
}
