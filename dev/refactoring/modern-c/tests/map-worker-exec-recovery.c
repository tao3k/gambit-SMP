/* DEV-only process supervisor and crash-replay probe. Run in an isolated
 * directory. Each scenario has its own journal and file-backed bank. */
#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/file.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

#include "map-worker-exec-journal.h"
enum cut { before_ack, after_ack, before_unlink, after_unlink, live_late_ack, live_early_ack, multi_reader, close_wins, register_wins, cut_count };
struct history {
  bool registered, acked, stopped, retiring, retired;
  bool closed;
  unsigned records, registered_readers, acked_readers;
  ino_t bank_inode;
};

static void require(bool ok, const char *where)
{
  if (!ok) {
    fprintf(stderr, "exec recovery failed at %s (errno=%d)\n", where, errno);
    exit(71);
  }
}

static void persist_reader(enum event event, unsigned id)
{
  struct stat bank;
  ino_t inode = 0;
  if (event == registered) {
    require(stat("bank", &bank) == 0, "register bank identity");
    inode = bank.st_ino;
  }
  struct record row = {17, id, event, inode};
  int fd = open("journal", O_WRONLY | O_APPEND);
  require(fd >= 0, "open journal");
  require(write(fd, &row, sizeof row) == sizeof row, "append record");
  require(fsync(fd) == 0 && close(fd) == 0, "sync journal");
}

static void persist(enum event event)
{
  persist_reader(event, 1);
}

static struct history query(void)
{
  int fd = open("journal", O_RDONLY);
  require(fd >= 0, "reopen journal");
  struct history state = {0};
  struct record row;
  ssize_t size;
  while ((size = read(fd, &row, sizeof row)) > 0) {
    require(size == sizeof row && row.epoch == 17 && row.reader >= 1 && row.reader <= 2, "record identity");
    unsigned bit = 1u << (row.reader - 1);
    require(row.event == registered || row.event == acked || row.reader == 1, "owner record identity");
    switch (row.event) {
    case registered:
      require(!state.closed && !(state.registered_readers & bit) && row.bank_inode &&
              (!state.registered || row.bank_inode == state.bank_inode), "one registration per reader");
      state.registered_readers |= bit;
      state.registered = true; state.bank_inode = row.bank_inode; break;
    case acked:
      require((state.registered_readers & bit) && !state.stopped &&
              !(state.acked_readers & bit), "one ACK per reader");
      state.acked_readers |= bit;
      state.acked = true; break;
    case admission_closed:
      require(state.registered && !state.closed, "close both registrations once");
      state.closed = true; break;
    case reader_stopped:
      require(!state.closed || state.acked_readers == state.registered_readers,
              "both closed reader ACKs precede drain");
      require(state.registered && !state.stopped, "one reader exit");
      state.stopped = true; break;
    case retiring:
      require(state.stopped && !state.retiring, "retirement requires reader exit");
      state.retiring = true; break;
    case retired:
      require(state.retiring && !state.retired, "one retirement commit");
      state.retired = true; break;
    default:
      require(false, "event kind");
    }
    ++state.records;
  }
  require(size == 0 && close(fd) == 0, "journal EOF");
  return state;
}

static void crash(void)
{
  kill(getpid(), SIGKILL);
  _Exit(72);
}

static int spawn(const char *exe, const char *role, enum cut cut)
{
  char number[2] = {(char)('0' + cut), 0};
  pid_t pid = fork();
  require(pid >= 0, "fork");
  if (pid == 0) {
    execl(exe, exe, role, number, (char *)NULL);
    _Exit(72);
  }
  int status;
  while (waitpid(pid, &status, 0) == -1) {
    require(errno == EINTR, "wait for exact child");
  }
  return status;
}

static int spawn_collector(const char *gc, const char *exe, enum cut cut)
{
  char number[2] = {(char)('0' + cut), 0};
  pid_t pid = fork();
  require(pid >= 0, "fork collector");
  if (pid == 0) {
    execl(gc, gc, "-:p3", "--exec-bank-probe", exe, number, (char *)NULL);
    _Exit(72);
  }
  int status;
  while (waitpid(pid, &status, 0) == -1)
    require(errno == EINTR, "wait collector");
  return status;
}

