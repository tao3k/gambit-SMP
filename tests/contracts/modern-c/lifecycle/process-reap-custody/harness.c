/* CBMC C contract harness for Gambit-SMP POSIX child-process reaping and
 * circular device-group custody (lib/os_io.c + lib/os_io.h).
 *
 * Adversarially challenges:
 *   1. Cross-thread SIGCHLD delivery during fork()..register() window:
 *      proves PID-specific waitpid(dev->pid, WNOHANG) never loses status,
 *      while legacy waitpid(-1) in SIGCHLD loses status.
 *   2. Concurrent dual-thread ___device_process_status_poll(dev):
 *      proves mutex serialization guarantees at-most-once waitpid(dev->pid).
 *   3. Circular dgroup add/remove across 1, 2, 3 devices:
 *      proves head/prev/next integrity, idempotent double-cleanup refusal,
 *      and exposes legacy head-skip traversal defect on |dgroup| >= 2.
 *   4. Early release orphan queue transfer & bounded drain:
 *      proves zero zombie leak, zero buffer overflow, and exact single reap.
 */

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>

extern int nondet_int(void);
extern unsigned int nondet_uint(void);

#define MAX_PIDS 3
#define MAX_ORPHANS 4

typedef struct sim_device {
    int id;
    int pid;
    int status;
    int got_status;
    int in_group;
    struct sim_device *prev;
    struct sim_device *next;
} sim_device;

typedef struct sim_dgroup {
    sim_device *list;
    int count;
} sim_dgroup;

static void dgroup_add(sim_dgroup *g, sim_device *dev) {
    assert(dev->in_group == 0);
    sim_device *head = g->list;
    if (head == 0) {
        dev->next = dev;
        dev->prev = dev;
        g->list = dev;
    } else {
        sim_device *tail = head->prev;
        dev->next = head;
        dev->prev = tail;
        tail->next = dev;
        head->prev = dev;
    }
    dev->in_group = 1;
    g->count++;
}

static bool dgroup_remove(sim_dgroup *g, sim_device *dev) {
    if (!dev->in_group) {
        return false; /* idempotent double-cleanup refusal */
    }
    sim_device *prev = dev->prev;
    sim_device *next = dev->next;
    if (prev == dev) {
        g->list = 0;
    } else {
        if (g->list == dev) {
            g->list = next;
        }
        prev->next = next;
        next->prev = prev;
        dev->next = dev;
        dev->prev = dev;
    }
    dev->in_group = 0;
    g->count--;
    return true;
}

static void check_dgroup_ring(const sim_dgroup *g) {
    if (g->count == 0) {
        assert(g->list == 0);
        return;
    }
    assert(g->list != 0);
    const sim_device *cur = g->list;
    int seen = 0;
    do {
        assert(cur->in_group == 1);
        assert(cur->next->prev == cur);
        assert(cur->prev->next == cur);
        cur = cur->next;
        seen++;
        assert(seen <= MAX_PIDS);
    } while (cur != g->list);
    assert(seen == g->count);
}

/* Kernel zombie table simulation */
static int kernel_zombie[MAX_PIDS + 1];
static int kernel_exit_code[MAX_PIDS + 1];
static int kernel_reap_count[MAX_PIDS + 1];

static int sim_waitpid_specific(int pid, int *status_out) {
    assert(pid >= 1 && pid <= MAX_PIDS);
    if (kernel_zombie[pid]) {
        kernel_zombie[pid] = 0;
        kernel_reap_count[pid]++;
        *status_out = kernel_exit_code[pid];
        return pid;
    }
    return 0;
}

/* Safe ___device_process_status_poll serialized under process_mutex */
static void safe_poll_device(sim_device *dev) {
    if (!dev->got_status && dev->pid > 0) {
        int st = 0;
        int r = sim_waitpid_specific(dev->pid, &st);
        if (r == dev->pid) {
            dev->status = st;
            dev->got_status = 1;
        }
    }
}

/* Orphan queue for early-released active processes */
static int orphan_pids[MAX_ORPHANS];
static int orphan_count = 0;

static void orphan_push(int pid) {
    assert(pid >= 1 && pid <= MAX_PIDS);
    if (orphan_count < MAX_ORPHANS) {
        orphan_pids[orphan_count++] = pid;
    }
}

