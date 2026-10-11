#include <stdio.h>

typedef unsigned long ___WORD;
static ___WORD storage[1024];
static ___WORD *alloc_heap_ptr;
static ___WORD *alloc_heap_chunk_limit;
static int closed;

static void end_heap_chunk(void *ps) {
  (void)ps;
  closed++;
  alloc_heap_ptr++;
}

static void start_heap_chunk(void *ps) {
  (void)ps;
  alloc_heap_chunk_limit = alloc_heap_ptr + CHUNK_WORDS;
}

static int observe(int local, int committed, int expected) {
  ___WORD *alloc = storage + local;
  void *___ps = 0;
  alloc_heap_ptr = storage + committed;
  alloc_heap_chunk_limit = storage + CHUNK_WORDS;
  closed = 0;
#include "continuation-chunk-source.inc"
  printf("LOCAL %d COMMITTED %d CLOSED %d\n", local, committed, closed);
  return closed == expected && alloc >= storage && alloc < storage + 1024;
}

int main(void) {
  int ok = observe(CHUNK_WORDS - 1, 0, 0);
  ok = observe(CHUNK_WORDS + 1, 0, 0) && ok;
  ok = observe(CHUNK_WORDS + 1, CHUNK_WORDS + 1, 1) && ok;
  if (ok) puts("STALE-COMMITTED-FRONTIER-OBSERVED");
  return ok ? 0 : 1;
}
