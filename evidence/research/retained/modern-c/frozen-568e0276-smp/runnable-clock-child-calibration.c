#include <inttypes.h>
#include <libproc.h>
#include <mach/mach_time.h>
#include <stddef.h>
#include <stdio.h>
#include <sys/resource.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static uint64_t cpu_ns(void)
{
  struct timespec ts;
  if (clock_gettime(CLOCK_PROCESS_CPUTIME_ID, &ts)) return 0;
  return (uint64_t)ts.tv_sec * UINT64_C(1000000000) + (uint64_t)ts.tv_nsec;
}

static int sample(const char *label)
{
  struct rusage_info_v4 info = {0};
  if (proc_pid_rusage(getpid(), RUSAGE_INFO_V4, (rusage_info_t *)&info)) {
    perror("proc_pid_rusage RUSAGE_INFO_V4");
    return 1;
  }
  printf("%s %" PRIu64 " %" PRIu64 " %" PRIu64 " %" PRIu64 " %" PRIu64 "\n",
         label, mach_absolute_time(), cpu_ns(),
         info.ri_user_time + info.ri_system_time, info.ri_runnable_time,
         info.ri_child_user_time + info.ri_child_system_time);
  return fflush(stdout) != 0;
}

static void busy(void)
{
  const uint64_t start = cpu_ns();
  while (cpu_ns() - start < UINT64_C(300000000)) {}
}

int main(void)
{
  mach_timebase_info_data_t ratio;
  if (mach_timebase_info(&ratio)) return 2;
  printf("abi %zu %zu %u %u\n", sizeof(struct rusage_info_v4),
         offsetof(struct rusage_info_v4, ri_runnable_time), ratio.numer, ratio.denom);
  if (sample("start")) return 3;
  busy();
  if (sample("busy-1")) return 4;
  if (nanosleep(&(struct timespec){.tv_nsec=750000000}, NULL)) return 5;
  if (sample("sleep-1")) return 6;
  busy();
  if (sample("busy-2")) return 7;
  if (nanosleep(&(struct timespec){.tv_nsec=750000000}, NULL)) return 8;
  if (sample("sleep-2")) return 9;
  pid_t child = fork();
  if (child == 0) {
    busy();
    _exit(0);
  }
  int status;
  if (child < 0 || waitpid(child, &status, 0) != child || !WIFEXITED(status) || WEXITSTATUS(status)) return 10;
  return sample("child-reaped");
}
