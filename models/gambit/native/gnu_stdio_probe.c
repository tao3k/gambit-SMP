#include <stdio.h>

#ifdef __clang__
#error GNU GCC is required.
#endif

int main(void)
{
  FILE *stream = fopen("/dev/null", "w");
  int error;
  if (stream == NULL) return 1;
  error = ferror(stream);
  return fclose(stream) != 0 || error != 0;
}
