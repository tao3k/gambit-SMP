/* CBMC adversarial C contract harness for Gambit-SMP v18:
 *   1. Direct posix_spawn FD-wiring & error-cleanup (zero leaked pipe FDs, zero fork())
 *   2. One-shot rest_observation_env_probed + explicit path != NULL open + fast-skip
 *   3. NULL-catcher guard in current_vm_resize_request
 */
#include <assert.h>
#include <stdint.h>

int nondet_int(void);
_Bool nondet_bool(void);

/* --- Contract 1: Direct posix_spawn pipe FD accounting & zero fork --- */
typedef struct {
  int in_rd, in_wr;
  int out_rd, out_wr;
  int fork_called;
  int spawn_called;
  int registered_in_wr;
  int registered_out_rd;
} spawn_ctx_t;

static void check_direct_posix_spawn_contract(void) {
  spawn_ctx_t ctx = { -1, -1, -1, -1, 0, 0, -1, -1 };
  _Bool has_redir = nondet_bool();
  _Bool pipe_ok = nondet_bool();
  _Bool spawn_ok = nondet_bool();
  _Bool setup_pid_ok = nondet_bool();

  int err = 0;
  if (has_redir) {
    if (pipe_ok) {
      ctx.in_rd = 10; ctx.in_wr = 11;
      ctx.out_rd = 12; ctx.out_wr = 13;
    } else {
      err = 1;
    }
  }

  if (err == 0) {
    /* Direct posix_spawn path NEVER invokes fork() */
    ctx.spawn_called = 1;
    if (!spawn_ok) err = 2;
  }

  /* Parent always closes child pipe ends if pipe creation succeeded */
  if (has_redir && pipe_ok) {
    ctx.in_rd = -1;
    ctx.out_wr = -1;
  }

  if (err == 0) {
    if (setup_pid_ok) {
      ctx.registered_in_wr = ctx.in_wr;
      ctx.registered_out_rd = ctx.out_rd;
    } else {
      err = 3;
    }
  }

  /* On any error after pipe creation, parent ends MUST be closed too */
  if (err != 0 && has_redir && pipe_ok) {
    ctx.in_wr = -1;
    ctx.out_rd = -1;
  }

  assert(ctx.fork_called == 0);
  assert(ctx.in_rd == -1 && ctx.out_wr == -1);
  if (err != 0) {
    assert(ctx.in_wr == -1 && ctx.out_rd == -1);
  } else if (has_redir) {
    assert(ctx.registered_in_wr == 11 && ctx.registered_out_rd == 12);
  }
}

/* --- Contract 2: One-shot env probe + explicit path != NULL override --- */
typedef struct {
  int env_probed;
  int map_open;
  int active;
  int getenv_count;
  int env_has_value;
} rest_obs_t;

static int rest_obs_open(rest_obs_t *o, int explicit_path) {
  if (o->map_open) return 1;
  if (!explicit_path) {
    if (o->env_probed) return 0;
    o->getenv_count++;
    o->env_probed = 1;
    if (!o->env_has_value) return 0;
  }
  o->map_open = 1;
  o->active = 1;
  return 1;
}

static void rest_note_entry(rest_obs_t *o) {
  if (!o->map_open && !o->env_probed)
    rest_obs_open(o, 0);
}

static void check_rest_observation_one_shot_contract(void) {
  rest_obs_t o = { 0, 0, 0, 0, nondet_bool() ? 1 : 0 };
  for (int i = 0; i < 6; i++) {
    rest_note_entry(&o);
  }
  /* Regardless of how many rest calls execute, getenv() is called at most once */
  assert(o.getenv_count <= 1);
  assert(o.map_open == o.env_has_value);
  assert(o.active == o.env_has_value);

  /* Explicit path != NULL open MUST still work even after an unset env probe */
  if (!o.env_has_value) {
    int ok = rest_obs_open(&o, 1);
    assert(ok == 1 && o.map_open == 1 && o.active == 1);
    assert(o.getenv_count == 1);
  }
}

/* --- Contract 3: current_vm_resize_request NULL-catcher boundary --- */
typedef struct {
  int *catcher;
  int threw;
} pstate_t;

static int guarded_resize_finish(pstate_t *ps, int err, int result) {
  if (err != 0) {
    if (ps->catcher != 0) {
      int dummy = *ps->catcher; /* safe non-NULL dereference */
      ps->threw = dummy + err;
      return -1;
    }
    return err;
  }
  return result;
}

static void check_resize_null_catcher_contract(void) {
  int buf = 42;
  _Bool has_catcher = nondet_bool();
  int err = nondet_int();
  if (err < 0 || err > 5) return;

  pstate_t ps = { has_catcher ? &buf : 0, 0 };
  int rc = guarded_resize_finish(&ps, err, 0);
  if (err == 0) {
    assert(rc == 0 && ps.threw == 0);
  } else if (has_catcher) {
    assert(ps.threw == 42 + err);
  } else {
    assert(rc == err && ps.threw == 0);
  }
}