static bool killed(int status)
{
  return WIFSIGNALED(status) && WTERMSIG(status) == SIGKILL;
}

static bool ok(int status)
{
  return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

static void reader(enum cut cut)
{
  struct history state = query();
  require(state.registered, "reader registration");
  int fd = open("bank", O_RDONLY | O_CLOEXEC);
  struct stat bank_info;
  require(fd >= 0 && fstat(fd, &bank_info) == 0 &&
          bank_info.st_ino == state.bank_inode, "reader bank identity");
  const unsigned char *bank = mmap(NULL, 1, PROT_READ, MAP_SHARED, fd, 0);
  require(bank != MAP_FAILED && bank[0] == 17, "read granted bank");
  if (cut == before_ack)
    crash();
  persist(acked);
  if (cut == after_ack)
    crash();
  require(munmap((void *)bank, 1) == 0 && close(fd) == 0, "reader closes");
}

/* One reader per fixture. The bank lock is a kernel-owned lease that
 * survives owner death and is released when the reader closes or exits. */
static int open_registered_bank(struct history state)
{
  struct stat info;
  int fd = open("bank", O_RDONLY | O_CLOEXEC);
  require(state.registered && fd >= 0 && fstat(fd, &info) == 0 &&
          info.st_ino == state.bank_inode, "open exact live bank");
  return fd;
}

static void live_reader(enum cut cut, int ready)
{
  int fd = open_registered_bank(query());
  require(flock(fd, LOCK_SH) == 0, "hold reader lease");
  const unsigned char *bank = mmap(NULL, 1, PROT_READ, MAP_SHARED, fd, 0);
  require(bank != MAP_FAILED && bank[0] == 17, "map live bank");
  int release = open("release", O_RDWR);
  require(release >= 0, "open release channel");
  if (cut == live_early_ack)
    persist(acked);
  require(write(ready, "r", 1) == 1 && close(ready) == 0, "reader ready");
  char token;
  require(read(release, &token, 1) == 1 && token == 'x' &&
          *(const volatile unsigned char *)bank == 17, "read bank after restart");
  if (cut == live_late_ack)
    persist(acked);
  require(munmap((void *)bank, 1) == 0 && close(release) == 0, "drop last bank view");
  /* Keep the lease descriptor open until process exit. */
  _Exit(0);
}

static void start_live_reader(const char *exe, enum cut cut, unsigned id)
{
  int ready[2];
  require(pipe(ready) == 0, "reader readiness channel");
  pid_t pid = fork();
  require(pid >= 0, "fork live reader");
  if (pid == 0) {
    char number[2] = {(char)('0' + cut), 0};
    char descriptor[32];
    require(close(ready[0]) == 0, "close reader pipe end");
    snprintf(descriptor, sizeof descriptor, "%d", ready[1]);
    const char *role = id == 2 ? "live-reader-two" : "live-reader";
    execl(exe, exe, role, number, descriptor, (char *)NULL);
    _Exit(72);
  }
  char token;
  require(close(ready[1]) == 0 && read(ready[0], &token, 1) == 1 &&
          token == 'r' && close(ready[0]) == 0, "reader entered before owner crash");
}

static void retire(enum cut cut, bool restarting)
{
  struct history state = query();
  require(state.stopped, "reaped reader receipt");
  if (state.retired) {
    require(access("bank", F_OK) == -1 && errno == ENOENT, "retired bank stays absent");
    return;
  }
  if (!state.retiring)
    persist(retiring);
  if (!restarting && cut == before_unlink)
    crash();
  struct stat bank;
  if (stat("bank", &bank) == 0) {
    require(bank.st_ino == state.bank_inode && unlink("bank") == 0, "unlink registered bank");
    static const char marker[] = "EXEC-RECOVERY-UNLINK\n";
    require(write(STDOUT_FILENO, marker, sizeof marker - 1) == sizeof marker - 1, "unlink marker");
  } else
    require(restarting && state.retiring && errno == ENOENT, "only replay accepts absent bank");
  int dir = open(".", O_RDONLY);
  require(dir >= 0 && fsync(dir) == 0 && close(dir) == 0, "sync unlink");
  if (!restarting && cut == after_unlink)
    crash();
  persist(retired);
}

static int recover_live(enum cut cut, bool probe)
{
  struct history state = query();
  if (state.stopped) {
    require(!probe && state.acked, "replay requires settled ACK");
    retire(cut, true);
    return 0;
  }
  require(state.acked == (cut == live_early_ack), "recover live registration and ACK");
  int lease = open_registered_bank(state);
  require(flock(lease, LOCK_EX | LOCK_NB) == -1 && errno == EWOULDBLOCK,
          "live reader must block retirement");
  if (probe) {
    require(close(lease) == 0, "release probe descriptor");
    return 73;
  }
  int release = open("release", O_WRONLY | O_NONBLOCK);
  require(release >= 0 && write(release, "x", 1) == 1 &&
          close(release) == 0, "let orphan reader finish");
  require(flock(lease, LOCK_EX) == 0, "wait for last reader view to close");
  require(query().acked, "replay durable ACK after reader exit");
  persist(reader_stopped);
  retire(cut, true);
  require(close(lease) == 0, "release exclusive lease");
  return 0;
}

static int lock_file(const char *name, int mode)
{
  int fd = open(name, O_RDWR | O_CLOEXEC);
  require(fd >= 0, "open protocol lock");
  if (flock(fd, mode) == -1) {
    require((mode & LOCK_NB) && errno == EWOULDBLOCK && close(fd) == 0,
            "lock refusal");
    return -1;
  }
  return fd;
}

static int multi_exec_reader(unsigned id, int ready)
{
  if (id == 3 && ready >= 0)
    require(write(ready, "p", 1) == 1 && close(ready) == 0, "registration pending");
  int gate = lock_file("admission", LOCK_EX);
  struct history state = query();
  if (state.closed) {
    require(close(gate) == 0, "late registration gate");
    return 74;
  }
  require(id <= 2, "late reader must see closed registration");
  int fd = open("bank", O_RDONLY | O_CLOEXEC);
  require(fd >= 0 && flock(fd, LOCK_SH) == 0, "pin bank before registration");
  const unsigned char *bank = mmap(NULL, 1, PROT_READ, MAP_SHARED, fd, 0);
  require(bank != MAP_FAILED && bank[0] == 17, "map multi-reader bank");
  int channel = open(id == 1 ? "release" : "release-two", O_RDWR);
  require(channel >= 0, "open reader release");
  int first = id == 1 ? lock_file("first-reader", LOCK_EX) : -1;
  persist_reader(registered, id);
  if (id == 1)
    persist_reader(acked, id);
  require(close(gate) == 0 && write(ready, "r", 1) == 1 && close(ready) == 0,
          "publish admitted reader");
  char token;
  require(read(channel, &token, 1) == 1 && token == 'x' &&
          *(const volatile unsigned char *)bank == 17, "read after original owner death");
  if (id == 2) {
    gate = lock_file("admission", LOCK_EX);
    persist_reader(acked, id);
    require(close(gate) == 0, "publish final reader ACK");
  }
  require(munmap((void *)bank, 1) == 0 && close(channel) == 0, "close reader view");
  if (id == 1)
    require(close(fd) == 0 && close(first) == 0, "drop first reader lease");
  _Exit(0);
}

static bool exited_with(int status, int code)
{
  return WIFEXITED(status) && WEXITSTATUS(status) == code;
}

static void release_reader(const char *name)
{
  int fd = open(name, O_WRONLY | O_NONBLOCK);
  require(fd >= 0 && write(fd, "x", 1) == 1 && close(fd) == 0, "release reader");
}

static long long now_ns(void)
{
  struct timespec now;
  require(clock_gettime(CLOCK_MONOTONIC, &now) == 0, "read recovery clock");
  return now.tv_sec * 1000000000LL + now.tv_nsec;
}

static pid_t close_against_pending_reader(const char *exe)
{
  int ready[2];
  require(pipe(ready) == 0, "pending registration pipe");
  pid_t child = fork();
  require(child >= 0, "fork pending reader");
  if (child == 0) {
    char descriptor[32];
    require(close(ready[0]) == 0, "close pending read end");
    snprintf(descriptor, sizeof descriptor, "%d", ready[1]);
    execl(exe, exe, "pending-reader", "7", descriptor, (char *)NULL);
    _Exit(72);
  }
  char token;
  require(close(ready[1]) == 0 && read(ready[0], &token, 1) == 1 &&
          token == 'p' && close(ready[0]) == 0, "reader attempts registration before close");
  persist(admission_closed);
  return child;
}
 
static int recover_multi(const char *exe, const char *role, enum cut cut)
{
  long long start = now_ns();
  bool probe = !strcmp(role, "probe-live");
  bool crash_recovery = !strcmp(role, "crash-recovery");
  int writer = lock_file("recovery", LOCK_EX | LOCK_NB);
  if (writer < 0)
    return 75;
  int gate = lock_file("admission", LOCK_EX);
  struct history state = query();
  unsigned expected = cut == close_wins ? 1 : 3;
  require(state.registered_readers == expected, "recover exact registrations");
  pid_t pending = -1;
  if (!state.closed) {
    if (cut == close_wins)
      pending = close_against_pending_reader(exe);
    else
      persist(admission_closed);
  }
  require(close(gate) == 0, "release closed admission gate");
  if (pending >= 0) {
    int status;
    while (waitpid(pending, &status, 0) == -1)
      require(errno == EINTR, "wait pending registration");
    require(exited_with(status, 74), "pending registration loses to close");
  }
  if (state.stopped) {
    long long settle_start = now_ns();
    retire(multi_reader, true);
    if (!state.retired) {
      FILE *timing = fopen("timing", "w");
      require(timing && fprintf(timing, "0 0 %lld\n", now_ns() - settle_start) > 0 &&
              fclose(timing) == 0, "save replay timing");
    }
    require(close(writer) == 0, "release replay lock");
    return 0;
  }
  int lease = open_registered_bank(state);
  require(flock(lease, LOCK_EX | LOCK_NB) == -1 && errno == EWOULDBLOCK,
          "live readers retain bank after registration closes");
  if (probe) {
    require(close(lease) == 0 && close(writer) == 0, "release multi probe");
    return 73;
  }
  require(exited_with(spawn(exe, "late-reader", multi_reader), 74), "reject late exec reader");
  require(exited_with(spawn(exe, "recover", multi_reader), 75), "reject competing recovery writer");
  long long drain_start = now_ns();
  release_reader("release");
  int first = lock_file("first-reader", LOCK_EX);
  require(close(first) == 0 && query().acked_readers == 1, "first reader drained");
  if (expected == 3) {
    require(flock(lease, LOCK_EX | LOCK_NB) == -1 && errno == EWOULDBLOCK,
            "last reader still pins bank");
    release_reader("release-two");
  }
  require(flock(lease, LOCK_EX) == 0, "last reader exited");
  long long settle_start = now_ns();
  require(query().acked_readers == expected, "replay all admitted ACKs");
  persist(reader_stopped);
  if (crash_recovery)
    retire(cut == close_wins ? before_unlink : after_unlink, false);
  retire(multi_reader, true);
  long long end = now_ns();
  FILE *timing = fopen("timing", "w");
  require(timing && fprintf(timing, "%lld %lld %lld\n", drain_start - start,
                            settle_start - drain_start, end - settle_start) > 0 &&
          fclose(timing) == 0, "save phase timings");
  require(close(lease) == 0 && close(writer) == 0, "release multi recovery");
  return 0;
}

static void create_lock(const char *name)
{
  int fd = open(name, O_RDWR | O_CREAT | O_EXCL, 0600);
  require(fd >= 0 && close(fd) == 0, "create fixture lock");
}

static void owner(const char *exe, enum cut cut)
{
  if (cut >= multi_reader) {
    start_live_reader(exe, cut, 1);
    if (cut != close_wins)
      start_live_reader(exe, cut, 2);
    crash();
  }
  persist(registered);
  if (cut >= live_late_ack) {
    start_live_reader(exe, cut, 1);
    crash();
  }
  int status = spawn(exe, "reader", cut);
  require(cut <= after_ack ? killed(status) : ok(status), "reader outcome");
  require(query().acked == (cut != before_ack), "exact ACK query");
  persist(reader_stopped);
  if (cut <= after_ack)
    crash();
  retire(cut, false);
}

int main(int argc, char **argv)
{
  if (argc == 3 || argc == 4) {
    enum cut cut = (enum cut)(argv[2][0] - '0');
    require(cut >= 0 && cut < cut_count, "cut");
    if (argc == 4) {
      if (cut >= multi_reader)
        return multi_exec_reader(!strcmp(argv[1], "pending-reader") ? 3 :
                                 !strcmp(argv[1], "live-reader-two") ? 2 : 1, atoi(argv[3]));
      require(cut >= live_late_ack && !strcmp(argv[1], "live-reader"), "live reader role");
      live_reader(cut, atoi(argv[3]));
    }
    if (!strcmp(argv[1], "reader"))
      reader(cut);
    else if (!strcmp(argv[1], "owner"))
      owner(argv[0], cut);
    else {
      if (cut >= multi_reader) {
        if (!strcmp(argv[1], "late-reader"))
          return multi_exec_reader(3, -1);
        return recover_multi(argv[0], argv[1], cut);
      }
      bool probe = !strcmp(argv[1], "probe-live");
      require(!strcmp(argv[1], "recover") || probe, "role");
      if (cut >= live_late_ack)
        return recover_live(cut, probe);
      require(!probe, "live probe cut");
      retire(cut, true);
    }
    return 0;
  }
  require((argc == 1 || (argc == 2 && argv[1][0] == '/')) && argv[0][0] == '/', "absolute executable paths");
  char directory[] = "exec-recovery.XXXXXX";
  require(mkdtemp(directory) != NULL && chdir(directory) == 0, "isolated fixture directory");
  long page = sysconf(_SC_PAGESIZE);
  require(page > 0, "mapping size");
  for (enum cut cut = before_ack; cut < cut_count; ++cut) {
    int fd = open("bank", O_WRONLY | O_CREAT | O_EXCL, 0600);
    unsigned char payload = 17;
    require(fd >= 0 && ftruncate(fd, page) == 0 &&
            write(fd, &payload, 1) == 1 && fsync(fd) == 0 && close(fd) == 0, "create bank");
    fd = open("journal", O_WRONLY | O_CREAT | O_EXCL, 0600);
    require(fd >= 0 && fsync(fd) == 0 && close(fd) == 0, "create journal");
    bool live = cut >= live_late_ack;
    if (live)
      require(mkfifo("release", 0600) == 0, "create release channel");
    if (cut >= multi_reader) {
      require(mkfifo("release-two", 0600) == 0, "create second release channel");
      create_lock("admission");
      create_lock("recovery");
      create_lock("first-reader");
    }
    int dir = open(".", O_RDONLY);
    require(dir >= 0 && fsync(dir) == 0 && close(dir) == 0, "sync fixture names");
    require(killed(spawn(argv[0], "owner", cut)), "owner crashed");
    struct history before = query();
    require(before.stopped == !live &&
            before.acked == (cut != before_ack && cut != live_late_ack) &&
            before.retiring == (!live && cut >= before_unlink) && !before.retired,
            "persisted crash cut");
    require((access("bank", F_OK) == 0) == (cut != after_unlink), "physical crash cut");
    if (live) {
      int status = spawn(argv[0], "probe-live", cut);
      require(WIFEXITED(status) && WEXITSTATUS(status) == 73 &&
              query().records == before.records + (cut >= multi_reader) && access("bank", F_OK) == 0,
              "restart refuses retirement with an orphan reader");
      puts("EXEC-RECOVERY-LIVE-READER-REFUSED");
    }
    if (cut == before_unlink) {
      int tail = open("journal", O_WRONLY | O_APPEND);
      off_t good = lseek(tail, 0, SEEK_END);
      unsigned char fragment = 17;
      require(tail >= 0 && good > 0 && write(tail, &fragment, 1) == 1 &&
              fsync(tail) == 0, "inject short journal tail");
      int rejected = spawn(argv[0], "recover", cut);
      require(WIFEXITED(rejected) && WEXITSTATUS(rejected) == 71 &&
              access("bank", F_OK) == 0, "short tail retains bank");
      require(ftruncate(tail, good) == 0 && fsync(tail) == 0 &&
              close(tail) == 0, "restore fixture prefix");
      puts("EXEC-RECOVERY-TORN-TAIL-REFUSED");
    }
    if (cut >= close_wins) {
      require(killed(spawn(argv[0], "crash-recovery", cut)), "restart writer crashed");
      struct history interrupted = query();
      require(interrupted.closed && interrupted.stopped && interrupted.retiring &&
              !interrupted.retired && interrupted.acked_readers == interrupted.registered_readers &&
              (access("bank", F_OK) == 0) == (cut == close_wins), "exact interrupted recovery");
      printf("EXEC-RECOVERY-SECOND-CRASH cut=%d readers=%u bank-present=%d\n",
             cut, interrupted.registered_readers, cut == close_wins);
    }
    struct timespec start, finish;
    require(clock_gettime(CLOCK_MONOTONIC, &start) == 0, "start clock");
    if (argc == 2)
      require(ok(spawn_collector(argv[1], argv[0], cut)), "collector linked restart");
    else
      require(ok(spawn(argv[0], "recover", cut)), "restart");
    require(clock_gettime(CLOCK_MONOTONIC, &finish) == 0, "finish clock");
    struct history settled = query();
    require(settled.retired && settled.records == (cut == close_wins ? 6u : cut >= multi_reader ? 8u : cut == before_ack ? 4u : 5u), "exact journal settlement");
    require(ok(spawn(argv[0], "recover", cut)) && query().records == settled.records, "idempotent restart");
    long long ns = (finish.tv_sec - start.tv_sec) * 1000000000LL + finish.tv_nsec - start.tv_nsec;
    printf("EXEC-RECOVERY-PASS cut=%d ack=%d records=%u journal-bytes=%zu bank-bytes=%ld window-ns=%lld coupled=%d\n",
           cut, settled.acked, settled.records, settled.records * sizeof(struct record), page, ns, argc == 2);
    if (cut >= multi_reader) {
      FILE *timing = fopen("timing", "r");
      long long arbitration = 0, drain = 0, settlement = 0;
      require(timing && fscanf(timing, "%lld %lld %lld", &arbitration, &drain, &settlement) == 3 &&
              fclose(timing) == 0, "read phase timings");
      printf("EXEC-RECOVERY-MULTI-PASS late=1 contender=1 first-drain-held=%d cut=%d arbitration-ns=%lld drain-ns=%lld settlement-ns=%lld coupled=%d\n",
             cut != close_wins, cut, arbitration, drain, settlement, argc == 2);
      require(unlink("timing") == 0 && unlink("release-two") == 0 &&
              unlink("admission") == 0 && unlink("recovery") == 0 &&
              unlink("first-reader") == 0, "remove multi-reader fixture files");
    }
    require(unlink("journal") == 0 && (!live || unlink("release") == 0), "remove fixture files");
  }
  require(chdir("..") == 0 && rmdir(directory) == 0, "remove fixture directory");
  return 0;
}
