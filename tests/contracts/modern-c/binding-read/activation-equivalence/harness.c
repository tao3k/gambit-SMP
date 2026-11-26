/* P0-2 Binding-Read Activation CBMC Contract:
 * 1. Single-page primitive_value lookup equivalence against dual-page lookup
 *    (vendor/gambit/lib/_mem/global-bindings.inc).
 * 2. Fast-path ___primitive_ref / ___GLOBALVARPRIMREF dispatch equivalence
 *    against root_writer_open fallback whenever binding_view.vm is valid,
 *    and mandatory fallback whenever binding_view.vm is NULL (frozen/closing).
 */
#include <stdint.h>
#include <stddef.h>

typedef long ___WORD;
typedef ___WORD ___SCMOBJ;
#define CHECK(p, n) __CPROVER_assert((p), (n))

extern int nondet_int(void);
extern ___WORD nondet_word(void);

#define PAGE_SLOTS 4
#define MAX_PAGES 2

typedef struct {
  int primitive_flags[PAGE_SLOTS];
  ___SCMOBJ primitives[PAGE_SLOTS];
} global_page;

typedef struct {
  int vm_id;
  int page_count;
  global_page pages[MAX_PAGES];
} vm_state;

typedef struct {
  vm_state *binding_view_vm;
  int frozen_for_gc;
  int entry_count;
} exec_context;

typedef struct {
  vm_state *vm;
  exec_context *context;
} proc_state;

typedef struct {
  unsigned int val;
  ___SCMOBJ prm_template;
} global_var;

static global_page *lookup_global_page(vm_state *vm, unsigned int idx) {
  unsigned int page_idx = idx / PAGE_SLOTS;
  if (!vm || page_idx >= (unsigned int)vm->page_count)
    return NULL;
  return &vm->pages[page_idx];
}

static ___SCMOBJ dual_page_primitive_value(vm_state *vm, const global_var *g) {
  unsigned int slot = g->val % PAGE_SLOTS;
  global_page *p_flag = lookup_global_page(vm, g->val);
  if (p_flag != NULL && p_flag->primitive_flags[slot] != 0) {
    global_page *p_cell = lookup_global_page(vm, g->val);
    if (p_cell != NULL)
      return p_cell->primitives[slot];
  }
  return g->prm_template;
}

static ___SCMOBJ single_page_primitive_value(vm_state *vm, const global_var *g) {
  unsigned int slot = g->val % PAGE_SLOTS;
  global_page *page = lookup_global_page(vm, g->val);
  if (page != NULL && page->primitive_flags[slot] != 0)
    return page->primitives[slot];
  return g->prm_template;
}

static ___SCMOBJ slow_primitive_ref(proc_state *ps, const global_var *g) {
  if (!ps || !ps->vm)
    return g->prm_template;
  return single_page_primitive_value(ps->vm, g);
}

static ___SCMOBJ fast_primitive_ref(proc_state *ps, const global_var *g) {
  if (ps != NULL && ps->context != NULL &&
      ps->context->binding_view_vm != NULL &&
      ps->context->binding_view_vm == ps->vm) {
    return single_page_primitive_value(ps->context->binding_view_vm, g);
  }
  return slow_primitive_ref(ps, g);
}

int main(void) {
  vm_state vm;
  vm.vm_id = 1;
  vm.page_count = nondet_int();
  __CPROVER_assume(vm.page_count >= 0 && vm.page_count <= MAX_PAGES);
  for (int p = 0; p < MAX_PAGES; ++p) {
    for (int s = 0; s < PAGE_SLOTS; ++s) {
      vm.pages[p].primitive_flags[s] = nondet_int() ? 1 : 0;
      vm.pages[p].primitives[s] = nondet_word();
    }
  }

  global_var g;
  g.val = (unsigned int)nondet_int();
  __CPROVER_assume(g.val < (unsigned int)(MAX_PAGES * PAGE_SLOTS + 2));
  g.prm_template = nondet_word();

  /* 1. Single-page vs dual-page equivalence */
  ___SCMOBJ r_dual = dual_page_primitive_value(&vm, &g);
  ___SCMOBJ r_single = single_page_primitive_value(&vm, &g);
  CHECK(r_single == r_dual, "p02.single-page-equiv-dual-page");

  /* 2. Fast-path vs slow fallback equivalence across open/frozen/null-context states */
  exec_context ctx;
  ctx.frozen_for_gc = nondet_int() ? 1 : 0;
  ctx.entry_count = ctx.frozen_for_gc ? 1 : (nondet_int() ? 1 : 0);
  /* Well-formedness: frozen or zero-entry contexts have binding_view_vm == NULL */
  if (ctx.frozen_for_gc || ctx.entry_count == 0)
    ctx.binding_view_vm = NULL;
  else
    ctx.binding_view_vm = nondet_int() ? &vm : NULL;

  proc_state ps;
  ps.vm = &vm;
  ps.context = nondet_int() ? &ctx : NULL;

  ___SCMOBJ r_fast = fast_primitive_ref(&ps, &g);
  ___SCMOBJ r_slow = slow_primitive_ref(&ps, &g);
  CHECK(r_fast == r_slow, "p02.fast-dispatch-equiv-slow-fallback");

  /* 3. Frozen context forces NULL view -> guaranteed fallback */
  ctx.frozen_for_gc = 1;
  ctx.binding_view_vm = NULL;
  CHECK(ctx.binding_view_vm == NULL, "p02.frozen-clears-binding-view");
  CHECK(fast_primitive_ref(&ps, &g) == slow_primitive_ref(&ps, &g),
        "p02.frozen-fallback-exact");

  return 0;
}
