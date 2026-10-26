"""Targeted Darwin syscall fault injection against the actual managed GSI."""
from pathlib import Path
import hashlib, json, os, re
from gambit_smp import workspace as w
from gambit_smp.artifact_storage import workspace_lease
from gambit_smp.recipes import tree_identity
from gambit_smp.framework import execute
ROOT = Path(__file__).resolve().parents[3]
BUILD = ROOT / ".cache/tasks/repair-9-12/build/gambit-core/c86dff86b3d7e2ed55e4d3900f2a58ea05c9ca955064da1e1da07d0c114a06d6"
SOURCE = BUILD / "source"
C_SOURCE = r'''#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
static unsigned long attempts, failures;
static int mode;
__attribute__((constructor)) static void setup(void) {
  const char *p = getenv("SMP_WAKE_FAULT"); mode = p ? atoi(p) : 0;
}
static ssize_t fault_write(int fd, const void *p, size_t n) {
  struct stat st;
  if (n == 1 && *(const unsigned char *)p == 0 &&
      fstat(fd, &st) == 0 && S_ISFIFO(st.st_mode) &&
      (fcntl(fd, F_GETFL) & O_NONBLOCK)) {
    unsigned long k = __sync_add_and_fetch(&attempts, 1);
    if (mode == 2 || (mode == 1 && k == 1)) {
      __sync_add_and_fetch(&failures, 1);
      errno = mode == 1 ? EINTR : EBADF;
      return -1;
    }
  }
  return write(fd, p, n);
}
__attribute__((used, section("__DATA,__interpose")))
static const struct { const void *replacement, *original; } interpose =
  {(const void *)fault_write, (const void *)write};
__attribute__((destructor)) static void report(void) {
  char b[160]; int n = snprintf(b, sizeof(b),
    "WAKE-INJECT mode=%d attempts=%lu failures=%lu\n", mode, attempts, failures);
  write(2, b, n);
}
'''
RETURN_PROGRAM = r'''(let loop ((i 0))
 (if (< i 5)
  (begin (##device-select-abort! 0)
         (##os-condvar-select! #f #t)
         (loop (+ i 1)))
  (begin (display "FAULT-INDEPENDENT-RETURN\n") (force-output))))
'''
GC_PROGRAM = r'''(define (worker i)
 (let ((root (make-vector 128 i)))
  (let loop ((n 0))
   (if (< n 3)
    (begin (##device-select-abort! 0) (##gc)
           (let ((start (##current-time-point)))
            (thread-sleep! 0.06)
            (if (< (- (##current-time-point) start) 0.05) (exit 31)))
           (if (not (= (vector-ref root 127) i)) (exit 32))
           (loop (+ n 1)))
    i))))
(let* ((threads (map (lambda (i) (make-thread (lambda () (worker i))))
                    '(0 1 2 3 4 5 6 7 8 9))))
 (for-each thread-start! threads)
 (let ((results (map thread-join! threads)))
  (if (not (equal? results '(0 1 2 3 4 5 6 7 8 9))) (exit 33))
  (display "GC-ROOT-DEADLINE-PROGRESS\n") (force-output)))
'''

def main():
 with w.execution_scope(ROOT, "repair-9-12"):
  out = w.task_output(ROOT, ROOT / ".cache/native-wake-fault")
  out.mkdir(parents=True, exist_ok=True)
  proof = json.loads((BUILD / "configure-proof.json").read_text())
  env = dict(os.environ); env.update(proof["commands"][0]["environment"])
  receipt = dict(schema="native-wake-fault.v1", stages=[], nativeAdmitted=False,
    coordinatorImplemented=False, fullInventoryExecuted=False,
    gsiSha256=hashlib.sha256((SOURCE / "gsi/gsi").read_bytes()).hexdigest(),
    sourceSha256=hashlib.sha256((SOURCE / "lib/os_io.c").read_bytes()).hexdigest())
  def save(): (out / "receipt.json").write_text(json.dumps(receipt, indent=2))
  def run(name, argv, cap, extra=None):
   selected = dict(env); selected.update(extra or {}); meta = {}
   rc, log, timed, sec = execute(argv, out, cap, env=selected, metadata=meta)
   (out / (name + ".log")).write_text(log)
   row = dict(name=name, exit=rc, timedOut=timed, seconds=sec, process=meta)
   receipt["stages"].append(row);save()
   print(name, rc, timed, sec, log[-800:], flush=True)
   return row, log
  with workspace_lease(ROOT, SOURCE, tree_identity(SOURCE)):
   c = out / "wake-fault.c";c.write_text(C_SOURCE)
   dylib = out / "wake-fault.dylib"
   row, _ = run("build-injector", ["/opt/homebrew/Cellar/gcc/16.2.0/bin/gcc-16", "-dynamiclib", "-O1", "-o", str(dylib), str(c)], 30)
   if row["exit"] != 0 or row["timedOut"]: return
   option = "-:p11,~~lib=" + str(SOURCE / "lib") + ",~~bin=" + str(SOURCE / "bin") + ",~~include=" + str(SOURCE / "include")
   for name, program, marker in [("independent-return", RETURN_PROGRAM, "FAULT-INDEPENDENT-RETURN"),
                                  ("gc-deadline-progress", GC_PROGRAM, "GC-ROOT-DEADLINE-PROGRESS")]:
    script = out / (name + ".scm");script.write_text(program)
    for mode in (0, 1, 2):
     row, log = run(name + "-" + str(mode), [str(SOURCE / "gsi/gsi"), option, str(script)], 30,
       {"DYLD_INSERT_LIBRARIES": str(dylib), "SMP_WAKE_FAULT": str(mode)})
     match = re.search(r"WAKE-INJECT mode=(\d+) attempts=(\d+) failures=(\d+)", log)
     row["injection"] = dict(mode=int(match[1]), attempts=int(match[2]), failures=int(match[3])) if match else None
     row["passed"] = bool(row["exit"] == 0 and not row["timedOut"] and marker in log and match
       and int(match[2]) > 0 and (mode == 0 or int(match[3]) > 0))
     save()
  print(out, flush=True)
if __name__ == "__main__": main()
