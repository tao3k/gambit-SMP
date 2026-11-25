/* The Recipe projects Gambit's resize, movable rearm, and GC return code.
 * Census, allocator availability and section selection are fixture inputs. */
typedef long ___WORD;
typedef long ___SIZE_TS;
typedef long ___PTRDIFF_T;
typedef int ___BOOL;
typedef double ___F64;

#define ___P(proto, old) proto
#define ___HIDDEN
#define ___CAST(type, value) ((type)(value))
#define ___LWS 3
#define ___WS 8
#define ___PAIR_BODY 1
#define ___SUBTYPED_BODY 1
#define ___VECTOR_BODY 1
#define ___PAIR_SIZE 2
#define INT_MAX 2147483647
#define SET_MAX(target, bound) do { if ((target)<(bound)) (target)=(bound); } while (0)
#define SET_MIN(target, bound) do { if ((target)>(bound)) (target)=(bound); } while (0)
#define CHECK(condition, property) __CPROVER_assert((condition),(property))

#include "section-geometry.inc"

typedef struct { int nb_sections; ___WORD *head; } section_pool;
typedef struct fixture_vm { int processor_count; } *___virtual_machine_state;
typedef struct { ___WORD *hp; } execution_context;
typedef struct fixture_processor {
  execution_context *context;
  ___WORD *heap_limit;
} *___processor_state;

static struct { struct { ___SIZE_TS max_heap; } setup_params; } setup;
#define ___GSTATE (&setup)

static ___SIZE_TS occupied_words_still, occupied_words_movable, heap_size;
static ___SIZE_TS overflow_reserve, normal_overflow_reserve;
static int nb_msections_assigned=2, nb_msections_stacks=1;
static section_pool *the_msections;
static ___F64 latest_gc_heap_size, latest_gc_live, latest_gc_movable, latest_gc_still;
static ___WORD *heap_msection, *alloc_heap_start, *alloc_heap_ptr, *alloc_heap_limit;
static _Bool backing_available;
static _Bool reserve_available;
static unsigned section_changes;

#define ALLOC_MEM_LOCK() ((void)0)
#define ALLOC_MEM_UNLOCK() ((void)0)
#define ___ACTLOG_END_PS() ((void)0)
#define ___PROCESSOR_ID(ps, vm) 0
#define REST_OBS(...) ((void)0)

static void determine_occupied_words(___virtual_machine_state vm) { (void)vm; }
static int compute_nb_msections_min(int processors) { return 2*processors; }
static int ___restore_msections(___virtual_machine_state vm) { (void)vm; return 0; }
static int ___resume_msections(___virtual_machine_state vm) { (void)vm; return 0; }
static int max_target_heap_space_in_recent_history(___virtual_machine_state vm) { (void)vm; return 0; }
static ___SIZE_TS adjust_heap(___SIZE_TS live) { return live; }
static int compute_nb_msections_needed(___SIZE_TS words) { (void)words; return 4; }
static ___SIZE_TS compute_free_heap_space_in_msections(int sections)
{
  (void)sections;
  return reserve_available ? normal_overflow_reserve : 0;
}

static void fatal_heap_overflow(void)
{
  CHECK(0, "resize.no-fatal-overflow-in-recoverable-cases");
  __CPROVER_assume(0);
}

static void adjust_msections(section_pool **pool, int target)
{
  if (backing_available) (*pool)->nb_sections=target;
}

static void add_to_target_heap_space_history(___virtual_machine_state vm, ___SIZE_TS target)
{
  (void)vm;
  (void)target;
}

static ___SIZE_TS compute_heap_size(void)
{
  return (___SIZE_TS)the_msections->nb_sections*___MSECTION_SIZE;
}

static ___SIZE_TS compute_free_heap_space_approximately(void) { return ___MSECTION_SIZE; }

static void set_heap_msection(___processor_state ps, ___WORD *base)
{
  (void)ps;
  heap_msection=alloc_heap_start=alloc_heap_ptr=base;
  alloc_heap_limit=base+(___MSECTION_SIZE>>1);
}

static void next_heap_msection(___processor_state ps)
{
  ++section_changes;
  set_heap_msection(ps,the_msections->head);
}

long write(int fd, const void *text, unsigned long size)
{
  (void)fd;
  (void)text;
  (void)size;
  return 0;
}

#include "resize.inc"
#include "publish.inc"
#include "rearm.inc"
#include "caller-overflow.inc"

static ___BOOL end_collection(___processor_state ___ps, ___virtual_machine_state ___vms,
                              ___SIZE_TS requested_words_still, ___BOOL overflow)
{
#include "epilogue.inc"
}

_Bool nondet_bool(void);

void still_reservation_contract(void)
{
  ___WORD old_half[___MSECTION_SIZE>>1], next_half[___MSECTION_SIZE>>1];
  const _Bool already_ready=nondet_bool();
  const ___SIZE_TS words=nondet_bool()?7:0;
  const ___SIZE_TS occupied_before=31;
  struct fixture_vm vm={.processor_count=1};
  section_pool pool={.nb_sections=4,.head=next_half};
  execution_context context={.hp=old_half+(already_ready?1:(___MSECTION_SIZE>>1)-1)};
  struct fixture_processor ps={.context=&context,
    .heap_limit=old_half+(___MSECTION_SIZE>>1)-___MSECTION_FUDGE};

  backing_available=nondet_bool();
  reserve_available=nondet_bool();
  setup.setup_params.max_heap=0;
  occupied_words_still=occupied_before;
  occupied_words_movable=8;
  overflow_reserve=normal_overflow_reserve=___DEFAULT_NORMAL_OVERFLOW_RESERVE;
  the_msections=&pool;
  set_heap_msection(&ps,old_half);
  alloc_heap_ptr=context.hp;

  ___BOOL resized_overflow=resize_heap(&vm,words);
  CHECK(resized_overflow==(!backing_available || !reserve_available),
        "resize.observe-real-refusal");
  CHECK(occupied_words_still==occupied_before+(resized_overflow?0:words),
        "resize.charge-or-rollback-once");

  ___BOOL result=end_collection(&ps,&vm,words,resized_overflow);
  CHECK(section_changes==(already_ready?0u:1u) && context.hp==alloc_heap_ptr &&
        context.hp<=ps.heap_limit && ps.heap_limit==alloc_heap_limit-___MSECTION_FUDGE,
        "epilogue.movable-interval-usable-with-reserve");
  if (words==0)
    CHECK(!result && occupied_words_still==occupied_before, "epilogue.zero-word-recovers");
  else if (resized_overflow)
    CHECK(result && occupied_words_still==occupied_before, "epilogue.still-rollback-stays-refused");
  else
    CHECK(!result && occupied_words_still==occupied_before+words, "epilogue.still-grant-preserves-charge");
}
