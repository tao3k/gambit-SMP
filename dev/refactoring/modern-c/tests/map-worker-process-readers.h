#ifndef GAMBIT_TEST_MAP_WORKER_PROCESS_READERS_H
#define GAMBIT_TEST_MAP_WORKER_PROCESS_READERS_H

#include <signal.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

struct map_process_ack {
  uintptr_t epoch;
  unsigned reader;
};

struct map_process_readers {
  char path[sizeof("map-worker-ack.XXXXXX")];
  int journal;
  pid_t pid[2];
  int release[2];
  const uintptr_t *mapping;
  size_t page;
  uintptr_t epoch;
  struct sigaction saved_sigchld;
  size_t backing_transition_peak;
};

static void map_process_start(struct map_process_readers *s)
{
  /* Isolated test process, no Gambit child operations in this window.
   * Otherwise the runtime SIGCHLD handler can reap an owned child first. */
  struct sigaction own = {0};
  own.sa_handler = SIG_DFL;
  sigemptyset(&own.sa_mask);
  if (sigaction(SIGCHLD, &own, &s->saved_sigchld) != 0)
    abort();
  memcpy(s->path, "map-worker-ack.XXXXXX", sizeof s->path);
  s->journal = mkstemp(s->path);
  long page = sysconf(_SC_PAGESIZE);
  if (s->journal < 0 || page <= 0)
    abort();
  s->page = (size_t)page;
  /* One shared bank page and two fixed journal record slots. */
  if (ftruncate(s->journal, page + 2 * sizeof(struct map_process_ack)) != 0)
    abort();
  s->epoch = map_worker_rounds.write_bank[0].epoch;
  if (pwrite(s->journal, &s->epoch, sizeof s->epoch, 0) != sizeof s->epoch ||
      fsync(s->journal) != 0)
    abort();
  s->mapping = mmap(NULL, s->page, PROT_READ, MAP_SHARED, s->journal, 0);
  if (s->mapping == MAP_FAILED)
    abort();
  /* Transfer the ledger's old backing to the very same mapped bytes
   * the readers access. Only retirement can unmap the parent view. */
  s->backing_transition_peak = map_worker_rounds.bank_bytes + s->page;
  free(map_worker_rounds.write_bank[0].storage);
  map_worker_rounds.write_bank[0].storage = (uintptr_t *)s->mapping;
  map_worker_rounds.write_bank[0].mapping_bytes = s->page;
  map_worker_rounds.bank_bytes += s->page - sizeof(uintptr_t);
  for (unsigned i = 0; i < 2; ++i) {
    int ready[2], release[2];
    if (pipe(ready) || pipe(release))
      abort();
    map_worker_rounds.write_bank[0].readers |= 1u << i;
    s->pid[i] = fork();
    if (s->pid[i] < 0)
      abort();
    if (s->pid[i] == 0) {
      /* No Gambit or allocator calls after fork in the threaded parent. */
      char byte = 'r';
      close(ready[0]);
      close(release[1]);
      if (*s->mapping != s->epoch || write(ready[1], &byte, 1) != 1 ||
          read(release[0], &byte, 1) != 1 || *s->mapping != s->epoch)
        _Exit(71);
      struct map_process_ack ack = {s->epoch, i};
      off_t offset = (off_t)s->page + i * sizeof ack;
      if (pwrite(s->journal, &ack, sizeof ack, offset) != sizeof ack ||
          fsync(s->journal) != 0)
        _Exit(71);
      /* Drop the ACK notification. Only the journal records settlement. */
      _Exit(0);
    }
    close(ready[1]);
    close(release[0]);
    s->release[i] = release[1];
    char byte;
    if (read(ready[0], &byte, 1) != 1 || byte != 'r')
      abort();
    close(ready[0]);
  }
}

static bool map_process_query(struct map_process_readers *s, unsigned reader)
{
  int fd = open(s->path, O_RDONLY);
  if (fd < 0)
    abort();
  struct map_process_ack ack;
  off_t offset = (off_t)s->page + reader * sizeof ack;
  if (pread(fd, &ack, sizeof ack, offset) != sizeof ack)
    abort();
  close(fd);
  return ack.epoch == s->epoch && ack.reader == reader;
}

static bool map_process_finish(struct map_process_readers *s)
{
  int result;
  if (write(s->release[0], "g", 1) != 1)
    abort();
  close(s->release[0]);
  if (waitpid(s->pid[0], &result, 0) != s->pid[0])
    abort();
  bool durable = WIFEXITED(result) && WEXITSTATUS(result) == 0 &&
    map_process_query(s, 0) && map_worker_ack_reader(s->epoch, 0) &&
    !map_worker_ack_reader(s->epoch, 0);
  bool held = !map_process_query(s, 1) && !map_worker_retire_bank(s->epoch);
  if (kill(s->pid[1], SIGKILL) != 0 ||
      waitpid(s->pid[1], &result, 0) != s->pid[1])
    abort();
  close(s->release[1]);
  bool crashed = WIFSIGNALED(result) && WTERMSIG(result) == SIGKILL &&
    !map_process_query(s, 1) && map_worker_ack_reader(s->epoch, 1);
  struct stat journal;
  if (fstat(s->journal, &journal) || close(s->journal) || unlink(s->path) ||
      sigaction(SIGCHLD, &s->saved_sigchld, NULL) != 0)
    abort();
  if (durable && held && crashed) {
    struct rusage usage;
    if (getrusage(RUSAGE_CHILDREN, &usage) != 0)
      abort();
    printf("MAP-WORKER-PROCESS-READERS-PASS children=2 durable=1 crashed=1 "
           "mapping-bytes=%zu ledger-peak-bytes=%zu transition-peak-bytes=%zu journal-record-bytes=%zu "
           "journal-file-bytes=%lld journal-blocks=%lld children-maxrss=%ld\n",
           s->page, map_worker_rounds.bank_bytes, s->backing_transition_peak,
           2 * sizeof(struct map_process_ack),
           (long long)journal.st_size, (long long)journal.st_blocks, usage.ru_maxrss);
  }
  return durable && held && crashed;
}

#endif