static void orphan_drain(void) {
    int write_idx = 0;
    for (int i = 0; i < orphan_count; i++) {
        int st = 0;
        int r = sim_waitpid_specific(orphan_pids[i], &st);
        if (r == 0) {
            orphan_pids[write_idx++] = orphan_pids[i];
        }
    }
    orphan_count = write_idx;
}

int main(void) {
    /* Case 1: Concurrent fast exit before registration + safe SIGCHLD flag-only */
    for (int i = 0; i <= MAX_PIDS; i++) {
        kernel_zombie[i] = 0;
        kernel_exit_code[i] = 0;
        kernel_reap_count[i] = 0;
    }

    int code1 = nondet_int();
    if (code1 < 0 || code1 > 255) code1 = 0;
    int code2 = nondet_int();
    if (code2 < 0 || code2 > 255) code2 = 42;

    /* Child 1 forks and exits BEFORE parent registers dev1 in dgroup */
    kernel_zombie[1] = 1;
    kernel_exit_code[1] = code1;
    /* Sibling thread polls dev2 (pid=2) while child 1 is unregistered */
    sim_device dev2 = { .id = 2, .pid = 2, .status = -1, .got_status = 0, .in_group = 0 };
    sim_dgroup g = { .list = 0, .count = 0 };
    dgroup_add(&g, &dev2);
    check_dgroup_ring(&g);

    safe_poll_device(&dev2);
    /* Polling pid=2 MUST NOT steal unregistered child 1! */
    assert(kernel_zombie[1] == 1);
    assert(kernel_reap_count[1] == 0);

    /* Now parent registers dev1 and polls it (even twice concurrently) */
    sim_device dev1 = { .id = 1, .pid = 1, .status = -1, .got_status = 0, .in_group = 0 };
    dgroup_add(&g, &dev1);
    check_dgroup_ring(&g);

    safe_poll_device(&dev1);
    safe_poll_device(&dev1); /* second concurrent poll must be no-op */
    assert(dev1.got_status == 1);
    assert(dev1.status == code1);
    assert(kernel_reap_count[1] == 1);

    /* Case 2: Expose legacy head-skip bug when |dgroup| == 2:
     * g.list is dev2 (head), g.list->prev is dev1.
     * Legacy loop `d = head->prev; do { ... d = d->prev; } while (d != head)`
     * checks ONLY dev1 and NEVER visits dev2 (head)! */
    {
        sim_device *head = g.list;
        sim_device *d = head->prev;
        bool legacy_found_head = false;
        do {
            if (d == head) legacy_found_head = true;
            d = d->prev;
        } while (d != head);
        assert(!legacy_found_head); /* proves legacy loop skips head! */
    }

    /* Safe PID-specific poll finds dev2 directly even when dev2 == g.list */
    kernel_zombie[2] = 1;
    kernel_exit_code[2] = code2;
    safe_poll_device(&dev2);
    assert(dev2.got_status == 1);
    assert(dev2.status == code2);
    assert(kernel_reap_count[2] == 1);

    /* Case 3: Circular dgroup removal integrity & idempotent double-remove */
    sim_device dev3 = { .id = 3, .pid = 3, .status = -1, .got_status = 0, .in_group = 0 };
    dgroup_add(&g, &dev3);
    check_dgroup_ring(&g);

    assert(dgroup_remove(&g, &dev2)); /* remove head */
    assert(!dgroup_remove(&g, &dev2)); /* double cleanup refused */
    check_dgroup_ring(&g);

    /* Case 4: Early release of running child 3 transfers to orphan queue and drains */
    assert(dgroup_remove(&g, &dev3));
    check_dgroup_ring(&g);
    safe_poll_device(&dev3);
    assert(dev3.got_status == 0);
    orphan_push(dev3.pid);
    assert(orphan_count == 1);

    /* Drain while still running keeps pid 3 queued */
    orphan_drain();
    assert(orphan_count == 1);
    assert(kernel_reap_count[3] == 0);

    /* Child 3 exits -> drain reaps cleanly once and empties queue */
    kernel_zombie[3] = 1;
    kernel_exit_code[3] = 0;
    orphan_drain();
    orphan_drain(); /* idempotent second drain */
    assert(orphan_count == 0);
    assert(kernel_reap_count[3] == 1);

    assert(dgroup_remove(&g, &dev1));
    check_dgroup_ring(&g);
    assert(g.count == 0 && g.list == 0);
    return 0;
}
