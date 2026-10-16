/* Executable protocol experiment, not Gambit FFI or collector code. */
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>

/* Single-thread component context; the header is not the full Gambit ABI. */
typedef size_t ___SIZE_T;
typedef int ___SCMOBJ;
typedef struct rc_header {
  struct rc_header *prev, *next;
  int refcount;
  ___SCMOBJ data;
} ___rc_header;
static ___rc_header rc_head;
#define ___EXP_FUNC(type, name) type name
#define ___P(args, old) args
#define ___PSD
#define ___PSV
#define ___PSDKR
#define ___PSGET
#define ___PSP
#define ___CAST(type, value) ((type)(value))
#define ___ALLOC_MEM(bytes) malloc(bytes)
#define ___FREE_MEM(ptr) free(ptr)
#define ___FAL 0
#include "rc-origin.inc"

struct object { atomic_int payload; atomic_int version; };
struct copy { int payload; int version; };

static void foreign_write(struct object *borrowed) {
  atomic_store_explicit(&borrowed->payload, 1, memory_order_relaxed);
  atomic_store_explicit(&borrowed->version, 1, memory_order_release);
}

static struct copy snapshot(struct object *source) {
  struct copy c;
  c.version = atomic_load_explicit(&source->version, memory_order_acquire);
  c.payload = atomic_load_explicit(&source->payload, memory_order_relaxed);
  return c;
}

int main(int argc, char **argv) {
  if (argc != 2) return 2;
  int fault = atoi(argv[1]);
  if (fault < 0 || fault > 2) return 2;
  rc_head.prev = rc_head.next = &rc_head;
  struct object *source = ___alloc_rc(sizeof(*source));
  if (!source) return 2;
  ___addref_rc(source);
  atomic_init(&source->payload, 0);
  atomic_init(&source->version, 0);
  struct copy c = snapshot(source);
  int lease = 1;
  /* Force the stale-copy interleaving, without an undefined C data race. */
  foreign_write(source);
  if (fault != 2) { ___release_rc(source); lease = 0; }
  if (fault != 1 && c.version != atomic_load_explicit(&source->version, memory_order_acquire))
    c = snapshot(source);
  int coherent = c.payload == atomic_load_explicit(&source->payload, memory_order_relaxed);
  int admissible = coherent && !lease;
  printf("{\"coherent\":%s,\"leaseDrained\":%s}\n",
         coherent ? "true" : "false", lease ? "false" : "true");
  ___release_rc(source);
  if (lease) ___release_rc(source);
  if (rc_head.next != &rc_head || rc_head.prev != &rc_head) return 2;
  return admissible ? 0 : 1;
}
