/*
 * CBMC C contract harness for P0:
 *   1. Bounded-spin + OS-yield backoff arithmetic in ___TICKETLOCK_LOCK2
 *      (zero signed/unsigned overflow, exact yield trigger after SPIN_LIMIT).
 *   2. alloc_scmobj_still tail-floor budget reservation arithmetic
 *      (strict heap conservation: words + extra <= avail, zero underflow/overflow).
 */
#include <assert.h>
#include <stdint.h>
#include <stddef.h>

extern unsigned int nondet_uint(void);
extern size_t nondet_size(void);

static const unsigned int TICKETLOCK_SPIN_LIMIT = 64u;

static unsigned int simulate_backoff_step(unsigned int *spins, unsigned int ticket, unsigned int cur) {
    unsigned int wait = (ticket >= cur) ? (ticket - cur) : 16u;
    if (wait > 16u) wait = 16u;
    if (wait == 0u) wait = 1u;

    if (*spins < TICKETLOCK_SPIN_LIMIT) {
        (*spins)++;
        return 0u; /* spin with ___CPU_RELAX */
    }
    return 1u; /* call ___THREAD_YIELD() */
}

static size_t compute_still_extra(size_t avail, size_t words, size_t proc_count, size_t chunk) {
    if (words > avail) return 0;
    size_t rem = avail - words;
    size_t extra = 0;
    if (rem > 0) {
        size_t denom = 2u * proc_count + 2u;
        size_t cap = rem / denom;
        extra = cap < chunk ? cap : chunk;
        if (extra < words) {
            size_t target = (words <= (SIZE_MAX / 4u)) ? (4u * words) : rem;
            size_t floor_extra = rem < target ? rem : target;
            extra = floor_extra < chunk ? floor_extra : chunk;
        }
    }
    return extra;
}

int main(void) {
    /* 1. Verify bounded spin counter never overflows and yields at SPIN_LIMIT */
    unsigned int spins = 0u;
    unsigned int ticket = nondet_uint();
    unsigned int cur = nondet_uint();
    __CPROVER_assume(ticket != cur);

    for (unsigned int i = 0; i < 64u; ++i) {
        unsigned int yielded = simulate_backoff_step(&spins, ticket, cur);
        assert(yielded == 0u);
    }
    assert(spins == TICKETLOCK_SPIN_LIMIT);
    assert(simulate_backoff_step(&spins, ticket, cur) == 1u);
    assert(spins == TICKETLOCK_SPIN_LIMIT); /* saturated, never overflows */

    /* 2. Verify alloc_scmobj_still budget reservation conservation */
    size_t avail = nondet_size();
    size_t words = nondet_size();
    size_t proc_count = nondet_size();
    size_t chunk = nondet_size();
    __CPROVER_assume(words > 0 && words <= avail);
    __CPROVER_assume(avail <= ((size_t)1u << 30));
    __CPROVER_assume(proc_count >= 1 && proc_count <= 256);
    __CPROVER_assume(chunk >= 1 && chunk <= ((size_t)1u << 24));

    size_t extra = compute_still_extra(avail, words, proc_count, chunk);
    assert(extra <= avail - words);
    assert(words + extra <= avail);
    assert(extra <= chunk);

    /* Concrete p12 m65536 tail-thrash regression check */
    size_t e12 = compute_still_extra(6800u, 262u, 12u, 16384u);
    assert(e12 == 1048u);
    assert(262u + e12 <= 6800u);

    return 0;
}