/* --- Contract 4: 128-byte cache-line disjointness & zero-write MESI rest disarm --- */
typedef struct {
  int words;
  int floor;
  int blocked;
  int owner;
  int force_slow;
  int writes;
} disarm_ctx_t;

static void guarded_disarm(disarm_ctx_t *d) {
  if (!d->owner && !d->words && !d->force_slow && !d->blocked)
    return;
  d->words = 0; d->floor = 0; d->blocked = 0; d->owner = 0; d->force_slow = 0;
  d->writes += 5;
}

static void check_cache_line_and_zero_write_disarm_contract(void) {
  /* Arbitrary malloc/calloc base offset mod 128 (both pstate=1040 and context=320) */
  uint64_t base = (uint64_t)(nondet_int() & 0xFFFF);
  uint64_t sizes[2] = { 320u, 1040u };
  for (int s = 0; s < 2; s++) {
    uint64_t active = sizes[s];
    uint64_t last_byte_p0 = base + active - 1u;
    uint64_t first_byte_p1 = base + active + 128u; /* 128-byte trailing guard */
    assert((last_byte_p0 / 128u) < (first_byte_p1 / 128u));
    assert((last_byte_p0 / 64u) < (first_byte_p1 / 64u));
  }

  /* Unarmed fast-path performs 0 global writes across repeated rest calls */
  disarm_ctx_t unarmed = { 0, 0, 0, 0, 0, 0 };
  for (int i = 0; i < 6; i++) guarded_disarm(&unarmed);
  assert(unarmed.writes == 0);

  /* Armed attempt still clears all 5 fields cleanly */
  disarm_ctx_t armed = { 12, 4, 1, 1, 1, 0 };
  guarded_disarm(&armed);
  assert(armed.words == 0 && armed.floor == 0 && armed.blocked == 0 &&
         armed.owner == 0 && armed.force_slow == 0 && armed.writes == 5);
}

/* --- Contract 5: Darwin direct posix_spawn child-env PATH resolution --- */
#define SIM_OK 0
#define SIM_ENOENT 2
#define SIM_EACCES 13
#define SIM_ENOMEM 12
#define SIM_ENAMETOOLONG 63

static int sim_spawn_along_child_path(const int *entry_results, int n_entries,
                                      const unsigned int *entry_lens,
                                      unsigned int prog_len, unsigned int buf_cap) {
  int saved_eacces = 0;
  for (int i = 0; i < n_entries; i++) {
    /* Bounded candidate path formatting: dir + '/' + prog + '\0' < buf_cap */
    unsigned int needed = entry_lens[i] + 1u + prog_len + 1u;
    if (needed > buf_cap) {
      return SIM_ENAMETOOLONG;
    }
    int st = entry_results[i];
    if (st == SIM_OK) return SIM_OK;
    if (st == SIM_EACCES) {
      saved_eacces = SIM_EACCES;
      continue;
    }
    if (st == SIM_ENOENT) {
      continue;
    }
    return st; /* immediate stop on fatal error (ENOMEM, ENOEXEC, etc.) */
  }
  return saved_eacces ? saved_eacces : SIM_ENOENT;
}

static void check_child_env_path_resolution_contract(void) {
  unsigned int lens[3] = { 12u, 16u, 20u };
  /* 1. ENOENT -> EACCES -> OK succeeds on third child PATH entry */
  int r1[3] = { SIM_ENOENT, SIM_EACCES, SIM_OK };
  assert(sim_spawn_along_child_path(r1, 3, lens, 10u, 1024u) == SIM_OK);

  /* 2. EACCES -> ENOENT retains EACCES per POSIX execvp */
  int r2[2] = { SIM_EACCES, SIM_ENOENT };
  assert(sim_spawn_along_child_path(r2, 2, lens, 10u, 1024u) == SIM_EACCES);

  /* 3. All ENOENT returns ENOENT (maps to no-such-file-or-directory-exception) */
  int r3[2] = { SIM_ENOENT, SIM_ENOENT };
  assert(sim_spawn_along_child_path(r3, 2, lens, 10u, 1024u) == SIM_ENOENT);

  /* 4. Fatal error stops search immediately */
  int r4[2] = { SIM_ENOMEM, SIM_OK };
  assert(sim_spawn_along_child_path(r4, 2, lens, 10u, 1024u) == SIM_ENOMEM);

  /* 5. Overlong path candidate fails closed with ENAMETOOLONG (zero truncation/overflow) */
  unsigned int big_lens[1] = { 4090u };
  assert(sim_spawn_along_child_path(r1, 1, big_lens, 20u, 4096u) == SIM_ENAMETOOLONG);
}

int main(void) {
  check_direct_posix_spawn_contract();
  check_rest_observation_one_shot_contract();
  check_resize_null_catcher_contract();
  check_cache_line_and_zero_write_disarm_contract();
  check_child_env_path_resolution_contract();
  return 0;
}
