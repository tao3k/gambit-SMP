/* Locked wrappers and error macros; only the POSIX primitives are injected. */
#include <errno.h>
#include <stdio.h>
#include <stddef.h>
typedef long ___SCMOBJ;
typedef unsigned long pthread_t;
typedef struct { pthread_t thread_id; } ___thread;
#define ___P(args, old) args
#define ___PVOID (void)
#define ___CAST(type, value) ((type)(value))
#define ___MASK(type, bits) (((type)1 << (bits)) - 1)
#define ___FIX(value) (value)
#define ___USE_POSIX_THREAD_SYSTEM
#include "error-source.inc"
static int returned_error, initialized, primitive_calls;
static int pthread_create(pthread_t *id, const void *attributes,
                          void *(*start)(void *), void *argument) {
  (void)attributes; (void)start; (void)argument;
  *id = 23;
  ++primitive_calls;
  return returned_error;
}
static int pthread_join(pthread_t id, void **result) {
  (void)result;
  if (id != 17) return 99;
  ++primitive_calls;
  return returned_error;
}
static void *start_pthread_thread(void *argument) { return argument; }
static ___SCMOBJ thread_init_common(___thread *thread) {
  if (thread->thread_id != 23) return 99;
  ++initialized;
  return ___FIX(___NO_ERR);
}
#include "errno-source.inc"
#define err_code_from_errno ___err_code_from_errno
#include "thread-source.inc"
int main(void) {
  const int errors[] = {0, 11, 22};
  const int ambient[] = {0, 4, 35};
  int checks = 0, invalid = 0;
  for (int operation = 0; operation < 2; ++operation)
    for (size_t e = 0; e < sizeof(errors) / sizeof(errors[0]); ++e)
      for (size_t a = 0; a < sizeof(ambient) / sizeof(ambient[0]); ++a) {
        ___thread thread = {17};
        returned_error = errors[e];
        initialized = primitive_calls = 0;
        errno = ambient[a];
        ___SCMOBJ result = operation ? ___thread_join(&thread) : ___thread_create(&thread);
        int expected_handle = !operation && !returned_error ? 23 : 17;
        invalid += result != ___FIX(___ERRNO_ERR(returned_error)) ||
          errno != ambient[a] || thread.thread_id != (pthread_t)expected_handle ||
          initialized != (!operation && !returned_error) || primitive_calls != 1;
        ++checks;
      }
  printf("{\"checks\":%d,\"invalid\":%d}\n", checks, invalid);
  return invalid ? 1 : 0;
}
