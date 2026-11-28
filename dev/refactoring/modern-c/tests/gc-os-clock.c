/* Darwin DEV trace clock correlation. Compile with the Apple SDK driver. */
#include <stdint.h>
#include <unistd.h>
#include <os/log.h>
#include <os/signpost.h>
#ifdef DEV_GC_KERNEL_CLOCK
#include <sys/kdebug_signpost.h>

int dev_gc_kernel_clock(unsigned id, uint64_t tid, uint64_t ns)
{
  return kdebug_signpost(0x474, (uintptr_t)ns, id, (uintptr_t)tid, 0x47434c4b);
}
void dev_gc_kernel_publication(unsigned sender, uint64_t identity, uint64_t after)
{
    kdebug_signpost(0x474, (uintptr_t)after, sender, (uintptr_t)identity, 0x47435042);
}
void dev_gc_kernel_signal(unsigned recipient, uint64_t token, unsigned end)
{
    kdebug_signpost(0x474, (uintptr_t)token, recipient, end, 0x47435347);
}
#endif

static os_log_t clock_log;

__attribute__((constructor))
static void initialize_clock_log(void)
{
  alarm(30); /* Same workload watchdog when xctrace launches this executable directly. */
  clock_log = os_log_create("org.gambit.dev.gc", OS_LOG_CATEGORY_POINTS_OF_INTEREST);
}

void dev_gc_signpost(unsigned id, uint64_t ns)
{
  os_signpost_event_emit(clock_log, OS_SIGNPOST_ID_EXCLUSIVE,
                         "GambitGCClock", "ns=%{public}llu id=%{public}u",
                         (unsigned long long)ns, id);
}
