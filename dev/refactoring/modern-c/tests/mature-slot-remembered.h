#ifndef GAMBIT_TEST_MATURE_SLOT_REMEMBERED_H
#define GAMBIT_TEST_MATURE_SLOT_REMEMBERED_H

#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

/* DEV p1 prototype. Domain indices identify stable, independently enumerated
 * mature slots. Calls are serialized by the fixture. The visitor must finish
 * the repair and report the destination generation without allocating. */
struct mature_slot_log {
  size_t *indices;
  size_t capacity;
  size_t count;
  bool overflow;
};

static inline void mature_slot_record(struct mature_slot_log *log, size_t index)
{
  if (log->overflow)
    return;
  for (size_t i = 0; i < log->count; i++)
    if (log->indices[i] == index)
      return;
  if (log->count == log->capacity)
    log->overflow = true;
  else
    log->indices[log->count++] = index;
}

static inline void mature_slot_store(struct mature_slot_log *log,
                                     uintptr_t *const *domain, size_t index,
                                     uintptr_t value)
{
  mature_slot_record(log, index);
  *domain[index] = value;
}

/* The next bank must have separate storage. The caller installs it before
 * reopening writers. Sticky overflow is an enumeration obligation for this
 * round and can be earned independently by the next bank. */
static inline size_t
mature_slot_scan(const struct mature_slot_log *current,
                 struct mature_slot_log *next,
                 uintptr_t *const *domain, size_t domain_count,
                 bool (*repair)(uintptr_t *, void *), void *context)
{
  const size_t count = current->overflow ? domain_count : current->count;
  next->count = 0;
  next->overflow = false;
  for (size_t i = 0; i < count; i++) {
    size_t index = current->overflow ? i : current->indices[i];
    if (repair(domain[index], context))
      mature_slot_record(next, index);
  }
  return count;
}

#endif
