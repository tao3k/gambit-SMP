/* Direct consumer of the collector header. It does not execute a GC round. */
#include <stdio.h>
#include <string.h>
#include "collector.h"

#define CHECK(x) do { if (!(x)) return 1; } while (0)
static ___processor_state_struct owner;
static ___processor_state_struct other;
static ___execution_context context;
static ___WORD words[64];

int main(void)
{
  ___gc_worker_arena arena;
  ___gc_resume_space resume;
  memset(&arena, 0, sizeof arena);
  memset(&resume, 0, sizeof resume);
  arena.base = arena.cursor = words;
  arena.limit = words + 32;
  arena.physical_limit = words + 40;
  arena.section = (___msection *)words; /* Identity only; never dereferenced. */
  arena.epoch = 7;
  arena.retired_words = 11;
  resume.context = &context;
  resume.owner = &owner;
  owner.context = &context;
  resume.epoch = 7;
  resume.stack_floor = words + 48;
  owner.mem.words_prev_msections_ = 5;
  context.hp = words + 55;
  other.context = &context;
  CHECK(___gc_resume_owner_matches(&resume, &owner));
  CHECK(!___gc_resume_owner_matches(&resume, &other));
  resume.owner = &other;
  CHECK(!___gc_resume_owner_matches(&resume, &owner));
  resume.owner = &owner;
  resume.owner = 0;
  CHECK(!___gc_arena_handoff(&arena, &resume, 7));
  resume.owner = &owner;
  owner.context = 0;
  CHECK(!___gc_arena_handoff(&arena, &resume, 7));
  owner.context = &context;
  CHECK(!___gc_arena_handoff(&arena, &resume, 8));
  CHECK(___gc_arena_reserve(&arena, 6));
  CHECK(!___gc_arena_handoff(&arena, &resume, 7));
  CHECK(!resume.accepted && owner.mem.words_prev_msections_ == 5);
  CHECK(!___gc_arena_commit(&arena, words + 1, words + 6));
  CHECK(___gc_arena_commit(&arena, words, words + 6));
  CHECK(!___gc_arena_commit(&arena, words, words + 6));
  CHECK(___gc_arena_handoff(&arena, &resume, 7));
  CHECK(owner.mem.alloc_heap_start_ == words && owner.mem.alloc_heap_ptr_ == words + 6);
  CHECK(owner.mem.alloc_heap_limit_ == words + 40 && owner.mem.alloc_stack_limit_ == words + 48);
  CHECK(___gc_resume_heap_interval_matches(words, words + 48, words, words + 6, words + 40));
  CHECK(!___gc_resume_heap_interval_matches(words, words + 48, words, words + 41, words + 40));
  CHECK(!___gc_resume_heap_interval_matches(words, words + 32, words, words + 6, words + 40));
  CHECK(!___gc_resume_heap_interval_matches(words + 1, words + 48, words, words + 6, words + 40));
  CHECK(!___gc_resume_heap_interval_matches(words, words + 48, words,
        (___WORD *)((char *)words + 1), words + 40));
  CHECK(!___gc_resume_heap_needs_refill(words + 8, words + 40, 32));
  CHECK(___gc_resume_heap_needs_refill(words + 9, words + 40, 32));
  CHECK(!___gc_resume_heap_needs_refill(words + 7, words + 40, 32));
  CHECK(___gc_resume_heap_needs_refill(words, words + 1, 32));
  CHECK(owner.mem.words_prev_msections_ == 16 && context.hp == words + 55);
  CHECK(!___gc_arena_handoff(&arena, &resume, 7));
  CHECK(!___gc_arena_reserve(&arena, 1));
  CHECK(owner.mem.words_prev_msections_ == 16);
  memset(&resume, 0, sizeof resume);
  resume.context = &context;
  resume.owner = &owner;
  resume.epoch = 9;
  resume.source_worker = -1;
  resume.stack_section = (___msection *)words;
  resume.loan_base = words;
  resume.loan_limit = words + 24;
  resume.owner = 0;
  CHECK(!___gc_resume_without_arena(&resume, 9));
  resume.owner = &owner;
  owner.context = 0;
  CHECK(!___gc_resume_without_arena(&resume, 9));
  owner.context = &context;
  CHECK(!___gc_resume_without_arena(&resume, 8));
  resume.loan_used = 1;
  CHECK(!___gc_resume_without_arena(&resume, 9));
  resume.loan_used = 0;
  CHECK(___gc_resume_without_arena(&resume, 9));
  CHECK(owner.mem.alloc_heap_start_ == words && owner.mem.alloc_heap_ptr_ == words);
  CHECK(owner.mem.alloc_heap_limit_ == words + 22 && owner.mem.alloc_stack_limit_ == words + 24);
  CHECK(context.hp == words + 55 && !___gc_resume_without_arena(&resume, 9));
  puts("GC-RESUME-ARENA-CONTRACT-PASS");
  return 0;
}
