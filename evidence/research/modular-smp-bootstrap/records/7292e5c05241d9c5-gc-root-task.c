/* Actual header kernel, not a second implementation of its transitions.
 * Physical root stop, task-slot grace and a whole-round seal are external
 * prerequisites; these controls do not grant them to arbitrary native callers. */
#include <stdio.h>
#include <string.h>
#include <pthread.h>
#include "gambit.h"

#define CHECK(x) do { if (!(x)) { fprintf(stderr,"gc-root-task:%d: %s\n",__LINE__,#x); return 1; } } while (0)

static ___gc_root_origin origin;
static ___gc_root_task task;
static ___execution_context context;
static pthread_mutex_t gate = PTHREAD_MUTEX_INITIALIZER;
static pthread_cond_t changed = PTHREAD_COND_INITIALIZER;
static int ready, go;

struct contender { ___WORD owner; int won; };
static void *claim(void *arg)
{
  struct contender *c = arg;
  pthread_mutex_lock(&gate);
  ready++;
  pthread_cond_broadcast(&changed);
  while (!go) pthread_cond_wait(&changed,&gate);
  pthread_mutex_unlock(&gate);
  c->won = ___gc_root_task_claim(&task,1,c->owner);
  return 0;
}

int main(void)
{
  pthread_t a, b;
  struct contender ca = {4,0}, cb = {5,0};
  ___WORD words[32];
  ___gc_worker_arena arena;
  ___WORD *begin, *past;
  memset(&origin,0,sizeof(origin));
  memset(&task,0,sizeof(task));
  memset(&context,0,sizeof(context));
  origin.incarnation = 1;
  context.saved[0] = ___FIX(37);
  CHECK(!___gc_root_task_publish(&task,&origin,1));
  CHECK(___gc_origin_freeze(&origin,&context,1));
  CHECK(!___gc_origin_freeze(&origin,&context,2));
  CHECK(___gc_root_task_publish(&task,&origin,1));
  CHECK(!___gc_root_task_claim(&task,2,4));
  CHECK(!___gc_origin_thaw(&task,1));
  CHECK(task.origin->context->saved[0] == ___FIX(37));
  puts("PUBLICATION-PASS");

  CHECK(pthread_create(&a,0,claim,&ca) == 0);
  CHECK(pthread_create(&b,0,claim,&cb) == 0);
  pthread_mutex_lock(&gate);
  while (ready != 2) pthread_cond_wait(&changed,&gate);
  go = 1;
  pthread_cond_broadcast(&changed);
  pthread_mutex_unlock(&gate);
  CHECK(pthread_join(a,0) == 0);
  CHECK(pthread_join(b,0) == 0);
  CHECK(ca.won+cb.won == 1);
  CHECK(!___gc_root_task_finish(&task,1,ca.won ? cb.owner : ca.owner));
  CHECK(!___gc_origin_thaw(&task,1)); /* retained winner, not idle */
  CHECK(___gc_root_task_finish(&task,1,ca.won ? ca.owner : cb.owner));
  CHECK(!___gc_root_task_finish(&task,1,ca.won ? ca.owner : cb.owner));
  CHECK(___gc_origin_thaw(&task,1));
  CHECK(!___gc_origin_freeze(&origin,&context,1));
  CHECK(___gc_origin_freeze(&origin,&context,___MAX_FIX));
  CHECK(!___gc_origin_freeze(&origin,&context,1));
  puts("CLAIM-RACE-PASS");

  memset(&arena,0,sizeof(arena));
  arena.base = arena.cursor = words;
  arena.limit = words+32;
  CHECK(!___gc_arena_reserve(&arena,33));
  CHECK(___gc_arena_reserve(&arena,8));
  begin = arena.pending; past = arena.pending_past;
  CHECK(!___gc_arena_reserve(&arena,1));
  CHECK(!___gc_arena_settle(&arena,begin+1,past,1));
  CHECK(arena.cursor == words+8);
  CHECK(___gc_arena_settle(&arena,begin,past,1));
  CHECK(arena.cursor == words);
  CHECK(!___gc_arena_settle(&arena,begin,past,1));
  CHECK(___gc_arena_reserve(&arena,32));
  CHECK(___gc_arena_settle(&arena,words,words+32,0));
  CHECK(arena.cursor == arena.limit);
  CHECK(!___gc_arena_reserve(&arena,1));
  puts("ARENA-PASS");
  return 0;
}
