/*
 * PLATFORM FEASIBILITY ONLY.
 * NOT-RUNTIME-ACCEPTANCE.
 * Not runtime pending-join acceptance and not a wrapper self-join.
 * A still-joinable target that surfaces EDEADLK does not prove Gambit error retry.
 *
 * Main B creates owner A. A creates worker W. No self-join.
 * W announces, then pthread_join(A). A waits for that announcement, delays a
 * fixed 20ms (not proof of call entry), then pthread_join(W).
 * Pass only if A observes real EDEADLK, W's join of A returns 0, then B's
 * join of W returns 0. If W observes EDEADLK, the result is INCONCLUSIVE.
 * Every pthread_join below is the real libc call. No synthetic wrapper.
 */

#include <errno.h>
#include <pthread.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

static pthread_t owner_a;
static pthread_t worker_w;

static atomic_int a_id_published = ATOMIC_VAR_INIT(0);
static atomic_int worker_published = ATOMIC_VAR_INIT(0);
static atomic_int w_announced = ATOMIC_VAR_INIT(0);
static atomic_int owner_returned = ATOMIC_VAR_INIT(0);
static atomic_int a_join_result = ATOMIC_VAR_INIT(0);
static atomic_int w_join_result = ATOMIC_VAR_INIT(0);
static atomic_int a_joined = ATOMIC_VAR_INIT(0);
static atomic_int test_done = ATOMIC_VAR_INIT(0);

static int64_t mono_ms(void)
{
    struct timespec ts;
    if (clock_gettime(CLOCK_MONOTONIC, &ts) != 0) {
        printf("FAIL clock_gettime\n");
        fflush(stdout);
        _exit(2);
    }
    return (int64_t)ts.tv_sec * 1000 + (int64_t)ts.tv_nsec / 1000000;
}

/* Own coordination waits. pthread_join itself is not timed here. */
static void wait_flag(atomic_int *flag, const char *what)
{
    const int64_t deadline = mono_ms() + 2000;
    while (atomic_load_explicit(flag, memory_order_acquire) == 0) {
        if (mono_ms() > deadline) {
            printf("FAIL timeout %s\n", what);
            fflush(stdout);
            _exit(2);
        }
        struct timespec step;
        step.tv_sec = 0;
        step.tv_nsec = 1000000L;
        nanosleep(&step, NULL);
    }
}

static void *watchdog(void *arg)
{
    (void)arg;
    const int64_t deadline = mono_ms() + 5000;
    while (mono_ms() < deadline) {
        if (atomic_load_explicit(&test_done, memory_order_acquire) != 0)
            return NULL;
        struct timespec step;
        step.tv_sec = 0;
        step.tv_nsec = 50000000L;
        nanosleep(&step, NULL);
    }
    if (atomic_load_explicit(&test_done, memory_order_acquire) == 0) {
        printf("FAIL watchdog blocked pthread\n");
        fflush(stdout);
        _exit(3);
    }
    return NULL;
}

static void *worker_main(void *arg)
{
    (void)arg;
    /* A id is published by main before W is created; acquire before use. */
    wait_flag(&a_id_published, "W wait A id");

    atomic_store_explicit(&w_announced, 1, memory_order_release);

    int rc = pthread_join(owner_a, NULL);
    atomic_store_explicit(&w_join_result, rc, memory_order_release);

    if (rc == EDEADLK) {
        printf("INCONCLUSIVE W EDEADLK\n");
        fflush(stdout);
        _exit(4);
    }
    if (rc != 0) {
        printf("FAIL W join A rc=%d\n", rc);
        fflush(stdout);
        _exit(5);
    }

    atomic_store_explicit(&a_joined, 1, memory_order_release);
    return NULL;
}

static void *owner_main(void *arg)
{
    (void)arg;
    wait_flag(&a_id_published, "A wait A id");

    int crc = pthread_create(&worker_w, NULL, worker_main, NULL);
    if (crc != 0) {
        printf("FAIL create W rc=%d\n", crc);
        fflush(stdout);
        _exit(6);
    }
    /* Publish W before main reads the handle. */
    atomic_store_explicit(&worker_published, 1, memory_order_release);

    wait_flag(&w_announced, "A wait W announcement");

    /* Fixed 20ms. This does not prove W has entered pthread_join. */
    struct timespec delay;
    delay.tv_sec = 0;
    delay.tv_nsec = 20000000L;
    nanosleep(&delay, NULL);

    int rc = pthread_join(worker_w, NULL);
    atomic_store_explicit(&a_join_result, rc, memory_order_release);
    atomic_store_explicit(&owner_returned, 1, memory_order_release);

    printf("THREAD-CYCLE-A-ERROR %d\n", rc);
    fflush(stdout);

    if (rc == 0) {
        /* Join consumed W. Do not hand W to main. */
        printf("FAIL A consumed W\n");
        fflush(stdout);
        _exit(7);
    }
    if (rc != EDEADLK) {
        printf("FAIL A join W rc=%d\n", rc);
        fflush(stdout);
        _exit(8);
    }

    /* EDEADLK leaves W joinable. A exits without joining W again. */
    return NULL;
}

int main(void)
{
    printf("NOT-RUNTIME-ACCEPTANCE\n");
    fflush(stdout);

    atomic_init(&a_id_published, 0);
    atomic_init(&worker_published, 0);
    atomic_init(&w_announced, 0);
    atomic_init(&owner_returned, 0);
    atomic_init(&a_join_result, 0);
    atomic_init(&w_join_result, 0);
    atomic_init(&a_joined, 0);
    atomic_init(&test_done, 0);

    pthread_t watchdog_thread;
    int wrc = pthread_create(&watchdog_thread, NULL, watchdog, NULL);
    if (wrc != 0) {
        printf("FAIL create watchdog rc=%d\n", wrc);
        fflush(stdout);
        _exit(9);
    }

    int arc = pthread_create(&owner_a, NULL, owner_main, NULL);
    if (arc != 0) {
        printf("FAIL create A rc=%d\n", arc);
        fflush(stdout);
        _exit(10);
    }
    /* Publish A before A creates W, so W never starts with an unpublished A. */
    atomic_store_explicit(&a_id_published, 1, memory_order_release);

    wait_flag(&worker_published, "main wait W published");
    wait_flag(&a_joined, "main wait A joined");
    wait_flag(&owner_returned, "main wait owner returned");

    int a_rc = atomic_load_explicit(&a_join_result, memory_order_acquire);
    int join_w_rc = atomic_load_explicit(&w_join_result, memory_order_acquire);
    if (a_rc != EDEADLK || join_w_rc != 0) {
        printf("FAIL observed A=%d W=%d\n", a_rc, join_w_rc);
        fflush(stdout);
        _exit(11);
    }

    /* B joins W only after W recorded that A was joined. Never join A. */
    int b_rc = pthread_join(worker_w, NULL);
    printf("B-REAL-JOIN %d\n", b_rc);
    fflush(stdout);
    if (b_rc != 0) {
        printf("FAIL B join W rc=%d\n", b_rc);
        fflush(stdout);
        _exit(12);
    }

    printf("PASS EDEADLK then join 0\n");
    printf("feasible EDEADLK with still-joinable target does not prove Gambit error retry\n");
    fflush(stdout);
    atomic_store_explicit(&test_done, 1, memory_order_release);
    if (pthread_join(watchdog_thread, NULL) != 0) return 13;
    return 0;
}
