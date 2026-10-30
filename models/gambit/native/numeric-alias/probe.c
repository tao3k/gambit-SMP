/* An observable alias workload, not a Gambit numeric correctness fixture. */
int scalar_a, scalar_b;
int *scalar_slots[2] = { &scalar_a, &scalar_b };
#ifndef FUNCTIONLESS
__attribute__((noinline)) int numeric_alias_probe(int selector, int value)
{
  int *chosen = scalar_slots[(unsigned)selector & 1];
  *chosen = value;
  return scalar_a + scalar_b;
}
#endif
