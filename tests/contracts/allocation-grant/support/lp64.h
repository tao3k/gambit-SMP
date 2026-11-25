/* Explicit LP64 analysis environment. This is not a replacement allocator.
 * Algorithm bodies and section layouts are projected verbatim from vendor.
 * External aligned allocation is summarized by CBMC's malloc/free model. */
#ifndef CONTRACT_ENVIRONMENT_H
#define CONTRACT_ENVIRONMENT_H
typedef unsigned long size_t;
typedef long ___WORD;
typedef unsigned long ___UWORD;
typedef long ___SIZE_TS;
typedef unsigned long ___SIZE_T;
typedef void *___processor_state;
#define INT_MAX 2147483647
#define ___MAX_FIX 2305843009213693951L
#define ___WORD_WIDTH 64
#define ___WS 8
#define ___LWS 3
#define ___VOLATILE volatile
#define ___HIDDEN
#define ___CAST(T,x) ((T)(x))
#define ___P(prototype,old) prototype
void *malloc(size_t);
void free(void *);
int nondet_int(void);
long nondet_long(void);
_Bool nondet_bool(void);
#define CHECK(p,name) __CPROVER_assert((p),(name))
#define ASSUME(p) __CPROVER_assume(p)
#include "word-rounding.inc"
#include "section-size.inc"
#include "section-layout.inc"
#endif
