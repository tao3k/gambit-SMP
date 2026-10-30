/* Darwin qualification adapter only. Never linked into the runtime/profile. */
#include <pthread.h>
#include <stdatomic.h>
#include <stdlib.h>
#include <errno.h>
#include <dlfcn.h>
#include <malloc/malloc.h>
static _Atomic int create_at, join_at, allocation_at;
static _Atomic int creates, joins, allocations;
void resize_test_arm(int c, int j, int a) {
  atomic_store(&creates,0);atomic_store(&joins,0);atomic_store(&allocations,0);
  atomic_store(&create_at,c);atomic_store(&join_at,j);atomic_store(&allocation_at,a);
}
int resize_test_count(int kind) {
  return kind==0 ? atomic_load(&creates) : kind==1 ? atomic_load(&joins) : atomic_load(&allocations);
}
static int create_thread(pthread_t *id,const pthread_attr_t *attr,
                         void *(*fn)(void *),void *arg) {
  int at=atomic_load(&create_at);
  if(at && atomic_fetch_add(&creates,1)+1==at) {errno=0;return EAGAIN;}
  int (*real)(pthread_t *,const pthread_attr_t *,void *(*)(void *),void *)=
    dlsym(RTLD_NEXT,"pthread_create");
  return real(id,attr,fn,arg);
}
static int join_thread(pthread_t id,void **result) {
  int at=atomic_load(&join_at);
  if(at && atomic_fetch_add(&joins,1)+1==at) {errno=0;return ESRCH;}
  int (*real)(pthread_t,void **)=dlsym(RTLD_NEXT,"pthread_join");
  return real(id,result);
}
static void *allocate(size_t bytes) {
  int at=atomic_load(&allocation_at);
  if(at && bytes>=1048576 && bytes<1052672 &&
     atomic_fetch_add(&allocations,1)+1==at) {errno=ENOMEM;return NULL;}
  return malloc_zone_malloc(malloc_default_zone(),bytes);
}
#define INTERPOSE(replacement,original) \
  __attribute__((used)) static struct {const void *r,*o;} map_##original \
  __attribute__((section("__DATA,__interpose")))={(const void *)&replacement,(const void *)&original}
INTERPOSE(create_thread,pthread_create);
INTERPOSE(join_thread,pthread_join);
INTERPOSE(allocate,malloc);
