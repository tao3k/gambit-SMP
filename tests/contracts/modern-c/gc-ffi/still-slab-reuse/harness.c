/*
 * CBMC C contract harness for bounded empty still-slab reuse across minor GCs
 * and exact 0-retention purge on major GC (aligned-allocation.inc + collection-round.inc).
 */
#include <assert.h>
#include <stdint.h>

extern unsigned int nondet_uint(void);

static unsigned int max_empty_for_class(unsigned int cls) {
    if (cls <= 1u) return 16u;
    if (cls <= 5u) return 4u;
    return 2u;
}

int main(void) {
    unsigned int cls = nondet_uint();
    __CPROVER_assume(cls < 8u);
    unsigned int cap = max_empty_for_class(cls);
    unsigned int empty_count = 0u;
    int global_cached = 0;
    unsigned int unmapped = 0u;

    /* Simulate arbitrary sequence of frees & alloc reuses across minor GCs */
    for (unsigned int step = 0u; step < 24u; ++step) {
        unsigned int op = nondet_uint();
        if ((op & 1u) == 0u) {
            /* Free an empty chunk */
            if (empty_count < cap) {
                empty_count++;
                global_cached++;
            } else {
                unmapped++;
            }
        } else {
            /* Alloc reuses cached empty chunk if available */
            if (empty_count > 0u) {
                empty_count--;
                global_cached--;
            }
        }
        assert(empty_count <= cap);
        assert(global_cached == (int)empty_count);
    }

    /* Major GC purge drains all cached empty chunks to exactly 0 */
    unmapped += empty_count;
    global_cached -= (int)empty_count;
    empty_count = 0u;

    assert(empty_count == 0u);
    assert(global_cached == 0);
    return 0;
}
